-- Migration: Add OpenEHR sync columns to clinical_notes table
-- Date: 2025-12-26
-- Purpose: Enable clinical notes sync to EHRbase/OpenEHR

-- Add OpenEHR sync columns to clinical_notes if they don't exist
DO $$
BEGIN
    -- EHRbase composition ID (stores the OpenEHR composition UID)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'clinical_notes' AND column_name = 'ehrbase_composition_id'
    ) THEN
        ALTER TABLE clinical_notes ADD COLUMN ehrbase_composition_id TEXT;
        COMMENT ON COLUMN clinical_notes.ehrbase_composition_id IS 'OpenEHR composition UID from EHRbase';
    END IF;

    -- Timestamp when synced to EHRbase
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'clinical_notes' AND column_name = 'ehrbase_synced_at'
    ) THEN
        ALTER TABLE clinical_notes ADD COLUMN ehrbase_synced_at TIMESTAMPTZ;
        COMMENT ON COLUMN clinical_notes.ehrbase_synced_at IS 'When the note was synced to OpenEHR';
    END IF;

    -- Sync status
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'clinical_notes' AND column_name = 'ehrbase_sync_status'
    ) THEN
        ALTER TABLE clinical_notes ADD COLUMN ehrbase_sync_status TEXT DEFAULT 'not_synced';
        COMMENT ON COLUMN clinical_notes.ehrbase_sync_status IS 'Sync status: not_synced, pending, synced, failed';
    END IF;

    -- Last sync error (if any)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'clinical_notes' AND column_name = 'ehrbase_sync_error'
    ) THEN
        ALTER TABLE clinical_notes ADD COLUMN ehrbase_sync_error TEXT;
        COMMENT ON COLUMN clinical_notes.ehrbase_sync_error IS 'Last sync error message if failed';
    END IF;

    -- Provider signature (for signed notes)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'clinical_notes' AND column_name = 'provider_signature'
    ) THEN
        ALTER TABLE clinical_notes ADD COLUMN provider_signature TEXT;
        COMMENT ON COLUMN clinical_notes.provider_signature IS 'Digital signature or provider name';
    END IF;

    -- Signed at timestamp
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'clinical_notes' AND column_name = 'signed_at'
    ) THEN
        ALTER TABLE clinical_notes ADD COLUMN signed_at TIMESTAMPTZ;
        COMMENT ON COLUMN clinical_notes.signed_at IS 'When the note was signed';
    END IF;

    -- Signed by (provider ID)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'clinical_notes' AND column_name = 'signed_by'
    ) THEN
        ALTER TABLE clinical_notes ADD COLUMN signed_by UUID REFERENCES users(id);
        COMMENT ON COLUMN clinical_notes.signed_by IS 'Provider who signed the note';
    END IF;

    -- Transcript language
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'clinical_notes' AND column_name = 'transcript_language'
    ) THEN
        ALTER TABLE clinical_notes ADD COLUMN transcript_language TEXT DEFAULT 'en-US';
        COMMENT ON COLUMN clinical_notes.transcript_language IS 'Language of the source transcript';
    END IF;

    -- Original transcript reference
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'clinical_notes' AND column_name = 'original_transcript_id'
    ) THEN
        ALTER TABLE clinical_notes ADD COLUMN original_transcript_id UUID REFERENCES video_call_sessions(id);
        COMMENT ON COLUMN clinical_notes.original_transcript_id IS 'Reference to the video call session with transcript';
    END IF;

END $$;

-- Create index for faster sync status queries
CREATE INDEX IF NOT EXISTS idx_clinical_notes_sync_status
ON clinical_notes(ehrbase_sync_status)
WHERE ehrbase_sync_status IN ('pending', 'failed');

-- Create index for provider lookup of their notes
CREATE INDEX IF NOT EXISTS idx_clinical_notes_provider
ON clinical_notes(provider_id, created_at DESC);

-- Create index for patient medical records
CREATE INDEX IF NOT EXISTS idx_clinical_notes_patient
ON clinical_notes(patient_id, created_at DESC);

-- Create index for appointment-based lookup
CREATE INDEX IF NOT EXISTS idx_clinical_notes_appointment
ON clinical_notes(appointment_id);

-- Add RLS policies for clinical_notes if not exists
DO $$
BEGIN
    -- Drop existing policies if they exist (to recreate with proper permissions)
    DROP POLICY IF EXISTS "clinical_notes_select_own" ON clinical_notes;
    DROP POLICY IF EXISTS "clinical_notes_insert_provider" ON clinical_notes;
    DROP POLICY IF EXISTS "clinical_notes_update_own" ON clinical_notes;
    DROP POLICY IF EXISTS "clinical_notes_admin_access" ON clinical_notes;

    -- Enable RLS
    ALTER TABLE clinical_notes ENABLE ROW LEVEL SECURITY;

    -- Providers can view notes they created or for their patients
    CREATE POLICY "clinical_notes_select_own" ON clinical_notes
        FOR SELECT USING (
            auth.uid() IS NULL OR  -- Allow service role and Firebase auth
            provider_id = auth.uid() OR
            patient_id = auth.uid()
        );

    -- Providers can insert their own notes
    CREATE POLICY "clinical_notes_insert_provider" ON clinical_notes
        FOR INSERT WITH CHECK (
            auth.uid() IS NULL OR  -- Allow service role and Firebase auth
            provider_id = auth.uid()
        );

    -- Providers can update their own draft notes
    CREATE POLICY "clinical_notes_update_own" ON clinical_notes
        FOR UPDATE USING (
            auth.uid() IS NULL OR  -- Allow service role and Firebase auth
            (provider_id = auth.uid() AND status = 'draft')
        );

END $$;

-- Create a view for clinical notes with related info
CREATE OR REPLACE VIEW clinical_notes_overview AS
SELECT
    cn.id,
    cn.appointment_id,
    cn.session_id,
    cn.provider_id,
    cn.patient_id,
    cn.note_type,
    cn.status,
    cn.chief_complaint,
    cn.assessment,
    cn.created_at,
    cn.updated_at,
    cn.signed_at,
    cn.ehrbase_composition_id,
    cn.ehrbase_synced_at,
    cn.ehrbase_sync_status,

    -- Provider info
    pu.first_name || ' ' || pu.last_name AS provider_name,
    COALESCE(mpp.primary_specialization, mpp.professional_role, 'General Practice') AS provider_specialty,

    -- Patient info
    ptu.first_name || ' ' || ptu.last_name AS patient_name,

    -- Appointment info
    a.appointment_number,
    a.scheduled_start AS appointment_date,

    -- Counts
    jsonb_array_length(COALESCE(cn.icd10_codes, '[]'::jsonb)) AS icd10_count,
    jsonb_array_length(COALESCE(cn.medical_entities, '[]'::jsonb)) AS entity_count

FROM clinical_notes cn
LEFT JOIN users pu ON pu.id = cn.provider_id
LEFT JOIN medical_provider_profiles mpp ON mpp.user_id = cn.provider_id
LEFT JOIN users ptu ON ptu.id = cn.patient_id
LEFT JOIN appointments a ON a.id = cn.appointment_id;

-- Grant access to the view
GRANT SELECT ON clinical_notes_overview TO anon, authenticated, service_role;

COMMENT ON VIEW clinical_notes_overview IS 'Clinical notes with provider, patient, and appointment details';
