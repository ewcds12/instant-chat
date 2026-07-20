ALTER TABLE messages
  ADD COLUMN recalled_at DATETIME(6) NULL AFTER created_at,
  ADD INDEX idx_messages_conversation_recalled_sequence (conversation_id, recalled_at, sequence);

CREATE TABLE message_deletions (
  message_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  deleted_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (message_id, user_id),
  CONSTRAINT fk_message_deletions_message FOREIGN KEY (message_id) REFERENCES messages (id) ON DELETE CASCADE,
  CONSTRAINT fk_message_deletions_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;
