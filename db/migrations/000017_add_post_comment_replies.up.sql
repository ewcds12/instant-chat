ALTER TABLE post_comments
  ADD COLUMN parent_comment_id BIGINT UNSIGNED NULL AFTER author_id,
  ADD CONSTRAINT fk_post_comments_parent_comment
    FOREIGN KEY (parent_comment_id) REFERENCES post_comments (id) ON DELETE CASCADE,
  ADD INDEX idx_post_comments_parent_comment_id (parent_comment_id, id ASC);
