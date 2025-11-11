-- =====================================================
-- Add Provider Type Constraints and Enhancements
-- =====================================================
-- Adds validation, legacy tracking, and helper views
-- to the existing medical_provider_types system
-- Created: 2025-11-06 21:00:00
-- =====================================================

-- 1. Add legacy column to track old values
ALTER TABLE medical_provider_profiles
ADD COLUMN IF NOT EXISTS professional_role_legacy VARCHAR(100);

-- Backup current values (only if legacy is null)
UPDATE medical_provider_profiles
SET professional_role_legacy = professional_role
WHERE professional_role_legacy IS NULL
  AND professional_role != 'Medical Doctor';

-- 2. Add check constraint to enforce standardized values
ALTER TABLE medical_provider_profiles
DROP CONSTRAINT IF EXISTS check_professional_role_values;

ALTER TABLE medical_provider_profiles
ADD CONSTRAINT check_professional_role_values
CHECK (professional_role IN (
  'Dentist',
  'Doctor of Osteopathic Medicine',
  'Emergency Medical Technician',
  'Licensed Clinical Social Worker',
  'Medical Doctor',
  'Medical Technologist',
  'Nurse Practitioner',
  'Occupational Therapist',
  'Optometrist',
  'Pharmacist',
  'Physical Therapist',
  'Physician Assistant',
  'Psychologist',
  'Registered Nurse',
  'Respiratory Therapist'
));

-- 3. Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_medical_provider_profiles_professional_role
ON medical_provider_profiles(professional_role);

-- 4. Create view joining provider profiles with type metadata
CREATE OR REPLACE VIEW v_provider_type_details AS
SELECT
  mpp.id as provider_id,
  mpp.user_id,
  u.full_name,
  u.email,
  mpp.professional_role,
  mpp.professional_role_legacy,
  mpt.provider_type_code,
  mpt.description as role_description,
  mpp.medical_license_number,
  mpp.application_status,
  mpp.years_of_experience,
  mpp.primary_specialization,
  mpp.practice_type
FROM medical_provider_profiles mpp
INNER JOIN users u ON u.id = mpp.user_id::uuid
LEFT JOIN medical_provider_types mpt ON mpt.provider_type_name = mpp.professional_role;

-- 5. Add helpful comments
COMMENT ON VIEW v_provider_type_details IS
'Provider details with standardized type information and legacy values for reference';

COMMENT ON COLUMN medical_provider_profiles.professional_role_legacy IS
'Original professional_role value before standardization (for reference only)';

-- 6. Grant permissions
GRANT SELECT ON v_provider_type_details TO postgres;
GRANT SELECT ON v_provider_type_details TO authenticated;

-- =====================================================
-- Verification
-- =====================================================

-- Check that constraint exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'check_professional_role_values'
  ) THEN
    RAISE NOTICE 'Check constraint successfully created';
  END IF;
END $$;

-- Check that legacy column exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'medical_provider_profiles'
    AND column_name = 'professional_role_legacy'
  ) THEN
    RAISE NOTICE 'Legacy column successfully created';
  END IF;
END $$;

-- Check that view exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.views
    WHERE table_name = 'v_provider_type_details'
  ) THEN
    RAISE NOTICE 'View successfully created';
  END IF;
END $$;

-- Check that index exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE indexname = 'idx_medical_provider_profiles_professional_role'
  ) THEN
    RAISE NOTICE 'Index successfully created';
  END IF;
END $$;
