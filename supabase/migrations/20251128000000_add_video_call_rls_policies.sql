-- Enable RLS on video_call_sessions and video_call_audit_log tables
-- This migration adds Row-Level Security policies to prevent unauthorized access

-- ============================================================================
-- video_call_sessions RLS Policies
-- ============================================================================

-- Enable RLS on video_call_sessions (if not already enabled)
ALTER TABLE video_call_sessions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Service role has full access to video_call_sessions" ON video_call_sessions;
DROP POLICY IF EXISTS "Providers can view their appointment sessions" ON video_call_sessions;
DROP POLICY IF EXISTS "Patients can view their appointment sessions" ON video_call_sessions;

-- Service role (Edge Functions) has full access
CREATE POLICY "Service role has full access to video_call_sessions"
ON video_call_sessions
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Providers can view sessions for their appointments
CREATE POLICY "Providers can view their appointment sessions"
ON video_call_sessions
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM appointments a
    INNER JOIN medical_provider_profiles mpp ON mpp.user_id = auth.uid()
    WHERE a.id = video_call_sessions.appointment_id
    AND a.provider_id = mpp.id
  )
);

-- Patients can view sessions for their appointments
CREATE POLICY "Patients can view their appointment sessions"
ON video_call_sessions
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM appointments a
    WHERE a.id = video_call_sessions.appointment_id
    AND a.patient_id = auth.uid()
  )
);

-- ============================================================================
-- video_call_audit_log RLS Policies
-- ============================================================================

-- Enable RLS on video_call_audit_log (if not already enabled)
ALTER TABLE video_call_audit_log ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Service role has full access to video_call_audit_log" ON video_call_audit_log;
DROP POLICY IF EXISTS "Providers can view audit logs for their sessions" ON video_call_audit_log;
DROP POLICY IF EXISTS "Patients can view audit logs for their sessions" ON video_call_audit_log;

-- Service role (Edge Functions) has full access
CREATE POLICY "Service role has full access to video_call_audit_log"
ON video_call_audit_log
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Providers can view audit logs for their appointment sessions
CREATE POLICY "Providers can view audit logs for their sessions"
ON video_call_audit_log
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM video_call_sessions vcs
    INNER JOIN appointments a ON a.id = vcs.appointment_id
    INNER JOIN medical_provider_profiles mpp ON mpp.user_id = auth.uid()
    WHERE vcs.id = video_call_audit_log.session_id
    AND a.provider_id = mpp.id
  )
);

-- Patients can view audit logs for their appointment sessions
CREATE POLICY "Patients can view audit logs for their sessions"
ON video_call_audit_log
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM video_call_sessions vcs
    INNER JOIN appointments a ON a.id = vcs.appointment_id
    WHERE vcs.id = video_call_audit_log.session_id
    AND a.patient_id = auth.uid()
  )
);

-- ============================================================================
-- Add helpful comments
-- ============================================================================

COMMENT ON POLICY "Service role has full access to video_call_sessions" ON video_call_sessions IS
'Allows Edge Functions (service_role) to create, update, and manage video call sessions';

COMMENT ON POLICY "Providers can view their appointment sessions" ON video_call_sessions IS
'Allows medical providers to view video call sessions for appointments they are assigned to';

COMMENT ON POLICY "Patients can view their appointment sessions" ON video_call_sessions IS
'Allows patients to view video call sessions for their own appointments';

COMMENT ON POLICY "Service role has full access to video_call_audit_log" ON video_call_audit_log IS
'Allows Edge Functions (service_role) to insert audit log entries for compliance tracking';

COMMENT ON POLICY "Providers can view audit logs for their sessions" ON video_call_audit_log IS
'Allows medical providers to view audit logs for video sessions in their appointments';

COMMENT ON POLICY "Patients can view audit logs for their sessions" ON video_call_audit_log IS
'Allows patients to view audit logs for video sessions in their appointments';
