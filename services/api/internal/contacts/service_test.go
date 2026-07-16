package contacts

import (
	"context"
	"errors"
	"testing"
	"time"
)

type fakeRepository struct {
	user             PublicUser
	findError        error
	createdRequester uint64
	createdAddressee uint64
	requests         []Request
}

func (f *fakeRepository) FindUserByUsername(context.Context, string) (PublicUser, error) {
	return f.user, f.findError
}

func (f *fakeRepository) CreateRequest(_ context.Context, requesterID, addresseeID uint64) (Request, error) {
	f.createdRequester = requesterID
	f.createdAddressee = addresseeID
	return Request{ID: 9, RequestedByUserID: requesterID, User: f.user}, nil
}

func (f *fakeRepository) ListRequests(context.Context, uint64) ([]Request, error) {
	return f.requests, nil
}

func (f *fakeRepository) AcceptRequest(context.Context, uint64, uint64) (Contact, error) {
	return Contact{}, nil
}

func (f *fakeRepository) RejectRequest(context.Context, uint64, uint64) error { return nil }

func (f *fakeRepository) ListContacts(context.Context, uint64) ([]Contact, error) { return nil, nil }

func (f *fakeRepository) RemoveContact(context.Context, uint64, uint64) error { return nil }

func (f *fakeRepository) AreContacts(context.Context, uint64, uint64) (bool, error) {
	return false, nil
}

func TestServiceSendRequestNormalizesUsername(t *testing.T) {
	repository := &fakeRepository{user: PublicUser{ID: 8, Username: "other_user"}}
	service := NewService(repository)

	request, err := service.SendRequest(context.Background(), 7, " OTHER_USER ")
	if err != nil {
		t.Fatalf("SendRequest() error = %v", err)
	}
	if request.ID != 9 || repository.createdRequester != 7 || repository.createdAddressee != 8 {
		t.Fatalf("request = %+v, requester = %d, addressee = %d", request, repository.createdRequester, repository.createdAddressee)
	}
}

func TestServiceSendRequestRejectsSelf(t *testing.T) {
	service := NewService(&fakeRepository{user: PublicUser{ID: 7, Username: "retro_user"}})

	_, err := service.SendRequest(context.Background(), 7, "retro_user")
	if !errors.Is(err, ErrSelfRequest) {
		t.Fatalf("SendRequest() error = %v, want ErrSelfRequest", err)
	}
}

func TestServiceListRequestsSeparatesDirection(t *testing.T) {
	now := time.Date(2026, time.July, 16, 12, 0, 0, 0, time.UTC)
	repository := &fakeRepository{requests: []Request{
		{ID: 1, RequestedByUserID: 7, CreatedAt: now},
		{ID: 2, RequestedByUserID: 8, CreatedAt: now},
	}}

	lists, err := NewService(repository).ListRequests(context.Background(), 7)
	if err != nil {
		t.Fatalf("ListRequests() error = %v", err)
	}
	if len(lists.Outgoing) != 1 || lists.Outgoing[0].ID != 1 || len(lists.Incoming) != 1 || lists.Incoming[0].ID != 2 {
		t.Fatalf("request lists = %+v", lists)
	}
}

func TestServiceSearchRejectsInvalidUsername(t *testing.T) {
	_, err := NewService(&fakeRepository{}).SearchUser(context.Background(), "2invalid")
	var inputError *InputError
	if !errors.As(err, &inputError) {
		t.Fatalf("SearchUser() error = %v, want InputError", err)
	}
}
