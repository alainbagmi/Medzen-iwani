import {
  BedrockRuntimeClient,
  InvokeModelCommand
} from '@aws-sdk/client-bedrock-runtime';

// Initialize Bedrock client with retry configuration
const bedrockClient = new BedrockRuntimeClient({
  region: process.env.AWS_REGION || 'eu-west-1',
  maxAttempts: 3
});

// Amazon Nova Pro Model ID (EU inference profile for eu-west-1)
const MODEL_ID = 'eu.amazon.nova-pro-v1:0';

const SUPPORTED_LANGUAGES = {
  'en': 'English',
  'fr': 'French',
  'sw': 'Swahili',
  'ha': 'Hausa',
  'yo': 'Yoruba',
  'ar': 'Arabic',
  'rw': 'Kinyarwanda',
  'pcm': 'Nigerian Pidgin',
  'camfrang': 'Camfranglais',
  'ig': 'Igbo',
  'am': 'Amharic'
};

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

// Supabase configuration
const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

/**
 * Detect language from user message using heuristic patterns
 */
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

  return 'en'; // Default to English
}

/**
 * Calculate confidence score based on response characteristics
 */
function calculateConfidence(response, stopReason) {
  let confidence = 0.8;

  if (stopReason === 'end_turn') confidence += 0.1;
  if (response.length > 100) confidence += 0.05;
  if (/\b(consult|doctor|medical professional|seek care)\b/i.test(response)) confidence += 0.05;

  return Math.min(confidence, 0.99);
}

/**
 * Main Lambda handler for AWS Bedrock AI Chat
 */
export const handler = async (event) => {
  console.log('Lambda invoked:', JSON.stringify(event, null, 2));

  try {
    // Parse request body
    let body;
    try {
      body = typeof event.body === 'string' ? JSON.parse(event.body) : event.body;
    } catch (e) {
      console.error('Failed to parse request body:', e);
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Invalid JSON in request body' })
      };
    }

    const { message, conversationId, userId, conversationHistory, preferredLanguage } = body;

    // Validate required fields
    if (!message || !conversationId || !userId) {
      console.error('Missing required fields:', { message: !!message, conversationId: !!conversationId, userId: !!userId });
      return {
        statusCode: 400,
        body: JSON.stringify({
          error: 'Missing required fields: message, conversationId, userId'
        })
      };
    }

    // Detect language
    const detectedLanguage = preferredLanguage || detectLanguage(message);
    console.log('Detected language:', detectedLanguage);

    // Build conversation context
    const messages = [];

    // Add conversation history if provided
    if (conversationHistory && Array.isArray(conversationHistory) && conversationHistory.length > 0) {
      conversationHistory.forEach(msg => {
        messages.push({
          role: msg.role === 'assistant' ? 'assistant' : 'user',
          content: [{ text: msg.content }]
        });
      });
    }

    // Add current message
    messages.push({
      role: 'user',
      content: [{ text: message }]
    });

    // Nova Pro request format
    const requestBody = {
      messages: messages,
      system: [{ text: SYSTEM_PROMPT }],
      inferenceConfig: {
        maxTokens: 4096,
        temperature: 0.7,
        topP: 0.9,
        stopSequences: []
      }
    };

    console.log('Calling Bedrock Nova Pro...');
    const startTime = Date.now();

    const command = new InvokeModelCommand({
      modelId: MODEL_ID,
      contentType: 'application/json',
      accept: 'application/json',
      body: JSON.stringify(requestBody)
    });

    const response = await bedrockClient.send(command);
    const responseTime = Date.now() - startTime;

    // Parse response
    const responseBody = JSON.parse(new TextDecoder().decode(response.body));
    console.log('Bedrock response:', JSON.stringify(responseBody, null, 2));

    // Extract AI response and metadata
    const aiResponse = responseBody.output?.message?.content?.[0]?.text || '';
    const stopReason = responseBody.stopReason || 'end_turn';
    const inputTokens = responseBody.usage?.inputTokens || 0;
    const outputTokens = responseBody.usage?.outputTokens || 0;

    if (!aiResponse) {
      throw new Error('No response text from Bedrock');
    }

    console.log('AI Response:', aiResponse.substring(0, 100) + '...');
    console.log('Tokens:', { inputTokens, outputTokens });

    // Calculate confidence
    const confidenceScore = calculateConfidence(aiResponse, stopReason);

    // Generate UUIDs for messages
    const userMessageId = crypto.randomUUID();
    const aiMessageId = crypto.randomUUID();

    // ✅ FIXED: Store user message with CORRECT schema
    const userMsgResponse = await fetch(`${SUPABASE_URL}/rest/v1/ai_messages`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Prefer': 'return=representation'
      },
      body: JSON.stringify({
        id: userMessageId,
        conversation_id: conversationId,
        role: 'user',
        content: message,
        language_code: detectedLanguage,  // ✅ FIXED: was 'language'
        input_tokens: inputTokens,        // ✅ FIXED: was 'tokens_used'
        created_at: new Date().toISOString() // ✅ ADDED: required field
      })
    });

    if (!userMsgResponse.ok) {
      const errorText = await userMsgResponse.text();
      console.error('Failed to save user message:', errorText);
    }

    // ✅ FIXED: Store AI response with CORRECT schema
    const aiMsgResponse = await fetch(`${SUPABASE_URL}/rest/v1/ai_messages`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Prefer': 'return=representation'
      },
      body: JSON.stringify({
        id: aiMessageId,
        conversation_id: conversationId,
        role: 'assistant',
        content: aiResponse,
        language_code: detectedLanguage,           // ✅ FIXED: was 'language'
        model_used: MODEL_ID,                      // ✅ FIXED: was 'model_version'
        input_tokens: inputTokens,                 // ✅ ADDED: top-level field
        output_tokens: outputTokens,               // ✅ FIXED: was 'tokens_used', now top-level
        total_tokens: inputTokens + outputTokens,  // ✅ ADDED: required field
        response_time_ms: responseTime,            // ✅ ADDED: top-level field
        confidence_score: confidenceScore,
        metadata: {
          stopReason: stopReason,
          model: MODEL_ID
        },
        created_at: new Date().toISOString()       // ✅ ADDED: required field
      })
    });

    if (!aiMsgResponse.ok) {
      const errorText = await aiMsgResponse.text();
      console.error('Failed to save AI message:', errorText);
    }

    // ✅ FIXED: Update conversation metadata with correct schema
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
        language_code: detectedLanguage  // ✅ FIXED: changed from 'default_language' to match schema
      })
    });

    // Return success response
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
        model: MODEL_ID
      })
    };

  } catch (error) {
    console.error('Lambda error:', error);

    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      },
      body: JSON.stringify({
        success: false,
        error: error.message || 'Internal server error',
        stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
      })
    };
  }
};
