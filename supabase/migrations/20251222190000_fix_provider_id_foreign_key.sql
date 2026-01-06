-- Migration: Fix appointments.provider_id Foreign Key
-- Date: December 22, 2025
-- Purpose: Change provider_id FK from users(id) to medical_provider_profiles(id)
--
-- IMPORTANT: This is a schema correction. The provider_id should reference
-- medical_provider_profiles.id, not users.id. The medical_provider_profiles
-- table contains the provider-specific data and has a user_id FK to users.

-- =====================================================
-- PART 1: Drop existing incorrect FK constraint
-- =====================================================

-- Drop any existing FK constraint on provider_id (may reference users)
DO $$
DECLARE
    constraint_name text;
BEGIN
    -- Find the FK constraint name for provider_id column
    SELECT tc.constraint_name INTO constraint_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
    WHERE tc.table_name = 'appointments'
        AND tc.table_schema = 'public'
        AND tc.constraint_type = 'FOREIGN KEY'
        AND kcu.column_name = 'provider_id';

    -- If constraint exists, drop it
    IF constraint_name IS NOT NULL THEN
        EXECUTE format('ALTER TABLE public.appointments DROP CONSTRAINT %I', constraint_name);
        RAISE NOTICE 'Dropped FK constraint: %', constraint_name;
    ELSE
        RAISE NOTICE 'No existing FK constraint found on provider_id';
    END IF;
END $$;

-- =====================================================
-- PART 2: Verify data integrity before adding new FK
-- =====================================================

-- First, update any provider_id values that might be user IDs to corresponding medical_provider_profile IDs
-- This handles cases where provider_id was incorrectly storing user.id instead of medical_provider_profiles.id
DO $$
DECLARE
    updated_count integer;
BEGIN
    -- Update appointments where provider_id matches a user_id in medical_provider_profiles
    -- (meaning it was incorrectly set to the user ID instead of the provider profile ID)
    UPDATE appointments a
    SET provider_id = mpp.id
    FROM medical_provider_profiles mpp
    WHERE a.provider_id = mpp.user_id
    AND NOT EXISTS (
        SELECT 1 FROM medical_provider_profiles
        WHERE id = a.provider_id
    );

    GET DIAGNOSTICS updated_count = ROW_COUNT;

    IF updated_count > 0 THEN
        RAISE NOTICE 'Corrected % appointments with user_id as provider_id', updated_count;
    ELSE
        RAISE NOTICE 'No appointments needed provider_id correction';
    END IF;
END $$;

-- Set provider_id to NULL where it doesn't match any medical_provider_profile
-- (orphaned records that can't be mapped)
DO $$
DECLARE
    nullified_count integer;
BEGIN
    UPDATE appointments
    SET provider_id = NULL
    WHERE provider_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM medical_provider_profiles
        WHERE id = appointments.provider_id
    );

    GET DIAGNOSTICS nullified_count = ROW_COUNT;

    IF nullified_count > 0 THEN
        RAISE WARNING 'Set % orphaned provider_id values to NULL', nullified_count;
    END IF;
END $$;

-- =====================================================
-- PART 3: Add correct FK constraint
-- =====================================================

-- Add FK constraint referencing medical_provider_profiles(id)
ALTER TABLE public.appointments
ADD CONSTRAINT appointments_provider_id_fkey
FOREIGN KEY (provider_id)
REFERENCES public.medical_provider_profiles(id)
ON UPDATE CASCADE
ON DELETE SET NULL;

-- Create index for better join performance
CREATE INDEX IF NOT EXISTS idx_appointments_provider_id
ON public.appointments (provider_id);

-- =====================================================
-- PART 4: Update appointment_overview view
-- =====================================================

-- Drop and recreate the view with correct join logic
DROP VIEW IF EXISTS appointment_overview CASCADE;

CREATE OR REPLACE VIEW appointment_overview AS
SELECT
    a.id AS appointment_id,
    a.id,  -- Keep both for backwards compatibility
    a.appointment_number,
    a.patient_id,
    a.provider_id,  -- Now references medical_provider_profiles.id
    a.facility_id,
    a.scheduled_start,
    a.scheduled_end,
    a.start_date AS appointment_start_date,
    a.start_time AS appointment_start_time,
    a.status AS appointment_status,
    a.status,  -- Keep both for backwards compatibility
    a.consultation_mode,
    a.appointment_type,
    a.specialty,
    a.chief_complaint,
    a.notes,
    a.video_enabled,
    a.video_call_id,
    a.video_call_status,
    a.video_call_url,
    a.provider_joined_at,
    a.patient_joined_at,
    a.created_at,
    a.updated_at,

    -- Patient information (from users table via patient_id)
    u_patient.id AS patient_user_id,
    u_patient.first_name AS patient_first_name,
    u_patient.last_name AS patient_last_name,
    COALESCE(u_patient.full_name, TRIM(COALESCE(u_patient.first_name, '') || ' ' || COALESCE(u_patient.last_name, ''))) AS patient_fullname,
    u_patient.full_name AS patient_full_name,
    COALESCE(u_patient.avatar_url, u_patient.profile_picture_url) AS patient_image_url,
    u_patient.email AS patient_email,
    u_patient.phone_number AS patient_phone,

    -- Provider information (from medical_provider_profiles and users)
    mpp.id AS provider_profile_id,
    mpp.user_id AS provider_user_id,
    u_provider.first_name AS provider_first_name,
    u_provider.last_name AS provider_last_name,
    COALESCE(u_provider.full_name, TRIM(COALESCE(u_provider.first_name, '') || ' ' || COALESCE(u_provider.last_name, ''))) AS provider_fullname,
    u_provider.full_name AS provider_full_name,
    COALESCE(u_provider.avatar_url, u_provider.profile_picture_url, mpp.avatar_url) AS provider_image_url,
    u_provider.email AS provider_email,
    u_provider.phone_number AS provider_phone,
    mpp.professional_role AS provider_role,
    mpp.primary_specialization AS provider_specialty,
    mpp.consultation_fee,
    mpp.consultation_duration_minutes,

    -- Facility information
    f.id AS facility_record_id,
    f.facility_name,
    f.address AS facility_address,
    f.image_url AS facility_image_url,
    f.phone_number AS facility_phone

FROM appointments a
-- Patient: appointments.patient_id -> users.id
LEFT JOIN users u_patient ON a.patient_id = u_patient.id
-- Provider: appointments.provider_id -> medical_provider_profiles.id -> users.id
LEFT JOIN medical_provider_profiles mpp ON a.provider_id = mpp.id
LEFT JOIN users u_provider ON mpp.user_id = u_provider.id
-- Facility
LEFT JOIN facilities f ON a.facility_id = f.id;

-- Grant permissions
GRANT SELECT ON appointment_overview TO authenticated;
GRANT SELECT ON appointment_overview TO anon;

COMMENT ON VIEW appointment_overview IS 'Comprehensive view of appointments with patient, provider, and facility details. provider_id now correctly references medical_provider_profiles.id';

-- =====================================================
-- PART 5: Update RLS policies that depend on provider_id
-- =====================================================

-- Drop and recreate policies for chime_messages that reference provider_id
DROP POLICY IF EXISTS "Only providers can send messages during active calls" ON chime_messages;
DROP POLICY IF EXISTS "Users can view messages from their appointments" ON chime_messages;

-- Policy: Providers can send messages (checking via medical_provider_profiles)
CREATE POLICY "Only providers can send messages during active calls"
ON chime_messages
FOR INSERT
TO authenticated
WITH CHECK (
    -- Check 1: User must be the provider in the appointment
    -- (appointment.provider_id -> medical_provider_profiles.id, then check user_id)
    EXISTS (
        SELECT 1 FROM appointments a
        JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
        WHERE a.id = appointment_id
        AND mpp.user_id = auth.uid()
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
CREATE POLICY "Users can view messages from their appointments"
ON chime_messages
FOR SELECT
TO authenticated
USING (
    -- User is either the patient or the provider's user account
    EXISTS (
        SELECT 1 FROM appointments a
        LEFT JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
        WHERE a.id = appointment_id
        AND (
            a.patient_id = auth.uid()  -- Patient
            OR mpp.user_id = auth.uid()  -- Provider
        )
    )
);

-- =====================================================
-- PART 6: Update helper functions
-- =====================================================

-- Function to check if user is provider in appointment
CREATE OR REPLACE FUNCTION is_provider_in_appointment(p_appointment_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM appointments a
        JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
        WHERE a.id = p_appointment_id
        AND mpp.user_id = auth.uid()
    );
END;
$$;

-- =====================================================
-- PART 7: Update appointment policies if they exist
-- =====================================================

-- Update appointments SELECT policy for providers
DROP POLICY IF EXISTS "appointments_select_provider" ON appointments;
CREATE POLICY "appointments_select_provider" ON appointments
FOR SELECT
TO authenticated
USING (
    -- Provider can see their own appointments via medical_provider_profiles
    EXISTS (
        SELECT 1 FROM medical_provider_profiles mpp
        WHERE mpp.id = provider_id
        AND mpp.user_id = auth.uid()
    )
);

-- Keep patient policy (patient_id still references users.id)
DROP POLICY IF EXISTS "appointments_select_patient" ON appointments;
CREATE POLICY "appointments_select_patient" ON appointments
FOR SELECT
TO authenticated
USING (patient_id = auth.uid());

-- Allow Firebase auth users (auth.uid() IS NULL)
DROP POLICY IF EXISTS "appointments_select_firebase" ON appointments;
CREATE POLICY "appointments_select_firebase" ON appointments
FOR SELECT
TO authenticated
USING (auth.uid() IS NULL);

-- =====================================================
-- PART 8: Document the change
-- =====================================================

COMMENT ON COLUMN appointments.provider_id IS 'References medical_provider_profiles.id (NOT users.id). Use JOIN with medical_provider_profiles to get user_id.';

-- =====================================================
-- Migration Complete
-- =====================================================

-- Verification queries (run manually):
-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'appointments' AND column_name = 'provider_id';
--
-- SELECT tc.constraint_name, ccu.table_name AS foreign_table
-- FROM information_schema.table_constraints tc
-- JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
-- WHERE tc.table_name = 'appointments' AND tc.constraint_type = 'FOREIGN KEY';
