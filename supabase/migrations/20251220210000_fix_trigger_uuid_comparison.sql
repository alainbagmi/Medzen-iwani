-- Fix trigger UUID comparison issue
-- The conversation_id column is UUID, not TEXT, causing type mismatch error

-- Drop and recreate the trigger function with proper type handling
CREATE OR REPLACE FUNCTION update_conversation_title_on_message()
RETURNS TRIGGER AS $$
DECLARE
  current_title TEXT;
BEGIN
  -- Only update title on user messages
  IF NEW.role = 'user' THEN
    -- Get current conversation title (handle both UUID and TEXT comparison)
    SELECT conversation_title INTO current_title
    FROM ai_conversations
    WHERE id = NEW.conversation_id::uuid;

    -- Only update if title is empty or default
    IF current_title IS NULL
       OR current_title = ''
       OR current_title = 'New Conversation'
       OR current_title LIKE 'New Chat%' THEN

      UPDATE ai_conversations
      SET
        conversation_title = generate_conversation_title(NEW.content),
        updated_at = NOW()
      WHERE id = NEW.conversation_id::uuid;
    END IF;
  END IF;

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't block the insert
    RAISE WARNING 'Error updating conversation title: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Log completion
DO $$
BEGIN
  RAISE NOTICE 'Fixed trigger UUID comparison issue';
END $$;
