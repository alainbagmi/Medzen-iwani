-- Fix UUID type casting in ehrbase_sync_snapshot trigger
-- The previous version had a type mismatch between UUID and TEXT

-- Drop and recreate the function with proper type handling
DROP TRIGGER IF EXISTS ehrbase_sync_snapshot_trigger ON ehrbase_sync_queue;
DROP FUNCTION IF EXISTS populate_ehrbase_sync_data_snapshot();

-- Create function with proper UUID handling
CREATE OR REPLACE FUNCTION populate_ehrbase_sync_data_snapshot()
RETURNS TRIGGER AS $$
BEGIN
  -- Only populate if data_snapshot is not already set
  IF NEW.data_snapshot IS NULL THEN
    -- Populate data_snapshot based on table_name
    -- Using NEW.record_id::uuid to ensure proper type casting
    CASE NEW.table_name
      WHEN 'vital_signs' THEN
        SELECT row_to_json(vs.*)
        INTO NEW.data_snapshot
        FROM vital_signs vs
        WHERE vs.id = NEW.record_id::uuid;

      WHEN 'prescriptions' THEN
        SELECT row_to_json(p.*)
        INTO NEW.data_snapshot
        FROM prescriptions p
        WHERE p.id = NEW.record_id::uuid;

      WHEN 'lab_results' THEN
        SELECT row_to_json(lr.*)
        INTO NEW.data_snapshot
        FROM lab_results lr
        WHERE lr.id = NEW.record_id::uuid;

      WHEN 'lab_orders' THEN
        SELECT row_to_json(lo.*)
        INTO NEW.data_snapshot
        FROM lab_orders lo
        WHERE lo.id = NEW.record_id::uuid;

      WHEN 'allergies' THEN
        SELECT row_to_json(a.*)
        INTO NEW.data_snapshot
        FROM allergies a
        WHERE a.id = NEW.record_id::uuid;

      WHEN 'clinical_consultations' THEN
        SELECT row_to_json(cc.*)
        INTO NEW.data_snapshot
        FROM clinical_consultations cc
        WHERE cc.id = NEW.record_id::uuid;

      WHEN 'admission_discharges' THEN
        SELECT row_to_json(ad.*)
        INTO NEW.data_snapshot
        FROM admission_discharges ad
        WHERE ad.id = NEW.record_id::uuid;

      WHEN 'surgical_procedures' THEN
        SELECT row_to_json(sp.*)
        INTO NEW.data_snapshot
        FROM surgical_procedures sp
        WHERE sp.id = NEW.record_id::uuid;

      WHEN 'user_medical_conditions' THEN
        SELECT row_to_json(umc.*)
        INTO NEW.data_snapshot
        FROM user_medical_conditions umc
        WHERE umc.id = NEW.record_id::uuid;

      WHEN 'user_medications' THEN
        SELECT row_to_json(um.*)
        INTO NEW.data_snapshot
        FROM user_medications um
        WHERE um.id = NEW.record_id::uuid;

      WHEN 'user_allergies' THEN
        SELECT row_to_json(ua.*)
        INTO NEW.data_snapshot
        FROM user_allergies ua
        WHERE ua.id = NEW.record_id::uuid;

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

-- Create trigger
CREATE TRIGGER ehrbase_sync_snapshot_trigger
  BEFORE INSERT ON ehrbase_sync_queue
  FOR EACH ROW
  EXECUTE FUNCTION populate_ehrbase_sync_data_snapshot();

-- Add comments
COMMENT ON FUNCTION populate_ehrbase_sync_data_snapshot() IS
'Automatically populates the data_snapshot field in ehrbase_sync_queue with the actual record data from the source table. Uses proper UUID type casting for record lookups.';
