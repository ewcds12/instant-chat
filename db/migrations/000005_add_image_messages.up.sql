CREATE TABLE message_images (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uploader_id BIGINT UNSIGNED NOT NULL,
  content_type VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  byte_size INT UNSIGNED NOT NULL,
  data MEDIUMBLOB NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  CONSTRAINT fk_message_images_uploader FOREIGN KEY (uploader_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;

ALTER TABLE messages
  ADD COLUMN kind VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'text' AFTER sequence,
  ADD COLUMN image_id BIGINT UNSIGNED NULL AFTER body,
  ADD CONSTRAINT fk_messages_image FOREIGN KEY (image_id) REFERENCES message_images (id) ON DELETE RESTRICT,
  ADD INDEX idx_messages_image_id (image_id);
