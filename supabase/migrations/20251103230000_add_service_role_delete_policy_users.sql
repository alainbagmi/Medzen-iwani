-- Migration: Add service_role DELETE policy for users table
-- Created: 2025-11-03 23:00:00
-- Purpose: Fix DELETE operations on users table blocked by RLS
--
-- Issue: Users table has RLS enabled but no DELETE policy for service_role
-- Result: DELETE operations return HTTP 200 but don't actually delete records
-- Solution: Add comprehensive policy for service_role to allow all operations

-- Drop existing policy if it exists (for idempotency)
DROP POLICY IF EXISTS "service_role_all_access" ON users;

-- Add service_role policy for users table (allows all operations)
CREATE POLICY "service_role_all_access" ON users
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Add comment explaining the policy
COMMENT ON POLICY "service_role_all_access" ON users IS
'Allows service_role to perform all operations (SELECT, INSERT, UPDATE, DELETE) on users table. Required for Firebase Functions, Edge Functions, and administrative operations. This policy bypasses all RLS restrictions for service_role.';
