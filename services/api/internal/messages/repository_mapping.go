package messages

import (
	"database/sql"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/store"
)

func messageFromClientRow(row store.GetMessageByClientIDRow) Message {
	return newMessage(
		row.ID, row.ConversationID, row.SenderID, row.SenderUsername,
		row.SenderDisplayName, row.SenderAvatarContentType, row.SenderCreatedAt, row.ClientMessageID,
		row.Sequence, row.Kind, row.Body, row.ImageID, row.ImageContentType,
		row.ImageByteSize, row.FileID, row.FileFilename, row.FileContentType,
		row.FileByteSize, row.ReplyToID, row.ReplySenderID, row.ReplySenderUsername,
		row.ReplySenderDisplayName, row.ReplySenderAvatarContentType,
		row.ReplySenderCreatedAt, row.ReplyKind, row.ReplyBody,
		row.ReplyFileFilename, row.ReplyRecalledAt, row.RecalledAt, row.CreatedAt,
	)
}

func messageFromLatestRow(row store.ListLatestMessagesRow) Message {
	return newMessage(
		row.ID, row.ConversationID, row.SenderID, row.SenderUsername,
		row.SenderDisplayName, row.SenderAvatarContentType, row.SenderCreatedAt, row.ClientMessageID,
		row.Sequence, row.Kind, row.Body, row.ImageID, row.ImageContentType,
		row.ImageByteSize, row.FileID, row.FileFilename, row.FileContentType,
		row.FileByteSize, row.ReplyToID, row.ReplySenderID, row.ReplySenderUsername,
		row.ReplySenderDisplayName, row.ReplySenderAvatarContentType,
		row.ReplySenderCreatedAt, row.ReplyKind, row.ReplyBody,
		row.ReplyFileFilename, row.ReplyRecalledAt, row.RecalledAt, row.CreatedAt,
	)
}

func messageFromBeforeRow(row store.ListMessagesBeforeRow) Message {
	return newMessage(
		row.ID, row.ConversationID, row.SenderID, row.SenderUsername,
		row.SenderDisplayName, row.SenderAvatarContentType, row.SenderCreatedAt, row.ClientMessageID,
		row.Sequence, row.Kind, row.Body, row.ImageID, row.ImageContentType,
		row.ImageByteSize, row.FileID, row.FileFilename, row.FileContentType,
		row.FileByteSize, row.ReplyToID, row.ReplySenderID, row.ReplySenderUsername,
		row.ReplySenderDisplayName, row.ReplySenderAvatarContentType,
		row.ReplySenderCreatedAt, row.ReplyKind, row.ReplyBody,
		row.ReplyFileFilename, row.ReplyRecalledAt, row.RecalledAt, row.CreatedAt,
	)
}

func messageFromAfterRow(row store.ListMessagesAfterRow) Message {
	return newMessage(
		row.ID, row.ConversationID, row.SenderID, row.SenderUsername,
		row.SenderDisplayName, row.SenderAvatarContentType, row.SenderCreatedAt, row.ClientMessageID,
		row.Sequence, row.Kind, row.Body, row.ImageID, row.ImageContentType,
		row.ImageByteSize, row.FileID, row.FileFilename, row.FileContentType,
		row.FileByteSize, row.ReplyToID, row.ReplySenderID, row.ReplySenderUsername,
		row.ReplySenderDisplayName, row.ReplySenderAvatarContentType,
		row.ReplySenderCreatedAt, row.ReplyKind, row.ReplyBody,
		row.ReplyFileFilename, row.ReplyRecalledAt, row.RecalledAt, row.CreatedAt,
	)
}

func newMessage(
	id, conversationID, senderID uint64,
	username, displayName string,
	senderAvatarContentType sql.NullString,
	senderCreatedAt time.Time,
	clientMessageID string,
	sequence uint64,
	kind string,
	body string,
	imageID sql.NullInt64,
	imageContentType sql.NullString,
	imageByteSize sql.NullInt32,
	fileID sql.NullInt64,
	fileFilename sql.NullString,
	fileContentType sql.NullString,
	fileByteSize sql.NullInt64,
	replyToID sql.NullInt64,
	replySenderID sql.NullInt64,
	replySenderUsername sql.NullString,
	replySenderDisplayName sql.NullString,
	replySenderAvatarContentType sql.NullString,
	replySenderCreatedAt sql.NullTime,
	replyKind sql.NullString,
	replyBody sql.NullString,
	replyFilename sql.NullString,
	replyRecalledAt sql.NullTime,
	recalledAt sql.NullTime,
	createdAt time.Time,
) Message {
	message := Message{
		ID:             id,
		ConversationID: conversationID,
		Sender: Sender{
			ID: senderID, Username: username, DisplayName: displayName, HasAvatar: senderAvatarContentType.Valid, CreatedAt: senderCreatedAt,
		},
		ClientMessageID: clientMessageID,
		Sequence:        sequence,
		Kind:            kind,
		Body:            body,
		ReplyTo: replyFromColumns(
			replyToID, replySenderID, replySenderUsername, replySenderDisplayName,
			replySenderAvatarContentType, replySenderCreatedAt, replyKind,
			replyBody, replyFilename, replyRecalledAt,
		),
		CreatedAt: createdAt,
	}
	if recalledAt.Valid {
		value := recalledAt.Time.UTC()
		message.RecalledAt = &value
		message.Body = ""
		return message
	}
	if kind == KindImage && imageID.Valid {
		message.Image = &ImageAttachment{
			ID:          uint64(imageID.Int64),
			ContentType: imageContentType.String,
			ByteSize:    uint32(imageByteSize.Int32),
		}
	}
	if kind == KindFile && fileID.Valid {
		message.File = &FileAttachment{
			ID:          uint64(fileID.Int64),
			Filename:    fileFilename.String,
			ContentType: fileContentType.String,
			ByteSize:    uint64(fileByteSize.Int64),
		}
	}
	return message
}

func replyFromColumns(
	id, senderID sql.NullInt64,
	username, displayName, avatarContentType sql.NullString,
	senderCreatedAt sql.NullTime,
	kind, body, filename sql.NullString,
	recalledAt sql.NullTime,
) *ReplyPreview {
	if !id.Valid || !senderID.Valid || !senderCreatedAt.Valid {
		return nil
	}
	reply := &ReplyPreview{
		ID: uint64(id.Int64),
		Sender: Sender{
			ID: uint64(senderID.Int64), Username: username.String,
			DisplayName: displayName.String, HasAvatar: avatarContentType.Valid,
			CreatedAt: senderCreatedAt.Time,
		},
		Kind: kind.String, Body: body.String, Filename: filename.String,
	}
	if recalledAt.Valid {
		value := recalledAt.Time.UTC()
		reply.RecalledAt = &value
		reply.Body = ""
		reply.Filename = ""
	}
	return reply
}
