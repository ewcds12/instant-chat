package realtime

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"sync"
	"time"

	"github.com/coder/websocket"

	"github.com/ewcds12/instant-chat/services/api/internal/auth"
)

const (
	writeTimeout     = 5 * time.Second
	heartbeatPeriod  = 25 * time.Second
	maxClientMessage = 1024
)

// Handler upgrades authenticated requests and owns each connection lifecycle.
type Handler struct {
	hub *Hub
}

// NewHandler creates the realtime HTTP handler.
func NewHandler(hub *Hub) *Handler {
	return &Handler{hub: hub}
}

// Connect upgrades one authenticated request to a WebSocket connection.
func (h *Handler) Connect(w http.ResponseWriter, r *http.Request) {
	user, ok := auth.UserFromContext(r.Context())
	if !ok {
		http.Error(w, "Authentication is required.", http.StatusUnauthorized)
		return
	}
	connection, err := websocket.Accept(w, r, nil)
	if err != nil {
		slog.Warn("realtime upgrade failed", "error", err)
		return
	}
	connection.SetReadLimit(maxClientMessage)
	ctx, cancel := context.WithCancel(context.Background())
	connected := h.hub.add(user.ID, cancel)
	if connected == nil {
		_ = connection.Close(websocket.StatusGoingAway, "Server is shutting down.")
		return
	}
	defer h.hub.remove(connected)
	defer cancel()

	errors := make(chan error, 2)
	var workers sync.WaitGroup
	workers.Add(2)
	go runRealtimeWorker(&workers, errors, func() error {
		return readClient(ctx, connection)
	})
	go runRealtimeWorker(&workers, errors, func() error {
		return writeClient(ctx, connection, connected.send)
	})

	select {
	case <-ctx.Done():
	case <-errors:
	}
	cancel()
	_ = connection.Close(websocket.StatusNormalClosure, "")
	workers.Wait()
}

func runRealtimeWorker(
	workers *sync.WaitGroup,
	errors chan<- error,
	work func() error,
) {
	defer workers.Done()
	errors <- work()
}

func readClient(ctx context.Context, connection *websocket.Conn) error {
	for {
		_, reader, err := connection.Reader(ctx)
		if err != nil {
			return err
		}
		if _, err := io.Copy(io.Discard, reader); err != nil {
			return err
		}
	}
}

func writeClient(
	ctx context.Context,
	connection *websocket.Conn,
	events <-chan []byte,
) error {
	heartbeat := time.NewTicker(heartbeatPeriod)
	defer heartbeat.Stop()
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case payload := <-events:
			writeCtx, cancel := context.WithTimeout(ctx, writeTimeout)
			err := connection.Write(writeCtx, websocket.MessageText, payload)
			cancel()
			if err != nil {
				return err
			}
		case <-heartbeat.C:
			pingCtx, cancel := context.WithTimeout(ctx, writeTimeout)
			err := connection.Ping(pingCtx)
			cancel()
			if err != nil {
				return err
			}
		}
	}
}
