#!/bin/bash

# Apply provider type standardization migration
# This script executes the migration via psql

SUPABASE_DB_URL="postgresql://postgres.noaeltglphdlkbflipit:FJClhDiZV5fAQ5mSzioel5bvRsKZM30xNtUhbNHXfoA=@aws-0-us-east-1.pooler.supabase.com:6543/postgres"

echo "============================================================"
echo "Applying Provider Type Standardization Migration"
echo "============================================================"
echo ""

# Execute the migration
psql "$SUPABASE_DB_URL" << 'EOF'

-- =====================================================
-- 1. CREATE PROVIDER TYPE ENUM
-- =====================================================

DO $$ BEGIN
  CREATE TYPE provider_type AS ENUM (
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
  );
EXCEPTION
  WHEN duplicate_object THEN
    RAISE NOTICE 'Type provider_type already exists, skipping';
END $$;

COMMENT ON TYPE provider_type IS 'Standardized medical provider professional role types';

-- =====================================================
-- 2. CREATE PROVIDER TYPES LOOKUP TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS provider_types (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  type_name provider_type NOT NULL UNIQUE,
  type_code VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  requires_medical_license BOOLEAN DEFAULT true,
  requires_board_certification BOOLEAN DEFAULT false,
  can_prescribe_medication BOOLEAN DEFAULT false,
  supervision_required BOOLEAN DEFAULT false,
  display_order INTEGER,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 3. SEED PROVIDER TYPES DATA
-- =====================================================

INSERT INTO provider_types (type_name, type_code, description, requires_medical_license, requires_board_certification, can_prescribe_medication, supervision_required, display_order) VALUES
('Medical Doctor', 'MD', 'Physician with MD degree, fully licensed to practice medicine', true, true, true, false, 1),
('Doctor of Osteopathic Medicine', 'DO', 'Physician with DO degree, fully licensed to practice medicine', true, true, true, false, 2),
('Nurse Practitioner', 'NP', 'Advanced practice registered nurse with prescriptive authority', true, true, true, false, 3),
('Physician Assistant', 'PA', 'Licensed to practice medicine under physician supervision', true, true, true, true, 4),
('Registered Nurse', 'RN', 'Licensed registered nurse providing direct patient care', true, false, false, false, 5),
('Pharmacist', 'PharmD', 'Licensed to dispense medications and provide pharmaceutical care', true, true, false, false, 6),
('Dentist', 'DDS', 'Licensed dental professional', true, true, false, false, 7),
('Optometrist', 'OD', 'Licensed eye care professional', true, true, false, false, 8),
('Psychologist', 'PsyD', 'Licensed mental health professional', true, true, false, false, 9),
('Physical Therapist', 'PT', 'Licensed physical therapy professional', true, true, false, false, 10),
('Occupational Therapist', 'OT', 'Licensed occupational therapy professional', true, true, false, false, 11),
('Respiratory Therapist', 'RT', 'Licensed respiratory care professional', true, true, false, false, 12),
('Medical Technologist', 'MT', 'Licensed laboratory professional', true, false, false, false, 13),
('Licensed Clinical Social Worker', 'LCSW', 'Licensed mental health and social services professional', true, true, false, false, 14),
('Emergency Medical Technician', 'EMT', 'Certified emergency medical services professional', true, false, false, false, 15)
ON CONFLICT (type_name) DO NOTHING;

-- =====================================================
-- 4. MIGRATE EXISTING DATA
-- =====================================================

ALTER TABLE medical_provider_profiles
ADD COLUMN IF NOT EXISTS professional_role_legacy VARCHAR(100);

UPDATE medical_provider_profiles
SET professional_role_legacy = professional_role
WHERE professional_role_legacy IS NULL;

UPDATE medical_provider_profiles
SET professional_role = 'Medical Doctor'
WHERE LOWER(professional_role) IN ('doctor', 'md', 'physician', 'medical_doctor');

UPDATE medical_provider_profiles
SET professional_role = 'Nurse Practitioner'
WHERE LOWER(professional_role) IN ('nurse practitioner', 'np', 'arnp', 'nurse_practitioner');

UPDATE medical_provider_profiles
SET professional_role = 'Physician Assistant'
WHERE LOWER(professional_role) IN ('physician assistant', 'pa', 'physician_assistant');

UPDATE medical_provider_profiles
SET professional_role = 'Registered Nurse'
WHERE LOWER(professional_role) IN ('nurse', 'rn', 'registered nurse', 'registered_nurse');

UPDATE medical_provider_profiles
SET professional_role = 'Dentist'
WHERE LOWER(professional_role) IN ('dentist', 'dds', 'dental');

UPDATE medical_provider_profiles
SET professional_role = 'Pharmacist'
WHERE LOWER(professional_role) IN ('pharmacist', 'pharmd', 'pharmacy');

UPDATE medical_provider_profiles
SET professional_role = 'Optometrist'
WHERE LOWER(professional_role) IN ('optometrist', 'od', 'optometry');

UPDATE medical_provider_profiles
SET professional_role = 'Psychologist'
WHERE LOWER(professional_role) IN ('psychologist', 'psyd', 'psychology');

UPDATE medical_provider_profiles
SET professional_role = 'Physical Therapist'
WHERE LOWER(professional_role) IN ('physical therapist', 'pt', 'physiotherapist', 'physical_therapist');

UPDATE medical_provider_profiles
SET professional_role = 'Occupational Therapist'
WHERE LOWER(professional_role) IN ('occupational therapist', 'ot', 'occupational_therapist');

UPDATE medical_provider_profiles
SET professional_role = 'Respiratory Therapist'
WHERE LOWER(professional_role) IN ('respiratory therapist', 'rt', 'respiratory_therapist');

-- =====================================================
-- 5. ADD CHECK CONSTRAINT
-- =====================================================

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

-- =====================================================
-- 6. CREATE INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_medical_provider_profiles_professional_role
ON medical_provider_profiles(professional_role);

CREATE INDEX IF NOT EXISTS idx_provider_types_type_code
ON provider_types(type_code);

CREATE INDEX IF NOT EXISTS idx_provider_types_active
ON provider_types(is_active)
WHERE is_active = true;

-- =====================================================
-- 7. CREATE VIEW FOR PROVIDER TYPE DETAILS
-- =====================================================

CREATE OR REPLACE VIEW v_provider_type_details AS
SELECT
  mpp.id as provider_id,
  mpp.user_id,
  u.full_name,
  u.email,
  mpp.professional_role,
  mpp.professional_role_legacy,
  pt.type_code,
  pt.description as role_description,
  pt.requires_medical_license,
  pt.requires_board_certification,
  pt.can_prescribe_medication,
  pt.supervision_required,
  mpp.medical_license_number,
  mpp.application_status,
  mpp.years_of_experience
FROM medical_provider_profiles mpp
INNER JOIN users u ON u.id = mpp.user_id::uuid
LEFT JOIN provider_types pt ON pt.type_name::text = mpp.professional_role;

COMMENT ON VIEW v_provider_type_details IS
'Provider details with standardized type information and legacy values for reference';

-- =====================================================
-- 8. CREATE FUNCTION TO VALIDATE PROVIDER TYPE
-- =====================================================

CREATE OR REPLACE FUNCTION validate_provider_type(role_value TEXT)
RETURNS BOOLEAN AS $func$
BEGIN
  RETURN role_value IN (
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
  );
END;
$func$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION validate_provider_type IS
'Validates that a provider type value matches one of the standardized types';

-- =====================================================
-- 9. CREATE TRIGGER FOR UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_provider_types_updated_at()
RETURNS TRIGGER AS $func$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$func$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_provider_types_updated_at ON provider_types;

CREATE TRIGGER trigger_provider_types_updated_at
  BEFORE UPDATE ON provider_types
  FOR EACH ROW
  EXECUTE FUNCTION update_provider_types_updated_at();

-- =====================================================
-- 10. GRANT PERMISSIONS
-- =====================================================

GRANT SELECT ON provider_types TO postgres;
GRANT SELECT ON provider_types TO authenticated;
GRANT SELECT ON v_provider_type_details TO postgres;
GRANT SELECT ON v_provider_type_details TO authenticated;

-- =====================================================
-- 11. ADD HELPFUL COMMENTS
-- =====================================================

COMMENT ON TABLE provider_types IS
'Lookup table for standardized medical provider professional role types with metadata about credentials and capabilities';

COMMENT ON COLUMN provider_types.type_name IS
'Standardized provider type name (uses provider_type enum)';

COMMENT ON COLUMN provider_types.type_code IS
'Short code for the provider type (e.g., MD, NP, PA)';

COMMENT ON COLUMN provider_types.requires_medical_license IS
'Whether this provider type requires a medical license';

COMMENT ON COLUMN provider_types.can_prescribe_medication IS
'Whether this provider type has prescriptive authority';

COMMENT ON COLUMN provider_types.supervision_required IS
'Whether this provider type requires physician supervision';

COMMENT ON COLUMN medical_provider_profiles.professional_role_legacy IS
'Original professional_role value before standardization migration (for reference only)';

EOF

echo ""
echo "============================================================"
echo "Migration Applied Successfully"
echo "============================================================"
echo ""
echo "Verifying results..."
echo ""

# Verify provider_types table
psql "$SUPABASE_DB_URL" -c "SELECT COUNT(*) as total_provider_types FROM provider_types;"

# Verify constraint
psql "$SUPABASE_DB_URL" -c "SELECT conname, contype FROM pg_constraint WHERE conname = 'check_professional_role_values';"

# Verify view
psql "$SUPABASE_DB_URL" -c "SELECT COUNT(*) FROM v_provider_type_details;"

# Check current provider
psql "$SUPABASE_DB_URL" -c "SELECT user_id, professional_role, professional_role_legacy FROM medical_provider_profiles LIMIT 5;"

echo ""
echo "============================================================"
echo "Verification Complete"
echo "============================================================"
