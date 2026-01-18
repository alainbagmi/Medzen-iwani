-- Migration: Fix malformed profile image URLs
-- Issue: Profile images have malformed URLs like 'file:///500x500?doctor'
-- Fix: Set invalid URLs to NULL so the app uses default avatars
-- Date: 2025-12-16

-- Fix users table
UPDATE users
SET avatar_url = NULL
WHERE avatar_url IS NOT NULL
  AND (
    avatar_url LIKE 'file:///%'
    OR avatar_url LIKE '/%'
    OR avatar_url LIKE '%500x500%'
    OR avatar_url LIKE '%.?%'
    OR (avatar_url NOT LIKE 'http%' AND LENGTH(avatar_url) > 0)
  );

-- Fix medical_provider_profiles table
UPDATE medical_provider_profiles
SET avatar_url = NULL
WHERE avatar_url IS NOT NULL
  AND (
    avatar_url LIKE 'file:///%'
    OR avatar_url LIKE '/%'
    OR avatar_url LIKE '%500x500%'
    OR avatar_url LIKE '%.?%'
    OR (avatar_url NOT LIKE 'http%' AND LENGTH(avatar_url) > 0)
  );

-- Fix facility_admin_profiles table
UPDATE facility_admin_profiles
SET avatar_url = NULL
WHERE avatar_url IS NOT NULL
  AND (
    avatar_url LIKE 'file:///%'
    OR avatar_url LIKE '/%'
    OR avatar_url LIKE '%500x500%'
    OR avatar_url LIKE '%.?%'
    OR (avatar_url NOT LIKE 'http%' AND LENGTH(avatar_url) > 0)
  );
