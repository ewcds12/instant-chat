-- name: LockConversationForMessage :one
SELECT conversation.next_sequence
FROM conversations AS conversation
JOIN conversation_members AS membership
  ON membership.conversation_id = conversation.id
WHERE conversation.id = sqlc.arg(conversation_id)
  AND membership.user_id = sqlc.arg(user_id)
  AND membership.is_active = TRUE
LIMIT 1
FOR UPDATE;

-- name: GetMessageByClientID :one
SELECT
  message.id,
  message.conversation_id,
  message.sender_id,
  sender.username AS sender_username,
  sender.display_name AS sender_display_name,
  sender.avatar_content_type AS sender_avatar_content_type,
  sender.created_at AS sender_created_at,
  message.client_message_id,
  message.sequence,
  message.kind,
  message.body,
  message.image_id,
  image.content_type AS image_content_type,
  image.byte_size AS image_byte_size,
  message.file_id,
  file.filename AS file_filename,
  file.content_type AS file_content_type,
  file.byte_size AS file_byte_size,
  reply.id AS reply_to_id,
  reply_sender.id AS reply_sender_id,
  reply_sender.username AS reply_sender_username,
  reply_sender.display_name AS reply_sender_display_name,
  reply_sender.avatar_content_type AS reply_sender_avatar_content_type,
  reply_sender.created_at AS reply_sender_created_at,
  reply.kind AS reply_kind,
  reply.body AS reply_body,
  reply_file.filename AS reply_file_filename,
  reply.recalled_at AS reply_recalled_at,
  message.recalled_at,
  message.created_at
FROM messages AS message
JOIN users AS sender ON sender.id = message.sender_id
LEFT JOIN message_images AS image ON image.id = message.image_id
LEFT JOIN message_files AS file ON file.id = message.file_id
LEFT JOIN messages AS reply ON reply.id = message.reply_to_message_id
LEFT JOIN users AS reply_sender ON reply_sender.id = reply.sender_id
LEFT JOIN message_files AS reply_file ON reply_file.id = reply.file_id
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
  kind,
  body,
  image_id,
  file_id,
  reply_to_message_id
)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: LockReplyMessage :one
SELECT id
FROM messages
WHERE id = sqlc.arg(reply_to_message_id)
  AND conversation_id = sqlc.arg(conversation_id)
  AND recalled_at IS NULL
LIMIT 1
FOR UPDATE;

-- name: CreateMessageImage :execresult
INSERT INTO message_images (
  uploader_id,
  content_type,
  byte_size,
  data
)
VALUES (?, ?, ?, ?);

-- name: CreateMessageFile :execresult
INSERT INTO message_files (
  uploader_id,
  filename,
  content_type,
  byte_size,
  data,
  object_key
)
VALUES (?, ?, ?, ?, NULL, ?);

-- name: AdvanceConversationSequence :exec
UPDATE conversations
SET next_sequence = next_sequence + 1,
    updated_at = CURRENT_TIMESTAMP(6)
WHERE id = ?;

-- name: RecallMessage :execresult
UPDATE messages
SET recalled_at = CURRENT_TIMESTAMP(6)
WHERE id = sqlc.arg(message_id)
  AND conversation_id = sqlc.arg(conversation_id)
  AND sender_id = sqlc.arg(user_id)
  AND recalled_at IS NULL
  AND created_at >= CURRENT_TIMESTAMP(6) - INTERVAL 5 MINUTE;

-- name: HideMessageForUser :exec
INSERT IGNORE INTO message_deletions (message_id, user_id)
SELECT message.id, sqlc.arg(user_id)
FROM messages AS message
JOIN conversation_members AS membership
  ON membership.conversation_id = message.conversation_id
WHERE message.id = sqlc.arg(message_id)
  AND message.conversation_id = sqlc.arg(conversation_id)
  AND membership.user_id = sqlc.arg(user_id)
  AND membership.is_active = TRUE;

-- name: IsConversationMember :one
SELECT EXISTS (
  SELECT 1
  FROM conversation_members
  WHERE conversation_id = sqlc.arg(conversation_id)
    AND user_id = sqlc.arg(user_id)
    AND is_active = TRUE
) AS is_member;

-- name: ListLatestMessages :many
SELECT
  message.id,
  message.conversation_id,
  message.sender_id,
  sender.username AS sender_username,
  sender.display_name AS sender_display_name,
  sender.avatar_content_type AS sender_avatar_content_type,
  sender.created_at AS sender_created_at,
  message.client_message_id,
  message.sequence,
  message.kind,
  message.body,
  message.image_id,
  image.content_type AS image_content_type,
  image.byte_size AS image_byte_size,
  message.file_id,
  file.filename AS file_filename,
  file.content_type AS file_content_type,
  file.byte_size AS file_byte_size,
  reply.id AS reply_to_id,
  reply_sender.id AS reply_sender_id,
  reply_sender.username AS reply_sender_username,
  reply_sender.display_name AS reply_sender_display_name,
  reply_sender.avatar_content_type AS reply_sender_avatar_content_type,
  reply_sender.created_at AS reply_sender_created_at,
  reply.kind AS reply_kind,
  reply.body AS reply_body,
  reply_file.filename AS reply_file_filename,
  reply.recalled_at AS reply_recalled_at,
  message.recalled_at,
  message.created_at
FROM messages AS message
JOIN users AS sender ON sender.id = message.sender_id
LEFT JOIN message_images AS image ON image.id = message.image_id
LEFT JOIN message_files AS file ON file.id = message.file_id
LEFT JOIN messages AS reply ON reply.id = message.reply_to_message_id
LEFT JOIN users AS reply_sender ON reply_sender.id = reply.sender_id
LEFT JOIN message_files AS reply_file ON reply_file.id = reply.file_id
WHERE message.conversation_id = sqlc.arg(conversation_id)
  AND NOT EXISTS (
    SELECT 1
    FROM message_deletions AS deletion
    WHERE deletion.message_id = message.id
      AND deletion.user_id = sqlc.arg(user_id)
  )
ORDER BY message.sequence DESC
LIMIT ?;

-- name: ListMessagesBefore :many
SELECT
  message.id,
  message.conversation_id,
  message.sender_id,
  sender.username AS sender_username,
  sender.display_name AS sender_display_name,
  sender.avatar_content_type AS sender_avatar_content_type,
  sender.created_at AS sender_created_at,
  message.client_message_id,
  message.sequence,
  message.kind,
  message.body,
  message.image_id,
  image.content_type AS image_content_type,
  image.byte_size AS image_byte_size,
  message.file_id,
  file.filename AS file_filename,
  file.content_type AS file_content_type,
  file.byte_size AS file_byte_size,
  reply.id AS reply_to_id,
  reply_sender.id AS reply_sender_id,
  reply_sender.username AS reply_sender_username,
  reply_sender.display_name AS reply_sender_display_name,
  reply_sender.avatar_content_type AS reply_sender_avatar_content_type,
  reply_sender.created_at AS reply_sender_created_at,
  reply.kind AS reply_kind,
  reply.body AS reply_body,
  reply_file.filename AS reply_file_filename,
  reply.recalled_at AS reply_recalled_at,
  message.recalled_at,
  message.created_at
FROM messages AS message
JOIN users AS sender ON sender.id = message.sender_id
LEFT JOIN message_images AS image ON image.id = message.image_id
LEFT JOIN message_files AS file ON file.id = message.file_id
LEFT JOIN messages AS reply ON reply.id = message.reply_to_message_id
LEFT JOIN users AS reply_sender ON reply_sender.id = reply.sender_id
LEFT JOIN message_files AS reply_file ON reply_file.id = reply.file_id
WHERE message.conversation_id = sqlc.arg(conversation_id)
  AND message.sequence < sqlc.arg(before_sequence)
  AND NOT EXISTS (
    SELECT 1
    FROM message_deletions AS deletion
    WHERE deletion.message_id = message.id
      AND deletion.user_id = sqlc.arg(user_id)
  )
ORDER BY message.sequence DESC
LIMIT ?;

-- name: ListMessagesAfter :many
SELECT
  message.id,
  message.conversation_id,
  message.sender_id,
  sender.username AS sender_username,
  sender.display_name AS sender_display_name,
  sender.avatar_content_type AS sender_avatar_content_type,
  sender.created_at AS sender_created_at,
  message.client_message_id,
  message.sequence,
  message.kind,
  message.body,
  message.image_id,
  image.content_type AS image_content_type,
  image.byte_size AS image_byte_size,
  message.file_id,
  file.filename AS file_filename,
  file.content_type AS file_content_type,
  file.byte_size AS file_byte_size,
  reply.id AS reply_to_id,
  reply_sender.id AS reply_sender_id,
  reply_sender.username AS reply_sender_username,
  reply_sender.display_name AS reply_sender_display_name,
  reply_sender.avatar_content_type AS reply_sender_avatar_content_type,
  reply_sender.created_at AS reply_sender_created_at,
  reply.kind AS reply_kind,
  reply.body AS reply_body,
  reply_file.filename AS reply_file_filename,
  reply.recalled_at AS reply_recalled_at,
  message.recalled_at,
  message.created_at
FROM messages AS message
JOIN users AS sender ON sender.id = message.sender_id
LEFT JOIN message_images AS image ON image.id = message.image_id
LEFT JOIN message_files AS file ON file.id = message.file_id
LEFT JOIN messages AS reply ON reply.id = message.reply_to_message_id
LEFT JOIN users AS reply_sender ON reply_sender.id = reply.sender_id
LEFT JOIN message_files AS reply_file ON reply_file.id = reply.file_id
WHERE message.conversation_id = sqlc.arg(conversation_id)
  AND message.sequence > sqlc.arg(after_sequence)
  AND NOT EXISTS (
    SELECT 1
    FROM message_deletions AS deletion
    WHERE deletion.message_id = message.id
      AND deletion.user_id = sqlc.arg(user_id)
  )
ORDER BY message.sequence ASC
LIMIT ?;

-- name: ListConversationMemberIDs :many
SELECT user_id
FROM conversation_members
WHERE conversation_id = ?
  AND is_active = TRUE
ORDER BY user_id ASC;

-- name: GetMessageImageForMember :one
SELECT
  image.content_type,
  image.byte_size,
  image.data
FROM message_images AS image
JOIN messages AS message ON message.image_id = image.id
JOIN conversation_members AS membership
  ON membership.conversation_id = message.conversation_id
WHERE image.id = sqlc.arg(image_id)
  AND membership.user_id = sqlc.arg(user_id)
  AND membership.is_active = TRUE
  AND message.recalled_at IS NULL
  AND NOT EXISTS (
    SELECT 1
    FROM message_deletions AS deletion
    WHERE deletion.message_id = message.id
      AND deletion.user_id = sqlc.arg(user_id)
  )
LIMIT 1;

-- name: GetMessageFileForMember :one
SELECT
  file.filename,
  file.content_type,
  file.byte_size,
  file.data,
  file.object_key
FROM message_files AS file
JOIN messages AS message ON message.file_id = file.id
JOIN conversation_members AS membership
  ON membership.conversation_id = message.conversation_id
WHERE file.id = sqlc.arg(file_id)
  AND membership.user_id = sqlc.arg(user_id)
  AND membership.is_active = TRUE
  AND message.recalled_at IS NULL
  AND NOT EXISTS (
    SELECT 1
    FROM message_deletions AS deletion
    WHERE deletion.message_id = message.id
      AND deletion.user_id = sqlc.arg(user_id)
  )
LIMIT 1;
