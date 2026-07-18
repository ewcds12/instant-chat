ALTER TABLE users
  ADD COLUMN gender VARCHAR(24) NULL AFTER display_name,
  ADD COLUMN region VARCHAR(80) NULL AFTER gender,
  ADD COLUMN avatar_content_type VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NULL AFTER region,
  ADD COLUMN avatar_data MEDIUMBLOB NULL AFTER avatar_content_type;
