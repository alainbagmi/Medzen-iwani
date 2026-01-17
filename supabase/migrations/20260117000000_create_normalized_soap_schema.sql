-- Phase 1: Create Normalized SOAP Database Schema (12 tables)
-- This migration establishes the foundation for the comprehensive SOAP note system
-- Date: 2026-01-17

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Master SOAP Notes Table
CREATE TABLE IF NOT EXISTS public.soap_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Core identifiers
    session_id UUID REFERENCES public.video_call_sessions(id) ON DELETE SET NULL,
    appointment_id UUID REFERENCES public.appointments(id) ON DELETE CASCADE NOT NULL,
    call_transcript_id UUID REFERENCES public.call_transcripts(id) ON DELETE SET NULL,
    provider_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    patient_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,

    -- Metadata
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('precall_draft', 'draft', 'in_progress', 'completed', 'signed', 'synced')),
    version INTEGER DEFAULT 1,
    is_real_time_draft BOOLEAN DEFAULT false,

    -- Encounter metadata
    encounter_type VARCHAR(50) CHECK (encounter_type IN ('telemedicine_video', 'telemedicine_audio', 'in_person')),
    visit_type VARCHAR(50) CHECK (visit_type IN ('new_patient', 'follow_up', 'urgent')),
    chief_complaint TEXT,
    reason_for_visit TEXT,
    consent_obtained BOOLEAN,
    consent_timestamp TIMESTAMPTZ,
    language_used VARCHAR(10),

    -- AI metadata
    ai_generated_at TIMESTAMPTZ,
    ai_model_used VARCHAR(255),
    ai_raw_response JSONB,
    ai_confidence_score DECIMAL(3,2),
    ai_generation_prompt_version VARCHAR(50),

    -- Clinician workflow
    requires_clinician_review BOOLEAN DEFAULT true,
    reviewed_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    review_notes TEXT,
    signed_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    signed_at TIMESTAMPTZ,
    signature_hash VARCHAR(255),

    -- EHR sync
    ehr_sync_status VARCHAR(50) DEFAULT 'pending' CHECK (ehr_sync_status IN ('pending', 'in_progress', 'completed', 'failed')),
    ehr_sync_error TEXT,
    synced_at TIMESTAMPTZ,
    ehrbase_composition_uid VARCHAR(255),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    submitted_at TIMESTAMPTZ,

    -- Constraints
    CONSTRAINT valid_dates CHECK (signed_at IS NULL OR signed_at >= created_at)
);

-- 2. Vital Signs Table (Objective - Vitals)
CREATE TABLE IF NOT EXISTS public.soap_vital_signs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    soap_note_id UUID REFERENCES public.soap_notes(id) ON DELETE CASCADE NOT NULL,
    measurement_time TIMESTAMPTZ DEFAULT NOW(),
    source VARCHAR(50) CHECK (source IN ('patient_device', 'clinic_device', 'wearable', 'patient_reported', 'previous_visit', 'unknown')),

    -- Core vitals
    temperature_value DECIMAL(4,1),
    temperature_unit VARCHAR(10) CHECK (temperature_unit IN ('celsius', 'fahrenheit')),
    temperature_site VARCHAR(50) CHECK (temperature_site IN ('oral', 'axillary', 'rectal', 'tympanic')),

    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,
    blood_pressure_position VARCHAR(50) CHECK (blood_pressure_position IN ('sitting', 'standing', 'supine')),

    heart_rate INTEGER,
    heart_rhythm VARCHAR(50) CHECK (heart_rhythm IN ('regular', 'irregular')),

    respiratory_rate INTEGER,
    respiratory_pattern VARCHAR(50) CHECK (respiratory_pattern IN ('normal', 'labored', 'shallow')),

    oxygen_saturation INTEGER CHECK (oxygen_saturation >= 0 AND oxygen_saturation <= 100),
    oxygen_supplemental BOOLEAN,
    oxygen_liters_per_minute DECIMAL(3,1),

    weight_kg DECIMAL(5,2),
    height_cm DECIMAL(5,2),
    bmi DECIMAL(4,1),
    bmi_category VARCHAR(50) CHECK (bmi_category IN ('underweight', 'normal', 'overweight', 'obese')),

    pain_score INTEGER CHECK (pain_score >= 0 AND pain_score <= 10),
    pain_location TEXT,

    -- Optional advanced vitals
    glasgow_coma_scale INTEGER CHECK (glasgow_coma_scale >= 3 AND glasgow_coma_scale <= 15),
    blood_glucose_mg_dl INTEGER,
    peak_flow_l_min INTEGER,

    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Review of Systems Table (Subjective - ROS)
CREATE TABLE IF NOT EXISTS public.soap_review_of_systems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    soap_note_id UUID REFERENCES public.soap_notes(id) ON DELETE CASCADE NOT NULL,
    system_name VARCHAR(50) NOT NULL CHECK (system_name IN (
        'constitutional', 'eyes', 'ent', 'cardiovascular', 'respiratory',
        'gastrointestinal', 'genitourinary', 'musculoskeletal', 'skin',
        'neurological', 'psychiatric', 'endocrine', 'hematologic_lymphatic',
        'allergic_immunologic', 'other'
    )),

    -- Findings
    has_symptoms BOOLEAN,
    symptoms_positive TEXT[],
    symptoms_negative TEXT[],
    symptoms_unknown TEXT[],

    -- Details
    severity VARCHAR(50) CHECK (severity IN ('mild', 'moderate', 'severe')),
    duration_description TEXT,
    onset_description TEXT,

    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(soap_note_id, system_name)
);

-- 4. Physical Examination Table (Objective - Exam)
CREATE TABLE IF NOT EXISTS public.soap_physical_exam (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    soap_note_id UUID REFERENCES public.soap_notes(id) ON DELETE CASCADE NOT NULL,
    system_name VARCHAR(50) NOT NULL CHECK (system_name IN (
        'general', 'heent', 'neck', 'cardiovascular', 'respiratory',
        'abdomen', 'extremities', 'skin', 'neurological'
    )),

    -- Findings
    is_abnormal BOOLEAN,
    findings TEXT[],
    clinical_significance VARCHAR(50) CHECK (clinical_significance IN ('normal', 'minor', 'significant', 'critical')),

    -- Telemedicine limitations
    limited_by_telemedicine BOOLEAN DEFAULT true,
    visual_inspection_only BOOLEAN,
    observation_notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(soap_note_id, system_name)
);

-- 5. History Items Table (Subjective - PMH/PSH/FH/SH)
CREATE TABLE IF NOT EXISTS public.soap_history_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    soap_note_id UUID REFERENCES public.soap_notes(id) ON DELETE CASCADE NOT NULL,
    history_type VARCHAR(50) NOT NULL CHECK (history_type IN ('past_medical', 'past_surgical', 'family', 'social')),

    -- Past Medical History
    condition_name TEXT,
    icd10_code VARCHAR(20),
    onset_date DATE,
    status VARCHAR(50) CHECK (status IN ('active', 'resolved', 'chronic')),

    -- Past Surgical History
    surgery_name TEXT,
    surgery_date DATE,
    complications TEXT,

    -- Family History
    relationship VARCHAR(50),
    condition TEXT,
    age_of_onset INTEGER,

    -- Social History
    category VARCHAR(50),
    value TEXT,
    frequency TEXT,
    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Medications Table (Subjective + Plan)
CREATE TABLE IF NOT EXISTS public.soap_medications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    soap_note_id UUID REFERENCES public.soap_notes(id) ON DELETE CASCADE NOT NULL,
    source VARCHAR(50) NOT NULL CHECK (source IN ('current_medication', 'newly_prescribed', 'discontinued')),

    -- Medication details
    medication_name TEXT NOT NULL,
    generic_name TEXT,
    dose TEXT,
    dose_value DECIMAL(10,2),
    dose_unit VARCHAR(50),
    route VARCHAR(50) CHECK (route IN ('oral', 'IV', 'IM', 'topical', 'subcutaneous', 'intranasal', 'inhaled', 'other')),
    frequency TEXT,
    duration TEXT,
    start_date DATE,
    end_date DATE,

    -- Clinical context
    indication TEXT,
    prescribing_provider UUID REFERENCES public.users(id) ON DELETE SET NULL,
    pharmacy_instructions TEXT,

    -- Safety
    contraindications TEXT[],
    drug_interactions TEXT[],
    side_effects_to_monitor TEXT[],
    requires_monitoring BOOLEAN,
    monitoring_plan TEXT,

    -- Status
    status VARCHAR(50) CHECK (status IN ('active', 'discontinued', 'completed')),
    discontinuation_reason TEXT,
    adherence VARCHAR(50) CHECK (adherence IN ('good', 'fair', 'poor', 'unknown')),
    adherence_barriers TEXT,

    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Allergies Table (Subjective - Safety)
CREATE TABLE IF NOT EXISTS public.soap_allergies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    soap_note_id UUID REFERENCES public.soap_notes(id) ON DELETE CASCADE NOT NULL,

    allergen TEXT NOT NULL,
    allergen_type VARCHAR(50) CHECK (allergen_type IN ('drug', 'food', 'environmental')),
    reaction TEXT,
    severity VARCHAR(50) CHECK (severity IN ('mild', 'moderate', 'severe', 'life_threatening')),
    onset_date DATE,
    status VARCHAR(50) CHECK (status IN ('active', 'resolved', 'suspected')),

    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Assessment Items Table (Assessment)
CREATE TABLE IF NOT EXISTS public.soap_assessment_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    soap_note_id UUID REFERENCES public.soap_notes(id) ON DELETE CASCADE NOT NULL,
    problem_number INTEGER NOT NULL,

    -- Diagnosis
    diagnosis_description TEXT NOT NULL,
    icd10_code VARCHAR(20),
    icd10_description TEXT,
    snomed_code VARCHAR(50),

    -- Clinical context
    is_primary_diagnosis BOOLEAN DEFAULT false,
    status VARCHAR(50) CHECK (status IN ('new', 'established', 'worsening', 'improving', 'stable', 'resolved')),
    severity VARCHAR(50) CHECK (severity IN ('mild', 'moderate', 'severe', 'critical')),
    confidence VARCHAR(50) CHECK (confidence IN ('confirmed', 'suspected', 'rule_out')),
    likelihood_percentage INTEGER CHECK (likelihood_percentage >= 0 AND likelihood_percentage <= 100),

    -- Supporting data
    key_findings TEXT[],
    pertinent_negatives TEXT[],
    differential_diagnoses TEXT[],

    -- Risk stratification
    risk_level VARCHAR(50) CHECK (risk_level IN ('low', 'moderate', 'high')),
    clinical_decision_score TEXT,
    prognosis TEXT,
    complications_risk TEXT[],

    clinical_impression_summary TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Plan Items Table (Plan)
CREATE TABLE IF NOT EXISTS public.soap_plan_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    soap_note_id UUID REFERENCES public.soap_notes(id) ON DELETE CASCADE NOT NULL,
    problem_number INTEGER,
    plan_type VARCHAR(50) NOT NULL CHECK (plan_type IN ('medication', 'lab', 'imaging', 'procedure', 'referral', 'education', 'follow_up', 'other')),

    -- Common fields
    description TEXT NOT NULL,
    indication TEXT,
    urgency VARCHAR(50) CHECK (urgency IN ('routine', 'urgent', 'stat', 'emergent')),
    status VARCHAR(50) CHECK (status IN ('ordered', 'completed', 'pending', 'cancelled')),

    -- Lab/Imaging orders
    test_name TEXT,
    body_site TEXT,
    fasting_required BOOLEAN,
    special_instructions TEXT,

    -- Procedures
    procedure_name TEXT,
    consent_obtained BOOLEAN,
    scheduled_date TIMESTAMPTZ,

    -- Referrals
    specialty TEXT,
    provider_name TEXT,
    referral_reason TEXT,
    preferred_timeframe TEXT,

    -- Follow-up
    follow_up_timeframe TEXT,
    follow_up_type VARCHAR(50) CHECK (follow_up_type IN ('telemedicine', 'in_person', 'lab_review', 'as_needed')),
    follow_up_with VARCHAR(100),

    -- Patient education
    education_topic TEXT,
    materials_provided TEXT[],
    comprehension_verified BOOLEAN,
    teach_back_completed BOOLEAN,

    -- Return precautions
    is_return_precaution BOOLEAN,
    red_flag_symptom TEXT,
    escalation_criteria TEXT,

    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Safety Alerts Table (Safety)
CREATE TABLE IF NOT EXISTS public.soap_safety_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    soap_note_id UUID REFERENCES public.soap_notes(id) ON DELETE CASCADE NOT NULL,
    alert_type VARCHAR(50) NOT NULL CHECK (alert_type IN ('red_flag', 'drug_interaction', 'allergy_conflict', 'contraindication', 'limitation')),

    severity VARCHAR(50) CHECK (severity IN ('informational', 'warning', 'critical')),
    title TEXT NOT NULL,
    description TEXT,
    recommendation TEXT,
    acknowledged_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
    acknowledged_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. HPI Details Table (Subjective - HPI)
CREATE TABLE IF NOT EXISTS public.soap_hpi_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    soap_note_id UUID REFERENCES public.soap_notes(id) ON DELETE CASCADE NOT NULL,

    hpi_narrative TEXT,

    -- Structured HPI elements
    symptom_onset TEXT,
    duration TEXT,
    location TEXT,
    radiation TEXT,
    quality TEXT,
    severity_scale INTEGER CHECK (severity_scale >= 0 AND severity_scale <= 10),
    timing_pattern TEXT,
    context TEXT,

    aggravating_factors TEXT[],
    relieving_factors TEXT[],
    associated_symptoms TEXT[],
    pertinent_negatives TEXT[],

    previous_episodes BOOLEAN,
    previous_treatment TEXT,
    patient_tried TEXT[],
    patient_goals TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. Coding & Billing Table (MDM & Billing)
CREATE TABLE IF NOT EXISTS public.soap_coding_billing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    soap_note_id UUID REFERENCES public.soap_notes(id) ON DELETE CASCADE NOT NULL,

    -- CPT codes
    cpt_code VARCHAR(20),
    cpt_description TEXT,
    cpt_confidence DECIMAL(3,2),

    -- Medical Decision Making
    mdm_level VARCHAR(50) CHECK (mdm_level IN ('straightforward', 'low', 'moderate', 'high')),
    mdm_rationale TEXT,
    problems_addressed_count INTEGER,
    data_reviewed TEXT[],
    risk_level VARCHAR(50) CHECK (risk_level IN ('minimal', 'low', 'moderate', 'high')),
    time_spent_minutes INTEGER,
    counseling_time_minutes INTEGER,

    -- E/M code suggestion
    em_code VARCHAR(20),
    em_rationale TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_soap_notes_appointment ON public.soap_notes(appointment_id);
CREATE INDEX IF NOT EXISTS idx_soap_notes_provider ON public.soap_notes(provider_id);
CREATE INDEX IF NOT EXISTS idx_soap_notes_patient ON public.soap_notes(patient_id);
CREATE INDEX IF NOT EXISTS idx_soap_notes_session ON public.soap_notes(session_id);
CREATE INDEX IF NOT EXISTS idx_soap_notes_status ON public.soap_notes(status);
CREATE INDEX IF NOT EXISTS idx_soap_notes_signed ON public.soap_notes(signed_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS idx_soap_notes_ehr_sync ON public.soap_notes(ehr_sync_status);

-- Child table indexes
CREATE INDEX IF NOT EXISTS idx_soap_vital_signs_note ON public.soap_vital_signs(soap_note_id);
CREATE INDEX IF NOT EXISTS idx_soap_vital_signs_measurement_time ON public.soap_vital_signs(soap_note_id, measurement_time DESC);

CREATE INDEX IF NOT EXISTS idx_soap_ros_note ON public.soap_review_of_systems(soap_note_id);
CREATE INDEX IF NOT EXISTS idx_soap_ros_system ON public.soap_review_of_systems(soap_note_id, system_name);

CREATE INDEX IF NOT EXISTS idx_soap_physical_exam_note ON public.soap_physical_exam(soap_note_id);
CREATE INDEX IF NOT EXISTS idx_soap_physical_exam_system ON public.soap_physical_exam(soap_note_id, system_name);

CREATE INDEX IF NOT EXISTS idx_soap_history_note ON public.soap_history_items(soap_note_id);
CREATE INDEX IF NOT EXISTS idx_soap_history_type ON public.soap_history_items(soap_note_id, history_type);

CREATE INDEX IF NOT EXISTS idx_soap_medications_note ON public.soap_medications(soap_note_id);
CREATE INDEX IF NOT EXISTS idx_soap_medications_status ON public.soap_medications(soap_note_id, status);
CREATE INDEX IF NOT EXISTS idx_soap_medications_name ON public.soap_medications(medication_name);

CREATE INDEX IF NOT EXISTS idx_soap_allergies_note ON public.soap_allergies(soap_note_id);
CREATE INDEX IF NOT EXISTS idx_soap_allergies_status ON public.soap_allergies(soap_note_id, status);

CREATE INDEX IF NOT EXISTS idx_soap_assessment_note ON public.soap_assessment_items(soap_note_id);
CREATE INDEX IF NOT EXISTS idx_soap_assessment_primary ON public.soap_assessment_items(soap_note_id, is_primary_diagnosis);
CREATE INDEX IF NOT EXISTS idx_soap_assessment_icd10 ON public.soap_assessment_items(icd10_code) WHERE icd10_code IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_soap_plan_note ON public.soap_plan_items(soap_note_id);
CREATE INDEX IF NOT EXISTS idx_soap_plan_type ON public.soap_plan_items(soap_note_id, plan_type);
CREATE INDEX IF NOT EXISTS idx_soap_plan_status ON public.soap_plan_items(soap_note_id, status);

CREATE INDEX IF NOT EXISTS idx_soap_safety_note ON public.soap_safety_alerts(soap_note_id);
CREATE INDEX IF NOT EXISTS idx_soap_safety_severity ON public.soap_safety_alerts(soap_note_id, severity);

CREATE INDEX IF NOT EXISTS idx_soap_hpi_note ON public.soap_hpi_details(soap_note_id);

CREATE INDEX IF NOT EXISTS idx_soap_coding_note ON public.soap_coding_billing(soap_note_id);

-- Create Trigger to Update Updated_at Timestamp
CREATE OR REPLACE FUNCTION public.update_soap_notes_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.soap_notes
    SET updated_at = NOW()
    WHERE id = COALESCE(NEW.soap_note_id, OLD.soap_note_id);
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all child tables
CREATE TRIGGER soap_vital_signs_update_timestamp
AFTER INSERT OR UPDATE OR DELETE ON public.soap_vital_signs
FOR EACH ROW EXECUTE FUNCTION public.update_soap_notes_timestamp();

CREATE TRIGGER soap_ros_update_timestamp
AFTER INSERT OR UPDATE OR DELETE ON public.soap_review_of_systems
FOR EACH ROW EXECUTE FUNCTION public.update_soap_notes_timestamp();

CREATE TRIGGER soap_physical_exam_update_timestamp
AFTER INSERT OR UPDATE OR DELETE ON public.soap_physical_exam
FOR EACH ROW EXECUTE FUNCTION public.update_soap_notes_timestamp();

CREATE TRIGGER soap_history_items_update_timestamp
AFTER INSERT OR UPDATE OR DELETE ON public.soap_history_items
FOR EACH ROW EXECUTE FUNCTION public.update_soap_notes_timestamp();

CREATE TRIGGER soap_medications_update_timestamp
AFTER INSERT OR UPDATE OR DELETE ON public.soap_medications
FOR EACH ROW EXECUTE FUNCTION public.update_soap_notes_timestamp();

CREATE TRIGGER soap_allergies_update_timestamp
AFTER INSERT OR UPDATE OR DELETE ON public.soap_allergies
FOR EACH ROW EXECUTE FUNCTION public.update_soap_notes_timestamp();

CREATE TRIGGER soap_assessment_items_update_timestamp
AFTER INSERT OR UPDATE OR DELETE ON public.soap_assessment_items
FOR EACH ROW EXECUTE FUNCTION public.update_soap_notes_timestamp();

CREATE TRIGGER soap_plan_items_update_timestamp
AFTER INSERT OR UPDATE OR DELETE ON public.soap_plan_items
FOR EACH ROW EXECUTE FUNCTION public.update_soap_notes_timestamp();

CREATE TRIGGER soap_safety_alerts_update_timestamp
AFTER INSERT OR UPDATE OR DELETE ON public.soap_safety_alerts
FOR EACH ROW EXECUTE FUNCTION public.update_soap_notes_timestamp();

CREATE TRIGGER soap_hpi_details_update_timestamp
AFTER INSERT OR UPDATE OR DELETE ON public.soap_hpi_details
FOR EACH ROW EXECUTE FUNCTION public.update_soap_notes_timestamp();

CREATE TRIGGER soap_coding_billing_update_timestamp
AFTER INSERT OR UPDATE OR DELETE ON public.soap_coding_billing
FOR EACH ROW EXECUTE FUNCTION public.update_soap_notes_timestamp();
