-- Fix facility_id: Convert TEXT to UUID and add Foreign Key Constraint
-- Run this in Supabase Dashboard > SQL Editor

-- ============================================================================
-- STEP 1: Convert medical_provider_profiles.facility_id from TEXT to UUID
-- ============================================================================

-- Add temporary UUID column
ALTER TABLE medical_provider_profiles
ADD COLUMN facility_id_uuid UUID;

-- Copy valid UUIDs from TEXT to UUID column
UPDATE medical_provider_profiles
SET facility_id_uuid = facility_id::uuid
WHERE facility_id IS NOT NULL
  AND facility_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- Drop the old TEXT column (this will drop the indexes too)
ALTER TABLE medical_provider_profiles
DROP COLUMN facility_id CASCADE;

-- Rename the UUID column to facility_id
ALTER TABLE medical_provider_profiles
RENAME COLUMN facility_id_uuid TO facility_id;

-- Add the foreign key constraint
ALTER TABLE medical_provider_profiles
ADD CONSTRAINT fk_medical_provider_facility
FOREIGN KEY (facility_id)
REFERENCES facilities(id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

-- Recreate the indexes
CREATE INDEX idx_medical_provider_profiles_facility_id
ON medical_provider_profiles(facility_id);

CREATE INDEX idx_medical_provider_profiles_facility_status
ON medical_provider_profiles(facility_id, application_status)
WHERE facility_id IS NOT NULL;

-- Add column comment
COMMENT ON COLUMN medical_provider_profiles.facility_id IS
'Primary/home facility for the medical provider. Foreign key to facilities table.';

-- ============================================================================
-- STEP 2: Convert facility_admin_profiles.primary_facility_id from TEXT to UUID
-- ============================================================================

-- Check if the column exists first
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'facility_admin_profiles'
        AND column_name = 'primary_facility_id'
    ) THEN
        -- Add temporary UUID column
        ALTER TABLE facility_admin_profiles
        ADD COLUMN primary_facility_id_uuid UUID;

        -- Copy valid UUIDs from TEXT to UUID column
        UPDATE facility_admin_profiles
        SET primary_facility_id_uuid = primary_facility_id::uuid
        WHERE primary_facility_id IS NOT NULL
          AND primary_facility_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

        -- Drop the old TEXT column
        ALTER TABLE facility_admin_profiles
        DROP COLUMN primary_facility_id CASCADE;

        -- Rename the UUID column
        ALTER TABLE facility_admin_profiles
        RENAME COLUMN primary_facility_id_uuid TO primary_facility_id;

        -- Add the foreign key constraint
        ALTER TABLE facility_admin_profiles
        ADD CONSTRAINT fk_facility_admin_primary_facility
        FOREIGN KEY (primary_facility_id)
        REFERENCES facilities(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE;

        -- Create index
        CREATE INDEX idx_facility_admin_profiles_primary_facility
        ON facility_admin_profiles(primary_facility_id);

        -- Add column comment
        COMMENT ON COLUMN facility_admin_profiles.primary_facility_id IS
        'Primary facility managed by this admin. Foreign key to facilities table.';

        RAISE NOTICE 'facility_admin_profiles.primary_facility_id converted to UUID with FK constraint';
    END IF;
END $$;

-- ============================================================================
-- STEP 3: Verify the foreign key constraints were created
-- ============================================================================

SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS references_table,
    ccu.column_name AS references_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name IN ('medical_provider_profiles', 'facility_admin_profiles')
    AND kcu.column_name IN ('facility_id', 'primary_facility_id')
ORDER BY tc.table_name;

-- ============================================================================
-- STEP 4: Check column types after conversion
-- ============================================================================

SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'medical_provider_profiles'
    AND column_name = 'facility_id'
UNION ALL
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'facility_admin_profiles'
    AND column_name = 'primary_facility_id'
ORDER BY table_name, column_name;
