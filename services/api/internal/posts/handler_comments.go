package posts

import (
	"net/http"
	"strconv"

	"github.com/ewcds12/instant-chat/services/api/internal/httpapi"
)

type commentRequest struct {
	Body string `json:"body"`
}

// CreateComment persists one text comment.
func (h *Handler) CreateComment(w http.ResponseWriter, r *http.Request) {
	postID, ok := positivePathID(w, r, "post_id", "Post ID")
	if !ok {
		return
	}
	var body commentRequest
	if err := httpapi.DecodeJSON(w, r, &body); err != nil {
		writeInvalidArgument(w, r, "Request body must be a valid JSON object.")
		return
	}
	comment, err := h.service.CreateComment(r.Context(), currentUserID(r), postID, body.Body)
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	httpapi.WriteJSON(w, http.StatusCreated, responseFromComment(comment))
}

// ListComments returns one descending comment page.
func (h *Handler) ListComments(w http.ResponseWriter, r *http.Request) {
	postID, ok := positivePathID(w, r, "post_id", "Post ID")
	if !ok {
		return
	}
	before, ok := optionalBefore(w, r)
	if !ok {
		return
	}
	limit, ok := optionalLimit(w, r)
	if !ok {
		return
	}
	page, err := h.service.ListComments(r.Context(), postID, before, limit)
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	comments := make([]commentResponse, 0, len(page.Comments))
	for _, comment := range page.Comments {
		comments = append(comments, responseFromComment(comment))
	}
	var next *string
	if page.NextCursor != nil {
		value := strconv.FormatUint(*page.NextCursor, 10)
		next = &value
	}
	httpapi.WriteJSON(w, http.StatusOK, struct {
		Comments   []commentResponse `json:"comments"`
		NextCursor *string           `json:"next_cursor"`
	}{Comments: comments, NextCursor: next})
}

// DeleteComment removes one comment owned by the current user.
func (h *Handler) DeleteComment(w http.ResponseWriter, r *http.Request) {
	postID, ok := positivePathID(w, r, "post_id", "Post ID")
	if !ok {
		return
	}
	commentID, ok := positivePathID(w, r, "comment_id", "Comment ID")
	if !ok {
		return
	}
	if err := h.service.DeleteComment(
		r.Context(), currentUserID(r), postID, commentID,
	); err != nil {
		writeServiceError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
