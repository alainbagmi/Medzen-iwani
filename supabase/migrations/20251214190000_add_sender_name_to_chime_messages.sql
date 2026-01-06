-- Migration: Add sender_name to chime_messages table
-- Purpose: Store sender's display name with each message for better UX
-- Date: 2025-12-14
-- Related: lib/custom_code/widgets/chime_meeting_webview.dart

-- Add sender_name column to store the display name of the message sender
ALTER TABLE chime_messages
  ADD COLUMN IF NOT EXISTS sender_name TEXT;

-- Create index for sender_name to optimize queries
CREATE INDEX IF NOT EXISTS idx_chime_messages_sender_name
  ON chime_messages(sender_name);

-- Add comment for documentation
COMMENT ON COLUMN chime_messages.sender_name IS 'Display name of the message sender (denormalized for performance)';
