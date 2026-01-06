-- ============================================================================
-- Comprehensive RLS Compliance Migration (CORRECTED)
-- MedZen Healthcare Database
-- Created: December 19, 2025
-- Purpose: Enable RLS on all remaining tables for HIPAA/GDPR compliance
-- ============================================================================
-- CRITICAL FIX: Profile tables (system_admin_profiles, facility_admin_profiles,
-- medical_provider_profiles) do NOT have firebase_uid column directly.
-- They have user_id -> users.id -> users.firebase_uid
-- All policies must JOIN through users table to check firebase_uid
-- ============================================================================

-- Helper function for admin access check (uses JOIN pattern)
CREATE OR REPLACE FUNCTION is_system_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM system_admin_profiles sap
        JOIN users u ON sap.user_id = u.id
        WHERE u.firebase_uid = auth.uid()::text
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_facility_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM facility_admin_profiles fap
        JOIN users u ON fap.user_id = u.id
        WHERE u.firebase_uid = auth.uid()::text
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_medical_provider()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM medical_provider_profiles mpp
        JOIN users u ON mpp.user_id = u.id
        WHERE u.firebase_uid = auth.uid()::text
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_any_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN is_system_admin() OR is_facility_admin();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- SECTION 1: COMMUNICATION & LOGGING TABLES
-- ============================================================================

-- email_logs - service role only (automated system)
ALTER TABLE IF EXISTS email_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "email_logs_service_only" ON email_logs;
CREATE POLICY "email_logs_service_only"
ON email_logs FOR ALL TO service_role
USING (true);

DROP POLICY IF EXISTS "email_logs_admin_read" ON email_logs;
CREATE POLICY "email_logs_admin_read"
ON email_logs FOR SELECT TO authenticated
USING (is_system_admin());

-- sms_logs - service role only
ALTER TABLE IF EXISTS sms_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "sms_logs_service_only" ON sms_logs;
CREATE POLICY "sms_logs_service_only"
ON sms_logs FOR ALL TO service_role
USING (true);

DROP POLICY IF EXISTS "sms_logs_admin_read" ON sms_logs;
CREATE POLICY "sms_logs_admin_read"
ON sms_logs FOR SELECT TO authenticated
USING (is_system_admin());

-- whatsapp_logs - service role only
ALTER TABLE IF EXISTS whatsapp_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "whatsapp_logs_service_only" ON whatsapp_logs;
CREATE POLICY "whatsapp_logs_service_only"
ON whatsapp_logs FOR ALL TO service_role
USING (true);

DROP POLICY IF EXISTS "whatsapp_logs_admin_read" ON whatsapp_logs;
CREATE POLICY "whatsapp_logs_admin_read"
ON whatsapp_logs FOR SELECT TO authenticated
USING (is_system_admin());

-- speech_to_text_logs - service role only
ALTER TABLE IF EXISTS speech_to_text_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "speech_to_text_logs_service_only" ON speech_to_text_logs;
CREATE POLICY "speech_to_text_logs_service_only"
ON speech_to_text_logs FOR ALL TO service_role
USING (true);

DROP POLICY IF EXISTS "speech_to_text_logs_admin_read" ON speech_to_text_logs;
CREATE POLICY "speech_to_text_logs_admin_read"
ON speech_to_text_logs FOR SELECT TO authenticated
USING (is_system_admin());

-- system_audit_logs - service role only (sensitive)
ALTER TABLE IF EXISTS system_audit_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "system_audit_logs_service_only" ON system_audit_logs;
CREATE POLICY "system_audit_logs_service_only"
ON system_audit_logs FOR ALL TO service_role
USING (true);

DROP POLICY IF EXISTS "system_audit_logs_admin_read" ON system_audit_logs;
CREATE POLICY "system_audit_logs_admin_read"
ON system_audit_logs FOR SELECT TO authenticated
USING (is_system_admin());

-- user_activity_logs - own access + admin read
ALTER TABLE IF EXISTS user_activity_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_activity_logs_own" ON user_activity_logs;
CREATE POLICY "user_activity_logs_own"
ON user_activity_logs FOR SELECT TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_system_admin()
);

DROP POLICY IF EXISTS "user_activity_logs_insert" ON user_activity_logs;
CREATE POLICY "user_activity_logs_insert"
ON user_activity_logs FOR INSERT TO authenticated
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- feedback - own access + admin read
ALTER TABLE IF EXISTS feedback ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "feedback_own_access" ON feedback;
CREATE POLICY "feedback_own_access"
ON feedback FOR SELECT TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
);

DROP POLICY IF EXISTS "feedback_insert" ON feedback;
CREATE POLICY "feedback_insert"
ON feedback FOR INSERT TO authenticated
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- ============================================================================
-- SECTION 2: MARKETING & CONTENT TABLES
-- ============================================================================

-- announcements - public read, admin manage
ALTER TABLE IF EXISTS announcements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "announcements_public_read" ON announcements;
CREATE POLICY "announcements_public_read"
ON announcements FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "announcements_admin_manage" ON announcements;
CREATE POLICY "announcements_admin_manage"
ON announcements FOR ALL TO authenticated
USING (is_any_admin())
WITH CHECK (is_any_admin());

-- announcement_reads - own access
ALTER TABLE IF EXISTS announcement_reads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "announcement_reads_own" ON announcement_reads;
CREATE POLICY "announcement_reads_own"
ON announcement_reads FOR ALL TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
)
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- promotions - public read, admin manage
ALTER TABLE IF EXISTS promotions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "promotions_public_read" ON promotions;
CREATE POLICY "promotions_public_read"
ON promotions FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "promotions_admin_manage" ON promotions;
CREATE POLICY "promotions_admin_manage"
ON promotions FOR ALL TO authenticated
USING (is_any_admin())
WITH CHECK (is_any_admin());

-- promotion_usage - own access + admin read
ALTER TABLE IF EXISTS promotion_usage ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "promotion_usage_own" ON promotion_usage;
CREATE POLICY "promotion_usage_own"
ON promotion_usage FOR SELECT TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
);

DROP POLICY IF EXISTS "promotion_usage_insert" ON promotion_usage;
CREATE POLICY "promotion_usage_insert"
ON promotion_usage FOR INSERT TO authenticated
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- publications - public read
ALTER TABLE IF EXISTS publications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "publications_public_read" ON publications;
CREATE POLICY "publications_public_read"
ON publications FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "publications_author_manage" ON publications;
CREATE POLICY "publications_author_manage"
ON publications FOR ALL TO authenticated
USING (
    author_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
)
WITH CHECK (
    author_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
);

-- publication_comments - public read, own manage
ALTER TABLE IF EXISTS publication_comments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "publication_comments_public_read" ON publication_comments;
CREATE POLICY "publication_comments_public_read"
ON publication_comments FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "publication_comments_own_manage" ON publication_comments;
CREATE POLICY "publication_comments_own_manage"
ON publication_comments FOR ALL TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
)
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- publication_likes - own access
ALTER TABLE IF EXISTS publication_likes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "publication_likes_public_read" ON publication_likes;
CREATE POLICY "publication_likes_public_read"
ON publication_likes FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "publication_likes_own_manage" ON publication_likes;
CREATE POLICY "publication_likes_own_manage"
ON publication_likes FOR ALL TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
)
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- publication_bookmarks - own access
ALTER TABLE IF EXISTS publication_bookmarks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "publication_bookmarks_own" ON publication_bookmarks;
CREATE POLICY "publication_bookmarks_own"
ON publication_bookmarks FOR ALL TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
)
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- ============================================================================
-- SECTION 3: FACILITY & PROVIDER MANAGEMENT
-- ============================================================================

-- facility_types - public read, admin manage
ALTER TABLE IF EXISTS facility_types ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "facility_types_public_read" ON facility_types;
CREATE POLICY "facility_types_public_read"
ON facility_types FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "facility_types_admin_manage" ON facility_types;
CREATE POLICY "facility_types_admin_manage"
ON facility_types FOR ALL TO authenticated
USING (is_system_admin())
WITH CHECK (is_system_admin());

-- facility_type_assignments
ALTER TABLE IF EXISTS facility_type_assignments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "facility_type_assignments_read" ON facility_type_assignments;
CREATE POLICY "facility_type_assignments_read"
ON facility_type_assignments FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "facility_type_assignments_admin_manage" ON facility_type_assignments;
CREATE POLICY "facility_type_assignments_admin_manage"
ON facility_type_assignments FOR ALL TO authenticated
USING (is_any_admin())
WITH CHECK (is_any_admin());

-- facility_departments - public read
ALTER TABLE IF EXISTS facility_departments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "facility_departments_public_read" ON facility_departments;
CREATE POLICY "facility_departments_public_read"
ON facility_departments FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "facility_departments_admin_manage" ON facility_departments;
CREATE POLICY "facility_departments_admin_manage"
ON facility_departments FOR ALL TO authenticated
USING (is_any_admin())
WITH CHECK (is_any_admin());

-- facility_department_assignments
ALTER TABLE IF EXISTS facility_department_assignments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "facility_department_assignments_read" ON facility_department_assignments;
CREATE POLICY "facility_department_assignments_read"
ON facility_department_assignments FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "facility_department_assignments_admin_manage" ON facility_department_assignments;
CREATE POLICY "facility_department_assignments_admin_manage"
ON facility_department_assignments FOR ALL TO authenticated
USING (is_any_admin())
WITH CHECK (is_any_admin());

-- facility_providers
ALTER TABLE IF EXISTS facility_providers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "facility_providers_public_read" ON facility_providers;
CREATE POLICY "facility_providers_public_read"
ON facility_providers FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "facility_providers_admin_manage" ON facility_providers;
CREATE POLICY "facility_providers_admin_manage"
ON facility_providers FOR ALL TO authenticated
USING (is_any_admin())
WITH CHECK (is_any_admin());

-- facility_reports - facility admin + system admin
ALTER TABLE IF EXISTS facility_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "facility_reports_admin_access" ON facility_reports;
CREATE POLICY "facility_reports_admin_access"
ON facility_reports FOR SELECT TO authenticated
USING (is_any_admin());

DROP POLICY IF EXISTS "facility_reports_admin_manage" ON facility_reports;
CREATE POLICY "facility_reports_admin_manage"
ON facility_reports FOR ALL TO authenticated
USING (is_any_admin())
WITH CHECK (is_any_admin());

-- ============================================================================
-- SECTION 4: PROVIDER SCHEDULING & SERVICES
-- ============================================================================

-- provider_availability - public read, provider manage
ALTER TABLE IF EXISTS provider_availability ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "provider_availability_public_read" ON provider_availability;
CREATE POLICY "provider_availability_public_read"
ON provider_availability FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "provider_availability_provider_manage" ON provider_availability;
CREATE POLICY "provider_availability_provider_manage"
ON provider_availability FOR ALL TO authenticated
USING (
    provider_id IN (
        SELECT mpp.id FROM medical_provider_profiles mpp
        JOIN users u ON mpp.user_id = u.id
        WHERE u.firebase_uid = auth.uid()::text
    )
    OR is_any_admin()
)
WITH CHECK (
    provider_id IN (
        SELECT mpp.id FROM medical_provider_profiles mpp
        JOIN users u ON mpp.user_id = u.id
        WHERE u.firebase_uid = auth.uid()::text
    )
    OR is_any_admin()
);

-- provider_schedule_exceptions
ALTER TABLE IF EXISTS provider_schedule_exceptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "provider_schedule_exceptions_read" ON provider_schedule_exceptions;
CREATE POLICY "provider_schedule_exceptions_read"
ON provider_schedule_exceptions FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "provider_schedule_exceptions_provider_manage" ON provider_schedule_exceptions;
CREATE POLICY "provider_schedule_exceptions_provider_manage"
ON provider_schedule_exceptions FOR ALL TO authenticated
USING (
    provider_id IN (
        SELECT mpp.id FROM medical_provider_profiles mpp
        JOIN users u ON mpp.user_id = u.id
        WHERE u.firebase_uid = auth.uid()::text
    )
    OR is_any_admin()
)
WITH CHECK (
    provider_id IN (
        SELECT mpp.id FROM medical_provider_profiles mpp
        JOIN users u ON mpp.user_id = u.id
        WHERE u.firebase_uid = auth.uid()::text
    )
    OR is_any_admin()
);

-- specialty_services - public read
ALTER TABLE IF EXISTS specialty_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "specialty_services_public_read" ON specialty_services;
CREATE POLICY "specialty_services_public_read"
ON specialty_services FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "specialty_services_admin_manage" ON specialty_services;
CREATE POLICY "specialty_services_admin_manage"
ON specialty_services FOR ALL TO authenticated
USING (is_system_admin())
WITH CHECK (is_system_admin());

-- provider_specialty_services
ALTER TABLE IF EXISTS provider_specialty_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "provider_specialty_services_public_read" ON provider_specialty_services;
CREATE POLICY "provider_specialty_services_public_read"
ON provider_specialty_services FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "provider_specialty_services_provider_manage" ON provider_specialty_services;
CREATE POLICY "provider_specialty_services_provider_manage"
ON provider_specialty_services FOR ALL TO authenticated
USING (
    provider_id IN (
        SELECT mpp.id FROM medical_provider_profiles mpp
        JOIN users u ON mpp.user_id = u.id
        WHERE u.firebase_uid = auth.uid()::text
    )
    OR is_any_admin()
)
WITH CHECK (
    provider_id IN (
        SELECT mpp.id FROM medical_provider_profiles mpp
        JOIN users u ON mpp.user_id = u.id
        WHERE u.firebase_uid = auth.uid()::text
    )
    OR is_any_admin()
);

-- ============================================================================
-- SECTION 5: REFERENCE DATA (Public Read)
-- ============================================================================

-- specialties - public read
ALTER TABLE IF EXISTS specialties ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "specialties_public_read" ON specialties;
CREATE POLICY "specialties_public_read"
ON specialties FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "specialties_admin_manage" ON specialties;
CREATE POLICY "specialties_admin_manage"
ON specialties FOR ALL TO authenticated
USING (is_system_admin())
WITH CHECK (is_system_admin());

-- provider_specialties
ALTER TABLE IF EXISTS provider_specialties ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "provider_specialties_public_read" ON provider_specialties;
CREATE POLICY "provider_specialties_public_read"
ON provider_specialties FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "provider_specialties_provider_manage" ON provider_specialties;
CREATE POLICY "provider_specialties_provider_manage"
ON provider_specialties FOR ALL TO authenticated
USING (
    provider_id IN (
        SELECT mpp.id::text FROM medical_provider_profiles mpp
        JOIN users u ON mpp.user_id = u.id
        WHERE u.firebase_uid = auth.uid()::text
    )
    OR is_any_admin()
)
WITH CHECK (
    provider_id IN (
        SELECT mpp.id::text FROM medical_provider_profiles mpp
        JOIN users u ON mpp.user_id = u.id
        WHERE u.firebase_uid = auth.uid()::text
    )
    OR is_any_admin()
);

-- medical_provider_types - public read
ALTER TABLE IF EXISTS medical_provider_types ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "medical_provider_types_public_read" ON medical_provider_types;
CREATE POLICY "medical_provider_types_public_read"
ON medical_provider_types FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "medical_provider_types_admin_manage" ON medical_provider_types;
CREATE POLICY "medical_provider_types_admin_manage"
ON medical_provider_types FOR ALL TO authenticated
USING (is_system_admin())
WITH CHECK (is_system_admin());

-- provider_type_assignments
ALTER TABLE IF EXISTS provider_type_assignments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "provider_type_assignments_public_read" ON provider_type_assignments;
CREATE POLICY "provider_type_assignments_public_read"
ON provider_type_assignments FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "provider_type_assignments_admin_manage" ON provider_type_assignments;
CREATE POLICY "provider_type_assignments_admin_manage"
ON provider_type_assignments FOR ALL TO authenticated
USING (is_any_admin())
WITH CHECK (is_any_admin());

-- blood_types - public read
ALTER TABLE IF EXISTS blood_types ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "blood_types_public_read" ON blood_types;
CREATE POLICY "blood_types_public_read"
ON blood_types FOR SELECT TO authenticated
USING (true);

-- lab_test_categories - public read
ALTER TABLE IF EXISTS lab_test_categories ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "lab_test_categories_public_read" ON lab_test_categories;
CREATE POLICY "lab_test_categories_public_read"
ON lab_test_categories FOR SELECT TO authenticated
USING (true);

-- lab_test_types - public read
ALTER TABLE IF EXISTS lab_test_types ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "lab_test_types_public_read" ON lab_test_types;
CREATE POLICY "lab_test_types_public_read"
ON lab_test_types FOR SELECT TO authenticated
USING (true);

-- ============================================================================
-- SECTION 6: HEALTH DATA TABLES
-- ============================================================================

-- blood_donors - public read for directory
ALTER TABLE IF EXISTS blood_donors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "blood_donors_public_read" ON blood_donors;
CREATE POLICY "blood_donors_public_read"
ON blood_donors FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "blood_donors_own_manage" ON blood_donors;
CREATE POLICY "blood_donors_own_manage"
ON blood_donors FOR ALL TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
)
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- reminders - own access
ALTER TABLE IF EXISTS reminders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "reminders_own_access" ON reminders;
CREATE POLICY "reminders_own_access"
ON reminders FOR ALL TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
)
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- waitlist - own access + admin (uses patient_id -> patient_profiles.user_id -> users)
ALTER TABLE IF EXISTS waitlist ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "waitlist_own_access" ON waitlist;
CREATE POLICY "waitlist_own_access"
ON waitlist FOR SELECT TO authenticated
USING (
    patient_id IN (
        SELECT pp.id FROM patient_profiles pp
        JOIN users u ON pp.user_id = u.id
        WHERE u.firebase_uid = auth.uid()::text
    )
    OR provider_id IN (
        SELECT mpp.id FROM medical_provider_profiles mpp
        JOIN users u ON mpp.user_id = u.id
        WHERE u.firebase_uid = auth.uid()::text
    )
    OR is_any_admin()
);

DROP POLICY IF EXISTS "waitlist_insert" ON waitlist;
CREATE POLICY "waitlist_insert"
ON waitlist FOR INSERT TO authenticated
WITH CHECK (
    patient_id IN (
        SELECT pp.id FROM patient_profiles pp
        JOIN users u ON pp.user_id = u.id
        WHERE u.firebase_uid = auth.uid()::text
    )
);

DROP POLICY IF EXISTS "waitlist_admin_manage" ON waitlist;
CREATE POLICY "waitlist_admin_manage"
ON waitlist FOR ALL TO authenticated
USING (is_any_admin())
WITH CHECK (is_any_admin());

-- medical_record_conditions
ALTER TABLE IF EXISTS medical_record_conditions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "medical_record_conditions_own" ON medical_record_conditions;
CREATE POLICY "medical_record_conditions_own"
ON medical_record_conditions FOR SELECT TO authenticated
USING (
    medical_record_id IN (
        SELECT id FROM medical_records WHERE patient_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    )
    OR is_medical_provider()
    OR is_any_admin()
);

-- patient_medical_report_exports - own access
ALTER TABLE IF EXISTS patient_medical_report_exports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "patient_medical_report_exports_own" ON patient_medical_report_exports;
CREATE POLICY "patient_medical_report_exports_own"
ON patient_medical_report_exports FOR ALL TO authenticated
USING (
    patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
)
WITH CHECK (
    patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- ============================================================================
-- SECTION 7: BILLING & SUBSCRIPTION TABLES
-- ============================================================================

-- subscription_plans - public read
ALTER TABLE IF EXISTS subscription_plans ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "subscription_plans_public_read" ON subscription_plans;
CREATE POLICY "subscription_plans_public_read"
ON subscription_plans FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "subscription_plans_admin_manage" ON subscription_plans;
CREATE POLICY "subscription_plans_admin_manage"
ON subscription_plans FOR ALL TO authenticated
USING (is_system_admin())
WITH CHECK (is_system_admin());

-- user_subscriptions - own access
ALTER TABLE IF EXISTS user_subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_subscriptions_own" ON user_subscriptions;
CREATE POLICY "user_subscriptions_own"
ON user_subscriptions FOR SELECT TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
);

DROP POLICY IF EXISTS "user_subscriptions_insert" ON user_subscriptions;
CREATE POLICY "user_subscriptions_insert"
ON user_subscriptions FOR INSERT TO authenticated
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- payment_methods - own access
ALTER TABLE IF EXISTS payment_methods ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "payment_methods_own" ON payment_methods;
CREATE POLICY "payment_methods_own"
ON payment_methods FOR ALL TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
)
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- invoice_line_items - participant access (patient or provider via appointment)
ALTER TABLE IF EXISTS invoice_line_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "invoice_line_items_access" ON invoice_line_items;
CREATE POLICY "invoice_line_items_access"
ON invoice_line_items FOR SELECT TO authenticated
USING (
    invoice_id IN (
        SELECT i.id FROM invoices i WHERE
        i.patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
        OR i.appointment_id IN (
            SELECT a.id FROM appointments a WHERE a.provider_id IN (
                SELECT id FROM users WHERE firebase_uid = auth.uid()::text
            )
        )
    )
    OR is_any_admin()
);

-- payment_analytics - SKIPPED (is a VIEW, not a table - inherits RLS from underlying tables)
-- Views don't support RLS directly

-- ============================================================================
-- SECTION 8: USER SETTINGS & PREFERENCES
-- ============================================================================

-- notification_preferences - own access
ALTER TABLE IF EXISTS notification_preferences ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "notification_preferences_own" ON notification_preferences;
CREATE POLICY "notification_preferences_own"
ON notification_preferences FOR ALL TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
)
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- profile_pictures - own access
ALTER TABLE IF EXISTS profile_pictures ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "profile_pictures_own" ON profile_pictures;
CREATE POLICY "profile_pictures_own"
ON profile_pictures FOR ALL TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
)
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- storage_file_ownership - own access (uses owner_firebase_uid directly)
ALTER TABLE IF EXISTS storage_file_ownership ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "storage_file_ownership_own" ON storage_file_ownership;
CREATE POLICY "storage_file_ownership_own"
ON storage_file_ownership FOR ALL TO authenticated
USING (
    owner_firebase_uid = auth.uid()::text
    OR is_any_admin()
)
WITH CHECK (
    owner_firebase_uid = auth.uid()::text
);

-- user_profiles (if separate from users) - own access
ALTER TABLE IF EXISTS user_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "user_profiles_own" ON user_profiles;
CREATE POLICY "user_profiles_own"
ON user_profiles FOR ALL TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
)
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- ============================================================================
-- SECTION 9: PATIENT CARE TABLES
-- ============================================================================

-- clinical_consultations - participant access
ALTER TABLE IF EXISTS clinical_consultations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "clinical_consultations_participant" ON clinical_consultations;
CREATE POLICY "clinical_consultations_participant"
ON clinical_consultations FOR SELECT TO authenticated
USING (
    patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
);

DROP POLICY IF EXISTS "clinical_consultations_provider_manage" ON clinical_consultations;
CREATE POLICY "clinical_consultations_provider_manage"
ON clinical_consultations FOR ALL TO authenticated
USING (
    provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
)
WITH CHECK (
    provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
);

-- admission_discharges - participant access
ALTER TABLE IF EXISTS admission_discharges ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "admission_discharges_participant" ON admission_discharges;
CREATE POLICY "admission_discharges_participant"
ON admission_discharges FOR SELECT TO authenticated
USING (
    patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "admission_discharges_provider_manage" ON admission_discharges;
CREATE POLICY "admission_discharges_provider_manage"
ON admission_discharges FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- review_responses - public read, provider manage
ALTER TABLE IF EXISTS review_responses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "review_responses_public_read" ON review_responses;
CREATE POLICY "review_responses_public_read"
ON review_responses FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "review_responses_responder_manage" ON review_responses;
CREATE POLICY "review_responses_responder_manage"
ON review_responses FOR ALL TO authenticated
USING (
    responder_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
)
WITH CHECK (
    responder_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
);

-- ============================================================================
-- SECTION 10: SECURITY & SYSTEM TABLES
-- ============================================================================

-- password_reset_tokens - service only
ALTER TABLE IF EXISTS password_reset_tokens ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "password_reset_tokens_service" ON password_reset_tokens;
CREATE POLICY "password_reset_tokens_service"
ON password_reset_tokens FOR ALL TO service_role
USING (true);

-- search_indexes - service only for writes
ALTER TABLE IF EXISTS search_indexes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "search_indexes_public_read" ON search_indexes;
CREATE POLICY "search_indexes_public_read"
ON search_indexes FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "search_indexes_service_write" ON search_indexes;
CREATE POLICY "search_indexes_service_write"
ON search_indexes FOR ALL TO service_role
USING (true);

-- search_analytics - admin only
ALTER TABLE IF EXISTS search_analytics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "search_analytics_admin" ON search_analytics;
CREATE POLICY "search_analytics_admin"
ON search_analytics FOR SELECT TO authenticated
USING (is_system_admin());

DROP POLICY IF EXISTS "search_analytics_insert" ON search_analytics;
CREATE POLICY "search_analytics_insert"
ON search_analytics FOR INSERT TO authenticated
WITH CHECK (true);

-- media_library - own access (uses uploaded_by_id column - UUID type)
ALTER TABLE IF EXISTS media_library ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "media_library_access" ON media_library;
CREATE POLICY "media_library_access"
ON media_library FOR SELECT TO authenticated
USING (
    uploaded_by_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
);

DROP POLICY IF EXISTS "media_library_own_manage" ON media_library;
CREATE POLICY "media_library_own_manage"
ON media_library FOR ALL TO authenticated
USING (
    uploaded_by_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
)
WITH CHECK (
    uploaded_by_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- ============================================================================
-- SECTION 11: EHR & INTEGRATION TABLES
-- ============================================================================

-- ehrbase_sync_queue - service only + admin read
ALTER TABLE IF EXISTS ehrbase_sync_queue ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ehrbase_sync_queue_service" ON ehrbase_sync_queue;
CREATE POLICY "ehrbase_sync_queue_service"
ON ehrbase_sync_queue FOR ALL TO service_role
USING (true);

DROP POLICY IF EXISTS "ehrbase_sync_queue_admin_read" ON ehrbase_sync_queue;
CREATE POLICY "ehrbase_sync_queue_admin_read"
ON ehrbase_sync_queue FOR SELECT TO authenticated
USING (is_system_admin());

-- ehr_compositions - participant access
ALTER TABLE IF EXISTS ehr_compositions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ehr_compositions_participant" ON ehr_compositions;
CREATE POLICY "ehr_compositions_participant"
ON ehr_compositions FOR SELECT TO authenticated
USING (
    ehr_id::text IN (
        SELECT ehr_id::text FROM electronic_health_records WHERE patient_id::text IN (
            SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text
        )
    )
    OR is_medical_provider()
    OR is_any_admin()
);

-- archetypes - public read
ALTER TABLE IF EXISTS archetypes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "archetypes_public_read" ON archetypes;
CREATE POLICY "archetypes_public_read"
ON archetypes FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "archetypes_admin_manage" ON archetypes;
CREATE POLICY "archetypes_admin_manage"
ON archetypes FOR ALL TO authenticated
USING (is_system_admin())
WITH CHECK (is_system_admin());

-- archetype_form_fields - public read
ALTER TABLE IF EXISTS archetype_form_fields ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "archetype_form_fields_public_read" ON archetype_form_fields;
CREATE POLICY "archetype_form_fields_public_read"
ON archetype_form_fields FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "archetype_form_fields_admin_manage" ON archetype_form_fields;
CREATE POLICY "archetype_form_fields_admin_manage"
ON archetype_form_fields FOR ALL TO authenticated
USING (is_system_admin())
WITH CHECK (is_system_admin());

-- templates - public read
ALTER TABLE IF EXISTS templates ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "templates_public_read" ON templates;
CREATE POLICY "templates_public_read"
ON templates FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "templates_admin_manage" ON templates;
CREATE POLICY "templates_admin_manage"
ON templates FOR ALL TO authenticated
USING (is_system_admin())
WITH CHECK (is_system_admin());

-- openehr_integration_health is a VIEW - views inherit security from underlying tables
-- No RLS needed for views

-- ============================================================================
-- SECTION 12: AI & EMBEDDING TABLES
-- ============================================================================

-- document_embeddings - service only
ALTER TABLE IF EXISTS document_embeddings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "document_embeddings_service" ON document_embeddings;
CREATE POLICY "document_embeddings_service"
ON document_embeddings FOR ALL TO service_role
USING (true);

-- medical_record_embeddings - service only
ALTER TABLE IF EXISTS medical_record_embeddings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "medical_record_embeddings_service" ON medical_record_embeddings;
CREATE POLICY "medical_record_embeddings_service"
ON medical_record_embeddings FOR ALL TO service_role
USING (true);

-- consultation_medical_entities - participant access
ALTER TABLE IF EXISTS consultation_medical_entities ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "consultation_medical_entities_access" ON consultation_medical_entities;
CREATE POLICY "consultation_medical_entities_access"
ON consultation_medical_entities FOR SELECT TO authenticated
USING (
    patient_id::text IN (SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text)
    OR provider_id::text IN (SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
);

-- custom_vocabulary_analytics is a MATERIALIZED VIEW - cannot have RLS
-- Materialized views inherit security from underlying tables when refreshed
-- No RLS needed for materialized views

-- ============================================================================
-- SECTION 13: USSD TABLES (Mobile Access)
-- ============================================================================

-- ussd_menus - public read
ALTER TABLE IF EXISTS ussd_menus ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ussd_menus_public_read" ON ussd_menus;
CREATE POLICY "ussd_menus_public_read"
ON ussd_menus FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "ussd_menus_admin_manage" ON ussd_menus;
CREATE POLICY "ussd_menus_admin_manage"
ON ussd_menus FOR ALL TO authenticated
USING (is_system_admin())
WITH CHECK (is_system_admin());

-- ussd_actions - service only
ALTER TABLE IF EXISTS ussd_actions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ussd_actions_service" ON ussd_actions;
CREATE POLICY "ussd_actions_service"
ON ussd_actions FOR ALL TO service_role
USING (true);

-- ussd_sessions - service only + own read
ALTER TABLE IF EXISTS ussd_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "ussd_sessions_service" ON ussd_sessions;
CREATE POLICY "ussd_sessions_service"
ON ussd_sessions FOR ALL TO service_role
USING (true);

DROP POLICY IF EXISTS "ussd_sessions_own_read" ON ussd_sessions;
CREATE POLICY "ussd_sessions_own_read"
ON ussd_sessions FOR SELECT TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- ============================================================================
-- SECTION 14: SPECIALTY VISIT TABLES (Clinical Data)
-- ============================================================================

-- All specialty visit tables follow same pattern:
-- - Patient access via patient_id
-- - Provider access via is_medical_provider() function (since provider column names vary per table)
-- - Admin access via is_any_admin()

-- nephrology_visits
ALTER TABLE IF EXISTS nephrology_visits ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "nephrology_visits_access" ON nephrology_visits;
CREATE POLICY "nephrology_visits_access"
ON nephrology_visits FOR SELECT TO authenticated
USING (
    patient_id::text IN (SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "nephrology_visits_provider_manage" ON nephrology_visits;
CREATE POLICY "nephrology_visits_provider_manage"
ON nephrology_visits FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- cardiology_visits
ALTER TABLE IF EXISTS cardiology_visits ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "cardiology_visits_access" ON cardiology_visits;
CREATE POLICY "cardiology_visits_access"
ON cardiology_visits FOR SELECT TO authenticated
USING (
    patient_id::text IN (SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "cardiology_visits_provider_manage" ON cardiology_visits;
CREATE POLICY "cardiology_visits_provider_manage"
ON cardiology_visits FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- neurology_exams
ALTER TABLE IF EXISTS neurology_exams ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "neurology_exams_access" ON neurology_exams;
CREATE POLICY "neurology_exams_access"
ON neurology_exams FOR SELECT TO authenticated
USING (
    patient_id::text IN (SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "neurology_exams_provider_manage" ON neurology_exams;
CREATE POLICY "neurology_exams_provider_manage"
ON neurology_exams FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- psychiatric_assessments
ALTER TABLE IF EXISTS psychiatric_assessments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "psychiatric_assessments_access" ON psychiatric_assessments;
CREATE POLICY "psychiatric_assessments_access"
ON psychiatric_assessments FOR SELECT TO authenticated
USING (
    patient_id::text IN (SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "psychiatric_assessments_provider_manage" ON psychiatric_assessments;
CREATE POLICY "psychiatric_assessments_provider_manage"
ON psychiatric_assessments FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- pulmonology_visits
ALTER TABLE IF EXISTS pulmonology_visits ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pulmonology_visits_access" ON pulmonology_visits;
CREATE POLICY "pulmonology_visits_access"
ON pulmonology_visits FOR SELECT TO authenticated
USING (
    patient_id::text IN (SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "pulmonology_visits_provider_manage" ON pulmonology_visits;
CREATE POLICY "pulmonology_visits_provider_manage"
ON pulmonology_visits FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- endocrinology_visits
ALTER TABLE IF EXISTS endocrinology_visits ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "endocrinology_visits_access" ON endocrinology_visits;
CREATE POLICY "endocrinology_visits_access"
ON endocrinology_visits FOR SELECT TO authenticated
USING (
    patient_id::text IN (SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "endocrinology_visits_provider_manage" ON endocrinology_visits;
CREATE POLICY "endocrinology_visits_provider_manage"
ON endocrinology_visits FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- gastroenterology_procedures
ALTER TABLE IF EXISTS gastroenterology_procedures ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "gastroenterology_procedures_access" ON gastroenterology_procedures;
CREATE POLICY "gastroenterology_procedures_access"
ON gastroenterology_procedures FOR SELECT TO authenticated
USING (
    patient_id::text IN (SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "gastroenterology_procedures_provider_manage" ON gastroenterology_procedures;
CREATE POLICY "gastroenterology_procedures_provider_manage"
ON gastroenterology_procedures FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- infectious_disease_visits
ALTER TABLE IF EXISTS infectious_disease_visits ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "infectious_disease_visits_access" ON infectious_disease_visits;
CREATE POLICY "infectious_disease_visits_access"
ON infectious_disease_visits FOR SELECT TO authenticated
USING (
    patient_id::text IN (SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "infectious_disease_visits_provider_manage" ON infectious_disease_visits;
CREATE POLICY "infectious_disease_visits_provider_manage"
ON infectious_disease_visits FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- oncology_treatments
ALTER TABLE IF EXISTS oncology_treatments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "oncology_treatments_access" ON oncology_treatments;
CREATE POLICY "oncology_treatments_access"
ON oncology_treatments FOR SELECT TO authenticated
USING (
    patient_id::text IN (SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "oncology_treatments_provider_manage" ON oncology_treatments;
CREATE POLICY "oncology_treatments_provider_manage"
ON oncology_treatments FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- surgical_procedures
ALTER TABLE IF EXISTS surgical_procedures ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "surgical_procedures_access" ON surgical_procedures;
CREATE POLICY "surgical_procedures_access"
ON surgical_procedures FOR SELECT TO authenticated
USING (
    patient_id::text IN (SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "surgical_procedures_provider_manage" ON surgical_procedures;
CREATE POLICY "surgical_procedures_provider_manage"
ON surgical_procedures FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- emergency_visits
ALTER TABLE IF EXISTS emergency_visits ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "emergency_visits_access" ON emergency_visits;
CREATE POLICY "emergency_visits_access"
ON emergency_visits FOR SELECT TO authenticated
USING (
    patient_id::text IN (SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "emergency_visits_provider_manage" ON emergency_visits;
CREATE POLICY "emergency_visits_provider_manage"
ON emergency_visits FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- antenatal_visits
ALTER TABLE IF EXISTS antenatal_visits ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "antenatal_visits_access" ON antenatal_visits;
CREATE POLICY "antenatal_visits_access"
ON antenatal_visits FOR SELECT TO authenticated
USING (
    patient_id::text IN (SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "antenatal_visits_provider_manage" ON antenatal_visits;
CREATE POLICY "antenatal_visits_provider_manage"
ON antenatal_visits FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- physiotherapy_sessions
ALTER TABLE IF EXISTS physiotherapy_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "physiotherapy_sessions_access" ON physiotherapy_sessions;
CREATE POLICY "physiotherapy_sessions_access"
ON physiotherapy_sessions FOR SELECT TO authenticated
USING (
    patient_id::text IN (SELECT id::text FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "physiotherapy_sessions_provider_manage" ON physiotherapy_sessions;
CREATE POLICY "physiotherapy_sessions_provider_manage"
ON physiotherapy_sessions FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- radiology_reports (uses radiologist_id and ordering_provider_id, NOT provider_id)
ALTER TABLE IF EXISTS radiology_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "radiology_reports_access" ON radiology_reports;
CREATE POLICY "radiology_reports_access"
ON radiology_reports FOR SELECT TO authenticated
USING (
    patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "radiology_reports_provider_manage" ON radiology_reports;
CREATE POLICY "radiology_reports_provider_manage"
ON radiology_reports FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- pathology_reports (uses pathologist_id and ordering_provider_id, NOT provider_id)
ALTER TABLE IF EXISTS pathology_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pathology_reports_access" ON pathology_reports;
CREATE POLICY "pathology_reports_access"
ON pathology_reports FOR SELECT TO authenticated
USING (
    patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "pathology_reports_provider_manage" ON pathology_reports;
CREATE POLICY "pathology_reports_provider_manage"
ON pathology_reports FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- ============================================================================
-- SECTION 15: PHARMACY & DISPENSING
-- ============================================================================

-- pharmacy_stock - facility access
ALTER TABLE IF EXISTS pharmacy_stock ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pharmacy_stock_read" ON pharmacy_stock;
CREATE POLICY "pharmacy_stock_read"
ON pharmacy_stock FOR SELECT TO authenticated
USING (is_medical_provider() OR is_any_admin());

DROP POLICY IF EXISTS "pharmacy_stock_manage" ON pharmacy_stock;
CREATE POLICY "pharmacy_stock_manage"
ON pharmacy_stock FOR ALL TO authenticated
USING (is_any_admin())
WITH CHECK (is_any_admin());

-- medication_dispensing - participant access
ALTER TABLE IF EXISTS medication_dispensing ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "medication_dispensing_access" ON medication_dispensing;
CREATE POLICY "medication_dispensing_access"
ON medication_dispensing FOR SELECT TO authenticated
USING (
    patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_medical_provider()
    OR is_any_admin()
);

DROP POLICY IF EXISTS "medication_dispensing_provider_manage" ON medication_dispensing;
CREATE POLICY "medication_dispensing_provider_manage"
ON medication_dispensing FOR ALL TO authenticated
USING (is_medical_provider() OR is_any_admin())
WITH CHECK (is_medical_provider() OR is_any_admin());

-- ============================================================================
-- SECTION 16: STAFF PROFILES (Healthcare Staff Types)
-- ============================================================================

-- doctor_profiles - public read for directory
ALTER TABLE IF EXISTS doctor_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "doctor_profiles_public_read" ON doctor_profiles;
CREATE POLICY "doctor_profiles_public_read"
ON doctor_profiles FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "doctor_profiles_own_manage" ON doctor_profiles;
CREATE POLICY "doctor_profiles_own_manage"
ON doctor_profiles FOR ALL TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
)
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
);

-- nurse_profiles
ALTER TABLE IF EXISTS nurse_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "nurse_profiles_public_read" ON nurse_profiles;
CREATE POLICY "nurse_profiles_public_read"
ON nurse_profiles FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "nurse_profiles_own_manage" ON nurse_profiles;
CREATE POLICY "nurse_profiles_own_manage"
ON nurse_profiles FOR ALL TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
)
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
);

-- pharmacist_profiles
ALTER TABLE IF EXISTS pharmacist_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "pharmacist_profiles_public_read" ON pharmacist_profiles;
CREATE POLICY "pharmacist_profiles_public_read"
ON pharmacist_profiles FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "pharmacist_profiles_own_manage" ON pharmacist_profiles;
CREATE POLICY "pharmacist_profiles_own_manage"
ON pharmacist_profiles FOR ALL TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
)
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
);

-- lab_technician_profiles
ALTER TABLE IF EXISTS lab_technician_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "lab_technician_profiles_public_read" ON lab_technician_profiles;
CREATE POLICY "lab_technician_profiles_public_read"
ON lab_technician_profiles FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "lab_technician_profiles_own_manage" ON lab_technician_profiles;
CREATE POLICY "lab_technician_profiles_own_manage"
ON lab_technician_profiles FOR ALL TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
)
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    OR is_any_admin()
);

-- doctor_performance_reports - admin only
ALTER TABLE IF EXISTS doctor_performance_reports ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "doctor_performance_reports_admin" ON doctor_performance_reports;
CREATE POLICY "doctor_performance_reports_admin"
ON doctor_performance_reports FOR SELECT TO authenticated
USING (is_any_admin());

-- ============================================================================
-- SECTION 17: MESSAGE REACTIONS (Chat Enhancement)
-- ============================================================================

-- message_reactions - conversation participant access
-- Note: conversations table uses participant_ids (array) and created_by_id, NOT patient_id/provider_id
ALTER TABLE IF EXISTS message_reactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "message_reactions_access" ON message_reactions;
CREATE POLICY "message_reactions_access"
ON message_reactions FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM messages m
        JOIN conversations c ON m.conversation_id = c.id
        WHERE m.id = message_reactions.message_id
        AND (
            c.created_by_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
            OR (SELECT id FROM users WHERE firebase_uid = auth.uid()::text) = ANY(c.participant_ids)
        )
    )
    OR is_any_admin()
);

DROP POLICY IF EXISTS "message_reactions_own_manage" ON message_reactions;
CREATE POLICY "message_reactions_own_manage"
ON message_reactions FOR ALL TO authenticated
USING (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
)
WITH CHECK (
    user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
);

-- ============================================================================
-- VERIFICATION QUERIES (Run after migration)
-- ============================================================================

-- Uncomment to verify RLS is enabled on all tables:
-- SELECT tablename, rowsecurity
-- FROM pg_tables
-- WHERE schemaname = 'public'
-- AND rowsecurity = true
-- ORDER BY tablename;

-- Uncomment to count policies:
-- SELECT COUNT(*) as total_policies FROM pg_policies WHERE schemaname = 'public';

-- Uncomment to list tables still missing RLS:
-- SELECT tablename
-- FROM pg_tables
-- WHERE schemaname = 'public'
-- AND rowsecurity = false
-- AND tablename NOT LIKE '%_view'
-- AND tablename NOT IN ('spatial_ref_sys', 'geometry_columns', 'geography_columns');

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
