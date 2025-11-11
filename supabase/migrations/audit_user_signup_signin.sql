-- =====================================================
-- Comprehensive User Signup/Signin Audit
-- Date: 2025-11-03
-- Purpose: Verify integrity of user authentication system
-- =====================================================

DO $$
DECLARE
    audit_report TEXT := '';
    issue_count INTEGER := 0;
    total_users INTEGER;
    users_without_ehr INTEGER;
    ehrs_without_users INTEGER;
    users_without_profiles INTEGER;
    rls_enabled_count INTEGER;
    cascade_constraint_count INTEGER;
    set_null_constraint_count INTEGER;
    missing_constraint_count INTEGER;
BEGIN
    audit_report := E'\n' || '╔════════════════════════════════════════════════════════════════════╗' || E'\n';
    audit_report := audit_report || '║     USER SIGNUP/SIGNIN COMPREHENSIVE AUDIT REPORT                  ║' || E'\n';
    audit_report := audit_report || '║     Date: ' || CURRENT_TIMESTAMP || '                    ║' || E'\n';
    audit_report := audit_report || '╚════════════════════════════════════════════════════════════════════╝' || E'\n\n';

    -- =====================================================
    -- SECTION 1: User Account Statistics
    -- =====================================================
    audit_report := audit_report || E'\n' || '═══ SECTION 1: USER ACCOUNT STATISTICS ═══' || E'\n\n';

    SELECT COUNT(*) INTO total_users FROM users;
    audit_report := audit_report || 'Total users in database: ' || total_users || E'\n';

    -- Count users by creation date
    audit_report := audit_report || E'\nUsers created in last:' || E'\n';
    audit_report := audit_report || '  - 24 hours: ' || (SELECT COUNT(*) FROM users WHERE created_at > NOW() - INTERVAL '24 hours') || E'\n';
    audit_report := audit_report || '  - 7 days:   ' || (SELECT COUNT(*) FROM users WHERE created_at > NOW() - INTERVAL '7 days') || E'\n';
    audit_report := audit_report || '  - 30 days:  ' || (SELECT COUNT(*) FROM users WHERE created_at > NOW() - INTERVAL '30 days') || E'\n';

    -- =====================================================
    -- SECTION 2: Data Integrity Checks
    -- =====================================================
    audit_report := audit_report || E'\n' || '═══ SECTION 2: DATA INTEGRITY CHECKS ═══' || E'\n\n';

    -- Check 1: Users without EHRs
    SELECT COUNT(*) INTO users_without_ehr
    FROM users u
    WHERE NOT EXISTS (
        SELECT 1 FROM electronic_health_records ehr
        WHERE ehr.patient_id = u.id
    );

    IF users_without_ehr > 0 THEN
        issue_count := issue_count + 1;
        audit_report := audit_report || '❌ CRITICAL: ' || users_without_ehr || ' users without EHR records' || E'\n';
        audit_report := audit_report || '   Users: ' || E'\n';
        FOR rec IN (
            SELECT u.id, u.email, u.created_at
            FROM users u
            WHERE NOT EXISTS (
                SELECT 1 FROM electronic_health_records ehr
                WHERE ehr.patient_id = u.id
            )
            LIMIT 10
        ) LOOP
            audit_report := audit_report || '   - ' || rec.email || ' (ID: ' || rec.id || ', created: ' || rec.created_at || ')' || E'\n';
        END LOOP;
        IF users_without_ehr > 10 THEN
            audit_report := audit_report || '   ... and ' || (users_without_ehr - 10) || ' more' || E'\n';
        END IF;
    ELSE
        audit_report := audit_report || '✅ All users have EHR records' || E'\n';
    END IF;

    -- Check 2: EHRs without users
    SELECT COUNT(*) INTO ehrs_without_users
    FROM electronic_health_records ehr
    WHERE NOT EXISTS (
        SELECT 1 FROM users u
        WHERE u.id = ehr.patient_id
    );

    IF ehrs_without_users > 0 THEN
        issue_count := issue_count + 1;
        audit_report := audit_report || '⚠️  WARNING: ' || ehrs_without_users || ' orphaned EHR records (no matching user)' || E'\n';
    ELSE
        audit_report := audit_report || '✅ No orphaned EHR records' || E'\n';
    END IF;

    -- Check 3: Users without user_profiles
    SELECT COUNT(*) INTO users_without_profiles
    FROM users u
    WHERE NOT EXISTS (
        SELECT 1 FROM user_profiles up
        WHERE up.user_id = u.id
    );

    IF users_without_profiles > 0 THEN
        audit_report := audit_report || 'ℹ️  INFO: ' || users_without_profiles || ' users without user_profiles (may be newly created)' || E'\n';
        audit_report := audit_report || '   Note: User profiles are created when users select their role in the app' || E'\n';
    ELSE
        audit_report := audit_report || '✅ All users have user_profiles' || E'\n';
    END IF;

    -- Check 4: Profile completeness by role
    audit_report := audit_report || E'\n' || 'Profile completeness by role:' || E'\n';
    FOR rec IN (
        SELECT
            up.role,
            COUNT(*) as total,
            COUNT(CASE
                WHEN up.role = 'patient' AND EXISTS (SELECT 1 FROM patient_profiles pp WHERE pp.user_id = up.user_id) THEN 1
                WHEN up.role = 'medical_provider' AND EXISTS (SELECT 1 FROM medical_provider_profiles mp WHERE mp.user_id = up.user_id) THEN 1
                WHEN up.role = 'facility_admin' AND EXISTS (SELECT 1 FROM facility_admin_profiles fa WHERE fa.user_id = up.user_id) THEN 1
                WHEN up.role = 'system_admin' AND EXISTS (SELECT 1 FROM system_admin_profiles sa WHERE sa.user_id = up.user_id) THEN 1
            END) as with_role_profile
        FROM user_profiles up
        GROUP BY up.role
    ) LOOP
        audit_report := audit_report || '  - ' || COALESCE(rec.role, 'null') || ': ' || rec.with_role_profile || '/' || rec.total || ' have role-specific profile' || E'\n';
    END LOOP;

    -- =====================================================
    -- SECTION 3: RLS Policy Verification
    -- =====================================================
    audit_report := audit_report || E'\n' || '═══ SECTION 3: ROW-LEVEL SECURITY (RLS) STATUS ═══' || E'\n\n';

    -- Check RLS enabled on critical tables
    FOR rec IN (
        SELECT
            tablename,
            CASE WHEN rowsecurity THEN '✅ Enabled' ELSE '❌ Disabled' END as rls_status
        FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename IN (
            'users', 'user_profiles', 'patient_profiles', 'medical_provider_profiles',
            'facility_admin_profiles', 'system_admin_profiles', 'electronic_health_records'
        )
        ORDER BY tablename
    ) LOOP
        audit_report := audit_report || rec.rls_status || ' - ' || rec.tablename || E'\n';
        IF rec.rls_status LIKE '%Disabled%' THEN
            issue_count := issue_count + 1;
        END IF;
    END LOOP;

    -- Count RLS policies
    SELECT COUNT(*) INTO rls_enabled_count
    FROM pg_policies
    WHERE schemaname = 'public'
    AND tablename IN (
        'user_profiles', 'patient_profiles', 'medical_provider_profiles',
        'facility_admin_profiles', 'system_admin_profiles'
    );

    audit_report := audit_report || E'\n' || 'Total RLS policies on profile tables: ' || rls_enabled_count || ' (expected: 25)' || E'\n';

    IF rls_enabled_count < 25 THEN
        issue_count := issue_count + 1;
        audit_report := audit_report || '⚠️  WARNING: Missing RLS policies (found ' || rls_enabled_count || ', expected 25)' || E'\n';
    END IF;

    -- =====================================================
    -- SECTION 4: Foreign Key CASCADE Constraints
    -- =====================================================
    audit_report := audit_report || E'\n' || '═══ SECTION 4: CASCADE CONSTRAINT VERIFICATION ═══' || E'\n\n';

    -- Count CASCADE constraints
    SELECT COUNT(*) INTO cascade_constraint_count
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
        AND rc.delete_rule = 'CASCADE'
        AND rc.update_rule = 'CASCADE';

    -- Count SET NULL constraints (audit tables)
    SELECT COUNT(*) INTO set_null_constraint_count
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
        AND rc.delete_rule = 'SET NULL';

    audit_report := audit_report || 'Foreign keys to users table:' || E'\n';
    audit_report := audit_report || '  - CASCADE (DELETE + UPDATE): ' || cascade_constraint_count || E'\n';
    audit_report := audit_report || '  - SET NULL (audit tables):   ' || set_null_constraint_count || E'\n';
    audit_report := audit_report || '  - Total: ' || (cascade_constraint_count + set_null_constraint_count) || E'\n';

    -- Check for missing CASCADE constraints
    SELECT COUNT(*) INTO missing_constraint_count
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
        AND rc.delete_rule = 'NO ACTION';

    IF missing_constraint_count > 0 THEN
        issue_count := issue_count + 1;
        audit_report := audit_report || E'\n' || '⚠️  WARNING: ' || missing_constraint_count || ' foreign keys with NO ACTION (should be CASCADE or SET NULL)' || E'\n';

        -- List tables with missing CASCADE
        FOR rec IN (
            SELECT tc.table_name, kcu.column_name
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
                AND rc.delete_rule = 'NO ACTION'
            LIMIT 10
        ) LOOP
            audit_report := audit_report || '   - ' || rec.table_name || '.' || rec.column_name || E'\n';
        END LOOP;
    ELSE
        audit_report := audit_report || '✅ All foreign keys properly configured with CASCADE or SET NULL' || E'\n';
    END IF;

    -- =====================================================
    -- SECTION 5: Database Triggers & Functions
    -- =====================================================
    audit_report := audit_report || E'\n' || '═══ SECTION 5: TRIGGER FUNCTIONS STATUS ═══' || E'\n\n';

    -- Check critical triggers
    FOR rec IN (
        SELECT
            t.tgname as trigger_name,
            c.relname as table_name,
            CASE WHEN t.tgenabled = 'O' THEN '✅ Enabled' ELSE '❌ Disabled' END as status
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        WHERE c.relnamespace = 'public'::regnamespace
        AND t.tgname LIKE '%ehrbase%' OR t.tgname LIKE '%profile%'
        ORDER BY c.relname, t.tgname
    ) LOOP
        audit_report := audit_report || rec.status || ' - ' || rec.table_name || '.' || rec.trigger_name || E'\n';
        IF rec.status LIKE '%Disabled%' THEN
            issue_count := issue_count + 1;
        END IF;
    END LOOP;

    -- =====================================================
    -- SECTION 6: Recent Signup Activity
    -- =====================================================
    audit_report := audit_report || E'\n' || '═══ SECTION 6: RECENT SIGNUP ACTIVITY ═══' || E'\n\n';

    audit_report := audit_report || 'Last 10 user signups:' || E'\n';
    FOR rec IN (
        SELECT
            u.email,
            u.created_at,
            CASE
                WHEN EXISTS (SELECT 1 FROM electronic_health_records WHERE patient_id = u.id) THEN '✅'
                ELSE '❌'
            END as has_ehr,
            CASE
                WHEN EXISTS (SELECT 1 FROM user_profiles WHERE user_id = u.id) THEN '✅'
                ELSE '⏳'
            END as has_profile
        FROM users u
        ORDER BY u.created_at DESC
        LIMIT 10
    ) LOOP
        audit_report := audit_report || '  ' || rec.created_at || ' | ' || rec.email || ' | EHR:' || rec.has_ehr || ' Profile:' || rec.has_profile || E'\n';
    END LOOP;

    -- =====================================================
    -- SECTION 7: Summary & Recommendations
    -- =====================================================
    audit_report := audit_report || E'\n' || '═══ SECTION 7: AUDIT SUMMARY ═══' || E'\n\n';

    IF issue_count = 0 THEN
        audit_report := audit_report || '✅ ✅ ✅  ALL CHECKS PASSED - System is healthy!  ✅ ✅ ✅' || E'\n';
    ELSE
        audit_report := audit_report || '⚠️  TOTAL ISSUES FOUND: ' || issue_count || E'\n\n';
        audit_report := audit_report || 'RECOMMENDED ACTIONS:' || E'\n';

        IF users_without_ehr > 0 THEN
            audit_report := audit_report || '  1. Investigate users without EHRs - check Firebase Cloud Function logs' || E'\n';
            audit_report := audit_report || '     Command: firebase functions:log --only onUserCreated' || E'\n';
        END IF;

        IF ehrs_without_users > 0 THEN
            audit_report := audit_report || '  2. Clean up orphaned EHR records or restore missing user entries' || E'\n';
        END IF;

        IF missing_constraint_count > 0 THEN
            audit_report := audit_report || '  3. Apply comprehensive CASCADE constraints migration' || E'\n';
            audit_report := audit_report || '     File: 20251103220001_comprehensive_cascade_constraints.sql' || E'\n';
        END IF;
    END IF;

    audit_report := audit_report || E'\n' || 'Audit completed: ' || CURRENT_TIMESTAMP || E'\n';
    audit_report := audit_report || '════════════════════════════════════════════════════════════════════' || E'\n';

    -- Output the complete report
    RAISE NOTICE '%', audit_report;
END $$;
