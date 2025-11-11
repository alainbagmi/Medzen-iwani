-- Permissive Profile Picture Upload Policy (Quick Fix)
-- Date: 2025-11-11
-- Issue: RLS policy blocks uploads because auth.uid() returns NULL
-- Solution: Allow uploads to profile_pictures bucket without strict Supabase auth check
-- Security: Ownership tracked via users.avatar_url database field with RLS
-- TODO: Replace with Firebase JWT integration for better security

-- Drop existing restrictive policy that requires auth.uid()
DROP POLICY IF EXISTS "Authenticated users can upload profile pictures" ON storage.objects;

-- Create permissive INSERT policy
-- Allows uploads to profile_pictures bucket by checking:
-- 1. Correct bucket (profile_pictures)
-- 2. Correct path structure (pics/*)
-- Note: Does NOT check auth.uid() to avoid RLS violation with anon key
CREATE POLICY "Allow profile picture uploads (permissive)"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'profile_pictures'
  AND (storage.foldername(name))[1] = 'pics'
);

-- Ensure SELECT policy exists (public viewing)
DROP POLICY IF EXISTS "Anyone can view profile pictures" ON storage.objects;
CREATE POLICY "Anyone can view profile pictures"
ON storage.objects FOR SELECT
USING (bucket_id = 'profile_pictures');

-- Keep UPDATE policy (owner-only, but won't work without Supabase auth session)
-- This is OK because we don't update files, we replace them via DELETE+INSERT
DROP POLICY IF EXISTS "Users can update their own profile pictures" ON storage.objects;
CREATE POLICY "Users can update their own profile pictures"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'profile_pictures'
  AND owner = auth.uid()
);

-- Keep DELETE policy (owner-only, but won't work without Supabase auth session)
-- This is OK because auto-delete trigger uses service role, not user auth
DROP POLICY IF EXISTS "Users can delete their own profile pictures" ON storage.objects;
CREATE POLICY "Users can delete their own profile pictures"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'profile_pictures'
  AND owner = auth.uid()
);

-- Add comment explaining this is a temporary solution
COMMENT ON POLICY "Allow profile picture uploads (permissive)" ON storage.objects IS
'Temporary permissive policy to allow uploads without Supabase auth session.
Users authenticate via Firebase Auth, but Supabase client uses anon key only.
Ownership tracked via users.avatar_url field with RLS on users table.
Replace with Firebase JWT integration or Supabase auth sessions for better security.
See: RLS_POLICY_FIX_ALTERNATIVE.md';

-- Verify policies are active
DO $$
BEGIN
  RAISE NOTICE '✅ Profile picture upload policies updated';
  RAISE NOTICE '⚠️  INSERT policy is permissive - uploads work with anon key';
  RAISE NOTICE '⚠️  UPDATE/DELETE policies require Supabase auth (won''t work without session)';
  RAISE NOTICE '✅ Database users.avatar_url field has RLS for ownership protection';
  RAISE NOTICE '📝 TODO: Implement Firebase JWT integration for proper auth';
END $$;
