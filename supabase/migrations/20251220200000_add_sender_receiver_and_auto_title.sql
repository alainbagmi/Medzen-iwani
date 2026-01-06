-- Add sender and receiver columns to AI chat tables and auto-generate titles

-- ============================================================================
-- 1. ADD SENDER/RECEIVER COLUMNS TO ai_conversations
-- ============================================================================

ALTER TABLE ai_conversations
ADD COLUMN IF NOT EXISTS sender_id TEXT,
ADD COLUMN IF NOT EXISTS receiver_id TEXT;

UPDATE ai_conversations
SET
  sender_id = user_id,
  receiver_id = assistant_id
WHERE sender_id IS NULL AND user_id IS NOT NULL;

COMMENT ON COLUMN ai_conversations.sender_id IS 'The human user who initiated the conversation';
COMMENT ON COLUMN ai_conversations.receiver_id IS 'The AI assistant receiving messages';

-- ============================================================================
-- 2. ADD SENDER/RECEIVER COLUMNS TO ai_messages
-- ============================================================================

ALTER TABLE ai_messages
ADD COLUMN IF NOT EXISTS sender_id TEXT,
ADD COLUMN IF NOT EXISTS receiver_id TEXT,
ADD COLUMN IF NOT EXISTS sender_name TEXT,
ADD COLUMN IF NOT EXISTS receiver_name TEXT;

UPDATE ai_messages
SET
  sender_id = CASE WHEN role = 'assistant' THEN 'assistant' ELSE 'user' END,
  receiver_id = CASE WHEN role = 'assistant' THEN 'user' ELSE 'assistant' END,
  sender_name = CASE WHEN role = 'assistant' THEN 'MedX AI' ELSE 'User' END,
  receiver_name = CASE WHEN role = 'assistant' THEN 'User' ELSE 'MedX AI' END
WHERE sender_id IS NULL;

COMMENT ON COLUMN ai_messages.sender_id IS 'ID of message sender (user or assistant)';
COMMENT ON COLUMN ai_messages.receiver_id IS 'ID of message receiver (user or assistant)';
COMMENT ON COLUMN ai_messages.sender_name IS 'Display name of sender';
COMMENT ON COLUMN ai_messages.receiver_name IS 'Display name of receiver';

-- ============================================================================
-- 3. CREATE FUNCTION TO AUTO-GENERATE CONVERSATION TITLE
-- ============================================================================

CREATE OR REPLACE FUNCTION generate_conversation_title(message_content TEXT)
RETURNS TEXT AS $$
DECLARE
  title TEXT;
  max_length INT := 50;
BEGIN
  IF message_content IS NULL OR message_content = '' THEN
    RETURN 'New Conversation';
  END IF;

  title := TRIM(message_content);
  title := REGEXP_REPLACE(title, E'[\\n\\r]+', ' ', 'g');
  title := REGEXP_REPLACE(title, E'\\s+', ' ', 'g');

  IF LENGTH(title) > max_length THEN
    title := SUBSTRING(title FROM 1 FOR max_length);
    title := title || '...';
  END IF;

  IF title IS NULL OR title = '' THEN
    title := 'New Conversation';
  END IF;

  RETURN title;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- 4. CREATE TRIGGER TO UPDATE CONVERSATION TITLE ON FIRST USER MESSAGE
-- ============================================================================

CREATE OR REPLACE FUNCTION update_conversation_title_on_message()
RETURNS TRIGGER AS $$
DECLARE
  current_title TEXT;
BEGIN
  IF NEW.role = 'user' THEN
    SELECT conversation_title INTO current_title
    FROM ai_conversations
    WHERE id::TEXT = NEW.conversation_id;

    IF current_title IS NULL
       OR current_title = ''
       OR current_title = 'New Conversation'
       OR current_title LIKE 'New Chat%' THEN

      UPDATE ai_conversations
      SET
        conversation_title = generate_conversation_title(NEW.content),
        updated_at = NOW()
      WHERE id::TEXT = NEW.conversation_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_conversation_title ON ai_messages;

CREATE TRIGGER trigger_update_conversation_title
  AFTER INSERT ON ai_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_title_on_message();

-- ============================================================================
-- 5. ADD INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_ai_messages_sender_id ON ai_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_ai_messages_receiver_id ON ai_messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_sender_id ON ai_conversations(sender_id);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_receiver_id ON ai_conversations(receiver_id);

-- ============================================================================
-- 6. LOG COMPLETION
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE 'Migration complete: Added sender/receiver columns and auto-title generation';
END $$;
