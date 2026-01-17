-- Emergency fix for chime_messages RLS policy
-- This allows video call messaging to work properly

-- Drop existing restrictive policy
DROP POLICY IF EXISTS "Users can send messages in their channels" ON chime_messages;

-- Create new policy that works for video call messaging
-- Users can insert messages if:
-- 1. They are authenticated
-- 2. The user_id/sender_id matches their auth.uid()
CREATE POLICY "Users can send messages when authenticated"
ON chime_messages
FOR INSERT
WITH CHECK (
    auth.uid() IS NOT NULL
    AND (
        (user_id IS NOT NULL AND user_id = auth.uid())
        OR (sender_id IS NOT NULL AND sender_id::uuid = auth.uid())
    )
);

-- Verify the policy was created
SELECT
    schemaname,
    tablename,
    policyname,
    cmd,
    with_check::text as with_check_clause
FROM pg_policies
WHERE tablename = 'chime_messages'
  AND cmd = 'INSERT';
