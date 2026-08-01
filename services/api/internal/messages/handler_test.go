package messages

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

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

func TestHandlerSendReturnsCreatedMessage(t *testing.T) {
	service := &stubMessageService{}
	handler := authenticated(http.HandlerFunc(NewHandler(service).Send))
	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/conversations/11/messages",
		strings.NewReader(
			`{"client_message_id":"0123456789abcdef0123456789abcdef","body":"Hello.","reply_to_message_id":"8"}`,
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
	if service.replyToID == nil || *service.replyToID != 8 {
		t.Fatalf("reply-to ID = %v, want 8", service.replyToID)
	}
}

func TestResponseFromMessageIncludesSenderAvatarURL(t *testing.T) {
	message := testMessage()
	message.Sender.HasAvatar = true

	response := responseFromMessage(message)

	if response.Sender.AvatarURL == nil || *response.Sender.AvatarURL != "/api/v1/users/7/avatar" {
		t.Fatalf("sender avatar URL = %v, want /api/v1/users/7/avatar", response.Sender.AvatarURL)
	}
}

func TestResponseFromMessageIncludesRecallTime(t *testing.T) {
	message := testMessage()
	recalledAt := time.Date(2026, 7, 16, 13, 5, 0, 0, time.UTC)
	message.RecalledAt = &recalledAt

	response := responseFromMessage(message)

	if response.RecalledAt == nil || !response.RecalledAt.Equal(recalledAt) {
		t.Fatalf("recalled at = %v, want %v", response.RecalledAt, recalledAt)
	}
}

func TestResponseFromMessageIncludesReplyPreview(t *testing.T) {
	message := testMessage()
	message.ReplyTo = &ReplyPreview{
		ID: 8,
		Sender: Sender{
			ID: 9, Username: "peer", DisplayName: "Peer",
			CreatedAt: time.Date(2026, 7, 16, 12, 0, 0, 0, time.UTC),
		},
		Kind: KindText, Body: "Original",
	}

	response := responseFromMessage(message)

	if response.ReplyTo == nil || response.ReplyTo.ID != "8" || response.ReplyTo.Body != "Original" {
		t.Fatalf("reply preview = %+v", response.ReplyTo)
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
