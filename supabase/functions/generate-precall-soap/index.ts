import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.4';
import { verifyFirebaseJWT } from '../_shared/verify-firebase-jwt.ts';

interface PreCallSOAPRequest {
  appointmentId: string;
  patientId: string;
  providerId: string;
  chiefComplaint?: string;
}

interface PreCallSOAPResponse {
  success: boolean;
  error?: string;
  code?: string;
  status: number;
  noteId?: string;
  preCallContext?: any;
  providerPreparationNotes?: string[];
  soapNote?: any;
}

const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';
const bedrockLambdaUrl = Deno.env.get('BEDROCK_LAMBDA_URL') || '';

const supabaseAdminClient = createClient(supabaseUrl, supabaseServiceKey);

function extractJSON(text: string): any {
  const match = text.match(/\{[\s\S]*\}/);
  if (match) {
    return JSON.parse(match[0]);
  }
  throw new Error('No JSON found in response');
}

async function getPatientHistory(
  appointmentId: string,
  patientId: string
): Promise<any> {
  try {
    const response = await fetch(
      `${supabaseUrl}/functions/v1/get-patient-history`,
      {
        method: 'POST',
        headers: {
          'apikey': supabaseServiceKey,
          'Authorization': `Bearer ${supabaseServiceKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          patientId,
          appointmentId,
        }),
      }
    );

    if (!response.ok) {
      throw new Error(
        `Patient history fetch failed: ${response.status} ${response.statusText}`
      );
    }

    return await response.json();
  } catch (error) {
    console.error('Error fetching patient history:', error);
    // Return empty object if history fetch fails - not critical
    return {
      patientData: {},
      pastNotes: [],
    };
  }
}

async function getPreviousSOAPNotes(
  patientId: string
): Promise<any[]> {
  try {
    const { data } = await supabaseAdminClient
      .from('soap_notes')
      .select(
        `
        id,
        chief_complaint,
        created_at,
        encounter_type,
        status,
        soap_assessment_items(id, diagnosis_description, icd10_code, status)
      `
      )
      .eq('patient_id', patientId)
      .eq('status', 'signed')
      .order('created_at', { ascending: false })
      .limit(3);

    return data || [];
  } catch (error) {
    console.error('Error fetching previous SOAP notes:', error);
    return [];
  }
}

async function generatePreCallSOAPWithBedrock(
  patientHistory: any,
  previousSOAPs: any[],
  chiefComplaint: string | undefined
): Promise<any> {
  const patientData = patientHistory.patientData || {};

  const prompt = `You are preparing a provider for a telemedicine consultation. Generate a comprehensive pre-call SOAP note to help the provider prepare.

PATIENT CONTEXT:
- Name: ${patientData.fullName || 'Patient'}
- Age: ${patientData.age || 'Unknown'}
- Gender: ${patientData.gender || 'Unknown'}
- Chief Complaint: ${chiefComplaint || 'Not stated'}

MEDICAL HISTORY:
- Chronic Conditions: ${
    (patientData.medicalConditions && patientData.medicalConditions.length > 0)
      ? patientData.medicalConditions.join(', ')
      : 'None'
  }
- Current Medications: ${
    (patientData.currentMedications && patientData.currentMedications.length > 0)
      ? patientData.currentMedications.join(', ')
      : 'None'
  }
- Allergies: ${
    (patientData.allergies && patientData.allergies.length > 0)
      ? patientData.allergies.join(', ')
      : 'NKDA'
  }
- Surgical History: ${
    (patientData.surgicalHistory && patientData.surgicalHistory.length > 0)
      ? patientData.surgicalHistory.join(', ')
      : 'None'
  }
- Family History: ${
    (patientData.familyHistory && patientData.familyHistory.length > 0)
      ? patientData.familyHistory.join(', ')
      : 'Unknown'
  }

RECENT VITALS (Last Visit):
${
  patientData.recentVitals
    ? `- Date: ${patientData.recentVitals.lastVisitDate}
- Temperature: ${patientData.recentVitals.temperature}°C
- Blood Pressure: ${patientData.recentVitals.bloodPressure}
- Heart Rate: ${patientData.recentVitals.heartRate} bpm
- SpO2: ${patientData.recentVitals.spo2}%`
    : 'No recent vitals on file'
}

PREVIOUS VISITS:
${
  previousSOAPs && previousSOAPs.length > 0
    ? previousSOAPs
        .map(
          (note) =>
            `- ${note.created_at}: ${note.chief_complaint}${
              note.soap_assessment_items && note.soap_assessment_items.length > 0
                ? ` → Main Issue: ${note.soap_assessment_items[0].diagnosis_description}`
                : ''
            }`
        )
        .join('\n')
    : 'No previous visits'
}

TASK:
Generate a pre-call SOAP note to help the provider prepare. Return valid JSON with this structure:

{
  "pre_call_context": {
    "chief_complaint": "string - patient's main reason for visit",
    "anticipated_hpi_topics": ["topic1", "topic2", "topic3"] - questions provider should ask,
    "red_flags_to_assess": ["flag1", "flag2"] - critical items to check,
    "medication_reconciliation_needed": boolean
  },
  "hpi": {
    "narrative": "string - patient has history of... Last visit was...",
    "relevant_past_episodes": ["episode1", "episode2"]
  },
  "medications": [
    {"name": "Metformin", "dose": "500mg", "frequency": "BID", "indication": "Type 2 Diabetes", "status": "current", "source": "patient_profile"}
  ],
  "allergies": [
    {"allergen": "Penicillin", "type": "drug", "reaction": "rash", "severity": "moderate", "status": "active"}
  ],
  "history_items": [
    {"type": "past_medical", "condition": "Hypertension", "onset_date": "2020-01-15", "status": "active"},
    {"type": "past_surgical", "surgery_name": "Appendectomy", "surgery_date": "2015-06-20"}
  ],
  "last_vitals": {
    "date": "2026-01-10",
    "temperature": 36.8,
    "bp_systolic": 140,
    "bp_diastolic": 90,
    "heart_rate": 82,
    "spo2": 98,
    "source": "previous_visit"
  },
  "assessment_preliminary": [
    {"problem": "Hypertension - follow-up", "status": "established", "monitoring_needed": "BP check, medication review"}
  ],
  "provider_preparation_notes": [
    "Review recent test results if available",
    "Assess medication adherence",
    "Check for complications"
  ]
}`;

  // Call Lambda function instead of direct AWS SDK
  const lambdaResponse = await fetch(bedrockLambdaUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: prompt,
      modelId: 'eu.anthropic.claude-opus-4-5-20251101-v1:0',
      temperature: 0.2,
      max_tokens: 2048,
    }),
  });

  if (!lambdaResponse.ok) {
    throw new Error(
      `Lambda function failed: ${lambdaResponse.status} ${lambdaResponse.statusText}`
    );
  }

  const lambdaData = await lambdaResponse.json();

  // Extract the response text from Lambda
  const content = lambdaData.content || lambdaData.text || '';

  return extractJSON(content);
}

serve(async (req) => {
  // CORS headers
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, x-firebase-token, apikey',
      },
    });
  }

  try {
    // Verify Firebase JWT
    const token = req.headers.get('x-firebase-token');
    if (!token) {
      return new Response(
        JSON.stringify({
          error: 'Missing Firebase token',
          code: 'INVALID_FIREBASE_TOKEN',
          status: 401,
        }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    const auth = await verifyFirebaseJWT(token);
    if (!auth.valid) {
      return new Response(
        JSON.stringify({
          error: 'Invalid Firebase token',
          code: 'INVALID_FIREBASE_TOKEN',
          status: 401,
        }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Parse request body
    const body = await req.json();
    const { appointmentId, patientId, providerId, chiefComplaint } =
      body as PreCallSOAPRequest;

    if (!appointmentId || !patientId || !providerId) {
      return new Response(
        JSON.stringify({
          error: 'Missing required parameters',
          code: 'INVALID_REQUEST',
          status: 400,
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Fetch patient history
    const patientHistory = await getPatientHistory(appointmentId, patientId);

    // Fetch previous SOAP notes
    const previousSOAPs = await getPreviousSOAPNotes(patientId);

    // Generate pre-call SOAP with Bedrock
    const soapData = await generatePreCallSOAPWithBedrock(
      patientHistory,
      previousSOAPs,
      chiefComplaint
    );

    // Create master SOAP note record
    const { data: soapNoteData, error: noteError } = await supabaseAdminClient
      .from('soap_notes')
      .insert({
        appointment_id: appointmentId,
        provider_id: providerId,
        patient_id: patientId,
        status: 'precall_draft',
        is_real_time_draft: false,
        chief_complaint:
          soapData.pre_call_context?.chief_complaint || chiefComplaint || '',
        ai_generated_at: new Date().toISOString(),
        ai_model_used: 'eu.anthropic.claude-opus-4-5-20251101-v1:0',
        ai_confidence_score: 0.85,
      })
      .select('id')
      .single();

    if (noteError || !soapNoteData) {
      throw new Error(`Failed to create SOAP note: ${noteError?.message}`);
    }

    const noteId = soapNoteData.id;

    // Insert HPI
    if (soapData.hpi) {
      await supabaseAdminClient.from('soap_hpi_details').insert({
        soap_note_id: noteId,
        hpi_narrative: soapData.hpi.narrative || '',
      });
    }

    // Insert medications
    if (soapData.medications && soapData.medications.length > 0) {
      const medicationRecords = soapData.medications.map((med: any) => ({
        soap_note_id: noteId,
        source: med.source || 'current_medication',
        medication_name: med.name,
        dose: med.dose,
        frequency: med.frequency,
        indication: med.indication,
        status: med.status || 'active',
      }));

      await supabaseAdminClient
        .from('soap_medications')
        .insert(medicationRecords);
    }

    // Insert allergies
    if (soapData.allergies && soapData.allergies.length > 0) {
      const allergyRecords = soapData.allergies.map((allergy: any) => ({
        soap_note_id: noteId,
        allergen: allergy.allergen,
        allergen_type: allergy.type,
        reaction: allergy.reaction,
        severity: allergy.severity,
        status: allergy.status || 'active',
      }));

      await supabaseAdminClient
        .from('soap_allergies')
        .insert(allergyRecords);
    }

    // Insert history items
    if (soapData.history_items && soapData.history_items.length > 0) {
      const historyRecords = soapData.history_items.map((item: any) => ({
        soap_note_id: noteId,
        history_type: item.type,
        condition_name: item.condition || item.surgery_name,
        onset_date: item.onset_date || item.surgery_date,
        status: item.status || 'completed',
      }));

      await supabaseAdminClient
        .from('soap_history_items')
        .insert(historyRecords);
    }

    // Insert last vitals (marked as from previous visit)
    if (soapData.last_vitals) {
      const v = soapData.last_vitals;
      await supabaseAdminClient.from('soap_vital_signs').insert({
        soap_note_id: noteId,
        source: 'previous_visit',
        measurement_time: v.date || new Date().toISOString(),
        temperature_value: v.temperature,
        temperature_unit: 'celsius',
        blood_pressure_systolic: v.bp_systolic,
        blood_pressure_diastolic: v.bp_diastolic,
        heart_rate: v.heart_rate,
        oxygen_saturation: v.spo2,
      });
    }

    // Insert preliminary assessment
    if (
      soapData.assessment_preliminary &&
      soapData.assessment_preliminary.length > 0
    ) {
      const assessmentRecords = soapData.assessment_preliminary.map(
        (item: any, idx: number) => ({
          soap_note_id: noteId,
          problem_number: idx + 1,
          diagnosis_description: item.problem,
          status: item.status || 'established',
          clinical_impression_summary: item.monitoring_needed,
        })
      );

      await supabaseAdminClient
        .from('soap_assessment_items')
        .insert(assessmentRecords);
    }

    // Fetch complete SOAP note using helper view
    const { data: fullNote, error: fetchError } = await supabaseAdminClient
      .from('soap_notes_full')
      .select('*')
      .eq('id', noteId)
      .single();

    if (fetchError) {
      throw new Error(`Failed to fetch complete SOAP note: ${fetchError.message}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        status: 200,
        noteId,
        preCallContext: soapData.pre_call_context,
        providerPreparationNotes: soapData.provider_preparation_notes || [],
        soapNote: fullNote,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error in generate-precall-soap:', error);

    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : 'Internal server error',
        code: 'INTERNAL_ERROR',
        status: 500,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});
