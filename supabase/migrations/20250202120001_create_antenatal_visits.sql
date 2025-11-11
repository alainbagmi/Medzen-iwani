-- Create antenatal_visits table for prenatal care tracking
-- Template: medzen-antenatal-care-encounter.v1

-- Create helper function for updated_at triggers (if not exists)
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE antenatal_visits (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign Keys
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),

    -- Visit Information
    visit_number INTEGER NOT NULL,
    gestational_age_weeks INTEGER,
    gestational_age_days INTEGER,
    visit_date DATE NOT NULL,
    visit_type VARCHAR(50), -- 'initial', 'routine', 'follow-up', 'emergency'

    -- Vital Signs
    weight_kg REAL,
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,
    fundal_height_cm REAL,

    -- Fetal Assessment
    fetal_heart_rate INTEGER,
    fetal_presentation VARCHAR(50), -- 'cephalic', 'breech', 'transverse'
    fetal_movement VARCHAR(20), -- 'active', 'reduced', 'absent'
    multiple_pregnancy BOOLEAN DEFAULT FALSE,
    number_of_fetuses INTEGER DEFAULT 1,

    -- Maternal Health
    edema_status VARCHAR(20), -- 'none', 'mild', 'moderate', 'severe'
    proteinuria VARCHAR(20), -- 'negative', 'trace', '+1', '+2', '+3', '+4'
    urine_glucose VARCHAR(20), -- 'negative', 'trace', '+1', '+2', '+3', '+4'

    -- Risk Factors
    risk_level VARCHAR(20), -- 'low', 'moderate', 'high'
    risk_factors TEXT[], -- Array of risk factors
    complications TEXT[], -- Array of complications

    -- Investigations Ordered
    lab_tests_ordered TEXT[],
    ultrasound_ordered BOOLEAN DEFAULT FALSE,
    ultrasound_date DATE,

    -- Treatment & Advice
    medications_prescribed TEXT[],
    supplements_prescribed TEXT[], -- e.g., folic acid, iron
    advice_given TEXT,
    next_visit_date DATE,

    -- Additional Notes
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
    CONSTRAINT valid_gestational_age CHECK (gestational_age_weeks >= 0 AND gestational_age_weeks <= 42),
    CONSTRAINT valid_gestational_days CHECK (gestational_age_days >= 0 AND gestational_age_days < 7),
    CONSTRAINT valid_visit_number CHECK (visit_number > 0),
    CONSTRAINT valid_fetal_count CHECK (number_of_fetuses >= 1)
);

-- Indexes
CREATE INDEX idx_antenatal_visits_patient ON antenatal_visits(patient_id);
CREATE INDEX idx_antenatal_visits_provider ON antenatal_visits(provider_id) WHERE provider_id IS NOT NULL;
CREATE INDEX idx_antenatal_visits_facility ON antenatal_visits(facility_id) WHERE facility_id IS NOT NULL;
CREATE INDEX idx_antenatal_visits_date ON antenatal_visits(visit_date DESC);
CREATE INDEX idx_antenatal_visits_created ON antenatal_visits(created_at DESC);
CREATE INDEX idx_antenatal_visits_ehrbase ON antenatal_visits(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;
CREATE INDEX idx_antenatal_visits_next_visit ON antenatal_visits(next_visit_date) WHERE next_visit_date IS NOT NULL;

-- Enable RLS
ALTER TABLE antenatal_visits ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Patient: Own records only
CREATE POLICY "patient_antenatal_visits_select" ON antenatal_visits
    FOR SELECT TO authenticated
    USING (patient_id::TEXT = auth.uid()::TEXT);

CREATE POLICY "patient_antenatal_visits_insert" ON antenatal_visits
    FOR INSERT TO authenticated
    WITH CHECK (patient_id::TEXT = auth.uid()::TEXT);

-- Provider: Patients with appointments
CREATE POLICY "provider_antenatal_visits_select" ON antenatal_visits
    FOR SELECT TO authenticated
    USING (
        patient_id IN (
            SELECT DISTINCT a.patient_id::uuid
            FROM appointments a
            JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
            WHERE mpp.user_id::TEXT = auth.uid()::TEXT
        )
    );

CREATE POLICY "provider_antenatal_visits_insert" ON antenatal_visits
    FOR INSERT TO authenticated
    WITH CHECK (
        provider_id IN (
            SELECT id FROM medical_provider_profiles
            WHERE user_id::TEXT = auth.uid()::TEXT
        )
    );

CREATE POLICY "provider_antenatal_visits_update" ON antenatal_visits
    FOR UPDATE TO authenticated
    USING (
        provider_id IN (
            SELECT id FROM medical_provider_profiles
            WHERE user_id::TEXT = auth.uid()::TEXT
        )
    );

-- Facility Admin: All facility records
CREATE POLICY "facility_admin_antenatal_visits_select" ON antenatal_visits
    FOR SELECT TO authenticated
    USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

-- System Admin: All records
CREATE POLICY "system_admin_antenatal_visits_all" ON antenatal_visits
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM system_admin_profiles
            WHERE user_id::TEXT = auth.uid()::TEXT
        )
    );

-- Trigger Function for EHRbase Sync
CREATE OR REPLACE FUNCTION queue_antenatal_visits_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  -- Get EHR ID for this patient
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id::TEXT;

  -- Only queue if EHR exists
  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name,
      record_id,
      template_id,
      sync_type,
      sync_status,
      data_snapshot,
      created_at,
      updated_at
    ) VALUES (
      'antenatal_visits',
      NEW.id::TEXT,
      'medzen.antenatal_care_encounter.v1',
      'composition_create',
      'pending',
      to_jsonb(NEW),
      NOW(),
      NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type)
    DO UPDATE SET
      sync_status = 'pending',
      data_snapshot = to_jsonb(NEW),
      updated_at = NOW(),
      retry_count = 0,
      error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create Trigger
DROP TRIGGER IF EXISTS trigger_queue_antenatal_visits_sync ON antenatal_visits;

CREATE TRIGGER trigger_queue_antenatal_visits_sync
  AFTER INSERT OR UPDATE ON antenatal_visits
  FOR EACH ROW
  EXECUTE FUNCTION queue_antenatal_visits_for_sync();

-- Update timestamp trigger
CREATE TRIGGER set_antenatal_visits_updated_at
  BEFORE UPDATE ON antenatal_visits
  FOR EACH ROW
  EXECUTE FUNCTION trigger_set_updated_at();
