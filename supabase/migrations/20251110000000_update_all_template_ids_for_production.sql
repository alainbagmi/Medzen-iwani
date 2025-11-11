-- Update All Template IDs for Production Readiness
-- This migration updates all sync queue trigger functions to use the correct
-- template IDs that match the TEMPLATE_ID_MAP in the sync-to-ehrbase edge function

-- =====================================================
-- 1. Core Medical Data Templates
-- =====================================================

-- Update vital_signs template
CREATE OR REPLACE FUNCTION queue_vital_signs_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'vital_signs',
    NEW.id::TEXT,
    'medzen.vital_signs_encounter.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update lab_results template
CREATE OR REPLACE FUNCTION queue_lab_results_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'lab_results',
    NEW.id::TEXT,
    'medzen.laboratory_result_report.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update prescriptions template
CREATE OR REPLACE FUNCTION queue_prescriptions_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'prescriptions',
    NEW.id::TEXT,
    'medzen.medication_list.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 2. Specialty Encounter Templates
-- =====================================================

-- Update antenatal_visits template
CREATE OR REPLACE FUNCTION queue_antenatal_visits_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'medzen.antenatal_care_encounter.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update surgical_procedures template
CREATE OR REPLACE FUNCTION queue_surgical_procedures_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'surgical_procedures',
    NEW.id::TEXT,
    'medzen.surgical_procedure_record.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update admission_discharges template
CREATE OR REPLACE FUNCTION queue_admission_discharges_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'admission_discharges',
    NEW.id::TEXT,
    'medzen.admission_discharge_summary.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update medication_dispensing template
CREATE OR REPLACE FUNCTION queue_medication_dispensing_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'medication_dispensing',
    NEW.id::TEXT,
    'medzen.medication_dispensing_record.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update pharmacy_stock template
CREATE OR REPLACE FUNCTION queue_pharmacy_stock_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
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
    'pharmacy_stock',
    NEW.id::TEXT,
    'medzen.medication_dispensing_record.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update clinical_consultations template
CREATE OR REPLACE FUNCTION queue_clinical_consultations_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'clinical_consultations',
    NEW.id::TEXT,
    'medzen.clinical_consultation.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update oncology_treatments template
CREATE OR REPLACE FUNCTION queue_oncology_treatments_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'oncology_treatments',
    NEW.id::TEXT,
    'medzen.oncology_treatment_record.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update infectious_disease_visits template
CREATE OR REPLACE FUNCTION queue_infectious_disease_visits_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'infectious_disease_visits',
    NEW.id::TEXT,
    'medzen.infectious_disease_encounter.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update cardiology_visits template
CREATE OR REPLACE FUNCTION queue_cardiology_visits_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'cardiology_visits',
    NEW.id::TEXT,
    'medzen.cardiology_encounter.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update emergency_visits template
CREATE OR REPLACE FUNCTION queue_emergency_visits_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'emergency_visits',
    NEW.id::TEXT,
    'medzen.emergency_medicine_encounter.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update nephrology_visits template
CREATE OR REPLACE FUNCTION queue_nephrology_visits_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'nephrology_visits',
    NEW.id::TEXT,
    'medzen.nephrology_encounter.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update gastroenterology_procedures template
CREATE OR REPLACE FUNCTION queue_gastroenterology_procedures_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'gastroenterology_procedures',
    NEW.id::TEXT,
    'medzen.gastroenterology_procedure.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update endocrinology_visits template
CREATE OR REPLACE FUNCTION queue_endocrinology_visits_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'endocrinology_visits',
    NEW.id::TEXT,
    'medzen.endocrinology_encounter.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update pulmonology_visits template
CREATE OR REPLACE FUNCTION queue_pulmonology_visits_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'pulmonology_visits',
    NEW.id::TEXT,
    'medzen.pulmonology_encounter.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update psychiatric_assessments template
CREATE OR REPLACE FUNCTION queue_psychiatric_assessments_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'psychiatric_assessments',
    NEW.id::TEXT,
    'medzen.psychiatry_assessment.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update neurology_exams template
CREATE OR REPLACE FUNCTION queue_neurology_exams_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'neurology_exams',
    NEW.id::TEXT,
    'medzen.neurology_examination.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. Diagnostic & Treatment Templates
-- =====================================================

-- Update radiology_reports template
CREATE OR REPLACE FUNCTION queue_radiology_reports_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'radiology_reports',
    NEW.id::TEXT,
    'medzen.radiology_report.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update pathology_reports template
CREATE OR REPLACE FUNCTION queue_pathology_reports_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'pathology_reports',
    NEW.id::TEXT,
    'medzen.pathology_report.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Update physiotherapy_sessions template
CREATE OR REPLACE FUNCTION queue_physiotherapy_sessions_for_sync()
RETURNS TRIGGER AS $$
DECLARE
  v_ehr_id VARCHAR;
BEGIN
  SELECT ehr_id INTO v_ehr_id
  FROM electronic_health_records
  WHERE patient_id = NEW.patient_id;

  IF v_ehr_id IS NULL THEN
    RAISE WARNING 'No EHR found for patient %, skipping sync', NEW.patient_id;
    RETURN NEW;
  END IF;

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
    'physiotherapy_sessions',
    NEW.id::TEXT,
    'medzen.physiotherapy_session.v1',  -- ✅ UPDATED
    'composition_create',
    'pending',
    to_jsonb(NEW),
    NOW(),
    NOW()
  )
  ON CONFLICT (table_name, record_id, sync_type) DO UPDATE
  SET
    sync_status = 'pending',
    data_snapshot = to_jsonb(NEW),
    updated_at = NOW(),
    retry_count = 0,
    error_message = NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 4. Summary Comments
-- =====================================================

COMMENT ON FUNCTION queue_vital_signs_for_sync IS 'Updated template ID to medzen.vital_signs_encounter.v1 for production';
COMMENT ON FUNCTION queue_lab_results_for_sync IS 'Updated template ID to medzen.laboratory_result_report.v1 for production';
COMMENT ON FUNCTION queue_prescriptions_for_sync IS 'Updated template ID to medzen.medication_list.v1 for production';
COMMENT ON FUNCTION queue_antenatal_visits_for_sync IS 'Updated template ID to medzen.antenatal_care_encounter.v1 for production';
COMMENT ON FUNCTION queue_surgical_procedures_for_sync IS 'Updated template ID to medzen.surgical_procedure_record.v1 for production';

-- Migration complete
