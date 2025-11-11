-- Fix record_id UUID type mismatch in queue_role_profile_sync function
-- Issue: record_id column is UUID type but function was casting NEW.id::TEXT causing type mismatch
-- Error: column "record_id" is of type uuid but expression is of type text

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
    NEW.id,  -- ✅ FIXED: Removed ::TEXT cast - record_id expects UUID type
    v_template_id,
    'composition_create',
    'pending',
    NEW.role,
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION queue_role_profile_sync IS 'Fixed record_id type - removed ::TEXT cast to match UUID column type in ehrbase_sync_queue';
