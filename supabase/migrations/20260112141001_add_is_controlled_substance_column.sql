-- =====================================================
-- ADD MISSING is_controlled_substance COLUMN
-- =====================================================
-- This migration adds the missing is_controlled_substance
-- column to the medications table, which is required
-- by the pharmacy_products data migration
-- =====================================================

-- Add is_controlled_substance column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'is_controlled_substance'
    ) THEN
        ALTER TABLE medications ADD COLUMN is_controlled_substance BOOLEAN DEFAULT false;
        RAISE NOTICE 'Added is_controlled_substance column to medications table';
    ELSE
        RAISE NOTICE 'is_controlled_substance column already exists in medications table';
    END IF;
END $$;

-- =====================================================
-- END OF MIGRATION
-- =====================================================
