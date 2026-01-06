-- Migration: Fix malformed image URLs across all tables
-- Date: 2025-12-02
-- Description: Remove malformed image URLs that contain '500x500', 'file://', or don't start with 'http'

-- Fix malformed avatar URLs in medical_provider_profiles
UPDATE medical_provider_profiles
SET avatar_url = NULL
WHERE avatar_url LIKE '%500x500%'
   OR avatar_url LIKE 'file://%'
   OR (avatar_url IS NOT NULL AND avatar_url NOT LIKE 'http%');

-- Fix malformed avatar URLs in users table
UPDATE users
SET avatar_url = NULL
WHERE avatar_url LIKE '%500x500%'
   OR avatar_url LIKE 'file://%'
   OR (avatar_url IS NOT NULL AND avatar_url NOT LIKE 'http%');

-- Fix malformed image URLs in facilities table (if column exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='facilities' AND column_name='image_url'
  ) THEN
    UPDATE facilities
    SET image_url = NULL
    WHERE image_url LIKE '%500x500%'
       OR image_url LIKE 'file://%'
       OR (image_url IS NOT NULL AND image_url NOT LIKE 'http%');
  END IF;
END $$;

-- Log the cleanup
DO $$
DECLARE
  provider_count INTEGER;
  user_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO provider_count
  FROM medical_provider_profiles
  WHERE avatar_url IS NULL;

  SELECT COUNT(*) INTO user_count
  FROM users
  WHERE avatar_url IS NULL;

  RAISE NOTICE 'Malformed URL cleanup completed:';
  RAISE NOTICE '  - medical_provider_profiles with NULL avatar_url: %', provider_count;
  RAISE NOTICE '  - users with NULL avatar_url: %', user_count;
END $$;
