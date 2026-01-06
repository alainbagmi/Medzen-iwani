-- Migration: Add multilingual support to video_call_sessions
-- Purpose: Enable language detection, custom vocabularies, and TTS for video calls
-- Created: 2025-11-20

-- Add multilingual columns to video_call_sessions
ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS transcript_language VARCHAR(10) DEFAULT 'en-US',
ADD COLUMN IF NOT EXISTS detected_languages JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS transcript_segments JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS tts_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS tts_language VARCHAR(10),
ADD COLUMN IF NOT EXISTS custom_vocabulary_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS language_confidence FLOAT,
ADD COLUMN IF NOT EXISTS auto_language_detect BOOLEAN DEFAULT true;

-- Add comments for documentation
COMMENT ON COLUMN video_call_sessions.transcript_language IS 'Primary language detected in the transcript (ISO 639-1 + region code, e.g., en-US, fr-FR)';
COMMENT ON COLUMN video_call_sessions.detected_languages IS 'Array of detected languages per speaker: [{speaker: 1, language: "en-US", confidence: 0.95}]';
COMMENT ON COLUMN video_call_sessions.transcript_segments IS 'Transcript segments with language tags: [{speaker: 1, start: 0, end: 5.2, text: "...", language: "en-US"}]';
COMMENT ON COLUMN video_call_sessions.tts_enabled IS 'Whether text-to-speech was enabled for this session';
COMMENT ON COLUMN video_call_sessions.tts_language IS 'Language used for TTS synthesis if enabled';
COMMENT ON COLUMN video_call_sessions.custom_vocabulary_name IS 'AWS Transcribe custom vocabulary used (e.g., pidgin-medical-terms)';
COMMENT ON COLUMN video_call_sessions.language_confidence IS 'Confidence score for primary language detection (0-1)';
COMMENT ON COLUMN video_call_sessions.auto_language_detect IS 'Whether automatic language detection was used vs user preference';

-- Create index for language-based queries
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_transcript_language
ON video_call_sessions(transcript_language);

CREATE INDEX IF NOT EXISTS idx_video_call_sessions_tts_language
ON video_call_sessions(tts_language);

-- Create index for JSONB language detection data
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_detected_languages
ON video_call_sessions USING GIN(detected_languages);

-- Update RLS policies to include new columns
-- (Existing policies will automatically cover new columns due to table-level policies)

-- Add helper function to extract speaker languages from detected_languages JSONB
CREATE OR REPLACE FUNCTION get_speaker_languages(session_id UUID)
RETURNS TABLE(speaker INT, language VARCHAR, confidence FLOAT)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT
    (elem->>'speaker')::INT as speaker,
    elem->>'language' as language,
    (elem->>'confidence')::FLOAT as confidence
  FROM video_call_sessions,
       jsonb_array_elements(detected_languages) as elem
  WHERE id = session_id;
END;
$$;

COMMENT ON FUNCTION get_speaker_languages IS 'Extract speaker language information from detected_languages JSONB column';

-- Add trigger to automatically detect code-switching
CREATE OR REPLACE FUNCTION detect_code_switching()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  unique_languages INT;
BEGIN
  -- Count unique languages across all speakers
  SELECT COUNT(DISTINCT elem->>'language')
  INTO unique_languages
  FROM jsonb_array_elements(NEW.detected_languages) as elem;

  -- If more than one language detected, mark as code-switching
  IF unique_languages > 1 THEN
    NEW.detected_languages = jsonb_set(
      NEW.detected_languages,
      '{code_switching}',
      'true'::jsonb,
      true
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER video_call_detect_code_switching
BEFORE INSERT OR UPDATE OF detected_languages
ON video_call_sessions
FOR EACH ROW
EXECUTE FUNCTION detect_code_switching();

COMMENT ON TRIGGER video_call_detect_code_switching ON video_call_sessions IS 'Automatically detect and flag code-switching (multilingual) conversations';

-- Grant necessary permissions
GRANT SELECT ON video_call_sessions TO authenticated;
GRANT EXECUTE ON FUNCTION get_speaker_languages TO authenticated;
