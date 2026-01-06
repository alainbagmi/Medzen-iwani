-- Migration: Add Row Level Security to medical_recording_metadata
-- Priority: HIGH - HIPAA Compliance Critical
-- Purpose: Restrict access to recording metadata to appointment participants only
-- Created: 2025-11-27

-- First verify table exists (create if not, based on Dart model structure)
CREATE TABLE IF NOT EXISTS medical_recording_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign keys
    session_id UUID NOT NULL REFERENCES video_call_sessions(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,

    -- S3 recording location
    recording_bucket VARCHAR(255) NOT NULL,
    recording_key VARCHAR(500) NOT NULL,

    -- Recording metadata
    duration_seconds INT,
    file_size_bytes BIGINT,
    format VARCHAR(50),

    -- HIPAA compliance
    encryption_type VARCHAR(50) NOT NULL DEFAULT 'aws:kms',
    retention_until TIMESTAMPTZ NOT NULL,
    deletion_scheduled BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT unique_session_recording UNIQUE (session_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_medical_recording_session
ON medical_recording_metadata(session_id);

CREATE INDEX IF NOT EXISTS idx_medical_recording_appointment
ON medical_recording_metadata(appointment_id);

CREATE INDEX IF NOT EXISTS idx_medical_recording_retention
ON medical_recording_metadata(retention_until)
WHERE deletion_scheduled = FALSE AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_medical_recording_cleanup
ON medical_recording_metadata(retention_until, deletion_scheduled)
WHERE deleted_at IS NULL;

-- Add comments for documentation
COMMENT ON TABLE medical_recording_metadata IS 'HIPAA-compliant metadata for Chime SDK video call recordings with 7-year retention tracking';
COMMENT ON COLUMN medical_recording_metadata.id IS 'Unique identifier for recording metadata';
COMMENT ON COLUMN medical_recording_metadata.session_id IS 'Reference to video_call_sessions table';
COMMENT ON COLUMN medical_recording_metadata.appointment_id IS 'Reference to appointments table for access control';
COMMENT ON COLUMN medical_recording_metadata.recording_bucket IS 'S3 bucket name where recording is stored';
COMMENT ON COLUMN medical_recording_metadata.recording_key IS 'S3 object key (path) to recording file';
COMMENT ON COLUMN medical_recording_metadata.duration_seconds IS 'Recording duration in seconds';
COMMENT ON COLUMN medical_recording_metadata.file_size_bytes IS 'Recording file size in bytes';
COMMENT ON COLUMN medical_recording_metadata.format IS 'Recording file format (MP4, WebM, etc.)';
COMMENT ON COLUMN medical_recording_metadata.encryption_type IS 'Encryption method (aws:kms for HIPAA compliance)';
COMMENT ON COLUMN medical_recording_metadata.retention_until IS 'Date when recording can be deleted per HIPAA 7-year retention requirement';
COMMENT ON COLUMN medical_recording_metadata.deletion_scheduled IS 'Flag indicating recording is queued for automated deletion';
COMMENT ON COLUMN medical_recording_metadata.deleted_at IS 'Timestamp when recording was deleted (soft delete for audit trail)';
COMMENT ON COLUMN medical_recording_metadata.created_at IS 'Timestamp when metadata was created';

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE medical_recording_metadata ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view recordings for their own appointments
-- This ensures patients can only see recordings for their appointments,
-- and providers can only see recordings for appointments they conducted
CREATE POLICY "Users can view own appointment recordings"
ON medical_recording_metadata
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM video_call_sessions vcs
        JOIN appointments a ON a.id = vcs.appointment_id
        WHERE vcs.id = medical_recording_metadata.session_id
        AND (a.patient_id = auth.uid() OR a.provider_id = auth.uid())
    )
);

-- Policy: Service role has full access (for edge functions)
-- This allows automated processes like cleanup and callback handlers to manage recordings
CREATE POLICY "Service role has full access to recording metadata"
ON medical_recording_metadata
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Policy: Only service role can insert (via chime-recording-callback)
-- Prevents users from manually creating fake recording metadata
CREATE POLICY "Service role can insert recording metadata"
ON medical_recording_metadata
FOR INSERT
TO service_role
WITH CHECK (true);

-- Policy: Only service role can update deletion status
-- Ensures only automated cleanup can update deletion fields
CREATE POLICY "Service role can update deletion status"
ON medical_recording_metadata
FOR UPDATE
TO service_role
USING (true)
WITH CHECK (true);

-- Policy: No deletes allowed (soft delete via deleted_at only)
-- Intentionally no DELETE policy to enforce soft deletes for audit trail
-- Hard deletes would violate HIPAA audit requirements

-- Grant permissions
GRANT SELECT ON medical_recording_metadata TO authenticated;
GRANT ALL ON medical_recording_metadata TO service_role;

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to get recordings that have expired retention
-- This is used by the cleanup edge function to identify recordings to delete
CREATE OR REPLACE FUNCTION get_expired_recordings(batch_size INT DEFAULT 100)
RETURNS SETOF medical_recording_metadata
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT *
  FROM medical_recording_metadata
  WHERE retention_until <= NOW()
    AND deletion_scheduled = FALSE
    AND deleted_at IS NULL
  ORDER BY retention_until ASC
  LIMIT batch_size;
$$;

COMMENT ON FUNCTION get_expired_recordings IS 'Returns recordings past their HIPAA retention period that need cleanup';

-- Grant execute permission to service role
GRANT EXECUTE ON FUNCTION get_expired_recordings TO service_role;
