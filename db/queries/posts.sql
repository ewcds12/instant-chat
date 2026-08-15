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

-- name: GetPost :many
SELECT
  post.id,
  post.body,
  post.created_at,
  (SELECT COUNT(*) FROM post_comments AS comment WHERE comment.post_id = post.id) AS comment_count,
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
ORDER BY image.position ASC;

-- name: ListLatestPosts :many
SELECT
  page.id,
  page.body,
  page.created_at,
  (SELECT COUNT(*) FROM post_comments AS comment WHERE comment.post_id = page.id) AS comment_count,
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
  (SELECT COUNT(*) FROM post_comments AS comment WHERE comment.post_id = page.id) AS comment_count,
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
  ORDER BY post.id DESC
  LIMIT ?
) AS page
JOIN users AS author ON author.id = page.author_id
LEFT JOIN post_images AS image ON image.post_id = page.id
ORDER BY page.id DESC, image.position ASC;

-- name: GetPostImage :one
SELECT image.content_type, image.byte_size, image.object_key
FROM post_images AS image
JOIN posts AS post ON post.id = image.post_id
WHERE image.id = sqlc.arg(image_id)
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

-- name: PostExists :one
SELECT EXISTS (
  SELECT 1 FROM posts WHERE id = sqlc.arg(post_id)
) AS post_exists;

-- name: CreatePostComment :execresult
INSERT INTO post_comments (post_id, author_id, parent_comment_id, body)
VALUES (?, ?, ?, ?);

-- name: ReplyParentExists :one
SELECT EXISTS (
  SELECT 1
  FROM post_comments
  WHERE id = sqlc.arg(parent_comment_id)
    AND post_id = sqlc.arg(post_id)
    AND parent_comment_id IS NULL
) AS reply_parent_exists;

-- name: GetPostComment :one
SELECT
  comment.id,
  comment.post_id,
  comment.parent_comment_id,
  comment.body,
  comment.created_at,
  author.id AS author_id,
  author.username AS author_username,
  author.display_name AS author_display_name,
  author.avatar_content_type AS author_avatar_content_type,
  author.created_at AS author_created_at
FROM post_comments AS comment
JOIN users AS author ON author.id = comment.author_id
WHERE comment.id = sqlc.arg(comment_id)
LIMIT 1;

-- name: ListLatestPostComments :many
WITH selected_roots AS (
  SELECT root_comment.id
  FROM post_comments AS root_comment
  WHERE root_comment.post_id = sqlc.arg(post_id)
    AND root_comment.parent_comment_id IS NULL
  ORDER BY root_comment.id DESC
  LIMIT ?
),
selected_replies AS (
  SELECT
    reply.id,
    ROW_NUMBER() OVER (PARTITION BY reply.parent_comment_id ORDER BY reply.id DESC) AS reply_number
  FROM post_comments AS reply
  JOIN selected_roots AS root ON reply.parent_comment_id = root.id
)
SELECT
  comment.id,
  comment.post_id,
  comment.parent_comment_id,
  comment.body,
  comment.created_at,
  author.id AS author_id,
  author.username AS author_username,
  author.display_name AS author_display_name,
  author.avatar_content_type AS author_avatar_content_type,
  author.created_at AS author_created_at
FROM post_comments AS comment
JOIN selected_roots AS root
  ON comment.id = root.id
    OR (
      comment.parent_comment_id = root.id
      AND comment.id IN (
        SELECT id FROM selected_replies WHERE reply_number <= 50
      )
    )
JOIN users AS author ON author.id = comment.author_id
ORDER BY root.id DESC, comment.parent_comment_id IS NOT NULL, comment.id ASC;

-- name: ListPostCommentsBefore :many
WITH selected_roots AS (
  SELECT root_comment.id
  FROM post_comments AS root_comment
  WHERE root_comment.post_id = sqlc.arg(post_id)
    AND root_comment.parent_comment_id IS NULL
    AND root_comment.id < sqlc.arg(before_comment_id)
  ORDER BY root_comment.id DESC
  LIMIT ?
),
selected_replies AS (
  SELECT
    reply.id,
    ROW_NUMBER() OVER (PARTITION BY reply.parent_comment_id ORDER BY reply.id DESC) AS reply_number
  FROM post_comments AS reply
  JOIN selected_roots AS root ON reply.parent_comment_id = root.id
)
SELECT
  comment.id,
  comment.post_id,
  comment.parent_comment_id,
  comment.body,
  comment.created_at,
  author.id AS author_id,
  author.username AS author_username,
  author.display_name AS author_display_name,
  author.avatar_content_type AS author_avatar_content_type,
  author.created_at AS author_created_at
FROM post_comments AS comment
JOIN selected_roots AS root
  ON comment.id = root.id
    OR (
      comment.parent_comment_id = root.id
      AND comment.id IN (
        SELECT id FROM selected_replies WHERE reply_number <= 50
      )
    )
JOIN users AS author ON author.id = comment.author_id
ORDER BY root.id DESC, comment.parent_comment_id IS NOT NULL, comment.id ASC;

-- name: DeletePostCommentForAuthor :execresult
DELETE FROM post_comments
WHERE id = sqlc.arg(comment_id)
  AND post_id = sqlc.arg(post_id)
  AND author_id = sqlc.arg(author_id);
