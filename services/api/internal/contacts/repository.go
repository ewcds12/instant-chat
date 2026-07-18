package contacts

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/go-sql-driver/mysql"

	"github.com/ewcds12/instant-chat/services/api/internal/store"
)

// MySQLRepository persists contact relationships through sqlc queries.
type MySQLRepository struct {
	queries *store.Queries
}

// NewMySQLRepository creates the production contact repository.
func NewMySQLRepository(database *sql.DB) *MySQLRepository {
	return &MySQLRepository{queries: store.New(database)}
}

// FindUserByUsername returns an account's public identity.
func (r *MySQLRepository) FindUserByUsername(ctx context.Context, username string) (PublicUser, error) {
	user, err := r.queries.FindPublicUserByUsername(ctx, username)
	if errors.Is(err, sql.ErrNoRows) {
		return PublicUser{}, ErrUserNotFound
	}
	if err != nil {
		return PublicUser{}, fmt.Errorf("find user by username: %w", err)
	}
	return PublicUser{ID: user.ID, Username: user.Username, DisplayName: user.DisplayName, HasAvatar: user.AvatarContentType.Valid, CreatedAt: user.CreatedAt}, nil
}

// CreateRequest inserts a unique pending relationship for the user pair.
func (r *MySQLRepository) CreateRequest(ctx context.Context, requesterID, addresseeID uint64) (Request, error) {
	lowerID, higherID := orderedPair(requesterID, addresseeID)
	result, err := r.queries.CreateContactRelationship(ctx, store.CreateContactRelationshipParams{
		LowerUserID: lowerID, HigherUserID: higherID, RequestedByUserID: requesterID,
	})
	if err != nil {
		return Request{}, r.mapDuplicateRelationship(ctx, lowerID, higherID, err)
	}
	requestID, err := result.LastInsertId()
	if err != nil || requestID <= 0 {
		return Request{}, fmt.Errorf("read contact request ID: %w", err)
	}
	return r.getRequest(ctx, requesterID, uint64(requestID))
}

// ListRequests returns every pending relationship involving the user.
func (r *MySQLRepository) ListRequests(ctx context.Context, userID uint64) ([]Request, error) {
	rows, err := r.queries.ListPendingContactRelationships(ctx, store.ListPendingContactRelationshipsParams{CurrentUserID: userID})
	if err != nil {
		return nil, fmt.Errorf("list contact requests: %w", err)
	}
	requests := make([]Request, 0, len(rows))
	for _, row := range rows {
		requests = append(requests, requestFromPendingRow(row))
	}
	return requests, nil
}

// AcceptRequest transitions an incoming pending request to accepted.
func (r *MySQLRepository) AcceptRequest(ctx context.Context, userID, requestID uint64) (Contact, error) {
	result, err := r.queries.AcceptContactRelationship(ctx, store.AcceptContactRelationshipParams{
		RelationshipID: requestID, CurrentUserID: userID,
	})
	if err != nil {
		return Contact{}, fmt.Errorf("accept contact request: %w", err)
	}
	if affected, err := result.RowsAffected(); err != nil || affected != 1 {
		return Contact{}, ErrRequestNotFound
	}
	request, err := r.getRequest(ctx, userID, requestID)
	if err != nil {
		return Contact{}, err
	}
	return Contact{RelationshipID: request.ID, User: request.User, ConnectedAt: request.UpdatedAt}, nil
}

// RejectRequest removes an incoming pending request.
func (r *MySQLRepository) RejectRequest(ctx context.Context, userID, requestID uint64) error {
	result, err := r.queries.RejectContactRelationship(ctx, store.RejectContactRelationshipParams{
		RelationshipID: requestID, CurrentUserID: userID,
	})
	if err != nil {
		return fmt.Errorf("reject contact request: %w", err)
	}
	return requireOneRow(result, ErrRequestNotFound)
}

// ListContacts returns accepted relationships involving the user.
func (r *MySQLRepository) ListContacts(ctx context.Context, userID uint64) ([]Contact, error) {
	rows, err := r.queries.ListAcceptedContacts(ctx, store.ListAcceptedContactsParams{CurrentUserID: userID})
	if err != nil {
		return nil, fmt.Errorf("list contacts: %w", err)
	}
	contacts := make([]Contact, 0, len(rows))
	for _, row := range rows {
		contacts = append(contacts, Contact{
			RelationshipID: row.RelationshipID,
			User:           PublicUser{ID: row.UserID, Username: row.Username, DisplayName: row.DisplayName, HasAvatar: row.AvatarContentType.Valid, CreatedAt: row.CreatedAt},
			ConnectedAt:    row.ConnectedAt,
		})
	}
	return contacts, nil
}

// RemoveContact deletes an accepted relationship.
func (r *MySQLRepository) RemoveContact(ctx context.Context, userID, contactUserID uint64) error {
	lowerID, higherID := orderedPair(userID, contactUserID)
	result, err := r.queries.RemoveAcceptedContact(ctx, store.RemoveAcceptedContactParams{
		LowerUserID: lowerID, HigherUserID: higherID,
	})
	if err != nil {
		return fmt.Errorf("remove contact: %w", err)
	}
	return requireOneRow(result, ErrContactNotFound)
}

// AreContacts reports whether the pair has an accepted relationship.
func (r *MySQLRepository) AreContacts(ctx context.Context, firstUserID, secondUserID uint64) (bool, error) {
	lowerID, higherID := orderedPair(firstUserID, secondUserID)
	status, err := r.queries.ContactRelationshipStatus(ctx, store.ContactRelationshipStatusParams{
		LowerUserID: lowerID, HigherUserID: higherID,
	})
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("read contact relationship: %w", err)
	}
	return status == "accepted", nil
}

func (r *MySQLRepository) getRequest(ctx context.Context, userID, requestID uint64) (Request, error) {
	row, err := r.queries.GetContactRelationshipByID(ctx, store.GetContactRelationshipByIDParams{
		CurrentUserID: userID, RelationshipID: requestID,
	})
	if errors.Is(err, sql.ErrNoRows) {
		return Request{}, ErrRequestNotFound
	}
	if err != nil {
		return Request{}, fmt.Errorf("read contact request: %w", err)
	}
	return requestFromRelationshipRow(row), nil
}

func (r *MySQLRepository) mapDuplicateRelationship(ctx context.Context, lowerID, higherID uint64, cause error) error {
	var mysqlError *mysql.MySQLError
	if !errors.As(cause, &mysqlError) || mysqlError.Number != 1062 {
		return fmt.Errorf("create contact request: %w", cause)
	}
	status, err := r.queries.ContactRelationshipStatus(ctx, store.ContactRelationshipStatusParams{
		LowerUserID: lowerID, HigherUserID: higherID,
	})
	if err != nil {
		return fmt.Errorf("resolve duplicate contact request: %w", err)
	}
	if status == "accepted" {
		return ErrAlreadyContacts
	}
	return ErrRequestExists
}

func orderedPair(firstID, secondID uint64) (uint64, uint64) {
	if firstID < secondID {
		return firstID, secondID
	}
	return secondID, firstID
}

func requireOneRow(result sql.Result, notFound error) error {
	affected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("read affected rows: %w", err)
	}
	if affected != 1 {
		return notFound
	}
	return nil
}

func requestFromRelationshipRow(row store.GetContactRelationshipByIDRow) Request {
	return Request{
		ID: row.ID, RequestedByUserID: row.RequestedByUserID,
		User:      PublicUser{ID: row.OtherUserID, Username: row.OtherUsername, DisplayName: row.OtherDisplayName, HasAvatar: row.OtherAvatarContentType.Valid, CreatedAt: row.OtherCreatedAt},
		CreatedAt: row.CreatedAt, UpdatedAt: row.UpdatedAt,
	}
}

func requestFromPendingRow(row store.ListPendingContactRelationshipsRow) Request {
	return Request{
		ID: row.ID, RequestedByUserID: row.RequestedByUserID,
		User:      PublicUser{ID: row.OtherUserID, Username: row.OtherUsername, DisplayName: row.OtherDisplayName, HasAvatar: row.OtherAvatarContentType.Valid, CreatedAt: row.OtherCreatedAt},
		CreatedAt: row.CreatedAt, UpdatedAt: row.UpdatedAt,
	}
}
