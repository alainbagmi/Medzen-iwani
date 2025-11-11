-- Add Role-Based EHR Support Migration
-- This migration enables role-aware EHR composition creation for all 4 user types

-- =====================================================
-- 1. Add user_role and primary_template_id columns
-- =====================================================

ALTER TABLE electronic_health_records
ADD COLUMN IF NOT EXISTS user_role VARCHAR(50),
ADD COLUMN IF NOT EXISTS primary_template_id VARCHAR(255);

-- Create indexes for role-based queries
CREATE INDEX IF NOT EXISTS idx_electronic_health_records_user_role
ON electronic_health_records(user_role);

CREATE INDEX IF NOT EXISTS idx_electronic_health_records_template
ON electronic_health_records(primary_template_id);

-- Add user_role to sync queue for role-specific processing
ALTER TABLE ehrbase_sync_queue
ADD COLUMN IF NOT EXISTS user_role VARCHAR(50),
ADD COLUMN IF NOT EXISTS composition_category VARCHAR(100);

CREATE INDEX IF NOT EXISTS idx_ehrbase_sync_queue_user_role
ON ehrbase_sync_queue(user_role);

-- =====================================================
-- 2. Create function to queue role-specific profile creation
-- =====================================================

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
  WHERE patient_id = v_user_id::TEXT;

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
  WHERE patient_id = v_user_id::TEXT;

  -- Queue role-specific profile composition
  INSERT INTO ehrbase_sync_queue (
    table_name,
    record_id,
    template_id,
    sync_type,
    sync_status,
    user_role,
    composition_category,
    data_snapshot,
    created_at,
    updated_at
  )
  VALUES (
    'user_profiles',
    v_user_id::TEXT,
    v_template_id,
    'role_profile_create',
    'pending',
    NEW.role,
    CASE NEW.role
      WHEN 'patient' THEN 'demographics'
      WHEN 'provider' THEN 'professional_profile'
      WHEN 'facility_admin' THEN 'facility_management'
      WHEN 'system_admin' THEN 'admin_profile'
    END,
    jsonb_build_object(
      'user_id', v_user_id,
      'ehr_id', v_ehr_id,
      'role', NEW.role,
      'profile_data', row_to_json(NEW.*)
    ),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type)
  DO UPDATE SET
    sync_status = 'pending',
    user_role = EXCLUDED.user_role,
    data_snapshot = EXCLUDED.data_snapshot,
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RAISE NOTICE 'Queued role profile sync for user % with role %', v_user_id, NEW.role;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. Create trigger on user_profiles.role UPDATE
-- =====================================================

DROP TRIGGER IF EXISTS trigger_queue_role_profile_sync ON user_profiles;

CREATE TRIGGER trigger_queue_role_profile_sync
  AFTER INSERT OR UPDATE OF role ON user_profiles
  FOR EACH ROW
  WHEN (NEW.role IS NOT NULL AND NEW.role != '')
  EXECUTE FUNCTION queue_role_profile_sync();

-- =====================================================
-- 4. Backfill existing records (optional)
-- =====================================================

-- Update existing EHRs with role from user_profiles
UPDATE electronic_health_records ehr
SET
  user_role = up.role,
  primary_template_id = CASE up.role
    WHEN 'patient' THEN 'medzen.patient.demographics.v1'
    WHEN 'provider' THEN 'medzen.provider.profile.v1'
    WHEN 'facility_admin' THEN 'medzen.facility.profile.v1'
    WHEN 'system_admin' THEN 'medzen.admin.profile.v1'
  END,
  updated_at = NOW()
FROM user_profiles up
WHERE ehr.patient_id::TEXT = up.user_id::TEXT
  AND up.role IS NOT NULL
  AND up.role != ''
  AND ehr.user_role IS NULL; -- Only backfill records without role

-- =====================================================
-- 5. Create view for role-based EHR monitoring
-- =====================================================

CREATE OR REPLACE VIEW v_ehr_by_role AS
SELECT
  user_role,
  COUNT(*) as ehr_count,
  COUNT(DISTINCT primary_template_id) as unique_templates,
  COUNT(*) FILTER (WHERE ehr_status = 'active') as active_count,
  COUNT(*) FILTER (WHERE created_at > NOW() - INTERVAL '7 days') as created_last_week,
  MIN(created_at) as first_created,
  MAX(created_at) as last_created
FROM electronic_health_records
WHERE user_role IS NOT NULL
GROUP BY user_role
ORDER BY user_role;

-- Grant permissions
GRANT SELECT ON v_ehr_by_role TO authenticated, service_role;

-- =====================================================
-- 6. Create helper function to get role statistics
-- =====================================================

CREATE OR REPLACE FUNCTION get_ehr_role_statistics()
RETURNS TABLE (
  role VARCHAR,
  total_ehrs BIGINT,
  pending_syncs BIGINT,
  completed_syncs BIGINT,
  failed_syncs BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(ehr.user_role, 'unknown') as role,
    COUNT(DISTINCT ehr.id) as total_ehrs,
    COUNT(DISTINCT sq.id) FILTER (WHERE sq.sync_status = 'pending') as pending_syncs,
    COUNT(DISTINCT sq.id) FILTER (WHERE sq.sync_status = 'completed') as completed_syncs,
    COUNT(DISTINCT sq.id) FILTER (WHERE sq.sync_status = 'failed') as failed_syncs
  FROM electronic_health_records ehr
  LEFT JOIN ehrbase_sync_queue sq ON sq.data_snapshot->>'ehr_id' = ehr.ehr_id
  GROUP BY ehr.user_role
  ORDER BY total_ehrs DESC;
END;
$$ LANGUAGE plpgsql;

-- Grant execution
GRANT EXECUTE ON FUNCTION get_ehr_role_statistics() TO authenticated, service_role;

-- =====================================================
-- Success Message
-- =====================================================

DO $$
BEGIN
  RAISE NOTICE '✅ Role-based EHR support migration completed successfully';
  RAISE NOTICE '📊 Run SELECT * FROM v_ehr_by_role to see role distribution';
  RAISE NOTICE '📈 Run SELECT * FROM get_ehr_role_statistics() for detailed stats';
END $$;
