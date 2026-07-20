package messages

import (
	"context"
	"fmt"

	"github.com/ewcds12/instant-chat/services/api/internal/store"
)

func (r *MySQLRepository) listLatest(
	ctx context.Context,
	userID, conversationID uint64,
	limit int,
) ([]Message, error) {
	rows, err := r.queries.ListLatestMessages(ctx, store.ListLatestMessagesParams{
		ConversationID: conversationID,
		UserID:         userID,
		Limit:          int32(limit),
	})
	if err != nil {
		return nil, fmt.Errorf("list latest messages: %w", err)
	}
	messages := make([]Message, 0, len(rows))
	for _, row := range rows {
		messages = append(messages, messageFromLatestRow(row))
	}
	return messages, nil
}

func (r *MySQLRepository) listBefore(
	ctx context.Context,
	userID, conversationID, before uint64,
	limit int,
) ([]Message, error) {
	rows, err := r.queries.ListMessagesBefore(ctx, store.ListMessagesBeforeParams{
		ConversationID: conversationID,
		BeforeSequence: before,
		UserID:         userID,
		Limit:          int32(limit),
	})
	if err != nil {
		return nil, fmt.Errorf("list messages before cursor: %w", err)
	}
	messages := make([]Message, 0, len(rows))
	for _, row := range rows {
		messages = append(messages, messageFromBeforeRow(row))
	}
	return messages, nil
}
