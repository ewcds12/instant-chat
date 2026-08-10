-- name: CreatePost :execresult
INSERT INTO posts (author_id, body)
VALUES (?, ?);

-- name: CreatePostImage :execresult
INSERT INTO post_images (
  post_id,
  position,
  content_type,
  byte_size,
  object_key
)
VALUES (?, ?, ?, ?, ?);

-- name: GetPostForViewer :many
SELECT
  post.id,
  post.body,
  post.created_at,
  author.id AS author_id,
  author.username AS author_username,
  author.display_name AS author_display_name,
  author.avatar_content_type AS author_avatar_content_type,
  author.created_at AS author_created_at,
  image.id AS image_id,
  image.position AS image_position,
  image.content_type AS image_content_type,
  image.byte_size AS image_byte_size
FROM posts AS post
JOIN users AS author ON author.id = post.author_id
LEFT JOIN post_images AS image ON image.post_id = post.id
WHERE post.id = sqlc.arg(post_id)
  AND NOT EXISTS (
    SELECT 1
    FROM user_blocks AS block
    WHERE block.blocker_id = sqlc.arg(viewer_id)
      AND block.blocked_user_id = post.author_id
  )
ORDER BY image.position ASC;

-- name: ListLatestPosts :many
SELECT
  page.id,
  page.body,
  page.created_at,
  author.id AS author_id,
  author.username AS author_username,
  author.display_name AS author_display_name,
  author.avatar_content_type AS author_avatar_content_type,
  author.created_at AS author_created_at,
  image.id AS image_id,
  image.position AS image_position,
  image.content_type AS image_content_type,
  image.byte_size AS image_byte_size
FROM (
  SELECT post.id, post.author_id, post.body, post.created_at
  FROM posts AS post
  WHERE NOT EXISTS (
    SELECT 1
    FROM user_blocks AS block
    WHERE block.blocker_id = sqlc.arg(viewer_id)
      AND block.blocked_user_id = post.author_id
  )
  ORDER BY post.id DESC
  LIMIT ?
) AS page
JOIN users AS author ON author.id = page.author_id
LEFT JOIN post_images AS image ON image.post_id = page.id
ORDER BY page.id DESC, image.position ASC;

-- name: ListPostsBefore :many
SELECT
  page.id,
  page.body,
  page.created_at,
  author.id AS author_id,
  author.username AS author_username,
  author.display_name AS author_display_name,
  author.avatar_content_type AS author_avatar_content_type,
  author.created_at AS author_created_at,
  image.id AS image_id,
  image.position AS image_position,
  image.content_type AS image_content_type,
  image.byte_size AS image_byte_size
FROM (
  SELECT post.id, post.author_id, post.body, post.created_at
  FROM posts AS post
  WHERE post.id < sqlc.arg(before_post_id)
    AND NOT EXISTS (
      SELECT 1
      FROM user_blocks AS block
      WHERE block.blocker_id = sqlc.arg(viewer_id)
        AND block.blocked_user_id = post.author_id
    )
  ORDER BY post.id DESC
  LIMIT ?
) AS page
JOIN users AS author ON author.id = page.author_id
LEFT JOIN post_images AS image ON image.post_id = page.id
ORDER BY page.id DESC, image.position ASC;

-- name: GetPostImageForViewer :one
SELECT image.content_type, image.byte_size, image.object_key
FROM post_images AS image
JOIN posts AS post ON post.id = image.post_id
WHERE image.id = sqlc.arg(image_id)
  AND NOT EXISTS (
    SELECT 1
    FROM user_blocks AS block
    WHERE block.blocker_id = sqlc.arg(viewer_id)
      AND block.blocked_user_id = post.author_id
  )
LIMIT 1;

-- name: ListPostObjectKeysForAuthor :many
SELECT image.object_key
FROM posts AS post
JOIN post_images AS image ON image.post_id = post.id
WHERE post.id = sqlc.arg(post_id)
  AND post.author_id = sqlc.arg(author_id)
ORDER BY image.position ASC;

-- name: DeletePostForAuthor :execresult
DELETE FROM posts
WHERE id = sqlc.arg(post_id)
  AND author_id = sqlc.arg(author_id);

-- name: ReportPost :execresult
INSERT INTO post_reports (post_id, reporter_id, reason)
SELECT post.id, sqlc.arg(reporter_id), sqlc.arg(reason)
FROM posts AS post
WHERE post.id = sqlc.arg(post_id)
  AND post.author_id <> sqlc.arg(reporter_id)
ON DUPLICATE KEY UPDATE
  reason = VALUES(reason),
  created_at = CURRENT_TIMESTAMP(6);

-- name: ReportablePostExists :one
SELECT EXISTS (
  SELECT 1
  FROM posts
  WHERE id = sqlc.arg(post_id)
    AND author_id <> sqlc.arg(reporter_id)
) AS reportable_post_exists;

-- name: UserExists :one
SELECT EXISTS (
  SELECT 1 FROM users WHERE id = sqlc.arg(user_id)
) AS user_exists;

-- name: BlockUser :exec
INSERT IGNORE INTO user_blocks (blocker_id, blocked_user_id)
VALUES (?, ?);

-- name: UnblockUser :exec
DELETE FROM user_blocks
WHERE blocker_id = sqlc.arg(blocker_id)
  AND blocked_user_id = sqlc.arg(blocked_user_id);

-- name: ListBlockedUsers :many
SELECT
  blocked.id,
  blocked.username,
  blocked.display_name,
  blocked.avatar_content_type,
  blocked.created_at
FROM user_blocks AS block
JOIN users AS blocked ON blocked.id = block.blocked_user_id
WHERE block.blocker_id = sqlc.arg(blocker_id)
ORDER BY block.created_at DESC, blocked.id DESC
LIMIT 500;
