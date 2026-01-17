import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  getAvailableBedrockModels,
  validateBedrockModel,
} from "../_shared/bedrock-models.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface ManageRequest {
  action: "list" | "enable" | "disable" | "set-default" | "get-default" | "validate";
  model_id?: string;
  use_case?: string;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));

    if (userError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: "Unauthorized" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Check if user is system admin
    const { data: sysAdmin } = await supabase
      .from("system_admin_profiles")
      .select("id")
      .eq("user_id", user.id)
      .single();

    if (!sysAdmin) {
      return new Response(
        JSON.stringify({
          success: false,
          error: "Only system admins can manage models",
        }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse request body
    let body: ManageRequest;
    try {
      body = await req.json();
    } catch {
      return new Response(
        JSON.stringify({ success: false, error: "Invalid JSON body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { action, model_id, use_case } = body;

    // Handle actions
    switch (action) {
      case "list": {
        // List all models
        const models = await getAvailableBedrockModels(
          supabaseUrl,
          supabaseServiceKey
        );
        return new Response(
          JSON.stringify({
            success: true,
            models: Array.from(models.values()),
            count: models.size,
          }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "validate": {
        // Validate a model exists
        if (!model_id) {
          return new Response(
            JSON.stringify({ success: false, error: "model_id is required" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        try {
          const model = await validateBedrockModel(
            model_id,
            supabaseUrl,
            supabaseServiceKey
          );
          return new Response(
            JSON.stringify({
              success: true,
              message: `Model '${model_id}' is valid`,
              model,
            }),
            { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        } catch (error) {
          return new Response(
            JSON.stringify({ success: false, error: error.message }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
      }

      case "enable": {
        // Enable a model
        if (!model_id) {
          return new Response(
            JSON.stringify({ success: false, error: "model_id is required" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const { error } = await supabase
          .from("bedrock_models")
          .update({ is_available: true, updated_at: new Date().toISOString() })
          .eq("model_id", model_id);

        if (error) {
          return new Response(
            JSON.stringify({ success: false, error: error.message }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        return new Response(
          JSON.stringify({ success: true, message: `Model '${model_id}' enabled` }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "disable": {
        // Disable a model
        if (!model_id) {
          return new Response(
            JSON.stringify({ success: false, error: "model_id is required" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        const { error } = await supabase
          .from("bedrock_models")
          .update({
            is_available: false,
            is_default: false,
            updated_at: new Date().toISOString(),
          })
          .eq("model_id", model_id);

        if (error) {
          return new Response(
            JSON.stringify({ success: false, error: error.message }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        return new Response(
          JSON.stringify({ success: true, message: `Model '${model_id}' disabled` }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "set-default": {
        // Set a model as default
        if (!model_id) {
          return new Response(
            JSON.stringify({ success: false, error: "model_id is required" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        // First, remove is_default from all models
        await supabase
          .from("bedrock_models")
          .update({ is_default: false })
          .neq("model_id", model_id);

        // Then set the specified model as default
        const { error } = await supabase
          .from("bedrock_models")
          .update({
            is_default: true,
            is_available: true,
            updated_at: new Date().toISOString(),
          })
          .eq("model_id", model_id);

        if (error) {
          return new Response(
            JSON.stringify({ success: false, error: error.message }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        return new Response(
          JSON.stringify({
            success: true,
            message: `Model '${model_id}' set as default`,
          }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      case "get-default": {
        // Get the default model
        const { data: model } = await supabase
          .from("bedrock_models")
          .select("*")
          .eq("is_default", true)
          .single();

        if (!model) {
          return new Response(
            JSON.stringify({ success: false, error: "No default model set" }),
            { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }

        return new Response(
          JSON.stringify({
            success: true,
            default_model: model,
          }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      default: {
        return new Response(
          JSON.stringify({
            success: false,
            error: `Unknown action: ${action}`,
            available_actions: [
              "list",
              "enable",
              "disable",
              "set-default",
              "get-default",
              "validate",
            ],
          }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }
  } catch (error) {
    console.error("Error in manage-bedrock-models:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "Internal server error",
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
