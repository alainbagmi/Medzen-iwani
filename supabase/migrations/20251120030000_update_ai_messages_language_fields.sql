-- Migration: Update ai_messages for enhanced language support
-- Purpose: Add language confidence, code-mixing detection, and TTS support to AI messages
-- Created: 2025-11-20

-- Add new columns to ai_messages
ALTER TABLE ai_messages
ADD COLUMN IF NOT EXISTS language_confidence FLOAT CHECK (language_confidence >= 0 AND language_confidence <= 1),
ADD COLUMN IF NOT EXISTS detected_code_mixing BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS language_alternatives JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS audio_url TEXT,
ADD COLUMN IF NOT EXISTS tts_voice_id VARCHAR(50),
ADD COLUMN IF NOT EXISTS audio_duration_seconds FLOAT,
ADD COLUMN IF NOT EXISTS audio_generated_at TIMESTAMPTZ;

-- Add comments for documentation
COMMENT ON COLUMN ai_messages.language_confidence IS 'Confidence score for language detection (0-1), higher is more confident';
COMMENT ON COLUMN ai_messages.detected_code_mixing IS 'Whether code-mixing/code-switching was detected in the message';
COMMENT ON COLUMN ai_messages.language_alternatives IS 'Alternative language detections with scores: [{language: "fr", confidence: 0.15}]';
COMMENT ON COLUMN ai_messages.audio_url IS 'S3 URL for TTS-generated audio response (AWS Polly)';
COMMENT ON COLUMN ai_messages.tts_voice_id IS 'AWS Polly voice ID used for audio generation';
COMMENT ON COLUMN ai_messages.audio_duration_seconds IS 'Duration of generated audio in seconds';
COMMENT ON COLUMN ai_messages.audio_generated_at IS 'Timestamp when TTS audio was generated';

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_ai_messages_language_confidence
ON ai_messages(language_confidence DESC);

CREATE INDEX IF NOT EXISTS idx_ai_messages_code_mixing
ON ai_messages(detected_code_mixing)
WHERE detected_code_mixing = true;

CREATE INDEX IF NOT EXISTS idx_ai_messages_audio_url
ON ai_messages(audio_url)
WHERE audio_url IS NOT NULL;

-- Create index for JSONB language_alternatives
CREATE INDEX IF NOT EXISTS idx_ai_messages_language_alternatives
ON ai_messages USING GIN(language_alternatives);

-- Update ai_conversations for TTS preferences
ALTER TABLE ai_conversations
ADD COLUMN IF NOT EXISTS tts_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS preferred_voice_id VARCHAR(50);

COMMENT ON COLUMN ai_conversations.tts_enabled IS 'Whether TTS audio is enabled for this conversation';
COMMENT ON COLUMN ai_conversations.preferred_voice_id IS 'User preferred AWS Polly voice ID for this conversation';

-- Create function to analyze language patterns
CREATE OR REPLACE FUNCTION analyze_message_language(message_text TEXT)
RETURNS JSONB
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  result JSONB;
  word_count INT;
  has_mixed_scripts BOOLEAN;
BEGIN
  word_count := array_length(string_to_array(message_text, ' '), 1);

  -- Simple heuristic for code-mixing detection
  -- Check for mixed scripts or language indicators
  has_mixed_scripts := (
    message_text ~ '[a-zA-Z]' AND  -- Has Latin characters
    (
      message_text ~ '[\u0600-\u06FF]' OR  -- Has Arabic
      message_text ~ '[\u4E00-\u9FFF]'     -- Has Chinese
    )
  );

  result := jsonb_build_object(
    'word_count', word_count,
    'has_mixed_scripts', has_mixed_scripts,
    'estimated_language_switches', CASE
      WHEN has_mixed_scripts THEN 2
      ELSE 0
    END
  );

  RETURN result;
END;
$$;

COMMENT ON FUNCTION analyze_message_language IS 'Analyze message for language patterns and code-mixing indicators';

-- Create function to get audio URL expiry
CREATE OR REPLACE FUNCTION is_audio_url_expired(audio_generated TIMESTAMPTZ)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  -- S3 presigned URLs typically expire after 7 days
  RETURN audio_generated IS NULL OR
         audio_generated < (NOW() - INTERVAL '7 days');
END;
$$;

COMMENT ON FUNCTION is_audio_url_expired IS 'Check if TTS audio URL has likely expired (7 day S3 presigned URL)';

-- Create view for messages with valid audio
CREATE OR REPLACE VIEW ai_messages_with_audio AS
SELECT
  am.*,
  is_audio_url_expired(am.audio_generated_at) as audio_expired
FROM ai_messages am
WHERE am.audio_url IS NOT NULL;

COMMENT ON VIEW ai_messages_with_audio IS 'AI messages that have TTS audio, with expiry status';

-- Create function to get conversation language statistics
CREATE OR REPLACE FUNCTION get_conversation_language_stats(conv_id UUID)
RETURNS TABLE(
  language VARCHAR,
  message_count BIGINT,
  avg_confidence FLOAT,
  code_mixing_count BIGINT
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT
    am.language,
    COUNT(*) as message_count,
    AVG(am.language_confidence) as avg_confidence,
    COUNT(*) FILTER (WHERE am.detected_code_mixing = true) as code_mixing_count
  FROM ai_messages am
  WHERE am.conversation_id = conv_id
    AND am.language IS NOT NULL
  GROUP BY am.language
  ORDER BY message_count DESC;
END;
$$;

COMMENT ON FUNCTION get_conversation_language_stats IS 'Get language usage statistics for a conversation';

-- Create trigger to validate language data
CREATE OR REPLACE FUNCTION validate_ai_message_language_data()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Validate language confidence is between 0 and 1
  IF NEW.language_confidence IS NOT NULL THEN
    IF NEW.language_confidence < 0 OR NEW.language_confidence > 1 THEN
      RAISE EXCEPTION 'language_confidence must be between 0 and 1';
    END IF;
  END IF;

  -- If audio URL exists, TTS voice must be specified
  IF NEW.audio_url IS NOT NULL AND NEW.tts_voice_id IS NULL THEN
    RAISE EXCEPTION 'tts_voice_id is required when audio_url is present';
  END IF;

  -- Auto-set audio_generated_at if not provided
  IF NEW.audio_url IS NOT NULL AND NEW.audio_generated_at IS NULL THEN
    NEW.audio_generated_at := NOW();
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER validate_ai_message_language
BEFORE INSERT OR UPDATE ON ai_messages
FOR EACH ROW
EXECUTE FUNCTION validate_ai_message_language_data();

COMMENT ON TRIGGER validate_ai_message_language ON ai_messages IS 'Validate language-related data integrity';

-- Create materialized view for language analytics
CREATE MATERIALIZED VIEW IF NOT EXISTS ai_language_usage_stats AS
SELECT
  am.language,
  COUNT(*) as total_messages,
  COUNT(DISTINCT am.conversation_id) as unique_conversations,
  AVG(am.language_confidence) as avg_confidence,
  COUNT(*) FILTER (WHERE am.detected_code_mixing = true) as code_mixing_messages,
  COUNT(*) FILTER (WHERE am.audio_url IS NOT NULL) as messages_with_audio,
  MIN(am.created_at) as first_used,
  MAX(am.created_at) as last_used
FROM ai_messages am
WHERE am.language IS NOT NULL
GROUP BY am.language;

CREATE UNIQUE INDEX ON ai_language_usage_stats(language);

COMMENT ON MATERIALIZED VIEW ai_language_usage_stats IS 'Aggregate statistics for language usage in AI conversations';

-- Create function to refresh language stats
CREATE OR REPLACE FUNCTION refresh_language_usage_stats()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY ai_language_usage_stats;
END;
$$;

COMMENT ON FUNCTION refresh_language_usage_stats IS 'Refresh language usage statistics materialized view';

-- Grant permissions
GRANT SELECT ON ai_messages TO authenticated;
GRANT SELECT ON ai_conversations TO authenticated;
GRANT SELECT ON ai_messages_with_audio TO authenticated;
GRANT SELECT ON ai_language_usage_stats TO authenticated;
GRANT EXECUTE ON FUNCTION analyze_message_language TO authenticated;
GRANT EXECUTE ON FUNCTION is_audio_url_expired TO authenticated;
GRANT EXECUTE ON FUNCTION get_conversation_language_stats TO authenticated;
GRANT EXECUTE ON FUNCTION refresh_language_usage_stats TO service_role;

-- Create scheduled job to refresh stats daily (requires pg_cron extension)
-- Uncomment if pg_cron is enabled:
-- SELECT cron.schedule(
--   'refresh-language-stats',
--   '0 2 * * *', -- 2 AM daily
--   $$SELECT refresh_language_usage_stats()$$
-- );
