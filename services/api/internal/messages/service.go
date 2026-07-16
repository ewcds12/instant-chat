package messages

import (
	"context"
	"regexp"
	"strings"
	"unicode/utf8"
)

const (
	defaultPageSize  = 50
	maximumPageSize  = 100
	maximumBodyRunes = 4000
)

var clientMessageIDPattern = regexp.MustCompile(`^[a-f0-9]{32}$`)

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
