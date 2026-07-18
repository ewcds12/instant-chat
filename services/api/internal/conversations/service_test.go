package conversations

import (
	"context"
	"errors"
	"testing"
)

type fakeRepository struct {
	createdUserID      uint64
	createdContactID   uint64
	readUserID         uint64
	readConversationID uint64
	readSequence       uint64
}

func (f *fakeRepository) CreateDirect(_ context.Context, userID, contactUserID uint64) (Conversation, bool, error) {
	f.createdUserID = userID
	f.createdContactID = contactUserID
	return Conversation{ID: 11, Kind: "direct"}, true, nil
}

func (f *fakeRepository) List(context.Context, uint64) ([]Conversation, error) {
	return []Conversation{}, nil
}

func (f *fakeRepository) MarkRead(_ context.Context, userID, conversationID, sequence uint64) error {
	f.readUserID = userID
	f.readConversationID = conversationID
	f.readSequence = sequence
	return nil
}

type fakeContactChecker struct {
	accepted bool
	err      error
}

func (f fakeContactChecker) AreContacts(context.Context, uint64, uint64) (bool, error) {
	return f.accepted, f.err
}

func TestServiceCreateDirectRequiresAcceptedContact(t *testing.T) {
	service := NewService(&fakeRepository{}, fakeContactChecker{})

	_, _, err := service.CreateDirect(context.Background(), 7, 8)
	if !errors.Is(err, ErrNotContact) {
		t.Fatalf("CreateDirect() error = %v, want ErrNotContact", err)
	}
}

func TestServiceCreateDirectDelegatesAcceptedPair(t *testing.T) {
	repository := &fakeRepository{}
	service := NewService(repository, fakeContactChecker{accepted: true})

	conversation, created, err := service.CreateDirect(context.Background(), 7, 8)
	if err != nil {
		t.Fatalf("CreateDirect() error = %v", err)
	}
	if !created || conversation.ID != 11 || repository.createdUserID != 7 || repository.createdContactID != 8 {
		t.Fatalf("conversation = %+v, created = %t", conversation, created)
	}
}

func TestServiceCreateDirectRejectsSelf(t *testing.T) {
	service := NewService(&fakeRepository{}, fakeContactChecker{accepted: true})

	_, _, err := service.CreateDirect(context.Background(), 7, 7)
	if !errors.Is(err, ErrSelfConversation) {
		t.Fatalf("CreateDirect() error = %v, want ErrSelfConversation", err)
	}
}

func TestServiceMarkReadDelegatesSequence(t *testing.T) {
	repository := &fakeRepository{}
	service := NewService(repository, fakeContactChecker{})

	if err := service.MarkRead(context.Background(), 7, 11, 9); err != nil {
		t.Fatalf("MarkRead() error = %v", err)
	}
	if repository.readUserID != 7 || repository.readConversationID != 11 || repository.readSequence != 9 {
		t.Fatalf("read call = %+v", repository)
	}
}

func TestServiceMarkReadRejectsZeroSequence(t *testing.T) {
	service := NewService(&fakeRepository{}, fakeContactChecker{})

	err := service.MarkRead(context.Background(), 7, 11, 0)
	if !errors.Is(err, ErrInvalidReadSequence) {
		t.Fatalf("MarkRead() error = %v, want ErrInvalidReadSequence", err)
	}
}
