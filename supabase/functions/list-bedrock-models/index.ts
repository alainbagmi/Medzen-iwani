import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import {
  getAvailableBedrockModels,
  getModelsForUseCase,
} from "../_shared/bedrock-models.ts";
import { getCorsHeaders, securityHeaders } from "../_shared/cors.ts";

serve(async (req) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: { ...corsHeaders, ...securityHeaders } });
  }

  try {
    // Initialize Supabase client with service role
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Parse query parameters
    const url = new URL(req.url);
    const useCase = url.searchParams.get("use_case");

    let models;

    if (useCase) {
      // Get models for specific use case
      models = await getModelsForUseCase(
        useCase,
        supabaseUrl,
        supabaseServiceKey
      );
    } else {
      // Get all available models
      const modelMap = await getAvailableBedrockModels(
        supabaseUrl,
        supabaseServiceKey
      );
      models = Array.from(modelMap.values());
    }

    // Format response
    const response = {
      success: true,
      models: models.map((m) => ({
        model_id: m.model_id,
        model_name: m.model_name,
        provider: m.provider,
        format: m.format,
        max_tokens: m.max_tokens,
        temperature: m.temperature,
        top_p: m.top_p,
        use_case: m.use_case,
      })),
      count: models.length,
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error in list-bedrock-models:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || "Internal server error",
      }),
      { status: 500, headers: { ...corsHeaders, ...securityHeaders, "Content-Type": "application/json" } }
    );
  }
});
