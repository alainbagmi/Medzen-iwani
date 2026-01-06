-- Make channel_arn nullable in chime_messages table
-- Date: 2025-12-17
--
-- Purpose: Fix constraint error when inserting messages via ChimeMeetingEnhanced widget
-- The widget uses channel_id (meeting ID) instead of channel_arn (AWS Chime messaging ARN)
-- Both should be optional since we support either identifier
--
-- Changes:
-- 1. Make channel_arn nullable
-- 2. Update constraint to require at least one identifier (channel_id OR channel_arn)

-- ============================================================================
-- 1. Make channel_arn nullable
-- ============================================================================

ALTER TABLE chime_messages
ALTER COLUMN channel_arn DROP NOT NULL;

-- ============================================================================
-- 2. Add check constraint to ensure at least one channel identifier exists
-- ============================================================================

-- Drop existing constraint if it exists
ALTER TABLE chime_messages
DROP CONSTRAINT IF EXISTS chime_messages_channel_identifier_check;

-- Add new constraint to require at least one identifier
ALTER TABLE chime_messages
ADD CONSTRAINT chime_messages_channel_identifier_check
CHECK (channel_id IS NOT NULL OR channel_arn IS NOT NULL);

-- ============================================================================
-- 3. Update comment
-- ============================================================================

COMMENT ON COLUMN chime_messages.channel_arn IS
    'Amazon Chime messaging channel ARN (optional if channel_id is provided)';

COMMENT ON COLUMN chime_messages.channel_id IS
    'Meeting ID or channel identifier (optional if channel_arn is provided). Used by ChimeMeetingEnhanced widget.';

-- ============================================================================
-- Migration verification query
-- ============================================================================

-- Run this to verify the migration succeeded:
--
-- -- Check if channel_arn is nullable
-- SELECT column_name, is_nullable, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'chime_messages'
-- AND column_name IN ('channel_arn', 'channel_id');
--
-- -- Check constraint
-- SELECT conname, pg_get_constraintdef(oid)
-- FROM pg_constraint
-- WHERE conrelid = 'chime_messages'::regclass
-- AND conname = 'chime_messages_channel_identifier_check';
