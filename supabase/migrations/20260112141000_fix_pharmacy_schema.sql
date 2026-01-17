-- =====================================================
-- FIX PHARMACY SCHEMA
-- =====================================================
-- This migration adds missing columns to existing
-- medications and prescriptions tables to match
-- the expected schema from 20260112140000
-- =====================================================

-- =====================================================
-- MEDICATIONS TABLE: Add missing columns
-- =====================================================

-- Add brand_name column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'brand_name'
    ) THEN
        ALTER TABLE medications ADD COLUMN brand_name TEXT;
        RAISE NOTICE 'Added brand_name column to medications table';
    ELSE
        RAISE NOTICE 'brand_name column already exists in medications table';
    END IF;
END $$;

-- Add drug_class column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'drug_class'
    ) THEN
        ALTER TABLE medications ADD COLUMN drug_class TEXT;
        RAISE NOTICE 'Added drug_class column to medications table';
    END IF;
END $$;

-- Add active_ingredients column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'active_ingredients'
    ) THEN
        ALTER TABLE medications ADD COLUMN active_ingredients TEXT[];
        RAISE NOTICE 'Added active_ingredients column to medications table';
    END IF;
END $$;

-- Add strength column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'strength'
    ) THEN
        ALTER TABLE medications ADD COLUMN strength TEXT;
        RAISE NOTICE 'Added strength column to medications table';
    END IF;
END $$;

-- Add dosage_form column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'dosage_form'
    ) THEN
        ALTER TABLE medications ADD COLUMN dosage_form TEXT;
        RAISE NOTICE 'Added dosage_form column to medications table';
    END IF;
END $$;

-- Add route_of_administration column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'route_of_administration'
    ) THEN
        ALTER TABLE medications ADD COLUMN route_of_administration TEXT;
        RAISE NOTICE 'Added route_of_administration column to medications table';
    END IF;
END $$;

-- Add manufacturer column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'manufacturer'
    ) THEN
        ALTER TABLE medications ADD COLUMN manufacturer TEXT;
        RAISE NOTICE 'Added manufacturer column to medications table';
    END IF;
END $$;

-- Add description column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'description'
    ) THEN
        ALTER TABLE medications ADD COLUMN description TEXT;
        RAISE NOTICE 'Added description column to medications table';
    END IF;
END $$;

-- Add side_effects column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'side_effects'
    ) THEN
        ALTER TABLE medications ADD COLUMN side_effects TEXT;
        RAISE NOTICE 'Added side_effects column to medications table';
    END IF;
END $$;

-- Add warnings column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'warnings'
    ) THEN
        ALTER TABLE medications ADD COLUMN warnings TEXT;
        RAISE NOTICE 'Added warnings column to medications table';
    END IF;
END $$;

-- Add requires_prescription column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'requires_prescription'
    ) THEN
        ALTER TABLE medications ADD COLUMN requires_prescription BOOLEAN DEFAULT true;
        RAISE NOTICE 'Added requires_prescription column to medications table';
    END IF;
END $$;

-- Add is_generic column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'is_generic'
    ) THEN
        ALTER TABLE medications ADD COLUMN is_generic BOOLEAN DEFAULT false;
        RAISE NOTICE 'Added is_generic column to medications table';
    END IF;
END $$;

-- Add ndc_code column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'ndc_code'
    ) THEN
        ALTER TABLE medications ADD COLUMN ndc_code TEXT;
        RAISE NOTICE 'Added ndc_code column to medications table';
    END IF;
END $$;

-- Add storage_conditions column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'storage_conditions'
    ) THEN
        ALTER TABLE medications ADD COLUMN storage_conditions TEXT;
        RAISE NOTICE 'Added storage_conditions column to medications table';
    END IF;
END $$;

-- Add is_active column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'is_active'
    ) THEN
        ALTER TABLE medications ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE 'Added is_active column to medications table';
    END IF;
END $$;

-- Add timestamps if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE medications ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added created_at column to medications table';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'medications' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE medications ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to medications table';
    END IF;
END $$;

-- =====================================================
-- PRESCRIPTIONS TABLE: Add missing columns if needed
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'prescriptions' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE prescriptions ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added created_at column to prescriptions table';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'prescriptions' AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE prescriptions ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to prescriptions table';
    END IF;
END $$;

DO $$
BEGIN
    RAISE NOTICE 'Schema fix migration completed successfully';
END $$;
