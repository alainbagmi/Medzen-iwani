-- Migration: Add ehr_id column to ehrbase_sync_queue table
-- Description: Enables the clinical note sync trigger to store patient EHR ID directly

-- Add ehr_id column to ehrbase_sync_queue if it doesn't exist
ALTER TABLE ehrbase_sync_queue ADD COLUMN IF NOT EXISTS ehr_id TEXT;

-- Add index for faster lookups by ehr_id
CREATE INDEX IF NOT EXISTS idx_ehrbase_sync_queue_ehr_id
ON ehrbase_sync_queue(ehr_id)
WHERE ehr_id IS NOT NULL;

-- Add comment
COMMENT ON COLUMN ehrbase_sync_queue.ehr_id IS 'EHRbase EHR ID for the patient - used for composition sync';
