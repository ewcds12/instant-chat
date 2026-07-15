package health

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

var fixedTime = time.Date(2026, time.July, 15, 12, 0, 0, 0, time.UTC)

type stubDatabase struct {
	err error
}

func (s stubDatabase) PingContext(context.Context) error {
	return s.err
}

func TestHandlerReportsHealthyDatabase(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/api/v1/health", nil)
	recorder := httptest.NewRecorder()

	newHandler(stubDatabase{}, func() time.Time { return fixedTime }).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status code = %d, want %d", recorder.Code, http.StatusOK)
	}
	want := `{"status":"healthy","service":"instant-chat-api","database":"healthy","checked_at":"2026-07-15T12:00:00Z"}`
	if got := recorder.Body.String(); got != want {
		t.Fatalf("body = %q, want %q", got, want)
	}
}

func TestHandlerReportsUnavailableDatabase(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "/api/v1/health", nil)
	recorder := httptest.NewRecorder()

	newHandler(
		stubDatabase{err: errors.New("database unavailable")},
		func() time.Time { return fixedTime },
	).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusServiceUnavailable {
		t.Fatalf("status code = %d, want %d", recorder.Code, http.StatusServiceUnavailable)
	}
	want := `{"status":"degraded","service":"instant-chat-api","database":"unavailable","checked_at":"2026-07-15T12:00:00Z"}`
	if got := recorder.Body.String(); got != want {
		t.Fatalf("body = %q, want %q", got, want)
	}
}
