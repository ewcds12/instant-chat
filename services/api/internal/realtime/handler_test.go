package realtime

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/coder/websocket"
	"github.com/coder/websocket/wsjson"

	"github.com/ewcds12/instant-chat/services/api/internal/auth"
	"github.com/ewcds12/instant-chat/services/api/internal/messages"
)

type fakeMemberRepository struct {
	userIDs []uint64
}

func (f fakeMemberRepository) ListConversationMemberIDs(
	context.Context,
	uint64,
) ([]uint64, error) {
	return f.userIDs, nil
}

func (f fakeMemberRepository) ListProfileRecipientIDs(context.Context, uint64) ([]uint64, error) {
	return f.userIDs, nil
}

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
func (stubAuthService) Logout(context.Context, string, string) error {
	return nil
}

func TestHandlerDeliversMessageCreatedToConversationMember(t *testing.T) {
	hub := NewHub(fakeMemberRepository{userIDs: []uint64{7, 8}})
	authHandler := auth.NewHandler(stubAuthService{})
	server := httptest.NewServer(authHandler.RequireUser(http.HandlerFunc(NewHandler(hub).Connect)))
	t.Cleanup(server.Close)

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	connection, _, err := websocket.Dial(ctx, websocketURL(server.URL), &websocket.DialOptions{
		HTTPHeader: http.Header{"Authorization": []string{"Bearer access"}},
	})
	if err != nil {
		t.Fatalf("Dial() error = %v", err)
	}
	t.Cleanup(func() {
		_ = connection.Close(websocket.StatusNormalClosure, "")
	})
	waitForUserConnection(t, hub, 7)

	hub.PublishMessage(ctx, realtimeTestMessage())

	var event eventEnvelope
	if err := wsjson.Read(ctx, connection, &event); err != nil {
		t.Fatalf("Read() error = %v", err)
	}
	if event.Type != "message.created" || event.Version != 1 {
		t.Fatalf("event = %+v", event)
	}
	if event.Payload.Message == nil || event.Payload.Message.ID != "21" || event.Payload.Message.Sequence != "4" {
		t.Fatalf("message payload = %+v", event.Payload.Message)
	}
}

func TestHubDoesNotDeliverToNonMember(t *testing.T) {
	hub := NewHub(fakeMemberRepository{userIDs: []uint64{8}})
	_, cancel := context.WithCancel(context.Background())
	connected := hub.add(7, cancel)
	defer hub.remove(connected)

	hub.PublishMessage(context.Background(), realtimeTestMessage())

	if len(connected.send) != 0 {
		t.Fatalf("queued events = %d, want 0", len(connected.send))
	}
}

func TestHubDeliversProfileUpdateToConversationPeer(t *testing.T) {
	hub := NewHub(fakeMemberRepository{userIDs: []uint64{7, 8}})
	_, cancel := context.WithCancel(context.Background())
	connected := hub.add(8, cancel)
	defer hub.remove(connected)

	hub.PublishProfile(context.Background(), auth.User{
		ID: 7, Username: "retro_user", DisplayName: "Retro User",
		CreatedAt: time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC),
		UpdatedAt: time.Date(2026, 7, 16, 13, 0, 0, 0, time.UTC),
	})

	var event eventEnvelope
	if err := json.Unmarshal(<-connected.send, &event); err != nil {
		t.Fatalf("decode event: %v", err)
	}
	if event.Type != "profile.updated" || event.Payload.User == nil || event.Payload.User.Username != "retro_user" {
		t.Fatalf("event = %+v", event)
	}
}

func TestHubRejectsConnectionsAfterShutdown(t *testing.T) {
	hub := NewHub(fakeMemberRepository{})
	hub.Close()
	_, cancel := context.WithCancel(context.Background())

	if connected := hub.add(7, cancel); connected != nil {
		t.Fatal("connection registered after hub shutdown")
	}
}

func waitForUserConnection(t *testing.T, hub *Hub, userID uint64) {
	t.Helper()
	deadline := time.Now().Add(time.Second)
	for time.Now().Before(deadline) {
		hub.mu.RLock()
		count := len(hub.clients[userID])
		hub.mu.RUnlock()
		if count == 1 {
			return
		}
		time.Sleep(time.Millisecond)
	}
	t.Fatal("realtime client was not registered")
}

func websocketURL(serverURL string) string {
	return "ws" + strings.TrimPrefix(serverURL, "http")
}

func realtimeTestMessage() messages.Message {
	return messages.Message{
		ID:             21,
		ConversationID: 11,
		Sender: messages.Sender{
			ID: 7, Username: "retro_user", DisplayName: "Retro User",
			CreatedAt: time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC),
		},
		ClientMessageID: "0123456789abcdef0123456789abcdef",
		Sequence:        4,
		Body:            "Hello.",
		CreatedAt:       time.Date(2026, 7, 16, 13, 0, 0, 0, time.UTC),
	}
}
