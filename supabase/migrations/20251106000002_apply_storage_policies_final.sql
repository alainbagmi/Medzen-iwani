-- =====================================================
-- Migration: Apply Storage Policies with User Directories
-- Created: 2025-11-06
-- Description: Replaces all storage policies with user-directory aware policies
-- Features:
--   - User avatars: 1 per user, in user/{uid}/ directory
--   - Facility images: Max 3 per facility, in facility/{facility_id}/ directory
--   - Documents: Unlimited per user, in user/{uid}/ directory
-- =====================================================

-- =====================================================
-- 1. Drop ALL Existing Policies
-- =====================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects') LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', r.policyname);
    END LOOP;
END $$;

-- =====================================================
-- 2. RLS Policies for user-avatars Bucket
-- =====================================================

-- Users can view their own avatars (requires auth)
CREATE POLICY "Users can view own avatars"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Public can view all avatars (for displaying profile pictures)
CREATE POLICY "Public can view user avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'user-avatars');

-- Users can upload avatars to their own directory
-- Path format: user-avatars/{user_firebase_uid}/filename.jpg
CREATE POLICY "Users can upload own avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can update their own avatars
CREATE POLICY "Users can update own avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'user-avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can delete their own avatars
CREATE POLICY "Users can delete own avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- =====================================================
-- 3. RLS Policies for facility-images Bucket
-- =====================================================

-- Public can view all facility images
CREATE POLICY "Public can view facility images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'facility-images');

-- Facility admins can upload images (max 3 per facility)
-- Path format: facility-images/{facility_id}/filename.jpg
CREATE POLICY "Facility admins can upload images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'facility-images' AND
  EXISTS (
    SELECT 1 FROM facility_admin_profiles fap
    WHERE fap.user_id = auth.uid()
    AND (storage.foldername(name))[1] = fap.primary_facility_id::text
    -- Enforce max 3 images per facility
    AND (
      SELECT COUNT(*)
      FROM storage.objects so
      WHERE so.bucket_id = 'facility-images'
      AND (storage.foldername(so.name))[1] = fap.primary_facility_id::text
    ) < 3
  )
);

-- Facility admins can update their facility images
CREATE POLICY "Facility admins can update images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'facility-images' AND
  EXISTS (
    SELECT 1 FROM facility_admin_profiles fap
    WHERE fap.user_id = auth.uid()
    AND (storage.foldername(name))[1] = fap.primary_facility_id::text
  )
);

-- Facility admins can delete their facility images
CREATE POLICY "Facility admins can delete images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'facility-images' AND
  EXISTS (
    SELECT 1 FROM facility_admin_profiles fap
    WHERE fap.user_id = auth.uid()
    AND (storage.foldername(name))[1] = fap.primary_facility_id::text
  )
);

-- =====================================================
-- 4. RLS Policies for documents Bucket
-- =====================================================

-- Users can view their own documents
-- Path format: documents/{user_firebase_uid}/filename.pdf
CREATE POLICY "Users can view own documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can upload unlimited documents to their own directory
CREATE POLICY "Users can upload own documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'documents' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can update their own documents
CREATE POLICY "Users can update own documents"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'documents' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Users can delete their own documents
CREATE POLICY "Users can delete own documents"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'documents' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Medical providers can view all patient documents (for patient care)
CREATE POLICY "Medical providers can view all documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents' AND
  EXISTS (
    SELECT 1 FROM medical_provider_profiles
    WHERE user_id = auth.uid()
  )
);

-- Facility admins can view all documents in their facility
CREATE POLICY "Facility admins can view all documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents' AND
  EXISTS (
    SELECT 1 FROM facility_admin_profiles
    WHERE user_id = auth.uid()
  )
);

-- System admins can view all documents
CREATE POLICY "System admins can view all documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents' AND
  EXISTS (
    SELECT 1 FROM system_admin_profiles
    WHERE user_id = auth.uid()
  )
);

-- =====================================================
-- 5. Helper Functions
-- =====================================================

-- Function to build storage path for user avatars
CREATE OR REPLACE FUNCTION get_user_avatar_storage_path(user_firebase_uid TEXT, filename TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN user_firebase_uid || '/' || filename;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_user_avatar_storage_path(TEXT, TEXT) IS 'Builds storage path: {user_id}/{filename}';

-- Function to build storage path for facility images
CREATE OR REPLACE FUNCTION get_facility_image_storage_path(facility_uuid UUID, filename TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN facility_uuid::text || '/' || filename;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_facility_image_storage_path(UUID, TEXT) IS 'Builds storage path: {facility_id}/{filename}';

-- Function to build storage path for documents
CREATE OR REPLACE FUNCTION get_document_storage_path(user_firebase_uid TEXT, filename TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN user_firebase_uid || '/' || filename;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_document_storage_path(TEXT, TEXT) IS 'Builds storage path: {user_id}/{filename}';

-- Function to count facility images
CREATE OR REPLACE FUNCTION count_facility_images(facility_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM storage.objects
    WHERE bucket_id = 'facility-images'
    AND (storage.foldername(name))[1] = facility_uuid::text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION count_facility_images(UUID) IS 'Returns count of images for a facility (max 3 allowed)';

-- =====================================================
-- Migration Complete
-- =====================================================

-- Expected directory structures:
-- ✅ user-avatars/{user_firebase_uid}/filename.jpg
-- ✅ facility-images/{facility_id}/filename.jpg (max 3 per facility)
-- ✅ documents/{user_firebase_uid}/filename.pdf (unlimited)
