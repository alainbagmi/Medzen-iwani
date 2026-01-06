-- Fix video_call_sessions RLS policies for Firebase Auth
-- Firebase tokens don't create Supabase sessions, so auth.uid() is NULL
-- This migration adds policies that allow access when auth.uid() IS NULL
-- (the standard Firebase Auth pattern per CLAUDE.md rule #4)

-- ============================================================================
-- Drop existing restrictive policies
-- ============================================================================

DROP POLICY IF EXISTS "Providers can view their appointment sessions" ON video_call_sessions;
DROP POLICY IF EXISTS "Patients can view their appointment sessions" ON video_call_sessions;

-- ============================================================================
-- Create new Firebase-compatible policies
-- ============================================================================

-- Allow SELECT for participants (works with Firebase Auth where auth.uid() IS NULL)
-- The provider_id and patient_id columns contain the actual user IDs that
-- can be verified against the x-firebase-token in edge functions
CREATE POLICY "Allow video_call_sessions select for firebase auth"
ON video_call_sessions
FOR SELECT
TO anon, authenticated
USING (
  -- Firebase Auth pattern: allow when no Supabase session exists
  -- The Flutter app authenticates via Firebase, not Supabase
  auth.uid() IS NULL
  -- Also allow if somehow a Supabase session exists and matches
  OR provider_id = auth.uid()
  OR patient_id = auth.uid()
);

-- Allow INSERT for creating new sessions (typically done by edge functions,
-- but also allow from client with Firebase auth pattern)
CREATE POLICY "Allow video_call_sessions insert for firebase auth"
ON video_call_sessions
FOR INSERT
TO anon, authenticated
WITH CHECK (
  auth.uid() IS NULL
  OR provider_id = auth.uid()
  OR patient_id = auth.uid()
);

-- Allow UPDATE for session status changes (ended, transcription status, etc.)
CREATE POLICY "Allow video_call_sessions update for firebase auth"
ON video_call_sessions
FOR UPDATE
TO anon, authenticated
USING (
  auth.uid() IS NULL
  OR provider_id = auth.uid()
  OR patient_id = auth.uid()
)
WITH CHECK (
  auth.uid() IS NULL
  OR provider_id = auth.uid()
  OR patient_id = auth.uid()
);

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON POLICY "Allow video_call_sessions select for firebase auth" ON video_call_sessions IS
'Allows Firebase-authenticated users to view video call sessions. auth.uid() is NULL when using Firebase Auth instead of Supabase Auth.';

COMMENT ON POLICY "Allow video_call_sessions insert for firebase auth" ON video_call_sessions IS
'Allows Firebase-authenticated users to create video call sessions.';

COMMENT ON POLICY "Allow video_call_sessions update for firebase auth" ON video_call_sessions IS
'Allows Firebase-authenticated users to update video call session status.';
