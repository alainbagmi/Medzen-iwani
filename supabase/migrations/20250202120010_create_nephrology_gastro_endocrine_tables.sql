-- Create nephrology, gastroenterology, and endocrinology tables (MEDIUM priority)
-- Templates: medzen-nephrology-encounter.v1, medzen-gastroenterology-procedures.v1, medzen-endocrinology-management.v1

-- Nephrology Visits Table
CREATE TABLE nephrology_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    nephrologist_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    visit_date TIMESTAMPTZ NOT NULL,
    ckd_stage VARCHAR(10), -- 'Stage_1', 'Stage_2', 'Stage_3a', 'Stage_3b', 'Stage_4', 'Stage_5'
    egfr_value REAL,
    creatinine_mg_dl REAL,
    bun_mg_dl REAL,
    proteinuria_g_day REAL,
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,

    -- Dialysis Information
    on_dialysis BOOLEAN DEFAULT FALSE,
    dialysis_type VARCHAR(50), -- 'hemodialysis', 'peritoneal_dialysis'
    dialysis_frequency VARCHAR(100),
    vascular_access_type VARCHAR(100),
    dialysis_adequacy_kt_v REAL,

    -- Transplant
    transplant_candidate BOOLEAN DEFAULT FALSE,
    post_transplant BOOLEAN DEFAULT FALSE,
    transplant_date DATE,
    immunosuppression_regimen TEXT[],

    diagnoses TEXT[],
    treatment_plan TEXT,
    medications_prescribed TEXT[],
    next_dialysis_date DATE,
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

CREATE INDEX idx_nephrology_visits_patient ON nephrology_visits(patient_id);
CREATE INDEX idx_nephrology_visits_nephrologist ON nephrology_visits(nephrologist_id) WHERE nephrologist_id IS NOT NULL;
CREATE INDEX idx_nephrology_visits_date ON nephrology_visits(visit_date DESC);
CREATE INDEX idx_nephrology_visits_ehrbase ON nephrology_visits(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE nephrology_visits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "patient_nephrology_visits_select" ON nephrology_visits FOR SELECT TO authenticated USING (patient_id::TEXT = auth.uid()::TEXT);
CREATE POLICY "provider_nephrology_visits_select" ON nephrology_visits FOR SELECT TO authenticated USING (patient_id IN (SELECT DISTINCT a.patient_id::uuid FROM appointments a JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id WHERE mpp.user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_nephrology_visits_insert" ON nephrology_visits FOR INSERT TO authenticated WITH CHECK (nephrologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_nephrology_visits_update" ON nephrology_visits FOR UPDATE TO authenticated USING (nephrologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "facility_admin_nephrology_visits_select" ON nephrology_visits FOR SELECT TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_nephrology_visits_all" ON nephrology_visits FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_nephrology_visits_for_sync() RETURNS TRIGGER AS $$ DECLARE v_ehr_id VARCHAR; BEGIN SELECT ehr_id INTO v_ehr_id FROM electronic_health_records WHERE patient_id = NEW.patient_id::TEXT; IF v_ehr_id IS NOT NULL THEN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('nephrology_visits', NEW.id::TEXT, 'medzen.nephrology_encounter.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_nephrology_visits_sync ON nephrology_visits;
CREATE TRIGGER trigger_queue_nephrology_visits_sync AFTER INSERT OR UPDATE ON nephrology_visits FOR EACH ROW EXECUTE FUNCTION queue_nephrology_visits_for_sync();
CREATE TRIGGER set_nephrology_visits_updated_at BEFORE UPDATE ON nephrology_visits FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

-- ========================================
-- Gastroenterology Procedures Table
-- ========================================

CREATE TABLE gastroenterology_procedures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    gastroenterologist_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    procedure_date TIMESTAMPTZ NOT NULL,
    procedure_name VARCHAR(255) NOT NULL, -- 'endoscopy', 'colonoscopy', 'ercp', 'capsule_endoscopy'
    indication TEXT NOT NULL,
    sedation_type VARCHAR(100),

    -- Endoscopy Findings
    esophagus_findings TEXT,
    stomach_findings TEXT,
    duodenum_findings TEXT,
    colon_findings TEXT,
    cecum_reached BOOLEAN DEFAULT FALSE,
    ileum_intubated BOOLEAN DEFAULT FALSE,

    -- Interventions
    biopsies_taken BOOLEAN DEFAULT FALSE,
    biopsy_sites TEXT[],
    polyps_removed BOOLEAN DEFAULT FALSE,
    polyp_details JSONB,
    hemostasis_performed BOOLEAN DEFAULT FALSE,
    dilation_performed BOOLEAN DEFAULT FALSE,

    -- Pathology
    pathology_results TEXT,
    h_pylori_status VARCHAR(20), -- 'positive', 'negative', 'pending'

    complications TEXT[],
    post_procedure_instructions TEXT,
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

CREATE INDEX idx_gastroenterology_procedures_patient ON gastroenterology_procedures(patient_id);
CREATE INDEX idx_gastroenterology_procedures_gastroenterologist ON gastroenterology_procedures(gastroenterologist_id) WHERE gastroenterologist_id IS NOT NULL;
CREATE INDEX idx_gastroenterology_procedures_date ON gastroenterology_procedures(procedure_date DESC);
CREATE INDEX idx_gastroenterology_procedures_ehrbase ON gastroenterology_procedures(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE gastroenterology_procedures ENABLE ROW LEVEL SECURITY;
CREATE POLICY "patient_gastroenterology_procedures_select" ON gastroenterology_procedures FOR SELECT TO authenticated USING (patient_id::TEXT = auth.uid()::TEXT);
CREATE POLICY "provider_gastroenterology_procedures_select" ON gastroenterology_procedures FOR SELECT TO authenticated USING (patient_id IN (SELECT DISTINCT a.patient_id::uuid FROM appointments a JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id WHERE mpp.user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_gastroenterology_procedures_insert" ON gastroenterology_procedures FOR INSERT TO authenticated WITH CHECK (gastroenterologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_gastroenterology_procedures_update" ON gastroenterology_procedures FOR UPDATE TO authenticated USING (gastroenterologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "facility_admin_gastroenterology_procedures_select" ON gastroenterology_procedures FOR SELECT TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_gastroenterology_procedures_all" ON gastroenterology_procedures FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_gastroenterology_procedures_for_sync() RETURNS TRIGGER AS $$ DECLARE v_ehr_id VARCHAR; BEGIN SELECT ehr_id INTO v_ehr_id FROM electronic_health_records WHERE patient_id = NEW.patient_id::TEXT; IF v_ehr_id IS NOT NULL THEN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('gastroenterology_procedures', NEW.id::TEXT, 'medzen.gastroenterology_procedures.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_gastroenterology_procedures_sync ON gastroenterology_procedures;
CREATE TRIGGER trigger_queue_gastroenterology_procedures_sync AFTER INSERT OR UPDATE ON gastroenterology_procedures FOR EACH ROW EXECUTE FUNCTION queue_gastroenterology_procedures_for_sync();
CREATE TRIGGER set_gastroenterology_procedures_updated_at BEFORE UPDATE ON gastroenterology_procedures FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();

-- ========================================
-- Endocrinology Visits Table
-- ========================================

CREATE TABLE endocrinology_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    endocrinologist_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    visit_date TIMESTAMPTZ NOT NULL,
    primary_endocrine_condition VARCHAR(255) NOT NULL, -- 'diabetes', 'thyroid_disorder', 'pituitary_disorder', 'adrenal_disorder'

    -- Diabetes Management
    diabetes_type VARCHAR(50), -- 'type_1', 'type_2', 'gestational', 'other'
    hba1c_percent REAL,
    fasting_glucose_mg_dl REAL,
    insulin_regimen TEXT,
    oral_medications TEXT[],
    cgm_in_use BOOLEAN DEFAULT FALSE,
    hypoglycemia_episodes INTEGER,

    -- Thyroid Assessment
    thyroid_condition VARCHAR(100), -- 'hypothyroidism', 'hyperthyroidism', 'thyroid_nodule', 'thyroid_cancer'
    tsh_miu_l REAL,
    t3_ng_dl REAL,
    t4_ng_dl REAL,
    thyroid_medications TEXT[],

    -- Hormonal Assessment
    hormonal_imbalances TEXT[],
    hormone_levels JSONB,

    -- Physical Findings
    weight_kg REAL,
    bmi REAL,
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,

    treatment_plan TEXT,
    lifestyle_recommendations TEXT,
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

CREATE INDEX idx_endocrinology_visits_patient ON endocrinology_visits(patient_id);
CREATE INDEX idx_endocrinology_visits_endocrinologist ON endocrinology_visits(endocrinologist_id) WHERE endocrinologist_id IS NOT NULL;
CREATE INDEX idx_endocrinology_visits_date ON endocrinology_visits(visit_date DESC);
CREATE INDEX idx_endocrinology_visits_ehrbase ON endocrinology_visits(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE endocrinology_visits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "patient_endocrinology_visits_select" ON endocrinology_visits FOR SELECT TO authenticated USING (patient_id::TEXT = auth.uid()::TEXT);
CREATE POLICY "provider_endocrinology_visits_select" ON endocrinology_visits FOR SELECT TO authenticated USING (patient_id IN (SELECT DISTINCT a.patient_id::uuid FROM appointments a JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id WHERE mpp.user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_endocrinology_visits_insert" ON endocrinology_visits FOR INSERT TO authenticated WITH CHECK (endocrinologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_endocrinology_visits_update" ON endocrinology_visits FOR UPDATE TO authenticated USING (endocrinologist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "facility_admin_endocrinology_visits_select" ON endocrinology_visits FOR SELECT TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_endocrinology_visits_all" ON endocrinology_visits FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_endocrinology_visits_for_sync() RETURNS TRIGGER AS $$ DECLARE v_ehr_id VARCHAR; BEGIN SELECT ehr_id INTO v_ehr_id FROM electronic_health_records WHERE patient_id = NEW.patient_id::TEXT; IF v_ehr_id IS NOT NULL THEN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('endocrinology_visits', NEW.id::TEXT, 'medzen.endocrinology_management.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_endocrinology_visits_sync ON endocrinology_visits;
CREATE TRIGGER trigger_queue_endocrinology_visits_sync AFTER INSERT OR UPDATE ON endocrinology_visits FOR EACH ROW EXECUTE FUNCTION queue_endocrinology_visits_for_sync();
CREATE TRIGGER set_endocrinology_visits_updated_at BEFORE UPDATE ON endocrinology_visits FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
