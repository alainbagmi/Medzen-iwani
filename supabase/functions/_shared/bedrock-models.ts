import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

interface BedrockModel {
  model_id: string;
  model_name: string;
  provider: string;
  format: string;
  max_tokens: number;
  temperature: number;
  top_p: number;
  use_case: string | null;
}

// Cache for bedrock models (TTL: 1 hour)
let modelCache: Map<string, BedrockModel> | null = null;
let modelCacheTime: number = 0;
const CACHE_TTL = 3600000; // 1 hour

/**
 * Get all available Bedrock models from the database
 * Cached for 1 hour to reduce database queries
 */
export async function getAvailableBedrockModels(
  supabaseUrl: string,
  supabaseServiceKey: string
): Promise<Map<string, BedrockModel>> {
  const now = Date.now();

  // Return cached results if still valid
  if (modelCache && modelCacheTime && now - modelCacheTime < CACHE_TTL) {
    console.log("Using cached Bedrock models");
    return modelCache;
  }

  try {
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { data: models, error } = await supabase
      .from("bedrock_models")
      .select("*")
      .eq("is_available", true)
      .order("priority", { ascending: true });

    if (error) {
      console.error("Error fetching bedrock models:", error);
      return new Map();
    }

    // Build map of model_id -> model config
    modelCache = new Map();
    models?.forEach((model: any) => {
      modelCache!.set(model.model_id, {
        model_id: model.model_id,
        model_name: model.model_name,
        provider: model.provider,
        format: model.format,
        max_tokens: model.max_tokens,
        temperature: model.temperature,
        top_p: model.top_p,
        use_case: model.use_case,
      });
    });

    modelCacheTime = now;
    console.log(`Loaded ${models?.length || 0} Bedrock models from database`);

    return modelCache;
  } catch (error) {
    console.error("Exception fetching bedrock models:", error);
    return new Map();
  }
}

/**
 * Get a specific Bedrock model configuration
 * Returns null if model is not available
 */
export async function getBedrockModel(
  modelId: string,
  supabaseUrl: string,
  supabaseServiceKey: string
): Promise<BedrockModel | null> {
  const models = await getAvailableBedrockModels(
    supabaseUrl,
    supabaseServiceKey
  );
  return models.get(modelId) || null;
}

/**
 * Get the best model for a specific use case
 * Falls back to default if no use-case match
 */
export async function getBestModelForUseCase(
  useCase: string | null,
  supabaseUrl: string,
  supabaseServiceKey: string
): Promise<BedrockModel | null> {
  const models = await getAvailableBedrockModels(
    supabaseUrl,
    supabaseServiceKey
  );

  if (useCase) {
    // First, try to find a model specifically configured for this use case
    for (const model of models.values()) {
      if (model.use_case === useCase) {
        return model;
      }
    }
  }

  // Fall back to first available model (priority order)
  return models.values().next().value || null;
}

/**
 * Get all model IDs available for a specific use case
 */
export async function getModelsForUseCase(
  useCase: string,
  supabaseUrl: string,
  supabaseServiceKey: string
): Promise<BedrockModel[]> {
  const models = await getAvailableBedrockModels(
    supabaseUrl,
    supabaseServiceKey
  );

  const result: BedrockModel[] = [];

  for (const model of models.values()) {
    if (model.use_case === null || model.use_case === useCase) {
      result.push(model);
    }
  }

  return result;
}

/**
 * Validate if a model ID is available and return its config
 * Throws error with helpful message if model is invalid
 */
export async function validateBedrockModel(
  modelId: string | undefined,
  supabaseUrl: string,
  supabaseServiceKey: string
): Promise<BedrockModel> {
  if (!modelId) {
    throw new Error("Model ID is required");
  }

  const model = await getBedrockModel(modelId, supabaseUrl, supabaseServiceKey);

  if (!model) {
    const availableModels = await getAvailableBedrockModels(
      supabaseUrl,
      supabaseServiceKey
    );
    const modelList = Array.from(availableModels.values())
      .map((m) => `${m.model_name} (${m.model_id})`)
      .join(", ");

    throw new Error(
      `Model '${modelId}' is not available. Available models: ${modelList}`
    );
  }

  return model;
}

/**
 * Clear the model cache
 * Useful when models are updated in the database
 */
export function clearModelCache() {
  modelCache = null;
  modelCacheTime = 0;
  console.log("Bedrock models cache cleared");
}
