package httpapi

import (
	"net"
	"net/http"
	"strconv"
	"sync"
	"time"
)

const maximumRateLimitVisitors = 10_000

type visitorWindow struct {
	count   int
	resetAt time.Time
}

// IPRateLimiter applies a fixed request window to each remote IP address.
type IPRateLimiter struct {
	mu       sync.Mutex
	limit    int
	window   time.Duration
	visitors map[string]visitorWindow
	now      func() time.Time
}

// NewIPRateLimiter creates an in-memory limiter for one API process.
func NewIPRateLimiter(limit int, window time.Duration) *IPRateLimiter {
	return &IPRateLimiter{
		limit: limit, window: window, visitors: make(map[string]visitorWindow), now: time.Now,
	}
}

// Handler wraps an endpoint with the configured rate limit.
func (l *IPRateLimiter) Handler(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !l.allow(clientIP(r.RemoteAddr)) {
			w.Header().Set("Retry-After", durationSeconds(l.window))
			WriteError(
				w, http.StatusTooManyRequests, "rate_limited",
				"Too many requests. Try again later.", RequestID(r.Context()),
			)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (l *IPRateLimiter) allow(address string) bool {
	l.mu.Lock()
	defer l.mu.Unlock()

	now := l.now().UTC()
	if _, exists := l.visitors[address]; !exists && len(l.visitors) >= maximumRateLimitVisitors {
		l.removeExpired(now)
		if len(l.visitors) >= maximumRateLimitVisitors {
			return false
		}
	}
	window := l.visitors[address]
	if window.resetAt.IsZero() || !now.Before(window.resetAt) {
		window = visitorWindow{resetAt: now.Add(l.window)}
	}
	window.count++
	l.visitors[address] = window
	if len(l.visitors) > 1000 {
		l.removeExpired(now)
	}
	return window.count <= l.limit
}

func (l *IPRateLimiter) removeExpired(now time.Time) {
	for address, window := range l.visitors {
		if !now.Before(window.resetAt) {
			delete(l.visitors, address)
		}
	}
}

func clientIP(remoteAddress string) string {
	host, _, err := net.SplitHostPort(remoteAddress)
	if err != nil {
		return remoteAddress
	}
	return host
}

func durationSeconds(value time.Duration) string {
	seconds := int(value.Round(time.Second) / time.Second)
	if seconds < 1 {
		seconds = 1
	}
	return strconv.Itoa(seconds)
}
