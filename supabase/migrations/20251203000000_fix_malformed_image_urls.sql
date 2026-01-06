-- Fix malformed image URLs in users table
-- Issue: Some users have malformed URLs like "file:///500x500?doctor" or "/500x500?doctor"
-- These should be NULL instead

-- Fix users table avatar_url
UPDATE users
SET avatar_url = NULL
WHERE avatar_url IS NOT NULL
  AND (
    avatar_url LIKE 'file:///%'
    OR avatar_url LIKE '/%'
    OR avatar_url LIKE '%500x500%'
    OR (avatar_url NOT LIKE 'http%' AND LENGTH(avatar_url) > 0)
  );

-- Add check constraint to prevent future malformed URLs
ALTER TABLE users
DROP CONSTRAINT IF EXISTS users_avatar_url_format;

ALTER TABLE users
ADD CONSTRAINT users_avatar_url_format
CHECK (
  avatar_url IS NULL
  OR avatar_url ~ '^https?://'
);

-- Add comment explaining the constraint
COMMENT ON CONSTRAINT users_avatar_url_format ON users IS
  'Ensures avatar_url is either NULL or starts with http:// or https://';
