# MedZen SOAP Workflow Deployment Checklist

**Status:** Ready for Deployment
**Updated:** January 2026
**Region:** us-east-1 (Claude Opus 4.5 availability)
**Model:** Claude Opus 4.5 (`anthropic.claude-opus-4-5-20251101-v1:0`)

---

## Overview

This checklist guides you through deploying the complete SOAP note generation workflow powered by AWS Step Functions and Claude Opus 4.5. The workflow automatically generates clinical SOAP notes from medical transcripts.

### Architecture
```
Video Call Ends
    ↓
finalize-video-call (Supabase Edge Function)
    ↓
Invoke Step Functions Workflow
    ↓
[SOAP Generation Pipeline]
    ├─ Validate Input (DynamoDB)
    ├─ Fetch Transcript (Lambda)
    ├─ Enrich Metadata (Lambda)
    ├─ Generate SOAP (Claude Opus 4.5 via Bedrock)
    ├─ Parse Response (Lambda)
    ├─ Save to Databases (DynamoDB + Supabase)
    ├─ Notify Provider (Lambda)
    └─ Complete
```

---

## Prerequisites

### AWS Account Requirements
- [ ] AWS Account with appropriate permissions
- [ ] AWS CLI configured and authenticated
- [ ] AWS Account ID available (12-digit number)
- [ ] Bedrock access enabled in us-east-1

### Claude Opus 4.5 Model Access
- [ ] Request model access in AWS Bedrock console
  - Navigate to: AWS Console → Bedrock → Model Access
  - Search for: "Claude Opus 4.5" or "claude-opus-4-5-20251101-v1:0"
  - Request access (may take 24-48 hours)
  - **IMPORTANT:** Verify access in **us-east-1 region specifically**

### Local Tools
- [ ] AWS CLI v2 installed (`aws --version`)
- [ ] curl installed (for testing)
- [ ] jq installed (for JSON parsing) - optional but recommended
- [ ] Supabase CLI installed (optional but recommended)

### Repository Setup
- [ ] Current directory: `aws-deployment/`
- [ ] Lambda function files present:
  - [ ] `lambda-functions/fetch-transcript.py`
  - [ ] `lambda-functions/enrich-metadata.py`
  - [ ] `lambda-functions/parse-bedrock-response.py`
  - [ ] `lambda-functions/update-supabase-soap.py`
  - [ ] `lambda-functions/send-notification.py`
- [ ] Step Functions definition: `soap-workflow-definition.json`
- [ ] Deployment scripts:
  - [ ] `08-deploy-soap-workflow.sh`
  - [ ] `test-soap-workflow.sh`

---

## Phase 1: Pre-Deployment Verification

### Step 1: Verify AWS Credentials
```bash
aws sts get-caller-identity --region us-east-1
```
Expected output: AWS Account ID, User ARN, and ARN

- [ ] AWS credentials are valid
- [ ] Output shows correct AWS Account ID

### Step 2: Verify AWS CLI Version
```bash
aws --version
```
Expected: AWS CLI v2.x or later

- [ ] AWS CLI is v2 or later

### Step 3: Verify Bedrock Model Access
```bash
aws bedrock get-foundation-model \
  --model-identifier anthropic.claude-opus-4-5-20251101-v1:0 \
  --region us-east-1
```
Expected: Model information JSON with model details

- [ ] Claude Opus 4.5 model is available in us-east-1
- [ ] Model ARN matches: `anthropic.claude-opus-4-5-20251101-v1:0`

### Step 4: Verify Required Files
```bash
ls -la lambda-functions/*.py
ls -la soap-workflow-definition.json
```

- [ ] All 5 Lambda function Python files exist
- [ ] Step Functions definition JSON exists
- [ ] Deployment scripts exist and are executable

---

## Phase 2: Execute Deployment

### Step 5: Run Deployment Script

**Note:** The deployment script handles all of the following steps automatically. You can either:
1. **Automated (Recommended):** Run the script below
2. **Manual:** Follow the individual steps in this checklist

```bash
cd aws-deployment
./08-deploy-soap-workflow.sh
```

The script will:
- ✓ Validate AWS credentials and CLI
- ✓ Create IAM role with all necessary policies
- ✓ Create/verify DynamoDB tables
- ✓ Create SQS retry queue
- ✓ Deploy 5 Lambda functions
- ✓ Create/update Step Functions state machine
- ✓ Output configuration summary

**Expected Output:**
```
✓ AWS Account: 123456789012
✓ AWS Region: us-east-1
✓ IAM role created: medzen-soap-workflow-execution-role
✓ DynamoDB tables created
✓ SQS queue created
✓ Lambda functions deployed: 5
✓ Step Functions state machine created/updated
✓ Configuration summary printed
```

**Timeline:** 3-5 minutes

- [ ] Deployment script executed successfully
- [ ] No error messages in output
- [ ] State Machine ARN displayed (save this!)

### Step 6: Capture Configuration

After deployment, note these values:

```bash
# From deployment script output:
AWS_ACCOUNT_ID=123456789012
AWS_REGION=us-east-1
STATE_MACHINE_ARN=arn:aws:states:us-east-1:123456789012:stateMachine:medzen-soap-workflow
ROLE_ARN=arn:aws:iam::123456789012:role/medzen-soap-workflow-execution-role
```

- [ ] AWS Account ID noted
- [ ] State Machine ARN noted
- [ ] Role ARN noted

---

## Phase 3: Supabase Configuration

### Step 7: Set Supabase Secrets

Set the following secrets in Supabase:

```bash
# Navigate to project directory
npx supabase link --project-ref noaeltglphdlkbflipit

# Set secrets
npx supabase secrets set AWS_REGION=us-east-1
npx supabase secrets set STEP_FUNCTIONS_STATE_MACHINE_ARN=<STATE_MACHINE_ARN>
npx supabase secrets set AWS_ACCESS_KEY_ID=<your-aws-key>
npx supabase secrets set AWS_SECRET_ACCESS_KEY=<your-aws-secret>
```

**Important:** Replace with actual values from your AWS credentials

- [ ] AWS_REGION set to us-east-1
- [ ] STEP_FUNCTIONS_STATE_MACHINE_ARN configured
- [ ] AWS_ACCESS_KEY_ID configured
- [ ] AWS_SECRET_ACCESS_KEY configured

### Step 8: Verify Supabase Secrets

```bash
npx supabase secrets list
```

Expected output shows all 4 secrets configured

- [ ] All secrets appear in list
- [ ] No secrets have "undefined" or "null" values

---

## Phase 4: Integration

### Step 9: Update finalize-video-call Edge Function

The `finalize-video-call` edge function needs to be updated to invoke the Step Functions workflow.

**File:** `supabase/functions/finalize-video-call/index.ts`

Key additions needed:
```typescript
import { StepFunctionsClient, StartExecutionCommand } from "https://esm.sh/@aws-sdk/client-sfn@3";

const stepFunctionsClient = new StepFunctionsClient({
  region: Deno.env.get("AWS_REGION") ?? "us-east-1",
  credentials: {
    accessKeyId: Deno.env.get("AWS_ACCESS_KEY_ID") ?? "",
    secretAccessKey: Deno.env.get("AWS_SECRET_ACCESS_KEY") ?? "",
  },
});

// Start Step Functions execution
const command = new StartExecutionCommand({
  stateMachineArn: Deno.env.get("STEP_FUNCTIONS_STATE_MACHINE_ARN"),
  name: `soap-${sessionId}-${Date.now()}`,
  input: JSON.stringify({
    sessionId,
    appointmentId,
    providerId,
    transcriptionEnabled: true,
    sourceSystem: "supabase-edge-function",
  }),
});

const result = await stepFunctionsClient.send(command);
```

See `SOAP_STEP_FUNCTIONS_INTEGRATION.md` for complete code example

- [ ] finalize-video-call function updated
- [ ] Step Functions import added
- [ ] StartExecutionCommand properly configured
- [ ] Environment variables correctly referenced

### Step 10: Deploy Updated Edge Function

```bash
npx supabase functions deploy finalize-video-call
```

Expected: Function deployed successfully message

- [ ] Edge function deployed without errors

---

## Phase 5: Testing

### Step 11: Run End-to-End Test

```bash
cd aws-deployment
./test-soap-workflow.sh
```

The test script will:
- ✓ Verify all resources exist
- ✓ Create test session in DynamoDB
- ✓ Start workflow execution
- ✓ Monitor execution for 30 seconds
- ✓ Display results
- ✓ Offer cleanup option

**Expected Output:**
```
✓ State machine found
✓ Lambda functions found (5)
✓ DynamoDB tables found
✓ Test session created
✓ Workflow execution started
✓ Monitoring execution...
✓ Workflow completed successfully!
✓ SOAP note created
```

**Timeline:** 1-2 minutes

- [ ] Test script runs without errors
- [ ] Workflow execution status changes to SUCCEEDED
- [ ] SOAP note appears in DynamoDB
- [ ] No error states reached

### Step 12: Verify Database Results

After test completes, verify SOAP note in Supabase:

```sql
-- Check in Supabase SQL Editor
SELECT * FROM soap_notes
ORDER BY created_at DESC
LIMIT 5;

-- Should show test SOAP note with:
-- - status: 'draft'
-- - ai_model: 'claude-opus-4-5-20251101-v1:0'
-- - sections: chief_complaint, subjective, objective, assessment, plan
```

- [ ] SOAP notes table contains new records
- [ ] Records have proper structure
- [ ] AI model field shows Claude Opus 4.5

### Step 13: Check CloudWatch Logs

```bash
# View Step Functions execution logs
aws logs tail /aws/states/medzen-soap-workflow \
  --region us-east-1 \
  --follow

# View Lambda function logs
aws logs tail /aws/lambda/medzen-fetch-transcript \
  --region us-east-1 \
  --follow
```

- [ ] Step Functions logs show state transitions
- [ ] Lambda logs show function execution
- [ ] No error entries in logs

---

## Phase 6: Production Validation

### Step 14: Test with Real Video Call (Optional)

Create a real video call in the app:
1. Start a video call between provider and patient
2. Transcribe the conversation
3. End the call

Expected:
- SOAP note automatically generated
- Provider receives notification
- Note appears in database

- [ ] Real video call test conducted
- [ ] SOAP note generated automatically
- [ ] Notification received

### Step 15: Monitor for 24 Hours

Set up monitoring alerts:

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

- [ ] CloudWatch alarm configured
- [ ] Alerts enabled for execution failures
- [ ] 24-hour monitoring period completed
- [ ] No unexpected failures observed

---

## Post-Deployment Configuration

### Step 16: Lambda Environment Variables (Optional)

If Lambda functions need additional configuration:

```bash
# Set environment variables for Lambda functions
aws lambda update-function-configuration \
  --function-name medzen-fetch-transcript \
  --environment Variables="{SUPABASE_URL=https://noaeltglphdlkbflipit.supabase.co,SUPABASE_SERVICE_KEY=...}" \
  --region us-east-1
```

- [ ] Lambda environment variables configured
- [ ] Function code has access to required secrets

### Step 17: Performance Tuning (Optional)

Adjust Lambda timeouts based on testing:

```bash
# Default: 30 seconds, 256 MB memory
# Adjust based on actual execution time observed

aws lambda update-function-configuration \
  --function-name medzen-fetch-transcript \
  --timeout 60 \
  --memory-size 512 \
  --region us-east-1
```

- [ ] Lambda timeouts verified appropriate
- [ ] Memory allocation adequate for workload

---

## Troubleshooting

### Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| "BedrockUnavailable" state | Claude Opus 4.5 not approved | Request model access in Bedrock console for us-east-1 |
| "InvalidInput" error | Session not in DynamoDB | Ensure video call sessions are recorded in DynamoDB |
| Lambda timeout | External API slow | Increase Lambda timeout (40+ seconds recommended) |
| "No transcript found" | Transcription not complete | Wait for transcription to finish before calling SOAP |
| "Access Denied" in Lambda | IAM role missing permissions | Verify all policies attached to Step Functions role |
| SOAP note not in Supabase | Lambda environment vars wrong | Verify SUPABASE_URL and SUPABASE_SERVICE_KEY |

### Debug Commands

```bash
# View specific execution
EXECUTION_ARN="arn:aws:states:us-east-1:ACCOUNT_ID:execution:medzen-soap-workflow:test-soap-execution"

aws stepfunctions describe-execution \
  --execution-arn $EXECUTION_ARN \
  --region us-east-1

# Get full execution history
aws stepfunctions get-execution-history \
  --execution-arn $EXECUTION_ARN \
  --region us-east-1

# View Lambda logs
aws logs tail /aws/lambda/medzen-fetch-transcript \
  --region us-east-1 \
  --follow \
  --log-stream-name-prefix medzen

# Check DynamoDB tables
aws dynamodb scan --table-name medzen-video-sessions --region us-east-1
aws dynamodb scan --table-name medzen-soap-notes --region us-east-1
```

---

## Rollback Procedure

If issues occur, rollback by:

1. **Disable workflow:** Update `finalize-video-call` to skip Step Functions
   ```typescript
   // Comment out or remove StartExecutionCommand
   ```

2. **Revert edge function:**
   ```bash
   git checkout supabase/functions/finalize-video-call/index.ts
   npx supabase functions deploy finalize-video-call
   ```

3. **Stop new executions:** No further SOAP generation attempts will be made

4. **Keep data:** DynamoDB records are preserved for recovery

5. **Restore from backup:** If needed, use DynamoDB point-in-time recovery

---

## Success Criteria

Deployment is successful when:

- ✅ AWS resources created (IAM, DynamoDB, SQS, Lambda, Step Functions)
- ✅ Supabase secrets configured
- ✅ finalize-video-call edge function deployed
- ✅ Test workflow execution completes successfully
- ✅ SOAP note appears in database
- ✅ CloudWatch logs show state transitions
- ✅ 24-hour monitoring shows no critical failures

---

## Documentation References

- [SOAP Step Functions Integration Guide](SOAP_STEP_FUNCTIONS_INTEGRATION.md)
- [AWS Bedrock Claude Opus 4.5 Documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/what-is-bedrock.html)
- [AWS Step Functions Documentation](https://docs.aws.amazon.com/step-functions/)
- [AWS Lambda Developer Guide](https://docs.aws.amazon.com/lambda/)
- [AWS DynamoDB Developer Guide](https://docs.aws.amazon.com/dynamodb/)

---

## Support

For issues or questions:

1. Check CloudWatch logs: `aws logs tail /aws/states/medzen-soap-workflow --follow --region us-east-1`
2. Review execution history: `aws stepfunctions get-execution-history --execution-arn <ARN>`
3. Verify Bedrock access: `aws bedrock get-foundation-model --model-identifier anthropic.claude-opus-4-5-20251101-v1:0 --region us-east-1`
4. Test Lambda independently in AWS Console
5. Validate DynamoDB table structure

---

## Sign-Off

- **Deployment Date:** _______________
- **Deployed By:** _______________
- **Verified By:** _______________
- **Production Ready:** ☐ Yes ☐ No

**Notes:**
```
_________________________________________________________________

_________________________________________________________________

_________________________________________________________________
```

---

**Last Updated:** January 2026
**Version:** 1.0 - Claude Opus 4.5
**Status:** Ready for Deployment
