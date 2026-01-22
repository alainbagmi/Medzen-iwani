import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { verifyFirebaseJWT } from '../_shared/verify-firebase-jwt.ts';

/**
 * Generates a complete 12-tab SOAP draft from call transcript + pre-call context snapshot.
 *
 * This function leverages AWS Bedrock (Claude) to intelligently populate all SOAP tabs
 * with emphasis on Tab 2 (Patient Identification) completeness from pre-gathered snapshot data.
 *
 * WORKFLOW:
 * =========
 *
 * 1. FETCH CONTEXT & TRANSCRIPT:
 *    - Retrieve context_snapshot JSONB from create-context-snapshot edge function
 *    - Fetch call_transcript chunks for the encounter
 *    - Combine: snapshot (verified patient data) + transcript (clinical findings)
 *
 * 2. BUILD ENHANCED PROMPT:
 *    - Include complete SOAP_SCHEMA_SKELETON (12-tab structure)
 *    - Insert context_snapshot.patient_demographics (14 fields) for Tab 2 extraction
 *    - Include context_snapshot.appointment_context (9 fields) for Tab 1 enhancement
 *    - Emphasize Tab 2 MANDATORY field extraction from snapshot (NOT transcript)
 *    - Include medical history from cumulative_medical_record
 *
 * 3. CALL AWS BEDROCK (Claude):
 *    - POST to BEDROCK_LAMBDA_URL with complete prompt
 *    - Claude generates complete SOAP JSON matching schema
 *    - Return: All 12 tabs populated with clinical data
 *
 * 4. POST-RESPONSE VALIDATION (CRITICAL):
 *    - Validate Tab 2 Patient Identification completeness
 *    - Check 6 REQUIRED fields present: full_name, dob, age, sex_at_birth, phone, email
 *    - Calculate confidence score: 0.8 base, -0.2 per missing required field, 0.5 floor
 *    - Add missing field names to ai_flags.missing_critical_info array
 *    - Mark ai_flags.needs_clinician_confirmation for fields requiring manual entry
 *
 * 5. RETURN RESPONSE:
 *    - Include ai_flags with missing_critical_info list (if any fields missing)
 *    - Include confidence score (0.5-1.0 range)
 *    - Provider uses flags to identify fields needing manual correction before signing
 *
 * TAB 2 PATIENT IDENTIFICATION FIELD MAPPING:
 * ============================================
 *
 * Data Sources Priority:
 * 1. SNAPSHOT (verified database) - ALWAYS preferred over transcript
 * 2. TRANSCRIPT (clinical context) - ONLY if not in snapshot
 *
 * Required Fields (MUST extract from snapshot OR flag missing):
 *   - full_name ← snapshot.patient_demographics.full_name
 *   - dob ← snapshot.patient_demographics.dob (format: YYYY-MM-DD)
 *   - age ← snapshot.patient_demographics.age OR calculate from dob
 *   - sex_at_birth ← snapshot.patient_demographics.gender
 *   - phone ← snapshot.patient_demographics.phone
 *   - email ← snapshot.patient_demographics.email
 *
 * Optional Fields (populate if available in snapshot):
 *   - address ← snapshot.patient_demographics.address
 *   - patient_number ← snapshot.patient_demographics.patient_number
 *   - emergency_contact_name ← snapshot.patient_demographics.emergency_contact_name
 *   - emergency_contact_phone ← snapshot.patient_demographics.emergency_contact_phone
 *   - emergency_contact_relationship ← snapshot.patient_demographics.emergency_contact_relationship
 *
 * CONFIDENCE SCORE SYSTEM:
 * ========================
 *
 * Base Score: 0.8 (80%)
 * Penalty: -0.2 (20%) per missing REQUIRED field
 * Minimum Floor: 0.5 (50%) - never drop below
 * Threshold for Provider Review: >0.70
 *
 * Score Calculation Examples:
 *   - 6 required fields present → 0.8 ✓ (above threshold, minimal corrections needed)
 *   - 5 required fields present (1 missing) → 0.8 - 0.2 = 0.6 ⚠️ (below threshold, manual review needed)
 *   - 4 required fields present (2 missing) → 0.8 - 0.4 = 0.4 → 0.5 floor (flagged for provider to fill)
 *   - 3 required fields present (3 missing) → 0.8 - 0.6 = 0.2 → 0.5 floor (incomplete, provider completes)
 *
 * AI_FLAGS STRUCTURE:
 * ===================
 *
 * ai_flags: {
 *   missing_critical_info: [
 *     "Tab 2: phone is missing - please fill manually",
 *     "Tab 2: address is missing or incomplete"
 *   ],
 *   needs_clinician_confirmation: [
 *     "Tab 4: medication dosage unclear from transcript",
 *     "Tab 5: patient reports allergy severity but unclear"
 *   ],
 *   confidence: 0.65  // 0.5 - 1.0 range
 * }
 *
 * USAGE BY PROVIDER:
 * ==================
 *
 * 1. Call ends → generate-soap-draft-v2 triggered
 * 2. Response includes 12-tab SOAP draft + ai_flags
 * 3. Provider opens PostCallClinicalNotesDialog
 * 4. Check ai_flags.missing_critical_info → manually fill Tab 2 gaps
 * 5. Review other flagged sections as needed
 * 6. Review & sign all tabs
 * 7. Save to clinical_notes table
 * 8. Async sync-to-ehrbase triggers for OpenEHR integration
 *
 * ERROR HANDLING:
 * ===============
 *
 * - 401: Missing/invalid Firebase token
 * - 404: Context snapshot not found
 * - 404: Encounter/transcript not found
 * - 503: AWS Bedrock unavailable
 * - Graceful degradation: Generate SOAP with available data, flag missing sections
 *
 * @param {string} encounter_id - UUID of video_call_sessions row
 * @param {string} appointment_id - UUID of appointment
 * @returns {Promise<Object>} Complete 12-tab SOAP draft with Tab 2 validation + ai_flags
 * @throws {Error} If Firebase token invalid or context snapshot not found
 */

interface ErrorResponse {
  error: string;
  code: string;
  status: number;
}

const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
const bedrockLambdaUrl = Deno.env.get('BEDROCK_LAMBDA_URL') || '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-firebase-token',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

// SOAP JSON Schema (12-tab structure)
const SOAP_SCHEMA_SKELETON = {
  tab1_encounter_header: {
    visit_date: '',
    visit_type: '',
    chief_complaint_as_written: '',
    interpreter_needed: false,
    identity_verified_method: '',
  },
  tab2_patient_identification: {
    full_name: '',
    dob: '',
    age: 0,
    sex_at_birth: '',
    phone: '',
    email: '',
    address: '',
    emergency_contact_name: '',
    emergency_contact_phone: '',
    emergency_contact_relationship: '',
  },
  tab3_cc: {
    chief_complaint_patient_words: '',
    primary_reason_coded: '',
  },
  tab4_subjective_hpi: {
    onset_date: '',
    duration: '',
    severity_0_10: 0,
    progression: '',
    associated_symptoms: [],
    timeline: '',
  },
  tab5_subjective_history: {
    pmh: [],
    psh: [],
    medications: [],
    allergies: [],
    family_history: [],
    social_history: {
      tobacco: '',
      alcohol: '',
      drugs: '',
      occupation: '',
    },
  },
  tab6_ros: {
    constitutional: '',
    eyes: '',
    ears_nose_throat: '',
    cardiovascular: '',
    respiratory: '',
    gastrointestinal: '',
    genitourinary: '',
    musculoskeletal: '',
    neurological: '',
    psychiatric: '',
    endocrine: '',
    lymph_nodes: '',
    skin: '',
    allergy_immunology: '',
  },
  tab7_objective_vitals_general: {
    vitals: {
      bp_systolic: 0,
      bp_diastolic: 0,
      hr: 0,
      rr: 0,
      temp_f: 0,
      o2_sat: 0,
      pain_score: 0,
    },
    general_appearance: '',
    mental_status: '',
  },
  tab8_objective_exam_telemed: {
    physical_exam: {},
    telemedicine_limitations: '',
  },
  tab9_objective_diagnostics: {
    home_readings: [],
    recent_labs: [],
    imaging: [],
    external_records: [],
  },
  tab10_assessment: {
    problem_list: [],
    differential_diagnosis: [],
    risk_severity: '',
  },
  tab11_plan: {
    medications: [],
    orders: [],
    patient_education: [],
    follow_up: [],
    referrals: [],
  },
  tab12_mdm_quality_attachments_signoff: {
    medical_decision_making: '',
    billing_codes: [],
    quality_checks: [],
    attachments: [],
    signature_date: '',
    signer_name: '',
    signer_credentials: '',
  },
  meta: {
    schema_version: '1.0.0',
    encounter_id: '',
    appointment_id: '',
    created_at: '',
    status: 'draft',
    drafted_by: 'ai',
    provenance: {
      context_snapshot_id: '',
      model: 'claude-3-haiku-20240307',
      prompt_version: '1.0.0',
      confidence: 0.8,
    },
    ai_flags: {
      needs_clinician_confirmation: [],
      missing_critical_info: [],
    },
  },
};

const SOAP_SYSTEM_PROMPT = `You are an expert clinical documentation AI. Your task is to generate a structured SOAP note draft using patient data and the transcription.

DATA SOURCES:
- CONTEXT_SNAPSHOT: Patient demographics, active conditions, medications, allergies, recent vitals, recent clinical notes, appointment context
- APPOINTMENT_CONTEXT: Contains appointment_id, chief_complaint, provider_name, facility_name, scheduled_start, specialty
- TRANSCRIPT: Recorded conversation between provider and patient during the telemedicine visit

CRITICAL DATA VERIFICATION BEFORE GENERATING SOAP:
1. Check CONTEXT_SNAPSHOT.patient_demographics has ALL required fields
2. If any Tab 2 field is missing from snapshot, add to ai_flags.missing_critical_info
3. NEVER invent patient demographics - use ONLY what's in snapshot
4. For appointment context, use CONTEXT_SNAPSHOT.appointment_context fields

MANDATORY TAB 2 FIELDS (extract from CONTEXT_SNAPSHOT.patient_demographics):
- full_name: REQUIRED (from snapshot.patient_demographics.full_name)
- patient_number: OPTIONAL (from snapshot.patient_demographics.patient_number) - include if available
- dob: REQUIRED (from snapshot.patient_demographics.dob)
- age: REQUIRED (calculate from dob or use snapshot.patient_demographics.age)
- sex_at_birth / gender: REQUIRED (from snapshot.patient_demographics.gender, use as sex_at_birth)
- phone: REQUIRED (from snapshot.patient_demographics.phone)
- email: REQUIRED (from snapshot.patient_demographics.email)
- address: OPTIONAL (from snapshot.patient_demographics.address) - include if available
- emergency_contact_name: OPTIONAL (from snapshot.patient_demographics.emergency_contact_name)
- emergency_contact_phone: OPTIONAL (from snapshot.patient_demographics.emergency_contact_phone)
- emergency_contact_relationship: OPTIONAL (from snapshot.patient_demographics.emergency_contact_relationship)

IF ANY REQUIRED FIELD IS MISSING:
- Leave field blank (do not invent)
- Add to ai_flags.missing_critical_info with field name
- Add to ai_flags.needs_clinician_confirmation for provider to fill manually

PRIORITY INSTRUCTION - POPULATE TAB 2 PATIENT DETAILS FIRST:
Before extracting anything else, ALWAYS populate Tab 2 (tab2_patient_identification) completely from CONTEXT_SNAPSHOT.patient_demographics:
- This is the MOST IMPORTANT step
- Extract: full_name, dob, age, sex_at_birth (gender), phone, email, address
- Extract emergency contact info if available
- NEVER leave required fields blank if data is in the snapshot
- These fields are foundational and must be correct

EXTRACTION RULES:

Tab 1 - Encounter Header (Extract from snapshot.appointment_context + transcript):
- visit_date: From CONTEXT_SNAPSHOT.appointment_context.scheduled_start (or today's date if not available)
- visit_type: CONTEXT_SNAPSHOT.appointment_context.appointment_type (default "video" for telemedicine)
- chief_complaint_as_written: FIRST use CONTEXT_SNAPSHOT.appointment_context.chief_complaint, THEN enhance from transcript if patient elaborates
- appointment_number: CONTEXT_SNAPSHOT.appointment_context.appointment_number (for reference tracking)
- provider_name: CONTEXT_SNAPSHOT.appointment_context.provider_name
- facility_name: CONTEXT_SNAPSHOT.appointment_context.facility_name
- specialty: CONTEXT_SNAPSHOT.appointment_context.specialty
- identity_verified_method: From TRANSCRIPT ("Verbal confirmation", "Video ID check", etc.)
- interpreter_needed: Check if patient mentioned language barrier

Tab 2 - Patient Identification (CRITICAL - Extract ALL from snapshot):
- full_name: From CONTEXT_SNAPSHOT.patient_demographics.full_name
- dob: From CONTEXT_SNAPSHOT.patient_demographics.dob
- age: Calculate from DOB or from CONTEXT_SNAPSHOT.patient_demographics
- sex_at_birth: From CONTEXT_SNAPSHOT.patient_demographics.sex_at_birth
- phone: From CONTEXT_SNAPSHOT.patient_demographics.phone
- email: From CONTEXT_SNAPSHOT.patient_demographics.email
- address: From CONTEXT_SNAPSHOT.patient_demographics.address (if available, else leave blank)
- emergency_contact_name: From CONTEXT_SNAPSHOT.patient_demographics.emergency_contact_name (if available)
- emergency_contact_phone: From CONTEXT_SNAPSHOT.patient_demographics.emergency_contact_phone (if available)
- emergency_contact_relationship: From CONTEXT_SNAPSHOT.patient_demographics (if available)

Tab 3 - Chief Complaint:
- chief_complaint_patient_words: PRESERVE EXACT PATIENT QUOTE from transcript
- primary_reason_coded: Categorize the reason (e.g., "Follow-up", "New symptom", "Medication review")

Tab 4 - Subjective / HPI:
- onset_date: When did symptoms start? (extract from TRANSCRIPT)
- duration: How long? (extract from TRANSCRIPT)
- severity_0_10: Numeric pain/severity scale from TRANSCRIPT
- progression: Has it gotten better/worse? (extract from TRANSCRIPT)
- associated_symptoms: Other symptoms mentioned? (extract from TRANSCRIPT)
- timeline: Full chronology of event (extract from TRANSCRIPT)

Tab 5 - History (Extract from CONTEXT_SNAPSHOT first, then update with TRANSCRIPT):
- pmh (Past Medical History): From CONTEXT_SNAPSHOT.active_conditions (list all chronic conditions)
- psh (Past Surgical History): From CONTEXT_SNAPSHOT clinical notes (if available, else leave blank)
- medications: CRITICAL - From CONTEXT_SNAPSHOT.current_medications (list ALL current medications with doses). If transcript mentions med changes, update list.
- allergies: CRITICAL - From CONTEXT_SNAPSHOT.allergies (list ALL known allergies). If none documented, mark "None documented - verify with patient during transcript"
- family_history: From CONTEXT_SNAPSHOT if available, supplement with TRANSCRIPT
- social_history: Extract smoking, alcohol, drugs, occupation from TRANSCRIPT. If not mentioned, check CONTEXT_SNAPSHOT

Tab 6 - Review of Systems (14 systems):
- Extract any positive findings from TRANSCRIPT
- Leave blank if not mentioned (do NOT assume negative)

Tab 7 - Objective Vitals (Extract from CONTEXT_SNAPSHOT.recent_labs_vitals first):
- vitals: From CONTEXT_SNAPSHOT.recent_labs_vitals (bp_systolic, bp_diastolic, hr, rr, temp_f, o2_sat, pain_score)
- general_appearance: From TRANSCRIPT video observation ("Alert and oriented", "Appears stated age", "Well-nourished", etc.) or from CONTEXT_SNAPSHOT if available
- mental_status: From TRANSCRIPT video ("Appropriate affect", "Clear speech", "Oriented to person/place/time") or from CONTEXT_SNAPSHOT

Tab 8 - Physical Exam (Telemedicine-specific):
- physical_exam: Document visual observations from video only
- telemedicine_limitations: Note what couldn't be assessed (palpation, auscultation, etc.)

Tab 9 - Diagnostics (Extract from CONTEXT_SNAPSHOT.recent_labs_vitals first):
- home_readings: Any vitals/readings patient mentioned measuring in TRANSCRIPT
- recent_labs: From CONTEXT_SNAPSHOT.recent_labs_vitals (include test names, values, dates, normal ranges)
- imaging: From CONTEXT_SNAPSHOT.recent_labs_vitals (include study type, date, findings)

Tab 10 - Assessment (Build from CONTEXT_SNAPSHOT + TRANSCRIPT):
- problem_list: Include all from CONTEXT_SNAPSHOT.active_conditions + new problems identified in HPI/findings/TRANSCRIPT
- differentials: What conditions could explain new symptoms from TRANSCRIPT?
- severity_risk_stratification: Is this urgent/emergent/routine based on findings and conditions?

Tab 11 - Plan:
- medications: New prescriptions or medication changes from TRANSCRIPT
- orders: Any referrals, labs, imaging ordered?
- patient_education: What was discussed with patient?
- follow_up: Next appointment timing?
- referrals: Any specialist referrals mentioned?

CRITICAL RULES:
1. Use ONLY provided CONTEXT_SNAPSHOT and TRANSCRIPT. Do NOT invent information.
2. If information is missing, leave field blank/null or state "Not mentioned"
3. For uncertainties, add to ai_flags.needs_clinician_confirmation
4. If critical info missing (allergies, meds unknown), add to ai_flags.missing_critical_info
5. Output MUST be valid JSON ONLY. No text before/after.
6. Preserve exact patient quotes in patient_words fields
7. If transcript conflicts snapshot, flag in needs_clinician_confirmation
8. Never assume normal findings
9. Mark confidence based on information completeness

SAFETY PRIORITIES:
- Always include allergies (mark "Unknown" if not documented)
- Always include current medications (mark "Unknown" if not documented)
- Flag any red flags, emergency symptoms, or concerning findings
- NEVER assume test results are normal
- Include all chronic conditions from CONTEXT_SNAPSHOT in problem list`;

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed', code: 'METHOD_NOT_ALLOWED', status: 405 }),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }

  try {
    // Verify Firebase JWT
    const token = req.headers.get('x-firebase-token');
    if (!token) {
      return new Response(
        JSON.stringify({ error: 'Missing Firebase token', code: 'MISSING_TOKEN', status: 401 }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const auth = await verifyFirebaseJWT(token);
    if (!auth.valid) {
      return new Response(
        JSON.stringify({ error: 'Invalid Firebase token', code: 'INVALID_FIREBASE_TOKEN', status: 401 }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const { encounter_id, patientMedicalHistory } = await req.json();

    if (!encounter_id) {
      return new Response(
        JSON.stringify({ error: 'Missing encounter_id', code: 'MISSING_PARAMS', status: 400 }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log('[generate-soap-draft-v2] Received patientMedicalHistory from request body:', !!patientMedicalHistory);

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

    console.log(`[generate-soap-draft-v2] Starting SOAP generation for encounter: ${encounter_id}`);

    // 1. Update encounter status to drafting
    await supabaseAdmin
      .from('video_call_sessions')
      .update({
        soap_status: 'drafting',
        encounter_status: 'soap_drafting',
      })
      .eq('id', encounter_id);

    // 2. Fetch encounter and context snapshot
    const { data: session, error: sessionError } = await supabaseAdmin
      .from('video_call_sessions')
      .select('context_snapshot_id, appointment_id, started_at, ended_at')
      .eq('id', encounter_id)
      .single();

    if (sessionError || !session) {
      console.error('[generate-soap-draft-v2] Failed to fetch session:', sessionError);
      return new Response(
        JSON.stringify({ error: 'Session not found', code: 'SESSION_NOT_FOUND', status: 404 }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 3. Fetch context snapshot
    const { data: snapshot, error: snapshotError } = await supabaseAdmin
      .from('context_snapshots')
      .select('*')
      .eq('id', session.context_snapshot_id)
      .single();

    if (snapshotError || !snapshot) {
      console.error('[generate-soap-draft-v2] Failed to fetch context snapshot:', snapshotError);
      return new Response(
        JSON.stringify({ error: 'Context snapshot not found', code: 'SNAPSHOT_NOT_FOUND', status: 404 }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 3.5. Merge patientMedicalHistory from request body with snapshot from database
    let contextData: any = { ...snapshot };
    if (patientMedicalHistory) {
      console.log('[generate-soap-draft-v2] Merging patientMedicalHistory from request body with snapshot...');

      // Merge patient demographics (request body takes precedence for missing fields)
      if (patientMedicalHistory.demographics) {
        contextData.patient_demographics = {
          ...(contextData.patient_demographics || {}),
          ...patientMedicalHistory.demographics,
        };
        console.log(
          `[generate-soap-draft-v2] ✅ Merged patient demographics: ${patientMedicalHistory.demographics.full_name || 'N/A'}`
        );
      }

      // Merge patient profile data
      if (patientMedicalHistory.profile) {
        contextData.patient_profile = {
          ...(contextData.patient_profile || {}),
          ...patientMedicalHistory.profile,
        };
        console.log('[generate-soap-draft-v2] ✅ Merged patient profile data');
      }

      // Merge medical history
      if (patientMedicalHistory.medical_history) {
        contextData.patient_medical_history = {
          ...(contextData.patient_medical_history || {}),
          ...patientMedicalHistory.medical_history,
        };
        console.log('[generate-soap-draft-v2] ✅ Merged patient medical history');
      }

      console.log('[generate-soap-draft-v2] Complete merged context prepared for SOAP generation');
    } else {
      console.log('[generate-soap-draft-v2] No patientMedicalHistory in request body, using snapshot data only');
    }

    // 4. Fetch and assemble transcript chunks
    console.log('[generate-soap-draft-v2] Fetching transcript chunks...');
    const { data: chunks, error: chunksError } = await supabaseAdmin
      .from('call_transcript_chunks')
      .select('sequence, speaker, text, start_ms, end_ms')
      .eq('encounter_id', encounter_id)
      .order('sequence', { ascending: true });

    if (chunksError) {
      console.error('[generate-soap-draft-v2] Failed to fetch chunks:', chunksError);
    }

    const transcriptText = (chunks || [])
      .map((c: any) => `[${formatTime(c.start_ms)}] ${c.speaker}: ${c.text}`)
      .join('\n');

    console.log(`[generate-soap-draft-v2] Assembled transcript: ${transcriptText.length} characters`);

    // 5. Build the user prompt with merged context data
    const userPrompt = buildSoapPrompt(
      contextData,
      transcriptText,
      {
        visit_type: 'video',
        start_time: session.started_at,
        end_time: session.ended_at,
        appointment_id: session.appointment_id,
      }
    );
    console.log('[generate-soap-draft-v2] User prompt built with merged patient context');

    // 6. Call Bedrock Lambda for SOAP generation (clinical model for providers)
    if (!bedrockLambdaUrl) {
      return new Response(
        JSON.stringify({ error: 'Bedrock Lambda endpoint not configured', code: 'CONFIG_ERROR', status: 500 }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log('[generate-soap-draft-v2] Calling Bedrock Lambda for SOAP generation...');

    // Call AWS Lambda function with timeout and retry logic
    const LAMBDA_TIMEOUT_MS = 60000; // 60 second timeout for SOAP generation
    const MAX_RETRIES = 2;
    const RETRY_DELAY_MS = 1000;

    let lambdaResponse: Response | null = null;
    let lastError: Error | null = null;
    const startTime = Date.now();

    for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), LAMBDA_TIMEOUT_MS);

        try {
          lambdaResponse = await fetch(bedrockLambdaUrl, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            signal: controller.signal,
            body: JSON.stringify({
              message: userPrompt,
              modelId: 'eu.amazon.nova-pro-v1:0', // Clinical model (Claude Opus equivalent)
              systemPrompt: SOAP_SYSTEM_PROMPT,
              modelConfig: {
                temperature: 0.3,
                maxTokens: 16000,
              },
              preferredLanguage: 'en',
            }),
          });

          clearTimeout(timeoutId);

          if (lambdaResponse.ok) {
            break; // Success, exit retry loop
          }

          if (lambdaResponse.status >= 500 && attempt < MAX_RETRIES) {
            console.log(`[generate-soap-draft-v2] Lambda returned ${lambdaResponse.status}, retrying (attempt ${attempt + 1}/${MAX_RETRIES})`);
            await new Promise(r => setTimeout(r, RETRY_DELAY_MS * Math.pow(2, attempt)));
            continue;
          }
        } finally {
          clearTimeout(timeoutId);
        }
      } catch (error) {
        lastError = error as Error;

        if ((error as any).name === 'AbortError') {
          console.error(`[generate-soap-draft-v2] Lambda call timed out after ${LAMBDA_TIMEOUT_MS}ms (attempt ${attempt + 1})`);
          if (attempt < MAX_RETRIES) {
            await new Promise(r => setTimeout(r, RETRY_DELAY_MS * Math.pow(2, attempt)));
            continue;
          }
          throw new Error(`SOAP generation timeout after ${LAMBDA_TIMEOUT_MS / 1000}s`);
        }

        if (attempt < MAX_RETRIES) {
          console.log(`[generate-soap-draft-v2] Lambda call failed, retrying (attempt ${attempt + 1}/${MAX_RETRIES}): ${error.message}`);
          await new Promise(r => setTimeout(r, RETRY_DELAY_MS * Math.pow(2, attempt)));
          continue;
        }

        throw error;
      }
    }

    const responseTime = Date.now() - startTime;

    if (!lambdaResponse || !lambdaResponse.ok) {
      const errorData = lambdaResponse ? await lambdaResponse.json().catch(() => ({})) : {};
      console.error('[generate-soap-draft-v2] Lambda error response:', errorData);
      return new Response(
        JSON.stringify({
          error: errorData.error || lastError?.message || 'Failed to generate SOAP from Bedrock',
          code: 'BEDROCK_ERROR',
          status: 500,
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`[generate-soap-draft-v2] Received response from Bedrock Lambda (${responseTime}ms)`);

    // 7. Parse Lambda response
    let soapDraft: any;
    const lambdaData = await lambdaResponse.json();
    const responseText = lambdaData.message || '';

    try {
      soapDraft = JSON.parse(responseText);
    } catch (parseError) {
      console.error('[generate-soap-draft-v2] Failed to parse Claude response as JSON:', parseError);
      console.error('[generate-soap-draft-v2] Response was:', responseText.substring(0, 500));
      return new Response(
        JSON.stringify({
          error: 'Failed to parse AI response',
          code: 'PARSE_ERROR',
          status: 500,
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 7b. VALIDATE Tab 2 completeness before returning
    console.log('[generate-soap-draft-v2] Validating Tab 2 Patient Demographics completeness...');
    const tab2 = soapDraft.tab2_patient_identification || {};
    const requiredFields = ['full_name', 'dob', 'age', 'sex_at_birth', 'phone', 'email'];
    const missingRequired = requiredFields.filter(field => !tab2[field] || tab2[field] === '');

    if (missingRequired.length > 0) {
      console.warn(`[generate-soap-draft-v2] ⚠️  Tab 2 missing required fields: ${missingRequired.join(', ')}`);

      // Add to ai_flags for provider attention
      if (!soapDraft.meta) {
        soapDraft.meta = { ai_flags: { needs_clinician_confirmation: [], missing_critical_info: [] } };
      }
      if (!soapDraft.meta.ai_flags) {
        soapDraft.meta.ai_flags = { needs_clinician_confirmation: [], missing_critical_info: [] };
      }

      missingRequired.forEach((field: string) => {
        soapDraft.meta.ai_flags.missing_critical_info.push(`Tab 2: ${field} is missing - please fill manually`);
      });

      // Lower confidence score due to missing critical data
      if (soapDraft.meta.provenance) {
        soapDraft.meta.provenance.confidence = Math.max(0.5, (soapDraft.meta.provenance.confidence || 0.8) - 0.2);
      }
    } else {
      console.log('[generate-soap-draft-v2] ✅ Tab 2 Patient Demographics complete');
    }

    // Log optional fields status
    const optionalFields = ['address', 'emergency_contact_name', 'emergency_contact_phone', 'patient_number'];
    const presentOptional = optionalFields.filter(field => tab2[field] && tab2[field] !== '');
    console.log(`[generate-soap-draft-v2] Tab 2 optional fields present: ${presentOptional.join(', ') || 'none'}`);

    // 8. Add provenance metadata
    soapDraft.meta = {
      ...soapDraft.meta,
      schema_version: '1.0.0',
      appointment_id: session.appointment_id,
      encounter_id,
      created_at: new Date().toISOString(),
      status: 'draft',
      drafted_by: 'ai',
      provenance: {
        context_snapshot_id: session.context_snapshot_id,
        transcript_id: encounter_id,
        model: 'claude-3-haiku-20240307',
        prompt_version: '1.0.0',
        confidence: 0.8,
      },
    };

    // 9. Save to soap_draft_json
    console.log('[generate-soap-draft-v2] Updating encounter with SOAP draft...');
    const { error: updateError } = await supabaseAdmin
      .from('video_call_sessions')
      .update({
        soap_draft_json: soapDraft,
        soap_status: 'draft_ready',
        encounter_status: 'soap_ready',
        server_revision: 1,
      })
      .eq('id', encounter_id);

    if (updateError) {
      console.error('[generate-soap-draft-v2] Failed to update SOAP draft:', updateError);
      return new Response(
        JSON.stringify({
          error: 'Failed to save SOAP draft',
          code: 'UPDATE_FAILED',
          status: 500,
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log('[generate-soap-draft-v2] ✅ SOAP draft generated and saved successfully');

    return new Response(
      JSON.stringify({
        ok: true,
        soap_draft: soapDraft,
        status: 200,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('[generate-soap-draft-v2] Unexpected error:', error);
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        code: 'INTERNAL_ERROR',
        status: 500,
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

// Helper functions

function formatTime(ms?: number): string {
  if (!ms) return '0:00';
  const totalSeconds = Math.floor(ms / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${minutes}:${seconds.toString().padStart(2, '0')}`;
}

function buildSoapPrompt(snapshot: any, transcript: string, metadata: any): string {
  return `TASK: Generate a complete SOAP note draft (all 12 tabs) using the provided JSON schema.

CONTEXT_SNAPSHOT (Truth Source - Patient History & Appointment Context):
${JSON.stringify(snapshot, null, 2)}

APPOINTMENT CONTEXT (from snapshot.appointment_context):
- Appointment ID: ${snapshot.appointment_context?.appointment_id || 'Not provided'}
- Appointment Number: ${snapshot.appointment_context?.appointment_number || 'Not provided'}
- Chief Complaint (pre-visit): ${snapshot.appointment_context?.chief_complaint || 'Not specified'}
- Appointment Type: ${snapshot.appointment_context?.appointment_type || 'Not specified'}
- Specialty: ${snapshot.appointment_context?.specialty || 'General'}
- Provider: ${snapshot.appointment_context?.provider_name || 'Not provided'}
- Facility: ${snapshot.appointment_context?.facility_name || 'Not provided'}
- Scheduled Start: ${snapshot.appointment_context?.scheduled_start || 'Not provided'}

VISIT METADATA:
- visit_type: ${metadata.visit_type}
- encounter_start: ${metadata.start_time}
- encounter_end: ${metadata.end_time}
- appointment_id: ${metadata.appointment_id}

TRANSCRIPT (Truth Source - What was said during the visit):
${transcript}

OUTPUT SCHEMA (fill all fields):
${JSON.stringify(SOAP_SCHEMA_SKELETON, null, 2)}

CRITICAL INSTRUCTIONS - SPEECH-TO-TEXT TRANSCRIPT ANALYSIS:

SPEAKER IDENTIFICATION (from Chime speech-to-text):
- "Provider:" = clinician/doctor statements (use for clinical observations, plan, assessment)
- "Patient:" = patient statements (use for symptoms, complaints, subjective experience, history)

STEP 1 - EXTRACT PATIENT DEMOGRAPHICS (MANDATORY):
- Populate ALL of Tab 2 from CONTEXT_SNAPSHOT.patient_demographics first
- Include: full_name, dob, age, sex_at_birth, phone, email, address, emergency contacts

STEP 2 - EXTRACT CHIEF COMPLAINT FROM TRANSCRIPT:
- Look for patient's FIRST statements about why they called (usually in first 1-2 "Patient:" lines)
- Extract EXACT patient words: "I've been having...", "I'm worried about...", "The problem is..."
- Preserve in chief_complaint_patient_words with exact quotes
- Categorize reason: "Follow-up", "New symptom", "Medication review", etc.

STEP 3 - EXTRACT HISTORY OF PRESENT ILLNESS (HPI) FROM PATIENT STATEMENTS:
- ONSET: When did it start? Search for "3 days ago", "since Monday", "last week", "started when..."
- DURATION: How long? "It's been 2 weeks", "for a month", "all day"
- SEVERITY: Pain/severity scale? "8 out of 10", "mild", "severe", "it really hurts"
- PROGRESSION: Getting better or worse? "It's getting worse", "improving", "same"
- ASSOCIATED SYMPTOMS: What else? "fever", "shortness of breath", "nausea", "headache"
- Extract COMPLETE TIMELINE of symptom development from patient description

STEP 4 - EXTRACT REVIEW OF SYSTEMS (ROS) FROM PATIENT STATEMENTS:
- SCAN transcript for mentions of body systems
- Map to ROS fields:
  * "fever, chills, fatigue" → constitutional
  * "chest pain, palpitations" → cardiovascular
  * "shortness of breath, cough" → respiratory
  * "nausea, vomiting, diarrhea, constipation" → gastrointestinal
  * "dysuria, frequency" → genitourinary
  * "joint pain, swelling" → musculoskeletal
  * "headache, dizziness, weakness" → neurological
  * "anxiety, depression" → psychiatric
- ONLY include systems mentioned (positive findings)
- DO NOT assume negative findings
- Use patient's EXACT description when possible

STEP 5 - EXTRACT PROVIDER OBSERVATIONS (PHYSICAL EXAM, VITALS, MENTAL STATUS):
- From Provider statements, extract:
  * Vitals: "blood pressure is...", "heart rate is...", "temperature", "oxygen saturation"
  * Appearance: "You look alert", "appear comfortable", "well-nourished", "appears ill"
  * Mental Status: "clear thinking", "oriented", "appropriate affect", "good eye contact"
  * Physical findings: "lungs clear", "rash on", "swelling in", etc.
- For telemedicine, note limitations: "I can't physically examine", "Can't do auscultation"
- Supplement with snapshot vitals if call vitals not documented

STEP 6 - EXTRACT MEDICATIONS & ALLERGIES FROM TRANSCRIPT:
- Listen for patient mentioning: "I'm on...", "I take...", "I'm allergic to..."
- Update snapshot medications if patient mentions changes: "I stopped taking...", "I started..."
- Extract allergies: "I'm allergic to penicillin", "Aspirin gives me a rash"
- MERGE transcript data with snapshot (don't replace)

STEP 7 - EXTRACT ASSESSMENT & PLAN FROM PROVIDER STATEMENTS:
- ASSESSMENT: What did provider conclude? "I think you have...", "Based on symptoms, sounds like...", "This appears to be..."
- DIFFERENTIALS: Alternative diagnoses? "Could be...", "Might be...", "Can't rule out..."
- PLAN: Next steps from provider:
  * Medications: "I'm going to prescribe...", "Take this medication..."
  * Follow-up: "Come back if...", "Follow up in 2 weeks", "Call if symptoms worsen"
  * Referrals: "See a specialist", "I'm referring you to..."
  * Education: "Rest", "Avoid...", "Watch for...", "Drink plenty of fluids"
  * Orders: "Get labs done", "X-ray", "Blood tests"

STEP 8 - COMBINE DATA SOURCES:
- Tab 2: From SNAPSHOT only (patient demographics)
- Tab 4 (HPI): From TRANSCRIPT patient statements
- Tab 5 (PMH/Meds/Allergies): SNAPSHOT as base + TRANSCRIPT updates
- Tab 6 (ROS): From TRANSCRIPT patient statements
- Tab 7 (Vitals): From TRANSCRIPT provider observations + SNAPSHOT recent vitals
- Tab 8 (Exam): From TRANSCRIPT provider observations
- Tab 9 (Diagnostics): From SNAPSHOT recent labs + TRANSCRIPT mentions
- Tab 10 (Assessment): From TRANSCRIPT provider statements + SNAPSHOT conditions
- Tab 11 (Plan): From TRANSCRIPT provider recommendations

GENERAL RULES:
1. For any information NOT in transcript or snapshot, leave blank and flag in ai_flags.needs_clinician_confirmation
2. Mark missing critical info in ai_flags.missing_critical_info (allergies unknown, meds unknown, etc.)
3. Use exact quotes from patient and provider where possible
4. Transcript is speech-to-text - may have minor transcription errors - use clinical context to correct
5. Return ONLY valid JSON - no markdown, no explanations, no text before/after JSON
6. VERIFY Tab 2 is completely populated from snapshot before returning

RETURN VALID JSON ONLY.`;
}
