/**
 * Finalize Transcript Edge Function
 *
 * Merges live caption segments into a final transcript and updates
 * the video_call_sessions table with the merged transcript text.
 * Sets transcript_status to 'ready' to trigger polling-based SOAP generation.
 *
 * This is a focused function that handles ONLY transcript finalization,
 * separate from the broader finalize-video-call orchestration.
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { verifyFirebaseToken } from '../_shared/verify-firebase-jwt.ts';
import { getCorsHeaders, securityHeaders } from '../_shared/cors.ts';
import { checkRateLimit, getRateLimitConfig, createRateLimitErrorResponse } from '../_shared/rate-limiter.ts';

interface FinalizeTranscriptRequest {
  sessionId: string;
}

serve(async (req: Request) => {
  const origin = req.headers.get('origin');
  const corsHeaders = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { ...corsHeaders, ...securityHeaders } });
  }

  try {
    // Verify Firebase JWT
    const authHeader = req.headers.get('x-firebase-token') || '';

    if (!authHeader) {
      return new Response(
        JSON.stringify({
          error: 'Missing x-firebase-token header',
          code: 'INVALID_REQUEST',
          status: 401,
        }),
        {
          status: 401,
          headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Get Firebase project ID from environment
    const firebaseProjectId = Deno.env.get('FIREBASE_PROJECT_ID');
    if (!firebaseProjectId) {
      console.error('[Transcript] ERROR: FIREBASE_PROJECT_ID environment variable not set');
      return new Response(
        JSON.stringify({
          error: 'Missing FIREBASE_PROJECT_ID secret',
          code: 'CONFIG_ERROR',
          status: 500,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Verify Firebase JWT token
    let auth;
    try {
      auth = await verifyFirebaseToken(authHeader, firebaseProjectId);
    } catch (tokenError) {
      console.error('[Transcript] Token verification failed:', tokenError);
      return new Response(
        JSON.stringify({
          error: 'Invalid or expired token',
          code: 'INVALID_FIREBASE_TOKEN',
          status: 401,
        }),
        {
          status: 401,
          headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    if (!auth || !auth.user_id) {
      return new Response(
        JSON.stringify({
          error: 'Unauthorized',
          code: 'INVALID_FIREBASE_TOKEN',
          status: 401,
        }),
        {
          status: 401,
          headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Rate limiting check (HIPAA: Prevents DDoS and abuse)
    const rateLimitConfig = getRateLimitConfig('finalize-transcript', auth.user_id);
    const rateLimit = await checkRateLimit(rateLimitConfig);
    if (!rateLimit.allowed) {
      console.warn(`🚫 Rate limit exceeded for user ${auth.user_id}`);
      return createRateLimitErrorResponse(rateLimit);
    }

    // Parse request body
    const body = (await req.json()) as FinalizeTranscriptRequest;
    const { sessionId } = body;

    if (!sessionId) {
      return new Response(
        JSON.stringify({
          error: 'Missing sessionId',
          code: 'INVALID_REQUEST',
          status: 400,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, ...securityHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    console.log(`📝 Finalizing transcript for session: ${sessionId}`);

    // Create Supabase admin client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') || '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    );

    // Step 1: Fetch all final caption segments
    console.log('[Transcript] Fetching live caption segments...');

    const { data: segments, error: segmentsError } = await supabase
      .from('live_caption_segments')
      .select('id, attendee_id, speaker_name, transcript_text, start_time_ms, created_at')
      .eq('session_id', sessionId)
      .eq('is_partial', false)
      .order('start_time_ms', { ascending: true });

    if (segmentsError) {
      console.error('[Transcript] Error fetching segments:', segmentsError);
      throw new Error(
        `Failed to fetch segments: ${segmentsError.message || JSON.stringify(segmentsError)}`
      );
    }

    console.log(
      `[Transcript] Found ${segments?.length || 0} final caption segments`
    );

    // Step 2: Merge segments into full transcript
    let fullTranscript = '';
    const speakerSegments: Array<{
      speaker_id: string;
      text: string;
      timestamp: string;
    }> = [];

    if (segments && segments.length > 0) {
      for (const segment of segments) {
        fullTranscript += (fullTranscript ? ' ' : '') + (segment.transcript_text || '');

        speakerSegments.push({
          speaker_id: segment.attendee_id || 'unknown',
          text: segment.transcript_text || '',
          timestamp: segment.created_at,
        });
      }
    }

    console.log(
      `[Transcript] Merged transcript: ${fullTranscript.length} characters`
    );

    // Step 3: Update video_call_sessions with transcript and status
    console.log('[Transcript] Updating session with transcript...');

    const now = new Date().toISOString();

    // Debug: Log the sessionId to ensure it's valid
    console.log(`[Transcript] Session ID for update: ${sessionId}`);

    const { data: updatedSession, error: updateError } = await supabase
      .from('video_call_sessions')
      .update({
        transcript_text: fullTranscript || null,
        transcript_status: fullTranscript && fullTranscript.length > 0
          ? 'ready'
          : 'failed',
        transcript_updated_at: now,
        // Queue SOAP generation if transcript is ready
        soap_status: fullTranscript && fullTranscript.length > 0
          ? 'queued'
          : 'none',
        soap_updated_at: now,
      })
      .eq('id', sessionId)
      .select('id, transcript_status, soap_status, transcript_text')
      .single();

    if (updateError) {
      console.error('[Transcript] Error updating session:', updateError);
      throw new Error(
        `Failed to update session: ${updateError.message || JSON.stringify(updateError)}`
      );
    }

    console.log(
      `[Transcript] ✅ Session updated with status: ${updatedSession.transcript_status}`
    );

    // Step 4: Return success response
    return new Response(
      JSON.stringify({
        success: true,
        transcriptLength: fullTranscript.length,
        segmentCount: segments?.length || 0,
        transcriptStatus: updatedSession.transcript_status,
        soapStatus: updatedSession.soap_status,
        message: `Finalized transcript: ${fullTranscript.length} characters from ${segments?.length || 0} segments`,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('[Transcript] Error:', error);

    return new Response(
      JSON.stringify({
        error: error instanceof Error
          ? error.message
          : 'Unknown error during transcript finalization',
        code: 'FINALIZE_ERROR',
        status: 500,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
