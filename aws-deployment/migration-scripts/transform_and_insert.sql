/**
 * MedZen DynamoDB to Supabase Migration: Transform and Insert
 *
 * This script transforms exported DynamoDB JSON data and inserts it into Supabase PostgreSQL tables.
 *
 * Usage:
 *   1. Export DynamoDB tables: python3 export_dynamodb_tables.py
 *   2. Create temporary staging tables for JSON import
 *   3. Import JSON files into staging tables
 *   4. Run this transformation script
 *   5. Run validate_migration.sql to verify
 *
 * Pre-requisites:
 *   - All Supabase target tables exist (video_call_sessions, clinical_notes, video_call_audit_log)
 *   - JSON files exported from DynamoDB
 *   - Temporary staging tables created
 */

-- ==================== SAFETY CHECKS ====================

-- Ensure we're not dropping any existing data
BEGIN;

-- Check target tables exist and are empty
DO $$
DECLARE
  v_video_sessions_count INT;
  v_clinical_notes_count INT;
  v_audit_log_count INT;
BEGIN
  SELECT COUNT(*) INTO v_video_sessions_count FROM video_call_sessions;
  SELECT COUNT(*) INTO v_clinical_notes_count FROM clinical_notes;
  SELECT COUNT(*) INTO v_audit_log_count FROM video_call_audit_log;

  IF v_video_sessions_count > 0 OR v_clinical_notes_count > 0 OR v_audit_log_count > 0 THEN
    RAISE EXCEPTION 'Target tables are not empty. Migration aborted for safety.
      video_call_sessions: % rows
      clinical_notes: % rows
      video_call_audit_log: % rows',
      v_video_sessions_count, v_clinical_notes_count, v_audit_log_count;
  END IF;

  RAISE NOTICE '[Migration] Safety check passed - target tables are empty';
END $$;

-- ==================== TEMPORARY STAGING TABLES ====================

-- Create staging table for raw video_call_sessions JSON import
CREATE TEMP TABLE stg_video_sessions_json (
  data JSONB NOT NULL
);

-- Create staging table for raw clinical_notes JSON import
CREATE TEMP TABLE stg_clinical_notes_json (
  data JSONB NOT NULL
);

-- Create staging table for raw video_call_audit_log JSON import
CREATE TEMP TABLE stg_audit_log_json (
  data JSONB NOT NULL
);

-- ==================== MIGRATION: medzen-video-sessions → video_call_sessions ====================

RAISE NOTICE '[Migration] Starting migration of video_call_sessions...';

INSERT INTO video_call_sessions (
  id,
  appointment_id,
  provider_id,
  patient_id,
  status,
  start_time,
  end_time,
  join_url,
  meeting_id,
  media_region,
  transcription_enabled,
  transcript_id,
  transcript_language,
  soap_note_id,
  finalization_status,
  created_at,
  updated_at
)
SELECT
  -- Direct UUID fields
  (data->>'id')::UUID as id,
  (data->>'appointmentId')::UUID as appointment_id,
  (data->>'providerId')::UUID as provider_id,
  (data->>'patientId')::UUID as patient_id,

  -- Status enum
  COALESCE(data->>'status', 'INITIATED')::TEXT as status,

  -- Timestamp conversion: DynamoDB milliseconds → PostgreSQL TIMESTAMP WITH TIME ZONE
  CASE
    WHEN data->>'startTime' IS NULL OR data->>'startTime' = '' THEN NULL
    WHEN (data->>'startTime')::BIGINT = 0 THEN NULL
    ELSE to_timestamp((data->>'startTime')::BIGINT / 1000.0) AT TIME ZONE 'UTC'
  END as start_time,

  CASE
    WHEN data->>'endTime' IS NULL OR data->>'endTime' = '' THEN NULL
    WHEN (data->>'endTime')::BIGINT = 0 THEN NULL
    ELSE to_timestamp((data->>'endTime')::BIGINT / 1000.0) AT TIME ZONE 'UTC'
  END as end_time,

  -- String fields
  data->>'joinUrl' as join_url,
  data->>'meetingId' as meeting_id,
  data->>'mediaRegion' as media_region,

  -- Boolean fields
  COALESCE((data->>'transcriptionEnabled')::BOOLEAN, false) as transcription_enabled,

  -- UUID fields with NULL handling
  CASE
    WHEN data->>'transcriptId' IS NULL OR data->>'transcriptId' = '' THEN NULL
    ELSE (data->>'transcriptId')::UUID
  END as transcript_id,

  data->>'transcriptLanguage' as transcript_language,

  CASE
    WHEN data->>'soapNoteId' IS NULL OR data->>'soapNoteId' = '' THEN NULL
    ELSE (data->>'soapNoteId')::UUID
  END as soap_note_id,

  data->>'finalizationStatus' as finalization_status,

  -- Timestamp fields with UTC timezone
  CASE
    WHEN data->>'createdAt' IS NULL OR data->>'createdAt' = '' THEN NOW() AT TIME ZONE 'UTC'
    WHEN (data->>'createdAt')::BIGINT = 0 THEN NOW() AT TIME ZONE 'UTC'
    ELSE to_timestamp((data->>'createdAt')::BIGINT / 1000.0) AT TIME ZONE 'UTC'
  END as created_at,

  CASE
    WHEN data->>'updatedAt' IS NULL OR data->>'updatedAt' = '' THEN NOW() AT TIME ZONE 'UTC'
    WHEN (data->>'updatedAt')::BIGINT = 0 THEN NOW() AT TIME ZONE 'UTC'
    ELSE to_timestamp((data->>'updatedAt')::BIGINT / 1000.0) AT TIME ZONE 'UTC'
  END as updated_at
FROM stg_video_sessions_json
ON CONFLICT (id) DO NOTHING;

-- Log migration results
DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM video_call_sessions;
  RAISE NOTICE '[Migration] ✓ Inserted % video_call_sessions records', v_count;
END $$;

-- ==================== MIGRATION: medzen-soap-notes → clinical_notes ====================

RAISE NOTICE '[Migration] Starting migration of clinical_notes...';

INSERT INTO clinical_notes (
  id,
  session_id,
  appointment_id,
  note_type,
  status,
  chief_complaint,
  subjective,
  objective,
  assessment,
  plan,
  ai_model,
  ai_generated_at,
  created_at,
  updated_at
)
SELECT
  -- Direct UUID fields
  (data->>'id')::UUID as id,
  (data->>'sessionId')::UUID as session_id,
  (data->>'appointmentId')::UUID as appointment_id,

  -- Note type (always SOAP for this migration)
  'SOAP'::TEXT as note_type,

  -- Status enum
  COALESCE(data->>'status', 'DRAFT')::TEXT as status,

  -- Chief complaint extracted from nested soapData
  CASE
    WHEN data->'soapData'->>'chiefComplaint' IS NOT NULL THEN data->'soapData'->>'chiefComplaint'
    ELSE ''::TEXT
  END as chief_complaint,

  -- JSONB nested objects - convert to JSONB, default to empty object
  CASE
    WHEN data->'soapData'->'subjective' IS NOT NULL THEN data->'soapData'->'subjective'
    ELSE '{}'::JSONB
  END as subjective,

  CASE
    WHEN data->'soapData'->'objective' IS NOT NULL THEN data->'soapData'->'objective'
    ELSE '{}'::JSONB
  END as objective,

  CASE
    WHEN data->'soapData'->'assessment' IS NOT NULL THEN data->'soapData'->'assessment'
    ELSE '{}'::JSONB
  END as assessment,

  CASE
    WHEN data->'soapData'->'plan' IS NOT NULL THEN data->'soapData'->'plan'
    ELSE '{}'::JSONB
  END as plan,

  -- AI model string
  data->>'aiModel' as ai_model,

  -- Timestamp fields with UTC timezone
  CASE
    WHEN data->>'aiGeneratedAt' IS NULL OR data->>'aiGeneratedAt' = '' THEN NULL
    WHEN (data->>'aiGeneratedAt')::BIGINT = 0 THEN NULL
    ELSE to_timestamp((data->>'aiGeneratedAt')::BIGINT / 1000.0) AT TIME ZONE 'UTC'
  END as ai_generated_at,

  CASE
    WHEN data->>'createdAt' IS NULL OR data->>'createdAt' = '' THEN NOW() AT TIME ZONE 'UTC'
    WHEN (data->>'createdAt')::BIGINT = 0 THEN NOW() AT TIME ZONE 'UTC'
    ELSE to_timestamp((data->>'createdAt')::BIGINT / 1000.0) AT TIME ZONE 'UTC'
  END as created_at,

  CASE
    WHEN data->>'updatedAt' IS NULL OR data->>'updatedAt' = '' THEN NOW() AT TIME ZONE 'UTC'
    WHEN (data->>'updatedAt')::BIGINT = 0 THEN NOW() AT TIME ZONE 'UTC'
    ELSE to_timestamp((data->>'updatedAt')::BIGINT / 1000.0) AT TIME ZONE 'UTC'
  END as updated_at
FROM stg_clinical_notes_json
ON CONFLICT (id) DO NOTHING;

-- Log migration results
DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM clinical_notes;
  RAISE NOTICE '[Migration] ✓ Inserted % clinical_notes records', v_count;
END $$;

-- ==================== MIGRATION: medzen-meeting-audit → video_call_audit_log ====================

RAISE NOTICE '[Migration] Starting migration of video_call_audit_log...';

INSERT INTO video_call_audit_log (
  id,
  session_id,
  event_type,
  event_data,
  created_at
)
SELECT
  -- Direct UUID fields
  (data->>'id')::UUID as id,
  (data->>'sessionId')::UUID as session_id,

  -- Event type enum (uppercase)
  UPPER(COALESCE(data->>'eventType', 'UNKNOWN'))::TEXT as event_type,

  -- Event data as JSONB
  CASE
    WHEN data->'eventData' IS NOT NULL THEN data->'eventData'
    ELSE '{}'::JSONB
  END as event_data,

  -- Timestamp - use later of timestamp or createdAt
  CASE
    WHEN data->>'createdAt' IS NOT NULL AND (data->>'createdAt')::BIGINT > 0
      THEN to_timestamp((data->>'createdAt')::BIGINT / 1000.0) AT TIME ZONE 'UTC'
    WHEN data->>'timestamp' IS NOT NULL AND (data->>'timestamp')::BIGINT > 0
      THEN to_timestamp((data->>'timestamp')::BIGINT / 1000.0) AT TIME ZONE 'UTC'
    ELSE NOW() AT TIME ZONE 'UTC'
  END as created_at
FROM stg_audit_log_json
ON CONFLICT (id) DO NOTHING;

-- Log migration results
DO $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM video_call_audit_log;
  RAISE NOTICE '[Migration] ✓ Inserted % video_call_audit_log records', v_count;
END $$;

-- ==================== FINAL VALIDATION ====================

RAISE NOTICE '[Migration] Migration complete. Running final validation...';

DO $$
DECLARE
  v_video_sessions_count INT;
  v_clinical_notes_count INT;
  v_audit_log_count INT;
BEGIN
  SELECT COUNT(*) INTO v_video_sessions_count FROM video_call_sessions;
  SELECT COUNT(*) INTO v_clinical_notes_count FROM clinical_notes;
  SELECT COUNT(*) INTO v_audit_log_count FROM video_call_audit_log;

  RAISE NOTICE '[Migration] ═════════════════════════════════════════════════════════';
  RAISE NOTICE '[Migration] MIGRATION RESULTS:';
  RAISE NOTICE '[Migration] ─────────────────────────────────────────────────────────';
  RAISE NOTICE '[Migration] video_call_sessions:  % records inserted', v_video_sessions_count;
  RAISE NOTICE '[Migration] clinical_notes:      % records inserted', v_clinical_notes_count;
  RAISE NOTICE '[Migration] video_call_audit_log: % records inserted', v_audit_log_count;
  RAISE NOTICE '[Migration] ─────────────────────────────────────────────────────────';
  RAISE NOTICE '[Migration] TOTAL:                % records',
    v_video_sessions_count + v_clinical_notes_count + v_audit_log_count;
  RAISE NOTICE '[Migration] ═════════════════════════════════════════════════════════';

  IF v_video_sessions_count > 0 AND v_clinical_notes_count > 0 THEN
    RAISE NOTICE '[Migration] ✓ SUCCESS - All migrations completed';
    RAISE NOTICE '[Migration] Next: Run validate_migration.sql to verify data integrity';
  ELSE
    RAISE WARNING '[Migration] ⚠ INCOMPLETE - Check if staging tables were populated correctly';
  END IF;
END $$;

-- ==================== CLEANUP ====================

-- Drop temporary staging tables (automatic with TEMP)
-- Clean up is automatic when transaction ends

COMMIT;

-- ==================== INSTRUCTIONS FOR MANUAL DATA IMPORT ====================

/*
To import JSON data into staging tables, use the following SQL commands
(adjust file paths as needed):

-- For video_call_sessions:
INSERT INTO stg_video_sessions_json (data)
SELECT jsonb_array_elements(data)
FROM (
  SELECT data::JSONB as data
  FROM (
    SELECT $$[{"id": "...", "appointmentId": "..."}]$$::JSONB as data
  ) x
) y;

-- For clinical_notes:
INSERT INTO stg_clinical_notes_json (data)
SELECT jsonb_array_elements(data)
FROM (
  SELECT data::JSONB as data
  FROM (
    SELECT $$[{"id": "...", "sessionId": "..."}]$$::JSONB as data
  ) x
) y;

-- For video_call_audit_log:
INSERT INTO stg_audit_log_json (data)
SELECT jsonb_array_elements(data)
FROM (
  SELECT data::JSONB as data
  FROM (
    SELECT $$[{"id": "...", "sessionId": "..."}]$$::JSONB as data
  ) x
) y;

If using psql with file input, you can pipe the JSON files through jq to format them
as proper PostgreSQL SQL insert statements.
*/
