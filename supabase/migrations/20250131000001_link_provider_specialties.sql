-- =====================================================
-- Link Provider Specialties - Relational Structure
-- =====================================================
-- Migrates from text-based specialty fields to proper relational structure
-- Adds foreign key to specialties table and creates junction table for
-- secondary specializations while maintaining backward compatibility
--
-- Created: 2025-01-31
-- Purpose: Enable standardized, queryable specialty data for providers
-- =====================================================

-- =====================================================
-- 1. ADD PRIMARY SPECIALTY FOREIGN KEY
-- =====================================================

-- Add primary_specialty_id column (foreign key to specialties table)
ALTER TABLE medical_provider_profiles
ADD COLUMN IF NOT EXISTS primary_specialty_id TEXT;

-- Foreign key constraint: primary_specialty_id references specialties table
-- Note: specialties.id is UUID type, primary_specialty_id is TEXT, so we skip FK constraint
-- Application-level validation will ensure data integrity
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'fk_medical_provider_profiles_primary_specialty'
  ) THEN
    -- Skip FK constraint due to type mismatch (TEXT vs UUID)
    -- Application code must validate specialty_id exists in specialties table
    NULL;
  END IF;
END $$;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_medical_provider_profiles_primary_specialty_id
ON medical_provider_profiles(primary_specialty_id);

COMMENT ON COLUMN medical_provider_profiles.primary_specialty_id IS
'References specialties.id (UUID stored as TEXT). Primary/main specialty for this provider. Use this instead of primary_specialization text field. No FK constraint due to type mismatch - application validates data integrity.';

-- =====================================================
-- 2. CREATE PROVIDER SPECIALTIES JUNCTION TABLE
-- =====================================================
-- For secondary specializations and sub-specialties (many-to-many relationship)

CREATE TABLE IF NOT EXISTS provider_specialties (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  provider_id TEXT NOT NULL,
  specialty_id TEXT NOT NULL,
  specialty_type VARCHAR(50) NOT NULL DEFAULT 'secondary',
  certification_date DATE,
  board_certified BOOLEAN DEFAULT false,
  years_experience INTEGER,
  notes TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Foreign key constraints
  -- Note: Both provider_id and specialty_id reference UUID columns but are stored as TEXT
  -- Skipping FK constraints due to TEXT vs UUID type mismatch
  -- Application-level validation will ensure data integrity

  -- Check constraint for specialty_type
  CONSTRAINT check_specialty_type_values
    CHECK (specialty_type IN ('secondary', 'subspecialty', 'area_of_expertise')),

  -- Unique constraint: provider can't have same specialty listed twice
  CONSTRAINT unique_provider_specialty
    UNIQUE (provider_id, specialty_id)
);

-- =====================================================
-- 3. CREATE INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_provider_specialties_provider_id
ON provider_specialties(provider_id);

CREATE INDEX IF NOT EXISTS idx_provider_specialties_specialty_id
ON provider_specialties(specialty_id);

CREATE INDEX IF NOT EXISTS idx_provider_specialties_type
ON provider_specialties(specialty_type);

CREATE INDEX IF NOT EXISTS idx_provider_specialties_active
ON provider_specialties(is_active)
WHERE is_active = true;

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_provider_specialties_provider_type
ON provider_specialties(provider_id, specialty_type)
WHERE is_active = true;

-- =====================================================
-- 4. CREATE TRIGGER FOR UPDATED_AT
-- =====================================================

CREATE OR REPLACE FUNCTION update_provider_specialties_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_provider_specialties_updated_at ON provider_specialties;

CREATE TRIGGER trigger_provider_specialties_updated_at
  BEFORE UPDATE ON provider_specialties
  FOR EACH ROW
  EXECUTE FUNCTION update_provider_specialties_updated_at();

-- =====================================================
-- 5. CREATE VIEW FOR PROVIDER SPECIALTY DETAILS
-- =====================================================
-- Combines primary and secondary specialties with full specialty details

CREATE OR REPLACE VIEW v_provider_specialty_details AS
SELECT
  mpp.id as provider_id,
  mpp.user_id,
  u.first_name,
  u.last_name,
  u.email,

  -- Primary specialty (new relational structure)
  mpp.primary_specialty_id,
  ps_primary.specialty_code as primary_specialty_code,
  ps_primary.specialty_name as primary_specialty_name,

  -- Legacy text field (for backward compatibility)
  mpp.primary_specialization as primary_specialty_text_legacy,

  -- Count of secondary specialties
  (SELECT COUNT(*)
   FROM provider_specialties ps
   WHERE ps.provider_id = mpp.id::text AND ps.is_active = true) as total_specialties,

  -- Provider details
  mpp.years_of_experience,
  mpp.professional_role,
  mpp.application_status

FROM medical_provider_profiles mpp
INNER JOIN users u ON u.id = mpp.user_id::uuid
LEFT JOIN specialties ps_primary ON ps_primary.id::text = mpp.primary_specialty_id;

COMMENT ON VIEW v_provider_specialty_details IS
'Consolidated view of provider specialty information combining new relational structure with legacy text fields';

-- =====================================================
-- 6. CREATE VIEW FOR PROVIDER SECONDARY SPECIALTIES
-- =====================================================

CREATE OR REPLACE VIEW v_provider_secondary_specialties AS
SELECT
  ps.provider_id,
  ps.specialty_id,
  s.specialty_code,
  s.specialty_name,
  s.description as specialty_description,
  ps.specialty_type,
  ps.board_certified,
  ps.certification_date,
  ps.years_experience,
  ps.notes,
  ps.is_active,
  ps.created_at
FROM provider_specialties ps
INNER JOIN specialties s ON s.id::text = ps.specialty_id
WHERE ps.is_active = true
ORDER BY ps.provider_id, ps.specialty_type, s.specialty_name;

COMMENT ON VIEW v_provider_secondary_specialties IS
'All secondary specializations, subspecialties, and areas of expertise for providers with full specialty details';

-- =====================================================
-- 7. CREATE VIEW FOR SPECIALTY PROVIDER COUNT
-- =====================================================
-- Useful for analytics: how many providers per specialty

CREATE OR REPLACE VIEW v_specialty_provider_counts AS
SELECT
  s.id as specialty_id,
  s.specialty_code,
  s.specialty_name,

  -- Count primary specialty assignments
  COUNT(DISTINCT mpp.id) FILTER (WHERE mpp.primary_specialty_id = s.id::text) as primary_count,

  -- Count secondary specialty assignments
  COUNT(DISTINCT ps.provider_id) FILTER (WHERE ps.specialty_id = s.id::text AND ps.is_active = true) as secondary_count,

  -- Total unique providers
  COUNT(DISTINCT
    CASE
      WHEN mpp.primary_specialty_id = s.id::text THEN mpp.id::text
      WHEN ps.provider_id IS NOT NULL AND ps.is_active = true THEN ps.provider_id
    END
  ) as total_provider_count

FROM specialties s
LEFT JOIN medical_provider_profiles mpp ON mpp.primary_specialty_id = s.id::text
LEFT JOIN provider_specialties ps ON ps.specialty_id = s.id::text
WHERE s.is_active = true
GROUP BY s.id, s.specialty_code, s.specialty_name
ORDER BY total_provider_count DESC, s.specialty_name;

COMMENT ON VIEW v_specialty_provider_counts IS
'Analytics view showing number of providers per specialty (primary and secondary)';

-- =====================================================
-- 8. ADD HELPFUL COMMENTS
-- =====================================================

COMMENT ON TABLE provider_specialties IS
'Many-to-many relationship between providers and specialties. Stores secondary specializations, subspecialties, and areas of expertise.';

COMMENT ON COLUMN provider_specialties.specialty_type IS
'Type of specialty relationship: secondary (additional specialty), subspecialty (specialized focus within main specialty), area_of_expertise (specific clinical interest)';

COMMENT ON COLUMN provider_specialties.board_certified IS
'Whether the provider is board certified in this specialty';

COMMENT ON COLUMN provider_specialties.years_experience IS
'Years of experience specifically in this specialty';

-- =====================================================
-- 9. GRANT PERMISSIONS FOR POWERSYNC
-- =====================================================

-- Grant SELECT on new table and views to postgres user (for PowerSync replication)
GRANT SELECT ON provider_specialties TO postgres;
GRANT SELECT ON v_provider_specialty_details TO postgres;
GRANT SELECT ON v_provider_secondary_specialties TO postgres;
GRANT SELECT ON v_specialty_provider_counts TO postgres;

-- Allow authenticated users to read specialty data
GRANT SELECT ON provider_specialties TO authenticated;

-- =====================================================
-- 10. MIGRATION NOTES
-- =====================================================

-- BACKWARD COMPATIBILITY:
-- - Legacy text fields (primary_specialization, secondary_specializations, sub_specialties)
--   are NOT removed to maintain backward compatibility
-- - New code should use primary_specialty_id and provider_specialties table
-- - Old code will continue to work with text fields during transition period
--
-- DATA MIGRATION STRATEGY (to be done separately):
-- - Option 1: Manual mapping of existing text values to specialty_id
-- - Option 2: Fuzzy matching script to auto-migrate common specialty names
-- - Option 3: UI prompt for providers to select from standardized list
--
-- FUTURE ENHANCEMENTS:
-- - Add data migration script to populate primary_specialty_id from primary_specialization text
-- - Add trigger to keep text fields in sync during transition
-- - Deprecate text fields after full migration

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check structure
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'provider_specialties'
-- ORDER BY ordinal_position;

-- Check foreign key constraints
-- SELECT con.conname, con.contype
-- FROM pg_constraint con
-- WHERE con.conrelid = 'provider_specialties'::regclass;

-- =====================================================
-- END OF MIGRATION
-- =====================================================
-- New structure created:
-- - primary_specialty_id column in medical_provider_profiles
-- - provider_specialties junction table for secondary/sub-specialties
-- - 3 views for easy querying
-- - Indexes for performance
-- - Backward compatibility maintained
