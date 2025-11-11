-- Migration: Comprehensive CASCADE constraints for all tables referencing users
-- This migration adds ON DELETE CASCADE and ON UPDATE CASCADE to all appropriate tables
-- Excludes audit/log tables which should preserve data for compliance
-- Date: 2025-11-03

-- =====================================================
-- Helper function to update foreign key constraints
-- =====================================================

CREATE OR REPLACE FUNCTION update_foreign_key_cascade(
    p_table_name TEXT,
    p_column_name TEXT,
    p_constraint_name TEXT
)
RETURNS VOID AS $$
BEGIN
    -- Drop existing constraint
    EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', p_table_name, p_constraint_name);

    -- Add new constraint with CASCADE
    EXECUTE format(
        'ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE',
        p_table_name,
        p_constraint_name,
        p_column_name
    );

    RAISE NOTICE 'Updated %: % -> CASCADE', p_table_name, p_column_name;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- Update all medical/clinical data tables
-- =====================================================

-- Profile tables
SELECT update_foreign_key_cascade('admin_profiles', 'user_id', 'admin_profiles_user_id_fkey');
SELECT update_foreign_key_cascade('doctor_profiles', 'user_id', 'doctor_profiles_user_id_fkey');
SELECT update_foreign_key_cascade('lab_technician_profiles', 'user_id', 'lab_technician_profiles_user_id_fkey');
SELECT update_foreign_key_cascade('nurse_profiles', 'user_id', 'nurse_profiles_user_id_fkey');
SELECT update_foreign_key_cascade('patient_profiles', 'user_id', 'patient_profiles_user_id_fkey');
SELECT update_foreign_key_cascade('pharmacist_profiles', 'user_id', 'pharmacist_profiles_user_id_fkey');

-- Medical data tables (patient_id)
SELECT update_foreign_key_cascade('admission_discharges', 'patient_id', 'admission_discharges_patient_id_fkey');
SELECT update_foreign_key_cascade('antenatal_visits', 'patient_id', 'antenatal_visits_patient_id_fkey');
SELECT update_foreign_key_cascade('appointments', 'patient_id', 'appointments_patient_id_fkey');
SELECT update_foreign_key_cascade('cardiology_visits', 'patient_id', 'cardiology_visits_patient_id_fkey');
SELECT update_foreign_key_cascade('clinical_consultations', 'patient_id', 'clinical_consultations_patient_id_fkey');
SELECT update_foreign_key_cascade('emergency_visits', 'patient_id', 'emergency_visits_patient_id_fkey');
SELECT update_foreign_key_cascade('endocrinology_visits', 'patient_id', 'endocrinology_visits_patient_id_fkey');
SELECT update_foreign_key_cascade('gastroenterology_procedures', 'patient_id', 'gastroenterology_procedures_patient_id_fkey');
SELECT update_foreign_key_cascade('immunizations', 'patient_id', 'immunizations_patient_id_fkey');
SELECT update_foreign_key_cascade('infectious_disease_visits', 'patient_id', 'infectious_disease_visits_patient_id_fkey');
SELECT update_foreign_key_cascade('invoices', 'patient_id', 'invoices_patient_id_fkey');
SELECT update_foreign_key_cascade('lab_orders', 'patient_id', 'lab_orders_patient_id_fkey');
SELECT update_foreign_key_cascade('lab_results', 'patient_id', 'lab_results_patient_id_fkey');
SELECT update_foreign_key_cascade('medical_records', 'patient_id', 'medical_records_patient_id_fkey');
SELECT update_foreign_key_cascade('medication_dispensing', 'patient_id', 'medication_dispensing_patient_id_fkey');
SELECT update_foreign_key_cascade('nephrology_visits', 'patient_id', 'nephrology_visits_patient_id_fkey');
SELECT update_foreign_key_cascade('neurology_exams', 'patient_id', 'neurology_exams_patient_id_fkey');
SELECT update_foreign_key_cascade('oncology_treatments', 'patient_id', 'oncology_treatments_patient_id_fkey');
SELECT update_foreign_key_cascade('pathology_reports', 'patient_id', 'pathology_reports_patient_id_fkey');
SELECT update_foreign_key_cascade('patient_medical_report_exports', 'patient_id', 'patient_medical_report_exports_patient_id_fkey');
SELECT update_foreign_key_cascade('physiotherapy_sessions', 'patient_id', 'physiotherapy_sessions_patient_id_fkey');
SELECT update_foreign_key_cascade('prescriptions', 'patient_id', 'prescriptions_patient_id_fkey');
SELECT update_foreign_key_cascade('psychiatric_assessments', 'patient_id', 'psychiatric_assessments_patient_id_fkey');
SELECT update_foreign_key_cascade('pulmonology_visits', 'patient_id', 'pulmonology_visits_patient_id_fkey');
SELECT update_foreign_key_cascade('radiology_reports', 'patient_id', 'radiology_reports_patient_id_fkey');
SELECT update_foreign_key_cascade('surgical_procedures', 'patient_id', 'surgical_procedures_patient_id_fkey');
SELECT update_foreign_key_cascade('vital_signs', 'patient_id', 'vital_signs_patient_id_fkey');
SELECT update_foreign_key_cascade('waitlist', 'patient_id', 'waitlist_patient_id_fkey');

-- User-related data tables (user_id)
SELECT update_foreign_key_cascade('ai_conversations', 'user_id', 'ai_conversations_user_id_fkey');
SELECT update_foreign_key_cascade('announcement_reads', 'user_id', 'announcement_reads_user_id_fkey');
SELECT update_foreign_key_cascade('blood_donors', 'user_id', 'blood_donors_user_id_fkey');
SELECT update_foreign_key_cascade('documents', 'user_id', 'documents_user_id_fkey');
SELECT update_foreign_key_cascade('message_reactions', 'user_id', 'message_reactions_user_id_fkey');
SELECT update_foreign_key_cascade('notification_preferences', 'user_id', 'notification_preferences_user_id_fkey');
SELECT update_foreign_key_cascade('notifications', 'user_id', 'notifications_user_id_fkey');
SELECT update_foreign_key_cascade('payment_methods', 'user_id', 'payment_methods_user_id_fkey');
SELECT update_foreign_key_cascade('profile_pictures', 'user_id', 'profile_pictures_user_id_fkey');
SELECT update_foreign_key_cascade('promotion_usage', 'user_id', 'promotion_usage_user_id_fkey');
SELECT update_foreign_key_cascade('provider_type_assignments', 'user_id', 'provider_type_assignments_user_id_fkey');
SELECT update_foreign_key_cascade('publication_bookmarks', 'user_id', 'publication_bookmarks_user_id_fkey');
SELECT update_foreign_key_cascade('publication_comments', 'user_id', 'publication_comments_user_id_fkey');
SELECT update_foreign_key_cascade('publication_likes', 'user_id', 'publication_likes_user_id_fkey');
SELECT update_foreign_key_cascade('reminders', 'user_id', 'reminders_user_id_fkey');
SELECT update_foreign_key_cascade('transactions', 'user_id', 'transactions_user_id_fkey');
SELECT update_foreign_key_cascade('user_allergies', 'user_id', 'user_allergies_user_id_fkey');
SELECT update_foreign_key_cascade('user_medical_conditions', 'user_id', 'user_medical_conditions_user_id_fkey');
SELECT update_foreign_key_cascade('user_medications', 'user_id', 'user_medications_user_id_fkey');
SELECT update_foreign_key_cascade('user_subscriptions', 'user_id', 'user_subscriptions_user_id_fkey');

-- =====================================================
-- Audit/Log tables - Make user_id nullable and keep NO ACTION
-- These tables should preserve data for compliance even if user is deleted
-- =====================================================

-- First, make user_id nullable in audit/log tables
ALTER TABLE email_logs ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE feedback ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE push_notifications ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE search_analytics ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE sms_logs ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE speech_to_text_logs ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE system_audit_logs ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE user_activity_logs ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE ussd_actions ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE ussd_sessions ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE whatsapp_logs ALTER COLUMN user_id DROP NOT NULL;

-- Update constraints to SET NULL on delete (preserve audit trail)
DO $$
DECLARE
    audit_tables TEXT[] := ARRAY[
        'email_logs', 'feedback', 'push_notifications', 'search_analytics',
        'sms_logs', 'speech_to_text_logs', 'system_audit_logs', 'user_activity_logs',
        'ussd_actions', 'ussd_sessions', 'whatsapp_logs'
    ];
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY audit_tables
    LOOP
        EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', tbl, tbl || '_user_id_fkey');
        EXECUTE format(
            'ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE',
            tbl,
            tbl || '_user_id_fkey'
        );
        RAISE NOTICE 'Updated audit table %: user_id -> SET NULL on delete', tbl;
    END LOOP;
END $$;

-- =====================================================
-- Add comments explaining the strategy
-- =====================================================

COMMENT ON CONSTRAINT admin_profiles_user_id_fkey ON admin_profiles IS
    'CASCADE: Deletes admin profile when user is deleted';

COMMENT ON CONSTRAINT doctor_profiles_user_id_fkey ON doctor_profiles IS
    'CASCADE: Deletes doctor profile when user is deleted';

COMMENT ON CONSTRAINT patient_profiles_user_id_fkey ON patient_profiles IS
    'CASCADE: Deletes patient profile when user is deleted';

COMMENT ON CONSTRAINT vital_signs_patient_id_fkey ON vital_signs IS
    'CASCADE: Deletes vital signs when patient is deleted';

COMMENT ON CONSTRAINT email_logs_user_id_fkey ON email_logs IS
    'SET NULL: Preserves email logs for compliance when user is deleted';

COMMENT ON CONSTRAINT system_audit_logs_user_id_fkey ON system_audit_logs IS
    'SET NULL: Preserves audit trail for compliance when user is deleted';

-- =====================================================
-- Verification: Show final state
-- =====================================================

DO $$
DECLARE
    fk_record RECORD;
    cascade_count INTEGER := 0;
    set_null_count INTEGER := 0;
    total_count INTEGER := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== Final Foreign Key Constraint Summary ===';
    RAISE NOTICE '';

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
        total_count := total_count + 1;

        IF fk_record.delete_rule = 'CASCADE' AND fk_record.update_rule = 'CASCADE' THEN
            cascade_count := cascade_count + 1;
        ELSIF fk_record.delete_rule = 'SET NULL' THEN
            set_null_count := set_null_count + 1;
        END IF;
    END LOOP;

    RAISE NOTICE 'Total foreign keys to users: %', total_count;
    RAISE NOTICE 'With CASCADE (DELETE + UPDATE): %', cascade_count;
    RAISE NOTICE 'With SET NULL (audit tables): %', set_null_count;
    RAISE NOTICE '';
    RAISE NOTICE '✅ Migration complete!';
END $$;

-- Drop helper function
DROP FUNCTION update_foreign_key_cascade(TEXT, TEXT, TEXT);
