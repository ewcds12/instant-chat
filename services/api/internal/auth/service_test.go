package auth

import (
	"bytes"
	"context"
	"errors"
	"testing"
	"time"
)

var serviceTestTime = time.Date(2026, time.July, 15, 12, 0, 0, 0, time.UTC)

type fakeRepository struct {
	createdUsername     string
	createdDisplayName  string
	createdPasswordHash string
	userRecord          UserRecord
	findUserError       error
	rotatedHash         []byte
	profileInput        ProfileInput
}

func (f *fakeRepository) CreateAccount(_ context.Context, username, displayName, passwordHash string, _, _ StoredToken) (User, error) {
	f.createdUsername = username
	f.createdDisplayName = displayName
	f.createdPasswordHash = passwordHash
	return User{ID: 7, Username: username, DisplayName: displayName, CreatedAt: serviceTestTime}, nil
}

func (f *fakeRepository) FindUserByUsername(context.Context, string) (UserRecord, error) {
	return f.userRecord, f.findUserError
}

func (f *fakeRepository) CreateSession(context.Context, uint64, StoredToken, StoredToken) error {
	return nil
}

func (f *fakeRepository) RotateSession(_ context.Context, oldRefreshHash []byte, _ time.Time, _, _ StoredToken) (User, error) {
	f.rotatedHash = bytes.Clone(oldRefreshHash)
	return User{ID: 7, Username: "retro_user", DisplayName: "Retro User"}, nil
}

func (f *fakeRepository) FindUserByAccessToken(context.Context, []byte, time.Time) (User, error) {
	return User{ID: 7}, nil
}

func (f *fakeRepository) UpdateProfile(_ context.Context, _ uint64, input ProfileInput) (User, error) {
	f.profileInput = input
	return User{ID: 7, Username: input.Username, DisplayName: input.DisplayName}, nil
}

func (f *fakeRepository) UpdateAvatar(context.Context, uint64, AvatarUpload) (User, error) {
	return User{ID: 7}, nil
}

func (f *fakeRepository) Avatar(context.Context, uint64) (Avatar, error) {
	return Avatar{}, nil
}

func (f *fakeRepository) RevokeSession(context.Context, []byte, []byte, time.Time) error {
	return nil
}

func TestServiceRegisterNormalizesInputAndIssuesSession(t *testing.T) {
	repository := &fakeRepository{}
	service := newTestService(t, repository)

	session, err := service.Register(
		context.Background(), "  RETRO_USER ", "  Retro User  ", "pw",
	)
	if err != nil {
		t.Fatalf("Register() error = %v", err)
	}

	if repository.createdUsername != "retro_user" {
		t.Fatalf("created username = %q, want normalized username", repository.createdUsername)
	}
	if repository.createdDisplayName != "Retro User" {
		t.Fatalf("created display name = %q, want trimmed name", repository.createdDisplayName)
	}
	if repository.createdPasswordHash == "pw" {
		t.Fatal("password was stored without hashing")
	}
	if session.AccessToken == "" || session.RefreshToken == "" {
		t.Fatal("Register() returned an empty token")
	}
	if session.AccessExpiresAt != serviceTestTime.Add(accessTokenTTL) {
		t.Fatalf("access expiration = %v, want %v", session.AccessExpiresAt, serviceTestTime.Add(accessTokenTTL))
	}
}

func TestServiceRegisterDoesNotEnforcePasswordLength(t *testing.T) {
	repository := &fakeRepository{}
	service := newTestService(t, repository)

	_, err := service.Register(
		context.Background(), "retro_user", "Retro User", "",
	)
	if err != nil {
		t.Fatalf("Register() error = %v", err)
	}
}

func TestServiceRegisterRejectsInvalidUsername(t *testing.T) {
	service := newTestService(t, &fakeRepository{})

	_, err := service.Register(context.Background(), "2invalid", "Retro User", "password")
	var inputError *InputError
	if !errors.As(err, &inputError) {
		t.Fatalf("Register() error = %v, want InputError", err)
	}
}

func TestServiceLoginRejectsIncorrectPassword(t *testing.T) {
	hasher := testPasswordHasher()
	passwordHash, err := hasher.Hash("correct password")
	if err != nil {
		t.Fatalf("Hash() error = %v", err)
	}
	repository := &fakeRepository{userRecord: UserRecord{
		User: User{ID: 7, Username: "retro_user"}, PasswordHash: passwordHash,
	}}
	service, err := NewService(repository, hasher)
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}

	_, err = service.Login(context.Background(), "retro_user", "incorrect password")
	if !errors.Is(err, ErrInvalidCredentials) {
		t.Fatalf("Login() error = %v, want ErrInvalidCredentials", err)
	}
}

func TestServiceRefreshHashesSuppliedToken(t *testing.T) {
	repository := &fakeRepository{}
	service := newTestService(t, repository)

	if _, err := service.Refresh(context.Background(), "refresh-token"); err != nil {
		t.Fatalf("Refresh() error = %v", err)
	}
	if !bytes.Equal(repository.rotatedHash, hashToken("refresh-token")) {
		t.Fatal("Refresh() did not hash the supplied token")
	}
}

func TestServiceUpdateProfileNormalizesIDAndAllowsUnsetFields(t *testing.T) {
	repository := &fakeRepository{}
	service := newTestService(t, repository)

	_, err := service.UpdateProfile(context.Background(), 7, ProfileInput{
		Username: "  RETRO_USER ", DisplayName: "  Retro User  ",
	})
	if err != nil {
		t.Fatalf("UpdateProfile() error = %v", err)
	}
	if repository.profileInput.Username != "retro_user" || repository.profileInput.DisplayName != "Retro User" {
		t.Fatalf("profile input = %+v", repository.profileInput)
	}

	_, err = service.UpdateProfile(context.Background(), 7, ProfileInput{
		Username: "retro_user", DisplayName: "Retro User", Gender: "unsupported",
	})
	var inputError *InputError
	if !errors.As(err, &inputError) {
		t.Fatalf("UpdateProfile() error = %v, want InputError", err)
	}
}

func newTestService(t *testing.T, repository Repository) *Service {
	t.Helper()
	service, err := NewService(repository, testPasswordHasher())
	if err != nil {
		t.Fatalf("NewService() error = %v", err)
	}
	service.now = func() time.Time { return serviceTestTime }
	return service
}
