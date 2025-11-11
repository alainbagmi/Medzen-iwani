-- Create clinical_consultations table for general consultations
-- Template: medzen-clinical-consultation.v1

CREATE TABLE clinical_consultations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),
    appointment_id UUID REFERENCES appointments(id),

    consultation_date TIMESTAMPTZ NOT NULL,
    consultation_type VARCHAR(100), -- 'initial', 'follow-up', 'urgent', 'routine'
    chief_complaint TEXT NOT NULL,
    history_of_present_illness TEXT,
    review_of_systems JSONB,

    -- Physical Examination
    general_appearance TEXT,
    vital_signs_id UUID REFERENCES vital_signs(id),
    physical_examination_findings TEXT,

    -- Assessment
    assessment TEXT,
    diagnoses TEXT[],
    differential_diagnoses TEXT[],

    -- Plan
    treatment_plan TEXT,
    medications_prescribed_ids UUID[],
    investigations_ordered TEXT[],
    referrals TEXT[],
    follow_up_date DATE,
    follow_up_instructions TEXT,

    notes TEXT,

    composition_id VARCHAR(255),
    ehrbase_synced BOOLEAN DEFAULT FALSE,
    ehrbase_synced_at TIMESTAMPTZ,
    ehrbase_sync_error TEXT,
    ehrbase_retry_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_clinical_consultations_patient ON clinical_consultations(patient_id);
CREATE INDEX idx_clinical_consultations_provider ON clinical_consultations(provider_id) WHERE provider_id IS NOT NULL;
CREATE INDEX idx_clinical_consultations_date ON clinical_consultations(consultation_date DESC);
CREATE INDEX idx_clinical_consultations_created ON clinical_consultations(created_at DESC);
CREATE INDEX idx_clinical_consultations_ehrbase ON clinical_consultations(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE clinical_consultations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_clinical_consultations_select" ON clinical_consultations FOR SELECT TO authenticated USING (patient_id::TEXT = auth.uid()::TEXT);
CREATE POLICY "provider_clinical_consultations_select" ON clinical_consultations FOR SELECT TO authenticated USING (patient_id IN (SELECT DISTINCT a.patient_id::uuid FROM appointments a JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id WHERE mpp.user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_clinical_consultations_insert" ON clinical_consultations FOR INSERT TO authenticated WITH CHECK (provider_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_clinical_consultations_update" ON clinical_consultations FOR UPDATE TO authenticated USING (provider_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "facility_admin_clinical_consultations_select" ON clinical_consultations FOR SELECT TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_clinical_consultations_all" ON clinical_consultations FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_clinical_consultations_for_sync() RETURNS TRIGGER AS $$ DECLARE v_ehr_id VARCHAR; BEGIN SELECT ehr_id INTO v_ehr_id FROM electronic_health_records WHERE patient_id = NEW.patient_id::TEXT; IF v_ehr_id IS NOT NULL THEN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('clinical_consultations', NEW.id::TEXT, 'medzen.clinical_consultation.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_clinical_consultations_sync ON clinical_consultations;
CREATE TRIGGER trigger_queue_clinical_consultations_sync AFTER INSERT OR UPDATE ON clinical_consultations FOR EACH ROW EXECUTE FUNCTION queue_clinical_consultations_for_sync();
CREATE TRIGGER set_clinical_consultations_updated_at BEFORE UPDATE ON clinical_consultations FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
