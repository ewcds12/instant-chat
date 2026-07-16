package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"io"
	"time"
)

const (
	accessTokenBytes  = 32
	refreshTokenBytes = 48
	accessTokenTTL    = 15 * time.Minute
	refreshTokenTTL   = 30 * 24 * time.Hour
)

type tokenPair struct {
	accessRaw  string
	access     StoredToken
	refreshRaw string
	refresh    StoredToken
}

func newTokenPair(now time.Time) (tokenPair, error) {
	accessRaw, err := randomToken(accessTokenBytes)
	if err != nil {
		return tokenPair{}, err
	}
	refreshRaw, err := randomToken(refreshTokenBytes)
	if err != nil {
		return tokenPair{}, err
	}
	return tokenPair{
		accessRaw: accessRaw,
		access: StoredToken{
			Hash:      hashToken(accessRaw),
			ExpiresAt: now.Add(accessTokenTTL),
		},
		refreshRaw: refreshRaw,
		refresh: StoredToken{
			Hash:      hashToken(refreshRaw),
			ExpiresAt: now.Add(refreshTokenTTL),
		},
	}, nil
}

func randomToken(size int) (string, error) {
	value := make([]byte, size)
	if _, err := io.ReadFull(rand.Reader, value); err != nil {
		return "", fmt.Errorf("read random token: %w", err)
	}
	return base64.RawURLEncoding.EncodeToString(value), nil
}

func hashToken(token string) []byte {
	digest := sha256.Sum256([]byte(token))
	return digest[:]
}

func buildSession(user User, tokens tokenPair) Session {
	return Session{
		User:             user,
		AccessToken:      tokens.accessRaw,
		AccessExpiresAt:  tokens.access.ExpiresAt,
		RefreshToken:     tokens.refreshRaw,
		RefreshExpiresAt: tokens.refresh.ExpiresAt,
	}
}
