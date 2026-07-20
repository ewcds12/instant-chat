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
	return r.send(ctx, userID, conversationID, clientMessageID, KindText, body, nil, nil)
}

// SendImage allocates a sequence and creates one image message atomically.
func (r *MySQLRepository) SendImage(
	ctx context.Context,
	userID, conversationID uint64,
	clientMessageID string,
	upload ImageUpload,
) (Message, bool, error) {
	return r.send(ctx, userID, conversationID, clientMessageID, KindImage, "", &upload, nil)
}

// SendFile allocates a sequence and creates one file message atomically.
func (r *MySQLRepository) SendFile(
	ctx context.Context,
	userID, conversationID uint64,
	clientMessageID string,
	upload FileUpload,
) (Message, bool, error) {
	return r.send(ctx, userID, conversationID, clientMessageID, KindFile, "", nil, &upload)
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

// File returns one file if the requester belongs to its conversation.
func (r *MySQLRepository) File(ctx context.Context, userID, fileID uint64) (MessageFile, error) {
	row, err := r.queries.GetMessageFileForMember(ctx, store.GetMessageFileForMemberParams{
		FileID: fileID,
		UserID: userID,
	})
	if errors.Is(err, sql.ErrNoRows) {
		return MessageFile{}, ErrFileNotFound
	}
	if err != nil {
		return MessageFile{}, fmt.Errorf("read message file: %w", err)
	}
	return MessageFile{
		Filename:    row.Filename,
		ContentType: row.ContentType,
		ByteSize:    row.ByteSize,
		Data:        row.Data,
	}, nil
}

// Recall removes a recent message only when requested by its sender.
func (r *MySQLRepository) Recall(
	ctx context.Context,
	userID, conversationID, messageID uint64,
) error {
	result, err := r.queries.RecallMessage(ctx, store.RecallMessageParams{
		MessageID: messageID, ConversationID: conversationID, UserID: userID,
	})
	if err != nil {
		return fmt.Errorf("recall message: %w", err)
	}
	changed, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("read recalled message count: %w", err)
	}
	if changed == 0 {
		return ErrRecallUnavailable
	}
	return nil
}

// Delete hides a message only from the requesting conversation member.
func (r *MySQLRepository) Delete(
	ctx context.Context,
	userID, conversationID, messageID uint64,
) error {
	member, err := r.queries.IsConversationMember(ctx, store.IsConversationMemberParams{
		ConversationID: conversationID, UserID: userID,
	})
	if err != nil {
		return fmt.Errorf("check conversation membership: %w", err)
	}
	if !member {
		return ErrConversationNotFound
	}
	if err := r.queries.HideMessageForUser(ctx, store.HideMessageForUserParams{
		MessageID: messageID, ConversationID: conversationID, UserID: userID,
	}); err != nil {
		return fmt.Errorf("hide message for user: %w", err)
	}
	return nil
}

func (r *MySQLRepository) send(
	ctx context.Context,
	userID, conversationID uint64,
	clientMessageID, kind, body string,
	upload *ImageUpload,
	fileUpload *FileUpload,
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
	fileID, err := createFile(ctx, queries, userID, fileUpload)
	if err != nil {
		return Message{}, false, rollback(tx, err)
	}
	if err := createMessage(
		ctx, queries, conversationID, userID, clientMessageID,
		sequence, kind, body, imageID, fileID,
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
		return r.listLatest(ctx, userID, conversationID, limit)
	}
	return r.listBefore(ctx, userID, conversationID, *before, limit)
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
		UserID:         userID,
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
