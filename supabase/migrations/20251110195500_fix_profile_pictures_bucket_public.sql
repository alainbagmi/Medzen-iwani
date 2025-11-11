-- Fix profile_pictures bucket to be public
-- The bucket has RLS policies that allow public access, but the bucket itself is marked as private
-- This causes 400 errors when accessing via /storage/v1/object/public/... URLs

-- Update the bucket to be public
UPDATE storage.buckets
SET public = true
WHERE id = 'profile_pictures';

-- Verify the change
DO $$
DECLARE
    bucket_status BOOLEAN;
BEGIN
    SELECT public INTO bucket_status
    FROM storage.buckets
    WHERE id = 'profile_pictures';

    IF bucket_status = true THEN
        RAISE NOTICE 'SUCCESS: profile_pictures bucket is now public';
    ELSE
        RAISE EXCEPTION 'FAILED: profile_pictures bucket is still private';
    END IF;
END $$;
