package messages

import (
	"bytes"
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/store"
)

// SendFile stores file bytes before creating their message metadata.
func (r *MySQLRepository) SendFile(
	ctx context.Context,
	userID, conversationID uint64,
	clientMessageID string,
	upload FileUpload,
) (Message, bool, error) {
	existing, found, err := r.preflightFileMessage(
		ctx, userID, conversationID, clientMessageID,
	)
	if err != nil || found {
		return existing, false, err
	}
	objectKey, err := newFileObjectKey(conversationID)
	if err != nil {
		return Message{}, false, err
	}
	if err := r.objectStore.Put(
		ctx, objectKey, upload.Reader, upload.ByteSize, upload.ContentType,
	); err != nil {
		return Message{}, false, fmt.Errorf("store message file: %w", err)
	}
	stored := storedFileUpload{
		Filename: upload.Filename, ContentType: upload.ContentType,
		ByteSize: uint64(upload.ByteSize), ObjectKey: objectKey,
	}
	message, created, err := r.send(
		ctx, userID, conversationID, clientMessageID, KindFile, "", nil, &stored, nil,
	)
	if err != nil {
		return Message{}, false, errors.Join(err, r.deleteObject(ctx, objectKey))
	}
	if !created {
		if cleanupErr := r.deleteObject(ctx, objectKey); cleanupErr != nil {
			slog.Error("remove idempotent file object", "error", cleanupErr)
		}
	}
	return message, created, nil
}

func (r *MySQLRepository) preflightFileMessage(
	ctx context.Context,
	userID, conversationID uint64,
	clientMessageID string,
) (Message, bool, error) {
	member, err := r.queries.IsConversationMember(ctx, store.IsConversationMemberParams{
		ConversationID: conversationID, UserID: userID,
	})
	if err != nil {
		return Message{}, false, fmt.Errorf("check conversation membership: %w", err)
	}
	if !member {
		return Message{}, false, ErrConversationNotFound
	}
	row, err := r.queries.GetMessageByClientID(ctx, store.GetMessageByClientIDParams{
		ConversationID: conversationID, SenderID: userID, ClientMessageID: clientMessageID,
	})
	if errors.Is(err, sql.ErrNoRows) {
		return Message{}, false, nil
	}
	if err != nil {
		return Message{}, false, fmt.Errorf("read idempotent file message: %w", err)
	}
	return messageFromClientRow(row), true, nil
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
	var content io.ReadCloser
	if row.ObjectKey.Valid {
		content, err = r.objectStore.Open(ctx, row.ObjectKey.String)
		if err != nil {
			return MessageFile{}, fmt.Errorf("open message file object: %w", err)
		}
	} else if row.Data.Valid {
		content = io.NopCloser(bytes.NewReader([]byte(row.Data.String)))
	} else {
		return MessageFile{}, errors.New("message file has no stored content")
	}
	return MessageFile{
		Filename: row.Filename, ContentType: row.ContentType,
		ByteSize: row.ByteSize, Content: content,
	}, nil
}

func newFileObjectKey(conversationID uint64) (string, error) {
	var id [16]byte
	if _, err := rand.Read(id[:]); err != nil {
		return "", fmt.Errorf("generate file object key: %w", err)
	}
	return fmt.Sprintf(
		"conversations/%d/files/%s", conversationID, hex.EncodeToString(id[:]),
	), nil
}

func (r *MySQLRepository) deleteObject(ctx context.Context, key string) error {
	cleanupCtx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 10*time.Second)
	defer cancel()
	if err := r.objectStore.Delete(cleanupCtx, key); err != nil {
		return fmt.Errorf("remove unreferenced file object: %w", err)
	}
	return nil
}
