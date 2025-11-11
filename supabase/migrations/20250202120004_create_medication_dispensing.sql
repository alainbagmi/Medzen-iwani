-- Create medication_dispensing table for pharmacy dispensing records
-- Template: medzen-medication-dispensing-record.v1

CREATE TABLE medication_dispensing (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    prescription_id UUID REFERENCES prescriptions(id),
    pharmacist_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    -- Medication Information
    medication_name VARCHAR(255) NOT NULL,
    medication_code VARCHAR(50), -- RxNorm code
    strength VARCHAR(100),
    dosage_form VARCHAR(100), -- 'tablet', 'capsule', 'syrup', 'injection'
    route VARCHAR(50), -- 'oral', 'IV', 'topical', 'inhaled'

    -- Dispensing Details
    quantity_dispensed DECIMAL(10,2) NOT NULL,
    unit VARCHAR(50) NOT NULL, -- 'tablets', 'ml', 'capsules', 'units'
    dispensing_date TIMESTAMPTZ NOT NULL,
    batch_number VARCHAR(100),
    expiry_date DATE,
    manufacturer VARCHAR(255),

    -- Prescription Details
    dosage_instructions TEXT,
    frequency VARCHAR(100),
    duration_days INTEGER,
    refills_remaining INTEGER DEFAULT 0,

    -- Patient Instructions
    counseling_provided BOOLEAN DEFAULT FALSE,
    counseling_notes TEXT,
    special_instructions TEXT,
    warnings TEXT[],

    -- Cost Information
    unit_price DECIMAL(10,2),
    total_cost DECIMAL(10,2),
    insurance_coverage DECIMAL(10,2),
    patient_copay DECIMAL(10,2),

    notes TEXT,

    -- EHRbase Integration
    composition_id VARCHAR(255),
    ehrbase_synced BOOLEAN DEFAULT FALSE,
    ehrbase_synced_at TIMESTAMPTZ,
    ehrbase_sync_error TEXT,
    ehrbase_retry_count INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_quantity CHECK (quantity_dispensed > 0),
    CONSTRAINT valid_refills CHECK (refills_remaining >= 0)
);

CREATE INDEX idx_medication_dispensing_patient ON medication_dispensing(patient_id);
CREATE INDEX idx_medication_dispensing_prescription ON medication_dispensing(prescription_id) WHERE prescription_id IS NOT NULL;
CREATE INDEX idx_medication_dispensing_pharmacist ON medication_dispensing(pharmacist_id) WHERE pharmacist_id IS NOT NULL;
CREATE INDEX idx_medication_dispensing_date ON medication_dispensing(dispensing_date DESC);
CREATE INDEX idx_medication_dispensing_created ON medication_dispensing(created_at DESC);
CREATE INDEX idx_medication_dispensing_ehrbase ON medication_dispensing(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

ALTER TABLE medication_dispensing ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patient_medication_dispensing_select" ON medication_dispensing FOR SELECT TO authenticated USING (patient_id::TEXT = auth.uid()::TEXT);
CREATE POLICY "provider_medication_dispensing_select" ON medication_dispensing FOR SELECT TO authenticated USING (patient_id IN (SELECT DISTINCT a.patient_id::uuid FROM appointments a JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id WHERE mpp.user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "provider_medication_dispensing_insert" ON medication_dispensing FOR INSERT TO authenticated WITH CHECK (pharmacist_id IN (SELECT id FROM medical_provider_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "facility_admin_medication_dispensing_select" ON medication_dispensing FOR SELECT TO authenticated USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));
CREATE POLICY "system_admin_medication_dispensing_all" ON medication_dispensing FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM system_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE OR REPLACE FUNCTION queue_medication_dispensing_for_sync() RETURNS TRIGGER AS $$ DECLARE v_ehr_id VARCHAR; BEGIN SELECT ehr_id INTO v_ehr_id FROM electronic_health_records WHERE patient_id = NEW.patient_id::TEXT; IF v_ehr_id IS NOT NULL THEN INSERT INTO ehrbase_sync_queue (table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at) VALUES ('medication_dispensing', NEW.id::TEXT, 'medzen.medication_dispensing_record.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()) ON CONFLICT (table_name, record_id, sync_type) DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_queue_medication_dispensing_sync ON medication_dispensing;
CREATE TRIGGER trigger_queue_medication_dispensing_sync AFTER INSERT OR UPDATE ON medication_dispensing FOR EACH ROW EXECUTE FUNCTION queue_medication_dispensing_for_sync();
CREATE TRIGGER set_medication_dispensing_updated_at BEFORE UPDATE ON medication_dispensing FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
