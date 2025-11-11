-- Create infectious_disease_visits table for infectious disease management
-- Template: medzen-infectious-disease-encounter.v1

CREATE TABLE infectious_disease_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    visit_date TIMESTAMPTZ NOT NULL,
    disease_name VARCHAR(255) NOT NULL,
    disease_icd_code VARCHAR(50),
    disease_category VARCHAR(100), -- 'viral', 'bacterial', 'fungal', 'parasitic', 'hiv_aids', 'tuberculosis', 'malaria', 'tropical'

    -- Symptoms & Presentation
    symptom_onset_date DATE,
    symptoms TEXT[],
    fever_present BOOLEAN DEFAULT FALSE,
    highest_temperature_celsius REAL,

    -- Diagnostics
    rapid_test_results JSONB,
    lab_tests_performed TEXT[],
    culture_results TEXT,
    serology_results TEXT,
    pcr_results TEXT,
    imaging_findings TEXT,

    -- Treatment
    antimicrobials_prescribed TEXT[],
    antivirals_prescribed TEXT[],
    antifungals_prescribed TEXT[],
    antiparasitics_prescribed TEXT[],
    supportive_care TEXT[],

    -- HIV/AIDS Specific
    cd4_count INTEGER,
    viral_load INTEGER,
    art_regimen TEXT,
    on_prophylaxis BOOLEAN DEFAULT FALSE,
    prophylaxis_medications TEXT[],

    -- TB Specific
    tb_type VARCHAR(50), -- 'pulmonary', 'extrapulmonary', 'drug_resistant'
    dots_treatment BOOLEAN DEFAULT FALSE,
    treatment_phase VARCHAR(50), -- 'intensive', 'continuation'

    -- Malaria Specific
    parasite_species VARCHAR(100),
    parasitemia_level REAL,

    -- Infection Control
    isolation_required BOOLEAN DEFAULT FALSE,
    isolation_type VARCHAR(50),
    contact_tracing_done BOOLEAN DEFAULT FALSE,
    contacts_identified INTEGER,

    -- Outcome
    treatment_response VARCHAR(50), -- 'improving', 'stable', 'worsening', 'cured'
    complications TEXT[],
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

CREATE INDEX idx_infectious_disease_visits_patient ON infectious_disease_visits(patient_id);
CREATE INDEX idx_infectious_disease_visits_provider ON infectious_disease_visits(provider_id) WHERE provider_id IS NOT NULL;
CREATE INDEX idx_infectious_disease_visits_date ON infectious_disease_visits(visit_date DESC);
CREATE INDEX idx_infectious_disease_visits_disease ON infectious_disease_visits(disease_category);
CREATE INDEX idx_infectious_disease_visits_created ON infectious_disease_visits(created_at DESC);
CREATE INDEX idx_infectious_disease_visits_ehrbase ON infectious_disease_visits(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE infectious_disease_visits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_infectious_disease_visits_select" ON infectious_disease_visits FOR SELECT TO authenticated USING (patient_id::TEXT = auth.uid()::TEXT);
CREATE POLICY "provider_infectious_disease_visits_select" ON infectious_disease_visits FOR SELECT TO authenticated USING (patient_id IN (SELECT DISTINCT a.patient_id::uuid FROM appointments a JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id WHERE mpp.user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_infectious_disease_visits_insert" ON infectious_disease_visits FOR INSERT TO authenticated WITH CHECK (provider_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_infectious_disease_visits_update" ON infectious_disease_visits FOR UPDATE TO authenticated USING (provider_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "facility_admin_infectious_disease_visits_select" ON infectious_disease_visits FOR SELECT TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_infectious_disease_visits_all" ON infectious_disease_visits FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_infectious_disease_visits_for_sync() RETURNS TRIGGER AS $$ DECLARE v_ehr_id VARCHAR; BEGIN SELECT ehr_id INTO v_ehr_id FROM electronic_health_records WHERE patient_id = NEW.patient_id::TEXT; IF v_ehr_id IS NOT NULL THEN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('infectious_disease_visits', NEW.id::TEXT, 'medzen.infectious_disease_encounter.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_infectious_disease_visits_sync ON infectious_disease_visits;
CREATE TRIGGER trigger_queue_infectious_disease_visits_sync AFTER INSERT OR UPDATE ON infectious_disease_visits FOR EACH ROW EXECUTE FUNCTION queue_infectious_disease_visits_for_sync();
CREATE TRIGGER set_infectious_disease_visits_updated_at BEFORE UPDATE ON infectious_disease_visits FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
