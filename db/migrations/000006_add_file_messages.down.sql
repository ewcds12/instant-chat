ALTER TABLE messages
  DROP FOREIGN KEY fk_messages_file,
  DROP INDEX idx_messages_file_id,
  DROP COLUMN file_id;

DROP TABLE message_files;
