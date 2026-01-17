import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-firebase-token",
};

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
  // CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
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

    // Step 2: Get patient profile data
    const { data: patientProfile } = await supabase
      .from("patient_profiles")
      .select(
        `id,
         date_of_birth,
         gender,
         blood_type,
         allergies,
         emergency_contact,
         emergency_phone,
         medical_conditions,
         current_medications,
         surgical_history,
         family_history`
      )
      .eq("patient_id", patientId)
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

    // Parse medications (stored as JSON)
    const medications: Array<{ name: string; dosage: string; frequency: string }> =
      [];
    if (patientProfile?.current_medications) {
      try {
        const medsData =
          typeof patientProfile.current_medications === "string"
            ? JSON.parse(patientProfile.current_medications)
            : patientProfile.current_medications;
        if (Array.isArray(medsData)) {
          medsData.forEach((med: any) => {
            medications.push({
              name: med.name || med,
              dosage: med.dosage || "",
              frequency: med.frequency || "",
            });
          });
        }
      } catch (e) {
        console.error("Error parsing medications:", e);
      }
    }

    // Parse allergies (stored as array)
    const allergies: string[] = [];
    if (patientProfile?.allergies) {
      if (Array.isArray(patientProfile.allergies)) {
        allergies.push(...patientProfile.allergies);
      } else if (typeof patientProfile.allergies === "string") {
        allergies.push(patientProfile.allergies);
      }
    }

    // Parse medical conditions
    const medicalConditions: string[] = [];
    if (patientProfile?.medical_conditions) {
      if (Array.isArray(patientProfile.medical_conditions)) {
        medicalConditions.push(...patientProfile.medical_conditions);
      } else if (typeof patientProfile.medical_conditions === "string") {
        medicalConditions.push(patientProfile.medical_conditions);
      }
    }

    // Parse surgical history
    const surgicalHistory: string[] = [];
    if (patientProfile?.surgical_history) {
      if (Array.isArray(patientProfile.surgical_history)) {
        surgicalHistory.push(...patientProfile.surgical_history);
      } else if (typeof patientProfile.surgical_history === "string") {
        surgicalHistory.push(patientProfile.surgical_history);
      }
    }

    // Parse family history
    const familyHistory: string[] = [];
    if (patientProfile?.family_history) {
      if (Array.isArray(patientProfile.family_history)) {
        familyHistory.push(...patientProfile.family_history);
      } else if (typeof patientProfile.family_history === "string") {
        familyHistory.push(patientProfile.family_history);
      }
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
      headers: { "Content-Type": "application/json", ...corsHeaders },
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
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }
});
