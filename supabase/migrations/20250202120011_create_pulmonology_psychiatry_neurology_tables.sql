-- Create pulmonology, psychiatric, and neurology tables (MEDIUM priority)
-- Templates: medzen-pulmonology-encounter.v1, medzen-psychiatric-assessment.v1, medzen-neurology-examination.v1

-- Pulmonology Visits Table
CREATE TABLE pulmonology_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pulmonologist_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    visit_date TIMESTAMPTZ NOT NULL,
    chief_complaint TEXT,
    respiratory_symptoms TEXT[],

    -- Respiratory Conditions
    chronic_conditions TEXT[], -- ['asthma', 'copd', 'ild', 'sleep_apnea', 'pulmonary_hypertension']
    smoking_status VARCHAR(50), -- 'never', 'former', 'current'
    pack_years REAL,

    -- Examination
    respiratory_rate INTEGER,
    oxygen_saturation REAL,
    breath_sounds TEXT,
    use_of_accessory_muscles BOOLEAN DEFAULT FALSE,

    -- Investigations
    spirometry_results JSONB, -- {fev1, fvc, fev1_fvc_ratio, pef}
    chest_xray_findings TEXT,
    ct_scan_findings TEXT,
    arterial_blood_gas JSONB, -- {ph, pco2, po2, hco3, sao2}

    -- Treatment
    inhaler_therapy TEXT[],
    oxygen_therapy BOOLEAN DEFAULT FALSE,
    oxygen_flow_rate_lpm REAL,
    medications_prescribed TEXT[],
    pulmonary_rehabilitation_recommended BOOLEAN DEFAULT FALSE,

    next_follow_up_date DATE,
    notes TEXT,
    composition_id VARCHAR(255),
    ehrbase_synced BOOLEAN DEFAULT FALSE,
    ehrbase_synced_at TIMESTAMPTZ,
    ehrbase_sync_error TEXT,
    ehrbase_retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pulmonology_visits_patient ON pulmonology_visits(patient_id);
CREATE INDEX idx_pulmonology_visits_pulmonologist ON pulmonology_visits(pulmonologist_id) WHERE pulmonologist_id IS NOT NULL;
CREATE INDEX idx_pulmonology_visits_date ON pulmonology_visits(visit_date DESC);
CREATE INDEX idx_pulmonology_visits_ehrbase ON pulmonology_visits(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE pulmonology_visits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "patient_pulmonology_visits_select" ON pulmonology_visits FOR SELECT TO authenticated USING (patient_id::TEXT = auth.uid()::TEXT);
CREATE POLICY "provider_pulmonology_visits_select" ON pulmonology_visits FOR SELECT TO authenticated USING (patient_id IN (SELECT DISTINCT a.patient_id::uuid FROM appointments a JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id WHERE mpp.user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_pulmonology_visits_insert" ON pulmonology_visits FOR INSERT TO authenticated WITH CHECK (pulmonologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_pulmonology_visits_update" ON pulmonology_visits FOR UPDATE TO authenticated USING (pulmonologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "facility_admin_pulmonology_visits_select" ON pulmonology_visits FOR SELECT TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_pulmonology_visits_all" ON pulmonology_visits FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_pulmonology_visits_for_sync() RETURNS TRIGGER AS $$ DECLARE v_ehr_id VARCHAR; BEGIN SELECT ehr_id INTO v_ehr_id FROM electronic_health_records WHERE patient_id = NEW.patient_id::TEXT; IF v_ehr_id IS NOT NULL THEN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('pulmonology_visits', NEW.id::TEXT, 'medzen.pulmonology_encounter.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_pulmonology_visits_sync ON pulmonology_visits;
CREATE TRIGGER trigger_queue_pulmonology_visits_sync AFTER INSERT OR UPDATE ON pulmonology_visits FOR EACH ROW EXECUTE FUNCTION queue_pulmonology_visits_for_sync();
CREATE TRIGGER set_pulmonology_visits_updated_at BEFORE UPDATE ON pulmonology_visits FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

-- ========================================
-- Psychiatric Assessments Table
-- ========================================

CREATE TABLE psychiatric_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    psychiatrist_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    assessment_date TIMESTAMPTZ NOT NULL,
    assessment_type VARCHAR(100), -- 'initial', 'follow-up', 'crisis', 'medication_review'
    chief_complaint TEXT,

    -- Mental Status Examination
    appearance TEXT,
    behavior TEXT,
    speech TEXT,
    mood VARCHAR(100),
    affect VARCHAR(100),
    thought_process TEXT,
    thought_content TEXT,
    perceptions TEXT, -- hallucinations, delusions
    cognition TEXT,
    insight VARCHAR(50), -- 'good', 'fair', 'poor', 'absent'
    judgment VARCHAR(50), -- 'good', 'fair', 'poor'

    -- Risk Assessment
    suicide_risk VARCHAR(20), -- 'none', 'low', 'moderate', 'high'
    homicide_risk VARCHAR(20),
    self_harm_risk VARCHAR(20),
    risk_factors TEXT[],
    protective_factors TEXT[],

    -- Diagnoses
    psychiatric_diagnoses TEXT[],
    dsm_v_codes TEXT[],
    icd_codes TEXT[],

    -- Screening Scales
    phq9_score INTEGER, -- Depression screening (0-27)
    gad7_score INTEGER, -- Anxiety screening (0-21)
    mood_disorder_questionnaire_positive BOOLEAN,

    -- Treatment Plan
    psychotherapy_type VARCHAR(100), -- 'CBT', 'DBT', 'psychodynamic', 'supportive'
    medications_prescribed TEXT[],
    hospitalization_recommended BOOLEAN DEFAULT FALSE,
    safety_plan TEXT,

    next_appointment_date DATE,
    notes TEXT,
    composition_id VARCHAR(255),
    ehrbase_synced BOOLEAN DEFAULT FALSE,
    ehrbase_synced_at TIMESTAMPTZ,
    ehrbase_sync_error TEXT,
    ehrbase_retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_phq9 CHECK (phq9_score BETWEEN 0 AND 27),
    CONSTRAINT valid_gad7 CHECK (gad7_score BETWEEN 0 AND 21)
);

CREATE INDEX idx_psychiatric_assessments_patient ON psychiatric_assessments(patient_id);
CREATE INDEX idx_psychiatric_assessments_psychiatrist ON psychiatric_assessments(psychiatrist_id) WHERE psychiatrist_id IS NOT NULL;
CREATE INDEX idx_psychiatric_assessments_date ON psychiatric_assessments(assessment_date DESC);
CREATE INDEX idx_psychiatric_assessments_ehrbase ON psychiatric_assessments(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE psychiatric_assessments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "patient_psychiatric_assessments_select" ON psychiatric_assessments FOR SELECT TO authenticated USING (patient_id::TEXT = auth.uid()::TEXT);
CREATE POLICY "provider_psychiatric_assessments_select" ON psychiatric_assessments FOR SELECT TO authenticated USING (patient_id IN (SELECT DISTINCT a.patient_id::uuid FROM appointments a JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id WHERE mpp.user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_psychiatric_assessments_insert" ON psychiatric_assessments FOR INSERT TO authenticated WITH CHECK (psychiatrist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_psychiatric_assessments_update" ON psychiatric_assessments FOR UPDATE TO authenticated USING (psychiatrist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "facility_admin_psychiatric_assessments_select" ON psychiatric_assessments FOR SELECT TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_psychiatric_assessments_all" ON psychiatric_assessments FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_psychiatric_assessments_for_sync() RETURNS TRIGGER AS $$ DECLARE v_ehr_id VARCHAR; BEGIN SELECT ehr_id INTO v_ehr_id FROM electronic_health_records WHERE patient_id = NEW.patient_id::TEXT; IF v_ehr_id IS NOT NULL THEN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('psychiatric_assessments', NEW.id::TEXT, 'medzen.psychiatric_assessment.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_psychiatric_assessments_sync ON psychiatric_assessments;
CREATE TRIGGER trigger_queue_psychiatric_assessments_sync AFTER INSERT OR UPDATE ON psychiatric_assessments FOR EACH ROW EXECUTE FUNCTION queue_psychiatric_assessments_for_sync();
CREATE TRIGGER set_psychiatric_assessments_updated_at BEFORE UPDATE ON psychiatric_assessments FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

-- ========================================
-- Neurology Examinations Table
-- ========================================

CREATE TABLE neurology_exams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    neurologist_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    exam_date TIMESTAMPTZ NOT NULL,
    chief_complaint TEXT,
    neurological_symptoms TEXT[],

    -- Neurological History
    neurological_conditions TEXT[], -- ['stroke', 'epilepsy', 'parkinsons', 'ms', 'migraine']
    seizure_history BOOLEAN DEFAULT FALSE,
    last_seizure_date DATE,
    seizure_frequency VARCHAR(100),

    -- Neurological Examination
    glasgow_coma_score INTEGER,
    mental_status TEXT,
    cranial_nerves TEXT,
    motor_examination TEXT,
    sensory_examination TEXT,
    reflexes TEXT,
    coordination TEXT,
    gait TEXT,

    -- Investigations
    eeg_results TEXT,
    mri_findings TEXT,
    ct_findings TEXT,
    nerve_conduction_studies TEXT,
    lumbar_puncture_results TEXT,

    -- Diagnoses
    diagnoses TEXT[],
    stroke_type VARCHAR(50), -- 'ischemic', 'hemorrhagic'
    nihss_score INTEGER, -- NIH Stroke Scale (0-42)

    -- Treatment
    medications_prescribed TEXT[],
    rehabilitation_recommended BOOLEAN DEFAULT FALSE,
    neurosurgery_consulted BOOLEAN DEFAULT FALSE,

    next_follow_up_date DATE,
    notes TEXT,
    composition_id VARCHAR(255),
    ehrbase_synced BOOLEAN DEFAULT FALSE,
    ehrbase_synced_at TIMESTAMPTZ,
    ehrbase_sync_error TEXT,
    ehrbase_retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_gcs_neuro CHECK (glasgow_coma_score BETWEEN 3 AND 15),
    CONSTRAINT valid_nihss CHECK (nihss_score BETWEEN 0 AND 42)
);

CREATE INDEX idx_neurology_exams_patient ON neurology_exams(patient_id);
CREATE INDEX idx_neurology_exams_neurologist ON neurology_exams(neurologist_id) WHERE neurologist_id IS NOT NULL;
CREATE INDEX idx_neurology_exams_date ON neurology_exams(exam_date DESC);
CREATE INDEX idx_neurology_exams_ehrbase ON neurology_exams(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE neurology_exams ENABLE ROW LEVEL SECURITY;
CREATE POLICY "patient_neurology_exams_select" ON neurology_exams FOR SELECT TO authenticated USING (patient_id::TEXT = auth.uid()::TEXT);
CREATE POLICY "provider_neurology_exams_select" ON neurology_exams FOR SELECT TO authenticated USING (patient_id IN (SELECT DISTINCT a.patient_id::uuid FROM appointments a JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id WHERE mpp.user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_neurology_exams_insert" ON neurology_exams FOR INSERT TO authenticated WITH CHECK (neurologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_neurology_exams_update" ON neurology_exams FOR UPDATE TO authenticated USING (neurologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "facility_admin_neurology_exams_select" ON neurology_exams FOR SELECT TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_neurology_exams_all" ON neurology_exams FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_neurology_exams_for_sync() RETURNS TRIGGER AS $$ DECLARE v_ehr_id VARCHAR; BEGIN SELECT ehr_id INTO v_ehr_id FROM electronic_health_records WHERE patient_id = NEW.patient_id::TEXT; IF v_ehr_id IS NOT NULL THEN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('neurology_exams', NEW.id::TEXT, 'medzen.neurology_examination.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_neurology_exams_sync ON neurology_exams;
CREATE TRIGGER trigger_queue_neurology_exams_sync AFTER INSERT OR UPDATE ON neurology_exams FOR EACH ROW EXECUTE FUNCTION queue_neurology_exams_for_sync();
CREATE TRIGGER set_neurology_exams_updated_at BEFORE UPDATE ON neurology_exams FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
