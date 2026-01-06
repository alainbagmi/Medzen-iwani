-- Migration: Final trigger fix with correct UUID handling
-- Description: Fixed trigger - record_id is UUID, not TEXT

-- Drop and recreate
DROP TRIGGER IF EXISTS tr_clinical_note_sync ON clinical_notes;
DROP TRIGGER IF EXISTS tr_clinical_note_sync_insert ON clinical_notes;
DROP FUNCTION IF EXISTS fn_queue_clinical_note_sync() CASCADE;

-- Create trigger function with correct types
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

    -- Get patient info
    SELECT ehr_id, (first_name || ' ' || last_name)
    INTO v_ehr_id, v_patient_name
    FROM users
    WHERE id = NEW.patient_id;

    -- Skip if no EHR ID
    IF v_ehr_id IS NULL OR v_ehr_id = '' THEN
        RAISE NOTICE 'Patient % has no EHR ID, skipping sync', NEW.patient_id;
        RETURN NEW;
    END IF;

    -- Get provider name
    SELECT (first_name || ' ' || last_name)
    INTO v_provider_name
    FROM users
    WHERE id = NEW.provider_id;

    -- Check if already queued (record_id is UUID type!)
    IF EXISTS (
        SELECT 1 FROM ehrbase_sync_queue
        WHERE table_name = 'clinical_notes'
        AND record_id = NEW.id  -- Both are UUID, no cast needed
        AND sync_status IN ('pending', 'processing')
    ) THEN
        RAISE NOTICE 'Note % already queued', NEW.id;
        RETURN NEW;
    END IF;

    -- Insert into sync queue (record_id is UUID!)
    INSERT INTO ehrbase_sync_queue (
        table_name,
        record_id,  -- UUID type
        template_id,
        sync_type,
        sync_status,
        ehr_id,
        retry_count,
        data_snapshot,
        created_at
    ) VALUES (
        'clinical_notes',
        NEW.id,  -- UUID - no cast needed!
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

    -- Update sync status on the note
    NEW.ehrbase_sync_status := 'queued';

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

-- Re-enable RLS with proper policies
ALTER TABLE clinical_notes ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies first
DROP POLICY IF EXISTS "clinical_notes_select_policy" ON clinical_notes;
DROP POLICY IF EXISTS "clinical_notes_insert_policy" ON clinical_notes;
DROP POLICY IF EXISTS "clinical_notes_update_policy" ON clinical_notes;
DROP POLICY IF EXISTS "clinical_notes_delete_policy" ON clinical_notes;
DROP POLICY IF EXISTS "clinical_notes_select" ON clinical_notes;
DROP POLICY IF EXISTS "clinical_notes_insert" ON clinical_notes;
DROP POLICY IF EXISTS "clinical_notes_update" ON clinical_notes;
DROP POLICY IF EXISTS "clinical_notes_delete" ON clinical_notes;

-- Create RLS policies that work with Firebase auth (auth.uid() IS NULL)
CREATE POLICY "clinical_notes_select" ON clinical_notes
    FOR SELECT USING (
        auth.uid() IS NULL  -- Firebase auth users
        OR patient_id = auth.uid()
        OR provider_id = auth.uid()
    );

CREATE POLICY "clinical_notes_insert" ON clinical_notes
    FOR INSERT WITH CHECK (
        auth.uid() IS NULL
        OR provider_id = auth.uid()
    );

CREATE POLICY "clinical_notes_update" ON clinical_notes
    FOR UPDATE USING (
        auth.uid() IS NULL
        OR provider_id = auth.uid()
    ) WITH CHECK (
        auth.uid() IS NULL
        OR provider_id = auth.uid()
    );

CREATE POLICY "clinical_notes_delete" ON clinical_notes
    FOR DELETE USING (
        auth.uid() IS NULL
        OR provider_id = auth.uid()
    );

COMMENT ON FUNCTION fn_queue_clinical_note_sync() IS
'Queues signed clinical notes (status=final) for EHRbase sync.
Fixed: record_id in ehrbase_sync_queue is UUID type, not TEXT.';
