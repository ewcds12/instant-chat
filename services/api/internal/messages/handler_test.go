package messages

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/auth"
	"github.com/ewcds12/instant-chat/services/api/internal/httpapi"
)

type stubMessageService struct {
	userID         uint64
	conversationID uint64
	clientID       string
	body           string
	image          ImageUpload
	file           FileUpload
}

func (s *stubMessageService) Send(
	_ context.Context,
	userID, conversationID uint64,
	clientID, body string,
) (Message, bool, error) {
	s.userID = userID
	s.conversationID = conversationID
	s.clientID = clientID
	s.body = body
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
		ByteSize:    uint32(len(file.Data)),
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
		Data:        []byte{1, 2, 3},
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

func TestHandlerListRejectsBeforeAndAfterTogether(t *testing.T) {
	handler := authenticated(http.HandlerFunc(NewHandler(&stubMessageService{}).List))
	request := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/conversations/11/messages?before=4&after=2",
		nil,
	)
	request.SetPathValue("conversation_id", "11")
	request.Header.Set("Authorization", "Bearer access")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusBadRequest)
	}
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
func (stubAuthService) Logout(context.Context, string, string) error {
	return nil
}

func TestHandlerSendReturnsCreatedMessage(t *testing.T) {
	service := &stubMessageService{}
	handler := authenticated(http.HandlerFunc(NewHandler(service).Send))
	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/conversations/11/messages",
		strings.NewReader(
			`{"client_message_id":"0123456789abcdef0123456789abcdef","body":"Hello."}`,
		),
	)
	request.SetPathValue("conversation_id", "11")
	request.Header.Set("Authorization", "Bearer access")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusCreated || service.userID != 7 || service.conversationID != 11 {
		t.Fatalf(
			"status = %d, user ID = %d, conversation ID = %d",
			recorder.Code, service.userID, service.conversationID,
		)
	}
}

func TestHandlerSendImageReturnsCreatedMessage(t *testing.T) {
	service := &stubMessageService{}
	handler := authenticated(http.HandlerFunc(NewHandler(service).SendImage))
	body := strings.NewReader(
		"--instant\r\n" +
			"Content-Disposition: form-data; name=\"client_message_id\"\r\n\r\n" +
			"0123456789abcdef0123456789abcdef\r\n" +
			"--instant\r\n" +
			"Content-Disposition: form-data; name=\"image\"; filename=\"image.png\"\r\n" +
			"Content-Type: image/png\r\n\r\n" +
			"\x89PNG\r\n\x1a\nimage\r\n" +
			"--instant--\r\n",
	)
	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/conversations/11/messages/images",
		body,
	)
	request.Header.Set("Content-Type", "multipart/form-data; boundary=instant")
	request.SetPathValue("conversation_id", "11")
	request.Header.Set("Authorization", "Bearer access")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusCreated || service.image.ContentType != "image/png" {
		t.Fatalf(
			"status = %d, image content type = %q",
			recorder.Code, service.image.ContentType,
		)
	}
}

func TestHandlerSendFileReturnsCreatedMessage(t *testing.T) {
	service := &stubMessageService{}
	handler := authenticated(http.HandlerFunc(NewHandler(service).SendFile))
	body := strings.NewReader(
		"--instant\r\n" +
			"Content-Disposition: form-data; name=\"client_message_id\"\r\n\r\n" +
			"0123456789abcdef0123456789abcdef\r\n" +
			"--instant\r\n" +
			"Content-Disposition: form-data; name=\"file\"; filename=\"Notes.pdf\"\r\n" +
			"Content-Type: application/pdf\r\n\r\n" +
			"%PDF-1.7\r\n" +
			"--instant--\r\n",
	)
	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/conversations/11/messages/files",
		body,
	)
	request.Header.Set("Content-Type", "multipart/form-data; boundary=instant")
	request.SetPathValue("conversation_id", "11")
	request.Header.Set("Authorization", "Bearer access")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusCreated || service.file.Filename != "Notes.pdf" {
		t.Fatalf(
			"status = %d, filename = %q",
			recorder.Code, service.file.Filename,
		)
	}
}

func TestHandlerImageReturnsBytes(t *testing.T) {
	handler := authenticated(http.HandlerFunc(NewHandler(&stubMessageService{}).Image))
	request := httptest.NewRequest(http.MethodGet, "/api/v1/message-images/5", nil)
	request.SetPathValue("image_id", "5")
	request.Header.Set("Authorization", "Bearer access")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK || recorder.Header().Get("Content-Type") != "image/png" {
		t.Fatalf("status = %d, content type = %q", recorder.Code, recorder.Header().Get("Content-Type"))
	}
}

func TestHandlerFileReturnsBytes(t *testing.T) {
	handler := authenticated(http.HandlerFunc(NewHandler(&stubMessageService{}).File))
	request := httptest.NewRequest(http.MethodGet, "/api/v1/message-files/8", nil)
	request.SetPathValue("file_id", "8")
	request.Header.Set("Authorization", "Bearer access")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK || recorder.Header().Get("Content-Type") != "application/pdf" {
		t.Fatalf("status = %d, content type = %q", recorder.Code, recorder.Header().Get("Content-Type"))
	}
	if !strings.Contains(recorder.Header().Get("Content-Disposition"), "Notes.pdf") {
		t.Fatalf("content disposition = %q", recorder.Header().Get("Content-Disposition"))
	}
}

func TestHandlerListRejectsInvalidCursor(t *testing.T) {
	handler := authenticated(http.HandlerFunc(NewHandler(&stubMessageService{}).List))
	request := httptest.NewRequest(
		http.MethodGet,
		"/api/v1/conversations/11/messages?before=zero",
		nil,
	)
	request.SetPathValue("conversation_id", "11")
	request.Header.Set("Authorization", "Bearer access")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusBadRequest)
	}
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
