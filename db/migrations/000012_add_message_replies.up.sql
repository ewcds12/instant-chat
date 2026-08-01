ALTER TABLE messages
  ADD COLUMN reply_to_message_id BIGINT UNSIGNED NULL AFTER file_id,
  ADD CONSTRAINT fk_messages_reply_to FOREIGN KEY (reply_to_message_id) REFERENCES messages (id) ON DELETE SET NULL,
  ADD INDEX idx_messages_reply_to_message_id (reply_to_message_id);
