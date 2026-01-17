# Bedrock Models - Quick Start

Fixed your "The provided model identifier is invalid" error by making models database-driven. Now you can change models without code changes!

## What Was Fixed

**Problem:** Model validation error when changing Bedrock models
**Root Cause:** Model ID wasn't in the hardcoded `MODEL_CONFIGS` dictionary
**Solution:** Models now load from `bedrock_models` database table

## Installation (One-time Setup)

```bash
# 1. Apply database migration
npx supabase db push

# 2. Deploy updated edge function
npx supabase functions deploy bedrock-ai-chat

# 3. Deploy new listing function
npx supabase functions deploy list-bedrock-models

# 4. Update Lambda function
cd aws-lambda/bedrock-ai-chat
npm install
zip -r function.zip .
aws lambda update-function-code --function-name medzen-bedrock-ai-chat --zip-file fileb://function.zip
```

## Usage

### View Available Models

```bash
curl -X GET "https://noaeltglphdlkbflipit.supabase.co/functions/v1/list-bedrock-models" \
  -H "apikey: $SUPABASE_ANON_KEY" | jq
```

### Switch Models (No Code Changes!)

Option A: **Via Supabase SQL**
```sql
-- See all models
SELECT model_id, model_name, is_available, priority FROM bedrock_models;

-- Enable a different model
UPDATE bedrock_models SET is_available = TRUE, is_default = TRUE
WHERE model_id = 'anthropic.claude-3-5-sonnet-20241022-v2:0';

-- Disable old default
UPDATE bedrock_models SET is_default = FALSE
WHERE model_id = 'eu.amazon.nova-pro-v1:0';
```

Option B: **Via AI Assistants Table**
```sql
-- Change model for a specific role
UPDATE ai_assistants
SET model_version = 'anthropic.claude-3-5-sonnet-20241022-v2:0'
WHERE assistant_type = 'clinical';
```

### Test Your Configuration

Send an AI message through the app - it will now use the configured model without any errors!

## Available Models

| Model | Cost | Best For | Status |
|-------|------|----------|--------|
| `eu.amazon.nova-pro-v1:0` | $0.80/$3.20 | General (DEFAULT) | ✅ Enabled |
| `eu.amazon.nova-lite-v1:0` | $0.075/$0.30 | Patients | ✅ Enabled |
| `eu.amazon.nova-micro-v1:0` | $0.035/$0.14 | Simple tasks | ✅ Enabled |
| `anthropic.claude-3-5-sonnet-20241022-v2:0` | $3/$15 | **Clinical** | ✅ Enabled |
| `anthropic.claude-3-sonnet-20240229-v1:0` | $3/$15 | Medical | ✅ Enabled |
| `anthropic.claude-3-opus-20240229-v1:0` | $15/$75 | Complex | ❌ Disabled |
| `anthropic.claude-3-haiku-20240307-v1:0` | $0.80/$4 | Operations | ❌ Disabled |

## Common Tasks

### Add a New Model
```sql
INSERT INTO bedrock_models (
  model_id, model_name, provider, format,
  max_tokens, temperature, top_p, is_available,
  input_cost_per_mtok, output_cost_per_mtok
) VALUES (
  'your-model-id',
  'Model Name',
  'amazon',  -- or 'anthropic'
  'nova',    -- or 'claude'
  4096, 0.7, 0.9, TRUE,
  0.80, 3.20
);
```

### Disable a Model
```sql
UPDATE bedrock_models SET is_available = FALSE
WHERE model_id = 'your-model-id';
```

### Set Model for Specific Role
```sql
UPDATE bedrock_models SET use_case = 'clinical'
WHERE model_id = 'anthropic.claude-3-5-sonnet-20241022-v2:0';
```

## Troubleshooting

**Error: "Model 'xxx' is not supported"**
- Check if model exists: `SELECT * FROM bedrock_models WHERE model_id = 'xxx';`
- Enable it: `UPDATE bedrock_models SET is_available = TRUE WHERE model_id = 'xxx';`

**Error: ValidationException from Bedrock**
- Model ID format is wrong or model not available in AWS
- Verify in AWS: `aws bedrock list-foundation-models --region eu-central-1`

**Models not updating after database change**
- Lambda caches models for 1 hour
- Wait or redeploy Lambda to clear cache

## Files Modified

- ✅ `supabase/migrations/20260115140000_create_bedrock_models_table.sql` - Database schema
- ✅ `supabase/functions/_shared/bedrock-models.ts` - Shared helper functions
- ✅ `supabase/functions/bedrock-ai-chat/index.ts` - Edge function with validation
- ✅ `supabase/functions/list-bedrock-models/index.ts` - Model listing API
- ✅ `aws-lambda/bedrock-ai-chat/index.mjs` - Lambda with dynamic model loading

## Next Steps

1. ✅ Deploy changes (see Installation above)
2. ✅ Test by listing models: `curl https://... /list-bedrock-models`
3. ✅ Send an AI message through the app
4. ✅ Change a model and test again (no re-deployment needed!)

---

**Need more details?** See `BEDROCK_MODELS_CONFIGURATION.md`
