UPDATE users
SET email = CONCAT(username, '@instant-chat.local')
WHERE email IS NULL;

ALTER TABLE users
  MODIFY COLUMN email VARCHAR(254) NOT NULL,
  ADD CONSTRAINT uq_users_email UNIQUE (email);
