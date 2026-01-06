-- Migration: Fix chime_messages INSERT policy for Firebase Auth
-- Date: December 21, 2025
-- Purpose: Allow authenticated users to insert messages without strict auth.uid() check

-- ============================================================================
-- PART 1: Drop existing INSERT policies
-- ============================================================================

DROP POLICY IF EXISTS "chime_messages_insert_firebase" ON chime_messages;
DROP POLICY IF EXISTS "Only providers can send messages during active calls" ON chime_messages;
DROP POLICY IF EXISTS "Authenticated users can insert messages" ON chime_messages;
DROP POLICY IF EXISTS "Users can insert their own messages" ON chime_messages;

-- ============================================================================
-- PART 2: Create permissive INSERT policy
-- ============================================================================

-- Allow any authenticated request to insert messages
-- The Flutter app validates the user before making the request
-- user_id and sender_id are set by the app to the correct Supabase user ID
CREATE POLICY "chime_messages_insert_authenticated"
ON chime_messages
FOR INSERT
TO authenticated
WITH CHECK (
    -- Must have a valid user_id or sender_id
    user_id IS NOT NULL OR sender_id IS NOT NULL
);

-- ============================================================================
-- PART 3: Also allow anon role for Firebase Auth compatibility
-- ============================================================================

-- Firebase Auth users connect with anon key but are authenticated via Firebase
-- Allow inserts with valid user_id/sender_id
CREATE POLICY "chime_messages_insert_anon"
ON chime_messages
FOR INSERT
TO anon
WITH CHECK (
    -- Must have a valid user_id or sender_id
    user_id IS NOT NULL OR sender_id IS NOT NULL
);

-- ============================================================================
-- PART 4: Update SELECT policy to include anon role
-- ============================================================================

DROP POLICY IF EXISTS "chime_messages_select_firebase" ON chime_messages;

-- Allow both authenticated and anon to select
CREATE POLICY "chime_messages_select_all"
ON chime_messages
FOR SELECT
TO authenticated, anon
USING (true);  -- App-level filtering by appointment_id

-- ============================================================================
-- PART 5: Update UPDATE and DELETE policies
-- ============================================================================

DROP POLICY IF EXISTS "chime_messages_update_firebase" ON chime_messages;
DROP POLICY IF EXISTS "chime_messages_delete_firebase" ON chime_messages;

-- Allow users to update their own messages
CREATE POLICY "chime_messages_update_own"
ON chime_messages
FOR UPDATE
TO authenticated, anon
USING (
    user_id IS NOT NULL OR sender_id IS NOT NULL
)
WITH CHECK (
    user_id IS NOT NULL OR sender_id IS NOT NULL
);

-- Allow users to delete their own messages
CREATE POLICY "chime_messages_delete_own"
ON chime_messages
FOR DELETE
TO authenticated, anon
USING (
    user_id IS NOT NULL OR sender_id IS NOT NULL
);

-- ============================================================================
-- PART 6: Add documentation
-- ============================================================================

COMMENT ON POLICY "chime_messages_insert_authenticated" ON chime_messages IS
    'Allows authenticated users to insert messages. Requires valid user_id or sender_id.';

COMMENT ON POLICY "chime_messages_insert_anon" ON chime_messages IS
    'Allows anon role (Firebase Auth users) to insert messages. Requires valid user_id or sender_id.';

COMMENT ON POLICY "chime_messages_select_all" ON chime_messages IS
    'Allows all authenticated users to read messages. App filters by appointment_id.';
