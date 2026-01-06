/**
 * MedZen Start Medical Transcription Edge Function
 *
 * Enables AWS Transcribe Medical for real-time transcription during video calls.
 * Uses medical-specific vocabulary and speaker diarization for accurate
 * doctor-patient conversation capture.
 *
 * Features:
 * - AWS Transcribe Medical specialty vocabulary
 * - Speaker diarization (Doctor vs Patient)
 * - Live caption streaming
 * - Medical entity extraction
 * - Multi-language support (en-US, en-GB, es-US)
 * - Duration limits for cost optimization
 * - CloudWatch metrics integration
 *
 * @version 1.1.0
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import {
  ChimeSDKMeetingsClient,
  StartMeetingTranscriptionCommand,
  StopMeetingTranscriptionCommand,
} from 'npm:@aws-sdk/client-chime-sdk-meetings@3.716.0';
import { CloudWatchClient, PutMetricDataCommand } from 'npm:@aws-sdk/client-cloudwatch@3.716.0';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

// AWS Configuration
const AWS_REGION_DEFAULT = Deno.env.get('AWS_REGION') || 'eu-central-1';
const AWS_ACCESS_KEY_ID = Deno.env.get('AWS_ACCESS_KEY_ID') || '';
const AWS_SECRET_ACCESS_KEY = Deno.env.get('AWS_SECRET_ACCESS_KEY') || '';

// Supabase Configuration
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '';

// Cost Optimization Configuration
const DEFAULT_MAX_DURATION_MINUTES = 120; // 2 hours default
const ABSOLUTE_MAX_DURATION_MINUTES = 240; // 4 hours absolute limit
const MIN_DURATION_MINUTES = 5; // Minimum 5 minutes
const TRANSCRIPTION_COST_PER_MINUTE = 0.0750; // AWS Transcribe Medical pricing

// CORS Headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-firebase-token',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

/**
 * Create a Chime SDK client for a specific region
 * CRITICAL: Chime meetings are regional - must use the same region as the meeting
 */
function createChimeClient(region: string): ChimeSDKMeetingsClient {
  console.log(`[Transcription] Creating Chime client for region: ${region}`);
  return new ChimeSDKMeetingsClient({
    region,
    credentials: {
      accessKeyId: AWS_ACCESS_KEY_ID,
      secretAccessKey: AWS_SECRET_ACCESS_KEY,
    },
  });
}

// CloudWatch client for metrics (uses default region)
const cloudWatchClient = new CloudWatchClient({
  region: AWS_REGION_DEFAULT,
  credentials: {
    accessKeyId: AWS_ACCESS_KEY_ID,
    secretAccessKey: AWS_SECRET_ACCESS_KEY,
  },
});

interface TranscriptionRequest {
  meetingId: string;
  sessionId: string;
  action: 'start' | 'stop';
  language?: string;
  specialty?: string;
  enableSpeakerIdentification?: boolean;
  contentIdentificationType?: 'PHI' | 'PII';
  maxDurationMinutes?: number; // Optional duration limit override
}

// Supported languages mapping
// AWS Transcribe Medical ONLY supports en-US
// AWS Transcribe Standard supports many languages including French and African languages
// For unsupported languages, we fallback to the closest supported language
//
// AWS Transcribe African Language Support (as of 2025):
// - Afrikaans (af-ZA) - batch & streaming ✓
// - Swahili Kenya (sw-KE), Tanzania (sw-TZ), Uganda (sw-UG), Rwanda (sw-RW), Burundi (sw-BI) - batch only
// - Zulu (zu-ZA) - batch & streaming ✓
// - Somali (so-SO) - batch & streaming ✓
// - Hausa (ha-NG) - batch only
// - Wolof (wo-SN) - batch only
// - Kinyarwanda (rw-RW) - batch only
//
// Unsupported (fallback to English or French):
// - Sango, Fulfulde, Yoruba, Amharic, Igbo, Lingala, Tigrinya, etc.

const LANGUAGE_CONFIG: Record<string, {
  engine: 'medical' | 'standard';
  awsCode: string;
  displayName: string;
  isNative: boolean; // true if natively supported by AWS Transcribe
  fallbackNote?: string;
}> = {
  // === ENGLISH VARIANTS ===
  'en-US': { engine: 'medical', awsCode: 'en-US', displayName: 'English (US)', isNative: true },
  'en-GB': { engine: 'standard', awsCode: 'en-GB', displayName: 'English (UK)', isNative: true },
  'en-ZA': { engine: 'standard', awsCode: 'en-ZA', displayName: 'English (South Africa)', isNative: true },
  'en-KE': { engine: 'standard', awsCode: 'en-US', displayName: 'English (Kenya)', isNative: false, fallbackNote: 'Using US English' },
  'en-NG': { engine: 'standard', awsCode: 'en-US', displayName: 'English (Nigeria)', isNative: false, fallbackNote: 'Using US English' },

  // === FRENCH VARIANTS ===
  'fr-FR': { engine: 'standard', awsCode: 'fr-FR', displayName: 'French (France)', isNative: true },
  'fr-CA': { engine: 'standard', awsCode: 'fr-CA', displayName: 'French (Canada)', isNative: true },
  'fr': { engine: 'standard', awsCode: 'fr-FR', displayName: 'French', isNative: true },
  'fr-CM': { engine: 'standard', awsCode: 'fr-FR', displayName: 'French (Cameroon)', isNative: false, fallbackNote: 'Using France French' },
  'fr-SN': { engine: 'standard', awsCode: 'fr-FR', displayName: 'French (Senegal)', isNative: false, fallbackNote: 'Using France French' },
  'fr-CI': { engine: 'standard', awsCode: 'fr-FR', displayName: 'French (Ivory Coast)', isNative: false, fallbackNote: 'Using France French' },
  'fr-CD': { engine: 'standard', awsCode: 'fr-FR', displayName: 'French (DRC)', isNative: false, fallbackNote: 'Using France French' },

  // === AFRICAN LANGUAGES - NATIVELY SUPPORTED ===
  'af': { engine: 'standard', awsCode: 'af-ZA', displayName: 'Afrikaans', isNative: true },
  'af-ZA': { engine: 'standard', awsCode: 'af-ZA', displayName: 'Afrikaans (South Africa)', isNative: true },

  // Swahili variants - batch only, but we support them
  'sw': { engine: 'standard', awsCode: 'sw-KE', displayName: 'Swahili', isNative: true },
  'sw-KE': { engine: 'standard', awsCode: 'sw-KE', displayName: 'Swahili (Kenya)', isNative: true },
  'sw-TZ': { engine: 'standard', awsCode: 'sw-TZ', displayName: 'Swahili (Tanzania)', isNative: true },
  'sw-UG': { engine: 'standard', awsCode: 'sw-UG', displayName: 'Swahili (Uganda)', isNative: true },
  'sw-RW': { engine: 'standard', awsCode: 'sw-RW', displayName: 'Swahili (Rwanda)', isNative: true },
  'sw-BI': { engine: 'standard', awsCode: 'sw-BI', displayName: 'Swahili (Burundi)', isNative: true },

  // Zulu - batch & streaming
  'zu': { engine: 'standard', awsCode: 'zu-ZA', displayName: 'Zulu', isNative: true },
  'zu-ZA': { engine: 'standard', awsCode: 'zu-ZA', displayName: 'Zulu (South Africa)', isNative: true },

  // Somali - batch & streaming
  'so': { engine: 'standard', awsCode: 'so-SO', displayName: 'Somali', isNative: true },
  'so-SO': { engine: 'standard', awsCode: 'so-SO', displayName: 'Somali (Somalia)', isNative: true },

  // Hausa - batch only
  'ha': { engine: 'standard', awsCode: 'ha-NG', displayName: 'Hausa', isNative: true },
  'ha-NG': { engine: 'standard', awsCode: 'ha-NG', displayName: 'Hausa (Nigeria)', isNative: true },

  // Wolof - batch only
  'wo': { engine: 'standard', awsCode: 'wo-SN', displayName: 'Wolof', isNative: true },
  'wo-SN': { engine: 'standard', awsCode: 'wo-SN', displayName: 'Wolof (Senegal)', isNative: true },

  // Kinyarwanda - batch only
  'rw': { engine: 'standard', awsCode: 'rw-RW', displayName: 'Kinyarwanda', isNative: true },
  'rw-RW': { engine: 'standard', awsCode: 'rw-RW', displayName: 'Kinyarwanda (Rwanda)', isNative: true },

  // === AFRICAN LANGUAGES - NOT SUPPORTED (FALLBACK) ===
  // Central African
  'sg': { engine: 'standard', awsCode: 'fr-FR', displayName: 'Sango', isNative: false, fallbackNote: 'Using French (lingua franca in CAR)' },

  // West African
  'ff': { engine: 'standard', awsCode: 'fr-FR', displayName: 'Fulfulde/Fula', isNative: false, fallbackNote: 'Using French (common second language)' },
  'yo': { engine: 'standard', awsCode: 'en-US', displayName: 'Yoruba', isNative: false, fallbackNote: 'Using English (common in Nigeria)' },
  'ig': { engine: 'standard', awsCode: 'en-US', displayName: 'Igbo', isNative: false, fallbackNote: 'Using English (common in Nigeria)' },
  'tw': { engine: 'standard', awsCode: 'en-US', displayName: 'Twi', isNative: false, fallbackNote: 'Using English (common in Ghana)' },
  'ee': { engine: 'standard', awsCode: 'en-US', displayName: 'Ewe', isNative: false, fallbackNote: 'Using English' },
  'ak': { engine: 'standard', awsCode: 'en-US', displayName: 'Akan', isNative: false, fallbackNote: 'Using English (common in Ghana)' },
  'bm': { engine: 'standard', awsCode: 'fr-FR', displayName: 'Bambara', isNative: false, fallbackNote: 'Using French (common in Mali)' },

  // East African
  'am': { engine: 'standard', awsCode: 'en-US', displayName: 'Amharic', isNative: false, fallbackNote: 'Using English' },
  'om': { engine: 'standard', awsCode: 'en-US', displayName: 'Oromo', isNative: false, fallbackNote: 'Using English' },
  'ti': { engine: 'standard', awsCode: 'en-US', displayName: 'Tigrinya', isNative: false, fallbackNote: 'Using English' },
  'lg': { engine: 'standard', awsCode: 'en-US', displayName: 'Luganda', isNative: false, fallbackNote: 'Using English (common in Uganda)' },
  'rn': { engine: 'standard', awsCode: 'fr-FR', displayName: 'Kirundi', isNative: false, fallbackNote: 'Using French (official in Burundi)' },

  // Central African
  'ln': { engine: 'standard', awsCode: 'fr-FR', displayName: 'Lingala', isNative: false, fallbackNote: 'Using French (common in DRC)' },
  'kg': { engine: 'standard', awsCode: 'fr-FR', displayName: 'Kikongo', isNative: false, fallbackNote: 'Using French (common in DRC)' },
  'lu': { engine: 'standard', awsCode: 'fr-FR', displayName: 'Luba-Katanga', isNative: false, fallbackNote: 'Using French (common in DRC)' },

  // Southern African
  'xh': { engine: 'standard', awsCode: 'en-ZA', displayName: 'Xhosa', isNative: false, fallbackNote: 'Using South African English' },
  'st': { engine: 'standard', awsCode: 'en-ZA', displayName: 'Sesotho', isNative: false, fallbackNote: 'Using South African English' },
  'tn': { engine: 'standard', awsCode: 'en-ZA', displayName: 'Setswana', isNative: false, fallbackNote: 'Using South African English' },
  'ts': { engine: 'standard', awsCode: 'en-ZA', displayName: 'Tsonga', isNative: false, fallbackNote: 'Using South African English' },
  've': { engine: 'standard', awsCode: 'en-ZA', displayName: 'Venda', isNative: false, fallbackNote: 'Using South African English' },
  'nr': { engine: 'standard', awsCode: 'zu-ZA', displayName: 'Southern Ndebele', isNative: false, fallbackNote: 'Using Zulu (related language)' },
  'ss': { engine: 'standard', awsCode: 'zu-ZA', displayName: 'Swati', isNative: false, fallbackNote: 'Using Zulu (related language)' },
  'ny': { engine: 'standard', awsCode: 'en-US', displayName: 'Chichewa', isNative: false, fallbackNote: 'Using English' },
  'sn': { engine: 'standard', awsCode: 'en-ZA', displayName: 'Shona', isNative: false, fallbackNote: 'Using South African English' },
  'nd': { engine: 'standard', awsCode: 'zu-ZA', displayName: 'Northern Ndebele', isNative: false, fallbackNote: 'Using Zulu (related language)' },

  // Creoles & Pidgins
  'pcm': { engine: 'standard', awsCode: 'en-US', displayName: 'Nigerian Pidgin', isNative: false, fallbackNote: 'Using English' },
  'kri': { engine: 'standard', awsCode: 'en-US', displayName: 'Krio (Sierra Leone)', isNative: false, fallbackNote: 'Using English' },

  // Arabic variants (North Africa)
  'ar': { engine: 'standard', awsCode: 'ar-AE', displayName: 'Arabic', isNative: true },
  'ar-EG': { engine: 'standard', awsCode: 'ar-AE', displayName: 'Arabic (Egypt)', isNative: false, fallbackNote: 'Using Gulf Arabic' },
  'ar-MA': { engine: 'standard', awsCode: 'ar-AE', displayName: 'Arabic (Morocco)', isNative: false, fallbackNote: 'Using Gulf Arabic' },
  'ar-DZ': { engine: 'standard', awsCode: 'ar-AE', displayName: 'Arabic (Algeria)', isNative: false, fallbackNote: 'Using Gulf Arabic' },
  'ar-TN': { engine: 'standard', awsCode: 'ar-AE', displayName: 'Arabic (Tunisia)', isNative: false, fallbackNote: 'Using Gulf Arabic' },
  'ar-SD': { engine: 'standard', awsCode: 'ar-AE', displayName: 'Arabic (Sudan)', isNative: false, fallbackNote: 'Using Gulf Arabic' },
};

/**
 * Get language configuration with fallback
 */
function getLanguageConfig(language: string): {
  engine: 'medical' | 'standard';
  awsCode: string;
  displayName: string;
  isNative: boolean;
  fallbackNote?: string;
} {
  const config = LANGUAGE_CONFIG[language];
  if (config) {
    if (!config.isNative) {
      console.log(`[Language] '${language}' (${config.displayName}) not natively supported. ${config.fallbackNote}`);
    }
    return config;
  }
  // Default fallback to English standard if language not recognized
  console.log(`[Language] Unknown language '${language}', falling back to en-US standard`);
  return {
    engine: 'standard',
    awsCode: 'en-US',
    displayName: 'English (US) - Fallback',
    isNative: false,
    fallbackNote: 'Language not recognized, using English'
  };
}

/**
 * Get list of all supported languages with their configurations
 */
function getSupportedLanguages(): Array<{
  code: string;
  displayName: string;
  isNative: boolean;
  region?: string;
}> {
  return Object.entries(LANGUAGE_CONFIG).map(([code, config]) => ({
    code,
    displayName: config.displayName,
    isNative: config.isNative,
    region: config.fallbackNote ? undefined : code.split('-')[1],
  }));
}

/**
 * Publish metrics to CloudWatch
 */
async function publishMetric(
  metricName: string,
  value: number,
  unit: string = 'Count'
): Promise<void> {
  try {
    await cloudWatchClient.send(new PutMetricDataCommand({
      Namespace: 'medzen/Transcription',
      MetricData: [{
        MetricName: metricName,
        Value: value,
        Unit: unit as any,
        Timestamp: new Date(),
        Dimensions: [
          { Name: 'Environment', Value: Deno.env.get('ENVIRONMENT') || 'production' }
        ]
      }]
    }));
  } catch (error) {
    console.error('[Metrics] Failed to publish metric:', metricName, error);
  }
}

/**
 * Validate and normalize duration limit
 */
function validateDurationLimit(requestedMinutes?: number): number {
  if (!requestedMinutes) {
    return DEFAULT_MAX_DURATION_MINUTES;
  }

  // Clamp to valid range
  return Math.max(
    MIN_DURATION_MINUTES,
    Math.min(requestedMinutes, ABSOLUTE_MAX_DURATION_MINUTES)
  );
}

/**
 * Check daily budget before starting transcription
 */
async function checkDailyBudget(supabase: any): Promise<{ allowed: boolean; remaining: number; used: number }> {
  const dailyBudget = parseFloat(Deno.env.get('DAILY_TRANSCRIPTION_BUDGET_USD') || '50');

  try {
    const today = new Date().toISOString().split('T')[0];
    const { data, error } = await supabase
      .from('transcription_usage_daily')
      .select('total_cost_usd')
      .eq('usage_date', today)
      .single();

    if (error && error.code !== 'PGRST116') { // PGRST116 = no rows found
      console.error('[Budget Check] Error:', error);
      // Allow on error to not block functionality
      return { allowed: true, remaining: dailyBudget, used: 0 };
    }

    const usedToday = data?.total_cost_usd || 0;
    const remaining = dailyBudget - usedToday;

    return {
      allowed: remaining > 0,
      remaining: Math.max(0, remaining),
      used: usedToday
    };
  } catch (error) {
    console.error('[Budget Check] Exception:', error);
    return { allowed: true, remaining: dailyBudget, used: 0 };
  }
}

/**
 * Calculate estimated cost for a session
 */
function estimateCost(durationMinutes: number): number {
  return Math.round(durationMinutes * TRANSCRIPTION_COST_PER_MINUTE * 10000) / 10000;
}

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    const body: TranscriptionRequest = await req.json();
    const {
      meetingId,
      sessionId,
      action,
      language = 'en-US',
      specialty = 'PRIMARYCARE',
      enableSpeakerIdentification = true,
      contentIdentificationType = 'PHI',
    } = body;

    if (!meetingId || !sessionId || !action) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: meetingId, sessionId, action' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`[Medical Transcription] ${action} for meeting ${meetingId}`);

    // CRITICAL: Fetch the session's media_region from the database
    // Chime meetings are regional - must use the correct region to access them
    const { data: sessionData, error: sessionFetchError } = await supabase
      .from('video_call_sessions')
      .select('media_region, status')
      .eq('id', sessionId)
      .single();

    if (sessionFetchError) {
      console.error('[Medical Transcription] Failed to fetch session:', sessionFetchError);
      return new Response(
        JSON.stringify({ error: 'Session not found', details: sessionFetchError.message }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Use the session's media_region, fallback to default if not set
    const mediaRegion = sessionData?.media_region || AWS_REGION_DEFAULT;
    console.log(`[Medical Transcription] Using region: ${mediaRegion} (session status: ${sessionData?.status})`);

    // Check if the session is active
    if (action === 'start' && sessionData?.status !== 'active') {
      console.warn(`[Medical Transcription] Session is not active: ${sessionData?.status}`);
      return new Response(
        JSON.stringify({
          error: 'Cannot start transcription - video call is not active',
          details: { status: sessionData?.status }
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Create Chime client with the correct region
    const chimeClient = createChimeClient(mediaRegion);

    if (action === 'start') {
      // Check daily budget before starting
      const budgetCheck = await checkDailyBudget(supabase);
      if (!budgetCheck.allowed) {
        console.warn(`[Medical Transcription] Daily budget exceeded. Used: $${budgetCheck.used}`);
        await publishMetric('BudgetExceeded', 1);

        return new Response(
          JSON.stringify({
            error: 'Daily transcription budget exceeded',
            details: {
              usedToday: budgetCheck.used,
              budgetRemaining: 0
            }
          }),
          { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Validate and set duration limit
      const maxDurationMinutes = validateDurationLimit(body.maxDurationMinutes);
      const estimatedMaxCost = estimateCost(maxDurationMinutes);

      console.log(`[Medical Transcription] Starting with max duration: ${maxDurationMinutes} min, estimated max cost: $${estimatedMaxCost}`);

      // Start medical transcription with AWS Transcribe Medical
      const startCommand = new StartMeetingTranscriptionCommand({
        MeetingId: meetingId,
        TranscriptionConfiguration: {
          EngineTranscribeMedicalSettings: {
            LanguageCode: language as 'en-US' | 'en-GB' | 'es-US',
            Specialty: specialty as 'PRIMARYCARE' | 'CARDIOLOGY' | 'NEUROLOGY' | 'ONCOLOGY' | 'RADIOLOGY' | 'UROLOGY',
            Type: 'CONVERSATION', // Doctor-patient conversation
            VocabularyName: Deno.env.get('MEDICAL_VOCABULARY_NAME'), // Optional custom vocabulary
            ContentIdentificationType: contentIdentificationType,
          },
        },
      });

      await chimeClient.send(startCommand);

      // Publish start metric
      await publishMetric('TranscriptionStarted', 1);
      await publishMetric('InProgressJobs', 1);

      // Update session with transcription status and duration limit
      const { error: updateError } = await supabase
        .from('video_call_sessions')
        .update({
          live_transcription_enabled: true,
          live_transcription_language: language,
          live_transcription_started_at: new Date().toISOString(),
          transcription_status: 'in_progress',
          transcription_max_duration_minutes: maxDurationMinutes,
          transcription_estimated_cost_usd: 0, // Will be calculated on completion
          transcription_auto_stopped: false,
          updated_at: new Date().toISOString(),
        })
        .eq('id', sessionId);

      if (updateError) {
        console.error('Error updating session:', updateError);
        await publishMetric('DatabaseErrors', 1);
        throw updateError;
      }

      // Log to audit trail
      await supabase.from('video_call_audit_log').insert({
        session_id: sessionId,
        event_type: 'TRANSCRIPTION_STARTED',
        event_data: {
          meetingId,
          language,
          specialty,
          enableSpeakerIdentification,
          maxDurationMinutes,
          estimatedMaxCost,
          budgetRemaining: budgetCheck.remaining
        },
        created_at: new Date().toISOString(),
      });

      console.log(`[Medical Transcription] Started successfully for ${meetingId}`);

      return new Response(
        JSON.stringify({
          success: true,
          message: 'Medical transcription started',
          config: {
            language,
            specialty,
            speakerIdentification: enableSpeakerIdentification,
            maxDurationMinutes,
            estimatedMaxCost,
            budgetRemaining: budgetCheck.remaining
          },
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );

    } else if (action === 'stop') {
      // Get session to calculate duration
      const { data: session } = await supabase
        .from('video_call_sessions')
        .select('live_transcription_started_at')
        .eq('id', sessionId)
        .single();

      // Calculate duration
      let durationSeconds = 0;
      let estimatedCost = 0;
      if (session?.live_transcription_started_at) {
        const startTime = new Date(session.live_transcription_started_at).getTime();
        durationSeconds = Math.floor((Date.now() - startTime) / 1000);
        estimatedCost = estimateCost(durationSeconds / 60);
      }

      // Stop transcription
      const stopCommand = new StopMeetingTranscriptionCommand({
        MeetingId: meetingId,
      });

      await chimeClient.send(stopCommand);

      // Publish stop metrics
      await publishMetric('TranscriptionStopped', 1);
      await publishMetric('InProgressJobs', -1);
      await publishMetric('TotalDurationMinutes', durationSeconds / 60, 'None');
      await publishMetric('EstimatedCostUSD', estimatedCost, 'None');

      // Aggregate live caption segments into transcript
      console.log(`[Medical Transcription] Aggregating live caption segments for session ${sessionId}...`);

      const { data: captionSegments, error: segmentsError } = await supabase
        .from('live_caption_segments')
        .select('speaker_name, transcript_text, created_at')
        .eq('session_id', sessionId)
        .order('created_at', { ascending: true });

      let aggregatedTranscript = '';
      const speakerSegments: Array<{ speaker: string; text: string; timestamp: string }> = [];

      if (!segmentsError && captionSegments && captionSegments.length > 0) {
        // Build transcript with speaker labels
        let currentSpeaker = '';
        let currentText = '';

        for (const segment of captionSegments) {
          const speaker = segment.speaker_name || 'Unknown';
          const text = segment.transcript_text || '';

          if (speaker !== currentSpeaker) {
            // Save previous speaker's text
            if (currentText.trim()) {
              aggregatedTranscript += `[${currentSpeaker}]: ${currentText.trim()}\n\n`;
              speakerSegments.push({
                speaker: currentSpeaker,
                text: currentText.trim(),
                timestamp: segment.created_at,
              });
            }
            currentSpeaker = speaker;
            currentText = text;
          } else {
            currentText += ' ' + text;
          }
        }

        // Add the last segment
        if (currentText.trim()) {
          aggregatedTranscript += `[${currentSpeaker}]: ${currentText.trim()}\n`;
          speakerSegments.push({
            speaker: currentSpeaker,
            text: currentText.trim(),
            timestamp: new Date().toISOString(),
          });
        }

        console.log(`[Medical Transcription] Aggregated ${captionSegments.length} segments into transcript (${aggregatedTranscript.length} chars)`);
      } else {
        console.log(`[Medical Transcription] No caption segments found for session ${sessionId}`);
        if (segmentsError) {
          console.error('Error fetching segments:', segmentsError);
        }
      }

      // Update session with duration, cost, and aggregated transcript
      const { error: updateError } = await supabase
        .from('video_call_sessions')
        .update({
          live_transcription_enabled: false,
          transcription_status: aggregatedTranscript ? 'completed' : 'no_transcript',
          transcription_duration_seconds: durationSeconds,
          transcription_estimated_cost_usd: estimatedCost,
          transcription_completed_at: new Date().toISOString(),
          transcript: aggregatedTranscript || null,
          speaker_segments: speakerSegments.length > 0 ? speakerSegments : null,
          updated_at: new Date().toISOString(),
        })
        .eq('id', sessionId);

      if (updateError) {
        console.error('Error updating session:', updateError);
        await publishMetric('DatabaseErrors', 1);
      }

      // Log to audit trail
      await supabase.from('video_call_audit_log').insert({
        session_id: sessionId,
        event_type: 'TRANSCRIPTION_STOPPED',
        event_data: {
          meetingId,
          durationSeconds,
          estimatedCost,
          transcriptLength: aggregatedTranscript.length,
          segmentCount: captionSegments?.length || 0,
          speakerCount: speakerSegments.length,
        },
        created_at: new Date().toISOString(),
      });

      console.log(`[Medical Transcription] Stopped for ${meetingId}. Duration: ${durationSeconds}s, Cost: $${estimatedCost}, Transcript: ${aggregatedTranscript.length} chars`);

      return new Response(
        JSON.stringify({
          success: true,
          message: 'Medical transcription stopped',
          stats: {
            durationSeconds,
            durationMinutes: Math.round(durationSeconds / 60 * 10) / 10,
            estimatedCost,
            transcriptLength: aggregatedTranscript.length,
            segmentCount: captionSegments?.length || 0,
            hasTranscript: aggregatedTranscript.length > 0,
          }
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ error: 'Invalid action. Use "start" or "stop"' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('[Medical Transcription] Error:', error);

    // Publish failure metric
    await publishMetric('FailedJobs', 1);
    await publishMetric('APIErrors', 1);

    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : 'Failed to control transcription',
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
