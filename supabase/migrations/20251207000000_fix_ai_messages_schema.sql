-- Migration: Fix ai_messages schema to match Edge Function expectations
-- Purpose: Add missing columns needed by bedrock-ai-chat Edge Function
-- Created: 2025-12-07
-- Issue: Edge Function uses input_tokens, output_tokens, language_code, model_used, response_time_ms
--        but database only has tokens_used, language, model_version

-- Add missing columns to ai_messages table
ALTER TABLE ai_messages
  -- Token tracking (more granular than single tokens_used)
  ADD COLUMN IF NOT EXISTS input_tokens INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS output_tokens INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_tokens INTEGER DEFAULT 0,

  -- Response time tracking
  ADD COLUMN IF NOT EXISTS response_time_ms INTEGER,

  -- Model tracking (Edge Function uses model_used)
  ADD COLUMN IF NOT EXISTS model_used TEXT,

  -- Language tracking (Edge Function uses language_code)
  ADD COLUMN IF NOT EXISTS language_code VARCHAR(10);

-- Update existing records to populate new columns from old ones
-- Migrate tokens_used to total_tokens
UPDATE ai_messages
SET total_tokens = COALESCE(tokens_used, 0)
WHERE total_tokens = 0 AND tokens_used IS NOT NULL;

-- Migrate language to language_code
UPDATE ai_messages
SET language_code = COALESCE(language, 'en')
WHERE language_code IS NULL;

-- Migrate model_version to model_used
UPDATE ai_messages
SET model_used = COALESCE(model_version, 'eu.amazon.nova-pro-v1:0')
WHERE model_used IS NULL;

-- Add comments for documentation
COMMENT ON COLUMN ai_messages.input_tokens IS 'Number of tokens in the user input';
COMMENT ON COLUMN ai_messages.output_tokens IS 'Number of tokens in the AI response';
COMMENT ON COLUMN ai_messages.total_tokens IS 'Total tokens used (input + output)';
COMMENT ON COLUMN ai_messages.response_time_ms IS 'Response time in milliseconds';
COMMENT ON COLUMN ai_messages.model_used IS 'AI model used for this response (e.g., anthropic.claude-3-sonnet)';
COMMENT ON COLUMN ai_messages.language_code IS 'ISO 639-1 language code (e.g., en, fr, sw)';

-- Keep the old columns for backward compatibility (can deprecate later)
COMMENT ON COLUMN ai_messages.tokens_used IS 'DEPRECATED: Use total_tokens instead. Kept for backward compatibility.';
COMMENT ON COLUMN ai_messages.language IS 'DEPRECATED: Use language_code instead. Kept for backward compatibility.';
COMMENT ON COLUMN ai_messages.model_version IS 'DEPRECATED: Use model_used instead. Kept for backward compatibility.';

-- Create indexes for query performance
CREATE INDEX IF NOT EXISTS idx_ai_messages_language_code ON ai_messages(language_code);
CREATE INDEX IF NOT EXISTS idx_ai_messages_model_used ON ai_messages(model_used);
CREATE INDEX IF NOT EXISTS idx_ai_messages_total_tokens ON ai_messages(total_tokens DESC);
CREATE INDEX IF NOT EXISTS idx_ai_messages_response_time ON ai_messages(response_time_ms);

-- Create function to sync old and new columns (trigger)
CREATE OR REPLACE FUNCTION sync_ai_messages_columns()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Sync total_tokens to tokens_used for backward compatibility
  IF NEW.total_tokens IS NOT NULL THEN
    NEW.tokens_used := NEW.total_tokens;
  END IF;

  -- Sync language_code to language for backward compatibility
  IF NEW.language_code IS NOT NULL THEN
    NEW.language := NEW.language_code;
  END IF;

  -- Sync model_used to model_version for backward compatibility
  IF NEW.model_used IS NOT NULL THEN
    NEW.model_version := NEW.model_used;
  END IF;

  RETURN NEW;
END;
$$;

-- Create trigger to keep old and new columns in sync
DROP TRIGGER IF EXISTS sync_ai_messages_columns_trigger ON ai_messages;
CREATE TRIGGER sync_ai_messages_columns_trigger
BEFORE INSERT OR UPDATE ON ai_messages
FOR EACH ROW
EXECUTE FUNCTION sync_ai_messages_columns();

COMMENT ON FUNCTION sync_ai_messages_columns IS 'Sync new columns (input_tokens, language_code, model_used) with old columns (tokens_used, language, model_version) for backward compatibility';

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON ai_messages TO authenticated;
GRANT ALL ON ai_messages TO service_role;
