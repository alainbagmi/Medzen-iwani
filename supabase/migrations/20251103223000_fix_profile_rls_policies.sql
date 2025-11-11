-- Migration: Fix RLS Policies for Profile Tables
-- Allows users to create and manage their own profiles
-- Date: 2025-11-03

-- =====================================================
-- 1. Enable RLS on all profile tables
-- =====================================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE medical_provider_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE facility_admin_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_admin_profiles ENABLE ROW LEVEL SECURITY;

-- Also enable on legacy profile tables if they exist
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'doctor_profiles') THEN
        ALTER TABLE doctor_profiles ENABLE ROW LEVEL SECURITY;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'nurse_profiles') THEN
        ALTER TABLE nurse_profiles ENABLE ROW LEVEL SECURITY;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_profiles') THEN
        ALTER TABLE admin_profiles ENABLE ROW LEVEL SECURITY;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'pharmacist_profiles') THEN
        ALTER TABLE pharmacist_profiles ENABLE ROW LEVEL SECURITY;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'lab_technician_profiles') THEN
        ALTER TABLE lab_technician_profiles ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- =====================================================
-- 2. Drop all existing profile policies (clean slate)
-- =====================================================

DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON user_profiles;
DROP POLICY IF EXISTS "Service role full access" ON user_profiles;
DROP POLICY IF EXISTS "Authenticated users read own profile" ON user_profiles;

DROP POLICY IF EXISTS "Users can view own profile" ON patient_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON patient_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON patient_profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON patient_profiles;
DROP POLICY IF EXISTS "Service role full access" ON patient_profiles;

DROP POLICY IF EXISTS "Users can view own profile" ON medical_provider_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON medical_provider_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON medical_provider_profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON medical_provider_profiles;
DROP POLICY IF EXISTS "Service role full access" ON medical_provider_profiles;

DROP POLICY IF EXISTS "Users can view own profile" ON facility_admin_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON facility_admin_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON facility_admin_profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON facility_admin_profiles;
DROP POLICY IF EXISTS "Service role full access" ON facility_admin_profiles;

DROP POLICY IF EXISTS "Users can view own profile" ON system_admin_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON system_admin_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON system_admin_profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON system_admin_profiles;
DROP POLICY IF EXISTS "Service role full access" ON system_admin_profiles;

-- Drop PowerSync policies
DROP POLICY IF EXISTS "powersync_read_all" ON user_profiles;
DROP POLICY IF EXISTS "powersync_read_all" ON patient_profiles;
DROP POLICY IF EXISTS "powersync_read_all" ON medical_provider_profiles;
DROP POLICY IF EXISTS "powersync_read_all" ON facility_admin_profiles;
DROP POLICY IF EXISTS "powersync_read_all" ON system_admin_profiles;

-- =====================================================
-- 3. Create new comprehensive RLS policies
-- Note: auth.uid() returns the Supabase user ID which matches users.id
-- =====================================================

-- =====================================================
-- 3a. user_profiles policies
-- =====================================================

CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own profile"
  ON user_profiles FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Service role bypass (for Firebase Functions)
CREATE POLICY "Service role full access"
  ON user_profiles FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- 3b. patient_profiles policies
-- =====================================================

CREATE POLICY "Users can view own profile"
  ON patient_profiles FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own profile"
  ON patient_profiles FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON patient_profiles FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own profile"
  ON patient_profiles FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Service role bypass
CREATE POLICY "Service role full access"
  ON patient_profiles FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- 3c. medical_provider_profiles policies
-- =====================================================

CREATE POLICY "Users can view own profile"
  ON medical_provider_profiles FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own profile"
  ON medical_provider_profiles FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON medical_provider_profiles FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own profile"
  ON medical_provider_profiles FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Service role bypass
CREATE POLICY "Service role full access"
  ON medical_provider_profiles FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- 3d. facility_admin_profiles policies
-- =====================================================

CREATE POLICY "Users can view own profile"
  ON facility_admin_profiles FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own profile"
  ON facility_admin_profiles FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON facility_admin_profiles FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own profile"
  ON facility_admin_profiles FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Service role bypass
CREATE POLICY "Service role full access"
  ON facility_admin_profiles FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- 3e. system_admin_profiles policies
-- =====================================================

CREATE POLICY "Users can view own profile"
  ON system_admin_profiles FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own profile"
  ON system_admin_profiles FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON system_admin_profiles FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own profile"
  ON system_admin_profiles FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Service role bypass
CREATE POLICY "Service role full access"
  ON system_admin_profiles FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- 4. Add PowerSync read access to profile tables
-- =====================================================

-- Allow PowerSync postgres user to read all profiles for sync
CREATE POLICY "powersync_read_all" ON user_profiles
  FOR SELECT
  TO postgres
  USING (true);

CREATE POLICY "powersync_read_all" ON patient_profiles
  FOR SELECT
  TO postgres
  USING (true);

CREATE POLICY "powersync_read_all" ON medical_provider_profiles
  FOR SELECT
  TO postgres
  USING (true);

CREATE POLICY "powersync_read_all" ON facility_admin_profiles
  FOR SELECT
  TO postgres
  USING (true);

CREATE POLICY "powersync_read_all" ON system_admin_profiles
  FOR SELECT
  TO postgres
  USING (true);

-- =====================================================
-- 5. Add helpful comments
-- =====================================================

COMMENT ON POLICY "Users can insert own profile" ON user_profiles IS
  'Allows authenticated users to create their own user_profiles entry';

COMMENT ON POLICY "Users can insert own profile" ON patient_profiles IS
  'Allows authenticated users to create their own patient_profiles entry';

COMMENT ON POLICY "Service role full access" ON user_profiles IS
  'Allows Firebase Cloud Functions (using service_role) to manage all profiles';

-- =====================================================
-- 6. Grant necessary table permissions
-- =====================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON user_profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON patient_profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON medical_provider_profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON facility_admin_profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON system_admin_profiles TO authenticated;

GRANT ALL ON user_profiles TO service_role;
GRANT ALL ON patient_profiles TO service_role;
GRANT ALL ON medical_provider_profiles TO service_role;
GRANT ALL ON facility_admin_profiles TO service_role;
GRANT ALL ON system_admin_profiles TO service_role;

-- =====================================================
-- 7. Verification
-- =====================================================

DO $$
DECLARE
  policy_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename IN ('user_profiles', 'patient_profiles', 'medical_provider_profiles',
                      'facility_admin_profiles', 'system_admin_profiles');

  RAISE NOTICE '';
  RAISE NOTICE '=== RLS Policy Summary ===';
  RAISE NOTICE 'Total policies created: %', policy_count;
  RAISE NOTICE 'Expected: 25 policies (5 tables × 5 policies each)';
  RAISE NOTICE '';

  IF policy_count >= 25 THEN
    RAISE NOTICE '✅ All profile RLS policies configured successfully!';
  ELSE
    RAISE WARNING '⚠️ Some policies may be missing. Expected 25, got %', policy_count;
  END IF;
END $$;
