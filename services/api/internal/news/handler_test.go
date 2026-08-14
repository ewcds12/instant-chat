package news

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

type stubDailyService struct {
	brief Brief
	err   error
}

func (s stubDailyService) Daily(context.Context) (Brief, error) {
	return s.brief, s.err
}

func TestHandlerReturnsDailyBrief(t *testing.T) {
	brief := Brief{
		Items:     []Item{{ID: "1", Title: "Headline", Summary: "Summary", Source: "Wikipedia Current Events", URL: "https://example.com"}},
		UpdatedAt: time.Date(2026, time.August, 14, 8, 0, 0, 0, time.UTC),
	}
	recorder := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/api/v1/news/daily", nil)

	NewHandler(stubDailyService{brief: brief}).Daily(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	want := `{"items":[{"id":"1","title":"Headline","summary":"Summary","source":"Wikipedia Current Events","url":"https://example.com"}],"updated_at":"2026-08-14T08:00:00Z"}`
	if recorder.Body.String() != want {
		t.Fatalf("body = %q, want %q", recorder.Body.String(), want)
	}
}

func TestHandlerMapsUpstreamFailure(t *testing.T) {
	recorder := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/api/v1/news/daily", nil)

	NewHandler(stubDailyService{err: errors.New("offline")}).Daily(recorder, request)

	if recorder.Code != http.StatusBadGateway {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
}
