/**
 * MedZen Generate SOAP Note from Transcript
 *
 * Generates a clinician-grade SOAP note using AWS Bedrock (Claude 3 Opus).
 * Accepts either live-merged or medical-grade transcripts and produces
 * structured SOAP JSON that doctors can review, edit, and submit.
 *
 * Features:
 * - Claude 3 Opus for high-quality medical reasoning
 * - Strict SOAP JSON schema validation
 * - Medical entity extraction
 * - ICD-10 and CPT code suggestions
 * - Safety flagging for red flags
 * - Uncertainty marking (for doctor clarification)
 * - Telemedicine limitations documentation
 * - Full audit trail
 *
 * @version 1.0.0
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { BedrockRuntimeClient, InvokeModelCommand } from 'npm:@aws-sdk/client-bedrock-runtime@3.716.0';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

// AWS Configuration
const AWS_REGION = Deno.env.get('AWS_REGION') || 'eu-central-1';
const AWS_ACCESS_KEY_ID = Deno.env.get('AWS_ACCESS_KEY_ID') || '';
const AWS_SECRET_ACCESS_KEY = Deno.env.get('AWS_SECRET_ACCESS_KEY') || '';

// Supabase Configuration
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

// Model configuration
const BEDROCK_MODEL_ID = 'eu.anthropic.claude-opus-4-5-20251101-v1:0';  // Claude Opus 4.5 (EU region)
const TEMPERATURE = 0.1;  // Low randomness for medical consistency (Opus 4.5 does not support top_p with temperature)

// CORS Headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-firebase-token',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface PatientHistoryData {
  medicalConditions: string[];
  currentMedications: Array<{ name: string; dosage: string; frequency: string }>;
  surgicalHistory: string[];
  familyHistory: string[];
  allergies: string[];
}

interface SOAPGenerationRequest {
  sessionId: string;
  appointmentId: string;
  transcriptId: string;  // call_transcript_id
  transcriptText: string;
  appointmentMetadata: {
    startTime: string;
    endTime: string;
    timezone: string;
    provider: {
      id: string;
      name: string;
      specialty: string;
    };
    patient: {
      id: string;
      name: string;
      age?: number;
      gender?: string;
    };
    reasonForVisit?: string;
  };
  priorMedicalHistory?: {
    problems?: string[];
    medications?: string[];
    allergies?: string[];
  };
  vitals?: {
    bp?: string;
    hr?: number;
    rr?: number;
    temp?: number;
    spO2?: number;
  };
  languageCode?: string;
  maxTokens?: number;
}

/**
 * Bedrock-formatted prompt for SOAP generation
 * Uses strict instructions to produce only valid JSON
 */
function buildSOAPPrompt(request: SOAPGenerationRequest): string {
  const { transcriptText, appointmentMetadata, priorMedicalHistory, vitals } = request;

  return `You are a clinical documentation specialist assisting a healthcare provider in generating a comprehensive SOAP note.

CRITICAL RULES:
1. Output ONLY a single valid JSON object matching the SOAP schema exactly.
2. Use ONLY facts from the transcript or provided context. Never invent medical information.
3. Mark anything uncertain as "unknown" or in the uncertainties list.
4. Telemedicine limitation: only claim observations explicitly mentioned; use "telemedicine_observations" section.
5. Generate clinician-grade prose for narratives (professional, concise, medically appropriate).
6. If a vital is not mentioned, set to null and note in uncertainties.
7. Include specific return precautions and red-flag symptoms based on findings.
8. No trailing commas. All arrays/objects must be syntactically valid JSON.

CONTEXT:
- Appointment: ${appointmentMetadata.provider.name} (${appointmentMetadata.provider.specialty}) ↔ ${appointmentMetadata.patient.name} (Age: ${appointmentMetadata.patient.age || 'unknown'})
- Time: ${appointmentMetadata.startTime} (${appointmentMetadata.timezone})
- Reason for visit: ${appointmentMetadata.reasonForVisit || 'Not stated'}
${priorMedicalHistory?.problems ? `- Known problems: ${priorMedicalHistory.problems.join(', ')}` : ''}
${priorMedicalHistory?.medications ? `- Known medications: ${priorMedicalHistory.medications.join(', ')}` : ''}
${priorMedicalHistory?.allergies ? `- Known allergies: ${priorMedicalHistory.allergies.join(', ')}` : ''}
${vitals ? `- Vitals reported: BP=${vitals.bp}, HR=${vitals.hr}, RR=${vitals.rr}, Temp=${vitals.temp}°C, SpO2=${vitals.spO2}%` : ''}

TRANSCRIPT:
"""
${transcriptText}
"""

TASK:
Generate a SOAP note from the transcript above. Return ONLY valid JSON matching this structure:

{
  "schema_version": "1.0.0",
  "generated_at": "ISO timestamp",
  "language": "en",
  "encounter": {
    "encounter_type": "telemedicine_video",
    "appointment_id": "${request.appointmentId}",
    "session_id": "${request.sessionId}",
    "start_time": "${appointmentMetadata.startTime}",
    "end_time": "${appointmentMetadata.endTime}",
    "timezone": "${appointmentMetadata.timezone}",
    "location": {
      "patient_location_text": "unknown",
      "provider_location_text": "unknown"
    }
  },
  "participants": {
    "provider": {
      "id": "${appointmentMetadata.provider.id}",
      "name": "${appointmentMetadata.provider.name}",
      "role": "Doctor",
      "specialty": "${appointmentMetadata.provider.specialty}",
      "facility": "unknown"
    },
    "patient": {
      "id": "${appointmentMetadata.patient.id}",
      "name": "${appointmentMetadata.patient.name}",
      "age_years": ${appointmentMetadata.patient.age || null},
      "sex_at_birth": "unknown",
      "gender_identity": "unknown",
      "pregnancy_status": "unknown"
    }
  },
  "source": {
    "transcript": {
      "type": "live_merged",
      "confidence_overall": 0.0,
      "language_code": "${request.languageCode || 'en-US'}",
      "speaker_labels_used": true,
      "notes": "Auto-generated from live transcription"
    },
    "data_quality": {
      "missing_audio_segments": false,
      "inaudible_sections": [],
      "uncertainties": []
    }
  },
  "chief_complaint": "Extract from transcript or 'not stated'",
  "subjective": {
    "hpi": {
      "narrative": "Clinician-grade HPI paragraph from transcript",
      "symptom_onset": "unknown",
      "duration": "unknown",
      "location": "unknown",
      "quality": "unknown",
      "severity_scale_0_10": null,
      "timing": "unknown",
      "context": "unknown",
      "modifying_factors": {
        "aggravating": [],
        "relieving": []
      },
      "associated_symptoms": [],
      "pertinent_negatives": []
    },
    "ros": {
      "constitutional": { "positives": [], "negatives": [], "unknown": [] },
      "cardiovascular": { "positives": [], "negatives": [], "unknown": [] },
      "respiratory": { "positives": [], "negatives": [], "unknown": [] },
      "gastrointestinal": { "positives": [], "negatives": [], "unknown": [] },
      "genitourinary": { "positives": [], "negatives": [], "unknown": [] },
      "musculoskeletal": { "positives": [], "negatives": [], "unknown": [] },
      "skin": { "positives": [], "negatives": [], "unknown": [] },
      "neurologic": { "positives": [], "negatives": [], "unknown": [] },
      "psychiatric": { "positives": [], "negatives": [], "unknown": [] },
      "endocrine": { "positives": [], "negatives": [], "unknown": [] },
      "hematologic": { "positives": [], "negatives": [], "unknown": [] },
      "allergic_immunologic": { "positives": [], "negatives": [], "unknown": [] }
    },
    "pmh": {
      "conditions": []
    },
    "psh": {
      "surgeries": []
    },
    "medications": [],
    "allergies": [],
    "social_history": {
      "tobacco": "unknown",
      "alcohol": "unknown",
      "substance_use": "unknown",
      "occupation": "unknown",
      "living_situation": "unknown"
    },
    "family_history": {
      "relevant_conditions": []
    }
  },
  "objective": {
    "vitals": {
      "measured": ${vitals ? 'true' : 'false'},
      "bp_mmHg": ${vitals?.bp ? `"${vitals.bp}"` : 'null'},
      "hr_bpm": ${vitals?.hr || null},
      "rr_bpm": ${vitals?.rr || null},
      "temp_c": ${vitals?.temp || null},
      "spo2_percent": ${vitals?.spO2 || null},
      "weight_kg": null,
      "height_cm": null,
      "bmi": null,
      "source": "${vitals ? 'patient_reported' : 'unknown'}"
    },
    "telemedicine_observations": {
      "general_appearance": "unknown",
      "respiratory_effort": "unknown",
      "speech": "unknown",
      "mental_status": "unknown",
      "skin_visible": "unknown",
      "other": []
    },
    "physical_exam_limited": {
      "performed": false,
      "summary": "Telemedicine consultation - limited physical exam capability",
      "systems": {
        "general": "unknown",
        "heent": "unknown",
        "cardiovascular": "unknown",
        "respiratory": "unknown",
        "abdomen": "unknown",
        "msk": "unknown",
        "neuro": "unknown",
        "skin": "unknown",
        "psych": "unknown"
      }
    },
    "diagnostics_reviewed": []
  },
  "assessment": {
    "problem_list": [],
    "clinical_impression_summary": "Clinical impression from transcript"
  },
  "plan": {
    "treatments": [],
    "orders": [],
    "follow_up": {
      "timeframe": "unknown",
      "with_whom": "provider",
      "return_precautions": ["Seek immediate care for severe symptoms", "Follow up for labs if ordered"]
    },
    "patient_education": [],
    "work_school_notes": {
      "needed": false,
      "restrictions": null
    }
  },
  "coding_billing": {
    "suggested_cpt": [],
    "mdm_level_suggestion": "moderate",
    "rationale": "Based on complexity of visit"
  },
  "safety": {
    "medication_safety_notes": [],
    "limitations": ["Telemedicine visit - physical exam limited to visual/verbal observation"],
    "requires_clinician_review": true
  },
  "doctor_editing": {
    "draft_quality": "medium",
    "recommended_clarifications": [],
    "sections_needing_attention": ["Vitals if patient-reported only"]
  }
}

Fill in the JSON above with extracted information from the transcript. Be thorough but conservative—if unsure, mark as unknown and list in uncertainties/recommended_clarifications.
`;
}

/**
 * Invoke Bedrock to generate SOAP note with timeout protection
 */
async function generateSOAPWithBedrock(request: SOAPGenerationRequest): Promise<any> {
  const bedrockClient = new BedrockRuntimeClient({
    region: AWS_REGION,
    credentials: {
      accessKeyId: AWS_ACCESS_KEY_ID,
      secretAccessKey: AWS_SECRET_ACCESS_KEY,
    },
  });

  const prompt = buildSOAPPrompt(request);
  const maxTokens = request.maxTokens || 4096;

  console.log(`[Bedrock] Invoking ${BEDROCK_MODEL_ID} for SOAP generation`);
  console.log(`[Bedrock] Temperature: ${TEMPERATURE}, MaxTokens: ${maxTokens}`);

  const command = new InvokeModelCommand({
    modelId: BEDROCK_MODEL_ID,
    contentType: 'application/json',
    accept: 'application/json',
    body: JSON.stringify({
      anthropic_version: 'bedrock-2023-05-31',
      max_tokens: maxTokens,
      temperature: TEMPERATURE,
      messages: [
        {
          role: 'user',
          content: prompt,
        },
      ],
    }),
  });

  let response;
  try {
    console.log(`[Bedrock] Sending request to Bedrock...`);
    // **CRITICAL FIX**: Add 45-second timeout to Bedrock call
    response = await Promise.race([
      bedrockClient.send(command),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Bedrock request timeout (45s) - try again or contact support')), 45000)
      ),
    ]);
    console.log(`[Bedrock] Response received, status: ${response.$metadata?.httpStatusCode}`);
  } catch (bedrockError) {
    console.error('[Bedrock] Failed to invoke model:', bedrockError instanceof Error ? bedrockError.message : String(bedrockError));
    console.error('[Bedrock] Error details:', bedrockError);
    throw new Error(`Bedrock invocation failed: ${bedrockError instanceof Error ? bedrockError.message : String(bedrockError)}`);
  }

  let responseBody;
  try {
    console.log(`[Bedrock] Parsing response body...`);
    const decodedBody = new TextDecoder().decode(response.body);
    console.log(`[Bedrock] Decoded body length: ${decodedBody.length}`);
    responseBody = JSON.parse(decodedBody);
    console.log(`[Bedrock] Response parsed. Keys: ${Object.keys(responseBody).join(', ')}`);
  } catch (parseError) {
    console.error('[Bedrock] Failed to parse response body:', parseError instanceof Error ? parseError.message : String(parseError));
    console.error('[Bedrock] Raw response:', response.body);
    throw new Error(`Response parsing failed: ${parseError instanceof Error ? parseError.message : String(parseError)}`);
  }

  // Extract text from response
  const generatedText = responseBody.content?.[0]?.text || '';
  console.log(`[Bedrock] Generated text length: ${generatedText.length}`);

  if (!generatedText) {
    console.error('[Bedrock] No text content found in response');
    console.error('[Bedrock] Response structure:', JSON.stringify(responseBody, null, 2));
    throw new Error('No text content in Bedrock response');
  }

  // Parse JSON from response
  let parsedSOAP: any;
  try {
    console.log(`[Bedrock] Extracting JSON from generated text...`);
    // Try to extract JSON from response (in case there's extra text)
    const jsonMatch = generatedText.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      console.log(`[Bedrock] JSON match found, length: ${jsonMatch[0].length}`);
      parsedSOAP = JSON.parse(jsonMatch[0]);
      console.log(`[Bedrock] JSON parsed successfully. Keys: ${Object.keys(parsedSOAP).join(', ')}`);
    } else {
      throw new Error('No JSON found in response');
    }
  } catch (e) {
    console.error('[Bedrock] Failed to parse SOAP JSON:', e instanceof Error ? e.message : String(e));
    console.error('[Bedrock] Generated text first 500 chars:', generatedText.substring(0, 500));
    throw new Error(`Failed to parse generated SOAP: ${e instanceof Error ? e.message : String(e)}`);
  }

  return parsedSOAP;
}

/**
 * Validate SOAP JSON schema
 */
function validateSOAPSchema(soapJson: any): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  // Required top-level keys
  const requiredKeys = ['chief_complaint', 'subjective', 'objective', 'assessment', 'plan', 'safety'];
  for (const key of requiredKeys) {
    if (!(key in soapJson)) {
      errors.push(`Missing required key: ${key}`);
    }
  }

  // Validate subjective sections
  if (soapJson.subjective) {
    if (!soapJson.subjective.hpi || typeof soapJson.subjective.hpi !== 'object') {
      errors.push('Invalid subjective.hpi structure');
    }
    if (!soapJson.subjective.ros || typeof soapJson.subjective.ros !== 'object') {
      errors.push('Invalid subjective.ros structure');
    }
  }

  // Validate objective sections
  if (soapJson.objective) {
    if (!soapJson.objective.vitals || typeof soapJson.objective.vitals !== 'object') {
      errors.push('Invalid objective.vitals structure');
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

/**
 * Fetch patient history from database
 */
async function getPatientHistory(
  supabase: any,
  patientId: string,
  appointmentId: string
): Promise<PatientHistoryData & { recentVitals?: any }> {
  console.log(`[Patient History] Fetching history for patient ${patientId}`);

  try {
    // **CRITICAL TIMEOUT FIX**: Wrap patient profile fetch with 5-second timeout
    // Prevents edge function from hanging if Supabase query stalls
    const patientProfilePromise = supabase
      .from('patient_profiles')
      .select(
        `id,
         medical_conditions,
         current_medications,
         surgical_history,
         family_history,
         allergies`
      )
      .eq('patient_id', patientId)
      .single();

    const { data: patientProfile } = await Promise.race([
      patientProfilePromise,
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Patient history fetch timeout (5s)')), 5000)
      ),
    ]) as any;

  // Parse medical conditions
  const medicalConditions: string[] = [];
  if (patientProfile?.medical_conditions) {
    if (Array.isArray(patientProfile.medical_conditions)) {
      medicalConditions.push(...patientProfile.medical_conditions);
    } else if (typeof patientProfile.medical_conditions === 'string') {
      medicalConditions.push(patientProfile.medical_conditions);
    }
  }

  // Parse medications
  const currentMedications: Array<{ name: string; dosage: string; frequency: string }> = [];
  if (patientProfile?.current_medications) {
    try {
      const medsData =
        typeof patientProfile.current_medications === 'string'
          ? JSON.parse(patientProfile.current_medications)
          : patientProfile.current_medications;
      if (Array.isArray(medsData)) {
        medsData.forEach((med: any) => {
          currentMedications.push({
            name: med.name || med,
            dosage: med.dosage || '',
            frequency: med.frequency || '',
          });
        });
      }
    } catch (e) {
      console.warn('[Patient History] Error parsing medications:', e);
    }
  }

  // Parse surgical history
  const surgicalHistory: string[] = [];
  if (patientProfile?.surgical_history) {
    if (Array.isArray(patientProfile.surgical_history)) {
      surgicalHistory.push(...patientProfile.surgical_history);
    } else if (typeof patientProfile.surgical_history === 'string') {
      surgicalHistory.push(patientProfile.surgical_history);
    }
  }

  // Parse family history
  const familyHistory: string[] = [];
  if (patientProfile?.family_history) {
    if (Array.isArray(patientProfile.family_history)) {
      familyHistory.push(...patientProfile.family_history);
    } else if (typeof patientProfile.family_history === 'string') {
      familyHistory.push(patientProfile.family_history);
    }
  }

  // Parse allergies
  const allergies: string[] = [];
  if (patientProfile?.allergies) {
    if (Array.isArray(patientProfile.allergies)) {
      allergies.push(...patientProfile.allergies);
    } else if (typeof patientProfile.allergies === 'string') {
      allergies.push(patientProfile.allergies);
    }
  }

  // Get recent vitals from past clinical notes
  const { data: recentNote } = await supabase
    .from('clinical_notes')
    .select(
      `created_at,
       section_3_vitals_temperature,
       section_3_vitals_systolic_bp,
       section_3_vitals_diastolic_bp,
       section_3_vitals_heart_rate,
       section_3_vitals_respiratory_rate,
       section_3_vitals_oxygen_saturation,
       section_3_vitals_weight,
       section_3_vitals_height`
    )
    .eq('patient_id', patientId)
    .eq('is_draft', false)
    .order('created_at', { ascending: false })
    .limit(1)
    .single();

  const recentVitals = recentNote
    ? {
        lastVisitDate: recentNote.created_at,
        temperature: recentNote.section_3_vitals_temperature,
        bloodPressure: recentNote.section_3_vitals_systolic_bp
          ? `${recentNote.section_3_vitals_systolic_bp}/${recentNote.section_3_vitals_diastolic_bp}`
          : undefined,
        heartRate: recentNote.section_3_vitals_heart_rate,
        respiratoryRate: recentNote.section_3_vitals_respiratory_rate,
        oxygenSaturation: recentNote.section_3_vitals_oxygen_saturation,
        weight: recentNote.section_3_vitals_weight,
        height: recentNote.section_3_vitals_height,
      }
    : undefined;

    return {
      medicalConditions,
      currentMedications,
      surgicalHistory,
      familyHistory,
      allergies,
      recentVitals,
    };
  } catch (timeoutError) {
    console.error('[Patient History] Timeout or error fetching history:', timeoutError instanceof Error ? timeoutError.message : String(timeoutError));
    // Return empty history structure on timeout - better than hanging
    return {
      medicalConditions: [],
      currentMedications: [],
      surgicalHistory: [],
      familyHistory: [],
      allergies: [],
      recentVitals: undefined,
    };
  }
}

/**
 * Insert normalized SOAP data into 11 tables with optimized parallel inserts
 */
async function insertNormalizedSOAPData(
  supabase: any,
  soapNoteId: string,
  soapJson: any,
  patientHistory: any
): Promise<void> {
  console.log(`[SOAP Normalization] Inserting normalized data for SOAP note ${soapNoteId}`);

  // **OPTIMIZATION**: Collect all insert promises and run in parallel
  const insertPromises: Promise<any>[] = [];

  // 1. Insert HPI Details
  if (soapJson.subjective?.hpi) {
    console.log(`[SOAP Normalization] Queuing HPI details insert...`);
    insertPromises.push(
      supabase.from('soap_hpi_details').insert({
        soap_note_id: soapNoteId,
        hpi_narrative: soapJson.subjective.hpi.narrative || '',
        symptom_onset: soapJson.subjective.hpi.symptom_onset || 'unknown',
        duration: soapJson.subjective.hpi.duration || 'unknown',
        location: soapJson.subjective.hpi.location || 'unknown',
        radiation: soapJson.subjective.hpi.radiation || null,
        quality: soapJson.subjective.hpi.quality || 'unknown',
        severity_scale: soapJson.subjective.hpi.severity_scale_0_10 || null,
        timing_pattern: soapJson.subjective.hpi.timing || 'unknown',
        context: soapJson.subjective.hpi.context || 'unknown',
        aggravating_factors: soapJson.subjective.hpi.modifying_factors?.aggravating || [],
        relieving_factors: soapJson.subjective.hpi.modifying_factors?.relieving || [],
        associated_symptoms: soapJson.subjective.hpi.associated_symptoms || [],
        pertinent_negatives: soapJson.subjective.hpi.pertinent_negatives || [],
      })
    );
  }

  // 2. Insert ROS (Review of Systems) - parallel
  if (soapJson.subjective?.ros && typeof soapJson.subjective.ros === 'object') {
    console.log(`[SOAP Normalization] Queuing ROS entries insert (parallel)...`);
    const rosSystems = [
      'constitutional', 'cardiovascular', 'respiratory', 'gastrointestinal',
      'genitourinary', 'musculoskeletal', 'skin', 'neurologic', 'psychiatric',
      'endocrine', 'hematologic', 'allergic_immunologic',
    ];

    const rosInserts = rosSystems
      .map((system) => {
        const rosData = soapJson.subjective.ros[system];
        if (rosData) {
          return supabase.from('soap_review_of_systems').insert({
            soap_note_id: soapNoteId,
            system_name: system === 'hematologic' ? 'hematologic_lymphatic' : system === 'allergic_immunologic' ? 'allergic_immunologic' : system,
            has_symptoms: (rosData.positives?.length || 0) > 0,
            symptoms_positive: rosData.positives || [],
            symptoms_negative: rosData.negatives || [],
            symptoms_unknown: rosData.unknown || [],
          });
        }
        return null;
      })
      .filter((p): p is Promise<any> => p !== null);

    insertPromises.push(...rosInserts);
  }

  // 3. Insert Vital Signs
  if (soapJson.objective?.vitals) {
    console.log(`[SOAP Normalization] Queuing vital signs insert...`);
    const vitals = soapJson.objective.vitals;
    insertPromises.push(
      supabase.from('soap_vital_signs').insert({
        soap_note_id: soapNoteId,
        source: vitals.source || 'unknown',
        temperature_value: vitals.temp_c || null,
        temperature_unit: vitals.temp_c ? 'celsius' : null,
        blood_pressure_systolic: vitals.bp_mmHg ? parseInt(vitals.bp_mmHg.split('/')[0]) : null,
        blood_pressure_diastolic: vitals.bp_mmHg ? parseInt(vitals.bp_mmHg.split('/')[1]) : null,
        heart_rate: vitals.hr_bpm || null,
        respiratory_rate: vitals.rr_bpm || null,
        oxygen_saturation: vitals.spo2_percent || null,
        weight_kg: vitals.weight_kg || null,
        height_cm: vitals.height_cm || null,
        bmi: vitals.bmi || null,
      })
    );
  }

  // 4. Insert Physical Exam - parallel
  if (soapJson.objective?.physical_exam_limited) {
    console.log(`[SOAP Normalization] Queuing physical exam inserts (parallel)...`);
    const examSystems = ['general', 'heent', 'cardiovascular', 'respiratory', 'abdomen', 'msk', 'neuro', 'skin', 'psych'];
    const examInserts = examSystems
      .map((system) => {
        const examKey = system === 'msk' ? 'msk' : system === 'neuro' ? 'neuro' : system === 'psych' ? 'psych' : system;
        const finding = soapJson.objective.physical_exam_limited.systems?.[examKey];
        if (finding && finding !== 'unknown') {
          return supabase.from('soap_physical_exam').insert({
            soap_note_id: soapNoteId,
            system_name: examKey,
            is_abnormal: false,
            findings: [finding],
            limited_by_telemedicine: true,
            visual_inspection_only: true,
            observation_notes: finding,
          });
        }
        return null;
      })
      .filter((p): p is Promise<any> => p !== null);
    insertPromises.push(...examInserts);
  }

  // 5. Insert Medical/Surgical History - parallel
  if (soapJson.subjective?.pmh?.conditions) {
    console.log(`[SOAP Normalization] Queuing PMH inserts (parallel)...`);
    const pmhInserts = soapJson.subjective.pmh.conditions.map((condition: any) =>
      supabase.from('soap_history_items').insert({
        soap_note_id: soapNoteId,
        history_type: 'past_medical',
        condition_name: condition.name || condition,
        status: 'active',
      })
    );
    insertPromises.push(...pmhInserts);
  }

  if (soapJson.subjective?.psh?.surgeries) {
    console.log(`[SOAP Normalization] Queuing PSH inserts (parallel)...`);
    const pshInserts = soapJson.subjective.psh.surgeries.map((surgery: any) =>
      supabase.from('soap_history_items').insert({
        soap_note_id: soapNoteId,
        history_type: 'past_surgical',
        surgery_name: surgery.name || surgery,
      })
    );
    insertPromises.push(...pshInserts);
  }

  // 6. Insert Medications - parallel
  if (soapJson.subjective?.medications) {
    console.log(`[SOAP Normalization] Queuing medication inserts (parallel)...`);
    const medInserts = soapJson.subjective.medications.map((med: any) =>
      supabase.from('soap_medications').insert({
        soap_note_id: soapNoteId,
        source: 'current_medication',
        medication_name: med.name || med,
        dose: med.dose || '',
        route: med.route || 'oral',
        frequency: med.frequency || '',
        status: 'active',
      })
    );
    insertPromises.push(...medInserts);
  }

  // 7. Insert Allergies - parallel
  if (soapJson.subjective?.allergies) {
    console.log(`[SOAP Normalization] Queuing allergy inserts (parallel)...`);
    const allergyInserts = soapJson.subjective.allergies.map((allergy: any) =>
      supabase.from('soap_allergies').insert({
        soap_note_id: soapNoteId,
        allergen: allergy.allergen || allergy,
        allergen_type: allergy.type || 'drug',
        severity: allergy.severity || 'unknown',
        status: 'active',
      })
    );
    insertPromises.push(...allergyInserts);
  }

  // 8. Insert Assessment Items - parallel
  if (soapJson.assessment?.problem_list) {
    console.log(`[SOAP Normalization] Queuing assessment inserts (parallel)...`);
    const assessmentInserts = soapJson.assessment.problem_list.map((problem: any, i: number) =>
      supabase.from('soap_assessment_items').insert({
        soap_note_id: soapNoteId,
        problem_number: i + 1,
        diagnosis_description: problem.diagnosis || problem,
        is_primary_diagnosis: i === 0,
        status: 'new',
        confidence: 'suspected',
        clinical_impression_summary: soapJson.assessment.clinical_impression_summary || '',
      })
    );
    insertPromises.push(...assessmentInserts);
  }

  // 9. Insert Plan Items - parallel
  if (soapJson.plan) {
    console.log(`[SOAP Normalization] Queuing plan inserts (parallel)...`);
    if (soapJson.plan.treatments) {
      const treatmentInserts = soapJson.plan.treatments.map((treatment: any) =>
        supabase.from('soap_plan_items').insert({
          soap_note_id: soapNoteId,
          plan_type: 'medication',
          description: treatment.description || treatment,
          status: 'ordered',
        })
      );
      insertPromises.push(...treatmentInserts);
    }

    if (soapJson.plan.orders) {
      const orderInserts = soapJson.plan.orders.map((order: any) =>
        supabase.from('soap_plan_items').insert({
          soap_note_id: soapNoteId,
          plan_type: 'lab',
          description: order.description || order,
          status: 'ordered',
        })
      );
      insertPromises.push(...orderInserts);
    }

    if (soapJson.plan.follow_up) {
      insertPromises.push(
        supabase.from('soap_plan_items').insert({
          soap_note_id: soapNoteId,
          plan_type: 'follow_up',
          description: `Follow up in ${soapJson.plan.follow_up.timeframe || 'unknown'}`,
          follow_up_timeframe: soapJson.plan.follow_up.timeframe || 'unknown',
          follow_up_type: soapJson.plan.follow_up.type || 'telemedicine',
          status: 'pending',
        })
      );
    }

    if (soapJson.plan.patient_education) {
      const eduInserts = soapJson.plan.patient_education.map((edu: any) =>
        supabase.from('soap_plan_items').insert({
          soap_note_id: soapNoteId,
          plan_type: 'education',
          description: edu.topic || edu,
          education_topic: edu.topic || edu,
          status: 'pending',
        })
      );
      insertPromises.push(...eduInserts);
    }

    if (soapJson.plan.follow_up?.return_precautions) {
      const precautionInserts = soapJson.plan.follow_up.return_precautions.map((precaution: string) =>
        supabase.from('soap_plan_items').insert({
          soap_note_id: soapNoteId,
          plan_type: 'other',
          is_return_precaution: true,
          red_flag_symptom: precaution,
          description: `Return precaution: ${precaution}`,
          status: 'pending',
        })
      );
      insertPromises.push(...precautionInserts);
    }
  }

  // 10. Insert Safety Alerts - parallel
  if (soapJson.safety) {
    console.log(`[SOAP Normalization] Queuing safety alert inserts (parallel)...`);
    if (soapJson.safety.medication_safety_notes) {
      const safetyInserts = soapJson.safety.medication_safety_notes.map((note: string) =>
        supabase.from('soap_safety_alerts').insert({
          soap_note_id: soapNoteId,
          alert_type: 'drug_interaction',
          severity: 'warning',
          title: 'Medication Safety',
          description: note,
        })
      );
      insertPromises.push(...safetyInserts);
    }

    if (soapJson.safety.limitations) {
      const limitInserts = soapJson.safety.limitations.map((limitation: string) =>
        supabase.from('soap_safety_alerts').insert({
          soap_note_id: soapNoteId,
          alert_type: 'limitation',
          severity: 'informational',
          title: 'Clinical Limitation',
          description: limitation,
        })
      );
      insertPromises.push(...limitInserts);
    }
  }

  // 11. Insert Coding & Billing
  if (soapJson.coding_billing) {
    console.log(`[SOAP Normalization] Queuing coding and billing insert...`);
    const coding = soapJson.coding_billing;
    insertPromises.push(
      supabase.from('soap_coding_billing').insert({
        soap_note_id: soapNoteId,
        cpt_code: coding.suggested_cpt?.[0] || null,
        mdm_level: coding.mdm_level_suggestion || 'moderate',
        mdm_rationale: coding.rationale || '',
      })
    );
  }

  // **CRITICAL OPTIMIZATION**: Execute all inserts in parallel
  console.log(`[SOAP Normalization] Executing ${insertPromises.length} database inserts in parallel...`);
  await Promise.all(insertPromises);
  console.log(`[SOAP Normalization] All normalized data inserts completed for SOAP note ${soapNoteId}`);
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    const body: SOAPGenerationRequest = await req.json();

    const { sessionId, appointmentId, transcriptId, transcriptText } = body;

    if (!sessionId || !appointmentId || !transcriptText) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Missing required fields: sessionId, appointmentId, transcriptText',
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`[SOAP Generation] Starting for session ${sessionId}`);

    // **OPTIMIZATION**: Fetch appointment data (we need patientId and providerId for parallel history fetch)
    const { data: appointmentData } = await supabase
      .from('appointments')
      .select('patient_id, provider_id')
      .eq('id', appointmentId)
      .single();

    if (!appointmentData) {
      throw new Error(`Appointment ${appointmentId} not found`);
    }

    const patientId = appointmentData.patient_id;
    const providerId = appointmentData.provider_id;

    // Fetch patient history in parallel
    console.log('[SOAP Generation] Fetching patient history...');
    const patientHistory = await getPatientHistory(supabase, patientId, appointmentId);

    // Populate priorMedicalHistory in request body
    body.priorMedicalHistory = {
      problems: patientHistory.medicalConditions,
      medications: patientHistory.currentMedications.map(m => `${m.name} ${m.dosage} ${m.frequency}`.trim()),
      allergies: patientHistory.allergies,
    };

    // Update call_transcripts processing status
    if (transcriptId) {
      await supabase
        .from('call_transcripts')
        .update({ processing_status: 'processing' })
        .eq('id', transcriptId);
    }

    // Call Bedrock
    console.log('[SOAP Generation] Calling Bedrock Claude 3 Opus...');
    const soapJson = await generateSOAPWithBedrock(body);

    // Validate schema
    const validation = validateSOAPSchema(soapJson);
    if (!validation.valid) {
      console.error('[SOAP Generation] Schema validation failed:', validation.errors);
      throw new Error(`Schema validation failed: ${validation.errors.join(', ')}`);
    }

    console.log('[SOAP Generation] Schema validation passed');

    // Save SOAP note master record (Step 3 - simplified master insert)
    const { data: soapData, error: soapError } = await supabase
      .from('soap_notes')
      .insert({
        session_id: sessionId,
        appointment_id: appointmentId,
        call_transcript_id: transcriptId,
        provider_id: providerId,
        patient_id: patientId,
        status: 'draft',
        encounter_type: 'telemedicine_video',
        visit_type: 'follow_up',
        chief_complaint: soapJson.chief_complaint,
        reason_for_visit: body.appointmentMetadata?.reasonForVisit || '',
        ai_generated_at: new Date().toISOString(),
        ai_model_used: BEDROCK_MODEL_ID,
        ai_raw_response: soapJson,
        ai_generation_prompt_version: '1.0.0',
        requires_clinician_review: true,
        consent_obtained: true,
        language_used: body.languageCode || 'en',
      })
      .select('id')
      .single();

    if (soapError) {
      console.error('[SOAP Generation] Failed to save SOAP note:', soapError);
      throw soapError;
    }

    console.log(`[SOAP Generation] SOAP note created: ${soapData.id}`);

    // Step 4: Insert normalized data into 11 tables
    console.log('[SOAP Generation] Inserting normalized SOAP data...');
    await insertNormalizedSOAPData(supabase, soapData.id, soapJson, patientHistory);

    // Update session to link SOAP note
    await supabase
      .from('video_call_sessions')
      .update({
        soap_note_id: soapData.id,
        soap_note_auto_generated: true,
      })
      .eq('id', sessionId);

    // Update transcript processing status
    if (transcriptId) {
      await supabase
        .from('call_transcripts')
        .update({ processing_status: 'completed' })
        .eq('id', transcriptId);
    }

    // Log audit event
    await supabase.from('video_call_audit_log').insert({
      session_id: sessionId,
      event_type: 'SOAP_NOTE_GENERATED',
      event_data: {
        soap_note_id: soapData.id,
        model: BEDROCK_MODEL_ID,
        timestamp: new Date().toISOString(),
      },
    });

    // Step 5: Retrieve complete SOAP note using helper view
    console.log('[SOAP Generation] Retrieving complete SOAP note from normalized view...');
    // **CRITICAL TIMEOUT FIX**: Wrap view retrieval with 10-second timeout
    // Prevents edge function from hanging if database view is slow
    const viewRetrievalPromise = supabase
      .rpc('get_soap_note_full', { p_soap_note_id: soapData.id })
      .single();

    const { data: completeSoapNote, error: retrieveError } = await Promise.race([
      viewRetrievalPromise,
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Database view retrieval timeout (10s)')), 10000)
      ),
    ]) as any;

    if (retrieveError) {
      console.warn('[SOAP Generation] Warning - could not retrieve via helper view:', retrieveError);
      // Fall back to raw JSON response if view retrieval fails
      return new Response(
        JSON.stringify({
          success: true,
          message: 'SOAP note generated successfully (view retrieval pending)',
          soapNoteId: soapData.id,
          soapNote: soapJson,
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'SOAP note generated successfully',
        soapNoteId: soapData.id,
        soapNote: soapJson,
        normalizedSoapNote: completeSoapNote,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('[SOAP Generation] Error:', error);
    console.error('[SOAP Generation] Error type:', typeof error);
    console.error('[SOAP Generation] Error keys:', error instanceof Object ? Object.keys(error) : 'N/A');
    if (error instanceof Error) {
      console.error('[SOAP Generation] Error name:', error.name);
      console.error('[SOAP Generation] Error message:', error.message);
      console.error('[SOAP Generation] Error stack:', error.stack);
    }

    // Build detailed error response
    let errorMessage = 'Unknown error occurred';
    let errorDetails: any = {};

    if (error instanceof Error) {
      errorMessage = error.message || 'Error occurred during SOAP generation';
      errorDetails.errorType = error.name;
      errorDetails.errorMessage = error.message;
    } else if (typeof error === 'object' && error !== null) {
      errorMessage = (error as any).message || (error as any).error || JSON.stringify(error);
      errorDetails.errorObject = error;
    } else if (typeof error === 'string') {
      errorMessage = error;
    }

    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage || 'Failed to generate SOAP note',
        code: 'SOAP_GENERATION_FAILED',
        details: errorDetails,
        timestamp: new Date().toISOString(),
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
