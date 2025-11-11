-- Create radiology, pathology, and physiotherapy tables (Diagnostic & Support)
-- Templates: medzen-radiology-report.v1, medzen-pathology-report.v1, medzen-physiotherapy-session.v1

-- Radiology Reports Table
CREATE TABLE radiology_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    radiologist_id UUID REFERENCES medical_provider_profiles(id),
    ordering_provider_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    exam_date TIMESTAMPTZ NOT NULL,
    modality VARCHAR(50) NOT NULL, -- 'X-ray', 'CT', 'MRI', 'Ultrasound', 'Mammography', 'PET', 'Nuclear_Medicine'
    body_part VARCHAR(255) NOT NULL,
    indication TEXT NOT NULL,
    technique TEXT,

    -- Findings
    findings TEXT NOT NULL,
    impressions TEXT NOT NULL,
    comparison_studies TEXT,
    recommendations TEXT,

    -- Technical Details
    contrast_used BOOLEAN DEFAULT FALSE,
    contrast_type VARCHAR(100),
    radiation_dose_mgy REAL,
    number_of_images INTEGER,

    -- Critical Results
    critical_finding BOOLEAN DEFAULT FALSE,
    critical_finding_communicated BOOLEAN DEFAULT FALSE,
    communicated_to VARCHAR(255),
    communication_time TIMESTAMPTZ,

    -- PACS Integration
    pacs_accession_number VARCHAR(100),
    pacs_study_instance_uid VARCHAR(255),
    dicom_series_urls TEXT[],

    -- Follow-up
    follow_up_recommended BOOLEAN DEFAULT FALSE,
    follow_up_timeframe VARCHAR(100),

    report_status VARCHAR(50) DEFAULT 'preliminary', -- 'preliminary', 'final', 'amended', 'addendum'
    report_finalized_at TIMESTAMPTZ,

    notes TEXT,
    composition_id VARCHAR(255),
    ehrbase_synced BOOLEAN DEFAULT FALSE,
    ehrbase_synced_at TIMESTAMPTZ,
    ehrbase_sync_error TEXT,
    ehrbase_retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_radiology_reports_patient ON radiology_reports(patient_id);
CREATE INDEX idx_radiology_reports_radiologist ON radiology_reports(radiologist_id) WHERE radiologist_id IS NOT NULL;
CREATE INDEX idx_radiology_reports_ordering_provider ON radiology_reports(ordering_provider_id) WHERE ordering_provider_id IS NOT NULL;
CREATE INDEX idx_radiology_reports_exam_date ON radiology_reports(exam_date DESC);
CREATE INDEX idx_radiology_reports_modality ON radiology_reports(modality);
CREATE INDEX idx_radiology_reports_critical ON radiology_reports(critical_finding) WHERE critical_finding = TRUE;
CREATE INDEX idx_radiology_reports_ehrbase ON radiology_reports(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE radiology_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "patient_radiology_reports_select" ON radiology_reports FOR SELECT TO authenticated USING (patient_id::TEXT = auth.uid()::TEXT);
CREATE POLICY "provider_radiology_reports_select" ON radiology_reports FOR SELECT TO authenticated USING (patient_id IN (SELECT DISTINCT a.patient_id::uuid FROM appointments a JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id WHERE mpp.user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_radiology_reports_insert" ON radiology_reports FOR INSERT TO authenticated WITH CHECK (radiologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT) OR ordering_provider_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_radiology_reports_update" ON radiology_reports FOR UPDATE TO authenticated USING (radiologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "facility_admin_radiology_reports_select" ON radiology_reports FOR SELECT TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_radiology_reports_all" ON radiology_reports FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_radiology_reports_for_sync() RETURNS TRIGGER AS $$ DECLARE v_ehr_id VARCHAR; BEGIN SELECT ehr_id INTO v_ehr_id FROM electronic_health_records WHERE patient_id = NEW.patient_id::TEXT; IF v_ehr_id IS NOT NULL THEN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('radiology_reports', NEW.id::TEXT, 'medzen.radiology_report.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_radiology_reports_sync ON radiology_reports;
CREATE TRIGGER trigger_queue_radiology_reports_sync AFTER INSERT OR UPDATE ON radiology_reports FOR EACH ROW EXECUTE FUNCTION queue_radiology_reports_for_sync();
CREATE TRIGGER set_radiology_reports_updated_at BEFORE UPDATE ON radiology_reports FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

-- ========================================
-- Pathology Reports Table
-- ========================================

CREATE TABLE pathology_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pathologist_id UUID REFERENCES medical_provider_profiles(id),
    ordering_provider_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    collection_date TIMESTAMPTZ NOT NULL,
    received_date TIMESTAMPTZ,
    report_date TIMESTAMPTZ,

    -- Specimen Information
    specimen_type VARCHAR(255) NOT NULL, -- 'biopsy', 'fine_needle_aspiration', 'surgical_resection', 'cytology'
    specimen_site VARCHAR(255) NOT NULL,
    specimen_id VARCHAR(100),
    number_of_specimens INTEGER DEFAULT 1,

    -- Clinical Information
    clinical_history TEXT,
    indication TEXT NOT NULL,
    procedure_type VARCHAR(255),

    -- Gross Description
    gross_description TEXT,

    -- Microscopic Findings
    microscopic_description TEXT NOT NULL,

    -- Diagnosis
    diagnosis TEXT NOT NULL,
    diagnosis_codes TEXT[], -- SNOMED codes
    histological_type VARCHAR(255),
    grade VARCHAR(50), -- 'well_differentiated', 'moderately_differentiated', 'poorly_differentiated'
    stage VARCHAR(50),

    -- Cancer-Specific
    tumor_size_cm REAL,
    margins_status VARCHAR(100), -- 'clear', 'involved', 'close'
    lymph_nodes_examined INTEGER,
    lymph_nodes_positive INTEGER,
    immunohistochemistry_results JSONB,
    molecular_markers JSONB,

    -- Special Stains
    special_stains_performed TEXT[],
    special_stains_results TEXT,

    -- Final Report
    final_diagnosis TEXT,
    recommendations TEXT,
    additional_comments TEXT,

    report_status VARCHAR(50) DEFAULT 'preliminary', -- 'preliminary', 'final', 'amended', 'addendum'
    report_finalized_at TIMESTAMPTZ,

    notes TEXT,
    composition_id VARCHAR(255),
    ehrbase_synced BOOLEAN DEFAULT FALSE,
    ehrbase_synced_at TIMESTAMPTZ,
    ehrbase_sync_error TEXT,
    ehrbase_retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pathology_reports_patient ON pathology_reports(patient_id);
CREATE INDEX idx_pathology_reports_pathologist ON pathology_reports(pathologist_id) WHERE pathologist_id IS NOT NULL;
CREATE INDEX idx_pathology_reports_collection_date ON pathology_reports(collection_date DESC);
CREATE INDEX idx_pathology_reports_specimen_type ON pathology_reports(specimen_type);
CREATE INDEX idx_pathology_reports_ehrbase ON pathology_reports(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE pathology_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "patient_pathology_reports_select" ON pathology_reports FOR SELECT TO authenticated USING (patient_id::TEXT = auth.uid()::TEXT);
CREATE POLICY "provider_pathology_reports_select" ON pathology_reports FOR SELECT TO authenticated USING (patient_id IN (SELECT DISTINCT a.patient_id::uuid FROM appointments a JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id WHERE mpp.user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_pathology_reports_insert" ON pathology_reports FOR INSERT TO authenticated WITH CHECK (pathologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT) OR ordering_provider_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_pathology_reports_update" ON pathology_reports FOR UPDATE TO authenticated USING (pathologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "facility_admin_pathology_reports_select" ON pathology_reports FOR SELECT TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_pathology_reports_all" ON pathology_reports FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_pathology_reports_for_sync() RETURNS TRIGGER AS $$ DECLARE v_ehr_id VARCHAR; BEGIN SELECT ehr_id INTO v_ehr_id FROM electronic_health_records WHERE patient_id = NEW.patient_id::TEXT; IF v_ehr_id IS NOT NULL THEN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('pathology_reports', NEW.id::TEXT, 'medzen.pathology_report.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_pathology_reports_sync ON pathology_reports;
CREATE TRIGGER trigger_queue_pathology_reports_sync AFTER INSERT OR UPDATE ON pathology_reports FOR EACH ROW EXECUTE FUNCTION queue_pathology_reports_for_sync();
CREATE TRIGGER set_pathology_reports_updated_at BEFORE UPDATE ON pathology_reports FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

-- ========================================
-- Physiotherapy Sessions Table
-- ========================================

CREATE TABLE physiotherapy_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    physiotherapist_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    session_date TIMESTAMPTZ NOT NULL,
    session_number INTEGER,
    session_duration_minutes INTEGER,

    -- Referral Information
    referring_condition VARCHAR(255), -- 'post_surgery', 'sports_injury', 'chronic_pain', 'neurological'
    referral_diagnosis TEXT,
    treatment_goals TEXT[],

    -- Assessment
    subjective_assessment TEXT, -- Patient's report
    objective_findings TEXT,
    pain_level INTEGER, -- 0-10 scale
    pain_location TEXT,

    -- Functional Assessment
    range_of_motion JSONB, -- Joint-specific measurements
    muscle_strength JSONB, -- Muscle groups and grades (0-5 scale)
    balance_assessment TEXT,
    gait_assessment TEXT,
    functional_mobility_score INTEGER,

    -- Treatment Provided
    modalities_used TEXT[], -- ['manual_therapy', 'exercise', 'electrotherapy', 'heat', 'ice']
    exercises_prescribed TEXT[],
    home_exercise_program TEXT,
    equipment_used TEXT[],

    -- Progress
    progress_notes TEXT,
    functional_improvements TEXT,
    barriers_to_progress TEXT[],

    -- Plan
    next_session_date DATE,
    sessions_remaining INTEGER,
    discharge_planned BOOLEAN DEFAULT FALSE,
    discharge_criteria TEXT,

    notes TEXT,
    composition_id VARCHAR(255),
    ehrbase_synced BOOLEAN DEFAULT FALSE,
    ehrbase_synced_at TIMESTAMPTZ,
    ehrbase_sync_error TEXT,
    ehrbase_retry_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_pain_level CHECK (pain_level BETWEEN 0 AND 10),
    CONSTRAINT valid_session_duration CHECK (session_duration_minutes > 0)
);

CREATE INDEX idx_physiotherapy_sessions_patient ON physiotherapy_sessions(patient_id);
CREATE INDEX idx_physiotherapy_sessions_physiotherapist ON physiotherapy_sessions(physiotherapist_id) WHERE physiotherapist_id IS NOT NULL;
CREATE INDEX idx_physiotherapy_sessions_date ON physiotherapy_sessions(session_date DESC);
CREATE INDEX idx_physiotherapy_sessions_ehrbase ON physiotherapy_sessions(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE physiotherapy_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "patient_physiotherapy_sessions_select" ON physiotherapy_sessions FOR SELECT TO authenticated USING (patient_id::TEXT = auth.uid()::TEXT);
CREATE POLICY "provider_physiotherapy_sessions_select" ON physiotherapy_sessions FOR SELECT TO authenticated USING (patient_id IN (SELECT DISTINCT a.patient_id::uuid FROM appointments a JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id WHERE mpp.user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_physiotherapy_sessions_insert" ON physiotherapy_sessions FOR INSERT TO authenticated WITH CHECK (physiotherapist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_physiotherapy_sessions_update" ON physiotherapy_sessions FOR UPDATE TO authenticated USING (physiotherapist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "facility_admin_physiotherapy_sessions_select" ON physiotherapy_sessions FOR SELECT TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_physiotherapy_sessions_all" ON physiotherapy_sessions FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_physiotherapy_sessions_for_sync() RETURNS TRIGGER AS $$ DECLARE v_ehr_id VARCHAR; BEGIN SELECT ehr_id INTO v_ehr_id FROM electronic_health_records WHERE patient_id = NEW.patient_id::TEXT; IF v_ehr_id IS NOT NULL THEN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('physiotherapy_sessions', NEW.id::TEXT, 'medzen.physiotherapy_session.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_physiotherapy_sessions_sync ON physiotherapy_sessions;
CREATE TRIGGER trigger_queue_physiotherapy_sessions_sync AFTER INSERT OR UPDATE ON physiotherapy_sessions FOR EACH ROW EXECUTE FUNCTION queue_physiotherapy_sessions_for_sync();
CREATE TRIGGER set_physiotherapy_sessions_updated_at BEFORE UPDATE ON physiotherapy_sessions FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
