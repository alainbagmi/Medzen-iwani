-- Fix trigger function to bypass RLS using SECURITY DEFINER
-- Error: new row violates row-level security policy (still happening)
-- Root Cause: Trigger functions need SECURITY DEFINER to bypass RLS
-- Solution: Recreate function with SECURITY DEFINER and set owner to postgres

-- Drop and recreate the function with SECURITY DEFINER
CREATE OR REPLACE FUNCTION queue_role_profile_sync()
RETURNS TRIGGER
SECURITY DEFINER  -- ✅ This makes the function run with owner's privileges, bypassing RLS
SET search_path = public
AS $$
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
    WHEN 'medical_provider' THEN 'medzen.provider.profile.v1'
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

  -- Queue role-specific profile composition (bypasses RLS due to SECURITY DEFINER)
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
    NEW.id,
    v_template_id,
    'role_profile_create',
    'pending',
    NEW.role,
    jsonb_build_object(
      'user_id', v_user_id,
      'ehr_id', v_ehr_id,
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
    user_role = EXCLUDED.user_role,
    data_snapshot = EXCLUDED.data_snapshot,
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ensure the function is owned by postgres (superuser) to have full privileges
ALTER FUNCTION queue_role_profile_sync() OWNER TO postgres;

COMMENT ON FUNCTION queue_role_profile_sync IS 'Queues role-specific profile composition for EHRbase sync. Uses SECURITY DEFINER to bypass RLS for system operations.';
