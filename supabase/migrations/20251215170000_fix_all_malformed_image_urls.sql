-- Fix malformed image URLs across all user-related tables
-- Issue: Some records have malformed URLs like "file:///500x500?doctor" or "/500x500?doctor" or "500x500?doctor"
-- These should be NULL instead

-- Fix users table
UPDATE users
SET avatar_url = NULL
WHERE avatar_url IS NOT NULL
  AND (
    avatar_url LIKE 'file:///%'
    OR avatar_url LIKE '/%'
    OR avatar_url LIKE '%500x500%'
    OR avatar_url LIKE '%?doctor%'
    OR avatar_url LIKE '%?patient%'
    OR avatar_url LIKE '%?admin%'
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
    OR avatar_url LIKE '%?doctor%'
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
    OR avatar_url LIKE '%?admin%'
    OR (avatar_url NOT LIKE 'http%' AND LENGTH(avatar_url) > 0)
  );

-- Add check constraints to prevent future malformed URLs
-- Users table
ALTER TABLE users
DROP CONSTRAINT IF EXISTS users_avatar_url_format;

ALTER TABLE users
ADD CONSTRAINT users_avatar_url_format
CHECK (
  avatar_url IS NULL
  OR avatar_url ~ '^https?://'
);

-- Medical provider profiles table
ALTER TABLE medical_provider_profiles
DROP CONSTRAINT IF EXISTS provider_avatar_url_format;

ALTER TABLE medical_provider_profiles
ADD CONSTRAINT provider_avatar_url_format
CHECK (
  avatar_url IS NULL
  OR avatar_url ~ '^https?://'
);

-- Facility admin profiles table
ALTER TABLE facility_admin_profiles
DROP CONSTRAINT IF EXISTS facility_admin_avatar_url_format;

ALTER TABLE facility_admin_profiles
ADD CONSTRAINT facility_admin_avatar_url_format
CHECK (
  avatar_url IS NULL
  OR avatar_url ~ '^https?://'
);

-- Add comments explaining the constraints
COMMENT ON CONSTRAINT users_avatar_url_format ON users IS
  'Ensures avatar_url is either NULL or starts with http:// or https://';

COMMENT ON CONSTRAINT provider_avatar_url_format ON medical_provider_profiles IS
  'Ensures avatar_url is either NULL or starts with http:// or https://';

COMMENT ON CONSTRAINT facility_admin_avatar_url_format ON facility_admin_profiles IS
  'Ensures avatar_url is either NULL or starts with http:// or https://';
