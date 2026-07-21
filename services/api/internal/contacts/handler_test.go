package contacts

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/auth"
	"github.com/ewcds12/instant-chat/services/api/internal/httpapi"
)

type stubContactService struct {
	requesterID       uint64
	canceledUserID    uint64
	canceledRequestID uint64
}

func (s *stubContactService) SearchUser(context.Context, string) (PublicUser, error) {
	return PublicUser{}, nil
}

func (s *stubContactService) SendRequest(_ context.Context, requesterID uint64, username string) (Request, error) {
	s.requesterID = requesterID
	return Request{
		ID: 9, RequestedByUserID: requesterID,
		User: PublicUser{ID: 8, Username: username, DisplayName: "Other User", CreatedAt: time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)},
	}, nil
}

func (s *stubContactService) ListRequests(context.Context, uint64) (RequestLists, error) {
	return RequestLists{Incoming: []Request{}, Outgoing: []Request{}}, nil
}

func (s *stubContactService) AcceptRequest(context.Context, uint64, uint64) (Contact, error) {
	return Contact{}, nil
}

func (s *stubContactService) RejectRequest(context.Context, uint64, uint64) error { return nil }

func (s *stubContactService) CancelRequest(_ context.Context, userID, requestID uint64) error {
	s.canceledUserID = userID
	s.canceledRequestID = requestID
	return nil
}

func (s *stubContactService) ListContacts(context.Context, uint64) ([]Contact, error) {
	return []Contact{}, nil
}

func (s *stubContactService) RemoveContact(context.Context, uint64, uint64) error { return nil }

type stubAuthService struct{}

func (stubAuthService) Register(context.Context, string, string, string) (auth.Session, error) {
	return auth.Session{}, nil
}
func (stubAuthService) Login(context.Context, string, string) (auth.Session, error) {
	return auth.Session{}, nil
}
func (stubAuthService) Refresh(context.Context, string) (auth.Session, error) {
	return auth.Session{}, nil
}
func (stubAuthService) CurrentUser(context.Context, string) (auth.User, error) {
	return auth.User{ID: 7, Username: "retro_user"}, nil
}
func (stubAuthService) UpdateProfile(context.Context, uint64, auth.ProfileInput) (auth.User, error) {
	return auth.User{}, nil
}
func (stubAuthService) UpdateAvatar(context.Context, uint64, auth.AvatarUpload) (auth.User, error) {
	return auth.User{}, nil
}
func (stubAuthService) Avatar(context.Context, uint64) (auth.Avatar, error) {
	return auth.Avatar{}, nil
}
func (stubAuthService) Logout(context.Context, string, string) error { return nil }

func TestHandlerSendRequestUsesAuthenticatedUser(t *testing.T) {
	service := &stubContactService{}
	contactHandler := NewHandler(service)
	authHandler := auth.NewHandler(stubAuthService{})
	handler := httpapi.RequestIDMiddleware(authHandler.RequireUser(http.HandlerFunc(contactHandler.SendRequest)))
	request := httptest.NewRequest(http.MethodPost, "/api/v1/contact-requests", strings.NewReader(`{"username":"other_user"}`))
	request.Header.Set("Authorization", "Bearer access")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusCreated || service.requesterID != 7 {
		t.Fatalf("status = %d, requester ID = %d", recorder.Code, service.requesterID)
	}
	var response requestResponse
	if err := json.Unmarshal(recorder.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if response.ID != "9" || response.User.Username != "other_user" {
		t.Fatalf("response = %+v", response)
	}
}

func TestHandlerCancelRequestUsesAuthenticatedRequester(t *testing.T) {
	service := &stubContactService{}
	contactHandler := NewHandler(service)
	authHandler := auth.NewHandler(stubAuthService{})
	handler := httpapi.RequestIDMiddleware(authHandler.RequireUser(http.HandlerFunc(contactHandler.CancelRequest)))
	request := httptest.NewRequest(http.MethodPost, "/api/v1/contact-requests/9/cancel", nil)
	request.SetPathValue("request_id", "9")
	request.Header.Set("Authorization", "Bearer access")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusNoContent || service.canceledUserID != 7 || service.canceledRequestID != 9 {
		t.Fatalf("status = %d, user ID = %d, request ID = %d", recorder.Code, service.canceledUserID, service.canceledRequestID)
	}
}
