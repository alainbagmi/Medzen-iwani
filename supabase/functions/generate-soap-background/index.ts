/**
 * Generate SOAP Background Job
 *
 * Generates SOAP (Subjective, Objective, Assessment, Plan) clinical notes
 * from finalized transcripts using AWS Bedrock Claude model.
 *
 * This is a background job triggered when transcript_status = 'ready'.
 * Updates soap_status from 'queued' → 'generating' → 'ready'/'failed'.
 *
 * Supports both modes:
 * - 'automatic': Full SOAP generation from transcript (default)
 * - 'on-demand': Enhancement/refinement with existing SOAP context (user-initiated)
 *
 * Decoupled from UI to prevent long-running operations from blocking dialog.
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { verifyFirebaseToken } from '../_shared/verify-firebase-jwt.ts';
import { getCorsHeaders, securityHeaders } from '../_shared/cors.ts';
import { checkRateLimit, getRateLimitConfig, createRateLimitErrorResponse } from '../_shared/rate-limiter.ts';
import {
  BedrockRuntimeClient,
  InvokeModelCommand,
} from 'npm:@aws-sdk/client-bedrock-runtime@3.716.0';

interface GenerateSoapRequest {
  sessionId: string;
  mode?: 'automatic' | 'on-demand';
  existingSoap?: SoapStructure;
}

interface SoapStructure {
  subjective: string;
  objective: string;
  assessment: string;
  plan: string;
}

serve(async (req: Request) => {
  const origin = req.headers.get('origin');
  const corsHeaders_dynamic = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { ...corsHeaders_dynamic, ...securityHeaders } });
  }

  try {
    // Verify Firebase JWT
    const authHeader = req.headers.get('x-firebase-token') || '';
    const auth = await verifyFirebaseToken(authHeader);

    if (!auth.valid) {
      return new Response(
        JSON.stringify({
          error: 'Unauthorized',
          code: 'INVALID_FIREBASE_TOKEN',
          status: 401,
        }),
        {
          status: 401,
          headers: { ...corsHeaders_dynamic, ...securityHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Rate limiting check
    const rateLimitConfig = getRateLimitConfig('generate-soap-background', auth.user_id || auth.sub || '');
    const rateLimit = await checkRateLimit(rateLimitConfig);
    if (!rateLimit.allowed) {
      return createRateLimitErrorResponse(rateLimit);
    }

    // Parse request body
    const body = (await req.json()) as GenerateSoapRequest;
    const { sessionId, mode = 'automatic', existingSoap } = body;

    if (!sessionId) {
      return new Response(
        JSON.stringify({
          error: 'Missing sessionId',
          code: 'INVALID_REQUEST',
          status: 400,
        }),
        {
          status: 400,
          headers: { ...corsHeaders_dynamic, ...securityHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const modeLabel = mode === 'on-demand' ? '✨ Enhancing' : '📋 Generating';
    console.log(`${modeLabel} SOAP for session: ${sessionId} (mode: ${mode})`);

    // Create Supabase admin client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') || '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    );

    // Step 1: Fetch session with transcript
    console.log('[SOAP] Fetching session with transcript...');

    const { data: session, error: sessionError } = await supabase
      .from('video_call_sessions')
      .select('id, transcript_text, soap_status, provider_id, patient_id, appointment_id')
      .eq('session_id', sessionId)
      .single();

    if (sessionError || !session) {
      console.error('[SOAP] Error fetching session:', sessionError);
      throw new Error(
        `Failed to fetch session: ${sessionError?.message || 'Session not found'}`
      );
    }

    const transcript = session.transcript_text as string | null;

    if (!transcript || transcript.length === 0) {
      console.log('[SOAP] ⚠️  Transcript empty, marking as failed');

      // Update to failed if transcript is empty
      await supabase
        .from('video_call_sessions')
        .update({
          soap_status: 'failed',
          soap_error: 'Empty or missing transcript',
          soap_updated_at: new Date().toISOString(),
        })
        .eq('session_id', sessionId);

      return new Response(
        JSON.stringify({
          success: false,
          error: 'Transcript is empty',
          code: 'EMPTY_TRANSCRIPT',
          status: 400,
        }),
        {
          status: 400,
          headers: { ...corsHeaders_dynamic, ...securityHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    // Step 2: Update status to 'generating'
    console.log('[SOAP] Updating session status to generating...');

    const now = new Date().toISOString();

    const { error: updateStatusError } = await supabase
      .from('video_call_sessions')
      .update({
        soap_status: 'generating',
        soap_updated_at: now,
      })
      .eq('session_id', sessionId);

    if (updateStatusError) {
      console.error('[SOAP] Error updating status:', updateStatusError);
      throw new Error(
        `Failed to update status: ${updateStatusError.message || JSON.stringify(updateStatusError)}`
      );
    }

    console.log(`[SOAP] ⏳ Processing from ${transcript.length} character transcript...`);

    // Step 3: Call AWS Bedrock Claude to generate SOAP
    const bedrockClient = new BedrockRuntimeClient({
      region: 'eu-central-1',
      credentials: {
        accessKeyId: Deno.env.get('AWS_ACCESS_KEY_ID') || '',
        secretAccessKey: Deno.env.get('AWS_SECRET_ACCESS_KEY') || '',
      },
    });

    // Generate prompt based on mode
    let prompt: string;
    let maxTokens = 4096;

    if (mode === 'on-demand' && existingSoap) {
      // On-demand enhancement: refine existing SOAP with transcript context
      maxTokens = 2048; // On-demand is lighter weight
      prompt = `You are a medical documentation specialist. Review and enhance the existing SOAP note with additional details from the consultation transcript.

EXISTING SOAP NOTE:
- Subjective: ${existingSoap.subjective}
- Objective: ${existingSoap.objective}
- Assessment: ${existingSoap.assessment}
- Plan: ${existingSoap.plan}

TRANSCRIPT:
${transcript}

Please enhance the SOAP note by:
1. Adding any missed details from the transcript
2. Correcting any inaccuracies
3. Clarifying vague entries
4. Maintaining clinical accuracy

Provide the response as a valid JSON object with these four keys:
- subjective: String (enhanced with any additional details)
- objective: String (enhanced with missing observations)
- assessment: String (enhanced with additional clinical insights)
- plan: String (enhanced with complete treatment recommendations)

Important:
- Return ONLY valid JSON, no additional text
- Ensure all four fields are present
- Preserve accurate information from the original note
- Add new information only if clinically relevant

JSON Response:`;
    } else {
      // Automatic mode: full SOAP generation from transcript
      prompt = `You are a medical documentation specialist. Generate a SOAP (Subjective, Objective, Assessment, Plan) clinical note from the following medical consultation transcript.

TRANSCRIPT:
${transcript}

Please provide the response as a valid JSON object with exactly these four keys:
- subjective: String (patient's symptoms, complaints, and medical history mentioned)
- objective: String (vital signs, observations, clinical findings)
- assessment: String (clinical diagnosis and interpretation of findings)
- plan: String (treatment recommendations, medications, follow-up)

Important:
- Make the response concise but comprehensive
- Focus on clinically relevant information
- Return ONLY valid JSON, no additional text
- Ensure all four fields are present even if some are empty

JSON Response:`;
    }

    console.log(`[SOAP] Calling AWS Bedrock Claude model (mode: ${mode}, tokens: ${maxTokens})...`);

    const invokeCommand = new InvokeModelCommand({
      modelId: 'anthropic.claude-3-haiku-20240307-v1:0',
      contentType: 'application/json',
      accept: 'application/json',
      body: JSON.stringify({
        anthropic_version: 'bedrock-2023-05-31',
        max_tokens: maxTokens,
        messages: [
          {
            role: 'user',
            content: prompt,
          },
        ],
      }),
    });

    const bedrockResponse = await bedrockClient.send(invokeCommand);

    // Parse Bedrock response
    console.log('[SOAP] Parsing Bedrock response...');

    const responseBody = JSON.parse(
      new TextDecoder().decode(bedrockResponse.body)
    );

    let soapJson: SoapStructure;

    if (responseBody.content && Array.isArray(responseBody.content)) {
      const textContent = responseBody.content.find(
        (c: { type: string }) => c.type === 'text'
      ) as { type: string; text: string } | undefined;

      if (!textContent) {
        throw new Error('No text content in Bedrock response');
      }

      // Extract JSON from response (Claude might add markdown or extra text)
      const jsonMatch = textContent.text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        console.error('[SOAP] Could not find JSON in response:', textContent.text);
        throw new Error('Could not parse JSON from Bedrock response');
      }

      soapJson = JSON.parse(jsonMatch[0]) as SoapStructure;
    } else {
      throw new Error('Unexpected Bedrock response format');
    }

    // Validate SOAP structure - ensure all keys exist
    if (
      !soapJson.subjective &&
      !soapJson.objective &&
      !soapJson.assessment &&
      !soapJson.plan
    ) {
      throw new Error('SOAP response missing all required fields');
    }

    // Provide defaults for missing fields
    soapJson = {
      subjective: soapJson.subjective || 'Not documented',
      objective: soapJson.objective || 'Not documented',
      assessment: soapJson.assessment || 'Not documented',
      plan: soapJson.plan || 'Not documented',
    };

    console.log('[SOAP] ✅ SOAP generated successfully');

    // Step 4: Update session with SOAP and mark as ready
    console.log('[SOAP] Saving SOAP to database...');

    const { data: updatedSession, error: saveSoapError } = await supabase
      .from('video_call_sessions')
      .update({
        soap_json: soapJson,
        soap_status: 'ready',
        soap_updated_at: now,
      })
      .eq('session_id', sessionId)
      .select('id, soap_status, soap_json')
      .single();

    if (saveSoapError) {
      console.error('[SOAP] Error saving SOAP:', saveSoapError);
      throw new Error(
        `Failed to save SOAP: ${saveSoapError.message || JSON.stringify(saveSoapError)}`
      );
    }

    console.log(`[SOAP] ✅ Session updated with SOAP status: ${updatedSession.soap_status}`);

    // Step 5: Return success response
    return new Response(
      JSON.stringify({
        success: true,
        soapStatus: updatedSession.soap_status,
        soap: soapJson,
        message: 'SOAP note generated successfully',
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (error) {
    console.error('[SOAP] Error:', error);

    // Try to update session with error status
    try {
      const authHeader = req.headers.get('x-firebase-token') || '';
      const auth = await verifyFirebaseToken(authHeader);

      if (auth.valid) {
        const body = (await req.clone().json()) as GenerateSoapRequest;
        if (body?.sessionId) {
          const supabase = createClient(
            Deno.env.get('SUPABASE_URL') || '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
          );

          await supabase
            .from('video_call_sessions')
            .update({
              soap_status: 'failed',
              soap_error: error instanceof Error ? error.message : String(error),
              soap_updated_at: new Date().toISOString(),
            })
            .eq('session_id', body.sessionId);
        }
      }
    } catch (updateError) {
      console.error('[SOAP] Could not update session with error:', updateError);
    }

    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : 'Unknown error during SOAP generation',
        code: 'SOAP_GENERATION_ERROR',
        status: 500,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
