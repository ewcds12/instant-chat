// Package messages manages persisted direct text messages.
package messages

import (
	"context"
	"errors"
	"time"
)

var (
	// ErrConversationNotFound hides whether a conversation exists from non-members.
	ErrConversationNotFound = errors.New("conversation not found")
)

// InputError describes one invalid message request field.
type InputError struct {
	Message string
}

func (e *InputError) Error() string {
	return e.Message
}

// Sender is the public identity attached to a message.
type Sender struct {
	ID          uint64
	Username    string
	DisplayName string
	CreatedAt   time.Time
}

// Message is one persisted direct text message.
type Message struct {
	ID              uint64
	ConversationID  uint64
	Sender          Sender
	ClientMessageID string
	Sequence        uint64
	Body            string
	CreatedAt       time.Time
}

// Page is one ascending message-history page.
type Page struct {
	Messages   []Message
	NextCursor *uint64
}

// Repository defines persistence required by message use cases.
type Repository interface {
	Send(
		ctx context.Context,
		userID, conversationID uint64,
		clientMessageID, body string,
	) (Message, bool, error)
	List(
		ctx context.Context,
		userID, conversationID uint64,
		before *uint64,
		limit int,
	) ([]Message, error)
	ListAfter(
		ctx context.Context,
		userID, conversationID, after uint64,
		limit int,
	) ([]Message, error)
}

// Publisher delivers newly persisted messages without affecting REST success.
type Publisher interface {
	PublishMessage(ctx context.Context, message Message)
}
