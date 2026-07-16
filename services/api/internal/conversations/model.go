// Package conversations manages the initial direct-conversation list.
package conversations

import (
	"context"
	"errors"
	"time"
)

var (
	// ErrNotContact indicates that a direct conversation requires an accepted contact.
	ErrNotContact = errors.New("direct conversation requires an accepted contact")
	// ErrSelfConversation indicates that a user targeted their own account.
	ErrSelfConversation = errors.New("cannot create a conversation with yourself")
)

// Peer is the public account identity shown for a direct conversation.
type Peer struct {
	ID          uint64
	Username    string
	DisplayName string
	CreatedAt   time.Time
}

// Conversation is the initial direct-conversation representation.
type Conversation struct {
	ID        uint64
	Kind      string
	Peer      Peer
	CreatedAt time.Time
	UpdatedAt time.Time
}

// Repository defines persistence required by conversation use cases.
type Repository interface {
	CreateDirect(ctx context.Context, userID, contactUserID uint64) (Conversation, bool, error)
	List(ctx context.Context, userID uint64) ([]Conversation, error)
}
