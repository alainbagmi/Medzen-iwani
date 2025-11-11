-- Fix RLS policies for profile_pictures bucket to be secure
-- Current issues:
-- 1. Anyone (even anonymous) can upload files
-- 2. Anyone can update/delete any file (no ownership check)
-- 3. Owner/owner_id fields are not being set

-- Drop existing insecure policies
DROP POLICY IF EXISTS "Allow anon uploads to profile_pictures" ON storage.objects;
DROP POLICY IF EXISTS "Allow public to delete profile_pictures" ON storage.objects;
DROP POLICY IF EXISTS "Allow public to update profile_pictures" ON storage.objects;
DROP POLICY IF EXISTS "Allow public to view profile_pictures" ON storage.objects;

-- 1. Allow public (unauthenticated) users to VIEW/READ profile pictures
-- This is fine since it's a public bucket for viewing profile pictures
CREATE POLICY "Public can view profile pictures"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile_pictures');

-- 2. Allow authenticated users to UPLOAD their own profile pictures
-- File path should be: pics/{user_id}_* or pics/{timestamp}.{ext}
CREATE POLICY "Authenticated users can upload profile pictures"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'profile_pictures'
    AND (storage.foldername(name))[1] = 'pics'
);

-- 3. Allow users to UPDATE only their own profile pictures
-- Uses auth.uid() to verify ownership
CREATE POLICY "Users can update own profile pictures"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'profile_pictures'
    AND owner = auth.uid()
)
WITH CHECK (
    bucket_id = 'profile_pictures'
    AND owner = auth.uid()
);

-- 4. Allow users to DELETE only their own profile pictures
CREATE POLICY "Users can delete own profile pictures"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'profile_pictures'
    AND owner = auth.uid()
);

-- Add comment explaining the policies
COMMENT ON POLICY "Public can view profile pictures" ON storage.objects IS
'Allows anyone to view profile pictures for public display';

COMMENT ON POLICY "Authenticated users can upload profile pictures" ON storage.objects IS
'Authenticated users can upload to pics/ folder. Owner is automatically set by Supabase to auth.uid()';

COMMENT ON POLICY "Users can update own profile pictures" ON storage.objects IS
'Users can only update files they own (where owner = auth.uid())';

COMMENT ON POLICY "Users can delete own profile pictures" ON storage.objects IS
'Users can only delete files they own (where owner = auth.uid())';
