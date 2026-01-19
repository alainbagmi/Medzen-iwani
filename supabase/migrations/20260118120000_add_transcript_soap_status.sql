-- Add transcript and SOAP status tracking columns to video_call_sessions
-- This enables background job orchestration and polling-based generation

ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS transcript_status TEXT
  CHECK (transcript_status IN ('none', 'recording', 'processing', 'ready', 'failed'))
  DEFAULT 'none',
ADD COLUMN IF NOT EXISTS transcript_text TEXT,
ADD COLUMN IF NOT EXISTS transcript_updated_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS soap_status TEXT
  CHECK (soap_status IN ('none', 'queued', 'generating', 'ready', 'failed'))
  DEFAULT 'none',
ADD COLUMN IF NOT EXISTS soap_json JSONB,
ADD COLUMN IF NOT EXISTS soap_error TEXT,
ADD COLUMN IF NOT EXISTS soap_updated_at TIMESTAMPTZ;

-- Add comments for documentation
COMMENT ON COLUMN video_call_sessions.transcript_status IS
'Transcript lifecycle: none → recording → processing → ready/failed';

COMMENT ON COLUMN video_call_sessions.transcript_text IS
'Complete merged transcript from all live caption segments';

COMMENT ON COLUMN video_call_sessions.transcript_updated_at IS
'Last update timestamp for transcript processing';

COMMENT ON COLUMN video_call_sessions.soap_status IS
'SOAP generation lifecycle: none → queued → generating → ready/failed';

COMMENT ON COLUMN video_call_sessions.soap_json IS
'Generated SOAP note structure with subjective, objective, assessment, plan';

COMMENT ON COLUMN video_call_sessions.soap_error IS
'Error message if SOAP generation failed';

COMMENT ON COLUMN video_call_sessions.soap_updated_at IS
'Last update timestamp for SOAP generation';

-- Create indexes for efficient polling queries
-- Used by dialog to check status every 2 seconds
CREATE INDEX IF NOT EXISTS idx_sessions_soap_status
  ON video_call_sessions(soap_status)
  WHERE soap_status IN ('queued', 'generating');

CREATE INDEX IF NOT EXISTS idx_sessions_transcript_status
  ON video_call_sessions(transcript_status)
  WHERE transcript_status IN ('recording', 'processing');

-- Composite index for background job queries
CREATE INDEX IF NOT EXISTS idx_sessions_status_updated
  ON video_call_sessions(soap_status, soap_updated_at DESC)
  WHERE soap_status IN ('queued', 'generating');

-- Ensure backward compatibility: set default status for existing sessions
-- If transcript already exists, mark as ready; otherwise mark as none
UPDATE video_call_sessions
SET
  transcript_status = CASE
    WHEN transcript IS NOT NULL AND transcript != '' THEN 'ready'
    ELSE 'none'
  END,
  transcript_updated_at = COALESCE(updated_at, created_at),
  soap_status = 'none',
  soap_updated_at = COALESCE(updated_at, created_at)
WHERE transcript_status = 'none' AND transcript_status IS NOT NULL;

-- Log completion
SELECT pg_sleep(0.1);  -- Ensure logging happens after migration
