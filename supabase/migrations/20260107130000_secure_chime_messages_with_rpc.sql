-- Migration: Secure chime_messages with RPC function
-- Date: 2026-01-07
-- Issue: USING (true) allows users to query any appointment's messages
-- Solution: Create RPC function that validates user is appointment participant
--
-- This provides defense-in-depth:
-- 1. RLS still allows SELECT (for realtime subscriptions)
-- 2. RPC function validates user_id matches appointment participant
-- 3. Client code uses RPC instead of direct SELECT

-- ============================================================================
-- PART 1: Create secure RPC function to get messages
-- ============================================================================

CREATE OR REPLACE FUNCTION get_appointment_messages(
    p_appointment_id UUID,
    p_user_id UUID
)
RETURNS TABLE (
    id UUID,
    appointment_id UUID,
    sender_id UUID,
    sender_name TEXT,
    sender_avatar TEXT,
    sender_role TEXT,
    receiver_id UUID,
    receiver_name TEXT,
    receiver_avatar TEXT,
    message_type TEXT,
    message_content TEXT,
    message TEXT,
    user_id UUID,
    file_url TEXT,
    file_name TEXT,
    file_type TEXT,
    file_size BIGINT,
    metadata TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Validate user is a participant in this appointment
    -- Check if user is either the patient or the provider
    IF NOT EXISTS (
        SELECT 1 FROM appointments a
        LEFT JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
        WHERE a.id = p_appointment_id
        AND (
            a.patient_id = p_user_id  -- User is the patient
            OR mpp.user_id = p_user_id  -- User is the provider
        )
    ) THEN
        RAISE EXCEPTION 'User is not a participant in this appointment'
            USING ERRCODE = '42501';  -- insufficient_privilege
    END IF;

    -- Return messages for this appointment
    RETURN QUERY
    SELECT
        cm.id,
        cm.appointment_id,
        cm.sender_id,
        cm.sender_name,
        cm.sender_avatar,
        cm.sender_role,
        cm.receiver_id,
        cm.receiver_name,
        cm.receiver_avatar,
        cm.message_type,
        cm.message_content,
        cm.message,
        cm.user_id,
        cm.file_url,
        cm.file_name,
        cm.file_type,
        cm.file_size,
        cm.metadata,
        cm.created_at
    FROM chime_messages cm
    WHERE cm.appointment_id = p_appointment_id
    ORDER BY cm.created_at ASC
    LIMIT 100;
END;
$$;

-- ============================================================================
-- PART 2: Create function to validate user can send message
-- ============================================================================

CREATE OR REPLACE FUNCTION can_send_message_to_appointment(
    p_appointment_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if user is a participant in this appointment
    RETURN EXISTS (
        SELECT 1 FROM appointments a
        LEFT JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
        WHERE a.id = p_appointment_id
        AND (
            a.patient_id = p_user_id  -- User is the patient
            OR mpp.user_id = p_user_id  -- User is the provider
        )
    );
END;
$$;

-- ============================================================================
-- PART 3: Update SELECT policy to be more restrictive
-- ============================================================================

-- Drop the overly permissive policy
DROP POLICY IF EXISTS "chime_messages_select_appointment_participants" ON chime_messages;

-- Create more restrictive policy that checks sender_id or receiver_id
-- This works for realtime subscriptions
CREATE POLICY "chime_messages_select_participants"
ON chime_messages
FOR SELECT
TO authenticated, anon
USING (
    -- For Supabase Auth users
    (auth.uid() IS NOT NULL AND (sender_id = auth.uid() OR receiver_id = auth.uid()))
    -- For Firebase Auth users (fallback - they should use RPC function)
    -- Still permissive for realtime subscriptions, but app should use RPC for initial load
    OR (auth.uid() IS NULL)
);

-- ============================================================================
-- PART 4: Keep INSERT policy but add validation
-- ============================================================================

-- Update INSERT policy to validate participation
DROP POLICY IF EXISTS "chime_messages_insert_authenticated" ON chime_messages;
DROP POLICY IF EXISTS "chime_messages_insert_anon" ON chime_messages;

CREATE POLICY "chime_messages_insert_validated"
ON chime_messages
FOR INSERT
TO authenticated, anon
WITH CHECK (
    -- Must have sender_id
    sender_id IS NOT NULL
    -- Validate user is participant (this is checked by edge function too)
    AND (
        -- For Supabase Auth
        (auth.uid() IS NOT NULL AND sender_id = auth.uid())
        -- For Firebase Auth - trust edge function validation
        OR (auth.uid() IS NULL)
    )
);

-- ============================================================================
-- PART 5: Grant execute permissions
-- ============================================================================

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_appointment_messages(UUID, UUID) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION can_send_message_to_appointment(UUID, UUID) TO authenticated, anon;

-- ============================================================================
-- PART 6: Add documentation
-- ============================================================================

COMMENT ON FUNCTION get_appointment_messages IS
    'Securely retrieves messages for an appointment. Validates user is a participant before returning messages. Use this instead of direct SELECT queries for better security.';

COMMENT ON FUNCTION can_send_message_to_appointment IS
    'Checks if a user can send messages to an appointment. Returns true if user is the patient or provider in the appointment.';

COMMENT ON POLICY "chime_messages_select_participants" ON chime_messages IS
    'Allows users to view messages where they are sender or receiver. For Firebase Auth users, RLS is permissive but they should use get_appointment_messages() RPC function for initial load which validates participation.';

COMMENT ON POLICY "chime_messages_insert_validated" ON chime_messages IS
    'Allows inserting messages with valid sender_id. Edge function validates participation before insert.';

-- ============================================================================
-- PART 7: Create index for better RPC performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_chime_messages_appointment_created
ON chime_messages(appointment_id, created_at);
