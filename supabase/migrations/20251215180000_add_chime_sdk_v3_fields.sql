-- Add fields for AWS Chime SDK v3 implementation
-- Supports recording, transcription, group calls, and messaging

-- Add transcription-related fields
ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS transcription_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS transcription_language VARCHAR(10) DEFAULT 'en-US',
ADD COLUMN IF NOT EXISTS external_meeting_id TEXT,
ADD COLUMN IF NOT EXISTS media_region TEXT,
ADD COLUMN IF NOT EXISTS media_placement JSONB,
ADD COLUMN IF NOT EXISTS ended_by UUID REFERENCES users(id);

-- Add comments for documentation
COMMENT ON COLUMN video_call_sessions.transcription_enabled IS
  'Whether medical transcription is enabled for this call';

COMMENT ON COLUMN video_call_sessions.transcription_language IS
  'Language code for transcription (e.g., en-US, es-ES, fr-FR)';

COMMENT ON COLUMN video_call_sessions.external_meeting_id IS
  'External meeting ID (usually the appointment ID)';

COMMENT ON COLUMN video_call_sessions.media_region IS
  'AWS region where media is processed (e.g., eu-central-1)';

COMMENT ON COLUMN video_call_sessions.media_placement IS
  'Chime media placement configuration (audio/video endpoints)';

COMMENT ON COLUMN video_call_sessions.ended_by IS
  'User ID of the person who ended the meeting';

-- Create index for faster lookups by external_meeting_id
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_external_meeting_id
  ON video_call_sessions(external_meeting_id);

-- Create index for transcription queries
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_transcription
  ON video_call_sessions(transcription_enabled)
  WHERE transcription_enabled = TRUE;
