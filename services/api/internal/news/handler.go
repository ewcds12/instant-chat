package news

import (
	"context"
	"log/slog"
	"net/http"

	"github.com/ewcds12/instant-chat/services/api/internal/httpapi"
)

type dailyService interface {
	Daily(context.Context) (Brief, error)
}

// Handler maps daily news requests to the news service.
type Handler struct {
	service dailyService
}

// NewHandler creates the daily news HTTP handler.
func NewHandler(service dailyService) *Handler {
	return &Handler{service: service}
}

// Daily returns the current cached daily brief.
func (h *Handler) Daily(w http.ResponseWriter, r *http.Request) {
	brief, err := h.service.Daily(r.Context())
	if err != nil {
		requestID := httpapi.RequestID(r.Context())
		slog.Error("daily news request failed", "request_id", requestID, "error", err)
		httpapi.WriteError(
			w,
			http.StatusBadGateway,
			"news_unavailable",
			"Daily news is temporarily unavailable.",
			requestID,
		)
		return
	}
	httpapi.WriteJSON(w, http.StatusOK, brief)
}
