/**
 * MedZen Generate Clinical Note Edge Function
 *
 * Generates AI-powered clinical notes (SOAP format) from video call transcripts
 * using AWS Bedrock Claude 3.7 Sonnet for clinical-grade accuracy.
 *
 * Features:
 * - Multi-language transcript support (English, French, African languages)
 * - SOAP note format with ICD-10/CPT coding suggestions
 * - Medical entity extraction and structured data
 * - EHRbase/OpenEHR ready output
 *
 * @version 1.0.0
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import {
  BedrockRuntimeClient,
  InvokeModelCommand,
} from 'npm:@aws-sdk/client-bedrock-runtime@3.716.0';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { getCorsHeaders, securityHeaders } from '../_shared/cors.ts';
import { checkRateLimit, getRateLimitConfig, createRateLimitErrorResponse } from '../_shared/rate-limiter.ts';
import { verifyFirebaseJWT } from '../_shared/verify-firebase-jwt.ts';

// AWS Bedrock configuration
const bedrockClient = new BedrockRuntimeClient({
  region: Deno.env.get('AWS_REGION') || 'eu-central-1',
  credentials: {
    accessKeyId: Deno.env.get('AWS_ACCESS_KEY_ID') || '',
    secretAccessKey: Deno.env.get('AWS_SECRET_ACCESS_KEY') || '',
  },
});

// Supabase configuration
const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

// Clinical model for note generation
// Using Claude 3.5 Sonnet v2 via cross-region inference for eu-central-1
// Format: {region}.anthropic.{model-id} for cross-region inference
const CLINICAL_MODEL_ID = Deno.env.get('CLINICAL_MODEL_ID') || 'anthropic.claude-3-sonnet-20240229-v1:0';

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-firebase-token',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface GenerateNoteRequest {
  sessionId: string;
  appointmentId: string;
  providerId: string;
  patientId: string;
  transcriptLanguage?: string;
  noteType?: 'soap' | 'progress' | 'consultation' | 'procedure';
  includeIcd10?: boolean;
  includeCpt?: boolean;
}

interface ClinicalNote {
  subjective: string;
  objective: string;
  assessment: string;
  plan: string;
  chiefComplaint: string;
  historyOfPresentIllness: string;
  icd10Codes: Array<{ code: string; description: string; confidence: number }>;
  cptCodes: Array<{ code: string; description: string; confidence: number }>;
  medicalEntities: Array<{
    text: string;
    type: string;
    icd10?: string;
    confidence: number;
  }>;
}

serve(async (req: Request) => {
  const origin = req.headers.get('origin');
  const corsHeaders_dynamic = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { ...corsHeaders_dynamic, ...securityHeaders } });
  }

  const startTime = Date.now();

  try {
    // Verify Firebase JWT
    const token = req.headers.get('x-firebase-token');
    if (!token) {
      return new Response(
        JSON.stringify({ error: 'Missing Firebase token', code: 'MISSING_TOKEN', status: 401 }),
        { status: 401, headers: { ...corsHeaders_dynamic, ...securityHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const auth = await verifyFirebaseJWT(token);
    if (!auth.valid) {
      return new Response(
        JSON.stringify({ error: 'Invalid Firebase token', code: 'INVALID_FIREBASE_TOKEN', status: 401 }),
        { status: 401, headers: { ...corsHeaders_dynamic, ...securityHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Rate limiting check
    const rateLimitConfig = getRateLimitConfig('generate-clinical-note', auth.user_id || auth.sub || '');
    const rateLimit = await checkRateLimit(rateLimitConfig);
    if (!rateLimit.allowed) {
      return createRateLimitErrorResponse(rateLimit);
    }

    // Initialize Supabase client with service role
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse request
    const body: GenerateNoteRequest = await req.json();
    const {
      sessionId,
      appointmentId,
      providerId,
      patientId,
      transcriptLanguage = 'en-US',
      noteType = 'soap',
      includeIcd10 = true,
      includeCpt = true,
    } = body;

    // Validate required fields
    if (!sessionId || !appointmentId || !providerId || !patientId) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: sessionId, appointmentId, providerId, patientId' }),
        { status: 400, headers: { ...corsHeaders_dynamic, ...securityHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`Generating clinical note for session: ${sessionId}`);

    // Get transcript from video_call_sessions
    const { data: session, error: sessionError } = await supabase
      .from('video_call_sessions')
      .select('transcript, speaker_segments, medical_entities, transcript_language')
      .eq('id', sessionId)
      .single();

    if (sessionError || !session) {
      console.error('Session fetch error:', sessionError);
      return new Response(
        JSON.stringify({ error: 'Session not found or transcript not available' }),
        { status: 404, headers: { ...corsHeaders_dynamic, ...securityHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const transcript = session.transcript;
    if (!transcript) {
      return new Response(
        JSON.stringify({ error: 'No transcript available for this session' }),
        { status: 400, headers: { ...corsHeaders_dynamic, ...securityHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get patient information for context
    const { data: patient } = await supabase
      .from('users')
      .select('first_name, last_name, date_of_birth')
      .eq('id', patientId)
      .single();

    // Get provider information
    const { data: provider } = await supabase
      .from('users')
      .select('first_name, last_name')
      .eq('id', providerId)
      .single();

    const { data: providerProfile } = await supabase
      .from('medical_provider_profiles')
      .select('specialty, provider_type')
      .eq('user_id', providerId)
      .single();

    // Build the prompt for clinical note generation
    const languageName = getLanguageName(transcriptLanguage || session.transcript_language || 'en-US');

    const prompt = buildClinicalNotePrompt({
      transcript,
      segments: session.speaker_segments,
      existingEntities: session.medical_entities,
      language: languageName,
      noteType,
      includeIcd10,
      includeCpt,
      patientName: patient ? `${patient.first_name} ${patient.last_name}` : 'Patient',
      patientDob: patient?.date_of_birth,
      providerName: provider ? `${provider.first_name} ${provider.last_name}` : 'Provider',
      providerSpecialty: providerProfile?.specialty || 'General Practice',
    });

    // Call AWS Bedrock Claude 3.7 Sonnet
    console.log('Invoking Bedrock model for clinical note generation...');

    const bedrockResponse = await bedrockClient.send(
      new InvokeModelCommand({
        modelId: CLINICAL_MODEL_ID,
        contentType: 'application/json',
        accept: 'application/json',
        body: JSON.stringify({
          anthropic_version: 'bedrock-2023-05-31',
          max_tokens: 8192,
          temperature: 0.2, // Low temperature for clinical accuracy
          messages: [
            {
              role: 'user',
              content: prompt,
            },
          ],
        }),
      })
    );

    const responseBody = JSON.parse(new TextDecoder().decode(bedrockResponse.body));
    const noteContent = responseBody.content?.[0]?.text;

    if (!noteContent) {
      throw new Error('Empty response from Bedrock');
    }

    // Parse the generated clinical note
    const clinicalNote = parseClinicalNote(noteContent);

    const generationTimeMs = Date.now() - startTime;

    // Store the clinical note in the database
    const { data: savedNote, error: insertError } = await supabase
      .from('clinical_notes')
      .insert({
        appointment_id: appointmentId,
        session_id: sessionId,
        provider_id: providerId,
        patient_id: patientId,
        subjective: clinicalNote.subjective,
        objective: clinicalNote.objective,
        assessment: clinicalNote.assessment,
        plan: clinicalNote.plan,
        chief_complaint: clinicalNote.chiefComplaint,
        history_of_present_illness: clinicalNote.historyOfPresentIllness,
        icd10_codes: clinicalNote.icd10Codes,
        cpt_codes: clinicalNote.cptCodes,
        medical_entities: clinicalNote.medicalEntities,
        note_type: noteType,
        status: 'draft',
        ai_generated: true,
        ai_model: CLINICAL_MODEL_ID,
        ai_confidence_score: calculateConfidenceScore(clinicalNote),
        ai_generation_time_ms: generationTimeMs,
        original_transcript_id: sessionId,
        transcript_language: transcriptLanguage || session.transcript_language,
        created_by: providerId,
      })
      .select()
      .single();

    if (insertError) {
      console.error('Database insert error:', insertError);
      throw new Error(`Failed to save clinical note: ${insertError.message}`);
    }

    console.log(`Clinical note generated and saved: ${savedNote.id}`);

    return new Response(
      JSON.stringify({
        success: true,
        noteId: savedNote.id,
        note: {
          subjective: clinicalNote.subjective,
          objective: clinicalNote.objective,
          assessment: clinicalNote.assessment,
          plan: clinicalNote.plan,
          chiefComplaint: clinicalNote.chiefComplaint,
          icd10Codes: clinicalNote.icd10Codes,
          cptCodes: clinicalNote.cptCodes,
          medicalEntities: clinicalNote.medicalEntities,
        },
        metadata: {
          aiModel: CLINICAL_MODEL_ID,
          generationTimeMs,
          status: 'draft',
        },
      }),
      {
        status: 200,
        headers: { ...corsHeaders_dynamic, ...securityHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('Clinical note generation error:', error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : 'Failed to generate clinical note',
      }),
      {
        status: 500,
        headers: { ...corsHeaders_dynamic, ...securityHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});

function getLanguageName(code: string): string {
  const languages: Record<string, string> = {
    'en-US': 'English',
    'en-GB': 'English',
    'fr-FR': 'French',
    'fr-CA': 'French',
    'ff': 'Fulfulde',
    'ff-Latn-NG': 'Fulfulde (Nigeria)',
    'ff-Latn-CM': 'Fulfulde (Cameroon)',
    'pcm': 'Nigerian Pidgin',
    'wes': 'Cameroonian Pidgin',
    'sw': 'Swahili',
    'ha': 'Hausa',
    'yo': 'Yoruba',
    'ln': 'Lingala',
    'sg': 'Sango',
    'ar': 'Arabic',
  };
  return languages[code] || 'English';
}

interface PromptParams {
  transcript: string;
  segments: string | null;
  existingEntities: string | null;
  language: string;
  noteType: string;
  includeIcd10: boolean;
  includeCpt: boolean;
  patientName: string;
  patientDob?: string;
  providerName: string;
  providerSpecialty: string;
}

function buildClinicalNotePrompt(params: PromptParams): string {
  const {
    transcript,
    segments,
    existingEntities,
    language,
    noteType,
    includeIcd10,
    includeCpt,
    patientName,
    patientDob,
    providerName,
    providerSpecialty,
  } = params;

  const segmentsText = segments ? `\n\nSPEAKER-LABELED SEGMENTS:\n${segments}` : '';
  const entitiesText = existingEntities
    ? `\n\nPREVIOUSLY EXTRACTED MEDICAL ENTITIES:\n${existingEntities}`
    : '';

  const icd10Instructions = includeIcd10
    ? `
6. ICD-10 CODES: Suggest appropriate ICD-10 diagnosis codes with confidence scores (0.0-1.0)`
    : '';

  const cptInstructions = includeCpt
    ? `
7. CPT CODES: Suggest appropriate CPT procedure codes for billing with confidence scores`
    : '';

  return `You are an expert medical documentation specialist. Generate a comprehensive ${noteType.toUpperCase()} clinical note from the following medical consultation transcript.

CONSULTATION DETAILS:
- Patient: ${patientName}${patientDob ? ` (DOB: ${patientDob})` : ''}
- Provider: ${providerName}
- Specialty: ${providerSpecialty}
- Language: ${language}

TRANSCRIPT:
${transcript}
${segmentsText}
${entitiesText}

Generate a structured clinical note in JSON format with the following sections:

1. CHIEF COMPLAINT: The primary reason for the visit in the patient's words (1-2 sentences)

2. HISTORY OF PRESENT ILLNESS: Detailed narrative of the current illness/condition

3. SUBJECTIVE: Patient-reported symptoms, concerns, and history
   - Include onset, duration, severity, associated symptoms
   - Previous treatments and their effectiveness
   - Impact on daily activities

4. OBJECTIVE: Provider's clinical observations and findings
   - Vital signs if mentioned
   - Physical examination findings
   - Review of any test results discussed

5. ASSESSMENT: Clinical impression and diagnosis
   - Primary diagnosis with reasoning
   - Differential diagnoses if applicable
   - Disease severity/staging if relevant
${icd10Instructions}
${cptInstructions}

8. PLAN: Treatment recommendations
   - Medications with dosages and frequencies
   - Lifestyle modifications
   - Follow-up instructions
   - Referrals if needed
   - Patient education provided

9. MEDICAL ENTITIES: Extract all medical entities mentioned
   - Symptoms, diagnoses, medications, procedures, allergies
   - Include ICD-10 codes where applicable
   - Include confidence scores

IMPORTANT GUIDELINES:
- Be thorough but concise
- Use professional medical terminology
- Ensure accuracy - do not invent information not in the transcript
- If information is unclear or missing, note "Not documented" rather than guessing
- For non-English transcripts, provide the note in English with original terms preserved in parentheses
- Format as valid JSON only, no markdown or explanatory text

Return ONLY the JSON object with this structure:
{
  "chiefComplaint": "string",
  "historyOfPresentIllness": "string",
  "subjective": "string",
  "objective": "string",
  "assessment": "string",
  "plan": "string",
  "icd10Codes": [{"code": "string", "description": "string", "confidence": 0.0-1.0}],
  "cptCodes": [{"code": "string", "description": "string", "confidence": 0.0-1.0}],
  "medicalEntities": [{"text": "string", "type": "SYMPTOM|DIAGNOSIS|MEDICATION|PROCEDURE|ALLERGY|VITAL_SIGN", "icd10": "optional", "confidence": 0.0-1.0}]
}`;
}

function parseClinicalNote(content: string): ClinicalNote {
  try {
    // Try to extract JSON from the response
    let jsonContent = content.trim();

    // If wrapped in markdown code blocks, extract
    const jsonMatch = content.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (jsonMatch) {
      jsonContent = jsonMatch[1].trim();
    }

    const parsed = JSON.parse(jsonContent);

    return {
      subjective: parsed.subjective || '',
      objective: parsed.objective || '',
      assessment: parsed.assessment || '',
      plan: parsed.plan || '',
      chiefComplaint: parsed.chiefComplaint || '',
      historyOfPresentIllness: parsed.historyOfPresentIllness || '',
      icd10Codes: Array.isArray(parsed.icd10Codes) ? parsed.icd10Codes : [],
      cptCodes: Array.isArray(parsed.cptCodes) ? parsed.cptCodes : [],
      medicalEntities: Array.isArray(parsed.medicalEntities) ? parsed.medicalEntities : [],
    };
  } catch (error) {
    console.error('Failed to parse clinical note JSON:', error);

    // Attempt to extract sections manually if JSON parsing fails
    return {
      subjective: extractSection(content, 'SUBJECTIVE', 'OBJECTIVE') || content,
      objective: extractSection(content, 'OBJECTIVE', 'ASSESSMENT') || '',
      assessment: extractSection(content, 'ASSESSMENT', 'PLAN') || '',
      plan: extractSection(content, 'PLAN', null) || '',
      chiefComplaint: extractSection(content, 'CHIEF COMPLAINT', 'HISTORY') || '',
      historyOfPresentIllness: extractSection(content, 'HISTORY OF PRESENT ILLNESS', 'SUBJECTIVE') || '',
      icd10Codes: [],
      cptCodes: [],
      medicalEntities: [],
    };
  }
}

function extractSection(content: string, startMarker: string, endMarker: string | null): string {
  const startRegex = new RegExp(`${startMarker}[:\\s]*`, 'i');
  const startMatch = content.match(startRegex);
  if (!startMatch) return '';

  const startIndex = startMatch.index! + startMatch[0].length;

  if (endMarker) {
    const endRegex = new RegExp(`${endMarker}[:\\s]*`, 'i');
    const endMatch = content.slice(startIndex).match(endRegex);
    if (endMatch) {
      return content.slice(startIndex, startIndex + endMatch.index!).trim();
    }
  }

  return content.slice(startIndex).trim();
}

function calculateConfidenceScore(note: ClinicalNote): number {
  let score = 0;
  let factors = 0;

  // Check completeness of SOAP sections
  if (note.subjective && note.subjective.length > 50) { score += 1; factors++; }
  if (note.objective && note.objective.length > 30) { score += 1; factors++; }
  if (note.assessment && note.assessment.length > 30) { score += 1; factors++; }
  if (note.plan && note.plan.length > 30) { score += 1; factors++; }

  // Check for ICD-10 codes
  if (note.icd10Codes.length > 0) { score += 0.5; factors += 0.5; }

  // Check for medical entities
  if (note.medicalEntities.length > 2) { score += 0.5; factors += 0.5; }

  // Calculate average
  return factors > 0 ? Math.min(1.0, score / factors) : 0.5;
}
