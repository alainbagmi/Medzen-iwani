import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { verifyFirebaseToken } from '../_shared/verify-firebase-jwt.ts';

/**
 * Creates a comprehensive pre-call context snapshot for a video consultation.
 *
 * This function gathers complete patient demographics, medical history, and appointment context
 * to enable full pre-population of SOAP notes (especially Tab 2 - Patient Identification).
 *
 * DATA GATHERING ARCHITECTURE (Three-Tier Query Pattern):
 * ========================================================
 *
 * Tier 1: appointment_overview (denormalized view)
 *   - Primary data source for appointment + patient + provider information
 *   - Query: appointment_overview WHERE appointment_id = ?
 *   - Returns: appointment_id, appointment_number, chief_complaint, appointment_type, specialty,
 *     scheduled_start, patient_id, patient_full_name, patient_email, patient_phone,
 *     provider_full_name, provider_specialty, facility_name
 *
 * Tier 2: user_profiles (address + emergency contacts)
 *   - Query: user_profiles WHERE user_id = ? (using patient_id extracted from Tier 1)
 *   - Returns: address, emergency_contact_name, emergency_contact_phone, emergency_contact_relationship
 *   - Fallback: Non-critical fields; continue if not found
 *
 * Tier 3: patient_profiles (patient number + cumulative medical record)
 *   - Query: patient_profiles WHERE user_id = ? (using patient_id extracted from Tier 1)
 *   - Returns: patient_number, blood_type, cumulative_medical_record, medical_record_last_updated_at
 *   - Includes: active_conditions, medications, allergies, surgical_history, family_history, social_history
 *
 * CONTEXT SNAPSHOT STRUCTURE (returned in JSONB):
 * =================================================
 *
 * patient_demographics (14 fields total):
 *   REQUIRED (8):
 *     - id, full_name, dob, age, gender, phone, email, created_at
 *   OPTIONAL (6):
 *     - patient_number, address, emergency_contact_name, emergency_contact_phone,
 *       emergency_contact_relationship, blood_type
 *
 * appointment_context (9 fields):
 *   - appointment_id, appointment_number, chief_complaint, appointment_type, specialty,
 *     scheduled_start, provider_name, provider_specialty, facility_name
 *
 * Medical History (from cumulative_medical_record JSONB):
 *   - active_conditions, current_medications, allergies, surgical_history,
 *     family_history, social_history, recent_labs_vitals, recent_notes_summary
 *
 * USAGE PATTERN:
 * ==============
 *
 * 1. Provider initiates call via joinRoom action
 * 2. Frontend calls create-context-snapshot with:
 *    - encounter_id: UUID of video_call_sessions row (for audit trail)
 *    - appointment_id: UUID of appointment being conducted
 * 3. Edge function returns context_snapshots row with complete context JSONB
 * 4. Context snapshot is passed to generate-soap-draft-v2 after call ends
 * 5. AI uses snapshot to pre-populate all 12 SOAP tabs, especially Tab 2
 *
 * ERROR HANDLING:
 * ===============
 *
 * - 401: Missing/invalid Firebase token
 * - 404: Appointment not found in appointment_overview
 * - 404: Patient not found in users table
 * - Non-critical failures (user_profiles, patient_profiles) log warnings but continue
 *
 * POST-RESPONSE VALIDATION:
 * =========================
 *
 * Client (generate-soap-draft-v2) validates:
 * - All 6 required Tab 2 fields present before confidence scoring
 * - Penalties: 0.8 base, -0.2 per missing required field, 0.5 minimum floor
 * - Flags missing data in ai_flags.missing_critical_info for provider review
 *
 * @param {string} encounter_id - UUID of video call session (for audit trail)
 * @param {string} appointment_id - UUID of appointment being conducted (PRIMARY KEY for data lookup)
 * @returns {Promise<Object>} Context snapshot with complete patient/appointment/medical data
 * @throws {Error} If Firebase token invalid, appointment not found, or patient not found
 */

interface ContextSnapshot {
  patient_demographics: {
    id: string;
    full_name: string;
    patient_number?: string;
    dob: string;
    age?: number;
    gender: string;
    phone: string;
    email: string;
    address?: string;
    emergency_contact_name?: string;
    emergency_contact_phone?: string;
    emergency_contact_relationship?: string;
    blood_type?: string;
    created_at: string;
  };
  appointment_context: {
    appointment_id: string;
    appointment_number: string;
    chief_complaint?: string;
    appointment_type: string;
    specialty?: string;
    scheduled_start: string;
    provider_name: string;
    provider_specialty?: string;
    facility_name?: string;
  };
  active_conditions: any;
  current_medications: any;
  allergies: any;
  surgical_history: any;
  family_history: any;
  social_history: any;
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
    const { encounter_id, appointment_id } = await req.json();

    if (!encounter_id || !appointment_id) {
      return new Response(
        JSON.stringify({ error: 'Missing encounter_id or appointment_id', code: 'MISSING_PARAMS', status: 400 }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Initialize Supabase admin client
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

    console.log(`[create-context-snapshot] Creating context snapshot for encounter: ${encounter_id}`);

    // 1. Fetch appointment overview to get denormalized patient + provider + appointment data
    console.log(`[create-context-snapshot] Fetching appointment overview for appointment: ${appointment_id}`);
    const { data: appointmentData, error: appointmentError } = await supabaseAdmin
      .from('appointment_overview')
      .select(`
        patient_user_id,
        patient_full_name,
        patient_email,
        patient_phone,
        patient_id,
        appointment_id,
        appointment_number,
        chief_complaint,
        appointment_type,
        specialty,
        scheduled_start,
        provider_full_name,
        provider_specialty,
        facility_name
      `)
      .eq('appointment_id', appointment_id)
      .single();

    if (appointmentError || !appointmentData) {
      console.error(`[create-context-snapshot] Failed to fetch appointment overview:`, appointmentError);
      return new Response(
        JSON.stringify({
          error: 'Failed to fetch appointment data',
          code: 'APPOINTMENT_NOT_FOUND',
          status: 404,
        }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const patient_id = appointmentData.patient_id;
    console.log(`[create-context-snapshot] Extracted patient_id: ${patient_id} from appointment`);

    // 2. Fetch patient demographics from users table
    console.log(`[create-context-snapshot] Fetching patient demographics for patient: ${patient_id}`);
    const { data: patientData, error: patientError } = await supabaseAdmin
      .from('users')
      .select('id, full_name, date_of_birth, gender, phone_number, email, created_at')
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

    // 3. Fetch patient address and emergency contact from patient_profiles
    console.log(`[create-context-snapshot] Fetching patient address and emergency contacts`);
    const { data: userProfile, error: userProfileError } = await supabaseAdmin
      .from('patient_profiles')
      .select('address, emergency_contact_name, emergency_contact_phone, emergency_contact_relationship')
      .eq('user_id', patient_id)
      .maybeSingle();

    if (userProfileError) {
      console.warn(`[create-context-snapshot] Failed to fetch user profile (non-critical):`, userProfileError);
    }

    // 4. Fetch patient profile with cumulative medical record AND patient_number
    console.log(`[create-context-snapshot] Fetching patient profile and medical history`);
    const { data: patientProfile, error: profileError } = await supabaseAdmin
      .from('patient_profiles')
      .select('blood_type, patient_number, cumulative_medical_record, medical_record_last_updated_at')
      .eq('user_id', patient_id)
      .maybeSingle();

    if (profileError) {
      console.error(`[create-context-snapshot] Failed to fetch patient profile:`, profileError);
    }

    const cumulativeRecord = patientProfile?.cumulative_medical_record || {};

    // 3. Extract active conditions from cumulative_medical_record
    console.log(`[create-context-snapshot] Extracting active conditions`);
    const activeConditions = extractConditionsFromCumulative(cumulativeRecord);

    // 4. Extract current medications from cumulative_medical_record
    console.log(`[create-context-snapshot] Extracting current medications`);
    const medications = extractMedicationsFromCumulative(cumulativeRecord);

    // 5. Extract allergies from cumulative_medical_record
    console.log(`[create-context-snapshot] Extracting allergies`);
    const allergies = extractAllergiesFromCumulative(cumulativeRecord);

    // 6. Extract surgical history
    const surgicalHistory = extractSurgicalHistory(cumulativeRecord);

    // 7. Extract family history
    const familyHistory = extractFamilyHistory(cumulativeRecord);

    // 8. Extract social history
    const socialHistory = extractSocialHistory(cumulativeRecord);

    // 9. Fetch recent labs and vitals
    console.log(`[create-context-snapshot] Fetching recent vitals`);
    const recentVitals = await fetchRecentVitals(supabaseAdmin, patient_id, cumulativeRecord);

    // 10. Summarize recent notes
    console.log(`[create-context-snapshot] Summarizing recent notes`);
    const recentNotesSummary = await summarizeRecentNotes(supabaseAdmin, patient_id);

    // 11. Build COMPLETE snapshot object with ALL Tab 2 fields
    const snapshot: ContextSnapshot = {
      patient_demographics: {
        id: patientData.id,
        full_name: patientData.full_name || appointmentData.patient_full_name,
        patient_number: patientProfile?.patient_number,
        dob: patientData.date_of_birth,
        age: patientData.date_of_birth
          ? Math.floor((Date.now() - new Date(patientData.date_of_birth).getTime()) / (365.25 * 24 * 60 * 60 * 1000))
          : undefined,
        gender: patientData.gender,
        phone: patientData.phone_number || appointmentData.patient_phone,
        email: patientData.email || appointmentData.patient_email,
        address: userProfile?.address,
        emergency_contact_name: userProfile?.emergency_contact_name,
        emergency_contact_phone: userProfile?.emergency_contact_phone,
        emergency_contact_relationship: userProfile?.emergency_contact_relationship,
        blood_type: patientProfile?.blood_type || 'Unknown',
        created_at: patientData.created_at,
      },
      appointment_context: {
        appointment_id: appointmentData.appointment_id,
        appointment_number: appointmentData.appointment_number,
        chief_complaint: appointmentData.chief_complaint,
        appointment_type: appointmentData.appointment_type,
        specialty: appointmentData.specialty,
        scheduled_start: appointmentData.scheduled_start,
        provider_name: appointmentData.provider_full_name,
        provider_specialty: appointmentData.provider_specialty,
        facility_name: appointmentData.facility_name,
      },
      active_conditions: activeConditions,
      current_medications: medications,
      allergies: allergies,
      surgical_history: surgicalHistory,
      family_history: familyHistory,
      social_history: socialHistory,
      recent_labs_vitals: recentVitals,
      recent_notes_summary: recentNotesSummary,
    };

    // Log completeness for debugging
    console.log(`[create-context-snapshot] Snapshot completeness check:`);
    console.log(`  - Patient Name: ${snapshot.patient_demographics.full_name ? '✓' : '✗'}`);
    console.log(`  - DOB: ${snapshot.patient_demographics.dob ? '✓' : '✗'}`);
    console.log(`  - Phone: ${snapshot.patient_demographics.phone ? '✓' : '✗'}`);
    console.log(`  - Email: ${snapshot.patient_demographics.email ? '✓' : '✗'}`);
    console.log(`  - Address: ${snapshot.patient_demographics.address ? '✓' : '✗ (optional)'}`);
    console.log(`  - Emergency Contact: ${snapshot.patient_demographics.emergency_contact_name ? '✓' : '✗ (optional)'}`);
    console.log(`  - Patient Number: ${snapshot.patient_demographics.patient_number ? '✓' : '✗ (optional)'}`);
    console.log(`  - Blood Type: ${snapshot.patient_demographics.blood_type !== 'Unknown' ? '✓' : '✗ (optional)'}`);
    console.log(`  - Appointment Type: ${snapshot.appointment_context.appointment_type ? '✓' : '✗'}`);
    console.log(`  - Provider: ${snapshot.appointment_context.provider_name ? '✓' : '✗'}`);

    // 12. Store snapshot in database
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

    // 13. Update encounter status in video_call_sessions
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

function extractConditionsFromCumulative(cumulativeRecord: any): any[] {
  try {
    const conditions = (cumulativeRecord?.conditions || []) as any[];
    return conditions
      .filter((c) => (c.status === 'active' || !c.status))
      .map((c) => ({
        name: c.name || 'Unknown',
        icd10: c.icd10 || 'N/A',
        status: c.status || 'active',
        onset_date: c.onset_date,
        severity: c.severity,
      }))
      .slice(0, 10);
  } catch (e) {
    console.warn('[extractConditionsFromCumulative] Error:', e);
    return [];
  }
}

function extractMedicationsFromCumulative(cumulativeRecord: any): any[] {
  try {
    const medications = (cumulativeRecord?.medications || []) as any[];
    return medications
      .filter((m) => (m.status === 'active' || !m.status))
      .map((m) => ({
        name: m.name || 'Unknown',
        dose: m.dose || '',
        frequency: m.frequency || '',
        route: m.route || 'oral',
        status: m.status || 'active',
      }))
      .slice(0, 15);
  } catch (e) {
    console.warn('[extractMedicationsFromCumulative] Error:', e);
    return [];
  }
}

function extractAllergiesFromCumulative(cumulativeRecord: any): any[] {
  try {
    const allergies = (cumulativeRecord?.allergies || []) as any[];
    return allergies
      .filter((a) => (a.status === 'active' || !a.status))
      .map((a) => ({
        allergen: a.allergen || 'Unknown',
        severity: a.severity || 'moderate',
        reaction: a.reaction || '',
        status: a.status || 'active',
      }))
      .slice(0, 10);
  } catch (e) {
    console.warn('[extractAllergiesFromCumulative] Error:', e);
    return [];
  }
}

function extractSurgicalHistory(cumulativeRecord: any): any[] {
  try {
    const procedures = (cumulativeRecord?.surgical_history || []) as any[];
    return procedures
      .map((p) => ({
        procedure: p.procedure || 'Unknown',
        date: p.date || 'N/A',
        surgeon: p.surgeon,
        notes: p.notes,
      }))
      .slice(0, 10);
  } catch (e) {
    console.warn('[extractSurgicalHistory] Error:', e);
    return [];
  }
}

function extractFamilyHistory(cumulativeRecord: any): any[] {
  try {
    const family = (cumulativeRecord?.family_history || []) as any[];
    return family
      .map((f) => ({
        condition: f.condition || 'Unknown',
        relationship: f.relationship || 'N/A',
        age_of_onset: f.age_of_onset,
      }))
      .slice(0, 10);
  } catch (e) {
    console.warn('[extractFamilyHistory] Error:', e);
    return [];
  }
}

function extractSocialHistory(cumulativeRecord: any): any {
  try {
    const social = cumulativeRecord?.social_history || {};
    return {
      smoking_status: social.smoking_status || 'Unknown',
      alcohol_use: social.alcohol_use || 'Unknown',
      drug_use: social.drug_use || 'None',
      occupation: social.occupation,
      living_situation: social.living_situation,
      notes: social.notes,
    };
  } catch (e) {
    console.warn('[extractSocialHistory] Error:', e);
    return {};
  }
}

async function fetchRecentVitals(supabaseAdmin: any, patientId: string, cumulativeRecord: any) {
  try {
    // First try to get latest vitals from cumulative record
    const vitalTrends = cumulativeRecord?.vital_trends || {};
    if (Object.keys(vitalTrends).length > 0) {
      return vitalTrends;
    }

    // Fallback to most recent SOAP note's vital signs
    const { data, error } = await supabaseAdmin
      .from('soap_notes')
      .select('objective')
      .eq('patient_id', patientId)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error || !data) return {};

    return data.objective?.vital_signs || {};
  } catch (e) {
    console.warn('[fetchRecentVitals] Error:', e);
  }
  return {};
}

async function summarizeRecentNotes(supabaseAdmin: any, patientId: string) {
  try {
    const { data, error } = await supabaseAdmin
      .from('soap_notes')
      .select('id, created_at, chief_complaint')
      .eq('patient_id', patientId)
      .order('created_at', { ascending: false })
      .limit(3);

    if (error || !data || data.length === 0) return 'No previous visits';

    return data
      .map(
        (note: any) =>
          `${note.chief_complaint || 'N/A'} (${new Date(note.created_at).toLocaleDateString()})`
      )
      .join('; ');
  } catch (e) {
    console.warn('[summarizeRecentNotes] Error:', e);
  }
  return 'No previous visits';
}
