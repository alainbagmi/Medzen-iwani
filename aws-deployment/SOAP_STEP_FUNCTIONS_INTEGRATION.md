# MedZen SOAP Note Generation - AWS Step Functions Integration Guide

## Overview

This guide explains how to deploy and integrate the AWS Step Functions workflow for automated SOAP note generation from medical call transcripts. The workflow orchestrates transcription retrieval, metadata enrichment, Claude Opus 4.5-based SOAP generation, and database synchronization.

**Updated:** January 2026 - Now using Claude Opus 4.5 (claude-opus-4-5-20251101-v1) deployed in us-east-1 region.

## Architecture

```
Video Call Ends
    ↓
finalize-video-call (Supabase Edge Function)
    ↓
Start Step Functions Execution
    ↓
[17-State Workflow]
    ├─ Validate Input (DynamoDB)
    ├─ Fetch Transcript (Lambda: fetch-transcript)
    ├─ Enrich Metadata (Lambda: enrich-metadata)
    ├─ Call Bedrock (Direct API: Claude 3 Opus)
    ├─ Parse Response (Lambda: parse-bedrock-response)
    ├─ Save to DynamoDB (Direct API)
    ├─ Update Supabase (Lambda: update-supabase-soap)
    ├─ Update Session Status (DynamoDB)
    ├─ Send Notification (Lambda: send-notification)
    └─ Success/Error States
```

## Prerequisites

1. **AWS Account** with permissions to:
   - Create Step Functions state machines
   - Create Lambda functions
   - Create IAM roles
   - Access DynamoDB and SQS
   - Access AWS Bedrock

2. **Claude Opus 4.5 Access** in `us-east-1` region
   - Go to AWS Console → Bedrock → Model Access
   - Request access to `anthropic.claude-opus-4-5-20251101-v1:0`
   - Note: This may take 24-48 hours for approval
   - Verify access in us-east-1 specifically (Claude Opus 4.5 limited availability)

3. **DynamoDB Tables**:
   ```sql
   -- medzen-video-sessions table
   -- PK: sessionId (String)
   -- Attributes: transcriptionEnabled (Boolean), providerId (String), etc.

   -- medzen-soap-notes table
   -- PK: soapNoteId (String)
   -- Attributes: sessionId, appointmentId, status, sections, etc.
   ```

4. **Supabase Environment Variables** (set in `supabase/functions` config):
   ```
   AWS_REGION=us-east-1
   AWS_ACCESS_KEY_ID=<your-AWS-key>
   AWS_SECRET_ACCESS_KEY=<your-AWS-secret>
   DAILY_TRANSCRIPTION_BUDGET_USD=50
   STEP_FUNCTIONS_ROLE_ARN=arn:aws:iam::ACCOUNT_ID:role/medzen-soap-workflow-execution-role
   STEP_FUNCTIONS_STATE_MACHINE_ARN=arn:aws:states:us-east-1:ACCOUNT_ID:stateMachine:medzen-soap-workflow
   ```

5. **SQS Queue** for retry handling:
   ```bash
   aws sqs create-queue \
     --queue-name medzen-soap-retry-queue \
     --region us-east-1 \
     --attributes VisibilityTimeout=300,MessageRetentionPeriod=1209600
   ```

## Step 1: Create IAM Role

### Option A: AWS Console

1. Navigate to IAM → Roles → Create Role
2. Trust entity: "AWS Service" → "Step Functions"
3. Add inline policies from `iam-role-medzen-soap-workflow.json`:
   - BedrockInvokeModel
   - LambdaInvocation
   - DynamoDBSessionState
   - SQSRetryQueue
   - SNSNotifications

### Option B: AWS CLI

```bash
# Create role
aws iam create-role \
  --role-name medzen-soap-workflow-execution-role \
  --assume-role-policy-document file://trust-policy.json \
  --region us-east-1

# Add inline policies
aws iam put-role-policy \
  --role-name medzen-soap-workflow-execution-role \
  --policy-name BedrockInvokeModel \
  --policy-document file://bedrock-policy.json

# Repeat for other policies...
```

### trust-policy.json
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Important**: Replace `ACCOUNT_ID` in policy files with your AWS Account ID (12-digit number).

## Step 2: Create Lambda Functions

All Lambda functions are in `aws-deployment/lambda-functions/`:

### Function 1: medzen-fetch-transcript
- **Runtime**: Python 3.11
- **Handler**: `lambda_function.lambda_handler`
- **Timeout**: 30 seconds
- **Memory**: 256 MB
- **Environment Variables**:
  ```
  SUPABASE_URL=https://[project-id].supabase.co
  SUPABASE_SERVICE_KEY=[service-role-key]
  ```

### Function 2: medzen-enrich-metadata
- **Runtime**: Python 3.11
- **Handler**: `lambda_function.lambda_handler`
- **Timeout**: 30 seconds
- **Memory**: 512 MB
- **Environment Variables**:
  ```
  SUPABASE_URL=https://[project-id].supabase.co
  SUPABASE_SERVICE_KEY=[service-role-key]
  ```

### Function 3: medzen-parse-bedrock-response
- **Runtime**: Python 3.11
- **Handler**: `lambda_function.lambda_handler`
- **Timeout**: 15 seconds
- **Memory**: 256 MB
- **Dependencies**: None (uses built-in json, re modules)

### Function 4: medzen-update-supabase-soap
- **Runtime**: Python 3.11
- **Handler**: `lambda_function.lambda_handler`
- **Timeout**: 30 seconds
- **Memory**: 512 MB
- **Environment Variables**:
  ```
  SUPABASE_URL=https://[project-id].supabase.co
  SUPABASE_SERVICE_KEY=[service-role-key]
  ```

### Function 5: medzen-send-notification
- **Runtime**: Python 3.11
- **Handler**: `lambda_function.lambda_handler`
- **Timeout**: 15 seconds
- **Memory**: 256 MB
- **Environment Variables**:
  ```
  SUPABASE_URL=https://[project-id].supabase.co
  SUPABASE_SERVICE_KEY=[service-role-key]
  FCM_SERVER_KEY=[Firebase-Cloud-Messaging-key]
  ```

### Deploy via AWS CLI

```bash
# Create ZIP archive
cd aws-deployment/lambda-functions
zip medzen-fetch-transcript.zip fetch-transcript.py
zip medzen-enrich-metadata.zip enrich-metadata.py
zip medzen-parse-bedrock-response.zip parse-bedrock-response.py
zip medzen-update-supabase-soap.zip update-supabase-soap.py
zip medzen-send-notification.zip send-notification.py

# Create functions
aws lambda create-function \
  --function-name medzen-fetch-transcript \
  --runtime python3.11 \
  --role arn:aws:iam::ACCOUNT_ID:role/medzen-lambda-execution-role \
  --handler fetch-transcript.lambda_handler \
  --zip-file fileb://medzen-fetch-transcript.zip \
  --timeout 30 \
  --memory-size 256 \
  --region eu-central-1 \
  --environment Variables={SUPABASE_URL=https://[project-id].supabase.co,SUPABASE_SERVICE_KEY=[key]}

# Repeat for other functions...
```

## Step 3: Create Step Functions State Machine

### Via AWS Console

1. Step Functions → State Machines → Create State Machine
2. Choose "Write your own" (not template)
3. Paste contents of `soap-workflow-definition.json`
4. **CRITICAL**: Replace all instances of `ACCOUNT_ID` with your actual AWS Account ID (12 digits)
5. Role: Select `medzen-soap-workflow-execution-role` created in Step 1
6. Name: `medzen-soap-workflow`
7. Create

### Via AWS CLI

```bash
# Replace ACCOUNT_ID first
sed -i 's/ACCOUNT_ID/123456789012/g' soap-workflow-definition.json

# Create state machine
aws stepfunctions create-state-machine \
  --name medzen-soap-workflow \
  --definition file://soap-workflow-definition.json \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/medzen-soap-workflow-execution-role \
  --region us-east-1

# Output will include StateMachineArn - save this for integration
```

## Step 4: Update Supabase Edge Function

Update `supabase/functions/finalize-video-call/index.ts` to invoke the Step Functions workflow:

```typescript
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { StepFunctionsClient, StartExecutionCommand } from "https://esm.sh/@aws-sdk/client-sfn@3";

const supabaseClient = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
);

const stepFunctionsClient = new StepFunctionsClient({
  region: "eu-central-1",
  credentials: {
    accessKeyId: Deno.env.get("AWS_ACCESS_KEY_ID") ?? "",
    secretAccessKey: Deno.env.get("AWS_SECRET_ACCESS_KEY") ?? "",
  },
});

Deno.serve(async (req: Request) => {
  try {
    const { sessionId, appointmentId, providerId, transcriptionEnabled } = await req.json();

    if (!sessionId || !appointmentId) {
      throw new Error("sessionId and appointmentId are required");
    }

    // If transcription not enabled, skip SOAP generation
    if (!transcriptionEnabled) {
      return new Response(
        JSON.stringify({
          statusCode: 200,
          message: "Transcription not enabled for this session",
          sessionId,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // Prepare Step Functions input
    const workflowInput = {
      sessionId,
      appointmentId,
      providerId,
      transcriptionEnabled: true,
      sourceSystem: "supabase-edge-function",
    };

    // Start Step Functions execution
    const command = new StartExecutionCommand({
      stateMachineArn: Deno.env.get("STEP_FUNCTIONS_STATE_MACHINE_ARN"),
      name: `soap-${sessionId}-${Date.now()}`,
      input: JSON.stringify(workflowInput),
    });

    const result = await stepFunctionsClient.send(command);

    console.log(`[Finalize] Started SOAP workflow execution: ${result.executionArn}`);

    // Return immediately (async workflow)
    return new Response(
      JSON.stringify({
        statusCode: 200,
        message: "SOAP generation workflow started",
        sessionId,
        executionArn: result.executionArn,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[Finalize] Error:", error.message);
    return new Response(
      JSON.stringify({
        statusCode: 500,
        error: "FinalizeFailed",
        message: error.message,
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
```

**Deploy updated function**:
```bash
npx supabase functions deploy finalize-video-call
```

## Step 5: Configuration Checklist

- [ ] AWS Account ID obtained (12-digit number)
- [ ] Claude Opus 4.5 access requested in Bedrock (`us-east-1`)
- [ ] DynamoDB tables created in `us-east-1` (`medzen-video-sessions`, `medzen-soap-notes`)
- [ ] SQS queue created in `us-east-1` (`medzen-soap-retry-queue`)
- [ ] IAM role created with all policies (includes Claude Opus 4.5 model ARN)
- [ ] All 5 Lambda functions created and deployed in `us-east-1`
- [ ] Step Functions state machine created in `us-east-1` (ACCOUNT_ID replaced)
- [ ] Supabase environment variables set:
  - AWS_REGION=us-east-1
  - AWS_ACCESS_KEY_ID=your-key
  - AWS_SECRET_ACCESS_KEY=your-secret
  - STEP_FUNCTIONS_STATE_MACHINE_ARN=arn:aws:states:us-east-1:ACCOUNT_ID:stateMachine:medzen-soap-workflow
- [ ] finalize-video-call edge function updated and deployed
- [ ] Supabase service key configured in Lambda environment variables
- [ ] Firebase Cloud Messaging (FCM) server key set for notifications
- [ ] Verify Claude Opus 4.5 model availability in us-east-1 Bedrock

## Testing the Workflow

### Manual Test via AWS CLI

```bash
# Start execution
aws stepfunctions start-execution \
  --state-machine-arn arn:aws:states:us-east-1:ACCOUNT_ID:stateMachine:medzen-soap-workflow \
  --name test-soap-execution \
  --input '{"sessionId":"test-session-123","appointmentId":"apt-456","providerId":"prov-789","transcriptionEnabled":true}' \
  --region us-east-1

# Monitor execution (replace executionArn from output above)
aws stepfunctions describe-execution \
  --execution-arn arn:aws:states:us-east-1:ACCOUNT_ID:execution:medzen-soap-workflow:test-soap-execution \
  --region us-east-1

# Get execution history
aws stepfunctions get-execution-history \
  --execution-arn arn:aws:states:us-east-1:ACCOUNT_ID:execution:medzen-soap-workflow:test-soap-execution \
  --region us-east-1
```

### End-to-End Test via Flutter

1. Create a test video call appointment in Supabase
2. End the call (triggers finalize-video-call edge function)
3. Check Step Functions execution in AWS Console
4. Verify SOAP note created in `soap_notes` table
5. Check provider received notification

### Debugging

**Check CloudWatch Logs**:
```bash
# View Step Functions logs
aws logs tail /aws/states/medzen-soap-workflow --follow --region us-east-1

# View specific Lambda logs
aws logs tail /aws/lambda/medzen-fetch-transcript --follow --region us-east-1
```

**Common Issues**:

| Issue | Cause | Solution |
|-------|-------|----------|
| "BedrockUnavailable" state reached | Claude Opus 4.5 not approved in us-east-1 | Request model access in Bedrock console for us-east-1 specifically |
| Lambda timeout | External API (Supabase) slow | Increase timeout, check network connectivity |
| "No transcript found" | Transcription not complete | Ensure transcription finished before starting workflow |
| "DynamoDB item not found" | Session not in DynamoDB | Verify video_call_sessions table has sessionId |
| SOAP never reaches Supabase | Lambda authentication failed | Verify SUPABASE_SERVICE_KEY is correct |
| No notification sent | FCM token missing or invalid | Check user has valid FCM token in database |
| Wrong region error in Step Functions | AWS_REGION env var mismatch | Verify AWS_REGION=us-east-1 in Supabase secrets |

## Monitoring & Observability

### CloudWatch Dashboard

Create a dashboard to monitor workflow health:

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name medzen-soap-failures \
  --alarm-description "Alert on SOAP workflow failures" \
  --metric-name ExecutionsFailed \
  --namespace AWS/States \
  --statistic Sum \
  --period 300 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --region us-east-1
```

### Key Metrics to Monitor

- ExecutionsStarted
- ExecutionsSucceeded
- ExecutionsFailed
- ExecutionTime (average)
- Lambda invocation duration
- Lambda error rate
- Bedrock throttling errors
- SQS queue depth (retry queue)

## Performance Characteristics

- **Average Workflow Duration**: 45-120 seconds
- **Bottleneck**: Bedrock invocation (30-90 seconds depending on transcript length)
- **Cost per SOAP Note**: ~$0.02-0.10 (depends on transcript length and token usage)
- **Cost per 1000 SOAPs**: ~$20-100 (Claude 3 Opus input/output tokens)
- **Concurrent Executions**: Bedrock limits may throttle at high volume

## Rollback Procedure

If issues occur:

1. **Disable workflow**: Update `finalize-video-call` to skip Step Functions invocation
2. **Keep DynamoDB records**: Don't delete data, just stop new executions
3. **Drain SQS queue**: Check for jobs awaiting retry
4. **Restore from backup**: DynamoDB point-in-time recovery if needed
5. **Revert Lambda code**: Push previous version via AWS Lambda console

## Next Steps

1. Deploy all components using checklist above
2. Run end-to-end test with real video call
3. Monitor CloudWatch for 24 hours
4. Adjust Lambda timeouts/memory based on actual performance
5. Set up SNS/email alerts for workflow failures
6. Document any customizations made during deployment

## Support & Troubleshooting

For issues:
1. Check CloudWatch Logs (most detailed debugging info)
2. Verify all environment variables are set correctly
3. Test individual Lambda functions independently via Lambda console
4. Check Bedrock model access status in AWS console
5. Ensure Supabase network connectivity from Lambda VPC (if using VPC)
