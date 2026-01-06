-- Migration: Repair FK constraint after partial failure
-- Date: December 22, 2025
-- Purpose: Complete the FK fix that partially failed due to column name issues

-- =====================================================
-- PART 1: Add FK constraint (if not exists from partial migration)
-- =====================================================

-- Check if constraint exists, if not add it
DO $$
BEGIN
    -- Only add if not already present
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'appointments_provider_id_fkey'
        AND table_name = 'appointments'
    ) THEN
        ALTER TABLE public.appointments
        ADD CONSTRAINT appointments_provider_id_fkey
        FOREIGN KEY (provider_id)
        REFERENCES public.medical_provider_profiles(id)
        ON UPDATE CASCADE
        ON DELETE SET NULL;

        RAISE NOTICE 'Added FK constraint appointments_provider_id_fkey';
    ELSE
        RAISE NOTICE 'FK constraint already exists';
    END IF;
END $$;

-- =====================================================
-- PART 2: Recreate appointment_overview view (fixed columns)
-- =====================================================

DROP VIEW IF EXISTS appointment_overview CASCADE;

CREATE OR REPLACE VIEW appointment_overview AS
SELECT
    a.id AS appointment_id,
    a.id,
    a.appointment_number,
    a.patient_id,
    a.provider_id,
    a.facility_id,
    a.scheduled_start,
    a.scheduled_end,
    a.start_date AS appointment_start_date,
    a.start_time AS appointment_start_time,
    a.status AS appointment_status,
    a.status,
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

    -- Patient information
    u_patient.id AS patient_user_id,
    u_patient.first_name AS patient_first_name,
    u_patient.last_name AS patient_last_name,
    COALESCE(u_patient.full_name, TRIM(COALESCE(u_patient.first_name, '') || ' ' || COALESCE(u_patient.last_name, ''))) AS patient_fullname,
    u_patient.full_name AS patient_full_name,
    COALESCE(u_patient.avatar_url, u_patient.profile_picture_url) AS patient_image_url,
    u_patient.email AS patient_email,
    u_patient.phone_number AS patient_phone,

    -- Provider information
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
LEFT JOIN users u_patient ON a.patient_id = u_patient.id
LEFT JOIN medical_provider_profiles mpp ON a.provider_id = mpp.id
LEFT JOIN users u_provider ON mpp.user_id = u_provider.id
LEFT JOIN facilities f ON a.facility_id = f.id;

GRANT SELECT ON appointment_overview TO authenticated;
GRANT SELECT ON appointment_overview TO anon;

COMMENT ON VIEW appointment_overview IS 'Appointments with patient, provider, facility details. provider_id references medical_provider_profiles.id';

-- =====================================================
-- PART 3: Update RLS policies
-- =====================================================

DROP POLICY IF EXISTS "Only providers can send messages during active calls" ON chime_messages;
DROP POLICY IF EXISTS "Users can view messages from their appointments" ON chime_messages;

CREATE POLICY "Only providers can send messages during active calls"
ON chime_messages
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM appointments a
        JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
        WHERE a.id = appointment_id
        AND mpp.user_id = auth.uid()
    )
    AND
    EXISTS (
        SELECT 1 FROM video_call_sessions vcs
        WHERE vcs.appointment_id = chime_messages.appointment_id
        AND vcs.is_call_active = TRUE
    )
);

CREATE POLICY "Users can view messages from their appointments"
ON chime_messages
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM appointments a
        LEFT JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
        WHERE a.id = appointment_id
        AND (a.patient_id = auth.uid() OR mpp.user_id = auth.uid())
    )
);

-- =====================================================
-- PART 4: Update helper functions
-- =====================================================

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
-- PART 5: Update appointment policies
-- =====================================================

DROP POLICY IF EXISTS "appointments_select_provider" ON appointments;
CREATE POLICY "appointments_select_provider" ON appointments
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM medical_provider_profiles mpp
        WHERE mpp.id = provider_id
        AND mpp.user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "appointments_select_patient" ON appointments;
CREATE POLICY "appointments_select_patient" ON appointments
FOR SELECT
TO authenticated
USING (patient_id = auth.uid());

DROP POLICY IF EXISTS "appointments_select_firebase" ON appointments;
CREATE POLICY "appointments_select_firebase" ON appointments
FOR SELECT
TO authenticated
USING (auth.uid() IS NULL);

COMMENT ON COLUMN appointments.provider_id IS 'References medical_provider_profiles.id (NOT users.id)';
