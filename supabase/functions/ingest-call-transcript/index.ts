/**
 * ingest-call-transcript Edge Function
 *
 * Ingests live transcript segments from the Chime SDK WebView.
 * Called by the Flutter app as transcript segments become available.
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

interface TranscriptSegment {
  speaker_external_id: string;
  is_partial: boolean;
  start_time_ms?: number | null;
  end_time_ms?: number | null;
  text: string;
  raw?: unknown;
}

interface IngestRequest {
  session_id: string;
  segments: TranscriptSegment[];
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("=== Ingest Call Transcript Request ===");

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
        .select("id")
        .eq("firebase_uid", firebaseUid)
        .single();

      if (userError || !userData) {
        throw new Error("User not found in database");
      }

      userId = userData.id;
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
    const body: IngestRequest = await req.json();
    const { session_id, segments } = body;

    // Validate required fields
    if (!session_id || !segments || !Array.isArray(segments)) {
      return new Response(
        JSON.stringify({ error: "Missing session_id or segments" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(
      `Ingesting ${segments.length} transcript segments for session ${session_id}`
    );

    // Get the video call session to verify authorization
    const { data: session, error: sessionError } = await supabaseAdmin
      .from("video_call_sessions")
      .select("id, provider_id, patient_id, appointment_id")
      .eq("id", session_id)
      .single();

    if (sessionError || !session) {
      console.error("Session not found:", session_id);
      return new Response(JSON.stringify({ error: "Session not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify user is a participant (provider or patient)
    // Note: session.provider_id might be medical_provider_profiles.id, so we need to check both
    const { data: appointment, error: appointmentError } = await supabaseAdmin
      .from("appointments")
      .select(`
        id,
        patient_id,
        medical_provider_profiles!appointments_provider_id_fkey(
          user_id
        )
      `)
      .eq("id", session.appointment_id)
      .single();

    if (appointmentError || !appointment) {
      console.error("Appointment not found for session");
      return new Response(JSON.stringify({ error: "Appointment not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const providerProfile = appointment.medical_provider_profiles as {
      user_id: string;
    } | null;
    const providerUserId = providerProfile?.user_id;

    if (appointment.patient_id !== userId && providerUserId !== userId) {
      console.log(`User ${userId} is not a participant in session ${session_id}`);
      return new Response(
        JSON.stringify({ error: "Not authorized to ingest transcripts" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Filter out partial segments (only store final results)
    const finalSegments = segments.filter((s) => !s.is_partial);

    if (finalSegments.length === 0) {
      return new Response(
        JSON.stringify({ ok: true, inserted: 0, message: "No final segments to insert" }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse speaker external ID to get role
    // Format: "role:userId" (e.g., "medical_provider:abc-123" or "patient:xyz-456")
    const parseSpeaker = (externalId: string) => {
      const parts = externalId.split(":");
      const role = parts[0] || "unknown";
      const speakerId = parts[1] || externalId;

      // Determine display name based on role
      let speakerName = "Unknown";
      if (role === "medical_provider" || role === "provider") {
        speakerName = "Provider";
      } else if (role === "patient") {
        speakerName = "Patient";
      }

      return { role, speakerId, speakerName };
    };

    // Prepare records for insertion
    const records = finalSegments.map((segment) => {
      const { speakerName } = parseSpeaker(segment.speaker_external_id);

      return {
        session_id,
        attendee_id: segment.speaker_external_id,
        speaker_name: speakerName,
        transcript_text: segment.text || "",
        is_partial: false,
        start_time_ms: segment.start_time_ms,
        language_code: null, // Can be enhanced later
        confidence: null,
      };
    });

    // Insert into live_caption_segments table
    const { data: insertedRecords, error: insertError } = await supabaseAdmin
      .from("live_caption_segments")
      .insert(records)
      .select("id");

    if (insertError) {
      console.error("Insert error:", insertError);
      return new Response(
        JSON.stringify({
          error: "Failed to insert transcript segments",
          details: insertError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const insertedCount = insertedRecords?.length || 0;
    console.log(`Inserted ${insertedCount} transcript segments`);

    return new Response(
      JSON.stringify({
        ok: true,
        inserted: insertedCount,
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
