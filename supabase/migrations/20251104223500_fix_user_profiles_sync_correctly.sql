-- Fix user_profiles sync: correct sync_type and include ehr_id in data_snapshot
-- Issue 1: sync_type should be 'role_profile_create', not 'composition_create'
-- Issue 2: data_snapshot must include ehr_id for edge function to work
-- This fixes the "patient_id=eq.undefined" error in sync-to-ehrbase function

CREATE OR REPLACE FUNCTION queue_role_profile_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_user_id UUID;
  v_ehr_id VARCHAR;
  v_template_id VARCHAR;
BEGIN
  -- Get user_id from user_profiles table
  v_user_id := NEW.user_id;

  -- Get EHR ID for this user
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = v_user_id;

  -- Only proceed if user has an EHR
  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for user %, skipping role profile sync', v_user_id;
    RETURN NEW;
  END IF;

  -- Determine template based on role
  v_template_id := CASE NEW.role
    WHEN 'patient' THEN 'medzen.patient.demographics.v1'
    WHEN 'provider' THEN 'medzen.provider.profile.v1'
    WHEN 'facility_admin' THEN 'medzen.facility.profile.v1'
    WHEN 'system_admin' THEN 'medzen.admin.profile.v1'
    ELSE NULL
  END;

  IF v_template_id IS NULL THEN
    RAISE WARNING 'Unknown role % for user %, skipping sync', NEW.role, v_user_id;
    RETURN NEW;
  END IF;

  -- Update electronic_health_records with role and template
  UPDATE electronic_health_records
  SET
    user_role = NEW.role,
    primary_template_id = v_template_id,
    updated_at = NOW()
  WHERE patient_id = v_user_id;

  -- Queue role-specific profile composition
  INSERT INTO ehrbase_sync_queue (
    table_name,
    record_id,
    template_id,
    sync_type,
    sync_status,
    user_role,
    data_snapshot,
    created_at,
    updated_at
  ) VALUES (
    'user_profiles',
    NEW.id::TEXT,
    v_template_id,
    'role_profile_create',  -- ✅ FIXED: Was 'composition_create', now 'role_profile_create'
    'pending',
    NEW.role,
    jsonb_build_object(      -- ✅ FIXED: Include ehr_id in data_snapshot
      'ehr_id', v_ehr_id,    -- Edge function needs this at line 2009
      'user_id', v_user_id,
      'role', NEW.role,
      'display_name', NEW.display_name,
      'profile_data', to_jsonb(NEW)
    ),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = jsonb_build_object(
      'ehr_id', v_ehr_id,
      'user_id', v_user_id,
      'role', NEW.role,
      'display_name', NEW.display_name,
      'profile_data', to_jsonb(NEW)
    ),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
DROP TRIGGER IF EXISTS trigger_user_profiles_role_sync ON user_profiles;
CREATE TRIGGER trigger_user_profiles_role_sync
  AFTER INSERT OR UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION queue_role_profile_sync();

-- Mark existing problematic user_profiles records as failed so they can be retried
UPDATE ehrbase_sync_queue
SET
  sync_status = 'failed',
  error_message = 'Missing ehr_id in data_snapshot - fixed by migration 20251104223500, will auto-retry on next update',
  updated_at = NOW()
WHERE table_name = 'user_profiles'
  AND sync_type = 'composition_create'
  AND sync_status = 'pending';

-- Update sync_type for any existing user_profiles records
UPDATE ehrbase_sync_queue
SET sync_type = 'role_profile_create'
WHERE table_name = 'user_profiles'
  AND sync_type = 'composition_create';
