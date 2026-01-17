# Bedrock Models - Complete Solution Summary

## Problem You Were Facing

```
Error invoking Bedrock model: An error occurred (ValidationException)
when calling the InvokeModel operation: The provided model identifier
is invalid.
```

## Root Cause

The Bedrock model ID you were trying to use wasn't in the hardcoded `MODEL_CONFIGS` object in the Lambda function. This meant:

1. ❌ Hardcoded model list in Lambda
2. ❌ Required code changes to add/change models
3. ❌ Required Lambda redeployment to use new models
4. ❌ No flexibility or easy switching

## The Solution: Database-Driven Models

You now have a complete flexible system that allows you to:

✅ Add models without code changes
✅ Enable/disable models instantly
✅ Switch between any Bedrock model
✅ Set different models per user role
✅ Track model usage and costs
✅ Cache models for performance (1-hour TTL)

## What Was Changed

### 1. **New Database Table** (`bedrock_models`)
   - Stores all available models and their configurations
   - Managed by system admins, readable by all authenticated users
   - Includes cost tracking, region info, and use-case assignment

### 2. **Updated Lambda Function** (aws-lambda/bedrock-ai-chat)
   - Loads models from database instead of hardcoded list
   - Validates model ID before invoking Bedrock
   - Returns helpful error message with available models
   - Caches models for 1 hour to reduce database queries

### 3. **Updated Edge Function** (supabase/functions/bedrock-ai-chat)
   - Validates model exists before sending to Lambda
   - Provides graceful error handling
   - Clear error messages to end users

### 4. **New Shared Helper** (supabase/functions/_shared/bedrock-models.ts)
   - Reusable functions for both edge functions and Lambda
   - Model validation and lookup
   - Use-case-based model selection
   - Database caching

### 5. **New API Endpoint** (supabase/functions/list-bedrock-models)
   - REST API to list available models
   - Filter by use case
   - Used by frontend to show available options

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                  Flutter/Web App                        │
├─────────────────────────────────────────────────────────┤
│  bedrock-ai-chat API                                   │
│  └─ POST /functions/v1/bedrock-ai-chat                │
│     └─ body: { message, conversationId, userId... }   │
├─────────────────────────────────────────────────────────┤
│  Edge Function: bedrock-ai-chat                        │
│  ├─ Load models from bedrock_models table             │
│  ├─ Validate model exists                             │
│  ├─ Determine user role                               │
│  ├─ Get assistant config                              │
│  └─ Call Lambda with modelId                          │
├─────────────────────────────────────────────────────────┤
│  Lambda Function: bedrock-ai-chat                      │
│  ├─ Load models from bedrock_models (cached)          │
│  ├─ Validate modelId is available                     │
│  ├─ Build request based on model format               │
│  │  ├─ Nova format: { messages, system, inference... }│
│  │  └─ Claude format: { messages, system, anthropic..}│
│  └─ Invoke Bedrock Runtime                            │
├─────────────────────────────────────────────────────────┤
│  AWS Bedrock (eu-central-1)                            │
│  ├─ Amazon Nova Pro/Lite/Micro                        │
│  └─ Anthropic Claude 3.5/3 Sonnet/Haiku/Opus        │
├─────────────────────────────────────────────────────────┤
│  Supabase Database                                     │
│  ├─ bedrock_models (model configs)                   │
│  ├─ ai_assistants (role-based models)                │
│  ├─ ai_conversations                                 │
│  └─ ai_messages                                       │
└─────────────────────────────────────────────────────────┘
```

## Files Created/Modified

### New Files
- ✅ `supabase/migrations/20260115140000_create_bedrock_models_table.sql` - Database schema
- ✅ `supabase/functions/_shared/bedrock-models.ts` - Helper functions
- ✅ `supabase/functions/list-bedrock-models/index.ts` - Model listing API
- ✅ `BEDROCK_MODELS_CONFIGURATION.md` - Full documentation
- ✅ `BEDROCK_QUICK_START.md` - Quick reference
- ✅ `BEDROCK_FIX_SUMMARY.md` - This file
- ✅ `verify_bedrock_deployment.sql` - Verification script

### Modified Files
- ✅ `supabase/functions/bedrock-ai-chat/index.ts` - Added model validation
- ✅ `aws-lambda/bedrock-ai-chat/index.mjs` - Added dynamic model loading

## Pre-Configured Models

### Amazon Nova (Recommended - Latest)
| Model | Cost | Best For |
|-------|------|----------|
| `eu.amazon.nova-pro-v1:0` | $0.80 / $3.20 | DEFAULT - General purpose |
| `eu.amazon.nova-lite-v1:0` | $0.075 / $0.30 | Patient interactions (health role) |
| `eu.amazon.nova-micro-v1:0` | $0.035 / $0.14 | Simple operations |

### Anthropic Claude 3 (Advanced)
| Model | Cost | Best For |
|-------|------|----------|
| `anthropic.claude-3-5-sonnet-20241022-v2:0` | $3 / $15 | **CLINICAL DECISIONS** (clinical role) |
| `anthropic.claude-3-sonnet-20240229-v1:0` | $3 / $15 | Medical scenarios |
| `anthropic.claude-3-opus-20240229-v1:0` | $15 / $75 | Complex analysis (disabled) |
| `anthropic.claude-3-haiku-20240307-v1:0` | $0.80 / $4 | Fast operations (disabled) |

## Deployment Checklist

- [ ] **1. Apply database migration**
  ```bash
  npx supabase db push
  ```

- [ ] **2. Deploy edge functions**
  ```bash
  npx supabase functions deploy bedrock-ai-chat
  npx supabase functions deploy list-bedrock-models
  ```

- [ ] **3. Update Lambda function**
  ```bash
  cd aws-lambda/bedrock-ai-chat
  npm install
  zip -r function.zip .
  aws lambda update-function-code \
    --function-name medzen-bedrock-ai-chat \
    --zip-file fileb://function.zip
  ```

- [ ] **4. Verify deployment**
  ```bash
  # Run SQL verification script
  # Check output in Supabase SQL editor
  ```

- [ ] **5. Test changes**
  ```bash
  # List available models
  curl -X GET "https://noaeltglphdlkbflipit.supabase.co/functions/v1/list-bedrock-models" \
    -H "apikey: $SUPABASE_ANON_KEY"

  # Send AI message through app
  # Should work without errors!
  ```

## Common Operations

### View All Models
```sql
SELECT model_id, model_name, is_available, is_default, use_case
FROM bedrock_models
ORDER BY priority;
```

### Switch to Claude for Clinical Decisions
```sql
UPDATE bedrock_models
SET is_available = FALSE, is_default = FALSE
WHERE model_id = 'eu.amazon.nova-pro-v1:0';

UPDATE bedrock_models
SET is_available = TRUE, is_default = TRUE
WHERE model_id = 'anthropic.claude-3-5-sonnet-20241022-v2:0';
```

### Add a New Model
```sql
INSERT INTO bedrock_models (
  model_id, model_name, provider, format,
  max_tokens, temperature, top_p,
  is_available, is_default, priority,
  input_cost_per_mtok, output_cost_per_mtok,
  description
) VALUES (
  'eu.amazon.nova-pro-v1:0',
  'Amazon Nova Pro',
  'amazon',
  'nova',
  4096, 0.7, 0.9,
  TRUE, TRUE, 10,
  0.80, 3.20,
  'High-quality reasoning model'
);
```

### Check Model Usage Stats
```sql
SELECT
  model_used,
  COUNT(*) as usage_count,
  AVG(input_tokens + output_tokens) as avg_tokens,
  MAX(response_time_ms) as max_response_time_ms
FROM ai_messages
WHERE model_used IS NOT NULL
  AND created_at > NOW() - INTERVAL '7 days'
GROUP BY model_used
ORDER BY usage_count DESC;
```

## What Happens When You Change Models

### Before (Old System)
1. ❌ Edit Lambda code
2. ❌ Redeploy Lambda (3-5 minutes)
3. ❌ Downtime for users
4. ❌ Risk of introducing bugs

### After (New System)
1. ✅ Update database record (1 second)
2. ✅ Immediate effect (next request)
3. ✅ No downtime
4. ✅ Easy rollback

## Error Handling

If a user encounters an error:

**Old message:**
```
The provided model identifier is invalid.
```

**New message:**
```
Model 'unknown-model-id' is not supported.
Available models: eu.amazon.nova-pro-v1:0,
anthropic.claude-3-5-sonnet-20241022-v2:0, ...
```

Much more helpful! 🎉

## Performance Optimization

### Caching Strategy
- **Lambda**: Caches models for 1 hour
- **Edge function**: Validates before sending to Lambda
- **Database**: RLS policies optimized for reads

### Cost Reduction
By tracking costs in the database, you can:
- Switch to cheaper models if needed
- Monitor spending per user role
- Optimize token usage

Example cost comparison:
- Nova Pro: $3.80 per million tokens
- Nova Lite: $0.375 per million tokens (10x cheaper!)

## Troubleshooting

### "Model 'xxx' is not supported"
1. Check if model exists: `SELECT * FROM bedrock_models WHERE model_id = 'xxx';`
2. If not found, insert it (see "Add a New Model" above)
3. If disabled, enable it: `UPDATE bedrock_models SET is_available = TRUE WHERE model_id = 'xxx';`

### Model Changes Not Taking Effect
- Lambda caches models for 1 hour
- Wait for cache to expire OR redeploy Lambda to clear immediately
- Edge function validates on each request (no cache)

### AWS Bedrock Errors
Check:
```bash
# List available models in eu-central-1
aws bedrock list-foundation-models --region eu-central-1 | grep modelId

# Check Lambda permissions
aws iam get-role-policy --role-name medzen-bedrock-lambda --policy-name bedrock-invoke
```

## Next Steps

1. **Deploy everything** (see checklist above)
2. **Test the new system** (send an AI message)
3. **Explore model options** (list available models)
4. **Optimize for your use case** (switch models per role)
5. **Monitor usage** (track costs and performance)

---

## FAQ

**Q: Do existing conversations change models?**
A: No. Each conversation keeps its original model. New conversations use the configured default.

**Q: Can I use different models for different users?**
A: Yes! Set `use_case` for medical providers vs patients, then configure `ai_assistants` table per role.

**Q: What if a model becomes unavailable?**
A: Set `is_available = FALSE` and assign a new default. Existing conversations still work.

**Q: How long is the model cache?**
A: Lambda caches for 1 hour. Edge function validates every request.

**Q: Can I add custom models?**
A: Yes! Just insert into `bedrock_models` table. If new format (not nova/claude), update `MODEL_CONFIGS` in Lambda.

---

**Ready to use the new system?** Start with `BEDROCK_QUICK_START.md` for the TL;DR version!
