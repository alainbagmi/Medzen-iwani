-- Add missing sync_type and data_snapshot columns directly
-- These were supposed to be added by 20250121000001 but never actually appeared

-- Add sync_type column
DO $$
BEGIN
    ALTER TABLE ehrbase_sync_queue ADD COLUMN sync_type VARCHAR(50) DEFAULT 'composition_create';
    RAISE NOTICE '✅ Added sync_type column';
EXCEPTION
    WHEN duplicate_column THEN
        RAISE NOTICE 'ℹ️  sync_type column already exists';
END $$;

-- Add data_snapshot column
DO $$
BEGIN
    ALTER TABLE ehrbase_sync_queue ADD COLUMN data_snapshot JSONB;
    RAISE NOTICE '✅ Added data_snapshot column';
EXCEPTION
    WHEN duplicate_column THEN
        RAISE NOTICE 'ℹ️  data_snapshot column already exists';
END $$;

-- Add last_retry_at column
DO $$
BEGIN
    ALTER TABLE ehrbase_sync_queue ADD COLUMN last_retry_at TIMESTAMPTZ;
    RAISE NOTICE '✅ Added last_retry_at column';
EXCEPTION
    WHEN duplicate_column THEN
        RAISE NOTICE 'ℹ️  last_retry_at column already exists';
END $$;

-- Add updated_at column
DO $$
BEGIN
    ALTER TABLE ehrbase_sync_queue ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
    RAISE NOTICE '✅ Added updated_at column';
EXCEPTION
    WHEN duplicate_column THEN
        RAISE NOTICE 'ℹ️  updated_at column already exists';
END $$;

-- Create index
CREATE INDEX IF NOT EXISTS idx_ehrbase_sync_queue_type_status
ON ehrbase_sync_queue(sync_type, sync_status);

-- Create unique constraint
DO $$
BEGIN
    ALTER TABLE ehrbase_sync_queue
    ADD CONSTRAINT unique_table_record_sync
    UNIQUE (table_name, record_id, sync_type);
    RAISE NOTICE '✅ Added unique constraint';
EXCEPTION
    WHEN duplicate_table THEN
        RAISE NOTICE 'ℹ️  Constraint already exists';
    WHEN others THEN
        RAISE NOTICE 'ℹ️  Constraint creation skipped: %', SQLERRM;
END $$;
