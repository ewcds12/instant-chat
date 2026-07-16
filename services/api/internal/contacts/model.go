// Package contacts manages contact requests and accepted contact relationships.
package contacts

import (
	"context"
	"errors"
	"time"
)

var (
	// ErrUserNotFound indicates that an exact username did not match an account.
	ErrUserNotFound = errors.New("user not found")
	// ErrSelfRequest indicates that a user targeted their own account.
	ErrSelfRequest = errors.New("cannot add yourself as a contact")
	// ErrRequestExists indicates that the pair already has a pending request.
	ErrRequestExists = errors.New("contact request already exists")
	// ErrAlreadyContacts indicates that the pair already has an accepted relationship.
	ErrAlreadyContacts = errors.New("users are already contacts")
	// ErrRequestNotFound hides requests that the current user cannot act on.
	ErrRequestNotFound = errors.New("contact request not found")
	// ErrContactNotFound indicates that an accepted relationship does not exist.
	ErrContactNotFound = errors.New("contact not found")
)

// InputError identifies a safe validation message for the client.
type InputError struct {
	Message string
}

func (e *InputError) Error() string {
	return e.Message
}

// PublicUser contains the account fields visible outside authentication.
type PublicUser struct {
	ID          uint64
	Username    string
	DisplayName string
	CreatedAt   time.Time
}

// Request is a pending relationship and the other account in the pair.
type Request struct {
	ID                uint64
	RequestedByUserID uint64
	User              PublicUser
	CreatedAt         time.Time
	UpdatedAt         time.Time
}

// RequestLists separates requests that can be acted on from requests sent by the user.
type RequestLists struct {
	Incoming []Request
	Outgoing []Request
}

// Contact is an accepted relationship and the other account in the pair.
type Contact struct {
	RelationshipID uint64
	User           PublicUser
	ConnectedAt    time.Time
}

// Repository defines persistence required by contact use cases.
type Repository interface {
	FindUserByUsername(ctx context.Context, username string) (PublicUser, error)
	CreateRequest(ctx context.Context, requesterID, addresseeID uint64) (Request, error)
	ListRequests(ctx context.Context, userID uint64) ([]Request, error)
	AcceptRequest(ctx context.Context, userID, requestID uint64) (Contact, error)
	RejectRequest(ctx context.Context, userID, requestID uint64) error
	ListContacts(ctx context.Context, userID uint64) ([]Contact, error)
	RemoveContact(ctx context.Context, userID, contactUserID uint64) error
	AreContacts(ctx context.Context, firstUserID, secondUserID uint64) (bool, error)
}
