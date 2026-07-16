package httpapi

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestIPRateLimiterBlocksRequestsOverLimit(t *testing.T) {
	limiter := NewIPRateLimiter(1, time.Minute)
	next := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})
	handler := RequestIDMiddleware(limiter.Handler(next))

	first := httptest.NewRequest(http.MethodPost, "/login", nil)
	first.RemoteAddr = "192.0.2.1:5000"
	firstRecorder := httptest.NewRecorder()
	handler.ServeHTTP(firstRecorder, first)
	if firstRecorder.Code != http.StatusNoContent {
		t.Fatalf("first status = %d, want %d", firstRecorder.Code, http.StatusNoContent)
	}

	second := httptest.NewRequest(http.MethodPost, "/login", nil)
	second.RemoteAddr = "192.0.2.1:5001"
	secondRecorder := httptest.NewRecorder()
	handler.ServeHTTP(secondRecorder, second)
	if secondRecorder.Code != http.StatusTooManyRequests {
		t.Fatalf("second status = %d, want %d", secondRecorder.Code, http.StatusTooManyRequests)
	}
	if secondRecorder.Header().Get("Retry-After") != "60" {
		t.Fatalf("Retry-After = %q, want %q", secondRecorder.Header().Get("Retry-After"), "60")
	}
}
