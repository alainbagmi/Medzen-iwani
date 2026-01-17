-- VIDEO CALL TRANSCRIPTION SYSTEM - VALIDATION TEST
-- This script validates the complete transcription system implementation
--
-- Tests performed:
-- 1. Database schema verification
-- 2. Required columns existence
-- 3. Indexes for performance
-- 4. RLS policies for security
-- 5. Triggers for automation

\set ECHO all

-- ================================================================
-- TEST 1: VIDEO_CALL_SESSIONS TABLE SCHEMA
-- ================================================================

\echo ''
\echo '=== TEST 1: VIDEO_CALL_SESSIONS TABLE TRANSCRIPTION COLUMNS ==='

SELECT
  column_name,
  data_type,
  is_nullable,
  CASE
    WHEN column_name ILIKE '%transcription%' THEN '✅ TRANSCRIPTION'
    WHEN column_name = 'live_transcription_enabled' THEN '✅ TRANSCRIPTION'
    WHEN column_name = 'live_transcription_language' THEN '✅ TRANSCRIPTION'
    WHEN column_name = 'live_transcription_engine' THEN '✅ TRANSCRIPTION'
    WHEN column_name = 'live_transcription_medical_vocabulary' THEN '✅ TRANSCRIPTION'
    WHEN column_name = 'transcript' THEN '✅ TRANSCRIPT'
    WHEN column_name = 'speaker_segments' THEN '✅ SPEAKER_SEGMENTS'
    ELSE '--'
  END as transcription_related
FROM information_schema.columns
WHERE table_name = 'video_call_sessions'
  AND (
    column_name ILIKE '%transcription%'
    OR column_name = 'transcript'
    OR column_name = 'speaker_segments'
    OR column_name ILIKE '%live_transcription%'
  )
ORDER BY ordinal_position;

-- ================================================================
-- TEST 2: LIVE_CAPTION_SEGMENTS TABLE
-- ================================================================

\echo ''
\echo '=== TEST 2: LIVE_CAPTION_SEGMENTS TABLE SCHEMA ==='

SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'live_caption_segments'
ORDER BY ordinal_position;

-- ================================================================
-- TEST 3: TRANSCRIPTION_USAGE_DAILY TABLE
-- ================================================================

\echo ''
\echo '=== TEST 3: TRANSCRIPTION_USAGE_DAILY TABLE SCHEMA ==='

SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'transcription_usage_daily'
ORDER BY ordinal_position;

-- ================================================================
-- TEST 4: VERIFY INDEXES FOR PERFORMANCE
-- ================================================================

\echo ''
\echo '=== TEST 4: INDEXES ON TRANSCRIPTION TABLES ==='

SELECT
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename IN (
  'video_call_sessions',
  'live_caption_segments',
  'transcription_usage_daily'
)
ORDER BY tablename, indexname;

-- ================================================================
-- TEST 5: VERIFY RLS POLICIES
-- ================================================================

\echo ''
\echo '=== TEST 5: ROW LEVEL SECURITY POLICIES ==='

SELECT
  tablename,
  policyname,
  cmd,
  SUBSTRING(qual FROM 1 FOR 100) as policy_condition
FROM pg_policies
WHERE tablename IN (
  'video_call_sessions',
  'live_caption_segments',
  'transcription_usage_daily'
)
ORDER BY tablename, policyname;

-- ================================================================
-- TEST 6: CHECK TABLE ROW SECURITY STATUS
-- ================================================================

\echo ''
\echo '=== TEST 6: ROW SECURITY ENABLED STATUS ==='

SELECT
  tablename,
  rowsecurity,
  CASE WHEN rowsecurity THEN '✅ RLS ENABLED' ELSE '❌ RLS DISABLED' END as status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'video_call_sessions',
    'live_caption_segments',
    'transcription_usage_daily'
  );

-- ================================================================
-- TEST 7: VERIFY TRIGGER FUNCTIONS
-- ================================================================

\echo ''
\echo '=== TEST 7: TRIGGER FUNCTIONS FOR TRANSCRIPTION ==='

SELECT
  trigger_name,
  event_object_table,
  event_manipulation,
  action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND (
    event_object_table IN (
      'video_call_sessions',
      'live_caption_segments',
      'transcription_usage_daily'
    )
    OR trigger_name ILIKE '%transcription%'
  )
ORDER BY event_object_table, trigger_name;

-- ================================================================
-- TEST 8: VERIFY FUNCTIONS FOR TRANSCRIPTION
-- ================================================================

\echo ''
\echo '=== TEST 8: DATABASE FUNCTIONS RELATED TO TRANSCRIPTION ==='

SELECT
  routine_name,
  routine_type,
  SUBSTRING(routine_definition FROM 1 FOR 100) as definition_start
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND (
    routine_name ILIKE '%transcription%'
    OR routine_name ILIKE '%caption%'
  )
ORDER BY routine_name;

-- ================================================================
-- TEST 9: SAMPLE DATA CHECK (if any test data exists)
-- ================================================================

\echo ''
\echo '=== TEST 9: SAMPLE VIDEO CALL SESSIONS (Last 5) ==='

SELECT
  id,
  appointment_id,
  chime_meeting_id,
  video_call_status,
  live_transcription_enabled,
  live_transcription_language,
  transcription_status,
  COALESCE(transcript, '[EMPTY]') as transcript_preview,
  created_at
FROM video_call_sessions
ORDER BY created_at DESC
LIMIT 5;

-- ================================================================
-- TEST 10: SAMPLE LIVE CAPTIONS (if any exist)
-- ================================================================

\echo ''
\echo '=== TEST 10: SAMPLE LIVE CAPTION SEGMENTS (Last 10) ==='

SELECT
  id,
  video_call_session_id,
  speaker_name,
  SUBSTRING(transcript_text FROM 1 FOR 50) as caption_text,
  confidence,
  created_at
FROM live_caption_segments
ORDER BY created_at DESC
LIMIT 10;

-- ================================================================
-- TEST 11: COST TRACKING DATA
-- ================================================================

\echo ''
\echo '=== TEST 11: TRANSCRIPTION USAGE & COSTS (Last 7 Days) ==='

SELECT
  usage_date,
  total_sessions,
  total_duration_seconds,
  ROUND(total_cost_usd::numeric, 2) as total_cost,
  successful_transcriptions,
  failed_transcriptions,
  CASE
    WHEN total_sessions > 0 THEN ROUND((successful_transcriptions::numeric / total_sessions * 100)::numeric, 1)
    ELSE 0
  END as success_rate_percent
FROM transcription_usage_daily
WHERE usage_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY usage_date DESC;

-- ================================================================
-- TEST 12: SYSTEM HEALTH CHECK
-- ================================================================

\echo ''
\echo '=== TEST 12: SYSTEM HEALTH SUMMARY ==='

WITH table_checks AS (
  SELECT 'video_call_sessions' as table_name,
         EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_name = 'video_call_sessions') as exists_check
  UNION ALL
  SELECT 'live_caption_segments',
         EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_name = 'live_caption_segments')
  UNION ALL
  SELECT 'transcription_usage_daily',
         EXISTS (SELECT 1 FROM information_schema.tables
                 WHERE table_name = 'transcription_usage_daily')
)
SELECT
  table_name,
  CASE WHEN exists_check THEN '✅ EXISTS' ELSE '❌ MISSING' END as status
FROM table_checks
ORDER BY table_name;

-- ================================================================
-- FINAL SUMMARY
-- ================================================================

\echo ''
\echo '=== TRANSCRIPTION SYSTEM VALIDATION COMPLETE ==='
\echo 'All tests executed successfully!'
\echo 'If all tables and columns are present, system is ready for testing.'
