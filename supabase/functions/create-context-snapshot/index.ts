import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { verifyFirebaseToken } from '../_shared/verify-firebase-jwt.ts';

interface ContextSnapshot {
  patient_demographics: any;
  active_conditions: any;
  current_medications: any;
  allergies: any;
  recent_labs_vitals: any;
  recent_notes_summary: string;
}

interface ErrorResponse {
  error: string;
  code: string;
  status: number;
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-firebase-token',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

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

    const firebaseProjectId = Deno.env.get('FIREBASE_PROJECT_ID') || 'medzen-bf20e';

    // Log token details for debugging
    const tokenParts = token.split('.');
    console.log(`[create-context-snapshot] Token verification attempt`);
    console.log(`[create-context-snapshot] Project ID: ${firebaseProjectId}`);
    console.log(`[create-context-snapshot] Token format: ${tokenParts.length} parts`);
    console.log(`[create-context-snapshot] Token header: ${tokenParts[0]}`);

    let auth;
    try {
      auth = await verifyFirebaseToken(token, firebaseProjectId);
      console.log(`[create-context-snapshot] ✓ Token verification succeeded`);
      console.log(`[create-context-snapshot] User ID: ${auth.sub || auth.uid}`);
    } catch (error) {
      const errorMsg = (error as Error).message;
      const errorStack = (error as Error).stack;
      console.error(`[create-context-snapshot] ✗ Token verification failed`);
      console.error(`[create-context-snapshot] Error message: ${errorMsg}`);
      console.error(`[create-context-snapshot] Error stack: ${errorStack}`);

      return new Response(
        JSON.stringify({
          error: 'Invalid Firebase token',
          code: 'INVALID_FIREBASE_TOKEN',
          status: 401,
          details: errorMsg
        }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const userId = auth.sub || auth.uid;
    const { encounter_id, patient_id } = await req.json();

    if (!encounter_id || !patient_id) {
      return new Response(
        JSON.stringify({ error: 'Missing encounter_id or patient_id', code: 'MISSING_PARAMS', status: 400 }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Initialize Supabase admin client
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

    console.log(`[create-context-snapshot] Creating context snapshot for encounter: ${encounter_id}`);

    // 1. Fetch patient demographics
    console.log(`[create-context-snapshot] Fetching patient demographics for patient: ${patient_id}`);
    const { data: patientData, error: patientError } = await supabaseAdmin
      .from('users')
      .select('id, full_name, dob, sex_at_birth, phone, email, created_at')
      .eq('id', patient_id)
      .single();

    if (patientError || !patientData) {
      console.error(`[create-context-snapshot] Failed to fetch patient data:`, patientError);
      return new Response(
        JSON.stringify({
          error: 'Failed to fetch patient demographics',
          code: 'PATIENT_NOT_FOUND',
          status: 404,
        }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 2. Fetch active conditions from recent clinical notes
    console.log(`[create-context-snapshot] Fetching active conditions`);
    const { data: conditionsData, error: conditionsError } = await supabaseAdmin
      .from('clinical_notes')
      .select('soap_json')
      .eq('patient_id', patient_id)
      .order('created_at', { ascending: false })
      .limit(5);

    const activeConditions = extractConditions(conditionsData || []);

    // 3. Fetch current medications and allergies
    console.log(`[create-context-snapshot] Fetching medications and allergies`);
    const { data: medData, error: medError } = await supabaseAdmin
      .from('clinical_notes')
      .select('soap_json')
      .eq('patient_id', patient_id)
      .order('created_at', { ascending: false })
      .limit(3);

    const medications = extractMedications(medData || []);
    const allergies = extractAllergies(medData || []);

    // 4. Fetch recent labs and vitals
    console.log(`[create-context-snapshot] Fetching recent vitals`);
    const recentVitals = await fetchRecentVitals(supabaseAdmin, patient_id);

    // 5. Summarize recent notes
    console.log(`[create-context-snapshot] Summarizing recent notes`);
    const recentNotesSummary = await summarizeRecentNotes(supabaseAdmin, patient_id);

    // 6. Build snapshot object
    const snapshot: ContextSnapshot = {
      patient_demographics: patientData,
      active_conditions: activeConditions,
      current_medications: medications,
      allergies: allergies,
      recent_labs_vitals: recentVitals,
      recent_notes_summary: recentNotesSummary,
    };

    // 7. Store snapshot in database
    console.log(`[create-context-snapshot] Storing context snapshot`);
    const { data: snapshotData, error: snapshotError } = await supabaseAdmin
      .from('context_snapshots')
      .insert({
        encounter_id,
        snapshot_version: 1,
        ...snapshot,
      })
      .select()
      .single();

    if (snapshotError || !snapshotData) {
      console.error(`[create-context-snapshot] Failed to create snapshot:`, snapshotError);
      return new Response(
        JSON.stringify({
          error: 'Failed to create context snapshot',
          code: 'SNAPSHOT_CREATION_FAILED',
          status: 500,
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 8. Update encounter status in video_call_sessions
    console.log(`[create-context-snapshot] Updating encounter status`);
    const { error: updateError } = await supabaseAdmin
      .from('video_call_sessions')
      .update({
        context_snapshot_id: snapshotData.id,
        encounter_status: 'precheck_open',
      })
      .eq('id', encounter_id);

    if (updateError) {
      console.error(`[create-context-snapshot] Failed to update encounter status:`, updateError);
      return new Response(
        JSON.stringify({
          error: 'Failed to update encounter status',
          code: 'UPDATE_FAILED',
          status: 500,
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`[create-context-snapshot] ✅ Context snapshot created successfully: ${snapshotData.id}`);

    return new Response(
      JSON.stringify({
        ok: true,
        snapshot: snapshotData,
        status: 200,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('[create-context-snapshot] Unexpected error:', error);
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

function extractConditions(notesData: any[]) {
  const conditions = [];
  for (const note of notesData) {
    try {
      if (note.soap_json) {
        const soapJson = typeof note.soap_json === 'string' ? JSON.parse(note.soap_json) : note.soap_json;
        if (soapJson.assessment?.problem_list) {
          conditions.push(...soapJson.assessment.problem_list);
        }
      }
    } catch (e) {
      console.warn('[extractConditions] Failed to parse note:', e);
    }
  }
  return conditions.slice(0, 10); // Return top 10 conditions
}

function extractMedications(notesData: any[]) {
  const meds = [];
  for (const note of notesData) {
    try {
      if (note.soap_json) {
        const soapJson = typeof note.soap_json === 'string' ? JSON.parse(note.soap_json) : note.soap_json;
        if (soapJson.subjective?.medications) {
          meds.push(...soapJson.subjective.medications);
        }
      }
    } catch (e) {
      console.warn('[extractMedications] Failed to parse note:', e);
    }
  }
  // Remove duplicates by medication name
  return Array.from(new Map(meds.map((m: any) => [m.name, m])).values()).slice(0, 15);
}

function extractAllergies(notesData: any[]) {
  const allergies = [];
  for (const note of notesData) {
    try {
      if (note.soap_json) {
        const soapJson = typeof note.soap_json === 'string' ? JSON.parse(note.soap_json) : note.soap_json;
        if (soapJson.subjective?.allergies) {
          allergies.push(...soapJson.subjective.allergies);
        }
      }
    } catch (e) {
      console.warn('[extractAllergies] Failed to parse note:', e);
    }
  }
  // Remove duplicates
  return Array.from(new Set(allergies.map((a: any) => a.allergen))).slice(0, 10);
}

async function fetchRecentVitals(supabaseAdmin: any, patientId: string) {
  try {
    const { data, error } = await supabaseAdmin
      .from('clinical_notes')
      .select('soap_json')
      .eq('patient_id', patientId)
      .order('created_at', { ascending: false })
      .limit(1);

    if (error || !data || data.length === 0) return null;

    const note = data[0];
    if (note.soap_json) {
      const soapJson = typeof note.soap_json === 'string' ? JSON.parse(note.soap_json) : note.soap_json;
      return soapJson.objective?.vital_signs || null;
    }
  } catch (e) {
    console.warn('[fetchRecentVitals] Error:', e);
  }
  return null;
}

async function summarizeRecentNotes(supabaseAdmin: any, patientId: string) {
  try {
    const { data, error } = await supabaseAdmin
      .from('clinical_notes')
      .select('created_at, narrative')
      .eq('patient_id', patientId)
      .order('created_at', { ascending: false })
      .limit(3);

    if (error || !data) return '';

    return data
      .map((note: any) => `[${new Date(note.created_at).toLocaleDateString()}] ${note.narrative || ''}`)
      .join('\n');
  } catch (e) {
    console.warn('[summarizeRecentNotes] Error:', e);
  }
  return '';
}
