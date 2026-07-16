package auth

import (
	"context"
	"errors"
	"fmt"
	"net/mail"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"

	"github.com/ewcds12/instant-chat/services/api/internal/users"
)

const (
	minimumPasswordRunes = 12
	maximumPasswordRunes = 128
	minimumDisplayRunes  = 2
	maximumDisplayRunes  = 80
)

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
func (s *Service) Register(ctx context.Context, email, username, displayName, password string) (Session, error) {
	normalizedEmail, normalizedUsername, err := validateRegistration(email, username, displayName, password)
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
		ctx, normalizedUsername, normalizedEmail, strings.TrimSpace(displayName), passwordHash,
		tokens.access, tokens.refresh,
	)
	if err != nil {
		return Session{}, err
	}
	return buildSession(user, tokens), nil
}

// Login verifies credentials and issues a new token pair.
func (s *Service) Login(ctx context.Context, email, password string) (Session, error) {
	normalizedEmail, valid := normalizeEmail(email)
	if !valid {
		s.consumePasswordTime(password)
		return Session{}, ErrInvalidCredentials
	}
	record, err := s.repository.FindUserByEmail(ctx, normalizedEmail)
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

func validateRegistration(email, username, displayName, password string) (string, string, error) {
	normalizedEmail, valid := normalizeEmail(email)
	if !valid {
		return "", "", &InputError{Message: "Enter a valid email address."}
	}
	normalizedUsername, valid := users.NormalizeUsername(username)
	if !valid {
		return "", "", &InputError{Message: "Username must be 3 to 32 characters, start with a letter, and use only lowercase letters, numbers, or underscores."}
	}
	trimmedName := strings.TrimSpace(displayName)
	nameLength := utf8.RuneCountInString(trimmedName)
	if nameLength < minimumDisplayRunes || nameLength > maximumDisplayRunes {
		return "", "", &InputError{Message: "Display name must be between 2 and 80 characters."}
	}
	for _, value := range trimmedName {
		if unicode.IsControl(value) {
			return "", "", &InputError{Message: "Display name contains an unsupported character."}
		}
	}
	passwordLength := utf8.RuneCountInString(password)
	if !utf8.ValidString(password) || passwordLength < minimumPasswordRunes || passwordLength > maximumPasswordRunes {
		return "", "", &InputError{Message: "Password must be between 12 and 128 characters."}
	}
	return normalizedEmail, normalizedUsername, nil
}

func normalizeEmail(value string) (string, bool) {
	normalized := strings.ToLower(strings.TrimSpace(value))
	if normalized == "" || len(normalized) > 254 {
		return "", false
	}
	address, err := mail.ParseAddress(normalized)
	return normalized, err == nil && address.Address == normalized
}
