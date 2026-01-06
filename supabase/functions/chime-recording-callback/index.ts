import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { verifyAwsSignatureV4 } from "../_shared/aws-signature-v4.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface RecordingResult {
  meetingId: string;
  recordingUrl: string;
  recordingBucket: string;
  recordingKey: string;
  durationSeconds: number;
  fileSize: number;
  format: string;
  createdAt: string;
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
      console.error('[Recording Callback] Unauthorized webhook request - invalid AWS signature');
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse body after verification
    const body: RecordingResult = JSON.parse(bodyText);
    const {
      meetingId,
      recordingUrl,
      recordingBucket,
      recordingKey,
      durationSeconds,
      fileSize,
      format,
      createdAt
    } = body;

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

    // Update video call session with recording info
    const { error: updateError } = await supabase
      .from("video_call_sessions")
      .update({
        recording_url: recordingUrl,
        recording_bucket: recordingBucket,
        recording_key: recordingKey,
        recording_duration_seconds: durationSeconds,
        recording_file_size: fileSize,
        recording_format: format,
        recording_completed_at: createdAt,
        updated_at: new Date().toISOString(),
      })
      .eq("meeting_id", meetingId);

    if (updateError) {
      console.error("Error updating session with recording:", updateError);
      throw updateError;
    }

    // Log to audit trail
    await supabase.from("video_call_audit_log").insert({
      session_id: session.id,
      event_type: "RECORDING_COMPLETED",
      event_data: {
        bucket: recordingBucket,
        key: recordingKey,
        durationSeconds,
        fileSize,
        format,
      },
      created_at: new Date().toISOString(),
    });

    // Calculate retention date (7 years for HIPAA)
    const retentionDate = new Date();
    retentionDate.setFullYear(retentionDate.getFullYear() + 7);

    // Store recording metadata for compliance
    await supabase.from("medical_recording_metadata").insert({
      session_id: session.id,
      appointment_id: session.appointment_id,
      recording_bucket: recordingBucket,
      recording_key: recordingKey,
      duration_seconds: durationSeconds,
      file_size_bytes: fileSize,
      format,
      retention_until: retentionDate.toISOString(),
      encryption_type: "aws:kms",
      created_at: new Date().toISOString(),
    });

    return new Response(
      JSON.stringify({
        success: true,
        message: "Recording metadata stored",
        sessionId: session.id,
        retentionUntil: retentionDate.toISOString(),
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error processing recording callback:", error);
    return new Response(
      JSON.stringify({ error: error.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
