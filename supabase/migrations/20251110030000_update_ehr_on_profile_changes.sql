-- ============================================================================
-- Migration: Update electronic_health_records on Profile Changes + Fix RLS
-- Date: 2025-11-10
-- ============================================================================
--
-- PURPOSE:
-- 1. Add RLS policies so electronic_health_records table is visible in Supabase Studio
-- 2. Create triggers to update electronic_health_records when user profiles are created/updated
--
-- FLOW:
-- User signs up (Firebase) → onUserCreated creates basic user + EHR
-- User selects role (FlutterFlow) → Profile table created
-- Trigger fires → Updates electronic_health_records.user_role
--
-- ============================================================================

-- ============================================================================
-- PART 1: Fix RLS Policies for Visibility
-- ============================================================================

-- Allow authenticated users to read their own records
CREATE POLICY "Users can view their own EHR records"
ON electronic_health_records
FOR SELECT
TO authenticated
USING (patient_id = auth.uid());

-- Allow service role to manage all records (for admin dashboard)
CREATE POLICY "Service role can manage all EHR records"
ON electronic_health_records
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Allow anon users to read (needed for public dashboards if any)
CREATE POLICY "Anon users can read EHR records"
ON electronic_health_records
FOR SELECT
TO anon
USING (true);

-- ============================================================================
-- PART 2: Trigger Function to Update electronic_health_records
-- ============================================================================

CREATE OR REPLACE FUNCTION update_electronic_health_records_on_profile_change()
RETURNS TRIGGER AS $$
DECLARE
    v_user_role VARCHAR;
    v_table_name VARCHAR;
BEGIN
    -- Determine the user role based on which table triggered this function
    v_table_name := TG_TABLE_NAME;

    CASE v_table_name
        WHEN 'patient_profiles' THEN
            v_user_role := 'patient';
        WHEN 'medical_provider_profiles' THEN
            v_user_role := 'medical_provider';
        WHEN 'facility_admin_profiles' THEN
            v_user_role := 'facility_admin';
        WHEN 'system_admin_profiles' THEN
            v_user_role := 'system_admin';
        ELSE
            v_user_role := 'unknown';
    END CASE;

    -- Update electronic_health_records with the user_role
    -- This happens after the profile is created/updated
    UPDATE electronic_health_records
    SET
        user_role = v_user_role,
        updated_at = NOW()
    WHERE patient_id = NEW.user_id;

    -- If no record exists, log a warning (should not happen if onUserCreated works correctly)
    IF NOT FOUND THEN
        RAISE WARNING 'No electronic_health_records entry found for user_id: %, role: %', NEW.user_id, v_user_role;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment
COMMENT ON FUNCTION update_electronic_health_records_on_profile_change() IS
'Updates the user_role in electronic_health_records when a user profile is created or updated.
This ensures the EHR system knows the user''s role (patient, provider, admin, etc.)';

-- ============================================================================
-- PART 3: Create Triggers on All Profile Tables
-- ============================================================================

-- Trigger for patient_profiles
DROP TRIGGER IF EXISTS trigger_update_ehr_on_patient_profile_change ON patient_profiles;
CREATE TRIGGER trigger_update_ehr_on_patient_profile_change
    AFTER INSERT OR UPDATE ON patient_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_electronic_health_records_on_profile_change();

-- Trigger for medical_provider_profiles
DROP TRIGGER IF EXISTS trigger_update_ehr_on_provider_profile_change ON medical_provider_profiles;
CREATE TRIGGER trigger_update_ehr_on_provider_profile_change
    AFTER INSERT OR UPDATE ON medical_provider_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_electronic_health_records_on_profile_change();

-- Trigger for facility_admin_profiles
DROP TRIGGER IF EXISTS trigger_update_ehr_on_facility_admin_profile_change ON facility_admin_profiles;
CREATE TRIGGER trigger_update_ehr_on_facility_admin_profile_change
    AFTER INSERT OR UPDATE ON facility_admin_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_electronic_health_records_on_profile_change();

-- Trigger for system_admin_profiles
DROP TRIGGER IF EXISTS trigger_update_ehr_on_system_admin_profile_change ON system_admin_profiles;
CREATE TRIGGER trigger_update_ehr_on_system_admin_profile_change
    AFTER INSERT OR UPDATE ON system_admin_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_electronic_health_records_on_profile_change();

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================
-- After this migration:
--
-- 1. Check RLS policies:
--    SELECT * FROM pg_policies WHERE tablename = 'electronic_health_records';
--
-- 2. Check triggers:
--    SELECT tgname, tgrelid::regclass, tgtype
--    FROM pg_trigger
--    WHERE tgname LIKE '%ehr_on%profile%';
--
-- 3. Test the trigger:
--    INSERT INTO patient_profiles (id, user_id)
--    VALUES (uuid_generate_v4(), '<existing_user_id>');
--
--    SELECT user_role FROM electronic_health_records
--    WHERE patient_id = '<existing_user_id>';
--    -- Should return 'patient'
--
-- 4. View table in Supabase Studio:
--    The table should now be visible under Table Editor
--
-- ============================================================================
