-- Add soap_note column to clinical_notes table
-- This column consolidates SOAP fields with appointment and patient profile context
-- for easy retrieval and display in the pre-call clinical notes dialog

-- Add the soap_note column
ALTER TABLE clinical_notes
ADD COLUMN IF NOT EXISTS soap_note TEXT;

-- Create helper function to aggregate SOAP data from multiple tables
CREATE OR REPLACE FUNCTION build_soap_note(
  p_clinical_note_id UUID
) RETURNS TEXT AS $$
DECLARE
  v_appointment_overview RECORD;
  v_patient_profile RECORD;
  v_clinical_note RECORD;
  v_result TEXT := '';
BEGIN
  -- Fetch clinical note data
  SELECT * INTO v_clinical_note
  FROM clinical_notes
  WHERE id = p_clinical_note_id;

  IF v_clinical_note IS NULL THEN
    RETURN '';
  END IF;

  -- Fetch appointment context if available
  IF v_clinical_note.appointment_id IS NOT NULL THEN
    SELECT
      chief_complaint,
      notes,
      specialty,
      appointment_type,
      appointment_status,
      consultation_mode
    INTO v_appointment_overview
    FROM appointment_overview
    WHERE id = v_clinical_note.appointment_id;
  END IF;

  -- Fetch patient profile if available
  IF v_clinical_note.patient_id IS NOT NULL THEN
    SELECT
      blood_type,
      allergies,
      chronic_conditions,
      current_medications,
      diabetes_type,
      hypertension,
      kidney_issue,
      is_pregnant,
      last_blood_sugar,
      last_blood_pressure_systolic,
      last_blood_pressure_diastolic
    INTO v_patient_profile
    FROM patient_profiles
    WHERE user_id = v_clinical_note.patient_id;
  END IF;

  -- Build comprehensive SOAP note
  v_result := '';

  -- Appointment context section
  IF v_appointment_overview IS NOT NULL THEN
    v_result := v_result || 'APPOINTMENT CONTEXT:' || E'\n';
    v_result := v_result || 'Specialty: ' || COALESCE(v_appointment_overview.specialty, 'N/A') || E'\n';
    v_result := v_result || 'Type: ' || COALESCE(v_appointment_overview.appointment_type, 'N/A') || E'\n';
    v_result := v_result || 'Status: ' || COALESCE(v_appointment_overview.appointment_status, 'N/A') || E'\n';
    v_result := v_result || 'Mode: ' || COALESCE(v_appointment_overview.consultation_mode, 'N/A') || E'\n';
    IF v_appointment_overview.chief_complaint IS NOT NULL THEN
      v_result := v_result || 'Chief Complaint: ' || v_appointment_overview.chief_complaint || E'\n';
    END IF;
    IF v_appointment_overview.notes IS NOT NULL THEN
      v_result := v_result || 'Notes: ' || v_appointment_overview.notes || E'\n';
    END IF;
    v_result := v_result || E'\n';
  END IF;

  -- Patient profile context section
  IF v_patient_profile IS NOT NULL THEN
    v_result := v_result || 'PATIENT PROFILE:' || E'\n';
    v_result := v_result || 'Blood Type: ' || COALESCE(v_patient_profile.blood_type, 'N/A') || E'\n';

    IF v_patient_profile.allergies IS NOT NULL AND array_length(v_patient_profile.allergies, 1) > 0 THEN
      v_result := v_result || 'Allergies: ' || array_to_string(v_patient_profile.allergies, ', ') || E'\n';
    END IF;

    IF v_patient_profile.chronic_conditions IS NOT NULL AND array_length(v_patient_profile.chronic_conditions, 1) > 0 THEN
      v_result := v_result || 'Chronic Conditions: ' || array_to_string(v_patient_profile.chronic_conditions, ', ') || E'\n';
    END IF;

    IF v_patient_profile.current_medications IS NOT NULL AND array_length(v_patient_profile.current_medications, 1) > 0 THEN
      v_result := v_result || 'Current Medications: ' || array_to_string(v_patient_profile.current_medications, ', ') || E'\n';
    END IF;

    IF v_patient_profile.diabetes_type IS NOT NULL THEN
      v_result := v_result || 'Diabetes: ' || v_patient_profile.diabetes_type || E'\n';
    END IF;

    IF v_patient_profile.hypertension THEN
      v_result := v_result || 'Hypertension: Yes' || E'\n';
    END IF;

    IF v_patient_profile.kidney_issue THEN
      v_result := v_result || 'Kidney Issues: Yes' || E'\n';
    END IF;

    IF v_patient_profile.is_pregnant THEN
      v_result := v_result || 'Pregnancy Status: Yes' || E'\n';
    END IF;

    IF v_patient_profile.last_blood_sugar IS NOT NULL THEN
      v_result := v_result || 'Last Blood Sugar: ' || v_patient_profile.last_blood_sugar || E'\n';
    END IF;

    IF v_patient_profile.last_blood_pressure_systolic IS NOT NULL THEN
      v_result := v_result || 'Last BP: ' || v_patient_profile.last_blood_pressure_systolic || '/' || v_patient_profile.last_blood_pressure_diastolic || E'\n';
    END IF;

    v_result := v_result || E'\n';
  END IF;

  -- SOAP sections
  v_result := v_result || 'CLINICAL ASSESSMENT:' || E'\n';

  IF v_clinical_note.subjective IS NOT NULL THEN
    v_result := v_result || E'\nSUBJECTIVE:' || E'\n' || v_clinical_note.subjective || E'\n';
  END IF;

  IF v_clinical_note.objective IS NOT NULL THEN
    v_result := v_result || E'\nOBJECTIVE:' || E'\n' || v_clinical_note.objective || E'\n';
  END IF;

  IF v_clinical_note.assessment IS NOT NULL THEN
    v_result := v_result || E'\nASSESSMENT:' || E'\n' || v_clinical_note.assessment || E'\n';
  END IF;

  IF v_clinical_note.plan IS NOT NULL THEN
    v_result := v_result || E'\nPLAN:' || E'\n' || v_clinical_note.plan || E'\n';
  END IF;

  RETURN NULLIF(v_result, '');
END;
$$ LANGUAGE plpgsql STABLE;

-- Create or replace function to update soap_note when clinical notes change
CREATE OR REPLACE FUNCTION update_clinical_note_soap_note()
RETURNS TRIGGER AS $$
BEGIN
  NEW.soap_note := build_soap_note(NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update soap_note on insert or update
DROP TRIGGER IF EXISTS trigger_update_clinical_note_soap_note ON clinical_notes;
CREATE TRIGGER trigger_update_clinical_note_soap_note
BEFORE INSERT OR UPDATE ON clinical_notes
FOR EACH ROW
EXECUTE FUNCTION update_clinical_note_soap_note();

-- Add comment documenting the column
COMMENT ON COLUMN clinical_notes.soap_note IS 'Consolidated SOAP note combining clinical assessment with appointment context (specialty, type, chief complaint) and patient profile data (allergies, medications, chronic conditions, vitals); automatically updated via trigger when clinical notes change';
