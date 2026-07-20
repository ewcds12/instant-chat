package realtime

import (
	"context"
	"encoding/json"
	"log/slog"
	"sync"

	"github.com/ewcds12/instant-chat/services/api/internal/auth"
	"github.com/ewcds12/instant-chat/services/api/internal/messages"
)

const clientQueueSize = 32

type client struct {
	userID uint64
	send   chan []byte
	cancel context.CancelFunc
}

// PublishProfile sends a changed public identity to connected conversation peers.
func (h *Hub) PublishProfile(ctx context.Context, user auth.User) {
	userIDs, err := h.repository.ListProfileRecipientIDs(ctx, user.ID)
	if err != nil {
		slog.Error("profile recipients lookup failed", "user_id", user.ID, "error", err)
		return
	}
	payload, err := json.Marshal(profileUpdatedEvent(user))
	if err != nil {
		slog.Error("profile event encoding failed", "user_id", user.ID, "error", err)
		return
	}
	for _, userID := range userIDs {
		h.publishToUser(userID, payload)
	}
}

// Hub tracks authenticated connections and publishes persisted messages.
type Hub struct {
	repository memberRepository
	mu         sync.RWMutex
	clients    map[uint64]map[*client]struct{}
	closed     bool
}

// NewHub creates an empty realtime connection registry.
func NewHub(repository memberRepository) *Hub {
	return &Hub{
		repository: repository,
		clients:    make(map[uint64]map[*client]struct{}),
	}
}

// PublishMessage sends a new persisted message to every conversation member.
func (h *Hub) PublishMessage(ctx context.Context, message messages.Message) {
	userIDs, err := h.repository.ListConversationMemberIDs(ctx, message.ConversationID)
	if err != nil {
		slog.Error(
			"realtime recipient lookup failed",
			"conversation_id", message.ConversationID,
			"message_id", message.ID,
			"error", err,
		)
		return
	}
	payload, err := json.Marshal(messageCreatedEvent(message))
	if err != nil {
		slog.Error("realtime event encoding failed", "message_id", message.ID, "error", err)
		return
	}
	for _, userID := range userIDs {
		h.publishToUser(userID, payload)
	}
}

// PublishRecall sends a recalled-message notice to every connected conversation member.
func (h *Hub) PublishRecall(ctx context.Context, recall messages.Recall) {
	userIDs, err := h.repository.ListConversationMemberIDs(ctx, recall.ConversationID)
	if err != nil {
		slog.Error(
			"realtime recall recipient lookup failed",
			"conversation_id", recall.ConversationID,
			"message_id", recall.MessageID,
			"error", err,
		)
		return
	}
	payload, err := json.Marshal(messageRecalledEvent(recall))
	if err != nil {
		slog.Error("realtime recall event encoding failed", "message_id", recall.MessageID, "error", err)
		return
	}
	for _, userID := range userIDs {
		h.publishToUser(userID, payload)
	}
}

// Close disconnects every client during server shutdown.
func (h *Hub) Close() {
	h.mu.Lock()
	h.closed = true
	clients := make([]*client, 0)
	for _, userClients := range h.clients {
		for connected := range userClients {
			clients = append(clients, connected)
		}
	}
	h.mu.Unlock()
	for _, connected := range clients {
		connected.cancel()
	}
}

func (h *Hub) add(userID uint64, cancel context.CancelFunc) *client {
	connected := &client{
		userID: userID,
		send:   make(chan []byte, clientQueueSize),
		cancel: cancel,
	}
	h.mu.Lock()
	if h.closed {
		h.mu.Unlock()
		cancel()
		return nil
	}
	if h.clients[userID] == nil {
		h.clients[userID] = make(map[*client]struct{})
	}
	h.clients[userID][connected] = struct{}{}
	h.mu.Unlock()
	return connected
}

func (h *Hub) remove(connected *client) {
	h.mu.Lock()
	delete(h.clients[connected.userID], connected)
	if len(h.clients[connected.userID]) == 0 {
		delete(h.clients, connected.userID)
	}
	h.mu.Unlock()
}

func (h *Hub) publishToUser(userID uint64, payload []byte) {
	h.mu.RLock()
	clients := make([]*client, 0, len(h.clients[userID]))
	for connected := range h.clients[userID] {
		clients = append(clients, connected)
	}
	h.mu.RUnlock()
	for _, connected := range clients {
		select {
		case connected.send <- payload:
		default:
			connected.cancel()
		}
	}
}
