-- Migration: Fix all malformed profile image URLs across all tables
-- Created: 2025-12-13 21:00:00
-- Description: Comprehensive fix for malformed image URLs in all profile-related tables

-- Fix users table
UPDATE users
SET avatar_url = NULL
WHERE avatar_url IS NOT NULL
  AND (
    avatar_url LIKE 'file:///%'
    OR avatar_url LIKE '/%'
    OR avatar_url LIKE '%500x500%'
    OR (avatar_url NOT LIKE 'http://%' AND avatar_url NOT LIKE 'https://%' AND LENGTH(avatar_url) > 0)
  );

-- Fix medical_provider_profiles table (uses avatar_url column)
UPDATE medical_provider_profiles
SET avatar_url = NULL
WHERE avatar_url IS NOT NULL
  AND (
    avatar_url LIKE 'file:///%'
    OR avatar_url LIKE '/%'
    OR avatar_url LIKE '%500x500%'
    OR (avatar_url NOT LIKE 'http://%' AND avatar_url NOT LIKE 'https://%' AND LENGTH(avatar_url) > 0)
  );

-- Fix facility_admin_profiles table (if exists, uses avatar_url column)
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = 'facility_admin_profiles'
  ) THEN
    UPDATE facility_admin_profiles
    SET avatar_url = NULL
    WHERE avatar_url IS NOT NULL
      AND (
        avatar_url LIKE 'file:///%'
        OR avatar_url LIKE '/%'
        OR avatar_url LIKE '%500x500%'
        OR (avatar_url NOT LIKE 'http://%' AND avatar_url NOT LIKE 'https://%' AND LENGTH(avatar_url) > 0)
      );
  END IF;
END $$;

-- Add constraints to prevent future malformed URLs

-- Users table constraint
DO $$
BEGIN
  ALTER TABLE users DROP CONSTRAINT IF EXISTS users_avatar_url_valid_http_url;
  ALTER TABLE users
  ADD CONSTRAINT users_avatar_url_valid_http_url
  CHECK (avatar_url IS NULL OR avatar_url LIKE 'http://%' OR avatar_url LIKE 'https://%');
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Could not add constraint to users table: %', SQLERRM;
END $$;

-- Medical provider profiles constraint
DO $$
BEGIN
  ALTER TABLE medical_provider_profiles DROP CONSTRAINT IF EXISTS medical_provider_profiles_avatar_url_valid;
  ALTER TABLE medical_provider_profiles
  ADD CONSTRAINT medical_provider_profiles_avatar_url_valid
  CHECK (avatar_url IS NULL OR avatar_url LIKE 'http://%' OR avatar_url LIKE 'https://%');
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Could not add constraint to medical_provider_profiles table: %', SQLERRM;
END $$;

-- Facility admin profiles constraint (if exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.tables
    WHERE table_schema = 'public'
    AND table_name = 'facility_admin_profiles'
  ) THEN
    ALTER TABLE facility_admin_profiles DROP CONSTRAINT IF EXISTS facility_admin_profiles_avatar_url_valid;
    ALTER TABLE facility_admin_profiles
    ADD CONSTRAINT facility_admin_profiles_avatar_url_valid
    CHECK (avatar_url IS NULL OR avatar_url LIKE 'http://%' OR avatar_url LIKE 'https://%');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Could not add constraint to facility_admin_profiles table: %', SQLERRM;
END $$;

-- Log the fixes
DO $$
DECLARE
  users_fixed INTEGER;
  providers_fixed INTEGER;
BEGIN
  SELECT COUNT(*) INTO users_fixed FROM users WHERE avatar_url IS NULL;
  SELECT COUNT(*) INTO providers_fixed FROM medical_provider_profiles WHERE avatar_url IS NULL;

  RAISE NOTICE 'Profile image URL fix complete';
  RAISE NOTICE 'Users with NULL avatar_url: %', users_fixed;
  RAISE NOTICE 'Providers with NULL avatar_url: %', providers_fixed;
END $$;
