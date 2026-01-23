import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY",
        }),
        { status: 500, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Generate UUIDs for test data
    const crypto = await import("https://deno.land/std@0.168.0/node/crypto.ts");
    const generateUUID = () => {
      const uuid = crypto.randomUUID();
      return uuid;
    };

    const providerId = generateUUID();
    const patientId = generateUUID();
    const sessionId = generateUUID();
    const appointmentId = generateUUID();
    const transcriptId = generateUUID();

    // Insert provider user
    const { data: providerData, error: providerError } = await supabase
      .from("users")
      .insert({
        id: providerId,
        firebase_uid: `provider-test-${Date.now()}`,
        email: `dr.smith.${Date.now()}@test.com`,
        name: "Dr. Smith",
        user_role: "medical_provider",
      })
      .select();

    if (providerError) {
      console.error("Provider creation error:", providerError);
      throw new Error(`Provider creation failed: ${JSON.stringify(providerError)}`);
    }

    // Insert patient user
    const { data: patientData, error: patientError } = await supabase
      .from("users")
      .insert({
        id: patientId,
        firebase_uid: `patient-test-${Date.now()}`,
        email: `john.doe.${Date.now()}@test.com`,
        name: "John Doe",
        user_role: "patient",
      })
      .select();

    if (patientError) {
      console.error("Patient creation error:", patientError);
      throw new Error(`Patient creation failed: ${JSON.stringify(patientError)}`);
    }

    // Insert appointment
    const { data: appointmentData, error: appointmentError } = await supabase
      .from("appointments")
      .insert({
        id: appointmentId,
        provider_id: providerId,
        patient_id: patientId,
        scheduled_time: new Date().toISOString(),
        appointment_status: "completed",
        chief_complaint: "Persistent headaches",
        notes: "Test appointment for SOAP generation",
      })
      .select();

    if (appointmentError) {
      console.error("Appointment creation error:", appointmentError);
      throw new Error(`Appointment creation failed: ${JSON.stringify(appointmentError)}`);
    }

    // Insert video call session
    const { data: sessionData, error: sessionError } = await supabase
      .from("video_call_sessions")
      .insert({
        id: sessionId,
        appointment_id: appointmentId,
        provider_id: providerId,
        patient_id: patientId,
        session_status: "completed",
        started_at: new Date().toISOString(),
        ended_at: new Date(Date.now() + 30 * 60000).toISOString(),
        call_duration: 1800,
        transcription_status: "completed",
        has_recording: false,
      })
      .select();

    if (sessionError) {
      console.error("Session creation error:", sessionError);
      throw new Error(`Session creation failed: ${JSON.stringify(sessionError)}`);
    }

    // Insert call transcripts record
    const { data: transcriptData, error: transcriptError } = await supabase
      .from("call_transcripts")
      .insert({
        id: transcriptId,
        session_id: sessionId,
        appointment_id: appointmentId,
        meeting_id: `chime-meeting-${Date.now()}`,
        type: "live_merged",
        source: "chime_live",
        raw_text:
          "Provider: Good morning, what brings you in today? Patient: Hi doctor, I've been having persistent headaches for a week now. Provider: How would you rate the pain on a scale of 1-10? Patient: About 7. Provider: Let me examine your head and neck. I notice some muscle tension. Have you been under stress? Patient: Yes, work has been very stressful. Provider: I'll prescribe ibuprofen for now and suggest relaxation techniques.",
        language_code: "en-US",
        processing_status: "completed",
        start_time: new Date().toISOString(),
        end_time: new Date(Date.now() + 30 * 60000).toISOString(),
        duration_seconds: 1800,
      })
      .select();

    if (transcriptError) {
      console.error("Transcript creation error:", transcriptError);
      throw new Error(`Transcript creation failed: ${JSON.stringify(transcriptError)}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Test data created successfully",
        data: {
          providerId,
          patientId,
          sessionId,
          appointmentId,
          transcriptId,
          provider: providerData,
          patient: patientData,
          appointment: appointmentData,
          session: sessionData,
          transcript: transcriptData,
        },
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error creating test data:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
