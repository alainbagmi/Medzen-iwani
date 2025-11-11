-- Comprehensive fix for type mismatch in ALL EHR sync trigger functions
-- Issue: patient_id is UUID type in electronic_health_records table
-- Error: "operator does not exist: uuid = text"
-- Solution: Remove ::TEXT casts since both columns are UUID type
--
-- This migration fixes 22 trigger functions that queue medical records for EHRbase sync:
--  - 1 user demographics function
--  - 3 core medical records functions (vital signs, lab results, prescriptions)
--  - 4 specialty visit/procedure functions (antenatal, surgical, admission/discharge, medication dispensing)
--  - 14 additional specialty visit functions

-- =====================================================
-- USER DEMOGRAPHICS SYNC (Special Case - users table)
-- =====================================================
CREATE OR REPLACE FUNCTION queue_user_demographics_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  -- Get the EHR ID for this user (NEW.id is from users table)
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.id;  -- ✅ FIXED: Removed ::TEXT cast (both are UUID)

  -- Only queue if user has an EHR
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
      'users_demographics',
      NEW.id::TEXT,
      'ehrbase.demographics.v1',
      'ehr_status_update',
      'pending',
      jsonb_build_object(
        'user_id', NEW.id,
        'firebase_uid', NEW.firebase_uid,
        'ehr_id', v_ehr_id,
        'first_name', NEW.first_name,
        'last_name', NEW.last_name,
        'middle_name', NEW.middle_name,
        'full_name', NEW.full_name,
        'date_of_birth', NEW.date_of_birth,
        'gender', NEW.gender,
        'email', NEW.email,
        'phone_number', NEW.phone_number,
        'country', NEW.country,
        'updated_at', NEW.updated_at
      ),
      NOW(),
      NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET
      sync_status = 'pending',
      data_snapshot = EXCLUDED.data_snapshot,
      updated_at = NOW(),
      retry_count = 0,
      error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- CORE MEDICAL RECORDS (vital signs, lab results, prescriptions)
-- =====================================================

CREATE OR REPLACE FUNCTION queue_vital_signs_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

  INSERT INTO ehrbase_sync_queue (
    table_name, record_id, template_id, sync_type, sync_status,
    data_snapshot, created_at, updated_at
  ) VALUES (
    'vital_signs', NEW.id::TEXT, 'medzen.vital_signs.v1',
    'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
      updated_at = NOW(), retry_count = 0, error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_lab_results_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

  INSERT INTO ehrbase_sync_queue (
    table_name, record_id, template_id, sync_type, sync_status,
    data_snapshot, created_at, updated_at
  ) VALUES (
    'lab_results', NEW.id::TEXT, 'medzen.lab_results.v1',
    'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
      updated_at = NOW(), retry_count = 0, error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_prescriptions_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

  INSERT INTO ehrbase_sync_queue (
    table_name, record_id, template_id, sync_type, sync_status,
    data_snapshot, created_at, updated_at
  ) VALUES (
    'prescriptions', NEW.id::TEXT, 'medzen.prescriptions.v1',
    'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
      updated_at = NOW(), retry_count = 0, error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SPECIALTY TABLES (High Priority)
-- =====================================================

CREATE OR REPLACE FUNCTION queue_antenatal_visits_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'antenatal_visits', NEW.id::TEXT, 'medzen.antenatal_care_encounter.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_surgical_procedures_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'surgical_procedures', NEW.id::TEXT, 'medzen.surgical_procedure_report.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_admission_discharges_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'admission_discharges', NEW.id::TEXT, 'medzen.admission_discharge_summary.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_medication_dispensing_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'medication_dispensing', NEW.id::TEXT, 'medzen.medication_dispensing_record.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SPECIALTY VISIT FUNCTIONS (Cardiology through Radiology)
-- =====================================================

CREATE OR REPLACE FUNCTION queue_cardiology_visits_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'cardiology_visits', NEW.id::TEXT, 'medzen.cardiology_encounter.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_clinical_consultations_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'clinical_consultations', NEW.id::TEXT, 'medzen.clinical_consultation.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_emergency_visits_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'emergency_visits', NEW.id::TEXT, 'medzen.emergency_encounter.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_endocrinology_visits_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'endocrinology_visits', NEW.id::TEXT, 'medzen.endocrinology_encounter.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_gastroenterology_procedures_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'gastroenterology_procedures', NEW.id::TEXT, 'medzen.gastroenterology_procedure.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_infectious_disease_visits_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'infectious_disease_visits', NEW.id::TEXT, 'medzen.infectious_disease_encounter.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_nephrology_visits_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'nephrology_visits', NEW.id::TEXT, 'medzen.nephrology_encounter.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_neurology_exams_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'neurology_exams', NEW.id::TEXT, 'medzen.neurology_examination.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_oncology_treatments_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'oncology_treatments', NEW.id::TEXT, 'medzen.oncology_treatment.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_pathology_reports_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'pathology_reports', NEW.id::TEXT, 'medzen.pathology_report.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_physiotherapy_sessions_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'physiotherapy_sessions', NEW.id::TEXT, 'medzen.physiotherapy_session.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_psychiatric_assessments_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'psychiatric_assessments', NEW.id::TEXT, 'medzen.psychiatric_assessment.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_pulmonology_visits_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'pulmonology_visits', NEW.id::TEXT, 'medzen.pulmonology_encounter.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION queue_radiology_reports_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;  -- ✅ FIXED: Removed ::TEXT cast

  IF v_ehr_id IS NOT NULL THEN
    INSERT INTO ehrbase_sync_queue (
      table_name, record_id, template_id, sync_type, sync_status,
      data_snapshot, created_at, updated_at
    ) VALUES (
      'radiology_reports', NEW.id::TEXT, 'medzen.radiology_report.v1',
      'composition_create', 'pending', to_jsonb(NEW), NOW(), NOW()
    )
    ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
    SET sync_status = 'pending', data_snapshot = to_jsonb(NEW),
        updated_at = NOW(), retry_count = 0, error_message = NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCTION COMMENTS
-- =====================================================
COMMENT ON FUNCTION queue_user_demographics_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns (special case: users.id to electronic_health_records.patient_id)';
COMMENT ON FUNCTION queue_vital_signs_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_lab_results_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_prescriptions_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_antenatal_visits_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_surgical_procedures_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_admission_discharges_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_medication_dispensing_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_cardiology_visits_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_clinical_consultations_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_emergency_visits_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_endocrinology_visits_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_gastroenterology_procedures_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_infectious_disease_visits_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_nephrology_visits_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_neurology_exams_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_oncology_treatments_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_pathology_reports_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_physiotherapy_sessions_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_psychiatric_assessments_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_pulmonology_visits_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
COMMENT ON FUNCTION queue_radiology_reports_for_sync IS 'Fixed type mismatch - removed ::TEXT cast when comparing UUID columns';
