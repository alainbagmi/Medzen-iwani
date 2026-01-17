-- Test script to verify RLS policies for video call messaging
-- Run this in Supabase SQL Editor to verify policies work correctly
--
-- Prerequisites:
-- 1. Have at least one video_call_session with provider_id and patient_id
-- 2. Have at least one message in chime_messages linked to that session

-- ============================================================================
-- PART 1: Verify video_call_sessions RLS Policies
-- ============================================================================

-- Check if RLS is enabled on video_call_sessions
SELECT
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'video_call_sessions';

-- List all RLS policies on video_call_sessions
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'video_call_sessions'
ORDER BY policyname;

-- ============================================================================
-- PART 2: Verify chime_messages RLS Policies
-- ============================================================================

-- Check if RLS is enabled on chime_messages
SELECT
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'chime_messages';

-- List all RLS policies on chime_messages
SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'chime_messages'
ORDER BY policyname;

-- ============================================================================
-- PART 3: Test Data Queries (without RLS - as superuser)
-- ============================================================================

-- Find recent video call sessions with participants
SELECT
    id,
    meeting_id,
    appointment_id,
    provider_id,
    patient_id,
    status,
    created_at
FROM video_call_sessions
WHERE created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC
LIMIT 5;

-- Find messages linked to video call sessions
SELECT
    cm.id,
    cm.channel_arn,
    cm.channel_id,
    cm.sender_id,
    cm.user_id,
    cm.message_type,
    SUBSTRING(cm.message_content, 1, 50) as message_preview,
    cm.created_at,
    vcs.provider_id,
    vcs.patient_id
FROM chime_messages cm
LEFT JOIN video_call_sessions vcs ON (
    vcs.meeting_id = cm.channel_arn
    OR vcs.meeting_id = cm.channel_id
)
WHERE cm.created_at > NOW() - INTERVAL '7 days'
ORDER BY cm.created_at DESC
LIMIT 10;

-- ============================================================================
-- PART 4: Verify Indexes for Performance
-- ============================================================================

-- Check indexes on video_call_sessions
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename = 'video_call_sessions'
AND (
    indexname LIKE '%meeting%'
    OR indexname LIKE '%provider%'
    OR indexname LIKE '%patient%'
)
ORDER BY indexname;

-- Check indexes on chime_messages
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename = 'chime_messages'
AND (
    indexname LIKE '%channel%'
    OR indexname LIKE '%sender%'
    OR indexname LIKE '%user%'
)
ORDER BY indexname;

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
--
-- 1. video_call_sessions should have RLS enabled (rls_enabled = true)
-- 2. Should see 4 policies on video_call_sessions:
--    - Participants can view their video call sessions (SELECT)
--    - Authenticated users can create video call sessions (INSERT)
--    - Participants can update their video call sessions (UPDATE)
--    - Participants can delete their video call sessions (DELETE)
--
-- 3. chime_messages should have RLS enabled (rls_enabled = true)
-- 4. Should see 4 policies on chime_messages:
--    - Users can view messages in video calls (SELECT)
--    - Users can send messages when authenticated (INSERT)
--    - Users can update their own messages in video calls (UPDATE)
--    - Users can delete their own messages in video calls (DELETE)
--
-- 5. Should see performance indexes:
--    - idx_video_call_sessions_meeting_participants
--    - idx_chime_messages_channel_lookup
--    - idx_chime_messages_sender_lookup
--
-- 6. Query plans should show index usage (not sequential scans)
--
-- ============================================================================
