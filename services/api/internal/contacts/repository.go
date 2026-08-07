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
	database *sql.DB
	queries  *store.Queries
}

// NewMySQLRepository creates the production contact repository.
func NewMySQLRepository(database *sql.DB) *MySQLRepository {
	return &MySQLRepository{database: database, queries: store.New(database)}
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

// AcceptRequestAndCreateConversation accepts a request and creates its direct conversation atomically.
func (r *MySQLRepository) AcceptRequestAndCreateConversation(
	ctx context.Context,
	userID, requestID uint64,
) (Contact, error) {
	tx, err := r.database.BeginTx(ctx, nil)
	if err != nil {
		return Contact{}, fmt.Errorf("begin contact acceptance transaction: %w", err)
	}
	queries := r.queries.WithTx(tx)
	result, err := queries.AcceptContactRelationship(ctx, store.AcceptContactRelationshipParams{
		RelationshipID: requestID, CurrentUserID: userID,
	})
	if err != nil {
		return Contact{}, rollbackContactAcceptance(tx, fmt.Errorf("accept contact request: %w", err))
	}
	affected, err := result.RowsAffected()
	if err != nil {
		return Contact{}, rollbackContactAcceptance(tx, fmt.Errorf("read accepted contact row count: %w", err))
	}
	if affected != 1 {
		return Contact{}, rollbackContactAcceptance(tx, ErrRequestNotFound)
	}
	request, err := readRequest(ctx, queries, userID, requestID)
	if err != nil {
		return Contact{}, rollbackContactAcceptance(tx, err)
	}
	if err := createDirectConversation(ctx, queries, userID, request.User.ID); err != nil {
		return Contact{}, rollbackContactAcceptance(tx, err)
	}
	lowerID, higherID := orderedPair(userID, request.User.ID)
	if err := queries.ReactivateDirectConversationMembers(
		ctx,
		store.ReactivateDirectConversationMembersParams{
			LowerUserID: lowerID, HigherUserID: higherID,
		},
	); err != nil {
		return Contact{}, rollbackContactAcceptance(
			tx,
			fmt.Errorf("reactivate direct conversation: %w", err),
		)
	}
	if err := tx.Commit(); err != nil {
		return Contact{}, fmt.Errorf("commit contact acceptance transaction: %w", err)
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

// CancelRequest removes an outgoing pending request.
func (r *MySQLRepository) CancelRequest(ctx context.Context, userID, requestID uint64) error {
	result, err := r.queries.CancelContactRelationship(ctx, store.CancelContactRelationshipParams{
		RelationshipID: requestID, CurrentUserID: userID,
	})
	if err != nil {
		return fmt.Errorf("cancel contact request: %w", err)
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
		remark := row.HigherUserRemark
		if row.LowerUserID == userID {
			remark = row.LowerUserRemark
		}
		contacts = append(contacts, Contact{
			RelationshipID: row.RelationshipID,
			User:           PublicUser{ID: row.UserID, Username: row.Username, DisplayName: row.DisplayName, HasAvatar: row.AvatarContentType.Valid, CreatedAt: row.CreatedAt},
			Remark:         remark,
			ConnectedAt:    row.ConnectedAt,
		})
	}
	return contacts, nil
}

// SetContactRemark stores the current user's private label for a contact.
func (r *MySQLRepository) SetContactRemark(
	ctx context.Context,
	userID, contactUserID uint64,
	remark string,
) error {
	result, err := r.queries.SetContactRemark(ctx, store.SetContactRemarkParams{
		CurrentUserID: userID, ContactUserID: contactUserID, Remark: remark,
	})
	if err != nil {
		return fmt.Errorf("set contact remark: %w", err)
	}
	affected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("read contact remark row count: %w", err)
	}
	if affected == 1 {
		return nil
	}
	accepted, err := r.AreContacts(ctx, userID, contactUserID)
	if err != nil {
		return err
	}
	if !accepted {
		return ErrContactNotFound
	}
	return nil
}

// RemoveContact deletes an accepted relationship and suspends its direct conversation.
func (r *MySQLRepository) RemoveContact(ctx context.Context, userID, contactUserID uint64) error {
	lowerID, higherID := orderedPair(userID, contactUserID)
	tx, err := r.database.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin contact deletion transaction: %w", err)
	}
	queries := r.queries.WithTx(tx)
	result, err := queries.RemoveAcceptedContact(ctx, store.RemoveAcceptedContactParams{
		LowerUserID: lowerID, HigherUserID: higherID,
	})
	if err != nil {
		return rollbackContactDeletion(tx, fmt.Errorf("delete contact: %w", err))
	}
	if err := requireOneRow(result, ErrContactNotFound); err != nil {
		return rollbackContactDeletion(tx, err)
	}
	if err := queries.DeactivateDirectConversationMembers(
		ctx,
		store.DeactivateDirectConversationMembersParams{
			LowerUserID: lowerID, HigherUserID: higherID,
		},
	); err != nil {
		return rollbackContactDeletion(
			tx,
			fmt.Errorf("deactivate direct conversation: %w", err),
		)
	}
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("commit contact deletion transaction: %w", err)
	}
	return nil
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
	return readRequest(ctx, r.queries, userID, requestID)
}

func readRequest(ctx context.Context, queries *store.Queries, userID, requestID uint64) (Request, error) {
	row, err := queries.GetContactRelationshipByID(ctx, store.GetContactRelationshipByIDParams{
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
	if !isDuplicateEntry(cause) {
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

func createDirectConversation(
	ctx context.Context,
	queries *store.Queries,
	creatorID, contactUserID uint64,
) error {
	lowerID, higherID := orderedPair(creatorID, contactUserID)
	result, err := queries.CreateDirectConversation(ctx, store.CreateDirectConversationParams{
		DirectLowerUserID: lowerID, DirectHigherUserID: higherID, CreatedByUserID: creatorID,
	})
	if isDuplicateEntry(err) {
		return nil
	}
	if err != nil {
		return fmt.Errorf("create direct conversation: %w", err)
	}
	conversationID, err := result.LastInsertId()
	if err != nil {
		return fmt.Errorf("read direct conversation ID: %w", err)
	}
	if conversationID <= 0 {
		return errors.New("direct conversation ID must be positive")
	}
	for _, memberID := range []uint64{lowerID, higherID} {
		if err := queries.CreateConversationMember(ctx, store.CreateConversationMemberParams{
			ConversationID: uint64(conversationID), UserID: memberID,
		}); err != nil {
			return fmt.Errorf("create conversation member: %w", err)
		}
	}
	return nil
}

func isDuplicateEntry(err error) bool {
	var mysqlError *mysql.MySQLError
	return errors.As(err, &mysqlError) && mysqlError.Number == 1062
}

func rollbackContactAcceptance(tx *sql.Tx, cause error) error {
	if err := tx.Rollback(); err != nil && !errors.Is(err, sql.ErrTxDone) {
		return errors.Join(cause, fmt.Errorf("roll back contact acceptance: %w", err))
	}
	return cause
}

func rollbackContactDeletion(tx *sql.Tx, cause error) error {
	if err := tx.Rollback(); err != nil && !errors.Is(err, sql.ErrTxDone) {
		return errors.Join(cause, fmt.Errorf("roll back contact deletion: %w", err))
	}
	return cause
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
