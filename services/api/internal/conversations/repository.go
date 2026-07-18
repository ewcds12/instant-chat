package conversations

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/go-sql-driver/mysql"

	"github.com/ewcds12/instant-chat/services/api/internal/store"
)

// MySQLRepository persists direct conversations through sqlc queries.
type MySQLRepository struct {
	database *sql.DB
	queries  *store.Queries
}

// NewMySQLRepository creates the production conversation repository.
func NewMySQLRepository(database *sql.DB) *MySQLRepository {
	return &MySQLRepository{database: database, queries: store.New(database)}
}

// CreateDirect creates both direct-conversation memberships atomically.
func (r *MySQLRepository) CreateDirect(ctx context.Context, userID, contactUserID uint64) (Conversation, bool, error) {
	lowerID, higherID := orderedPair(userID, contactUserID)
	conversationID, duplicate, err := r.insertDirect(ctx, userID, lowerID, higherID)
	if err != nil {
		return Conversation{}, false, err
	}
	if duplicate {
		conversation, err := r.getDirect(ctx, userID, lowerID, higherID)
		return conversation, false, err
	}
	conversation, err := r.getDirect(ctx, userID, lowerID, higherID)
	if err != nil {
		return Conversation{}, false, err
	}
	if conversation.ID != conversationID {
		return Conversation{}, false, errors.New("created conversation ID did not match stored conversation")
	}
	return conversation, true, nil
}

// List returns conversations for one member.
func (r *MySQLRepository) List(ctx context.Context, userID uint64) ([]Conversation, error) {
	rows, err := r.queries.ListConversationsForUser(ctx, store.ListConversationsForUserParams{CurrentUserID: userID})
	if err != nil {
		return nil, fmt.Errorf("list conversations: %w", err)
	}
	conversations := make([]Conversation, 0, len(rows))
	for _, row := range rows {
		conversations = append(conversations, conversationFromListRow(row))
	}
	return conversations, nil
}

// MarkRead advances one member's read marker without allowing future sequences.
func (r *MySQLRepository) MarkRead(ctx context.Context, userID, conversationID, sequence uint64) error {
	isMember, err := r.queries.IsConversationMemberForRead(ctx, store.IsConversationMemberForReadParams{
		ConversationID: conversationID, UserID: userID,
	})
	if err != nil {
		return fmt.Errorf("check conversation member: %w", err)
	}
	if !isMember {
		return ErrConversationNotFound
	}
	if err := r.queries.MarkConversationRead(ctx, store.MarkConversationReadParams{
		Sequence: sequence, ConversationID: conversationID, UserID: userID,
	}); err != nil {
		return fmt.Errorf("mark conversation read: %w", err)
	}
	return nil
}

func (r *MySQLRepository) insertDirect(ctx context.Context, creatorID, lowerID, higherID uint64) (uint64, bool, error) {
	tx, err := r.database.BeginTx(ctx, nil)
	if err != nil {
		return 0, false, fmt.Errorf("begin conversation transaction: %w", err)
	}
	queries := r.queries.WithTx(tx)
	result, err := queries.CreateDirectConversation(ctx, store.CreateDirectConversationParams{
		DirectLowerUserID: lowerID, DirectHigherUserID: higherID, CreatedByUserID: creatorID,
	})
	if err != nil {
		if rollbackErr := tx.Rollback(); rollbackErr != nil && !errors.Is(rollbackErr, sql.ErrTxDone) {
			return 0, false, errors.Join(err, fmt.Errorf("roll back transaction: %w", rollbackErr))
		}
		if isDuplicate(err) {
			return 0, true, nil
		}
		return 0, false, fmt.Errorf("create direct conversation: %w", err)
	}
	conversationID, err := result.LastInsertId()
	if err != nil || conversationID <= 0 {
		return 0, false, rollback(tx, errors.New("new conversation ID must be positive"))
	}
	if err := addMembers(ctx, queries, uint64(conversationID), lowerID, higherID); err != nil {
		return 0, false, rollback(tx, err)
	}
	if err := tx.Commit(); err != nil {
		return 0, false, fmt.Errorf("commit conversation transaction: %w", err)
	}
	return uint64(conversationID), false, nil
}

func (r *MySQLRepository) getDirect(ctx context.Context, currentUserID, lowerID, higherID uint64) (Conversation, error) {
	row, err := r.queries.GetDirectConversationByPair(ctx, store.GetDirectConversationByPairParams{
		CurrentUserID: currentUserID, LowerUserID: lowerID, HigherUserID: higherID,
	})
	if err != nil {
		return Conversation{}, fmt.Errorf("read direct conversation: %w", err)
	}
	return conversationFromPairRow(row), nil
}

func addMembers(ctx context.Context, queries *store.Queries, conversationID, lowerID, higherID uint64) error {
	for _, userID := range []uint64{lowerID, higherID} {
		if err := queries.CreateConversationMember(ctx, store.CreateConversationMemberParams{
			ConversationID: conversationID, UserID: userID,
		}); err != nil {
			return fmt.Errorf("create conversation member: %w", err)
		}
	}
	return nil
}

func isDuplicate(err error) bool {
	var mysqlError *mysql.MySQLError
	return errors.As(err, &mysqlError) && mysqlError.Number == 1062
}

func orderedPair(firstID, secondID uint64) (uint64, uint64) {
	if firstID < secondID {
		return firstID, secondID
	}
	return secondID, firstID
}

func rollback(tx *sql.Tx, cause error) error {
	if err := tx.Rollback(); err != nil && !errors.Is(err, sql.ErrTxDone) {
		return errors.Join(cause, fmt.Errorf("roll back transaction: %w", err))
	}
	return cause
}

func conversationFromPairRow(row store.GetDirectConversationByPairRow) Conversation {
	return Conversation{
		ID: row.ID, Kind: row.Kind,
		Peer:      Peer{ID: row.PeerUserID, Username: row.PeerUsername, DisplayName: row.PeerDisplayName, HasAvatar: row.PeerAvatarContentType.Valid, CreatedAt: row.PeerCreatedAt},
		CreatedAt: row.CreatedAt, UpdatedAt: row.UpdatedAt, UnreadCount: uint64(row.UnreadCount),
		LastMessage: lastMessage(
			row.LastMessageSequence,
			row.LastMessageKind,
			row.LastMessageBody,
			row.LastMessageFileName,
		),
	}
}

func conversationFromListRow(row store.ListConversationsForUserRow) Conversation {
	return Conversation{
		ID: row.ID, Kind: row.Kind,
		Peer:      Peer{ID: row.PeerUserID, Username: row.PeerUsername, DisplayName: row.PeerDisplayName, HasAvatar: row.PeerAvatarContentType.Valid, CreatedAt: row.PeerCreatedAt},
		CreatedAt: row.CreatedAt, UpdatedAt: row.UpdatedAt, UnreadCount: uint64(row.UnreadCount),
		LastMessage: lastMessage(
			row.LastMessageSequence,
			row.LastMessageKind,
			row.LastMessageBody,
			row.LastMessageFileName,
		),
	}
}

func lastMessage(sequence sql.NullInt64, kind, body, fileName sql.NullString) *LastMessage {
	if !sequence.Valid || sequence.Int64 <= 0 || !kind.Valid || !body.Valid {
		return nil
	}
	return &LastMessage{
		Sequence: uint64(sequence.Int64),
		Kind:     kind.String,
		Body:     body.String,
		FileName: fileName.String,
	}
}
