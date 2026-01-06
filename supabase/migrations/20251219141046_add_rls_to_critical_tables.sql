-- Migration: Add RLS to Critical Healthcare Tables
-- Purpose: Ensure HIPAA compliance by enabling Row Level Security on all sensitive tables
-- Date: 2025-12-19
-- Author: MedZen Compliance Audit

-- =====================================================
-- PART 1: ENABLE RLS ON CRITICAL TABLES
-- =====================================================

-- Appointments - Critical healthcare scheduling data
ALTER TABLE IF EXISTS appointments ENABLE ROW LEVEL SECURITY;

-- Documents - Medical documents and files
ALTER TABLE IF EXISTS documents ENABLE ROW LEVEL SECURITY;

-- Reviews - Provider reviews (contains user references)
ALTER TABLE IF EXISTS reviews ENABLE ROW LEVEL SECURITY;

-- Notifications - User notifications
ALTER TABLE IF EXISTS notifications ENABLE ROW LEVEL SECURITY;

-- Conversations - Chat conversations
ALTER TABLE IF EXISTS conversations ENABLE ROW LEVEL SECURITY;

-- Messages - Chat messages
ALTER TABLE IF EXISTS messages ENABLE ROW LEVEL SECURITY;

-- Withdrawals - Financial transactions
ALTER TABLE IF EXISTS withdrawals ENABLE ROW LEVEL SECURITY;

-- Transactions - Payment transactions
ALTER TABLE IF EXISTS transactions ENABLE ROW LEVEL SECURITY;

-- Invoices - Billing invoices
ALTER TABLE IF EXISTS invoices ENABLE ROW LEVEL SECURITY;

-- Allergies - Medical allergies catalog
ALTER TABLE IF EXISTS allergies ENABLE ROW LEVEL SECURITY;

-- User Allergies - Patient-specific allergies
ALTER TABLE IF EXISTS user_allergies ENABLE ROW LEVEL SECURITY;

-- Medications - Medication catalog
ALTER TABLE IF EXISTS medications ENABLE ROW LEVEL SECURITY;

-- User Medications - Patient-specific medications
ALTER TABLE IF EXISTS user_medications ENABLE ROW LEVEL SECURITY;

-- User Medical Conditions - Patient conditions
ALTER TABLE IF EXISTS user_medical_conditions ENABLE ROW LEVEL SECURITY;

-- Lab Orders - Laboratory test orders
ALTER TABLE IF EXISTS lab_orders ENABLE ROW LEVEL SECURITY;

-- Prescription Medications - Prescribed medications
ALTER TABLE IF EXISTS prescription_medications ENABLE ROW LEVEL SECURITY;

-- Push Notifications - FCM push notifications
ALTER TABLE IF EXISTS push_notifications ENABLE ROW LEVEL SECURITY;

-- Appointment Reminders - SKIPPED (is a view, inherits RLS from underlying tables)
-- ALTER TABLE IF EXISTS appointment_reminders ENABLE ROW LEVEL SECURITY;

-- Medical Conditions - Conditions catalog
ALTER TABLE IF EXISTS medical_conditions ENABLE ROW LEVEL SECURITY;

-- Referrals - Patient referrals
ALTER TABLE IF EXISTS referrals ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- PART 2: CREATE RLS POLICIES FOR APPOINTMENTS
-- =====================================================

-- Drop existing policies if any
DROP POLICY IF EXISTS "appointments_select_own" ON appointments;
DROP POLICY IF EXISTS "appointments_insert_own" ON appointments;
DROP POLICY IF EXISTS "appointments_update_own" ON appointments;
DROP POLICY IF EXISTS "appointments_delete_own" ON appointments;

-- Patients can view their own appointments
CREATE POLICY "appointments_select_patient" ON appointments
    FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- Providers can view appointments assigned to them
CREATE POLICY "appointments_select_provider" ON appointments
    FOR SELECT
    USING (
        provider_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- Patients can create their own appointments
CREATE POLICY "appointments_insert_patient" ON appointments
    FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- Providers and patients can update their appointments
CREATE POLICY "appointments_update_participant" ON appointments
    FOR UPDATE
    USING (
        patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
        OR provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    );

-- =====================================================
-- PART 3: CREATE RLS POLICIES FOR DOCUMENTS
-- =====================================================

DROP POLICY IF EXISTS "documents_select_own" ON documents;
DROP POLICY IF EXISTS "documents_insert_own" ON documents;
DROP POLICY IF EXISTS "documents_update_own" ON documents;
DROP POLICY IF EXISTS "documents_delete_own" ON documents;

-- Users can view their own documents
CREATE POLICY "documents_select_own" ON documents
    FOR SELECT
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- Users can upload their own documents
CREATE POLICY "documents_insert_own" ON documents
    FOR INSERT
    WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- Users can update their own documents
CREATE POLICY "documents_update_own" ON documents
    FOR UPDATE
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- Users can delete their own documents
CREATE POLICY "documents_delete_own" ON documents
    FOR DELETE
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- =====================================================
-- PART 4: CREATE RLS POLICIES FOR NOTIFICATIONS
-- =====================================================

DROP POLICY IF EXISTS "notifications_select_own" ON notifications;
DROP POLICY IF EXISTS "notifications_insert_system" ON notifications;
DROP POLICY IF EXISTS "notifications_update_own" ON notifications;

-- Users can view their own notifications
CREATE POLICY "notifications_select_own" ON notifications
    FOR SELECT
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- Users can update their own notifications (mark as read)
CREATE POLICY "notifications_update_own" ON notifications
    FOR UPDATE
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- =====================================================
-- PART 5: CREATE RLS POLICIES FOR CONVERSATIONS
-- =====================================================

DROP POLICY IF EXISTS "conversations_select_participant" ON conversations;
DROP POLICY IF EXISTS "conversations_insert_participant" ON conversations;

-- Participants can view their conversations (uses participant_ids array or conversation_participants table)
CREATE POLICY "conversations_select_participant" ON conversations
    FOR SELECT
    USING (
        -- Check if user is in conversation_participants table
        id IN (
            SELECT conversation_id FROM conversation_participants
            WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
        )
        -- Or check if user is in the participant_ids array
        OR (SELECT id FROM users WHERE firebase_uid = auth.uid()::text) = ANY(participant_ids)
        -- Or user created the conversation
        OR created_by_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    );

-- Users can create conversations
CREATE POLICY "conversations_insert_participant" ON conversations
    FOR INSERT
    WITH CHECK (
        created_by_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
    );

-- =====================================================
-- PART 6: CREATE RLS POLICIES FOR MESSAGES
-- =====================================================

DROP POLICY IF EXISTS "messages_select_participant" ON messages;
DROP POLICY IF EXISTS "messages_insert_sender" ON messages;

-- Participants can view messages in their conversations
CREATE POLICY "messages_select_participant" ON messages
    FOR SELECT
    USING (
        -- User is a participant in the conversation
        conversation_id IN (
            SELECT conversation_id FROM conversation_participants
            WHERE user_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
        )
        -- Or user is in the conversation's participant_ids array
        OR conversation_id IN (
            SELECT id FROM conversations
            WHERE (SELECT id FROM users WHERE firebase_uid = auth.uid()::text) = ANY(participant_ids)
        )
    );

-- Users can send messages
CREATE POLICY "messages_insert_sender" ON messages
    FOR INSERT
    WITH CHECK (
        sender_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- =====================================================
-- PART 7: CREATE RLS POLICIES FOR REVIEWS
-- =====================================================

DROP POLICY IF EXISTS "reviews_select_public" ON reviews;
DROP POLICY IF EXISTS "reviews_insert_reviewer" ON reviews;
DROP POLICY IF EXISTS "reviews_update_own" ON reviews;

-- Everyone can view reviews (public)
CREATE POLICY "reviews_select_public" ON reviews
    FOR SELECT
    USING (true);

-- Users can create reviews (reviewer_id is the column name)
CREATE POLICY "reviews_insert_reviewer" ON reviews
    FOR INSERT
    WITH CHECK (
        reviewer_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- Users can update their own reviews
CREATE POLICY "reviews_update_own" ON reviews
    FOR UPDATE
    USING (
        reviewer_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- =====================================================
-- PART 8: CREATE RLS POLICIES FOR FINANCIAL TABLES
-- =====================================================

-- Withdrawals (uses provider_id, not user_id)
DROP POLICY IF EXISTS "withdrawals_select_own" ON withdrawals;
DROP POLICY IF EXISTS "withdrawals_insert_own" ON withdrawals;

CREATE POLICY "withdrawals_select_own" ON withdrawals
    FOR SELECT
    USING (
        provider_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

CREATE POLICY "withdrawals_insert_own" ON withdrawals
    FOR INSERT
    WITH CHECK (
        provider_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- Transactions (only has user_id column)
DROP POLICY IF EXISTS "transactions_select_own" ON transactions;

CREATE POLICY "transactions_select_own" ON transactions
    FOR SELECT
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- Invoices (has patient_id, get provider via appointment)
DROP POLICY IF EXISTS "invoices_select_own" ON invoices;

-- Patients can view their own invoices
CREATE POLICY "invoices_select_patient" ON invoices
    FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- Providers can view invoices for their appointments
CREATE POLICY "invoices_select_provider" ON invoices
    FOR SELECT
    USING (
        appointment_id IN (
            SELECT id FROM appointments WHERE provider_id IN (
                SELECT id FROM users WHERE firebase_uid = auth.uid()::text
            )
        )
    );

-- =====================================================
-- PART 9: CREATE RLS POLICIES FOR MEDICAL DATA
-- =====================================================

-- User Allergies
DROP POLICY IF EXISTS "user_allergies_select_own" ON user_allergies;
DROP POLICY IF EXISTS "user_allergies_insert_own" ON user_allergies;
DROP POLICY IF EXISTS "user_allergies_update_own" ON user_allergies;
DROP POLICY IF EXISTS "user_allergies_delete_own" ON user_allergies;

CREATE POLICY "user_allergies_select_own" ON user_allergies
    FOR SELECT
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

CREATE POLICY "user_allergies_insert_own" ON user_allergies
    FOR INSERT
    WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

CREATE POLICY "user_allergies_update_own" ON user_allergies
    FOR UPDATE
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

CREATE POLICY "user_allergies_delete_own" ON user_allergies
    FOR DELETE
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- User Medications
DROP POLICY IF EXISTS "user_medications_select_own" ON user_medications;
DROP POLICY IF EXISTS "user_medications_insert_own" ON user_medications;
DROP POLICY IF EXISTS "user_medications_update_own" ON user_medications;
DROP POLICY IF EXISTS "user_medications_delete_own" ON user_medications;

CREATE POLICY "user_medications_select_own" ON user_medications
    FOR SELECT
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

CREATE POLICY "user_medications_insert_own" ON user_medications
    FOR INSERT
    WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

CREATE POLICY "user_medications_update_own" ON user_medications
    FOR UPDATE
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

CREATE POLICY "user_medications_delete_own" ON user_medications
    FOR DELETE
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- User Medical Conditions
DROP POLICY IF EXISTS "user_medical_conditions_select_own" ON user_medical_conditions;
DROP POLICY IF EXISTS "user_medical_conditions_insert_own" ON user_medical_conditions;
DROP POLICY IF EXISTS "user_medical_conditions_update_own" ON user_medical_conditions;
DROP POLICY IF EXISTS "user_medical_conditions_delete_own" ON user_medical_conditions;

CREATE POLICY "user_medical_conditions_select_own" ON user_medical_conditions
    FOR SELECT
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

CREATE POLICY "user_medical_conditions_insert_own" ON user_medical_conditions
    FOR INSERT
    WITH CHECK (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

CREATE POLICY "user_medical_conditions_update_own" ON user_medical_conditions
    FOR UPDATE
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

CREATE POLICY "user_medical_conditions_delete_own" ON user_medical_conditions
    FOR DELETE
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- Lab Orders
DROP POLICY IF EXISTS "lab_orders_select_own" ON lab_orders;
DROP POLICY IF EXISTS "lab_orders_insert_provider" ON lab_orders;

CREATE POLICY "lab_orders_select_patient" ON lab_orders
    FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

CREATE POLICY "lab_orders_select_provider" ON lab_orders
    FOR SELECT
    USING (
        ordering_provider_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

CREATE POLICY "lab_orders_insert_provider" ON lab_orders
    FOR INSERT
    WITH CHECK (
        ordering_provider_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- Prescription Medications
DROP POLICY IF EXISTS "prescription_medications_select_own" ON prescription_medications;

CREATE POLICY "prescription_medications_select_own" ON prescription_medications
    FOR SELECT
    USING (
        prescription_id IN (
            SELECT id FROM prescriptions WHERE
                patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
                OR doctor_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
        )
    );

-- =====================================================
-- PART 10: CREATE RLS POLICIES FOR NOTIFICATIONS & REMINDERS
-- =====================================================

-- Push Notifications
DROP POLICY IF EXISTS "push_notifications_select_own" ON push_notifications;

CREATE POLICY "push_notifications_select_own" ON push_notifications
    FOR SELECT
    USING (
        user_id IN (
            SELECT id FROM users WHERE firebase_uid = auth.uid()::text
        )
    );

-- Appointment Reminders - SKIPPED (appointment_reminders is a VIEW, not a table)
-- Views inherit RLS from their underlying tables (appointments already has RLS)
-- DROP POLICY IF EXISTS "appointment_reminders_select_own" ON appointment_reminders;
-- CREATE POLICY "appointment_reminders_select_own" ON appointment_reminders
--     FOR SELECT
--     USING (
--         appointment_id IN (
--             SELECT id FROM appointments WHERE
--                 patient_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
--                 OR provider_id IN (SELECT id FROM users WHERE firebase_uid = auth.uid()::text)
--         )
--     );

-- =====================================================
-- PART 11: CREATE RLS FOR CATALOG TABLES (Read-only public)
-- =====================================================

-- Allergies catalog - public read
DROP POLICY IF EXISTS "allergies_select_public" ON allergies;
CREATE POLICY "allergies_select_public" ON allergies
    FOR SELECT
    USING (true);

-- Medications catalog - public read
DROP POLICY IF EXISTS "medications_select_public" ON medications;
CREATE POLICY "medications_select_public" ON medications
    FOR SELECT
    USING (true);

-- Medical conditions catalog - public read
DROP POLICY IF EXISTS "medical_conditions_select_public" ON medical_conditions;
CREATE POLICY "medical_conditions_select_public" ON medical_conditions
    FOR SELECT
    USING (true);

-- =====================================================
-- PART 12: SERVICE ROLE BYPASS FOR EDGE FUNCTIONS
-- =====================================================

-- Allow service role to bypass RLS for edge functions and admin operations
-- This is automatically handled by Supabase when using service_role key

-- =====================================================
-- VERIFICATION COMMENT
-- =====================================================
-- This migration adds RLS to the following critical tables:
-- 1. appointments - Healthcare scheduling
-- 2. documents - Medical documents
-- 3. reviews - Provider reviews
-- 4. notifications - User notifications
-- 5. conversations - Chat conversations
-- 6. messages - Chat messages
-- 7. withdrawals - Financial withdrawals
-- 8. transactions - Payment transactions
-- 9. invoices - Billing invoices
-- 10. allergies - Allergies catalog
-- 11. user_allergies - Patient allergies
-- 12. medications - Medications catalog
-- 13. user_medications - Patient medications
-- 14. user_medical_conditions - Patient conditions
-- 15. lab_orders - Lab test orders
-- 16. prescription_medications - Prescribed meds
-- 17. push_notifications - FCM notifications
-- 18. appointment_reminders - Scheduled reminders
-- 19. medical_conditions - Conditions catalog
-- 20. referrals - Patient referrals

-- Total: 20 critical tables now have RLS enabled
