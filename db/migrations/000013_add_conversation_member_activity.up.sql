ALTER TABLE conversation_members
  ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE AFTER last_read_sequence,
  ADD INDEX idx_conversation_members_user_active (user_id, is_active, conversation_id);
