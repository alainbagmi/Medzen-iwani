# Bedrock Model Orchestration - Quick Start Guide

## TL;DR

The system lets you **switch AI models instantly** without redeploying code.

### For DevOps/Admins

```bash
# Install
export SUPABASE_SERVICE_KEY=<your-key>
chmod +x scripts/orchestrate-bedrock.sh

# Switch model manually
./scripts/orchestrate-bedrock.sh switch eu.amazon.nova-lite-v1:0 "Cost optimization"

# Auto-switch to optimal model
./scripts/orchestrate-bedrock.sh auto-switch clinical

# List all models
./scripts/orchestrate-bedrock.sh list
```

### For Flutter Developers

```dart
// Show notification when model switches
import 'package:your_app/custom_code/actions/show_model_switch_notification.dart';

await showModelSwitchNotification(
  context,
  modelName: "Claude 3.5 Sonnet",
  modelId: "anthropic.claude-3-5-sonnet-20241022-v2:0",
  type: 'auto',
  title: "Auto-Switching AI Model",
  message: "Upgraded to better model for clinical analysis",
);
```

### For Backend/Edge Functions

```typescript
// Auto-switch when detecting use case
const response = await fetch(
  `${supabaseUrl}/functions/v1/orchestrate-bedrock-models`,
  {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${supabaseServiceKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      action: 'auto-switch',
      useCase: 'clinical',
      conversationId: conv.id,
      userId: user.id,
      showNotification: true,
    }),
  }
);

const result = await response.json();
console.log(`Switched to: ${result.notification.modelName}`);
```

---

## 5-Minute Setup

### Step 1: Deploy IAM Policy (Once)
```bash
cd aws-deployment
./setup-bedrock-permissions.sh
```
This grants Lambda access to **ALL Bedrock models** in eu-central-1.

### Step 2: Deploy Edge Function (Once)
```bash
npx supabase functions deploy orchestrate-bedrock-models
```

### Step 3: Run Migration (Once)
```bash
npx supabase migration up
```
Creates tables for tracking model switches.

### Step 4: Test
```bash
export SUPABASE_SERVICE_KEY=your-service-key
./scripts/orchestrate-bedrock.sh list
```

---

## Common Use Cases

### Use Case 1: Cost Optimization

**Goal:** Reduce costs by switching to cheaper models

```bash
# Check current costs
./scripts/orchestrate-bedrock.sh list

# Switch to Nova Lite (cheaper)
./scripts/orchestrate-bedrock.sh switch \
  eu.amazon.nova-lite-v1:0 \
  "Cost optimization"
```

**Cost Difference (approximate):**
- Claude 3.5 Sonnet: $3/$15 per MTok
- Nova Pro: $0.30/$1.20 per MTok
- Nova Lite: $0.06/$0.24 per MTok

### Use Case 2: Quality Improvement

**Goal:** Improve response quality for specific use cases

```bash
# Auto-switch to best model for clinical use
./scripts/orchestrate-bedrock.sh auto-switch clinical
```

**Models by Use Case:**
| Use Case | Model | Reason |
|----------|-------|--------|
| clinical | Claude 3.5 Sonnet | Medical expertise |
| health | Nova Lite | General wellness |
| operations | Nova Pro | Balanced |
| platform | Nova Pro | System support |

### Use Case 3: Load Balancing

**Goal:** Distribute load across models

```typescript
// In edge function
const availableModels = await getModelsForUseCase('clinical');
const randomModel = availableModels[
  Math.floor(Math.random() * availableModels.length)
];

const result = await orchestrate({
  action: 'switch',
  modelId: randomModel.model_id,
  reason: 'Load balancing',
});
```

### Use Case 4: Emergency Fallback

**Goal:** Switch if primary model fails

```typescript
// In bedrock-ai-chat edge function
let response;
try {
  response = await invokeBedrock(primaryModel);
} catch (err) {
  if (err.statusCode === 429) {
    // Rate limited - switch to fallback
    await orchestrate({
      action: 'auto-switch',
      useCase: conversationUseCase,
      reason: 'Primary model rate-limited',
    });
    response = await invokeBedrock(fallbackModel);
  }
}
```

---

## API Quick Reference

### Manual Switch
```bash
curl -X POST "$SUPABASE_URL/functions/v1/orchestrate-bedrock-models" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "switch",
    "modelId": "eu.amazon.nova-lite-v1:0",
    "reason": "Cost optimization"
  }'
```

### Auto-Switch
```bash
curl -X POST "$SUPABASE_URL/functions/v1/orchestrate-bedrock-models" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "auto-switch",
    "useCase": "clinical"
  }'
```

### List Models
```bash
curl -X POST "$SUPABASE_URL/functions/v1/orchestrate-bedrock-models" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"action":"list-all"}'
```

---

## Flutter UI Integration

### Show Auto-Switch Notification

```dart
// When orchestrate API detects use case change
if (useCase != previousUseCase) {
  final response = await orchestrateModelSwitch(useCase);

  if (response.notification != null) {
    await showModelSwitchNotification(
      context,
      modelName: response.notification.modelName,
      modelId: response.notification.modelId,
      type: response.notification.type, // 'auto' or 'manual'
      title: response.notification.title,
      message: response.notification.message,
    );
  }
}
```

### Show Model Picker Dialog

```dart
final models = await getAvailableModels();

final selected = await showModelSwitchDialog(
  context,
  availableModels: models,
  currentModelId: currentModel.id,
  currentModelName: currentModel.name,
);

if (selected != null) {
  await orchestrateModelSwitch(
    action: 'switch',
    modelId: selected,
    showNotification: true,
  );
}
```

---

## Monitoring

### Recent Switches
```sql
SELECT user_id, previous_model_id, new_model_id, reason, timestamp
FROM bedrock_model_switches
ORDER BY timestamp DESC
LIMIT 20;
```

### Auto-Adoption Rate
```sql
SELECT
  new_model_id,
  COUNT(*) FILTER (WHERE switch_type = 'auto')::float / COUNT(*) * 100 as auto_percentage
FROM bedrock_model_switches
GROUP BY new_model_id;
```

### Cost Impact
```sql
SELECT
  new_model_id,
  COUNT(*) as switches,
  SUM(cost_impact_estimated) as total_savings
FROM bedrock_model_switches
WHERE timestamp > NOW() - INTERVAL '7 days'
GROUP BY new_model_id;
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Model not found" | Run `./orchestrate-bedrock.sh list` to see available models |
| 401 Error | Set `export SUPABASE_SERVICE_KEY=<your-key>` |
| Notification doesn't show | Verify `ScaffoldMessenger` in widget tree |
| Slow to switch | Cache is updated every hour, use `clear-cache` to refresh |
| Lambda says "not authorized" | Run `./aws-deployment/setup-bedrock-permissions.sh` |

---

## Files You Need

| File | Purpose |
|------|---------|
| `aws-deployment/iam-policies/bedrock-models-access.json` | Permissions policy |
| `supabase/functions/orchestrate-bedrock-models/index.ts` | Switching engine |
| `scripts/orchestrate-bedrock.sh` | CLI tool |
| `lib/custom_code/actions/show_model_switch_notification.dart` | UI notifications |
| `BEDROCK_MODEL_ORCHESTRATION.md` | Full documentation |

---

## Next Steps

1. **Deploy:** `npx supabase functions deploy orchestrate-bedrock-models`
2. **Test:** `./scripts/orchestrate-bedrock.sh list`
3. **Integrate:** Import and use in your edge functions
4. **Monitor:** Check `bedrock_model_switches` table for events

---

## Examples Repository

See `BEDROCK_MODEL_ORCHESTRATION.md` for:
- Complete API reference
- Database schema
- Analytics queries
- Best practices
- Advanced workflows

