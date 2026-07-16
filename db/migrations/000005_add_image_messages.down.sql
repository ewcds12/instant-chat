ALTER TABLE messages
  DROP FOREIGN KEY fk_messages_image,
  DROP INDEX idx_messages_image_id,
  DROP COLUMN image_id,
  DROP COLUMN kind;

DROP TABLE message_images;
