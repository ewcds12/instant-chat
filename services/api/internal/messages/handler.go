package messages

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"strconv"

	"github.com/ewcds12/instant-chat/services/api/internal/auth"
	"github.com/ewcds12/instant-chat/services/api/internal/httpapi"
)

type messageService interface {
	Send(context.Context, uint64, uint64, string, string) (Message, bool, error)
	SendImage(context.Context, uint64, uint64, string, ImageUpload) (Message, bool, error)
	SendFile(context.Context, uint64, uint64, string, FileUpload) (Message, bool, error)
	Image(context.Context, uint64, uint64) (ImageFile, error)
	File(context.Context, uint64, uint64) (MessageFile, error)
	List(context.Context, uint64, uint64, *uint64, *uint64, int) (Page, error)
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

// SendImage persists one direct image message.
func (h *Handler) SendImage(w http.ResponseWriter, r *http.Request) {
	conversationID, ok := conversationID(w, r)
	if !ok {
		return
	}
	upload, clientMessageID, ok := imageUpload(w, r)
	if !ok {
		return
	}
	message, created, err := h.service.SendImage(
		r.Context(), currentUserID(r), conversationID, clientMessageID, upload,
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

// SendFile persists one direct file message.
func (h *Handler) SendFile(w http.ResponseWriter, r *http.Request) {
	conversationID, ok := conversationID(w, r)
	if !ok {
		return
	}
	upload, clientMessageID, ok := fileUpload(w, r)
	if !ok {
		return
	}
	message, created, err := h.service.SendFile(
		r.Context(), currentUserID(r), conversationID, clientMessageID, upload,
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

// Image returns one image attachment for an authorized conversation member.
func (h *Handler) Image(w http.ResponseWriter, r *http.Request) {
	imageID, ok := positivePathID(w, r, "image_id", "Image ID")
	if !ok {
		return
	}
	image, err := h.service.Image(r.Context(), currentUserID(r), imageID)
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	w.Header().Set("Cache-Control", "private, max-age=60")
	w.Header().Set("Content-Disposition", "inline")
	w.Header().Set("Content-Length", strconv.FormatUint(uint64(image.ByteSize), 10))
	w.Header().Set("Content-Type", image.ContentType)
	w.Header().Set("X-Content-Type-Options", "nosniff")
	if _, err := w.Write(image.Data); err != nil {
		slog.Debug("write message image failed", "request_id", httpapi.RequestID(r.Context()), "error", err)
	}
}

// File returns one file attachment for an authorized conversation member.
func (h *Handler) File(w http.ResponseWriter, r *http.Request) {
	fileID, ok := positivePathID(w, r, "file_id", "File ID")
	if !ok {
		return
	}
	file, err := h.service.File(r.Context(), currentUserID(r), fileID)
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	w.Header().Set("Cache-Control", "private, max-age=60")
	w.Header().Set("Content-Disposition", attachmentDisposition(file.Filename))
	w.Header().Set("Content-Length", strconv.FormatUint(uint64(file.ByteSize), 10))
	w.Header().Set("Content-Type", file.ContentType)
	w.Header().Set("X-Content-Type-Options", "nosniff")
	if _, err := w.Write(file.Data); err != nil {
		slog.Debug("write message file failed", "request_id", httpapi.RequestID(r.Context()), "error", err)
	}
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
	after, ok := optionalSequence(w, r, "after")
	if !ok {
		return
	}
	if before != nil && after != nil {
		writeInvalidArgument(w, r, "Before and after cannot be used together.")
		return
	}
	limit, ok := optionalLimit(w, r)
	if !ok {
		return
	}
	page, err := h.service.List(
		r.Context(), currentUserID(r), conversationID, before, after, limit,
	)
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

func optionalSequence(w http.ResponseWriter, r *http.Request, name string) (*uint64, bool) {
	raw := r.URL.Query().Get(name)
	if raw == "" {
		return nil, true
	}
	value, err := strconv.ParseUint(raw, 10, 64)
	if err != nil {
		writeInvalidArgument(w, r, "After cursor must be a nonnegative integer string.")
		return nil, false
	}
	return &value, true
}

func conversationID(w http.ResponseWriter, r *http.Request) (uint64, bool) {
	return positivePathID(w, r, "conversation_id", "Conversation ID")
}

func positivePathID(w http.ResponseWriter, r *http.Request, name, label string) (uint64, bool) {
	value, err := strconv.ParseUint(r.PathValue(name), 10, 64)
	if err != nil || value == 0 {
		writeInvalidArgument(w, r, label+" must be a positive integer string.")
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
	case errors.Is(err, ErrImageNotFound):
		httpapi.WriteError(w, http.StatusNotFound, "image_not_found", "Image was not found.", requestID)
	case errors.Is(err, ErrFileNotFound):
		httpapi.WriteError(w, http.StatusNotFound, "file_not_found", "File was not found.", requestID)
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
