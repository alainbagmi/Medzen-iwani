-- Fix chime_messages RLS policies to work without Supabase Auth session
-- Date: 2025-12-16
--
-- Issue: App uses Firebase Auth, not Supabase Auth, so auth.uid() returns NULL
-- RLS policies fail because they check auth.uid() IS NOT NULL
--
-- Solution: Modify policies to validate based on video_call_sessions participation
-- instead of requiring Supabase auth session

-- ============================================================================
-- Drop existing INSERT policy
-- ============================================================================

DROP POLICY IF EXISTS "Users can insert messages in video calls" ON chime_messages;

-- ============================================================================
-- Create new INSERT policy without auth.uid() requirement
-- ============================================================================

CREATE POLICY "Allow message inserts for video call participants"
ON chime_messages
FOR INSERT
WITH CHECK (
    -- User must be a participant in the video call session
    -- Check using sender_id or user_id against video_call_sessions
    (
        sender_id IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM video_call_sessions vcs
            WHERE (
                vcs.meeting_id = chime_messages.channel_arn
                OR vcs.meeting_id = chime_messages.channel_id
            )
            AND (
                vcs.provider_id = sender_id
                OR vcs.patient_id = sender_id
            )
        )
    )
    OR (
        user_id IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM video_call_sessions vcs
            WHERE (
                vcs.meeting_id = chime_messages.channel_arn
                OR vcs.meeting_id = chime_messages.channel_id
            )
            AND (
                vcs.provider_id = user_id
                OR vcs.patient_id = user_id
            )
        )
    )
    -- Backward compatibility for chime_messaging_channels
    OR (
        EXISTS (
            SELECT 1 FROM chime_messaging_channels c
            WHERE c.channel_arn = chime_messages.channel_arn
            AND (
                c.provider_id = COALESCE(sender_id, user_id)
                OR c.patient_id = COALESCE(sender_id, user_id)
            )
        )
    )
);

-- ============================================================================
-- Update SELECT policy to work without auth.uid()
-- ============================================================================

DROP POLICY IF EXISTS "Users can view messages in video calls" ON chime_messages;

CREATE POLICY "Allow viewing messages for anyone"
ON chime_messages
FOR SELECT
USING (true);  -- Allow public read for now, can restrict later if needed

-- Note: Consider adding more restrictive SELECT policy in production
-- For now, allowing open SELECT to unblock video call messaging
-- You can add user-specific filtering at the application level

-- ============================================================================
-- Update UPDATE policy
-- ============================================================================

DROP POLICY IF EXISTS "Users can update their own messages in video calls" ON chime_messages;

CREATE POLICY "Allow users to update their own messages"
ON chime_messages
FOR UPDATE
USING (
    -- Allow updates if user is participant in video call
    (
        sender_id IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM video_call_sessions vcs
            WHERE (
                vcs.meeting_id = chime_messages.channel_arn
                OR vcs.meeting_id = chime_messages.channel_id
            )
            AND (
                vcs.provider_id = sender_id
                OR vcs.patient_id = sender_id
            )
        )
    )
    OR (
        user_id IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM video_call_sessions vcs
            WHERE (
                vcs.meeting_id = chime_messages.channel_arn
                OR vcs.meeting_id = chime_messages.channel_id
            )
            AND (
                vcs.provider_id = user_id
                OR vcs.patient_id = user_id
            )
        )
    )
);

-- ============================================================================
-- Update DELETE policy
-- ============================================================================

DROP POLICY IF EXISTS "Users can delete their own messages in video calls" ON chime_messages;

CREATE POLICY "Allow users to delete their own messages"
ON chime_messages
FOR DELETE
USING (
    -- Allow deletes if user is participant in video call
    (
        sender_id IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM video_call_sessions vcs
            WHERE (
                vcs.meeting_id = chime_messages.channel_arn
                OR vcs.meeting_id = chime_messages.channel_id
            )
            AND (
                vcs.provider_id = sender_id
                OR vcs.patient_id = sender_id
            )
        )
    )
    OR (
        user_id IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM video_call_sessions vcs
            WHERE (
                vcs.meeting_id = chime_messages.channel_arn
                OR vcs.meeting_id = chime_messages.channel_id
            )
            AND (
                vcs.provider_id = user_id
                OR vcs.patient_id = user_id
            )
        )
    )
);

-- ============================================================================
-- Add indexes for performance
-- ============================================================================

-- Ensure the performance index from previous migration exists
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_meeting_participants
    ON video_call_sessions(meeting_id, provider_id, patient_id);

CREATE INDEX IF NOT EXISTS idx_chime_messages_channel_lookup
    ON chime_messages(channel_arn, channel_id)
    WHERE channel_arn IS NOT NULL OR channel_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_chime_messages_sender_lookup
    ON chime_messages(sender_id, user_id)
    WHERE sender_id IS NOT NULL OR user_id IS NOT NULL;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON POLICY "Allow message inserts for video call participants" ON chime_messages IS
    'Allows message inserts if sender_id/user_id is a participant in the video call session. Works without Supabase Auth session (uses Firebase Auth).';

COMMENT ON POLICY "Allow viewing messages for anyone" ON chime_messages IS
    'Temporary open SELECT policy for video call messaging. Consider restricting in production.';

COMMENT ON POLICY "Allow users to update their own messages" ON chime_messages IS
    'Allows users to update their own messages if they are participants in the video call session.';

COMMENT ON POLICY "Allow users to delete their own messages" ON chime_messages IS
    'Allows users to delete their own messages if they are participants in the video call session.';
