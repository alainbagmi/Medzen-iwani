-- Grant unrestricted SELECT access to medical_practitioners_details_view
-- This allows patients to view available practitioners for booking appointments

-- Grant SELECT to all roles (view already exists, just ensure permissions)
GRANT SELECT ON medical_practitioners_details_view TO anon;
GRANT SELECT ON medical_practitioners_details_view TO authenticated;
GRANT SELECT ON medical_practitioners_details_view TO service_role;

-- Also grant on the other practitioner view
GRANT SELECT ON medical_practitioners_view TO anon;
GRANT SELECT ON medical_practitioners_view TO authenticated;
GRANT SELECT ON medical_practitioners_view TO service_role;

-- Ensure underlying tables have SELECT policies that allow reading approved providers
-- Create policy for medical_provider_profiles if not exists
DO $$
BEGIN
    -- Check if policy exists
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'medical_provider_profiles'
        AND policyname = 'medical_providers_public_read'
    ) THEN
        CREATE POLICY "medical_providers_public_read" ON medical_provider_profiles
        FOR SELECT
        USING (application_status = 'approved');
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'medical_providers_public_read policy: %', SQLERRM;
END $$;

-- Ensure users table allows reading basic profile info
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'users'
        AND policyname = 'users_public_profile_read'
    ) THEN
        CREATE POLICY "users_public_profile_read" ON users
        FOR SELECT
        USING (true);
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'users_public_profile_read policy: %', SQLERRM;
END $$;

-- Make the view security definer to bypass RLS on underlying tables
-- First get current view definition and recreate
DO $$
DECLARE
    view_def text;
BEGIN
    -- Get current view definition
    SELECT pg_get_viewdef('medical_practitioners_details_view'::regclass, true) INTO view_def;

    -- Drop and recreate with security_invoker = false
    EXECUTE 'DROP VIEW IF EXISTS medical_practitioners_details_view';
    EXECUTE 'CREATE VIEW medical_practitioners_details_view WITH (security_invoker = false) AS ' || view_def;

    -- Re-grant permissions
    GRANT SELECT ON medical_practitioners_details_view TO anon;
    GRANT SELECT ON medical_practitioners_details_view TO authenticated;
    GRANT SELECT ON medical_practitioners_details_view TO service_role;

    RAISE NOTICE 'View recreated with security_invoker = false';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'View recreation skipped: %', SQLERRM;
END $$;

COMMENT ON VIEW medical_practitioners_details_view IS 'Public view of approved medical practitioners for patient booking. Accessible without authentication.';
