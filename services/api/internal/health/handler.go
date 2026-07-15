// Package health exposes service and database health information.
package health

import (
	"context"
	"encoding/json"
	"net/http"
	"time"
)

const databasePingTimeout = 2 * time.Second

type databasePinger interface {
	PingContext(ctx context.Context) error
}

type handler struct {
	database databasePinger
	now      func() time.Time
}

type response struct {
	Status    string    `json:"status"`
	Service   string    `json:"service"`
	Database  string    `json:"database"`
	CheckedAt time.Time `json:"checked_at"`
}

// NewHandler returns the HTTP health-check handler.
func NewHandler(database databasePinger) http.Handler {
	return newHandler(database, time.Now)
}

func newHandler(database databasePinger, now func() time.Time) http.Handler {
	return &handler{database: database, now: now}
}

func (h *handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), databasePingTimeout)
	defer cancel()

	statusCode := http.StatusOK
	databaseStatus := "healthy"
	serviceStatus := "healthy"
	if err := h.database.PingContext(ctx); err != nil {
		statusCode = http.StatusServiceUnavailable
		databaseStatus = "unavailable"
		serviceStatus = "degraded"
	}

	body, err := json.Marshal(response{
		Status:    serviceStatus,
		Service:   "instant-chat-api",
		Database:  databaseStatus,
		CheckedAt: h.now().UTC(),
	})
	if err != nil {
		http.Error(w, "failed to encode health response", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(statusCode)
	if _, err := w.Write(body); err != nil {
		return
	}
}
