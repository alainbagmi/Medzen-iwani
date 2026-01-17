# Bedrock Models Configuration - MedZen

Complete guide for managing and switching between Bedrock models without code changes.

## Problem Solved

Previously, changing Bedrock models required:
- Modifying Lambda code
- Redeploying Lambda function
- Potential downtime

Now, models are **database-driven** and can be managed through Supabase or the admin UI.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│ Bedrock AI Chat Request                             │
├─────────────────────────────────────────────────────┤
│ Edge Function (bedrock-ai-chat)                    │
│ ├─ Loads models from bedrock_models table          │
│ ├─ Validates requested model is available          │
│ └─ Sends to Lambda with modelId                    │
├─────────────────────────────────────────────────────┤
│ Lambda Function (bedrock-ai-chat)                  │
│ ├─ Loads models from bedrock_models table (cached) │
│ ├─ Validates modelId before invocation             │
│ └─ Invokes appropriate Bedrock model format        │
├─────────────────────────────────────────────────────┤
│ Bedrock Runtime (eu-central-1)                    │
│ └─ Executes model and returns response            │
└─────────────────────────────────────────────────────┘
```

## Database Table: `bedrock_models`

Stores all available Bedrock models and their configurations.

### Schema

```sql
CREATE TABLE bedrock_models (
  id UUID PRIMARY KEY,
  model_id VARCHAR(255) UNIQUE,           -- e.g., "eu.amazon.nova-pro-v1:0"
  model_name VARCHAR(255),                -- e.g., "Amazon Nova Pro"
  provider VARCHAR(50),                   -- 'amazon' or 'anthropic'
  format VARCHAR(50),                     -- 'nova' or 'claude'
  max_tokens INT,                         -- Max output tokens
  temperature FLOAT,                      -- 0.0 - 2.0
  top_p FLOAT,                            -- 0.0 - 1.0
  input_cost_per_mtok FLOAT,             -- Cost per million tokens
  output_cost_per_mtok FLOAT,
  region VARCHAR(50),                     -- AWS region
  is_available BOOLEAN,                   -- Enable/disable model
  is_default BOOLEAN,                     -- Default model
  priority INT,                           -- Selection priority (lower = higher)
  use_case VARCHAR(100),                  -- 'health', 'clinical', 'operations', 'platform'
  description TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

## Available Models (Seeded)

### Amazon Nova (Latest - Recommended)
| Model | Provider | Cost | Use Case |
|-------|----------|------|----------|
| `eu.amazon.nova-pro-v1:0` | Amazon | $0.80/$3.20 | General (default) |
| `eu.amazon.nova-lite-v1:0` | Amazon | $0.075/$0.30 | Patient interactions |
| `eu.amazon.nova-micro-v1:0` | Amazon | $0.035/$0.14 | Simple tasks |

### Anthropic Claude 3 (Advanced Clinical)
| Model | Provider | Cost | Use Case |
|-------|----------|------|----------|
| `anthropic.claude-3-5-sonnet-20241022-v2:0` | Anthropic | $3.00/$15.00 | **Clinical decision support** |
| `anthropic.claude-3-sonnet-20240229-v1:0` | Anthropic | $3.00/$15.00 | Medical scenarios |
| `anthropic.claude-3-opus-20240229-v1:0` | Anthropic | $15.00/$75.00 | Complex analysis (disabled) |
| `anthropic.claude-3-haiku-20240307-v1:0` | Anthropic | $0.80/$4.00 | Fast operations (disabled) |

## How It Works

### 1. Edge Function (bedrock-ai-chat)

When a user sends an AI message:

```typescript
// 1. Validate model is available
await validateBedrockModel(selectedModel, supabaseUrl, supabaseServiceKey);

// 2. Pass to Lambda
const response = await fetch(bedrockLambdaUrl, {
  body: JSON.stringify({
    message,
    modelId: selectedModel,  // Passed from database
    systemPrompt,
    modelConfig
  })
});
```

### 2. Lambda Function (bedrock-ai-chat)

Lambda loads models on startup (cached for 1 hour):

```javascript
// Load latest models from database
await loadBedrockModelsFromDatabase();

// Validate model exists
if (!MODEL_CONFIGS[modelId]) {
  throw new Error(`Model '${modelId}' is not supported`);
}

// Build request based on model format (Nova vs Claude)
const requestBody = buildBedrockRequest(modelId, messages, systemPrompt);

// Invoke Bedrock
const response = await bedrockClient.send(
  new InvokeModelCommand({
    modelId: modelId,
    body: JSON.stringify(requestBody)
  })
);
```

## API Usage

### List Available Models

**Endpoint:** `GET /functions/v1/list-bedrock-models`

```bash
curl -X GET "https://noaeltglphdlkbflipit.supabase.co/functions/v1/list-bedrock-models" \
  -H "apikey: $SUPABASE_ANON_KEY"
```

**Response:**
```json
{
  "success": true,
  "models": [
    {
      "model_id": "eu.amazon.nova-pro-v1:0",
      "model_name": "Amazon Nova Pro",
      "provider": "amazon",
      "format": "nova",
      "max_tokens": 4096,
      "temperature": 0.7,
      "top_p": 0.9,
      "use_case": null
    },
    {
      "model_id": "anthropic.claude-3-5-sonnet-20241022-v2:0",
      "model_name": "Claude 3.5 Sonnet",
      "provider": "anthropic",
      "format": "claude",
      "max_tokens": 8192,
      "temperature": 0.3,
      "top_p": 0.85,
      "use_case": "clinical"
    }
  ],
  "count": 7
}
```

### Get Models for Specific Use Case

```bash
curl -X GET "https://noaeltglphdlkbflipit.supabase.co/functions/v1/list-bedrock-models?use_case=clinical" \
  -H "apikey: $SUPABASE_ANON_KEY"
```

Returns only models suitable for clinical use.

## Managing Models

### Add a New Model

1. **Enable in AWS Bedrock**
   ```bash
   # Verify model is available in eu-central-1
   aws bedrock list-foundation-models --region eu-central-1
   ```

2. **Insert into Supabase**
   ```sql
   INSERT INTO bedrock_models (
     model_id,
     model_name,
     provider,
     format,
     max_tokens,
     temperature,
     top_p,
     is_available,
     is_default,
     priority,
     use_case,
     description,
     input_cost_per_mtok,
     output_cost_per_mtok
   ) VALUES (
     'eu.amazon.nova-pro-v1:0',
     'Amazon Nova Pro',
     'amazon',
     'nova',
     4096,
     0.7,
     0.9,
     TRUE,
     TRUE,
     10,
     NULL,
     'High-quality reasoning model',
     0.80,
     3.20
   );
   ```

### Enable/Disable a Model

```sql
-- Disable a model (existing conversations can still use it)
UPDATE bedrock_models
SET is_available = FALSE
WHERE model_id = 'anthropic.claude-3-opus-20240229-v1:0';

-- Re-enable a model
UPDATE bedrock_models
SET is_available = TRUE
WHERE model_id = 'anthropic.claude-3-opus-20240229-v1:0';
```

### Change Default Model

```sql
-- Set new default
UPDATE bedrock_models
SET is_default = TRUE
WHERE model_id = 'anthropic.claude-3-5-sonnet-20241022-v2:0';

-- Remove old default
UPDATE bedrock_models
SET is_default = FALSE
WHERE model_id = 'eu.amazon.nova-pro-v1:0'
  AND model_id != 'anthropic.claude-3-5-sonnet-20241022-v2:0';
```

### Update Model Configuration

```sql
-- Change temperature (creativity) for a model
UPDATE bedrock_models
SET temperature = 0.5
WHERE model_id = 'eu.amazon.nova-lite-v1:0';

-- Change token limits
UPDATE bedrock_models
SET max_tokens = 8192
WHERE model_id = 'anthropic.claude-3-5-sonnet-20241022-v2:0';
```

### Assign Model to Use Case

```sql
-- Set model as preferred for clinical interactions
UPDATE bedrock_models
SET use_case = 'clinical'
WHERE model_id = 'anthropic.claude-3-5-sonnet-20241022-v2:0';

-- Reset use case (available for all)
UPDATE bedrock_models
SET use_case = NULL
WHERE model_id = 'eu.amazon.nova-pro-v1:0';
```

## Configuration Best Practices

### 1. Temperature Settings

- **0.3** (Claude defaults): More focused, clinical reasoning
- **0.7** (Nova defaults): Balanced creativity and consistency
- **1.0+**: More creative, exploratory responses

For medical use: Keep at 0.3-0.5 for reliability.

### 2. Token Limits

- **4096**: Sufficient for most medical queries
- **8192**: For complex consultations with history
- **Max output only**: Input tokens unlimited in Bedrock

### 3. Model Hierarchy

Priority order for selection:

1. **Use-case specific** (highest priority): e.g., clinical role → Claude model
2. **Default model** (fallback): Set `is_default = TRUE`
3. **First available** (last resort): Ordered by `priority`

### 4. Cost Optimization

```sql
-- Find cost-effective models
SELECT model_id, model_name,
       (input_cost_per_mtok + output_cost_per_mtok) / 2 as avg_cost
FROM bedrock_models
WHERE is_available = TRUE
ORDER BY avg_cost ASC;
```

## Troubleshooting

### Error: "Model 'xxx' is not supported"

**Cause:** Model ID not in `bedrock_models` table or `is_available = FALSE`

**Fix:**
```sql
-- Check if model exists
SELECT * FROM bedrock_models WHERE model_id = 'your-model-id';

-- Enable if disabled
UPDATE bedrock_models
SET is_available = TRUE
WHERE model_id = 'your-model-id';
```

### Error: "ValidationException" from Bedrock

**Cause:** Model ID format or AWS credentials issue

**Check:**
```bash
# List available models in your region
aws bedrock list-foundation-models --region eu-central-1 | grep "modelId"

# Verify Lambda has Bedrock permissions
aws iam get-role-policy --role-name medzen-bedrock-lambda --policy-name bedrock-invoke
```

### Model Cache Issues

If models don't update after database changes:

1. **Automatic refresh** (1 hour): Wait for cache to expire
2. **Manual refresh**: Call function to clear cache
   ```sql
   -- Models reload on next Lambda invocation
   -- Cache expires after 1 hour
   ```

## Deployment Steps

### 1. Apply Database Migration

```bash
npx supabase db push
```

### 2. Deploy Edge Function

```bash
npx supabase functions deploy bedrock-ai-chat
npx supabase functions deploy list-bedrock-models
```

### 3. Deploy Lambda Function

```bash
cd aws-lambda/bedrock-ai-chat
npm install
zip -r function.zip .
aws lambda update-function-code \
  --function-name medzen-bedrock-ai-chat \
  --zip-file fileb://function.zip
```

### 4. Verify Configuration

```bash
# Test edge function
curl -X GET "https://noaeltglphdlkbflipit.supabase.co/functions/v1/list-bedrock-models" \
  -H "apikey: $SUPABASE_ANON_KEY" | jq

# Test Lambda
# Send a message through the UI - should work without code changes
```

## Adding Custom Models

To support new Bedrock models:

1. **Update database** - Add row to `bedrock_models`
2. **Update `MODEL_CONFIGS`** in Lambda - IF model format is new
   ```javascript
   // Only needed if new format (nova/claude)
   'new.model-v1:0': { provider: 'provider', format: 'format' }
   ```
3. **Test** - List available models, send test message

## Monitoring

### Track Model Usage

```sql
-- Which models are being used?
SELECT
  model_used,
  COUNT(*) as usage_count,
  AVG(input_tokens) as avg_input_tokens,
  AVG(output_tokens) as avg_output_tokens
FROM ai_messages
WHERE model_used IS NOT NULL
GROUP BY model_used
ORDER BY usage_count DESC;
```

### Cost Analysis

```sql
-- Calculate costs by model
SELECT
  bm.model_id,
  bm.model_name,
  COUNT(*) as message_count,
  SUM(am.input_tokens) / 1000000.0 * bm.input_cost_per_mtok as input_cost,
  SUM(am.output_tokens) / 1000000.0 * bm.output_cost_per_mtok as output_cost
FROM ai_messages am
JOIN bedrock_models bm ON am.model_used = bm.model_id
WHERE am.created_at > NOW() - INTERVAL '30 days'
GROUP BY bm.model_id, bm.model_name, bm.input_cost_per_mtok, bm.output_cost_per_mtok
ORDER BY (input_cost + output_cost) DESC;
```

## Summary

✅ **Before:** Model changes required code deployment
✅ **After:** Model changes via database updates (instant)

Key files:
- Migration: `supabase/migrations/20260115140000_create_bedrock_models_table.sql`
- Shared helper: `supabase/functions/_shared/bedrock-models.ts`
- Edge function: `supabase/functions/bedrock-ai-chat/index.ts`
- Lambda function: `aws-lambda/bedrock-ai-chat/index.mjs`
- Model list API: `supabase/functions/list-bedrock-models/index.ts`
