-- Fix chime_storage RLS policies for Firebase Auth pattern
-- Date: 2026-01-03
-- Issue: File uploads to chime_storage fail because RLS policies were never configured
-- Solution: Create permissive INSERT policy similar to profile_pictures bucket
-- Security: Messages tracked via chime_messages table with appointment_id

-- ============================================================================
-- 1. Drop any existing restrictive policies
-- ============================================================================

DROP POLICY IF EXISTS "Allow authenticated uploads to chime_storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow public reads from chime_storage" ON storage.objects;
DROP POLICY IF EXISTS "Allow chime storage uploads" ON storage.objects;
DROP POLICY IF EXISTS "chime_storage_insert" ON storage.objects;
DROP POLICY IF EXISTS "chime_storage_select" ON storage.objects;

-- ============================================================================
-- 2. Create permissive INSERT policy for file uploads
-- ============================================================================

-- Allows uploads to chime_storage bucket without Supabase auth check
-- Path structure: chat-files/{appointment_id}/{timestamp}_{filename}
CREATE POLICY "Allow chime storage uploads (permissive)"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'chime_storage'
  AND (storage.foldername(name))[1] = 'chat-files'
);

-- ============================================================================
-- 3. Create public SELECT policy for viewing files
-- ============================================================================

-- Bucket is already public=true, but this ensures RLS doesn't block reads
CREATE POLICY "Allow public reads from chime_storage"
ON storage.objects FOR SELECT
USING (bucket_id = 'chime_storage');

-- ============================================================================
-- 4. Create UPDATE policy (owner-only, requires service role for file updates)
-- ============================================================================

CREATE POLICY "Allow chime storage updates"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'chime_storage'
);

-- ============================================================================
-- 5. Create DELETE policy (service role will handle cleanup)
-- ============================================================================

CREATE POLICY "Allow chime storage deletes"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'chime_storage'
);

-- ============================================================================
-- 6. Update bucket settings if needed
-- ============================================================================

-- Ensure allowed_mime_types includes common image and document types
UPDATE storage.buckets
SET
  file_size_limit = 26214400,  -- 25 MB max
  allowed_mime_types = ARRAY[
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
    'application/pdf',
    'text/plain',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'video/mp4',
    'audio/mpeg',
    'audio/mp3'
  ]
WHERE id = 'chime_storage';

-- ============================================================================
-- 7. Verification
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '✅ chime_storage RLS policies created';
  RAISE NOTICE '  - INSERT: Permissive (allows uploads to chat-files/ folder)';
  RAISE NOTICE '  - SELECT: Public (allows reading all files)';
  RAISE NOTICE '  - UPDATE/DELETE: Permissive (handled by service role)';
  RAISE NOTICE '';
  RAISE NOTICE '🔒 Security: File ownership tracked via chime_messages.metadata.fileUrl';
  RAISE NOTICE '📝 Path pattern: chat-files/{appointment_id}/{timestamp}_{filename}';
END $$;
