-- Migration: Fix all malformed image URLs across the system
-- Created: 2025-12-13
-- Description: Removes malformed URLs like 'file:///500x500?doctor' patterns

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

-- Add constraint to prevent future malformed URLs in users table
DO $$ 
BEGIN
  ALTER TABLE users DROP CONSTRAINT IF EXISTS users_avatar_url_valid_http_url;
  ALTER TABLE users 
  ADD CONSTRAINT users_avatar_url_valid_http_url 
  CHECK (avatar_url IS NULL OR avatar_url LIKE 'http://%' OR avatar_url LIKE 'https://%');
END $$;
