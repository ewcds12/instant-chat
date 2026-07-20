package messages

import (
	"database/sql"
	"testing"
	"time"

	"github.com/ewcds12/instant-chat/services/api/internal/store"
)

func TestMessageFromLatestRowMasksRecalledContent(t *testing.T) {
	recalledAt := time.Date(2026, 7, 20, 13, 5, 0, 0, time.UTC)
	message := messageFromLatestRow(store.ListLatestMessagesRow{
		ID: 21, ConversationID: 11, SenderID: 7, SenderUsername: "alex",
		SenderDisplayName: "Alex", ClientMessageID: "client-message-id", Sequence: 4,
		Kind: KindFile, Body: "private", ImageID: sql.NullInt64{Int64: 3, Valid: true},
		FileID: sql.NullInt64{Int64: 5, Valid: true}, RecalledAt: sql.NullTime{Time: recalledAt, Valid: true},
	})

	if message.RecalledAt == nil || !message.RecalledAt.Equal(recalledAt) {
		t.Fatalf("recalled at = %v, want %v", message.RecalledAt, recalledAt)
	}
	if message.Body != "" || message.Image != nil || message.File != nil {
		t.Fatalf("recalled message leaked content: %+v", message)
	}
}
