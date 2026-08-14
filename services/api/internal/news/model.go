// Package news provides a cached daily brief from a public current-events feed.
package news

import "time"

// Item is one source-linked daily news entry.
type Item struct {
	ID      string `json:"id"`
	Title   string `json:"title"`
	Summary string `json:"summary"`
	Source  string `json:"source"`
	URL     string `json:"url"`
}

// Brief is the current daily news collection and its fetch time.
type Brief struct {
	Items     []Item    `json:"items"`
	UpdatedAt time.Time `json:"updated_at"`
}
