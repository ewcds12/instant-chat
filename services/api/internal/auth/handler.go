package auth

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/httpapi"
)

type authService interface {
	Register(ctx context.Context, username, displayName, password string) (Session, error)
	Login(ctx context.Context, username, password string) (Session, error)
	Refresh(ctx context.Context, refreshToken string) (Session, error)
	CurrentUser(ctx context.Context, accessToken string) (User, error)
	Logout(ctx context.Context, accessToken, refreshToken string) error
}

// Handler maps authentication HTTP requests to the service.
type Handler struct {
	service authService
}

// NewHandler creates the authentication HTTP handler collection.
func NewHandler(service authService) *Handler {
	return &Handler{service: service}
}

type registerRequest struct {
	Username    string `json:"username"`
	DisplayName string `json:"display_name"`
	Password    string `json:"password"`
}

type loginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type refreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type userResponse struct {
	ID          string    `json:"id"`
	Username    string    `json:"username"`
	DisplayName string    `json:"display_name"`
	CreatedAt   time.Time `json:"created_at"`
}

type sessionResponse struct {
	User             userResponse `json:"user"`
	AccessToken      string       `json:"access_token"`
	AccessExpiresAt  time.Time    `json:"access_expires_at"`
	RefreshToken     string       `json:"refresh_token"`
	RefreshExpiresAt time.Time    `json:"refresh_expires_at"`
}

// Register handles account creation.
func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	var request registerRequest
	if err := httpapi.DecodeJSON(w, r, &request); err != nil {
		writeInvalidJSON(w, r)
		return
	}
	session, err := h.service.Register(r.Context(), request.Username, request.DisplayName, request.Password)
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	httpapi.WriteJSON(w, http.StatusCreated, responseFromSession(session))
}

// Login handles credential authentication.
func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var request loginRequest
	if err := httpapi.DecodeJSON(w, r, &request); err != nil {
		writeInvalidJSON(w, r)
		return
	}
	session, err := h.service.Login(r.Context(), request.Username, request.Password)
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	httpapi.WriteJSON(w, http.StatusOK, responseFromSession(session))
}

// Refresh handles one-time refresh token rotation.
func (h *Handler) Refresh(w http.ResponseWriter, r *http.Request) {
	var request refreshRequest
	if err := httpapi.DecodeJSON(w, r, &request); err != nil {
		writeInvalidJSON(w, r)
		return
	}
	session, err := h.service.Refresh(r.Context(), request.RefreshToken)
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	httpapi.WriteJSON(w, http.StatusOK, responseFromSession(session))
}

// CurrentUser returns the account associated with an access token.
func (h *Handler) CurrentUser(w http.ResponseWriter, r *http.Request) {
	user, err := h.service.CurrentUser(r.Context(), bearerToken(r))
	if err != nil {
		writeServiceError(w, r, err)
		return
	}
	httpapi.WriteJSON(w, http.StatusOK, struct {
		User userResponse `json:"user"`
	}{User: responseFromUser(user)})
}

// Logout revokes the supplied access and refresh token pair.
func (h *Handler) Logout(w http.ResponseWriter, r *http.Request) {
	var request refreshRequest
	if err := httpapi.DecodeJSON(w, r, &request); err != nil {
		writeInvalidJSON(w, r)
		return
	}
	if err := h.service.Logout(r.Context(), bearerToken(r), request.RefreshToken); err != nil {
		writeServiceError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func bearerToken(r *http.Request) string {
	const prefix = "Bearer "
	value := r.Header.Get("Authorization")
	if !strings.HasPrefix(value, prefix) {
		return ""
	}
	return strings.TrimSpace(strings.TrimPrefix(value, prefix))
}

func writeInvalidJSON(w http.ResponseWriter, r *http.Request) {
	httpapi.WriteError(
		w, http.StatusBadRequest, "invalid_argument",
		"Request body must be a valid JSON object.", httpapi.RequestID(r.Context()),
	)
}

func writeServiceError(w http.ResponseWriter, r *http.Request, err error) {
	requestID := httpapi.RequestID(r.Context())
	var inputError *InputError
	switch {
	case errors.As(err, &inputError):
		httpapi.WriteError(w, http.StatusBadRequest, "invalid_argument", inputError.Message, requestID)
	case errors.Is(err, ErrUsernameTaken):
		httpapi.WriteError(w, http.StatusConflict, "username_taken", "An account already uses that username.", requestID)
	case errors.Is(err, ErrInvalidCredentials):
		httpapi.WriteError(w, http.StatusUnauthorized, "invalid_credentials", "Username or password is incorrect.", requestID)
	case errors.Is(err, ErrInvalidToken):
		httpapi.WriteError(w, http.StatusUnauthorized, "invalid_token", "The session is missing, expired, or revoked.", requestID)
	default:
		slog.Error("authentication request failed", "request_id", requestID, "error", err)
		httpapi.WriteError(w, http.StatusInternalServerError, "internal_error", "The request could not be completed.", requestID)
	}
}

func responseFromSession(session Session) sessionResponse {
	return sessionResponse{
		User: responseFromUser(session.User), AccessToken: session.AccessToken,
		AccessExpiresAt: session.AccessExpiresAt, RefreshToken: session.RefreshToken,
		RefreshExpiresAt: session.RefreshExpiresAt,
	}
}

func responseFromUser(user User) userResponse {
	return userResponse{
		ID: strconv.FormatUint(user.ID, 10), Username: user.Username,
		DisplayName: user.DisplayName, CreatedAt: user.CreatedAt.UTC(),
	}
}
