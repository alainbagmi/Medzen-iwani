const functions = require("firebase-functions");
const { ChatOpenAI } = require("@langchain/openai");
const { ChatAnthropic } = require("@langchain/anthropic");
const { ChatGoogleGenerativeAI } = require("@langchain/google-genai");
const { ChatPromptTemplate } = require("@langchain/core/prompts");
const { StringOutputParser } = require("@langchain/core/output_parsers");
const { createClient } = require("@supabase/supabase-js");

// Initialize Supabase client
const getSupabaseClient = () => {
  const supabaseUrl = functions.config().supabase?.url;
  const supabaseServiceKey = functions.config().supabase?.service_key;

  if (!supabaseUrl || !supabaseServiceKey) {
    throw new Error("Supabase configuration missing");
  }

  return createClient(supabaseUrl, supabaseServiceKey);
};

/**
 * Get the appropriate LLM instance based on assistant configuration
 */
const getLLMForAssistant = (assistant) => {
  const modelVersion = assistant.model_version || "gpt-4";

  // Determine which provider based on model version
  if (modelVersion.startsWith("gpt-")) {
    // OpenAI models
    const openaiApiKey = functions.config().openai?.api_key;
    if (!openaiApiKey) {
      throw new Error("OpenAI API key not configured");
    }
    return new ChatOpenAI({
      modelName: modelVersion,
      temperature: 0.7,
      openAIApiKey: openaiApiKey,
    });
  } else if (modelVersion.startsWith("claude-")) {
    // Anthropic models
    const anthropicApiKey = functions.config().anthropic?.api_key;
    if (!anthropicApiKey) {
      throw new Error("Anthropic API key not configured");
    }
    return new ChatAnthropic({
      modelName: modelVersion,
      temperature: 0.7,
      anthropicApiKey: anthropicApiKey,
    });
  } else if (modelVersion.startsWith("gemini-")) {
    // Google models
    const googleApiKey = functions.config().google?.api_key;
    if (!googleApiKey) {
      throw new Error("Google API key not configured");
    }
    return new ChatGoogleGenerativeAI({
      modelName: modelVersion,
      temperature: 0.7,
      apiKey: googleApiKey,
    });
  }

  // Default to GPT-4
  const openaiApiKey = functions.config().openai?.api_key;
  return new ChatOpenAI({
    modelName: "gpt-4",
    temperature: 0.7,
    openAIApiKey: openaiApiKey,
  });
};

/**
 * Build the system prompt with conversation history
 */
const buildPromptWithHistory = async (supabase, assistant, conversationId, userMessage) => {
  // Get recent conversation history (last 10 messages)
  const { data: history, error: historyError } = await supabase
    .from("ai_messages")
    .select("message_content, sender_role, created_at")
    .eq("conversation_id", conversationId)
    .order("created_at", { ascending: false })
    .limit(10);

  if (historyError) {
    console.error("Error fetching conversation history:", historyError);
  }

  // Reverse to get chronological order
  const messages = history ? history.reverse() : [];

  // Build context from history
  const historyContext = messages
    .map((msg) => `${msg.sender_role === "user" ? "Patient" : "Assistant"}: ${msg.message_content}`)
    .join("\n");

  // Create the full prompt
  const systemPrompt = assistant.system_prompt;
  const fullPrompt = `${systemPrompt}

Previous conversation:
${historyContext || "No previous conversation"}

Current patient message:
${userMessage}

Please provide a helpful, accurate, and empathetic response. If the patient's query requires
medical attention, advise them to consult with a healthcare provider.`;

  return fullPrompt;
};

/**
 * Extract confidence score and action items from AI response
 */
const parseAiResponse = (response) => {
  // Simple heuristics for confidence score
  let confidenceScore = 0.8; // Default

  const lowerResponse = response.toLowerCase();

  // Reduce confidence if response contains uncertainty markers
  if (
    lowerResponse.includes("i'm not sure") ||
    lowerResponse.includes("i don't know") ||
    lowerResponse.includes("consult a doctor") ||
    lowerResponse.includes("seek medical attention")
  ) {
    confidenceScore = 0.6;
  }

  // Increase confidence if response is definitive
  if (
    lowerResponse.includes("definitely") ||
    lowerResponse.includes("certainly") ||
    lowerResponse.includes("clearly")
  ) {
    confidenceScore = 0.9;
  }

  // Extract action items (simple regex for bullet points or numbered lists)
  const actionItems = [];
  const bulletPoints = response.match(/[-•*]\s+(.+)/g);
  const numberedItems = response.match(/\d+\.\s+(.+)/g);

  if (bulletPoints) {
    actionItems.push(...bulletPoints.map((item) => item.replace(/[-•*]\s+/, "").trim()));
  }
  if (numberedItems) {
    actionItems.push(...numberedItems.map((item) => item.replace(/\d+\.\s+/, "").trim()));
  }

  return {
    confidenceScore,
    actionItems: actionItems.slice(0, 5), // Limit to 5 action items
  };
};

/**
 * Handle incoming AI chat messages and generate responses
 *
 * Input:
 * - conversationId: UUID of the ai_conversations record
 * - userId: UUID of the user sending the message
 * - message: User's message content
 * - assistantId: UUID of the ai_assistant to use
 *
 * Output:
 * - success: boolean
 * - messageId: UUID of the created AI response message
 * - response: AI assistant's response text
 * - confidenceScore: Confidence score of the response
 * - actionItems: Extracted action items from response
 */
exports.handleAiChatMessage = functions.https.onCall(async (data, context) => {
  try {
    // Authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated to use AI chat"
      );
    }

    const { conversationId, userId, message, assistantId } = data;

    // Validate required parameters
    if (!conversationId || !userId || !message || !assistantId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required parameters: conversationId, userId, message, assistantId"
      );
    }

    // Verify the authenticated user matches the userId
    if (context.auth.uid !== userId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "User can only send messages for themselves"
      );
    }

    const supabase = getSupabaseClient();

    // Get assistant details
    const { data: assistant, error: assistantError } = await supabase
      .from("ai_assistants")
      .select("*")
      .eq("id", assistantId)
      .eq("is_active", true)
      .single();

    if (assistantError || !assistant) {
      throw new functions.https.HttpsError(
        "not-found",
        "AI assistant not found or is not active"
      );
    }

    // Verify conversation exists and belongs to user
    const { data: conversation, error: conversationError } = await supabase
      .from("ai_conversations")
      .select("id, user_id, assistant_id")
      .eq("id", conversationId)
      .eq("user_id", userId)
      .single();

    if (conversationError || !conversation) {
      throw new functions.https.HttpsError(
        "not-found",
        "AI conversation not found or does not belong to user"
      );
    }

    // Store user message
    const { data: userMessageRecord, error: userMessageError } = await supabase
      .from("ai_messages")
      .insert({
        conversation_id: conversationId,
        sender_id: userId,
        sender_role: "user",
        message_content: message,
        created_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (userMessageError) {
      console.error("Error storing user message:", userMessageError);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to store user message"
      );
    }

    // Build prompt with conversation history
    const fullPrompt = await buildPromptWithHistory(
      supabase,
      assistant,
      conversationId,
      message
    );

    // Get LLM instance
    const llm = getLLMForAssistant(assistant);

    // Create prompt template
    const promptTemplate = ChatPromptTemplate.fromMessages([
      ["system", "{prompt}"],
    ]);

    // Create chain
    const chain = promptTemplate.pipe(llm).pipe(new StringOutputParser());

    // Track response time
    const startTime = Date.now();

    // Generate AI response
    const aiResponse = await chain.invoke({
      prompt: fullPrompt,
    });

    const responseTime = Date.now() - startTime;

    // Parse AI response for confidence and action items
    const { confidenceScore, actionItems } = parseAiResponse(aiResponse);

    // Store AI response
    const { data: aiMessageRecord, error: aiMessageError } = await supabase
      .from("ai_messages")
      .insert({
        conversation_id: conversationId,
        sender_id: null, // AI has no user ID
        sender_role: "assistant",
        message_content: aiResponse,
        confidence_score: confidenceScore,
        action_items: actionItems,
        response_time_ms: responseTime,
        created_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (aiMessageError) {
      console.error("Error storing AI message:", aiMessageError);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to store AI response"
      );
    }

    // Update conversation last_message_at and message count
    await supabase
      .from("ai_conversations")
      .update({
        last_message_at: new Date().toISOString(),
        message_count: conversation.message_count + 2, // User message + AI response
        updated_at: new Date().toISOString(),
      })
      .eq("id", conversationId);

    // Update assistant average response time
    await supabase.rpc("update_assistant_avg_response_time", {
      p_assistant_id: assistantId,
      p_response_time: responseTime,
    });

    return {
      success: true,
      userMessageId: userMessageRecord.id,
      aiMessageId: aiMessageRecord.id,
      response: aiResponse,
      confidenceScore,
      actionItems,
      responseTime,
      message: "AI response generated successfully",
    };
  } catch (error) {
    console.error("Error in handleAiChatMessage:", error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      "internal",
      `Failed to process AI chat message: ${error.message}`
    );
  }
});

/**
 * Create a new AI conversation
 *
 * Input:
 * - userId: UUID of the user
 * - assistantId: UUID of the ai_assistant
 * - initialMessage: Optional initial message from user
 *
 * Output:
 * - conversationId: UUID of the created conversation
 * - assistant: Assistant details
 */
exports.createAiConversation = functions.https.onCall(async (data, context) => {
  try {
    // Authentication check
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated to create AI conversation"
      );
    }

    const { userId, assistantId, initialMessage } = data;

    // Validate required parameters
    if (!userId || !assistantId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required parameters: userId, assistantId"
      );
    }

    // Verify the authenticated user matches the userId
    if (context.auth.uid !== userId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "User can only create conversations for themselves"
      );
    }

    const supabase = getSupabaseClient();

    // Get assistant details
    const { data: assistant, error: assistantError } = await supabase
      .from("ai_assistants")
      .select("*")
      .eq("id", assistantId)
      .eq("is_active", true)
      .single();

    if (assistantError || !assistant) {
      throw new functions.https.HttpsError(
        "not-found",
        "AI assistant not found or is not active"
      );
    }

    // Create conversation
    const { data: conversation, error: conversationError } = await supabase
      .from("ai_conversations")
      .insert({
        user_id: userId,
        assistant_id: assistantId,
        conversation_topic: `Chat with ${assistant.assistant_name}`,
        message_count: 0,
        created_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (conversationError) {
      console.error("Error creating AI conversation:", conversationError);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to create AI conversation"
      );
    }

    // If initial message provided, process it
    let initialResponse = null;
    if (initialMessage) {
      const messageResult = await exports.handleAiChatMessage.run({
        conversationId: conversation.id,
        userId,
        message: initialMessage,
        assistantId,
      }, context);

      initialResponse = {
        response: messageResult.response,
        confidenceScore: messageResult.confidenceScore,
        actionItems: messageResult.actionItems,
      };
    }

    return {
      success: true,
      conversationId: conversation.id,
      assistant: {
        id: assistant.id,
        name: assistant.assistant_name,
        type: assistant.assistant_type,
        description: assistant.description,
        iconUrl: assistant.icon_url,
      },
      initialResponse,
      message: "AI conversation created successfully",
    };
  } catch (error) {
    console.error("Error in createAiConversation:", error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      "internal",
      `Failed to create AI conversation: ${error.message}`
    );
  }
});
