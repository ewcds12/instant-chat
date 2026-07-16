package realtime

import (
	"strconv"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/messages"
)

type eventEnvelope struct {
	EventID    string         `json:"event_id"`
	Type       string         `json:"type"`
	Version    int            `json:"version"`
	OccurredAt time.Time      `json:"occurred_at"`
	Payload    messagePayload `json:"payload"`
}

type messagePayload struct {
	Message messageEvent `json:"message"`
}

type messageEvent struct {
	ID              string      `json:"id"`
	ConversationID  string      `json:"conversation_id"`
	Sender          senderEvent `json:"sender"`
	ClientMessageID string      `json:"client_message_id"`
	Sequence        string      `json:"sequence"`
	Kind            string      `json:"kind"`
	Body            string      `json:"body"`
	Image           *imageEvent `json:"image"`
	CreatedAt       time.Time   `json:"created_at"`
}

type imageEvent struct {
	ID          string `json:"id"`
	URL         string `json:"url"`
	ContentType string `json:"content_type"`
	ByteSize    uint32 `json:"byte_size"`
}

type senderEvent struct {
	ID          string    `json:"id"`
	Username    string    `json:"username"`
	DisplayName string    `json:"display_name"`
	CreatedAt   time.Time `json:"created_at"`
}

func messageCreatedEvent(message messages.Message) eventEnvelope {
	body := messageEvent{
		ID:             strconv.FormatUint(message.ID, 10),
		ConversationID: strconv.FormatUint(message.ConversationID, 10),
		Sender: senderEvent{
			ID:          strconv.FormatUint(message.Sender.ID, 10),
			Username:    message.Sender.Username,
			DisplayName: message.Sender.DisplayName,
			CreatedAt:   message.Sender.CreatedAt.UTC(),
		},
		ClientMessageID: message.ClientMessageID,
		Sequence:        strconv.FormatUint(message.Sequence, 10),
		Kind:            message.Kind,
		Body:            message.Body,
		CreatedAt:       message.CreatedAt.UTC(),
	}
	if body.Kind == "" {
		body.Kind = messages.KindText
	}
	if message.Image != nil {
		imageID := strconv.FormatUint(message.Image.ID, 10)
		body.Image = &imageEvent{
			ID:          imageID,
			URL:         "/api/v1/message-images/" + imageID,
			ContentType: message.Image.ContentType,
			ByteSize:    message.Image.ByteSize,
		}
	}
	return eventEnvelope{
		EventID:    "message:" + strconv.FormatUint(message.ID, 10),
		Type:       "message.created",
		Version:    1,
		OccurredAt: message.CreatedAt.UTC(),
		Payload:    messagePayload{Message: body},
	}
}
