-- Check current RLS policies for chime_messages
SELECT
    policyname,
    cmd,
    roles,
    qual AS "using_clause",
    with_check
FROM pg_policies
WHERE tablename = 'chime_messages'
ORDER BY policyname, cmd;

-- Check if RLS is enabled
SELECT
    schemaname,
    tablename,
    rowsecurity AS "rls_enabled"
FROM pg_tables
WHERE tablename = 'chime_messages';
