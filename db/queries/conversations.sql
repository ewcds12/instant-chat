-- name: CreateDirectConversation :execresult
INSERT INTO conversations (
  kind,
  direct_lower_user_id,
  direct_higher_user_id,
  created_by_user_id
)
VALUES ('direct', ?, ?, ?);

-- name: CreateConversationMember :exec
INSERT INTO conversation_members (conversation_id, user_id)
VALUES (?, ?);

-- name: GetDirectConversationByPair :one
SELECT
  conversation.id,
  conversation.kind,
  conversation.created_at,
  conversation.updated_at,
  other_user.id AS peer_user_id,
  other_user.username AS peer_username,
  other_user.display_name AS peer_display_name,
  other_user.created_at AS peer_created_at
FROM conversations AS conversation
JOIN users AS other_user
  ON other_user.id = CASE
    WHEN conversation.direct_lower_user_id = sqlc.arg(current_user_id) THEN conversation.direct_higher_user_id
    ELSE conversation.direct_lower_user_id
  END
WHERE conversation.direct_lower_user_id = sqlc.arg(lower_user_id)
  AND conversation.direct_higher_user_id = sqlc.arg(higher_user_id)
LIMIT 1;

-- name: ListConversationsForUser :many
SELECT
  conversation.id,
  conversation.kind,
  conversation.created_at,
  conversation.updated_at,
  other_user.id AS peer_user_id,
  other_user.username AS peer_username,
  other_user.display_name AS peer_display_name,
  other_user.created_at AS peer_created_at
FROM conversation_members AS membership
JOIN conversations AS conversation ON conversation.id = membership.conversation_id
JOIN users AS other_user
  ON other_user.id = CASE
    WHEN conversation.direct_lower_user_id = sqlc.arg(current_user_id) THEN conversation.direct_higher_user_id
    ELSE conversation.direct_lower_user_id
  END
WHERE membership.user_id = sqlc.arg(current_user_id)
ORDER BY conversation.updated_at DESC, conversation.id DESC
LIMIT 200;
