ALTER TABLE conversations
  ADD COLUMN next_sequence BIGINT UNSIGNED NOT NULL DEFAULT 1 AFTER created_by_user_id;

CREATE TABLE messages (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  conversation_id BIGINT UNSIGNED NOT NULL,
  sender_id BIGINT UNSIGNED NOT NULL,
  client_message_id VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  sequence BIGINT UNSIGNED NOT NULL,
  body VARCHAR(4000) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  CONSTRAINT uq_messages_conversation_sequence UNIQUE (conversation_id, sequence),
  CONSTRAINT uq_messages_sender_client_id UNIQUE (conversation_id, sender_id, client_message_id),
  CONSTRAINT fk_messages_conversation FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE,
  CONSTRAINT fk_messages_sender FOREIGN KEY (sender_id) REFERENCES users (id) ON DELETE CASCADE,
  INDEX idx_messages_conversation_sequence (conversation_id, sequence)
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;
