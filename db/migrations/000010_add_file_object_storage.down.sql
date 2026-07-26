ALTER TABLE message_files
  MODIFY COLUMN data LONGBLOB NOT NULL;

ALTER TABLE message_files
  DROP CHECK chk_message_files_storage,
  DROP INDEX uq_message_files_object_key,
  DROP COLUMN object_key;
