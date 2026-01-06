-- Fix malformed image URLs in users table and related tables
-- These URLs should be full Supabase storage URLs, not partial paths like "/500x500?doctor"

-- First, let's check what's causing the issue and set proper NULL values for invalid URLs

-- Fix users table
UPDATE users
SET avatar_url = NULL
WHERE avatar_url IS NOT NULL
  AND (
    avatar_url LIKE '/%' -- starts with / (relative path)
    OR avatar_url NOT LIKE 'http%' -- doesn't start with http/https
    OR LENGTH(avatar_url) < 10 -- too short to be valid
  );

-- Fix medical_provider_profiles
UPDATE medical_provider_profiles
SET avatar_url = NULL
WHERE avatar_url IS NOT NULL
  AND (
    avatar_url LIKE '/%'
    OR avatar_url NOT LIKE 'http%'
    OR LENGTH(avatar_url) < 10
  );

-- Fix facility_admin_profiles
UPDATE facility_admin_profiles
SET avatar_url = NULL
WHERE avatar_url IS NOT NULL
  AND (
    avatar_url LIKE '/%'
    OR avatar_url NOT LIKE 'http%'
    OR LENGTH(avatar_url) < 10
  );

-- Fix system_admin_profiles
UPDATE system_admin_profiles
SET avatar_url = NULL
WHERE avatar_url IS NOT NULL
  AND (
    avatar_url LIKE '/%'
    OR avatar_url NOT LIKE 'http%'
    OR LENGTH(avatar_url) < 10
  );

-- Fix facilities
UPDATE facilities
SET image_url = NULL
WHERE image_url IS NOT NULL
  AND (
    image_url LIKE '/%'
    OR image_url NOT LIKE 'http%'
    OR LENGTH(image_url) < 10
  );

-- Add a constraint to prevent future malformed URLs in users table
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_avatar_url_valid;
ALTER TABLE users
  ADD CONSTRAINT users_avatar_url_valid
  CHECK (
    avatar_url IS NULL
    OR (
      avatar_url LIKE 'http%'
      AND LENGTH(avatar_url) >= 10
    )
  );

-- Add constraints to other tables
ALTER TABLE medical_provider_profiles DROP CONSTRAINT IF EXISTS provider_avatar_url_valid;
ALTER TABLE medical_provider_profiles
  ADD CONSTRAINT provider_avatar_url_valid
  CHECK (
    avatar_url IS NULL
    OR (
      avatar_url LIKE 'http%'
      AND LENGTH(avatar_url) >= 10
    )
  );

ALTER TABLE facility_admin_profiles DROP CONSTRAINT IF EXISTS facility_admin_avatar_url_valid;
ALTER TABLE facility_admin_profiles
  ADD CONSTRAINT facility_admin_avatar_url_valid
  CHECK (
    avatar_url IS NULL
    OR (
      avatar_url LIKE 'http%'
      AND LENGTH(avatar_url) >= 10
    )
  );

ALTER TABLE system_admin_profiles DROP CONSTRAINT IF EXISTS system_admin_avatar_url_valid;
ALTER TABLE system_admin_profiles
  ADD CONSTRAINT system_admin_avatar_url_valid
  CHECK (
    avatar_url IS NULL
    OR (
      avatar_url LIKE 'http%'
      AND LENGTH(avatar_url) >= 10
    )
  );

ALTER TABLE facilities DROP CONSTRAINT IF EXISTS facilities_image_url_valid;
ALTER TABLE facilities
  ADD CONSTRAINT facilities_image_url_valid
  CHECK (
    image_url IS NULL
    OR (
      image_url LIKE 'http%'
      AND LENGTH(image_url) >= 10
    )
  );

-- Add a helpful comment
COMMENT ON CONSTRAINT users_avatar_url_valid ON users IS
  'Ensures avatar URLs are either NULL or valid HTTP/HTTPS URLs';
