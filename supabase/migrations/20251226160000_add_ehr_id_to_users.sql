-- Migration: Add ehr_id column to users table
-- Description: Stores the EHRbase EHR ID for each patient to enable clinical note syncing

-- Add ehr_id column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS ehr_id TEXT;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_ehr_id ON users(ehr_id) WHERE ehr_id IS NOT NULL;

-- Add comment
COMMENT ON COLUMN users.ehr_id IS 'EHRbase EHR ID for the patient - set by onUserCreated Firebase function';
