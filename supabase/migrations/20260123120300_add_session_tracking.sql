-- HIPAA 164.312(a)(2)(iii): Session Timeout & Authentication Controls
-- Track active sessions for 15-minute idle timeout enforcement
CREATE TABLE IF NOT EXISTS active_sessions_enhanced (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  firebase_session_token_hash VARCHAR(64),
  session_start_at TIMESTAMPTZ DEFAULT NOW(),
  last_activity_at TIMESTAMPTZ DEFAULT NOW(),
  ip_address INET,
  user_agent TEXT,
  device_type VARCHAR(50), -- 'web', 'ios', 'android'
  ended_at TIMESTAMPTZ,
  end_reason VARCHAR(100), -- 'user_logout', 'timeout_idle', 'timeout_max_duration', 'security_incident'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_active_session UNIQUE(user_id, firebase_session_token_hash, session_start_at)
);

-- Indexes for efficient lookups
CREATE INDEX IF NOT EXISTS idx_active_sessions_user_id
  ON active_sessions_enhanced(user_id, ended_at)
  WHERE ended_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_active_sessions_ip_address
  ON active_sessions_enhanced(ip_address);

CREATE INDEX IF NOT EXISTS idx_active_sessions_last_activity
  ON active_sessions_enhanced(last_activity_at DESC)
  WHERE ended_at IS NULL;

-- RLS: Users can view their own sessions, admins can view all
ALTER TABLE active_sessions_enhanced ENABLE ROW LEVEL SECURITY;

-- Users can view their own sessions
CREATE POLICY "Users view own sessions" ON active_sessions_enhanced
FOR SELECT TO authenticated USING (
  user_id = (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
  OR EXISTS (
    SELECT 1 FROM system_admin_profiles sap
    JOIN users u ON sap.user_id = u.id
    WHERE u.firebase_uid = auth.uid()::text
  )
);

-- Service role can insert sessions
CREATE POLICY "Service role can manage sessions" ON active_sessions_enhanced
FOR ALL TO service_role USING (true);

-- Auto-update last_activity_at on session access
CREATE OR REPLACE FUNCTION update_session_activity()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_activity_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Cleanup expired sessions (>8 hours old or idle >15 minutes)
DROP FUNCTION IF EXISTS cleanup_expired_sessions() CASCADE;
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS void AS $$
BEGIN
  -- Mark sessions as timed out if idle for >15 minutes
  UPDATE active_sessions_enhanced
  SET
    ended_at = NOW(),
    end_reason = 'timeout_idle'
  WHERE
    ended_at IS NULL
    AND last_activity_at < NOW() - INTERVAL '15 minutes';

  -- Mark sessions as timed out if >8 hours old
  UPDATE active_sessions_enhanced
  SET
    ended_at = NOW(),
    end_reason = 'timeout_max_duration'
  WHERE
    ended_at IS NULL
    AND session_start_at < NOW() - INTERVAL '8 hours';

  -- Delete old ended sessions (>30 days)
  DELETE FROM active_sessions_enhanced
  WHERE ended_at IS NOT NULL AND ended_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Schedule cleanup to run every 5 minutes
SELECT cron.schedule(
  'cleanup-sessions-frequent',
  '*/5 * * * *',
  'SELECT cleanup_expired_sessions()'
);

-- View for active sessions summary
CREATE OR REPLACE VIEW active_sessions_summary AS
SELECT
  u.id,
  u.email,
  COUNT(*) AS active_session_count,
  MIN(ase.session_start_at) AS oldest_session_start,
  MAX(ase.last_activity_at) AS most_recent_activity,
  array_agg(DISTINCT ase.device_type) AS device_types,
  array_agg(DISTINCT ase.ip_address::text) AS ip_addresses
FROM users u
LEFT JOIN active_sessions_enhanced ase ON u.id = ase.user_id
  AND ase.ended_at IS NULL
GROUP BY u.id, u.email
ORDER BY u.email;
