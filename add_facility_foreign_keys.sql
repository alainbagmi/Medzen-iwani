-- Add Foreign Key Constraints for Facility Relationships
-- Run this in Supabase Dashboard > SQL Editor

-- ============================================================================
-- STEP 1: Check current column types
-- ============================================================================
SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name IN ('medical_provider_profiles', 'facility_admin_profiles', 'facilities')
    AND column_name IN ('facility_id', 'primary_facility_id', 'id')
ORDER BY table_name, column_name;

-- ============================================================================
-- STEP 2: Add foreign key for medical_provider_profiles
-- ============================================================================

-- First, drop the constraint if it exists
ALTER TABLE medical_provider_profiles
DROP CONSTRAINT IF EXISTS fk_medical_provider_facility;

-- Add the foreign key constraint
-- Note: This assumes facility_id is already UUID type
-- If it's TEXT, you'll need to convert it first (see full migration file)
ALTER TABLE medical_provider_profiles
ADD CONSTRAINT fk_medical_provider_facility
FOREIGN KEY (facility_id)
REFERENCES facilities(id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

-- ============================================================================
-- STEP 3: Add foreign key for facility_admin_profiles
-- ============================================================================

-- First, drop the constraint if it exists
ALTER TABLE facility_admin_profiles
DROP CONSTRAINT IF EXISTS fk_facility_admin_primary_facility;

-- Add the foreign key constraint
-- Note: This assumes primary_facility_id is already UUID type
-- If it's TEXT, you'll need to convert it first (see full migration file)
ALTER TABLE facility_admin_profiles
ADD CONSTRAINT fk_facility_admin_primary_facility
FOREIGN KEY (primary_facility_id)
REFERENCES facilities(id)
ON DELETE RESTRICT
ON UPDATE CASCADE;

-- ============================================================================
-- STEP 4: Add indexes for performance
-- ============================================================================

-- Drop old indexes if they exist
DROP INDEX IF EXISTS idx_medical_provider_profiles_facility_id;
DROP INDEX IF EXISTS idx_facility_admin_profiles_primary_facility;

-- Create new indexes
CREATE INDEX idx_medical_provider_profiles_facility_id
ON medical_provider_profiles(facility_id);

CREATE INDEX idx_facility_admin_profiles_primary_facility
ON facility_admin_profiles(primary_facility_id);

-- ============================================================================
-- STEP 5: Verify the constraints were added
-- ============================================================================

SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name IN ('medical_provider_profiles', 'facility_admin_profiles')
ORDER BY tc.table_name, tc.constraint_name;
