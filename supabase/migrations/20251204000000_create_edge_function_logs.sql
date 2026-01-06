-- Create edge_function_logs table for persistent logging
-- This allows server-side log storage for debugging Supabase Edge Functions

CREATE TABLE IF NOT EXISTS edge_function_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  function_name TEXT NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  level TEXT NOT NULL CHECK (level IN ('info', 'error', 'debug', 'warning')),
  message TEXT,
  metadata JSONB,
  user_id TEXT,
  firebase_uid TEXT,
  request_id TEXT,
  status_code INTEGER,
  error_details TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on function_name for faster queries
CREATE INDEX idx_edge_function_logs_function_name ON edge_function_logs(function_name);

-- Create index on timestamp for time-based queries
CREATE INDEX idx_edge_function_logs_timestamp ON edge_function_logs(timestamp DESC);

-- Create index on level for filtering by severity
CREATE INDEX idx_edge_function_logs_level ON edge_function_logs(level);

-- Create composite index for common queries (function + time + level)
CREATE INDEX idx_edge_function_logs_function_time_level
ON edge_function_logs(function_name, timestamp DESC, level);

-- Enable RLS (Row Level Security)
ALTER TABLE edge_function_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Service role can do anything (for Edge Functions to write logs)
CREATE POLICY "Service role has full access to edge_function_logs"
ON edge_function_logs
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Policy: Authenticated users can read all logs (for debugging)
CREATE POLICY "Authenticated users can read edge_function_logs"
ON edge_function_logs
FOR SELECT
TO authenticated
USING (true);

-- Create function to clean up old logs (older than 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_edge_function_logs()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM edge_function_logs
  WHERE timestamp < NOW() - INTERVAL '30 days';
END;
$$;

-- Add comment to table
COMMENT ON TABLE edge_function_logs IS 'Persistent logs for Supabase Edge Functions, especially for debugging authentication issues';
