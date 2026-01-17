-- Complete Verification Script for Chime Messages Setup
-- Run this in Supabase SQL Editor to verify everything is configured correctly
-- Date: 2025-12-17

\echo '=========================================='
\echo 'Chime Messages Setup Verification'
\echo '=========================================='
\echo ''

-- ============================================================================
-- 1. Verify Table Structure
-- ============================================================================

\echo '1. TABLE COLUMNS'
\echo '---'

SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'chime_messages'
ORDER BY ordinal_position;

\echo ''
\echo 'Expected: 12 columns including channel_id, message_type, sender_id, message_content'
\echo ''

-- ============================================================================
-- 2. Verify Constraints
-- ============================================================================

\echo '2. TABLE CONSTRAINTS'
\echo '---'

SELECT
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'public.chime_messages'::regclass
ORDER BY conname;

\echo ''
\echo 'Expected: message_type CHECK constraint with (text, system, file, image)'
\echo ''

-- ============================================================================
-- 3. Verify RLS Policies
-- ============================================================================

\echo '3. RLS POLICIES'
\echo '---'

SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as command,
    qual::text as using_expression,
    with_check::text as with_check_expression
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'chime_messages'
ORDER BY policyname;

\echo ''
\echo 'Expected: 4 policies (INSERT, SELECT, UPDATE, DELETE)'
\echo '- INSERT: "Authenticated users can insert messages with valid IDs"'
\echo '- SELECT: "Video call participants can view messages"'
\echo '- UPDATE: "Users can update their own messages"'
\echo '- DELETE: "Users can delete their own messages"'
\echo ''

-- ============================================================================
-- 4. Verify Indexes
-- ============================================================================

\echo '4. TABLE INDEXES'
\echo '---'

SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename = 'chime_messages'
ORDER BY indexname;

\echo ''
\echo 'Expected: 3+ indexes including:'
\echo '- idx_chime_messages_channel_id_created (composite)'
\echo '- idx_chime_messages_sender_id'
\echo ''

-- ============================================================================
-- 5. Verify Storage Bucket
-- ============================================================================

\echo '5. STORAGE BUCKET'
\echo '---'

SELECT
    id,
    name,
    owner,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets
WHERE id = 'chime_storage';

\echo ''
\echo 'Expected: chime_storage bucket with public=true, 50MB limit'
\echo ''

-- ============================================================================
-- 6. Check Recent Messages (if any exist)
-- ============================================================================

\echo '6. RECENT MESSAGES (if any)'
\echo '---'

SELECT
    id,
    message_type,
    LEFT(message_content, 50) as content_preview,
    sender_id,
    channel_id,
    created_at
FROM chime_messages
ORDER BY created_at DESC
LIMIT 5;

\echo ''
\echo 'If no messages, table is empty (expected for new setup)'
\echo ''

-- ============================================================================
-- 7. Check Storage Objects (if any exist)
-- ============================================================================

\echo '7. STORAGE OBJECTS (if any)'
\echo '---'

SELECT
    name,
    bucket_id,
    owner,
    (metadata->>'size')::bigint as file_size_bytes,
    created_at
FROM storage.objects
WHERE bucket_id = 'chime_storage'
ORDER BY created_at DESC
LIMIT 5;

\echo ''
\echo 'If no objects, storage is empty (expected for new setup)'
\echo ''

-- ============================================================================
-- 8. Verify Message Type Constraint
-- ============================================================================

\echo '8. MESSAGE TYPE CONSTRAINT DETAILS'
\echo '---'

SELECT
    conname,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'public.chime_messages'::regclass
AND conname = 'chime_messages_type_check';

\echo ''
\echo 'Expected: CHECK (message_type = ANY (ARRAY[''text'', ''system'', ''file'', ''image'']))'
\echo ''

-- ============================================================================
-- 9. Test Query Performance (optional)
-- ============================================================================

\echo '9. TEST QUERY PERFORMANCE'
\echo '---'

EXPLAIN ANALYZE
SELECT *
FROM chime_messages
WHERE channel_id = 'test-channel-123'
ORDER BY created_at DESC
LIMIT 10;

\echo ''
\echo 'Expected: Index scan using idx_chime_messages_channel_id_created'
\echo ''

-- ============================================================================
-- Summary
-- ============================================================================

\echo '=========================================='
\echo 'VERIFICATION COMPLETE'
\echo '=========================================='
\echo ''
\echo 'Next Steps:'
\echo '1. Verify all expected items are present above'
\echo '2. Configure storage RLS policies in Supabase Dashboard'
\echo '3. Test in Flutter app (see CHIME_MESSAGES_SCHEMA_UPDATE_SUMMARY.md)'
\echo ''
\echo 'Documentation:'
\echo '- CHIME_MESSAGES_SCHEMA_UPDATE_SUMMARY.md'
\echo '- ENHANCED_CHIME_USAGE_GUIDE.md'
\echo '- test_chime_messaging.sh (bash test script)'
\echo ''
