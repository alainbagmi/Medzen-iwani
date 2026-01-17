-- Add cumulative medical record system for patient history tracking
-- This migration adds JSONB-based cumulative patient medical records that grow with each visit

-- Add columns to patient_profiles table
ALTER TABLE patient_profiles
ADD COLUMN IF NOT EXISTS cumulative_medical_record JSONB DEFAULT '{
  "conditions": [],
  "medications": [],
  "allergies": [],
  "surgical_history": [],
  "family_history": [],
  "vital_trends": {},
  "social_history": {},
  "review_of_systems_trends": {},
  "physical_exam_findings": {},
  "metadata": {
    "total_visits": 0,
    "source_soap_notes": [],
    "last_updated": null
  }
}'::JSONB,
ADD COLUMN IF NOT EXISTS medical_record_last_updated_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS medical_record_last_soap_note_id UUID;

-- Add foreign key constraint for medical_record_last_soap_note_id
ALTER TABLE patient_profiles
ADD CONSTRAINT fk_patient_profiles_medical_record_soap_note
FOREIGN KEY (medical_record_last_soap_note_id)
REFERENCES soap_notes(id) ON DELETE SET NULL;

-- Create GIN index for fast JSONB queries
CREATE INDEX IF NOT EXISTS idx_patient_profiles_cumulative_record_gin
ON patient_profiles USING GIN (cumulative_medical_record);

-- Create covering index for pre-call queries (optimizes provider waiting time)
CREATE INDEX IF NOT EXISTS idx_patient_profiles_precall
ON patient_profiles(user_id)
INCLUDE (cumulative_medical_record, blood_type, medical_record_last_updated_at);

-- Function to deduplicate and merge SOAP data into cumulative record
-- This function is called from the edge function with pre-extracted SOAP data
CREATE OR REPLACE FUNCTION merge_soap_into_cumulative_record(
  p_patient_id UUID,
  p_soap_note_id UUID,
  p_soap_data JSONB
) RETURNS JSONB AS $$
DECLARE
  v_current_record JSONB;
  v_merged JSONB;
  v_conditions JSONB;
  v_medications JSONB;
  v_allergies JSONB;
  v_new_condition JSONB;
  v_new_medication JSONB;
  v_new_allergy JSONB;
  v_idx INT;
  v_found BOOLEAN;
BEGIN
  -- Get current cumulative record (or start fresh)
  SELECT COALESCE(cumulative_medical_record, '{
    "conditions": [],
    "medications": [],
    "allergies": [],
    "surgical_history": [],
    "family_history": [],
    "vital_trends": {},
    "social_history": {},
    "review_of_systems_trends": {},
    "physical_exam_findings": {},
    "metadata": {"total_visits": 0, "source_soap_notes": [], "last_updated": null}
  }'::JSONB)
  INTO v_current_record
  FROM patient_profiles
  WHERE user_id = p_patient_id;

  -- Start with current record as base
  v_merged := v_current_record;

  -- DEDUPLICATION: Conditions (dedupe by name + icd10)
  v_conditions := COALESCE(v_merged->'conditions', '[]'::JSONB);
  FOR v_new_condition IN SELECT * FROM jsonb_array_elements(COALESCE(p_soap_data->'conditions', '[]'::JSONB))
  LOOP
    v_found := FALSE;
    FOR v_idx IN 0..jsonb_array_length(v_conditions)-1
    LOOP
      IF LOWER((v_conditions->v_idx->>'name')) = LOWER((v_new_condition->>'name'))
         AND (v_conditions->v_idx->>'icd10') = (v_new_condition->>'icd10')
      THEN
        -- Update status if changed (resolved → active = recurrence)
        IF (v_conditions->v_idx->>'status') != (v_new_condition->>'status') THEN
          v_conditions := jsonb_set(
            v_conditions,
            ARRAY[v_idx::text, 'status'],
            to_jsonb(v_new_condition->>'status')
          );
          v_conditions := jsonb_set(
            v_conditions,
            ARRAY[v_idx::text, 'last_updated'],
            to_jsonb(NOW()::text)
          );
        END IF;
        v_found := TRUE;
        EXIT;
      END IF;
    END LOOP;

    -- Add new condition if not found
    IF NOT v_found THEN
      v_conditions := v_conditions || jsonb_build_array(
        v_new_condition || jsonb_build_object(
          'added_from_soap_note_id', p_soap_note_id::text,
          'last_updated', NOW()::text
        )
      );
    END IF;
  END LOOP;

  v_merged := jsonb_set(v_merged, '{conditions}', v_conditions);

  -- DEDUPLICATION: Medications (dedupe by name, update dose/frequency if changed)
  v_medications := COALESCE(v_merged->'medications', '[]'::JSONB);
  FOR v_new_medication IN SELECT * FROM jsonb_array_elements(COALESCE(p_soap_data->'medications', '[]'::JSONB))
  LOOP
    v_found := FALSE;
    FOR v_idx IN 0..jsonb_array_length(v_medications)-1
    LOOP
      IF LOWER((v_medications->v_idx->>'name')) = LOWER((v_new_medication->>'name'))
      THEN
        -- Update dose/frequency if changed
        IF (v_medications->v_idx->>'dose') != (v_new_medication->>'dose')
           OR (v_medications->v_idx->>'frequency') != (v_new_medication->>'frequency')
           OR (v_medications->v_idx->>'status') != (v_new_medication->>'status')
        THEN
          v_medications := jsonb_set(v_medications, ARRAY[v_idx::text, 'dose'], to_jsonb(v_new_medication->>'dose'));
          v_medications := jsonb_set(v_medications, ARRAY[v_idx::text, 'frequency'], to_jsonb(v_new_medication->>'frequency'));
          v_medications := jsonb_set(v_medications, ARRAY[v_idx::text, 'status'], to_jsonb(v_new_medication->>'status'));
          v_medications := jsonb_set(v_medications, ARRAY[v_idx::text, 'last_updated'], to_jsonb(NOW()::text));
        END IF;
        v_found := TRUE;
        EXIT;
      END IF;
    END LOOP;

    -- Add new medication if not found
    IF NOT v_found THEN
      v_medications := v_medications || jsonb_build_array(
        v_new_medication || jsonb_build_object(
          'added_from_soap_note_id', p_soap_note_id::text,
          'last_updated', NOW()::text
        )
      );
    END IF;
  END LOOP;

  v_merged := jsonb_set(v_merged, '{medications}', v_medications);

  -- DEDUPLICATION: Allergies (dedupe by allergen, keep highest severity)
  v_allergies := COALESCE(v_merged->'allergies', '[]'::JSONB);
  FOR v_new_allergy IN SELECT * FROM jsonb_array_elements(COALESCE(p_soap_data->'allergies', '[]'::JSONB))
  LOOP
    v_found := FALSE;
    FOR v_idx IN 0..jsonb_array_length(v_allergies)-1
    LOOP
      IF LOWER((v_allergies->v_idx->>'allergen')) = LOWER((v_new_allergy->>'allergen'))
      THEN
        -- Keep highest severity
        IF (v_allergies->v_idx->>'severity') != (v_new_allergy->>'severity') THEN
          v_allergies := jsonb_set(
            v_allergies,
            ARRAY[v_idx::text, 'severity'],
            to_jsonb(v_new_allergy->>'severity')
          );
          v_allergies := jsonb_set(
            v_allergies,
            ARRAY[v_idx::text, 'last_updated'],
            to_jsonb(NOW()::text)
          );
        END IF;
        v_found := TRUE;
        EXIT;
      END IF;
    END LOOP;

    -- Add new allergy if not found
    IF NOT v_found THEN
      v_allergies := v_allergies || jsonb_build_array(
        v_new_allergy || jsonb_build_object(
          'status', 'active',
          'added_from_soap_note_id', p_soap_note_id::text,
          'last_updated', NOW()::text
        )
      );
    END IF;
  END LOOP;

  v_merged := jsonb_set(v_merged, '{allergies}', v_allergies);

  -- Update vital trends (always use latest)
  IF p_soap_data->'vital_trends' IS NOT NULL THEN
    v_merged := jsonb_set(v_merged, '{vital_trends}',
      (p_soap_data->'vital_trends') || jsonb_build_object(
        'last_measured', NOW()::text
      )
    );
  END IF;

  -- Update metadata
  v_merged := jsonb_set(
    v_merged,
    '{metadata,total_visits}',
    to_jsonb((COALESCE((v_merged->'metadata'->>'total_visits')::INT, 0) + 1))
  );

  v_merged := jsonb_set(
    v_merged,
    '{metadata,last_updated}',
    to_jsonb(NOW()::text)
  );

  -- Add soap note ID to source list (avoid duplicates)
  IF NOT (v_merged->'metadata'->'source_soap_notes' @> to_jsonb(p_soap_note_id::text)) THEN
    v_merged := jsonb_set(
      v_merged,
      '{metadata,source_soap_notes}',
      (v_merged->'metadata'->'source_soap_notes') || jsonb_build_array(p_soap_note_id::text)
    );
  END IF;

  -- Update patient_profiles with merged record
  UPDATE patient_profiles
  SET
    cumulative_medical_record = v_merged,
    medical_record_last_updated_at = NOW(),
    medical_record_last_soap_note_id = p_soap_note_id
  WHERE user_id = p_patient_id;

  RETURN v_merged;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION merge_soap_into_cumulative_record(UUID, UUID, JSONB) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION merge_soap_into_cumulative_record(UUID, UUID, JSONB) IS
  'Merges SOAP note data into patient cumulative medical record with intelligent deduplication.
   Parameters:
   - p_patient_id: UUID of patient
   - p_soap_note_id: UUID of source SOAP note
   - p_soap_data: JSONB structure with conditions, medications, allergies, vital_trends
   Deduplication rules:
   - Conditions: dedupe by (name, icd10), update status if changed
   - Medications: dedupe by name, update dose/frequency if changed
   - Allergies: dedupe by allergen, keep highest severity
   - Vitals: always update to latest
   Returns updated JSONB record.';

COMMENT ON COLUMN patient_profiles.cumulative_medical_record IS
  'JSONB containing cumulative patient medical record across all visits.
   Schema: {conditions, medications, allergies, surgical_history, family_history,
   vital_trends, social_history, review_of_systems_trends, physical_exam_findings, metadata}';

COMMENT ON COLUMN patient_profiles.medical_record_last_updated_at IS
  'Timestamp of last cumulative record update';

COMMENT ON COLUMN patient_profiles.medical_record_last_soap_note_id IS
  'Reference to last SOAP note that updated the cumulative record';
