-- Create oncology_treatments table for cancer treatment management
-- Template: medzen-oncology-treatment-plan.v1

CREATE TABLE oncology_treatments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    oncologist_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    -- Cancer Diagnosis
    cancer_type VARCHAR(255) NOT NULL,
    cancer_icd_code VARCHAR(50),
    primary_site VARCHAR(255),
    histology VARCHAR(255),
    diagnosis_date DATE NOT NULL,

    -- Staging
    tnm_staging VARCHAR(50), -- e.g., 'T2N1M0'
    clinical_stage VARCHAR(10), -- 'I', 'II', 'III', 'IV'
    grade VARCHAR(10), -- '1', '2', '3', 'well differentiated', 'poorly differentiated'

    -- Treatment Plan
    treatment_intent VARCHAR(50), -- 'curative', 'palliative', 'adjuvant', 'neoadjuvant'
    treatment_modalities TEXT[], -- ['chemotherapy', 'radiation', 'surgery', 'immunotherapy']
    treatment_protocol VARCHAR(255),
    treatment_start_date DATE,
    expected_end_date DATE,

    -- Chemotherapy Details
    chemotherapy_regimen VARCHAR(255),
    cycle_number INTEGER,
    total_cycles_planned INTEGER,
    current_cycle_start_date DATE,
    chemotherapy_drugs TEXT[],

    -- Radiation Details
    radiation_site VARCHAR(255),
    total_dose_gy DECIMAL(10,2),
    fractions_completed INTEGER,
    total_fractions_planned INTEGER,

    -- Performance Status
    ecog_performance_status INTEGER, -- 0-5 scale
    karnofsky_score INTEGER, -- 0-100 scale

    -- Response Assessment
    response_to_treatment VARCHAR(50), -- 'complete_response', 'partial_response', 'stable_disease', 'progressive_disease'
    tumor_markers JSONB, -- e.g., {"CEA": "5.2", "CA-125": "35"}
    imaging_results TEXT,

    -- Side Effects & Complications
    side_effects TEXT[],
    complications TEXT[],
    supportive_care_needed TEXT[],

    -- Follow-up
    next_treatment_date DATE,
    next_imaging_date DATE,
    follow_up_instructions TEXT,

    notes TEXT,

    composition_id VARCHAR(255),
    ehrbase_synced BOOLEAN DEFAULT FALSE,
    ehrbase_synced_at TIMESTAMPTZ,
    ehrbase_sync_error TEXT,
    ehrbase_retry_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_ecog CHECK (ecog_performance_status BETWEEN 0 AND 5),
    CONSTRAINT valid_karnofsky CHECK (karnofsky_score BETWEEN 0 AND 100),
    CONSTRAINT valid_cycle CHECK (cycle_number > 0)
);

CREATE INDEX idx_oncology_treatments_patient ON oncology_treatments(patient_id);
CREATE INDEX idx_oncology_treatments_oncologist ON oncology_treatments(oncologist_id) WHERE oncologist_id IS NOT NULL;
CREATE INDEX idx_oncology_treatments_diagnosis_date ON oncology_treatments(diagnosis_date DESC);
CREATE INDEX idx_oncology_treatments_created ON oncology_treatments(created_at DESC);
CREATE INDEX idx_oncology_treatments_ehrbase ON oncology_treatments(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE oncology_treatments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_oncology_treatments_select" ON oncology_treatments FOR SELECT TO authenticated USING (patient_id::TEXT = auth.uid()::TEXT);
CREATE POLICY "provider_oncology_treatments_select" ON oncology_treatments FOR SELECT TO authenticated USING (patient_id IN (SELECT DISTINCT a.patient_id::uuid FROM appointments a JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id WHERE mpp.user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_oncology_treatments_insert" ON oncology_treatments FOR INSERT TO authenticated WITH CHECK (oncologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_oncology_treatments_update" ON oncology_treatments FOR UPDATE TO authenticated USING (oncologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "facility_admin_oncology_treatments_select" ON oncology_treatments FOR SELECT TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_oncology_treatments_all" ON oncology_treatments FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_oncology_treatments_for_sync() RETURNS TRIGGER AS $$ DECLARE v_ehr_id VARCHAR; BEGIN SELECT ehr_id INTO v_ehr_id FROM electronic_health_records WHERE patient_id = NEW.patient_id::TEXT; IF v_ehr_id IS NOT NULL THEN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('oncology_treatments', NEW.id::TEXT, 'medzen.oncology_treatment_plan.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_oncology_treatments_sync ON oncology_treatments;
CREATE TRIGGER trigger_queue_oncology_treatments_sync AFTER INSERT OR UPDATE ON oncology_treatments FOR EACH ROW EXECUTE FUNCTION queue_oncology_treatments_for_sync();
CREATE TRIGGER set_oncology_treatments_updated_at BEFORE UPDATE ON oncology_treatments FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
