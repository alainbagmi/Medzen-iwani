-- Verify Profile Picture RLS Configuration
-- Run this in Supabase Studio SQL Editor to verify all settings are correct

-- ============================================
-- 1. Check All RLS Policies
-- ============================================

SELECT
  '=== RLS POLICIES ===' as section,
  polname as policy_name,
  CASE polcmd
    WHEN 'r' THEN 'SELECT'
    WHEN 'a' THEN 'INSERT'
    WHEN 'w' THEN 'UPDATE'
    WHEN 'd' THEN 'DELETE'
  END as operation,
  CASE
    WHEN polroles = '{0}' THEN 'PUBLIC'
    ELSE pg_get_userbyid(polroles[1])
  END as applies_to,
  pg_get_expr(polqual, polrelid) as using_check,
  pg_get_expr(polwithcheck, polrelid) as with_check
FROM pg_policy
WHERE polrelid = 'storage.objects'::regclass
  AND polname LIKE '%profile_pictures%'
ORDER BY polcmd;

-- Expected Results:
-- 1. INSERT: with_check should include "auth.uid() IS NOT NULL"
-- 2. SELECT: PUBLIC access, bucket check only
-- 3. UPDATE: authenticated, owner = auth.uid()
-- 4. DELETE: authenticated, owner = auth.uid()

-- ============================================
-- 2. Check Bucket Configuration
-- ============================================

SELECT
  '=== BUCKET CONFIG ===' as section,
  id,
  name,
  public as is_public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets
WHERE id = 'profile_pictures';

-- Expected Results:
-- - public: true
-- - file_size_limit: 5242880 (5MB)
-- - allowed_mime_types: [image/jpeg, image/jpg, image/png, image/gif, image/webp]

-- ============================================
-- 3. Check for Multiple Files Per User
-- ============================================

SELECT
  '=== FILES PER USER ===' as section,
  owner,
  COUNT(*) as file_count
FROM storage.objects
WHERE bucket_id = 'profile_pictures'
  AND owner IS NOT NULL
GROUP BY owner
HAVING COUNT(*) > 1;

-- Expected Results:
-- No rows (each user should have max 1 file)

-- ============================================
-- 4. Check Recent Uploads
-- ============================================

SELECT
  '=== RECENT UPLOADS ===' as section,
  id,
  name,
  owner,
  created_at,
  updated_at
FROM storage.objects
WHERE bucket_id = 'profile_pictures'
ORDER BY created_at DESC
LIMIT 5;

-- Expected Results:
-- - owner field should be populated (UUID)
-- - names should be in 'pics/' folder

-- ============================================
-- 5. Verify INSERT Policy Details
-- ============================================

SELECT
  '=== INSERT POLICY DETAIL ===' as section,
  polname as policy_name,
  pg_get_expr(polwithcheck, polrelid) as full_check_expression
FROM pg_policy
WHERE polrelid = 'storage.objects'::regclass
  AND polname = 'Authenticated users can upload profile pictures'
  AND polcmd = 'a';

-- Expected Results:
-- Should contain all three checks:
-- 1. bucket_id = 'profile_pictures'::text
-- 2. (storage.foldername(name))[1] = 'pics'::text
-- 3. auth.uid() IS NOT NULL

-- ============================================
-- SUMMARY
-- ============================================
-- All checks should return expected results for proper configuration
-- If any check fails, review the migration file:
-- supabase/migrations/20251110213800_fix_profile_pictures_insert_policy.sql
