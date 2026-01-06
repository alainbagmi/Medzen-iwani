-- Migration: Improve video call schema for production-grade Chime SDK implementation
-- This adds a participants table and improves the video_calls table structure
-- Based on AWS best practices for Chime SDK

-- ============================================
-- 1. Create video_call_participants table
-- ============================================
CREATE TABLE IF NOT EXISTS video_call_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  video_call_id UUID NOT NULL REFERENCES video_call_sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role VARCHAR(20) NOT NULL CHECK (role IN ('provider', 'patient', 'observer')),

  -- Chime SDK attendee information
  chime_attendee_id VARCHAR(255),
  chime_join_token TEXT,
  chime_external_user_id VARCHAR(255),

  -- Participant status and timing
  status VARCHAR(20) DEFAULT 'invited' CHECK (status IN ('invited', 'joined', 'left', 'removed', 'failed')),
  joined_at TIMESTAMPTZ,
  left_at TIMESTAMPTZ,
  duration_seconds INTEGER,

  -- Quality metrics for this participant
  quality_metrics JSONB DEFAULT '{}'::jsonb,

  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Constraints
  UNIQUE(video_call_id, user_id),
  UNIQUE(video_call_id, chime_attendee_id)
);

-- Add indexes for common queries
CREATE INDEX idx_video_call_participants_video_call_id ON video_call_participants(video_call_id);
CREATE INDEX idx_video_call_participants_user_id ON video_call_participants(user_id);
CREATE INDEX idx_video_call_participants_status ON video_call_participants(status);

-- Add comments
COMMENT ON TABLE video_call_participants IS 'Tracks individual participants in video calls with their Chime SDK attendee information';
COMMENT ON COLUMN video_call_participants.chime_attendee_id IS 'Amazon Chime SDK Attendee ID (unique per meeting)';
COMMENT ON COLUMN video_call_participants.chime_join_token IS 'Chime SDK join token for this attendee';
COMMENT ON COLUMN video_call_participants.chime_external_user_id IS 'External user identifier passed to Chime SDK';
COMMENT ON COLUMN video_call_participants.quality_metrics IS 'Call quality metrics (packet loss, latency, etc.)';

-- ============================================
-- 2. Add trigger to update updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_video_call_participants_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_video_call_participants_updated_at
  BEFORE UPDATE ON video_call_participants
  FOR EACH ROW
  EXECUTE FUNCTION update_video_call_participants_updated_at();

-- ============================================
-- 3. Improve video_call_sessions table
-- ============================================

-- Add columns if they don't exist
ALTER TABLE video_call_sessions
  ADD COLUMN IF NOT EXISTS total_participants INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS max_participants_reached INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_recording BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS recording_pipeline_id VARCHAR(255);

-- Add index for common queries
CREATE INDEX IF NOT EXISTS idx_video_call_sessions_created_by
  ON video_call_sessions(created_by);

-- Add comments
COMMENT ON COLUMN video_call_sessions.total_participants IS 'Total number of participants who joined';
COMMENT ON COLUMN video_call_sessions.max_participants_reached IS 'Maximum concurrent participants';
COMMENT ON COLUMN video_call_sessions.is_recording IS 'Whether meeting recording is active';
COMMENT ON COLUMN video_call_sessions.recording_pipeline_id IS 'Chime SDK media capture pipeline ID';

-- ============================================
-- 4. Row Level Security (RLS) Policies
-- ============================================

-- Enable RLS
ALTER TABLE video_call_participants ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view participants in their own video calls
CREATE POLICY select_own_video_call_participants ON video_call_participants
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM video_call_sessions vcs
      INNER JOIN appointments a ON vcs.appointment_id = a.id
      WHERE vcs.id = video_call_participants.video_call_id
      AND (a.provider_id = auth.uid() OR a.patient_id = auth.uid())
    )
  );

-- Policy: System/service can manage all participants
CREATE POLICY service_role_all_video_call_participants ON video_call_participants
  FOR ALL
  USING (auth.jwt() ->> 'role' = 'service_role')
  WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- ============================================
-- 5. Functions for participant management
-- ============================================

-- Function to add a participant and update meeting stats
CREATE OR REPLACE FUNCTION add_video_call_participant(
  p_video_call_id UUID,
  p_user_id UUID,
  p_role VARCHAR(20),
  p_chime_attendee_id VARCHAR(255),
  p_chime_join_token TEXT,
  p_chime_external_user_id VARCHAR(255)
)
RETURNS UUID AS $$
DECLARE
  v_participant_id UUID;
  v_current_participants INTEGER;
BEGIN
  -- Insert participant
  INSERT INTO video_call_participants (
    video_call_id,
    user_id,
    role,
    chime_attendee_id,
    chime_join_token,
    chime_external_user_id,
    status
  ) VALUES (
    p_video_call_id,
    p_user_id,
    p_role,
    p_chime_attendee_id,
    p_chime_join_token,
    p_chime_external_user_id,
    'invited'
  )
  RETURNING id INTO v_participant_id;

  -- Update total participants count
  UPDATE video_call_sessions
  SET total_participants = total_participants + 1
  WHERE id = p_video_call_id;

  RETURN v_participant_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark participant as joined
CREATE OR REPLACE FUNCTION mark_participant_joined(
  p_participant_id UUID
)
RETURNS VOID AS $$
DECLARE
  v_video_call_id UUID;
  v_current_count INTEGER;
BEGIN
  -- Update participant status
  UPDATE video_call_participants
  SET
    status = 'joined',
    joined_at = NOW()
  WHERE id = p_participant_id
  RETURNING video_call_id INTO v_video_call_id;

  -- Count current active participants
  SELECT COUNT(*) INTO v_current_count
  FROM video_call_participants
  WHERE video_call_id = v_video_call_id
  AND status = 'joined';

  -- Update max participants if needed
  UPDATE video_call_sessions
  SET max_participants_reached = GREATEST(max_participants_reached, v_current_count)
  WHERE id = v_video_call_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark participant as left
CREATE OR REPLACE FUNCTION mark_participant_left(
  p_participant_id UUID
)
RETURNS VOID AS $$
BEGIN
  UPDATE video_call_participants
  SET
    status = 'left',
    left_at = NOW(),
    duration_seconds = EXTRACT(EPOCH FROM (NOW() - joined_at))::INTEGER
  WHERE id = p_participant_id
  AND status = 'joined';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 6. View for easy participant access
-- ============================================
CREATE OR REPLACE VIEW video_call_participants_view AS
SELECT
  vcp.*,
  u.email as user_email,
  CONCAT(u.first_name, ' ', u.last_name) as user_name,
  u.profile_picture_url as user_avatar,
  vcs.appointment_id,
  vcs.status as call_status,
  vcs.meeting_id
FROM video_call_participants vcp
INNER JOIN users u ON vcp.user_id = u.id
INNER JOIN video_call_sessions vcs ON vcp.video_call_id = vcs.id;

-- Grant access to authenticated users
GRANT SELECT ON video_call_participants_view TO authenticated;

-- Add comments
COMMENT ON VIEW video_call_participants_view IS 'Comprehensive view of video call participants with user and session details';
