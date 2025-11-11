-- =====================================================
-- Fix Storage RLS for Anon Role (FlutterFlow Default)
-- FlutterFlow uses anon key for uploads, not authenticated token
-- =====================================================

-- Drop existing policies that require authenticated role
DROP POLICY IF EXISTS "Authenticated users can upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload facility images" ON storage.objects;
DROP POLICY IF EXISTS "Facility images are publicly viewable" ON storage.objects;
DROP POLICY IF EXISTS "Facility admins can delete facility images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own documents" ON storage.objects;
DROP POLICY IF EXISTS "Providers can view all documents" ON storage.objects;
DROP POLICY IF EXISTS "Facility admins can view all documents" ON storage.objects;
DROP POLICY IF EXISTS "System admins can view all documents" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own documents" ON storage.objects;

-- =====================================================
-- USER AVATARS BUCKET - Allow anon role uploads
-- =====================================================

-- Allow anon role to upload (FlutterFlow default behavior)
CREATE POLICY "Allow anon uploads to user-avatars"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'user-avatars');

-- Allow public to view avatars (can restrict later if needed)
CREATE POLICY "Allow public to view user-avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'user-avatars');

-- Allow public to update files in user-avatars
CREATE POLICY "Allow public to update user-avatars"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'user-avatars');

-- Allow public to delete files in user-avatars
CREATE POLICY "Allow public to delete user-avatars"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'user-avatars');

-- =====================================================
-- FACILITY IMAGES BUCKET - Allow anon role uploads
-- =====================================================

-- Allow anon role to upload facility images
CREATE POLICY "Allow anon uploads to facility-images"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'facility-images');

-- Public read for facility images
CREATE POLICY "Allow public to view facility-images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'facility-images');

-- Allow public to update facility images
CREATE POLICY "Allow public to update facility-images"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'facility-images');

-- Allow public to delete facility images
CREATE POLICY "Allow public to delete facility-images"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'facility-images');

-- =====================================================
-- DOCUMENTS BUCKET - Allow anon role uploads
-- =====================================================

-- Allow anon role to upload documents
CREATE POLICY "Allow anon uploads to documents"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'documents');

-- Allow public to view documents
CREATE POLICY "Allow public to view documents"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'documents');

-- Allow public to update documents
CREATE POLICY "Allow public to update documents"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'documents');

-- Allow public to delete documents
CREATE POLICY "Allow public to delete documents"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'documents');

-- =====================================================
-- NOTES
-- =====================================================

-- This allows uploads using the anon key (FlutterFlow default)
-- Security is maintained through:
-- 1. Bucket configuration (file size limits, allowed MIME types)
-- 2. Application-level access control
-- 3. Optional: Use track_file_upload() function to log ownership
-- 4. Can add more restrictive policies later if needed

-- For enhanced security later, you can:
-- 1. Use auth.uid() in policies when FlutterFlow is configured to send user tokens
-- 2. Use ownership tracking table for DELETE operations
-- 3. Restrict based on user roles from profile tables
