-- Migration: Create chime_messages table for real-time message storage
-- Purpose: Store actual message content for Chime SDK in-call chat
-- Related to: subscribe_to_chime_messages.dart, send_chime_message.dart
-- Date: 2025-11-27

-- Create chime_messages table for storing chat messages
CREATE TABLE IF NOT EXISTS chime_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_arn TEXT NOT NULL,
    message TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_id TEXT, -- Chime SDK message identifier
    metadata JSONB DEFAULT '{}', -- Additional message metadata (reactions, read status, etc.)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance optimization
CREATE INDEX idx_chime_messages_channel_arn ON chime_messages(channel_arn);
CREATE INDEX idx_chime_messages_created_at ON chime_messages(created_at);
CREATE INDEX idx_chime_messages_user_id ON chime_messages(user_id);
CREATE INDEX idx_chime_messages_channel_created ON chime_messages(channel_arn, created_at DESC);

-- Enable Row Level Security
ALTER TABLE chime_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view messages in channels they're part of
CREATE POLICY "Users can view messages in their channels"
ON chime_messages
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM chime_messaging_channels c
        WHERE c.channel_arn = chime_messages.channel_arn
        AND (c.provider_id = auth.uid() OR c.patient_id = auth.uid())
    )
);

-- RLS Policy: Users can insert messages in channels they're part of
CREATE POLICY "Users can send messages in their channels"
ON chime_messages
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM chime_messaging_channels c
        WHERE c.channel_arn = chime_messages.channel_arn
        AND (c.provider_id = auth.uid() OR c.patient_id = auth.uid())
    )
    AND user_id = auth.uid()
);

-- RLS Policy: Users can update their own messages (for editing)
CREATE POLICY "Users can update their own messages"
ON chime_messages
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- RLS Policy: Users can delete their own messages
CREATE POLICY "Users can delete their own messages"
ON chime_messages
FOR DELETE
USING (user_id = auth.uid());

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_chime_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_chime_messages_updated_at_trigger
BEFORE UPDATE ON chime_messages
FOR EACH ROW
EXECUTE FUNCTION update_chime_messages_updated_at();

-- Function to update last_message_at in chime_messaging_channels
CREATE OR REPLACE FUNCTION update_channel_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE chime_messaging_channels
    SET last_message_at = NOW()
    WHERE channel_arn = NEW.channel_arn;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update channel's last_message_at when message is sent
CREATE TRIGGER update_channel_last_message_trigger
AFTER INSERT ON chime_messages
FOR EACH ROW
EXECUTE FUNCTION update_channel_last_message();

-- Add comment for documentation
COMMENT ON TABLE chime_messages IS 'Stores real-time chat messages for Chime SDK video calls. Messages are streamed to clients via Supabase Realtime.';
COMMENT ON COLUMN chime_messages.channel_arn IS 'Amazon Chime messaging channel ARN';
COMMENT ON COLUMN chime_messages.message IS 'Message content (text)';
COMMENT ON COLUMN chime_messages.message_id IS 'Chime SDK message identifier for correlation';
COMMENT ON COLUMN chime_messages.metadata IS 'Additional message metadata (reactions, read receipts, etc.)';
