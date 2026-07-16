// Package realtime manages authenticated WebSocket message delivery.
package realtime

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/ewcds12/instant-chat/services/api/internal/store"
)

type memberRepository interface {
	ListConversationMemberIDs(ctx context.Context, conversationID uint64) ([]uint64, error)
}

// MySQLRepository reads the authorized recipients for a conversation.
type MySQLRepository struct {
	queries *store.Queries
}

// NewMySQLRepository creates the production realtime repository.
func NewMySQLRepository(database *sql.DB) *MySQLRepository {
	return &MySQLRepository{queries: store.New(database)}
}

// ListConversationMemberIDs returns every authorized conversation member.
func (r *MySQLRepository) ListConversationMemberIDs(
	ctx context.Context,
	conversationID uint64,
) ([]uint64, error) {
	userIDs, err := r.queries.ListConversationMemberIDs(ctx, conversationID)
	if err != nil {
		return nil, fmt.Errorf("list conversation members: %w", err)
	}
	return userIDs, nil
}
