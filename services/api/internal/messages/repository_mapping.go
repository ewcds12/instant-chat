package messages

import (
	"database/sql"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/store"
)

func messageFromClientRow(row store.GetMessageByClientIDRow) Message {
	return newMessage(
		row.ID, row.ConversationID, row.SenderID, row.SenderUsername,
		row.SenderDisplayName, row.SenderCreatedAt, row.ClientMessageID,
		row.Sequence, row.Kind, row.Body, row.ImageID, row.ImageContentType,
		row.ImageByteSize, row.CreatedAt,
	)
}

func messageFromLatestRow(row store.ListLatestMessagesRow) Message {
	return newMessage(
		row.ID, row.ConversationID, row.SenderID, row.SenderUsername,
		row.SenderDisplayName, row.SenderCreatedAt, row.ClientMessageID,
		row.Sequence, row.Kind, row.Body, row.ImageID, row.ImageContentType,
		row.ImageByteSize, row.CreatedAt,
	)
}

func messageFromBeforeRow(row store.ListMessagesBeforeRow) Message {
	return newMessage(
		row.ID, row.ConversationID, row.SenderID, row.SenderUsername,
		row.SenderDisplayName, row.SenderCreatedAt, row.ClientMessageID,
		row.Sequence, row.Kind, row.Body, row.ImageID, row.ImageContentType,
		row.ImageByteSize, row.CreatedAt,
	)
}

func messageFromAfterRow(row store.ListMessagesAfterRow) Message {
	return newMessage(
		row.ID, row.ConversationID, row.SenderID, row.SenderUsername,
		row.SenderDisplayName, row.SenderCreatedAt, row.ClientMessageID,
		row.Sequence, row.Kind, row.Body, row.ImageID, row.ImageContentType,
		row.ImageByteSize, row.CreatedAt,
	)
}

func newMessage(
	id, conversationID, senderID uint64,
	username, displayName string,
	senderCreatedAt time.Time,
	clientMessageID string,
	sequence uint64,
	kind string,
	body string,
	imageID sql.NullInt64,
	imageContentType sql.NullString,
	imageByteSize sql.NullInt32,
	createdAt time.Time,
) Message {
	message := Message{
		ID:             id,
		ConversationID: conversationID,
		Sender: Sender{
			ID: senderID, Username: username, DisplayName: displayName, CreatedAt: senderCreatedAt,
		},
		ClientMessageID: clientMessageID,
		Sequence:        sequence,
		Kind:            kind,
		Body:            body,
		CreatedAt:       createdAt,
	}
	if kind == KindImage && imageID.Valid {
		message.Image = &ImageAttachment{
			ID:          uint64(imageID.Int64),
			ContentType: imageContentType.String,
			ByteSize:    uint32(imageByteSize.Int32),
		}
	}
	return message
}
