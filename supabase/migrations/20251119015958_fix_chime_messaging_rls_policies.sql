-- Migration: Clean up RLS policies for Chime messaging tables
-- Purpose: Drop any existing RLS policies to allow 20251119020000_create_chime_messaging_tables.sql to create them fresh
-- Fixes: Duplicate policy error blocking deployment
-- Date: 2025-11-27

-- Drop existing policies if they exist (safe approach)
-- This allows the next migration to create them cleanly
DROP POLICY IF EXISTS "Users can view own channels" ON chime_messaging_channels;
DROP POLICY IF EXISTS "Authenticated users can create channels" ON chime_messaging_channels;
DROP POLICY IF EXISTS "Users can update own channels" ON chime_messaging_channels;
DROP POLICY IF EXISTS "Users can view audit for own channels" ON chime_message_audit;
DROP POLICY IF EXISTS "System can insert audit logs" ON chime_message_audit;

-- Ensure RLS is enabled (safe to run multiple times)
ALTER TABLE IF EXISTS chime_messaging_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS chime_message_audit ENABLE ROW LEVEL SECURITY;

-- Note: Policies will be created by the next migration (20251119020000_create_chime_messaging_tables.sql)
