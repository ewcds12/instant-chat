package posts

import (
	"context"
	"errors"
	"io"
	"log/slog"
	"net/http"
	"strconv"

	"github.com/ewcds12/instant-chat/services/api/internal/auth"
	"github.com/ewcds12/instant-chat/services/api/internal/httpapi"
)

type postService interface {
	Create(context.Context, uint64, string, []ImageUpload) (Post, error)
	List(context.Context, uint64, *uint64, int) (Page, error)
	Image(context.Context, uint64, uint64) (ImageFile, error)
	Delete(context.Context, uint64, uint64) error
	Report(context.Context, uint64, uint64, string) error
	Block(context.Context, uint64, uint64) error
	Unblock(context.Context, uint64, uint64) error
	ListBlocked(context.Context, uint64) ([]BlockedUser, error)
}

// Handler maps public post HTTP requests to the service.
type Handler struct {
	service postService
}

// NewHandler creates the public post HTTP handler collection.
func NewHandler(service postService) *Handler { return &Handler{service: service} }

// Create persists one text and photo post.
func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
	body, images, cleanup, ok := postUpload(w, r)
	if !ok {
		return
	}
	defer cleanup()
	post, err := h.service.Create(r.Context(), currentUserID(r), body, images)
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	httpapi.WriteJSON(w, http.StatusCreated, responseFromPost(post))
}

// List returns one descending global feed page.
func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	before, ok := optionalBefore(w, r)
	if !ok {
		return
	}
	limit, ok := optionalLimit(w, r)
	if !ok {
		return
	}
	page, err := h.service.List(r.Context(), currentUserID(r), before, limit)
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	posts := make([]postResponse, 0, len(page.Posts))
	for _, post := range page.Posts {
		posts = append(posts, responseFromPost(post))
	}
	var next *string
	if page.NextCursor != nil {
		value := strconv.FormatUint(*page.NextCursor, 10)
		next = &value
	}
	httpapi.WriteJSON(w, http.StatusOK, struct {
		Posts      []postResponse `json:"posts"`
		NextCursor *string        `json:"next_cursor"`
	}{Posts: posts, NextCursor: next})
}

// Image streams one authorized private post image.
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
	defer image.Content.Close()
	w.Header().Set("Content-Type", image.ContentType)
	w.Header().Set("Content-Length", strconv.FormatUint(uint64(image.ByteSize), 10))
	w.WriteHeader(http.StatusOK)
	if _, err := io.Copy(w, image.Content); err != nil {
		slog.Warn("stream post image", "request_id", httpapi.RequestID(r.Context()), "error", err)
	}
}

// Delete removes one post owned by the current user.
func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	postID, ok := positivePathID(w, r, "post_id", "Post ID")
	if !ok {
		return
	}
	if err := h.service.Delete(r.Context(), currentUserID(r), postID); err != nil {
		writeServiceError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

type reportRequest struct {
	Reason string `json:"reason"`
}

// Report records one report from the current user.
func (h *Handler) Report(w http.ResponseWriter, r *http.Request) {
	postID, ok := positivePathID(w, r, "post_id", "Post ID")
	if !ok {
		return
	}
	var body reportRequest
	if err := httpapi.DecodeJSON(w, r, &body); err != nil {
		writeInvalidArgument(w, r, "Request body must be a valid JSON object.")
		return
	}
	if err := h.service.Report(r.Context(), currentUserID(r), postID, body.Reason); err != nil {
		writeServiceError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// Block hides one user's posts from the current user's feed.
func (h *Handler) Block(w http.ResponseWriter, r *http.Request) {
	h.mutateBlock(w, r, h.service.Block)
}

// Unblock restores one user's posts to the current user's feed.
func (h *Handler) Unblock(w http.ResponseWriter, r *http.Request) {
	h.mutateBlock(w, r, h.service.Unblock)
}

func (h *Handler) mutateBlock(
	w http.ResponseWriter,
	r *http.Request,
	action func(context.Context, uint64, uint64) error,
) {
	userID, ok := positivePathID(w, r, "user_id", "User ID")
	if !ok {
		return
	}
	if err := action(r.Context(), currentUserID(r), userID); err != nil {
		writeServiceError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ListBlocked returns users hidden from the current user's feed.
func (h *Handler) ListBlocked(w http.ResponseWriter, r *http.Request) {
	users, err := h.service.ListBlocked(r.Context(), currentUserID(r))
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	responses := make([]authorResponse, 0, len(users))
	for _, user := range users {
		responses = append(responses, responseFromAuthor(user.Author))
	}
	httpapi.WriteJSON(w, http.StatusOK, struct {
		Users []authorResponse `json:"users"`
	}{Users: responses})
}

func currentUserID(r *http.Request) uint64 {
	user, _ := auth.UserFromContext(r.Context())
	return user.ID
}

func optionalBefore(w http.ResponseWriter, r *http.Request) (*uint64, bool) {
	raw := r.URL.Query().Get("before")
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
		writeInvalidArgument(w, r, "Limit must be between 1 and 50.")
		return 0, false
	}
	return value, true
}

func positivePathID(w http.ResponseWriter, r *http.Request, name, label string) (uint64, bool) {
	value, err := strconv.ParseUint(r.PathValue(name), 10, 64)
	if err != nil || value == 0 {
		writeInvalidArgument(w, r, label+" must be a positive integer string.")
		return 0, false
	}
	return value, true
}

func writeServiceError(w http.ResponseWriter, r *http.Request, err error) {
	requestID := httpapi.RequestID(r.Context())
	var inputError *InputError
	switch {
	case errors.As(err, &inputError):
		httpapi.WriteError(w, http.StatusBadRequest, "invalid_argument", inputError.Message, requestID)
	case errors.Is(err, ErrPostNotFound):
		httpapi.WriteError(w, http.StatusNotFound, "post_not_found", "Post was not found.", requestID)
	case errors.Is(err, ErrPostImageNotFound):
		httpapi.WriteError(w, http.StatusNotFound, "post_image_not_found", "Post image was not found.", requestID)
	case errors.Is(err, ErrUserNotFound):
		httpapi.WriteError(w, http.StatusNotFound, "user_not_found", "User was not found.", requestID)
	default:
		slog.Error("post request failed", "request_id", requestID, "error", err)
		httpapi.WriteError(
			w, http.StatusInternalServerError, "internal_error",
			"The request could not be completed.", requestID,
		)
	}
}

func writeInvalidArgument(w http.ResponseWriter, r *http.Request, message string) {
	httpapi.WriteError(
		w, http.StatusBadRequest, "invalid_argument", message,
		httpapi.RequestID(r.Context()),
	)
}
