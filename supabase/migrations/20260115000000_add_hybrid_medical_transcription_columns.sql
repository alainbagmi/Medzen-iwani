-- Add columns to support hybrid medical transcription model
-- This enables medical transcription for ALL languages (not just en-US)
-- with language-specific medical vocabularies and AI entity extraction

-- Add base columns first (if they don't exist)
ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS live_transcription_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS live_transcription_language VARCHAR(10) DEFAULT 'en-US',
ADD COLUMN IF NOT EXISTS live_transcription_engine TEXT DEFAULT 'aws_transcribe_medical';

-- Add column to track which medical vocabulary was used
ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS live_transcription_medical_vocabulary VARCHAR(255),
ADD COLUMN IF NOT EXISTS live_transcription_medical_entities_enabled BOOLEAN DEFAULT false;

-- Add index for querying by medical vocabulary
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_medical_vocab
ON video_call_sessions(live_transcription_medical_vocabulary)
WHERE live_transcription_enabled = true;

-- Add index for querying sessions with medical entity extraction
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_medical_entities
ON video_call_sessions(live_transcription_medical_entities_enabled)
WHERE live_transcription_enabled = true;

-- Add comments documenting the new fields
COMMENT ON COLUMN video_call_sessions.live_transcription_medical_vocabulary IS
'Medical vocabulary name used for transcription (e.g., medzen-medical-vocab-fr, medzen-medical-vocab-sw). Enables medical terminology recognition in all languages, not just en-US.';

COMMENT ON COLUMN video_call_sessions.live_transcription_medical_entities_enabled IS
'Whether medical entity extraction via AI is enabled for this transcription. Used to identify diagnoses, medications, and procedures from transcripts in any language.';

-- Create a view for querying medical transcription usage by language
CREATE OR REPLACE VIEW medical_transcription_usage AS
SELECT
  live_transcription_language,
  live_transcription_medical_vocabulary,
  live_transcription_engine,
  COUNT(*) as session_count,
  COUNT(CASE WHEN live_transcription_medical_entities_enabled THEN 1 END) as sessions_with_entity_extraction,
  AVG(EXTRACT(EPOCH FROM (COALESCE(ended_at, NOW()) - started_at))/60)::INT as avg_duration_minutes,
  MAX(created_at) as last_session
FROM video_call_sessions
WHERE live_transcription_enabled = true
GROUP BY live_transcription_language, live_transcription_medical_vocabulary, live_transcription_engine
ORDER BY session_count DESC;

COMMENT ON VIEW medical_transcription_usage IS
'View showing medical transcription usage statistics by language and vocabulary. Tracks the adoption of hybrid medical transcription across different languages.';
