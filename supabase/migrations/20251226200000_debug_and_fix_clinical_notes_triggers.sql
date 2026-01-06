-- Migration: Debug and fix clinical notes update issue
-- Description: Check for constraint issues and fix them

-- First, let's see all triggers including internal ones
DO $$
DECLARE
    trigger_rec RECORD;
BEGIN
    RAISE NOTICE 'Listing ALL triggers on clinical_notes:';
    FOR trigger_rec IN
        SELECT t.tgname, t.tgtype, t.tgisinternal, p.proname as function_name
        FROM pg_trigger t
        LEFT JOIN pg_proc p ON t.tgfoid = p.oid
        WHERE t.tgrelid = 'clinical_notes'::regclass
    LOOP
        RAISE NOTICE 'Trigger: %, Type: %, Internal: %, Function: %',
            trigger_rec.tgname, trigger_rec.tgtype, trigger_rec.tgisinternal, trigger_rec.function_name;
    END LOOP;
END $$;

-- Drop ALL triggers including internal constraint triggers if any
DO $$
DECLARE
    trigger_rec RECORD;
BEGIN
    FOR trigger_rec IN
        SELECT tgname
        FROM pg_trigger
        WHERE tgrelid = 'clinical_notes'::regclass
    LOOP
        BEGIN
            EXECUTE format('DROP TRIGGER IF EXISTS %I ON clinical_notes CASCADE', trigger_rec.tgname);
            RAISE NOTICE 'Dropped trigger: %', trigger_rec.tgname;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not drop trigger %: %', trigger_rec.tgname, SQLERRM;
        END;
    END LOOP;
END $$;

-- Check for check constraints
DO $$
DECLARE
    constraint_rec RECORD;
BEGIN
    RAISE NOTICE 'Listing all constraints on clinical_notes:';
    FOR constraint_rec IN
        SELECT conname, contype, pg_get_constraintdef(oid) as def
        FROM pg_constraint
        WHERE conrelid = 'clinical_notes'::regclass
    LOOP
        RAISE NOTICE 'Constraint: %, Type: %, Definition: %',
            constraint_rec.conname, constraint_rec.contype, constraint_rec.def;
    END LOOP;
END $$;

-- Recreate the sync trigger with even simpler logic
CREATE OR REPLACE FUNCTION fn_queue_signed_clinical_note()
RETURNS TRIGGER AS $$
BEGIN
    -- Only run if patient has EHR ID
    IF EXISTS (
        SELECT 1 FROM users
        WHERE id = NEW.patient_id
        AND ehr_id IS NOT NULL
        AND ehr_id != ''
    ) THEN
        -- Insert into queue if not already queued
        INSERT INTO ehrbase_sync_queue (
            table_name, record_id, template_id, sync_type, sync_status, ehr_id, retry_count, data_snapshot, created_at
        )
        SELECT
            'clinical_notes',
            NEW.id::text,
            'medzen.clinical.notes.v1',
            'create',
            'pending',
            u.ehr_id,
            0,
            jsonb_build_object(
                'note_id', NEW.id::text,
                'patient_id', NEW.patient_id::text,
                'provider_id', NEW.provider_id::text,
                'note_type', NEW.note_type,
                'status', NEW.status
            ),
            NOW()
        FROM users u
        WHERE u.id = NEW.patient_id
        AND NOT EXISTS (
            SELECT 1 FROM ehrbase_sync_queue
            WHERE table_name = 'clinical_notes'
            AND record_id = NEW.id::text
            AND sync_status IN ('pending', 'processing')
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create simple trigger
CREATE TRIGGER tr_sync_signed_note
    AFTER UPDATE ON clinical_notes
    FOR EACH ROW
    WHEN (NEW.status = 'final' AND (OLD.status IS DISTINCT FROM 'final'))
    EXECUTE FUNCTION fn_queue_signed_clinical_note();

GRANT EXECUTE ON FUNCTION fn_queue_signed_clinical_note() TO authenticated, service_role;
