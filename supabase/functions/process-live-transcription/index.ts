/**
 * MedZen Process Live Transcription
 *
 * Real-time transcription processing during video calls.
 * - Processes transcription segments incrementally
 * - Extracts clinical data using Claude AI
 * - Updates SOAP note draft in real-time
 * - Handles empty/null transcriptions gracefully
 *
 * Called every 10-15 seconds with new transcription segments
 * Updates existing draft if exists, creates new if not
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { BedrockRuntimeClient, InvokeModelCommand } from 'npm:@aws-sdk/client-bedrock-runtime@3.716.0';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";
import { checkRateLimit, getRateLimitConfig, createRateLimitErrorResponse } from "../_shared/rate-limiter.ts";
import { verifyFirebaseJWT } from "../_shared/verify-firebase-jwt.ts";

// AWS Configuration
const AWS_REGION = Deno.env.get('AWS_REGION') || 'eu-central-1';
const AWS_ACCESS_KEY_ID = Deno.env.get('AWS_ACCESS_KEY_ID') || '';
const AWS_SECRET_ACCESS_KEY = Deno.env.get('AWS_SECRET_ACCESS_KEY') || '';

// Supabase Configuration
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

const BEDROCK_MODEL_ID = 'eu.anthropic.claude-opus-4-5-20251101-v1:0';
const TEMPERATURE = 0.1;

interface LiveTranscriptionRequest {
  sessionId: string;
  appointmentId: string;
  patientId: string;
  providerId: string;
  transcriptionSegment: string;
  cumulativeTranscript: string;  // Full transcript so far
  isCallActive: boolean;
}

interface ExtractedClinicalData {
  chiefComplaint?: string;
  historyOfPresentIllness?: string;
  symptoms?: string[];
  vitalsExtracted?: {
    temperature?: number;
    systolicBp?: number;
    diastolicBp?: number;
    heartRate?: number;
    respiratoryRate?: number;
    oxygenSaturation?: number;
    weight?: number;
    height?: number;
  };
  physicalExamFindings?: string;
  assessmentDiagnoses?: string[];
  planTreatments?: string[];
  medications?: Array<{ name: string; dosage?: string; frequency?: string }>;
  orders?: string[];
  uncertainty?: string[];
}

function buildExtractionPrompt(cumulativeTranscript: string): string {
  return `You are a clinical documentation AI assistant. Extract structured clinical data from this medical conversation transcript.

INSTRUCTIONS:
1. Extract ONLY information explicitly mentioned in the transcript
2. If information is not clearly stated, do NOT invent it
3. Return ONLY a valid JSON object, no markdown or extra text
4. For vitals, extract numbers with units
5. For diagnoses, list as strings
6. Mark any unclear or uncertain information in the "uncertainty" array

TRANSCRIPT:
${cumulativeTranscript}

Extract and return this JSON structure:
{
  "chiefComplaint": "patient's main complaint or reason for visit (string or null)",
  "historyOfPresentIllness": "detailed timeline of symptoms (string or null)",
  "symptoms": ["array of symptoms mentioned"],
  "vitalsExtracted": {
    "temperature": "number or null",
    "systolicBp": "number or null",
    "diastolicBp": "number or null",
    "heartRate": "number or null",
    "respiratoryRate": "number or null",
    "oxygenSaturation": "number or null",
    "weight": "number or null",
    "height": "number or null"
  },
  "physicalExamFindings": "findings from physical exam (string or null)",
  "assessmentDiagnoses": ["array of diagnoses being considered"],
  "planTreatments": ["array of treatments discussed"],
  "medications": [{"name": "med name", "dosage": "dosage", "frequency": "frequency"}],
  "orders": ["array of orders/tests discussed"],
  "uncertainty": ["array of items that need clarification"]
}`;
}

async function extractClinicalData(transcript: string): Promise<ExtractedClinicalData | null> {
  if (!transcript || transcript.trim().length === 0) {
    return null;
  }

  try {
    const bedrockClient = new BedrockRuntimeClient({
      region: AWS_REGION,
      credentials: {
        accessKeyId: AWS_ACCESS_KEY_ID,
        secretAccessKey: AWS_SECRET_ACCESS_KEY,
      },
    });

    const prompt = buildExtractionPrompt(transcript);

    const command = new InvokeModelCommand({
      modelId: BEDROCK_MODEL_ID,
      contentType: 'application/json',
      accept: 'application/json',
      body: JSON.stringify({
        anthropic_version: 'bedrock-2023-06-01',
        max_tokens: 2000,
        temperature: TEMPERATURE,
        messages: [
          {
            role: 'user',
            content: prompt,
          },
        ],
      }),
    });

    const response = await bedrockClient.send(command);
    const responseText = new TextDecoder().decode(response.body);
    const parsedResponse = JSON.parse(responseText);

    if (parsedResponse.content && Array.isArray(parsedResponse.content)) {
      const textContent = parsedResponse.content.find(
        (c: any) => c.type === 'text'
      );
      if (textContent && textContent.text) {
        // Extract JSON from response (might have markdown wrapping)
        const jsonMatch = textContent.text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          return JSON.parse(jsonMatch[0]);
        }
      }
    }

    return null;
  } catch (error) {
    console.error('Error extracting clinical data:', error);
    return null;
  }
}

async function updateSOAPDraft(
  supabase: any,
  appointmentId: string,
  patientId: string,
  extractedData: ExtractedClinicalData,
  patientData: any
) {
  try {
    // Check if draft exists for this appointment
    const { data: existingDraft } = await supabase
      .from('clinical_notes')
      .select('id')
      .eq('appointment_id', appointmentId)
      .eq('is_draft', true)
      .maybeSingle();

    const noteData = {
      appointment_id: appointmentId,
      patient_id: patientId,
      is_draft: true,
      created_by_ai: true,
      has_doctor_edits: false,

      // Section 1: Chief Complaint
      section_1_chief_complaint:
        extractedData.chiefComplaint || patientData?.chiefComplaint,

      // Section 2: Subjective
      section_2_hpi: extractedData.historyOfPresentIllness,
      section_2_symptoms: extractedData.symptoms?.join(', '),
      section_2_medical_conditions: patientData?.medicalConditions?.join(', '),
      section_2_current_medications:
        patientData?.currentMedications
          ?.map((m: any) => `${m.name} ${m.dosage || ''}`)
          .join(', '),
      section_2_allergies: patientData?.allergies?.join(', '),

      // Section 3: Objective
      section_3_vitals_temperature: extractedData.vitalsExtracted?.temperature,
      section_3_vitals_systolic_bp: extractedData.vitalsExtracted?.systolicBp,
      section_3_vitals_diastolic_bp: extractedData.vitalsExtracted?.diastolicBp,
      section_3_vitals_heart_rate: extractedData.vitalsExtracted?.heartRate,
      section_3_vitals_respiratory_rate:
        extractedData.vitalsExtracted?.respiratoryRate,
      section_3_vitals_oxygen_saturation:
        extractedData.vitalsExtracted?.oxygenSaturation,
      section_3_vitals_weight: extractedData.vitalsExtracted?.weight,
      section_3_vitals_height: extractedData.vitalsExtracted?.height,
      section_3_physical_exam: extractedData.physicalExamFindings,

      // Section 4: Assessment
      section_4_assessment_diagnoses: extractedData.assessmentDiagnoses?.join(
        '\n'
      ),

      // Section 5: Plan
      section_5_plan_medications: extractedData.medications
        ?.map((m) => `${m.name} ${m.dosage || ''} ${m.frequency || ''}`)
        .join('\n'),
      section_5_plan_treatments: extractedData.planTreatments?.join('\n'),
      section_5_plan_orders: extractedData.orders?.join('\n'),

      // Section 7: QA/Safety
      section_7_safety_notes:
        extractedData.uncertainty && extractedData.uncertainty.length > 0
          ? `Clarification needed: ${extractedData.uncertainty.join('; ')}`
          : null,

      last_modified: new Date().toISOString(),
    };

    if (existingDraft) {
      // Update existing draft
      const { error: updateError } = await supabase
        .from('clinical_notes')
        .update(noteData)
        .eq('id', existingDraft.id);

      if (updateError) {
        console.error('Error updating draft:', updateError);
        throw updateError;
      }

      console.log(`✅ Updated draft for appointment ${appointmentId}`);
    } else {
      // Create new draft
      const { error: insertError } = await supabase
        .from('clinical_notes')
        .insert([noteData]);

      if (insertError) {
        console.error('Error creating draft:', insertError);
        throw insertError;
      }

      console.log(`✅ Created draft for appointment ${appointmentId}`);
    }

    return true;
  } catch (error) {
    console.error('Error updating SOAP draft:', error);
    throw error;
  }
}

serve(async (req: Request) => {
  const origin = req.headers.get("origin");
  const corsHeaders_resp = getCorsHeaders(origin);

  // CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { ...corsHeaders_resp, ...securityHeaders } });
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405, headers: { ...corsHeaders_resp, ...securityHeaders } });
  }

  try {
    // Firebase auth
    const token = req.headers.get("x-firebase-token");
    if (token) {
      const auth = await verifyFirebaseJWT(token);
      if (!auth.valid) {
        return new Response(
          JSON.stringify({ error: "Invalid Firebase token", code: "INVALID_FIREBASE_TOKEN", status: 401 }),
          { status: 401, headers: { ...corsHeaders_resp, ...securityHeaders, "Content-Type": "application/json" } }
        );
      }

      // Rate limiting for authenticated endpoints
      const rateLimitConfig = getRateLimitConfig('process-live-transcription', auth.user_id || auth.sub || '');
      const rateLimit = await checkRateLimit(rateLimitConfig);
      if (!rateLimit.allowed) {
        return createRateLimitErrorResponse(rateLimit);
      }
    }

    const request = (await req.json()) as LiveTranscriptionRequest;

    const {
      sessionId,
      appointmentId,
      patientId,
      providerId,
      cumulativeTranscript,
      isCallActive,
    } = request;

    // Validate inputs
    if (!appointmentId || !patientId) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'appointmentId and patientId are required',
        }),
        { status: 400, headers: { ...corsHeaders_resp, ...securityHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // If transcript is empty, still update with patient metadata
    if (!cumulativeTranscript || cumulativeTranscript.trim().length === 0) {
      console.log(
        'No transcription yet, will update with patient metadata only'
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // Get patient data
    const { data: patientData } = await supabase
      .from('patient_profiles')
      .select(
        `id,
         date_of_birth,
         gender,
         blood_type,
         allergies,
         medical_conditions,
         current_medications`
      )
      .eq('patient_id', patientId)
      .maybeSingle();

    // Get appointment details
    const { data: appointmentData } = await supabase
      .from('appointments')
      .select('chief_complaint, appointment_date')
      .eq('id', appointmentId)
      .maybeSingle();

    // Extract clinical data if transcript exists
    let extractedData: ExtractedClinicalData = {};
    if (cumulativeTranscript && cumulativeTranscript.trim().length > 0) {
      const extracted = await extractClinicalData(cumulativeTranscript);
      if (extracted) {
        extractedData = extracted;
      }
    }

    // Combine with appointment chief complaint if not extracted
    if (!extractedData.chiefComplaint && appointmentData?.chief_complaint) {
      extractedData.chiefComplaint = appointmentData.chief_complaint;
    }

    // Update or create SOAP draft
    await updateSOAPDraft(
      supabase,
      appointmentId,
      patientId,
      extractedData,
      patientData
    );

    return new Response(
      JSON.stringify({
        success: true,
        message: 'SOAP draft updated successfully',
        extractedDataSummary: {
          chiefComplaint: extractedData.chiefComplaint || 'Not yet extracted',
          symptomsCount: extractedData.symptoms?.length || 0,
          diagnosesCount: extractedData.assessmentDiagnoses?.length || 0,
          vitalsExtracted:
            Object.values(extractedData.vitalsExtracted || {}).filter((v) => v)
              .length || 0,
        },
      }),
      { status: 200, headers: { ...corsHeaders_resp, ...securityHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error in process-live-transcription:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      }),
      {
        status: 500,
        headers: { ...corsHeaders_resp, ...securityHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
