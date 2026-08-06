-- name: ListProfileRecipientIDs :many
SELECT DISTINCT member.user_id
FROM conversation_members AS source
JOIN conversation_members AS member ON member.conversation_id = source.conversation_id
WHERE source.user_id = ?
  AND source.is_active = TRUE
  AND member.is_active = TRUE
ORDER BY member.user_id;
