package conversations

import "context"

type contactChecker interface {
	AreContacts(ctx context.Context, firstUserID, secondUserID uint64) (bool, error)
}

// Service implements direct-conversation business rules.
type Service struct {
	repository Repository
	contacts   contactChecker
}

// NewService creates the conversation service.
func NewService(repository Repository, contacts contactChecker) *Service {
	return &Service{repository: repository, contacts: contacts}
}

// CreateDirect returns the unique direct conversation for an accepted contact.
func (s *Service) CreateDirect(ctx context.Context, userID, contactUserID uint64) (Conversation, bool, error) {
	if userID == contactUserID {
		return Conversation{}, false, ErrSelfConversation
	}
	accepted, err := s.contacts.AreContacts(ctx, userID, contactUserID)
	if err != nil {
		return Conversation{}, false, err
	}
	if !accepted {
		return Conversation{}, false, ErrNotContact
	}
	return s.repository.CreateDirect(ctx, userID, contactUserID)
}

// List returns the user's direct conversations in most-recently-updated order.
func (s *Service) List(ctx context.Context, userID uint64) ([]Conversation, error) {
	return s.repository.List(ctx, userID)
}

// MarkRead records the latest message sequence seen by the current member.
func (s *Service) MarkRead(ctx context.Context, userID, conversationID, sequence uint64) error {
	if sequence == 0 {
		return ErrInvalidReadSequence
	}
	return s.repository.MarkRead(ctx, userID, conversationID, sequence)
}
