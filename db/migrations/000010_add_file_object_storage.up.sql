ALTER TABLE message_files
  MODIFY COLUMN data LONGBLOB NULL,
  ADD COLUMN object_key VARCHAR(512) CHARACTER SET ascii COLLATE ascii_bin NULL AFTER byte_size,
  ADD CONSTRAINT chk_message_files_storage
    CHECK ((data IS NULL) <> (object_key IS NULL)),
  ADD UNIQUE INDEX uq_message_files_object_key (object_key);
