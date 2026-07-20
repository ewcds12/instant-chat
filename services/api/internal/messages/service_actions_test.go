package messages

import (
	"context"
	"errors"
	"testing"
)

func (f *fakeRepository) Recall(
	_ context.Context,
	_, conversationID, messageID uint64,
) error {
	f.recalledID = messageID
	if conversationID == 0 {
		return ErrConversationNotFound
	}
	return f.err
}

func (f *fakeRepository) Delete(
	_ context.Context,
	_, conversationID, messageID uint64,
) error {
	f.deletedID = messageID
	if conversationID == 0 {
		return ErrConversationNotFound
	}
	return f.err
}

func (f *fakePublisher) PublishRecall(_ context.Context, recall Recall) {
	f.recalls = append(f.recalls, recall)
}

func TestServiceRecallPublishesToConversationMembers(t *testing.T) {
	repository := &fakeRepository{}
	publisher := &fakePublisher{}
	service := NewService(repository, publisher)

	err := service.Recall(context.Background(), 7, 11, 21)

	if err != nil || repository.recalledID != 21 {
		t.Fatalf("Recall() error = %v, message ID = %d", err, repository.recalledID)
	}
	if len(publisher.recalls) != 1 || publisher.recalls[0] != (Recall{ConversationID: 11, MessageID: 21}) {
		t.Fatalf("published recalls = %+v", publisher.recalls)
	}
}

func TestServiceRecallDoesNotPublishUnavailableMessage(t *testing.T) {
	publisher := &fakePublisher{}
	service := NewService(&fakeRepository{err: ErrRecallUnavailable}, publisher)

	err := service.Recall(context.Background(), 7, 11, 21)

	if !errors.Is(err, ErrRecallUnavailable) || len(publisher.recalls) != 0 {
		t.Fatalf("Recall() error = %v, published recalls = %+v", err, publisher.recalls)
	}
}

func TestServiceDeleteHidesOnlyTheCurrentUsersCopy(t *testing.T) {
	repository := &fakeRepository{}
	publisher := &fakePublisher{}
	service := NewService(repository, publisher)

	err := service.Delete(context.Background(), 7, 11, 21)

	if err != nil || repository.deletedID != 21 || len(publisher.recalls) != 0 {
		t.Fatalf("Delete() error = %v, message ID = %d, recalls = %+v", err, repository.deletedID, publisher.recalls)
	}
}
