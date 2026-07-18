package messages

import (
	"mime"
	"strconv"
	"time"
)

type senderResponse struct {
	ID          string    `json:"id"`
	Username    string    `json:"username"`
	DisplayName string    `json:"display_name"`
	AvatarURL   *string   `json:"avatar_url"`
	CreatedAt   time.Time `json:"created_at"`
}

type messageResponse struct {
	ID              string         `json:"id"`
	ConversationID  string         `json:"conversation_id"`
	Sender          senderResponse `json:"sender"`
	ClientMessageID string         `json:"client_message_id"`
	Sequence        string         `json:"sequence"`
	Kind            string         `json:"kind"`
	Body            string         `json:"body"`
	Image           *imageResponse `json:"image"`
	File            *fileResponse  `json:"file"`
	CreatedAt       time.Time      `json:"created_at"`
}

type imageResponse struct {
	ID          string `json:"id"`
	URL         string `json:"url"`
	ContentType string `json:"content_type"`
	ByteSize    uint32 `json:"byte_size"`
}

type fileResponse struct {
	ID          string `json:"id"`
	URL         string `json:"url"`
	Filename    string `json:"filename"`
	ContentType string `json:"content_type"`
	ByteSize    uint32 `json:"byte_size"`
}

func responseFromMessage(message Message) messageResponse {
	response := messageResponse{
		ID:             strconv.FormatUint(message.ID, 10),
		ConversationID: strconv.FormatUint(message.ConversationID, 10),
		Sender: senderResponse{
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
	if response.Kind == "" {
		response.Kind = KindText
	}
	if message.Sender.HasAvatar {
		url := "/api/v1/users/" + response.Sender.ID + "/avatar"
		response.Sender.AvatarURL = &url
	}
	if message.Image != nil {
		response.Image = responseFromImage(message.Image)
	}
	if message.File != nil {
		response.File = responseFromFile(message.File)
	}
	return response
}

func responseFromImage(image *ImageAttachment) *imageResponse {
	imageID := strconv.FormatUint(image.ID, 10)
	return &imageResponse{
		ID:          imageID,
		URL:         "/api/v1/message-images/" + imageID,
		ContentType: image.ContentType,
		ByteSize:    image.ByteSize,
	}
}

func responseFromFile(file *FileAttachment) *fileResponse {
	fileID := strconv.FormatUint(file.ID, 10)
	return &fileResponse{
		ID:          fileID,
		URL:         "/api/v1/message-files/" + fileID,
		Filename:    file.Filename,
		ContentType: file.ContentType,
		ByteSize:    file.ByteSize,
	}
}

func attachmentDisposition(filename string) string {
	return mime.FormatMediaType("attachment", map[string]string{"filename": filename})
}
