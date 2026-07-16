package messages

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/store"
)

// MySQLRepository persists direct messages through sqlc queries.
type MySQLRepository struct {
	database *sql.DB
	queries  *store.Queries
}

// NewMySQLRepository creates the production message repository.
func NewMySQLRepository(database *sql.DB) *MySQLRepository {
	return &MySQLRepository{database: database, queries: store.New(database)}
}

// Send allocates a conversation sequence and creates one message atomically.
func (r *MySQLRepository) Send(
	ctx context.Context,
	userID, conversationID uint64,
	clientMessageID, body string,
) (Message, bool, error) {
	tx, err := r.database.BeginTx(ctx, nil)
	if err != nil {
		return Message{}, false, fmt.Errorf("begin message transaction: %w", err)
	}
	queries := r.queries.WithTx(tx)
	sequence, err := queries.LockConversationForMessage(ctx, store.LockConversationForMessageParams{
		ConversationID: conversationID,
		UserID:         userID,
	})
	if errors.Is(err, sql.ErrNoRows) {
		return Message{}, false, rollback(tx, ErrConversationNotFound)
	}
	if err != nil {
		return Message{}, false, rollback(tx, fmt.Errorf("lock conversation: %w", err))
	}
	existing, err := queries.GetMessageByClientID(ctx, store.GetMessageByClientIDParams{
		ConversationID:  conversationID,
		SenderID:        userID,
		ClientMessageID: clientMessageID,
	})
	if err == nil {
		if commitErr := tx.Commit(); commitErr != nil {
			return Message{}, false, fmt.Errorf("commit idempotent message transaction: %w", commitErr)
		}
		return messageFromClientRow(existing), false, nil
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return Message{}, false, rollback(tx, fmt.Errorf("read idempotent message: %w", err))
	}
	if err := createMessage(ctx, queries, conversationID, userID, clientMessageID, sequence, body); err != nil {
		return Message{}, false, rollback(tx, err)
	}
	created, err := queries.GetMessageByClientID(ctx, store.GetMessageByClientIDParams{
		ConversationID:  conversationID,
		SenderID:        userID,
		ClientMessageID: clientMessageID,
	})
	if err != nil {
		return Message{}, false, rollback(tx, fmt.Errorf("read created message: %w", err))
	}
	if err := tx.Commit(); err != nil {
		return Message{}, false, fmt.Errorf("commit message transaction: %w", err)
	}
	return messageFromClientRow(created), true, nil
}

// List returns newest-first rows after checking conversation membership.
func (r *MySQLRepository) List(
	ctx context.Context,
	userID, conversationID uint64,
	before *uint64,
	limit int,
) ([]Message, error) {
	member, err := r.queries.IsConversationMember(ctx, store.IsConversationMemberParams{
		ConversationID: conversationID,
		UserID:         userID,
	})
	if err != nil {
		return nil, fmt.Errorf("check conversation membership: %w", err)
	}
	if !member {
		return nil, ErrConversationNotFound
	}
	if before == nil {
		return r.listLatest(ctx, conversationID, limit)
	}
	return r.listBefore(ctx, conversationID, *before, limit)
}

// ListAfter returns ascending rows newer than a server sequence.
func (r *MySQLRepository) ListAfter(
	ctx context.Context,
	userID, conversationID, after uint64,
	limit int,
) ([]Message, error) {
	member, err := r.queries.IsConversationMember(ctx, store.IsConversationMemberParams{
		ConversationID: conversationID,
		UserID:         userID,
	})
	if err != nil {
		return nil, fmt.Errorf("check conversation membership: %w", err)
	}
	if !member {
		return nil, ErrConversationNotFound
	}
	rows, err := r.queries.ListMessagesAfter(ctx, store.ListMessagesAfterParams{
		ConversationID: conversationID,
		AfterSequence:  after,
		Limit:          int32(limit),
	})
	if err != nil {
		return nil, fmt.Errorf("list messages after sequence: %w", err)
	}
	messages := make([]Message, 0, len(rows))
	for _, row := range rows {
		messages = append(messages, messageFromAfterRow(row))
	}
	return messages, nil
}

func createMessage(
	ctx context.Context,
	queries *store.Queries,
	conversationID, userID uint64,
	clientMessageID string,
	sequence uint64,
	body string,
) error {
	_, err := queries.CreateMessage(ctx, store.CreateMessageParams{
		ConversationID:  conversationID,
		SenderID:        userID,
		ClientMessageID: clientMessageID,
		Sequence:        sequence,
		Body:            body,
	})
	if err != nil {
		return fmt.Errorf("create message: %w", err)
	}
	if err := queries.AdvanceConversationSequence(ctx, conversationID); err != nil {
		return fmt.Errorf("advance conversation sequence: %w", err)
	}
	return nil
}

func (r *MySQLRepository) listLatest(ctx context.Context, conversationID uint64, limit int) ([]Message, error) {
	rows, err := r.queries.ListLatestMessages(ctx, store.ListLatestMessagesParams{
		ConversationID: conversationID,
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
	conversationID, before uint64,
	limit int,
) ([]Message, error) {
	rows, err := r.queries.ListMessagesBefore(ctx, store.ListMessagesBeforeParams{
		ConversationID: conversationID,
		BeforeSequence: before,
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

func rollback(tx *sql.Tx, cause error) error {
	if err := tx.Rollback(); err != nil && !errors.Is(err, sql.ErrTxDone) {
		return errors.Join(cause, fmt.Errorf("roll back transaction: %w", err))
	}
	return cause
}

func messageFromClientRow(row store.GetMessageByClientIDRow) Message {
	return newMessage(
		row.ID, row.ConversationID, row.SenderID, row.SenderUsername,
		row.SenderDisplayName, row.SenderCreatedAt, row.ClientMessageID,
		row.Sequence, row.Body, row.CreatedAt,
	)
}

func messageFromLatestRow(row store.ListLatestMessagesRow) Message {
	return newMessage(
		row.ID, row.ConversationID, row.SenderID, row.SenderUsername,
		row.SenderDisplayName, row.SenderCreatedAt, row.ClientMessageID,
		row.Sequence, row.Body, row.CreatedAt,
	)
}

func messageFromBeforeRow(row store.ListMessagesBeforeRow) Message {
	return newMessage(
		row.ID, row.ConversationID, row.SenderID, row.SenderUsername,
		row.SenderDisplayName, row.SenderCreatedAt, row.ClientMessageID,
		row.Sequence, row.Body, row.CreatedAt,
	)
}

func messageFromAfterRow(row store.ListMessagesAfterRow) Message {
	return newMessage(
		row.ID, row.ConversationID, row.SenderID, row.SenderUsername,
		row.SenderDisplayName, row.SenderCreatedAt, row.ClientMessageID,
		row.Sequence, row.Body, row.CreatedAt,
	)
}

func newMessage(
	id, conversationID, senderID uint64,
	username, displayName string,
	senderCreatedAt time.Time,
	clientMessageID string,
	sequence uint64,
	body string,
	createdAt time.Time,
) Message {
	return Message{
		ID:             id,
		ConversationID: conversationID,
		Sender: Sender{
			ID: senderID, Username: username, DisplayName: displayName, CreatedAt: senderCreatedAt,
		},
		ClientMessageID: clientMessageID,
		Sequence:        sequence,
		Body:            body,
		CreatedAt:       createdAt,
	}
}
