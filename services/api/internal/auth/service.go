package auth

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/ewcds12/instant-chat/services/api/internal/users"
)

const (
	minimumDisplayRunes = 2
	maximumDisplayRunes = 80
	maximumRegionRunes  = 80
	maximumAvatarBytes  = 5 * 1024 * 1024
)

var allowedAvatarContentTypes = map[string]struct{}{
	"image/gif":  {},
	"image/jpeg": {},
	"image/png":  {},
	"image/webp": {},
}

// Service implements authentication business rules.
type Service struct {
	repository Repository
	passwords  *PasswordHasher
	dummyHash  string
	now        func() time.Time
}

// NewService creates an authentication service.
func NewService(repository Repository, passwords *PasswordHasher) (*Service, error) {
	dummyHash, err := passwords.Hash("not-a-real-account-password")
	if err != nil {
		return nil, fmt.Errorf("create authentication timing hash: %w", err)
	}
	return &Service{
		repository: repository,
		passwords:  passwords,
		dummyHash:  dummyHash,
		now:        time.Now,
	}, nil
}

// Register creates a user and initial token pair.
func (s *Service) Register(ctx context.Context, username, displayName, password string) (Session, error) {
	normalizedUsername, err := validateRegistration(username, displayName)
	if err != nil {
		return Session{}, err
	}
	passwordHash, err := s.passwords.Hash(password)
	if err != nil {
		return Session{}, fmt.Errorf("hash password: %w", err)
	}
	now := s.now().UTC()
	tokens, err := newTokenPair(now)
	if err != nil {
		return Session{}, err
	}
	user, err := s.repository.CreateAccount(
		ctx, normalizedUsername, strings.TrimSpace(displayName), passwordHash,
		tokens.access, tokens.refresh,
	)
	if err != nil {
		return Session{}, err
	}
	return buildSession(user, tokens), nil
}

// Login verifies credentials and issues a new token pair.
func (s *Service) Login(ctx context.Context, username, password string) (Session, error) {
	normalizedUsername, valid := users.NormalizeUsername(username)
	if !valid {
		s.consumePasswordTime(password)
		return Session{}, ErrInvalidCredentials
	}
	record, err := s.repository.FindUserByUsername(ctx, normalizedUsername)
	if err != nil {
		if errors.Is(err, ErrInvalidCredentials) {
			s.consumePasswordTime(password)
		}
		return Session{}, err
	}
	validPassword, err := s.passwords.Verify(record.PasswordHash, password)
	if err != nil {
		return Session{}, fmt.Errorf("verify password hash: %w", err)
	}
	if !validPassword {
		return Session{}, ErrInvalidCredentials
	}
	tokens, err := newTokenPair(s.now().UTC())
	if err != nil {
		return Session{}, err
	}
	if err := s.repository.CreateSession(ctx, record.ID, tokens.access, tokens.refresh); err != nil {
		return Session{}, err
	}
	return buildSession(record.User, tokens), nil
}

// Refresh rotates a valid refresh token and issues a new session.
func (s *Service) Refresh(ctx context.Context, refreshToken string) (Session, error) {
	if refreshToken == "" {
		return Session{}, ErrInvalidToken
	}
	now := s.now().UTC()
	tokens, err := newTokenPair(now)
	if err != nil {
		return Session{}, err
	}
	user, err := s.repository.RotateSession(ctx, hashToken(refreshToken), now, tokens.access, tokens.refresh)
	if err != nil {
		return Session{}, err
	}
	return buildSession(user, tokens), nil
}

// CurrentUser resolves a user from a valid access token.
func (s *Service) CurrentUser(ctx context.Context, accessToken string) (User, error) {
	if accessToken == "" {
		return User{}, ErrInvalidToken
	}
	return s.repository.FindUserByAccessToken(ctx, hashToken(accessToken), s.now().UTC())
}

// UpdateProfile validates and persists the editable account profile fields.
func (s *Service) UpdateProfile(ctx context.Context, userID uint64, input ProfileInput) (User, error) {
	normalizedUsername, valid := users.NormalizeUsername(input.Username)
	if !valid {
		return User{}, &InputError{Message: "ID must be 3 to 32 characters, start with a letter, and use only lowercase letters, numbers, or underscores."}
	}
	displayName, err := validateDisplayName(input.DisplayName)
	if err != nil {
		return User{}, err
	}
	gender, err := validateGender(input.Gender)
	if err != nil {
		return User{}, err
	}
	region, err := validateRegion(input.Region)
	if err != nil {
		return User{}, err
	}
	return s.repository.UpdateProfile(ctx, userID, ProfileInput{
		Username: normalizedUsername, DisplayName: displayName, Gender: gender, Region: region,
	})
}

// UpdateAvatar validates and stores one profile photo.
func (s *Service) UpdateAvatar(ctx context.Context, userID uint64, upload AvatarUpload) (User, error) {
	if len(upload.Data) == 0 {
		return User{}, &InputError{Message: "Profile photo must not be empty."}
	}
	if len(upload.Data) > maximumAvatarBytes {
		return User{}, &InputError{Message: "Profile photo must be 5 MB or smaller."}
	}
	if _, ok := allowedAvatarContentTypes[upload.ContentType]; !ok {
		return User{}, &InputError{Message: "Profile photo must be PNG, JPEG, GIF, or WebP."}
	}
	return s.repository.UpdateAvatar(ctx, userID, upload)
}

// Avatar returns one profile photo for an authenticated account.
func (s *Service) Avatar(ctx context.Context, userID uint64) (Avatar, error) {
	if userID == 0 {
		return Avatar{}, &InputError{Message: "User ID must be a positive integer string."}
	}
	return s.repository.Avatar(ctx, userID)
}

// Logout revokes the supplied access and refresh token pair.
func (s *Service) Logout(ctx context.Context, accessToken, refreshToken string) error {
	if accessToken == "" || refreshToken == "" {
		return ErrInvalidToken
	}
	return s.repository.RevokeSession(
		ctx, hashToken(accessToken), hashToken(refreshToken), s.now().UTC(),
	)
}

func (s *Service) consumePasswordTime(password string) {
	// A valid dummy hash reduces the account-enumeration timing difference.
	_, _ = s.passwords.Verify(s.dummyHash, password)
}

func validateRegistration(username, displayName string) (string, error) {
	normalizedUsername, valid := users.NormalizeUsername(username)
	if !valid {
		return "", &InputError{Message: "Username must be 3 to 32 characters, start with a letter, and use only lowercase letters, numbers, or underscores."}
	}
	if _, err := validateDisplayName(displayName); err != nil {
		return "", err
	}
	return normalizedUsername, nil
}

func validateDisplayName(value string) (string, error) {
	trimmed := strings.TrimSpace(value)
	length := utf8.RuneCountInString(trimmed)
	if length < minimumDisplayRunes || length > maximumDisplayRunes {
		return "", &InputError{Message: "Name must be between 2 and 80 characters."}
	}
	for _, character := range trimmed {
		if unicode.IsControl(character) {
			return "", &InputError{Message: "Name contains an unsupported character."}
		}
	}
	return trimmed, nil
}

func validateGender(value string) (string, error) {
	switch strings.TrimSpace(value) {
	case "", "female", "male", "non_binary", "prefer_not_to_say":
		return strings.TrimSpace(value), nil
	default:
		return "", &InputError{Message: "Gender is not supported."}
	}
}

func validateRegion(value string) (string, error) {
	trimmed := strings.TrimSpace(value)
	if utf8.RuneCountInString(trimmed) > maximumRegionRunes {
		return "", &InputError{Message: "Region must be 80 characters or fewer."}
	}
	for _, character := range trimmed {
		if unicode.IsControl(character) {
			return "", &InputError{Message: "Region contains an unsupported character."}
		}
	}
	return trimmed, nil
}
