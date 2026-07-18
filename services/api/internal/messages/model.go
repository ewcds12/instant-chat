// Package messages manages persisted direct conversation messages.
package messages

import (
	"context"
	"errors"
	"time"
)

var (
	// ErrConversationNotFound hides whether a conversation exists from non-members.
	ErrConversationNotFound = errors.New("conversation not found")
	// ErrImageNotFound hides whether an image exists from non-members.
	ErrImageNotFound = errors.New("message image not found")
	// ErrFileNotFound hides whether a file exists from non-members.
	ErrFileNotFound = errors.New("message file not found")
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
	CreatedAt       time.Time
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
	Data        []byte
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
	Data        []byte
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
