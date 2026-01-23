import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.0";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";
import { checkRateLimit, getRateLimitConfig, createRateLimitErrorResponse } from "../_shared/rate-limiter.ts";

// Import shared utilities
const { verifyFirebaseJWT } = await import("../_shared/verify-firebase-jwt.ts");

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!supabaseUrl || !supabaseKey) {
  throw new Error("Missing Supabase environment variables");
}

const supabaseAdmin = createClient(supabaseUrl, supabaseKey);

interface SoapNoteData {
  conditions: Array<{
    name: string;
    icd10?: string;
    status: string;
    severity?: string;
  }>;
  medications: Array<{
    name: string;
    dose?: string;
    route?: string;
    frequency?: string;
    status: string;
  }>;
  allergies: Array<{
    allergen: string;
    reaction?: string;
    severity: string;
  }>;
  vital_trends?: Record<string, any>;
}

/**
 * Extract SOAP data from normalized soap_notes structure
 */
async function extractSoapData(
  soapNoteId: string
): Promise<SoapNoteData> {
  try {
    // Get problem list (conditions)
    const { data: conditions } = await supabaseAdmin
      .from("soap_assessment_problem_list")
      .select(
        "diagnosis_name, icd10_code, status, severity"
      )
      .eq("soap_note_id", soapNoteId);

    // Get medications
    const { data: medications } = await supabaseAdmin
      .from("soap_plan_medication")
      .select(
        "medication_name, dose, route, frequency, status"
      )
      .eq("soap_note_id", soapNoteId);

    // Get allergies
    const { data: allergies } = await supabaseAdmin
      .from("soap_subjective_allergies")
      .select(
        "allergen, reaction, severity"
      )
      .eq("soap_note_id", soapNoteId);

    // Get vital signs
    const { data: vitals } = await supabaseAdmin
      .from("soap_objective_vital_signs")
      .select(
        "vital_name, vital_value, unit"
      )
      .eq("soap_note_id", soapNoteId);

    // Transform to JSONB format expected by merge function
    const soapData: SoapNoteData = {
      conditions: (conditions || []).map(c => ({
        name: c.diagnosis_name,
        icd10: c.icd10_code,
        status: c.status || "active",
        severity: c.severity,
      })),
      medications: (medications || []).map(m => ({
        name: m.medication_name,
        dose: m.dose,
        route: m.route,
        frequency: m.frequency,
        status: m.status || "active",
      })),
      allergies: (allergies || []).map(a => ({
        allergen: a.allergen,
        reaction: a.reaction,
        severity: a.severity || "moderate",
      })),
      vital_trends: vitals
        ? Object.fromEntries(
            vitals.map(v => [
              v.vital_name,
              {
                value: v.vital_value,
                unit: v.unit,
              },
            ])
          )
        : {},
    };

    return soapData;
  } catch (error) {
    console.error("Error extracting SOAP data:", error);
    throw error;
  }
}

/**
 * Update patient cumulative medical record
 * Called after post-call SOAP note is signed
 */
serve(async (req: Request) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  // CORS pre-flight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: { ...corsHeaders, ...securityHeaders },
    });
  }

  try {
    // Get Firebase token from headers (lowercase)
    const firebaseToken = req.headers.get("x-firebase-token");
    if (!firebaseToken) {
      return new Response(
        JSON.stringify({
          error: "Missing x-firebase-token header",
          code: "INVALID_FIREBASE_TOKEN",
          status: 401,
        }),
        {
          status: 401,
          headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Verify Firebase token
    const auth = await verifyFirebaseJWT(firebaseToken);
    if (!auth.valid) {
      return new Response(
        JSON.stringify({
          error: "Invalid or expired Firebase token",
          code: "INVALID_FIREBASE_TOKEN",
          status: 401,
        }),
        {
          status: 401,
          headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const userId = auth.userId;

    // Rate limiting check (HIPAA: Prevents DDoS and abuse)
    const rateLimitConfig = getRateLimitConfig('update-patient-medical-record', userId);
    const rateLimit = await checkRateLimit(rateLimitConfig);
    if (!rateLimit.allowed) {
      console.warn(`🚫 Rate limit exceeded for user ${userId}`);
      return createRateLimitErrorResponse(rateLimit);
    }

    const { soapNoteId, patientId } = await req.json();

    if (!soapNoteId || !patientId) {
      return new Response(
        JSON.stringify({
          error: "Missing required parameters: soapNoteId, patientId",
          code: "INVALID_REQUEST",
          status: 400,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Verify SOAP note exists and belongs to this patient
    const { data: soapNote, error: soapError } = await supabaseAdmin
      .from("soap_notes")
      .select("id, patient_id, provider_id, created_at")
      .eq("id", soapNoteId)
      .single();

    if (soapError || !soapNote) {
      console.error("SOAP note not found:", soapNoteId);
      return new Response(
        JSON.stringify({
          error: "SOAP note not found",
          code: "NOT_FOUND",
          status: 404,
        }),
        {
          status: 404,
          headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Verify patient ID matches
    if (soapNote.patient_id !== patientId) {
      console.error(
        `Patient ID mismatch: SOAP has ${soapNote.patient_id}, request has ${patientId}`
      );
      return new Response(
        JSON.stringify({
          error: "Patient ID mismatch",
          code: "INVALID_REQUEST",
          status: 400,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Extract SOAP data from normalized structure
    console.log(`📋 Extracting SOAP data for note ${soapNoteId}`);
    const soapData = await extractSoapData(soapNoteId);

    // Call PostgreSQL function to merge into cumulative record
    console.log(`🔄 Merging SOAP data into patient record for ${patientId}`);
    const { data: mergedRecord, error: mergeError } = await supabaseAdmin.rpc(
      "merge_soap_into_cumulative_record",
      {
        p_patient_id: patientId,
        p_soap_note_id: soapNoteId,
        p_soap_data: soapData,
      }
    );

    if (mergeError) {
      console.error("Error merging SOAP data:", mergeError);
      return new Response(
        JSON.stringify({
          error: "Failed to update patient medical record",
          code: "MERGE_ERROR",
          status: 500,
          details: mergeError,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`✅ Successfully updated patient medical record for ${patientId}`);
    console.log(
      `📊 Record now has ${mergedRecord?.metadata?.total_visits || 0} visits`
    );

    return new Response(
      JSON.stringify({
        success: true,
        status: 200,
        message: "Patient medical record updated successfully",
        data: {
          patientId,
          soapNoteId,
          updatedRecord: mergedRecord,
          totalVisits: mergedRecord?.metadata?.total_visits,
        },
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Unexpected error in update-patient-medical-record:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        code: "INTERNAL_ERROR",
        status: 500,
        details: String(error),
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
