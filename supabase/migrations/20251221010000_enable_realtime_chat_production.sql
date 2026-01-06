-- Migration: Production-Ready Real-time Chat Configuration
-- Date: December 21, 2025
-- Purpose: Ensure chime_messages has full realtime support and proper indexes

-- ============================================================================
-- PART 1: Enable Realtime for chime_messages
-- ============================================================================

-- First, ensure the table is part of the realtime publication
-- This is required for real-time subscriptions to work
DO $$
BEGIN
    -- Check if table is already in publication
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'chime_messages'
    ) THEN
        -- Add table to realtime publication
        ALTER PUBLICATION supabase_realtime ADD TABLE chime_messages;
        RAISE NOTICE 'Added chime_messages to supabase_realtime publication';
    ELSE
        RAISE NOTICE 'chime_messages already in supabase_realtime publication';
    END IF;
END $$;

-- ============================================================================
-- PART 2: Configure Realtime with Full Replica Identity
-- ============================================================================

-- Set REPLICA IDENTITY to FULL for complete change data
-- This ensures all columns are available in realtime events
ALTER TABLE chime_messages REPLICA IDENTITY FULL;

-- ============================================================================
-- PART 3: Optimize Indexes for Chat Queries
-- ============================================================================

-- Index for appointment-based chat queries (most common)
CREATE INDEX IF NOT EXISTS idx_chime_messages_appointment_created
ON chime_messages(appointment_id, created_at DESC);

-- Index for user-based queries
CREATE INDEX IF NOT EXISTS idx_chime_messages_sender_created
ON chime_messages(sender_id, created_at DESC);

-- Index for channel-based queries (backward compatibility)
CREATE INDEX IF NOT EXISTS idx_chime_messages_channel_created
ON chime_messages(channel_id, created_at DESC);

-- ============================================================================
-- PART 4: Ensure Required Columns Exist
-- ============================================================================

-- Add is_read column for read receipts (if not exists)
ALTER TABLE chime_messages
ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT FALSE;

-- Add read_at timestamp for when message was read
ALTER TABLE chime_messages
ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ;

-- ============================================================================
-- PART 5: Create Function to Mark Messages as Read
-- ============================================================================

CREATE OR REPLACE FUNCTION mark_messages_read(
    p_appointment_id UUID,
    p_reader_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    updated_count INTEGER;
BEGIN
    -- Mark all unread messages from other users as read
    UPDATE chime_messages
    SET
        is_read = TRUE,
        read_at = NOW()
    WHERE
        appointment_id = p_appointment_id
        AND sender_id != p_reader_id
        AND is_read = FALSE;

    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$;

COMMENT ON FUNCTION mark_messages_read IS 'Mark all unread messages in an appointment as read by the specified user';

-- ============================================================================
-- PART 6: Create Trigger for Automatic Timestamps
-- ============================================================================

-- Ensure updated_at is automatically set
CREATE OR REPLACE FUNCTION update_chime_messages_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- Drop existing trigger if exists and recreate
DROP TRIGGER IF EXISTS chime_messages_updated_at ON chime_messages;
CREATE TRIGGER chime_messages_updated_at
    BEFORE UPDATE ON chime_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_chime_messages_timestamp();

-- ============================================================================
-- PART 7: Create View for Unread Message Counts
-- ============================================================================

CREATE OR REPLACE VIEW unread_message_counts AS
SELECT
    appointment_id,
    sender_id,
    COUNT(*) as unread_count
FROM chime_messages
WHERE is_read = FALSE
GROUP BY appointment_id, sender_id;

GRANT SELECT ON unread_message_counts TO authenticated;
GRANT SELECT ON unread_message_counts TO anon;

-- ============================================================================
-- PART 8: Add Comments for Documentation
-- ============================================================================

COMMENT ON TABLE chime_messages IS 'Real-time chat messages for video calls. Linked to appointments for appointment-based chat. Realtime enabled for instant message delivery.';

COMMENT ON COLUMN chime_messages.is_read IS 'Whether the message has been read by the recipient';
COMMENT ON COLUMN chime_messages.read_at IS 'Timestamp when the message was read';
COMMENT ON COLUMN chime_messages.appointment_id IS 'Links message to specific appointment for appointment-based chat';

-- ============================================================================
-- PART 9: Verify Realtime Configuration
-- ============================================================================

-- Log the realtime status for verification
DO $$
DECLARE
    is_realtime_enabled BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'chime_messages'
    ) INTO is_realtime_enabled;

    IF is_realtime_enabled THEN
        RAISE NOTICE '✅ Realtime is ENABLED for chime_messages';
    ELSE
        RAISE WARNING '❌ Realtime is NOT enabled for chime_messages';
    END IF;
END $$;
