-- Enhanced EHR Sync System Migration
-- This migration adds complete demographic sync support and offline-first capabilities

-- =====================================================
-- 1. Update ehrbase_sync_queue table with new fields
-- =====================================================

-- Add new columns to support demographic updates and better offline sync
ALTER TABLE ehrbase_sync_queue
ADD COLUMN IF NOT EXISTS sync_type VARCHAR(50) DEFAULT 'composition_create',
ADD COLUMN IF NOT EXISTS data_snapshot JSONB,
ADD COLUMN IF NOT EXISTS last_retry_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Create index for sync_type and sync_status for faster queries
CREATE INDEX IF NOT EXISTS idx_ehrbase_sync_queue_type_status
ON ehrbase_sync_queue(sync_type, sync_status);

-- Create index for offline-first queries (pending items first)
CREATE INDEX IF NOT EXISTS idx_ehrbase_sync_queue_pending
ON ehrbase_sync_queue(sync_status, created_at)
WHERE sync_status = 'pending';

-- Add unique constraint to prevent duplicate queue entries
ALTER TABLE ehrbase_sync_queue
ADD CONSTRAINT unique_table_record_sync
UNIQUE (table_name, record_id, sync_type);

-- =====================================================
-- 2. Create function to queue demographic updates
-- =====================================================

CREATE OR REPLACE FUNCTION queue_user_demographics_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  -- Get the EHR ID for this user
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.id::TEXT;

  -- Only queue if user has an EHR
  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name,
      record_id,
      template_id,
      sync_type,
      sync_status,
      data_snapshot,
      created_at,
      updated_at
    ) VALUES (
      'users_demographics',
      NEW.id::TEXT,
      'ehrbase.demographics.v1', -- Template for demographic data
      'ehr_status_update',
      'pending',
      jsonb_build_object(
        'user_id', NEW.id,
        'firebase_uid', NEW.firebase_uid,
        'ehr_id', v_ehr_id,
        'first_name', NEW.first_name,
        'last_name', NEW.last_name,
        'middle_name', NEW.middle_name,
        'full_name', NEW.full_name,
        'date_of_birth', NEW.date_of_birth,
        'gender', NEW.gender,
        'email', NEW.email,
        'phone_number', NEW.phone_number,
        'country', NEW.country,
        'updated_at', NEW.updated_at
      ),
      NOW(),
      NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type)
    DO UPDATE SET
      sync_status = 'pending',
      data_snapshot = EXCLUDED.data_snapshot,
      updated_at = NOW(),
      retry_count = 0, -- Reset retry count on new update
      error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. Create trigger for user demographic updates
-- =====================================================

DROP TRIGGER IF EXISTS trigger_queue_user_demographics_sync ON users;

CREATE TRIGGER trigger_queue_user_demographics_sync
  AFTER UPDATE OF first_name, last_name, middle_name, date_of_birth, gender, phone_number, country ON users
  FOR EACH ROW
  WHEN (
    OLD.first_name IS DISTINCT FROM NEW.first_name OR
    OLD.last_name IS DISTINCT FROM NEW.last_name OR
    OLD.middle_name IS DISTINCT FROM NEW.middle_name OR
    OLD.date_of_birth IS DISTINCT FROM NEW.date_of_birth OR
    OLD.gender IS DISTINCT FROM NEW.gender OR
    OLD.phone_number IS DISTINCT FROM NEW.phone_number OR
    OLD.country IS DISTINCT FROM NEW.country
  )
  EXECUTE FUNCTION queue_user_demographics_for_sync();

-- =====================================================
-- 4. Create function to queue vital signs for sync
-- =====================================================

CREATE OR REPLACE FUNCTION queue_vital_signs_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  -- Get the EHR ID for this patient
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id::TEXT;

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name,
      record_id,
      template_id,
      sync_type,
      sync_status,
      data_snapshot,
      created_at,
      updated_at
    ) VALUES (
      'vital_signs',
      NEW.id::TEXT,
      'ehrbase.vital_signs.v1',
      'composition_create',
      'pending',
      to_jsonb(NEW),
      NOW(),
      NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type)
    DO UPDATE SET
      sync_status = 'pending',
      data_snapshot = to_jsonb(NEW),
      updated_at = NOW();
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. Create triggers for medical record types
-- =====================================================

-- Vital Signs Trigger
DROP TRIGGER IF EXISTS trigger_queue_vital_signs_sync ON vital_signs;

CREATE TRIGGER trigger_queue_vital_signs_sync
  AFTER INSERT OR UPDATE ON vital_signs
  FOR EACH ROW
  EXECUTE FUNCTION queue_vital_signs_for_sync();

-- Lab Results Trigger
CREATE OR REPLACE FUNCTION queue_lab_results_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id::TEXT;

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at
    ) VALUES (
      'lab_results', NEW.id::TEXT, 'ehrbase.lab_results.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type)
    DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_lab_results_sync ON lab_results;

CREATE TRIGGER trigger_queue_lab_results_sync
  AFTER INSERT OR UPDATE ON lab_results
  FOR EACH ROW
  EXECUTE FUNCTION queue_lab_results_for_sync();

-- Prescriptions Trigger
CREATE OR REPLACE FUNCTION queue_prescriptions_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id::TEXT;

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at
    ) VALUES (
      'prescriptions', NEW.id::TEXT, 'ehrbase.prescriptions.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type)
    DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_prescriptions_sync ON prescriptions;

CREATE TRIGGER trigger_queue_prescriptions_sync
  AFTER INSERT OR UPDATE ON prescriptions
  FOR EACH ROW
  EXECUTE FUNCTION queue_prescriptions_for_sync();

-- =====================================================
-- 6. Create function to clean up old processed entries
-- =====================================================

CREATE OR REPLACE FUNCTION cleanup_old_sync_queue_entries()
RETURNS void AS $$
BEGIN
  -- Delete successfully processed entries older than 30 days
  DELETE FROM ehrbase_sync_queue
  WHERE sync_status = 'completed'
    AND processed_at < NOW() - INTERVAL '30 days';

  -- Delete failed entries with max retries older than 90 days
  DELETE FROM ehrbase_sync_queue
  WHERE sync_status = 'failed'
    AND retry_count >= 5
    AND created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 7. Create view for monitoring sync health
-- =====================================================

CREATE OR REPLACE VIEW v_sync_health_by_type AS
SELECT
  sync_type,
  sync_status,
  COUNT(*) as count,
  MIN(created_at) as oldest_entry,
  MAX(created_at) as newest_entry,
  AVG(retry_count) as avg_retry_count
FROM ehrbase_sync_queue
GROUP BY sync_type, sync_status
ORDER BY sync_type, sync_status;

-- =====================================================
-- 8. Grant necessary permissions (adjust as needed)
-- =====================================================

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE ON ehrbase_sync_queue TO authenticated;
GRANT SELECT ON v_sync_health_by_type TO authenticated;

-- Grant execute on functions
GRANT EXECUTE ON FUNCTION cleanup_old_sync_queue_entries() TO authenticated;

-- =====================================================
-- 9. Comments for documentation
-- =====================================================

COMMENT ON TABLE ehrbase_sync_queue IS 'Queue for syncing data to EHRbase with offline-first support';
COMMENT ON COLUMN ehrbase_sync_queue.sync_type IS 'Type of sync: composition_create, composition_update, ehr_status_update';
COMMENT ON COLUMN ehrbase_sync_queue.data_snapshot IS 'Complete data snapshot at time of queue insertion for offline-first sync';
COMMENT ON FUNCTION queue_user_demographics_for_sync() IS 'Queues user demographic updates for EHR_STATUS sync to EHRbase';
COMMENT ON FUNCTION cleanup_old_sync_queue_entries() IS 'Cleans up old processed entries to prevent table bloat';
