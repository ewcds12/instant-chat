ALTER TABLE users
  ADD COLUMN username VARCHAR(32) NULL AFTER id;

UPDATE users
SET username = CONCAT('user_', id)
WHERE username IS NULL;

ALTER TABLE users
  MODIFY COLUMN username VARCHAR(32) NOT NULL,
  ADD CONSTRAINT uq_users_username UNIQUE (username);

CREATE TABLE contact_relationships (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  lower_user_id BIGINT UNSIGNED NOT NULL,
  higher_user_id BIGINT UNSIGNED NOT NULL,
  requested_by_user_id BIGINT UNSIGNED NOT NULL,
  status VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  CONSTRAINT uq_contact_relationships_user_pair UNIQUE (lower_user_id, higher_user_id),
  CONSTRAINT fk_contact_relationships_lower_user FOREIGN KEY (lower_user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_contact_relationships_higher_user FOREIGN KEY (higher_user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_contact_relationships_requested_by_user FOREIGN KEY (requested_by_user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT chk_contact_relationships_user_order CHECK (lower_user_id < higher_user_id),
  CONSTRAINT chk_contact_relationships_requester CHECK (requested_by_user_id IN (lower_user_id, higher_user_id)),
  CONSTRAINT chk_contact_relationships_status CHECK (status IN ('pending', 'accepted')),
  INDEX idx_contact_relationships_lower_status (lower_user_id, status, updated_at, id),
  INDEX idx_contact_relationships_higher_status (higher_user_id, status, updated_at, id),
  INDEX idx_contact_relationships_requester_status (requested_by_user_id, status, updated_at, id)
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE conversations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  kind VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  direct_lower_user_id BIGINT UNSIGNED NOT NULL,
  direct_higher_user_id BIGINT UNSIGNED NOT NULL,
  created_by_user_id BIGINT UNSIGNED NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  CONSTRAINT uq_conversations_direct_user_pair UNIQUE (direct_lower_user_id, direct_higher_user_id),
  CONSTRAINT fk_conversations_direct_lower_user FOREIGN KEY (direct_lower_user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_conversations_direct_higher_user FOREIGN KEY (direct_higher_user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT fk_conversations_created_by_user FOREIGN KEY (created_by_user_id) REFERENCES users (id) ON DELETE CASCADE,
  CONSTRAINT chk_conversations_kind CHECK (kind = 'direct'),
  CONSTRAINT chk_conversations_user_order CHECK (direct_lower_user_id < direct_higher_user_id),
  CONSTRAINT chk_conversations_creator CHECK (created_by_user_id IN (direct_lower_user_id, direct_higher_user_id)),
  INDEX idx_conversations_updated (updated_at, id)
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE conversation_members (
  conversation_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  joined_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (conversation_id, user_id),
  CONSTRAINT fk_conversation_members_conversations FOREIGN KEY (conversation_id) REFERENCES conversations (id) ON DELETE CASCADE,
  CONSTRAINT fk_conversation_members_users FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
  INDEX idx_conversation_members_user_joined (user_id, joined_at, conversation_id)
) ENGINE = InnoDB
  DEFAULT CHARACTER SET = utf8mb4
  COLLATE = utf8mb4_0900_ai_ci;
