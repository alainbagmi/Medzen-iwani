-- Add recording, transcription, and medical entity extraction fields
-- for AWS Chime SDK v3 complete implementation
-- Date: 2025-12-15

-- Recording-related fields
ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS recording_pipeline_id TEXT,
ADD COLUMN IF NOT EXISTS recording_url TEXT,
ADD COLUMN IF NOT EXISTS recording_bucket TEXT,
ADD COLUMN IF NOT EXISTS recording_key TEXT,
ADD COLUMN IF NOT EXISTS recording_file_size BIGINT,
ADD COLUMN IF NOT EXISTS recording_duration_seconds INTEGER,
ADD COLUMN IF NOT EXISTS recording_format TEXT,
ADD COLUMN IF NOT EXISTS recording_completed_at TIMESTAMPTZ;

-- Transcription-related fields
ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS transcription_job_name TEXT,
ADD COLUMN IF NOT EXISTS transcription_output_key TEXT,
ADD COLUMN IF NOT EXISTS transcription_status TEXT,
ADD COLUMN IF NOT EXISTS transcript TEXT,
ADD COLUMN IF NOT EXISTS speaker_segments JSONB,
ADD COLUMN IF NOT EXISTS transcription_completed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS transcription_error TEXT;

-- Medical entity extraction fields
ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS medical_entities JSONB,
ADD COLUMN IF NOT EXISTS medical_codes JSONB,
ADD COLUMN IF NOT EXISTS medical_summary JSONB,
ADD COLUMN IF NOT EXISTS entity_extraction_completed_at TIMESTAMPTZ;

-- Add comments for documentation
COMMENT ON COLUMN video_call_sessions.recording_pipeline_id IS
  'AWS Chime Media Pipeline ID for recording';

COMMENT ON COLUMN video_call_sessions.recording_url IS
  'Presigned URL to access the recording';

COMMENT ON COLUMN video_call_sessions.recording_bucket IS
  'S3 bucket name where recording is stored';

COMMENT ON COLUMN video_call_sessions.recording_key IS
  'S3 object key for the recording file';

COMMENT ON COLUMN video_call_sessions.recording_file_size IS
  'Recording file size in bytes';

COMMENT ON COLUMN video_call_sessions.recording_duration_seconds IS
  'Duration of recording in seconds';

COMMENT ON COLUMN video_call_sessions.recording_format IS
  'Recording format (e.g., mp4, webm)';

COMMENT ON COLUMN video_call_sessions.recording_completed_at IS
  'Timestamp when recording was completed and saved to S3';

COMMENT ON COLUMN video_call_sessions.transcription_job_name IS
  'AWS Transcribe Medical job name';

COMMENT ON COLUMN video_call_sessions.transcription_output_key IS
  'S3 key for transcription output JSON';

COMMENT ON COLUMN video_call_sessions.transcription_status IS
  'Transcription job status (IN_PROGRESS, COMPLETED, FAILED)';

COMMENT ON COLUMN video_call_sessions.transcript IS
  'Full text transcript of the consultation';

COMMENT ON COLUMN video_call_sessions.speaker_segments IS
  'Speaker-identified transcript segments with timestamps';

COMMENT ON COLUMN video_call_sessions.transcription_completed_at IS
  'Timestamp when transcription completed';

COMMENT ON COLUMN video_call_sessions.transcription_error IS
  'Error message if transcription failed';

COMMENT ON COLUMN video_call_sessions.medical_entities IS
  'Extracted medical entities (medications, conditions, procedures, anatomy, PHI)';

COMMENT ON COLUMN video_call_sessions.medical_codes IS
  'Medical coding (ICD-10-CM, RxNorm, SNOMED CT)';

COMMENT ON COLUMN video_call_sessions.medical_summary IS
  'AI-generated medical summary (chief complaint, diagnoses, medications, procedures)';

COMMENT ON COLUMN video_call_sessions.entity_extraction_completed_at IS
  'Timestamp when medical entity extraction completed';

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_recording_completed
  ON video_call_sessions(recording_completed_at)
  WHERE recording_completed_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_video_call_sessions_transcription_status
  ON video_call_sessions(transcription_status)
  WHERE transcription_status IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_video_call_sessions_transcription_completed
  ON video_call_sessions(transcription_completed_at)
  WHERE transcription_completed_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_video_call_sessions_entity_extraction_completed
  ON video_call_sessions(entity_extraction_completed_at)
  WHERE entity_extraction_completed_at IS NOT NULL;

-- Create index for searching transcripts
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_transcript_search
  ON video_call_sessions USING gin(to_tsvector('english', transcript))
  WHERE transcript IS NOT NULL;
