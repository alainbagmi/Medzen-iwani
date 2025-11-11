-- Fix user_profiles sync trigger to include ehr_id in data_snapshot
-- Issue: The migration 20251103200000 used to_jsonb(NEW) which only includes
--        columns from user_profiles table, but ehr_id is in electronic_health_records table
-- Fix: Use jsonb_build_object to explicitly include ehr_id

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
    WHEN 'medical_provider' THEN 'medzen.provider.profile.v1'  -- Support both variants
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
  -- ✅ FIX: Use jsonb_build_object to explicitly include ehr_id
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
    'role_profile_create',  -- ✅ Use correct sync_type expected by edge function
    'pending',
    NEW.role,
    jsonb_build_object(
      'user_id', v_user_id,
      'ehr_id', v_ehr_id,  -- ✅ Explicitly include ehr_id from electronic_health_records
      'role', NEW.role,
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

COMMENT ON FUNCTION queue_role_profile_sync IS 'Queues role-specific profile composition for EHRbase sync. Fixed to include ehr_id in data_snapshot.';
