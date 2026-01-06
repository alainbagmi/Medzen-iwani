-- Migration: Fix Transcription Cost Tracking Columns
-- Description: Adds missing columns for transcription tracking
-- Date: 2025-12-29
-- Note: Previous migration (20251228140000) partially failed - this cleans it up

-- Add transcription cost tracking columns (idempotent)
DO $$
BEGIN
  -- Add columns if they don't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
    WHERE table_name = 'video_call_sessions' AND column_name = 'transcription_duration_seconds') THEN
    ALTER TABLE video_call_sessions ADD COLUMN transcription_duration_seconds INTEGER DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
    WHERE table_name = 'video_call_sessions' AND column_name = 'transcription_estimated_cost_usd') THEN
    ALTER TABLE video_call_sessions ADD COLUMN transcription_estimated_cost_usd DECIMAL(10, 4) DEFAULT 0;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
    WHERE table_name = 'video_call_sessions' AND column_name = 'transcription_max_duration_minutes') THEN
    ALTER TABLE video_call_sessions ADD COLUMN transcription_max_duration_minutes INTEGER DEFAULT 120;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
    WHERE table_name = 'video_call_sessions' AND column_name = 'transcription_auto_stopped') THEN
    ALTER TABLE video_call_sessions ADD COLUMN transcription_auto_stopped BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- Create or replace function to calculate transcription cost
CREATE OR REPLACE FUNCTION calculate_transcription_cost(duration_seconds INTEGER)
RETURNS DECIMAL(10, 4) AS $$
BEGIN
  RETURN ROUND((duration_seconds::DECIMAL / 60) * 0.0750, 4);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Create or replace trigger function to auto-calculate cost
CREATE OR REPLACE FUNCTION update_transcription_cost()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.transcription_duration_seconds IS NOT NULL AND
     (OLD.transcription_duration_seconds IS NULL OR
      NEW.transcription_duration_seconds != OLD.transcription_duration_seconds) THEN
    NEW.transcription_estimated_cost_usd := calculate_transcription_cost(NEW.transcription_duration_seconds);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate trigger
DROP TRIGGER IF EXISTS trg_update_transcription_cost ON video_call_sessions;
CREATE TRIGGER trg_update_transcription_cost
BEFORE UPDATE ON video_call_sessions
FOR EACH ROW
EXECUTE FUNCTION update_transcription_cost();

-- Create index for transcription queries
CREATE INDEX IF NOT EXISTS idx_video_call_transcription_status
ON video_call_sessions(transcription_status, live_transcription_started_at);

-- Add comment for documentation
COMMENT ON COLUMN video_call_sessions.transcription_max_duration_minutes IS 'Maximum allowed transcription duration in minutes (default 120)';
COMMENT ON COLUMN video_call_sessions.transcription_auto_stopped IS 'True if transcription was automatically stopped due to duration limit';
