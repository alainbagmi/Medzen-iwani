-- Create chime_storage bucket for video call chat file uploads
-- Date: 2025-12-17
--
-- Purpose: Support file/image sharing in ChimeMeetingEnhanced widget chat
--
-- Changes:
-- 1. Create chime_storage bucket if it doesn't exist
-- 2. Set public access for the bucket
-- 3. Configure RLS policies for authenticated uploads
-- 4. Set appropriate file size limits

-- ============================================================================
-- 1. Create storage bucket
-- ============================================================================

-- Note: Supabase storage bucket creation is idempotent
-- Using storage.buckets table to check and insert if needed
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'chime_storage',
    'chime_storage',
    true,  -- Public bucket for easy access to chat images
    52428800,  -- 50 MB max file size
    ARRAY[
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp',
        'application/pdf',
        'text/plain',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ]
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 2. Storage RLS Policies (MANUAL SETUP REQUIRED)
-- ============================================================================

-- NOTE: Storage RLS policies CANNOT be created via SQL migrations.
-- They must be configured through the Supabase Dashboard or Management API.
--
-- To configure storage policies in Supabase Dashboard:
-- 1. Go to Storage > Policies
-- 2. Create the following policies for the chime_storage bucket:
--
-- Policy 1: "Allow authenticated uploads to chime_storage"
--    Operation: INSERT
--    Policy definition: bucket_id = 'chime_storage'
--
-- Policy 2: "Allow public reads from chime_storage"
--    Operation: SELECT
--    Policy definition: bucket_id = 'chime_storage'
--
-- Policy 3: "Allow users to update their own files"
--    Operation: UPDATE
--    Policy definition: bucket_id = 'chime_storage' AND auth.uid() = owner
--
-- Policy 4: "Allow users to delete their own files"
--    Operation: DELETE
--    Policy definition: bucket_id = 'chime_storage' AND auth.uid() = owner
--
-- Alternative: Since bucket is public=true, RLS policies may not be strictly
-- required for SELECT operations. However, they provide additional security
-- for INSERT/UPDATE/DELETE operations.

-- ============================================================================
-- 4. Migration verification query
-- ============================================================================

-- Run this to verify the migration succeeded:
--
-- SELECT id, name, public, file_size_limit, allowed_mime_types
-- FROM storage.buckets
-- WHERE id = 'chime_storage';
--
-- SELECT policyname, cmd
-- FROM pg_policies
-- WHERE tablename = 'objects' AND schemaname = 'storage'
-- AND policyname LIKE '%chime_storage%';
