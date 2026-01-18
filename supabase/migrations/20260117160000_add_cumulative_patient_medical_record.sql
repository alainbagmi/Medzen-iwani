-- Cumulative Patient Medical Record Implementation
-- Adds JSONB column to store comprehensive patient history
-- Enables pre-call display of complete patient context
-- Deduplicates and merges SOAP data across all visits

-- Add cumulative medical record column to patient_profiles
ALTER TABLE patient_profiles
ADD COLUMN cumulative_medical_record JSONB DEFAULT '{
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
}'::JSONB;

-- Track when cumulative record was last updated
ALTER TABLE patient_profiles
ADD COLUMN medical_record_last_updated_at TIMESTAMPTZ;

-- Track the last SOAP note that updated the cumulative record
ALTER TABLE patient_profiles
ADD COLUMN medical_record_last_soap_note_id UUID
REFERENCES soap_notes(id) ON DELETE SET NULL;

-- GIN index for efficient JSONB queries (searching conditions, medications, etc.)
CREATE INDEX idx_patient_profiles_cumulative_record_gin
ON patient_profiles USING GIN (cumulative_medical_record);

-- Covering index for pre-call queries (optimizes fetch of all pre-call data)
CREATE INDEX idx_patient_profiles_precall
ON patient_profiles(user_id)
INCLUDE (cumulative_medical_record, blood_type, medical_record_last_updated_at);

-- Function to intelligently merge SOAP data into cumulative record
-- Handles deduplication, status updates, and intelligent conflict resolution
CREATE OR REPLACE FUNCTION merge_soap_into_cumulative_record(
  p_patient_id UUID,
  p_soap_note_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_current_record JSONB;
  v_soap_data JSONB;
  v_merged JSONB;
  v_conditions JSONB;
  v_medications JSONB;
  v_allergies JSONB;
  v_surgical_history JSONB;
  v_family_history JSONB;
  v_vital_trends JSONB;
  v_social_history JSONB;
  v_metadata JSONB;
  v_new_condition JSONB;
  v_new_medication JSONB;
  v_new_allergy JSONB;
  v_condition_exists BOOLEAN;
  v_medication_exists BOOLEAN;
  v_allergy_exists BOOLEAN;
BEGIN
  -- Get current cumulative record (or initialize if NULL)
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
    "metadata": {
      "total_visits": 0,
      "source_soap_notes": [],
      "last_updated": null
    }
  }'::JSONB)
  INTO v_current_record
  FROM patient_profiles
  WHERE user_id = p_patient_id;

  -- Get SOAP note data from soap_notes table
  SELECT jsonb_build_object(
    'assessment_problem_list', (SELECT jsonb_agg(
      jsonb_build_object(
        'diagnosis_description', diagnosis_description,
        'icd10_code', icd10_code,
        'status', 'active',
        'severity', severity,
        'onset_date', created_at
      )
    ) FROM (
      SELECT DISTINCT diagnosis_description, icd10_code, severity FROM soap_assessment_problem_list
      WHERE soap_id = p_soap_note_id
    ) t),
    'medication_list', (SELECT jsonb_agg(
      jsonb_build_object(
        'name', medication_name,
        'generic_name', generic_name,
        'dose', dose,
        'route', route,
        'frequency', frequency,
        'status', 'active'
      )
    ) FROM (
      SELECT DISTINCT medication_name, generic_name, dose, route, frequency FROM soap_medication_list
      WHERE soap_id = p_soap_note_id
    ) t),
    'allergies', (SELECT jsonb_agg(
      jsonb_build_object(
        'allergen', allergen,
        'type', allergy_type,
        'severity', severity,
        'reaction', reaction,
        'status', 'active'
      )
    ) FROM (
      SELECT DISTINCT allergen, allergy_type, severity, reaction FROM soap_allergies
      WHERE soap_id = p_soap_note_id
    ) t),
    'surgical_history', (SELECT jsonb_agg(
      jsonb_build_object(
        'procedure', procedure_name,
        'date', procedure_date,
        'complications', complications
      )
    ) FROM (
      SELECT DISTINCT procedure_name, procedure_date, complications FROM soap_surgical_history
      WHERE soap_id = p_soap_note_id
    ) t),
    'family_history', (SELECT jsonb_agg(
      jsonb_build_object(
        'condition', family_condition,
        'relationship', relationship,
        'age_of_onset', age_of_onset
      )
    ) FROM (
      SELECT DISTINCT family_condition, relationship, age_of_onset FROM soap_family_history
      WHERE soap_id = p_soap_note_id
    ) t),
    'vital_signs', (SELECT jsonb_build_object(
      'systolic', bp_systolic,
      'diastolic', bp_diastolic,
      'heart_rate', heart_rate,
      'temperature_c', temperature_c,
      'spo2_percent', spo2_percent,
      'weight_kg', weight_kg,
      'bmi', bmi,
      'timestamp', s.created_at
    ) FROM soap_vitals s WHERE s.soap_id = p_soap_note_id LIMIT 1),
    'social_history', (SELECT jsonb_build_object(
      'tobacco', tobacco_use,
      'alcohol', alcohol_use,
      'occupation', occupation
    ) FROM soap_social_history WHERE soap_id = p_soap_note_id LIMIT 1)
  ) INTO v_soap_data;

  -- Initialize merged structure from current
  v_merged := v_current_record;

  -- Initialize arrays
  v_conditions := COALESCE(v_current_record->'conditions', '[]'::JSONB);
  v_medications := COALESCE(v_current_record->'medications', '[]'::JSONB);
  v_allergies := COALESCE(v_current_record->'allergies', '[]'::JSONB);
  v_surgical_history := COALESCE(v_current_record->'surgical_history', '[]'::JSONB);
  v_family_history := COALESCE(v_current_record->'family_history', '[]'::JSONB);
  v_vital_trends := COALESCE(v_current_record->'vital_trends', '{}'::JSONB);
  v_social_history := COALESCE(v_current_record->'social_history', '{}'::JSONB);
  v_metadata := COALESCE(v_current_record->'metadata', '{
    "total_visits": 0,
    "source_soap_notes": [],
    "last_updated": null
  }'::JSONB);

  -- Process conditions (dedup by name + icd10)
  IF v_soap_data->'assessment_problem_list' IS NOT NULL THEN
    FOR v_new_condition IN
      SELECT jsonb_array_elements(v_soap_data->'assessment_problem_list')
    LOOP
      v_condition_exists := FALSE;

      -- Check if condition already exists
      IF (SELECT COUNT(*) FROM jsonb_array_elements(v_conditions) c
          WHERE LOWER((c->>'name')::TEXT) = LOWER((v_new_condition->>'diagnosis_description')::TEXT)
          AND c->>'icd10' = v_new_condition->>'icd10_code') > 0
      THEN
        v_condition_exists := TRUE;
        -- Update status if changed
        v_conditions := (
          SELECT jsonb_agg(
            CASE
              WHEN LOWER((c->>'name')::TEXT) = LOWER((v_new_condition->>'diagnosis_description')::TEXT)
                   AND c->>'icd10' = v_new_condition->>'icd10_code'
              THEN c || jsonb_build_object(
                'status', v_new_condition->>'status',
                'last_updated', NOW()::TEXT,
                'added_from_soap_note_id', p_soap_note_id::TEXT
              )
              ELSE c
            END
          )
          FROM jsonb_array_elements(v_conditions) c
        );
      END IF;

      -- Add new condition if not found
      IF NOT v_condition_exists THEN
        v_conditions := v_conditions || jsonb_build_array(
          v_new_condition || jsonb_build_object(
            'added_from_soap_note_id', p_soap_note_id::TEXT,
            'last_updated', NOW()::TEXT
          )
        );
      END IF;
    END LOOP;
  END IF;

  -- Process medications (dedup by name)
  IF v_soap_data->'medication_list' IS NOT NULL THEN
    FOR v_new_medication IN
      SELECT jsonb_array_elements(v_soap_data->'medication_list')
    LOOP
      v_medication_exists := FALSE;

      -- Check if medication already exists
      IF (SELECT COUNT(*) FROM jsonb_array_elements(v_medications) m
          WHERE LOWER((m->>'name')::TEXT) = LOWER((v_new_medication->>'name')::TEXT)) > 0
      THEN
        v_medication_exists := TRUE;
        -- Update dose/frequency/status if changed
        v_medications := (
          SELECT jsonb_agg(
            CASE
              WHEN LOWER((m->>'name')::TEXT) = LOWER((v_new_medication->>'name')::TEXT)
              THEN m || jsonb_build_object(
                'dose', v_new_medication->>'dose',
                'frequency', v_new_medication->>'frequency',
                'status', v_new_medication->>'status',
                'last_updated', NOW()::TEXT,
                'added_from_soap_note_id', p_soap_note_id::TEXT
              )
              ELSE m
            END
          )
          FROM jsonb_array_elements(v_medications) m
        );
      END IF;

      -- Add new medication if not found
      IF NOT v_medication_exists THEN
        v_medications := v_medications || jsonb_build_array(
          v_new_medication || jsonb_build_object(
            'added_from_soap_note_id', p_soap_note_id::TEXT,
            'last_updated', NOW()::TEXT
          )
        );
      END IF;
    END LOOP;
  END IF;

  -- Process allergies (dedup by allergen, keep highest severity)
  IF v_soap_data->'allergies' IS NOT NULL THEN
    FOR v_new_allergy IN
      SELECT jsonb_array_elements(v_soap_data->'allergies')
    LOOP
      v_allergy_exists := FALSE;

      -- Check if allergy already exists
      IF (SELECT COUNT(*) FROM jsonb_array_elements(v_allergies) a
          WHERE LOWER((a->>'allergen')::TEXT) = LOWER((v_new_allergy->>'allergen')::TEXT)) > 0
      THEN
        v_allergy_exists := TRUE;
        -- Update to higher severity if applicable
        v_allergies := (
          SELECT jsonb_agg(
            CASE
              WHEN LOWER((a->>'allergen')::TEXT) = LOWER((v_new_allergy->>'allergen')::TEXT)
              THEN a || jsonb_build_object(
                'severity', CASE
                  WHEN (a->>'severity')::TEXT = 'severe' THEN 'severe'
                  WHEN (v_new_allergy->>'severity')::TEXT = 'severe' THEN 'severe'
                  WHEN (a->>'severity')::TEXT = 'moderate' THEN 'moderate'
                  WHEN (v_new_allergy->>'severity')::TEXT = 'moderate' THEN 'moderate'
                  ELSE 'mild'
                END,
                'status', v_new_allergy->>'status',
                'last_updated', NOW()::TEXT,
                'added_from_soap_note_id', p_soap_note_id::TEXT
              )
              ELSE a
            END
          )
          FROM jsonb_array_elements(v_allergies) a
        );
      END IF;

      -- Add new allergy if not found
      IF NOT v_allergy_exists THEN
        v_allergies := v_allergies || jsonb_build_array(
          v_new_allergy || jsonb_build_object(
            'added_from_soap_note_id', p_soap_note_id::TEXT,
            'last_updated', NOW()::TEXT
          )
        );
      END IF;
    END LOOP;
  END IF;

  -- Process surgical history (dedup by procedure + date)
  IF v_soap_data->'surgical_history' IS NOT NULL THEN
    FOR v_surgical_history IN
      SELECT jsonb_array_elements(v_soap_data->'surgical_history')
    LOOP
      IF (SELECT COUNT(*) FROM jsonb_array_elements(v_surgical_history) s
          WHERE LOWER((s->>'procedure')::TEXT) = LOWER((v_surgical_history->>'procedure')::TEXT)
          AND s->>'date' = v_surgical_history->>'date') = 0
      THEN
        v_surgical_history := v_surgical_history || jsonb_build_array(
          v_surgical_history || jsonb_build_object('added_from_soap_note_id', p_soap_note_id::TEXT)
        );
      END IF;
    END LOOP;
  END IF;

  -- Process family history (keep first entry - immutable)
  IF v_soap_data->'family_history' IS NOT NULL THEN
    FOR v_family_history IN
      SELECT jsonb_array_elements(v_soap_data->'family_history')
    LOOP
      IF (SELECT COUNT(*) FROM jsonb_array_elements(v_family_history) f
          WHERE LOWER((f->>'condition')::TEXT) = LOWER((v_family_history->>'condition')::TEXT)
          AND f->>'relationship' = v_family_history->>'relationship') = 0
      THEN
        v_family_history := v_family_history || jsonb_build_array(
          v_family_history || jsonb_build_object('added_from_soap_note_id', p_soap_note_id::TEXT)
        );
      END IF;
    END LOOP;
  END IF;

  -- Process vital trends (always update to latest)
  IF v_soap_data->'vital_signs' IS NOT NULL AND v_soap_data->'vital_signs' != 'null'::JSONB THEN
    v_vital_trends := jsonb_build_object(
      'last_bp_systolic', v_soap_data->'vital_signs'->>'systolic',
      'last_bp_diastolic', v_soap_data->'vital_signs'->>'diastolic',
      'last_heart_rate', v_soap_data->'vital_signs'->>'heart_rate',
      'last_temperature_c', v_soap_data->'vital_signs'->>'temperature_c',
      'last_spo2_percent', v_soap_data->'vital_signs'->>'spo2_percent',
      'last_weight_kg', v_soap_data->'vital_signs'->>'weight_kg',
      'last_bmi', v_soap_data->'vital_signs'->>'bmi',
      'last_measured', v_soap_data->'vital_signs'->>'timestamp'
    );
  END IF;

  -- Process social history (update to latest)
  IF v_soap_data->'social_history' IS NOT NULL AND v_soap_data->'social_history' != 'null'::JSONB THEN
    v_social_history := v_soap_data->'social_history' || jsonb_build_object(
      'last_updated', NOW()::TEXT
    );
  END IF;

  -- Update metadata
  v_metadata := jsonb_build_object(
    'total_visits', COALESCE((v_metadata->>'total_visits')::INT, 0) + 1,
    'last_visit_date', NOW()::DATE::TEXT,
    'source_soap_notes', COALESCE(v_metadata->'source_soap_notes', '[]'::JSONB) ||
                        jsonb_build_array(p_soap_note_id::TEXT),
    'last_updated', NOW()::TEXT
  );

  -- Build final merged record
  v_merged := jsonb_build_object(
    'conditions', v_conditions,
    'medications', v_medications,
    'allergies', v_allergies,
    'surgical_history', v_surgical_history,
    'family_history', v_family_history,
    'vital_trends', v_vital_trends,
    'social_history', v_social_history,
    'review_of_systems_trends', COALESCE(v_current_record->'review_of_systems_trends', '{}'::JSONB),
    'physical_exam_findings', COALESCE(v_current_record->'physical_exam_findings', '{}'::JSONB),
    'metadata', v_metadata
  );

  -- Update patient_profiles
  UPDATE patient_profiles
  SET
    cumulative_medical_record = v_merged,
    medical_record_last_updated_at = NOW(),
    medical_record_last_soap_note_id = p_soap_note_id
  WHERE user_id = p_patient_id;

  RETURN v_merged;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path TO public;

-- Function to rollback patient record update (removes all data from specific SOAP note)
CREATE OR REPLACE FUNCTION rollback_patient_record_update(
  p_patient_id UUID,
  p_soap_note_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
  v_current_record JSONB;
  v_rolled_back JSONB;
BEGIN
  -- Get current cumulative record
  SELECT cumulative_medical_record
  INTO v_current_record
  FROM patient_profiles
  WHERE user_id = p_patient_id;

  IF v_current_record IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Remove all items with added_from_soap_note_id = p_soap_note_id
  v_rolled_back := jsonb_build_object(
    'conditions', (
      SELECT COALESCE(jsonb_agg(c), '[]'::JSONB)
      FROM jsonb_array_elements(v_current_record->'conditions') c
      WHERE (c->>'added_from_soap_note_id')::UUID != p_soap_note_id
    ),
    'medications', (
      SELECT COALESCE(jsonb_agg(m), '[]'::JSONB)
      FROM jsonb_array_elements(v_current_record->'medications') m
      WHERE (m->>'added_from_soap_note_id')::UUID != p_soap_note_id
    ),
    'allergies', (
      SELECT COALESCE(jsonb_agg(a), '[]'::JSONB)
      FROM jsonb_array_elements(v_current_record->'allergies') a
      WHERE (a->>'added_from_soap_note_id')::UUID != p_soap_note_id
    ),
    'surgical_history', (
      SELECT COALESCE(jsonb_agg(s), '[]'::JSONB)
      FROM jsonb_array_elements(v_current_record->'surgical_history') s
      WHERE (s->>'added_from_soap_note_id')::UUID != p_soap_note_id
    ),
    'family_history', (
      SELECT COALESCE(jsonb_agg(f), '[]'::JSONB)
      FROM jsonb_array_elements(v_current_record->'family_history') f
      WHERE (f->>'added_from_soap_note_id')::UUID != p_soap_note_id
    ),
    'vital_trends', v_current_record->'vital_trends',
    'social_history', v_current_record->'social_history',
    'review_of_systems_trends', v_current_record->'review_of_systems_trends',
    'physical_exam_findings', v_current_record->'physical_exam_findings',
    'metadata', (
      SELECT jsonb_build_object(
        'total_visits', GREATEST(0, COALESCE((v_current_record->'metadata'->>'total_visits')::INT, 1) - 1),
        'last_visit_date', v_current_record->'metadata'->>'last_visit_date',
        'source_soap_notes', (
          SELECT COALESCE(jsonb_agg(n), '[]'::JSONB)
          FROM jsonb_array_elements(v_current_record->'metadata'->'source_soap_notes') n
          WHERE n::TEXT != ('\"' || p_soap_note_id::TEXT || '\"')
        ),
        'last_updated', NOW()::TEXT
      )
    )
  );

  -- Update patient_profiles
  UPDATE patient_profiles
  SET
    cumulative_medical_record = v_rolled_back,
    medical_record_last_updated_at = NOW()
  WHERE user_id = p_patient_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path TO public;

-- Grant permissions to authenticated users and service role
GRANT EXECUTE ON FUNCTION merge_soap_into_cumulative_record TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION rollback_patient_record_update TO service_role;

-- Create trigger to automatically update cumulative record when new SOAP note is created
CREATE OR REPLACE FUNCTION update_cumulative_record_on_soap_insert()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM merge_soap_into_cumulative_record(NEW.patient_id, NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_update_cumulative_record_on_soap_insert
AFTER INSERT ON soap_notes
FOR EACH ROW
EXECUTE FUNCTION update_cumulative_record_on_soap_insert();

-- Add comment for documentation
COMMENT ON COLUMN patient_profiles.cumulative_medical_record IS 'Comprehensive patient medical record accumulated across all visits. JSONB structure includes: conditions, medications, allergies, surgical_history, family_history, vital_trends, social_history, and metadata. Updated automatically when new SOAP notes are created.';

COMMENT ON COLUMN patient_profiles.medical_record_last_updated_at IS 'Timestamp of the most recent cumulative record update';

COMMENT ON COLUMN patient_profiles.medical_record_last_soap_note_id IS 'Reference to the most recent SOAP note that updated the cumulative record';

COMMENT ON FUNCTION merge_soap_into_cumulative_record IS 'Intelligently merges SOAP note data into cumulative patient medical record with deduplication. Rules: conditions dedup by name+icd10 (update status), medications dedup by name (update dose), allergies dedup by allergen (keep highest severity), surgical/family history dedup by full key (immutable).';

COMMENT ON FUNCTION rollback_patient_record_update IS 'Admin function to rollback a specific SOAP note update from the cumulative record. Removes all data with added_from_soap_note_id = p_soap_note_id.';
