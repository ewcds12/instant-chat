DROP TABLE conversation_members;
DROP TABLE conversations;
DROP TABLE contact_relationships;

ALTER TABLE users
  DROP INDEX uq_users_username,
  DROP COLUMN username;
