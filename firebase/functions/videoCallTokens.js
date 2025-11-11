const functions = require("firebase-functions");
const { RtcTokenBuilder, RtcRole } = require("agora-token");
const { createClient } = require("@supabase/supabase-js");

// Initialize Supabase client
const getSupabaseClient = () => {
  const supabaseUrl = functions.config().supabase?.url;
  const supabaseServiceKey = functions.config().supabase?.service_key;

  if (!supabaseUrl || !supabaseServiceKey) {
    throw new Error("Supabase configuration missing. Set with: firebase functions:config:set supabase.url=... supabase.service_key=...");
  }

  return createClient(supabaseUrl, supabaseServiceKey);
};

/**
 * Generate time-limited Agora RTC tokens for video call participants
 *
 * Input:
 * - sessionId: UUID of the video_call_sessions record
 * - providerId: UUID of the medical provider
 * - patientId: UUID of the patient
 * - appointmentId: UUID of the appointment
 *
 * Output:
 * - providerToken: Agora RTC token for provider
 * - patientToken: Agora RTC token for patient
 * - conversationId: UUID of the created group chat
 * - expiresAt: Token expiration timestamp
 */
exports.generateVideoCallTokens = functions.https.onCall(async (data, context) => {
  try {
    // Authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated to generate video call tokens"
      );
    }

    const { sessionId, providerId, patientId, appointmentId } = data;

    // Validate required parameters
    if (!sessionId || !providerId || !patientId || !appointmentId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required parameters: sessionId, providerId, patientId, appointmentId"
      );
    }

    // Get Agora configuration from Firebase config
    const agoraAppId = functions.config().agora?.app_id;
    const agoraAppCertificate = functions.config().agora?.app_certificate;

    if (!agoraAppId || !agoraAppCertificate) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Agora configuration missing. Set with: firebase functions:config:set agora.app_id=... agora.app_certificate=..."
      );
    }

    const supabase = getSupabaseClient();

    // Verify the session exists and matches the appointment
    const { data: session, error: sessionError } = await supabase
      .from("video_call_sessions")
      .select("id, appointment_id, channel_name, status")
      .eq("id", sessionId)
      .eq("appointment_id", appointmentId)
      .single();

    if (sessionError || !session) {
      throw new functions.https.HttpsError(
        "not-found",
        "Video call session not found or does not match appointment"
      );
    }

    if (session.status === "completed" || session.status === "cancelled") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Video call session is ${session.status} and cannot generate new tokens`
      );
    }

    // Generate Agora channel name if not exists
    const channelName = session.channel_name || `videocall_${sessionId}`;

    // Token validity: 2 hours from now
    const tokenExpirationInSeconds = 7200;
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + tokenExpirationInSeconds;

    // Generate tokens for provider and patient
    const providerToken = RtcTokenBuilder.buildTokenWithUid(
      agoraAppId,
      agoraAppCertificate,
      channelName,
      0, // Use 0 for dynamic UID assignment, or pass specific UID
      RtcRole.PUBLISHER,
      privilegeExpiredTs
    );

    const patientToken = RtcTokenBuilder.buildTokenWithUid(
      agoraAppId,
      agoraAppCertificate,
      channelName,
      0, // Use 0 for dynamic UID assignment
      RtcRole.PUBLISHER,
      privilegeExpiredTs
    );

    // Calculate expiration timestamp
    const expiresAt = new Date(privilegeExpiredTs * 1000).toISOString();

    // Update video_call_sessions with tokens
    const { error: updateError } = await supabase
      .from("video_call_sessions")
      .update({
        channel_name: channelName,
        provider_token: providerToken,
        patient_token: patientToken,
        token_expires_at: expiresAt,
        status: "active",
        updated_at: new Date().toISOString()
      })
      .eq("id", sessionId);

    if (updateError) {
      console.error("Error updating video_call_sessions:", updateError);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to update video call session with tokens"
      );
    }

    // Create a group chat conversation for this video call
    const { data: conversation, error: conversationError } = await supabase
      .rpc("create_conversation_with_validation", {
        p_creator_id: providerId,
        p_participant_ids: [providerId, patientId],
        p_conversation_type: "group",
        p_conversation_category: "provider_to_patient",
        p_appointment_id: appointmentId,
        p_title: "Video Call Chat"
      });

    if (conversationError) {
      console.error("Error creating conversation:", conversationError);
      // Don't fail the token generation if conversation creation fails
      // Log and continue
    }

    // Return tokens and conversation ID
    return {
      success: true,
      channelName,
      providerToken,
      patientToken,
      conversationId: conversation || null,
      expiresAt,
      message: "Video call tokens generated successfully"
    };

  } catch (error) {
    console.error("Error in generateVideoCallTokens:", error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      "internal",
      `Failed to generate video call tokens: ${error.message}`
    );
  }
});

/**
 * Refresh expired Agora RTC tokens for an active video call
 *
 * Input:
 * - sessionId: UUID of the video_call_sessions record
 * - participantId: UUID of the user requesting token refresh
 *
 * Output:
 * - token: New Agora RTC token
 * - expiresAt: Token expiration timestamp
 */
exports.refreshVideoCallToken = functions.https.onCall(async (data, context) => {
  try {
    // Authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated to refresh video call token"
      );
    }

    const { sessionId, participantId } = data;

    // Validate required parameters
    if (!sessionId || !participantId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required parameters: sessionId, participantId"
      );
    }

    // Verify the authenticated user matches the participant
    if (context.auth.uid !== participantId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "User can only refresh their own token"
      );
    }

    // Get Agora configuration
    const agoraAppId = functions.config().agora?.app_id;
    const agoraAppCertificate = functions.config().agora?.app_certificate;

    if (!agoraAppId || !agoraAppCertificate) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Agora configuration missing"
      );
    }

    const supabase = getSupabaseClient();

    // Get session details
    const { data: session, error: sessionError } = await supabase
      .from("video_call_sessions")
      .select("id, channel_name, status, provider_id, patient_id")
      .eq("id", sessionId)
      .single();

    if (sessionError || !session) {
      throw new functions.https.HttpsError(
        "not-found",
        "Video call session not found"
      );
    }

    if (session.status !== "active") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Video call session is not active"
      );
    }

    // Verify participant is part of the call
    if (participantId !== session.provider_id && participantId !== session.patient_id) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "User is not a participant in this video call"
      );
    }

    // Generate new token
    const tokenExpirationInSeconds = 7200;
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + tokenExpirationInSeconds;

    const newToken = RtcTokenBuilder.buildTokenWithUid(
      agoraAppId,
      agoraAppCertificate,
      session.channel_name,
      0,
      RtcRole.PUBLISHER,
      privilegeExpiredTs
    );

    const expiresAt = new Date(privilegeExpiredTs * 1000).toISOString();

    // Update the appropriate token field
    const tokenField = participantId === session.provider_id ? "provider_token" : "patient_token";

    const { error: updateError } = await supabase
      .from("video_call_sessions")
      .update({
        [tokenField]: newToken,
        token_expires_at: expiresAt,
        updated_at: new Date().toISOString()
      })
      .eq("id", sessionId);

    if (updateError) {
      console.error("Error updating token:", updateError);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to update token"
      );
    }

    return {
      success: true,
      token: newToken,
      expiresAt,
      message: "Token refreshed successfully"
    };

  } catch (error) {
    console.error("Error in refreshVideoCallToken:", error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      "internal",
      `Failed to refresh video call token: ${error.message}`
    );
  }
});
