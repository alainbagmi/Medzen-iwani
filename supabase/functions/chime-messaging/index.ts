import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";
import { checkRateLimit, getRateLimitConfig, createRateLimitErrorResponse } from "../_shared/rate-limiter.ts";

interface MessagingRequest {
  action: "createChannel" | "sendMessage" | "listMessages" | "listChannels" | "deleteChannel";
  channelId?: string;
  appointmentId?: string;
  message?: string;
  messageType?: "text" | "system" | "file";
  metadata?: Record<string, unknown>;
  limit?: number;
  nextToken?: string;
}

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const lambdaUrl = Deno.env.get("CHIME_MESSAGING_LAMBDA_URL")!;

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get user from auth header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
      );
    }

    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired token" }),
        { status: 401, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
      );
    }

    const body: MessagingRequest = await req.json();
    const { action, channelId, appointmentId, message, messageType, metadata, limit, nextToken } = body;

    if (!action) {
      return new Response(
        JSON.stringify({ error: "action is required" }),
        { status: 400, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
      );
    }

    // Build Lambda request
    const lambdaPayload: Record<string, unknown> = {
      action,
      userId: user.id,
      userEmail: user.email,
    };

    switch (action) {
      case "createChannel":
        if (!appointmentId) {
          return new Response(
            JSON.stringify({ error: "appointmentId is required for createChannel" }),
            { status: 400, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
          );
        }

        // Verify user is part of the appointment
        const { data: appointment, error: apptError } = await supabase
          .from("appointments")
          .select("id, provider_id, patient_id")
          .eq("id", appointmentId)
          .single();

        if (apptError || !appointment) {
          return new Response(
            JSON.stringify({ error: "Appointment not found" }),
            { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        if (appointment.provider_id !== user.id && appointment.patient_id !== user.id) {
          return new Response(
            JSON.stringify({ error: "Not authorized for this appointment" }),
            { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        lambdaPayload.appointmentId = appointmentId;
        lambdaPayload.providerId = appointment.provider_id;
        lambdaPayload.patientId = appointment.patient_id;
        break;

      case "sendMessage":
        if (!channelId || !message) {
          return new Response(
            JSON.stringify({ error: "channelId and message are required for sendMessage" }),
            { status: 400, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
          );
        }
        lambdaPayload.channelId = channelId;
        lambdaPayload.message = message;
        lambdaPayload.messageType = messageType || "text";
        if (metadata) lambdaPayload.metadata = metadata;
        break;

      case "listMessages":
        if (!channelId) {
          return new Response(
            JSON.stringify({ error: "channelId is required for listMessages" }),
            { status: 400, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
          );
        }
        lambdaPayload.channelId = channelId;
        lambdaPayload.limit = limit || 50;
        if (nextToken) lambdaPayload.nextToken = nextToken;
        break;

      case "listChannels":
        lambdaPayload.limit = limit || 20;
        if (nextToken) lambdaPayload.nextToken = nextToken;
        break;

      case "deleteChannel":
        if (!channelId) {
          return new Response(
            JSON.stringify({ error: "channelId is required for deleteChannel" }),
            { status: 400, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
          );
        }
        lambdaPayload.channelId = channelId;
        break;

      default:
        return new Response(
          JSON.stringify({ error: `Unknown action: ${action}` }),
          { status: 400, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
        );
    }

    // Call AWS Lambda
    const lambdaResponse = await fetch(lambdaUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(lambdaPayload),
    });

    const lambdaData = await lambdaResponse.json();

    if (!lambdaResponse.ok) {
      console.error("Lambda error:", lambdaData);
      return new Response(
        JSON.stringify({ error: lambdaData.error || "Messaging operation failed" }),
        { status: lambdaResponse.status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Store channel info in database if created
    if (action === "createChannel" && lambdaData.channelArn) {
      await supabase.from("chime_messaging_channels").upsert({
        channel_arn: lambdaData.channelArn,
        channel_id: lambdaData.channelId,
        appointment_id: appointmentId,
        provider_id: lambdaPayload.providerId,
        patient_id: lambdaPayload.patientId,
        created_by: user.id,
        created_at: new Date().toISOString(),
      });
    }

    // Store message in database for unlimited retention and querying
    if (action === "sendMessage" && lambdaData.messageId) {
      const timestamp = new Date().toISOString();

      // Store full message content in chime_messages table
      // Using both old and new column names for backward compatibility
      await supabase.from("chime_messages").insert({
        message_id: lambdaData.messageId,
        channel_arn: channelId,        // Old field (keep for compatibility)
        channel_id: channelId,          // New field (matches Lambda response)
        user_id: user.id,               // Old field (keep for compatibility)
        sender_id: user.id,             // New field (proper naming)
        message: message,               // Old field (keep for compatibility)
        message_content: message,       // New field (explicit naming)
        message_type: messageType || "text",  // New field
        metadata: metadata || {},
        created_at: timestamp,
      });

      // Also log to audit table for compliance tracking
      await supabase.from("chime_message_audit").insert({
        message_id: lambdaData.messageId,
        channel_id: channelId,
        sender_id: user.id,
        message_type: messageType || "text",
        created_at: timestamp,
      });
    }

    return new Response(
      JSON.stringify(lambdaData),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in chime-messaging:", error);
    return new Response(
      JSON.stringify({ error: error.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
