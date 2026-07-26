package messages

import (
	"context"
	"errors"
	"testing"
)

type fakeRepository struct {
	sentClientID string
	sentBody     string
	imageUpload  *ImageUpload
	fileUpload   *FileUpload
	recalledID   uint64
	deletedID    uint64
	listedLimit  int
	messages     []Message
	idempotent   bool
	err          error
}

func (f *fakeRepository) Send(
	_ context.Context,
	_, _ uint64,
	clientMessageID, body string,
) (Message, bool, error) {
	f.sentClientID = clientMessageID
	f.sentBody = body
	return Message{ID: 9, ClientMessageID: clientMessageID, Body: body}, !f.idempotent, f.err
}

func (f *fakeRepository) SendImage(
	_ context.Context,
	_, _ uint64,
	clientMessageID string,
	upload ImageUpload,
) (Message, bool, error) {
	f.sentClientID = clientMessageID
	f.imageUpload = &upload
	return Message{
		ID:              9,
		ClientMessageID: clientMessageID,
		Kind:            KindImage,
		Image:           &ImageAttachment{ID: 3, ContentType: upload.ContentType, ByteSize: uint32(len(upload.Data))},
	}, !f.idempotent, f.err
}

func (f *fakeRepository) SendFile(
	_ context.Context,
	_, _ uint64,
	clientMessageID string,
	upload FileUpload,
) (Message, bool, error) {
	f.sentClientID = clientMessageID
	f.fileUpload = &upload
	return Message{
		ID:              9,
		ClientMessageID: clientMessageID,
		Kind:            KindFile,
		File: &FileAttachment{
			ID:          4,
			Filename:    upload.Filename,
			ContentType: upload.ContentType,
			ByteSize:    uint64(upload.ByteSize),
		},
	}, !f.idempotent, f.err
}

func (f *fakeRepository) Image(context.Context, uint64, uint64) (ImageFile, error) {
	return ImageFile{}, f.err
}

func (f *fakeRepository) File(context.Context, uint64, uint64) (MessageFile, error) {
	return MessageFile{}, f.err
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

func (f *fakeRepository) ListAfter(
	_ context.Context,
	_, _, _ uint64,
	limit int,
) ([]Message, error) {
	f.listedLimit = limit
	return f.messages, f.err
}

type fakePublisher struct {
	messages []Message
	recalls  []Recall
}

func (f *fakePublisher) PublishMessage(_ context.Context, message Message) {
	f.messages = append(f.messages, message)
}

func TestServiceSendValidatesAndTrimsBody(t *testing.T) {
	repository := &fakeRepository{}
	publisher := &fakePublisher{}
	service := NewService(repository, publisher)

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
	if len(publisher.messages) != 1 {
		t.Fatalf("published messages = %d, want 1", len(publisher.messages))
	}
}

func TestServiceSendRejectsInvalidClientMessageID(t *testing.T) {
	service := NewService(&fakeRepository{}, &fakePublisher{})

	_, _, err := service.Send(context.Background(), 7, 11, "not-an-id", "Hello.")

	var inputError *InputError
	if !errors.As(err, &inputError) {
		t.Fatalf("Send() error = %v, want InputError", err)
	}
}

func TestServiceSendDoesNotRepublishIdempotentMessage(t *testing.T) {
	publisher := &fakePublisher{}
	service := NewService(&fakeRepository{idempotent: true}, publisher)

	_, created, err := service.Send(
		context.Background(), 7, 11,
		"0123456789abcdef0123456789abcdef", "Hello.",
	)

	if err != nil || created || len(publisher.messages) != 0 {
		t.Fatalf(
			"Send() error = %v, created = %t, published = %d",
			err, created, len(publisher.messages),
		)
	}
}

func TestServiceSendImageValidatesAndPublishes(t *testing.T) {
	repository := &fakeRepository{}
	publisher := &fakePublisher{}
	service := NewService(repository, publisher)

	message, created, err := service.SendImage(
		context.Background(), 7, 11,
		"0123456789abcdef0123456789abcdef",
		ImageUpload{ContentType: "image/png", Data: []byte{1, 2, 3}},
	)

	if err != nil {
		t.Fatalf("SendImage() error = %v", err)
	}
	if !created || message.Kind != KindImage || repository.imageUpload == nil {
		t.Fatalf("message = %+v, created = %t", message, created)
	}
	if len(publisher.messages) != 1 {
		t.Fatalf("published messages = %d, want 1", len(publisher.messages))
	}
}

func TestServiceSendImageRejectsUnsupportedContentType(t *testing.T) {
	service := NewService(&fakeRepository{}, &fakePublisher{})

	_, _, err := service.SendImage(
		context.Background(), 7, 11,
		"0123456789abcdef0123456789abcdef",
		ImageUpload{ContentType: "text/plain", Data: []byte("nope")},
	)

	var inputError *InputError
	if !errors.As(err, &inputError) {
		t.Fatalf("SendImage() error = %v, want InputError", err)
	}
}

func TestServiceSendImageRejectsOversizedImage(t *testing.T) {
	service := NewService(&fakeRepository{}, &fakePublisher{})

	_, _, err := service.SendImage(
		context.Background(), 7, 11,
		"0123456789abcdef0123456789abcdef",
		ImageUpload{
			ContentType: "image/png",
			Data:        make([]byte, maximumImageBytes+1),
		},
	)

	var inputError *InputError
	if !errors.As(err, &inputError) {
		t.Fatalf("SendImage() error = %v, want InputError", err)
	}
	if inputError.Message != "Image must be 15 MB or smaller." {
		t.Fatalf("InputError.Message = %q", inputError.Message)
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
	service := NewService(repository, &fakePublisher{})

	page, err := service.List(context.Background(), 7, 11, nil, nil, 2)

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

func TestServiceListAfterReturnsCatchUpCursor(t *testing.T) {
	after := uint64(2)
	repository := &fakeRepository{messages: []Message{
		{Sequence: 3},
		{Sequence: 4},
		{Sequence: 5},
	}}
	service := NewService(repository, &fakePublisher{})

	page, err := service.List(context.Background(), 7, 11, nil, &after, 2)

	if err != nil {
		t.Fatalf("List() error = %v", err)
	}
	if len(page.Messages) != 2 || page.Messages[0].Sequence != 3 || page.Messages[1].Sequence != 4 {
		t.Fatalf("messages = %+v", page.Messages)
	}
	if page.NextCursor == nil || *page.NextCursor != 4 {
		t.Fatalf("next cursor = %v, want 4", page.NextCursor)
	}
}
