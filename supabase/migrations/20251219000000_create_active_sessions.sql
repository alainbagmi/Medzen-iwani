-- Migration: Create active_sessions table for session timeout and single-device enforcement
-- Created: 2025-12-19
-- Purpose: Track user sessions, enforce 5-minute inactivity timeout, prevent concurrent device logins

-- Create active_sessions table
CREATE TABLE IF NOT EXISTS active_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  device_name TEXT,
  device_platform TEXT,
  ip_address TEXT,
  firebase_uid TEXT NOT NULL,
  session_token TEXT NOT NULL UNIQUE,
  last_activity_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  is_video_call_active BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE(user_id, device_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_active_sessions_user ON active_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_active_sessions_token ON active_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_active_sessions_firebase ON active_sessions(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_active_sessions_active ON active_sessions(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_active_sessions_expires ON active_sessions(expires_at);

-- Enable Row Level Security
ALTER TABLE active_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Users can view their own sessions
CREATE POLICY "Users can view own sessions" ON active_sessions
  FOR SELECT
  USING (firebase_uid = current_setting('request.jwt.claims', true)::json->>'sub');

-- Users can create sessions for themselves
CREATE POLICY "Users can create own sessions" ON active_sessions
  FOR INSERT
  WITH CHECK (firebase_uid = current_setting('request.jwt.claims', true)::json->>'sub');

-- Users can update their own sessions
CREATE POLICY "Users can update own sessions" ON active_sessions
  FOR UPDATE
  USING (firebase_uid = current_setting('request.jwt.claims', true)::json->>'sub');

-- Users can delete their own sessions
CREATE POLICY "Users can delete own sessions" ON active_sessions
  FOR DELETE
  USING (firebase_uid = current_setting('request.jwt.claims', true)::json->>'sub');

-- Service role can access all sessions (for cleanup jobs)
CREATE POLICY "Service role full access" ON active_sessions
  FOR ALL
  USING (current_setting('request.jwt.claims', true)::json->>'role' = 'service_role');

-- Function to invalidate other sessions when creating a new one (single-device enforcement)
CREATE OR REPLACE FUNCTION invalidate_other_sessions()
RETURNS TRIGGER AS $$
BEGIN
  -- Deactivate all other sessions for this user
  UPDATE active_sessions
  SET is_active = FALSE
  WHERE user_id = NEW.user_id
    AND id != NEW.id
    AND is_active = TRUE;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to enforce single-device login
DROP TRIGGER IF EXISTS trigger_invalidate_other_sessions ON active_sessions;
CREATE TRIGGER trigger_invalidate_other_sessions
  AFTER INSERT ON active_sessions
  FOR EACH ROW
  EXECUTE FUNCTION invalidate_other_sessions();

-- Function to check session expiry (can be called by scheduled job)
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- Delete sessions that have expired
  DELETE FROM active_sessions
  WHERE expires_at < NOW()
    OR (last_activity_at < NOW() - INTERVAL '5 minutes' AND is_video_call_active = FALSE);

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get remaining session time in seconds
CREATE OR REPLACE FUNCTION get_session_remaining_seconds(p_session_token TEXT)
RETURNS INTEGER AS $$
DECLARE
  remaining_seconds INTEGER;
  session_record RECORD;
BEGIN
  SELECT * INTO session_record
  FROM active_sessions
  WHERE session_token = p_session_token
    AND is_active = TRUE;

  IF NOT FOUND THEN
    RETURN -1; -- Session not found or inactive
  END IF;

  -- If video call is active, return a large number (session extended)
  IF session_record.is_video_call_active THEN
    RETURN 3600; -- 1 hour max during video calls
  END IF;

  -- Calculate seconds remaining (5 minute timeout)
  remaining_seconds := EXTRACT(EPOCH FROM (session_record.last_activity_at + INTERVAL '5 minutes' - NOW()))::INTEGER;

  IF remaining_seconds < 0 THEN
    RETURN 0;
  END IF;

  RETURN remaining_seconds;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION cleanup_expired_sessions() TO service_role;
GRANT EXECUTE ON FUNCTION get_session_remaining_seconds(TEXT) TO authenticated;

-- Add comment for documentation
COMMENT ON TABLE active_sessions IS 'Tracks active user sessions for timeout enforcement and single-device login policy';
COMMENT ON COLUMN active_sessions.is_video_call_active IS 'When true, session timeout is paused (extended during video calls)';
COMMENT ON COLUMN active_sessions.session_token IS 'Unique token stored client-side to identify this session';
