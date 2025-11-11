-- Migration: Add CASCADE constraints to all foreign keys referencing users table
-- This ensures that when a user is deleted, all related records are automatically deleted
-- Date: 2025-11-03

-- =====================================================
-- 1. Drop and recreate user_profiles foreign key
-- =====================================================

-- Drop existing constraint if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'user_profiles_user_id_fkey'
        AND table_name = 'user_profiles'
    ) THEN
        ALTER TABLE user_profiles DROP CONSTRAINT user_profiles_user_id_fkey;
    END IF;
END $$;

-- Add new constraint with CASCADE
ALTER TABLE user_profiles
    ADD CONSTRAINT user_profiles_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- =====================================================
-- 2. Drop and recreate medical_provider_profiles foreign key
-- =====================================================

-- Drop existing constraint if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'medical_provider_profiles_user_id_fkey'
        AND table_name = 'medical_provider_profiles'
    ) THEN
        ALTER TABLE medical_provider_profiles DROP CONSTRAINT medical_provider_profiles_user_id_fkey;
    END IF;
END $$;

-- Add new constraint with CASCADE
ALTER TABLE medical_provider_profiles
    ADD CONSTRAINT medical_provider_profiles_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- =====================================================
-- 3. Drop and recreate facility_admin_profiles foreign key
-- =====================================================

-- Drop existing constraint if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'facility_admin_profiles_user_id_fkey'
        AND table_name = 'facility_admin_profiles'
    ) THEN
        ALTER TABLE facility_admin_profiles DROP CONSTRAINT facility_admin_profiles_user_id_fkey;
    END IF;
END $$;

-- Add new constraint with CASCADE
ALTER TABLE facility_admin_profiles
    ADD CONSTRAINT facility_admin_profiles_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- =====================================================
-- 4. Drop and recreate system_admin_profiles foreign key
-- =====================================================

-- Drop existing constraint if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'system_admin_profiles_user_id_fkey'
        AND table_name = 'system_admin_profiles'
    ) THEN
        ALTER TABLE system_admin_profiles DROP CONSTRAINT system_admin_profiles_user_id_fkey;
    END IF;
END $$;

-- Add new constraint with CASCADE
ALTER TABLE system_admin_profiles
    ADD CONSTRAINT system_admin_profiles_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- =====================================================
-- 5. Drop and recreate electronic_health_records foreign key
-- =====================================================

-- Drop existing constraint if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'electronic_health_records_patient_id_fkey'
        AND table_name = 'electronic_health_records'
    ) THEN
        ALTER TABLE electronic_health_records DROP CONSTRAINT electronic_health_records_patient_id_fkey;
    END IF;
END $$;

-- Add new constraint with CASCADE
ALTER TABLE electronic_health_records
    ADD CONSTRAINT electronic_health_records_patient_id_fkey
    FOREIGN KEY (patient_id)
    REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;

-- =====================================================
-- 6. Verify all foreign keys have CASCADE
-- =====================================================

-- This will show all foreign keys to users table with their delete/update rules
DO $$
DECLARE
    fk_record RECORD;
    missing_cascade BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '=== Foreign Key Constraints to users table ===';

    FOR fk_record IN
        SELECT
            tc.table_name,
            kcu.column_name,
            rc.update_rule,
            rc.delete_rule
        FROM information_schema.table_constraints AS tc
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
        JOIN information_schema.referential_constraints AS rc
            ON rc.constraint_name = tc.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
            AND kcu.column_name IN ('user_id', 'patient_id')
            AND tc.table_schema = 'public'
            AND EXISTS (
                SELECT 1 FROM information_schema.constraint_column_usage
                WHERE constraint_name = tc.constraint_name
                AND table_name = 'users'
            )
        ORDER BY tc.table_name
    LOOP
        RAISE NOTICE 'Table: %, Column: %, Delete: %, Update: %',
            fk_record.table_name,
            fk_record.column_name,
            fk_record.delete_rule,
            fk_record.update_rule;

        IF fk_record.delete_rule != 'CASCADE' OR fk_record.update_rule != 'CASCADE' THEN
            RAISE WARNING 'Missing CASCADE on %.%', fk_record.table_name, fk_record.column_name;
            missing_cascade := TRUE;
        END IF;
    END LOOP;

    IF NOT missing_cascade THEN
        RAISE NOTICE '✅ All foreign keys to users table have CASCADE constraints';
    ELSE
        RAISE WARNING '⚠️ Some foreign keys are missing CASCADE constraints';
    END IF;
END $$;

-- =====================================================
-- 7. Add helpful comments
-- =====================================================

COMMENT ON CONSTRAINT user_profiles_user_id_fkey ON user_profiles IS
    'Cascades deletes and updates from users table to user_profiles';

COMMENT ON CONSTRAINT medical_provider_profiles_user_id_fkey ON medical_provider_profiles IS
    'Cascades deletes and updates from users table to medical_provider_profiles';

COMMENT ON CONSTRAINT facility_admin_profiles_user_id_fkey ON facility_admin_profiles IS
    'Cascades deletes and updates from users table to facility_admin_profiles';

COMMENT ON CONSTRAINT system_admin_profiles_user_id_fkey ON system_admin_profiles IS
    'Cascades deletes and updates from users table to system_admin_profiles';

COMMENT ON CONSTRAINT electronic_health_records_patient_id_fkey ON electronic_health_records IS
    'Cascades deletes and updates from users table to electronic_health_records';
