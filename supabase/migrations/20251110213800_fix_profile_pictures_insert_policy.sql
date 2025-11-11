-- Fix the INSERT policy to work with Supabase Storage's internal mechanisms
-- The storage API uses the storage admin role internally but respects auth context
-- The owner field is set by a database trigger AFTER the INSERT, so we can't check it in the policy

-- Drop the existing INSERT policy
DROP POLICY IF EXISTS "Authenticated users can upload profile pictures" ON storage.objects;

-- Create a new INSERT policy that works with the storage API
-- Key insight: The storage API sets owner via trigger AFTER insert, so we only check:
-- 1. Correct bucket
-- 2. Correct folder
-- 3. User is authenticated (auth.uid() IS NOT NULL)
CREATE POLICY "Authenticated users can upload profile pictures"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile_pictures'
  AND (storage.foldername(name))[1] = 'pics'
  -- Verify there is an authenticated user making this request
  AND auth.uid() IS NOT NULL
);

-- Ensure the bucket configuration is correct
UPDATE storage.buckets
SET
  public = true,
  file_size_limit = 5242880,  -- 5MB
  allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp']::text[]
WHERE id = 'profile_pictures';
