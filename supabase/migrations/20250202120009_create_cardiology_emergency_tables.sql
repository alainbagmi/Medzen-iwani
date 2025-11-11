-- Create cardiology_visits and emergency_visits tables (HIGH priority specialty tables)
-- Templates: medzen-cardiology-encounter.v1, medzen-emergency-medicine-encounter.v1

-- Cardiology Visits Table
CREATE TABLE cardiology_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    cardiologist_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    visit_date TIMESTAMPTZ NOT NULL,
    visit_type VARCHAR(100), -- 'initial', 'follow-up', 'acute', 'post-procedure'
    chief_complaint TEXT,

    -- Cardiovascular History
    cardiac_history TEXT[],
    risk_factors TEXT[], -- ['hypertension', 'diabetes', 'smoking', 'family_history']
    current_medications TEXT[],

    -- Examination
    heart_rate INTEGER,
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,
    cardiac_rhythm VARCHAR(50), -- 'regular', 'irregular', 'atrial_fibrillation'
    heart_sounds TEXT,
    murmurs TEXT,

    -- Investigations
    ecg_findings TEXT,
    ecg_interpretation VARCHAR(255),
    echocardiogram_findings TEXT,
    ejection_fraction_percent REAL,
    stress_test_results TEXT,
    cardiac_biomarkers JSONB, -- {"troponin": "0.05", "bnp": "150"}
    imaging_results TEXT,

    -- Diagnosis
    diagnoses TEXT[],
    nyha_class INTEGER, -- 1-4 for heart failure classification

    -- Treatment Plan
    medications_prescribed TEXT[],
    lifestyle_modifications TEXT[],
    procedures_recommended TEXT[],
    procedure_scheduled BOOLEAN DEFAULT FALSE,
    next_follow_up_date DATE,

    notes TEXT,

    composition_id VARCHAR(255),
    ehrbase_synced BOOLEAN DEFAULT FALSE,
    ehrbase_synced_at TIMESTAMPTZ,
    ehrbase_sync_error TEXT,
    ehrbase_retry_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_nyha CHECK (nyha_class BETWEEN 1 AND 4),
    CONSTRAINT valid_ejection_fraction CHECK (ejection_fraction_percent BETWEEN 0 AND 100)
);

CREATE INDEX idx_cardiology_visits_patient ON cardiology_visits(patient_id);
CREATE INDEX idx_cardiology_visits_cardiologist ON cardiology_visits(cardiologist_id) WHERE cardiologist_id IS NOT NULL;
CREATE INDEX idx_cardiology_visits_date ON cardiology_visits(visit_date DESC);
CREATE INDEX idx_cardiology_visits_ehrbase ON cardiology_visits(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE cardiology_visits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_cardiology_visits_select" ON cardiology_visits FOR SELECT TO authenticated USING (patient_id::TEXT = auth.uid()::TEXT);
CREATE POLICY "provider_cardiology_visits_select" ON cardiology_visits FOR SELECT TO authenticated USING (patient_id IN (SELECT DISTINCT a.patient_id::uuid FROM appointments a JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id WHERE mpp.user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_cardiology_visits_insert" ON cardiology_visits FOR INSERT TO authenticated WITH CHECK (cardiologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_cardiology_visits_update" ON cardiology_visits FOR UPDATE TO authenticated USING (cardiologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "facility_admin_cardiology_visits_select" ON cardiology_visits FOR SELECT TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_cardiology_visits_all" ON cardiology_visits FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_cardiology_visits_for_sync() RETURNS TRIGGER AS $$ DECLARE v_ehr_id VARCHAR; BEGIN SELECT ehr_id INTO v_ehr_id FROM electronic_health_records WHERE patient_id = NEW.patient_id::TEXT; IF v_ehr_id IS NOT NULL THEN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('cardiology_visits', NEW.id::TEXT, 'medzen.cardiology_encounter.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_cardiology_visits_sync ON cardiology_visits;
CREATE TRIGGER trigger_queue_cardiology_visits_sync AFTER INSERT OR UPDATE ON cardiology_visits FOR EACH ROW EXECUTE FUNCTION queue_cardiology_visits_for_sync();
CREATE TRIGGER set_cardiology_visits_updated_at BEFORE UPDATE ON cardiology_visits FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

-- ========================================
-- Emergency Visits Table
-- ========================================

CREATE TABLE emergency_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emergency_physician_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    arrival_time TIMESTAMPTZ NOT NULL,
    departure_time TIMESTAMPTZ,
    length_of_stay_minutes INTEGER,

    -- Triage
    triage_category VARCHAR(20), -- 'P1_critical', 'P2_emergency', 'P3_urgent', 'P4_semi_urgent', 'P5_non_urgent'
    triage_time TIMESTAMPTZ,
    chief_complaint TEXT NOT NULL,
    mode_of_arrival VARCHAR(50), -- 'walk-in', 'ambulance', 'police', 'transfer'

    -- Initial Assessment
    initial_vital_signs JSONB,
    glasgow_coma_score INTEGER,
    pain_score INTEGER, -- 0-10
    trauma BOOLEAN DEFAULT FALSE,
    mechanism_of_injury TEXT,

    -- Resuscitation
    resuscitation_performed BOOLEAN DEFAULT FALSE,
    cpr_performed BOOLEAN DEFAULT FALSE,
    defibrillation_performed BOOLEAN DEFAULT FALSE,
    airway_management VARCHAR(100),
    fluids_administered_ml INTEGER,
    blood_products_given BOOLEAN DEFAULT FALSE,

    -- Diagnostics
    lab_tests_ordered TEXT[],
    imaging_performed TEXT[],
    procedures_performed TEXT[],

    -- Diagnosis & Treatment
    emergency_diagnosis TEXT[],
    medications_administered TEXT[],
    interventions TEXT[],

    -- Disposition
    disposition VARCHAR(100), -- 'admitted', 'discharged', 'transferred', 'left_ama', 'deceased'
    admitted_to_ward VARCHAR(100),
    discharge_instructions TEXT,

    notes TEXT,

    composition_id VARCHAR(255),
    ehrbase_synced BOOLEAN DEFAULT FALSE,
    ehrbase_synced_at TIMESTAMPTZ,
    ehrbase_sync_error TEXT,
    ehrbase_retry_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_gcs CHECK (glasgow_coma_score BETWEEN 3 AND 15),
    CONSTRAINT valid_pain_score CHECK (pain_score BETWEEN 0 AND 10)
);

CREATE INDEX idx_emergency_visits_patient ON emergency_visits(patient_id);
CREATE INDEX idx_emergency_visits_physician ON emergency_visits(emergency_physician_id) WHERE emergency_physician_id IS NOT NULL;
CREATE INDEX idx_emergency_visits_arrival ON emergency_visits(arrival_time DESC);
CREATE INDEX idx_emergency_visits_triage ON emergency_visits(triage_category);
CREATE INDEX idx_emergency_visits_ehrbase ON emergency_visits(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE emergency_visits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_emergency_visits_select" ON emergency_visits FOR SELECT TO authenticated USING (patient_id::TEXT = auth.uid()::TEXT);
CREATE POLICY "provider_emergency_visits_select" ON emergency_visits FOR SELECT TO authenticated USING (patient_id IN (SELECT DISTINCT a.patient_id::uuid FROM appointments a JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id WHERE mpp.user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_emergency_visits_insert" ON emergency_visits FOR INSERT TO authenticated WITH CHECK (emergency_physician_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_emergency_visits_update" ON emergency_visits FOR UPDATE TO authenticated USING (emergency_physician_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "facility_admin_emergency_visits_select" ON emergency_visits FOR SELECT TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_emergency_visits_all" ON emergency_visits FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_emergency_visits_for_sync() RETURNS TRIGGER AS $$ DECLARE v_ehr_id VARCHAR; BEGIN SELECT ehr_id INTO v_ehr_id FROM electronic_health_records WHERE patient_id = NEW.patient_id::TEXT; IF v_ehr_id IS NOT NULL THEN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('emergency_visits', NEW.id::TEXT, 'medzen.emergency_medicine_encounter.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_emergency_visits_sync ON emergency_visits;
CREATE TRIGGER trigger_queue_emergency_visits_sync AFTER INSERT OR UPDATE ON emergency_visits FOR EACH ROW EXECUTE FUNCTION queue_emergency_visits_for_sync();
CREATE TRIGGER set_emergency_visits_updated_at BEFORE UPDATE ON emergency_visits FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
