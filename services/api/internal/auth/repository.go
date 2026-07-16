package auth

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/go-sql-driver/mysql"

	"github.com/ewcds12/instant-chat/services/api/internal/store"
)

// MySQLRepository persists authentication data with sqlc-generated queries.
type MySQLRepository struct {
	database *sql.DB
	queries  *store.Queries
}

// NewMySQLRepository creates the production authentication repository.
func NewMySQLRepository(database *sql.DB) *MySQLRepository {
	return &MySQLRepository{database: database, queries: store.New(database)}
}

// CreateAccount creates a user and initial session atomically.
func (r *MySQLRepository) CreateAccount(ctx context.Context, username, email, displayName, passwordHash string, access, refresh StoredToken) (User, error) {
	tx, err := r.database.BeginTx(ctx, nil)
	if err != nil {
		return User{}, fmt.Errorf("begin account transaction: %w", err)
	}
	queries := r.queries.WithTx(tx)
	result, err := queries.CreateUser(ctx, store.CreateUserParams{
		Username: username, Email: email, DisplayName: displayName, PasswordHash: passwordHash,
	})
	if err != nil {
		return User{}, rollback(tx, mapCreateUserError(err))
	}
	userID, err := result.LastInsertId()
	if err != nil {
		return User{}, rollback(tx, fmt.Errorf("read new user ID: %w", err))
	}
	if userID <= 0 {
		return User{}, rollback(tx, errors.New("new user ID must be positive"))
	}
	if err := createTokens(ctx, queries, uint64(userID), access, refresh); err != nil {
		return User{}, rollback(tx, err)
	}
	created, err := queries.GetUserByEmail(ctx, email)
	if err != nil {
		return User{}, rollback(tx, fmt.Errorf("read new user: %w", err))
	}
	if err := tx.Commit(); err != nil {
		return User{}, fmt.Errorf("commit account transaction: %w", err)
	}
	return userFromStore(created), nil
}

// FindUserByEmail returns the private record used to verify credentials.
func (r *MySQLRepository) FindUserByEmail(ctx context.Context, email string) (UserRecord, error) {
	user, err := r.queries.GetUserByEmail(ctx, email)
	if errors.Is(err, sql.ErrNoRows) {
		return UserRecord{}, ErrInvalidCredentials
	}
	if err != nil {
		return UserRecord{}, fmt.Errorf("find user by email: %w", err)
	}
	return UserRecord{User: userFromStore(user), PasswordHash: user.PasswordHash}, nil
}

// CreateSession persists an access and refresh token atomically.
func (r *MySQLRepository) CreateSession(ctx context.Context, userID uint64, access, refresh StoredToken) error {
	tx, err := r.database.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin session transaction: %w", err)
	}
	if err := createTokens(ctx, r.queries.WithTx(tx), userID, access, refresh); err != nil {
		return rollback(tx, err)
	}
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit session transaction: %w", err)
	}
	return nil
}

// RotateSession revokes a refresh token and replaces its token pair atomically.
func (r *MySQLRepository) RotateSession(ctx context.Context, oldRefreshHash []byte, now time.Time, access, refresh StoredToken) (User, error) {
	tx, err := r.database.BeginTx(ctx, nil)
	if err != nil {
		return User{}, fmt.Errorf("begin refresh transaction: %w", err)
	}
	queries := r.queries.WithTx(tx)
	session, err := queries.GetRefreshSessionForUpdate(ctx, store.GetRefreshSessionForUpdateParams{
		TokenHash: oldRefreshHash, ExpiresAt: now,
	})
	if errors.Is(err, sql.ErrNoRows) {
		return User{}, rollback(tx, ErrInvalidToken)
	}
	if err != nil {
		return User{}, rollback(tx, fmt.Errorf("find refresh token: %w", err))
	}
	if err := queries.RevokeRefreshTokenByID(ctx, store.RevokeRefreshTokenByIDParams{
		RevokedAt: sql.NullTime{Time: now, Valid: true}, ID: session.RefreshTokenID,
	}); err != nil {
		return User{}, rollback(tx, fmt.Errorf("revoke refresh token: %w", err))
	}
	if err := createTokens(ctx, queries, session.UserID, access, refresh); err != nil {
		return User{}, rollback(tx, err)
	}
	if err := tx.Commit(); err != nil {
		return User{}, fmt.Errorf("commit refresh transaction: %w", err)
	}
	return User{
		ID: session.UserID, Username: session.Username, Email: session.Email, DisplayName: session.DisplayName,
		CreatedAt: session.CreatedAt, UpdatedAt: session.UpdatedAt,
	}, nil
}

// FindUserByAccessToken resolves a nonexpired, nonrevoked access token.
func (r *MySQLRepository) FindUserByAccessToken(ctx context.Context, tokenHash []byte, now time.Time) (User, error) {
	user, err := r.queries.GetUserByAccessToken(ctx, store.GetUserByAccessTokenParams{
		TokenHash: tokenHash, ExpiresAt: now,
	})
	if errors.Is(err, sql.ErrNoRows) {
		return User{}, ErrInvalidToken
	}
	if err != nil {
		return User{}, fmt.Errorf("find access token: %w", err)
	}
	return User{
		ID: user.UserID, Username: user.Username, Email: user.Email, DisplayName: user.DisplayName,
		CreatedAt: user.CreatedAt, UpdatedAt: user.UpdatedAt,
	}, nil
}

// RevokeSession revokes both supplied tokens atomically and is idempotent.
func (r *MySQLRepository) RevokeSession(ctx context.Context, accessHash, refreshHash []byte, now time.Time) error {
	tx, err := r.database.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin logout transaction: %w", err)
	}
	queries := r.queries.WithTx(tx)
	revokedAt := sql.NullTime{Time: now, Valid: true}
	if err := queries.RevokeAccessTokenByHash(ctx, store.RevokeAccessTokenByHashParams{
		RevokedAt: revokedAt, TokenHash: accessHash,
	}); err != nil {
		return rollback(tx, fmt.Errorf("revoke access token: %w", err))
	}
	if err := queries.RevokeRefreshTokenByHash(ctx, store.RevokeRefreshTokenByHashParams{
		RevokedAt: revokedAt, TokenHash: refreshHash,
	}); err != nil {
		return rollback(tx, fmt.Errorf("revoke refresh token: %w", err))
	}
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit logout transaction: %w", err)
	}
	return nil
}

func createTokens(ctx context.Context, queries *store.Queries, userID uint64, access, refresh StoredToken) error {
	if err := queries.CreateAccessToken(ctx, store.CreateAccessTokenParams{
		UserID: userID, TokenHash: access.Hash, ExpiresAt: access.ExpiresAt,
	}); err != nil {
		return fmt.Errorf("create access token: %w", err)
	}
	if err := queries.CreateRefreshToken(ctx, store.CreateRefreshTokenParams{
		UserID: userID, TokenHash: refresh.Hash, ExpiresAt: refresh.ExpiresAt,
	}); err != nil {
		return fmt.Errorf("create refresh token: %w", err)
	}
	return nil
}

func userFromStore(user store.GetUserByEmailRow) User {
	return User{
		ID: user.ID, Username: user.Username, Email: user.Email, DisplayName: user.DisplayName,
		CreatedAt: user.CreatedAt, UpdatedAt: user.UpdatedAt,
	}
}

func mapCreateUserError(err error) error {
	var mysqlError *mysql.MySQLError
	if errors.As(err, &mysqlError) && mysqlError.Number == 1062 {
		if strings.Contains(mysqlError.Message, "uq_users_username") {
			return ErrUsernameTaken
		}
		return ErrEmailTaken
	}
	return fmt.Errorf("create user: %w", err)
}

func rollback(tx *sql.Tx, cause error) error {
	if err := tx.Rollback(); err != nil && !errors.Is(err, sql.ErrTxDone) {
		return errors.Join(cause, fmt.Errorf("roll back transaction: %w", err))
	}
	return cause
}
