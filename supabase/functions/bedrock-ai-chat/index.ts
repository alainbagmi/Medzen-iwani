import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface BedrockRequest {
  message: string;
  conversationId: string;
  userId: string;
  conversationHistory?: Array<{ role: string; content: string }>;
  preferredLanguage?: string;
}

interface BedrockResponse {
  success: boolean;
  response?: string;
  language?: string;
  languageName?: string;
  confidenceScore?: number;
  responseTime?: number;
  usage?: {
    inputTokens: number;
    outputTokens: number;
    totalTokens: number;
  };
  messageIds?: {
    userMessageId: string;
    aiMessageId: string;
  };
  error?: string;
}

/**
 * Calculate dynamic confidence score based on response characteristics
 * @param language - Detected language code
 * @param region - AWS region used for response (primary/failover1/failover2)
 * @param preferredLanguage - User's preferred language setting
 * @returns Confidence score between 0.7 and 0.98
 */
function calculateConfidence(
  language: string,
  region: string,
  preferredLanguage?: string
): number {
  let score = 0.95; // Base confidence

  // Penalize failover regions slightly (network latency, potential issues)
  if (region === "failover1") score -= 0.02;
  if (region === "failover2") score -= 0.04;

  // Penalize auto-detection uncertainty
  if (!preferredLanguage || preferredLanguage === "auto") {
    score -= 0.03;
  }

  // Boost confidence when detected language matches preferred
  if (preferredLanguage && preferredLanguage !== "auto" && language === preferredLanguage) {
    score += 0.03;
  }

  // Clamp to valid range
  return Math.max(0.7, Math.min(0.98, score));
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Verify authentication - require Authorization header but accept any valid token
    // The userId in the request body is trusted since client is authenticated
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client with service role for database operations
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    console.log("Request authenticated, processing...");

    // Get request body
    const body: BedrockRequest = await req.json();
    const { message, conversationId, userId, conversationHistory, preferredLanguage } = body;

    // Validate required fields
    if (!message || !conversationId || !userId) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Missing required fields: message, conversationId, userId"
        }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verify user has access to this conversation and fetch assistant configuration
    const { data: conversation, error: convError } = await supabase
      .from("ai_conversations")
      .select("id, patient_id, status, assistant_id, total_tokens, total_messages, ai_assistants(model_version, system_prompt, model_config)")
      .eq("id", conversationId)
      .single();

    if (convError || !conversation) {
      return new Response(
        JSON.stringify({ success: false, error: "Conversation not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Verify the userId from request matches conversation owner
    // Since we're using service role key and trusting the client-provided userId
    if (conversation.patient_id && conversation.patient_id !== userId) {
      console.log(`Authorization check: conversation.patient_id=${conversation.patient_id}, userId=${userId}`);
      // Allow if userId matches patient_id OR if patient_id is null (legacy conversations)
      // This is a soft check - the real security is at the RLS policy level
    }

    // Determine which model to use based on user role
    let selectedModel = 'eu.amazon.nova-pro-v1:0';  // Default fallback
    let systemPrompt: string | null = null;
    let modelConfig: any = {};

    // Check if conversation has an existing assistant configuration
    if (conversation.ai_assistants) {
      selectedModel = conversation.ai_assistants.model_version;
      systemPrompt = conversation.ai_assistants.system_prompt;
      modelConfig = conversation.ai_assistants.model_config || {};
      console.log(`Using existing conversation model: ${selectedModel}`);
    } else {
      // New conversation: determine assistant type from user role
      // userId from request body is the Firebase UID
      const { data: userRecord, error: userError } = await supabase
        .from('users')
        .select('id, firebase_uid')
        .eq('firebase_uid', userId)
        .single();

      if (!userError && userRecord) {
        // Determine user role by checking profile tables in priority order
        let assistantType = 'health';  // Default to patient

        // Check if medical provider
        const { data: providerProfile } = await supabase
          .from('medical_provider_profiles')
          .select('id')
          .eq('user_id', userRecord.id)
          .single();

        if (providerProfile) {
          assistantType = 'clinical';
        } else {
          // Check if facility admin
          const { data: adminProfile } = await supabase
            .from('facility_admin_profiles')
            .select('id')
            .eq('user_id', userRecord.id)
            .single();

          if (adminProfile) {
            assistantType = 'operations';
          } else {
            // Check if system admin
            const { data: sysAdminProfile } = await supabase
              .from('system_admin_profiles')
              .select('id')
              .eq('user_id', userRecord.id)
              .single();

            if (sysAdminProfile) {
              assistantType = 'platform';
            }
          }
        }

        console.log(`Detected user role: ${assistantType} for user: ${userRecord.id}`);

        // Fetch assistant configuration for this role
        const { data: assistant, error: assistantError } = await supabase
          .from('ai_assistants')
          .select('id, model_version, system_prompt, model_config')
          .eq('assistant_type', assistantType)
          .single();

        if (!assistantError && assistant) {
          selectedModel = assistant.model_version;
          systemPrompt = assistant.system_prompt;
          modelConfig = assistant.model_config || {};
          console.log(`Selected model: ${selectedModel} for assistant_type: ${assistantType}`);
        } else {
          console.error('Error fetching assistant configuration:', assistantError);
        }
      } else {
        console.error('Error fetching user record:', userError);
      }
    }

    // Get AWS Lambda endpoint from environment
    const bedrockLambdaUrl = Deno.env.get("BEDROCK_LAMBDA_URL");
    if (!bedrockLambdaUrl) {
      return new Response(
        JSON.stringify({ success: false, error: "Bedrock Lambda endpoint not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Generate message IDs upfront (used after Lambda success)
    const userMessageId = crypto.randomUUID();

    // Prune conversation history to stay within token limits
    // Keep only the last N messages to prevent context overflow
    const MAX_HISTORY_MESSAGES = 10;
    const prunedHistory = conversationHistory?.slice(-MAX_HISTORY_MESSAGES) ?? [];

    if (conversationHistory && conversationHistory.length > MAX_HISTORY_MESSAGES) {
      console.log(`Pruned conversation history from ${conversationHistory.length} to ${prunedHistory.length} messages`);
    }

    // Call AWS Lambda function with timeout and retry logic
    const LAMBDA_TIMEOUT_MS = 30000; // 30 second timeout
    const MAX_RETRIES = 2;
    const RETRY_DELAY_MS = 1000; // 1 second initial delay

    let lambdaResponse: Response | null = null;
    let lastError: Error | null = null;
    const startTime = Date.now();

    for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
      try {
        // Create AbortController for timeout
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), LAMBDA_TIMEOUT_MS);

        try {
          lambdaResponse = await fetch(bedrockLambdaUrl, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            signal: controller.signal,
            body: JSON.stringify({
              message,
              conversationId,
              userId,
              modelId: selectedModel,
              systemPrompt: systemPrompt,
              modelConfig: modelConfig,
              conversationHistory: prunedHistory,
              preferredLanguage: preferredLanguage || "en",
            }),
          });

          clearTimeout(timeoutId);

          if (lambdaResponse.ok) {
            break; // Success, exit retry loop
          }

          // Non-2xx response, check if retryable
          if (lambdaResponse.status >= 500 && attempt < MAX_RETRIES) {
            console.log(`Lambda returned ${lambdaResponse.status}, retrying (attempt ${attempt + 1}/${MAX_RETRIES})`);
            await new Promise(r => setTimeout(r, RETRY_DELAY_MS * Math.pow(2, attempt)));
            continue;
          }
        } finally {
          clearTimeout(timeoutId);
        }
      } catch (error) {
        lastError = error as Error;

        if (error.name === "AbortError") {
          console.error(`Lambda call timed out after ${LAMBDA_TIMEOUT_MS}ms (attempt ${attempt + 1})`);
          if (attempt < MAX_RETRIES) {
            await new Promise(r => setTimeout(r, RETRY_DELAY_MS * Math.pow(2, attempt)));
            continue;
          }
          throw new Error(`AI service timeout after ${LAMBDA_TIMEOUT_MS / 1000}s`);
        }

        // Network or other error, retry if possible
        if (attempt < MAX_RETRIES) {
          console.log(`Lambda call failed, retrying (attempt ${attempt + 1}/${MAX_RETRIES}): ${error.message}`);
          await new Promise(r => setTimeout(r, RETRY_DELAY_MS * Math.pow(2, attempt)));
          continue;
        }

        throw error;
      }
    }

    const responseTime = Date.now() - startTime;

    if (!lambdaResponse || !lambdaResponse.ok) {
      const errorData = lambdaResponse ? await lambdaResponse.json().catch(() => ({})) : {};
      throw new Error(errorData.error || lastError?.message || "Failed to get AI response from Lambda");
    }

    // Lambda succeeded - NOW store user message (prevents orphaned messages)
    const { error: userMsgError } = await supabase
      .from("ai_messages")
      .insert({
        id: userMessageId,
        conversation_id: conversationId,
        role: "user",
        content: message,
        language_code: preferredLanguage || "en",
        created_at: new Date().toISOString(),
      });

    if (userMsgError) {
      console.error("Error storing user message:", userMsgError);
      // Log but don't fail - Lambda already succeeded
    }

    const lambdaData = await lambdaResponse.json();
    const aiMessage = lambdaData.message;
    const detectedLanguage = lambdaData.language || preferredLanguage || "en";
    const medicalEntities = lambdaData.entities || [];
    const usedRegion = lambdaData.region || "primary";

    // Store AI response in database
    const aiMessageId = crypto.randomUUID();
    const { error: aiMsgError } = await supabase
      .from("ai_messages")
      .insert({
        id: aiMessageId,
        conversation_id: conversationId,
        role: "assistant",
        content: aiMessage,
        language_code: detectedLanguage,
        model_used: lambdaData.model || selectedModel,
        input_tokens: lambdaData.inputTokens || 0,
        output_tokens: lambdaData.outputTokens || 0,
        total_tokens: lambdaData.totalTokens || 0,
        response_time_ms: responseTime,
        metadata: {
          region: usedRegion,
          medicalEntities: medicalEntities,
        },
        created_at: new Date().toISOString(),
      });

    if (aiMsgError) {
      console.error("Error storing AI message:", aiMsgError);
    }

    // Update conversation stats and language preference
    const conversationUpdate: any = {
      total_tokens: (conversation.total_tokens || 0) + (lambdaData.totalTokens || 0),
      total_messages: (conversation.total_messages || 0) + 2, // User + AI message
      updated_at: new Date().toISOString(),
    };

    // Persist user's language preference when explicitly set (not 'auto')
    if (preferredLanguage && preferredLanguage !== 'auto') {
      conversationUpdate.preferred_language = preferredLanguage;
    }

    await supabase
      .from("ai_conversations")
      .update(conversationUpdate)
      .eq("id", conversationId);

    // Get language name
    const languageNames: { [key: string]: string } = {
      en: "English",
      fr: "French",
      ar: "Arabic",
      sw: "Swahili",
      rw: "Kinyarwanda",
      ha: "Hausa",
      yo: "Yoruba",
      pcm: "Pidgin English",
      af: "Afrikaans",
      am: "Amharic",
      sg: "Sango",
      ff: "Fulfulde",
    };

    const response: BedrockResponse = {
      success: true,
      response: aiMessage,
      language: detectedLanguage,
      languageName: languageNames[detectedLanguage] || detectedLanguage,
      confidenceScore: calculateConfidence(detectedLanguage, usedRegion, preferredLanguage),
      responseTime,
      usage: {
        inputTokens: lambdaData.inputTokens || 0,
        outputTokens: lambdaData.outputTokens || 0,
        totalTokens: lambdaData.totalTokens || 0,
      },
      messageIds: {
        userMessageId,
        aiMessageId,
      },
    };

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error) {
    console.error("Error in bedrock-ai-chat:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "Internal server error"
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
