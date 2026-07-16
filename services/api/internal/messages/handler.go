package messages

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

type messageService interface {
	Send(context.Context, uint64, uint64, string, string) (Message, bool, error)
	List(context.Context, uint64, uint64, *uint64, int) (Page, error)
}

// Handler maps message HTTP requests to the service.
type Handler struct {
	service messageService
}

// NewHandler creates the message HTTP handler collection.
func NewHandler(service messageService) *Handler {
	return &Handler{service: service}
}

type sendRequest struct {
	ClientMessageID string `json:"client_message_id"`
	Body            string `json:"body"`
}

type senderResponse struct {
	ID          string    `json:"id"`
	Username    string    `json:"username"`
	DisplayName string    `json:"display_name"`
	CreatedAt   time.Time `json:"created_at"`
}

type messageResponse struct {
	ID              string         `json:"id"`
	ConversationID  string         `json:"conversation_id"`
	Sender          senderResponse `json:"sender"`
	ClientMessageID string         `json:"client_message_id"`
	Sequence        string         `json:"sequence"`
	Body            string         `json:"body"`
	CreatedAt       time.Time      `json:"created_at"`
}

// Send persists one direct text message.
func (h *Handler) Send(w http.ResponseWriter, r *http.Request) {
	conversationID, ok := conversationID(w, r)
	if !ok {
		return
	}
	var body sendRequest
	if err := httpapi.DecodeJSON(w, r, &body); err != nil {
		writeInvalidArgument(w, r, "Request body must be a valid JSON object.")
		return
	}
	message, created, err := h.service.Send(
		r.Context(), currentUserID(r), conversationID, body.ClientMessageID, body.Body,
	)
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	status := http.StatusOK
	if created {
		status = http.StatusCreated
	}
	httpapi.WriteJSON(w, status, responseFromMessage(message))
}

// List returns one cursor-paginated message-history page.
func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	conversationID, ok := conversationID(w, r)
	if !ok {
		return
	}
	before, ok := optionalPositiveUint(w, r, "before")
	if !ok {
		return
	}
	limit, ok := optionalLimit(w, r)
	if !ok {
		return
	}
	page, err := h.service.List(r.Context(), currentUserID(r), conversationID, before, limit)
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	responses := make([]messageResponse, 0, len(page.Messages))
	for _, message := range page.Messages {
		responses = append(responses, responseFromMessage(message))
	}
	var nextCursor *string
	if page.NextCursor != nil {
		value := strconv.FormatUint(*page.NextCursor, 10)
		nextCursor = &value
	}
	httpapi.WriteJSON(w, http.StatusOK, struct {
		Messages   []messageResponse `json:"messages"`
		NextCursor *string           `json:"next_cursor"`
	}{Messages: responses, NextCursor: nextCursor})
}

func conversationID(w http.ResponseWriter, r *http.Request) (uint64, bool) {
	value, err := strconv.ParseUint(r.PathValue("conversation_id"), 10, 64)
	if err != nil || value == 0 {
		writeInvalidArgument(w, r, "Conversation ID must be a positive integer string.")
		return 0, false
	}
	return value, true
}

func optionalPositiveUint(w http.ResponseWriter, r *http.Request, name string) (*uint64, bool) {
	raw := r.URL.Query().Get(name)
	if raw == "" {
		return nil, true
	}
	value, err := strconv.ParseUint(raw, 10, 64)
	if err != nil || value == 0 {
		writeInvalidArgument(w, r, "Before cursor must be a positive integer string.")
		return nil, false
	}
	return &value, true
}

func optionalLimit(w http.ResponseWriter, r *http.Request) (int, bool) {
	raw := r.URL.Query().Get("limit")
	if raw == "" {
		return 0, true
	}
	value, err := strconv.Atoi(raw)
	if err != nil || value < 1 || value > maximumPageSize {
		writeInvalidArgument(w, r, "Limit must be between 1 and 100.")
		return 0, false
	}
	return value, true
}

func currentUserID(r *http.Request) uint64 {
	user, _ := auth.UserFromContext(r.Context())
	return user.ID
}

func writeServiceError(w http.ResponseWriter, r *http.Request, err error) {
	requestID := httpapi.RequestID(r.Context())
	var inputError *InputError
	switch {
	case errors.As(err, &inputError):
		httpapi.WriteError(w, http.StatusBadRequest, "invalid_argument", inputError.Message, requestID)
	case errors.Is(err, ErrConversationNotFound):
		httpapi.WriteError(w, http.StatusNotFound, "conversation_not_found", "Conversation was not found.", requestID)
	default:
		slog.Error("message request failed", "request_id", requestID, "error", err)
		httpapi.WriteError(
			w, http.StatusInternalServerError, "internal_error",
			"The request could not be completed.", requestID,
		)
	}
}

func writeInvalidArgument(w http.ResponseWriter, r *http.Request, message string) {
	httpapi.WriteError(w, http.StatusBadRequest, "invalid_argument", message, httpapi.RequestID(r.Context()))
}

func responseFromMessage(message Message) messageResponse {
	return messageResponse{
		ID:             strconv.FormatUint(message.ID, 10),
		ConversationID: strconv.FormatUint(message.ConversationID, 10),
		Sender: senderResponse{
			ID:          strconv.FormatUint(message.Sender.ID, 10),
			Username:    message.Sender.Username,
			DisplayName: message.Sender.DisplayName,
			CreatedAt:   message.Sender.CreatedAt.UTC(),
		},
		ClientMessageID: message.ClientMessageID,
		Sequence:        strconv.FormatUint(message.Sequence, 10),
		Body:            message.Body,
		CreatedAt:       message.CreatedAt.UTC(),
	}
}
