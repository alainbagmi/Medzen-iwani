// MedX AI Chat Handler - Multi-Model Support (Nova Pro, Nova Lite, Claude 3 Sonnet)
// Lambda Function for Role-Based AI Assistants
// - Health (Patients) → Nova Pro
// - Clinical (Providers) → Claude 3 Sonnet
// - Operations (Facility Admins) → Nova Lite
// - Platform (System Admins) → Nova Lite

import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";
import { LambdaClient, InvokeCommand } from "@aws-sdk/client-lambda";

const BEDROCK_REGION = process.env.BEDROCK_REGION || 'eu-central-1';
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;
const POLLY_TTS_FUNCTION_NAME = process.env.POLLY_TTS_FUNCTION_NAME || 'medzen-polly-tts';

// Amazon Nova Pro Model ID (EU inference profile for eu-central-1)
const DEFAULT_MODEL_ID = process.env.BEDROCK_MODEL_ID || 'eu.amazon.nova-pro-v1:0';

// Model configuration mapping - will be populated from database or use defaults
let MODEL_CONFIGS = {
  // Amazon Nova models (same API format)
  'eu.amazon.nova-pro-v1:0': { provider: 'amazon', format: 'nova' },
  'eu.amazon.nova-lite-v1:0': { provider: 'amazon', format: 'nova' },
  'eu.amazon.nova-micro-v1:0': { provider: 'amazon', format: 'nova' },
  // Anthropic Claude models (different API format)
  'anthropic.claude-3-sonnet-20240229-v1:0': { provider: 'anthropic', format: 'claude' },
  'anthropic.claude-3-haiku-20240307-v1:0': { provider: 'anthropic', format: 'claude' },
  'anthropic.claude-3-opus-20240229-v1:0': { provider: 'anthropic', format: 'claude' },
  'anthropic.claude-3-5-sonnet-20241022-v2:0': { provider: 'anthropic', format: 'claude' }
};

// Cache for bedrock models fetched from database
let modelCacheTime = 0;
let modelCacheTTL = 3600000; // 1 hour cache

// Function to load models from database
async function loadBedrockModelsFromDatabase() {
  // Only refresh cache every hour
  if (modelCacheTime && Date.now() - modelCacheTime < modelCacheTTL) {
    console.log('Using cached model configurations');
    return;
  }

  if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
    console.warn('Supabase not configured, using hardcoded model configs');
    return;
  }

  try {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/bedrock_models?is_available=eq.true`, {
      headers: {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Accept': 'application/json'
      }
    });

    if (response.ok) {
      const models = await response.json();
      MODEL_CONFIGS = {};

      models.forEach(model => {
        MODEL_CONFIGS[model.model_id] = {
          provider: model.provider,
          format: model.format,
          model_name: model.model_name,
          max_tokens: model.max_tokens,
          temperature: model.temperature,
          top_p: model.top_p
        };
      });

      modelCacheTime = Date.now();
      console.log(`Loaded ${models.length} models from database`);
    } else {
      console.warn('Failed to load models from database:', response.status);
    }
  } catch (error) {
    console.warn('Error loading models from database, using defaults:', error.message);
    // Continue with hardcoded configs
  }
}

// Supported languages with their codes (12 African languages)
const SUPPORTED_LANGUAGES = {
  'en': 'English',
  'fr': 'French',
  'ar': 'Arabic',
  'sw': 'Swahili',
  'ha': 'Hausa',
  'yo': 'Yoruba',
  'ff': 'Fulfulde',      // Added - Fulani language
  'pcm': 'Nigerian Pidgin',
  'rw': 'Kinyarwanda',
  'am': 'Amharic',
  'af': 'Afrikaans',     // Added - South Africa
  'sg': 'Sango',         // Added - Central African Republic
  // Legacy codes for backwards compatibility
  'camfrang': 'Camfranglais',
  'ig': 'Igbo'
};

// MedX System Prompt
const SYSTEM_PROMPT = `You are MedX, a compassionate and knowledgeable medical AI health assistant for MedZen Health, a telemedicine platform serving patients across Africa.

## Your Role
- Provide helpful, accurate health information and guidance
- Help patients understand symptoms and when to seek medical care
- Assist with appointment scheduling recommendations
- Provide medication information and reminders
- Offer health education tailored to the patient's context

## Language Support
You are fluent in multiple African languages and dialects:
- English, French, Arabic
- Swahili, Kinyarwanda
- Hausa, Yoruba, Igbo
- Nigerian Pidgin (Naija)
- Camfranglais (Cameroon French-English mix)
- Amharic

IMPORTANT: Always respond in the same language the user writes to you. If they write in Pidgin, respond in Pidgin. If they write in Camfranglais, respond in Camfranglais.

## Guidelines
1. Be empathetic and culturally sensitive
2. Use clear, simple language appropriate for the patient's literacy level
3. Always recommend consulting a doctor for serious symptoms
4. Never diagnose conditions - only provide information
5. Respect patient privacy and confidentiality
6. For emergencies, advise immediate medical attention
7. Consider local healthcare context and accessibility

## Response Format
- Keep responses concise but complete
- Use bullet points for lists
- Include confidence level (high/medium/low) for health information
- Suggest follow-up questions when appropriate
- End with actionable next steps when relevant

## Safety
- Never prescribe medications
- Never provide specific dosages without doctor consultation
- Always err on the side of caution
- Escalate to human provider for: chest pain, difficulty breathing, severe bleeding, loss of consciousness, suicidal thoughts`;

// Bedrock client with retry logic
const bedrockClient = new BedrockRuntimeClient({
  region: BEDROCK_REGION,
  maxAttempts: 3
});

// Lambda client for TTS invocation
const lambdaClient = new LambdaClient({
  region: BEDROCK_REGION
});

// Invoke Polly TTS Lambda to generate audio
async function generateTTSAudio(text, messageId, userId, languageCode) {
  try {
    console.log(`Generating TTS audio for message ${messageId} in ${languageCode}...`);

    const payload = {
      body: JSON.stringify({
        text,
        messageId,
        userId,
        languageCode
      })
    };

    const command = new InvokeCommand({
      FunctionName: POLLY_TTS_FUNCTION_NAME,
      InvocationType: 'RequestResponse',
      Payload: JSON.stringify(payload)
    });

    const response = await lambdaClient.send(command);
    const responsePayload = JSON.parse(Buffer.from(response.Payload).toString());

    if (response.StatusCode === 200 && responsePayload.statusCode === 200) {
      const ttsData = JSON.parse(responsePayload.body);
      console.log('TTS audio generated successfully:', ttsData.audioUrl);
      return ttsData;
    } else {
      console.error('TTS Lambda returned error:', responsePayload);
      return null;
    }
  } catch (error) {
    console.error('Failed to generate TTS audio:', error);
    // Return null to gracefully degrade (continue without audio)
    return null;
  }
}

// Detect language from text (simple heuristic)
function detectLanguage(text) {
  const lowerText = text.toLowerCase();

  // Camfranglais indicators (French-English mix with local terms)
  if (/\b(je go|tu know|c'est how|on va|il y a way|tu es|je suis|c'est nice|on est|je wanda|tu do|on kick)\b/i.test(text)) {
    return 'camfrang';
  }

  // Nigerian Pidgin indicators
  if (/\b(wetin|dey|na |abi|wahala|no be|e don|how far|abeg|sha|sef|o!|una|dem|pikin|palava)\b/i.test(text)) {
    return 'pcm';
  }

  // Swahili indicators
  if (/\b(habari|jambo|asante|pole|ndio|hapana|sawa|karibu|kwaheri|daktari|maumivu)\b/i.test(text)) {
    return 'sw';
  }

  // Hausa indicators
  if (/\b(sannu|yaya|nagode|ba|ne|ce|ina|kana|muna|lafiya|ciwo)\b/i.test(text)) {
    return 'ha';
  }

  // Yoruba indicators
  if (/\b(bawo|pẹlẹ|dara|rara|bẹẹni|ṣe|ẹ kaabo|o dabi)\b/i.test(text) || /[ẹọṣ]/i.test(text)) {
    return 'yo';
  }

  // Fulfulde (Fula) indicators - spoken across West Africa
  if (/\b(a jaraama|useko|eey|alaa|ɗum|noy|jam|ko|mi|ɓe|ɗe|ƴee)\b/i.test(text) || /[ɓɗɲŋƴ]/i.test(text)) {
    return 'ff';
  }

  // Arabic indicators
  if (/[\u0600-\u06FF]/.test(text)) {
    return 'ar';
  }

  // French indicators
  if (/\b(bonjour|merci|comment|je suis|vous|nous|est-ce|avoir|être|douleur|médecin)\b/i.test(text)) {
    return 'fr';
  }

  // Kinyarwanda indicators
  if (/\b(muraho|murakoze|yego|oya|amakuru|bite|mfite)\b/i.test(text)) {
    return 'rw';
  }

  // Igbo indicators
  if (/\b(kedu|ndewo|daalu|ee|mba|ọ dị mma|ahụ)\b/i.test(text) || /[ọụ]/i.test(text)) {
    return 'ig';
  }

  // Amharic (Ethiopic script)
  if (/[\u1200-\u137F]/.test(text)) {
    return 'am';
  }

  // Afrikaans indicators - South Africa
  if (/\b(goeie|dankie|ja|nee|asseblief|hoe gaan|baie|dokter|gesondheid|pyn)\b/i.test(text)) {
    return 'af';
  }

  // Sango indicators - Central African Republic
  if (/\b(bala|singila|ala|ee|en-en|mo|nzoni|koli|yanga|sango)\b/i.test(text)) {
    return 'sg';
  }

  return 'en'; // Default to English
}

// Build request body based on model type (Nova vs Claude have different APIs)
function buildBedrockRequest(modelId, messages, systemPrompt, modelConfig) {
  const modelInfo = MODEL_CONFIGS[modelId] || { format: 'nova' }; // Default to Nova format

  if (modelInfo.format === 'claude') {
    // Anthropic Claude format
    return {
      anthropic_version: "bedrock-2023-05-31",
      max_tokens: modelConfig.max_tokens || 4096,
      temperature: modelConfig.temperature || 0.3,
      top_p: modelConfig.top_p || 0.85,
      system: systemPrompt,
      messages: messages.map(m => ({
        role: m.role,
        content: typeof m.content === 'string' ? m.content : m.content[0]?.text || ''
      }))
    };
  } else {
    // Amazon Nova format (default)
    return {
      messages: messages.map(m => ({
        role: m.role,
        content: typeof m.content === 'string' ? [{ text: m.content }] : m.content
      })),
      system: systemPrompt ? [{ text: systemPrompt }] : undefined,
      inferenceConfig: {
        maxTokens: modelConfig.max_tokens || 4096,
        temperature: modelConfig.temperature || 0.7,
        topP: modelConfig.top_p || 0.9,
        stopSequences: []
      }
    };
  }
}

// Parse response based on model type
function parseBedrockResponse(modelId, responseBody) {
  const modelInfo = MODEL_CONFIGS[modelId] || { format: 'nova' };

  if (modelInfo.format === 'claude') {
    // Claude response format
    return {
      text: responseBody.content?.[0]?.text || 'I apologize, but I was unable to generate a response.',
      inputTokens: responseBody.usage?.input_tokens || 0,
      outputTokens: responseBody.usage?.output_tokens || 0,
      stopReason: responseBody.stop_reason || 'end_turn'
    };
  } else {
    // Nova response format
    return {
      text: responseBody.output?.message?.content?.[0]?.text || 'I apologize, but I was unable to generate a response.',
      inputTokens: responseBody.usage?.inputTokens || 0,
      outputTokens: responseBody.usage?.outputTokens || 0,
      stopReason: responseBody.stopReason || 'end_turn'
    };
  }
}

// Main handler
export const handler = async (event) => {
  console.log('Event received:', JSON.stringify(event));

  // Load latest models from database (cached for 1 hour)
  await loadBedrockModelsFromDatabase();

  // Handle CORS preflight
  if (event.requestContext?.http?.method === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
      },
      body: ''
    };
  }

  // Parse request body
  let body;
  try {
    body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
  } catch (e) {
    return {
      statusCode: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ error: 'Invalid JSON body' })
    };
  }

  const {
    message,
    conversationId,
    userId,
    modelId = DEFAULT_MODEL_ID,
    systemPrompt = null,
    modelConfig = {},
    conversationHistory = [],
    preferredLanguage
  } = body;

  console.log(`Using model: ${modelId} for user: ${userId}`);

  // Validate that the model is supported
  if (!MODEL_CONFIGS[modelId]) {
    const availableModels = Object.keys(MODEL_CONFIGS).join(', ');
    return {
      statusCode: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        error: `Model '${modelId}' is not supported`,
        availableModels: availableModels,
        message: 'Please select one of the available models above. To add a new model, contact a system administrator.'
      })
    };
  }

  if (!message) {
    return {
      statusCode: 400,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({ error: 'Message is required' })
    };
  }

  try {
    // Detect language - prefer explicit preference over auto-detection
    const detectedLanguage = (preferredLanguage && preferredLanguage !== 'auto')
      ? preferredLanguage
      : detectLanguage(message);
    console.log(`Language: ${detectedLanguage} (${SUPPORTED_LANGUAGES[detectedLanguage] || 'Unknown'}), preference: ${preferredLanguage || 'auto'}`);

    // Build conversation messages (model-agnostic format)
    const messages = [];

    // Add conversation history (last 10 messages for context)
    if (conversationHistory && conversationHistory.length > 0) {
      for (const msg of conversationHistory.slice(-10)) {
        messages.push({
          role: msg.role === 'assistant' ? 'assistant' : 'user',
          content: msg.content
        });
      }
    }

    // Add current user message
    messages.push({
      role: 'user',
      content: message
    });

    // Build effective system prompt with language instruction
    const languageName = SUPPORTED_LANGUAGES[detectedLanguage] || 'English';
    const languageInstruction = (preferredLanguage && preferredLanguage !== 'auto')
      ? `\n\nIMPORTANT: The user has requested responses in ${languageName}. Always respond in ${languageName}.`
      : '';
    const effectiveSystemPrompt = (systemPrompt || SYSTEM_PROMPT) + languageInstruction;

    // Merge model configs with defaults
    const effectiveModelConfig = {
      max_tokens: modelConfig.max_tokens || 4096,
      temperature: modelConfig.temperature || 0.7,
      top_p: modelConfig.top_p || 0.9
    };

    // Build request body using multi-model helper (handles Nova vs Claude API differences)
    const requestBody = buildBedrockRequest(modelId, messages, effectiveSystemPrompt, effectiveModelConfig);

    console.log(`Calling Bedrock model: ${modelId} (format: ${MODEL_CONFIGS[modelId]?.format || 'nova'})`);
    const startTime = Date.now();

    const command = new InvokeModelCommand({
      modelId: modelId,
      contentType: 'application/json',
      accept: 'application/json',
      body: JSON.stringify(requestBody)
    });

    const response = await bedrockClient.send(command);
    const responseTime = Date.now() - startTime;

    // Parse response using multi-model helper (handles Nova vs Claude response formats)
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));
    console.log('Bedrock response received, parsing...');

    const parsedResponse = parseBedrockResponse(modelId, responseBody);
    const aiResponse = parsedResponse.text;
    const inputTokens = parsedResponse.inputTokens;
    const outputTokens = parsedResponse.outputTokens;
    const stopReason = parsedResponse.stopReason;

    // Calculate confidence (based on stop reason)
    let confidenceScore = 0.85;
    if (stopReason === 'end_turn' || stopReason === 'stop') confidenceScore = 0.9;
    if (stopReason === 'max_tokens') confidenceScore = 0.7;

    // Save to Supabase if credentials provided
    let userMessageId = null;
    let aiMessageId = null;

    if (SUPABASE_URL && SUPABASE_SERVICE_KEY && conversationId) {
      try {
        // Save user message
        const userMsgResponse = await fetch(`${SUPABASE_URL}/rest/v1/ai_messages`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
            'Prefer': 'return=representation'
          },
          body: JSON.stringify({
            conversation_id: conversationId,
            role: 'user',
            content: message,
            language: detectedLanguage,
            tokens_used: inputTokens
          })
        });

        if (userMsgResponse.ok) {
          const userMsgData = await userMsgResponse.json();
          userMessageId = userMsgData[0]?.id;
        }

        // Save AI response
        const aiMsgResponse = await fetch(`${SUPABASE_URL}/rest/v1/ai_messages`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
            'Prefer': 'return=representation'
          },
          body: JSON.stringify({
            conversation_id: conversationId,
            role: 'assistant',
            content: aiResponse,
            language: detectedLanguage,
            tokens_used: outputTokens,
            model_version: modelId,
            confidence_score: confidenceScore,
            metadata: {
              responseTime,
              stopReason,
              inputTokens,
              outputTokens
            }
          })
        });

        if (aiMsgResponse.ok) {
          const aiMsgData = await aiMsgResponse.json();
          aiMessageId = aiMsgData[0]?.id;
        }

        // Generate TTS audio if AI message was saved successfully
        if (aiMessageId && userId) {
          const ttsData = await generateTTSAudio(
            aiResponse,
            aiMessageId,
            userId,
            detectedLanguage
          );

          // Update AI message with audio metadata if TTS succeeded
          if (ttsData && ttsData.audioUrl) {
            await fetch(`${SUPABASE_URL}/rest/v1/ai_messages?id=eq.${aiMessageId}`, {
              method: 'PATCH',
              headers: {
                'Content-Type': 'application/json',
                'apikey': SUPABASE_SERVICE_KEY,
                'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`
              },
              body: JSON.stringify({
                audio_url: ttsData.audioUrl,
                voice_id: ttsData.voiceId,
                audio_duration_seconds: ttsData.durationSeconds
              })
            });
          }
        }

        // Update conversation metadata
        await fetch(`${SUPABASE_URL}/rest/v1/ai_conversations?id=eq.${conversationId}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'apikey': SUPABASE_SERVICE_KEY,
            'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`
          },
          body: JSON.stringify({
            updated_at: new Date().toISOString(),
            total_tokens: inputTokens + outputTokens,
            default_language: detectedLanguage
          })
        });

      } catch (dbError) {
        console.error('Database save error:', dbError);
        // Continue - don't fail the request due to DB issues
      }
    }

    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
      },
      body: JSON.stringify({
        success: true,
        response: aiResponse,
        language: detectedLanguage,
        languageName: SUPPORTED_LANGUAGES[detectedLanguage] || 'Unknown',
        confidenceScore,
        responseTime,
        usage: {
          inputTokens,
          outputTokens,
          totalTokens: inputTokens + outputTokens
        },
        messageIds: {
          userMessageId,
          aiMessageId
        },
        model: modelId
      })
    };

  } catch (error) {
    console.error('Error:', error);

    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        success: false,
        error: error.message || 'Internal server error',
        errorType: error.name
      })
    };
  }
};
