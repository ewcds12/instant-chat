package messages

import (
	"bytes"
	"context"
	"errors"
	"testing"
)

func TestServiceSendFileValidatesAndPublishes(t *testing.T) {
	repository := &fakeRepository{}
	publisher := &fakePublisher{}
	service := NewService(repository, publisher)

	message, created, err := service.SendFile(
		context.Background(), 7, 11,
		"0123456789abcdef0123456789abcdef",
		FileUpload{
			Filename:    "Notes.pdf",
			ContentType: "application/pdf",
			ByteSize:    3,
			Reader:      bytes.NewReader([]byte{1, 2, 3}),
		},
	)

	if err != nil {
		t.Fatalf("SendFile() error = %v", err)
	}
	if !created || message.Kind != KindFile || repository.fileUpload == nil {
		t.Fatalf("message = %+v, created = %t", message, created)
	}
	if repository.fileUpload.Filename != "Notes.pdf" || len(publisher.messages) != 1 {
		t.Fatalf("file upload = %+v, published = %d", repository.fileUpload, len(publisher.messages))
	}
}

func TestServiceSendFileRejectsOversizedFile(t *testing.T) {
	service := NewService(&fakeRepository{}, &fakePublisher{})

	_, _, err := service.SendFile(
		context.Background(), 7, 11,
		"0123456789abcdef0123456789abcdef",
		FileUpload{
			Filename:    "large.zip",
			ContentType: "application/zip",
			ByteSize:    maximumFileBytes + 1,
			Reader:      bytes.NewReader(nil),
		},
	)

	var inputError *InputError
	if !errors.As(err, &inputError) {
		t.Fatalf("SendFile() error = %v, want InputError", err)
	}
	if inputError.Message != "File must be 2 GB or smaller." {
		t.Fatalf("InputError.Message = %q", inputError.Message)
	}
}

func TestServiceSendFileAcceptsTwoGigabyteBoundary(t *testing.T) {
	repository := &fakeRepository{}
	service := NewService(repository, &fakePublisher{})

	_, created, err := service.SendFile(
		context.Background(), 7, 11,
		"0123456789abcdef0123456789abcdef",
		FileUpload{
			Filename:    "archive.zip",
			ContentType: "application/zip",
			ByteSize:    maximumFileBytes,
			Reader:      bytes.NewReader(nil),
		},
	)

	if err != nil || !created {
		t.Fatalf("SendFile() error = %v, created = %t", err, created)
	}
	if repository.fileUpload == nil || repository.fileUpload.ByteSize != maximumFileBytes {
		t.Fatalf("file upload = %+v", repository.fileUpload)
	}
}
