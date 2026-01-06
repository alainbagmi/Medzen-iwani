/**
 * call-send-message Edge Function
 *
 * Secure chat messaging for video calls with role enforcement.
 * - Only call participants (patient/provider) can send messages
 * - Supports text messages and file attachments
 * - Inserts notification for the other participant
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

interface SendMessageRequest {
  appointment_id: string;
  message_type: "text" | "file";
  text?: string;
  file_url?: string;
  file_name?: string;
  file_mime?: string;
  file_size?: number;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("=== Call Send Message Request ===");

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
    let userRole: string = "";
    let userName: string = "";
    let userAvatar: string = "";

    try {
      const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID");
      if (!firebaseProjectId) {
        throw new Error("FIREBASE_PROJECT_ID not configured");
      }

      console.log("Verifying Firebase token...");
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
        .select("id, email, full_name, photo_url, role")
        .eq("firebase_uid", firebaseUid)
        .single();

      if (userError || !userData) {
        console.error("User lookup failed for UID:", firebaseUid);
        throw new Error("User not found in database");
      }

      userId = userData.id;
      userRole = userData.role || "";
      userName = userData.full_name || "User";
      userAvatar = userData.photo_url || "";

      console.log("Auth Success - User:", userId, "Role:", userRole);
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
    const body: SendMessageRequest = await req.json();
    const {
      appointment_id,
      message_type,
      text,
      file_url,
      file_name,
      file_mime,
      file_size,
    } = body;

    // Validate required fields
    if (!appointment_id || !message_type) {
      return new Response(
        JSON.stringify({ error: "Missing appointment_id or message_type" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (message_type === "text" && (!text || !text.trim())) {
      return new Response(JSON.stringify({ error: "Empty text message" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (message_type === "file" && (!file_url || !file_name)) {
      return new Response(
        JSON.stringify({ error: "Missing file_url or file_name" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get appointment to verify participant
    // NOTE: appointments.provider_id references medical_provider_profiles.id
    const { data: appointment, error: appointmentError } = await supabaseAdmin
      .from("appointments")
      .select(
        `
        id,
        provider_id,
        patient_id,
        medical_provider_profiles!appointments_provider_id_fkey(
          user_id,
          users!medical_provider_profiles_user_id_fkey(full_name)
        )
      `
      )
      .eq("id", appointment_id)
      .single();

    if (appointmentError || !appointment) {
      console.error("Appointment query error:", appointmentError);
      return new Response(JSON.stringify({ error: "Appointment not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Extract provider's user_id from nested relationship
    const providerProfile = appointment.medical_provider_profiles as {
      user_id: string;
      users: { full_name?: string } | null;
    } | null;
    const providerUserId = providerProfile?.user_id;

    // Verify user is a participant in this appointment
    const isProvider = providerUserId === userId;
    const isPatient = appointment.patient_id === userId;

    if (!isProvider && !isPatient) {
      console.log(
        `User ${userId} is not a participant in appointment ${appointment_id}`
      );
      return new Response(
        JSON.stringify({ error: "Not a participant in this appointment" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Determine sender role
    const senderRole = isProvider ? "medical_provider" : "patient";

    console.log(
      `User ${userId} (${senderRole}) sending ${message_type} message`
    );

    // Insert message into chime_messages
    const messageData: Record<string, unknown> = {
      appointment_id,
      sender_id: userId,
      sender_name: userName,
      sender_avatar: userAvatar,
      sender_role: senderRole,
      message_type,
      message_content: message_type === "text" ? text : null,
      message: message_type === "text" ? text : `File: ${file_name}`,
      user_id: userId,
    };

    // Add file fields if it's a file message
    if (message_type === "file") {
      messageData.file_url = file_url;
      messageData.file_name = file_name;
      messageData.file_mime = file_mime;
      messageData.file_size = file_size;
    }

    const { data: insertedMessage, error: insertError } = await supabaseAdmin
      .from("chime_messages")
      .insert(messageData)
      .select("*")
      .single();

    if (insertError) {
      console.error("Insert message error:", insertError);
      return new Response(
        JSON.stringify({ error: "Failed to send message", details: insertError.message }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log("Message inserted:", insertedMessage.id);

    // Determine recipient and send notification
    const recipientId = isProvider ? appointment.patient_id : providerUserId;

    if (recipientId) {
      // Insert notification for the other participant
      const notificationTitle =
        message_type === "text" ? "New message" : "New file shared";
      const notificationBody =
        message_type === "text"
          ? text?.substring(0, 100) || "New message"
          : `${userName} shared: ${file_name}`;

      const { error: notifError } = await supabaseAdmin
        .from("call_notifications")
        .insert({
          recipient_id: recipientId,
          type: "message",
          title: notificationTitle,
          body: notificationBody,
          payload: {
            appointment_id,
            message_id: insertedMessage.id,
            sender_name: userName,
            sender_role: senderRole,
            message_type,
          },
        });

      if (notifError) {
        console.error("Notification insert error:", notifError);
        // Don't fail the request, just log the error
      } else {
        console.log("Notification sent to:", recipientId);
      }
    }

    return new Response(
      JSON.stringify({
        message_id: insertedMessage.id,
        created_at: insertedMessage.created_at,
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
