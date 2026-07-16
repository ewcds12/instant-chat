-- name: LockConversationForMessage :one
SELECT conversation.next_sequence
FROM conversations AS conversation
JOIN conversation_members AS membership
  ON membership.conversation_id = conversation.id
WHERE conversation.id = sqlc.arg(conversation_id)
  AND membership.user_id = sqlc.arg(user_id)
LIMIT 1
FOR UPDATE;

-- name: GetMessageByClientID :one
SELECT
  message.id,
  message.conversation_id,
  message.sender_id,
  sender.username AS sender_username,
  sender.display_name AS sender_display_name,
  sender.created_at AS sender_created_at,
  message.client_message_id,
  message.sequence,
  message.body,
  message.created_at
FROM messages AS message
JOIN users AS sender ON sender.id = message.sender_id
WHERE message.conversation_id = sqlc.arg(conversation_id)
  AND message.sender_id = sqlc.arg(sender_id)
  AND message.client_message_id = sqlc.arg(client_message_id)
LIMIT 1;

-- name: CreateMessage :execresult
INSERT INTO messages (
  conversation_id,
  sender_id,
  client_message_id,
  sequence,
  body
)
VALUES (?, ?, ?, ?, ?);

-- name: AdvanceConversationSequence :exec
UPDATE conversations
SET next_sequence = next_sequence + 1,
    updated_at = CURRENT_TIMESTAMP(6)
WHERE id = ?;

-- name: IsConversationMember :one
SELECT EXISTS (
  SELECT 1
  FROM conversation_members
  WHERE conversation_id = sqlc.arg(conversation_id)
    AND user_id = sqlc.arg(user_id)
) AS is_member;

-- name: ListLatestMessages :many
SELECT
  message.id,
  message.conversation_id,
  message.sender_id,
  sender.username AS sender_username,
  sender.display_name AS sender_display_name,
  sender.created_at AS sender_created_at,
  message.client_message_id,
  message.sequence,
  message.body,
  message.created_at
FROM messages AS message
JOIN users AS sender ON sender.id = message.sender_id
WHERE message.conversation_id = sqlc.arg(conversation_id)
ORDER BY message.sequence DESC
LIMIT ?;

-- name: ListMessagesBefore :many
SELECT
  message.id,
  message.conversation_id,
  message.sender_id,
  sender.username AS sender_username,
  sender.display_name AS sender_display_name,
  sender.created_at AS sender_created_at,
  message.client_message_id,
  message.sequence,
  message.body,
  message.created_at
FROM messages AS message
JOIN users AS sender ON sender.id = message.sender_id
WHERE message.conversation_id = sqlc.arg(conversation_id)
  AND message.sequence < sqlc.arg(before_sequence)
ORDER BY message.sequence DESC
LIMIT ?;

-- name: ListMessagesAfter :many
SELECT
  message.id,
  message.conversation_id,
  message.sender_id,
  sender.username AS sender_username,
  sender.display_name AS sender_display_name,
  sender.created_at AS sender_created_at,
  message.client_message_id,
  message.sequence,
  message.body,
  message.created_at
FROM messages AS message
JOIN users AS sender ON sender.id = message.sender_id
WHERE message.conversation_id = sqlc.arg(conversation_id)
  AND message.sequence > sqlc.arg(after_sequence)
ORDER BY message.sequence ASC
LIMIT ?;

-- name: ListConversationMemberIDs :many
SELECT user_id
FROM conversation_members
WHERE conversation_id = ?
ORDER BY user_id ASC;
