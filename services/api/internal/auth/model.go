package auth

import (
	"context"
	"errors"
	"time"
)

var (
	// ErrEmailTaken indicates that an account already uses the normalized email.
	ErrEmailTaken = errors.New("email is already registered")
	// ErrUsernameTaken indicates that an account already uses the normalized username.
	ErrUsernameTaken = errors.New("username is already registered")
	// ErrInvalidCredentials hides whether the email or password was incorrect.
	ErrInvalidCredentials = errors.New("invalid email or password")
	// ErrInvalidToken indicates that a session token is missing, expired, or revoked.
	ErrInvalidToken = errors.New("invalid session token")
)

// InputError identifies a safe validation message for the client.
type InputError struct {
	Message string
}

func (e *InputError) Error() string {
	return e.Message
}

// User is the public account representation.
type User struct {
	ID          uint64
	Username    string
	Email       string
	DisplayName string
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

// UserRecord contains private data used only while authenticating.
type UserRecord struct {
	User
	PasswordHash string
}

// StoredToken is the digest and expiration persisted for an opaque token.
type StoredToken struct {
	Hash      []byte
	ExpiresAt time.Time
}

// Session is returned once a new access and refresh token pair is issued.
type Session struct {
	User             User
	AccessToken      string
	AccessExpiresAt  time.Time
	RefreshToken     string
	RefreshExpiresAt time.Time
}

// Repository defines the transactional persistence required by authentication.
type Repository interface {
	CreateAccount(ctx context.Context, username, email, displayName, passwordHash string, access, refresh StoredToken) (User, error)
	FindUserByEmail(ctx context.Context, email string) (UserRecord, error)
	CreateSession(ctx context.Context, userID uint64, access, refresh StoredToken) error
	RotateSession(ctx context.Context, oldRefreshHash []byte, now time.Time, access, refresh StoredToken) (User, error)
	FindUserByAccessToken(ctx context.Context, tokenHash []byte, now time.Time) (User, error)
	RevokeSession(ctx context.Context, accessHash, refreshHash []byte, now time.Time) error
}
