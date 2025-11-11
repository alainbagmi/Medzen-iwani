-- Fix all queue trigger functions to use SECURITY DEFINER
-- Problem: 23 trigger functions are SECURITY INVOKER, causing RLS violations
-- Solution: Add SECURITY DEFINER to all queue_* functions

-- This script adds SECURITY DEFINER to all queue functions that insert into ehrbase_sync_queue
-- Functions already fixed: queue_role_profile_sync, queue_user_demographics_for_sync, queue_payment_for_sync

DO $$
DECLARE
  func_name text;
  func_names text[] := ARRAY[
    'queue_admission_discharges_for_sync',
    'queue_antenatal_visits_for_sync',
    'queue_cardiology_visits_for_sync',
    'queue_clinical_consultations_for_sync',
    'queue_emergency_visits_for_sync',
    'queue_endocrinology_visits_for_sync',
    'queue_for_ehrbase_sync',
    'queue_gastroenterology_procedures_for_sync',
    'queue_infectious_disease_visits_for_sync',
    'queue_lab_results_for_sync',
    'queue_medication_dispensing_for_sync',
    'queue_nephrology_visits_for_sync',
    'queue_neurology_exams_for_sync',
    'queue_oncology_treatments_for_sync',
    'queue_pathology_reports_for_sync',
    'queue_pharmacy_stock_for_sync',
    'queue_physiotherapy_sessions_for_sync',
    'queue_prescriptions_for_sync',
    'queue_psychiatric_assessments_for_sync',
    'queue_pulmonology_visits_for_sync',
    'queue_radiology_reports_for_sync',
    'queue_surgical_procedures_for_sync',
    'queue_vital_signs_for_sync'
  ];
BEGIN
  FOREACH func_name IN ARRAY func_names LOOP
    -- Add SECURITY DEFINER to each function
    EXECUTE format('
      ALTER FUNCTION %I() SECURITY DEFINER;
      ALTER FUNCTION %I() OWNER TO postgres;
      ALTER FUNCTION %I() SET search_path = public;
    ', func_name, func_name, func_name);

    RAISE NOTICE 'Fixed function: %', func_name;
  END LOOP;
END $$;

-- Verify all queue functions now have SECURITY DEFINER
DO $$
DECLARE
  invoker_count integer;
BEGIN
  SELECT COUNT(*) INTO invoker_count
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname = 'public'
    AND p.proname LIKE 'queue_%'
    AND p.prosecdef = false;

  IF invoker_count > 0 THEN
    RAISE WARNING '% queue functions still have SECURITY INVOKER', invoker_count;
  ELSE
    RAISE NOTICE 'All queue functions now have SECURITY DEFINER ✅';
  END IF;
END $$;

COMMENT ON FUNCTION queue_admission_discharges_for_sync IS 'Queues admission/discharge records for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_antenatal_visits_for_sync IS 'Queues antenatal visits for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_cardiology_visits_for_sync IS 'Queues cardiology visits for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_clinical_consultations_for_sync IS 'Queues clinical consultations for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_emergency_visits_for_sync IS 'Queues emergency visits for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_endocrinology_visits_for_sync IS 'Queues endocrinology visits for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_for_ehrbase_sync IS 'Generic queue function for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_gastroenterology_procedures_for_sync IS 'Queues gastroenterology procedures for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_infectious_disease_visits_for_sync IS 'Queues infectious disease visits for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_lab_results_for_sync IS 'Queues lab results for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_medication_dispensing_for_sync IS 'Queues medication dispensing records for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_nephrology_visits_for_sync IS 'Queues nephrology visits for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_neurology_exams_for_sync IS 'Queues neurology exams for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_oncology_treatments_for_sync IS 'Queues oncology treatments for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_pathology_reports_for_sync IS 'Queues pathology reports for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_pharmacy_stock_for_sync IS 'Queues pharmacy stock records for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_physiotherapy_sessions_for_sync IS 'Queues physiotherapy sessions for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_prescriptions_for_sync IS 'Queues prescriptions for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_psychiatric_assessments_for_sync IS 'Queues psychiatric assessments for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_pulmonology_visits_for_sync IS 'Queues pulmonology visits for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_radiology_reports_for_sync IS 'Queues radiology reports for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_surgical_procedures_for_sync IS 'Queues surgical procedures for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
COMMENT ON FUNCTION queue_vital_signs_for_sync IS 'Queues vital signs for EHRbase sync. Uses SECURITY DEFINER to bypass RLS.';
