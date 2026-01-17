-- Phase 1 Task 2c: Add validation functions and helper views for normalized SOAP schema
-- Purpose: Validate SOAP data integrity, support efficient queries, and prepare for EHRbase sync
-- Date: January 17, 2026

-- ============================================================================
-- SECTION 1: VALIDATION FUNCTIONS
-- ============================================================================

-- Function: Calculate BMI from weight and height
-- Used by: SOAP form UI validation, vital signs insertion
-- Returns: BMI value or NULL if inputs invalid
CREATE OR REPLACE FUNCTION public.calculate_bmi(
    weight_kg DECIMAL,
    height_cm DECIMAL
) RETURNS DECIMAL AS $$
BEGIN
    IF weight_kg IS NULL OR height_cm IS NULL THEN
        RETURN NULL;
    END IF;

    IF weight_kg <= 0 OR height_cm <= 0 THEN
        RETURN NULL;
    END IF;

    -- Convert height to meters: height_cm / 100, then BMI = weight / (height^2)
    RETURN ROUND((weight_kg / ((height_cm / 100.0) ^ 2))::NUMERIC, 1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function: Validate vital signs for clinical plausibility
-- Used by: process-live-transcription-v2, generate-soap-from-transcript edge functions
-- Returns: TRUE if valid, FALSE if out of realistic ranges
CREATE OR REPLACE FUNCTION public.validate_vital_signs(
    note_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_count INT;
    v_temp_min DECIMAL := 35.0;
    v_temp_max DECIMAL := 42.0;
    v_hr_min INT := 30;
    v_hr_max INT := 200;
    v_rr_min INT := 8;
    v_rr_max INT := 60;
    v_spo2_min INT := 50;
    v_spo2_max INT := 100;
    v_sys_min INT := 40;
    v_sys_max INT := 300;
    v_dia_min INT := 20;
    v_dia_max INT := 200;
BEGIN
    -- Check if vital signs exist for this note
    SELECT COUNT(*) INTO v_count
    FROM public.soap_vital_signs
    WHERE soap_note_id = note_id;

    IF v_count = 0 THEN
        -- No vitals recorded is valid (e.g., telemedicine patient can't measure)
        RETURN TRUE;
    END IF;

    -- Validate temperature (if recorded)
    SELECT COUNT(*) INTO v_count
    FROM public.soap_vital_signs
    WHERE soap_note_id = note_id
    AND (
        temperature_value IS NULL
        OR (temperature_value >= v_temp_min AND temperature_value <= v_temp_max)
    );

    IF (SELECT COUNT(*) FROM public.soap_vital_signs WHERE soap_note_id = note_id AND temperature_value IS NOT NULL) > 0
    AND v_count = 0 THEN
        RETURN FALSE; -- Temperature out of range
    END IF;

    -- Validate heart rate (if recorded)
    SELECT COUNT(*) INTO v_count
    FROM public.soap_vital_signs
    WHERE soap_note_id = note_id
    AND (
        heart_rate IS NULL
        OR (heart_rate >= v_hr_min AND heart_rate <= v_hr_max)
    );

    IF (SELECT COUNT(*) FROM public.soap_vital_signs WHERE soap_note_id = note_id AND heart_rate IS NOT NULL) > 0
    AND v_count = 0 THEN
        RETURN FALSE; -- Heart rate out of range
    END IF;

    -- Validate respiratory rate (if recorded)
    SELECT COUNT(*) INTO v_count
    FROM public.soap_vital_signs
    WHERE soap_note_id = note_id
    AND (
        respiratory_rate IS NULL
        OR (respiratory_rate >= v_rr_min AND respiratory_rate <= v_rr_max)
    );

    IF (SELECT COUNT(*) FROM public.soap_vital_signs WHERE soap_note_id = note_id AND respiratory_rate IS NOT NULL) > 0
    AND v_count = 0 THEN
        RETURN FALSE; -- Respiratory rate out of range
    END IF;

    -- Validate oxygen saturation (if recorded)
    SELECT COUNT(*) INTO v_count
    FROM public.soap_vital_signs
    WHERE soap_note_id = note_id
    AND (
        oxygen_saturation IS NULL
        OR (oxygen_saturation >= v_spo2_min AND oxygen_saturation <= v_spo2_max)
    );

    IF (SELECT COUNT(*) FROM public.soap_vital_signs WHERE soap_note_id = note_id AND oxygen_saturation IS NOT NULL) > 0
    AND v_count = 0 THEN
        RETURN FALSE; -- SpO2 out of range
    END IF;

    -- Validate blood pressure (if recorded)
    SELECT COUNT(*) INTO v_count
    FROM public.soap_vital_signs
    WHERE soap_note_id = note_id
    AND (
        (blood_pressure_systolic IS NULL OR (blood_pressure_systolic >= v_sys_min AND blood_pressure_systolic <= v_sys_max))
        AND (blood_pressure_diastolic IS NULL OR (blood_pressure_diastolic >= v_dia_min AND blood_pressure_diastolic <= v_dia_max))
    );

    IF (SELECT COUNT(*) FROM public.soap_vital_signs WHERE soap_note_id = note_id AND (blood_pressure_systolic IS NOT NULL OR blood_pressure_diastolic IS NOT NULL)) > 0
    AND v_count = 0 THEN
        RETURN FALSE; -- Blood pressure out of range
    END IF;

    -- All checks passed
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function: Validate medications for required fields and consistency
-- Used by: generate-soap-from-transcript, ComprehensiveSOAPFormDialog
-- Returns: TRUE if valid, FALSE if required fields missing or inconsistent
CREATE OR REPLACE FUNCTION public.validate_medications(
    note_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_count INT;
    v_med_record RECORD;
BEGIN
    -- Check if medications exist for this note
    SELECT COUNT(*) INTO v_count
    FROM public.soap_medications
    WHERE soap_note_id = note_id;

    IF v_count = 0 THEN
        -- No medications recorded is valid
        RETURN TRUE;
    END IF;

    -- Validate each medication
    FOR v_med_record IN
        SELECT id, medication_name, dose, frequency, status
        FROM public.soap_medications
        WHERE soap_note_id = note_id
    LOOP
        -- Medication name is required
        IF v_med_record.medication_name IS NULL OR v_med_record.medication_name = '' THEN
            RETURN FALSE;
        END IF;

        -- Status must be one of allowed values
        IF v_med_record.status IS NOT NULL
        AND v_med_record.status NOT IN ('active', 'discontinued', 'completed') THEN
            RETURN FALSE;
        END IF;

        -- At least dose or frequency should be present for active meds
        IF v_med_record.status = 'active'
        AND (v_med_record.dose IS NULL OR v_med_record.dose = '')
        AND (v_med_record.frequency IS NULL OR v_med_record.frequency = '') THEN
            RETURN FALSE;
        END IF;
    END LOOP;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function: Validate assessment items for required diagnostic information
-- Used by: generate-soap-from-transcript, SOAP form validation
-- Returns: TRUE if valid, FALSE if required fields missing
CREATE OR REPLACE FUNCTION public.validate_assessment_items(
    note_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_count INT;
    v_assessment_record RECORD;
BEGIN
    -- Check if assessments exist for this note
    SELECT COUNT(*) INTO v_count
    FROM public.soap_assessment_items
    WHERE soap_note_id = note_id;

    IF v_count = 0 THEN
        -- At least one assessment is recommended but not required (rare edge case)
        RETURN TRUE;
    END IF;

    -- Validate each assessment item
    FOR v_assessment_record IN
        SELECT id, diagnosis_description, status
        FROM public.soap_assessment_items
        WHERE soap_note_id = note_id
    LOOP
        -- Diagnosis description is required
        IF v_assessment_record.diagnosis_description IS NULL OR v_assessment_record.diagnosis_description = '' THEN
            RETURN FALSE;
        END IF;

        -- Status must be one of allowed values if present
        IF v_assessment_record.status IS NOT NULL
        AND v_assessment_record.status NOT IN ('new', 'established', 'worsening', 'improving', 'stable', 'resolved') THEN
            RETURN FALSE;
        END IF;
    END LOOP;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function: Validate safety alerts for required information
-- Used by: generate-soap-from-transcript, finalize-video-call
-- Returns: TRUE if valid, FALSE if critical alerts missing required data
CREATE OR REPLACE FUNCTION public.validate_safety_alerts(
    note_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_count INT;
    v_alert_record RECORD;
BEGIN
    -- Check if safety alerts exist for this note
    SELECT COUNT(*) INTO v_count
    FROM public.soap_safety_alerts
    WHERE soap_note_id = note_id;

    IF v_count = 0 THEN
        -- No alerts recorded is valid
        RETURN TRUE;
    END IF;

    -- Validate critical alerts
    FOR v_alert_record IN
        SELECT id, alert_type, severity, title
        FROM public.soap_safety_alerts
        WHERE soap_note_id = note_id
        AND severity = 'critical'
    LOOP
        -- Critical alerts must have title
        IF v_alert_record.title IS NULL OR v_alert_record.title = '' THEN
            RETURN FALSE;
        END IF;
    END LOOP;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SECTION 2: HELPER VIEWS FOR EFFICIENT QUERIES
-- ============================================================================

-- View: SOAP notes by provider with recent activity
-- Purpose: Enable provider dashboards to show their recent SOAP notes
-- Used by: provider_landing_page_widget.dart
CREATE OR REPLACE VIEW public.soap_notes_by_provider AS
SELECT
    sn.id,
    sn.provider_id,
    sn.patient_id,
    sn.appointment_id,
    sn.chief_complaint,
    sn.status,
    sn.signed_at,
    sn.created_at,
    COUNT(CASE WHEN sai.is_primary_diagnosis THEN 1 END) AS primary_diagnoses_count,
    COUNT(DISTINCT spi.id) AS plan_items_count,
    (SELECT ehr_sync_status FROM public.soap_notes WHERE id = sn.id LIMIT 1) AS ehr_sync_status
FROM public.soap_notes sn
LEFT JOIN public.soap_assessment_items sai ON sai.soap_note_id = sn.id
LEFT JOIN public.soap_plan_items spi ON spi.soap_note_id = sn.id
GROUP BY sn.id, sn.provider_id, sn.patient_id, sn.appointment_id, sn.chief_complaint, sn.status, sn.signed_at, sn.created_at;

-- View: SOAP notes by patient with medical history context
-- Purpose: Enable patient portals to display their SOAP notes with context
-- Used by: patient_landing_page_widget.dart, PatientHistoryDialog
CREATE OR REPLACE VIEW public.soap_notes_by_patient AS
SELECT
    sn.id,
    sn.patient_id,
    sn.provider_id,
    sn.appointment_id,
    sn.chief_complaint,
    sn.status,
    sn.created_at,
    sn.signed_at,
    COUNT(DISTINCT sai.id) AS total_diagnoses,
    COUNT(CASE WHEN sai.status = 'active' THEN 1 END) AS active_problems,
    COUNT(DISTINCT sm.id) AS medications_count,
    COUNT(CASE WHEN sa.severity = 'life_threatening' THEN 1 END) AS critical_allergies_count
FROM public.soap_notes sn
LEFT JOIN public.soap_assessment_items sai ON sai.soap_note_id = sn.id
LEFT JOIN public.soap_medications sm ON sm.soap_note_id = sn.id AND sm.status = 'active'
LEFT JOIN public.soap_allergies sa ON sa.soap_note_id = sn.id
WHERE sn.status IN ('signed', 'submitted')
GROUP BY sn.id, sn.patient_id, sn.provider_id, sn.appointment_id, sn.chief_complaint, sn.status, sn.created_at, sn.signed_at;

-- View: Diagnoses with active medications and follow-up plans
-- Purpose: Support care continuity by linking problems to medications and follow-up
-- Used by: generate-precall-soap, AI chat context building
CREATE OR REPLACE VIEW public.problem_medication_followup_map AS
SELECT
    sai.soap_note_id,
    sai.problem_number,
    sai.diagnosis_description,
    sai.icd10_code,
    COUNT(DISTINCT sm.id) AS medication_count,
    array_agg(DISTINCT sm.medication_name) AS medications,
    COUNT(DISTINCT spi.id) AS plan_count,
    array_agg(DISTINCT spi.plan_type) FILTER (WHERE spi.plan_type IS NOT NULL) AS plan_types,
    MAX(spi.follow_up_timeframe) AS earliest_followup
FROM public.soap_assessment_items sai
LEFT JOIN public.soap_medications sm ON sm.soap_note_id = sai.soap_note_id
    AND (sm.indication ILIKE '%' || sai.diagnosis_description || '%' OR sm.indication ILIKE '%' || COALESCE(sai.icd10_description, '') || '%')
LEFT JOIN public.soap_plan_items spi ON spi.soap_note_id = sai.soap_note_id
    AND spi.problem_number = sai.problem_number
GROUP BY sai.soap_note_id, sai.problem_number, sai.diagnosis_description, sai.icd10_code;

-- View: Critical alerts requiring provider acknowledgment
-- Purpose: Surfacecritical safety issues for rapid provider response
-- Used by: Clinical safety dashboards, post-call review
CREATE OR REPLACE VIEW public.critical_safety_alerts AS
SELECT
    ssa.id,
    ssa.soap_note_id,
    sn.patient_id,
    sn.provider_id,
    sn.appointment_id,
    ssa.alert_type,
    ssa.title,
    ssa.description,
    ssa.recommendation,
    ssa.acknowledged_by,
    ssa.acknowledged_at,
    CASE
        WHEN ssa.acknowledged_by IS NULL THEN 'PENDING'
        WHEN ssa.acknowledged_at IS NULL THEN 'ACKNOWLEDGED_NO_TIME'
        WHEN (NOW() - ssa.acknowledged_at) < INTERVAL '24 hours' THEN 'RECENTLY_ACKNOWLEDGED'
        ELSE 'ACKNOWLEDGED_AGED'
    END AS acknowledgment_status
FROM public.soap_safety_alerts ssa
JOIN public.soap_notes sn ON sn.id = ssa.soap_note_id
WHERE ssa.severity IN ('warning', 'critical')
ORDER BY ssa.acknowledged_by NULLS FIRST, ssa.created_at DESC;

-- ============================================================================
-- SECTION 3: UPDATE EXISTING TRIGGERS AND FUNCTIONS
-- ============================================================================

-- Update: Trigger to cascade updated_at from child tables to parent soap_notes
-- Already created in schema migration, but ensure it exists
DROP TRIGGER IF EXISTS soap_vital_signs_update_parent ON public.soap_vital_signs CASCADE;
CREATE TRIGGER soap_vital_signs_update_parent
AFTER INSERT OR UPDATE ON public.soap_vital_signs
FOR EACH ROW
EXECUTE FUNCTION public.update_soap_notes_timestamp();

DROP TRIGGER IF EXISTS soap_review_of_systems_update_parent ON public.soap_review_of_systems CASCADE;
CREATE TRIGGER soap_review_of_systems_update_parent
AFTER INSERT OR UPDATE ON public.soap_review_of_systems
FOR EACH ROW
EXECUTE FUNCTION public.update_soap_notes_timestamp();

DROP TRIGGER IF EXISTS soap_physical_exam_update_parent ON public.soap_physical_exam CASCADE;
CREATE TRIGGER soap_physical_exam_update_parent
AFTER INSERT OR UPDATE ON public.soap_physical_exam
FOR EACH ROW
EXECUTE FUNCTION public.update_soap_notes_timestamp();

DROP TRIGGER IF EXISTS soap_history_items_update_parent ON public.soap_history_items CASCADE;
CREATE TRIGGER soap_history_items_update_parent
AFTER INSERT OR UPDATE ON public.soap_history_items
FOR EACH ROW
EXECUTE FUNCTION public.update_soap_notes_timestamp();

DROP TRIGGER IF EXISTS soap_medications_update_parent ON public.soap_medications CASCADE;
CREATE TRIGGER soap_medications_update_parent
AFTER INSERT OR UPDATE ON public.soap_medications
FOR EACH ROW
EXECUTE FUNCTION public.update_soap_notes_timestamp();

DROP TRIGGER IF EXISTS soap_allergies_update_parent ON public.soap_allergies CASCADE;
CREATE TRIGGER soap_allergies_update_parent
AFTER INSERT OR UPDATE ON public.soap_allergies
FOR EACH ROW
EXECUTE FUNCTION public.update_soap_notes_timestamp();

DROP TRIGGER IF EXISTS soap_assessment_items_update_parent ON public.soap_assessment_items CASCADE;
CREATE TRIGGER soap_assessment_items_update_parent
AFTER INSERT OR UPDATE ON public.soap_assessment_items
FOR EACH ROW
EXECUTE FUNCTION public.update_soap_notes_timestamp();

DROP TRIGGER IF EXISTS soap_plan_items_update_parent ON public.soap_plan_items CASCADE;
CREATE TRIGGER soap_plan_items_update_parent
AFTER INSERT OR UPDATE ON public.soap_plan_items
FOR EACH ROW
EXECUTE FUNCTION public.update_soap_notes_timestamp();

DROP TRIGGER IF EXISTS soap_safety_alerts_update_parent ON public.soap_safety_alerts CASCADE;
CREATE TRIGGER soap_safety_alerts_update_parent
AFTER INSERT OR UPDATE ON public.soap_safety_alerts
FOR EACH ROW
EXECUTE FUNCTION public.update_soap_notes_timestamp();

DROP TRIGGER IF EXISTS soap_hpi_details_update_parent ON public.soap_hpi_details CASCADE;
CREATE TRIGGER soap_hpi_details_update_parent
AFTER INSERT OR UPDATE ON public.soap_hpi_details
FOR EACH ROW
EXECUTE FUNCTION public.update_soap_notes_timestamp();

DROP TRIGGER IF EXISTS soap_coding_billing_update_parent ON public.soap_coding_billing CASCADE;
CREATE TRIGGER soap_coding_billing_update_parent
AFTER INSERT OR UPDATE ON public.soap_coding_billing
FOR EACH ROW
EXECUTE FUNCTION public.update_soap_notes_timestamp();

-- Grant permissions on new functions to service_role (used by edge functions)
GRANT EXECUTE ON FUNCTION public.calculate_bmi(DECIMAL, DECIMAL) TO service_role;
GRANT EXECUTE ON FUNCTION public.validate_vital_signs(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.validate_medications(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.validate_assessment_items(UUID) TO service_role;
GRANT EXECUTE ON FUNCTION public.validate_safety_alerts(UUID) TO service_role;

-- Grant permissions on new views to authenticated users
GRANT SELECT ON public.soap_notes_by_provider TO authenticated;
GRANT SELECT ON public.soap_notes_by_patient TO authenticated;
GRANT SELECT ON public.problem_medication_followup_map TO authenticated;
GRANT SELECT ON public.critical_safety_alerts TO authenticated;

-- ============================================================================
-- SECTION 4: MIGRATION COMPLETION
-- ============================================================================

-- Migration 20260117000200_add_soap_validation_functions completed successfully
