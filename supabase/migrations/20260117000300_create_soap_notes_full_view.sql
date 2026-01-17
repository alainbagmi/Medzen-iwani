-- Create Comprehensive SOAP Notes View
-- Aggregates normalized SOAP data back into hierarchical JSON structure
-- Date: 2026-01-17

/**
 * soap_notes_full: Complete SOAP note reconstruction view
 * Joins all normalized tables to reconstruct the full SOAP note with all details
 */
CREATE OR REPLACE VIEW public.soap_notes_full AS
SELECT
  sn.id,
  sn.session_id,
  sn.appointment_id,
  sn.call_transcript_id,
  sn.provider_id,
  sn.patient_id,
  sn.status,
  sn.version,
  sn.is_real_time_draft,
  sn.encounter_type,
  sn.visit_type,
  sn.chief_complaint,
  sn.reason_for_visit,
  sn.consent_obtained,
  sn.consent_timestamp,
  sn.language_used,
  -- AI metadata
  sn.ai_generated_at,
  sn.ai_model_used,
  sn.ai_confidence_score,
  sn.ai_generation_prompt_version,
  sn.ai_raw_response,
  -- Clinician workflow
  sn.requires_clinician_review,
  sn.reviewed_by,
  sn.reviewed_at,
  sn.review_notes,
  sn.signed_by,
  sn.signed_at,
  sn.signature_hash,
  -- EHR sync
  sn.ehr_sync_status,
  sn.ehr_sync_error,
  sn.synced_at,
  sn.ehrbase_composition_uid,
  sn.created_at,
  sn.updated_at,
  sn.submitted_at,
  -- Aggregated data
  (
    SELECT jsonb_build_object(
      'narrative', shp.hpi_narrative,
      'symptom_onset', shp.symptom_onset,
      'duration', shp.duration,
      'location', shp.location,
      'radiation', shp.radiation,
      'quality', shp.quality,
      'severity_scale_0_10', shp.severity_scale,
      'timing', shp.timing_pattern,
      'context', shp.context,
      'modifying_factors', jsonb_build_object(
        'aggravating', COALESCE(shp.aggravating_factors, ARRAY[]::TEXT[]),
        'relieving', COALESCE(shp.relieving_factors, ARRAY[]::TEXT[])
      ),
      'associated_symptoms', COALESCE(shp.associated_symptoms, ARRAY[]::TEXT[]),
      'pertinent_negatives', COALESCE(shp.pertinent_negatives, ARRAY[]::TEXT[])
    )
    FROM public.soap_hpi_details shp
    WHERE shp.soap_note_id = sn.id
  ) AS subjective_hpi,
  -- ROS
  (
    SELECT jsonb_object_agg(
      srs.system_name,
      jsonb_build_object(
        'has_symptoms', srs.has_symptoms,
        'positives', COALESCE(srs.symptoms_positive, ARRAY[]::TEXT[]),
        'negatives', COALESCE(srs.symptoms_negative, ARRAY[]::TEXT[]),
        'unknown', COALESCE(srs.symptoms_unknown, ARRAY[]::TEXT[]),
        'severity', srs.severity,
        'duration_description', srs.duration_description,
        'onset_description', srs.onset_description
      )
    )
    FROM public.soap_review_of_systems srs
    WHERE srs.soap_note_id = sn.id
  ) AS subjective_ros,
  -- Medications
  (
    SELECT jsonb_agg(
      jsonb_build_object(
        'id', sm.id,
        'source', sm.source,
        'name', sm.medication_name,
        'generic_name', sm.generic_name,
        'dose', sm.dose,
        'route', sm.route,
        'frequency', sm.frequency,
        'duration', sm.duration,
        'start_date', sm.start_date,
        'end_date', sm.end_date,
        'indication', sm.indication,
        'status', sm.status,
        'contraindications', COALESCE(sm.contraindications, ARRAY[]::TEXT[]),
        'drug_interactions', COALESCE(sm.drug_interactions, ARRAY[]::TEXT[]),
        'side_effects_to_monitor', COALESCE(sm.side_effects_to_monitor, ARRAY[]::TEXT[]),
        'requires_monitoring', sm.requires_monitoring,
        'monitoring_plan', sm.monitoring_plan,
        'adherence', sm.adherence
      )
    )
    FROM public.soap_medications sm
    WHERE sm.soap_note_id = sn.id
  ) AS subjective_medications,
  -- Allergies
  (
    SELECT jsonb_agg(
      jsonb_build_object(
        'id', sa.id,
        'allergen', sa.allergen,
        'allergen_type', sa.allergen_type,
        'reaction', sa.reaction,
        'severity', sa.severity,
        'onset_date', sa.onset_date,
        'status', sa.status
      )
    )
    FROM public.soap_allergies sa
    WHERE sa.soap_note_id = sn.id
  ) AS subjective_allergies,
  -- History items (PMH, PSH, FH, SH)
  (
    SELECT jsonb_agg(
      jsonb_build_object(
        'id', shi.id,
        'history_type', shi.history_type,
        'condition_name', shi.condition_name,
        'icd10_code', shi.icd10_code,
        'onset_date', shi.onset_date,
        'status', shi.status,
        'surgery_name', shi.surgery_name,
        'surgery_date', shi.surgery_date,
        'complications', shi.complications,
        'relationship', shi.relationship,
        'condition', shi.condition,
        'age_of_onset', shi.age_of_onset,
        'category', shi.category,
        'value', shi.value,
        'frequency', shi.frequency
      )
    )
    FROM public.soap_history_items shi
    WHERE shi.soap_note_id = sn.id
  ) AS subjective_history_items,
  -- Vital signs
  (
    SELECT jsonb_build_object(
      'measured', TRUE,
      'source', COALESCE(MAX(svs.source), 'unknown'),
      'bp_mmHg', CONCAT_WS('/', MAX(svs.blood_pressure_systolic), MAX(svs.blood_pressure_diastolic)),
      'hr_bpm', MAX(svs.heart_rate),
      'rr_bpm', MAX(svs.respiratory_rate),
      'temp_c', MAX(svs.temperature_value),
      'spo2_percent', MAX(svs.oxygen_saturation),
      'weight_kg', MAX(svs.weight_kg),
      'height_cm', MAX(svs.height_cm),
      'bmi', MAX(svs.bmi),
      'measurements', jsonb_agg(
        jsonb_build_object(
          'id', svs.id,
          'measurement_time', svs.measurement_time,
          'source', svs.source,
          'temperature_value', svs.temperature_value,
          'blood_pressure', CONCAT_WS('/', svs.blood_pressure_systolic, svs.blood_pressure_diastolic),
          'heart_rate', svs.heart_rate,
          'respiratory_rate', svs.respiratory_rate,
          'oxygen_saturation', svs.oxygen_saturation,
          'weight_kg', svs.weight_kg,
          'height_cm', svs.height_cm,
          'bmi', svs.bmi,
          'pain_score', svs.pain_score
        )
      )
    )
    FROM public.soap_vital_signs svs
    WHERE svs.soap_note_id = sn.id
  ) AS objective_vitals,
  -- Physical exam
  (
    SELECT jsonb_object_agg(
      spe.system_name,
      jsonb_build_object(
        'id', spe.id,
        'is_abnormal', spe.is_abnormal,
        'findings', COALESCE(spe.findings, ARRAY[]::TEXT[]),
        'clinical_significance', spe.clinical_significance,
        'limited_by_telemedicine', spe.limited_by_telemedicine,
        'visual_inspection_only', spe.visual_inspection_only,
        'observation_notes', spe.observation_notes
      )
    )
    FROM public.soap_physical_exam spe
    WHERE spe.soap_note_id = sn.id
  ) AS objective_physical_exam,
  -- Assessment items
  (
    SELECT jsonb_agg(
      jsonb_build_object(
        'id', sai.id,
        'problem_number', sai.problem_number,
        'diagnosis_description', sai.diagnosis_description,
        'icd10_code', sai.icd10_code,
        'icd10_description', sai.icd10_description,
        'snomed_code', sai.snomed_code,
        'is_primary_diagnosis', sai.is_primary_diagnosis,
        'status', sai.status,
        'severity', sai.severity,
        'confidence', sai.confidence,
        'likelihood_percentage', sai.likelihood_percentage,
        'key_findings', COALESCE(sai.key_findings, ARRAY[]::TEXT[]),
        'pertinent_negatives', COALESCE(sai.pertinent_negatives, ARRAY[]::TEXT[]),
        'differential_diagnoses', COALESCE(sai.differential_diagnoses, ARRAY[]::TEXT[]),
        'risk_level', sai.risk_level,
        'clinical_impression_summary', sai.clinical_impression_summary
      )
      ORDER BY sai.problem_number
    )
    FROM public.soap_assessment_items sai
    WHERE sai.soap_note_id = sn.id
  ) AS assessment_problem_list,
  -- Plan items
  (
    SELECT jsonb_object_agg(plan_type, plan_items_json)
    FROM (
      SELECT
        spi.plan_type,
        jsonb_agg(
          jsonb_build_object(
            'id', spi.id,
            'plan_type', spi.plan_type,
            'description', spi.description,
            'indication', spi.indication,
            'urgency', spi.urgency,
            'status', spi.status,
            'test_name', spi.test_name,
            'follow_up_timeframe', spi.follow_up_timeframe,
            'follow_up_type', spi.follow_up_type,
            'education_topic', spi.education_topic,
            'is_return_precaution', spi.is_return_precaution,
            'red_flag_symptom', spi.red_flag_symptom
          )
        ) as plan_items_json
      FROM public.soap_plan_items spi
      WHERE spi.soap_note_id = sn.id
      GROUP BY spi.plan_type
    ) t
  ) AS plan_by_type,
  -- Safety alerts
  (
    SELECT jsonb_agg(
      jsonb_build_object(
        'id', ssa.id,
        'alert_type', ssa.alert_type,
        'severity', ssa.severity,
        'title', ssa.title,
        'description', ssa.description,
        'recommendation', ssa.recommendation,
        'acknowledged_by', ssa.acknowledged_by,
        'acknowledged_at', ssa.acknowledged_at
      )
      ORDER BY CASE ssa.severity
        WHEN 'critical' THEN 1
        WHEN 'warning' THEN 2
        WHEN 'informational' THEN 3
        ELSE 4
      END
    )
    FROM public.soap_safety_alerts ssa
    WHERE ssa.soap_note_id = sn.id
  ) AS safety_alerts,
  -- Coding & billing
  (
    SELECT jsonb_build_object(
      'cpt_code', scb.cpt_code,
      'cpt_description', scb.cpt_description,
      'cpt_confidence', scb.cpt_confidence,
      'mdm_level', scb.mdm_level,
      'mdm_rationale', scb.mdm_rationale,
      'problems_addressed_count', scb.problems_addressed_count,
      'data_reviewed', COALESCE(scb.data_reviewed, ARRAY[]::TEXT[]),
      'risk_level', scb.risk_level,
      'time_spent_minutes', scb.time_spent_minutes,
      'em_code', scb.em_code,
      'em_rationale', scb.em_rationale
    )
    FROM public.soap_coding_billing scb
    WHERE scb.soap_note_id = sn.id
  ) AS coding_billing
FROM public.soap_notes sn;

-- Create helper function to get SOAP note with all details
CREATE OR REPLACE FUNCTION public.get_soap_note_full(p_soap_note_id UUID)
RETURNS TABLE (
  id UUID,
  session_id UUID,
  appointment_id UUID,
  patient_id UUID,
  provider_id UUID,
  status VARCHAR,
  chief_complaint TEXT,
  created_at TIMESTAMPTZ,
  signed_at TIMESTAMPTZ,
  signed_by UUID,
  ehr_sync_status VARCHAR,
  subjective_hpi JSONB,
  subjective_ros JSONB,
  subjective_medications JSONB,
  subjective_allergies JSONB,
  subjective_history_items JSONB,
  objective_vitals JSONB,
  objective_physical_exam JSONB,
  assessment_problem_list JSONB,
  plan_by_type JSONB,
  safety_alerts JSONB,
  coding_billing JSONB
) AS $$
  SELECT
    snf.id,
    snf.session_id,
    snf.appointment_id,
    snf.patient_id,
    snf.provider_id,
    snf.status,
    snf.chief_complaint,
    snf.created_at,
    snf.signed_at,
    snf.signed_by,
    snf.ehr_sync_status,
    snf.subjective_hpi::JSONB,
    snf.subjective_ros::JSONB,
    snf.subjective_medications::JSONB,
    snf.subjective_allergies::JSONB,
    snf.subjective_history_items::JSONB,
    snf.objective_vitals::JSONB,
    snf.objective_physical_exam::JSONB,
    snf.assessment_problem_list::JSONB,
    snf.plan_by_type::JSONB,
    snf.safety_alerts::JSONB,
    snf.coding_billing::JSONB
  FROM public.soap_notes_full snf
  WHERE snf.id = p_soap_note_id;
$$ LANGUAGE SQL STABLE;

-- Grant access
GRANT SELECT ON public.soap_notes_full TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_soap_note_full(UUID) TO anon, authenticated, service_role;
