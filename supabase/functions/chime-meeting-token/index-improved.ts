/**
 * Supabase Edge Function: chime-meeting-token (Improved)
 *
 * This is an improved version that uses the video_call_participants table
 * for better tracking and compliance with the recommended architecture.
 *
 * Actions:
 * - create: Create new meeting and add creator as participant
 * - join: Add participant to existing meeting
 * - end: End meeting and update all participant statuses
 *
 * To deploy this improved version:
 * 1. Replace the existing index.ts with this file
 * 2. Run: npx supabase functions deploy chime-meeting-token
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { verifyFirebaseToken } from "./verify-firebase-jwt.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-firebase-token",
};

interface MeetingRequest {
  action: "create" | "join" | "end";
  appointmentId?: string;
  meetingId?: string;
  userId?: string;
  capabilities?: {
    audio?: "SendReceive" | "Send" | "Receive" | "None";
    video?: "SendReceive" | "Send" | "Receive" | "None";
    content?: "SendReceive" | "Send" | "Receive" | "None";
  };
}

interface ChimeMeetingResponse {
  meeting: {
    MeetingId: string;
    ExternalMeetingId: string;
    MediaRegion: string;
    MediaPlacement: {
      AudioHostUrl: string;
      AudioFallbackUrl: string;
      SignalingUrl: string;
      TurnControlUrl: string;
      EventIngestionUrl: string;
    };
  };
  attendee: {
    AttendeeId: string;
    ExternalUserId: string;
    JoinToken: string;
  };
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get Firebase token from custom header
    const firebaseTokenHeader = req.headers.get("X-Firebase-Token");
    if (!firebaseTokenHeader) {
      return new Response(
        JSON.stringify({ error: "Missing X-Firebase-Token header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // Verify Firebase JWT token
    let userId: string;
    let userEmail: string;

    try {
      const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID");
      if (!firebaseProjectId) {
        throw new Error("FIREBASE_PROJECT_ID not configured");
      }

      const payload = await verifyFirebaseToken(firebaseTokenHeader, firebaseProjectId);
      const firebaseUid = payload.user_id || payload.sub;

      if (!firebaseUid) {
        throw new Error("No user ID in verified token");
      }

      // Look up user in Supabase
      const { data: userData, error: userError } = await supabaseAdmin
        .from("users")
        .select("id, email, display_name, firebase_uid")
        .eq("firebase_uid", firebaseUid)
        .single();

      if (userError || !userData) {
        console.error("User lookup error:", userError);
        throw new Error("User not found in database");
      }

      userId = userData.id;
      userEmail = userData.email;

      console.log("=== Auth Success ===");
      console.log("Firebase UID:", firebaseUid);
      console.log("Supabase User ID:", userId);
      console.log("User email:", userEmail);
    } catch (error) {
      console.error("=== Auth Error ===", error);
      return new Response(
        JSON.stringify({ error: "Invalid or expired token", details: error.message }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get request body
    const body: MeetingRequest = await req.json();
    const { action, appointmentId, meetingId, capabilities } = body;

    // Get AWS API Gateway endpoint
    const chimeApiEndpoint = Deno.env.get("CHIME_API_ENDPOINT");
    if (!chimeApiEndpoint) {
      return new Response(
        JSON.stringify({ error: "Chime API endpoint not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    switch (action) {
      case "create": {
        if (!appointmentId) {
          return new Response(
            JSON.stringify({ error: "appointmentId is required for create action" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // 1. Verify appointment exists and user has access
        const { data: appointment, error: appointmentError } = await supabaseAdmin
          .from("appointments")
          .select("id, provider_id, patient_id, status")
          .eq("id", appointmentId)
          .single();

        if (appointmentError || !appointment) {
          console.error("Appointment query error:", appointmentError);
          return new Response(
            JSON.stringify({ error: "Appointment not found" }),
            { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Check authorization
        const isProvider = appointment.provider_id === userId;
        const isPatient = appointment.patient_id === userId;

        if (!isProvider && !isPatient) {
          return new Response(
            JSON.stringify({ error: "Not authorized to create meeting for this appointment" }),
            { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const userRole = isProvider ? "provider" : "patient";

        // 2. Call AWS Lambda to create meeting
        const createResponse = await fetch(`${chimeApiEndpoint}/meetings`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            action: "create",
            appointmentId,
            userId,
            capabilities
          }),
        });

        if (!createResponse.ok) {
          const errorData = await createResponse.json();
          throw new Error(errorData.error || "Failed to create meeting");
        }

        const meetingData: ChimeMeetingResponse = await createResponse.json();

        // 3. Create video_call_session record
        const { data: sessionData, error: sessionError } = await supabaseAdmin
          .from("video_call_sessions")
          .insert({
            appointment_id: appointmentId,
            channel_name: `meeting-${appointmentId}`,
            meeting_id: meetingData.meeting.MeetingId,
            external_meeting_id: meetingData.meeting.ExternalMeetingId,
            media_region: meetingData.meeting.MediaRegion,
            status: "active",
            created_by: userId,
            meeting_data: meetingData.meeting,
            started_at: new Date().toISOString(),
          })
          .select()
          .single();

        if (sessionError) {
          console.error("Error creating session:", sessionError);
          throw new Error("Failed to create session record");
        }

        // 4. Add creator as first participant
        const { error: participantError } = await supabaseAdmin
          .from("video_call_participants")
          .insert({
            video_call_id: sessionData.id,
            user_id: userId,
            role: userRole,
            chime_attendee_id: meetingData.attendee.AttendeeId,
            chime_join_token: meetingData.attendee.JoinToken,
            chime_external_user_id: userId,
            status: "invited",
          });

        if (participantError) {
          console.error("Error adding participant:", participantError);
          // Don't fail the request - session was created successfully
        }

        return new Response(
          JSON.stringify({
            meeting: meetingData.meeting,
            attendee: meetingData.attendee,
            sessionId: sessionData.id,
          }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "join": {
        if (!meetingId) {
          return new Response(
            JSON.stringify({ error: "meetingId is required for join action" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // 1. Get meeting session from database
        const { data: session, error: sessionError } = await supabaseAdmin
          .from("video_call_sessions")
          .select(`
            *,
            appointments(
              id,
              provider_id,
              patient_id
            )
          `)
          .eq("meeting_id", meetingId)
          .single();

        if (sessionError || !session) {
          console.error("Session query error:", sessionError);
          return new Response(
            JSON.stringify({ error: "Meeting not found" }),
            { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // 2. Check authorization
        const appointment = session.appointments;
        const isProvider = appointment.provider_id === userId;
        const isPatient = appointment.patient_id === userId;

        if (!isProvider && !isPatient) {
          return new Response(
            JSON.stringify({ error: "Not authorized to join this meeting" }),
            { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const userRole = isProvider ? "provider" : "patient";

        // 3. Check if user is already a participant
        const { data: existingParticipant } = await supabaseAdmin
          .from("video_call_participants")
          .select("id, status, chime_attendee_id, chime_join_token")
          .eq("video_call_id", session.id)
          .eq("user_id", userId)
          .maybeSingle();

        // If already joined and has valid token, return existing attendee data
        if (existingParticipant && existingParticipant.status === "invited" && existingParticipant.chime_join_token) {
          return new Response(
            JSON.stringify({
              meeting: session.meeting_data,
              attendee: {
                AttendeeId: existingParticipant.chime_attendee_id,
                ExternalUserId: userId,
                JoinToken: existingParticipant.chime_join_token,
              },
            }),
            { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // 4. Create new attendee via AWS Lambda
        const attendeeResponse = await fetch(`${chimeApiEndpoint}/meetings`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            action: "join",
            meetingId,
            userId,
            capabilities
          }),
        });

        if (!attendeeResponse.ok) {
          const errorData = await attendeeResponse.json();
          throw new Error(errorData.error || "Failed to join meeting");
        }

        const attendeeData = await attendeeResponse.json();

        // 5. Add/update participant record
        if (existingParticipant) {
          // Update existing participant
          await supabaseAdmin
            .from("video_call_participants")
            .update({
              chime_attendee_id: attendeeData.attendee.AttendeeId,
              chime_join_token: attendeeData.attendee.JoinToken,
              status: "invited",
            })
            .eq("id", existingParticipant.id);
        } else {
          // Create new participant
          await supabaseAdmin
            .from("video_call_participants")
            .insert({
              video_call_id: session.id,
              user_id: userId,
              role: userRole,
              chime_attendee_id: attendeeData.attendee.AttendeeId,
              chime_join_token: attendeeData.attendee.JoinToken,
              chime_external_user_id: userId,
              status: "invited",
            });
        }

        return new Response(
          JSON.stringify({
            meeting: attendeeData.meeting,
            attendee: attendeeData.attendee,
          }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "end": {
        if (!meetingId) {
          return new Response(
            JSON.stringify({ error: "meetingId is required for end action" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // 1. Get session
        const { data: session, error: sessionError } = await supabaseAdmin
          .from("video_call_sessions")
          .select("id, created_by")
          .eq("meeting_id", meetingId)
          .single();

        if (sessionError || !session) {
          return new Response(
            JSON.stringify({ error: "Meeting not found" }),
            { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // 2. Only creator can end meeting (or service role)
        if (session.created_by !== userId) {
          return new Response(
            JSON.stringify({ error: "Only the meeting creator can end the meeting" }),
            { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // 3. End meeting via AWS Lambda
        const endResponse = await fetch(`${chimeApiEndpoint}/meetings`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            action: "end",
            meetingId,
          }),
        });

        if (!endResponse.ok) {
          const errorData = await endResponse.json();
          console.error("Failed to end meeting:", errorData);
          // Continue even if AWS call fails - update database anyway
        }

        // 4. Update session status
        await supabaseAdmin
          .from("video_call_sessions")
          .update({
            status: "ended",
            ended_at: new Date().toISOString(),
          })
          .eq("meeting_id", meetingId);

        // 5. Mark all active participants as left
        await supabaseAdmin
          .from("video_call_participants")
          .update({
            status: "left",
            left_at: new Date().toISOString(),
          })
          .eq("video_call_id", session.id)
          .eq("status", "joined");

        return new Response(
          JSON.stringify({ message: "Meeting ended successfully" }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      default:
        return new Response(
          JSON.stringify({ error: "Invalid action" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: error.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
