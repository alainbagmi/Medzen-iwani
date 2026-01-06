import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { verifyFirebaseToken } from "./verify-firebase-jwt.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-firebase-token",
};

interface MeetingRequest {
  action: "create" | "join" | "end" | "batch-join" | "get-status" | "get-link";
  appointmentId?: string;
  meetingId?: string;
  userId?: string;
  userIds?: string[]; // For batch attendee creation
  enableRecording?: boolean;
  enableTranscription?: boolean;
  transcriptionLanguage?: string; // e.g., "en-US", "es-ES", "fr-FR"
}

// Send push notification to patient when provider starts call
// Uses Supabase send-push-notification edge function with FCM
const sendVideoCallNotification = async (
  patientFcmToken: string,
  providerName: string,
  appointmentId: string,
  meetingId: string
) => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  try {
    console.log(`📱 Sending video call notification to patient`);
    console.log(`📱 Provider: ${providerName}, Appointment: ${appointmentId}`);

    // Call the send-push-notification edge function
    const response = await fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${supabaseServiceKey}`,
        'apikey': supabaseServiceKey,
      },
      body: JSON.stringify({
        fcm_token: patientFcmToken,
        title: '📹 Video Call Starting',
        body: `${providerName} is ready for your video consultation. Tap to join now.`,
        data: {
          type: 'video_call',
          action: 'join_call',
          appointmentId: appointmentId,
          meetingId: meetingId,
          providerName: providerName,
          initialPageName: 'patient_landing_page',
          parameterData: JSON.stringify({
            appointmentId: appointmentId,
            autoJoinCall: 'true',
          }),
        },
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`❌ Push notification failed: ${response.status} - ${errorText}`);

      // Handle invalid token case - patient may have uninstalled app
      if (response.status === 410) {
        console.log(`⚠️ Patient FCM token is invalid/expired - they may need to reinstall the app`);
      }
    } else {
      const result = await response.json();
      console.log(`✅ Push notification sent successfully!`);
      console.log(`   Message ID: ${result.messageId}`);
    }
  } catch (error) {
    console.error(`❌ Error sending push notification:`, error);
    // Don't throw - notification failure shouldn't block the meeting
  }
};

// Call AWS Lambda via API Gateway
const callChimeLambda = async (action: string, params: any) => {
  const chimeApiEndpoint = Deno.env.get("CHIME_API_ENDPOINT");

  if (!chimeApiEndpoint) {
    throw new Error("CHIME_API_ENDPOINT not configured");
  }

  // Ensure the endpoint includes /meetings path
  // API Gateway routes: POST /meetings, POST /messaging, GET /health
  const meetingsUrl = chimeApiEndpoint.endsWith('/meetings')
    ? chimeApiEndpoint
    : `${chimeApiEndpoint.replace(/\/$/, '')}/meetings`;

  console.log(`📞 Calling Lambda API - Action: ${action}`);
  console.log(`📞 Lambda URL: ${meetingsUrl}`);

  const response = await fetch(meetingsUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      action,
      ...params,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error(`❌ Lambda API error: ${response.status} - ${errorText}`);
    throw new Error(`Lambda API returned ${response.status}: ${errorText}`);
  }

  const result = await response.json();
  console.log(`✅ Lambda API success - Action: ${action}`);
  return result;
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("=== Chime Meeting Token Request ===");

    // Get Firebase token from custom header
    const firebaseTokenHeader = req.headers.get("x-firebase-token") || req.headers.get("X-Firebase-Token");

    if (!firebaseTokenHeader) {
      return new Response(
        JSON.stringify({ error: "Missing x-firebase-token header" }),
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

      console.log("🔍 Verifying Firebase token...");
      const payload = await verifyFirebaseToken(firebaseTokenHeader, firebaseProjectId);
      const firebaseUid = payload.user_id || payload.sub;

      console.log("📋 Token payload - user_id:", payload.user_id);
      console.log("📋 Token payload - sub:", payload.sub);
      console.log("📋 Token payload - email:", payload.email);
      console.log("📋 Extracted UID:", firebaseUid);

      if (!firebaseUid) {
        throw new Error("No user ID in verified token");
      }

      console.log("🔍 Looking up user with Firebase UID:", firebaseUid);

      // Look up user in Supabase
      const { data: userData, error: userError } = await supabaseAdmin
        .from("users")
        .select("id, email, firebase_uid, full_name")
        .eq("firebase_uid", firebaseUid)
        .single();

      console.log("📊 Query found user:", !!userData);
      if (userError) {
        console.error("📊 Query error code:", userError.code);
        console.error("📊 Query error message:", userError.message);
      }
      if (userData) {
        console.log("📊 User ID:", userData.id);
        console.log("📊 User email:", userData.email);
        console.log("📊 User Firebase UID:", userData.firebase_uid);
      }

      if (userError || !userData) {
        console.error("❌ User lookup failed for UID:", firebaseUid);
        console.error("❌ Error:", userError?.message || "No error message");
        throw new Error("User not found in database");
      }

      userId = userData.id;
      userEmail = userData.email;

      console.log("✓ Auth Success - User:", userId, userEmail);

    } catch (error) {
      console.error("Auth Error:", error);
      return new Response(
        JSON.stringify({ error: "Invalid or expired token", details: error.message }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get request body
    const body: MeetingRequest = await req.json();
    const {
      action,
      appointmentId,
      meetingId,
      userIds,
      enableRecording = false,
      enableTranscription = false,
      transcriptionLanguage = "en-US"
    } = body;

    console.log("Action:", action);
    console.log("Appointment ID:", appointmentId);
    console.log("Recording:", enableRecording);
    console.log("Transcription:", enableTranscription);

    switch (action) {
      case "create": {
        if (!appointmentId) {
          return new Response(
            JSON.stringify({ error: "appointmentId is required for create action" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Verify appointment exists and user has access
        // Include provider info for push notification
        // NOTE: appointments.provider_id now references medical_provider_profiles.id (not users.id)
        // We need to join through medical_provider_profiles to get user info
        const { data: appointment, error: appointmentError } = await supabaseAdmin
          .from("appointments")
          .select(`
            id,
            provider_id,
            patient_id,
            status,
            medical_provider_profiles!appointments_provider_id_fkey(
              id,
              user_id,
              users!medical_provider_profiles_user_id_fkey(full_name, firebase_uid)
            )
          `)
          .eq("id", appointmentId)
          .single();

        if (appointmentError || !appointment) {
          console.error("Appointment query error:", appointmentError);
          return new Response(
            JSON.stringify({ error: "Appointment not found" }),
            { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Extract provider's user_id from the nested medical_provider_profiles relationship
        const providerProfile = appointment.medical_provider_profiles as { id: string; user_id: string; users: { full_name?: string; firebase_uid?: string } | null } | null;
        const providerUserId = providerProfile?.user_id;

        // CRITICAL: Only providers can CREATE meetings - patients must wait for provider to start the call
        // This prevents patients from starting video calls before the provider is ready
        if (providerUserId !== userId) {
          console.log(`❌ User ${userId} attempted to CREATE meeting but is not the provider (provider: ${providerUserId})`);
          return new Response(
            JSON.stringify({
              error: "Only providers can start video calls. Please wait for your provider to initiate the call.",
              code: "PATIENT_CANNOT_CREATE",
              isPatient: appointment.patient_id === userId,
            }),
            { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Call Lambda API to create meeting
        const lambdaResponse = await callChimeLambda("create", {
          appointmentId,
          userId,
          enableRecording,
          enableTranscription,
          transcriptionLanguage,
        });

        console.log("✓ Meeting created:", lambdaResponse.meeting?.MeetingId);
        console.log("✓ Attendee created:", lambdaResponse.attendee?.AttendeeId);

        // Store meeting in database with provider_id and patient_id for RLS
        // First, try to update any existing session for this appointment (handles restart case)
        const sessionData = {
          provider_id: appointment.provider_id,
          patient_id: appointment.patient_id,
          channel_name: `meeting-${appointmentId}`,
          meeting_id: lambdaResponse.meeting.MeetingId,
          external_meeting_id: appointmentId,
          status: "active",
          is_call_active: true,
          created_by: userId,
          recording_enabled: enableRecording,
          transcription_enabled: enableTranscription,
          transcription_language: transcriptionLanguage,
          recording_pipeline_id: lambdaResponse.recording?.pipelineId,
          transcription_job_name: lambdaResponse.transcription?.jobName,
          attendee_tokens: {
            [userId]: lambdaResponse.attendee,
          },
          meeting_data: lambdaResponse.meeting,
          media_region: lambdaResponse.meeting.MediaRegion,
          media_placement: lambdaResponse.meeting.MediaPlacement,
          // Reset fields from previous session
          ended_at: null,
          ended_by: null,
          started_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        };

        // Try update first (for existing sessions)
        const { data: updateResult, error: updateError } = await supabaseAdmin
          .from("video_call_sessions")
          .update(sessionData)
          .eq("appointment_id", appointmentId)
          .select();

        if (updateError) {
          console.error("Error updating session:", updateError);
          // Don't throw here - we'll try to insert instead
        }

        // If no rows updated, insert new session
        let sessionCreated = false;
        if (!updateResult || updateResult.length === 0) {
          console.log("📝 No existing session, inserting new one...");
          const { data: insertResult, error: insertError } = await supabaseAdmin
            .from("video_call_sessions")
            .insert({
              appointment_id: appointmentId,
              ...sessionData,
            })
            .select();

          if (insertError) {
            console.error("❌ CRITICAL: Error inserting session:", insertError);
            // This is a critical error - the meeting was created in AWS but not stored in DB
            // The patient won't be able to join!
            return new Response(
              JSON.stringify({
                error: "Failed to store video call session. Please try again.",
                code: "SESSION_CREATE_FAILED",
                details: insertError.message
              }),
              { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
          }
          sessionCreated = !!insertResult && insertResult.length > 0;
          console.log("✓ New session created in database:", sessionCreated);
        } else {
          sessionCreated = true;
          console.log("✓ Existing session updated in database");
        }

        // Verify session was actually created/updated
        if (!sessionCreated) {
          console.error("❌ CRITICAL: Session not created - verifying in database...");
          const { data: verifySession } = await supabaseAdmin
            .from("video_call_sessions")
            .select("id, status")
            .eq("appointment_id", appointmentId)
            .eq("status", "active")
            .single();

          if (!verifySession) {
            console.error("❌ CRITICAL: No active session found after create attempt!");
            return new Response(
              JSON.stringify({
                error: "Failed to verify video call session. Please try again.",
                code: "SESSION_VERIFY_FAILED"
              }),
              { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
          }
          console.log("✓ Session verified in database:", verifySession.id);
        }

        // If provider started the call, send push notification to patient
        // Check against providerUserId (user's ID) not provider_id (which is now medical_provider_profiles.id)
        if (userId === providerUserId && appointment.patient_id) {
          // Get provider info from the nested relationship path
          const providerUserInfo = providerProfile?.users;
          const providerName = providerUserInfo?.full_name || "Your provider";

          // Get patient's FCM token for push notification
          const { data: patientData } = await supabaseAdmin
            .from("users")
            .select("fcm_token, firebase_uid")
            .eq("id", appointment.patient_id)
            .single();

          if (patientData?.fcm_token) {
            console.log(`📱 Provider ${providerName} started call, notifying patient...`);
            console.log(`📱 Patient has FCM token: ${patientData.fcm_token.substring(0, 20)}...`);
            // Send notification asynchronously - don't block the response
            sendVideoCallNotification(
              patientData.fcm_token,
              providerName,
              appointmentId,
              lambdaResponse.meeting.MeetingId
            ).catch(err => console.error("Notification error:", err));
          } else {
            console.log(`⚠️ Patient does not have FCM token registered - cannot send push notification`);
            console.log(`   Patient ID: ${appointment.patient_id}`);
            console.log(`   Patient Firebase UID: ${patientData?.firebase_uid || 'unknown'}`);
          }

          // Insert into call_notifications for realtime listener (fallback for in-app notification)
          // This works even if FCM token is missing or push fails
          try {
            await supabaseAdmin.from("call_notifications").insert({
              recipient_id: appointment.patient_id,
              type: "call_started",
              title: "📹 Video Call Started",
              body: `${providerName} is ready for your video consultation. Tap to join now.`,
              payload: {
                appointment_id: appointmentId,
                call_id: lambdaResponse.meeting.MeetingId,
                meeting_id: lambdaResponse.meeting.MeetingId,
                provider_name: providerName,
              },
            });
            console.log(`✅ Call notification inserted for patient ${appointment.patient_id}`);
          } catch (notifError) {
            console.error(`❌ Failed to insert call notification:`, notifError);
            // Don't throw - this is a non-critical failure
          }
        }

        return new Response(
          JSON.stringify({
            meeting: lambdaResponse.meeting,
            attendee: lambdaResponse.attendee,
            recordingEnabled: enableRecording,
            transcriptionEnabled: enableTranscription,
            recordingPipelineId: lambdaResponse.recording?.pipelineId,
            transcriptionJobName: lambdaResponse.transcription?.jobName,
          }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "join": {
        // Allow joining by either meetingId OR appointmentId
        if (!meetingId && !appointmentId) {
          return new Response(
            JSON.stringify({ error: "meetingId or appointmentId is required for join action" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        console.log("📞 JOIN request - appointmentId:", appointmentId, "meetingId:", meetingId);
        console.log("📞 User requesting join:", userId);

        // Get meeting from database - support lookup by meetingId or appointmentId
        let sessionQuery = supabaseAdmin
          .from("video_call_sessions")
          .select("*, appointments(provider_id, patient_id)");

        if (meetingId) {
          sessionQuery = sessionQuery.eq("meeting_id", meetingId);
        } else {
          // Lookup by appointmentId - get the active session
          sessionQuery = sessionQuery
            .eq("appointment_id", appointmentId)
            .eq("status", "active");
        }

        const { data: session, error: sessionError } = await sessionQuery.single();

        if (sessionError || !session) {
          console.error("❌ Session query failed for appointment:", appointmentId);
          console.error("❌ Session error:", sessionError?.message || "No session found");

          // Debug: Check if there are ANY sessions for this appointment
          const { data: allSessions } = await supabaseAdmin
            .from("video_call_sessions")
            .select("id, status, meeting_id, created_at")
            .eq("appointment_id", appointmentId);

          console.log("📊 All sessions for this appointment:", JSON.stringify(allSessions));

          // Provide more helpful error message
          const errorMsg = appointmentId
            ? "No active video call found for this appointment. The provider may not have started the call yet."
            : "Meeting not found";
          return new Response(
            JSON.stringify({ error: errorMsg, code: "NO_ACTIVE_CALL" }),
            { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        console.log("✓ Found active session:", session.id, "meeting_id:", session.meeting_id);

        // Check authorization - user must be part of the appointment
        const appointmentData = session.appointments;

        // Handle null appointments data (foreign key join failed)
        if (!appointmentData) {
          console.error("❌ appointments join returned null - checking session directly");
          // Fall back to checking session's provider_id and patient_id
          if (session.provider_id !== userId && session.patient_id !== userId) {
            return new Response(
              JSON.stringify({ error: "Not authorized to join this meeting. You must be part of this appointment." }),
              { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
          }
        } else {
          console.log("📋 Appointment data:", JSON.stringify(appointmentData));
          console.log("📋 Checking auth: provider_id=", appointmentData.provider_id, "patient_id=", appointmentData.patient_id, "userId=", userId);

          if (appointmentData.provider_id !== userId && appointmentData.patient_id !== userId) {
            console.error("❌ Authorization failed - user is neither provider nor patient");
            return new Response(
              JSON.stringify({ error: "Not authorized to join this meeting. You must be part of this appointment." }),
              { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
          }
        }

        console.log("✓ Authorization passed for user:", userId);

        // Use the meetingId from the session
        const sessionMeetingId = session.meeting_id;

        // Call Lambda API to join meeting
        let lambdaResponse;
        try {
          lambdaResponse = await callChimeLambda("join", {
            meetingId: sessionMeetingId,
            userId,
          });
        } catch (lambdaError: any) {
          // Handle stale session - meeting expired/ended in AWS but database not updated
          if (lambdaError.message?.includes("404") || lambdaError.message?.includes("Meeting not found")) {
            console.log("⚠️ Meeting expired in AWS, cleaning up stale session");

            // Update the stale session to ended
            await supabaseAdmin
              .from("video_call_sessions")
              .update({
                status: "ended",
                ended_at: new Date().toISOString(),
                is_call_active: false,
              })
              .eq("meeting_id", sessionMeetingId);

            return new Response(
              JSON.stringify({
                error: "The video call has ended or expired. Please ask the provider to start a new call.",
                code: "MEETING_EXPIRED",
                canRetry: false,
              }),
              { status: 410, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
          }
          throw lambdaError; // Re-throw other errors
        }

        console.log("✓ Attendee joined:", lambdaResponse.attendee?.AttendeeId);

        // Update attendee tokens in database
        const updatedTokens = {
          ...session.attendee_tokens,
          [userId]: lambdaResponse.attendee,
        };

        await supabaseAdmin
          .from("video_call_sessions")
          .update({
            attendee_tokens: updatedTokens,
            updated_at: new Date().toISOString(),
          })
          .eq("meeting_id", sessionMeetingId);

        return new Response(
          JSON.stringify({
            meeting: session.meeting_data,
            attendee: lambdaResponse.attendee,
            appointmentId: session.appointment_id,
            meetingId: sessionMeetingId,
            recordingEnabled: session.recording_enabled,
            transcriptionEnabled: session.transcription_enabled,
          }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "batch-join": {
        // Create multiple attendees at once (for group calls)
        if (!meetingId || !userIds || userIds.length === 0) {
          return new Response(
            JSON.stringify({ error: "meetingId and userIds are required for batch-join action" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Call Lambda API to batch create attendees
        const lambdaResponse = await callChimeLambda("batch-join", {
          meetingId,
          userIds,
        });

        console.log("✓ Batch created attendees:", lambdaResponse.attendees?.length || 0);
        console.log("✗ Errors:", lambdaResponse.errors?.length || 0);

        return new Response(
          JSON.stringify({
            attendees: lambdaResponse.attendees,
            errors: lambdaResponse.errors,
          }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "leave": {
        // Patient leaves the call but doesn't end it
        // They can rejoin later if the call is still active
        if (!meetingId) {
          return new Response(
            JSON.stringify({ error: "meetingId is required for leave action" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        console.log(`👋 User ${userId} leaving meeting ${meetingId}`);

        // Just acknowledge the leave - meeting continues
        // The Chime SDK will handle removing the attendee
        return new Response(
          JSON.stringify({
            message: "Left the call successfully",
            canRejoin: true,
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

        // Get meeting session
        const { data: session, error: sessionError } = await supabaseAdmin
          .from("video_call_sessions")
          .select("*, appointments(provider_id, patient_id)")
          .eq("meeting_id", meetingId)
          .single();

        if (sessionError || !session) {
          return new Response(
            JSON.stringify({ error: "Meeting not found" }),
            { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // ONLY provider can end the meeting - patients can only leave
        const isProvider = session.appointments.provider_id === userId;
        if (!isProvider) {
          console.log(`❌ User ${userId} tried to end call but is not the provider`);
          return new Response(
            JSON.stringify({
              error: "Only the provider can end this call. You can leave the call and rejoin later.",
              code: "PATIENT_CANNOT_END",
              canLeave: true,
            }),
            { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Call Lambda API to end meeting
        await callChimeLambda("end", {
          meetingId,
          userId,
        });

        console.log("✓ Meeting ended by provider:", meetingId);

        // Update database
        await supabaseAdmin
          .from("video_call_sessions")
          .update({
            status: "ended",
            ended_at: new Date().toISOString(),
            ended_by: userId,
            is_call_active: false,
          })
          .eq("meeting_id", meetingId);

        return new Response(
          JSON.stringify({ message: "Meeting ended successfully" }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "get-status": {
        // Check if there's an active call for an appointment
        if (!appointmentId) {
          return new Response(
            JSON.stringify({ error: "appointmentId is required for get-status action" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Verify appointment exists and user has access
        // NOTE: appointments.provider_id now references medical_provider_profiles.id
        const { data: appointment, error: appointmentError } = await supabaseAdmin
          .from("appointments")
          .select(`
            id,
            provider_id,
            patient_id,
            status,
            scheduled_start,
            medical_provider_profiles!appointments_provider_id_fkey(
              user_id,
              users!medical_provider_profiles_user_id_fkey(full_name)
            )
          `)
          .eq("id", appointmentId)
          .single();

        if (appointmentError || !appointment) {
          return new Response(
            JSON.stringify({ error: "Appointment not found" }),
            { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Extract provider's user_id from the nested relationship
        const providerProfileStatus = appointment.medical_provider_profiles as { user_id: string; users: { full_name?: string } | null } | null;
        const providerUserIdStatus = providerProfileStatus?.user_id;

        // Check authorization - compare against provider's user_id
        if (providerUserIdStatus !== userId && appointment.patient_id !== userId) {
          return new Response(
            JSON.stringify({ error: "Not authorized to view this appointment" }),
            { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Check for active video call session
        const { data: session } = await supabaseAdmin
          .from("video_call_sessions")
          .select("meeting_id, status, created_by, started_at")
          .eq("appointment_id", appointmentId)
          .eq("status", "active")
          .single();

        const providerUserInfoStatus = providerProfileStatus?.users;

        return new Response(
          JSON.stringify({
            appointmentId,
            hasActiveCall: !!session,
            callStatus: session?.status || "not_started",
            meetingId: session?.meeting_id || null,
            providerName: providerUserInfoStatus?.full_name || "Provider",
            isProvider: providerUserIdStatus === userId,
            isPatient: appointment.patient_id === userId,
            canJoin: !!session && session.status === "active",
          }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "get-link": {
        // Generate a shareable join link for an appointment
        if (!appointmentId) {
          return new Response(
            JSON.stringify({ error: "appointmentId is required for get-link action" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Verify appointment exists and user has access
        // NOTE: appointments.provider_id now references medical_provider_profiles.id
        const { data: appointment, error: appointmentError } = await supabaseAdmin
          .from("appointments")
          .select(`
            id,
            provider_id,
            patient_id,
            scheduled_start,
            medical_provider_profiles!appointments_provider_id_fkey(
              user_id,
              users!medical_provider_profiles_user_id_fkey(full_name)
            )
          `)
          .eq("id", appointmentId)
          .single();

        if (appointmentError || !appointment) {
          return new Response(
            JSON.stringify({ error: "Appointment not found" }),
            { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // Extract provider's user_id from the nested relationship
        const providerProfileLink = appointment.medical_provider_profiles as { user_id: string; users: { full_name?: string } | null } | null;
        const providerUserIdLink = providerProfileLink?.user_id;

        // Check authorization - only provider can generate links (compare against user_id)
        if (providerUserIdLink !== userId) {
          return new Response(
            JSON.stringify({ error: "Only the provider can generate join links" }),
            { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const providerUserInfoLink = providerProfileLink?.users;

        // Generate deep link for the app
        // Format: medzen://join-call?appointmentId=xxx
        const deepLink = `medzen://join-call?appointmentId=${appointmentId}`;

        // Generate web link (for SMS/email sharing)
        const webLink = `https://medzenhealth.app/join-call?appointmentId=${appointmentId}`;

        return new Response(
          JSON.stringify({
            appointmentId,
            deepLink,
            webLink,
            providerName: providerUserInfoLink?.full_name || "Provider",
            scheduledStart: appointment.scheduled_start,
            message: `Join your video consultation with ${providerUserInfoLink?.full_name || "your provider"}`,
          }),
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
      JSON.stringify({
        error: error.message || "Internal server error",
        details: error.stack,
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
