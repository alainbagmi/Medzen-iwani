-- Migration: Create call_transcripts table for storing finalized video call transcripts
-- Description: Stores merged and finalized transcripts from video calls, including speaker mapping and metadata

-- =====================================================
-- Create call_transcripts table
-- =====================================================
CREATE TABLE IF NOT EXISTS call_transcripts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES video_call_sessions(id) ON DELETE CASCADE,
  appointment_id UUID NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
  meeting_id VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL DEFAULT 'live_merged', -- live_merged, post_call, hybrid
  source VARCHAR(50) NOT NULL DEFAULT 'chime_live', -- chime_live, transcribe_medical, hybrid
  raw_text TEXT, -- Full merged transcript text
  speaker_map JSONB, -- Array of {speaker, text, timestamp} objects
  total_segments INTEGER DEFAULT 0, -- Count of live caption segments merged
  processing_status VARCHAR(50) DEFAULT 'completed', -- completed, failed, pending
  language_code VARCHAR(10) DEFAULT 'en-US',
  confidence FLOAT, -- Average confidence score from segments
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  duration_seconds INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment for documentation
COMMENT ON TABLE call_transcripts IS 'Stores finalized transcripts from video calls, merged from live captions or post-call transcription jobs';

-- =====================================================
-- Create indexes for efficient queries
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_call_transcripts_session_id
  ON call_transcripts(session_id);

CREATE INDEX IF NOT EXISTS idx_call_transcripts_appointment_id
  ON call_transcripts(appointment_id);

CREATE INDEX IF NOT EXISTS idx_call_transcripts_created_at
  ON call_transcripts(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_call_transcripts_processing_status
  ON call_transcripts(processing_status);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_call_transcripts_session_status
  ON call_transcripts(session_id, processing_status);

-- =====================================================
-- Enable Row Level Security
-- =====================================================
ALTER TABLE call_transcripts ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "transcript_select_access" ON call_transcripts;
DROP POLICY IF EXISTS "transcript_insert_access" ON call_transcripts;
DROP POLICY IF EXISTS "transcript_update_access" ON call_transcripts;

-- RLS Policies
-- Select: Users can view transcripts for sessions they participated in
CREATE POLICY "transcript_select_access" ON call_transcripts
FOR SELECT USING (
  auth.uid() IS NULL OR
  session_id IN (
    SELECT id FROM video_call_sessions
    WHERE provider_id = auth.uid() OR patient_id = auth.uid()
  )
);

-- Insert: Only service role can insert (called from edge functions)
CREATE POLICY "transcript_insert_access" ON call_transcripts
FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- Update: Only service role can update
CREATE POLICY "transcript_update_access" ON call_transcripts
FOR UPDATE USING (auth.role() = 'service_role');

-- =====================================================
-- Grant permissions
-- =====================================================
GRANT SELECT ON call_transcripts TO anon;
GRANT SELECT ON call_transcripts TO authenticated;
GRANT ALL ON call_transcripts TO service_role;
