-- Add sender_avatar column to chime_messages table
-- This stores the profile picture URL of the message sender for display in chat

ALTER TABLE chime_messages
ADD COLUMN IF NOT EXISTS sender_avatar TEXT;

-- Add comment for documentation
COMMENT ON COLUMN chime_messages.sender_avatar IS 'Profile picture URL of the message sender';
