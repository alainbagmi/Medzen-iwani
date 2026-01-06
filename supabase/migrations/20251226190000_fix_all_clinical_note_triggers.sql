-- Migration: Fix all clinical note triggers - drop all and recreate
-- Description: Removes any problematic triggers and recreates the sync trigger cleanly

-- Drop ALL triggers on clinical_notes to start fresh
DO $$
DECLARE
    trigger_rec RECORD;
BEGIN
    FOR trigger_rec IN
        SELECT tgname
        FROM pg_trigger
        WHERE tgrelid = 'clinical_notes'::regclass
        AND NOT tgisinternal
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS %I ON clinical_notes', trigger_rec.tgname);
        RAISE NOTICE 'Dropped trigger: %', trigger_rec.tgname;
    END LOOP;
END $$;

-- Drop any existing sync functions
DROP FUNCTION IF EXISTS queue_clinical_note_for_sync() CASCADE;
DROP FUNCTION IF EXISTS auto_sync_clinical_note() CASCADE;

-- Create a new, clean trigger function
CREATE OR REPLACE FUNCTION fn_queue_clinical_note_for_ehrbase_sync()
RETURNS TRIGGER AS $$
DECLARE
    v_ehr_id TEXT;
    v_patient_name TEXT;
    v_provider_name TEXT;
    v_provider_specialty TEXT;
BEGIN
    -- Only trigger when status changes to 'final' (signed)
    IF NEW.status = 'final' AND (OLD IS NULL OR OLD.status IS DISTINCT FROM 'final') THEN
        -- Get patient's EHR ID using explicit cast
        SELECT u.ehr_id INTO v_ehr_id
        FROM users u
        WHERE u.id = NEW.patient_id::uuid;

        -- Skip if patient has no EHR ID
        IF v_ehr_id IS NULL OR v_ehr_id = '' THEN
            RETURN NEW;
        END IF;

        -- Get patient name
        SELECT u.first_name || ' ' || u.last_name INTO v_patient_name
        FROM users u
        WHERE u.id = NEW.patient_id::uuid;

        -- Get provider name
        SELECT u.first_name || ' ' || u.last_name INTO v_provider_name
        FROM users u
        WHERE u.id = NEW.provider_id::uuid;

        -- Get provider specialty
        SELECT COALESCE(mpp.primary_specialization, mpp.professional_role, 'General Practice') INTO v_provider_specialty
        FROM medical_provider_profiles mpp
        WHERE mpp.user_id = NEW.provider_id::uuid;

        -- Check if already queued (prevent duplicates)
        IF NOT EXISTS (
            SELECT 1 FROM ehrbase_sync_queue
            WHERE table_name = 'clinical_notes'
            AND record_id = NEW.id::text
            AND sync_status IN ('pending', 'processing')
        ) THEN
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
                NEW.id::text,
                'medzen.clinical.notes.v1',
                'create',
                'pending',
                v_ehr_id,
                0,
                jsonb_build_object(
                    'note_id', NEW.id::text,
                    'appointment_id', NEW.appointment_id::text,
                    'session_id', NEW.session_id::text,
                    'patient_id', NEW.patient_id::text,
                    'patient_name', COALESCE(v_patient_name, 'Unknown Patient'),
                    'provider_id', NEW.provider_id::text,
                    'provider_name', COALESCE(v_provider_name, 'Unknown Provider'),
                    'provider_specialty', COALESCE(v_provider_specialty, 'General Practice'),
                    'note_type', NEW.note_type,
                    'chief_complaint', NEW.chief_complaint,
                    'history_of_present_illness', NEW.history_of_present_illness,
                    'subjective', NEW.subjective,
                    'objective', NEW.objective,
                    'assessment', NEW.assessment,
                    'plan', NEW.plan,
                    'icd10_codes', NEW.icd10_codes,
                    'cpt_codes', NEW.cpt_codes,
                    'medical_entities', NEW.medical_entities,
                    'signed_by', NEW.provider_signature,
                    'signed_at', NEW.signed_at::text,
                    'transcript_language', NEW.transcript_language
                ),
                NOW()
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger on status updates only
CREATE TRIGGER tr_clinical_note_sync_on_sign
    AFTER UPDATE OF status ON clinical_notes
    FOR EACH ROW
    WHEN (NEW.status = 'final')
    EXECUTE FUNCTION fn_queue_clinical_note_for_ehrbase_sync();

-- Also create trigger for new notes inserted as final
CREATE TRIGGER tr_clinical_note_sync_on_insert
    AFTER INSERT ON clinical_notes
    FOR EACH ROW
    WHEN (NEW.status = 'final')
    EXECUTE FUNCTION fn_queue_clinical_note_for_ehrbase_sync();

-- Grant execute permission
GRANT EXECUTE ON FUNCTION fn_queue_clinical_note_for_ehrbase_sync() TO authenticated, service_role;

-- Add comment
COMMENT ON FUNCTION fn_queue_clinical_note_for_ehrbase_sync() IS
'Queues signed clinical notes for EHRbase/OpenEHR sync when status is final';
