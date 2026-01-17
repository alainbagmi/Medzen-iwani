-- Migration: Create System Admin Reporting Functions
-- Date: 2026-01-14
-- Purpose: Enable system admin Nova Pro AI to query platform-wide statistics and system metrics
--          while enforcing system admin permission checks
--          Functions return platform-scoped data: user statistics, system health, security metrics, AI usage
--
-- CRITICAL CONSTRAINT: "the ai should only do what the role (system admin) can do"
-- Implementation:
--   1. can_view_reports permission gate (granular permissions)
--   2. SECURITY DEFINER pattern for controlled RLS bypass
--   3. Proper error handling with descriptive messages

-- ============================================================================
-- Function 1: Get Platform User Statistics
-- ============================================================================
-- Returns user adoption metrics and active session information across platform

CREATE OR REPLACE FUNCTION get_platform_user_statistics(
  p_admin_user_id TEXT
) RETURNS TABLE(
  total_users INT,
  active_users INT,
  total_sessions INT,
  active_sessions INT,
  error_message TEXT
) AS $$
DECLARE
  v_has_access BOOLEAN;
  v_total_users INT;
  v_active_users INT;
  v_total_sessions INT;
  v_active_sessions INT;
  v_error_message TEXT := NULL;
BEGIN
  -- Step 1: Verify admin has system admin profile with reporting permissions
  SELECT EXISTS (
    SELECT 1 FROM system_admin_profiles
    WHERE user_id = p_admin_user_id
      AND can_view_reports = true
  ) INTO v_has_access;

  IF NOT v_has_access THEN
    v_error_message := 'Access Denied: You do not have permission to view platform reports.';
    RETURN QUERY SELECT NULL::INT, NULL::INT, NULL::INT, NULL::INT, v_error_message;
    RETURN;
  END IF;

  -- Step 2: Get total user count
  SELECT COUNT(*)::INT
  INTO v_total_users
  FROM users;

  -- Step 3: Get active users count (is_active = true)
  SELECT COUNT(*)::INT
  INTO v_active_users
  FROM users
  WHERE is_active = true;

  -- Step 4: Get total sessions count
  SELECT COUNT(*)::INT
  INTO v_total_sessions
  FROM active_sessions;

  -- Step 5: Get active sessions count (session still active)
  SELECT COUNT(*)::INT
  INTO v_active_sessions
  FROM active_sessions
  WHERE expires_at > NOW();

  RETURN QUERY SELECT v_total_users, v_active_users, v_total_sessions, v_active_sessions, v_error_message;
EXCEPTION WHEN OTHERS THEN
  v_error_message := 'Database Error: ' || SQLERRM;
  RETURN QUERY SELECT NULL::INT, NULL::INT, NULL::INT, NULL::INT, v_error_message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- Function 2: Get System Health Metrics
-- ============================================================================
-- Returns system performance and reliability metrics

CREATE OR REPLACE FUNCTION get_system_health_metrics(
  p_admin_user_id TEXT
) RETURNS TABLE(
  total_facilities INT,
  active_facilities INT,
  total_providers INT,
  active_providers INT,
  total_appointments INT,
  completed_appointments INT,
  error_message TEXT
) AS $$
DECLARE
  v_has_access BOOLEAN;
  v_total_facilities INT;
  v_active_facilities INT;
  v_total_providers INT;
  v_active_providers INT;
  v_total_appointments INT;
  v_completed_appointments INT;
  v_error_message TEXT := NULL;
BEGIN
  -- Step 1: Verify admin has system admin profile with reporting permissions
  SELECT EXISTS (
    SELECT 1 FROM system_admin_profiles
    WHERE user_id = p_admin_user_id
      AND can_view_reports = true
  ) INTO v_has_access;

  IF NOT v_has_access THEN
    v_error_message := 'Access Denied: You do not have permission to view platform reports.';
    RETURN QUERY SELECT NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, v_error_message;
    RETURN;
  END IF;

  -- Step 2: Get total facilities
  SELECT COUNT(*)::INT
  INTO v_total_facilities
  FROM facilities;

  -- Step 3: Get active facilities (has active staff or patients)
  SELECT COUNT(DISTINCT f.id)::INT
  INTO v_active_facilities
  FROM facilities f
  WHERE EXISTS (
    SELECT 1 FROM facility_providers fp
    WHERE fp.facility_id = f.id AND fp.is_active = true AND fp.end_date IS NULL
  )
  OR EXISTS (
    SELECT 1 FROM patient_profiles pp
    WHERE pp.preferred_hospital_id = f.id
  );

  -- Step 4: Get total medical providers
  SELECT COUNT(*)::INT
  INTO v_total_providers
  FROM medical_provider_profiles;

  -- Step 5: Get active medical providers
  SELECT COUNT(*)::INT
  INTO v_active_providers
  FROM medical_provider_profiles mpp
  WHERE EXISTS (
    SELECT 1 FROM users u
    WHERE u.id = mpp.user_id AND u.is_active = true
  );

  -- Step 6: Get total appointments
  SELECT COUNT(*)::INT
  INTO v_total_appointments
  FROM appointments;

  -- Step 7: Get completed appointments
  SELECT COUNT(*)::INT
  INTO v_completed_appointments
  FROM appointments
  WHERE status = 'completed';

  RETURN QUERY SELECT v_total_facilities, v_active_facilities, v_total_providers, v_active_providers, v_total_appointments, v_completed_appointments, v_error_message;
EXCEPTION WHEN OTHERS THEN
  v_error_message := 'Database Error: ' || SQLERRM;
  RETURN QUERY SELECT NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, v_error_message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- Function 3: Get Security Metrics
-- ============================================================================
-- Returns security-related metrics and activity indicators

CREATE OR REPLACE FUNCTION get_security_metrics(
  p_admin_user_id TEXT
) RETURNS TABLE(
  total_ai_conversations INT,
  total_video_calls INT,
  total_clinical_notes INT,
  ehrbase_sync_pending INT,
  error_message TEXT
) AS $$
DECLARE
  v_has_access BOOLEAN;
  v_total_ai_conversations INT;
  v_total_video_calls INT;
  v_total_clinical_notes INT;
  v_ehrbase_sync_pending INT;
  v_error_message TEXT := NULL;
BEGIN
  -- Step 1: Verify admin has system admin profile with reporting permissions
  SELECT EXISTS (
    SELECT 1 FROM system_admin_profiles
    WHERE user_id = p_admin_user_id
      AND can_view_reports = true
  ) INTO v_has_access;

  IF NOT v_has_access THEN
    v_error_message := 'Access Denied: You do not have permission to view platform reports.';
    RETURN QUERY SELECT NULL::INT, NULL::INT, NULL::INT, NULL::INT, v_error_message;
    RETURN;
  END IF;

  -- Step 2: Get total AI conversations
  SELECT COUNT(*)::INT
  INTO v_total_ai_conversations
  FROM ai_conversations;

  -- Step 3: Get total video calls
  SELECT COUNT(*)::INT
  INTO v_total_video_calls
  FROM video_call_sessions;

  -- Step 4: Get total clinical notes
  SELECT COUNT(*)::INT
  INTO v_total_clinical_notes
  FROM clinical_notes;

  -- Step 5: Get pending EHRbase syncs
  SELECT COUNT(*)::INT
  INTO v_ehrbase_sync_pending
  FROM ehrbase_sync_queue
  WHERE sync_status IN ('pending', 'retrying');

  RETURN QUERY SELECT v_total_ai_conversations, v_total_video_calls, v_total_clinical_notes, v_ehrbase_sync_pending, v_error_message;
EXCEPTION WHEN OTHERS THEN
  v_error_message := 'Database Error: ' || SQLERRM;
  RETURN QUERY SELECT NULL::INT, NULL::INT, NULL::INT, NULL::INT, v_error_message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- Function 4: Get AI Usage Metrics
-- ============================================================================
-- Returns AI model usage and performance statistics

CREATE OR REPLACE FUNCTION get_ai_usage_metrics(
  p_admin_user_id TEXT
) RETURNS TABLE(
  total_ai_messages INT,
  total_tokens_used BIGINT,
  avg_response_time_ms NUMERIC,
  daily_active_conversations INT,
  error_message TEXT
) AS $$
DECLARE
  v_has_access BOOLEAN;
  v_total_ai_messages INT;
  v_total_tokens_used BIGINT;
  v_avg_response_time_ms NUMERIC;
  v_daily_active_conversations INT;
  v_error_message TEXT := NULL;
BEGIN
  -- Step 1: Verify admin has system admin profile with reporting permissions
  SELECT EXISTS (
    SELECT 1 FROM system_admin_profiles
    WHERE user_id = p_admin_user_id
      AND can_view_reports = true
  ) INTO v_has_access;

  IF NOT v_has_access THEN
    v_error_message := 'Access Denied: You do not have permission to view platform reports.';
    RETURN QUERY SELECT NULL::INT, NULL::BIGINT, NULL::NUMERIC, NULL::INT, v_error_message;
    RETURN;
  END IF;

  -- Step 2: Get total AI messages
  SELECT COUNT(*)::INT
  INTO v_total_ai_messages
  FROM ai_messages;

  -- Step 3: Get total tokens used across all AI messages
  SELECT COALESCE(SUM(total_tokens), 0)::BIGINT
  INTO v_total_tokens_used
  FROM ai_messages
  WHERE total_tokens > 0;

  -- Step 4: Get average response time in milliseconds
  SELECT COALESCE(AVG(response_time_ms), 0)::NUMERIC
  INTO v_avg_response_time_ms
  FROM ai_messages
  WHERE response_time_ms > 0
    AND created_at > NOW() - INTERVAL '7 days';

  -- Step 5: Get daily active conversations (conversations with messages in last 24 hours)
  SELECT COUNT(DISTINCT conversation_id)::INT
  INTO v_daily_active_conversations
  FROM ai_messages
  WHERE created_at > NOW() - INTERVAL '1 day';

  RETURN QUERY SELECT v_total_ai_messages, v_total_tokens_used, v_avg_response_time_ms, v_daily_active_conversations, v_error_message;
EXCEPTION WHEN OTHERS THEN
  v_error_message := 'Database Error: ' || SQLERRM;
  RETURN QUERY SELECT NULL::INT, NULL::BIGINT, NULL::NUMERIC, NULL::INT, v_error_message;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- Function 5: Get Platform Summary (Comprehensive Metrics)
-- ============================================================================
-- Returns comprehensive platform statistics in a single query

CREATE OR REPLACE FUNCTION get_platform_summary(
  p_admin_user_id TEXT
) RETURNS TABLE(
  total_users INT,
  active_users INT,
  total_facilities INT,
  active_facilities INT,
  total_providers INT,
  active_providers INT,
  total_appointments INT,
  completed_appointments INT,
  total_ai_conversations INT,
  total_video_calls INT,
  total_clinical_notes INT,
  ehrbase_sync_pending INT,
  error_message TEXT
) AS $$
DECLARE
  v_has_access BOOLEAN;
  v_total_users INT;
  v_active_users INT;
  v_total_facilities INT;
  v_active_facilities INT;
  v_total_providers INT;
  v_active_providers INT;
  v_total_appointments INT;
  v_completed_appointments INT;
  v_total_ai_conversations INT;
  v_total_video_calls INT;
  v_total_clinical_notes INT;
  v_ehrbase_sync_pending INT;
  v_error_message TEXT := NULL;
BEGIN
  -- Step 1: Verify admin has system admin profile with reporting permissions
  SELECT EXISTS (
    SELECT 1 FROM system_admin_profiles
    WHERE user_id = p_admin_user_id
      AND can_view_reports = true
  ) INTO v_has_access;

  IF NOT v_has_access THEN
    v_error_message := 'Access Denied: You do not have permission to view platform reports.';
    RETURN QUERY SELECT NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, v_error_message;
    RETURN;
  END IF;

  -- Step 2: Gather all metrics

  -- User metrics
  SELECT COUNT(*)::INT INTO v_total_users FROM users;
  SELECT COUNT(*)::INT INTO v_active_users FROM users WHERE is_active = true;

  -- Facility metrics
  SELECT COUNT(*)::INT INTO v_total_facilities FROM facilities;
  SELECT COUNT(DISTINCT f.id)::INT
  INTO v_active_facilities
  FROM facilities f
  WHERE EXISTS (
    SELECT 1 FROM facility_providers fp
    WHERE fp.facility_id = f.id AND fp.is_active = true AND fp.end_date IS NULL
  )
  OR EXISTS (
    SELECT 1 FROM patient_profiles pp
    WHERE pp.preferred_hospital_id = f.id
  );

  -- Provider metrics
  SELECT COUNT(*)::INT INTO v_total_providers FROM medical_provider_profiles;
  SELECT COUNT(*)::INT
  INTO v_active_providers
  FROM medical_provider_profiles mpp
  WHERE EXISTS (
    SELECT 1 FROM users u
    WHERE u.id = mpp.user_id AND u.is_active = true
  );

  -- Appointment metrics
  SELECT COUNT(*)::INT INTO v_total_appointments FROM appointments;
  SELECT COUNT(*)::INT INTO v_completed_appointments FROM appointments WHERE status = 'completed';

  -- AI & Clinical metrics
  SELECT COUNT(*)::INT INTO v_total_ai_conversations FROM ai_conversations;
  SELECT COUNT(*)::INT INTO v_total_video_calls FROM video_call_sessions;
  SELECT COUNT(*)::INT INTO v_total_clinical_notes FROM clinical_notes;
  SELECT COUNT(*)::INT
  INTO v_ehrbase_sync_pending
  FROM ehrbase_sync_queue
  WHERE sync_status IN ('pending', 'retrying');

  -- Step 3: Return all metrics
  RETURN QUERY SELECT
    v_total_users,
    v_active_users,
    v_total_facilities,
    v_active_facilities,
    v_total_providers,
    v_active_providers,
    v_total_appointments,
    v_completed_appointments,
    v_total_ai_conversations,
    v_total_video_calls,
    v_total_clinical_notes,
    v_ehrbase_sync_pending,
    v_error_message;

EXCEPTION WHEN OTHERS THEN
  v_error_message := 'Database Error: ' || SQLERRM;
  RETURN QUERY SELECT NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, NULL::INT, v_error_message;
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
  func5_exists BOOLEAN;
  all_correct BOOLEAN := true;
BEGIN
  -- Check if all functions exist in public schema
  SELECT EXISTS(
    SELECT 1 FROM information_schema.routines
    WHERE routine_schema = 'public' AND routine_name = 'get_platform_user_statistics'
  ) INTO func1_exists;

  SELECT EXISTS(
    SELECT 1 FROM information_schema.routines
    WHERE routine_schema = 'public' AND routine_name = 'get_system_health_metrics'
  ) INTO func2_exists;

  SELECT EXISTS(
    SELECT 1 FROM information_schema.routines
    WHERE routine_schema = 'public' AND routine_name = 'get_security_metrics'
  ) INTO func3_exists;

  SELECT EXISTS(
    SELECT 1 FROM information_schema.routines
    WHERE routine_schema = 'public' AND routine_name = 'get_ai_usage_metrics'
  ) INTO func4_exists;

  SELECT EXISTS(
    SELECT 1 FROM information_schema.routines
    WHERE routine_schema = 'public' AND routine_name = 'get_platform_summary'
  ) INTO func5_exists;

  IF NOT (func1_exists AND func2_exists AND func3_exists AND func4_exists AND func5_exists) THEN
    RAISE WARNING 'Some functions were not created: func1=%, func2=%, func3=%, func4=%, func5=%',
      func1_exists, func2_exists, func3_exists, func4_exists, func5_exists;
    all_correct := false;
  END IF;

  IF all_correct THEN
    RAISE NOTICE 'Migration successful: System Admin Reporting Functions created';
    RAISE NOTICE '✓ get_platform_user_statistics() - Returns user adoption and session metrics with access control';
    RAISE NOTICE '✓ get_system_health_metrics() - Returns facility and provider metrics with access control';
    RAISE NOTICE '✓ get_security_metrics() - Returns AI usage and EHRbase sync metrics with access control';
    RAISE NOTICE '✓ get_ai_usage_metrics() - Returns AI conversation and token usage with access control';
    RAISE NOTICE '✓ get_platform_summary() - Returns comprehensive platform metrics with access control';
    RAISE NOTICE 'All functions enforce: can_view_reports permission gate + system admin verification';
  ELSE
    RAISE WARNING 'Migration incomplete: Please verify function creation';
  END IF;
END $$;
