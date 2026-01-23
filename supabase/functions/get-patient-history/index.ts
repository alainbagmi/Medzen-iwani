import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

interface PatientHistoryRequest {
  patientId: string;
  appointmentId?: string;
}

interface PatientHistoryResponse {
  success: boolean;
  hasHistory: boolean;
  patientData?: {
    // From users table
    userId: string;
    firstName: string;
    lastName: string;
    fullName: string;
    email: string;
    phone: string;
    profileImageUrl?: string;

    // From patient_profiles table
    dateOfBirth: string;
    age: number;
    gender: string;
    bloodType: string;
    allergies: string[];
    emergencyContact?: string;
    emergencyPhone?: string;

    // Medical history
    medicalConditions: string[];
    currentMedications: Array<{ name: string; dosage: string; frequency: string }>;
    surgicalHistory: string[];
    familyHistory: string[];

    // Recent vitals from past visits
    recentVitals?: {
      lastVisitDate: string;
      temperature?: number;
      bloodPressure?: string;
      heartRate?: number;
      respiratoryRate?: number;
      oxygenSaturation?: number;
      weight?: number;
      height?: number;
    };

    // Appointment context
    appointmentDate?: string;
    chiefComplaint?: string;
  };
  pastNotes?: Array<{
    date: string;
    assessment: string;
    plan: string;
    provider: string;
  }>;
  error?: string;
}

serve(async (req: Request): Promise<Response> => {
  const origin = req.headers.get("origin");
  const corsHeaders_resp = getCorsHeaders(origin);

  // CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders_resp, ...securityHeaders } });
  }

  try {
    const { patientId, appointmentId } = (await req.json()) as PatientHistoryRequest;

    if (!patientId) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "patientId is required",
        } as PatientHistoryResponse),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // Step 1: Get user data
    const { data: userData, error: userError } = await supabase
      .from("users")
      .select("id, firebase_uid, email, phone, first_name, last_name, profile_image_url")
      .eq("id", patientId)
      .single();

    if (userError || !userData) {
      return new Response(
        JSON.stringify({
          success: false,
          hasHistory: false,
          error: `Patient not found: ${userError?.message}`,
        } as PatientHistoryResponse),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    // Step 2: Get patient profile data including cumulative medical record
    const { data: patientProfile } = await supabase
      .from("patient_profiles")
      .select(
        `id,
         date_of_birth,
         gender,
         blood_type,
         emergency_contact,
         emergency_phone,
         cumulative_medical_record,
         medical_record_last_updated_at`
      )
      .eq("user_id", patientId)
      .single();

    // Step 3: Get appointment details if appointmentId provided
    let appointmentData = null;
    if (appointmentId) {
      const { data: apt } = await supabase
        .from("appointments")
        .select("appointment_date, chief_complaint")
        .eq("id", appointmentId)
        .single();
      appointmentData = apt;
    }

    // Step 4: Get past clinical notes (last 5 visits)
    const { data: pastNotes } = await supabase
      .from("clinical_notes")
      .select(
        `created_at,
         assessment_impression,
         plan_treatments,
         provider_name`
      )
      .eq("patient_id", patientId)
      .eq("is_draft", false)
      .order("created_at", { ascending: false })
      .limit(5);

    // Step 5: Get recent vitals from past visit (last clinical note)
    const { data: recentNote } = await supabase
      .from("clinical_notes")
      .select(
        `created_at,
         section_3_vitals_temperature,
         section_3_vitals_systolic_bp,
         section_3_vitals_diastolic_bp,
         section_3_vitals_heart_rate,
         section_3_vitals_respiratory_rate,
         section_3_vitals_oxygen_saturation,
         section_3_vitals_weight,
         section_3_vitals_height`
      )
      .eq("patient_id", patientId)
      .eq("is_draft", false)
      .order("created_at", { ascending: false })
      .limit(1)
      .single();

    // Calculate age
    const today = new Date();
    const birthDate = patientProfile?.date_of_birth
      ? new Date(patientProfile.date_of_birth)
      : null;
    let age = 0;
    if (birthDate) {
      age = today.getFullYear() - birthDate.getFullYear();
      const monthDiff = today.getMonth() - birthDate.getMonth();
      if (
        monthDiff < 0 ||
        (monthDiff === 0 && today.getDate() < birthDate.getDate())
      ) {
        age--;
      }
    }

    // Extract from cumulative medical record (JSONB)
    const cumulativeRecord = patientProfile?.cumulative_medical_record as any || {
      conditions: [],
      medications: [],
      allergies: [],
      surgical_history: [],
      family_history: [],
      metadata: { total_visits: 0 }
    };

    // Parse medications from cumulative record (active only)
    const medications: Array<{ name: string; dosage: string; frequency: string }> = [];
    if (cumulativeRecord?.medications && Array.isArray(cumulativeRecord.medications)) {
      cumulativeRecord.medications
        .filter((med: any) => med.status === "active" || !med.status)
        .forEach((med: any) => {
          medications.push({
            name: med.name || "",
            dosage: med.dose || "",
            frequency: med.frequency || "",
          });
        });
    }

    // Parse allergies from cumulative record
    const allergies: string[] = [];
    if (cumulativeRecord?.allergies && Array.isArray(cumulativeRecord.allergies)) {
      cumulativeRecord.allergies.forEach((allergy: any) => {
        const allergenStr = `${allergy.allergen || "Unknown"}${
          allergy.severity ? ` (${allergy.severity})` : ""
        }`;
        allergies.push(allergenStr);
      });
    }

    // Parse medical conditions from cumulative record (active only)
    const medicalConditions: string[] = [];
    if (cumulativeRecord?.conditions && Array.isArray(cumulativeRecord.conditions)) {
      cumulativeRecord.conditions
        .filter((cond: any) => cond.status === "active" || !cond.status)
        .forEach((cond: any) => {
          const condStr = `${cond.name || "Unknown"}${
            cond.icd10 ? ` (${cond.icd10})` : ""
          }`;
          medicalConditions.push(condStr);
        });
    }

    // Parse surgical history from cumulative record
    const surgicalHistory: string[] = [];
    if (cumulativeRecord?.surgical_history && Array.isArray(cumulativeRecord.surgical_history)) {
      cumulativeRecord.surgical_history.forEach((surgery: any) => {
        const surgStr = typeof surgery === "string" ? surgery : surgery.name || surgery.description || JSON.stringify(surgery);
        surgicalHistory.push(surgStr);
      });
    }

    // Parse family history from cumulative record
    const familyHistory: string[] = [];
    if (cumulativeRecord?.family_history && Array.isArray(cumulativeRecord.family_history)) {
      cumulativeRecord.family_history.forEach((family: any) => {
        const familyStr = typeof family === "string" ? family : family.condition || family.name || JSON.stringify(family);
        familyHistory.push(familyStr);
      });
    }

    // Build response
    const hasHistory = medications.length > 0 || allergies.length > 0 ||
                       medicalConditions.length > 0 || surgicalHistory.length > 0;

    const response: PatientHistoryResponse = {
      success: true,
      hasHistory,
      patientData: {
        userId: userData.id,
        firstName: userData.first_name || "",
        lastName: userData.last_name || "",
        fullName: `${userData.first_name || ""} ${userData.last_name || ""}`.trim(),
        email: userData.email || "",
        phone: userData.phone || "",
        profileImageUrl: userData.profile_image_url,
        dateOfBirth: patientProfile?.date_of_birth || "",
        age,
        gender: patientProfile?.gender || "",
        bloodType: patientProfile?.blood_type || "",
        allergies,
        emergencyContact: patientProfile?.emergency_contact,
        emergencyPhone: patientProfile?.emergency_phone,
        medicalConditions,
        currentMedications: medications,
        surgicalHistory,
        familyHistory,
        appointmentDate: appointmentData?.appointment_date,
        chiefComplaint: appointmentData?.chief_complaint,
        recentVitals: recentNote
          ? {
              lastVisitDate: recentNote.created_at,
              temperature: recentNote.section_3_vitals_temperature,
              bloodPressure: recentNote.section_3_vitals_systolic_bp
                ? `${recentNote.section_3_vitals_systolic_bp}/${recentNote.section_3_vitals_diastolic_bp}`
                : undefined,
              heartRate: recentNote.section_3_vitals_heart_rate,
              respiratoryRate: recentNote.section_3_vitals_respiratory_rate,
              oxygenSaturation: recentNote.section_3_vitals_oxygen_saturation,
              weight: recentNote.section_3_vitals_weight,
              height: recentNote.section_3_vitals_height,
            }
          : undefined,
      },
      pastNotes: pastNotes
        ? pastNotes.map((note: any) => ({
            date: note.created_at,
            assessment: note.assessment_impression || "",
            plan: note.plan_treatments || "",
            provider: note.provider_name || "",
          }))
        : [],
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { "Content-Type": "application/json", ...corsHeaders_resp, ...securityHeaders },
    });
  } catch (error) {
    console.error("Error in get-patient-history:", error);
    return new Response(
      JSON.stringify({
        success: false,
        hasHistory: false,
        error: error instanceof Error ? error.message : "Unknown error",
      } as PatientHistoryResponse),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders_resp, ...securityHeaders },
      }
    );
  }
});
