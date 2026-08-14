package news

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"html"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"
)

const (
	featuredFeedBaseURL = "https://en.wikipedia.org/api/rest_v1/feed/featured"
	cacheDuration       = 15 * time.Minute
	maximumItems        = 5
)

var errNoNews = errors.New("current-events feed returned no usable news")

// Service fetches and briefly caches the daily news collection.
type Service struct {
	client  *http.Client
	now     func() time.Time
	baseURL string

	mu       sync.RWMutex
	cached   *Brief
	cachedAt time.Time
}

// NewService creates a daily news service backed by Wikimedia's featured feed.
func NewService(client *http.Client) *Service {
	return newService(client, time.Now, featuredFeedBaseURL)
}

func newService(client *http.Client, now func() time.Time, baseURL string) *Service {
	return &Service{client: client, now: now, baseURL: strings.TrimRight(baseURL, "/")}
}

// Daily returns today's source-linked news, using a short shared cache.
func (s *Service) Daily(ctx context.Context) (Brief, error) {
	now := s.now().UTC()
	if brief, ok := s.freshCache(now); ok {
		return brief, nil
	}

	brief, err := s.fetch(ctx, now)
	if err != nil {
		if stale, ok := s.staleCache(); ok {
			return stale, nil
		}
		return Brief{}, err
	}
	s.mu.Lock()
	s.cached = &brief
	s.cachedAt = now
	s.mu.Unlock()
	return cloneBrief(brief), nil
}

func (s *Service) freshCache(now time.Time) (Brief, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if s.cached == nil || now.Sub(s.cachedAt) >= cacheDuration {
		return Brief{}, false
	}
	return cloneBrief(*s.cached), true
}

func (s *Service) staleCache() (Brief, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if s.cached == nil {
		return Brief{}, false
	}
	return cloneBrief(*s.cached), true
}

func (s *Service) fetch(ctx context.Context, now time.Time) (Brief, error) {
	url := fmt.Sprintf("%s/%04d/%02d/%02d", s.baseURL, now.Year(), now.Month(), now.Day())
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return Brief{}, fmt.Errorf("create current-events request: %w", err)
	}
	request.Header.Set("Accept", "application/json")
	request.Header.Set("User-Agent", "InstantChat/1.0")
	response, err := s.client.Do(request)
	if err != nil {
		return Brief{}, fmt.Errorf("fetch current events: %w", err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return Brief{}, fmt.Errorf("fetch current events: unexpected status %d", response.StatusCode)
	}

	var feed featuredFeed
	decoder := json.NewDecoder(response.Body)
	if err := decoder.Decode(&feed); err != nil {
		return Brief{}, fmt.Errorf("decode current events: %w", err)
	}
	items := itemsFromFeed(feed)
	if len(items) == 0 {
		return Brief{}, errNoNews
	}
	return Brief{Items: items, UpdatedAt: now}, nil
}

type featuredFeed struct {
	News []struct {
		Story string `json:"story"`
		Links []struct {
			PageID int64 `json:"pageid"`
			Titles struct {
				Normalized string `json:"normalized"`
			} `json:"titles"`
			ContentURLs struct {
				Desktop struct {
					Page string `json:"page"`
				} `json:"desktop"`
			} `json:"content_urls"`
		} `json:"links"`
	} `json:"news"`
}

func itemsFromFeed(feed featuredFeed) []Item {
	items := make([]Item, 0, maximumItems)
	seen := make(map[string]struct{})
	for _, entry := range feed.News {
		if len(entry.Links) == 0 {
			continue
		}
		link := entry.Links[0]
		title := strings.TrimSpace(link.Titles.Normalized)
		pageURL := strings.TrimSpace(link.ContentURLs.Desktop.Page)
		if link.PageID < 1 || title == "" || !isAllowedSourceURL(pageURL) {
			continue
		}
		if _, exists := seen[pageURL]; exists {
			continue
		}
		summary := plainText(entry.Story)
		if summary == "" {
			continue
		}
		seen[pageURL] = struct{}{}
		items = append(items, Item{
			ID:      strconv.FormatInt(link.PageID, 10),
			Title:   title,
			Summary: summary,
			Source:  "Wikipedia Current Events",
			URL:     pageURL,
		})
		if len(items) == maximumItems {
			break
		}
	}
	return items
}

func isAllowedSourceURL(value string) bool {
	parsed, err := url.Parse(value)
	return err == nil && parsed.Scheme == "https" && parsed.Hostname() == "en.wikipedia.org"
}

func plainText(value string) string {
	var result strings.Builder
	inTag := false
	for _, character := range value {
		switch character {
		case '<':
			inTag = true
		case '>':
			inTag = false
		default:
			if !inTag {
				result.WriteRune(character)
			}
		}
	}
	return strings.Join(strings.Fields(html.UnescapeString(result.String())), " ")
}

func cloneBrief(brief Brief) Brief {
	brief.Items = append([]Item(nil), brief.Items...)
	return brief
}
