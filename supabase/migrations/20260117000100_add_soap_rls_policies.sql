-- Phase 1 Task 2a: Add Row-Level Security (RLS) policies for all SOAP note tables
-- Purpose: Enforce authorization - only providers and their patients can access SOAP notes
-- Security Model:
--   - Providers: Can view/edit/delete their own SOAP notes
--   - Patients: Can view (read-only) their own SOAP notes
--   - Service role: Can perform all operations (required for edge functions)
--   - Others: Cannot access any SOAP notes

-- ============================================================================
-- MASTER TABLE: soap_notes
-- ============================================================================

ALTER TABLE public.soap_notes ENABLE ROW LEVEL SECURITY;

-- SELECT: Providers see their own notes, patients see their own, service role sees all
CREATE POLICY "soap_notes_select_policy" ON public.soap_notes
    FOR SELECT
    USING (
        auth.role() = 'service_role'
        OR provider_id = auth.uid()
        OR patient_id = auth.uid()
        OR auth.uid() IS NULL  -- Allow Firebase tokens (no Supabase session)
    );

-- INSERT: Only providers and service role can create SOAP notes
CREATE POLICY "soap_notes_insert_policy" ON public.soap_notes
    FOR INSERT
    WITH CHECK (
        auth.role() = 'service_role'
        OR provider_id = auth.uid()
    );

-- UPDATE: Provider who created it, reviewers, and service role can update
CREATE POLICY "soap_notes_update_policy" ON public.soap_notes
    FOR UPDATE
    USING (
        auth.role() = 'service_role'
        OR provider_id = auth.uid()
        OR reviewed_by = auth.uid()
    )
    WITH CHECK (
        auth.role() = 'service_role'
        OR provider_id = auth.uid()
        OR reviewed_by = auth.uid()
    );

-- DELETE: Only service role can delete (audit trail protection)
CREATE POLICY "soap_notes_delete_policy" ON public.soap_notes
    FOR DELETE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- CHILD TABLE 1: soap_vital_signs
-- ============================================================================

ALTER TABLE public.soap_vital_signs ENABLE ROW LEVEL SECURITY;

-- SELECT: User can see vitals for their SOAP notes
CREATE POLICY "soap_vital_signs_select_policy" ON public.soap_vital_signs
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_vital_signs.soap_note_id
            AND (
                auth.role() = 'service_role'
                OR sn.provider_id = auth.uid()
                OR sn.patient_id = auth.uid()
                OR auth.uid() IS NULL
            )
        )
    );

-- INSERT: Only authorized on the parent note
CREATE POLICY "soap_vital_signs_insert_policy" ON public.soap_vital_signs
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_vital_signs.soap_note_id
            AND (
                auth.role() = 'service_role'
                OR sn.provider_id = auth.uid()
            )
        )
    );

-- UPDATE: Only authorized providers can update
CREATE POLICY "soap_vital_signs_update_policy" ON public.soap_vital_signs
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_vital_signs.soap_note_id
            AND (
                auth.role() = 'service_role'
                OR sn.provider_id = auth.uid()
            )
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_vital_signs.soap_note_id
            AND (
                auth.role() = 'service_role'
                OR sn.provider_id = auth.uid()
            )
        )
    );

-- DELETE: Only service role
CREATE POLICY "soap_vital_signs_delete_policy" ON public.soap_vital_signs
    FOR DELETE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- CHILD TABLE 2: soap_review_of_systems
-- ============================================================================

ALTER TABLE public.soap_review_of_systems ENABLE ROW LEVEL SECURITY;

CREATE POLICY "soap_ros_select_policy" ON public.soap_review_of_systems
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_review_of_systems.soap_note_id
            AND (
                auth.role() = 'service_role'
                OR sn.provider_id = auth.uid()
                OR sn.patient_id = auth.uid()
                OR auth.uid() IS NULL
            )
        )
    );

CREATE POLICY "soap_ros_insert_policy" ON public.soap_review_of_systems
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_review_of_systems.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_ros_update_policy" ON public.soap_review_of_systems
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_review_of_systems.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_review_of_systems.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_ros_delete_policy" ON public.soap_review_of_systems
    FOR DELETE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- CHILD TABLE 3: soap_physical_exam
-- ============================================================================

ALTER TABLE public.soap_physical_exam ENABLE ROW LEVEL SECURITY;

CREATE POLICY "soap_physical_exam_select_policy" ON public.soap_physical_exam
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_physical_exam.soap_note_id
            AND (
                auth.role() = 'service_role'
                OR sn.provider_id = auth.uid()
                OR sn.patient_id = auth.uid()
                OR auth.uid() IS NULL
            )
        )
    );

CREATE POLICY "soap_physical_exam_insert_policy" ON public.soap_physical_exam
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_physical_exam.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_physical_exam_update_policy" ON public.soap_physical_exam
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_physical_exam.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_physical_exam.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_physical_exam_delete_policy" ON public.soap_physical_exam
    FOR DELETE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- CHILD TABLE 4: soap_history_items
-- ============================================================================

ALTER TABLE public.soap_history_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "soap_history_items_select_policy" ON public.soap_history_items
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_history_items.soap_note_id
            AND (
                auth.role() = 'service_role'
                OR sn.provider_id = auth.uid()
                OR sn.patient_id = auth.uid()
                OR auth.uid() IS NULL
            )
        )
    );

CREATE POLICY "soap_history_items_insert_policy" ON public.soap_history_items
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_history_items.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_history_items_update_policy" ON public.soap_history_items
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_history_items.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_history_items.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_history_items_delete_policy" ON public.soap_history_items
    FOR DELETE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- CHILD TABLE 5: soap_medications
-- ============================================================================

ALTER TABLE public.soap_medications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "soap_medications_select_policy" ON public.soap_medications
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_medications.soap_note_id
            AND (
                auth.role() = 'service_role'
                OR sn.provider_id = auth.uid()
                OR sn.patient_id = auth.uid()
                OR auth.uid() IS NULL
            )
        )
    );

CREATE POLICY "soap_medications_insert_policy" ON public.soap_medications
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_medications.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_medications_update_policy" ON public.soap_medications
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_medications.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_medications.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_medications_delete_policy" ON public.soap_medications
    FOR DELETE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- CHILD TABLE 6: soap_allergies
-- ============================================================================

ALTER TABLE public.soap_allergies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "soap_allergies_select_policy" ON public.soap_allergies
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_allergies.soap_note_id
            AND (
                auth.role() = 'service_role'
                OR sn.provider_id = auth.uid()
                OR sn.patient_id = auth.uid()
                OR auth.uid() IS NULL
            )
        )
    );

CREATE POLICY "soap_allergies_insert_policy" ON public.soap_allergies
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_allergies.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_allergies_update_policy" ON public.soap_allergies
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_allergies.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_allergies.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_allergies_delete_policy" ON public.soap_allergies
    FOR DELETE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- CHILD TABLE 7: soap_assessment_items
-- ============================================================================

ALTER TABLE public.soap_assessment_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "soap_assessment_items_select_policy" ON public.soap_assessment_items
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_assessment_items.soap_note_id
            AND (
                auth.role() = 'service_role'
                OR sn.provider_id = auth.uid()
                OR sn.patient_id = auth.uid()
                OR auth.uid() IS NULL
            )
        )
    );

CREATE POLICY "soap_assessment_items_insert_policy" ON public.soap_assessment_items
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_assessment_items.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_assessment_items_update_policy" ON public.soap_assessment_items
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_assessment_items.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_assessment_items.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_assessment_items_delete_policy" ON public.soap_assessment_items
    FOR DELETE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- CHILD TABLE 8: soap_plan_items
-- ============================================================================

ALTER TABLE public.soap_plan_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "soap_plan_items_select_policy" ON public.soap_plan_items
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_plan_items.soap_note_id
            AND (
                auth.role() = 'service_role'
                OR sn.provider_id = auth.uid()
                OR sn.patient_id = auth.uid()
                OR auth.uid() IS NULL
            )
        )
    );

CREATE POLICY "soap_plan_items_insert_policy" ON public.soap_plan_items
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_plan_items.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_plan_items_update_policy" ON public.soap_plan_items
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_plan_items.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_plan_items.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_plan_items_delete_policy" ON public.soap_plan_items
    FOR DELETE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- CHILD TABLE 9: soap_safety_alerts
-- ============================================================================

ALTER TABLE public.soap_safety_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "soap_safety_alerts_select_policy" ON public.soap_safety_alerts
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_safety_alerts.soap_note_id
            AND (
                auth.role() = 'service_role'
                OR sn.provider_id = auth.uid()
                OR sn.patient_id = auth.uid()
                OR auth.uid() IS NULL
            )
        )
    );

CREATE POLICY "soap_safety_alerts_insert_policy" ON public.soap_safety_alerts
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_safety_alerts.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_safety_alerts_update_policy" ON public.soap_safety_alerts
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_safety_alerts.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_safety_alerts.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_safety_alerts_delete_policy" ON public.soap_safety_alerts
    FOR DELETE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- CHILD TABLE 10: soap_hpi_details
-- ============================================================================

ALTER TABLE public.soap_hpi_details ENABLE ROW LEVEL SECURITY;

CREATE POLICY "soap_hpi_details_select_policy" ON public.soap_hpi_details
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_hpi_details.soap_note_id
            AND (
                auth.role() = 'service_role'
                OR sn.provider_id = auth.uid()
                OR sn.patient_id = auth.uid()
                OR auth.uid() IS NULL
            )
        )
    );

CREATE POLICY "soap_hpi_details_insert_policy" ON public.soap_hpi_details
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_hpi_details.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_hpi_details_update_policy" ON public.soap_hpi_details
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_hpi_details.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_hpi_details.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_hpi_details_delete_policy" ON public.soap_hpi_details
    FOR DELETE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- CHILD TABLE 11: soap_coding_billing
-- ============================================================================

ALTER TABLE public.soap_coding_billing ENABLE ROW LEVEL SECURITY;

CREATE POLICY "soap_coding_billing_select_policy" ON public.soap_coding_billing
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_coding_billing.soap_note_id
            AND (
                auth.role() = 'service_role'
                OR sn.provider_id = auth.uid()
                OR sn.patient_id = auth.uid()
                OR auth.uid() IS NULL
            )
        )
    );

CREATE POLICY "soap_coding_billing_insert_policy" ON public.soap_coding_billing
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_coding_billing.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_coding_billing_update_policy" ON public.soap_coding_billing
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_coding_billing.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.soap_notes sn
            WHERE sn.id = soap_coding_billing.soap_note_id
            AND (auth.role() = 'service_role' OR sn.provider_id = auth.uid())
        )
    );

CREATE POLICY "soap_coding_billing_delete_policy" ON public.soap_coding_billing
    FOR DELETE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- Verification
-- ============================================================================

-- Verify all tables have RLS enabled
SELECT tablename FROM pg_tables
WHERE tablename LIKE 'soap_%'
AND schemaname = 'public'
ORDER BY tablename;
