package messages

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/ewcds12/instant-chat/services/api/internal/store"
)

type storedFileUpload struct {
	Filename    string
	ContentType string
	ByteSize    uint64
	ObjectKey   string
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
	fileID sql.NullInt64,
) error {
	_, err := queries.CreateMessage(ctx, store.CreateMessageParams{
		ConversationID:  conversationID,
		SenderID:        userID,
		ClientMessageID: clientMessageID,
		Sequence:        sequence,
		Kind:            kind,
		Body:            body,
		ImageID:         imageID,
		FileID:          fileID,
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
	return insertedID(result, "image")
}

func createFile(
	ctx context.Context,
	queries *store.Queries,
	userID uint64,
	upload *storedFileUpload,
) (sql.NullInt64, error) {
	if upload == nil {
		return sql.NullInt64{}, nil
	}
	result, err := queries.CreateMessageFile(ctx, store.CreateMessageFileParams{
		UploaderID:  userID,
		Filename:    upload.Filename,
		ContentType: upload.ContentType,
		ByteSize:    upload.ByteSize,
		ObjectKey:   sql.NullString{String: upload.ObjectKey, Valid: true},
	})
	if err != nil {
		return sql.NullInt64{}, fmt.Errorf("create message file: %w", err)
	}
	return insertedID(result, "file")
}

func insertedID(result sql.Result, label string) (sql.NullInt64, error) {
	id, err := result.LastInsertId()
	if err != nil {
		return sql.NullInt64{}, fmt.Errorf("read created %s id: %w", label, err)
	}
	return sql.NullInt64{Int64: id, Valid: true}, nil
}

func rollback(tx *sql.Tx, cause error) error {
	if err := tx.Rollback(); err != nil && !errors.Is(err, sql.ErrTxDone) {
		return errors.Join(cause, fmt.Errorf("roll back transaction: %w", err))
	}
	return cause
}
