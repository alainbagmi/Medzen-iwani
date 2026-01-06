-- Retry adding sender_avatar column to chime_messages table
-- This column stores the profile picture URL of the message sender

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chime_messages' AND column_name = 'sender_avatar'
    ) THEN
        ALTER TABLE chime_messages ADD COLUMN sender_avatar TEXT;
        COMMENT ON COLUMN chime_messages.sender_avatar IS 'Profile picture URL of the message sender';
    END IF;
END $$;
