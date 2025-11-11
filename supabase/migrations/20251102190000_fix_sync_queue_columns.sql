-- Fix Migration: Ensure ehrbase_sync_queue has all required columns
-- This migration ensures sync_type and data_snapshot columns exist
-- (They should have been added by 20250121000001 but may not have been applied correctly)

DO $$
BEGIN
    -- Add sync_type column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'ehrbase_sync_queue'
        AND column_name = 'sync_type'
    ) THEN
        ALTER TABLE ehrbase_sync_queue
        ADD COLUMN sync_type VARCHAR(50) DEFAULT 'composition_create';

        RAISE NOTICE '✅ Added sync_type column to ehrbase_sync_queue';
    ELSE
        RAISE NOTICE 'ℹ️  sync_type column already exists';
    END IF;

    -- Add data_snapshot column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'ehrbase_sync_queue'
        AND column_name = 'data_snapshot'
    ) THEN
        ALTER TABLE ehrbase_sync_queue
        ADD COLUMN data_snapshot JSONB;

        RAISE NOTICE '✅ Added data_snapshot column to ehrbase_sync_queue';
    ELSE
        RAISE NOTICE 'ℹ️  data_snapshot column already exists';
    END IF;

    -- Add last_retry_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'ehrbase_sync_queue'
        AND column_name = 'last_retry_at'
    ) THEN
        ALTER TABLE ehrbase_sync_queue
        ADD COLUMN last_retry_at TIMESTAMPTZ;

        RAISE NOTICE '✅ Added last_retry_at column to ehrbase_sync_queue';
    ELSE
        RAISE NOTICE 'ℹ️  last_retry_at column already exists';
    END IF;

    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'ehrbase_sync_queue'
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE ehrbase_sync_queue
        ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();

        RAISE NOTICE '✅ Added updated_at column to ehrbase_sync_queue';
    ELSE
        RAISE NOTICE 'ℹ️  updated_at column already exists';
    END IF;
END $$;

-- Create index for sync_type and sync_status if it doesn't exist
CREATE INDEX IF NOT EXISTS idx_ehrbase_sync_queue_type_status
ON ehrbase_sync_queue(sync_type, sync_status);

-- Create unique constraint if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'unique_table_record_sync'
    ) THEN
        ALTER TABLE ehrbase_sync_queue
        ADD CONSTRAINT unique_table_record_sync
        UNIQUE (table_name, record_id, sync_type);

        RAISE NOTICE '✅ Added unique constraint unique_table_record_sync';
    ELSE
        RAISE NOTICE 'ℹ️  unique_table_record_sync constraint already exists';
    END IF;
EXCEPTION
    WHEN duplicate_table THEN
        RAISE NOTICE 'ℹ️  unique_table_record_sync constraint already exists';
END $$;
