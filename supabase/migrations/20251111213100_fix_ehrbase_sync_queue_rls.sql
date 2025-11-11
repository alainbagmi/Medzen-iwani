-- Fix RLS policies for ehrbase_sync_queue to allow trigger functions to INSERT
-- Error: new row violates row-level security policy for table "ehrbase_sync_queue"
-- Solution: Add policies for system operations (triggers, service role)

-- Allow service_role to do everything (for edge functions and system operations)
CREATE POLICY "service_role_all_access"
ON ehrbase_sync_queue
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Allow authenticated users to insert (for trigger functions that run as authenticator)
CREATE POLICY "authenticated_insert_access"
ON ehrbase_sync_queue
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow authenticated users to update their own queue entries
CREATE POLICY "authenticated_update_access"
ON ehrbase_sync_queue
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Allow authenticated users to read queue entries
CREATE POLICY "authenticated_select_access"
ON ehrbase_sync_queue
FOR SELECT
TO authenticated
USING (true);

COMMENT ON POLICY "service_role_all_access" ON ehrbase_sync_queue IS 'Allow service_role full access for edge functions and system operations';
COMMENT ON POLICY "authenticated_insert_access" ON ehrbase_sync_queue IS 'Allow trigger functions to insert sync queue entries';
COMMENT ON POLICY "authenticated_update_access" ON ehrbase_sync_queue IS 'Allow updates to sync queue (retry logic, status updates)';
COMMENT ON POLICY "authenticated_select_access" ON ehrbase_sync_queue IS 'Allow reading sync queue for monitoring and debugging';
