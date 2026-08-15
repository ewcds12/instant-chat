ALTER TABLE post_comments
  DROP FOREIGN KEY fk_post_comments_parent_comment,
  DROP INDEX idx_post_comments_parent_comment_id,
  DROP COLUMN parent_comment_id;
