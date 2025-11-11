-- ========================================================================
-- Migration: Add Demographics Sync Trigger on Users Table
-- ========================================================================
-- Purpose: Queue user demographics for sync to EHRbase when profile changes
-- Date: 2025-11-10
-- ========================================================================

-- ========================================================================
-- 1. Create function to queue demographics for EHRbase sync
-- ========================================================================
CREATE OR REPLACE FUNCTION queue_user_demographics_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  ehr_record RECORD;
  snapshot_data JSONB;
BEGIN
  -- Get the associated EHR record for this user
  SELECT * INTO ehr_record
  FROM electronic_health_records
  WHERE patient_id = NEW.id;

  -- Only queue if EHR exists
  IF ehr_record.ehr_id IS NOT NULL THEN

    -- Build comprehensive demographics snapshot
    snapshot_data := jsonb_build_object(
      -- Core identity
      'user_id', NEW.id,
      'firebase_uid', NEW.firebase_uid,
      'email', NEW.email,
      'ehr_id', ehr_record.ehr_id,

      -- Personal information
      'first_name', NEW.first_name,
      'middle_name', NEW.middle_name,
      'last_name', NEW.last_name,
      'date_of_birth', NEW.date_of_birth,
      'gender', NEW.gender,
      'blood_type', NEW.blood_type,

      -- Contact information
      'phone', NEW.phone,
      'address', NEW.address,
      'city', NEW.city,
      'state', NEW.state,
      'postal_code', NEW.postal_code,
      'country', NEW.country,

      -- Identification
      'id_type', NEW.id_type,
      'id_number', NEW.id_number,
      'passport_number', NEW.passport_number,
      'national_id', NEW.national_id,

      -- Demographics
      'ethnicity', NEW.ethnicity,
      'nationality', NEW.nationality,
      'language', NEW.language,
      'marital_status', NEW.marital_status,
      'occupation', NEW.occupation,

      -- Emergency contact
      'emergency_contact_name', NEW.emergency_contact_name,
      'emergency_contact_phone', NEW.emergency_contact_phone,
      'emergency_contact_relationship', NEW.emergency_contact_relationship,

      -- Medical info
      'allergies', NEW.allergies,
      'chronic_conditions', NEW.chronic_conditions,
      'medications', NEW.medications,

      -- Metadata
      'created_at', NEW.created_at,
      'updated_at', NEW.updated_at,
      'is_active', NEW.is_active
    );

    -- Insert into sync queue
    INSERT INTO ehrbase_sync_queue (
      table_name,
      record_id,
      operation,
      sync_type,
      sync_status,
      data_snapshot,
      retry_count,
      ehr_id
    )
    VALUES (
      'users',
      NEW.id,
      TG_OP,  -- 'INSERT' or 'UPDATE'
      'demographics',
      'pending',
      snapshot_data,
      0,
      ehr_record.ehr_id
    )
    ON CONFLICT (table_name, record_id, ehr_id)
    WHERE sync_status IN ('pending', 'processing')
    DO UPDATE SET
      operation = EXCLUDED.operation,
      sync_status = 'pending',
      data_snapshot = EXCLUDED.data_snapshot,
      updated_at = NOW(),
      retry_count = 0;  -- Reset retry count for new attempt

    -- Log the queue operation
    RAISE NOTICE 'Queued demographics sync for user: %, EHR: %', NEW.id, ehr_record.ehr_id;
  ELSE
    RAISE NOTICE 'No EHR found for user: %, skipping demographics sync', NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================================================
-- 2. Create trigger on users table
-- ========================================================================
-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_queue_user_demographics_for_ehrbase_sync ON users;

-- Create trigger for INSERT and UPDATE operations
CREATE TRIGGER trigger_queue_user_demographics_for_ehrbase_sync
  AFTER INSERT OR UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION queue_user_demographics_for_sync();

-- ========================================================================
-- 3. Grant necessary permissions
-- ========================================================================
GRANT EXECUTE ON FUNCTION queue_user_demographics_for_sync() TO authenticated;
GRANT EXECUTE ON FUNCTION queue_user_demographics_for_sync() TO service_role;

-- ========================================================================
-- 4. Add comment for documentation
-- ========================================================================
COMMENT ON FUNCTION queue_user_demographics_for_sync() IS
'Automatically queues user demographics for sync to EHRbase when user profile is created or updated.
Creates OpenEHR demographics composition with complete patient information.';

COMMENT ON TRIGGER trigger_queue_user_demographics_for_ehrbase_sync ON users IS
'Triggers demographics sync to EHRbase on user profile changes';

-- ========================================================================
-- Migration Complete
-- ========================================================================
-- Changes:
-- 1. Created queue_user_demographics_for_sync() function
-- 2. Added trigger on users table for INSERT/UPDATE
-- 3. Comprehensive data snapshot with all user fields
-- 4. Proper conflict handling for queue entries
-- ========================================================================
