-- Fix migration: Apply the remaining parts of transcription cost tracking
-- The previous migration failed at the RLS policy due to users.role not existing

-- Create table for daily transcription usage tracking (may already exist, so use IF NOT EXISTS)
CREATE TABLE IF NOT EXISTS transcription_usage_daily (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usage_date DATE NOT NULL UNIQUE,
  total_sessions INTEGER DEFAULT 0,
  total_duration_seconds INTEGER DEFAULT 0,
  total_cost_usd DECIMAL(10, 4) DEFAULT 0,
  successful_transcriptions INTEGER DEFAULT 0,
  failed_transcriptions INTEGER DEFAULT 0,
  timeout_transcriptions INTEGER DEFAULT 0,
  avg_duration_seconds INTEGER DEFAULT 0,
  max_duration_seconds INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on usage tracking table
ALTER TABLE transcription_usage_daily ENABLE ROW LEVEL SECURITY;

-- Drop old policy if exists and create new one with correct role check
DROP POLICY IF EXISTS "admins_can_view_usage" ON transcription_usage_daily;

-- Only admins can view usage data - using profile tables instead of users.role
CREATE POLICY "admins_can_view_usage" ON transcription_usage_daily
FOR SELECT USING (
  auth.uid() IS NULL -- Service role access (for Firebase auth pattern)
  OR EXISTS (
    SELECT 1 FROM system_admin_profiles WHERE user_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM facility_admin_profiles WHERE user_id = auth.uid()
  )
);

-- Create function to update daily usage stats
CREATE OR REPLACE FUNCTION update_daily_transcription_stats()
RETURNS TRIGGER AS $$
DECLARE
  today DATE := CURRENT_DATE;
BEGIN
  -- Only process when transcription status changes to terminal state
  IF NEW.transcription_status IN ('COMPLETED', 'FAILED', 'timeout') AND
     (OLD.transcription_status IS NULL OR OLD.transcription_status = 'in_progress') THEN

    INSERT INTO transcription_usage_daily (
      usage_date,
      total_sessions,
      total_duration_seconds,
      total_cost_usd,
      successful_transcriptions,
      failed_transcriptions,
      timeout_transcriptions
    ) VALUES (
      today,
      1,
      COALESCE(NEW.transcription_duration_seconds, 0),
      COALESCE(NEW.transcription_estimated_cost_usd, 0),
      CASE WHEN NEW.transcription_status = 'COMPLETED' THEN 1 ELSE 0 END,
      CASE WHEN NEW.transcription_status = 'FAILED' THEN 1 ELSE 0 END,
      CASE WHEN NEW.transcription_status = 'timeout' THEN 1 ELSE 0 END
    )
    ON CONFLICT (usage_date) DO UPDATE SET
      total_sessions = transcription_usage_daily.total_sessions + 1,
      total_duration_seconds = transcription_usage_daily.total_duration_seconds + COALESCE(NEW.transcription_duration_seconds, 0),
      total_cost_usd = transcription_usage_daily.total_cost_usd + COALESCE(NEW.transcription_estimated_cost_usd, 0),
      successful_transcriptions = transcription_usage_daily.successful_transcriptions +
        CASE WHEN NEW.transcription_status = 'COMPLETED' THEN 1 ELSE 0 END,
      failed_transcriptions = transcription_usage_daily.failed_transcriptions +
        CASE WHEN NEW.transcription_status = 'FAILED' THEN 1 ELSE 0 END,
      timeout_transcriptions = transcription_usage_daily.timeout_transcriptions +
        CASE WHEN NEW.transcription_status = 'timeout' THEN 1 ELSE 0 END,
      updated_at = NOW();

    -- Update averages
    UPDATE transcription_usage_daily
    SET avg_duration_seconds = total_duration_seconds / NULLIF(total_sessions, 0),
        max_duration_seconds = GREATEST(max_duration_seconds, COALESCE(NEW.transcription_duration_seconds, 0))
    WHERE usage_date = today;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_daily_transcription_stats ON video_call_sessions;
CREATE TRIGGER trg_update_daily_transcription_stats
AFTER UPDATE ON video_call_sessions
FOR EACH ROW
EXECUTE FUNCTION update_daily_transcription_stats();

-- Create view for transcription analytics
CREATE OR REPLACE VIEW transcription_analytics AS
SELECT
  usage_date,
  total_sessions,
  successful_transcriptions,
  failed_transcriptions,
  timeout_transcriptions,
  ROUND(total_duration_seconds / 60.0, 2) as total_duration_minutes,
  ROUND(avg_duration_seconds / 60.0, 2) as avg_duration_minutes,
  ROUND(max_duration_seconds / 60.0, 2) as max_duration_minutes,
  total_cost_usd,
  CASE WHEN total_sessions > 0
    THEN ROUND(100.0 * successful_transcriptions / total_sessions, 1)
    ELSE 0
  END as success_rate_percent,
  CASE WHEN total_sessions > 0
    THEN ROUND(100.0 * timeout_transcriptions / total_sessions, 1)
    ELSE 0
  END as timeout_rate_percent
FROM transcription_usage_daily
ORDER BY usage_date DESC;

-- Create index for efficient date queries
CREATE INDEX IF NOT EXISTS idx_transcription_usage_date ON transcription_usage_daily(usage_date DESC);

-- Create index on video_call_sessions for transcription queries
CREATE INDEX IF NOT EXISTS idx_video_call_transcription_status
ON video_call_sessions(transcription_status, live_transcription_started_at);

-- Grant select on view
GRANT SELECT ON transcription_analytics TO authenticated, anon;

-- Add comment for documentation
COMMENT ON TABLE transcription_usage_daily IS 'Daily aggregated transcription usage for cost tracking and monitoring';
