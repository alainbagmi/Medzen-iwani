-- Migration: Add Amazon Chime SDK columns to video_call_sessions
-- This migration adds the columns required for Chime video calls
-- Replaces the deprecated Agora video call columns

-- Add Chime-specific columns
ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS meeting_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS meeting_data JSONB,
ADD COLUMN IF NOT EXISTS external_meeting_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS media_region VARCHAR(50) DEFAULT 'us-east-1',
ADD COLUMN IF NOT EXISTS attendee_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS join_token TEXT;

-- Add index on meeting_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_meeting_id
ON video_call_sessions(meeting_id);

-- Add index on status and appointment_id for the common query pattern
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_status_appointment
ON video_call_sessions(status, appointment_id);

-- Add comments for documentation
COMMENT ON COLUMN video_call_sessions.meeting_id IS 'Amazon Chime SDK Meeting ID';
COMMENT ON COLUMN video_call_sessions.meeting_data IS 'Full meeting and attendee data from Chime SDK';
COMMENT ON COLUMN video_call_sessions.external_meeting_id IS 'External meeting ID (usually appointment_id)';
COMMENT ON COLUMN video_call_sessions.media_region IS 'AWS region for media processing';
COMMENT ON COLUMN video_call_sessions.attendee_id IS 'Chime Attendee ID for the provider';
COMMENT ON COLUMN video_call_sessions.join_token IS 'Chime join token for the provider';

-- Mark old Agora columns as deprecated (but don't remove for backwards compatibility)
COMMENT ON COLUMN video_call_sessions.agora_app_id IS 'DEPRECATED: Agora App ID - replaced by Amazon Chime';
COMMENT ON COLUMN video_call_sessions.provider_rtc_token IS 'DEPRECATED: Agora provider token - replaced by Chime join_token';
COMMENT ON COLUMN video_call_sessions.patient_rtc_token IS 'DEPRECATED: Agora patient token - replaced by Chime attendee tokens';

-- Update the status enum to include Chime-specific statuses if not already present
-- Note: This assumes status is a varchar. If it's an enum, you'd need to alter the enum type.
-- For now, we'll just ensure the column allows the new values.
