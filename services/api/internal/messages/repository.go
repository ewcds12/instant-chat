package messages

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

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
	return r.send(ctx, userID, conversationID, clientMessageID, KindText, body, nil)
}

// SendImage allocates a sequence and creates one image message atomically.
func (r *MySQLRepository) SendImage(
	ctx context.Context,
	userID, conversationID uint64,
	clientMessageID string,
	upload ImageUpload,
) (Message, bool, error) {
	return r.send(ctx, userID, conversationID, clientMessageID, KindImage, "", &upload)
}

// Image returns one image if the requester belongs to its conversation.
func (r *MySQLRepository) Image(ctx context.Context, userID, imageID uint64) (ImageFile, error) {
	row, err := r.queries.GetMessageImageForMember(ctx, store.GetMessageImageForMemberParams{
		ImageID: imageID,
		UserID:  userID,
	})
	if errors.Is(err, sql.ErrNoRows) {
		return ImageFile{}, ErrImageNotFound
	}
	if err != nil {
		return ImageFile{}, fmt.Errorf("read message image: %w", err)
	}
	return ImageFile{
		ContentType: row.ContentType,
		ByteSize:    row.ByteSize,
		Data:        row.Data,
	}, nil
}

func (r *MySQLRepository) send(
	ctx context.Context,
	userID, conversationID uint64,
	clientMessageID, kind, body string,
	upload *ImageUpload,
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
	imageID, err := createImage(ctx, queries, userID, upload)
	if err != nil {
		return Message{}, false, rollback(tx, err)
	}
	if err := createMessage(
		ctx, queries, conversationID, userID, clientMessageID,
		sequence, kind, body, imageID,
	); err != nil {
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
	kind string,
	body string,
	imageID sql.NullInt64,
) error {
	_, err := queries.CreateMessage(ctx, store.CreateMessageParams{
		ConversationID:  conversationID,
		SenderID:        userID,
		ClientMessageID: clientMessageID,
		Sequence:        sequence,
		Kind:            kind,
		Body:            body,
		ImageID:         imageID,
	})
	if err != nil {
		return fmt.Errorf("create message: %w", err)
	}
	if err := queries.AdvanceConversationSequence(ctx, conversationID); err != nil {
		return fmt.Errorf("advance conversation sequence: %w", err)
	}
	return nil
}

func createImage(
	ctx context.Context,
	queries *store.Queries,
	userID uint64,
	upload *ImageUpload,
) (sql.NullInt64, error) {
	if upload == nil {
		return sql.NullInt64{}, nil
	}
	result, err := queries.CreateMessageImage(ctx, store.CreateMessageImageParams{
		UploaderID:  userID,
		ContentType: upload.ContentType,
		ByteSize:    uint32(len(upload.Data)),
		Data:        upload.Data,
	})
	if err != nil {
		return sql.NullInt64{}, fmt.Errorf("create message image: %w", err)
	}
	id, err := result.LastInsertId()
	if err != nil {
		return sql.NullInt64{}, fmt.Errorf("read created image id: %w", err)
	}
	return sql.NullInt64{Int64: id, Valid: true}, nil
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
