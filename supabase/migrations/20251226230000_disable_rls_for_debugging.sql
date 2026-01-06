-- Migration: Temporarily disable RLS on clinical_notes for debugging
-- Description: This will help isolate if the uuid=text error is from RLS policies

-- First, list all current policies for reference
DO $$
DECLARE
    policy_rec RECORD;
BEGIN
    RAISE NOTICE 'Current RLS policies on clinical_notes before disabling:';
    FOR policy_rec IN
        SELECT policyname, cmd
        FROM pg_policies
        WHERE tablename = 'clinical_notes' AND schemaname = 'public'
    LOOP
        RAISE NOTICE '  - % (%)', policy_rec.policyname, policy_rec.cmd;
    END LOOP;
END $$;

-- Disable RLS entirely (service role already bypasses RLS, but this ensures it's off)
ALTER TABLE clinical_notes DISABLE ROW LEVEL SECURITY;

-- Verify RLS is disabled
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_tables
        WHERE tablename = 'clinical_notes'
        AND schemaname = 'public'
        AND rowsecurity = false
    ) THEN
        RAISE NOTICE 'RLS has been DISABLED on clinical_notes';
    ELSE
        RAISE NOTICE 'RLS is still ENABLED on clinical_notes';
    END IF;
END $$;
