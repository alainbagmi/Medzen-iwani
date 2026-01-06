-- Migration: Deprecate Unused Tables and Add Admin RLS Policies
-- Purpose: Mark deprecated tables and ensure admin access to all RLS-enabled tables
-- Date: 2025-12-19
-- Author: MedZen Compliance Audit

-- =====================================================
-- PART 1: ADD DEPRECATION COMMENTS TO UNUSED TABLES
-- =====================================================

-- These tables are deprecated and should not be used:
-- 1. z_chats - Legacy chat system (replaced by ai_conversations)
-- 2. z_chat_messages - Legacy chat messages (replaced by ai_messages)
-- 3. chat - Duplicate/legacy chat table
-- 4. conversation - Legacy conversation (use conversations)
-- 5. specialties_backup_20251114 - Temporary backup
-- 6. provider_profiles_backup_20251114 - Temporary backup

-- Add deprecation comments to tables that exist (using DO block for safe execution)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'z_chats') THEN
        COMMENT ON TABLE z_chats IS 'DEPRECATED: Legacy chat system. Use ai_conversations instead.';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'z_chat_messages') THEN
        COMMENT ON TABLE z_chat_messages IS 'DEPRECATED: Legacy chat messages. Use ai_messages instead.';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'chat') THEN
        COMMENT ON TABLE chat IS 'DEPRECATED: Legacy chat table. Use ai_conversations instead.';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'conversation') THEN
        COMMENT ON TABLE conversation IS 'DEPRECATED: Legacy conversation table. Use conversations instead.';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'specialties_backup_20251114') THEN
        COMMENT ON TABLE specialties_backup_20251114 IS 'DEPRECATED: Temporary backup table. Safe to delete.';
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'provider_profiles_backup_20251114') THEN
        COMMENT ON TABLE provider_profiles_backup_20251114 IS 'DEPRECATED: Temporary backup table. Safe to delete.';
    END IF;
END $$;

-- =====================================================
-- PART 2: ADD ADMIN POLICIES FOR SYSTEM/FACILITY ADMINS
-- =====================================================

-- Create helper function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin_user()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM users u
        WHERE u.firebase_uid = auth.uid()::text
        AND (u.role IN ('system_admin', 'facility_admin') OR u.is_admin = true)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add admin select policies to key tables
-- These allow admins to view all records for management purposes

-- Appointments - Admin full access
DROP POLICY IF EXISTS "appointments_admin_all" ON appointments;
CREATE POLICY "appointments_admin_all" ON appointments
    FOR ALL
    USING (is_admin_user());

-- Documents - Admin can view all
DROP POLICY IF EXISTS "documents_admin_select" ON documents;
CREATE POLICY "documents_admin_select" ON documents
    FOR SELECT
    USING (is_admin_user());

-- Users - Admin can view all
DROP POLICY IF EXISTS "users_admin_select" ON users;
CREATE POLICY "users_admin_select" ON users
    FOR SELECT
    USING (is_admin_user());

-- Notifications - Admin can create for any user
DROP POLICY IF EXISTS "notifications_admin_insert" ON notifications;
CREATE POLICY "notifications_admin_insert" ON notifications
    FOR INSERT
    WITH CHECK (is_admin_user());

-- Reviews - Admin can moderate
DROP POLICY IF EXISTS "reviews_admin_all" ON reviews;
CREATE POLICY "reviews_admin_all" ON reviews
    FOR ALL
    USING (is_admin_user());

-- Withdrawals - Admin can view all
DROP POLICY IF EXISTS "withdrawals_admin_select" ON withdrawals;
CREATE POLICY "withdrawals_admin_select" ON withdrawals
    FOR SELECT
    USING (is_admin_user());

-- Transactions - Admin can view all
DROP POLICY IF EXISTS "transactions_admin_select" ON transactions;
CREATE POLICY "transactions_admin_select" ON transactions
    FOR SELECT
    USING (is_admin_user());

-- =====================================================
-- PART 3: ADD PROVIDER ACCESS TO PATIENT DATA
-- =====================================================

-- Providers should be able to view patient medical data for appointments

-- User Allergies - Provider can view for their patients
DROP POLICY IF EXISTS "user_allergies_provider_select" ON user_allergies;
CREATE POLICY "user_allergies_provider_select" ON user_allergies
    FOR SELECT
    USING (
        user_id IN (
            SELECT DISTINCT patient_id FROM appointments
            WHERE provider_id IN (
                SELECT id FROM users WHERE firebase_uid = auth.uid()::text
            )
        )
    );

-- User Medications - Provider can view for their patients
DROP POLICY IF EXISTS "user_medications_provider_select" ON user_medications;
CREATE POLICY "user_medications_provider_select" ON user_medications
    FOR SELECT
    USING (
        user_id IN (
            SELECT DISTINCT patient_id FROM appointments
            WHERE provider_id IN (
                SELECT id FROM users WHERE firebase_uid = auth.uid()::text
            )
        )
    );

-- User Medical Conditions - Provider can view for their patients
DROP POLICY IF EXISTS "user_medical_conditions_provider_select" ON user_medical_conditions;
CREATE POLICY "user_medical_conditions_provider_select" ON user_medical_conditions
    FOR SELECT
    USING (
        user_id IN (
            SELECT DISTINCT patient_id FROM appointments
            WHERE provider_id IN (
                SELECT id FROM users WHERE firebase_uid = auth.uid()::text
            )
        )
    );

-- =====================================================
-- PART 4: ENSURE REFERRALS HAS RLS (if table exists)
-- =====================================================

-- Only apply referrals policies if the table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'referrals') THEN
        ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

        -- Drop existing policies if any
        DROP POLICY IF EXISTS "referrals_select_participant" ON referrals;
        DROP POLICY IF EXISTS "referrals_insert_provider" ON referrals;

        -- Create select policy
        EXECUTE 'CREATE POLICY "referrals_select_participant" ON referrals
            FOR SELECT
            USING (
                patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
                OR referring_provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
                OR referred_to_provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
            )';

        -- Create insert policy
        EXECUTE 'CREATE POLICY "referrals_insert_provider" ON referrals
            FOR INSERT
            WITH CHECK (
                referring_provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
            )';
    END IF;
END $$;

-- =====================================================
-- VERIFICATION SUMMARY
-- =====================================================
-- 1. Added deprecation comments to 6 unused tables
-- 2. Created is_admin_user() helper function
-- 3. Added admin policies for management access
-- 4. Added provider access to patient medical data
-- 5. Ensured referrals table has RLS
