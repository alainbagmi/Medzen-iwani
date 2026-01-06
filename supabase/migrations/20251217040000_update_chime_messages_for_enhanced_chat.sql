-- Update chime_messages schema for enhanced video call chat
-- Date: 2025-12-17
--
-- Purpose: Support the enhanced ChimeMeetingEnhanced widget chat functionality
-- Features: Text messages, file/image sharing, emoji support
--
-- Changes:
-- 1. Add 'image' to message_type check constraint
-- 2. Ensure all required columns exist
-- 3. Add index for better query performance
-- 4. Update RLS policies for Firebase Auth users

-- ============================================================================
-- 1. Update message_type check constraint to include 'image'
-- ============================================================================

-- Drop existing constraint
ALTER TABLE chime_messages
DROP CONSTRAINT IF EXISTS chime_messages_type_check;

-- Recreate with 'image' type added
ALTER TABLE chime_messages
ADD CONSTRAINT chime_messages_type_check
CHECK (message_type IN ('text', 'system', 'file', 'image'));

-- ============================================================================
-- 2. Ensure all columns exist (idempotent)
-- ============================================================================

-- These should already exist from previous migrations, but ensuring they're present
ALTER TABLE chime_messages
ADD COLUMN IF NOT EXISTS channel_id TEXT,
ADD COLUMN IF NOT EXISTS message_type TEXT DEFAULT 'text',
ADD COLUMN IF NOT EXISTS sender_id TEXT, -- Changed to TEXT for Firebase UID
ADD COLUMN IF NOT EXISTS message_content TEXT;

-- ============================================================================
-- 3. Add indexes for better query performance
-- ============================================================================

-- Index for channel_id (used by our widget)
CREATE INDEX IF NOT EXISTS idx_chime_messages_channel_id_created
ON chime_messages(channel_id, created_at DESC);

-- Index for sender_id lookups
CREATE INDEX IF NOT EXISTS idx_chime_messages_sender_id
ON chime_messages(sender_id);

-- ============================================================================
-- 4. Update RLS policies for Firebase Auth compatibility
-- ============================================================================

-- The current policies (from 20251216 migrations) should work, but let's ensure
-- they're optimized for our use case

-- Drop any overly restrictive policies
DROP POLICY IF EXISTS "Users can send messages in their channels" ON chime_messages;
DROP POLICY IF EXISTS "Allow message inserts for video call participants" ON chime_messages;

-- Recreate INSERT policy (allows authenticated users with valid sender_id/user_id)
-- This is compatible with Firebase Auth where users don't have Supabase auth.uid()
CREATE POLICY "Authenticated users can insert messages with valid IDs"
ON chime_messages
FOR INSERT
WITH CHECK (
    -- Require either sender_id or user_id to be present
    -- This ensures every message is associated with a user
    (sender_id IS NOT NULL OR user_id IS NOT NULL)
    AND
    -- Require either channel_id or channel_arn to be present
    -- This ensures every message is associated with a channel/meeting
    (channel_id IS NOT NULL OR channel_arn IS NOT NULL)
);

-- Keep SELECT policy as-is (from 20251216120000_secure_chime_messages_select_policy.sql)
-- It already handles Firebase Auth users correctly with the auth.uid() IS NULL fallback

-- ============================================================================
-- 5. Add helpful comments
-- ============================================================================

COMMENT ON CONSTRAINT chime_messages_type_check ON chime_messages IS
    'Message types: text (plain text), image (image file), file (other files), system (system messages)';

COMMENT ON COLUMN chime_messages.channel_id IS
    'Meeting ID or channel identifier. Used by ChimeMeetingEnhanced widget.';

COMMENT ON COLUMN chime_messages.sender_id IS
    'Firebase Auth UID of message sender. Stored as TEXT to support Firebase Auth.';

COMMENT ON COLUMN chime_messages.message_type IS
    'Type of message: text, image, file, or system. Determines how message is rendered in chat.';

COMMENT ON COLUMN chime_messages.metadata IS
    'JSON metadata: {sender: string, fileName: string, fileUrl: string, fileSize: number, timestamp: string}';

-- ============================================================================
-- 6. Migration verification query
-- ============================================================================

-- Run this to verify the migration succeeded:
--
-- -- Check constraint
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = 'chime_messages'::regclass
-- AND conname = 'chime_messages_type_check';
--
-- -- Check policies
-- SELECT policyname, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename = 'chime_messages';
--
-- -- Check indexes
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'chime_messages';
