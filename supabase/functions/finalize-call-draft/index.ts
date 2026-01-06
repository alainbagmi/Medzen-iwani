/**
 * finalize-call-draft Edge Function
 *
 * Compiles a draft clinical note from the video call transcript and chat messages.
 * Only the provider can finalize the draft. The draft includes:
 * - Clinical note template (SOAP-style)
 * - Transcript appendix (speaker-tagged)
 * - Chat appendix (including attachments)
 *
 * @author MedZen AI Team
 * @version 1.0.0
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { verifyFirebaseToken } from "../_shared/verify-firebase-jwt.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-firebase-token",
};

interface FinalizeRequest {
  session_id: string;
}

/**
 * Generates a clinical note template based on language
 */
function generateClinicalTemplate(
  language: string,
  appointmentId: string
): string[] {
  const isFr = language.startsWith("fr");

  if (isFr) {
    return [
      "═══════════════════════════════════════════════════════════════════",
      "                    NOTE CLINIQUE (BROUILLON)",
      "═══════════════════════════════════════════════════════════════════",
      "",
      `Rendez-vous/Consultation: ${appointmentId}`,
      `Langue: ${language}`,
      `Date: ${new Date().toISOString().split("T")[0]}`,
      "",
      "───────────────────────────────────────────────────────────────────",
      "1) MOTIF DE CONSULTATION (CC)",
      "───────────────────────────────────────────────────────────────────",
      "- [À compléter par le prestataire]",
      "",
      "───────────────────────────────────────────────────────────────────",
      "2) HISTOIRE DE LA MALADIE ACTUELLE (HMA)",
      "───────────────────────────────────────────────────────────────────",
      "- Début: [ ]",
      "- Durée: [ ]",
      "- Sévérité: [ ]",
      "- Symptômes associés: [ ]",
      "",
      "───────────────────────────────────────────────────────────────────",
      "3) REVUE DES SYSTÈMES (ROS)",
      "───────────────────────────────────────────────────────────────────",
      "- Général: [ ]",
      "- Cardiovasculaire: [ ]",
      "- Respiratoire: [ ]",
      "- Digestif: [ ]",
      "- Neurologique: [ ]",
      "",
      "───────────────────────────────────────────────────────────────────",
      "4) ANTÉCÉDENTS",
      "───────────────────────────────────────────────────────────────────",
      "- Antécédents médicaux: [ ]",
      "- Antécédents chirurgicaux: [ ]",
      "- Médicaments actuels: [ ]",
      "- Allergies: [ ]",
      "- Histoire familiale: [ ]",
      "- Histoire sociale: [ ]",
      "",
      "───────────────────────────────────────────────────────────────────",
      "5) EXAMEN OBJECTIF",
      "───────────────────────────────────────────────────────────────────",
      "- Signes vitaux: [ ]",
      "- Examen clinique: [ ]",
      "",
      "───────────────────────────────────────────────────────────────────",
      "6) ÉVALUATION",
      "───────────────────────────────────────────────────────────────────",
      "- Diagnostic principal: [ ]",
      "- Diagnostics différentiels: [ ]",
      "",
      "───────────────────────────────────────────────────────────────────",
      "7) PLAN",
      "───────────────────────────────────────────────────────────────────",
      "- Médicaments: [ ]",
      "- Examens (laboratoire/imagerie): [ ]",
      "- Références: [ ]",
      "- Suivi: [ ]",
      "",
      "═══════════════════════════════════════════════════════════════════",
      "                    ANNEXE: TRANSCRIPTION",
      "═══════════════════════════════════════════════════════════════════",
      "",
    ];
  }

  return [
    "═══════════════════════════════════════════════════════════════════",
    "                 CLINICAL ENCOUNTER NOTE (DRAFT)",
    "═══════════════════════════════════════════════════════════════════",
    "",
    `Appointment/Encounter: ${appointmentId}`,
    `Language: ${language}`,
    `Date: ${new Date().toISOString().split("T")[0]}`,
    "",
    "───────────────────────────────────────────────────────────────────",
    "1) CHIEF COMPLAINT (CC)",
    "───────────────────────────────────────────────────────────────────",
    "- [To be completed by provider]",
    "",
    "───────────────────────────────────────────────────────────────────",
    "2) HISTORY OF PRESENT ILLNESS (HPI)",
    "───────────────────────────────────────────────────────────────────",
    "- Onset: [ ]",
    "- Duration: [ ]",
    "- Severity: [ ]",
    "- Associated symptoms: [ ]",
    "",
    "───────────────────────────────────────────────────────────────────",
    "3) REVIEW OF SYSTEMS (ROS)",
    "───────────────────────────────────────────────────────────────────",
    "- General: [ ]",
    "- Cardiovascular: [ ]",
    "- Respiratory: [ ]",
    "- GI: [ ]",
    "- Neurological: [ ]",
    "",
    "───────────────────────────────────────────────────────────────────",
    "4) PAST HISTORY",
    "───────────────────────────────────────────────────────────────────",
    "- PMH: [ ]",
    "- PSH: [ ]",
    "- Current Medications: [ ]",
    "- Allergies: [ ]",
    "- Family History: [ ]",
    "- Social History: [ ]",
    "",
    "───────────────────────────────────────────────────────────────────",
    "5) OBJECTIVE",
    "───────────────────────────────────────────────────────────────────",
    "- Vitals: [ ]",
    "- Exam findings: [ ]",
    "",
    "───────────────────────────────────────────────────────────────────",
    "6) ASSESSMENT",
    "───────────────────────────────────────────────────────────────────",
    "- Working diagnosis: [ ]",
    "- Differentials: [ ]",
    "",
    "───────────────────────────────────────────────────────────────────",
    "7) PLAN",
    "───────────────────────────────────────────────────────────────────",
    "- Medications: [ ]",
    "- Labs/Imaging: [ ]",
    "- Referrals: [ ]",
    "- Follow-up: [ ]",
    "",
    "═══════════════════════════════════════════════════════════════════",
    "                    APPENDIX: TRANSCRIPT",
    "═══════════════════════════════════════════════════════════════════",
    "",
  ];
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("=== Finalize Call Draft Request ===");

    // Get Firebase token from custom header
    const firebaseTokenHeader =
      req.headers.get("x-firebase-token") ||
      req.headers.get("X-Firebase-Token");

    if (!firebaseTokenHeader) {
      return new Response(
        JSON.stringify({ error: "Missing x-firebase-token header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // Verify Firebase JWT token
    let userId: string;

    try {
      const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID");
      if (!firebaseProjectId) {
        throw new Error("FIREBASE_PROJECT_ID not configured");
      }

      const payload = await verifyFirebaseToken(
        firebaseTokenHeader,
        firebaseProjectId
      );
      const firebaseUid = payload.user_id || payload.sub;

      if (!firebaseUid) {
        throw new Error("No user ID in verified token");
      }

      // Look up user in Supabase
      const { data: userData, error: userError } = await supabaseAdmin
        .from("users")
        .select("id, role")
        .eq("firebase_uid", firebaseUid)
        .single();

      if (userError || !userData) {
        throw new Error("User not found in database");
      }

      userId = userData.id;
      console.log("Auth Success - User:", userId, "Role:", userData.role);
    } catch (error) {
      console.error("Auth Error:", error);
      return new Response(
        JSON.stringify({
          error: "Invalid or expired token",
          details: error.message,
        }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const body: FinalizeRequest = await req.json();
    const { session_id } = body;

    if (!session_id) {
      return new Response(JSON.stringify({ error: "Missing session_id" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log(`Finalizing draft for session ${session_id}`);

    // Get the video call session
    const { data: session, error: sessionError } = await supabaseAdmin
      .from("video_call_sessions")
      .select("*, appointments(id, patient_id, provider_id)")
      .eq("id", session_id)
      .single();

    if (sessionError || !session) {
      console.error("Session not found:", session_id);
      return new Response(JSON.stringify({ error: "Session not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get appointment details with provider info
    const { data: appointment, error: appointmentError } = await supabaseAdmin
      .from("appointments")
      .select(`
        id,
        patient_id,
        provider_id,
        medical_provider_profiles!appointments_provider_id_fkey(
          user_id
        )
      `)
      .eq("id", session.appointment_id)
      .single();

    if (appointmentError || !appointment) {
      console.error("Appointment not found");
      return new Response(JSON.stringify({ error: "Appointment not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Extract provider's user_id
    const providerProfile = appointment.medical_provider_profiles as {
      user_id: string;
    } | null;
    const providerUserId = providerProfile?.user_id;

    // Only provider can finalize draft
    if (providerUserId !== userId) {
      console.log(`User ${userId} is not the provider for this session`);
      return new Response(
        JSON.stringify({ error: "Only the provider can finalize the draft" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get transcript segments
    const { data: segments, error: segmentsError } = await supabaseAdmin
      .from("live_caption_segments")
      .select("*")
      .eq("session_id", session_id)
      .eq("is_partial", false)
      .order("created_at", { ascending: true });

    if (segmentsError) {
      console.error("Error fetching segments:", segmentsError);
    }

    // Get chat messages
    const { data: messages, error: messagesError } = await supabaseAdmin
      .from("chime_messages")
      .select("*")
      .eq("appointment_id", session.appointment_id)
      .order("created_at", { ascending: true });

    if (messagesError) {
      console.error("Error fetching messages:", messagesError);
    }

    // Get language from session
    const language = session.transcription_language || session.language_code || "en-US";

    // Generate clinical template
    const template = generateClinicalTemplate(language, session.appointment_id);

    // Format transcript lines
    const transcriptLines = (segments || [])
      .map((s: Record<string, unknown>) => {
        const speaker = s.speaker_name || "Unknown";
        const text = String(s.transcript_text || "").trim();
        if (text.length < 3) return null;
        return `  [${speaker}]: ${text}`;
      })
      .filter((x: string | null) => x !== null);

    // Format chat lines
    const isFr = language.startsWith("fr");
    const chatHeader = isFr
      ? [
          "",
          "═══════════════════════════════════════════════════════════════════",
          "                    ANNEXE: JOURNAL DE MESSAGES",
          "═══════════════════════════════════════════════════════════════════",
          "",
        ]
      : [
          "",
          "═══════════════════════════════════════════════════════════════════",
          "                    APPENDIX: CHAT LOG",
          "═══════════════════════════════════════════════════════════════════",
          "",
        ];

    const chatLines = (messages || []).map((m: Record<string, unknown>) => {
      const sender = m.sender_role === "patient" ? "Patient" : "Provider";
      if (m.message_type === "file") {
        return `  [${sender}] ${isFr ? "a partagé" : "shared"}: ${m.file_name || "attachment"}`;
      }
      return `  [${sender}]: ${m.message_content || m.message || ""}`;
    });

    // Provider attestation
    const attestation = isFr
      ? [
          "",
          "═══════════════════════════════════════════════════════════════════",
          "                    ATTESTATION DU PRESTATAIRE",
          "═══════════════════════════════════════════════════════════════════",
          "",
          "J'ai relu et modifié ce brouillon avant validation.",
          "",
          "Signature: __________________  Date: ____________",
          "",
        ]
      : [
          "",
          "═══════════════════════════════════════════════════════════════════",
          "                    PROVIDER ATTESTATION",
          "═══════════════════════════════════════════════════════════════════",
          "",
          "I have reviewed and edited this draft before submission.",
          "",
          "Signature: __________________  Date: ____________",
          "",
        ];

    // Combine all sections
    const draftText = [
      ...template,
      ...(transcriptLines.length > 0
        ? transcriptLines
        : [isFr ? "  (Aucune transcription disponible)" : "  (No transcript available)"]),
      ...chatHeader,
      ...(chatLines.length > 0
        ? chatLines
        : [isFr ? "  (Aucun message)" : "  (No messages)"]),
      ...attestation,
    ].join("\n");

    // Insert draft into consultation_note_drafts
    const { data: draft, error: insertError } = await supabaseAdmin
      .from("consultation_note_drafts")
      .insert({
        appointment_id: session.appointment_id,
        session_id,
        created_by: userId,
        source: "chime_live",
        language_code: language,
        draft_text: draftText,
        status: "editing",
      })
      .select("*")
      .single();

    if (insertError) {
      console.error("Error inserting draft:", insertError);
      return new Response(
        JSON.stringify({
          error: "Failed to create draft",
          details: insertError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`Draft created: ${draft.id}`);

    // Mark session as ended if still active
    if (session.status === "active") {
      await supabaseAdmin
        .from("video_call_sessions")
        .update({
          status: "ended",
          ended_at: new Date().toISOString(),
          ended_by: userId,
          is_call_active: false,
        })
        .eq("id", session_id);
    }

    return new Response(
      JSON.stringify({
        draft_id: draft.id,
        appointment_id: session.appointment_id,
        transcript_segments: segments?.length || 0,
        chat_messages: messages?.length || 0,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({
        error: error.message || "Internal server error",
        details: error.stack,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
