-- Migration: Create video_call_audit_log table for audit trail
-- Description: Creates audit log table for tracking video call events (transcription, recordings, etc.)

-- =====================================================
-- Create video_call_audit_log table
-- =====================================================
CREATE TABLE IF NOT EXISTS video_call_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES video_call_sessions(id) ON DELETE CASCADE,
  event_type VARCHAR(100) NOT NULL,
  event_data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add comment for documentation
COMMENT ON TABLE video_call_audit_log IS 'Audit trail for video call events including transcription lifecycle, recordings, and system events';

-- =====================================================
-- Create indexes for efficient queries
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_video_call_audit_session_id
  ON video_call_audit_log(session_id);

CREATE INDEX IF NOT EXISTS idx_video_call_audit_event_type
  ON video_call_audit_log(event_type);

CREATE INDEX IF NOT EXISTS idx_video_call_audit_created_at
  ON video_call_audit_log(created_at DESC);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_video_call_audit_session_event
  ON video_call_audit_log(session_id, event_type);

-- =====================================================
-- Enable Row Level Security
-- =====================================================
ALTER TABLE video_call_audit_log ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for idempotency)
DROP POLICY IF EXISTS "Service role has full access to video_call_audit_log" ON video_call_audit_log;
DROP POLICY IF EXISTS "Users can view audit logs for their sessions" ON video_call_audit_log;

-- RLS Policies
-- Service role can do anything
CREATE POLICY "Service role has full access to video_call_audit_log" ON video_call_audit_log
FOR ALL USING (auth.role() = 'service_role');

-- Users can view audit logs for sessions they participated in
CREATE POLICY "Users can view audit logs for their sessions" ON video_call_audit_log
FOR SELECT USING (
  auth.uid() IS NULL OR
  session_id IN (
    SELECT id FROM video_call_sessions
    WHERE provider_id = auth.uid() OR patient_id = auth.uid()
  )
);

-- =====================================================
-- Grant permissions
-- =====================================================
GRANT SELECT ON video_call_audit_log TO anon;
GRANT SELECT ON video_call_audit_log TO authenticated;
GRANT ALL ON video_call_audit_log TO service_role;
