ALTER TABLE messages
  DROP FOREIGN KEY fk_messages_reply_to,
  DROP INDEX idx_messages_reply_to_message_id,
  DROP COLUMN reply_to_message_id;
