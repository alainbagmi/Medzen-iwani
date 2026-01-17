-- Verify chime_messages table schema and RLS policies

-- 1. Check table columns
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'chime_messages'
ORDER BY ordinal_position;

-- 2. Check constraints
SELECT
    conname as constraint_name,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'chime_messages'::regclass;

-- 3. Check RLS policies
SELECT
    policyname,
    cmd as command,
    permissive,
    roles,
    qual::text as using_clause,
    with_check::text as with_check_clause
FROM pg_policies
WHERE tablename = 'chime_messages'
ORDER BY policyname;

-- 4. Check indexes
SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'chime_messages'
ORDER BY indexname;
