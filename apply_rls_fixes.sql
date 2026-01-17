-- ====================================================================
-- CONSOLIDATED RLS FIX FOR CHIME_MESSAGES
-- ====================================================================
-- This script applies all RLS policy fixes for video call messaging
-- Created: 2025-12-14
-- Purpose: Fix message sending/receiving during video calls
--
-- ISSUE: Video calls don't create chime_messaging_channels records,
--        causing RLS policies to block message operations
--
-- SOLUTION: Allow authenticated users to send/view messages based on
--          video_call_sessions participation instead
-- ====================================================================

BEGIN;

-- ====================================================================
-- STEP 1: Clean up old/conflicting policies
-- ====================================================================

DROP POLICY IF EXISTS "Users can send messages in their channels" ON chime_messages;
DROP POLICY IF EXISTS "Users can send messages when authenticated" ON chime_messages;
DROP POLICY IF EXISTS "Users can view messages in their channels" ON chime_messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON chime_messages;
DROP POLICY IF EXISTS "Users can delete their own messages" ON chime_messages;
DROP POLICY IF EXISTS "video_call_messaging_insert" ON chime_messages;
DROP POLICY IF EXISTS "video_call_messaging_select" ON chime_messages;
DROP POLICY IF EXISTS "video_call_messaging_update" ON chime_messages;
DROP POLICY IF EXISTS "video_call_messaging_delete" ON chime_messages;

-- ====================================================================
-- STEP 2: Create INSERT policy for sending messages
-- ====================================================================

CREATE POLICY "video_call_messaging_insert"
ON chime_messages
FOR INSERT
TO authenticated
WITH CHECK (
    -- User must be authenticated
    auth.uid() IS NOT NULL
    AND
    -- Either user_id or sender_id must match the authenticated user
    (
        (user_id IS NOT NULL AND user_id = auth.uid())
        OR
        (sender_id IS NOT NULL AND sender_id = auth.uid())
    )
);

COMMENT ON POLICY "video_call_messaging_insert" ON chime_messages IS
'Allows authenticated users to send messages during video calls. Validates that the sender (user_id or sender_id) matches auth.uid(). Does not require chime_messaging_channels record, making it compatible with video call messaging.';

-- ====================================================================
-- STEP 3: Create SELECT policy for viewing messages
-- ====================================================================

CREATE POLICY "video_call_messaging_select"
ON chime_messages
FOR SELECT
TO authenticated
USING (
    auth.uid() IS NOT NULL
    AND (
        -- Option 1: User is participant in the video call session
        -- channel_arn is mapped to meeting_id in video calls
        EXISTS (
            SELECT 1 FROM video_call_sessions vcs
            WHERE vcs.meeting_id = chime_messages.channel_arn
            AND (vcs.provider_id::uuid = auth.uid() OR vcs.patient_id::uuid = auth.uid())
            AND vcs.status IN ('active', 'in_progress', 'initializing', 'scheduled')
        )
        OR
        -- Option 2: User has access via chime_messaging_channels (backward compatible)
        EXISTS (
            SELECT 1 FROM chime_messaging_channels c
            WHERE c.channel_arn = chime_messages.channel_arn
            AND (c.provider_id = auth.uid() OR c.patient_id = auth.uid())
        )
        OR
        -- Option 3: User is the sender (can always see own messages)
        (
            (user_id IS NOT NULL AND user_id = auth.uid())
            OR
            (sender_id IS NOT NULL AND sender_id = auth.uid())
        )
    )
);

COMMENT ON POLICY "video_call_messaging_select" ON chime_messages IS
'Allows authenticated users to view messages in video call sessions. Checks video_call_sessions table for active participants. Falls back to chime_messaging_channels for backward compatibility. Users can always see their own messages.';

-- ====================================================================
-- STEP 4: Create UPDATE policy for editing messages
-- ====================================================================

CREATE POLICY "video_call_messaging_update"
ON chime_messages
FOR UPDATE
TO authenticated
USING (
    auth.uid() IS NOT NULL
    AND (
        (user_id IS NOT NULL AND user_id = auth.uid())
        OR
        (sender_id IS NOT NULL AND sender_id = auth.uid())
    )
)
WITH CHECK (
    auth.uid() IS NOT NULL
    AND (
        (user_id IS NOT NULL AND user_id = auth.uid())
        OR
        (sender_id IS NOT NULL AND sender_id = auth.uid())
    )
);

COMMENT ON POLICY "video_call_messaging_update" ON chime_messages IS
'Allows authenticated users to update their own messages. Validates that user_id or sender_id matches auth.uid().';

-- ====================================================================
-- STEP 5: Create DELETE policy for removing messages
-- ====================================================================

CREATE POLICY "video_call_messaging_delete"
ON chime_messages
FOR DELETE
TO authenticated
USING (
    auth.uid() IS NOT NULL
    AND (
        (user_id IS NOT NULL AND user_id = auth.uid())
        OR
        (sender_id IS NOT NULL AND sender_id = auth.uid())
    )
);

COMMENT ON POLICY "video_call_messaging_delete" ON chime_messages IS
'Allows authenticated users to delete their own messages. Validates that user_id or sender_id matches auth.uid().';

-- ====================================================================
-- VERIFICATION: Check that policies were created
-- ====================================================================

DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'chime_messages'
    AND policyname LIKE 'video_call_messaging_%';

    IF policy_count = 4 THEN
        RAISE NOTICE '✅ SUCCESS: All 4 RLS policies created for chime_messages';
        RAISE NOTICE '   - video_call_messaging_insert';
        RAISE NOTICE '   - video_call_messaging_select';
        RAISE NOTICE '   - video_call_messaging_update';
        RAISE NOTICE '   - video_call_messaging_delete';
    ELSE
        RAISE WARNING '⚠️  WARNING: Expected 4 policies, found %', policy_count;
    END IF;
END $$;

COMMIT;

-- ====================================================================
-- POST-DEPLOYMENT TESTING
-- ====================================================================
-- After running this script, test:
-- 1. Create a video call session
-- 2. Send a message from provider
-- 3. Send a message from patient
-- 4. Verify both users can see both messages
-- 5. Check browser console for any RLS errors
-- ====================================================================
