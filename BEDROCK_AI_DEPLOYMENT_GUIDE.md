# Bedrock AI Deployment Guide

Complete guide for deploying the MedZen Bedrock AI chat system with multi-region failover and medical entity extraction.

## Architecture Overview

```
┌─────────────────┐
│   Flutter App   │
│  (Patient Chat) │
└────────┬────────┘
         │
         ├─→ send_bedrock_message.dart
         │
         ↓
┌─────────────────────────┐
│  Supabase Edge Function │
│   bedrock-ai-chat       │
│  • Auth verification    │
│  • Message storage      │
│  • Usage tracking       │
└────────┬────────────────┘
         │
         ↓
┌─────────────────────────┐
│     AWS Lambda          │
│ medzen-ai-chat-handler  │
│  • Multi-region failover│
│  • Language detection   │
│  • Medical entities     │
└────────┬────────────────┘
         │
         ↓
┌─────────────────────────┐
│    AWS Bedrock          │
│  Claude 3 Sonnet        │
│  + Comprehend Medical   │
│  + Translate            │
└─────────────────────────┘
```

## Prerequisites

### Required Software
- AWS CLI (`aws --version`) - v2.x or higher
- Supabase CLI (`supabase --version`) - v1.x or higher
- Node.js 18+ (`node --version`)
- Git

### Required Credentials
1. **AWS Account** with:
   - Bedrock model access enabled (Claude 3 Sonnet)
   - IAM permissions for CloudFormation, Lambda, API Gateway
   - Region: eu-west-1 (primary)

2. **Supabase Project**:
   - Project ID: `noaeltglphdlkbflipit`
   - Service Role Key (from Supabase dashboard)

### AWS Bedrock Model Access

Before deployment, request access to Claude 3 Sonnet in AWS Bedrock:

```bash
# Check if you have access
aws bedrock list-foundation-models --region eu-west-1 \
  --query "modelSummaries[?contains(modelId, 'claude-3-sonnet')]"

# If empty, request access via AWS Console:
# 1. Navigate to AWS Bedrock → Model access
# 2. Request access to "Claude 3 Sonnet"
# 3. Wait for approval (usually 5-10 minutes)
```

## Step-by-Step Deployment

### 1. Configure AWS Credentials

```bash
# Set AWS credentials
aws configure

# Verify access
aws sts get-caller-identity
```

### 2. Set Environment Variables

```bash
# Get Supabase service key from: https://app.supabase.com/project/noaeltglphdlkbflipit/settings/api
export SUPABASE_SERVICE_KEY="your-service-role-key-here"

# Optional: Override defaults
export PROJECT_NAME="medzen"
export ENVIRONMENT="production"
export AWS_REGION="eu-west-1"
```

### 3. Deploy CloudFormation Stack

```bash
cd aws-deployment/scripts
./deploy-bedrock-ai.sh
```

The script will:
1. ✅ Verify prerequisites (AWS CLI, Supabase CLI, credentials)
2. ✅ Deploy CloudFormation stack (Lambda, API Gateway, IAM roles)
3. ✅ Retrieve Lambda URL from stack outputs
4. ✅ Configure Supabase secrets
5. ✅ Deploy Supabase Edge Function
6. ✅ Run verification tests

**Expected Duration:** 5-10 minutes

### 4. Verify Deployment

```bash
# Check CloudFormation stack status
aws cloudformation describe-stacks \
  --stack-name medzen-bedrock-ai-eu-west-1 \
  --region eu-west-1 \
  --query 'Stacks[0].StackStatus'

# Test Lambda function directly
LAMBDA_URL=$(aws cloudformation describe-stacks \
  --stack-name medzen-bedrock-ai-eu-west-1 \
  --region eu-west-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`LambdaFunctionUrl`].OutputValue' \
  --output text)

curl -X POST "$LAMBDA_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What are symptoms of diabetes?",
    "conversationId": "test-conv-id",
    "userId": "test-user-id"
  }'

# Expected response:
# {
#   "message": "Symptoms of diabetes include...",
#   "language": "en",
#   "region": "primary",
#   "entities": [...]
# }
```

### 5. Test Edge Function

```bash
# View Edge Function logs
npx supabase functions logs bedrock-ai-chat --tail --project-ref noaeltglphdlkbflipit

# Manual test (requires valid user token)
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat" \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello, how can I stay healthy?",
    "conversationId": "your-conversation-id",
    "userId": "your-user-id",
    "preferredLanguage": "en"
  }'
```

### 6. Test from Flutter App

```dart
import 'package:medzen_iwani/custom_code/actions/send_bedrock_message.dart';
import 'package:medzen_iwani/custom_code/actions/create_bedrock_conversation.dart';

// Test in Flutter
Future<void> testBedrockAI() async {
  // 1. Create conversation
  final conversationId = await createBedrockConversation(
    FFAppState().UserID,
    "Health Questions",
  );

  print("Conversation created: $conversationId");

  // 2. Send test message
  final result = await sendBedrockMessage(
    conversationId!,
    FFAppState().UserID,
    "What are the benefits of exercise?",
    null, // No conversation history
    "en", // English
  );

  // 3. Check response
  if (result['success'] == true) {
    print("✅ AI Response: ${result['response']}");
    print("Language: ${result['languageName']}");
    print("Tokens: ${result['totalTokens']}");
  } else {
    print("❌ Error: ${result['error']}");
  }
}
```

## Configuration

### Environment Variables (Lambda)

Set via CloudFormation parameters:

```yaml
BEDROCK_MODEL_ID: anthropic.claude-3-sonnet-20240229-v1:0
BEDROCK_REGION: eu-west-1
FAILOVER_REGION_1: us-east-1
FAILOVER_REGION_2: af-south-1
SUPABASE_URL: https://noaeltglphdlkbflipit.supabase.co
SUPABASE_SERVICE_KEY: (encrypted)
```

### Supabase Secrets

```bash
# Set Lambda URL for Edge Function
npx supabase secrets set BEDROCK_LAMBDA_URL="https://xxx.lambda-url.eu-west-1.on.aws" \
  --project-ref noaeltglphdlkbflipit

# View all secrets
npx supabase secrets list --project-ref noaeltglphdlkbflipit
```

### Database Tables

Ensure these tables exist (already in migrations):

```sql
-- Conversations
CREATE TABLE ai_conversations (
  id UUID PRIMARY KEY,
  patient_id UUID REFERENCES users(id),
  assistant_id UUID REFERENCES ai_assistants(id),
  title TEXT,
  status TEXT DEFAULT 'active',
  default_language TEXT DEFAULT 'en',
  total_tokens INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages
CREATE TABLE ai_messages (
  id UUID PRIMARY KEY,
  conversation_id UUID REFERENCES ai_conversations(id),
  role TEXT NOT NULL, -- 'user' or 'assistant'
  content TEXT NOT NULL,
  language_code TEXT,
  model_used TEXT,
  input_tokens INTEGER,
  output_tokens INTEGER,
  total_tokens INTEGER,
  response_time_ms INTEGER,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Monitoring

### CloudWatch Dashboards

```bash
# View Lambda logs
aws logs tail /aws/lambda/medzen-ai-chat-handler \
  --region eu-west-1 \
  --follow

# Check error rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=medzen-ai-chat-handler \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region eu-west-1

# Check duration
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=medzen-ai-chat-handler \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum \
  --region eu-west-1
```

### CloudWatch Alarms (Auto-created)

- `medzen-ai-lambda-errors` - Lambda error count > 5 in 10 minutes
- `medzen-ai-lambda-duration` - Average duration > 30 seconds
- `medzen-ai-lambda-throttles` - Any throttling detected

### Database Analytics

```sql
-- Message volume by language
SELECT
  language_code,
  COUNT(*) as message_count,
  AVG(total_tokens) as avg_tokens,
  AVG(response_time_ms) as avg_response_time_ms
FROM ai_messages
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY language_code
ORDER BY message_count DESC;

-- Conversation metrics
SELECT
  DATE_TRUNC('hour', created_at) as hour,
  COUNT(*) as conversations,
  AVG(total_tokens) as avg_tokens
FROM ai_conversations
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY hour
ORDER BY hour DESC;

-- Most active users
SELECT
  patient_id,
  COUNT(DISTINCT ac.id) as conversations,
  COUNT(am.id) as messages,
  SUM(ac.total_tokens) as total_tokens
FROM ai_conversations ac
LEFT JOIN ai_messages am ON ac.id = am.conversation_id
WHERE ac.created_at > NOW() - INTERVAL '30 days'
GROUP BY patient_id
ORDER BY messages DESC
LIMIT 10;
```

## Troubleshooting

### Issue: Lambda returns "Model access denied"

**Cause:** Bedrock model access not enabled

**Fix:**
```bash
# 1. Check model access
aws bedrock get-foundation-model \
  --model-identifier anthropic.claude-3-sonnet-20240229-v1:0 \
  --region eu-west-1

# 2. If error, request access via AWS Console:
#    Bedrock → Model access → Request access to Claude 3 Sonnet

# 3. Wait 5-10 minutes for approval

# 4. Test again
```

### Issue: Edge Function returns "Bedrock Lambda endpoint not configured"

**Cause:** `BEDROCK_LAMBDA_URL` secret not set

**Fix:**
```bash
# Get Lambda URL
LAMBDA_URL=$(aws cloudformation describe-stacks \
  --stack-name medzen-bedrock-ai-eu-west-1 \
  --region eu-west-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`LambdaFunctionUrl`].OutputValue' \
  --output text)

# Set secret
npx supabase secrets set BEDROCK_LAMBDA_URL="$LAMBDA_URL" \
  --project-ref noaeltglphdlkbflipit

# Redeploy Edge Function
npx supabase functions deploy bedrock-ai-chat \
  --project-ref noaeltglphdlkbflipit
```

### Issue: "Not authorized for this conversation"

**Cause:** User ID mismatch or invalid conversation

**Fix:**
```sql
-- Check conversation ownership
SELECT id, patient_id, status
FROM ai_conversations
WHERE id = 'your-conversation-id';

-- Ensure patient_id matches current user
```

### Issue: High latency (>5 seconds)

**Possible causes:**
1. Cold start - Lambda not warmed up
2. Bedrock region failover
3. Large conversation history

**Fix:**
```bash
# Check which region is being used
aws logs filter-log-events \
  --log-group-name /aws/lambda/medzen-ai-chat-handler \
  --filter-pattern "region" \
  --region eu-west-1 \
  --max-items 10

# Warm up Lambda
for i in {1..5}; do
  curl -X POST "$LAMBDA_URL" \
    -H "Content-Type: application/json" \
    -d '{"message":"ping","conversationId":"test","userId":"test"}' &
done
```

### Issue: Language detection incorrect

**Cause:** Insufficient language-specific keywords

**Fix:**
Update language patterns in Lambda code (`bedrock-ai-multi-region.yaml`):

```javascript
const languagePatterns = {
  sw: ['habari', 'jambo', 'asante', 'daktari', 'mgonjwa'],
  // Add more patterns...
};
```

## Cost Optimization

### AWS Bedrock Pricing (eu-west-1)

- Claude 3 Sonnet: $0.003 per 1K input tokens, $0.015 per 1K output tokens
- Comprehend Medical: $0.01 per request (entity detection)
- Lambda: $0.20 per 1M requests + $0.0000166667 per GB-second
- S3: $0.023 per GB/month

### Estimated Monthly Costs

**Assumptions:**
- 10,000 conversations/month
- Average 10 messages per conversation (100,000 messages)
- Average 500 tokens per request (250 input + 250 output)

**Breakdown:**
- Bedrock: 100,000 × (250 × $0.003 + 250 × $0.015) / 1000 = **$450**
- Comprehend: 100,000 × $0.01 = **$1,000** (optional, can disable)
- Lambda: 100,000 × $0.20 / 1M + compute = **$20**
- S3: ~1 GB = **$1**
- API Gateway: 100,000 × $1 / 1M = **$0.10**

**Total: ~$471/month** (or ~$71 without Comprehend Medical)

### Cost Reduction Tips

1. **Disable Comprehend Medical** for non-critical conversations
2. **Implement caching** for common questions
3. **Use smaller model** for simple queries (Claude 3 Haiku)
4. **Set token limits** in prompts
5. **Archive old conversations** to cheaper S3 storage

```javascript
// In Lambda code, add:
const useComprehend = message.includes('symptom') || message.includes('diagnosis');
if (useComprehend) {
  // Only call Comprehend for medical queries
}
```

## Multi-Region Deployment

Deploy to additional regions for redundancy:

```bash
# Deploy to us-east-1
export AWS_REGION=us-east-1
./deploy-bedrock-ai.sh

# Deploy to af-south-1 (if Bedrock available)
export AWS_REGION=af-south-1
./deploy-bedrock-ai.sh
```

**Note:** Lambda function already has built-in failover logic. Multi-region deployment is optional.

## Rollback

```bash
# Delete CloudFormation stack
aws cloudformation delete-stack \
  --stack-name medzen-bedrock-ai-eu-west-1 \
  --region eu-west-1

# Remove Edge Function
npx supabase functions delete bedrock-ai-chat \
  --project-ref noaeltglphdlkbflipit

# Remove secret
npx supabase secrets unset BEDROCK_LAMBDA_URL \
  --project-ref noaeltglphdlkbflipit
```

## Support

- **AWS Bedrock Issues:** Check [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- **Supabase Edge Functions:** Check [Supabase Functions Docs](https://supabase.com/docs/guides/functions)
- **CloudFormation Issues:** Review stack events in AWS Console

## Next Steps

1. ✅ Deploy infrastructure
2. ✅ Test with sample messages
3. ✅ Integrate into Flutter UI
4. 🔄 Monitor usage and costs
5. 🔄 Optimize prompts for better responses
6. 🔄 Add conversation summarization
7. 🔄 Implement feedback loop for model improvement
