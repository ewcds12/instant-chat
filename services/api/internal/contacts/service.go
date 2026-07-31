package contacts

import (
	"context"

	"github.com/ewcds12/instant-chat/services/api/internal/users"
)

// Service implements contact business rules.
type Service struct {
	repository Repository
}

// NewService creates the contact service.
func NewService(repository Repository) *Service {
	return &Service{repository: repository}
}

// SearchUser finds one account by its exact normalized username.
func (s *Service) SearchUser(ctx context.Context, username string) (PublicUser, error) {
	normalized, valid := users.NormalizeUsername(username)
	if !valid {
		return PublicUser{}, &InputError{Message: "Enter a valid username."}
	}
	return s.repository.FindUserByUsername(ctx, normalized)
}

// SendRequest creates a pending relationship with an exact username.
func (s *Service) SendRequest(ctx context.Context, requesterID uint64, username string) (Request, error) {
	target, err := s.SearchUser(ctx, username)
	if err != nil {
		return Request{}, err
	}
	if requesterID == target.ID {
		return Request{}, ErrSelfRequest
	}
	return s.repository.CreateRequest(ctx, requesterID, target.ID)
}

// ListRequests returns incoming and outgoing pending requests.
func (s *Service) ListRequests(ctx context.Context, userID uint64) (RequestLists, error) {
	requests, err := s.repository.ListRequests(ctx, userID)
	if err != nil {
		return RequestLists{}, err
	}
	lists := RequestLists{Incoming: []Request{}, Outgoing: []Request{}}
	for _, request := range requests {
		if request.RequestedByUserID == userID {
			lists.Outgoing = append(lists.Outgoing, request)
		} else {
			lists.Incoming = append(lists.Incoming, request)
		}
	}
	return lists, nil
}

// AcceptRequest accepts an incoming request.
func (s *Service) AcceptRequest(ctx context.Context, userID, requestID uint64) (Contact, error) {
	return s.repository.AcceptRequestAndCreateConversation(ctx, userID, requestID)
}

// RejectRequest rejects an incoming request.
func (s *Service) RejectRequest(ctx context.Context, userID, requestID uint64) error {
	return s.repository.RejectRequest(ctx, userID, requestID)
}

// CancelRequest cancels an outgoing request that remains pending.
func (s *Service) CancelRequest(ctx context.Context, userID, requestID uint64) error {
	return s.repository.CancelRequest(ctx, userID, requestID)
}

// ListContacts returns accepted contacts ordered by display name.
func (s *Service) ListContacts(ctx context.Context, userID uint64) ([]Contact, error) {
	return s.repository.ListContacts(ctx, userID)
}

// RemoveContact removes an accepted relationship.
func (s *Service) RemoveContact(ctx context.Context, userID, contactUserID uint64) error {
	if userID == contactUserID {
		return ErrContactNotFound
	}
	return s.repository.RemoveContact(ctx, userID, contactUserID)
}
