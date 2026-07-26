// Package messages manages persisted direct conversation messages.
package messages

import (
	"context"
	"errors"
	"io"
	"time"
)

var (
	// ErrConversationNotFound hides whether a conversation exists from non-members.
	ErrConversationNotFound = errors.New("conversation not found")
	// ErrImageNotFound hides whether an image exists from non-members.
	ErrImageNotFound = errors.New("message image not found")
	// ErrFileNotFound hides whether a file exists from non-members.
	ErrFileNotFound = errors.New("message file not found")
	// ErrRecallUnavailable indicates that a message cannot be recalled anymore.
	ErrRecallUnavailable = errors.New("message recall is unavailable")
)

const (
	// KindText identifies a regular text message.
	KindText = "text"
	// KindImage identifies a message with one image attachment.
	KindImage = "image"
	// KindFile identifies a message with one file attachment.
	KindFile = "file"
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
	HasAvatar   bool
	CreatedAt   time.Time
}

// Message is one persisted direct text message.
type Message struct {
	ID              uint64
	ConversationID  uint64
	Sender          Sender
	ClientMessageID string
	Sequence        uint64
	Kind            string
	Body            string
	Image           *ImageAttachment
	File            *FileAttachment
	RecalledAt      *time.Time
	CreatedAt       time.Time
}

// Recall identifies a message that was recalled for every conversation member.
type Recall struct {
	ConversationID uint64
	MessageID      uint64
}

// ImageAttachment is the public metadata for one image message attachment.
type ImageAttachment struct {
	ID          uint64
	ContentType string
	ByteSize    uint32
}

// ImageUpload is a validated image upload candidate.
type ImageUpload struct {
	ContentType string
	Data        []byte
}

// FileAttachment is the public metadata for one file message attachment.
type FileAttachment struct {
	ID          uint64
	Filename    string
	ContentType string
	ByteSize    uint32
}

// FileUpload is a validated file upload candidate.
type FileUpload struct {
	Filename    string
	ContentType string
	ByteSize    int64
	Reader      io.Reader
}

// ImageFile is one authorized image download.
type ImageFile struct {
	ContentType string
	ByteSize    uint32
	Data        []byte
}

// MessageFile is one authorized file download.
type MessageFile struct {
	Filename    string
	ContentType string
	ByteSize    uint32
	Content     io.ReadCloser
}

// FileObjectStore persists and retrieves file-message object bytes.
type FileObjectStore interface {
	Put(
		ctx context.Context,
		key string,
		reader io.Reader,
		size int64,
		contentType string,
	) error
	Open(ctx context.Context, key string) (io.ReadCloser, error)
	Delete(ctx context.Context, key string) error
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
	SendImage(
		ctx context.Context,
		userID, conversationID uint64,
		clientMessageID string,
		upload ImageUpload,
	) (Message, bool, error)
	SendFile(
		ctx context.Context,
		userID, conversationID uint64,
		clientMessageID string,
		upload FileUpload,
	) (Message, bool, error)
	Image(ctx context.Context, userID, imageID uint64) (ImageFile, error)
	File(ctx context.Context, userID, fileID uint64) (MessageFile, error)
	Recall(ctx context.Context, userID, conversationID, messageID uint64) error
	Delete(ctx context.Context, userID, conversationID, messageID uint64) error
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
	PublishRecall(ctx context.Context, recall Recall)
}
