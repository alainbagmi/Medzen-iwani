import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { verifyAwsSignatureV4 } from "../_shared/aws-signature-v4.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface MedicalEntity {
  id: string;
  text: string;
  category: string;
  type: string;
  score: number;
  beginOffset: number;
  endOffset: number;
  traits?: Array<{
    name: string;
    score: number;
  }>;
  attributes?: Array<{
    type: string;
    score: number;
    text: string;
    relationshipScore?: number;
  }>;
}

interface ICD10Code {
  code: string;
  description: string;
  score: number;
}

interface EntityExtractionResult {
  meetingId: string;
  entities: MedicalEntity[];
  icd10Codes: ICD10Code[];
  medications: Array<{
    name: string;
    rxNormId?: string;
    dosage?: string;
    frequency?: string;
  }>;
  processedAt: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Read body once for signature verification
    const bodyText = await req.text();

    // Verify AWS Signature V4
    const isValid = await verifyAwsSignatureV4(req, bodyText, 'eu-central-1');
    if (!isValid) {
      console.error('[Entity Extraction] Unauthorized webhook request - invalid AWS signature');
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse body after verification
    const body: EntityExtractionResult = JSON.parse(bodyText);
    const { meetingId, entities, icd10Codes, medications, processedAt } = body;

    if (!meetingId) {
      return new Response(
        JSON.stringify({ error: "meetingId is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get the video call session
    const { data: session, error: sessionError } = await supabase
      .from("video_call_sessions")
      .select("id, appointment_id")
      .eq("meeting_id", meetingId)
      .single();

    if (sessionError || !session) {
      return new Response(
        JSON.stringify({ error: "Session not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Categorize entities
    const categorizedEntities = {
      conditions: entities.filter(e => e.category === "MEDICAL_CONDITION"),
      medications: entities.filter(e => e.category === "MEDICATION"),
      anatomy: entities.filter(e => e.category === "ANATOMY"),
      tests: entities.filter(e => e.category === "TEST_TREATMENT_PROCEDURE"),
      protectedHealthInfo: entities.filter(e => e.category === "PROTECTED_HEALTH_INFORMATION"),
    };

    // Update video call session with medical entities
    const { error: updateError } = await supabase
      .from("video_call_sessions")
      .update({
        medical_entities: categorizedEntities,
        icd10_codes: icd10Codes,
        extracted_medications: medications,
        entity_extraction_completed_at: processedAt,
        updated_at: new Date().toISOString(),
      })
      .eq("meeting_id", meetingId);

    if (updateError) {
      console.error("Error updating session with entities:", updateError);
      throw updateError;
    }

    // Store detailed entities for medical records
    if (session.appointment_id) {
      // Get the appointment to find patient_id
      const { data: appointment } = await supabase
        .from("appointments")
        .select("patient_id, provider_id")
        .eq("id", session.appointment_id)
        .single();

      if (appointment) {
        // Store medical conditions for future reference
        for (const entity of categorizedEntities.conditions) {
          await supabase.from("consultation_medical_entities").insert({
            appointment_id: session.appointment_id,
            patient_id: appointment.patient_id,
            provider_id: appointment.provider_id,
            entity_type: "CONDITION",
            entity_text: entity.text,
            entity_category: entity.category,
            confidence_score: entity.score,
            icd10_code: icd10Codes.find(c =>
              entity.text.toLowerCase().includes(c.description.toLowerCase().split(" ")[0])
            )?.code,
            source: "CHIME_TRANSCRIPTION",
            created_at: new Date().toISOString(),
          });
        }

        // Store medications
        for (const med of medications) {
          await supabase.from("consultation_medical_entities").insert({
            appointment_id: session.appointment_id,
            patient_id: appointment.patient_id,
            provider_id: appointment.provider_id,
            entity_type: "MEDICATION",
            entity_text: med.name,
            entity_category: "MEDICATION",
            additional_data: {
              rxNormId: med.rxNormId,
              dosage: med.dosage,
              frequency: med.frequency,
            },
            source: "CHIME_TRANSCRIPTION",
            created_at: new Date().toISOString(),
          });
        }
      }
    }

    // Log to audit trail
    await supabase.from("video_call_audit_log").insert({
      session_id: session.id,
      event_type: "ENTITY_EXTRACTION_COMPLETED",
      event_data: {
        totalEntities: entities.length,
        conditionCount: categorizedEntities.conditions.length,
        medicationCount: medications.length,
        icd10Count: icd10Codes.length,
      },
      created_at: new Date().toISOString(),
    });

    return new Response(
      JSON.stringify({
        success: true,
        summary: {
          conditions: categorizedEntities.conditions.length,
          medications: medications.length,
          icd10Codes: icd10Codes.length,
          totalEntities: entities.length,
        },
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error processing entity extraction:", error);
    return new Response(
      JSON.stringify({ error: error.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
