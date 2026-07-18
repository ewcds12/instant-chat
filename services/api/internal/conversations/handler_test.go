package conversations

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

type stubConversationService struct {
	userID         uint64
	contactUserID  uint64
	conversationID uint64
	sequence       uint64
	conversations  []Conversation
}

func (s *stubConversationService) CreateDirect(_ context.Context, userID, contactUserID uint64) (Conversation, bool, error) {
	s.userID = userID
	s.contactUserID = contactUserID
	return Conversation{
		ID: 11, Kind: "direct",
		Peer:      Peer{ID: contactUserID, Username: "other_user", DisplayName: "Other User", CreatedAt: time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC)},
		CreatedAt: time.Date(2026, 7, 16, 13, 0, 0, 0, time.UTC),
		UpdatedAt: time.Date(2026, 7, 16, 13, 0, 0, 0, time.UTC),
	}, true, nil
}

func (s *stubConversationService) List(context.Context, uint64) ([]Conversation, error) {
	return s.conversations, nil
}

func (s *stubConversationService) MarkRead(_ context.Context, userID, conversationID, sequence uint64) error {
	s.userID = userID
	s.conversationID = conversationID
	s.sequence = sequence
	return nil
}

type stubAuthService struct{}

func (stubAuthService) Register(context.Context, string, string, string) (auth.Session, error) {
	return auth.Session{}, nil
}

func TestHandlerMarkReadReturnsNoContent(t *testing.T) {
	service := &stubConversationService{}
	conversationHandler := NewHandler(service)
	authHandler := auth.NewHandler(stubAuthService{})
	handler := httpapi.RequestIDMiddleware(authHandler.RequireUser(http.HandlerFunc(conversationHandler.MarkRead)))
	request := httptest.NewRequest(http.MethodPost, "/api/v1/conversations/11/read", strings.NewReader(`{"sequence":"9"}`))
	request.SetPathValue("conversation_id", "11")
	request.Header.Set("Authorization", "Bearer access")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusNoContent || service.userID != 7 || service.conversationID != 11 || service.sequence != 9 {
		t.Fatalf("status = %d, service = %+v", recorder.Code, service)
	}
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
func (stubAuthService) Logout(context.Context, string, string) error { return nil }

func TestHandlerCreateDirectReturnsCreated(t *testing.T) {
	service := &stubConversationService{}
	conversationHandler := NewHandler(service)
	authHandler := auth.NewHandler(stubAuthService{})
	handler := httpapi.RequestIDMiddleware(authHandler.RequireUser(http.HandlerFunc(conversationHandler.CreateDirect)))
	request := httptest.NewRequest(http.MethodPost, "/api/v1/conversations", strings.NewReader(`{"contact_user_id":"8"}`))
	request.Header.Set("Authorization", "Bearer access")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusCreated || service.userID != 7 || service.contactUserID != 8 {
		t.Fatalf("status = %d, user ID = %d, contact ID = %d", recorder.Code, service.userID, service.contactUserID)
	}
}

func TestHandlerListIncludesLastMessagePreview(t *testing.T) {
	service := &stubConversationService{conversations: []Conversation{{
		ID: 11,
		LastMessage: &LastMessage{
			Sequence: 9,
			Kind:     "text",
			Body:     "See you soon",
		},
	}}}
	conversationHandler := NewHandler(service)
	authHandler := auth.NewHandler(stubAuthService{})
	handler := httpapi.RequestIDMiddleware(authHandler.RequireUser(http.HandlerFunc(conversationHandler.List)))
	request := httptest.NewRequest(http.MethodGet, "/api/v1/conversations", nil)
	request.Header.Set("Authorization", "Bearer access")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	var response struct {
		Conversations []struct {
			LastMessage *lastMessageResponse `json:"last_message"`
		} `json:"conversations"`
	}
	if err := json.NewDecoder(recorder.Body).Decode(&response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if recorder.Code != http.StatusOK || len(response.Conversations) != 1 || response.Conversations[0].LastMessage == nil || response.Conversations[0].LastMessage.Body != "See you soon" {
		t.Fatalf("status = %d, response = %+v", recorder.Code, response)
	}
}
