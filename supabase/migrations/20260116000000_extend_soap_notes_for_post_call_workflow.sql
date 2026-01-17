-- Migration: Extend soap_notes table for post-call SOAP entry workflow
-- Description: Adds fields to support provider-authored SOAP notes after video calls

-- =====================================================
-- Add new columns for post-call SOAP entry
-- =====================================================

-- Add provider_id foreign key if not exists
ALTER TABLE soap_notes
ADD COLUMN IF NOT EXISTS provider_id UUID REFERENCES users(id) ON DELETE SET NULL;

-- Add patient_id foreign key if not exists
ALTER TABLE soap_notes
ADD COLUMN IF NOT EXISTS patient_id UUID REFERENCES users(id) ON DELETE SET NULL;

-- Update status enum to include 'signed' for post-call workflow
-- Note: Using VARCHAR so we don't need to alter the type constraint
-- Existing values: draft, submitted, archived
-- New values: signed, synced

-- Add fields for post-call provider-authored content
ALTER TABLE soap_notes
ADD COLUMN IF NOT EXISTS signed_at TIMESTAMPTZ;

ALTER TABLE soap_notes
ADD COLUMN IF NOT EXISTS signed_by UUID REFERENCES users(id) ON DELETE SET NULL;

-- Store complete transcript attached to the note
ALTER TABLE soap_notes
ADD COLUMN IF NOT EXISTS transcript TEXT;

-- Store the full SOAP note data as JSON for export/audit
ALTER TABLE soap_notes
ADD COLUMN IF NOT EXISTS full_data JSONB;

-- Track sync status to EHRbase
ALTER TABLE soap_notes
ADD COLUMN IF NOT EXISTS synced_at TIMESTAMPTZ;

ALTER TABLE soap_notes
ADD COLUMN IF NOT EXISTS ehr_sync_status VARCHAR(50) DEFAULT 'pending'; -- pending, processing, completed, failed

ALTER TABLE soap_notes
ADD COLUMN IF NOT EXISTS ehr_sync_error TEXT;

-- =====================================================
-- Create trigger to queue signed SOAP notes for EHR sync
-- =====================================================

CREATE OR REPLACE FUNCTION queue_signed_soap_note_for_sync()
RETURNS TRIGGER AS $$
DECLARE
    v_ehr_id TEXT;
    v_patient_name TEXT;
    v_provider_name TEXT;
BEGIN
    -- Only trigger when status changes to 'signed'
    IF NEW.status = 'signed' AND (OLD.status IS NULL OR OLD.status != 'signed') THEN
        -- Get patient's EHR ID
        SELECT ehr_id INTO v_ehr_id
        FROM users
        WHERE id = NEW.patient_id;

        -- Skip if patient has no EHR ID
        IF v_ehr_id IS NULL OR v_ehr_id = '' THEN
            RAISE NOTICE 'SOAP note % not synced: patient has no EHR ID', NEW.id;
            UPDATE soap_notes SET ehr_sync_status = 'skipped', ehr_sync_error = 'No EHR ID for patient'
            WHERE id = NEW.id;
            RETURN NEW;
        END IF;

        -- Get patient name
        SELECT full_name INTO v_patient_name
        FROM users
        WHERE id = NEW.patient_id;

        -- Get provider name
        SELECT full_name INTO v_provider_name
        FROM users
        WHERE id = NEW.provider_id;

        -- Check if already queued (prevent duplicates)
        IF NOT EXISTS (
            SELECT 1 FROM ehrbase_sync_queue
            WHERE table_name = 'soap_notes'
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
                'soap_notes',
                NEW.id::text,
                'medzen.clinical.notes.v1',
                'create',
                'pending',
                v_ehr_id,
                0,
                jsonb_build_object(
                    'note_id', NEW.id,
                    'session_id', NEW.session_id,
                    'appointment_id', NEW.appointment_id,
                    'patient_id', NEW.patient_id,
                    'patient_name', COALESCE(v_patient_name, 'Unknown'),
                    'provider_id', NEW.provider_id,
                    'provider_name', COALESCE(v_provider_name, 'Unknown'),
                    'chief_complaint', NEW.chief_complaint,
                    'subjective', NEW.subjective,
                    'objective', NEW.objective,
                    'assessment', NEW.assessment,
                    'plan', NEW.plan,
                    'transcript', NEW.transcript,
                    'signed_at', NEW.signed_at,
                    'signed_by', NEW.signed_by,
                    'full_data', NEW.full_data
                ),
                NOW()
            );

            -- Update sync status
            UPDATE soap_notes
            SET ehr_sync_status = 'pending'
            WHERE id = NEW.id;

            RAISE NOTICE 'Signed SOAP note % queued for EHRbase sync', NEW.id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS trigger_queue_signed_soap_note_sync ON soap_notes;

-- Create trigger on soap_notes table for post-call SOAP notes
CREATE TRIGGER trigger_queue_signed_soap_note_sync
    AFTER INSERT OR UPDATE OF status ON soap_notes
    FOR EACH ROW
    EXECUTE FUNCTION queue_signed_soap_note_for_sync();

-- Add comment
COMMENT ON FUNCTION queue_signed_soap_note_for_sync() IS
'Automatically queues signed SOAP notes (post-call provider-authored) for EHRbase/OpenEHR sync';

-- Grant execute permission
GRANT EXECUTE ON FUNCTION queue_signed_soap_note_for_sync() TO authenticated;
GRANT EXECUTE ON FUNCTION queue_signed_soap_note_for_sync() TO service_role;

-- =====================================================
-- Create indexes for new columns
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_soap_notes_provider_id
  ON soap_notes(provider_id);

CREATE INDEX IF NOT EXISTS idx_soap_notes_patient_id
  ON soap_notes(patient_id);

CREATE INDEX IF NOT EXISTS idx_soap_notes_signed_at
  ON soap_notes(signed_at DESC);

CREATE INDEX IF NOT EXISTS idx_soap_notes_ehr_sync_status
  ON soap_notes(ehr_sync_status);
