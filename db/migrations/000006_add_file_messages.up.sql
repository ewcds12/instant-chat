CREATE TABLE message_files (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  uploader_id BIGINT UNSIGNED NOT NULL,
  filename VARCHAR(255) NOT NULL,
  content_type VARCHAR(128) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  byte_size INT UNSIGNED NOT NULL,
  data LONGBLOB NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  CONSTRAINT fk_message_files_uploader FOREIGN KEY (uploader_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;

ALTER TABLE messages
  ADD COLUMN file_id BIGINT UNSIGNED NULL AFTER image_id,
  ADD CONSTRAINT fk_messages_file FOREIGN KEY (file_id) REFERENCES message_files (id) ON DELETE RESTRICT,
  ADD INDEX idx_messages_file_id (file_id);
