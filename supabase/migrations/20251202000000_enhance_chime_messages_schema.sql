-- Add new columns while keeping existing ones for backward compatibility
ALTER TABLE chime_messages
  ADD COLUMN IF NOT EXISTS channel_id TEXT,
  ADD COLUMN IF NOT EXISTS message_type TEXT DEFAULT 'text',
  ADD COLUMN IF NOT EXISTS sender_id UUID REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS message_content TEXT;

-- Add check constraint for message_type
ALTER TABLE chime_messages
  ADD CONSTRAINT chime_messages_type_check
  CHECK (message_type IN ('text', 'system', 'file'));

-- Create index for new channel_id column
CREATE INDEX IF NOT EXISTS idx_chime_messages_channel_id
  ON chime_messages(channel_id);

-- Migrate existing data to new columns (if any)
UPDATE chime_messages
SET message_content = message,
    sender_id = user_id::uuid
WHERE message_content IS NULL;

-- Add comments
COMMENT ON COLUMN chime_messages.channel_id IS 'Channel ID for backward compatibility with channel_arn';
COMMENT ON COLUMN chime_messages.message_type IS 'Type of message: text, system, or file';
COMMENT ON COLUMN chime_messages.sender_id IS 'User ID of message sender';
COMMENT ON COLUMN chime_messages.message_content IS 'Message content (mirrors message column)';
