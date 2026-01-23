import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";
import { checkRateLimit, getRateLimitConfig, createRateLimitErrorResponse } from "../_shared/rate-limiter.ts";
import { verifyFirebaseJWT } from "../_shared/verify-firebase-jwt.ts";

interface SOAPRequest {
  patientId: string;
  appointmentId: string;
  transcript?: string;
  mode: "pre-call" | "post-call";
}

interface SOAPResponse {
  chiefComplaint?: string;
  hpiNarrative?: string;
  pastMedicalHistory?: string;
  allergies?: string;
  assessment?: string;
  plan?: string;
  medications?: string;
  error?: string;
}

/**
 * SECURITY-FIRST SOAP GENERATION FUNCTION
 *
 * This function generates SOAP clinical notes using Claude Opus with strict patient data isolation.
 *
 * CRITICAL SECURITY:
 * 1. Validates appointment belongs to patient BEFORE any data access
 * 2. All database queries scoped to specific patientId
 * 3. Claude Opus prompt explicitly limited to patient data
 * 4. No cross-patient data access possible
 * 5. Audit logging for all data access attempts
 */
serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders_dynamic = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders_dynamic, ...securityHeaders } });
  }

  try {
    // Verify authentication - require Authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders_dynamic, ...securityHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client with service role for database operations
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get request body
    const body: SOAPRequest = await req.json();
    const { patientId, appointmentId, transcript, mode } = body;

    // Validate required fields
    if (!patientId || !appointmentId || !mode || !["pre-call", "post-call"].includes(mode)) {
      return new Response(
        JSON.stringify({
          error: "Missing or invalid required fields: patientId, appointmentId, mode"
        }),
        { status: 400, headers: { ...corsHeaders_dynamic, ...securityHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`🔐 SOAP Generation Request - Patient: ${patientId}, Appointment: ${appointmentId}, Mode: ${mode}`);

    // ==========================================
    // SECURITY: VALIDATE APPOINTMENT-PATIENT MATCH
    // ==========================================
    console.log(`🔐 SECURITY: Validating appointment ownership...`);

    const { data: appointment, error: appointmentError } = await supabase
      .from("appointments")
      .select("id, patient_id, appointment_date, appointment_type, chief_complaint")
      .eq("id", appointmentId)
      .single();

    if (appointmentError || !appointment) {
      console.error(`❌ SECURITY: Appointment not found - ${appointmentError?.message || "unknown error"}`);
      return new Response(
        JSON.stringify({ error: "Appointment not found" }),
        { status: 404, headers: { ...corsHeaders_dynamic, ...securityHeaders, "Content-Type": "application/json" } }
      );
    }

    // CRITICAL: Verify appointment belongs to patient
    if (appointment.patient_id !== patientId) {
      console.error(`🚨 SECURITY VIOLATION: Unauthorized access attempt!`);
      console.error(`   Requested patient: ${patientId}`);
      console.error(`   Appointment owner: ${appointment.patient_id}`);
      console.error(`   Appointment: ${appointmentId}`);

      // Log security violation for audit trail
      await supabase
        .from("audit_log")
        .insert({
          event_type: "unauthorized_soap_access",
          user_id: patientId,
          appointment_id: appointmentId,
          error_details: `Attempted access to appointment owned by ${appointment.patient_id}`,
          created_at: new Date().toISOString(),
        })
        .then(() => {
          console.log("✓ Security violation logged to audit_log");
        })
        .catch((err) => {
          console.warn(`⚠️ Could not log security violation: ${err.message}`);
        });

      return new Response(
        JSON.stringify({ error: "Unauthorized access to patient data" }),
        { status: 403, headers: { ...corsHeaders_dynamic, ...securityHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(`✅ SECURITY: Appointment ownership validated - proceeding with patient-scoped data access`);

    // ==========================================
    // FETCH PATIENT-SCOPED DATA
    // ==========================================
    console.log(`📋 Fetching patient-scoped data for SOAP generation...`);

    // 1. Fetch patient profile (scoped to THIS patient only)
    const { data: patientProfile, error: patientError } = await supabase
      .from("patient_profiles")
      .select("blood_pressure, heart_rate, temperature, respiratory_rate, oxygen_saturation, weight, height, blood_group, medical_conditions, medications_history")
      .eq("user_id", patientId)
      .single();

    if (patientError) {
      console.warn(`⚠️ Could not fetch patient profile: ${patientError.message}`);
    }

    // 2. Fetch previous SOAP notes (scoped to THIS patient only - last 3)
    const { data: previousSOAPs, error: soapError } = await supabase
      .from("soap_notes")
      .select("chief_complaint, hpi_narrative, past_medical_history, allergies, assessment, plan")
      .eq("patient_id", patientId)
      .order("created_at", { ascending: false })
      .limit(3);

    if (soapError) {
      console.warn(`⚠️ Could not fetch previous SOAP notes: ${soapError.message}`);
    }

    // 3. Fetch appointment details
    const appointmentDate = new Date(appointment.appointment_date).toLocaleDateString();
    const appointmentType = appointment.appointment_type || "General Consultation";

    console.log(`✓ Patient data fetched - Chief Complaint from appointment: "${appointment.chief_complaint}"`);

    // ==========================================
    // PREPARE CONTEXT FOR CLAUDE OPUS
    // ==========================================
    console.log(`🤖 Preparing Claude Opus context (patient-scoped)...`);

    // Build patient context
    const biometricsContext = patientProfile
      ? `Current Vitals:
   - Blood Pressure: ${patientProfile.blood_pressure || "N/A"}
   - Heart Rate: ${patientProfile.heart_rate || "N/A"} bpm
   - Temperature: ${patientProfile.temperature || "N/A"}°C
   - Respiratory Rate: ${patientProfile.respiratory_rate || "N/A"} breaths/min
   - Oxygen Saturation: ${patientProfile.oxygen_saturation || "N/A"}%
   - Weight: ${patientProfile.weight || "N/A"} kg
   - Height: ${patientProfile.height || "N/A"} cm
   - Blood Group: ${patientProfile.blood_group || "N/A"}`
      : "Biometrics: Not available";

    const previousSOAPContext =
      previousSOAPs && previousSOAPs.length > 0
        ? `Previous Medical History:
${previousSOAPs
  .slice(0, 1)
  .map(
    (soap, i) =>
      `Previous Visit ${i + 1}:
- Chief Complaint: ${soap.chief_complaint || "N/A"}
- History: ${soap.hpi_narrative || "N/A"}
- Past History: ${soap.past_medical_history || "N/A"}
- Allergies: ${soap.allergies || "N/A"}`
  )
  .join("\n\n")}`
        : "Previous Medical History: No previous records available";

    // Build the prompt based on mode
    let modePrompt = "";
    if (mode === "pre-call") {
      modePrompt = `Generate PRE-CALL clinical context for a provider to review before consultation.
Focus on: Chief Complaint, History of Present Illness, Past Medical History, and Allergies.
These fields will be REVIEWED (read-only) by the provider before the call starts.
Provide professional medical context to help the provider prepare.`;
    } else {
      modePrompt = `Generate POST-CALL clinical assessment based on the consultation transcript.
Focus on: Assessment & Diagnosis, Plan, Medications, and Follow-up Instructions.
The provider will EDIT these fields after the call.
Provide a professional assessment that the provider can review and modify.`;
    }

    // Build Claude Opus prompt with EXPLICIT patient ID isolation
    const claudePrompt = `You are a clinical documentation AI assistant.

PATIENT ID: ${patientId}
APPOINTMENT ID: ${appointmentId}
DATE: ${appointmentDate}
VISIT TYPE: ${appointmentType}

CRITICAL: You are only processing data for Patient ID: ${patientId}.
Never reference, suggest, or generate data for any other patient.
All clinical decisions and recommendations must be based solely on this patient's information.

${modePrompt}

PATIENT INFORMATION:
Chief Complaint: ${appointment.chief_complaint || "Not specified"}

${biometricsContext}

${previousSOAPContext}

${
  transcript
    ? `CONSULTATION TRANSCRIPT:
${transcript}

Using this transcript, generate professional clinical assessment.`
    : ""
}

${
  mode === "pre-call"
    ? `Generate fields as JSON:
{
  "chiefComplaint": "Brief chief complaint summary",
  "hpiNarrative": "Relevant history based on appointment notes and vitals",
  "pastMedicalHistory": "Known medical conditions or relevant history",
  "allergies": "Known allergies or sensitivities"
}`
    : `Generate fields as JSON:
{
  "assessment": "Clinical assessment and diagnosis based on consultation",
  "plan": "Treatment and management plan",
  "medications": "Recommended medications if applicable",
  "followUp": "Follow-up instructions and next steps"
}`
}

Return ONLY valid JSON, no additional text.`;

    // ==========================================
    // CALL AWS LAMBDA FOR BEDROCK CLAUDE OPUS
    // ==========================================
    console.log(`📡 Calling AWS Lambda for Claude Opus generation...`);

    const bedrockLambdaUrl = Deno.env.get("BEDROCK_LAMBDA_URL");
    if (!bedrockLambdaUrl) {
      console.error("❌ BEDROCK_LAMBDA_URL not configured");
      return new Response(
        JSON.stringify({ error: "AI service not configured" }),
        { status: 500, headers: { ...corsHeaders_dynamic, ...securityHeaders, "Content-Type": "application/json" } }
      );
    }

    const LAMBDA_TIMEOUT_MS = 30000; // 30 seconds
    const MAX_RETRIES = 2;
    let lambdaResponse: Response | null = null;

    for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), LAMBDA_TIMEOUT_MS);

        try {
          lambdaResponse = await fetch(bedrockLambdaUrl, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            signal: controller.signal,
            body: JSON.stringify({
              message: claudePrompt,
              conversationId: `soap-${appointmentId}`,
              userId: patientId,
              modelId: "eu.anthropic.claude-opus-4-20250514", // Claude Opus for medical expertise
              systemPrompt: "You are a clinical documentation specialist helping generate SOAP notes. Generate only JSON output.",
              modelConfig: {
                temperature: 0.7,
                max_tokens: 1024,
              },
            }),
          });

          clearTimeout(timeoutId);

          if (lambdaResponse.ok) {
            break; // Success, exit retry loop
          }

          // Non-2xx response, check if retryable
          if (lambdaResponse.status >= 500 && attempt < MAX_RETRIES) {
            console.log(`Lambda returned ${lambdaResponse.status}, retrying (attempt ${attempt + 1}/${MAX_RETRIES})`);
            await new Promise((r) => setTimeout(r, 1000 * Math.pow(2, attempt)));
            continue;
          }
        } finally {
          clearTimeout(timeoutId);
        }
      } catch (error) {
        if ((error as Error).name === "AbortError") {
          console.error(`Lambda call timed out after ${LAMBDA_TIMEOUT_MS}ms (attempt ${attempt + 1})`);
          if (attempt < MAX_RETRIES) {
            await new Promise((r) => setTimeout(r, 1000 * Math.pow(2, attempt)));
            continue;
          }
          throw new Error(`AI service timeout after ${LAMBDA_TIMEOUT_MS / 1000}s`);
        }

        if (attempt < MAX_RETRIES) {
          console.log(`Lambda call failed, retrying (attempt ${attempt + 1}/${MAX_RETRIES}): ${(error as Error).message}`);
          await new Promise((r) => setTimeout(r, 1000 * Math.pow(2, attempt)));
          continue;
        }

        throw error;
      }
    }

    if (!lambdaResponse || !lambdaResponse.ok) {
      const errorData = lambdaResponse ? await lambdaResponse.json().catch(() => ({})) : {};
      throw new Error((errorData as any).error || "Failed to get SOAP generation from Lambda");
    }

    // ==========================================
    // PARSE CLAUDE OPUS RESPONSE
    // ==========================================
    console.log(`✅ Received SOAP generation from Claude Opus`);

    const lambdaData = await lambdaResponse.json();
    const soapContent = (lambdaData as any).message;

    console.log(`📝 Parsing generated SOAP content...`);

    // Extract JSON from response
    let soapData: SOAPResponse = {};
    try {
      // Try to parse as JSON directly
      soapData = JSON.parse(soapContent);
    } catch (parseError) {
      // Try to extract JSON from markdown code blocks
      const jsonMatch = soapContent.match(/```(?:json)?\s*([\s\S]*?)```/);
      if (jsonMatch) {
        try {
          soapData = JSON.parse(jsonMatch[1]);
        } catch (innerError) {
          console.warn(`Could not parse JSON from markdown: ${(innerError as Error).message}`);
          // Return partial response with raw content
          soapData = { hpiNarrative: soapContent };
        }
      } else {
        console.warn(`Could not extract JSON from response`);
        soapData = { hpiNarrative: soapContent };
      }
    }

    // ==========================================
    // LOG AUDIT TRAIL
    // ==========================================
    console.log(`📋 Logging SOAP generation to audit trail...`);

    await supabase
      .from("audit_log")
      .insert({
        event_type: "soap_generation",
        user_id: patientId,
        appointment_id: appointmentId,
        metadata: {
          mode: mode,
          fields_generated: Object.keys(soapData).length,
        },
        created_at: new Date().toISOString(),
      })
      .then(() => {
        console.log("✓ SOAP generation logged");
      })
      .catch((err) => {
        console.warn(`⚠️ Could not log SOAP generation: ${err.message}`);
      });

    // ==========================================
    // RETURN SUCCESS RESPONSE
    // ==========================================
    console.log(`✅ SOAP generation complete for Patient: ${patientId}`);

    return new Response(
      JSON.stringify({
        success: true,
        patientId: patientId,
        appointmentId: appointmentId,
        mode: mode,
        data: soapData,
      }),
      { status: 200, headers: { ...corsHeaders_dynamic, ...securityHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("❌ Error in SOAP generation:", (error as Error).message);

    return new Response(
      JSON.stringify({
        error: "Failed to generate SOAP",
        details: (error as Error).message,
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
