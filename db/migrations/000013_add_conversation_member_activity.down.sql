ALTER TABLE conversation_members
  DROP INDEX idx_conversation_members_user_active,
  DROP COLUMN is_active;
