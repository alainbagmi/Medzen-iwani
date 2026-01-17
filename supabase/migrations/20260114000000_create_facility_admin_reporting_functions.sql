-- Migration: Create Facility Admin Reporting Functions
-- Date: 2026-01-14
-- Purpose: Enable facility admin Nova Lite AI to query facility statistics and operational metrics
--          while enforcing managed_facilities scope and can_view_reports permission check
--          Functions return facility-scoped data: patient count, staff count, user count, metrics
--
-- CRITICAL CONSTRAINT: "the ai should only do what the role (facility admin) can do"
-- Implementation:
--   1. managed_facilities array scope verification (RBAC)
--   2. can_view_reports permission gate (granular permissions)
--   3. SECURITY DEFINER pattern for controlled RLS bypass
--   4. Proper error handling with descriptive messages

-- ============================================================================
-- Function 1: Get Facility Patient Count
-- ============================================================================
-- Returns total active patients assigned to facility
-- Scope: Only patients with preferred_hospital_id matching the facility

CREATE OR REPLACE FUNCTION get_facility_patients_count(
  p_facility_id TEXT,
  p_admin_user_id TEXT
) RETURNS TABLE(
  patient_count INT,
  error_message TEXT
) AS $$
DECLARE
  v_has_access BOOLEAN;
  v_count INT;
  v_error_message TEXT := NULL;
BEGIN
  -- Step 1: Verify admin has access to this facility
  SELECT EXISTS (
    SELECT 1 FROM facility_admin_profiles
    WHERE user_id = p_admin_user_id
      AND managed_facilities @> ARRAY[p_facility_id]::TEXT[]
      AND can_view_reports = true
  ) INTO v_has_access;

  IF NOT v_has_access THEN
    v_error_message := 'Access Denied: You do not have permission to view reports for this facility.';
    RETURN QUERY SELECT NULL::INT, v_error_message;
    RETURN;
  END IF;

  -- Step 2: Get patient count for facility
  -- Patients are linked to facility via preferred_hospital_id
  SELECT COUNT(*)::INT
  INTO v_count
  FROM patient_profiles pp
  WHERE pp.preferred_hospital_id = p_facility_id
    AND EXISTS (
      SELECT 1 FROM users u
      WHERE u.id = pp.user_id AND u.is_active = true
    );

  RETURN QUERY SELECT v_count, v_error_message;
EXCEPTION WHEN OTHERS THEN
  v_error_message := 'Database Error: ' || SQLERRM;
  RETURN QUERY SELECT NULL::INT, v_error_message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- Function 2: Get Facility Staff Count
-- ============================================================================
-- Returns total active staff members assigned to facility
-- Scope: Only providers in facility_providers with:
--   - facility_id matching facility
--   - is_active = true
--   - end_date IS NULL (currently employed)

CREATE OR REPLACE FUNCTION get_facility_staff_count(
  p_facility_id TEXT,
  p_admin_user_id TEXT
) RETURNS TABLE(
  staff_count INT,
  error_message TEXT
) AS $$
DECLARE
  v_has_access BOOLEAN;
  v_count INT;
  v_error_message TEXT := NULL;
BEGIN
  -- Step 1: Verify admin has access to this facility
  SELECT EXISTS (
    SELECT 1 FROM facility_admin_profiles
    WHERE user_id = p_admin_user_id
      AND managed_facilities @> ARRAY[p_facility_id]::TEXT[]
      AND can_view_reports = true
  ) INTO v_has_access;

  IF NOT v_has_access THEN
    v_error_message := 'Access Denied: You do not have permission to view reports for this facility.';
    RETURN QUERY SELECT NULL::INT, v_error_message;
    RETURN;
  END IF;

  -- Step 2: Get staff count for facility
  -- Staff linked via facility_providers junction table
  -- Active staff: is_active = true AND end_date IS NULL
  SELECT COUNT(*)::INT
  INTO v_count
  FROM facility_providers fp
  WHERE fp.facility_id = p_facility_id
    AND fp.is_active = true
    AND fp.end_date IS NULL;

  RETURN QUERY SELECT v_count, v_error_message;
EXCEPTION WHEN OTHERS THEN
  v_error_message := 'Database Error: ' || SQLERRM;
  RETURN QUERY SELECT NULL::INT, v_error_message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- Function 3: Get Facility Active Users Count
-- ============================================================================
-- Returns total active user accounts linked to facility
-- Scope: Counts users who are active (is_active = true) and have any role at facility
-- Includes: patients, providers, facility admins with this facility in managed_facilities

CREATE OR REPLACE FUNCTION get_facility_active_users_count(
  p_facility_id TEXT,
  p_admin_user_id TEXT
) RETURNS TABLE(
  user_count INT,
  error_message TEXT
) AS $$
DECLARE
  v_has_access BOOLEAN;
  v_count INT;
  v_error_message TEXT := NULL;
BEGIN
  -- Step 1: Verify admin has access to this facility
  SELECT EXISTS (
    SELECT 1 FROM facility_admin_profiles
    WHERE user_id = p_admin_user_id
      AND managed_facilities @> ARRAY[p_facility_id]::TEXT[]
      AND can_view_reports = true
  ) INTO v_has_access;

  IF NOT v_has_access THEN
    v_error_message := 'Access Denied: You do not have permission to view reports for this facility.';
    RETURN QUERY SELECT NULL::INT, v_error_message;
    RETURN;
  END IF;

  -- Step 2: Get unique active users linked to facility
  -- Count users across all roles: patients, providers, facility admins
  SELECT COUNT(DISTINCT u.id)::INT
  INTO v_count
  FROM users u
  WHERE u.is_active = true
    AND (
      -- Patients with preferred facility
      EXISTS (SELECT 1 FROM patient_profiles pp WHERE pp.user_id = u.id AND pp.preferred_hospital_id = p_facility_id)
      OR
      -- Providers at this facility
      EXISTS (SELECT 1 FROM facility_providers fp WHERE fp.facility_id = p_facility_id AND EXISTS (SELECT 1 FROM medical_provider_profiles mpp WHERE mpp.user_id = u.id AND mpp.id = fp.provider_id AND fp.is_active = true AND fp.end_date IS NULL))
      OR
      -- Facility admins managing this facility
      EXISTS (SELECT 1 FROM facility_admin_profiles fap WHERE fap.user_id = u.id AND fap.managed_facilities @> ARRAY[p_facility_id]::TEXT[])
    );

  RETURN QUERY SELECT v_count, v_error_message;
EXCEPTION WHEN OTHERS THEN
  v_error_message := 'Database Error: ' || SQLERRM;
  RETURN QUERY SELECT NULL::INT, v_error_message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- Function 4: Get Facility Summary (Comprehensive Metrics)
-- ============================================================================
-- Returns comprehensive facility statistics including operational metrics
-- Scope: All counts and metrics for facility; enforces access control

CREATE OR REPLACE FUNCTION get_facility_summary(
  p_facility_id TEXT,
  p_admin_user_id TEXT
) RETURNS TABLE(
  patient_count INT,
  staff_count INT,
  active_users_count INT,
  operational_efficiency_score NUMERIC,
  patient_satisfaction_avg NUMERIC,
  error_message TEXT
) AS $$
DECLARE
  v_has_access BOOLEAN;
  v_patient_count INT;
  v_staff_count INT;
  v_users_count INT;
  v_efficiency NUMERIC;
  v_satisfaction NUMERIC;
  v_error_message TEXT := NULL;
BEGIN
  -- Step 1: Verify admin has access to this facility
  SELECT EXISTS (
    SELECT 1 FROM facility_admin_profiles
    WHERE user_id = p_admin_user_id
      AND managed_facilities @> ARRAY[p_facility_id]::TEXT[]
      AND can_view_reports = true
  ) INTO v_has_access;

  IF NOT v_has_access THEN
    v_error_message := 'Access Denied: You do not have permission to view reports for this facility.';
    RETURN QUERY SELECT NULL::INT, NULL::INT, NULL::INT, NULL::NUMERIC, NULL::NUMERIC, v_error_message;
    RETURN;
  END IF;

  -- Step 2: Get all metrics

  -- Patient count
  SELECT COUNT(*)::INT
  INTO v_patient_count
  FROM patient_profiles pp
  WHERE pp.preferred_hospital_id = p_facility_id
    AND EXISTS (SELECT 1 FROM users u WHERE u.id = pp.user_id AND u.is_active = true);

  -- Staff count
  SELECT COUNT(*)::INT
  INTO v_staff_count
  FROM facility_providers fp
  WHERE fp.facility_id = p_facility_id
    AND fp.is_active = true
    AND fp.end_date IS NULL;

  -- Active users count
  SELECT COUNT(DISTINCT u.id)::INT
  INTO v_users_count
  FROM users u
  WHERE u.is_active = true
    AND (
      EXISTS (SELECT 1 FROM patient_profiles pp WHERE pp.user_id = u.id AND pp.preferred_hospital_id = p_facility_id)
      OR
      EXISTS (SELECT 1 FROM facility_providers fp WHERE fp.facility_id = p_facility_id AND EXISTS (SELECT 1 FROM medical_provider_profiles mpp WHERE mpp.user_id = u.id AND mpp.id = fp.provider_id AND fp.is_active = true AND fp.end_date IS NULL))
      OR
      EXISTS (SELECT 1 FROM facility_admin_profiles fap WHERE fap.user_id = u.id AND fap.managed_facilities @> ARRAY[p_facility_id]::TEXT[])
    );

  -- Operational efficiency (from facility admin profile managing this facility)
  SELECT COALESCE(AVG(fap.operational_efficiency_score), 0)::NUMERIC
  INTO v_efficiency
  FROM facility_admin_profiles fap
  WHERE fap.managed_facilities @> ARRAY[p_facility_id]::TEXT[];

  -- Patient satisfaction average (from facility admin profile managing this facility)
  SELECT COALESCE(AVG(fap.patient_satisfaction_avg), 0)::NUMERIC
  INTO v_satisfaction
  FROM facility_admin_profiles fap
  WHERE fap.managed_facilities @> ARRAY[p_facility_id]::TEXT[];

  -- Step 3: Return all metrics
  RETURN QUERY SELECT
    v_patient_count,
    v_staff_count,
    v_users_count,
    v_efficiency,
    v_satisfaction,
    v_error_message;

EXCEPTION WHEN OTHERS THEN
  v_error_message := 'Database Error: ' || SQLERRM;
  RETURN QUERY SELECT NULL::INT, NULL::INT, NULL::INT, NULL::NUMERIC, NULL::NUMERIC, v_error_message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- Verification Block: Confirm all functions created successfully
-- ============================================================================

DO $$
DECLARE
  func1_exists BOOLEAN;
  func2_exists BOOLEAN;
  func3_exists BOOLEAN;
  func4_exists BOOLEAN;
  all_correct BOOLEAN := true;
BEGIN
  -- Check if all functions exist in public schema
  SELECT EXISTS(
    SELECT 1 FROM information_schema.routines
    WHERE routine_schema = 'public' AND routine_name = 'get_facility_patients_count'
  ) INTO func1_exists;

  SELECT EXISTS(
    SELECT 1 FROM information_schema.routines
    WHERE routine_schema = 'public' AND routine_name = 'get_facility_staff_count'
  ) INTO func2_exists;

  SELECT EXISTS(
    SELECT 1 FROM information_schema.routines
    WHERE routine_schema = 'public' AND routine_name = 'get_facility_active_users_count'
  ) INTO func3_exists;

  SELECT EXISTS(
    SELECT 1 FROM information_schema.routines
    WHERE routine_schema = 'public' AND routine_name = 'get_facility_summary'
  ) INTO func4_exists;

  IF NOT (func1_exists AND func2_exists AND func3_exists AND func4_exists) THEN
    RAISE WARNING 'Some functions were not created: func1=%, func2=%, func3=%, func4=%',
      func1_exists, func2_exists, func3_exists, func4_exists;
    all_correct := false;
  END IF;

  IF all_correct THEN
    RAISE NOTICE 'Migration successful: Facility Admin Reporting Functions created';
    RAISE NOTICE '✓ get_facility_patients_count() - Returns patient count with access control';
    RAISE NOTICE '✓ get_facility_staff_count() - Returns active staff count with access control';
    RAISE NOTICE '✓ get_facility_active_users_count() - Returns total active users with access control';
    RAISE NOTICE '✓ get_facility_summary() - Returns comprehensive facility metrics with access control';
    RAISE NOTICE 'All functions enforce: managed_facilities array scope + can_view_reports permission';
  ELSE
    RAISE WARNING 'Migration incomplete: Please verify function creation';
  END IF;
END $$;
