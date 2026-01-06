-- Add missing INSERT policy for chime_messages
-- Date: 2025-12-15
--
-- Issue: Migration 20251215202909 dropped the INSERT policy but didn't recreate it
-- This causes RLS error 42501 when users try to send messages during video calls
--
-- This migration adds the INSERT policy that works for both:
-- 1. Video calls (using video_call_sessions table)
-- 2. Messaging channels (using chime_messaging_channels table)

-- Drop existing INSERT policy if exists (for idempotency)
DROP POLICY IF EXISTS "Users can send messages in their channels" ON chime_messages;
DROP POLICY IF EXISTS "Users can insert messages in video calls" ON chime_messages;

-- Create new INSERT policy that works for video calls
-- Users can insert messages if they are participants in the video call
CREATE POLICY "Users can insert messages in video calls"
ON chime_messages
FOR INSERT
WITH CHECK (
    auth.uid() IS NOT NULL
    AND (
        -- Allow if user is participant in the video call session
        EXISTS (
            SELECT 1 FROM video_call_sessions vcs
            WHERE (
                vcs.meeting_id = chime_messages.channel_arn
                OR vcs.meeting_id = chime_messages.channel_id
            )
            AND (vcs.provider_id = auth.uid() OR vcs.patient_id = auth.uid())
        )
        -- Also allow if user is in chime_messaging_channels (backward compatibility)
        OR EXISTS (
            SELECT 1 FROM chime_messaging_channels c
            WHERE c.channel_arn = chime_messages.channel_arn
            AND (c.provider_id = auth.uid() OR c.patient_id = auth.uid())
        )
    )
    -- Ensure the user_id or sender_id matches the authenticated user
    AND (
        (user_id IS NOT NULL AND user_id = auth.uid())
        OR (sender_id IS NOT NULL AND sender_id = auth.uid())
        OR (user_id IS NULL AND sender_id IS NULL) -- Allow if both are NULL (will be set by trigger)
    )
);

-- Add comment for documentation
COMMENT ON POLICY "Users can insert messages in video calls" ON chime_messages IS
    'Allows users to insert messages if they are participants in the video call session or in the messaging channel. Ensures user_id/sender_id matches authenticated user.';
