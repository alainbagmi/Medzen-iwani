/**
 * MedZen Finalize Video Call
 *
 * Orchestrates the end-of-call workflow:
 * 1. Stops live transcription
 * 2. Merges live caption segments into final transcript
 * 3. Starts post-call Transcribe Medical batch job
 * 4. Builds speaker map from participants
 * 5. Triggers SOAP note auto-generation
 * 6. Finalizes session and notifies doctor
 *
 * Handles both complete calls and error scenarios.
 *
 * @version 1.0.0
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import {
  ChimeSDKMeetingsClient,
  StopMeetingTranscriptionCommand,
} from 'npm:@aws-sdk/client-chime-sdk-meetings@3.716.0';
import {
  TranscribeClient,
  StartTranscriptionJobCommand,
} from 'npm:@aws-sdk/client-transcribe@3.716.0';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { getCorsHeaders, securityHeaders } from '../_shared/cors.ts';

// AWS Configuration
const AWS_REGION = Deno.env.get('AWS_REGION') || 'eu-central-1';
const AWS_ACCESS_KEY_ID = Deno.env.get('AWS_ACCESS_KEY_ID') || '';
const AWS_SECRET_ACCESS_KEY = Deno.env.get('AWS_SECRET_ACCESS_KEY') || '';

// Supabase Configuration
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

// AWS Transcribe Medical configuration
const TRANSCRIBE_OUTPUT_BUCKET = Deno.env.get('TRANSCRIBE_OUTPUT_BUCKET') || 'medzen-transcripts';
const TRANSCRIBE_ROLE_ARN = Deno.env.get('TRANSCRIBE_ROLE_ARN') || '';

interface FinalizeCallRequest {
  sessionId: string;
  meetingId: string;
  appointmentId: string;
  providerId: string;
  patientId: string;
  transcriptionEnabled: boolean;
  recordingEnabled: boolean;
  pipelineId?: string;  // Chime Media Capture Pipeline ID
}

/**
 * Create Chime client for region
 */
function createChimeClient(region: string): ChimeSDKMeetingsClient {
  return new ChimeSDKMeetingsClient({
    region,
    credentials: {
      accessKeyId: AWS_ACCESS_KEY_ID,
      secretAccessKey: AWS_SECRET_ACCESS_KEY,
    },
  });
}

/**
 * Create Transcribe client
 */
function createTranscribeClient(): TranscribeClient {
  return new TranscribeClient({
    region: AWS_REGION,
    credentials: {
      accessKeyId: AWS_ACCESS_KEY_ID,
      secretAccessKey: AWS_SECRET_ACCESS_KEY,
    },
  });
}

/**
 * Stop live transcription and merge captions
 */
async function stopTranscriptionAndMerge(
  supabase: any,
  sessionId: string,
  appointmentId: string,
  meetingId: string,
  mediaRegion: string
) {
  console.log(`[Finalize] Stopping transcription for session ${sessionId}...`);

  const chimeClient = createChimeClient(mediaRegion);

  try {
    // Stop live transcription
    const stopCommand = new StopMeetingTranscriptionCommand({
      MeetingId: meetingId,
    });

    await chimeClient.send(stopCommand);
    console.log('[Finalize] Live transcription stopped');
  } catch (error) {
    console.warn('[Finalize] Error stopping transcription (may already be stopped):', error);
    // Don't throw - transcription might already be stopped
  }

  // Merge live caption segments into final transcript
  console.log('[Finalize] Merging live caption segments...');

  const { data: captionSegments, error: segmentsError } = await supabase
    .from('live_caption_segments')
    .select('id, speaker_name, transcript_text, created_at')
    .eq('session_id', sessionId)
    .order('created_at', { ascending: true });

  if (segmentsError) {
    console.error('[Finalize] Error fetching caption segments:', segmentsError);
    throw new Error(`Failed to fetch caption segments: ${segmentsError.message || JSON.stringify(segmentsError)}`);
  }

  let aggregatedText = '';
  const speakerSegments: Array<{ speaker: string; text: string; timestamp: string }> = [];
  let currentSpeaker = '';
  let currentText = '';

  if (captionSegments && captionSegments.length > 0) {
    for (const segment of captionSegments) {
      const speaker = segment.speaker_name || 'Unknown';
      const text = segment.transcript_text || '';

      if (speaker !== currentSpeaker && currentText.trim()) {
        // Save previous speaker's segment
        aggregatedText += `[${currentSpeaker}]: ${currentText.trim()}\n\n`;
        speakerSegments.push({
          speaker: currentSpeaker,
          text: currentText.trim(),
          timestamp: segment.created_at,
        });
        currentSpeaker = speaker;
        currentText = text;
      } else if (speaker === currentSpeaker) {
        currentText += ' ' + text;
      } else {
        currentSpeaker = speaker;
        currentText = text;
      }
    }

    // Save last segment
    if (currentText.trim()) {
      aggregatedText += `[${currentSpeaker}]: ${currentText.trim()}`;
      speakerSegments.push({
        speaker: currentSpeaker,
        text: currentText.trim(),
        timestamp: new Date().toISOString(),
      });
    }
  }

  console.log(`[Finalize] Merged ${captionSegments?.length || 0} segments (${aggregatedText.length} chars)`);

  // Create call_transcript record (appointment_id is required by schema)
  console.log('[Finalize] Creating call_transcript record...');
  console.log(`  session_id: ${sessionId}`);
  console.log(`  appointment_id: ${appointmentId}`);
  console.log(`  meeting_id: ${meetingId}`);
  console.log(`  raw_text length: ${(aggregatedText || null)?.length || 0}`);
  console.log(`  speaker_segments: ${speakerSegments.length}`);

  const { data: transcriptData, error: transcriptError } = await supabase
    .from('call_transcripts')
    .insert({
      session_id: sessionId,
      appointment_id: appointmentId,
      meeting_id: meetingId,
      type: 'live_merged',
      source: 'chime_live',
      raw_text: aggregatedText || null,
      speaker_map: speakerSegments.length > 0 ? speakerSegments : null,
      total_segments: captionSegments?.length || 0,
      processing_status: 'completed',
    })
    .select('id')
    .single();

  if (transcriptError) {
    console.error('[Finalize] Error creating transcript record:');
    console.error(`  Code: ${transcriptError.code}`);
    console.error(`  Message: ${transcriptError.message}`);
    console.error(`  Details: ${transcriptError.details}`);
    console.error(`  Hint: ${transcriptError.hint}`);
    const errorMsg = transcriptError.message || transcriptError.code || JSON.stringify(transcriptError);
    throw new Error(`Failed to create transcript: ${errorMsg}`);
  }

  console.log(`[Finalize] Created transcript record: ${transcriptData.id}`);

  return {
    transcriptId: transcriptData.id,
    transcriptText: aggregatedText,
    speakerSegments,
  };
}

/**
 * Start Transcribe Medical post-call job
 */
async function startTranscribeMedicalJob(
  supabase: any,
  sessionId: string,
  meetingId: string,
  pipelineId?: string
) {
  if (!pipelineId) {
    console.log('[Finalize] No recording pipeline ID - skipping post-call medical transcription');
    return null;
  }

  console.log(`[Finalize] Starting Transcribe Medical job for recording ${pipelineId}...`);

  const transcribeClient = createTranscribeClient();

  try {
    // Assume recording is in S3 at s3://bucket/session-id/audio.wav
    const audioFileUri = `s3://${TRANSCRIBE_OUTPUT_BUCKET}/${sessionId}/audio.wav`;

    const jobName = `medzen-${sessionId}-${Date.now()}`;

    const command = new StartTranscriptionJobCommand({
      TranscriptionJobName: jobName,
      LanguageCode: 'en-US',
      MediaFormat: 'wav',
      Media: {
        MediaFileUri: audioFileUri,
      },
      OutputBucketName: TRANSCRIBE_OUTPUT_BUCKET,
      ContentIdentificationType: 'PHI',
      Specialty: 'PRIMARYCARE',
      Type: 'CONVERSATION',  // Doctor-patient conversation
      ModelSettings: {
        LanguageModelName: 'medical',
      },
      Tags: [
        { Key: 'session-id', Value: sessionId },
        { Key: 'meeting-id', Value: meetingId },
      ],
    });

    const response = await transcribeClient.send(command);

    console.log(`[Finalize] Transcribe Medical job started: ${jobName}`);

    // Update session with job info
    await supabase
      .from('video_call_sessions')
      .update({
        medical_transcription_job_id: jobName,
        medical_transcription_job_status: 'queued',
      })
      .eq('id', sessionId);

    return jobName;
  } catch (error) {
    console.error('[Finalize] Error starting Transcribe Medical job:', error);
    // Don't throw - let the call continue without post-call transcription
    return null;
  }
}

/**
 * Build speaker map from participants
 */
async function buildSpeakerMap(supabase: any, sessionId: string) {
  console.log('[Finalize] Building speaker map from participants...');

  // Use video_call_participants_view to get user names joined from users table
  const { data: participants, error: participantsError } = await supabase
    .from('video_call_participants')
    .select('id, chime_attendee_id, user_id, role')
    .eq('video_call_id', sessionId);

  if (participantsError) {
    console.error('[Finalize] Error fetching participants:', participantsError);
    throw new Error(`Failed to fetch participants: ${participantsError.message || JSON.stringify(participantsError)}`);
  }

  if (!participants || participants.length === 0) {
    console.log('[Finalize] No participants found');
    return {};
  }

  console.log(`[Finalize] Found ${participants.length} participants`);

  const speakerMap: Record<string, { userId: string; role: string; displayName: string }> = {};

  for (const p of participants) {
    console.log(`[Finalize] Processing participant: chime_attendee_id=${p.chime_attendee_id}, user_id=${p.user_id}, role=${p.role}`);

    speakerMap[p.chime_attendee_id] = {
      userId: p.user_id,
      role: p.role,
      displayName: p.chime_attendee_id ? `${p.role}-${p.chime_attendee_id.substring(0, 8)}` : 'Unknown',
    };

    // Create speaker mapping record
    const speakerLabel = p.role === 'provider' ? 'Doctor' : p.role === 'patient' ? 'Patient' : p.role;

    try {
      const { data: mappingData, error: mappingError } = await supabase
        .from('speaker_mappings')
        .insert({
          session_id: sessionId,
          attendee_id: p.chime_attendee_id,
          user_id: p.user_id,
          speaker_label: speakerLabel,
          confidence_score: 1.0,
        })
        .select('id')
        .single();

      if (mappingError) {
        console.error(`[Finalize] Error inserting speaker mapping for attendee ${p.chime_attendee_id}:`, mappingError);
        throw new Error(`Failed to insert speaker mapping for attendee ${p.chime_attendee_id}: ${mappingError.message || JSON.stringify(mappingError)}`);
      }

      console.log(`[Finalize] Created speaker mapping: ${mappingData.id} for attendee ${p.chime_attendee_id}`);
    } catch (error) {
      console.error(`[Finalize] Exception creating speaker mapping for attendee ${p.chime_attendee_id}:`, error);
      throw error;
    }
  }

  console.log(`[Finalize] Created speaker mappings for ${Object.keys(speakerMap).length} participants`);

  return speakerMap;
}

/**
 * Timeout wrapper for async operations to prevent hanging
 */
async function withTimeout<T>(promise: Promise<T>, timeoutMs: number, operationName: string): Promise<T> {
  let timeoutHandle: number;
  const timeoutPromise = new Promise<T>((_, reject) => {
    timeoutHandle = setTimeout(() => {
      reject(new Error(`${operationName} timed out after ${timeoutMs}ms`));
    }, timeoutMs);
  });

  try {
    return await Promise.race([promise, timeoutPromise]);
  } finally {
    clearTimeout(timeoutHandle!);
  }
}

/**
 * Trigger SOAP note generation via HTTP call
 */
async function triggerSOAPGeneration(
  supabase: any,
  sessionId: string,
  appointmentId: string,
  transcriptId: string,
  transcriptText: string
) {
  console.log('[Finalize] Triggering SOAP note generation...');

  try {
    // Fetch appointment metadata for SOAP generation
    console.log(`[Finalize] Fetching appointment ${appointmentId} for SOAP generation...`);

    // Step 1: Fetch appointment without nested relationships (direct relationship query)
    const { data: appointment, error: appointmentError } = await supabase
      .from('appointments')
      .select(
        `
        id,
        start_time,
        scheduled_start,
        scheduled_end,
        chief_complaint,
        provider_id,
        patient_id
      `
      )
      .eq('id', appointmentId)
      .single();

    if (appointmentError) {
      console.error('[Finalize] Error fetching appointment:');
      console.error(`  Code: ${appointmentError.code}`);
      console.error(`  Message: ${appointmentError.message}`);
      const errorMsg = appointmentError.message || appointmentError.code || JSON.stringify(appointmentError);
      throw new Error(`Failed to fetch appointment ${appointmentId}: ${errorMsg}`);
    }

    if (!appointment) {
      throw new Error(`Appointment not found for ID ${appointmentId}`);
    }

    console.log(`[Finalize] Appointment found: provider=${appointment.provider_id}, patient=${appointment.patient_id}`);

    // Step 1b: Fetch video session to get actual call end time
    console.log(`[Finalize] Fetching video session for appointment ${appointmentId}...`);
    const { data: session, error: sessionError } = await supabase
      .from('video_call_sessions')
      .select('id, started_at, ended_at, duration_seconds')
      .eq('appointment_id', appointmentId)
      .single();

    if (sessionError) {
      console.warn(`[Finalize] Warning fetching session: ${sessionError.message}`);
    }

    // Step 2: Fetch provider profile using the provider_id (which is a user_id)
    console.log(`[Finalize] Fetching provider profile for user ${appointment.provider_id}...`);
    const { data: providerProfile, error: providerError } = await supabase
      .from('medical_provider_profiles')
      .select('id, display_name, specialty')
      .eq('user_id', appointment.provider_id)
      .single();

    if (providerError) {
      console.warn(`[Finalize] Warning fetching provider profile: ${providerError.message}`);
    }

    // Step 3: Fetch patient profile using the patient_id (which is a user_id)
    console.log(`[Finalize] Fetching patient profile for user ${appointment.patient_id}...`);
    const { data: patientProfile, error: patientError } = await supabase
      .from('patient_profiles')
      .select('id, display_name, age, gender')
      .eq('user_id', appointment.patient_id)
      .single();

    if (patientError) {
      console.warn(`[Finalize] Warning fetching patient profile: ${patientError.message}`);
    }

    // Call generate-soap-from-transcript edge function
    const supabaseUrl = SUPABASE_URL;
    const supabaseKey = SUPABASE_SERVICE_KEY;

    console.log('[Finalize] Calling generate-soap-from-transcript edge function...');

    const soapPromise = fetch(`${supabaseUrl}/functions/v1/generate-soap-from-transcript`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
      },
      body: JSON.stringify({
        sessionId,
        appointmentId,
        transcriptId,
        transcriptText,
        appointmentMetadata: {
          startTime: appointment.start_time || appointment.scheduled_start,
          endTime: session?.ended_at || new Date().toISOString(),
          callDuration: session?.duration_seconds,
          timezone: 'UTC', // appointments table doesn't store timezone, use UTC default
          provider: {
            id: appointment.provider_id,
            name: providerProfile?.display_name || 'Provider',
            specialty: providerProfile?.specialty || 'General',
          },
          patient: {
            id: appointment.patient_id,
            name: patientProfile?.display_name || 'Patient',
            age: patientProfile?.age,
            gender: patientProfile?.gender,
          },
          reasonForVisit: appointment.chief_complaint,
        },
        languageCode: 'en-US',
      }),
    });

    // Wrap with 30-second timeout to prevent hanging
    const response = await withTimeout(soapPromise, 30000, 'SOAP generation edge function call');

    console.log(`[Finalize] SOAP generation response: ${response.status} ${response.statusText}`);

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[Finalize] SOAP generation error response:`, errorText);
      try {
        const error = JSON.parse(errorText);
        throw new Error(`SOAP generation failed (${response.status}): ${error.error || error.message || errorText}`);
      } catch (e) {
        throw new Error(`SOAP generation failed (${response.status}): ${errorText}`);
      }
    }

    const result = await response.json();
    console.log(`[Finalize] SOAP note generated: ${result.soapNoteId}`);

    return result.soapNoteId;
  } catch (error) {
    console.error('[Finalize] Error triggering SOAP generation:', error);
    throw error;
  }
}

/**
 * Mark session as finalized
 */
async function finalizeSession(
  supabase: any,
  sessionId: string,
  success: boolean,
  errorMessage?: string
) {
  console.log(`[Finalize] Marking session as finalized (success=${success})...`);

  await supabase
    .from('video_call_sessions')
    .update({
      status: success ? 'finalized' : 'failed',
      finalization_status: success ? 'completed' : 'failed',
      finalization_error: errorMessage || null,
      updated_at: new Date().toISOString(),
    })
    .eq('id', sessionId);

  // Log audit event
  await supabase.from('video_call_audit_log').insert({
    session_id: sessionId,
    event_type: 'SESSION_FINALIZED',
    event_data: {
      success,
      error: errorMessage,
      timestamp: new Date().toISOString(),
    },
  });
}

serve(async (req: Request) => {
  const origin = req.headers.get('origin');
  const corsHeaders = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { ...corsHeaders, ...securityHeaders } });
  }

  let body: FinalizeCallRequest | null = null;
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    body = await req.json();
    const { sessionId, meetingId, appointmentId, providerId, transcriptionEnabled, recordingEnabled, pipelineId } = body;

    if (!sessionId || !meetingId || !appointmentId) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Missing required fields: sessionId, meetingId, appointmentId',
        }),
        { status: 400, headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`[Finalize] Starting finalization for session ${sessionId}`);

    // Fetch session to get media region
    // Note: sessionId is actually the appointmentId from the frontend
    console.log(`[Finalize] Fetching session for appointment ${appointmentId}`);
    const { data: session, error: sessionError } = await supabase
      .from('video_call_sessions')
      .select('id, media_region')
      .eq('appointment_id', appointmentId)
      .single();

    if (sessionError) {
      console.error(`[Finalize] Session fetch error:`, sessionError);
      console.error(`  Code: ${sessionError.code}`);
      console.error(`  Message: ${sessionError.message}`);
      console.error(`  Details: ${sessionError.details}`);
      const errorMsg = sessionError.message || sessionError.code || JSON.stringify(sessionError);
      throw new Error(`Failed to fetch session for appointment ${appointmentId}: ${errorMsg}`);
    }

    if (!session || !session.id) {
      console.error(`[Finalize] Invalid session data:`, session);
      throw new Error(`Session data invalid for appointment ${appointmentId}: ${JSON.stringify(session)}`);
    }

    console.log(`[Finalize] Session found: id=${session.id}, region=${session.media_region}`);

    // Use the actual session ID from the database for subsequent queries
    const actualSessionId = session.id;
    console.log(`[Finalize] Using session ID: ${actualSessionId}`);

    const mediaRegion = session?.media_region || 'eu-central-1';

    // Step 1: Stop transcription and merge captions
    let transcriptId = '';
    let transcriptText = '';
    let speakerSegments = [];

    if (transcriptionEnabled) {
      console.log('[Finalize] Step 1: Stopping transcription and merging captions...');
      try {
        const result = await stopTranscriptionAndMerge(supabase, actualSessionId, appointmentId, meetingId, mediaRegion);
        transcriptId = result.transcriptId;
        transcriptText = result.transcriptText;
        speakerSegments = result.speakerSegments;
        console.log(`[Finalize] Transcription complete: ${transcriptText.length} chars, ${speakerSegments.length} speakers`);
      } catch (e) {
        console.error('[Finalize] Transcription error:', e);
        throw e;
      }
    }

    // Step 2: Build speaker map
    console.log('[Finalize] Step 2: Building speaker map...');
    try {
      await buildSpeakerMap(supabase, actualSessionId);
      console.log('[Finalize] Speaker map built');
    } catch (e) {
      console.error('[Finalize] Speaker map error:', e);
      throw e;
    }

    // Step 3: Start post-call Transcribe Medical job (async, no wait)
    if (recordingEnabled && pipelineId) {
      startTranscribeMedicalJob(supabase, actualSessionId, meetingId, pipelineId).catch(error =>
        console.error('[Finalize] Background transcription job failed:', error)
      );
    }

    // Step 4: Trigger SOAP note generation
    let soapNoteId = '';
    if (transcriptionEnabled && transcriptText) {
      console.log('[Finalize] Step 4: Triggering SOAP note generation...');
      try {
        // Wait for SOAP generation with a reasonable timeout (40 seconds)
        soapNoteId = await withTimeout(
          triggerSOAPGeneration(supabase, actualSessionId, appointmentId, transcriptId, transcriptText),
          40000,
          'SOAP note generation'
        );
        console.log(`[Finalize] SOAP note generated: ${soapNoteId}`);
      } catch (e) {
        console.error('[Finalize] SOAP generation error (will continue):', e);
        // Don't throw - allow finalization to continue without SOAP note
        // The transcript will still be available for manual review
      }
    } else {
      console.log(`[Finalize] Skipping SOAP generation: transcriptionEnabled=${transcriptionEnabled}, transcriptText length=${transcriptText.length}`);
    }

    // Step 5: Finalize session
    console.log('[Finalize] Step 5: Finalizing session...');
    try {
      await finalizeSession(supabase, actualSessionId, true);
      console.log('[Finalize] Session finalized');
    } catch (e) {
      console.error('[Finalize] Finalize session error:', e);
      throw e;
    }

    console.log(`[Finalize] Session finalization complete for ${actualSessionId}`);

    // Step 6: Fetch the generated SOAP note to return complete content to provider for review
    let soapNoteContent = null;
    if (soapNoteId) {
      try {
        console.log(`[Finalize] Fetching SOAP note ${soapNoteId} for review...`);
        const { data: soapNote, error: soapError } = await supabase
          .from('soap_notes')
          .select('*')
          .eq('id', soapNoteId)
          .single();

        if (soapError) {
          console.warn(`[Finalize] Warning fetching SOAP note: ${soapError.message}`);
        } else if (soapNote) {
          soapNoteContent = soapNote;
          console.log(`[Finalize] SOAP note fetched successfully`);
        }
      } catch (e) {
        console.error('[Finalize] Error fetching SOAP note:', e);
        // Don't throw - return what we have
      }
    }

    console.log(`[Finalize] Finalization complete - returning data to provider`);
    console.log(`  Session: ${actualSessionId}`);
    console.log(`  Transcript: ${transcriptText.length} chars`);
    console.log(`  SOAP Note: ${soapNoteId ? 'available' : 'generating or failed'}`);

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Video call finalized successfully',
        data: {
          sessionId: actualSessionId,
          transcriptId: transcriptId || null,
          transcript: transcriptText || null,
          transcriptLength: transcriptText.length,
          soapNoteId: soapNoteId || null,
          soapNote: soapNoteContent || null,
          speakerCount: speakerSegments.length,
          speakerSegments: speakerSegments,
        },
      }),
      { status: 200, headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    // Enhanced error logging
    console.error('[Finalize] ERROR in main handler:', error);
    if (error instanceof Error) {
      console.error(`  Error name: ${error.name}`);
      console.error(`  Error message: ${error.message}`);
      console.error(`  Error stack: ${error.stack}`);
    } else {
      console.error(`  Error (non-Error object):`, JSON.stringify(error));
    }
    console.error('[Finalize] Request body:', body);

    // Extract error message
    let errorMessage = 'Unknown error';
    if (error instanceof Error) {
      errorMessage = error.message;
    } else if (typeof error === 'object' && error !== null && 'message' in error) {
      errorMessage = String((error as any).message);
    } else if (typeof error === 'string') {
      errorMessage = error;
    } else {
      errorMessage = JSON.stringify(error);
    }

    // Try to update session with error
    try {
      if (body && body.appointmentId) {
        const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

        // First try to fetch the actual session ID from appointmentId
        const { data: sessionData } = await supabase
          .from('video_call_sessions')
          .select('id')
          .eq('appointment_id', body.appointmentId)
          .single();

        if (sessionData?.id) {
          await finalizeSession(
            supabase,
            sessionData.id,
            false,
            errorMessage
          );
        }
      }
    } catch (cleanupError) {
      console.error('[Finalize] Cleanup error:', cleanupError);
      // Ignore cleanup errors
    }

    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage || 'Failed to finalize call',
        code: 'FINALIZATION_ERROR',
        timestamp: new Date().toISOString(),
      }),
      { status: 500, headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
