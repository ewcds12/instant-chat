package messages

import (
	"context"
	"regexp"
	"strings"
	"unicode/utf8"
)

const (
	defaultPageSize   = 50
	maximumPageSize   = 100
	maximumBodyRunes  = 4000
	maximumImageBytes = 15 * 1024 * 1024
	maximumFileBytes  = 25 * 1024 * 1024
	maximumNameRunes  = 255
)

var clientMessageIDPattern = regexp.MustCompile(`^[a-f0-9]{32}$`)

var allowedImageContentTypes = map[string]struct{}{
	"image/gif":  {},
	"image/jpeg": {},
	"image/png":  {},
	"image/webp": {},
}

// Service implements message validation and cursor pagination.
type Service struct {
	repository Repository
	publisher  Publisher
}

// NewService creates the message service.
func NewService(repository Repository, publisher Publisher) *Service {
	return &Service{repository: repository, publisher: publisher}
}

// Send validates and persists a text message.
func (s *Service) Send(
	ctx context.Context,
	userID, conversationID uint64,
	clientMessageID, body string,
) (Message, bool, error) {
	if !clientMessageIDPattern.MatchString(clientMessageID) {
		return Message{}, false, &InputError{
			Message: "Client message ID must be 32 lowercase hexadecimal characters.",
		}
	}
	trimmedBody := strings.TrimSpace(body)
	if trimmedBody == "" {
		return Message{}, false, &InputError{Message: "Message body must not be empty."}
	}
	if !utf8.ValidString(trimmedBody) || utf8.RuneCountInString(trimmedBody) > maximumBodyRunes {
		return Message{}, false, &InputError{
			Message: "Message body must contain at most 4,000 Unicode characters.",
		}
	}
	message, created, err := s.repository.Send(
		ctx, userID, conversationID, clientMessageID, trimmedBody,
	)
	if err == nil && created {
		s.publisher.PublishMessage(ctx, message)
	}
	return message, created, err
}

// SendImage validates and persists one image message.
func (s *Service) SendImage(
	ctx context.Context,
	userID, conversationID uint64,
	clientMessageID string,
	upload ImageUpload,
) (Message, bool, error) {
	if !clientMessageIDPattern.MatchString(clientMessageID) {
		return Message{}, false, &InputError{
			Message: "Client message ID must be 32 lowercase hexadecimal characters.",
		}
	}
	if len(upload.Data) == 0 {
		return Message{}, false, &InputError{Message: "Image must not be empty."}
	}
	if len(upload.Data) > maximumImageBytes {
		return Message{}, false, &InputError{Message: "Image must be 15 MB or smaller."}
	}
	if _, ok := allowedImageContentTypes[upload.ContentType]; !ok {
		return Message{}, false, &InputError{
			Message: "Image must be PNG, JPEG, GIF, or WebP.",
		}
	}
	message, created, err := s.repository.SendImage(
		ctx, userID, conversationID, clientMessageID, upload,
	)
	if err == nil && created {
		s.publisher.PublishMessage(ctx, message)
	}
	return message, created, err
}

// SendFile validates and persists one file message.
func (s *Service) SendFile(
	ctx context.Context,
	userID, conversationID uint64,
	clientMessageID string,
	upload FileUpload,
) (Message, bool, error) {
	if !clientMessageIDPattern.MatchString(clientMessageID) {
		return Message{}, false, &InputError{
			Message: "Client message ID must be 32 lowercase hexadecimal characters.",
		}
	}
	filename := strings.TrimSpace(upload.Filename)
	if filename == "" || !utf8.ValidString(filename) || utf8.RuneCountInString(filename) > maximumNameRunes {
		return Message{}, false, &InputError{
			Message: "Filename must contain 1 to 255 Unicode characters.",
		}
	}
	if len(upload.Data) == 0 {
		return Message{}, false, &InputError{Message: "File must not be empty."}
	}
	if len(upload.Data) > maximumFileBytes {
		return Message{}, false, &InputError{Message: "File must be 25 MB or smaller."}
	}
	if strings.TrimSpace(upload.ContentType) == "" {
		upload.ContentType = "application/octet-stream"
	}
	upload.Filename = filename
	message, created, err := s.repository.SendFile(
		ctx, userID, conversationID, clientMessageID, upload,
	)
	if err == nil && created {
		s.publisher.PublishMessage(ctx, message)
	}
	return message, created, err
}

// Image returns one authorized image attachment.
func (s *Service) Image(ctx context.Context, userID, imageID uint64) (ImageFile, error) {
	if imageID == 0 {
		return ImageFile{}, &InputError{Message: "Image ID must be a positive integer string."}
	}
	return s.repository.Image(ctx, userID, imageID)
}

// File returns one authorized file attachment.
func (s *Service) File(ctx context.Context, userID, fileID uint64) (MessageFile, error) {
	if fileID == 0 {
		return MessageFile{}, &InputError{Message: "File ID must be a positive integer string."}
	}
	return s.repository.File(ctx, userID, fileID)
}

// Recall marks the sender's recent message as recalled for every conversation member.
func (s *Service) Recall(
	ctx context.Context,
	userID, conversationID, messageID uint64,
) error {
	if err := s.repository.Recall(ctx, userID, conversationID, messageID); err != nil {
		return err
	}
	s.publisher.PublishRecall(ctx, Recall{
		ConversationID: conversationID,
		MessageID:      messageID,
	})
	return nil
}

// Delete hides one message only for the requesting conversation member.
func (s *Service) Delete(
	ctx context.Context,
	userID, conversationID, messageID uint64,
) error {
	return s.repository.Delete(ctx, userID, conversationID, messageID)
}

// List returns one ascending history page and an older-page cursor.
func (s *Service) List(
	ctx context.Context,
	userID, conversationID uint64,
	before, after *uint64,
	limit int,
) (Page, error) {
	if before != nil && after != nil {
		return Page{}, &InputError{Message: "Before and after cannot be used together."}
	}
	if limit == 0 {
		limit = defaultPageSize
	}
	if limit < 1 || limit > maximumPageSize {
		return Page{}, &InputError{Message: "Limit must be between 1 and 100."}
	}
	if after != nil {
		return s.listAfter(ctx, userID, conversationID, *after, limit)
	}
	messages, err := s.repository.List(ctx, userID, conversationID, before, limit+1)
	if err != nil {
		return Page{}, err
	}
	hasMore := len(messages) > limit
	if hasMore {
		messages = messages[:limit]
	}
	reverse(messages)
	var nextCursor *uint64
	if hasMore {
		cursor := messages[0].Sequence
		nextCursor = &cursor
	}
	return Page{Messages: messages, NextCursor: nextCursor}, nil
}

func (s *Service) listAfter(
	ctx context.Context,
	userID, conversationID, after uint64,
	limit int,
) (Page, error) {
	messages, err := s.repository.ListAfter(
		ctx, userID, conversationID, after, limit+1,
	)
	if err != nil {
		return Page{}, err
	}
	hasMore := len(messages) > limit
	if hasMore {
		messages = messages[:limit]
	}
	var nextCursor *uint64
	if hasMore {
		cursor := messages[len(messages)-1].Sequence
		nextCursor = &cursor
	}
	return Page{Messages: messages, NextCursor: nextCursor}, nil
}

func reverse(messages []Message) {
	for left, right := 0, len(messages)-1; left < right; left, right = left+1, right-1 {
		messages[left], messages[right] = messages[right], messages[left]
	}
}
