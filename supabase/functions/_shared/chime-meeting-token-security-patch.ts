/**
 * MedZen Chime Meeting Token - Phase 1 Security Enhancements
 *
 * This file contains the enhanced authorization logic that must be added
 * to supabase/functions/chime-meeting-token/index.ts
 *
 * CRITICAL SECURITY FIXES:
 * 1. Appointment-level authorization (prevent meeting hijacking)
 * 2. Timing validation (prevent early/late joins)
 * 3. Status validation (cancelled appointments)
 * 4. Video-enabled check
 * 5. Meeting ID cryptographic validation
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { verifyFirebaseToken } from "./verify-firebase-jwt.ts";

// ============================================
// CRITICAL: Add this code AFTER Firebase JWT verification
// and BEFORE calling the Chime Lambda function
// ============================================

/**
 * Step 1: Validate User is Authorized for This Specific Appointment
 *
 * This prevents meeting hijacking where an authenticated user tries to join
 * an appointment they don't own by guessing/enumerating appointment IDs.
 */
async function validateAppointmentAuthorization(
  supabase: any,
  appointmentId: string,
  supabaseUserId: string,
  firebaseUid: string
): Promise<{ authorized: boolean; appointment?: any; error?: string }> {

  console.log('[AUTH] Starting appointment authorization check');
  console.log('[AUTH] Appointment ID:', appointmentId);
  console.log('[AUTH] Supabase User ID:', supabaseUserId);
  console.log('[AUTH] Firebase UID:', firebaseUid);

  // Fetch appointment with participant details
  const { data: appointment, error: apptError } = await supabase
    .from('appointments')
    .select(`
      id,
      provider_id,
      patient_id,
      status,
      appointment_start_date,
      appointment_end_date,
      video_enabled,
      created_at,
      updated_at
    `)
    .eq('id', appointmentId)
    .single();

  if (apptError || !appointment) {
    console.error('[AUTH] ❌ Appointment not found:', apptError?.message);
    return {
      authorized: false,
      error: 'Appointment not found'
    };
  }

  console.log('[AUTH] Appointment found:', {
    id: appointment.id,
    provider_id: appointment.provider_id,
    patient_id: appointment.patient_id,
    status: appointment.status,
    video_enabled: appointment.video_enabled,
  });

  // Check if user is either provider or patient
  const isProvider = appointment.provider_id === supabaseUserId;
  const isPatient = appointment.patient_id === supabaseUserId;

  if (!isProvider && !isPatient) {
    console.error('[AUTH] ❌ Unauthorized access attempt');
    console.error('[AUTH] User ID:', supabaseUserId);
    console.error('[AUTH] Provider ID:', appointment.provider_id);
    console.error('[AUTH] Patient ID:', appointment.patient_id);
    console.error('[AUTH] This is a potential meeting hijacking attempt!');

    // Log security event for HIPAA audit
    await supabase.from('video_call_audit_log').insert({
      user_id: supabaseUserId,
      appointment_id: appointmentId,
      action: 'join_attempt_unauthorized',
      firebase_uid: firebaseUid,
      supabase_uid: supabaseUserId,
      error_message: 'User not authorized for this appointment',
      ip_address: null, // Add from request headers if available
      user_agent: null, // Add from request headers if available
    });

    return {
      authorized: false,
      error: 'Unauthorized: You are not a participant in this appointment'
    };
  }

  console.log('[AUTH] ✅ User is authorized:', isProvider ? 'Provider' : 'Patient');

  return {
    authorized: true,
    appointment
  };
}

/**
 * Step 2: Validate Meeting Timing
 *
 * Prevents users from joining meetings too early or after they've ended.
 * Allows 15-minute buffer before/after appointment time.
 */
function validateMeetingTiming(appointment: any): { valid: boolean; error?: string } {
  const now = new Date();
  const startTime = new Date(appointment.appointment_start_date);
  const endTime = new Date(appointment.appointment_end_date);

  const BUFFER_MINUTES = 15; // Allow joining 15 min early and staying 15 min late
  const earliestJoin = new Date(startTime.getTime() - BUFFER_MINUTES * 60000);
  const latestJoin = new Date(endTime.getTime() + BUFFER_MINUTES * 60000);

  console.log('[TIMING] Current time:', now.toISOString());
  console.log('[TIMING] Appointment start:', startTime.toISOString());
  console.log('[TIMING] Appointment end:', endTime.toISOString());
  console.log('[TIMING] Earliest join (15 min before):', earliestJoin.toISOString());
  console.log('[TIMING] Latest join (15 min after):', latestJoin.toISOString());

  if (now < earliestJoin) {
    const minutesUntilStart = Math.floor((earliestJoin.getTime() - now.getTime()) / 60000);
    console.error('[TIMING] ❌ Too early to join');
    return {
      valid: false,
      error: `Too early to join. Meeting opens in ${minutesUntilStart} minutes at ${earliestJoin.toISOString()}`
    };
  }

  if (now > latestJoin) {
    const minutesSinceEnd = Math.floor((now.getTime() - latestJoin.getTime()) / 60000);
    console.error('[TIMING] ❌ Meeting has ended');
    return {
      valid: false,
      error: `Appointment ended ${minutesSinceEnd} minutes ago`
    };
  }

  console.log('[TIMING] ✅ Timing is valid');
  return { valid: true };
}

/**
 * Step 3: Validate Appointment Status
 *
 * Ensures appointment hasn't been cancelled and video is enabled.
 */
function validateAppointmentStatus(appointment: any): { valid: boolean; error?: string } {
  console.log('[STATUS] Checking appointment status:', appointment.status);
  console.log('[STATUS] Video enabled:', appointment.video_enabled);

  if (appointment.status === 'cancelled') {
    console.error('[STATUS] ❌ Appointment is cancelled');
    return {
      valid: false,
      error: 'This appointment has been cancelled'
    };
  }

  if (!appointment.video_enabled) {
    console.error('[STATUS] ❌ Video not enabled for this appointment');
    return {
      valid: false,
      error: 'Video calls are not enabled for this appointment'
    };
  }

  // Optional: Check if appointment is marked as completed
  if (appointment.status === 'completed') {
    console.warn('[STATUS] ⚠️ Appointment already marked as completed');
    // Allow joining completed appointments (doctor may need to review notes)
  }

  console.log('[STATUS] ✅ Appointment status is valid');
  return { valid: true };
}

/**
 * Step 4: Validate Meeting Session Matches Appointment
 *
 * Prevents using a valid appointment ID with an incorrect meeting ID.
 */
async function validateMeetingSession(
  supabase: any,
  appointmentId: string,
  sessionId: string
): Promise<{ valid: boolean; error?: string }> {

  console.log('[SESSION] Validating meeting session');
  console.log('[SESSION] Appointment ID:', appointmentId);
  console.log('[SESSION] Session ID:', sessionId);

  const { data: session, error: sessionError } = await supabase
    .from('video_call_sessions')
    .select('*')
    .eq('appointment_id', appointmentId)
    .eq('chime_meeting_id', sessionId)
    .single();

  if (sessionError || !session) {
    console.error('[SESSION] ❌ Meeting session validation failed');
    console.error('[SESSION] This could be a meeting hijacking attempt');
    console.error('[SESSION] Error:', sessionError?.message);
    return {
      valid: false,
      error: 'Invalid meeting session'
    };
  }

  console.log('[SESSION] ✅ Meeting session is valid');
  return { valid: true };
}

/**
 * Step 5: Optional - Cryptographic Request Signature Validation
 *
 * Adds an extra layer of security to prevent request tampering.
 * This requires the client to generate an HMAC signature of the request.
 */
async function validateRequestSignature(
  appointmentId: string,
  sessionId: string,
  userId: string,
  timestamp: number,
  signature: string
): Promise<{ valid: boolean; error?: string }> {

  // Get shared secret from environment
  const secret = Deno.env.get('MEETING_HMAC_SECRET');
  if (!secret) {
    console.warn('[HMAC] ⚠️ MEETING_HMAC_SECRET not configured - skipping signature validation');
    return { valid: true }; // Allow if not configured
  }

  console.log('[HMAC] Validating request signature');

  // Check timestamp is recent (within 5 minutes)
  const now = Date.now();
  const FIVE_MINUTES = 5 * 60 * 1000;
  if (Math.abs(now - timestamp) > FIVE_MINUTES) {
    console.error('[HMAC] ❌ Timestamp too old or in future');
    return {
      valid: false,
      error: 'Request timestamp expired'
    };
  }

  // Generate expected signature
  const data = `${appointmentId}:${sessionId}:${userId}:${timestamp}`;
  const encoder = new TextEncoder();
  const keyData = encoder.encode(secret);
  const messageData = encoder.encode(data);

  const key = await crypto.subtle.importKey(
    'raw',
    keyData,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signatureBuffer = await crypto.subtle.sign('HMAC', key, messageData);
  const signatureArray = Array.from(new Uint8Array(signatureBuffer));
  const expectedSignature = signatureArray
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');

  if (signature !== expectedSignature) {
    console.error('[HMAC] ❌ Signature mismatch');
    console.error('[HMAC] Expected:', expectedSignature);
    console.error('[HMAC] Received:', signature);
    return {
      valid: false,
      error: 'Invalid request signature'
    };
  }

  console.log('[HMAC] ✅ Signature is valid');
  return { valid: true };
}

/**
 * Main Authorization Function - USE THIS IN index.ts
 *
 * Add this function call AFTER Firebase JWT verification
 * and BEFORE calling the Chime Lambda function.
 */
export async function authorizeVideoCallAccess(
  supabase: any,
  appointmentId: string,
  sessionId: string,
  supabaseUserId: string,
  firebaseUid: string,
  requestSignature?: string,
  requestTimestamp?: number
): Promise<{ authorized: boolean; appointment?: any; error?: string; statusCode?: number }> {

  console.log('=== Starting Video Call Authorization ===');

  try {
    // Step 1: Validate appointment authorization
    const authResult = await validateAppointmentAuthorization(
      supabase,
      appointmentId,
      supabaseUserId,
      firebaseUid
    );

    if (!authResult.authorized) {
      return {
        authorized: false,
        error: authResult.error,
        statusCode: 403 // Forbidden
      };
    }

    const appointment = authResult.appointment!;

    // Step 2: Validate timing
    const timingResult = validateMeetingTiming(appointment);
    if (!timingResult.valid) {
      return {
        authorized: false,
        error: timingResult.error,
        statusCode: 403
      };
    }

    // Step 3: Validate status
    const statusResult = validateAppointmentStatus(appointment);
    if (!statusResult.valid) {
      return {
        authorized: false,
        error: statusResult.error,
        statusCode: statusResult.error?.includes('cancelled') ? 410 : 403 // 410 Gone for cancelled
      };
    }

    // Step 4: Validate meeting session
    const sessionResult = await validateMeetingSession(
      supabase,
      appointmentId,
      sessionId
    );
    if (!sessionResult.valid) {
      return {
        authorized: false,
        error: sessionResult.error,
        statusCode: 403
      };
    }

    // Step 5: Optional - Validate request signature
    if (requestSignature && requestTimestamp) {
      const hmacResult = await validateRequestSignature(
        appointmentId,
        sessionId,
        supabaseUserId,
        requestTimestamp,
        requestSignature
      );
      if (!hmacResult.valid) {
        return {
          authorized: false,
          error: hmacResult.error,
          statusCode: 403
        };
      }
    }

    // Log successful authorization for HIPAA audit
    await supabase.from('video_call_audit_log').insert({
      user_id: supabaseUserId,
      appointment_id: appointmentId,
      meeting_id: sessionId,
      action: 'join_authorized',
      firebase_uid: firebaseUid,
      supabase_uid: supabaseUserId,
    });

    console.log('=== Authorization Successful ===');
    return {
      authorized: true,
      appointment
    };

  } catch (error) {
    console.error('=== Authorization Error ===');
    console.error(error);

    return {
      authorized: false,
      error: 'Internal authorization error',
      statusCode: 500
    };
  }
}

// ============================================
// INTEGRATION INSTRUCTIONS
// ============================================
/*

In supabase/functions/chime-meeting-token/index.ts, add this code:

1. Import the authorization function:
   import { authorizeVideoCallAccess } from './chime-meeting-token-security-patch.ts';

2. After Firebase JWT verification and Supabase user lookup, add:

   // CRITICAL SECURITY CHECK - Validate authorization
   const authResult = await authorizeVideoCallAccess(
     supabase,
     appointmentId,
     sessionId,
     supabaseUserId,
     firebaseUid,
     requestBody.signature,      // Optional
     requestBody.timestamp        // Optional
   );

   if (!authResult.authorized) {
     console.error('❌ Authorization failed:', authResult.error);
     return new Response(
       JSON.stringify({
         error: authResult.error,
         code: 'UNAUTHORIZED'
       }),
       {
         status: authResult.statusCode || 403,
         headers: { 'Content-Type': 'application/json' }
       }
     );
   }

   console.log('✅ Authorization successful, proceeding with Chime token generation');

3. Continue with existing Chime Lambda call

4. Log join success for HIPAA audit:
   await supabase.from('video_call_audit_log').insert({
     user_id: supabaseUserId,
     appointment_id: appointmentId,
     meeting_id: sessionId,
     action: 'join_success',
     firebase_uid: firebaseUid,
     supabase_uid: supabaseUserId,
   });

*/
