-- name: FindPublicUserByUsername :one
SELECT id, username, display_name, avatar_content_type, created_at
FROM users
WHERE username = ?
LIMIT 1;

-- name: CreateContactRelationship :execresult
INSERT INTO contact_relationships (
  lower_user_id,
  higher_user_id,
  requested_by_user_id,
  status
)
VALUES (?, ?, ?, 'pending');

-- name: GetContactRelationshipByID :one
SELECT
  relationship.id,
  relationship.lower_user_id,
  relationship.higher_user_id,
  relationship.requested_by_user_id,
  relationship.status,
  relationship.created_at,
  relationship.updated_at,
  other_user.id AS other_user_id,
  other_user.username AS other_username,
  other_user.display_name AS other_display_name,
  other_user.avatar_content_type AS other_avatar_content_type,
  other_user.created_at AS other_created_at
FROM contact_relationships AS relationship
JOIN users AS other_user
  ON other_user.id = CASE
    WHEN relationship.lower_user_id = sqlc.arg(current_user_id) THEN relationship.higher_user_id
    ELSE relationship.lower_user_id
  END
WHERE relationship.id = sqlc.arg(relationship_id)
  AND (
    relationship.lower_user_id = sqlc.arg(current_user_id)
    OR relationship.higher_user_id = sqlc.arg(current_user_id)
  )
LIMIT 1;

-- name: ListPendingContactRelationships :many
SELECT
  relationship.id,
  relationship.lower_user_id,
  relationship.higher_user_id,
  relationship.requested_by_user_id,
  relationship.status,
  relationship.created_at,
  relationship.updated_at,
  other_user.id AS other_user_id,
  other_user.username AS other_username,
  other_user.display_name AS other_display_name,
  other_user.avatar_content_type AS other_avatar_content_type,
  other_user.created_at AS other_created_at
FROM contact_relationships AS relationship
JOIN users AS other_user
  ON other_user.id = CASE
    WHEN relationship.lower_user_id = sqlc.arg(current_user_id) THEN relationship.higher_user_id
    ELSE relationship.lower_user_id
  END
WHERE relationship.status = 'pending'
  AND (
    relationship.lower_user_id = sqlc.arg(current_user_id)
    OR relationship.higher_user_id = sqlc.arg(current_user_id)
  )
ORDER BY relationship.updated_at DESC, relationship.id DESC
LIMIT 100;

-- name: ListAcceptedContacts :many
SELECT
  relationship.id AS relationship_id,
  other_user.id AS user_id,
  other_user.username,
  other_user.display_name,
  other_user.avatar_content_type,
  other_user.created_at,
  relationship.updated_at AS connected_at
FROM contact_relationships AS relationship
JOIN users AS other_user
  ON other_user.id = CASE
    WHEN relationship.lower_user_id = sqlc.arg(current_user_id) THEN relationship.higher_user_id
    ELSE relationship.lower_user_id
  END
WHERE relationship.status = 'accepted'
  AND (
    relationship.lower_user_id = sqlc.arg(current_user_id)
    OR relationship.higher_user_id = sqlc.arg(current_user_id)
  )
ORDER BY other_user.display_name, other_user.username, other_user.id
LIMIT 500;

-- name: AcceptContactRelationship :execresult
UPDATE contact_relationships
SET status = 'accepted'
WHERE id = sqlc.arg(relationship_id)
  AND status = 'pending'
  AND requested_by_user_id <> sqlc.arg(current_user_id)
  AND (
    lower_user_id = sqlc.arg(current_user_id)
    OR higher_user_id = sqlc.arg(current_user_id)
  );

-- name: RejectContactRelationship :execresult
DELETE FROM contact_relationships
WHERE id = sqlc.arg(relationship_id)
  AND status = 'pending'
  AND requested_by_user_id <> sqlc.arg(current_user_id)
  AND (
    lower_user_id = sqlc.arg(current_user_id)
    OR higher_user_id = sqlc.arg(current_user_id)
  );

-- name: RemoveAcceptedContact :execresult
DELETE FROM contact_relationships
WHERE lower_user_id = sqlc.arg(lower_user_id)
  AND higher_user_id = sqlc.arg(higher_user_id)
  AND status = 'accepted';

-- name: ContactRelationshipStatus :one
SELECT status
FROM contact_relationships
WHERE lower_user_id = sqlc.arg(lower_user_id)
  AND higher_user_id = sqlc.arg(higher_user_id)
LIMIT 1;
