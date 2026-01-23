import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { CloudWatchClient, PutMetricDataCommand } from "npm:@aws-sdk/client-cloudwatch@3.716.0";
import { verifyAwsSignatureV4 } from "../_shared/aws-signature-v4.ts";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";

// CloudWatch client for metrics
const cloudWatchClient = new CloudWatchClient({
  region: Deno.env.get("AWS_REGION") || "eu-central-1",
  credentials: {
    accessKeyId: Deno.env.get("AWS_ACCESS_KEY_ID") || "",
    secretAccessKey: Deno.env.get("AWS_SECRET_ACCESS_KEY") || "",
  },
});

/**
 * Publish metrics to CloudWatch
 */
async function publishMetric(metricName: string, value: number, unit: string = "Count"): Promise<void> {
  try {
    await cloudWatchClient.send(new PutMetricDataCommand({
      Namespace: "medzen/Transcription",
      MetricData: [{
        MetricName: metricName,
        Value: value,
        Unit: unit as any,
        Timestamp: new Date(),
        Dimensions: [
          { Name: "Environment", Value: Deno.env.get("ENVIRONMENT") || "production" }
        ]
      }]
    }));
  } catch (error) {
    console.error("[Metrics] Failed to publish metric:", metricName, error);
  }
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Retry configuration
const MAX_RETRIES = 3;
const INITIAL_RETRY_DELAY_MS = 1000; // 1 second
const MAX_RETRY_DELAY_MS = 10000; // 10 seconds

interface TranscriptionResult {
  meetingId: string;
  transcriptionJobName: string;
  status: "COMPLETED" | "FAILED";
  transcriptUri?: string;
  transcript?: string;
  speakers?: Array<{
    speakerId: string;
    segments: Array<{
      startTime: number;
      endTime: number;
      content: string;
    }>;
  }>;
}

/**
 * Retry a function with exponential backoff
 * @param fn Function to retry
 * @param retries Number of retries
 * @param delay Initial delay in ms
 * @returns Result of the function
 */
async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  retries: number = MAX_RETRIES,
  delay: number = INITIAL_RETRY_DELAY_MS
): Promise<T> {
  try {
    return await fn();
  } catch (error) {
    if (retries <= 0) {
      throw error;
    }

    console.log(`[Transcription Callback] Retry attempt, ${retries} retries left. Waiting ${delay}ms...`);

    // Wait with exponential backoff
    await new Promise(resolve => setTimeout(resolve, delay));

    // Exponential backoff with jitter, capped at MAX_RETRY_DELAY_MS
    const nextDelay = Math.min(delay * 2 + Math.random() * 1000, MAX_RETRY_DELAY_MS);

    return retryWithBackoff(fn, retries - 1, nextDelay);
  }
}

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders_dynamic = getCorsHeaders(origin);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders_dynamic, ...securityHeaders } });
  }

  try {
    // Read body once for signature verification
    const bodyText = await req.text();

    // Verify AWS Signature V4
    const isValid = await verifyAwsSignatureV4(req, bodyText, 'eu-central-1');
    if (!isValid) {
      console.error('[Transcription Callback] Unauthorized webhook request - invalid AWS signature');
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders_dynamic, ...securityHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse body after verification
    const body: TranscriptionResult = JSON.parse(bodyText);
    const { meetingId, transcriptionJobName, status, transcript, speakers } = body;

    if (!meetingId) {
      return new Response(
        JSON.stringify({ error: "meetingId is required" }),
        { status: 400, headers: { ...corsHeaders_dynamic, ...securityHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get the video call session
    const { data: session, error: sessionError } = await supabase
      .from("video_call_sessions")
      .select("id, appointment_id")
      .eq("meeting_id", meetingId)
      .single();

    if (sessionError || !session) {
      console.error("Session not found:", sessionError);
      return new Response(
        JSON.stringify({ error: "Session not found" }),
        { status: 404, headers: { ...corsHeaders_dynamic, ...securityHeaders, "Content-Type": "application/json" } }
      );
    }

    // Update video call session with transcription data
    const updateData: Record<string, any> = {
      transcription_job_name: transcriptionJobName,
      transcription_status: status,
      updated_at: new Date().toISOString(),
    };

    if (status === "COMPLETED" && transcript) {
      updateData.transcript = transcript;
      updateData.speaker_segments = speakers || [];
    }

    // Update with retry logic for resilience
    await retryWithBackoff(async () => {
      const { error: updateError } = await supabase
        .from("video_call_sessions")
        .update(updateData)
        .eq("meeting_id", meetingId);

      if (updateError) {
        console.error("[Transcription Callback] Error updating session:", updateError);
        throw updateError;
      }
    });

    console.log(`[Transcription Callback] Successfully updated session for meeting ${meetingId}`);

    // Publish metrics based on status
    if (status === "COMPLETED") {
      await publishMetric("SuccessfulJobs", 1);
      await publishMetric("InProgressJobs", -1);
    } else if (status === "FAILED") {
      await publishMetric("FailedJobs", 1);
      await publishMetric("InProgressJobs", -1);
    }

    // Log to audit trail with retry
    await retryWithBackoff(async () => {
      const { error: auditError } = await supabase.from("video_call_audit_log").insert({
        session_id: session.id,
        event_type: "TRANSCRIPTION_" + status,
        event_data: {
          jobName: transcriptionJobName,
          status,
          hasTranscript: !!transcript,
          speakerCount: speakers?.length || 0,
        },
        created_at: new Date().toISOString(),
      });

      if (auditError) {
        console.error("[Transcription Callback] Error inserting audit log:", auditError);
        throw auditError;
      }
    });

    console.log(`[Transcription Callback] Audit log recorded for session ${session.id}`);

    return new Response(
      JSON.stringify({
        success: true,
        message: `Transcription ${status.toLowerCase()}`,
        sessionId: session.id,
      }),
      { status: 200, headers: { ...corsHeaders_dynamic, ...securityHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error processing transcription callback:", error);

    // Publish error metric
    await publishMetric("CallbackErrors", 1);

    return new Response(
      JSON.stringify({ error: error.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders_dynamic, ...securityHeaders, "Content-Type": "application/json" } }
    );
  }
});
