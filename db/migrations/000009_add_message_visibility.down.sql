DROP TABLE message_deletions;

ALTER TABLE messages
  DROP INDEX idx_messages_conversation_recalled_sequence,
  DROP COLUMN recalled_at;
