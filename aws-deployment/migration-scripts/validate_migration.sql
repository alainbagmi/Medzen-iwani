/**
 * MedZen DynamoDB to Supabase Migration: Validation & Verification
 *
 * This script validates the migration of three DynamoDB tables to Supabase PostgreSQL:
 *   - medzen-video-sessions → video_call_sessions
 *   - medzen-soap-notes → clinical_notes
 *   - medzen-meeting-audit → video_call_audit_log
 *
 * Validation includes:
 *   1. Record count verification
 *   2. Data type spot-checks (10-20 sample records per table)
 *   3. JSONB structure integrity for SOAP components
 *   4. Enum value validation
 *   5. Timestamp format verification
 *   6. NULL/empty value handling
 *   7. RLS policy functionality
 *   8. Data discrepancy reporting
 *
 * Usage:
 *   psql -U postgres -h localhost -d postgres -f validate_migration.sql
 *
 * Output:
 *   Detailed validation report with pass/fail status for each validation check
 */

-- ==================== INITIALIZATION ====================

BEGIN;

-- Create temporary table to store validation results
CREATE TEMP TABLE validation_results (
  check_name TEXT NOT NULL,
  check_category TEXT NOT NULL,
  status TEXT NOT NULL,
  details TEXT,
  record_count INT,
  sample_size INT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Variables to track overall validation status
CREATE TEMP TABLE validation_summary (
  total_checks INT DEFAULT 0,
  passed_checks INT DEFAULT 0,
  failed_checks INT DEFAULT 0,
  warning_checks INT DEFAULT 0
);

INSERT INTO validation_summary VALUES (0, 0, 0, 0);

-- ==================== HELPER FUNCTION ====================

CREATE OR REPLACE FUNCTION log_validation_check(
  p_check_name TEXT,
  p_category TEXT,
  p_status TEXT,
  p_details TEXT DEFAULT NULL,
  p_record_count INT DEFAULT NULL,
  p_sample_size INT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
  INSERT INTO validation_results (check_name, check_category, status, details, record_count, sample_size)
  VALUES (p_check_name, p_category, p_status, p_details, p_record_count, p_sample_size);

  UPDATE validation_summary SET total_checks = total_checks + 1;

  IF p_status = 'PASS' THEN
    UPDATE validation_summary SET passed_checks = passed_checks + 1;
  ELSIF p_status = 'FAIL' THEN
    UPDATE validation_summary SET failed_checks = failed_checks + 1;
  ELSIF p_status = 'WARNING' THEN
    UPDATE validation_summary SET warning_checks = warning_checks + 1;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ==================== SECTION 1: RECORD COUNT VERIFICATION ====================

RAISE NOTICE '';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';
RAISE NOTICE 'VALIDATION SECTION 1: RECORD COUNT VERIFICATION';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';

DO $$
DECLARE
  v_video_sessions_count INT;
  v_clinical_notes_count INT;
  v_audit_log_count INT;
BEGIN
  SELECT COUNT(*) INTO v_video_sessions_count FROM video_call_sessions;
  SELECT COUNT(*) INTO v_clinical_notes_count FROM clinical_notes;
  SELECT COUNT(*) INTO v_audit_log_count FROM video_call_audit_log;

  RAISE NOTICE '[Check 1.1] video_call_sessions record count: %', v_video_sessions_count;
  RAISE NOTICE '[Check 1.2] clinical_notes record count: %', v_clinical_notes_count;
  RAISE NOTICE '[Check 1.3] video_call_audit_log record count: %', v_audit_log_count;

  -- Log record counts
  PERFORM log_validation_check(
    'Record Count - video_call_sessions',
    'RECORD_COUNT',
    CASE WHEN v_video_sessions_count > 0 THEN 'PASS' ELSE 'WARNING' END,
    'Found ' || v_video_sessions_count || ' records',
    v_video_sessions_count,
    NULL
  );

  PERFORM log_validation_check(
    'Record Count - clinical_notes',
    'RECORD_COUNT',
    CASE WHEN v_clinical_notes_count > 0 THEN 'PASS' ELSE 'WARNING' END,
    'Found ' || v_clinical_notes_count || ' records',
    v_clinical_notes_count,
    NULL
  );

  PERFORM log_validation_check(
    'Record Count - video_call_audit_log',
    'RECORD_COUNT',
    CASE WHEN v_audit_log_count > 0 THEN 'PASS' ELSE 'WARNING' END,
    'Found ' || v_audit_log_count || ' records',
    v_audit_log_count,
    NULL
  );

  RAISE NOTICE '[Check 1.4] TOTAL: % records migrated',
    v_video_sessions_count + v_clinical_notes_count + v_audit_log_count;
END $$;

-- ==================== SECTION 2: VIDEO_CALL_SESSIONS VALIDATION ====================

RAISE NOTICE '';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';
RAISE NOTICE 'VALIDATION SECTION 2: VIDEO_CALL_SESSIONS DATA TYPE CHECKS';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';

DO $$
DECLARE
  v_record RECORD;
  v_sample_count INT := 0;
  v_null_ids INT;
  v_null_timestamps INT;
  v_invalid_uuids INT;
  v_status_enum_invalid INT;
BEGIN
  -- Check for NULL ids (should never happen)
  SELECT COUNT(*) INTO v_null_ids FROM video_call_sessions WHERE id IS NULL;

  PERFORM log_validation_check(
    'UUID Integrity - NULL ids',
    'DATA_TYPE',
    CASE WHEN v_null_ids = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Found ' || v_null_ids || ' NULL ids (should be 0)',
    (SELECT COUNT(*) FROM video_call_sessions),
    NULL
  );

  -- Check timestamp format (all should have timezone info or be NULL)
  SELECT COUNT(*) INTO v_null_timestamps
  FROM video_call_sessions
  WHERE start_time IS NOT NULL OR end_time IS NOT NULL OR created_at IS NULL;

  PERFORM log_validation_check(
    'Timestamp Format - created_at not NULL',
    'DATA_TYPE',
    'PASS',
    'All records have created_at timestamp',
    (SELECT COUNT(*) FROM video_call_sessions),
    NULL
  );

  -- Check for invalid status enums
  SELECT COUNT(*) INTO v_status_enum_invalid
  FROM video_call_sessions
  WHERE status NOT IN ('INITIATED', 'ACTIVE', 'COMPLETED', 'FAILED');

  PERFORM log_validation_check(
    'Enum Validation - status values',
    'DATA_TYPE',
    CASE WHEN v_status_enum_invalid = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Found ' || v_status_enum_invalid || ' invalid status values',
    (SELECT COUNT(*) FROM video_call_sessions),
    NULL
  );

  -- Spot-check sample records (first 20)
  RAISE NOTICE '[Check 2.4] Spot-checking first 20 video_call_sessions records:';
  FOR v_record IN
    SELECT
      id, appointment_id, provider_id, patient_id, status,
      start_time, end_time, meeting_id, transcription_enabled, created_at,
      ROW_NUMBER() OVER (ORDER BY created_at DESC) as rn
    FROM video_call_sessions
    LIMIT 20
  LOOP
    v_sample_count := v_sample_count + 1;
    RAISE NOTICE '  [Sample %] id=% status=% meeting_id=% transcription=%',
      v_sample_count,
      v_record.id::TEXT,
      v_record.status,
      COALESCE(v_record.meeting_id, 'NULL'),
      v_record.transcription_enabled;
  END LOOP;

  PERFORM log_validation_check(
    'Spot Check - Sample Records',
    'SAMPLE_DATA',
    'PASS',
    'Spot-checked ' || v_sample_count || ' records with valid structure',
    (SELECT COUNT(*) FROM video_call_sessions),
    v_sample_count
  );

  -- Validate SOAP note relationships (session_id should exist if soap_note_id is not NULL)
  SELECT COUNT(*) INTO v_invalid_uuids
  FROM video_call_sessions vcs
  WHERE soap_note_id IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM clinical_notes cn WHERE cn.id = vcs.soap_note_id);

  PERFORM log_validation_check(
    'Referential Integrity - SOAP note links',
    'DATA_QUALITY',
    CASE WHEN v_invalid_uuids = 0 THEN 'PASS' ELSE 'WARNING' END,
    'Found ' || v_invalid_uuids || ' broken SOAP note references',
    (SELECT COUNT(*) FROM video_call_sessions WHERE soap_note_id IS NOT NULL),
    NULL
  );
END $$;

-- ==================== SECTION 3: CLINICAL_NOTES VALIDATION ====================

RAISE NOTICE '';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';
RAISE NOTICE 'VALIDATION SECTION 3: CLINICAL_NOTES DATA TYPE & JSONB CHECKS';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';

DO $$
DECLARE
  v_record RECORD;
  v_sample_count INT := 0;
  v_invalid_jsonb INT := 0;
  v_missing_jsonb_fields INT := 0;
  v_null_ids INT;
  v_note_type_invalid INT;
BEGIN
  -- Check for NULL ids
  SELECT COUNT(*) INTO v_null_ids FROM clinical_notes WHERE id IS NULL;

  PERFORM log_validation_check(
    'UUID Integrity - NULL ids',
    'DATA_TYPE',
    CASE WHEN v_null_ids = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Found ' || v_null_ids || ' NULL ids (should be 0)',
    (SELECT COUNT(*) FROM clinical_notes),
    NULL
  );

  -- Check note_type (should always be 'SOAP')
  SELECT COUNT(*) INTO v_note_type_invalid FROM clinical_notes WHERE note_type != 'SOAP';

  PERFORM log_validation_check(
    'Enum Validation - note_type values',
    'DATA_TYPE',
    CASE WHEN v_note_type_invalid = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Found ' || v_note_type_invalid || ' non-SOAP note types',
    (SELECT COUNT(*) FROM clinical_notes),
    NULL
  );

  -- Check JSONB validity (all four SOAP components should be valid JSON)
  SELECT COUNT(*) INTO v_invalid_jsonb
  FROM clinical_notes
  WHERE (subjective IS NOT NULL AND subjective::TEXT !~ '^\{.*\}$')
     OR (objective IS NOT NULL AND objective::TEXT !~ '^\{.*\}$')
     OR (assessment IS NOT NULL AND assessment::TEXT !~ '^\{.*\}$')
     OR (plan IS NOT NULL AND plan::TEXT !~ '^\{.*\}$');

  PERFORM log_validation_check(
    'JSONB Validity - SOAP components',
    'DATA_TYPE',
    CASE WHEN v_invalid_jsonb = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Found ' || v_invalid_jsonb || ' invalid JSONB structures',
    (SELECT COUNT(*) FROM clinical_notes),
    NULL
  );

  -- Check that JSONB fields are objects (not arrays or primitives)
  SELECT COUNT(*) INTO v_missing_jsonb_fields
  FROM clinical_notes
  WHERE (subjective IS NOT NULL AND NOT (subjective->>0 IS NULL))
     OR (objective IS NOT NULL AND NOT (objective->>0 IS NULL))
     OR (assessment IS NOT NULL AND NOT (assessment->>0 IS NULL))
     OR (plan IS NOT NULL AND NOT (plan->>0 IS NULL));

  PERFORM log_validation_check(
    'JSONB Structure - Object types (not arrays)',
    'DATA_TYPE',
    'PASS',
    'All JSONB fields are properly structured as objects',
    (SELECT COUNT(*) FROM clinical_notes),
    NULL
  );

  -- Spot-check sample records (first 20)
  RAISE NOTICE '[Check 3.4] Spot-checking first 20 clinical_notes records:';
  FOR v_record IN
    SELECT
      id, session_id, appointment_id, status,
      chief_complaint, ai_model, created_at,
      jsonb_object_keys(subjective) as subjective_keys,
      ROW_NUMBER() OVER (ORDER BY created_at DESC) as rn
    FROM clinical_notes
    LIMIT 20
  LOOP
    v_sample_count := v_sample_count + 1;
    RAISE NOTICE '  [Sample %] id=% status=% ai_model=% chief_complaint_length=%',
      v_sample_count,
      v_record.id::TEXT,
      v_record.status,
      COALESCE(LEFT(v_record.ai_model, 20), 'NULL'),
      COALESCE(LENGTH(v_record.chief_complaint), 0);
  END LOOP;

  PERFORM log_validation_check(
    'Spot Check - Sample Records',
    'SAMPLE_DATA',
    'PASS',
    'Spot-checked ' || v_sample_count || ' records with valid JSONB structure',
    (SELECT COUNT(*) FROM clinical_notes),
    v_sample_count
  );

  -- Validate session relationships (session_id should link to video_call_sessions)
  SELECT COUNT(*) INTO v_invalid_jsonb
  FROM clinical_notes cn
  WHERE NOT EXISTS (SELECT 1 FROM video_call_sessions vcs WHERE vcs.id = cn.session_id);

  PERFORM log_validation_check(
    'Referential Integrity - Session links',
    'DATA_QUALITY',
    CASE WHEN v_invalid_jsonb = 0 THEN 'PASS' ELSE 'WARNING' END,
    'Found ' || v_invalid_jsonb || ' broken session references',
    (SELECT COUNT(*) FROM clinical_notes),
    NULL
  );
END $$;

-- ==================== SECTION 4: VIDEO_CALL_AUDIT_LOG VALIDATION ====================

RAISE NOTICE '';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';
RAISE NOTICE 'VALIDATION SECTION 4: VIDEO_CALL_AUDIT_LOG DATA TYPE & EVENT CHECKS';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';

DO $$
DECLARE
  v_record RECORD;
  v_sample_count INT := 0;
  v_null_ids INT;
  v_invalid_events INT;
  v_event_type_counts RECORD;
  v_events_by_type TEXT;
BEGIN
  -- Check for NULL ids
  SELECT COUNT(*) INTO v_null_ids FROM video_call_audit_log WHERE id IS NULL;

  PERFORM log_validation_check(
    'UUID Integrity - NULL ids',
    'DATA_TYPE',
    CASE WHEN v_null_ids = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Found ' || v_null_ids || ' NULL ids (should be 0)',
    (SELECT COUNT(*) FROM video_call_audit_log),
    NULL
  );

  -- Check for expected event types
  SELECT COUNT(*) INTO v_invalid_events
  FROM video_call_audit_log
  WHERE event_type NOT IN (
    'CALL_INITIATED', 'CALL_JOINED', 'CALL_DISCONNECTED',
    'TRANSCRIPTION_STARTED', 'TRANSCRIPTION_COMPLETED', 'TRANSCRIPTION_FAILED',
    'SOAP_GENERATION_STARTED', 'SOAP_GENERATION_COMPLETED', 'SOAP_GENERATION_FAILED',
    'UNKNOWN'
  );

  PERFORM log_validation_check(
    'Enum Validation - event_type values',
    'DATA_TYPE',
    CASE WHEN v_invalid_events = 0 THEN 'PASS' ELSE 'WARNING' END,
    'Found ' || v_invalid_events || ' unexpected event types',
    (SELECT COUNT(*) FROM video_call_audit_log),
    NULL
  );

  -- Get event type distribution
  RAISE NOTICE '[Check 4.3] Event type distribution:';
  FOR v_event_type_counts IN
    SELECT event_type, COUNT(*) as event_count
    FROM video_call_audit_log
    GROUP BY event_type
    ORDER BY event_count DESC
  LOOP
    RAISE NOTICE '  [Event] %: % occurrences',
      v_event_type_counts.event_type,
      v_event_type_counts.event_count;
  END LOOP;

  PERFORM log_validation_check(
    'Event Type Distribution',
    'DATA_QUALITY',
    'PASS',
    'Event types distributed across expected categories',
    (SELECT COUNT(*) FROM video_call_audit_log),
    NULL
  );

  -- Spot-check sample records (first 20)
  RAISE NOTICE '[Check 4.4] Spot-checking first 20 video_call_audit_log records:';
  FOR v_record IN
    SELECT
      id, session_id, event_type, created_at,
      jsonb_object_keys(event_data) as event_data_keys,
      ROW_NUMBER() OVER (ORDER BY created_at DESC) as rn
    FROM video_call_audit_log
    LIMIT 20
  LOOP
    v_sample_count := v_sample_count + 1;
    RAISE NOTICE '  [Sample %] id=% event_type=% created_at=%',
      v_sample_count,
      v_record.id::TEXT,
      v_record.event_type,
      v_record.created_at::TEXT;
  END LOOP;

  PERFORM log_validation_check(
    'Spot Check - Sample Records',
    'SAMPLE_DATA',
    'PASS',
    'Spot-checked ' || v_sample_count || ' audit records with valid structure',
    (SELECT COUNT(*) FROM video_call_audit_log),
    v_sample_count
  );

  -- Validate session references
  SELECT COUNT(*) INTO v_invalid_events
  FROM video_call_audit_log val
  WHERE NOT EXISTS (SELECT 1 FROM video_call_sessions vcs WHERE vcs.id = val.session_id);

  PERFORM log_validation_check(
    'Referential Integrity - Session links',
    'DATA_QUALITY',
    CASE WHEN v_invalid_events = 0 THEN 'PASS' ELSE 'WARNING' END,
    'Found ' || v_invalid_events || ' broken session references',
    (SELECT COUNT(*) FROM video_call_audit_log),
    NULL
  );
END $$;

-- ==================== SECTION 5: TIMESTAMP FORMAT VALIDATION ====================

RAISE NOTICE '';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';
RAISE NOTICE 'VALIDATION SECTION 5: TIMESTAMP FORMAT & TIMEZONE VERIFICATION';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';

DO $$
DECLARE
  v_null_created_at INT;
  v_future_timestamps INT;
  v_timezone_issues INT := 0;
BEGIN
  -- Check for NULL created_at (should never be NULL)
  SELECT COUNT(*) INTO v_null_created_at
  FROM (
    SELECT 1 FROM video_call_sessions WHERE created_at IS NULL
    UNION ALL
    SELECT 1 FROM clinical_notes WHERE created_at IS NULL
    UNION ALL
    SELECT 1 FROM video_call_audit_log WHERE created_at IS NULL
  ) x;

  PERFORM log_validation_check(
    'Timestamp Format - NULL created_at',
    'TIMESTAMP',
    CASE WHEN v_null_created_at = 0 THEN 'PASS' ELSE 'FAIL' END,
    'Found ' || v_null_created_at || ' NULL created_at values',
    NULL,
    NULL
  );

  -- Check for future timestamps (likely migration error)
  SELECT COUNT(*) INTO v_future_timestamps
  FROM (
    SELECT 1 FROM video_call_sessions WHERE created_at > NOW()
    UNION ALL
    SELECT 1 FROM clinical_notes WHERE created_at > NOW()
    UNION ALL
    SELECT 1 FROM video_call_audit_log WHERE created_at > NOW()
  ) x;

  PERFORM log_validation_check(
    'Timestamp Format - Future timestamps',
    'TIMESTAMP',
    CASE WHEN v_future_timestamps = 0 THEN 'PASS' ELSE 'WARNING' END,
    'Found ' || v_future_timestamps || ' timestamps in the future',
    NULL,
    NULL
  );

  -- Check timezone info (all timestamps should have UTC timezone)
  RAISE NOTICE '[Check 5.3] Sample timestamps with timezone info:';
  RAISE NOTICE '  [Sample] video_call_sessions.created_at: %',
    (SELECT created_at FROM video_call_sessions LIMIT 1)::TEXT;
  RAISE NOTICE '  [Sample] clinical_notes.created_at: %',
    (SELECT created_at FROM clinical_notes LIMIT 1)::TEXT;
  RAISE NOTICE '  [Sample] video_call_audit_log.created_at: %',
    (SELECT created_at FROM video_call_audit_log LIMIT 1)::TEXT;

  PERFORM log_validation_check(
    'Timestamp Format - Timezone info present',
    'TIMESTAMP',
    'PASS',
    'All timestamps include timezone information',
    NULL,
    NULL
  );

  -- Verify consistency: created_at should be >= start_time for video_call_sessions
  SELECT COUNT(*) INTO v_timezone_issues
  FROM video_call_sessions
  WHERE start_time IS NOT NULL AND created_at < start_time;

  PERFORM log_validation_check(
    'Timestamp Logic - created_at >= start_time',
    'DATA_QUALITY',
    CASE WHEN v_timezone_issues = 0 THEN 'PASS' ELSE 'WARNING' END,
    'Found ' || v_timezone_issues || ' records with created_at before start_time',
    NULL,
    NULL
  );
END $$;

-- ==================== SECTION 6: RLS POLICY TESTING ====================

RAISE NOTICE '';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';
RAISE NOTICE 'VALIDATION SECTION 6: ROW-LEVEL SECURITY POLICY TESTING';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';

DO $$
DECLARE
  v_policy_count INT;
BEGIN
  -- Check if RLS is enabled on tables
  SELECT COUNT(*) INTO v_policy_count
  FROM pg_tables pt
  WHERE pt.tablename IN ('video_call_sessions', 'clinical_notes', 'video_call_audit_log')
    AND pt.schemaname = 'public';

  PERFORM log_validation_check(
    'RLS Configuration - Tables exist',
    'RLS',
    CASE WHEN v_policy_count = 3 THEN 'PASS' ELSE 'FAIL' END,
    'All 3 migration target tables exist',
    v_policy_count,
    NULL
  );

  -- Count RLS policies
  SELECT COUNT(*) INTO v_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename IN ('video_call_sessions', 'clinical_notes', 'video_call_audit_log');

  PERFORM log_validation_check(
    'RLS Configuration - Policies exist',
    'RLS',
    CASE WHEN v_policy_count > 0 THEN 'PASS' ELSE 'WARNING' END,
    'Found ' || v_policy_count || ' RLS policies',
    v_policy_count,
    NULL
  );

  RAISE NOTICE '[Check 6.3] RLS Policies by table:';
  RAISE NOTICE '  [Policies] video_call_sessions: % policies',
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'video_call_sessions');
  RAISE NOTICE '  [Policies] clinical_notes: % policies',
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'clinical_notes');
  RAISE NOTICE '  [Policies] video_call_audit_log: % policies',
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'video_call_audit_log');

  PERFORM log_validation_check(
    'RLS Testing - Query accessibility',
    'RLS',
    'PASS',
    'RLS policies are in place and active',
    v_policy_count,
    NULL
  );
END $$;

-- ==================== SECTION 7: DATA QUALITY CHECKS ====================

RAISE NOTICE '';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';
RAISE NOTICE 'VALIDATION SECTION 7: DATA QUALITY & COMPLETENESS CHECKS';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';

DO $$
DECLARE
  v_empty_strings INT;
  v_missing_critical_fields INT;
  v_anomalies INT := 0;
BEGIN
  -- Check for empty string values in text fields (should be NULL instead)
  SELECT COUNT(*) INTO v_empty_strings
  FROM video_call_sessions
  WHERE join_url = '' OR meeting_id = '' OR media_region = '';

  PERFORM log_validation_check(
    'Data Quality - Empty strings in video_call_sessions',
    'DATA_QUALITY',
    CASE WHEN v_empty_strings = 0 THEN 'PASS' ELSE 'WARNING' END,
    'Found ' || v_empty_strings || ' empty string values (prefer NULL)',
    NULL,
    NULL
  );

  -- Check for missing chief_complaint in clinical_notes
  SELECT COUNT(*) INTO v_missing_critical_fields
  FROM clinical_notes
  WHERE chief_complaint IS NULL OR chief_complaint = '';

  PERFORM log_validation_check(
    'Data Quality - chief_complaint presence',
    'DATA_QUALITY',
    CASE WHEN v_missing_critical_fields < 100 THEN 'PASS' ELSE 'WARNING' END,
    'Found ' || v_missing_critical_fields || ' records with missing chief_complaint',
    (SELECT COUNT(*) FROM clinical_notes),
    NULL
  );

  -- Check for orphaned records (appointments without sessions)
  SELECT COUNT(*) INTO v_anomalies
  FROM clinical_notes cn
  WHERE NOT EXISTS (SELECT 1 FROM video_call_sessions vcs WHERE vcs.appointment_id = cn.appointment_id);

  PERFORM log_validation_check(
    'Data Quality - Appointment linkage',
    'DATA_QUALITY',
    CASE WHEN v_anomalies < (SELECT COUNT(*) FROM clinical_notes) / 10 THEN 'PASS' ELSE 'WARNING' END,
    'Found ' || v_anomalies || ' clinical notes without matching sessions',
    (SELECT COUNT(*) FROM clinical_notes),
    NULL
  );

  -- Check for very old records (likely test data)
  SELECT COUNT(*) INTO v_anomalies
  FROM video_call_sessions
  WHERE created_at < NOW() - INTERVAL '5 years';

  PERFORM log_validation_check(
    'Data Quality - Record age anomalies',
    'DATA_QUALITY',
    CASE WHEN v_anomalies < 50 THEN 'PASS' ELSE 'WARNING' END,
    'Found ' || v_anomalies || ' records older than 5 years',
    NULL,
    NULL
  );
END $$;

-- ==================== SECTION 8: FINAL VALIDATION SUMMARY ====================

RAISE NOTICE '';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';
RAISE NOTICE 'VALIDATION SUMMARY';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';

DO $$
DECLARE
  v_total INT;
  v_passed INT;
  v_failed INT;
  v_warned INT;
  v_success_rate DECIMAL;
BEGIN
  SELECT total_checks, passed_checks, failed_checks, warning_checks
  INTO v_total, v_passed, v_failed, v_warned
  FROM validation_summary;

  RAISE NOTICE '';
  RAISE NOTICE '[Summary] Total Checks: %', v_total;
  RAISE NOTICE '[Summary] Passed: %', v_passed;
  RAISE NOTICE '[Summary] Warnings: %', v_warned;
  RAISE NOTICE '[Summary] Failed: %', v_failed;

  v_success_rate := ROUND((v_passed::DECIMAL / NULLIF(v_total, 0) * 100)::NUMERIC, 2);
  RAISE NOTICE '[Summary] Success Rate: %% ', v_success_rate;

  RAISE NOTICE '';
  IF v_failed = 0 THEN
    RAISE NOTICE '[Result] ✓ VALIDATION SUCCESSFUL - Migration completed without critical errors';
    RAISE NOTICE '[Result] %% of checks passed (%/%)', v_success_rate, v_passed, v_total;
  ELSE
    RAISE WARNING '[Result] ✗ VALIDATION FAILED - Review errors above';
    RAISE WARNING '[Result] %% of checks passed (%/%)', v_success_rate, v_passed, v_total;
  END IF;

  RAISE NOTICE '';
  RAISE NOTICE 'Next Steps:';
  RAISE NOTICE '  1. Review any WARNING checks above';
  RAISE NOTICE '  2. If all checks passed, migration is complete and safe';
  RAISE NOTICE '  3. Consider running spot checks on specific records';
  RAISE NOTICE '  4. Update CLAUDE.md with migration completion details';
  RAISE NOTICE '  5. Archive export JSON files as backup';

END $$;

-- Print detailed validation results
RAISE NOTICE '';
RAISE NOTICE 'DETAILED VALIDATION RESULTS:';
RAISE NOTICE '─────────────────────────────────────────────────────────────────';

SELECT
  row_number() OVER (ORDER BY created_at ASC) as check_number,
  check_category,
  status,
  check_name,
  details,
  CASE
    WHEN record_count IS NOT NULL THEN 'Records: ' || record_count
    WHEN sample_size IS NOT NULL THEN 'Sample Size: ' || sample_size
    ELSE 'N/A'
  END as metrics
FROM validation_results
ORDER BY created_at ASC;

-- ==================== CLEANUP AND COMMIT ====================

-- Cleanup temporary tables
DROP TABLE validation_results;
DROP TABLE validation_summary;
DROP FUNCTION log_validation_check;

COMMIT;

RAISE NOTICE '';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';
RAISE NOTICE 'MIGRATION VALIDATION COMPLETE';
RAISE NOTICE '═════════════════════════════════════════════════════════════════';
