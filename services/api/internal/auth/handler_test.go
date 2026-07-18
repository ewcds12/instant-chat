package auth

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/httpapi"
)

type stubAuthService struct {
	session    Session
	loginError error
	accessSeen string
}

func (s *stubAuthService) Register(context.Context, string, string, string) (Session, error) {
	return s.session, nil
}

func (s *stubAuthService) Login(context.Context, string, string) (Session, error) {
	return Session{}, s.loginError
}

func (s *stubAuthService) Refresh(context.Context, string) (Session, error) {
	return s.session, nil
}

func (s *stubAuthService) CurrentUser(_ context.Context, accessToken string) (User, error) {
	s.accessSeen = accessToken
	if accessToken == "" {
		return User{}, ErrInvalidToken
	}
	return s.session.User, nil
}

func (s *stubAuthService) UpdateProfile(context.Context, uint64, ProfileInput) (User, error) {
	return s.session.User, nil
}

func (s *stubAuthService) UpdateAvatar(context.Context, uint64, AvatarUpload) (User, error) {
	return s.session.User, nil
}

func (s *stubAuthService) Avatar(context.Context, uint64) (Avatar, error) {
	return Avatar{}, nil
}

func (s *stubAuthService) Logout(context.Context, string, string) error {
	return nil
}

func TestHandlerRegisterReturnsSession(t *testing.T) {
	createdAt := time.Date(2026, time.July, 15, 12, 0, 0, 0, time.UTC)
	service := &stubAuthService{session: Session{
		User:        User{ID: 7, Username: "retro_user", DisplayName: "Retro User", CreatedAt: createdAt},
		AccessToken: "access", AccessExpiresAt: createdAt.Add(accessTokenTTL),
		RefreshToken: "refresh", RefreshExpiresAt: createdAt.Add(refreshTokenTTL),
	}}
	handler := NewHandler(service)
	request := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", strings.NewReader(
		`{"username":"retro_user","display_name":"Retro User","password":"pw"}`,
	))
	recorder := httptest.NewRecorder()

	httpapi.RequestIDMiddleware(http.HandlerFunc(handler.Register)).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusCreated {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusCreated)
	}
	var response sessionResponse
	if err := json.Unmarshal(recorder.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if response.User.ID != "7" || response.User.Username != "retro_user" || response.AccessToken != "access" {
		t.Fatalf("response = %+v, want user ID and token", response)
	}
}

func TestHandlerLoginReturnsStableCredentialError(t *testing.T) {
	service := &stubAuthService{loginError: ErrInvalidCredentials}
	handler := NewHandler(service)
	request := httptest.NewRequest(http.MethodPost, "/api/v1/auth/login", strings.NewReader(
		`{"username":"retro_user","password":"incorrect password"}`,
	))
	recorder := httptest.NewRecorder()

	httpapi.RequestIDMiddleware(http.HandlerFunc(handler.Login)).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusUnauthorized)
	}
	var response httpapi.ErrorResponse
	if err := json.Unmarshal(recorder.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if response.Error.Code != "invalid_credentials" || response.Error.RequestID == "" {
		t.Fatalf("error response = %+v, want stable code and request ID", response.Error)
	}
}

func TestHandlerCurrentUserRequiresBearerToken(t *testing.T) {
	service := &stubAuthService{}
	handler := NewHandler(service)
	request := httptest.NewRequest(http.MethodGet, "/api/v1/auth/me", nil)
	recorder := httptest.NewRecorder()

	httpapi.RequestIDMiddleware(http.HandlerFunc(handler.CurrentUser)).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusUnauthorized)
	}
	if service.accessSeen != "" {
		t.Fatalf("access token = %q, want empty", service.accessSeen)
	}
}

func TestHandlerRejectsUnknownJSONField(t *testing.T) {
	handler := NewHandler(&stubAuthService{loginError: errors.New("must not be called")})
	request := httptest.NewRequest(http.MethodPost, "/api/v1/auth/login", strings.NewReader(
		`{"username":"retro_user","password":"password","extra":true}`,
	))
	recorder := httptest.NewRecorder()

	httpapi.RequestIDMiddleware(http.HandlerFunc(handler.Login)).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusBadRequest)
	}
}
