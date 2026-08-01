package messages

import (
	"context"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/auth"
	"github.com/ewcds12/instant-chat/services/api/internal/httpapi"
)

type stubMessageService struct {
	userID         uint64
	conversationID uint64
	clientID       string
	body           string
	replyToID      *uint64
	image          ImageUpload
	file           FileUpload
}

func (s *stubMessageService) Send(
	_ context.Context,
	userID, conversationID uint64,
	clientID, body string,
	replyToMessageID *uint64,
) (Message, bool, error) {
	s.userID = userID
	s.conversationID = conversationID
	s.clientID = clientID
	s.body = body
	s.replyToID = replyToMessageID
	return testMessage(), true, nil
}

func (s *stubMessageService) SendImage(
	_ context.Context,
	userID, conversationID uint64,
	clientID string,
	image ImageUpload,
) (Message, bool, error) {
	s.userID = userID
	s.conversationID = conversationID
	s.clientID = clientID
	s.image = image
	message := testMessage()
	message.Kind = KindImage
	message.Body = ""
	message.Image = &ImageAttachment{ID: 5, ContentType: image.ContentType, ByteSize: uint32(len(image.Data))}
	return message, true, nil
}

func (s *stubMessageService) SendFile(
	_ context.Context,
	userID, conversationID uint64,
	clientID string,
	file FileUpload,
) (Message, bool, error) {
	s.userID = userID
	s.conversationID = conversationID
	s.clientID = clientID
	s.file = file
	message := testMessage()
	message.Kind = KindFile
	message.Body = ""
	message.File = &FileAttachment{
		ID:          8,
		Filename:    file.Filename,
		ContentType: file.ContentType,
		ByteSize:    uint64(file.ByteSize),
	}
	return message, true, nil
}

func (s *stubMessageService) Image(context.Context, uint64, uint64) (ImageFile, error) {
	return ImageFile{ContentType: "image/png", ByteSize: 3, Data: []byte{1, 2, 3}}, nil
}

func (s *stubMessageService) File(context.Context, uint64, uint64) (MessageFile, error) {
	return MessageFile{
		Filename:    "Notes.pdf",
		ContentType: "application/pdf",
		ByteSize:    3,
		Content:     io.NopCloser(strings.NewReader("PDF")),
	}, nil
}

func (s *stubMessageService) List(
	context.Context,
	uint64,
	uint64,
	*uint64,
	*uint64,
	int,
) (Page, error) {
	cursor := uint64(3)
	return Page{Messages: []Message{testMessage()}, NextCursor: &cursor}, nil
}

type stubAuthService struct{}

func (stubAuthService) Register(context.Context, string, string, string) (auth.Session, error) {
	return auth.Session{}, nil
}

func (stubAuthService) Login(context.Context, string, string) (auth.Session, error) {
	return auth.Session{}, nil
}

func (stubAuthService) Refresh(context.Context, string) (auth.Session, error) {
	return auth.Session{}, nil
}

func (stubAuthService) CurrentUser(context.Context, string) (auth.User, error) {
	return auth.User{ID: 7, Username: "retro_user"}, nil
}

func (stubAuthService) UpdateProfile(context.Context, uint64, auth.ProfileInput) (auth.User, error) {
	return auth.User{}, nil
}

func (stubAuthService) UpdateAvatar(context.Context, uint64, auth.AvatarUpload) (auth.User, error) {
	return auth.User{}, nil
}

func (stubAuthService) Avatar(context.Context, uint64) (auth.Avatar, error) {
	return auth.Avatar{}, nil
}

func (stubAuthService) Logout(context.Context, string, string) error {
	return nil
}

func authenticated(next http.Handler) http.Handler {
	authHandler := auth.NewHandler(stubAuthService{})
	return httpapi.RequestIDMiddleware(authHandler.RequireUser(next))
}

func testMessage() Message {
	return Message{
		ID:             21,
		ConversationID: 11,
		Sender: Sender{
			ID: 7, Username: "retro_user", DisplayName: "Retro User",
			CreatedAt: time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC),
		},
		ClientMessageID: "0123456789abcdef0123456789abcdef",
		Sequence:        4,
		Kind:            KindText,
		Body:            "Hello.",
		CreatedAt:       time.Date(2026, 7, 16, 13, 0, 0, 0, time.UTC),
	}
}
