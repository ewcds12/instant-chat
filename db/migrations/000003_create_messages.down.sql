DROP TABLE messages;

ALTER TABLE conversations
  DROP COLUMN next_sequence;
