package contacts

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

type contactService interface {
	SearchUser(ctx context.Context, username string) (PublicUser, error)
	SendRequest(ctx context.Context, requesterID uint64, username string) (Request, error)
	ListRequests(ctx context.Context, userID uint64) (RequestLists, error)
	AcceptRequest(ctx context.Context, userID, requestID uint64) (Contact, error)
	RejectRequest(ctx context.Context, userID, requestID uint64) error
	ListContacts(ctx context.Context, userID uint64) ([]Contact, error)
	RemoveContact(ctx context.Context, userID, contactUserID uint64) error
}

// Handler maps contact HTTP requests to the service.
type Handler struct {
	service contactService
}

// NewHandler creates the contact HTTP handler collection.
func NewHandler(service contactService) *Handler {
	return &Handler{service: service}
}

type sendRequestBody struct {
	Username string `json:"username"`
}

type publicUserResponse struct {
	ID          string    `json:"id"`
	Username    string    `json:"username"`
	DisplayName string    `json:"display_name"`
	AvatarURL   *string   `json:"avatar_url"`
	CreatedAt   time.Time `json:"created_at"`
}

type requestResponse struct {
	ID        string             `json:"id"`
	User      publicUserResponse `json:"user"`
	CreatedAt time.Time          `json:"created_at"`
	UpdatedAt time.Time          `json:"updated_at"`
}

type contactResponse struct {
	RelationshipID string             `json:"relationship_id"`
	User           publicUserResponse `json:"user"`
	ConnectedAt    time.Time          `json:"connected_at"`
}

// SearchUser returns one exact username match.
func (h *Handler) SearchUser(w http.ResponseWriter, r *http.Request) {
	user, err := h.service.SearchUser(r.Context(), r.URL.Query().Get("username"))
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	httpapi.WriteJSON(w, http.StatusOK, struct {
		User publicUserResponse `json:"user"`
	}{User: responseFromUser(user)})
}

// SendRequest creates a pending contact request.
func (h *Handler) SendRequest(w http.ResponseWriter, r *http.Request) {
	var body sendRequestBody
	if err := httpapi.DecodeJSON(w, r, &body); err != nil {
		writeInvalidArgument(w, r, "Request body must be a valid JSON object.")
		return
	}
	request, err := h.service.SendRequest(r.Context(), currentUserID(r), body.Username)
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	httpapi.WriteJSON(w, http.StatusCreated, responseFromRequest(request))
}

// ListRequests returns incoming and outgoing pending requests.
func (h *Handler) ListRequests(w http.ResponseWriter, r *http.Request) {
	lists, err := h.service.ListRequests(r.Context(), currentUserID(r))
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	httpapi.WriteJSON(w, http.StatusOK, struct {
		Incoming []requestResponse `json:"incoming"`
		Outgoing []requestResponse `json:"outgoing"`
	}{Incoming: responsesFromRequests(lists.Incoming), Outgoing: responsesFromRequests(lists.Outgoing)})
}

// AcceptRequest accepts an incoming contact request.
func (h *Handler) AcceptRequest(w http.ResponseWriter, r *http.Request) {
	requestID, ok := pathID(w, r, "request_id")
	if !ok {
		return
	}
	contact, err := h.service.AcceptRequest(r.Context(), currentUserID(r), requestID)
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	httpapi.WriteJSON(w, http.StatusOK, responseFromContact(contact))
}

// RejectRequest rejects an incoming contact request.
func (h *Handler) RejectRequest(w http.ResponseWriter, r *http.Request) {
	requestID, ok := pathID(w, r, "request_id")
	if !ok {
		return
	}
	if err := h.service.RejectRequest(r.Context(), currentUserID(r), requestID); err != nil {
		writeServiceError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ListContacts returns accepted contacts.
func (h *Handler) ListContacts(w http.ResponseWriter, r *http.Request) {
	contacts, err := h.service.ListContacts(r.Context(), currentUserID(r))
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	responses := make([]contactResponse, 0, len(contacts))
	for _, contact := range contacts {
		responses = append(responses, responseFromContact(contact))
	}
	httpapi.WriteJSON(w, http.StatusOK, struct {
		Contacts []contactResponse `json:"contacts"`
	}{Contacts: responses})
}

// RemoveContact removes an accepted contact.
func (h *Handler) RemoveContact(w http.ResponseWriter, r *http.Request) {
	contactUserID, ok := pathID(w, r, "user_id")
	if !ok {
		return
	}
	if err := h.service.RemoveContact(r.Context(), currentUserID(r), contactUserID); err != nil {
		writeServiceError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func currentUserID(r *http.Request) uint64 {
	user, _ := auth.UserFromContext(r.Context())
	return user.ID
}

func pathID(w http.ResponseWriter, r *http.Request, name string) (uint64, bool) {
	value, err := strconv.ParseUint(r.PathValue(name), 10, 64)
	if err != nil || value == 0 {
		writeInvalidArgument(w, r, "Resource ID must be a positive integer.")
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
	case errors.Is(err, ErrUserNotFound):
		httpapi.WriteError(w, http.StatusNotFound, "user_not_found", "No account uses that username.", requestID)
	case errors.Is(err, ErrSelfRequest):
		httpapi.WriteError(w, http.StatusBadRequest, "self_contact", "You cannot add yourself as a contact.", requestID)
	case errors.Is(err, ErrRequestExists):
		httpapi.WriteError(w, http.StatusConflict, "request_exists", "A contact request is already pending.", requestID)
	case errors.Is(err, ErrAlreadyContacts):
		httpapi.WriteError(w, http.StatusConflict, "already_contacts", "This account is already a contact.", requestID)
	case errors.Is(err, ErrRequestNotFound):
		httpapi.WriteError(w, http.StatusNotFound, "request_not_found", "The contact request was not found.", requestID)
	case errors.Is(err, ErrContactNotFound):
		httpapi.WriteError(w, http.StatusNotFound, "contact_not_found", "The contact was not found.", requestID)
	default:
		slog.Error("contact request failed", "request_id", requestID, "error", err)
		httpapi.WriteError(w, http.StatusInternalServerError, "internal_error", "The request could not be completed.", requestID)
	}
}

func writeInvalidArgument(w http.ResponseWriter, r *http.Request, message string) {
	httpapi.WriteError(w, http.StatusBadRequest, "invalid_argument", message, httpapi.RequestID(r.Context()))
}

func responseFromUser(user PublicUser) publicUserResponse {
	response := publicUserResponse{
		ID: strconv.FormatUint(user.ID, 10), Username: user.Username,
		DisplayName: user.DisplayName, CreatedAt: user.CreatedAt.UTC(),
	}
	if user.HasAvatar {
		url := "/api/v1/users/" + response.ID + "/avatar"
		response.AvatarURL = &url
	}
	return response
}

func responseFromRequest(request Request) requestResponse {
	return requestResponse{
		ID: strconv.FormatUint(request.ID, 10), User: responseFromUser(request.User),
		CreatedAt: request.CreatedAt.UTC(), UpdatedAt: request.UpdatedAt.UTC(),
	}
}

func responsesFromRequests(requests []Request) []requestResponse {
	responses := make([]requestResponse, 0, len(requests))
	for _, request := range requests {
		responses = append(responses, responseFromRequest(request))
	}
	return responses
}

func responseFromContact(contact Contact) contactResponse {
	return contactResponse{
		RelationshipID: strconv.FormatUint(contact.RelationshipID, 10),
		User:           responseFromUser(contact.User), ConnectedAt: contact.ConnectedAt.UTC(),
	}
}
