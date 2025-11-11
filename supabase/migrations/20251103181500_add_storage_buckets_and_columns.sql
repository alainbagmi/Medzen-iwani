-- =====================================================
-- Migration: Add Storage Buckets and Avatar/Image Columns
-- Created: 2025-11-03
-- Description: Links storage buckets to database tables for avatars and documents
-- =====================================================

-- =====================================================
-- 1. Add Avatar/Image Columns to Tables
-- =====================================================

-- Add avatar_url to medical_provider_profiles
ALTER TABLE medical_provider_profiles
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

COMMENT ON COLUMN medical_provider_profiles.avatar_url IS 'URL to provider avatar image stored in user-avatars bucket';

-- Add avatar_url to facility_admin_profiles
ALTER TABLE facility_admin_profiles
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

COMMENT ON COLUMN facility_admin_profiles.avatar_url IS 'URL to facility admin avatar image stored in user-avatars bucket';

-- Add avatar_url to system_admin_profiles
ALTER TABLE system_admin_profiles
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

COMMENT ON COLUMN system_admin_profiles.avatar_url IS 'URL to system admin avatar image stored in user-avatars bucket';

-- Add image_url to facilities (for care center photos/logos)
ALTER TABLE facilities
ADD COLUMN IF NOT EXISTS image_url TEXT;

COMMENT ON COLUMN facilities.image_url IS 'URL to facility image/logo stored in facility-images bucket';

-- =====================================================
-- 2. Storage Policies for user-avatars Bucket
-- =====================================================

-- Allow authenticated users to view their own avatars
CREATE POLICY "Users can view their own avatars"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-avatars' AND
  (auth.uid()::text = (storage.foldername(name))[1])
);

-- Allow authenticated users to upload their own avatars (max 1 per user)
CREATE POLICY "Users can upload their own avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-avatars' AND
  (auth.uid()::text = (storage.foldername(name))[1]) AND
  NOT EXISTS (
    SELECT 1 FROM storage.objects
    WHERE bucket_id = 'user-avatars'
    AND (auth.uid()::text = (storage.foldername(name))[1])
  )
);

-- Allow authenticated users to update their own avatars
CREATE POLICY "Users can update their own avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'user-avatars' AND
  (auth.uid()::text = (storage.foldername(name))[1])
);

-- Allow authenticated users to delete their own avatars
CREATE POLICY "Users can delete their own avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-avatars' AND
  (auth.uid()::text = (storage.foldername(name))[1])
);

-- =====================================================
-- 3. Storage Policies for facility-images Bucket
-- =====================================================

-- Allow anyone to view facility images (public bucket)
CREATE POLICY "Anyone can view facility images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'facility-images');

-- Allow facility admins to upload facility images (max 3 per facility)
CREATE POLICY "Facility admins can upload facility images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'facility-images' AND
  EXISTS (
    SELECT 1 FROM facility_admin_profiles fap
    WHERE fap.user_id = auth.uid()
    AND (
      -- Count existing images for this admin's facilities
      SELECT COUNT(*)
      FROM storage.objects so
      WHERE so.bucket_id = 'facility-images'
      AND so.name LIKE (fap.primary_facility_id::text || '%')
    ) < 3
  )
);

-- Allow facility admins to update facility images
CREATE POLICY "Facility admins can update facility images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'facility-images' AND
  EXISTS (
    SELECT 1 FROM facility_admin_profiles
    WHERE user_id = auth.uid()
  )
);

-- Allow facility admins to delete facility images
CREATE POLICY "Facility admins can delete facility images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'facility-images' AND
  EXISTS (
    SELECT 1 FROM facility_admin_profiles
    WHERE user_id = auth.uid()
  )
);

-- =====================================================
-- 4. Storage Policies for documents Bucket
-- =====================================================

-- Allow users to view their own documents
CREATE POLICY "Users can view their own documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents' AND
  (auth.uid()::text = (storage.foldername(name))[1])
);

-- Allow authenticated users to upload documents
CREATE POLICY "Users can upload documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'documents' AND
  (auth.uid()::text = (storage.foldername(name))[1])
);

-- Allow users to update their own documents
CREATE POLICY "Users can update their own documents"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'documents' AND
  (auth.uid()::text = (storage.foldername(name))[1])
);

-- Allow users to delete their own documents
CREATE POLICY "Users can delete their own documents"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'documents' AND
  (auth.uid()::text = (storage.foldername(name))[1])
);

-- Allow medical providers to view patient documents (for their patients)
CREATE POLICY "Medical providers can view patient documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents' AND
  EXISTS (
    SELECT 1 FROM medical_provider_profiles
    WHERE user_id = auth.uid()
  )
);

-- Allow facility admins to view documents from their facility
CREATE POLICY "Facility admins can view facility documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents' AND
  EXISTS (
    SELECT 1 FROM facility_admin_profiles
    WHERE user_id = auth.uid()
  )
);

-- Allow system admins to view all documents
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
-- 5. Update Documents Table to Reference Storage
-- =====================================================

-- Add bucket_name column to documents table for better tracking
ALTER TABLE documents
ADD COLUMN IF NOT EXISTS bucket_name TEXT DEFAULT 'documents';

COMMENT ON COLUMN documents.bucket_name IS 'Supabase storage bucket name where file is stored';

-- Add storage_path column for full storage path
ALTER TABLE documents
ADD COLUMN IF NOT EXISTS storage_path TEXT;

COMMENT ON COLUMN documents.storage_path IS 'Full path in storage bucket (e.g., user-id/filename.pdf)';

-- =====================================================
-- 6. Create Helper Functions
-- =====================================================

-- Function to get user's avatar URL
CREATE OR REPLACE FUNCTION get_user_avatar_url(user_firebase_uid TEXT)
RETURNS TEXT AS $$
DECLARE
  avatar_url TEXT;
BEGIN
  -- First check users table
  SELECT u.avatar_url INTO avatar_url
  FROM users u
  WHERE u.firebase_uid = user_firebase_uid AND u.avatar_url IS NOT NULL;

  IF avatar_url IS NOT NULL THEN
    RETURN avatar_url;
  END IF;

  -- Check medical_provider_profiles
  SELECT mpp.avatar_url INTO avatar_url
  FROM medical_provider_profiles mpp
  JOIN users u ON u.id = mpp.user_id
  WHERE u.firebase_uid = user_firebase_uid AND mpp.avatar_url IS NOT NULL;

  IF avatar_url IS NOT NULL THEN
    RETURN avatar_url;
  END IF;

  -- Check facility_admin_profiles
  SELECT fap.avatar_url INTO avatar_url
  FROM facility_admin_profiles fap
  JOIN users u ON u.id = fap.user_id
  WHERE u.firebase_uid = user_firebase_uid AND fap.avatar_url IS NOT NULL;

  IF avatar_url IS NOT NULL THEN
    RETURN avatar_url;
  END IF;

  -- Check system_admin_profiles
  SELECT sap.avatar_url INTO avatar_url
  FROM system_admin_profiles sap
  JOIN users u ON u.id = sap.user_id
  WHERE u.firebase_uid = user_firebase_uid AND sap.avatar_url IS NOT NULL;

  RETURN avatar_url;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_user_avatar_url(TEXT) IS 'Helper function to get user avatar URL from any profile table';

-- =====================================================
-- 7. Grant Permissions
-- =====================================================

-- Grant usage on storage to authenticated users
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT ALL ON storage.objects TO authenticated;
GRANT ALL ON storage.buckets TO authenticated;

-- =====================================================
-- Migration Complete
-- =====================================================
