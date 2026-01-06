-- Fix ehrbase_sync_queue data_snapshot trigger
-- This migration ensures that data_snapshot is properly populated when records are added to the sync queue

-- Drop existing trigger and function if they exist
DROP TRIGGER IF EXISTS ehrbase_sync_snapshot_trigger ON ehrbase_sync_queue;
DROP FUNCTION IF EXISTS populate_ehrbase_sync_data_snapshot();

-- Create function to populate data_snapshot field
-- This function fetches the actual record data and stores it in the data_snapshot field
CREATE OR REPLACE FUNCTION populate_ehrbase_sync_data_snapshot()
RETURNS TRIGGER AS $$
BEGIN
  -- Only populate if data_snapshot is not already set
  IF NEW.data_snapshot IS NULL THEN
    -- Populate data_snapshot based on table_name
    CASE NEW.table_name
      WHEN 'vital_signs' THEN
        SELECT row_to_json(vs.*)
        INTO NEW.data_snapshot
        FROM vital_signs vs
        WHERE vs.id::text = NEW.record_id;

      WHEN 'prescriptions' THEN
        SELECT row_to_json(p.*)
        INTO NEW.data_snapshot
        FROM prescriptions p
        WHERE p.id::text = NEW.record_id;

      WHEN 'lab_results' THEN
        SELECT row_to_json(lr.*)
        INTO NEW.data_snapshot
        FROM lab_results lr
        WHERE lr.id::text = NEW.record_id;

      WHEN 'lab_orders' THEN
        SELECT row_to_json(lo.*)
        INTO NEW.data_snapshot
        FROM lab_orders lo
        WHERE lo.id::text = NEW.record_id;

      WHEN 'allergies' THEN
        SELECT row_to_json(a.*)
        INTO NEW.data_snapshot
        FROM allergies a
        WHERE a.id::text = NEW.record_id;

      WHEN 'clinical_consultations' THEN
        SELECT row_to_json(cc.*)
        INTO NEW.data_snapshot
        FROM clinical_consultations cc
        WHERE cc.id::text = NEW.record_id;

      WHEN 'admission_discharges' THEN
        SELECT row_to_json(ad.*)
        INTO NEW.data_snapshot
        FROM admission_discharges ad
        WHERE ad.id::text = NEW.record_id;

      WHEN 'surgical_procedures' THEN
        SELECT row_to_json(sp.*)
        INTO NEW.data_snapshot
        FROM surgical_procedures sp
        WHERE sp.id::text = NEW.record_id;

      WHEN 'user_medical_conditions' THEN
        SELECT row_to_json(umc.*)
        INTO NEW.data_snapshot
        FROM user_medical_conditions umc
        WHERE umc.id::text = NEW.record_id;

      WHEN 'user_medications' THEN
        SELECT row_to_json(um.*)
        INTO NEW.data_snapshot
        FROM user_medications um
        WHERE um.id::text = NEW.record_id;

      WHEN 'user_allergies' THEN
        SELECT row_to_json(ua.*)
        INTO NEW.data_snapshot
        FROM user_allergies ua
        WHERE ua.id::text = NEW.record_id;

      -- Add more tables as needed
      ELSE
        -- For unknown tables, log a warning but don't fail
        RAISE WARNING 'Unknown table_name in ehrbase_sync_queue: %', NEW.table_name;
    END CASE;

    -- Log if data_snapshot is still null after attempting to fetch
    IF NEW.data_snapshot IS NULL THEN
      RAISE WARNING 'Failed to populate data_snapshot for table: %, record_id: %', NEW.table_name, NEW.record_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger that fires before insert
CREATE TRIGGER ehrbase_sync_snapshot_trigger
  BEFORE INSERT ON ehrbase_sync_queue
  FOR EACH ROW
  EXECUTE FUNCTION populate_ehrbase_sync_data_snapshot();

-- Add comments for documentation
COMMENT ON FUNCTION populate_ehrbase_sync_data_snapshot() IS
'Automatically populates the data_snapshot field in ehrbase_sync_queue with the actual record data from the source table. This ensures the sync-to-ehrbase edge function has all necessary data to create OpenEHR compositions.';

COMMENT ON TRIGGER ehrbase_sync_snapshot_trigger ON ehrbase_sync_queue IS
'Triggers before INSERT to populate data_snapshot field with actual record data from source table.';

-- Create index on table_name and record_id for better performance
CREATE INDEX IF NOT EXISTS idx_ehrbase_sync_queue_table_record
  ON ehrbase_sync_queue(table_name, record_id);

-- Create index on sync_status for monitoring queries
CREATE INDEX IF NOT EXISTS idx_ehrbase_sync_queue_status
  ON ehrbase_sync_queue(sync_status)
  WHERE sync_status IN ('pending', 'processing');

-- Add constraint to ensure data_snapshot is not null for medical records
-- (Optional - can be enabled after verifying trigger works)
-- ALTER TABLE ehrbase_sync_queue
--   ADD CONSTRAINT check_data_snapshot_not_null
--   CHECK (sync_type = 'ehr_status_update' OR data_snapshot IS NOT NULL);
