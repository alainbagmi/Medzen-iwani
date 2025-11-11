-- Create surgical_procedures table for surgical interventions
-- Template: medzen-surgical-procedure-report.v1

CREATE TABLE surgical_procedures (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign Keys
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    surgeon_id UUID REFERENCES medical_provider_profiles(id),
    facility_id UUID REFERENCES facilities(id),
    admission_id UUID, -- Nullable - links to admission_discharges if applicable (table created in later migration)

    -- Procedure Information
    procedure_name VARCHAR(255) NOT NULL,
    procedure_code VARCHAR(50), -- ICD-10-PCS or CPT code
    procedure_type VARCHAR(100), -- 'elective', 'emergency', 'urgent'
    procedure_date TIMESTAMPTZ NOT NULL,
    procedure_duration_minutes INTEGER,

    -- Pre-operative Information
    indication TEXT NOT NULL,
    diagnosis VARCHAR(255),
    pre_op_assessment TEXT,
    asa_classification VARCHAR(10), -- 'I', 'II', 'III', 'IV', 'V'
    risk_level VARCHAR(20), -- 'low', 'moderate', 'high'

    -- Surgical Team
    assistant_surgeons TEXT[], -- Array of surgeon IDs or names
    anesthetist_id UUID REFERENCES medical_provider_profiles(id),
    anesthesia_type VARCHAR(100), -- 'general', 'regional', 'local', 'sedation'
    scrub_nurse VARCHAR(255),
    circulating_nurse VARCHAR(255),

    -- Procedure Details
    approach VARCHAR(100), -- 'open', 'laparoscopic', 'robotic', 'endoscopic'
    site_of_surgery VARCHAR(255),
    laterality VARCHAR(20), -- 'left', 'right', 'bilateral', 'midline'
    incision_type VARCHAR(100),
    implants_used TEXT[],
    specimens_taken TEXT[],

    -- Intra-operative Findings
    findings TEXT,
    complications_intraop TEXT[],
    blood_loss_ml INTEGER,
    transfusions_given BOOLEAN DEFAULT FALSE,
    transfusion_details TEXT,

    -- Post-operative Information
    outcome VARCHAR(50), -- 'successful', 'complicated', 'aborted'
    post_op_diagnosis VARCHAR(255),
    complications_postop TEXT[],
    drains_placed TEXT[],

    -- Recovery
    post_op_instructions TEXT,
    follow_up_date DATE,
    estimated_recovery_days INTEGER,

    -- Additional Notes
    special_equipment_used TEXT[],
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
    CONSTRAINT valid_duration CHECK (procedure_duration_minutes >= 0),
    CONSTRAINT valid_blood_loss CHECK (blood_loss_ml >= 0)
);

-- Indexes
CREATE INDEX idx_surgical_procedures_patient ON surgical_procedures(patient_id);
CREATE INDEX idx_surgical_procedures_surgeon ON surgical_procedures(surgeon_id) WHERE surgeon_id IS NOT NULL;
CREATE INDEX idx_surgical_procedures_facility ON surgical_procedures(facility_id) WHERE facility_id IS NOT NULL;
CREATE INDEX idx_surgical_procedures_date ON surgical_procedures(procedure_date DESC);
CREATE INDEX idx_surgical_procedures_created ON surgical_procedures(created_at DESC);
CREATE INDEX idx_surgical_procedures_ehrbase ON surgical_procedures(ehrbase_synced, created_at) WHERE NOT ehrbase_synced;
CREATE INDEX idx_surgical_procedures_follow_up ON surgical_procedures(follow_up_date) WHERE follow_up_date IS NOT NULL;

-- Enable RLS
ALTER TABLE surgical_procedures ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "patient_surgical_procedures_select" ON surgical_procedures
    FOR SELECT TO authenticated
    USING (patient_id::TEXT = auth.uid()::TEXT);

CREATE POLICY "provider_surgical_procedures_select" ON surgical_procedures
    FOR SELECT TO authenticated
    USING (
        patient_id IN (
            SELECT DISTINCT a.patient_id::uuid
            FROM appointments a
            JOIN medical_provider_profiles mpp ON mpp.id = a.provider_id
            WHERE mpp.user_id::TEXT = auth.uid()::TEXT
        )
    );

CREATE POLICY "provider_surgical_procedures_insert" ON surgical_procedures
    FOR INSERT TO authenticated
    WITH CHECK (
        surgeon_id IN (
            SELECT id FROM medical_provider_profiles
            WHERE user_id::TEXT = auth.uid()::TEXT
        )
    );

CREATE POLICY "provider_surgical_procedures_update" ON surgical_procedures
    FOR UPDATE TO authenticated
    USING (
        surgeon_id IN (
            SELECT id FROM medical_provider_profiles
            WHERE user_id::TEXT = auth.uid()::TEXT
        )
    );

CREATE POLICY "facility_admin_surgical_procedures_select" ON surgical_procedures
    FOR SELECT TO authenticated
    USING (facility_id IN (SELECT facility_id FROM facility_admin_profiles WHERE user_id::TEXT = auth.uid()::TEXT));

CREATE POLICY "system_admin_surgical_procedures_all" ON surgical_procedures
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM system_admin_profiles
            WHERE user_id::TEXT = auth.uid()::TEXT
        )
    );

-- Trigger Function
CREATE OR REPLACE FUNCTION queue_surgical_procedures_for_sync()
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
      'surgical_procedures', NEW.id::TEXT, 'medzen.surgical_procedure_report.v1', 'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type)
    DO UPDATE SET sync_status = 'pending', data_snapshot = to_jsonb(NEW), updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create Trigger
DROP TRIGGER IF EXISTS trigger_queue_surgical_procedures_sync ON surgical_procedures;

CREATE TRIGGER trigger_queue_surgical_procedures_sync
  AFTER INSERT OR UPDATE ON surgical_procedures
  FOR EACH ROW
  EXECUTE FUNCTION queue_surgical_procedures_for_sync();

CREATE TRIGGER set_surgical_procedures_updated_at
  BEFORE UPDATE ON surgical_procedures
  FOR EACH ROW
  EXECUTE FUNCTION trigger_set_updated_at();
