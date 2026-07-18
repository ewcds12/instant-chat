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
  (
    SELECT COUNT(*)
    FROM messages AS unread_message
    WHERE unread_message.conversation_id = conversation.id
      AND unread_message.sender_id <> sqlc.arg(current_user_id)
      AND unread_message.sequence > membership.last_read_sequence
  ) AS unread_count,
  latest_message.sequence AS last_message_sequence,
  latest_message.kind AS last_message_kind,
  latest_message.body AS last_message_body,
  latest_file.filename AS last_message_file_name,
  other_user.id AS peer_user_id,
  other_user.username AS peer_username,
  other_user.display_name AS peer_display_name,
  other_user.avatar_content_type AS peer_avatar_content_type,
  other_user.created_at AS peer_created_at
FROM conversations AS conversation
JOIN conversation_members AS membership
  ON membership.conversation_id = conversation.id
  AND membership.user_id = sqlc.arg(current_user_id)
LEFT JOIN messages AS latest_message
  ON latest_message.conversation_id = conversation.id
  AND latest_message.sequence = conversation.next_sequence - 1
LEFT JOIN message_files AS latest_file ON latest_file.id = latest_message.file_id
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
  (
    SELECT COUNT(*)
    FROM messages AS unread_message
    WHERE unread_message.conversation_id = conversation.id
      AND unread_message.sender_id <> sqlc.arg(current_user_id)
      AND unread_message.sequence > membership.last_read_sequence
  ) AS unread_count,
  latest_message.sequence AS last_message_sequence,
  latest_message.kind AS last_message_kind,
  latest_message.body AS last_message_body,
  latest_file.filename AS last_message_file_name,
  other_user.id AS peer_user_id,
  other_user.username AS peer_username,
  other_user.display_name AS peer_display_name,
  other_user.avatar_content_type AS peer_avatar_content_type,
  other_user.created_at AS peer_created_at
FROM conversation_members AS membership
JOIN conversations AS conversation ON conversation.id = membership.conversation_id
LEFT JOIN messages AS latest_message
  ON latest_message.conversation_id = conversation.id
  AND latest_message.sequence = conversation.next_sequence - 1
LEFT JOIN message_files AS latest_file ON latest_file.id = latest_message.file_id
JOIN users AS other_user
  ON other_user.id = CASE
    WHEN conversation.direct_lower_user_id = sqlc.arg(current_user_id) THEN conversation.direct_higher_user_id
    ELSE conversation.direct_lower_user_id
  END
WHERE membership.user_id = sqlc.arg(current_user_id)
ORDER BY conversation.updated_at DESC, conversation.id DESC
LIMIT 200;

-- name: IsConversationMemberForRead :one
SELECT EXISTS(
  SELECT 1
  FROM conversation_members
  WHERE conversation_id = sqlc.arg(conversation_id)
    AND user_id = sqlc.arg(user_id)
) AS is_member;

-- name: MarkConversationRead :exec
UPDATE conversation_members AS membership
JOIN conversations AS conversation ON conversation.id = membership.conversation_id
SET membership.last_read_sequence = GREATEST(
  membership.last_read_sequence,
  LEAST(sqlc.arg(sequence), conversation.next_sequence - 1)
)
WHERE membership.conversation_id = sqlc.arg(conversation_id)
  AND membership.user_id = sqlc.arg(user_id);
