-- Grant unrestricted SELECT access to BOTH medical practitioner views
-- These views allow patients to view available practitioners for booking appointments

-- Grant SELECT to all roles for medical_practitioners_view
GRANT SELECT ON medical_practitioners_view TO anon;
GRANT SELECT ON medical_practitioners_view TO authenticated;
GRANT SELECT ON medical_practitioners_view TO service_role;

-- Grant SELECT to all roles for medical_practitioners_details_view
GRANT SELECT ON medical_practitioners_details_view TO anon;
GRANT SELECT ON medical_practitioners_details_view TO authenticated;
GRANT SELECT ON medical_practitioners_details_view TO service_role;

-- Recreate medical_practitioners_view with security_invoker = false
DO $$
DECLARE
    view_def text;
BEGIN
    -- Get current view definition
    SELECT pg_get_viewdef('medical_practitioners_view'::regclass, true) INTO view_def;

    -- Drop and recreate with security_invoker = false
    EXECUTE 'DROP VIEW IF EXISTS medical_practitioners_view CASCADE';
    EXECUTE 'CREATE VIEW medical_practitioners_view WITH (security_invoker = false) AS ' || view_def;

    -- Re-grant permissions
    GRANT SELECT ON medical_practitioners_view TO anon;
    GRANT SELECT ON medical_practitioners_view TO authenticated;
    GRANT SELECT ON medical_practitioners_view TO service_role;

    RAISE NOTICE 'medical_practitioners_view recreated with security_invoker = false';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'medical_practitioners_view recreation failed: %', SQLERRM;
END $$;

-- Recreate medical_practitioners_details_view with security_invoker = false
DO $$
DECLARE
    view_def text;
BEGIN
    -- Get current view definition
    SELECT pg_get_viewdef('medical_practitioners_details_view'::regclass, true) INTO view_def;

    -- Drop and recreate with security_invoker = false
    EXECUTE 'DROP VIEW IF EXISTS medical_practitioners_details_view CASCADE';
    EXECUTE 'CREATE VIEW medical_practitioners_details_view WITH (security_invoker = false) AS ' || view_def;

    -- Re-grant permissions
    GRANT SELECT ON medical_practitioners_details_view TO anon;
    GRANT SELECT ON medical_practitioners_details_view TO authenticated;
    GRANT SELECT ON medical_practitioners_details_view TO service_role;

    RAISE NOTICE 'medical_practitioners_details_view recreated with security_invoker = false';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'medical_practitioners_details_view recreation failed: %', SQLERRM;
END $$;

-- Also ensure RLS policies exist on underlying tables that allow reading
-- Create policy for users table to allow reading provider info (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'users'
        AND policyname = 'users_public_read_all'
    ) THEN
        CREATE POLICY "users_public_read_all" ON users
        FOR SELECT
        USING (true);
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'users_public_read_all policy: %', SQLERRM;
END $$;

-- Create policy for medical_provider_profiles to allow reading (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'medical_provider_profiles'
        AND policyname = 'medical_provider_profiles_public_read'
    ) THEN
        CREATE POLICY "medical_provider_profiles_public_read" ON medical_provider_profiles
        FOR SELECT
        USING (true);
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'medical_provider_profiles_public_read policy: %', SQLERRM;
END $$;

-- Create policy for user_profiles to allow reading (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'user_profiles'
        AND policyname = 'user_profiles_public_read'
    ) THEN
        CREATE POLICY "user_profiles_public_read" ON user_profiles
        FOR SELECT
        USING (true);
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'user_profiles_public_read policy: %', SQLERRM;
END $$;

-- Create policy for reviews to allow reading (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'reviews'
        AND policyname = 'reviews_public_read'
    ) THEN
        CREATE POLICY "reviews_public_read" ON reviews
        FOR SELECT
        USING (true);
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'reviews_public_read policy: %', SQLERRM;
END $$;

-- Create policy for appointments to allow reading count (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'appointments'
        AND policyname = 'appointments_public_count_read'
    ) THEN
        CREATE POLICY "appointments_public_count_read" ON appointments
        FOR SELECT
        USING (true);
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'appointments_public_count_read policy: %', SQLERRM;
END $$;

COMMENT ON VIEW medical_practitioners_view IS 'Public view of medical practitioners for patient booking. Accessible without authentication.';
COMMENT ON VIEW medical_practitioners_details_view IS 'Detailed public view of approved medical practitioners. Accessible without authentication.';
