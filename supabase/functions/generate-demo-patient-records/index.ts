import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { jwtDecode } from "https://esm.sh/jwt-decode@3.1.2";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

interface GenerateRecordsRequest {
  patientId?: string; // Optional: if not provided, uses first patient
  generateCount?: number; // 1-3, default 3
}

interface GenerateRecordsResponse {
  success: boolean;
  message: string;
  patientId?: string;
  soapNotesCreated?: number;
  conditionsCount?: number;
  medicationsCount?: number;
  allergiesCount?: number;
  error?: string;
}

serve(async (req: Request): Promise<Response> => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  try {
    const { patientId: requestPatientId, generateCount = 3 } =
      (await req.json()) as GenerateRecordsRequest;

    // Verify Firebase token
    const token = req.headers.get("x-firebase-token");
    if (!token) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing x-firebase-token header",
        } as GenerateRecordsResponse),
        { status: 401, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

    // Get demo patient ID
    let patientId = requestPatientId;

    if (!patientId) {
      // Find first patient or demo patient
      const { data: patients } = await supabaseAdmin
        .from("users")
        .select("id, first_name, email")
        .eq("role", "patient")
        .order("created_at", { ascending: true })
        .limit(1);

      if (!patients || patients.length === 0) {
        return new Response(
          JSON.stringify({
            success: false,
            error: "No patients found in system",
          } as GenerateRecordsResponse),
          { status: 404, headers: { "Content-Type": "application/json" } }
        );
      }

      patientId = patients[0].id;
    }

    // Get provider ID
    const { data: providers } = await supabaseAdmin
      .from("users")
      .select("id")
      .eq("role", "provider")
      .order("created_at", { ascending: true })
      .limit(1);

    if (!providers || providers.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "No providers found in system",
        } as GenerateRecordsResponse),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    const providerId = providers[0].id;

    // ========================================================================
    // Visit 1: Initial Visit (2026-01-05)
    // ========================================================================

    const visit1Date = new Date("2026-01-05T09:30:00Z");
    const soapNote1Id = crypto.randomUUID();

    const { error: soapNote1Error } = await supabaseAdmin
      .from("soap_notes")
      .insert({
        id: soapNote1Id,
        patient_id: patientId,
        provider_id: providerId,
        session_id: crypto.randomUUID(),
        status: "signed",
        created_at: visit1Date.toISOString(),
        updated_at: new Date(visit1Date.getTime() + 15 * 60000).toISOString(),
        signed_at: new Date(visit1Date.getTime() + 15 * 60000).toISOString(),
        signed_by: providerId,
      });

    if (soapNote1Error) {
      throw new Error(`Failed to create SOAP note 1: ${soapNote1Error.message}`);
    }

    // Add conditions for Visit 1
    await supabaseAdmin.from("soap_assessment_problem_list").insert([
      {
        id: crypto.randomUUID(),
        soap_note_id: soapNote1Id,
        diagnosis_name: "Type 2 Diabetes Mellitus",
        icd10_code: "E11.9",
        status: "active",
        severity: "moderate",
        notes: "Well-controlled on current regimen",
      },
      {
        id: crypto.randomUUID(),
        soap_note_id: soapNote1Id,
        diagnosis_name: "Hypertension",
        icd10_code: "I10",
        status: "active",
        severity: "mild",
        notes: "BP 138/88 mmHg",
      },
      {
        id: crypto.randomUUID(),
        soap_note_id: soapNote1Id,
        diagnosis_name: "Hyperlipidemia",
        icd10_code: "E78.5",
        status: "active",
        severity: "mild",
        notes: "Total cholesterol 215 mg/dL",
      },
    ]);

    // Add medications for Visit 1
    await supabaseAdmin.from("soap_plan_medication").insert([
      {
        id: crypto.randomUUID(),
        soap_note_id: soapNote1Id,
        name: "Metformin",
        dose: "500mg",
        route: "oral",
        frequency: "twice daily",
        status: "active",
        notes: "Current",
      },
      {
        id: crypto.randomUUID(),
        soap_note_id: soapNote1Id,
        name: "Lisinopril",
        dose: "10mg",
        route: "oral",
        frequency: "once daily",
        status: "active",
        notes: "Current",
      },
      {
        id: crypto.randomUUID(),
        soap_note_id: soapNote1Id,
        name: "Atorvastatin",
        dose: "20mg",
        route: "oral",
        frequency: "once daily at bedtime",
        status: "active",
        notes: "Current",
      },
    ]);

    // Add allergies for Visit 1
    await supabaseAdmin.from("soap_subjective_allergies").insert([
      {
        id: crypto.randomUUID(),
        soap_note_id: soapNote1Id,
        allergen: "Penicillin",
        reaction: "Rash and itching",
        severity: "moderate",
      },
      {
        id: crypto.randomUUID(),
        soap_note_id: soapNote1Id,
        allergen: "Sulfonamides",
        reaction: "Nausea",
        severity: "mild",
      },
    ]);

    // Add vitals for Visit 1
    await supabaseAdmin.from("soap_objective_vital_signs").insert([
      {
        id: crypto.randomUUID(),
        soap_note_id: soapNote1Id,
        vital_name: "Temperature",
        vital_value: "98.6",
        unit: "°F",
      },
      {
        id: crypto.randomUUID(),
        soap_note_id: soapNote1Id,
        vital_name: "Blood Pressure Systolic",
        vital_value: "138",
        unit: "mmHg",
      },
      {
        id: crypto.randomUUID(),
        soap_note_id: soapNote1Id,
        vital_name: "Blood Pressure Diastolic",
        vital_value: "88",
        unit: "mmHg",
      },
      {
        id: crypto.randomUUID(),
        soap_note_id: soapNote1Id,
        vital_name: "Heart Rate",
        vital_value: "72",
        unit: "bpm",
      },
      {
        id: crypto.randomUUID(),
        soap_note_id: soapNote1Id,
        vital_name: "Weight",
        vital_value: "185",
        unit: "lbs",
      },
      {
        id: crypto.randomUUID(),
        soap_note_id: soapNote1Id,
        vital_name: "Height",
        vital_value: "70",
        unit: "inches",
      },
    ]);

    // Merge Visit 1 into cumulative record
    await supabaseAdmin.rpc("merge_soap_into_cumulative_record", {
      p_patient_id: patientId,
      p_soap_note_id: soapNote1Id,
      p_soap_data: {},
    });

    // ========================================================================
    // Visit 2: Follow-up Visit (2026-01-12) - New medication added
    // ========================================================================

    if (generateCount >= 2) {
      const visit2Date = new Date("2026-01-12T10:15:00Z");
      const soapNote2Id = crypto.randomUUID();

      const { error: soapNote2Error } = await supabaseAdmin
        .from("soap_notes")
        .insert({
          id: soapNote2Id,
          patient_id: patientId,
          provider_id: providerId,
          session_id: crypto.randomUUID(),
          status: "signed",
          created_at: visit2Date.toISOString(),
          updated_at: new Date(
            visit2Date.getTime() + 15 * 60000
          ).toISOString(),
          signed_at: new Date(visit2Date.getTime() + 15 * 60000).toISOString(),
          signed_by: providerId,
        });

      if (soapNote2Error) {
        throw new Error(
          `Failed to create SOAP note 2: ${soapNote2Error.message}`
        );
      }

      // Add conditions for Visit 2 (new condition + updates)
      await supabaseAdmin.from("soap_assessment_problem_list").insert([
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          diagnosis_name: "Type 2 Diabetes Mellitus",
          icd10_code: "E11.9",
          status: "active",
          severity: "moderate",
          notes: "Well-controlled, last HbA1c 6.8%",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          diagnosis_name: "Hypertension",
          icd10_code: "I10",
          status: "active",
          severity: "moderate",
          notes: "BP 148/92 mmHg - increased dose needed",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          diagnosis_name: "Hyperlipidemia",
          icd10_code: "E78.5",
          status: "active",
          severity: "mild",
          notes: "Continue current therapy",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          diagnosis_name: "Chronic Kidney Disease Stage 3a",
          icd10_code: "N18.1",
          status: "active",
          severity: "moderate",
          notes: "eGFR 48 mL/min",
        },
      ]);

      // Add medications for Visit 2 (dose update + new medication)
      await supabaseAdmin.from("soap_plan_medication").insert([
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          name: "Metformin",
          dose: "500mg",
          route: "oral",
          frequency: "twice daily",
          status: "active",
          notes: "Continue",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          name: "Lisinopril",
          dose: "20mg",
          route: "oral",
          frequency: "once daily",
          status: "active",
          notes: "Dose increased from 10mg",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          name: "Atorvastatin",
          dose: "20mg",
          route: "oral",
          frequency: "once daily at bedtime",
          status: "active",
          notes: "Continue",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          name: "Amlodipine",
          dose: "5mg",
          route: "oral",
          frequency: "once daily",
          status: "active",
          notes: "New - for additional BP control",
        },
      ]);

      // Add allergies for Visit 2
      await supabaseAdmin.from("soap_subjective_allergies").insert([
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          allergen: "Penicillin",
          reaction: "Rash and itching",
          severity: "moderate",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          allergen: "Sulfonamides",
          reaction: "Nausea",
          severity: "mild",
        },
      ]);

      // Add vitals for Visit 2
      await supabaseAdmin.from("soap_objective_vital_signs").insert([
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          vital_name: "Temperature",
          vital_value: "98.4",
          unit: "°F",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          vital_name: "Blood Pressure Systolic",
          vital_value: "148",
          unit: "mmHg",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          vital_name: "Blood Pressure Diastolic",
          vital_value: "92",
          unit: "mmHg",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          vital_name: "Heart Rate",
          vital_value: "75",
          unit: "bpm",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          vital_name: "Weight",
          vital_value: "186",
          unit: "lbs",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          vital_name: "Height",
          vital_value: "70",
          unit: "inches",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote2Id,
          vital_name: "Blood Sugar (Fasting)",
          vital_value: "128",
          unit: "mg/dL",
        },
      ]);

      // Merge Visit 2 into cumulative record
      await supabaseAdmin.rpc("merge_soap_into_cumulative_record", {
        p_patient_id: patientId,
        p_soap_note_id: soapNote2Id,
        p_soap_data: {},
      });
    }

    // ========================================================================
    // Visit 3: Recent Visit (2026-01-20) - Allergy escalated, new medication
    // ========================================================================

    if (generateCount >= 3) {
      const visit3Date = new Date("2026-01-20T14:00:00Z");
      const soapNote3Id = crypto.randomUUID();

      const { error: soapNote3Error } = await supabaseAdmin
        .from("soap_notes")
        .insert({
          id: soapNote3Id,
          patient_id: patientId,
          provider_id: providerId,
          session_id: crypto.randomUUID(),
          status: "signed",
          created_at: visit3Date.toISOString(),
          updated_at: new Date(
            visit3Date.getTime() + 20 * 60000
          ).toISOString(),
          signed_at: new Date(visit3Date.getTime() + 20 * 60000).toISOString(),
          signed_by: providerId,
        });

      if (soapNote3Error) {
        throw new Error(
          `Failed to create SOAP note 3: ${soapNote3Error.message}`
        );
      }

      // Add conditions for Visit 3 (new condition)
      await supabaseAdmin.from("soap_assessment_problem_list").insert([
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          diagnosis_name: "Type 2 Diabetes Mellitus",
          icd10_code: "E11.9",
          status: "active",
          severity: "moderate",
          notes: "Excellent control, HbA1c 6.5%",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          diagnosis_name: "Hypertension",
          icd10_code: "I10",
          status: "active",
          severity: "mild",
          notes: "BP now 135/85 mmHg - improved",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          diagnosis_name: "Hyperlipidemia",
          icd10_code: "E78.5",
          status: "active",
          severity: "mild",
          notes: "LDL within goal",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          diagnosis_name: "Chronic Kidney Disease Stage 3a",
          icd10_code: "N18.1",
          status: "active",
          severity: "mild",
          notes: "Stable eGFR 50 mL/min",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          diagnosis_name: "Anxiety Disorder",
          icd10_code: "F41.1",
          status: "active",
          severity: "mild",
          notes: "Starting therapy",
        },
      ]);

      // Add medications for Visit 3 (new medication)
      await supabaseAdmin.from("soap_plan_medication").insert([
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          name: "Metformin",
          dose: "500mg",
          route: "oral",
          frequency: "twice daily",
          status: "active",
          notes: "Continue",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          name: "Lisinopril",
          dose: "20mg",
          route: "oral",
          frequency: "once daily",
          status: "active",
          notes: "Continue",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          name: "Atorvastatin",
          dose: "20mg",
          route: "oral",
          frequency: "once daily at bedtime",
          status: "active",
          notes: "Continue",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          name: "Amlodipine",
          dose: "5mg",
          route: "oral",
          frequency: "once daily",
          status: "active",
          notes: "Continue",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          name: "Sertraline",
          dose: "50mg",
          route: "oral",
          frequency: "once daily",
          status: "active",
          notes: "New - for anxiety",
        },
      ]);

      // Add allergies for Visit 3 (escalated + new)
      await supabaseAdmin.from("soap_subjective_allergies").insert([
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          allergen: "Penicillin",
          reaction: "Severe rash and angioedema",
          severity: "severe",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          allergen: "Sulfonamides",
          reaction: "Nausea",
          severity: "mild",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          allergen: "NSAIDs",
          reaction: "GI upset",
          severity: "moderate",
        },
      ]);

      // Add vitals for Visit 3
      await supabaseAdmin.from("soap_objective_vital_signs").insert([
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          vital_name: "Temperature",
          vital_value: "98.5",
          unit: "°F",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          vital_name: "Blood Pressure Systolic",
          vital_value: "135",
          unit: "mmHg",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          vital_name: "Blood Pressure Diastolic",
          vital_value: "85",
          unit: "mmHg",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          vital_name: "Heart Rate",
          vital_value: "70",
          unit: "bpm",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          vital_name: "Weight",
          vital_value: "184",
          unit: "lbs",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          vital_name: "Height",
          vital_value: "70",
          unit: "inches",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          vital_name: "Blood Sugar (Fasting)",
          vital_value: "112",
          unit: "mg/dL",
        },
        {
          id: crypto.randomUUID(),
          soap_note_id: soapNote3Id,
          vital_name: "Oxygen Saturation",
          vital_value: "98",
          unit: "%",
        },
      ]);

      // Merge Visit 3 into cumulative record
      await supabaseAdmin.rpc("merge_soap_into_cumulative_record", {
        p_patient_id: patientId,
        p_soap_note_id: soapNote3Id,
        p_soap_data: {},
      });
    }

    // Fetch final patient profile to show results
    const { data: patientProfile } = await supabaseAdmin
      .from("patient_profiles")
      .select(
        "cumulative_medical_record, medical_record_last_updated_at, medical_record_last_soap_note_id"
      )
      .eq("user_id", patientId)
      .single();

    const cumulativeRecord = patientProfile?.cumulative_medical_record as any;

    return new Response(
      JSON.stringify({
        success: true,
        message: `Successfully created ${generateCount} medical records for demo patient`,
        patientId,
        soapNotesCreated: generateCount,
        conditionsCount: cumulativeRecord?.conditions?.length || 0,
        medicationsCount: cumulativeRecord?.medications?.length || 0,
        allergiesCount: cumulativeRecord?.allergies?.length || 0,
      } as GenerateRecordsResponse),
      {
        status: 200,
        headers: { "Content-Type": "application/json", ...corsHeaders, ...securityHeaders },
      }
    );
  } catch (error) {
    console.error("Error generating demo patient records:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : "Unknown error",
      } as GenerateRecordsResponse),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders, ...securityHeaders },
      }
    );
  }
});
