package messages

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
)

func (s *stubMessageService) Recall(context.Context, uint64, uint64, uint64) error {
	return nil
}

func (s *stubMessageService) Delete(context.Context, uint64, uint64, uint64) error {
	return nil
}

type actionMessageService struct {
	*stubMessageService
	recalledMessageID uint64
	deletedMessageID  uint64
}

func (s *actionMessageService) Recall(
	_ context.Context,
	_, _, messageID uint64,
) error {
	s.recalledMessageID = messageID
	return nil
}

func (s *actionMessageService) Delete(
	_ context.Context,
	_, _, messageID uint64,
) error {
	s.deletedMessageID = messageID
	return nil
}

func TestHandlerRecallReturnsNoContent(t *testing.T) {
	service := &actionMessageService{stubMessageService: &stubMessageService{}}
	handler := authenticated(http.HandlerFunc(NewHandler(service).Recall))
	request := httptest.NewRequest(http.MethodPost, "/api/v1/conversations/11/messages/21/recall", nil)
	request.SetPathValue("conversation_id", "11")
	request.SetPathValue("message_id", "21")
	request.Header.Set("Authorization", "Bearer access")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusNoContent || service.recalledMessageID != 21 {
		t.Fatalf("status = %d, recalled message ID = %d", recorder.Code, service.recalledMessageID)
	}
}

func TestHandlerDeleteReturnsNoContent(t *testing.T) {
	service := &actionMessageService{stubMessageService: &stubMessageService{}}
	handler := authenticated(http.HandlerFunc(NewHandler(service).Delete))
	request := httptest.NewRequest(http.MethodDelete, "/api/v1/conversations/11/messages/21", nil)
	request.SetPathValue("conversation_id", "11")
	request.SetPathValue("message_id", "21")
	request.Header.Set("Authorization", "Bearer access")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusNoContent || service.deletedMessageID != 21 {
		t.Fatalf("status = %d, deleted message ID = %d", recorder.Code, service.deletedMessageID)
	}
}
