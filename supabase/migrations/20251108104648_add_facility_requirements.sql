-- Migration: Add Facility Requirements for Providers and Admins
-- Purpose: Enforce facility assignment during registration and add proper foreign key constraints
-- Date: 2025-11-08

-- ============================================================================
-- PART 1: Data Validation and Cleanup
-- ============================================================================

-- Check for existing NULL values (for reporting purposes)
DO $$
DECLARE
    null_provider_count INTEGER;
    null_admin_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO null_provider_count
    FROM medical_provider_profiles
    WHERE facility_id IS NULL;

    SELECT COUNT(*) INTO null_admin_count
    FROM facility_admin_profiles
    WHERE primary_facility_id IS NULL;

    RAISE NOTICE 'Found % medical providers without facility assignment', null_provider_count;
    RAISE NOTICE 'Found % facility admins without facility assignment', null_admin_count;
END $$;

-- ============================================================================
-- PART 2: Fix Type Mismatch (TEXT to UUID) for Medical Provider Profiles
-- ============================================================================

-- Step 1: Create temporary column with UUID type
ALTER TABLE medical_provider_profiles
ADD COLUMN facility_id_uuid UUID;

-- Step 2: Copy data with conversion (only valid UUIDs)
UPDATE medical_provider_profiles
SET facility_id_uuid = facility_id::uuid
WHERE facility_id IS NOT NULL
  AND facility_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- Step 3: Drop old column and rename new one
ALTER TABLE medical_provider_profiles
DROP COLUMN facility_id CASCADE;

ALTER TABLE medical_provider_profiles
RENAME COLUMN facility_id_uuid TO facility_id;

-- Step 4: Add foreign key constraint
ALTER TABLE medical_provider_profiles
ADD CONSTRAINT fk_medical_provider_facility
FOREIGN KEY (facility_id)
REFERENCES facilities(id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

-- Step 5: Add NOT NULL constraint (commented out for safety - uncomment after ensuring all providers have facilities)
-- ALTER TABLE medical_provider_profiles
-- ALTER COLUMN facility_id SET NOT NULL;

-- Step 6: Add comment
COMMENT ON COLUMN medical_provider_profiles.facility_id IS 'Primary/home facility for the medical provider. Required field enforced at application level.';

-- ============================================================================
-- PART 3: Fix Type Mismatch (TEXT to UUID) for Facility Admin Profiles
-- ============================================================================

-- Step 1: Create temporary column with UUID type
ALTER TABLE facility_admin_profiles
ADD COLUMN primary_facility_id_uuid UUID;

-- Step 2: Copy data with conversion (only valid UUIDs)
UPDATE facility_admin_profiles
SET primary_facility_id_uuid = primary_facility_id::uuid
WHERE primary_facility_id IS NOT NULL
  AND primary_facility_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- Step 3: Drop old column and rename new one
ALTER TABLE facility_admin_profiles
DROP COLUMN primary_facility_id CASCADE;

ALTER TABLE facility_admin_profiles
RENAME COLUMN primary_facility_id_uuid TO primary_facility_id;

-- Step 4: Add foreign key constraint
ALTER TABLE facility_admin_profiles
ADD CONSTRAINT fk_facility_admin_primary_facility
FOREIGN KEY (primary_facility_id)
REFERENCES facilities(id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

-- Step 5: Add NOT NULL constraint (commented out for safety - uncomment after ensuring all admins have facilities)
-- ALTER TABLE facility_admin_profiles
-- ALTER COLUMN primary_facility_id SET NOT NULL;

-- Step 6: Add comment
COMMENT ON COLUMN facility_admin_profiles.primary_facility_id IS 'Primary facility managed by this admin. Required field enforced at application level.';

-- ============================================================================
-- PART 4: Update Indexes (regenerate after type change)
-- ============================================================================

-- Drop old indexes if they exist
DROP INDEX IF EXISTS idx_medical_provider_profiles_facility_id;
DROP INDEX IF EXISTS idx_medical_provider_profiles_facility_status;
DROP INDEX IF EXISTS idx_facility_admin_profiles_primary_facility;

-- Recreate indexes with UUID type
CREATE INDEX idx_medical_provider_profiles_facility_id
ON medical_provider_profiles(facility_id);

CREATE INDEX idx_medical_provider_profiles_facility_status
ON medical_provider_profiles(facility_id, application_status)
WHERE facility_id IS NOT NULL;

CREATE INDEX idx_facility_admin_profiles_primary_facility
ON facility_admin_profiles(primary_facility_id);

-- Create composite index for facility admin queries
CREATE INDEX idx_facility_admin_user_facility
ON facility_admin_profiles(user_id, primary_facility_id);

-- ============================================================================
-- PART 5: Update Row-Level Security Policies
-- ============================================================================

-- Drop and recreate facility admin provider access policy with UUID comparison
DROP POLICY IF EXISTS "facility_admin_facility_providers" ON medical_provider_profiles;

CREATE POLICY "facility_admin_facility_providers" ON medical_provider_profiles
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM facility_admin_profiles fap
      WHERE fap.user_id = auth.uid()
        AND (
          fap.primary_facility_id = medical_provider_profiles.facility_id
          OR medical_provider_profiles.facility_id = ANY(
            SELECT unnest(fap.managed_facilities::uuid[])
          )
        )
    )
  );

COMMENT ON POLICY "facility_admin_facility_providers" ON medical_provider_profiles IS
'Facility admins can view providers at their primary or managed facilities (UUID comparison)';

-- ============================================================================
-- PART 6: Update facility_providers junction table
-- ============================================================================

-- Fix facility_providers table types if needed
DO $$
BEGIN
    -- Check if facility_id is TEXT and convert to UUID
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'facility_providers'
        AND column_name = 'facility_id'
        AND data_type = 'text'
    ) THEN
        -- Create temp column
        ALTER TABLE facility_providers ADD COLUMN facility_id_uuid UUID;

        -- Copy data
        UPDATE facility_providers
        SET facility_id_uuid = facility_id::uuid
        WHERE facility_id IS NOT NULL
          AND facility_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

        -- Drop old and rename
        ALTER TABLE facility_providers DROP COLUMN facility_id CASCADE;
        ALTER TABLE facility_providers RENAME COLUMN facility_id_uuid TO facility_id;

        -- Add FK constraint
        ALTER TABLE facility_providers
        ADD CONSTRAINT fk_facility_providers_facility
        FOREIGN KEY (facility_id) REFERENCES facilities(id) ON DELETE CASCADE;

        RAISE NOTICE 'facility_providers.facility_id converted to UUID';
    END IF;

    -- Check if provider_id is TEXT and convert to UUID
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'facility_providers'
        AND column_name = 'provider_id'
        AND data_type = 'text'
    ) THEN
        -- Create temp column
        ALTER TABLE facility_providers ADD COLUMN provider_id_uuid UUID;

        -- Copy data
        UPDATE facility_providers
        SET provider_id_uuid = provider_id::uuid
        WHERE provider_id IS NOT NULL
          AND provider_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

        -- Drop old and rename
        ALTER TABLE facility_providers DROP COLUMN provider_id CASCADE;
        ALTER TABLE facility_providers RENAME COLUMN provider_id_uuid TO provider_id;

        -- Add FK constraint
        ALTER TABLE facility_providers
        ADD CONSTRAINT fk_facility_providers_provider
        FOREIGN KEY (provider_id) REFERENCES medical_provider_profiles(id) ON DELETE CASCADE;

        RAISE NOTICE 'facility_providers.provider_id converted to UUID';
    END IF;
END $$;

-- ============================================================================
-- PART 7: Create Helper Function to Ensure Facility Providers Entry
-- ============================================================================

-- Function to automatically create facility_providers entry when facility_id is set
CREATE OR REPLACE FUNCTION sync_provider_primary_facility()
RETURNS TRIGGER AS $$
BEGIN
    -- When facility_id is set (INSERT or UPDATE)
    IF NEW.facility_id IS NOT NULL THEN
        -- Insert or update facility_providers entry
        INSERT INTO facility_providers (
            facility_id,
            provider_id,
            is_primary_facility,
            is_active,
            start_date
        ) VALUES (
            NEW.facility_id,
            NEW.id,
            true,
            true,
            COALESCE(NEW.created_at, NOW())
        )
        ON CONFLICT (facility_id, provider_id)
        DO UPDATE SET
            is_primary_facility = true,
            is_active = true,
            updated_at = NOW();
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_sync_provider_primary_facility ON medical_provider_profiles;
CREATE TRIGGER trigger_sync_provider_primary_facility
    AFTER INSERT OR UPDATE OF facility_id ON medical_provider_profiles
    FOR EACH ROW
    EXECUTE FUNCTION sync_provider_primary_facility();

COMMENT ON FUNCTION sync_provider_primary_facility() IS
'Automatically creates/updates facility_providers entry when provider facility_id is set';

-- ============================================================================
-- PART 8: Validation and Summary
-- ============================================================================

DO $$
DECLARE
    provider_count INTEGER;
    admin_count INTEGER;
    provider_facility_count INTEGER;
    admin_facility_count INTEGER;
    facilities_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO provider_count FROM medical_provider_profiles;
    SELECT COUNT(*) INTO admin_count FROM facility_admin_profiles;
    SELECT COUNT(*) INTO provider_facility_count
    FROM medical_provider_profiles WHERE facility_id IS NOT NULL;
    SELECT COUNT(*) INTO admin_facility_count
    FROM facility_admin_profiles WHERE primary_facility_id IS NOT NULL;
    SELECT COUNT(*) INTO facilities_count FROM facilities WHERE is_active = true;

    RAISE NOTICE '=== Migration Summary ===';
    RAISE NOTICE 'Total medical providers: %', provider_count;
    RAISE NOTICE 'Providers with facility: %', provider_facility_count;
    RAISE NOTICE 'Providers without facility: %', provider_count - provider_facility_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Total facility admins: %', admin_count;
    RAISE NOTICE 'Admins with facility: %', admin_facility_count;
    RAISE NOTICE 'Admins without facility: %', admin_count - admin_facility_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Active facilities: %', facilities_count;
    RAISE NOTICE '';
    RAISE NOTICE '=== Action Required ===';
    IF provider_count - provider_facility_count > 0 THEN
        RAISE NOTICE 'WARNING: % providers need facility assignment before enabling NOT NULL constraint', provider_count - provider_facility_count;
    END IF;
    IF admin_count - admin_facility_count > 0 THEN
        RAISE NOTICE 'WARNING: % admins need facility assignment before enabling NOT NULL constraint', admin_count - admin_facility_count;
    END IF;
END $$;
