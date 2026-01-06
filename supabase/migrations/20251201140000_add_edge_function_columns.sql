-- Migration: Add columns expected by bedrock-ai-chat Edge Function
-- Purpose: Add language_code, input_tokens, output_tokens columns to ai_messages
-- Created: 2025-12-01
-- Reason: Edge Function (supabase/functions/bedrock-ai-chat/index.ts) stores these columns
--         but they don't exist in the database, causing INSERT failures

-- Add missing columns to ai_messages table
ALTER TABLE ai_messages
ADD COLUMN IF NOT EXISTS language_code VARCHAR(10),
ADD COLUMN IF NOT EXISTS input_tokens INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS output_tokens INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_tokens INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS model_used VARCHAR(100),
ADD COLUMN IF NOT EXISTS response_time_ms INTEGER;

-- Add comments for documentation
COMMENT ON COLUMN ai_messages.language_code IS 'ISO 639-1 language code (e.g., en, fr, sw) - stored by Edge Function';
COMMENT ON COLUMN ai_messages.input_tokens IS 'Number of tokens in the input/prompt sent to Bedrock';
COMMENT ON COLUMN ai_messages.output_tokens IS 'Number of tokens in the AI response from Bedrock';
COMMENT ON COLUMN ai_messages.total_tokens IS 'Total tokens used (input + output)';
COMMENT ON COLUMN ai_messages.model_used IS 'Bedrock model identifier used for this message';
COMMENT ON COLUMN ai_messages.response_time_ms IS 'Response time in milliseconds for Lambda invocation';

-- Create indexes for common queries
CREATE INDEX IF NOT EXISTS idx_ai_messages_language_code
ON ai_messages(language_code)
WHERE language_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_ai_messages_total_tokens
ON ai_messages(total_tokens DESC)
WHERE total_tokens > 0;

CREATE INDEX IF NOT EXISTS idx_ai_messages_model_used
ON ai_messages(model_used)
WHERE model_used IS NOT NULL;

-- Backfill language_code from existing language column (if any exist)
UPDATE ai_messages
SET language_code = language
WHERE language IS NOT NULL AND language_code IS NULL;

-- Backfill total_tokens from existing tokens_used column (if any exist)
UPDATE ai_messages
SET total_tokens = tokens_used
WHERE tokens_used IS NOT NULL AND total_tokens = 0;

-- Note: We're keeping both language and language_code columns for backward compatibility
-- The Lambda function uses 'language' while the Edge Function uses 'language_code'
-- Both should be populated going forward

-- Grant permissions
GRANT SELECT ON ai_messages TO authenticated;
GRANT INSERT ON ai_messages TO authenticated;
GRANT UPDATE ON ai_messages TO authenticated;
