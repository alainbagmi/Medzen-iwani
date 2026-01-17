# Bedrock Model Orchestration System

**Version:** 1.0
**Region:** eu-central-1
**Last Updated:** January 15, 2026

## Overview

The Bedrock Model Orchestration System provides comprehensive management of AI models across the MedZen platform. It enables:

- **Instant model switching** without code deployment
- **Auto-switching** based on use case with user notifications
- **Manual switching** via CLI or API
- **Full access** to all Bedrock models in the eu-central-1 region
- **Cost tracking** and analytics for model usage
- **Audit logging** of all model switching events

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Application                      │
│  (show_model_switch_notification.dart action)                │
└────────────────────────┬────────────────────────────────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                 │
┌───────▼─────────┐        ┌──────────────▼──────┐
│  bedrock-ai-    │        │  orchestrate-      │
│  chat           │        │  bedrock-models    │
│  (Edge Function)│        │  (Edge Function)   │
└────────┬────────┘        └──────────┬─────────┘
         │                             │
         │    ┌────────────────────────┤
         │    │                        │
    ┌────▼────▼─────────────────────────────┐
    │   Supabase Database                   │
    │  ┌─────────────────────────────────┐  │
    │  │  bedrock_models (config)        │  │
    │  │  bedrock_model_switches (log)   │  │
    │  │  ai_conversations (state)       │  │
    │  │  ai_assistants (mapping)        │  │
    │  └─────────────────────────────────┘  │
    └────────────┬──────────────────────────┘
                 │
    ┌────────────▼──────────────┐
    │   AWS Bedrock             │
    │  (Nova, Claude models)    │
    └───────────────────────────┘
```

## Components

### 1. IAM Policy (Jump Server Access)

**File:** `aws-deployment/iam-policies/bedrock-models-access.json`

**Access Level:** Full access to all Bedrock models in eu-central-1

**Included Vendors:**
- Amazon Nova (nova-lite, nova-pro, nova-micro)
- Anthropic Claude (3.5 Sonnet, 3 Opus, etc.)
- Meta Llama
- Mistral
- Cohere

**Permissions:**
```json
"bedrock:InvokeModel"
"bedrock:InvokeModelWithResponseStream"
"bedrock:GetFoundationModel"
"bedrock:ListFoundationModels"
"bedrock:GetInferenceProfile"
"bedrock:ListInferenceProfiles"
```

**To Apply:**
```bash
cd aws-deployment
./setup-bedrock-permissions.sh
```

### 2. Orchestration Edge Function

**File:** `supabase/functions/orchestrate-bedrock-models/index.ts`

**Endpoint:** `https://noaeltglphdlkbflipit.supabase.co/functions/v1/orchestrate-bedrock-models`

**Actions:**

#### List All Models
```bash
curl -X POST "$SUPABASE_URL/functions/v1/orchestrate-bedrock-models" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action":"list-all"}'
```

**Response:**
```json
{
  "success": true,
  "action": "list-all",
  "data": {
    "total": 8,
    "models": [
      {
        "id": "eu.amazon.nova-pro-v1:0",
        "name": "Amazon Nova Pro",
        "provider": "amazon",
        "useCase": "operations",
        "maxTokens": 4000
      }
    ]
  }
}
```

#### List Models for Use Case
```bash
curl -X POST "$SUPABASE_URL/functions/v1/orchestrate-bedrock-models" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "get-for-use-case",
    "useCase": "clinical"
  }'
```

#### Manual Model Switch
```bash
curl -X POST "$SUPABASE_URL/functions/v1/orchestrate-bedrock-models" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "switch",
    "modelId": "eu.amazon.nova-lite-v1:0",
    "conversationId": "conv-123",
    "userId": "user-456",
    "reason": "Cost optimization",
    "showNotification": true
  }'
```

**Response with Notification:**
```json
{
  "success": true,
  "action": "switch",
  "data": {
    "switched": true,
    "from": "Claude 3.5 Sonnet",
    "to": "Amazon Nova Lite"
  },
  "notification": {
    "title": "Switching AI Model",
    "message": "Upgraded from Claude 3.5 Sonnet to Amazon Nova Lite (Cost optimization)...",
    "type": "manual",
    "modelName": "Amazon Nova Lite",
    "modelId": "eu.amazon.nova-lite-v1:0"
  }
}
```

#### Auto-Switch with Notification
```bash
curl -X POST "$SUPABASE_URL/functions/v1/orchestrate-bedrock-models" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "auto-switch",
    "useCase": "clinical",
    "conversationId": "conv-123",
    "userId": "user-456",
    "showNotification": true
  }'
```

#### Validate Model
```bash
curl -X POST "$SUPABASE_URL/functions/v1/orchestrate-bedrock-models" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "validate",
    "modelId": "eu.amazon.nova-pro-v1:0"
  }'
```

#### Clear Cache
```bash
curl -X POST "$SUPABASE_URL/functions/v1/orchestrate-bedrock-models" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action":"clear-cache"}'
```

### 3. CLI Orchestrator

**File:** `scripts/orchestrate-bedrock.sh`

**Commands:**

```bash
# List all models
./orchestrate-bedrock.sh list

# Show models for specific use case
./orchestrate-bedrock.sh use-case clinical
./orchestrate-bedrock.sh use-case health
./orchestrate-bedrock.sh use-case operations
./orchestrate-bedrock.sh use-case platform

# Validate a model
./orchestrate-bedrock.sh validate eu.amazon.nova-pro-v1:0

# Manual switch with reason
./orchestrate-bedrock.sh switch eu.amazon.nova-lite-v1:0 "Cost optimization"

# Auto-switch to optimal model
./orchestrate-bedrock.sh auto-switch clinical

# Clear cache after database updates
./orchestrate-bedrock.sh clear-cache
```

**Setup:**
```bash
export SUPABASE_SERVICE_KEY=your-service-key-here
chmod +x scripts/orchestrate-bedrock.sh
./scripts/orchestrate-bedrock.sh list
```

### 4. Flutter UI Notifications

**File:** `lib/custom_code/actions/show_model_switch_notification.dart`

**Three Notification Components:**

#### 1. Auto-Switch Snackbar Notification
```dart
import 'show_model_switch_notification.dart';

// Called automatically when auto-switching happens
await showModelSwitchNotification(
  context,
  modelName: "Amazon Nova Pro",
  modelId: "eu.amazon.nova-pro-v1:0",
  type: 'auto',
  title: "Auto-Switching AI Model",
  message: "Upgraded to better model for this request...",
  displayDuration: Duration(seconds: 5),
);
```

**Display:**
- Green background for auto-switches
- Blue background for manual switches
- Shows model name, provider, and reason
- Auto-dismisses after 5 seconds

#### 2. Model Selection Dialog
```dart
// Allow user to select from available models
final selected = await showModelSwitchDialog(
  context,
  availableModels: [
    {
      'id': 'eu.amazon.nova-lite-v1:0',
      'name': 'Amazon Nova Lite',
      'provider': 'amazon',
      'useCase': 'health',
    },
    {
      'id': 'anthropic.claude-3-5-sonnet-20241022-v2:0',
      'name': 'Claude 3.5 Sonnet',
      'provider': 'anthropic',
      'useCase': 'clinical',
    },
  ],
  currentModelId: currentModelId,
  currentModelName: "Nova Pro",
);

if (selected != null) {
  // Call orchestrate API to switch
}
```

#### 3. Confirmation Dialog
```dart
// Confirm before switching
final confirmed = await showModelSwitchConfirmation(
  context,
  fromModel: 'Claude 3.5 Sonnet',
  toModel: 'Amazon Nova Lite',
  reason: 'Cost optimization',
);

if (confirmed) {
  // Proceed with switch
}
```

### 5. Database Schema

#### bedrock_model_switches Table
Tracks all model switching events for analytics and optimization:

```sql
CREATE TABLE bedrock_model_switches (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  conversation_id UUID NOT NULL,
  previous_model_id TEXT NOT NULL,
  new_model_id TEXT NOT NULL,
  switch_action TEXT ('manual_switch', 'auto_switch', 'fallback_switch'),
  reason TEXT,
  notification_shown BOOLEAN,
  notification_title TEXT,
  notification_message TEXT,
  switch_type TEXT ('auto', 'manual'),
  timestamp TIMESTAMP,
  cost_impact_estimated DECIMAL(10, 6),
  created_at TIMESTAMP
);

-- Indexes for common queries
CREATE INDEX idx_bedrock_switches_user_id ON bedrock_model_switches(user_id);
CREATE INDEX idx_bedrock_switches_conversation_id ON bedrock_model_switches(conversation_id);
CREATE INDEX idx_bedrock_switches_new_model_id ON bedrock_model_switches(new_model_id);
CREATE INDEX idx_bedrock_switches_timestamp ON bedrock_model_switches(timestamp DESC);
```

#### Views for Analytics

**bedrock_model_switch_analytics**
- Groups switches by model and hour
- Shows auto vs manual switching trends
- Provides switch reasons

**user_model_preferences**
- Shows preferred models by user
- Tracks auto-adoption percentage
- Useful for optimization

## Setup Instructions

### 1. Deploy IAM Policy

```bash
# Update jump server (Lambda) with full Bedrock access
cd aws-deployment
./setup-bedrock-permissions.sh

# Verify the policy was applied
aws iam get-role-policy --role-name medzen-bedrock-lambda \
  --policy-name bedrock-models-access
```

### 2. Deploy Edge Function

```bash
# Deploy the orchestrate function
npx supabase functions deploy orchestrate-bedrock-models

# Verify deployment
npx supabase functions logs orchestrate-bedrock-models --tail
```

### 3. Apply Database Migration

```bash
# Run migration to create tracking tables
npx supabase migration up

# Verify tables were created
npx supabase db pull
```

### 4. Test the System

```bash
# Set environment variable
export SUPABASE_SERVICE_KEY=<your-service-key>

# Test list command
./scripts/orchestrate-bedrock.sh list

# Test validation
./scripts/orchestrate-bedrock.sh validate eu.amazon.nova-pro-v1:0

# Test auto-switch
./scripts/orchestrate-bedrock.sh auto-switch clinical
```

## Usage Workflows

### Workflow 1: Manual Model Switching

**Scenario:** You want to switch to a cheaper model to reduce costs.

```bash
# 1. List available models
./orchestrate-bedrock.sh list

# 2. Pick a cheaper model (e.g., Nova Lite)
# 3. Validate it works
./orchestrate-bedrock.sh validate eu.amazon.nova-lite-v1:0

# 4. Switch to it
./orchestrate-bedrock.sh switch eu.amazon.nova-lite-v1:0 "Cost reduction"

# 5. User sees notification in app:
#    ✅ Switching AI Model
#    Using: Amazon Nova Lite
```

### Workflow 2: Auto-Switching by Use Case

**Scenario:** Patient starts using medical assistant (clinical use case).

```
1. User opens clinical chat
2. bedrock-ai-chat edge function detects use case = 'clinical'
3. Calls orchestrate-bedrock-models with action: 'auto-switch'
4. Function switches to optimal clinical model (Claude 3.5 Sonnet)
5. Shows green notification: "Auto-Switching AI Model"
6. User starts chatting with upgraded model
7. Switch event logged for analytics
```

### Workflow 3: Cost Optimization

**Scenario:** Monitor costs and auto-switch cheaper models when appropriate.

```bash
# 1. Check models for use case
./orchestrate-bedrock.sh use-case health

# 2. Auto-switch to cheaper option
./orchestrate-bedrock.sh auto-switch health

# 3. Monitor switching analytics
SELECT
  new_model_id,
  COUNT(*) as switches,
  switch_type
FROM bedrock_model_switches
WHERE DATE(timestamp) = CURRENT_DATE
GROUP BY new_model_id, switch_type
ORDER BY switches DESC;
```

### Workflow 4: Fallback Handling

**Scenario:** Primary model fails, auto-switch to fallback.

```typescript
// In Lambda handler or edge function
try {
  const response = await invokeBedrock(primaryModel);
} catch (err) {
  if (err.statusCode === 429) { // Rate limit
    // Auto-switch to fallback model
    await orchestrateModelSwitch({
      action: 'fallback-switch',
      reason: 'Rate limit exceeded on primary model',
    });
  }
}
```

## Monitoring and Analytics

### View Switching Events

```sql
-- Recent model switches
SELECT
  user_id,
  new_model_id,
  switch_type,
  reason,
  timestamp
FROM bedrock_model_switches
ORDER BY timestamp DESC
LIMIT 20;

-- Switches by model (last 7 days)
SELECT
  new_model_id,
  COUNT(*) as total_switches,
  COUNT(*) FILTER (WHERE switch_type = 'auto') as auto_switches,
  COUNT(*) FILTER (WHERE switch_type = 'manual') as manual_switches
FROM bedrock_model_switches
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY new_model_id
ORDER BY total_switches DESC;
```

### Cost Analysis

```sql
-- Estimated cost impact of switching
SELECT
  user_id,
  previous_model_id,
  new_model_id,
  COUNT(*) as switches,
  SUM(COALESCE(cost_impact_estimated, 0)) as total_estimated_savings
FROM bedrock_model_switches
WHERE timestamp > NOW() - INTERVAL '30 days'
GROUP BY user_id, previous_model_id, new_model_id
ORDER BY total_estimated_savings DESC;
```

### User Preference Tracking

```sql
-- View of user model preferences (last 30 days)
SELECT * FROM user_model_preferences
ORDER BY selection_count DESC;

-- Top adopted models
SELECT
  preferred_model_id,
  COUNT(DISTINCT user_id) as users,
  AVG(auto_adoption_percentage) as avg_auto_adoption
FROM user_model_preferences
GROUP BY preferred_model_id
ORDER BY users DESC;
```

## Troubleshooting

### Issue: Model switching fails with "Model not found"

**Solution:**
1. Verify model exists in bedrock_models table
2. Check is_available flag is TRUE
3. Clear cache: `./orchestrate-bedrock.sh clear-cache`
4. Update database: `npx supabase db pull`

### Issue: Notifications don't appear in app

**Solution:**
1. Ensure `show_model_switch_notification` is imported
2. Verify BuildContext is available
3. Check ScaffoldMessenger is in widget tree
4. Test with manual API call

### Issue: Lambda says "not authorized to Bedrock"

**Solution:**
1. Verify IAM policy was applied: `aws iam get-role-policy ...`
2. Attach policy if missing: `./aws-deployment/setup-bedrock-permissions.sh`
3. Wait 5 minutes for AWS to propagate
4. Test with: `aws bedrock list-foundation-models --region eu-central-1`

### Issue: Edge function returns 401

**Solution:**
1. Check SUPABASE_SERVICE_KEY is set
2. Verify Authorization header in request
3. Test with: `export SUPABASE_SERVICE_KEY=<key>` first
4. Check function logs: `npx supabase functions logs orchestrate-bedrock-models --tail`

## Best Practices

### 1. Always Validate Before Switching
```bash
./orchestrate-bedrock.sh validate <model-id>
```

### 2. Use Reasons for Audit Trail
```bash
./orchestrate-bedrock.sh switch <model> "reason for switch"
```

### 3. Monitor Cost Impact
- Track switches in bedrock_model_switches
- Compare costs in bedrock_models table
- Use analytics views to identify patterns

### 4. Test in Staging First
```bash
# Test with staging environment
export SUPABASE_SERVICE_KEY=$STAGING_KEY
./orchestrate-bedrock.sh list
```

### 5. Auto-Switch Gradually
- Start with auto-switch for non-critical use cases
- Monitor user feedback and performance
- Expand to critical use cases after validation

### 6. Cache Management
- Cache TTL is 1 hour (bedrock-models.ts)
- Clear cache after model configuration changes
- Clear cache before major deployments

## Configuration Files

| File | Purpose | Access |
|------|---------|--------|
| `aws-deployment/iam-policies/bedrock-models-access.json` | IAM policy for Lambda | Read/Write |
| `supabase/functions/orchestrate-bedrock-models/index.ts` | Orchestration API | Deploy |
| `scripts/orchestrate-bedrock.sh` | CLI tool | Execute |
| `lib/custom_code/actions/show_model_switch_notification.dart` | UI notifications | Use in widgets |
| `supabase/migrations/20260115160000_...` | Database schema | Run migration |

## API Reference

### Orchestrate Bedrock Models Endpoint

**Base URL:** `https://noaeltglphdlkbflipit.supabase.co/functions/v1/orchestrate-bedrock-models`

**Authentication:** Bearer token (SUPABASE_SERVICE_KEY)

**All Actions:**

| Action | Required Params | Response | Purpose |
|--------|-----------------|----------|---------|
| `list-all` | none | List of all models | Get available models |
| `get-for-use-case` | useCase | Filtered models | Models for specific use |
| `validate` | modelId | Validation result | Check if model exists |
| `switch` | modelId | Switch result + notification | Manually change model |
| `auto-switch` | useCase | Switch result + notification | Auto-optimize model |
| `clear-cache` | none | Confirmation | Refresh model cache |

## Support

For issues or questions:
1. Check the Troubleshooting section
2. Review function logs: `npx supabase functions logs orchestrate-bedrock-models --tail`
3. Check database: `SELECT * FROM bedrock_models WHERE is_available = true;`
4. Test manually: `./orchestrate-bedrock.sh list`

## Version History

**v1.0 (Jan 15, 2026)**
- Initial release
- Full Bedrock model access in eu-central-1
- Manual and auto-switching capabilities
- Model switching notifications
- Analytics and audit logging
