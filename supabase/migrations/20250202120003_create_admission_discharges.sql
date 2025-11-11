-- Create admission_discharges table for hospital admissions and discharges
-- Template: medzen-admission-discharge-summary.v1

CREATE TABLE admission_discharges (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign Keys
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    admitting_provider_id UUID REFERENCES medical_provider_profiles(id),
    discharge_provider_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    -- Admission Information
    admission_date TIMESTAMPTZ NOT NULL,
    admission_type VARCHAR(50), -- 'emergency', 'elective', 'observation', 'transfer'
    admission_source VARCHAR(100), -- 'ER', 'outpatient_clinic', 'transfer_from_facility', 'home'
    admission_diagnosis VARCHAR(255) NOT NULL,
    chief_complaint TEXT,

    -- Patient Status on Admission
    admission_vital_signs JSONB, -- Store as JSON: {bp_sys, bp_dia, hr, temp, rr, spo2}
    admission_glasgow_coma_score INTEGER,
    admission_consciousness_level VARCHAR(50), -- 'alert', 'responsive', 'unresponsive'

    -- Hospital Stay
    ward_type VARCHAR(100), -- 'general_ward', 'ICU', 'CCU', 'NICU', 'isolation'
    bed_number VARCHAR(50),
    length_of_stay_days INTEGER,
    complications_during_stay TEXT[],

    -- Treatment During Stay
    procedures_performed TEXT[],
    medications_administered TEXT[],
    investigations_done TEXT[],
    consultations_requested TEXT[], -- Other specialists consulted

    -- Discharge Information
    discharge_date TIMESTAMPTZ,
    discharge_type VARCHAR(50), -- 'routine', 'against_medical_advice', 'transfer', 'deceased'
    discharge_diagnosis VARCHAR(255),
    discharge_condition VARCHAR(100), -- 'improved', 'stable', 'worsened', 'unchanged'
    discharge_destination VARCHAR(100), -- 'home', 'another_facility', 'rehabilitation', 'morgue'

    -- Discharge Instructions
    discharge_medications TEXT[],
    discharge_instructions TEXT,
    activity_restrictions TEXT,
    diet_instructions TEXT,
    follow_up_date DATE,
    follow_up_provider_id UUID REFERENCES medical_provider_profiles(id),

    -- Additional Information
    death_date TIMESTAMPTZ,
    cause_of_death TEXT,
    autopsy_performed BOOLEAN DEFAULT FALSE,

    notes TEXT,

    -- EHRbase Integration
    composition_id VARCHAR(255),
    ehrbase_synced BOOLEAN DEFAULT FALSE,
    ehrbase_synced_at TIMESTAMPTZ,
    ehrbase_sync_error TEXT,
    ehrbase_retry_count INTEGER DEFAULT 0,

    -- Audit Fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_length_of_stay CHECK (length_of_stay_days >= 0),
    CONSTRAINT valid_discharge CHECK (discharge_date IS NULL OR discharge_date >= admission_date),
    CONSTRAINT valid_death CHECK (death_date IS NULL OR death_date >= admission_date)
);

-- Indexes
CREATE INDEX idx_admission_discharges_patient ON admission_discharges(patient_id);
CREATE INDEX idx_admission_discharges_facility ON admission_discharges(facility_id) WHERE facility_id IS NOT NULL;
CREATE INDEX idx_admission_discharges_admission_date ON admission_discharges(admission_date DESC);
CREATE INDEX idx_admission_discharges_discharge_date ON admission_discharges(discharge_date DESC) WHERE discharge_date IS NOT NULL;
CREATE INDEX idx_admission_discharges_created ON admission_discharges(created_at DESC);
CREATE INDEX idx_admission_discharges_ehrbase ON admission_discharges(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;

-- Enable RLS
ALTER TABLE admission_discharges ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "patient_admission_discharges_select" ON admission_discharges
    FOR SELECT TO authenticated
    USING (patient_id::TEXT = auth.uid()::TEXT);

CREATE POLICY "provider_admission_discharges_select" ON admission_discharges
    FOR SELECT TO authenticated
    USING (
        patient_id IN (
            SELECT DISTINCT a.patient_id::uuid
            FROM appointments a
            JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
            WHERE mpp.user_id::TEXT = auth.uid()::TEXT
        )
    );

CREATE POLICY "provider_admission_discharges_insert" ON admission_discharges
    FOR INSERT TO authenticated
    WITH CHECK (
        admitting_provider_id IN (
            SELECT id FROM medical_provider_profiles
            WHERE user_id::TEXT = auth.uid()::TEXT
        )
    );

CREATE POLICY "provider_admission_discharges_update" ON admission_discharges
    FOR UPDATE TO authenticated
    USING (
        admitting_provider_id IN (
            SELECT id FROM medical_provider_profiles
            WHERE user_id::TEXT = auth.uid()::TEXT
        ) OR discharge_provider_id IN (
            SELECT id FROM medical_provider_profiles
            WHERE user_id::TEXT = auth.uid()::TEXT
        )
    );

CREATE POLICY "facility_admin_admission_discharges_select" ON admission_discharges
    FOR SELECT TO authenticated
    USING (
        facility_id IN (
            SELECT facility_id FROM facility_admin_profiles
            WHERE user_id::TEXT = auth.uid()::TEXT
        )
    );

CREATE POLICY "system_admin_admission_discharges_all" ON admission_discharges
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM system_admin_profiles
            WHERE user_id::TEXT = auth.uid()::TEXT
        )
    );

-- Trigger Function
CREATE OR REPLACE FUNCTION queue_admission_discharges_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id::TEXT;

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status, data_snapshot, created_at, updated_at
    ) VALUES (
      'admission_discharges', NEW.id::TEXT, 'medzen.admission_discharge_summary.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type)
    DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create Trigger
DROP TRIGGER IF EXISTS trigger_queue_admission_discharges_sync ON admission_discharges;

CREATE TRIGGER trigger_queue_admission_discharges_sync
  AFTER INSERT OR UPDATE ON admission_discharges
  FOR EACH ROW
  EXECUTE FUNCTION queue_admission_discharges_for_sync();

CREATE TRIGGER set_admission_discharges_updated_at
  BEFORE UPDATE ON admission_discharges
  FOR EACH ROW
  EXECUTE FUNCTION trigger_set_updated_at();
