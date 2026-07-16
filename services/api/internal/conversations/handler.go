package conversations

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"strconv"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/auth"
	"github.com/ewcds12/instant-chat/services/api/internal/httpapi"
)

type conversationService interface {
	CreateDirect(ctx context.Context, userID, contactUserID uint64) (Conversation, bool, error)
	List(ctx context.Context, userID uint64) ([]Conversation, error)
}

// Handler maps conversation HTTP requests to the service.
type Handler struct {
	service conversationService
}

// NewHandler creates the conversation HTTP handler collection.
func NewHandler(service conversationService) *Handler {
	return &Handler{service: service}
}

type createConversationRequest struct {
	ContactUserID string `json:"contact_user_id"`
}

type peerResponse struct {
	ID          string    `json:"id"`
	Username    string    `json:"username"`
	DisplayName string    `json:"display_name"`
	CreatedAt   time.Time `json:"created_at"`
}

type conversationResponse struct {
	ID        string       `json:"id"`
	Kind      string       `json:"kind"`
	Peer      peerResponse `json:"peer"`
	CreatedAt time.Time    `json:"created_at"`
	UpdatedAt time.Time    `json:"updated_at"`
}

// CreateDirect creates or returns the unique direct conversation for a contact.
func (h *Handler) CreateDirect(w http.ResponseWriter, r *http.Request) {
	var body createConversationRequest
	if err := httpapi.DecodeJSON(w, r, &body); err != nil {
		writeInvalidArgument(w, r, "Request body must be a valid JSON object.")
		return
	}
	contactUserID, err := strconv.ParseUint(body.ContactUserID, 10, 64)
	if err != nil || contactUserID == 0 {
		writeInvalidArgument(w, r, "Contact user ID must be a positive integer string.")
		return
	}
	conversation, created, err := h.service.CreateDirect(r.Context(), currentUserID(r), contactUserID)
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	status := http.StatusOK
	if created {
		status = http.StatusCreated
	}
	httpapi.WriteJSON(w, status, responseFromConversation(conversation))
}

// List returns the current user's conversation list.
func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	conversations, err := h.service.List(r.Context(), currentUserID(r))
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	responses := make([]conversationResponse, 0, len(conversations))
	for _, conversation := range conversations {
		responses = append(responses, responseFromConversation(conversation))
	}
	httpapi.WriteJSON(w, http.StatusOK, struct {
		Conversations []conversationResponse `json:"conversations"`
	}{Conversations: responses})
}

func currentUserID(r *http.Request) uint64 {
	user, _ := auth.UserFromContext(r.Context())
	return user.ID
}

func writeServiceError(w http.ResponseWriter, r *http.Request, err error) {
	requestID := httpapi.RequestID(r.Context())
	switch {
	case errors.Is(err, ErrNotContact):
		httpapi.WriteError(w, http.StatusForbidden, "contact_required", "A direct conversation requires an accepted contact.", requestID)
	case errors.Is(err, ErrSelfConversation):
		httpapi.WriteError(w, http.StatusBadRequest, "self_conversation", "You cannot create a conversation with yourself.", requestID)
	default:
		slog.Error("conversation request failed", "request_id", requestID, "error", err)
		httpapi.WriteError(w, http.StatusInternalServerError, "internal_error", "The request could not be completed.", requestID)
	}
}

func writeInvalidArgument(w http.ResponseWriter, r *http.Request, message string) {
	httpapi.WriteError(w, http.StatusBadRequest, "invalid_argument", message, httpapi.RequestID(r.Context()))
}

func responseFromConversation(conversation Conversation) conversationResponse {
	return conversationResponse{
		ID: strconv.FormatUint(conversation.ID, 10), Kind: conversation.Kind,
		Peer: peerResponse{
			ID: strconv.FormatUint(conversation.Peer.ID, 10), Username: conversation.Peer.Username,
			DisplayName: conversation.Peer.DisplayName, CreatedAt: conversation.Peer.CreatedAt.UTC(),
		},
		CreatedAt: conversation.CreatedAt.UTC(), UpdatedAt: conversation.UpdatedAt.UTC(),
	}
}
