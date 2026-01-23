import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  getAvailableBedrockModels,
  validateBedrockModel,
  getModelsForUseCase,
  clearModelCache,
} from "../_shared/bedrock-models.ts";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";

interface OrchestrateRequest {
  action:
    | "switch"
    | "auto-switch"
    | "list-all"
    | "validate"
    | "get-available"
    | "get-for-use-case"
    | "clear-cache";
  modelId?: string;
  useCase?: string;
  userId?: string;
  conversationId?: string;
  reason?: string;
  showNotification?: boolean;
}

interface ModelSwitchEvent {
  timestamp: string;
  userId: string;
  conversationId: string;
  previousModelId: string;
  newModelId: string;
  action: string;
  reason: string;
  notification: {
    shown: boolean;
    title: string;
    message: string;
    type: "auto" | "manual";
  };
}

interface OrchestrateResponse {
  success: boolean;
  action: string;
  data?: any;
  notification?: {
    title: string;
    message: string;
    type: "auto" | "manual";
    modelName: string;
    modelId: string;
  };
  error?: string;
}

/**
 * Format notification message for model switching
 */
function formatNotification(
  previousModel: any,
  newModel: any,
  reason: string,
  isAuto: boolean
): OrchestrateResponse["notification"] {
  const action = isAuto ? "automatically switched" : "switched";
  const reasonText = reason ? ` (${reason})` : "";

  return {
    title: `${isAuto ? "Auto-Switching" : "Switching"} AI Model`,
    message: `Upgraded from ${previousModel?.model_name || "default model"} to ${newModel.model_name}${reasonText}. Processing will resume momentarily.`,
    type: isAuto ? "auto" : "manual",
    modelName: newModel.model_name,
    modelId: newModel.model_id,
  };
}

/**
 * Log model switch event to database
 */
async function logModelSwitchEvent(
  supabase: any,
  event: ModelSwitchEvent
): Promise<void> {
  try {
    const { error } = await supabase.from("bedrock_model_switches").insert({
      user_id: event.userId,
      conversation_id: event.conversationId,
      previous_model_id: event.previousModelId,
      new_model_id: event.newModelId,
      switch_action: event.action,
      reason: event.reason,
      notification_shown: event.notification.shown,
      notification_title: event.notification.title,
      notification_message: event.notification.message,
      switch_type: event.notification.type,
      timestamp: event.timestamp,
    });

    if (error) {
      console.error("Failed to log model switch event:", error);
    } else {
      console.log(`Model switch event logged for user ${event.userId}`);
    }
  } catch (err) {
    console.error("Exception logging model switch:", err);
  }
}

/**
 * Get previous model for conversation to show in notification
 */
async function getPreviousModel(
  supabase: any,
  conversationId: string
): Promise<any | null> {
  try {
    const { data, error } = await supabase
      .from("ai_conversations")
      .select("model_version")
      .eq("id", conversationId)
      .single();

    if (error || !data) return null;

    return data.model_version
      ? await validateBedrockModel(
          data.model_version,
          Deno.env.get("SUPABASE_URL")!,
          Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
        ).catch(() => null)
      : null;
  } catch {
    return null;
  }
}

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({
          success: false,
          action: "none",
          error: "Missing authorization header",
        }),
        {
          status: 401,
          headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const body: OrchestrateRequest = await req.json();
    const {
      action,
      modelId,
      useCase,
      userId = "system",
      conversationId = "default",
      reason = "",
      showNotification = true,
    } = body;

    console.log(`Orchestrating Bedrock models - Action: ${action}`);

    const response: OrchestrateResponse = {
      success: true,
      action,
    };

    // Handle different orchestration actions
    switch (action) {
      case "list-all": {
        const models = await getAvailableBedrockModels(
          supabaseUrl,
          supabaseServiceKey
        );
        const modelList = Array.from(models.values());

        response.data = {
          total: modelList.length,
          models: modelList.map((m) => ({
            id: m.model_id,
            name: m.model_name,
            provider: m.provider,
            useCase: m.use_case,
            maxTokens: m.max_tokens,
          })),
        };
        break;
      }

      case "get-for-use-case": {
        if (!useCase) {
          return new Response(
            JSON.stringify({
              success: false,
              action,
              error: "useCase parameter is required",
            }),
            { status: 400, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
          );
        }

        const models = await getModelsForUseCase(
          useCase,
          supabaseUrl,
          supabaseServiceKey
        );

        response.data = {
          useCase,
          count: models.length,
          models: models.map((m) => ({
            id: m.model_id,
            name: m.model_name,
            provider: m.provider,
            costPerMtok: { input: "$?", output: "$?" },
          })),
        };
        break;
      }

      case "validate": {
        if (!modelId) {
          return new Response(
            JSON.stringify({
              success: false,
              action,
              error: "modelId parameter is required",
            }),
            { status: 400, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
          );
        }

        try {
          const model = await validateBedrockModel(
            modelId,
            supabaseUrl,
            supabaseServiceKey
          );
          response.data = {
            valid: true,
            model: {
              id: model.model_id,
              name: model.model_name,
              provider: model.provider,
              format: model.format,
            },
          };
        } catch (err) {
          response.success = false;
          response.data = {
            valid: false,
            error: (err as Error).message,
          };
        }
        break;
      }

      case "switch": {
        if (!modelId) {
          return new Response(
            JSON.stringify({
              success: false,
              action,
              error: "modelId parameter is required for manual switch",
            }),
            { status: 400, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
          );
        }

        try {
          const newModel = await validateBedrockModel(
            modelId,
            supabaseUrl,
            supabaseServiceKey
          );
          const previousModel = await getPreviousModel(supabase, conversationId);

          // Update conversation with new model
          const { error: updateError } = await supabase
            .from("ai_conversations")
            .update({ model_version: modelId })
            .eq("id", conversationId);

          if (updateError) {
            throw updateError;
          }

          // Log the switch event
          const switchEvent: ModelSwitchEvent = {
            timestamp: new Date().toISOString(),
            userId,
            conversationId,
            previousModelId: previousModel?.model_id || "unknown",
            newModelId: modelId,
            action: "manual_switch",
            reason,
            notification: formatNotification(
              previousModel,
              newModel,
              reason,
              false
            ),
          };

          await logModelSwitchEvent(supabase, switchEvent);

          response.data = {
            switched: true,
            from: previousModel?.model_name || "unknown",
            to: newModel.model_name,
          };

          if (showNotification) {
            response.notification = switchEvent.notification;
          }
        } catch (err) {
          response.success = false;
          response.error = (err as Error).message;
        }
        break;
      }

      case "auto-switch": {
        if (!useCase) {
          return new Response(
            JSON.stringify({
              success: false,
              action,
              error: "useCase parameter is required for auto-switch",
            }),
            { status: 400, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
          );
        }

        try {
          const models = await getModelsForUseCase(
            useCase,
            supabaseUrl,
            supabaseServiceKey
          );

          if (models.length === 0) {
            throw new Error(
              `No models available for use case: ${useCase}`
            );
          }

          const newModel = models[0]; // Get highest priority model
          const previousModel = await getPreviousModel(supabase, conversationId);

          // Skip if already using the same model
          if (previousModel?.model_id === newModel.model_id) {
            response.data = {
              switched: false,
              reason: "Already using optimal model",
              currentModel: newModel.model_name,
            };
            break;
          }

          // Update conversation with new model
          const { error: updateError } = await supabase
            .from("ai_conversations")
            .update({ model_version: newModel.model_id })
            .eq("id", conversationId);

          if (updateError) {
            throw updateError;
          }

          // Log the switch event
          const switchEvent: ModelSwitchEvent = {
            timestamp: new Date().toISOString(),
            userId,
            conversationId,
            previousModelId: previousModel?.model_id || "unknown",
            newModelId: newModel.model_id,
            action: "auto_switch",
            reason: useCase ? `Optimized for ${useCase}` : "Auto-optimization",
            notification: formatNotification(
              previousModel,
              newModel,
              useCase ? `Optimized for ${useCase}` : "Auto-optimization",
              true
            ),
          };

          await logModelSwitchEvent(supabase, switchEvent);

          response.data = {
            switched: true,
            from: previousModel?.model_name || "default",
            to: newModel.model_name,
            useCase,
          };

          if (showNotification) {
            response.notification = switchEvent.notification;
          }
        } catch (err) {
          response.success = false;
          response.error = (err as Error).message;
        }
        break;
      }

      case "clear-cache": {
        clearModelCache();
        response.data = {
          cacheCleared: true,
          message: "Bedrock models cache cleared successfully",
        };
        break;
      }

      default: {
        return new Response(
          JSON.stringify({
            success: false,
            action: "none",
            error: `Unknown action: ${action}. Valid actions: switch, auto-switch, list-all, validate, get-available, get-for-use-case, clear-cache`,
          }),
          {
            status: 400,
            headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
          }
        );
      }
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Orchestration error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        action: "error",
        error: (error as Error).message,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
