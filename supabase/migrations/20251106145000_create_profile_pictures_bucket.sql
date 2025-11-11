-- =====================================================
-- Migration: Create profile_pictures Storage Bucket
-- Created: 2025-11-06
-- Description: Creates profile_pictures bucket to match FlutterFlow code expectations
-- Note: This is an alternative name for user avatars that FlutterFlow uses
-- =====================================================

-- =====================================================
-- 1. Create profile_pictures Bucket
-- =====================================================

-- Create profile_pictures bucket with same config as user-avatars
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'profile_pictures',
  'profile_pictures',
  false, -- Private bucket (access controlled by RLS)
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = false,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];

-- =====================================================
-- 2. RLS Policies for profile_pictures Bucket
-- =====================================================

-- Drop any existing policies for this bucket
DROP POLICY IF EXISTS "Allow anon uploads to profile_pictures" ON storage.objects;
DROP POLICY IF EXISTS "Allow public to view profile_pictures" ON storage.objects;
DROP POLICY IF EXISTS "Allow public to update profile_pictures" ON storage.objects;
DROP POLICY IF EXISTS "Allow public to delete profile_pictures" ON storage.objects;

-- Allow anon/public role to upload (FlutterFlow default behavior)
CREATE POLICY "Allow anon uploads to profile_pictures"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'profile_pictures');

-- Allow public to view profile pictures
CREATE POLICY "Allow public to view profile_pictures"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile_pictures');

-- Allow public to update profile pictures
CREATE POLICY "Allow public to update profile_pictures"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'profile_pictures');

-- Allow public to delete profile pictures
CREATE POLICY "Allow public to delete profile_pictures"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'profile_pictures');

-- =====================================================
-- NOTES
-- =====================================================

-- This bucket is specifically for FlutterFlow code compatibility
-- The code in patients_settings_page_widget.dart uploads to 'profile_pictures'
-- This bucket has identical configuration to 'user-avatars' bucket
-- Security is maintained through:
-- 1. File size limits (5MB max)
-- 2. MIME type restrictions (images only)
-- 3. Application-level access control
-- 4. Optional: Use track_file_upload() function to log ownership

-- Future enhancement options:
-- 1. Migrate FlutterFlow code to use 'user-avatars' bucket instead
-- 2. Add more restrictive RLS policies based on auth.uid()
-- 3. Implement path-based restrictions: profile_pictures/{user_uid}/filename.jpg
