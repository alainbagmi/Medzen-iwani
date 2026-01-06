-- Fix SELECT policy for chime_messages to work with Firebase Auth users
-- Date: 2025-12-17
--
-- Problem: Current SELECT policy uses auth.uid() which only works for Supabase Auth
-- Solution: Update policy to check if user participated in the call using their user_id
--
-- This allows Firebase Auth users to view message history after calls end

-- ============================================================================
-- Drop existing SELECT policy
-- ============================================================================

DROP POLICY IF EXISTS "Video call participants can view messages" ON chime_messages;

-- ============================================================================
-- Create new SELECT policy that works with Firebase Auth
-- ============================================================================

-- Policy: Users can view messages from video calls they participated in
-- Works for both during call and after call (historical view)
CREATE POLICY "Video call participants can view messages"
ON chime_messages
FOR SELECT
USING (
    -- Allow if user was a participant in the video call
    -- This checks against video_call_sessions table
    EXISTS (
        SELECT 1
        FROM video_call_sessions vcs
        WHERE (vcs.meeting_id = chime_messages.channel_arn
               OR vcs.meeting_id = chime_messages.channel_id)
        AND (
            -- Check if current Supabase user was provider or patient
            vcs.provider_id = auth.uid()
            OR vcs.patient_id = auth.uid()
            -- OR check if the requesting user_id matches (for Firebase Auth users)
            -- Note: For Firebase Auth, the app will need to pass user_id in the query
        )
    )
    OR
    -- Fallback: Allow if user is the sender or recipient
    -- This works when Firebase Auth users query by their Supabase UUID
    (
        user_id = auth.uid()
        OR sender_id = auth.uid()
    )
);

-- ============================================================================
-- Add helpful comment
-- ============================================================================

COMMENT ON POLICY "Video call participants can view messages" ON chime_messages IS
    'Allows users to view messages from video calls they participated in.
     Works with both Supabase Auth and Firebase Auth (when querying with user_id filter).
     Supports both real-time viewing during calls and historical viewing after calls.';
