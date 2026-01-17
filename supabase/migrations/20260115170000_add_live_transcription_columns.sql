-- Add live transcription columns to video_call_sessions
-- These columns are required by the start-medical-transcription edge function
-- Deployed: 2026-01-15

-- Add the remaining columns needed for live transcription tracking
ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS live_transcription_started_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS transcription_status TEXT DEFAULT 'pending' CHECK (transcription_status IN ('pending', 'in_progress', 'completed', 'failed', 'stopped')),
ADD COLUMN IF NOT EXISTS transcription_max_duration_minutes INTEGER DEFAULT 60,
ADD COLUMN IF NOT EXISTS transcription_estimated_cost_usd DECIMAL(10,4) DEFAULT 0,
ADD COLUMN IF NOT EXISTS transcription_auto_stopped BOOLEAN DEFAULT FALSE;

-- Create index for efficient queries on transcription status
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_transcription_status
ON video_call_sessions(transcription_status);

-- Log migration completion
DO $$
BEGIN
  RAISE NOTICE 'Live Transcription Columns Migration Complete';
  RAISE NOTICE '  ✓ live_transcription_started_at';
  RAISE NOTICE '  ✓ transcription_status';
  RAISE NOTICE '  ✓ transcription_max_duration_minutes';
  RAISE NOTICE '  ✓ transcription_estimated_cost_usd';
  RAISE NOTICE '  ✓ transcription_auto_stopped';
END $$;
