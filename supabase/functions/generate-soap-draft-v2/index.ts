import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import Anthropic from 'https://esm.sh/@anthropic-ai/sdk@0.24.3';
import { verifyFirebaseJWT } from '../_shared/verify-firebase-jwt.ts';

interface ErrorResponse {
  error: string;
  code: string;
  status: number;
}

const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY') || '';

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
    emergency_contact_name: '',
    emergency_contact_phone: '',
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

const SOAP_SYSTEM_PROMPT = `You are a clinical documentation assistant. Your task is to generate a structured SOAP note draft for a clinician to review and finalize.

CRITICAL RULES:
1. Use ONLY the provided CONTEXT_SNAPSHOT and TRANSCRIPT. Do NOT invent information.
2. If information is missing, leave the field blank/null or state "Not mentioned in transcript"
3. For uncertainties or potential gaps, add entries to ai_flags.needs_clinician_confirmation
4. If critical clinical information is missing (allergies, current meds, red flags), add to ai_flags.missing_critical_info
5. Output MUST be valid JSON conforming to the provided schema. Output JSON ONLY.
6. Preserve exact patient quotes in chief_complaint_patient_words
7. Extract timeline, duration, severity from transcript
8. Use problem-oriented language in assessment and plan
9. If transcript conflicts with snapshot data, note in ai_flags.needs_clinician_confirmation

SAFETY PRIORITIES:
- Always include allergies section (mark unknown if not mentioned)
- Always include current medications (mark unknown if not mentioned)
- Always flag any red flags or emergency symptoms
- Never assume normal findings - only include what was documented or stated
- Mark confidence level based on information completeness`;

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed', code: 'METHOD_NOT_ALLOWED', status: 405 }),
      { status: 405, headers: { 'Content-Type': 'application/json' } }
    );
  }

  try {
    // Verify Firebase JWT
    const token = req.headers.get('x-firebase-token');
    if (!token) {
      return new Response(
        JSON.stringify({ error: 'Missing Firebase token', code: 'MISSING_TOKEN', status: 401 }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const auth = await verifyFirebaseJWT(token);
    if (!auth.valid) {
      return new Response(
        JSON.stringify({ error: 'Invalid Firebase token', code: 'INVALID_FIREBASE_TOKEN', status: 401 }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const { encounter_id } = await req.json();

    if (!encounter_id) {
      return new Response(
        JSON.stringify({ error: 'Missing encounter_id', code: 'MISSING_PARAMS', status: 400 }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

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
        { status: 404, headers: { 'Content-Type': 'application/json' } }
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
        { status: 404, headers: { 'Content-Type': 'application/json' } }
      );
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

    // 5. Build the user prompt
    const userPrompt = buildSoapPrompt(
      snapshot,
      transcriptText,
      {
        visit_type: 'video',
        start_time: session.started_at,
        end_time: session.ended_at,
        appointment_id: session.appointment_id,
      }
    );

    // 6. Call Claude via Anthropic SDK
    console.log('[generate-soap-draft-v2] Calling Claude 3 Haiku for SOAP generation...');
    const anthropic = new Anthropic({
      apiKey: anthropicApiKey,
    });

    const message = await anthropic.messages.create({
      model: 'claude-3-haiku-20240307',
      max_tokens: 16000,
      temperature: 0.3,
      system: SOAP_SYSTEM_PROMPT,
      messages: [
        {
          role: 'user',
          content: userPrompt,
        },
      ],
    });

    console.log('[generate-soap-draft-v2] Received response from Claude');

    // 7. Parse JSON response
    let soapDraft: any;
    const responseText = message.content[0].type === 'text' ? message.content[0].text : '';

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
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

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
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    console.log('[generate-soap-draft-v2] ✅ SOAP draft generated and saved successfully');

    return new Response(
      JSON.stringify({
        ok: true,
        soap_draft: soapDraft,
        status: 200,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('[generate-soap-draft-v2] Unexpected error:', error);
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        code: 'INTERNAL_ERROR',
        status: 500,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
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

CONTEXT_SNAPSHOT (Truth Source - Patient History):
${JSON.stringify(snapshot, null, 2)}

VISIT METADATA:
- visit_type: ${metadata.visit_type}
- encounter_start: ${metadata.start_time}
- encounter_end: ${metadata.end_time}
- appointment_id: ${metadata.appointment_id}

TRANSCRIPT (Truth Source - What was said during the visit):
${transcript}

OUTPUT SCHEMA (fill all fields):
${JSON.stringify(SOAP_SCHEMA_SKELETON, null, 2)}

INSTRUCTIONS:
1. Extract chief complaint in patient's own words from transcript
2. Build HPI (History of Present Illness) from what patient stated about onset, duration, severity, progression
3. Use snapshot data for PMH, medications, allergies as baseline - update if transcript mentions changes
4. Extract vitals if documented during call
5. Build assessment based on chief complaint and findings
6. Build plan based on what was discussed during call
7. For any information NOT in transcript or snapshot, leave blank and add to ai_flags.needs_clinician_confirmation
8. Mark missing critical info (allergies unknown, meds unknown, etc.) in ai_flags.missing_critical_info
9. Use exact patient quotes where possible
10. Return ONLY valid JSON - no markdown, no explanations

RETURN VALID JSON ONLY.`;
}
