-- Migration: Auto-sync signed clinical notes to OpenEHR
-- Description: Trigger to automatically queue clinical notes for EHRbase sync when signed

-- Function to queue clinical note for EHRbase sync
CREATE OR REPLACE FUNCTION queue_clinical_note_for_sync()
RETURNS TRIGGER AS $$
DECLARE
    v_ehr_id TEXT;
    v_patient_name TEXT;
    v_provider_name TEXT;
    v_provider_specialty TEXT;
BEGIN
    -- Only trigger when status changes to 'final' (signed)
    IF NEW.status = 'final' AND (OLD.status IS NULL OR OLD.status != 'final') THEN
        -- Get patient's EHR ID
        SELECT ehr_id INTO v_ehr_id
        FROM users
        WHERE id = NEW.patient_id;

        -- Skip if patient has no EHR ID
        IF v_ehr_id IS NULL OR v_ehr_id = '' THEN
            RAISE NOTICE 'Clinical note % not synced: patient has no EHR ID', NEW.id;
            RETURN NEW;
        END IF;

        -- Get patient name
        SELECT first_name || ' ' || last_name INTO v_patient_name
        FROM users
        WHERE id = NEW.patient_id;

        -- Get provider name
        SELECT first_name || ' ' || last_name INTO v_provider_name
        FROM users
        WHERE id = NEW.provider_id;

        -- Get provider specialty
        SELECT COALESCE(primary_specialization, professional_role, 'General Practice') INTO v_provider_specialty
        FROM medical_provider_profiles
        WHERE user_id = NEW.provider_id;

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
                    'note_id', NEW.id,
                    'appointment_id', NEW.appointment_id,
                    'session_id', NEW.session_id,
                    'patient_id', NEW.patient_id,
                    'patient_name', COALESCE(v_patient_name, 'Unknown Patient'),
                    'provider_id', NEW.provider_id,
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
                    'signed_at', NEW.signed_at,
                    'transcript_language', NEW.transcript_language
                ),
                NOW()
            );

            RAISE NOTICE 'Clinical note % queued for EHRbase sync', NEW.id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_queue_clinical_note_sync ON clinical_notes;

-- Create trigger on clinical_notes table
CREATE TRIGGER trigger_queue_clinical_note_sync
    AFTER INSERT OR UPDATE OF status ON clinical_notes
    FOR EACH ROW
    EXECUTE FUNCTION queue_clinical_note_for_sync();

-- Add comment
COMMENT ON FUNCTION queue_clinical_note_for_sync() IS
'Automatically queues signed clinical notes for EHRbase/OpenEHR sync when status changes to final';

-- Grant execute permission
GRANT EXECUTE ON FUNCTION queue_clinical_note_for_sync() TO authenticated;
GRANT EXECUTE ON FUNCTION queue_clinical_note_for_sync() TO service_role;
