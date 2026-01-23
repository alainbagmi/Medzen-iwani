-- HIPAA/GDPR: Rate limiting table to prevent API abuse and DDoS attacks
CREATE TABLE IF NOT EXISTS rate_limit_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  identifier VARCHAR(255) NOT NULL, -- user_id, firebase_uid, or IP address
  endpoint VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient lookups
CREATE INDEX IF NOT EXISTS idx_rate_limit_identifier_created_at
  ON rate_limit_tracking(identifier, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_rate_limit_endpoint
  ON rate_limit_tracking(endpoint, created_at DESC);

-- No RLS - service role only manages rate limits
ALTER TABLE rate_limit_tracking DISABLE ROW LEVEL SECURITY;
