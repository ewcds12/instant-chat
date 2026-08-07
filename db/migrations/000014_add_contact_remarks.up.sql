ALTER TABLE contact_relationships
  ADD COLUMN lower_user_remark VARCHAR(64) NOT NULL DEFAULT '' AFTER status,
  ADD COLUMN higher_user_remark VARCHAR(64) NOT NULL DEFAULT '' AFTER lower_user_remark;
