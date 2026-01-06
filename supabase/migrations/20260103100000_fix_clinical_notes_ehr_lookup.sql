-- Migration: Fix clinical notes EHR lookup
-- Description: Use electronic_health_records table instead of users.ehr_id (which is always NULL)
-- The ehr_id values are stored in electronic_health_records.ehr_id, not users.ehr_id

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS tr_clinical_note_sync ON clinical_notes;
DROP TRIGGER IF EXISTS tr_clinical_note_sync_insert ON clinical_notes;
DROP FUNCTION IF EXISTS fn_queue_clinical_note_sync() CASCADE;

-- Create trigger function that uses electronic_health_records table
CREATE OR REPLACE FUNCTION fn_queue_clinical_note_sync()
RETURNS TRIGGER AS $$
DECLARE
    v_ehr_id TEXT;
    v_patient_name TEXT;
    v_provider_name TEXT;
BEGIN
    -- Only process when status becomes 'final'
    IF NEW.status != 'final' OR (OLD IS NOT NULL AND OLD.status = 'final') THEN
        RETURN NEW;
    END IF;

    -- Get patient name from users table
    SELECT (first_name || ' ' || last_name)
    INTO v_patient_name
    FROM users
    WHERE id = NEW.patient_id;

    -- Get EHR ID from electronic_health_records table (NOT from users.ehr_id!)
    -- This is where the actual EHR IDs are stored
    SELECT ehr_id
    INTO v_ehr_id
    FROM electronic_health_records
    WHERE patient_id = NEW.patient_id;

    -- Skip if no EHR record exists
    IF v_ehr_id IS NULL OR v_ehr_id = '' THEN
        RAISE NOTICE 'Patient % has no EHR record in electronic_health_records, skipping sync', NEW.patient_id;
        RETURN NEW;
    END IF;

    -- Get provider name
    SELECT (first_name || ' ' || last_name)
    INTO v_provider_name
    FROM users
    WHERE id = NEW.provider_id;

    -- Check if already queued
    IF EXISTS (
        SELECT 1 FROM ehrbase_sync_queue
        WHERE table_name = 'clinical_notes'
        AND record_id = NEW.id
        AND sync_status IN ('pending', 'processing')
    ) THEN
        RAISE NOTICE 'Note % already queued', NEW.id;
        RETURN NEW;
    END IF;

    -- Insert into sync queue
    INSERT INTO ehrbase_sync_queue (
        table_name,
        record_id,
        template_id,
        sync_type,
        sync_status,
        ehr_id,
        retry_count,
        data_snapshot,
        created_at
    ) VALUES (
        'clinical_notes',
        NEW.id,
        'medzen.clinical.notes.v1',
        'create',
        'pending',
        v_ehr_id,
        0,
        jsonb_build_object(
            'note_id', NEW.id::text,
            'appointment_id', COALESCE(NEW.appointment_id::text, ''),
            'session_id', COALESCE(NEW.session_id::text, ''),
            'patient_id', NEW.patient_id::text,
            'patient_name', COALESCE(v_patient_name, 'Unknown'),
            'provider_id', NEW.provider_id::text,
            'provider_name', COALESCE(v_provider_name, 'Unknown'),
            'note_type', COALESCE(NEW.note_type, 'soap'),
            'chief_complaint', COALESCE(NEW.chief_complaint, ''),
            'subjective', COALESCE(NEW.subjective, ''),
            'objective', COALESCE(NEW.objective, ''),
            'assessment', COALESCE(NEW.assessment, ''),
            'plan', COALESCE(NEW.plan, ''),
            'icd10_codes', COALESCE(NEW.icd10_codes, '[]'::jsonb),
            'cpt_codes', COALESCE(NEW.cpt_codes, '[]'::jsonb),
            'medical_entities', COALESCE(NEW.medical_entities, '{}'::jsonb),
            'signed_by', COALESCE(NEW.provider_signature, ''),
            'signed_at', COALESCE(NEW.signed_at::text, ''),
            'transcript_language', COALESCE(NEW.transcript_language, 'en')
        ),
        NOW()
    );

    -- Update sync status on the note (if column exists)
    BEGIN
        NEW.ehrbase_sync_status := 'queued';
    EXCEPTION WHEN undefined_column THEN
        NULL; -- Column doesn't exist, skip
    END;

    RAISE NOTICE 'Note % queued for EHRbase sync (ehr_id: %)', NEW.id, v_ehr_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute
GRANT EXECUTE ON FUNCTION fn_queue_clinical_note_sync() TO authenticated, service_role;

-- Create triggers
CREATE TRIGGER tr_clinical_note_sync
    BEFORE UPDATE ON clinical_notes
    FOR EACH ROW
    WHEN (NEW.status = 'final')
    EXECUTE FUNCTION fn_queue_clinical_note_sync();

CREATE TRIGGER tr_clinical_note_sync_insert
    BEFORE INSERT ON clinical_notes
    FOR EACH ROW
    WHEN (NEW.status = 'final')
    EXECUTE FUNCTION fn_queue_clinical_note_sync();

COMMENT ON FUNCTION fn_queue_clinical_note_sync() IS
'Queues signed clinical notes (status=final) for EHRbase sync.
FIXED: Uses electronic_health_records.ehr_id instead of users.ehr_id (which was always NULL).';
