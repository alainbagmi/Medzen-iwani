-- =====================================================
-- Migration: Fix Storage Buckets Setup with User Directories
-- Created: 2025-11-06
-- Description: Creates storage buckets and fixes RLS policies for user-specific directories
-- =====================================================

-- =====================================================
-- 1. Drop Existing Policies (if any)
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatars" ON storage.objects;

DROP POLICY IF EXISTS "Anyone can view facility images" ON storage.objects;
DROP POLICY IF EXISTS "Facility admins can upload facility images" ON storage.objects;
DROP POLICY IF EXISTS "Facility admins can update facility images" ON storage.objects;
DROP POLICY IF EXISTS "Facility admins can delete facility images" ON storage.objects;

DROP POLICY IF EXISTS "Users can view their own documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own documents" ON storage.objects;
DROP POLICY IF EXISTS "Medical providers can view patient documents" ON storage.objects;
DROP POLICY IF EXISTS "Facility admins can view facility documents" ON storage.objects;
DROP POLICY IF EXISTS "System admins can view all documents" ON storage.objects;

-- =====================================================
-- 2. Create Storage Buckets
-- =====================================================

-- Create user-avatars bucket (private, user-specific directories)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'user-avatars',
  'user-avatars',
  false,
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];

-- Create facility-images bucket (public, facility-specific directories)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'facility-images',
  'facility-images',
  true,
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 10485760,
  allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];

-- Create documents bucket (private, user-specific directories)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documents',
  'documents',
  false,
  52428800, -- 50MB limit
  ARRAY['application/pdf', 'image/jpeg', 'image/jpg', 'image/png', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = 52428800,
  allowed_mime_types = ARRAY['application/pdf', 'image/jpeg', 'image/jpg', 'image/png', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'];

-- =====================================================
-- 3. Enhanced RLS Policies for user-avatars Bucket
-- =====================================================

-- Allow authenticated users to view their own avatars
-- Path format: user-avatars/{user_firebase_uid}/filename.jpg
CREATE POLICY "Users can view own avatars"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'user-avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow anyone to view avatars (for profile pictures that need to be public)
CREATE POLICY "Public can view user avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'user-avatars');

-- Allow authenticated users to upload avatars to their own directory
-- Path format: user-avatars/{user_firebase_uid}/filename.jpg
CREATE POLICY "Users can upload own avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'user-avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text AND
  -- Limit file size (checked at bucket level, but double-check here)
  octet_length(decode(encode(name::bytea, 'escape'), 'escape')) < 5242880
);

-- Allow authenticated users to update their own avatars
CREATE POLICY "Users can update own avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'user-avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authenticated users to delete their own avatars
CREATE POLICY "Users can delete own avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'user-avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- =====================================================
-- 4. RLS Policies for facility-images Bucket
-- =====================================================

-- Anyone can view facility images (public bucket)
CREATE POLICY "Public can view facility images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'facility-images');

-- Facility admins can upload images to their facility's directory
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
  )
);

-- Facility admins can update images in their facility's directory
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

-- Facility admins can delete images in their facility's directory
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
-- 5. RLS Policies for documents Bucket
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

-- Users can upload documents to their own directory
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

-- Medical providers can view all documents (for patient care)
CREATE POLICY "Medical providers can view documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'documents' AND
  EXISTS (
    SELECT 1 FROM medical_provider_profiles
    WHERE user_id = auth.uid()
  )
);

-- Facility admins can view all documents
CREATE POLICY "Facility admins can view documents"
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
-- 6. Helper Function for Building Storage Paths
-- =====================================================

-- Function to build proper storage path for user avatars
CREATE OR REPLACE FUNCTION get_user_avatar_storage_path(user_firebase_uid TEXT, filename TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN user_firebase_uid || '/' || filename;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_user_avatar_storage_path(TEXT, TEXT) IS 'Builds storage path for user avatars: {user_id}/{filename}';

-- Function to build proper storage path for facility images
CREATE OR REPLACE FUNCTION get_facility_image_storage_path(facility_uuid UUID, filename TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN facility_uuid::text || '/' || filename;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_facility_image_storage_path(UUID, TEXT) IS 'Builds storage path for facility images: {facility_id}/{filename}';

-- Function to build proper storage path for documents
CREATE OR REPLACE FUNCTION get_document_storage_path(user_firebase_uid TEXT, filename TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN user_firebase_uid || '/' || filename;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_document_storage_path(TEXT, TEXT) IS 'Builds storage path for documents: {user_id}/{filename}';

-- =====================================================
-- Migration Complete
-- =====================================================

-- Expected path formats:
-- User Avatars: user-avatars/{user_firebase_uid}/filename.jpg
-- Facility Images: facility-images/{facility_id}/filename.jpg
-- Documents: documents/{user_firebase_uid}/filename.pdf
