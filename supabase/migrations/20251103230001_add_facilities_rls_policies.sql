-- =====================================================
-- Migration: Add RLS Policies for Facilities Table
-- Created: 2025-11-03
-- Description: Enables RLS and creates policies for facilities table
-- =====================================================

-- =====================================================
-- 1. Enable RLS on facilities table
-- =====================================================

ALTER TABLE facilities ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 2. Drop existing policies if any
-- =====================================================

DROP POLICY IF EXISTS "Anyone can view facilities" ON facilities;
DROP POLICY IF EXISTS "Facility admins can insert facilities" ON facilities;
DROP POLICY IF EXISTS "Facility admins can update their facilities" ON facilities;
DROP POLICY IF EXISTS "System admins full access to facilities" ON facilities;
DROP POLICY IF EXISTS "Service role full access" ON facilities;
DROP POLICY IF EXISTS "powersync_read_all" ON facilities;

-- =====================================================
-- 3. Create RLS policies for facilities
-- =====================================================

-- Public can view all facilities (for finding healthcare centers)
CREATE POLICY "Anyone can view facilities"
  ON facilities FOR SELECT
  TO authenticated
  USING (true);

-- Facility admins can create new facilities
-- (Only system admins should be able to create facilities in production)
CREATE POLICY "System admins can insert facilities"
  ON facilities FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM system_admin_profiles
      WHERE user_id = auth.uid()
    )
  );

-- Facility admins can update their own facilities
CREATE POLICY "Facility admins can update their facilities"
  ON facilities FOR UPDATE
  TO authenticated
  USING (
    -- Allow if user is facility admin for this facility
    EXISTS (
      SELECT 1 FROM facility_admin_profiles
      WHERE user_id = auth.uid()
      AND (
        primary_facility_id = facilities.id
        OR facilities.id::text = ANY(managed_facilities::text[])
      )
    )
    -- OR if user is system admin
    OR EXISTS (
      SELECT 1 FROM system_admin_profiles
      WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    -- Same check for WITH CHECK
    EXISTS (
      SELECT 1 FROM facility_admin_profiles
      WHERE user_id = auth.uid()
      AND (
        primary_facility_id = facilities.id
        OR facilities.id::text = ANY(managed_facilities::text[])
      )
    )
    OR EXISTS (
      SELECT 1 FROM system_admin_profiles
      WHERE user_id = auth.uid()
    )
  );

-- System admins have full access to all facilities
CREATE POLICY "System admins full access to facilities"
  ON facilities FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM system_admin_profiles
      WHERE user_id = auth.uid()
    )
  );

-- Service role bypass (for Firebase Functions and edge functions)
CREATE POLICY "Service role full access"
  ON facilities FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- PowerSync read access
CREATE POLICY "powersync_read_all"
  ON facilities FOR SELECT
  TO postgres
  USING (true);

-- =====================================================
-- 4. Grant necessary permissions
-- =====================================================

GRANT SELECT ON facilities TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON facilities TO authenticated;
GRANT ALL ON facilities TO service_role;

-- =====================================================
-- 5. Add helpful comments
-- =====================================================

COMMENT ON POLICY "Anyone can view facilities" ON facilities IS
  'Allows all authenticated users to view facilities (for finding healthcare centers)';

COMMENT ON POLICY "System admins can insert facilities" ON facilities IS
  'Only system admins can create new healthcare facilities';

COMMENT ON POLICY "Facility admins can update their facilities" ON facilities IS
  'Facility admins can update facilities they manage';

COMMENT ON POLICY "Service role full access" ON facilities IS
  'Allows server-side operations (Firebase Functions, edge functions) to manage facilities';

-- =====================================================
-- 6. Verification
-- =====================================================

DO $$
DECLARE
  policy_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'facilities';

  RAISE NOTICE '';
  RAISE NOTICE '=== Facilities RLS Policy Summary ===';
  RAISE NOTICE 'Total policies created: %', policy_count;
  RAISE NOTICE 'Expected: 6 policies';
  RAISE NOTICE '';

  IF policy_count >= 6 THEN
    RAISE NOTICE '✅ All facilities RLS policies configured successfully!';
  ELSE
    RAISE WARNING '⚠️ Some policies may be missing. Expected 6, got %', policy_count;
  END IF;
END $$;
