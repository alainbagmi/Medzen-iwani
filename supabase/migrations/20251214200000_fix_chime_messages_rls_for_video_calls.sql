-- Migration: Fix RLS policies for chime_messages to work with video calls
-- Problem: Video calls don't create chime_messaging_channels records, causing RLS failures
-- Solution: Allow messages if user is authenticated and owns the message
-- Date: 2025-12-14

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

-- Add comment for documentation
COMMENT ON POLICY "Users can send messages when authenticated" ON chime_messages IS
'Allows authenticated users to send messages in video calls. Validates sender_id or user_id matches auth.uid(). Does not require chime_messaging_channels record for video call compatibility.';
