-- SYSTEM VALIDATION SCRIPT - Pre-Test Verification
-- Run this before executing Test 1 to verify all system components are ready
--
-- This script checks:
-- 1. Medical vocabularies are deployed to AWS Transcribe
-- 2. Database schema is complete
-- 3. Edge functions are deployed
-- 4. RLS policies are configured
-- 5. Cost tracking is enabled

-- ============================================================
-- 1. VERIFY DATABASE SCHEMA
-- ============================================================

-- Check video_call_sessions table has all required columns
\echo ''
\echo '=== CHECKING VIDEO_CALL_SESSIONS TABLE SCHEMA ==='
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'video_call_sessions'
  AND column_name IN (
    'id',
    'appointment_id',
    'chime_meeting_id',
    'video_call_status',
    'live_transcription_enabled',
    'live_transcription_language',
    'live_transcription_engine',
    'live_transcription_medical_vocabulary',
    'live_transcription_medical_entities_enabled',
    'transcription_status',
    'transcription_duration_seconds',
    'transcription_estimated_cost_usd',
    'transcript',
    'speaker_segments'
  )
ORDER BY column_name;

-- Check live_caption_segments table exists and has correct schema
\echo ''
\echo '=== CHECKING LIVE_CAPTION_SEGMENTS TABLE SCHEMA ==='
SELECT
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'live_caption_segments'
ORDER BY ordinal_position;

-- Check transcription_usage_daily table exists
\echo ''
\echo '=== CHECKING TRANSCRIPTION_USAGE_DAILY TABLE SCHEMA ==='
SELECT
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'transcription_usage_daily'
ORDER BY ordinal_position;

-- ============================================================
-- 2. VERIFY RLS POLICIES
-- ============================================================

\echo ''
\echo '=== CHECKING RLS POLICIES ON TRANSCRIPTION TABLES ==='
SELECT
  policyname,
  tablename,
  permissive,
  cmd,
  qual
FROM pg_policies
WHERE tablename IN ('video_call_sessions', 'live_caption_segments', 'transcription_usage_daily')
ORDER BY tablename, policyname;

-- ============================================================
-- 3. VERIFY INDEXES FOR PERFORMANCE
-- ============================================================

\echo ''
\echo '=== CHECKING INDEXES ON TRANSCRIPTION TABLES ==='
SELECT
  schemaname,
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename IN ('video_call_sessions', 'live_caption_segments', 'transcription_usage_daily')
ORDER BY tablename, indexname;

-- ============================================================
-- 4. VERIFY TEST DATA (if any exists)
-- ============================================================

\echo ''
\echo '=== CHECKING FOR EXISTING TEST USERS ==='
SELECT
  id,
  email,
  name,
  role,
  created_at
FROM users
WHERE email LIKE '%test%'
LIMIT 5;

-- ============================================================
-- 5. VERIFY COST LIMITS ARE CONFIGURED
-- ============================================================

\echo ''
\echo '=== CHECKING TRANSCRIPTION COST LIMITS ==='
-- This would be in a transcription_cost_limits table if it exists
-- For now, check if cost tracking structure is in place
SELECT
  table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE '%transcription%'
ORDER BY table_name;

-- ============================================================
-- 6. VERIFY APPOINTMENTS TABLE HAS LANGUAGE CODE
-- ============================================================

\echo ''
\echo '=== CHECKING APPOINTMENTS TABLE FOR LANGUAGE CODE ==='
SELECT
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'appointments'
  AND column_name IN ('language_code', 'appointment_status', 'provider_id', 'patient_id')
ORDER BY column_name;

-- ============================================================
-- 7. VERIFY EDGE FUNCTION DEPLOYMENT
-- ============================================================

\echo ''
\echo '=== SYSTEM VALIDATION SUMMARY ==='
\echo 'To complete validation, run these commands in terminal:'
\echo ''
\echo '# 1. Check edge function exists:'
\echo 'npx supabase functions list | grep start-medical-transcription'
\echo ''
\echo '# 2. Check edge function logs are working:'
\echo 'npx supabase functions logs start-medical-transcription --limit 10'
\echo ''
\echo '# 3. Check AWS vocabularies are READY:'
\echo 'python3 << EOF'
\echo 'import boto3'
\echo 'client = boto3.client("transcribe", region_name="eu-central-1")'
\echo 'vocabs = ['
\echo '  "medzen-medical-vocab-en",'
\echo '  "medzen-medical-vocab-fr",'
\echo '  "medzen-medical-vocab-sw",'
\echo '  "medzen-medical-vocab-zu",'
\echo '  "medzen-medical-vocab-ha",'
\echo '  "medzen-medical-vocab-yo-fallback-en",'
\echo '  "medzen-medical-vocab-ig-fallback-en",'
\echo '  "medzen-medical-vocab-pcm-fallback-en",'
\echo '  "medzen-medical-vocab-ln-fallback-fr",'
\echo '  "medzen-medical-vocab-kg-fallback-fr"'
\echo ']'
\echo 'for vocab in vocabs:'
\echo '  response = client.get_vocabulary(VocabularyName=vocab)'
\echo '  status = response.get("VocabularyState", "UNKNOWN")'
\echo '  ready = "✅" if status == "READY" else "❌"'
\echo '  print(f"{ready} {vocab}: {status}")'
\echo 'EOF'
\echo ''
\echo '=== VALIDATION COMPLETE ==='
\echo 'If all checks passed, system is ready for Test 1 execution'
