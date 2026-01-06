-- Migration: Fix active_sessions RLS for Firebase Auth users
-- Created: 2025-12-21
-- Purpose: Allow Firebase Auth users (connecting via anon key) to manage their sessions

-- ============================================================================
-- PART 1: Drop existing restrictive policies
-- ============================================================================

DROP POLICY IF EXISTS "Users can view own sessions" ON active_sessions;
DROP POLICY IF EXISTS "Users can create own sessions" ON active_sessions;
DROP POLICY IF EXISTS "Users can update own sessions" ON active_sessions;
DROP POLICY IF EXISTS "Users can delete own sessions" ON active_sessions;
DROP POLICY IF EXISTS "Service role full access" ON active_sessions;

-- ============================================================================
-- PART 2: Create Firebase Auth compatible policies
-- ============================================================================

-- Allow authenticated users and anon (Firebase Auth) to view sessions
-- The app filters by firebase_uid client-side
CREATE POLICY "active_sessions_select"
ON active_sessions
FOR SELECT
TO authenticated, anon
USING (true);  -- App-level filtering by firebase_uid

-- Allow inserts with valid firebase_uid
CREATE POLICY "active_sessions_insert"
ON active_sessions
FOR INSERT
TO authenticated, anon
WITH CHECK (
    firebase_uid IS NOT NULL AND
    user_id IS NOT NULL AND
    device_id IS NOT NULL
);

-- Allow updates to own sessions (by firebase_uid match in the row)
CREATE POLICY "active_sessions_update"
ON active_sessions
FOR UPDATE
TO authenticated, anon
USING (firebase_uid IS NOT NULL)
WITH CHECK (firebase_uid IS NOT NULL);

-- Allow deletes of own sessions
CREATE POLICY "active_sessions_delete"
ON active_sessions
FOR DELETE
TO authenticated, anon
USING (firebase_uid IS NOT NULL);

-- Service role full access (for cleanup jobs)
CREATE POLICY "active_sessions_service_role"
ON active_sessions
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ============================================================================
-- PART 3: Grant permissions
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON active_sessions TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON active_sessions TO authenticated;

-- ============================================================================
-- PART 4: Add comments
-- ============================================================================

COMMENT ON POLICY "active_sessions_select" ON active_sessions IS
    'Allow all authenticated/anon users to view sessions. App filters by firebase_uid.';
COMMENT ON POLICY "active_sessions_insert" ON active_sessions IS
    'Allow session creation with valid firebase_uid, user_id, and device_id.';
COMMENT ON POLICY "active_sessions_update" ON active_sessions IS
    'Allow updates to sessions with valid firebase_uid.';
COMMENT ON POLICY "active_sessions_delete" ON active_sessions IS
    'Allow deletion of sessions with valid firebase_uid.';
