-- Migration: Fix malformed avatar URLs in users table
-- Created: 2025-12-13
-- Issue: URLs contain 'file:///', '500x500', or don't start with http/https

-- Fix users table avatar URLs
UPDATE users
SET avatar_url = NULL
WHERE avatar_url IS NOT NULL
  AND (
    avatar_url LIKE 'file:///%'
    OR avatar_url LIKE '%500x500%'
    OR avatar_url LIKE '/%'
    OR (avatar_url NOT LIKE 'http://%' AND avatar_url NOT LIKE 'https://%' AND LENGTH(avatar_url) > 0)
  );

-- Add constraint to prevent future malformed URLs
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'users_avatar_url_valid'
    ) THEN
        ALTER TABLE users
        ADD CONSTRAINT users_avatar_url_valid
        CHECK (
            avatar_url IS NULL
            OR avatar_url ~ '^https?://.+'
        );
    END IF;
END $$;

-- Log completion
DO $$
DECLARE
    total_users INTEGER;
    null_avatars INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_users FROM users;
    SELECT COUNT(*) INTO null_avatars FROM users WHERE avatar_url IS NULL;

    RAISE NOTICE '=== Migration Complete ===';
    RAISE NOTICE 'Total users: %', total_users;
    RAISE NOTICE 'Users with NULL avatar (cleaned malformed): %', null_avatars;
    RAISE NOTICE 'Added constraint to prevent future malformed URLs';
END $$;
