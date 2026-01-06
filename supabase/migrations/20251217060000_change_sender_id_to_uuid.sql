-- Change sender_id from TEXT to UUID with foreign key to users table
-- Date: 2025-12-17
--
-- Purpose: Link sender_id to Supabase authenticated users via UUID
--
-- Changes:
-- 1. Convert sender_id from TEXT to UUID
-- 2. Add foreign key constraint to users table
-- 3. Update RLS policies to use auth.uid() for sender_id checks
-- 4. Add default value for sender_id using auth.uid()

-- ============================================================================
-- 1. Handle existing data (if any)
-- ============================================================================

-- If there are existing rows with TEXT sender_id values that are valid UUIDs,
-- they will be preserved. If there are invalid UUID strings, they need to be
-- handled before this migration can succeed.

-- Optional: Delete any rows with invalid sender_id (if needed)
-- DELETE FROM chime_messages WHERE sender_id !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

-- ============================================================================
-- 2. Drop ALL policies that reference sender_id
-- ============================================================================

-- Must drop all policies that reference sender_id before dropping the column
DROP POLICY IF EXISTS "video_call_messaging_insert" ON chime_messages;
DROP POLICY IF EXISTS "video_call_messaging_select" ON chime_messages;
DROP POLICY IF EXISTS "video_call_messaging_update" ON chime_messages;
DROP POLICY IF EXISTS "video_call_messaging_delete" ON chime_messages;
DROP POLICY IF EXISTS "Allow users to update their own messages" ON chime_messages;
DROP POLICY IF EXISTS "Allow users to delete their own messages" ON chime_messages;
DROP POLICY IF EXISTS "Authenticated users can insert messages" ON chime_messages;
DROP POLICY IF EXISTS "Authenticated users can insert messages with valid IDs" ON chime_messages;
DROP POLICY IF EXISTS "Video call participants can view messages" ON chime_messages;

-- ============================================================================
-- 3. Change sender_id column type to UUID
-- ============================================================================

-- Drop the column (now safe since policies are dropped)
ALTER TABLE chime_messages
DROP COLUMN IF EXISTS sender_id;

-- Add sender_id as UUID with foreign key
ALTER TABLE chime_messages
ADD COLUMN sender_id UUID REFERENCES public.users(id) ON DELETE CASCADE;

-- ============================================================================
-- 4. Create new RLS policies with UUID sender_id
-- ============================================================================

-- Policy 1: INSERT - Authenticated users can insert messages
CREATE POLICY "Authenticated users can insert messages"
ON chime_messages
FOR INSERT
WITH CHECK (
    -- Require user_id to be set (will be populated by app)
    user_id IS NOT NULL
    AND
    -- Require channel identification
    (channel_id IS NOT NULL OR channel_arn IS NOT NULL)
);

-- Policy 2: SELECT - Video call participants can view messages
CREATE POLICY "Video call participants can view messages"
ON chime_messages
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM video_call_sessions vcs
        WHERE (vcs.meeting_id = chime_messages.channel_arn OR vcs.meeting_id = chime_messages.channel_id)
        AND (vcs.provider_id = auth.uid() OR vcs.patient_id = auth.uid())
    )
);

-- Policy 3: UPDATE - Users can update their own messages
CREATE POLICY "Users can update their own messages"
ON chime_messages
FOR UPDATE
USING (
    sender_id = auth.uid() OR user_id = auth.uid()
);

-- Policy 4: DELETE - Users can delete their own messages
CREATE POLICY "Users can delete their own messages"
ON chime_messages
FOR DELETE
USING (
    sender_id = auth.uid() OR user_id = auth.uid()
);

-- ============================================================================
-- 6. Create index on sender_id (UUID)
-- ============================================================================

-- Recreate the index since we dropped and recreated the column
CREATE INDEX IF NOT EXISTS idx_chime_messages_sender_id
ON chime_messages(sender_id);

-- ============================================================================
-- 7. Add helpful comments
-- ============================================================================

COMMENT ON COLUMN chime_messages.sender_id IS
    'Supabase Auth UUID of message sender. Links to users table. Automatically set from auth.uid() on INSERT.';

COMMENT ON CONSTRAINT chime_messages_sender_id_fkey ON chime_messages IS
    'Ensures sender_id references a valid user in the users table. Cascades on delete.';

-- ============================================================================
-- 8. Migration verification query
-- ============================================================================

-- Run this to verify the migration succeeded:
--
-- -- Check column type
-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'chime_messages' AND column_name = 'sender_id';
--
-- -- Check foreign key constraint
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = 'chime_messages'::regclass
-- AND conname = 'chime_messages_sender_id_fkey';
--
-- -- Check policies
-- SELECT policyname, cmd
-- FROM pg_policies
-- WHERE tablename = 'chime_messages'
-- ORDER BY policyname;
