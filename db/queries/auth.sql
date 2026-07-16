-- name: CreateUser :execresult
INSERT INTO users (email, display_name, password_hash)
VALUES (?, ?, ?);

-- name: GetUserByEmail :one
SELECT id, email, display_name, password_hash, created_at, updated_at
FROM users
WHERE email = ?
LIMIT 1;

-- name: CreateAccessToken :exec
INSERT INTO access_tokens (user_id, token_hash, expires_at)
VALUES (?, ?, ?);

-- name: CreateRefreshToken :exec
INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
VALUES (?, ?, ?);

-- name: GetUserByAccessToken :one
SELECT
  u.id AS user_id,
  u.email,
  u.display_name,
  u.created_at,
  u.updated_at
FROM access_tokens AS access
JOIN users AS u ON u.id = access.user_id
WHERE access.token_hash = ?
  AND access.revoked_at IS NULL
  AND access.expires_at > ?
LIMIT 1;

-- name: GetRefreshSessionForUpdate :one
SELECT
  refresh.id AS refresh_token_id,
  u.id AS user_id,
  u.email,
  u.display_name,
  u.created_at,
  u.updated_at
FROM refresh_tokens AS refresh
JOIN users AS u ON u.id = refresh.user_id
WHERE refresh.token_hash = ?
  AND refresh.revoked_at IS NULL
  AND refresh.expires_at > ?
LIMIT 1
FOR UPDATE;

-- name: RevokeAccessTokenByHash :exec
UPDATE access_tokens
SET revoked_at = ?
WHERE token_hash = ?
  AND revoked_at IS NULL;

-- name: RevokeRefreshTokenByHash :exec
UPDATE refresh_tokens
SET revoked_at = ?
WHERE token_hash = ?
  AND revoked_at IS NULL;

-- name: RevokeRefreshTokenByID :exec
UPDATE refresh_tokens
SET revoked_at = ?
WHERE id = ?
  AND revoked_at IS NULL;
