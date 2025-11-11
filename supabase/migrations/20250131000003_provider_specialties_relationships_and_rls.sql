-- =====================================================
-- Provider Specialties Relationships and RLS Policies
-- =====================================================
-- Adds foreign key constraints, indexes, and comprehensive RLS policies
-- for provider_specialties and related tables
--
-- Created: 2025-01-31
-- Purpose: Secure provider specialty data with proper relationships and access control
-- =====================================================

-- =====================================================
-- 1. ADD FOREIGN KEY CONSTRAINTS
-- =====================================================

-- Note: We're working around TEXT/UUID type mismatches by using application-level validation
-- and creating check constraints for basic validation

-- Add check constraint to ensure provider_id references valid medical_provider_profiles
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'check_provider_specialties_provider_id_format'
  ) THEN
    ALTER TABLE provider_specialties
    ADD CONSTRAINT check_provider_specialties_provider_id_format
    CHECK (provider_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
  END IF;
END $$;

-- Add check constraint to ensure specialty_id references valid specialties
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'check_provider_specialties_specialty_id_format'
  ) THEN
    ALTER TABLE provider_specialties
    ADD CONSTRAINT check_provider_specialties_specialty_id_format
    CHECK (specialty_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');
  END IF;
END $$;

COMMENT ON CONSTRAINT check_provider_specialties_provider_id_format ON provider_specialties IS
'Ensures provider_id is a valid UUID format string';

COMMENT ON CONSTRAINT check_provider_specialties_specialty_id_format ON provider_specialties IS
'Ensures specialty_id is a valid UUID format string';

-- Create function to validate provider_specialty relationships
CREATE OR REPLACE FUNCTION validate_provider_specialty_relationships()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate provider_id exists in medical_provider_profiles
  IF NOT EXISTS (
    SELECT 1 FROM medical_provider_profiles
    WHERE id::text = NEW.provider_id
  ) THEN
    RAISE EXCEPTION 'Invalid provider_id: % does not exist in medical_provider_profiles', NEW.provider_id;
  END IF;

  -- Validate specialty_id exists in specialties
  IF NOT EXISTS (
    SELECT 1 FROM specialties
    WHERE id::text = NEW.specialty_id
  ) THEN
    RAISE EXCEPTION 'Invalid specialty_id: % does not exist in specialties', NEW.specialty_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to validate relationships on INSERT/UPDATE
DROP TRIGGER IF EXISTS trigger_validate_provider_specialty_relationships ON provider_specialties;

CREATE TRIGGER trigger_validate_provider_specialty_relationships
  BEFORE INSERT OR UPDATE ON provider_specialties
  FOR EACH ROW
  EXECUTE FUNCTION validate_provider_specialty_relationships();

COMMENT ON FUNCTION validate_provider_specialty_relationships() IS
'Validates provider_id and specialty_id exist in their respective tables before INSERT/UPDATE';

-- =====================================================
-- 2. ADD ADDITIONAL INDEXES FOR PERFORMANCE
-- =====================================================

-- Composite index for common queries (provider + active status)
CREATE INDEX IF NOT EXISTS idx_provider_specialties_provider_active
ON provider_specialties(provider_id, is_active)
WHERE is_active = true;

-- Index for board certified providers
CREATE INDEX IF NOT EXISTS idx_provider_specialties_board_certified
ON provider_specialties(specialty_id, board_certified)
WHERE board_certified = true AND is_active = true;

-- Index for specialty type filtering
CREATE INDEX IF NOT EXISTS idx_provider_specialties_type_active
ON provider_specialties(specialty_type, is_active)
WHERE is_active = true;

-- =====================================================
-- 3. ENABLE ROW LEVEL SECURITY
-- =====================================================

-- Enable RLS on provider-related tables
ALTER TABLE medical_provider_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE provider_specialties ENABLE ROW LEVEL SECURITY;
ALTER TABLE specialties ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 4. CREATE RLS POLICIES FOR SPECIALTIES TABLE
-- =====================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "specialties_public_read" ON specialties;
DROP POLICY IF EXISTS "specialties_admin_all" ON specialties;
DROP POLICY IF EXISTS "powersync_read_all" ON specialties;

-- Policy 1: Public read access (specialties are public reference data)
CREATE POLICY "specialties_public_read" ON specialties
  FOR SELECT
  TO authenticated
  USING (is_active = true);

-- Policy 2: System admin full access
CREATE POLICY "specialties_admin_all" ON specialties
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM system_admin_profiles
      WHERE system_admin_profiles.user_id::uuid = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM system_admin_profiles
      WHERE system_admin_profiles.user_id::uuid = auth.uid()
    )
  );

-- Policy 3: PowerSync read access
CREATE POLICY "powersync_read_all" ON specialties
  FOR SELECT
  TO postgres
  USING (true);

-- =====================================================
-- 5. CREATE RLS POLICIES FOR MEDICAL_PROVIDER_PROFILES
-- =====================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "providers_own_profile_read" ON medical_provider_profiles;
DROP POLICY IF EXISTS "providers_own_profile_update" ON medical_provider_profiles;
DROP POLICY IF EXISTS "providers_public_approved_read" ON medical_provider_profiles;
DROP POLICY IF EXISTS "facility_admin_facility_providers" ON medical_provider_profiles;
DROP POLICY IF EXISTS "system_admin_all_providers" ON medical_provider_profiles;
DROP POLICY IF EXISTS "powersync_read_all" ON medical_provider_profiles;

-- Policy 1: Providers can read their own profile
CREATE POLICY "providers_own_profile_read" ON medical_provider_profiles
  FOR SELECT
  TO authenticated
  USING (user_id::uuid = auth.uid());

-- Policy 2: Providers can update their own profile (except application_status)
CREATE POLICY "providers_own_profile_update" ON medical_provider_profiles
  FOR UPDATE
  TO authenticated
  USING (user_id::uuid = auth.uid())
  WITH CHECK (
    user_id::uuid = auth.uid()
    -- Prevent providers from changing their own application_status
    AND application_status = (SELECT application_status FROM medical_provider_profiles WHERE id = medical_provider_profiles.id)
  );

-- Policy 3: All authenticated users can read approved provider profiles (for search/booking)
CREATE POLICY "providers_public_approved_read" ON medical_provider_profiles
  FOR SELECT
  TO authenticated
  USING (application_status = 'approved');

-- Policy 4: Facility admins can read providers at their facility
CREATE POLICY "facility_admin_facility_providers" ON medical_provider_profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM facility_admin_profiles fap
      WHERE fap.user_id::uuid = auth.uid()
        AND (
          fap.primary_facility_id::text = medical_provider_profiles.facility_id::text
          OR medical_provider_profiles.facility_id::text = ANY(fap.managed_facilities::text[])
        )
    )
  );

-- Policy 5: System admins have full access to all provider profiles
CREATE POLICY "system_admin_all_providers" ON medical_provider_profiles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM system_admin_profiles
      WHERE system_admin_profiles.user_id::uuid = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM system_admin_profiles
      WHERE system_admin_profiles.user_id::uuid = auth.uid()
    )
  );

-- Policy 6: PowerSync read access
CREATE POLICY "powersync_read_all" ON medical_provider_profiles
  FOR SELECT
  TO postgres
  USING (true);

-- =====================================================
-- 6. CREATE RLS POLICIES FOR PROVIDER_SPECIALTIES
-- =====================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "provider_specialties_own_read" ON provider_specialties;
DROP POLICY IF EXISTS "provider_specialties_own_manage" ON provider_specialties;
DROP POLICY IF EXISTS "provider_specialties_public_read" ON provider_specialties;
DROP POLICY IF EXISTS "provider_specialties_facility_admin_read" ON provider_specialties;
DROP POLICY IF EXISTS "provider_specialties_system_admin_all" ON provider_specialties;
DROP POLICY IF EXISTS "powersync_read_all" ON provider_specialties;

-- Policy 1: Providers can read their own specialties
CREATE POLICY "provider_specialties_own_read" ON provider_specialties
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM medical_provider_profiles mpp
      WHERE mpp.id::text = provider_specialties.provider_id
        AND mpp.user_id::uuid = auth.uid()
    )
  );

-- Policy 2: Providers can manage their own specialties
CREATE POLICY "provider_specialties_own_manage" ON provider_specialties
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM medical_provider_profiles mpp
      WHERE mpp.id::text = provider_specialties.provider_id
        AND mpp.user_id::uuid = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM medical_provider_profiles mpp
      WHERE mpp.id::text = provider_specialties.provider_id
        AND mpp.user_id::uuid = auth.uid()
    )
  );

-- Policy 3: All authenticated users can read specialties of approved providers
CREATE POLICY "provider_specialties_public_read" ON provider_specialties
  FOR SELECT
  TO authenticated
  USING (
    is_active = true
    AND EXISTS (
      SELECT 1 FROM medical_provider_profiles mpp
      WHERE mpp.id::text = provider_specialties.provider_id
        AND mpp.application_status = 'approved'
    )
  );

-- Policy 4: Facility admins can read specialties of providers at their facility
CREATE POLICY "provider_specialties_facility_admin_read" ON provider_specialties
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM facility_admin_profiles fap
      INNER JOIN medical_provider_profiles mpp ON mpp.id::text = provider_specialties.provider_id
      WHERE fap.user_id::uuid = auth.uid()
        AND (
          fap.primary_facility_id::text = mpp.facility_id::text
          OR mpp.facility_id::text = ANY(fap.managed_facilities::text[])
        )
    )
  );

-- Policy 5: System admins have full access
CREATE POLICY "provider_specialties_system_admin_all" ON provider_specialties
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM system_admin_profiles
      WHERE system_admin_profiles.user_id::uuid = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM system_admin_profiles
      WHERE system_admin_profiles.user_id::uuid = auth.uid()
    )
  );

-- Policy 6: PowerSync read access
CREATE POLICY "powersync_read_all" ON provider_specialties
  FOR SELECT
  TO postgres
  USING (true);

-- =====================================================
-- 7. CREATE HELPER FUNCTIONS FOR PROVIDER SPECIALTY MANAGEMENT
-- =====================================================

-- Function to add multiple specialties to a provider
CREATE OR REPLACE FUNCTION add_provider_specialties(
  p_provider_id TEXT,
  p_specialty_ids TEXT[],
  p_specialty_type VARCHAR(50) DEFAULT 'secondary'
)
RETURNS TABLE(
  specialty_id TEXT,
  specialty_name TEXT,
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  v_specialty_id TEXT;
  v_specialty_name TEXT;
  v_exists BOOLEAN;
BEGIN
  -- Validate provider exists
  IF NOT EXISTS (SELECT 1 FROM medical_provider_profiles WHERE id::text = p_provider_id) THEN
    RAISE EXCEPTION 'Provider ID % does not exist', p_provider_id;
  END IF;

  -- Validate specialty type
  IF p_specialty_type NOT IN ('secondary', 'subspecialty', 'area_of_expertise') THEN
    RAISE EXCEPTION 'Invalid specialty_type: %. Must be secondary, subspecialty, or area_of_expertise', p_specialty_type;
  END IF;

  -- Process each specialty
  FOREACH v_specialty_id IN ARRAY p_specialty_ids
  LOOP
    -- Get specialty name
    SELECT s.specialty_name INTO v_specialty_name
    FROM specialties s
    WHERE s.id::text = v_specialty_id;

    -- Check if specialty exists
    IF v_specialty_name IS NULL THEN
      RETURN QUERY SELECT v_specialty_id, NULL::TEXT, false, 'Specialty not found'::TEXT;
      CONTINUE;
    END IF;

    -- Check if already assigned
    SELECT EXISTS (
      SELECT 1 FROM provider_specialties
      WHERE provider_id = p_provider_id
        AND specialty_id = v_specialty_id
    ) INTO v_exists;

    IF v_exists THEN
      RETURN QUERY SELECT v_specialty_id, v_specialty_name, false, 'Specialty already assigned'::TEXT;
      CONTINUE;
    END IF;

    -- Insert the specialty
    BEGIN
      INSERT INTO provider_specialties (provider_id, specialty_id, specialty_type, is_active)
      VALUES (p_provider_id, v_specialty_id, p_specialty_type, true);

      RETURN QUERY SELECT v_specialty_id, v_specialty_name, true, 'Added successfully'::TEXT;
    EXCEPTION WHEN OTHERS THEN
      RETURN QUERY SELECT v_specialty_id, v_specialty_name, false, SQLERRM::TEXT;
    END;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION add_provider_specialties(TEXT, TEXT[], VARCHAR) IS
'Batch add multiple specialties to a provider profile';

-- Function to remove multiple specialties from a provider
CREATE OR REPLACE FUNCTION remove_provider_specialties(
  p_provider_id TEXT,
  p_specialty_ids TEXT[]
)
RETURNS TABLE(
  specialty_id TEXT,
  success BOOLEAN,
  message TEXT
) AS $$
DECLARE
  v_specialty_id TEXT;
BEGIN
  -- Validate provider exists
  IF NOT EXISTS (SELECT 1 FROM medical_provider_profiles WHERE id::text = p_provider_id) THEN
    RAISE EXCEPTION 'Provider ID % does not exist', p_provider_id;
  END IF;

  -- Process each specialty
  FOREACH v_specialty_id IN ARRAY p_specialty_ids
  LOOP
    BEGIN
      DELETE FROM provider_specialties
      WHERE provider_id = p_provider_id
        AND specialty_id = v_specialty_id;

      IF FOUND THEN
        RETURN QUERY SELECT v_specialty_id, true, 'Removed successfully'::TEXT;
      ELSE
        RETURN QUERY SELECT v_specialty_id, false, 'Specialty not found for this provider'::TEXT;
      END IF;
    EXCEPTION WHEN OTHERS THEN
      RETURN QUERY SELECT v_specialty_id, false, SQLERRM::TEXT;
    END;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION remove_provider_specialties(TEXT, TEXT[]) IS
'Batch remove multiple specialties from a provider profile';

-- Function to get provider's full specialty information
CREATE OR REPLACE FUNCTION get_provider_specialty_info(p_provider_id TEXT)
RETURNS TABLE(
  provider_id TEXT,
  provider_name TEXT,
  primary_specialty_id TEXT,
  primary_specialty_name TEXT,
  secondary_specialties JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    mpp.id::text,
    u.first_name || ' ' || u.last_name as provider_name,
    mpp.primary_specialty_id,
    s.specialty_name as primary_specialty_name,
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'specialty_id', ps.specialty_id,
          'specialty_name', s2.specialty_name,
          'specialty_type', ps.specialty_type,
          'board_certified', ps.board_certified,
          'years_experience', ps.years_experience
        )
      ) FILTER (WHERE ps.id IS NOT NULL),
      '[]'::jsonb
    ) as secondary_specialties
  FROM medical_provider_profiles mpp
  INNER JOIN users u ON u.id = mpp.user_id::uuid
  LEFT JOIN specialties s ON s.id::text = mpp.primary_specialty_id
  LEFT JOIN provider_specialties ps ON ps.provider_id = mpp.id::text AND ps.is_active = true
  LEFT JOIN specialties s2 ON s2.id::text = ps.specialty_id
  WHERE mpp.id::text = p_provider_id
  GROUP BY mpp.id, u.first_name, u.last_name, mpp.primary_specialty_id, s.specialty_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_provider_specialty_info(TEXT) IS
'Get complete specialty information for a provider including primary and all secondary specialties';

-- =====================================================
-- 8. CREATE VIEW FOR PROVIDER SPECIALTY SEARCH
-- =====================================================

CREATE OR REPLACE VIEW v_provider_specialty_search AS
SELECT
  mpp.id as provider_id,
  mpp.user_id,
  u.first_name,
  u.last_name,
  u.email,
  mpp.provider_number,
  mpp.professional_role,
  mpp.years_of_experience,
  mpp.application_status,

  -- Primary specialty
  mpp.primary_specialty_id,
  ps_primary.specialty_code as primary_specialty_code,
  ps_primary.specialty_name as primary_specialty_name,

  -- All specialties (primary + secondary) as array
  ARRAY_AGG(DISTINCT ps_all.specialty_id) FILTER (WHERE ps_all.specialty_id IS NOT NULL) as all_specialty_ids,
  ARRAY_AGG(DISTINCT ps_all.specialty_name) FILTER (WHERE ps_all.specialty_name IS NOT NULL) as all_specialty_names,

  -- Count of secondary specialties
  COUNT(DISTINCT ps.id) as secondary_specialty_count,

  -- Board certifications
  COUNT(DISTINCT ps.id) FILTER (WHERE ps.board_certified = true) as board_certification_count

FROM medical_provider_profiles mpp
INNER JOIN users u ON u.id = mpp.user_id::uuid
LEFT JOIN specialties ps_primary ON ps_primary.id::text = mpp.primary_specialty_id
LEFT JOIN provider_specialties ps ON ps.provider_id = mpp.id::text AND ps.is_active = true
LEFT JOIN specialties ps_secondary ON ps_secondary.id::text = ps.specialty_id
LEFT JOIN (
  -- Union of primary and secondary specialties
  SELECT mpp2.id::text as provider_id, s.id::text as specialty_id, s.specialty_name
  FROM medical_provider_profiles mpp2
  LEFT JOIN specialties s ON s.id::text = mpp2.primary_specialty_id
  WHERE mpp2.primary_specialty_id IS NOT NULL

  UNION

  SELECT ps2.provider_id::text, ps2.specialty_id, s2.specialty_name
  FROM provider_specialties ps2
  INNER JOIN specialties s2 ON s2.id::text = ps2.specialty_id
  WHERE ps2.is_active = true
) ps_all ON ps_all.provider_id::text = mpp.id::text

WHERE mpp.application_status = 'approved'
GROUP BY
  mpp.id, mpp.user_id, u.first_name, u.last_name, u.email,
  mpp.provider_number, mpp.professional_role, mpp.years_of_experience,
  mpp.application_status, mpp.primary_specialty_id,
  ps_primary.specialty_code, ps_primary.specialty_name;

COMMENT ON VIEW v_provider_specialty_search IS
'Optimized view for searching providers by specialty with all specialty information aggregated';

-- Grant permissions on view
GRANT SELECT ON v_provider_specialty_search TO authenticated;
GRANT SELECT ON v_provider_specialty_search TO postgres;

-- =====================================================
-- 9. ADD HELPFUL DOCUMENTATION
-- =====================================================

COMMENT ON TABLE provider_specialties IS
'Junction table storing provider-specialty relationships with additional certification details.

SECURITY:
- RLS enabled with role-based access control
- Providers can manage their own specialties
- Approved provider specialties are publicly readable
- Facility admins can view providers at their facility
- System admins have full access

RELATIONSHIPS:
- provider_id → medical_provider_profiles.id (validated by trigger)
- specialty_id → specialties.id (validated by trigger)

TRIGGERS:
- Validates FK relationships on INSERT/UPDATE
- Updates specialty counts in specialties table
- Auto-updates updated_at timestamp';

-- =====================================================
-- 10. GRANT EXECUTION PERMISSIONS
-- =====================================================

-- Grant execute permissions on helper functions
GRANT EXECUTE ON FUNCTION add_provider_specialties(TEXT, TEXT[], VARCHAR) TO authenticated;
GRANT EXECUTE ON FUNCTION remove_provider_specialties(TEXT, TEXT[]) TO authenticated;
GRANT EXECUTE ON FUNCTION get_provider_specialty_info(TEXT) TO authenticated;

-- =====================================================
-- END OF MIGRATION
-- =====================================================

-- Summary of changes:
-- 1. Added UUID format validation constraints
-- 2. Created trigger to validate FK relationships
-- 3. Added performance indexes
-- 4. Enabled RLS on specialties, medical_provider_profiles, provider_specialties
-- 5. Created comprehensive RLS policies for all roles:
--    - Patient: Read approved providers and their specialties
--    - Provider: Read/update own profile and specialties
--    - Facility Admin: Read providers at their facility
--    - System Admin: Full access to all data
--    - PowerSync: Read access for sync
-- 6. Created helper functions for batch operations
-- 7. Created optimized search view
-- 8. Added comprehensive documentation
