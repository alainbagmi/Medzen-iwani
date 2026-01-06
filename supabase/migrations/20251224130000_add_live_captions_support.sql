-- Migration: Add Live Captions Support for Real-Time Transcription
-- Description: Adds columns and table for storing live speech-to-text captions during video calls

-- =====================================================
-- 1. Add live transcription tracking columns to video_call_sessions
-- =====================================================
ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS live_transcription_enabled BOOLEAN DEFAULT false;

ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS live_transcription_language VARCHAR(10) DEFAULT 'en-US';

ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS live_transcription_started_at TIMESTAMPTZ;

-- =====================================================
-- 2. Create table for persistent caption segments
-- =====================================================
CREATE TABLE IF NOT EXISTS live_caption_segments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES video_call_sessions(id) ON DELETE CASCADE,
  attendee_id VARCHAR(255),
  speaker_name VARCHAR(255),
  transcript_text TEXT NOT NULL,
  is_partial BOOLEAN DEFAULT false,
  language_code VARCHAR(10),
  confidence FLOAT,
  start_time_ms BIGINT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment for documentation
COMMENT ON TABLE live_caption_segments IS 'Stores real-time caption segments from AWS Transcribe during video calls';

-- =====================================================
-- 3. Create indexes for efficient queries
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_live_caption_session_created
ON live_caption_segments(session_id, created_at);

CREATE INDEX IF NOT EXISTS idx_live_caption_speaker
ON live_caption_segments(session_id, speaker_name);

-- =====================================================
-- 4. Enable Row Level Security
-- =====================================================
ALTER TABLE live_caption_segments ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if exists (for idempotency)
DROP POLICY IF EXISTS "caption_select_access" ON live_caption_segments;
DROP POLICY IF EXISTS "caption_insert_access" ON live_caption_segments;

-- RLS for Firebase auth (must allow auth.uid() IS NULL for Firebase users)
-- Select: Users can view captions for sessions they participated in
CREATE POLICY "caption_select_access" ON live_caption_segments
FOR SELECT USING (
  auth.uid() IS NULL OR
  session_id IN (
    SELECT id FROM video_call_sessions
    WHERE provider_id = auth.uid() OR patient_id = auth.uid()
  )
);

-- Insert: Allow inserts for active sessions
CREATE POLICY "caption_insert_access" ON live_caption_segments
FOR INSERT WITH CHECK (
  auth.uid() IS NULL OR
  session_id IN (
    SELECT id FROM video_call_sessions
    WHERE (provider_id = auth.uid() OR patient_id = auth.uid())
    AND status = 'active'
  )
);

-- =====================================================
-- 5. Grant permissions for service role and anon
-- =====================================================
GRANT SELECT, INSERT ON live_caption_segments TO anon;
GRANT SELECT, INSERT ON live_caption_segments TO authenticated;
GRANT ALL ON live_caption_segments TO service_role;
