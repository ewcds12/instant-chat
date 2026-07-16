package messages

import (
	"context"
	"errors"
	"testing"
)

type fakeRepository struct {
	sentClientID string
	sentBody     string
	listedLimit  int
	messages     []Message
	err          error
}

func (f *fakeRepository) Send(
	_ context.Context,
	_, _ uint64,
	clientMessageID, body string,
) (Message, bool, error) {
	f.sentClientID = clientMessageID
	f.sentBody = body
	return Message{ID: 9, ClientMessageID: clientMessageID, Body: body}, true, f.err
}

func (f *fakeRepository) List(
	_ context.Context,
	_, _ uint64,
	_ *uint64,
	limit int,
) ([]Message, error) {
	f.listedLimit = limit
	return f.messages, f.err
}

func TestServiceSendValidatesAndTrimsBody(t *testing.T) {
	repository := &fakeRepository{}
	service := NewService(repository)

	message, created, err := service.Send(
		context.Background(), 7, 11,
		"0123456789abcdef0123456789abcdef", "  Hello.  ",
	)

	if err != nil {
		t.Fatalf("Send() error = %v", err)
	}
	if !created || message.Body != "Hello." || repository.sentBody != "Hello." {
		t.Fatalf("message = %+v, created = %t", message, created)
	}
}

func TestServiceSendRejectsInvalidClientMessageID(t *testing.T) {
	service := NewService(&fakeRepository{})

	_, _, err := service.Send(context.Background(), 7, 11, "not-an-id", "Hello.")

	var inputError *InputError
	if !errors.As(err, &inputError) {
		t.Fatalf("Send() error = %v, want InputError", err)
	}
}

func TestServiceListReturnsAscendingPageAndOlderCursor(t *testing.T) {
	repository := &fakeRepository{
		messages: []Message{
			{Sequence: 5},
			{Sequence: 4},
			{Sequence: 3},
		},
	}
	service := NewService(repository)

	page, err := service.List(context.Background(), 7, 11, nil, 2)

	if err != nil {
		t.Fatalf("List() error = %v", err)
	}
	if repository.listedLimit != 3 {
		t.Fatalf("repository limit = %d, want 3", repository.listedLimit)
	}
	if len(page.Messages) != 2 || page.Messages[0].Sequence != 4 || page.Messages[1].Sequence != 5 {
		t.Fatalf("messages = %+v", page.Messages)
	}
	if page.NextCursor == nil || *page.NextCursor != 4 {
		t.Fatalf("next cursor = %v, want 4", page.NextCursor)
	}
}
