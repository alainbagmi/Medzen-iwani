-- Migration: Implement Appointment-Based Chat with Provider-Only Initiation
-- Date: December 18, 2025
-- Purpose:
--   1. Add provider_role to appointment_overview
--   2. Add call status tracking to video_call_sessions
--   3. Implement chat restrictions (provider-only initiation, call-active only)
--   4. Update chat to be appointment-based instead of person-based

-- =====================================================
-- PART 1: Add provider_role to appointment_overview
-- =====================================================

-- Check if appointment_overview is a view or table and add provider_role
-- This assumes it might be a view that needs to be recreated

-- Drop existing view if it exists
DROP VIEW IF EXISTS appointment_overview CASCADE;

-- Recreate appointment_overview with provider_role field
CREATE OR REPLACE VIEW appointment_overview AS
SELECT
    a.id AS appointment_id,
    a.patient_id,
    a.provider_id,
    a.facility_id,
    a.start_date AS appointment_start_date,
    a.start_time AS appointment_start_time,
    a.status AS appointment_status,
    a.consultation_mode,
    a.notes,

    -- Patient information
    u_patient.full_name AS patient_fullname,
    u_patient.profile_picture_url AS patient_image_url,

    -- Provider information
    u_provider.full_name AS provider_fullname,
    u_provider.profile_picture_url AS provider_image_url,
    mpp.professional_role AS provider_role,              -- NEW: Provider role (Doctor, Nurse, etc.)
    mpp.primary_specialization AS provider_specialty,     -- Keep for backward compatibility

    -- Facility information
    f.facility_name AS facility_name,
    f.address AS facility_address,
    f.image_url AS facility_image_url
FROM
    appointments a
    LEFT JOIN users u_patient ON a.patient_id = u_patient.id
    LEFT JOIN users u_provider ON a.provider_id = u_provider.id
    LEFT JOIN medical_provider_profiles mpp ON a.provider_id = mpp.user_id
    LEFT JOIN facilities f ON a.facility_id = f.id;

-- Grant permissions
GRANT SELECT ON appointment_overview TO authenticated;
GRANT SELECT ON appointment_overview TO anon;

COMMENT ON VIEW appointment_overview IS 'Comprehensive view of appointments with patient, provider, and facility details. Includes provider_role for display instead of specialty.';

-- =====================================================
-- PART 2: Add call status tracking
-- =====================================================

-- Add is_call_active column to video_call_sessions to track if call is currently active
ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS is_call_active BOOLEAN DEFAULT TRUE;

-- Add ended_at timestamp to track when call ended
ALTER TABLE video_call_sessions
ADD COLUMN IF NOT EXISTS ended_at TIMESTAMPTZ;

COMMENT ON COLUMN video_call_sessions.is_call_active IS 'TRUE while call is active, FALSE after call ends. Chat becomes read-only when FALSE.';
COMMENT ON COLUMN video_call_sessions.ended_at IS 'Timestamp when call ended. Used to determine if chat should be read-only.';

-- =====================================================
-- PART 3: Update chime_messages for appointment-based chat
-- =====================================================

-- Add appointment_id to chime_messages to link messages to specific appointments
ALTER TABLE chime_messages
ADD COLUMN IF NOT EXISTS appointment_id UUID REFERENCES appointments(id) ON DELETE CASCADE;

-- Create index for faster appointment-based queries
CREATE INDEX IF NOT EXISTS idx_chime_messages_appointment_id
ON chime_messages(appointment_id);

COMMENT ON COLUMN chime_messages.appointment_id IS 'Links message to specific appointment. All messages for an appointment create a chat history.';

-- =====================================================
-- PART 4: RLS Policies for Provider-Only Chat Initiation
-- =====================================================

-- Drop existing chime_messages policies that might conflict
DROP POLICY IF EXISTS "Users can insert their own messages" ON chime_messages;
DROP POLICY IF EXISTS "Users can insert messages in their channels" ON chime_messages;
DROP POLICY IF EXISTS "Allow message inserts during active calls" ON chime_messages;

-- NEW POLICY: Only providers can send messages (patients cannot initiate or send)
CREATE POLICY "Only providers can send messages during active calls"
ON chime_messages
FOR INSERT
TO authenticated
WITH CHECK (
    -- Check 1: User must be the provider in the appointment
    EXISTS (
        SELECT 1 FROM appointments a
        WHERE a.id = appointment_id
        AND a.provider_id = auth.uid()
    )
    AND
    -- Check 2: Call must be active (not ended)
    EXISTS (
        SELECT 1 FROM video_call_sessions vcs
        WHERE vcs.appointment_id = chime_messages.appointment_id
        AND vcs.is_call_active = TRUE
    )
);

-- Policy: Users can view messages from their own appointments
DROP POLICY IF EXISTS "Users can view messages from their appointments" ON chime_messages;
CREATE POLICY "Users can view messages from their appointments"
ON chime_messages
FOR SELECT
TO authenticated
USING (
    -- User is either the patient or provider in the appointment
    EXISTS (
        SELECT 1 FROM appointments a
        WHERE a.id = appointment_id
        AND (a.patient_id = auth.uid() OR a.provider_id = auth.uid())
    )
);

-- =====================================================
-- PART 5: Helper Functions for Chat Restrictions
-- =====================================================

-- Function to check if user is provider in appointment
CREATE OR REPLACE FUNCTION is_provider_in_appointment(p_appointment_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM appointments
        WHERE id = p_appointment_id
        AND provider_id = auth.uid()
    );
END;
$$;

-- Function to check if call is active
CREATE OR REPLACE FUNCTION is_call_active_for_appointment(p_appointment_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM video_call_sessions
        WHERE appointment_id = p_appointment_id
        AND is_call_active = TRUE
    );
END;
$$;

-- Function to end call and make chat read-only
CREATE OR REPLACE FUNCTION end_video_call(p_appointment_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only provider can end the call
    IF NOT is_provider_in_appointment(p_appointment_id) THEN
        RAISE EXCEPTION 'Only providers can end calls';
    END IF;

    -- Update video_call_sessions
    UPDATE video_call_sessions
    SET
        is_call_active = FALSE,
        ended_at = NOW()
    WHERE
        appointment_id = p_appointment_id
        AND is_call_active = TRUE;
END;
$$;

COMMENT ON FUNCTION is_provider_in_appointment IS 'Check if current user is the provider in an appointment';
COMMENT ON FUNCTION is_call_active_for_appointment IS 'Check if video call is currently active for an appointment';
COMMENT ON FUNCTION end_video_call IS 'End video call and make chat read-only. Only callable by provider.';

-- =====================================================
-- PART 6: Update video_call_sessions trigger
-- =====================================================

-- Automatically set is_call_active to TRUE when session is created
CREATE OR REPLACE FUNCTION set_call_active_on_create()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.is_call_active := TRUE;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_set_call_active ON video_call_sessions;
CREATE TRIGGER trigger_set_call_active
BEFORE INSERT ON video_call_sessions
FOR EACH ROW
EXECUTE FUNCTION set_call_active_on_create();

-- =====================================================
-- PART 7: Grant Permissions
-- =====================================================

GRANT EXECUTE ON FUNCTION is_provider_in_appointment TO authenticated;
GRANT EXECUTE ON FUNCTION is_call_active_for_appointment TO authenticated;
GRANT EXECUTE ON FUNCTION end_video_call TO authenticated;

-- =====================================================
-- Migration Complete
-- =====================================================

-- Verification queries (commented out for production):
-- SELECT * FROM appointment_overview LIMIT 5;
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'video_call_sessions';
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'chime_messages';
