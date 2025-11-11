-- PowerSync Multi-Role Support via Materialized Views
-- This migration creates optimized views for complex role-based data access
-- These views solve PowerSync's limitation on subqueries in sync rules

-- =====================================================
-- 1. PROVIDER ACCESSIBLE PATIENTS VIEW
-- =====================================================
-- Shows which patients each provider can access (via appointments)

CREATE MATERIALIZED VIEW IF NOT EXISTS v_provider_accessible_patients AS
SELECT DISTINCT
    mpp.user_id as provider_user_id,
    mpp.id as provider_id,
    a.patient_id,
    u.id as patient_user_id,
    u.first_name as patient_first_name,
    u.last_name as patient_last_name,
    u.date_of_birth as patient_dob,
    u.gender as patient_gender,
    pp.blood_type,
    pp.emergency_contact_name,
    pp.emergency_contact_phone,
    MAX(a.scheduled_start) as last_appointment_date,
    COUNT(a.id) as total_appointments
FROM medical_provider_profiles mpp
INNER JOIN appointments a ON a.provider_id = mpp.id
INNER JOIN users u ON a.patient_id::uuid = u.id
LEFT JOIN patient_profiles pp ON pp.user_id = a.patient_id
GROUP BY
    mpp.user_id,
    mpp.id,
    a.patient_id,
    u.id,
    u.first_name,
    u.last_name,
    u.date_of_birth,
    u.gender,
    pp.blood_type,
    pp.emergency_contact_name,
    pp.emergency_contact_phone;

CREATE UNIQUE INDEX IF NOT EXISTS idx_v_provider_patients_provider_patient
    ON v_provider_accessible_patients(provider_user_id, patient_id);

CREATE INDEX IF NOT EXISTS idx_v_provider_patients_provider
    ON v_provider_accessible_patients(provider_user_id);

COMMENT ON MATERIALIZED VIEW v_provider_accessible_patients IS
    'Providers can access patient demographics for patients they have appointments with';

-- =====================================================
-- 2. PROVIDER ACCESSIBLE VITAL SIGNS VIEW
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS v_provider_accessible_vital_signs AS
SELECT
    vap.provider_user_id,
    vap.provider_id,
    vs.*
FROM v_provider_accessible_patients vap
INNER JOIN vital_signs vs ON vs.patient_id = vap.patient_id;

CREATE INDEX IF NOT EXISTS idx_v_provider_vital_signs_provider
    ON v_provider_accessible_vital_signs(provider_user_id);

CREATE INDEX IF NOT EXISTS idx_v_provider_vital_signs_patient
    ON v_provider_accessible_vital_signs(patient_id);

COMMENT ON MATERIALIZED VIEW v_provider_accessible_vital_signs IS
    'Vital signs accessible to providers based on patient relationships';

-- =====================================================
-- 3. PROVIDER ACCESSIBLE LAB RESULTS VIEW
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS v_provider_accessible_lab_results AS
SELECT
    vap.provider_user_id,
    vap.provider_id,
    lr.*
FROM v_provider_accessible_patients vap
INNER JOIN lab_results lr ON lr.patient_id = vap.patient_id;

CREATE INDEX IF NOT EXISTS idx_v_provider_lab_results_provider
    ON v_provider_accessible_lab_results(provider_user_id);

CREATE INDEX IF NOT EXISTS idx_v_provider_lab_results_patient
    ON v_provider_accessible_lab_results(patient_id);

COMMENT ON MATERIALIZED VIEW v_provider_accessible_lab_results IS
    'Lab results accessible to providers based on patient relationships';

-- =====================================================
-- 4. PROVIDER ACCESSIBLE PRESCRIPTIONS VIEW
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS v_provider_accessible_prescriptions AS
SELECT
    vap.provider_user_id,
    vap.provider_id,
    p.*
FROM v_provider_accessible_patients vap
INNER JOIN prescriptions p ON p.patient_id = vap.patient_id;

CREATE INDEX IF NOT EXISTS idx_v_provider_prescriptions_provider
    ON v_provider_accessible_prescriptions(provider_user_id);

CREATE INDEX IF NOT EXISTS idx_v_provider_prescriptions_patient
    ON v_provider_accessible_prescriptions(patient_id);

COMMENT ON MATERIALIZED VIEW v_provider_accessible_prescriptions IS
    'Prescriptions accessible to providers based on patient relationships';

-- =====================================================
-- 5. PROVIDER ACCESSIBLE MEDICAL RECORDS VIEW
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS v_provider_accessible_medical_records AS
SELECT
    vap.provider_user_id,
    vap.provider_id,
    mr.*
FROM v_provider_accessible_patients vap
INNER JOIN medical_records mr ON mr.patient_id = vap.patient_id;

CREATE INDEX IF NOT EXISTS idx_v_provider_medical_records_provider
    ON v_provider_accessible_medical_records(provider_user_id);

CREATE INDEX IF NOT EXISTS idx_v_provider_medical_records_patient
    ON v_provider_accessible_medical_records(patient_id);

COMMENT ON MATERIALIZED VIEW v_provider_accessible_medical_records IS
    'Medical records accessible to providers based on patient relationships';

-- =====================================================
-- 6. PROVIDER APPOINTMENTS VIEW
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS v_provider_appointments AS
SELECT
    mpp.user_id as provider_user_id,
    mpp.id as provider_id,
    a.*
FROM medical_provider_profiles mpp
INNER JOIN appointments a ON a.provider_id = mpp.id;

CREATE INDEX IF NOT EXISTS idx_v_provider_appointments_provider
    ON v_provider_appointments(provider_user_id);

COMMENT ON MATERIALIZED VIEW v_provider_appointments IS
    'All appointments for each provider';

-- =====================================================
-- 7. FACILITY ADMIN ACCESSIBLE DATA VIEW
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS v_facility_admin_accessible_appointments AS
SELECT
    fap.user_id as admin_user_id,
    fap.facility_id,
    a.*
FROM facility_admin_profiles fap
INNER JOIN appointments a ON a.facility_id = fap.facility_id;

CREATE INDEX IF NOT EXISTS idx_v_facility_admin_appointments_admin
    ON v_facility_admin_accessible_appointments(admin_user_id);

CREATE INDEX IF NOT EXISTS idx_v_facility_admin_appointments_facility
    ON v_facility_admin_accessible_appointments(facility_id);

COMMENT ON MATERIALIZED VIEW v_facility_admin_accessible_appointments IS
    'All appointments at facilities managed by this admin';

-- =====================================================
-- 8. FACILITY ADMIN ACCESSIBLE PROVIDERS VIEW
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS v_facility_admin_accessible_providers AS
SELECT
    fap.user_id as admin_user_id,
    fap.facility_id,
    fp.provider_id,
    mpp.*
FROM facility_admin_profiles fap
INNER JOIN facility_providers fp ON fp.facility_id = fap.facility_id
INNER JOIN medical_provider_profiles mpp ON mpp.id = fp.provider_id;

CREATE INDEX IF NOT EXISTS idx_v_facility_admin_providers_admin
    ON v_facility_admin_accessible_providers(admin_user_id);

COMMENT ON MATERIALIZED VIEW v_facility_admin_accessible_providers IS
    'All providers working at facilities managed by this admin';

-- =====================================================
-- 9. FACILITY ADMIN ACCESSIBLE PATIENTS VIEW
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS v_facility_admin_accessible_patients AS
SELECT DISTINCT
    fap.user_id as admin_user_id,
    fap.facility_id,
    a.patient_id,
    u.*
FROM facility_admin_profiles fap
INNER JOIN appointments a ON a.facility_id = fap.facility_id
INNER JOIN users u ON u.id::text = a.patient_id;

CREATE UNIQUE INDEX IF NOT EXISTS idx_v_facility_admin_patients_admin_patient
    ON v_facility_admin_accessible_patients(admin_user_id, patient_id);

COMMENT ON MATERIALIZED VIEW v_facility_admin_accessible_patients IS
    'All patients with appointments at facilities managed by this admin';

-- =====================================================
-- 10. REFRESH FUNCTION FOR ALL VIEWS
-- =====================================================

CREATE OR REPLACE FUNCTION refresh_powersync_materialized_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY v_provider_accessible_patients;
    REFRESH MATERIALIZED VIEW CONCURRENTLY v_provider_accessible_vital_signs;
    REFRESH MATERIALIZED VIEW CONCURRENTLY v_provider_accessible_lab_results;
    REFRESH MATERIALIZED VIEW CONCURRENTLY v_provider_accessible_prescriptions;
    REFRESH MATERIALIZED VIEW CONCURRENTLY v_provider_accessible_medical_records;
    REFRESH MATERIALIZED VIEW CONCURRENTLY v_provider_appointments;
    REFRESH MATERIALIZED VIEW CONCURRENTLY v_facility_admin_accessible_appointments;
    REFRESH MATERIALIZED VIEW CONCURRENTLY v_facility_admin_accessible_providers;
    REFRESH MATERIALIZED VIEW CONCURRENTLY v_facility_admin_accessible_patients;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION refresh_powersync_materialized_views() IS
    'Refresh all PowerSync materialized views. Call this periodically (e.g., every 5 minutes) via cron or Edge Function';

-- =====================================================
-- 11. AUTOMATIC REFRESH TRIGGER (OPTIONAL)
-- =====================================================
-- NOTE: For large datasets, consider using pg_cron or a scheduled Edge Function instead

-- Example: Refresh every 5 minutes using pg_cron (if installed)
-- SELECT cron.schedule(
--     'refresh-powersync-views',
--     '*/5 * * * *',  -- Every 5 minutes
--     'SELECT refresh_powersync_materialized_views();'
-- );

-- =====================================================
-- 12. GRANT PERMISSIONS
-- =====================================================

-- Allow PostgreSQL user (used by PowerSync) to read these views
GRANT SELECT ON v_provider_accessible_patients TO postgres;
GRANT SELECT ON v_provider_accessible_vital_signs TO postgres;
GRANT SELECT ON v_provider_accessible_lab_results TO postgres;
GRANT SELECT ON v_provider_accessible_prescriptions TO postgres;
GRANT SELECT ON v_provider_accessible_medical_records TO postgres;
GRANT SELECT ON v_provider_appointments TO postgres;
GRANT SELECT ON v_facility_admin_accessible_appointments TO postgres;
GRANT SELECT ON v_facility_admin_accessible_providers TO postgres;
GRANT SELECT ON v_facility_admin_accessible_patients TO postgres;

-- Allow authenticated users to call refresh function
GRANT EXECUTE ON FUNCTION refresh_powersync_materialized_views() TO authenticated;

-- =====================================================
-- USAGE INSTRUCTIONS
-- =====================================================
--
-- 1. Run this migration:
--    npx supabase db push
--
-- 2. Initial refresh:
--    SELECT refresh_powersync_materialized_views();
--
-- 3. Set up automatic refresh (choose one):
--
--    Option A: pg_cron (requires extension)
--      CREATE EXTENSION IF NOT EXISTS pg_cron;
--      SELECT cron.schedule(
--          'refresh-powersync-views',
--          '*/5 * * * *',
--          'SELECT refresh_powersync_materialized_views();'
--      );
--
--    Option B: Supabase Edge Function (recommended)
--      Create an Edge Function that runs on a schedule:
--      - Create supabase/functions/refresh-powersync-views/index.ts
--      - Schedule it via Supabase cron or external scheduler
--
-- 4. Update PowerSync sync rules to use these views
--    See POWERSYNC_SYNC_RULES_COMPLETE.yaml
--
-- =====================================================
