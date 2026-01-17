# Bedrock Models - Jump Server Setup Guide

Complete guide for setting up AWS permissions and model switching capabilities on your jump server.

## Overview

Your Lambda function ("jump server") needs to access ALL Bedrock models in the region. This guide ensures:

✅ Lambda has proper IAM permissions
✅ Jump server can access any model
✅ Quick switching between models (no code changes)
✅ Auto-selection based on user role or request

---

## Step 1: Set Up IAM Permissions

### A. Apply Bedrock Access Policy

```bash
# Navigate to aws-deployment directory
cd aws-deployment

# Make script executable
chmod +x setup-bedrock-permissions.sh

# Run setup (one-time)
./setup-bedrock-permissions.sh
```

This script:
1. ✅ Attaches IAM policy to Lambda role
2. ✅ Grants access to all Nova and Claude models
3. ✅ Verifies permissions
4. ✅ Lists available models in region

### B. What Permissions Are Applied

**IAM Policy:** `aws-deployment/iam-policies/bedrock-models-access.json`

```json
{
  "Action": [
    "bedrock:InvokeModel",
    "bedrock:InvokeModelWithResponseStream",
    "bedrock:GetFoundationModel",
    "bedrock:ListFoundationModels"
  ],
  "Resource": [
    "arn:aws:bedrock:eu-central-1::foundation-model/amazon.nova-*",
    "arn:aws:bedrock:eu-central-1::foundation-model/anthropic.claude-*"
  ]
}
```

This allows Lambda to:
- Invoke any Nova or Claude model
- List available models
- Get model details

---

## Step 2: Deploy Model Management Functions

### A. Deploy Management API

```bash
# Deploy the model management edge function
npx supabase functions deploy manage-bedrock-models
```

This creates a protected endpoint (`/functions/v1/manage-bedrock-models`) for:
- Listing available models
- Enabling/disabling models
- Setting default models
- Validating models

### B. Set Environment Variables

Ensure your deployment has:

```bash
# Lambda environment
export SUPABASE_URL=https://noaeltglphdlkbflipit.supabase.co
export SUPABASE_SERVICE_KEY=<your-service-key>
export BEDROCK_REGION=eu-central-1
```

---

## Step 3: Quick Model Switching

### Option A: Using CLI Script (Easiest)

```bash
# Set required environment variable
export SUPABASE_SERVICE_KEY=<your-service-key>

# List all available models
./scripts/switch-bedrock-model.sh list

# Show current default model
./scripts/switch-bedrock-model.sh default

# Switch to Claude for clinical reasoning
./scripts/switch-bedrock-model.sh anthropic.claude-3-5-sonnet-20241022-v2:0 switch

# Switch back to Nova
./scripts/switch-bedrock-model.sh eu.amazon.nova-pro-v1:0 switch

# Enable a disabled model
./scripts/switch-bedrock-model.sh eu.amazon.nova-lite-v1:0 enable

# Disable a model
./scripts/switch-bedrock-model.sh eu.amazon.nova-micro-v1:0 disable
```

**Output Example:**
```
🔄 Switching to model: anthropic.claude-3-5-sonnet-20241022-v2:0...
✅ Successfully switched to anthropic.claude-3-5-sonnet-20241022-v2:0

Model details:
Claude 3.5 Sonnet
Cost: $3/$15
Format: claude
```

### Option B: Using REST API (For Integration)

```bash
export SUPABASE_KEY="<your-service-key>"

# List models
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/manage-bedrock-models" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "list"}' | jq

# Set default model
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/manage-bedrock-models" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "set-default",
    "model_id": "anthropic.claude-3-5-sonnet-20241022-v2:0"
  }' | jq

# Enable a model
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/manage-bedrock-models" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "enable", "model_id": "eu.amazon.nova-lite-v1:0"}' | jq

# Validate a model exists
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/manage-bedrock-models" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action": "validate", "model_id": "anthropic.claude-3-5-sonnet-20241022-v2:0"}' | jq
```

### Option C: Direct SQL (Advanced)

```sql
-- Switch to Claude
UPDATE bedrock_models
SET is_available = FALSE, is_default = FALSE
WHERE model_id = 'eu.amazon.nova-pro-v1:0';

UPDATE bedrock_models
SET is_available = TRUE, is_default = TRUE
WHERE model_id = 'anthropic.claude-3-5-sonnet-20241022-v2:0';

-- Verify change
SELECT model_id, model_name, is_default FROM bedrock_models WHERE is_available = TRUE;
```

---

## Step 4: Auto-Selection Based on Request

The system automatically selects the best model based on:

### By User Role (Automatic)
```
Patient (health role)        → eu.amazon.nova-lite-v1:0 (cheap)
Medical Provider (clinical)  → anthropic.claude-3-5-sonnet (expert)
Facility Admin (operations)  → eu.amazon.nova-micro-v1:0 (fast)
System Admin (platform)      → eu.amazon.nova-pro-v1:0 (default)
```

Configure in `ai_assistants` table:
```sql
UPDATE ai_assistants
SET model_version = 'eu.amazon.nova-lite-v1:0'
WHERE assistant_type = 'health';

UPDATE ai_assistants
SET model_version = 'anthropic.claude-3-5-sonnet-20241022-v2:0'
WHERE assistant_type = 'clinical';
```

### By Conversation (After Initial Setup)
Once a conversation starts, it keeps the same model throughout.

### By Use Case (Database Field)
Set `use_case` in `bedrock_models`:
```sql
UPDATE bedrock_models
SET use_case = 'clinical'
WHERE model_id = 'anthropic.claude-3-5-sonnet-20241022-v2:0';

UPDATE bedrock_models
SET use_case = 'health'
WHERE model_id = 'eu.amazon.nova-lite-v1:0';
```

---

## Lambda Function Structure

Your updated Lambda handles:

```
Request arrives
  ↓
Load models from bedrock_models table (cached)
  ↓
Validate requested/selected model
  ↓
Build request based on model format
  ├─ Nova format: { messages, system, inferenceConfig }
  └─ Claude format: { messages, system, anthropic_version }
  ↓
Invoke Bedrock with modelId
  ↓
Parse response based on model format
  ├─ Nova: response.output.message.content[0].text
  └─ Claude: response.content[0].text
  ↓
Return response to user
```

---

## Monitoring & Verification

### Check Lambda Has Correct Permissions

```bash
# View Lambda's IAM role
aws iam get-role --role-name medzen-bedrock-lambda

# View attached policies
aws iam list-role-policies --role-name medzen-bedrock-lambda

# Get specific policy
aws iam get-role-policy \
  --role-name medzen-bedrock-lambda \
  --policy-name bedrock-models-access
```

### List Available Models in Region

```bash
# View all models in eu-central-1
aws bedrock list-foundation-models \
  --region eu-central-1 \
  --query 'modelSummaries[*].modelId' \
  --output table | grep -E '(nova|claude)'

# Output should show:
# - amazon.nova-pro-v1:0
# - amazon.nova-lite-v1:0
# - amazon.nova-micro-v1:0
# - anthropic.claude-3-5-sonnet-20241022-v2:0
# - anthropic.claude-3-sonnet-20240229-v1:0
# - anthropic.claude-3-opus-20240229-v1:0
# - anthropic.claude-3-haiku-20240307-v1:0
```

### Test Model Access

```bash
# Test invoking a model
aws bedrock invoke-model \
  --region eu-central-1 \
  --model-id eu.amazon.nova-pro-v1:0 \
  --content-type application/json \
  --accept application/json \
  --body '{"messages":[{"role":"user","content":"Hello"}]}' \
  response.json

cat response.json | jq
```

### Track Model Switching

```sql
-- See which models are being used
SELECT
  model_used,
  COUNT(*) as usage_count,
  COUNT(DISTINCT conversation_id) as conversations,
  AVG(response_time_ms) as avg_response_time_ms
FROM ai_messages
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY model_used
ORDER BY usage_count DESC;

-- See cost per model
SELECT
  bm.model_id,
  bm.model_name,
  COUNT(*) as usage_count,
  (SUM(am.input_tokens) / 1000000.0 * bm.input_cost_per_mtok) +
  (SUM(am.output_tokens) / 1000000.0 * bm.output_cost_per_mtok) as estimated_cost
FROM ai_messages am
JOIN bedrock_models bm ON am.model_used = bm.model_id
GROUP BY bm.model_id, bm.model_name
ORDER BY estimated_cost DESC;
```

---

## Troubleshooting

### Lambda Access Denied Error

```
AccessDenied: User is not authorized to perform: bedrock:InvokeModel
```

**Fix:**
1. Run `aws-deployment/setup-bedrock-permissions.sh`
2. Verify policy: `aws iam get-role-policy --role-name medzen-bedrock-lambda --policy-name bedrock-models-access`
3. Wait 1-2 minutes for IAM policy to propagate

### Model Not Available in Region

```
ValidationException: The provided model identifier is invalid
```

**Fix:**
1. Check available models: `aws bedrock list-foundation-models --region eu-central-1`
2. Verify model exists in `bedrock_models` table: `SELECT * FROM bedrock_models WHERE model_id = 'xxx';`
3. Enable model: `UPDATE bedrock_models SET is_available = TRUE WHERE model_id = 'xxx';`

### CLI Script Authentication Error

```
❌ Error: SUPABASE_SERVICE_KEY environment variable not set
```

**Fix:**
```bash
export SUPABASE_SERVICE_KEY=$(aws secretsmanager get-secret-value --secret-id supabase/service-key --query SecretString --output text)
./scripts/switch-bedrock-model.sh list
```

### Changes Not Taking Effect

Model cache expires after 1 hour. To force immediate reload:

```bash
# Redeploy Lambda (if changed code)
cd aws-lambda/bedrock-ai-chat
npm install && zip -r function.zip . && \
aws lambda update-function-code --function-name medzen-bedrock-ai-chat --zip-file fileb://function.zip

# Or just wait 1 hour for cache to expire
```

---

## Best Practices

### 1. Cost Optimization

Switch to cheaper models for non-critical tasks:

```bash
# Production: Use Claude for clinical decisions
./scripts/switch-bedrock-model.sh anthropic.claude-3-5-sonnet-20241022-v2:0 switch

# Development/Testing: Use Nova Micro (10x cheaper)
./scripts/switch-bedrock-model.sh eu.amazon.nova-micro-v1:0 switch
```

Cost comparison per million tokens:
- Nova Pro: $3.80
- Nova Lite: $0.375 (10x cheaper)
- Nova Micro: $0.175 (22x cheaper)
- Claude 3.5 Sonnet: $18.00

### 2. Role-Based Selection

Automatically assign models per user role:

```sql
-- Clinical (medical experts) get best model
UPDATE ai_assistants
SET model_version = 'anthropic.claude-3-5-sonnet-20241022-v2:0'
WHERE assistant_type = 'clinical';

-- Patients get cheap model
UPDATE ai_assistants
SET model_version = 'eu.amazon.nova-lite-v1:0'
WHERE assistant_type = 'health';

-- Operations get fast model
UPDATE ai_assistants
SET model_version = 'eu.amazon.nova-micro-v1:0'
WHERE assistant_type = 'operations';
```

### 3. Graceful Degradation

Always keep at least one model enabled:

```bash
# Disable old model AFTER enabling new one
./scripts/switch-bedrock-model.sh <new-model> switch
# Don't disable unless new model confirmed working
```

### 4. Monitoring

Track model changes and their impact:

```sql
-- Monitor model performance
SELECT
  model_used,
  AVG(response_time_ms) as avg_response_time,
  STDDEV(response_time_ms) as response_std_dev,
  COUNT(*) as request_count
FROM ai_messages
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY model_used
ORDER BY response_time_ms ASC;
```

---

## Complete Workflow

### Scenario: Switch from Nova to Claude

```bash
# 1. Check current setup
./scripts/switch-bedrock-model.sh default

# Output: eu.amazon.nova-pro-v1:0

# 2. List available models
./scripts/switch-bedrock-model.sh list

# 3. Switch to Claude
./scripts/switch-bedrock-model.sh anthropic.claude-3-5-sonnet-20241022-v2:0 switch

# 4. Verify change
./scripts/switch-bedrock-model.sh default

# Output: anthropic.claude-3-5-sonnet-20241022-v2:0

# 5. Send test message through app
# (Should use Claude model automatically)

# 6. If needed, switch back
./scripts/switch-bedrock-model.sh eu.amazon.nova-pro-v1:0 switch
```

**Total time: < 10 seconds** (vs 5+ minutes with code deployment)

---

## Summary

✅ Lambda now has full Bedrock access
✅ Can switch between models in < 1 second
✅ Multiple switching methods (CLI, API, SQL)
✅ Automatic role-based selection
✅ Built-in monitoring and cost tracking
✅ No code changes required

---

## Next Steps

1. Run setup script: `aws-deployment/setup-bedrock-permissions.sh`
2. Deploy edge functions: `npx supabase functions deploy manage-bedrock-models`
3. Test CLI: `./scripts/switch-bedrock-model.sh list`
4. Switch model: `./scripts/switch-bedrock-model.sh <model-id> switch`
5. Send AI message and verify it works

---

**Need help?** Check the main guides: `BEDROCK_QUICK_START.md` or `BEDROCK_MODELS_CONFIGURATION.md`
