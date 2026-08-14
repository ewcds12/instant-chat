package news

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

var testNow = time.Date(2026, time.August, 14, 8, 30, 0, 0, time.UTC)

func TestDailyParsesAndCachesCurrentEvents(t *testing.T) {
	requests := 0
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requests++
		if r.URL.Path != "/2026/08/14" {
			t.Fatalf("path = %q", r.URL.Path)
		}
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"news":[{"story":"<b>A solar eclipse</b> crosses Europe &amp; Asia.","links":[{"pageid":42,"titles":{"normalized":"Solar eclipse of August 12, 2026"},"content_urls":{"desktop":{"page":"https://en.wikipedia.org/wiki/Solar_eclipse"}}}]}]}`))
	}))
	defer server.Close()

	service := newService(server.Client(), func() time.Time { return testNow }, server.URL)
	first, err := service.Daily(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	second, err := service.Daily(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if requests != 1 {
		t.Fatalf("requests = %d, want 1", requests)
	}
	if len(first.Items) != 1 || first.Items[0].ID != "42" {
		t.Fatalf("items = %+v", first.Items)
	}
	if first.Items[0].Summary != "A solar eclipse crosses Europe & Asia." {
		t.Fatalf("summary = %q", first.Items[0].Summary)
	}
	if second.UpdatedAt != testNow {
		t.Fatalf("updated_at = %v", second.UpdatedAt)
	}
}

func TestDailyUsesStaleCacheWhenRefreshFails(t *testing.T) {
	requests := 0
	now := testNow
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		requests++
		if requests > 1 {
			http.Error(w, "upstream unavailable", http.StatusServiceUnavailable)
			return
		}
		_, _ = w.Write([]byte(`{"news":[{"story":"Story","links":[{"pageid":7,"titles":{"normalized":"Headline"},"content_urls":{"desktop":{"page":"https://en.wikipedia.org/wiki/Headline"}}}]}]}`))
	}))
	defer server.Close()

	service := newService(server.Client(), func() time.Time { return now }, server.URL)
	first, err := service.Daily(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	now = now.Add(cacheDuration)
	stale, err := service.Daily(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if stale.Items[0] != first.Items[0] || requests != 2 {
		t.Fatalf("stale = %+v, requests = %d", stale, requests)
	}
}

func TestSourceURLAllowlist(t *testing.T) {
	if !isAllowedSourceURL("https://en.wikipedia.org/wiki/Current_events") {
		t.Fatal("expected Wikipedia HTTPS URL to be allowed")
	}
	for _, value := range []string{
		"http://en.wikipedia.org/wiki/Current_events",
		"https://example.com/story",
		"https://en.wikipedia.org.example.com/story",
	} {
		if isAllowedSourceURL(value) {
			t.Fatalf("URL %q should not be allowed", value)
		}
	}
}
