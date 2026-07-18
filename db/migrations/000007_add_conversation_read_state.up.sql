ALTER TABLE conversation_members
  ADD COLUMN last_read_sequence BIGINT UNSIGNED NOT NULL DEFAULT 0 AFTER user_id;
