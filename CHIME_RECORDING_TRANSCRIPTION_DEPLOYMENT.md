# AWS Chime SDK v3 - Recording, Transcription & Medical Scribing Deployment Guide

## 📋 Overview

This guide walks you through deploying the complete video call infrastructure with:
- ✅ **Video Calls** (AWS Chime SDK v3.600.0)
- ✅ **Text Messaging** (Real-time chat in calls)
- ✅ **Recording** (Media Capture Pipelines)
- ✅ **Medical Transcription** (AWS Transcribe Medical)
- ✅ **Medical Entity Extraction** (AWS Comprehend Medical)

## 🏗️ Architecture

```
┌─────────────┐
│ Flutter App │
└──────┬──────┘
       │
       ▼
┌───────────────────┐
│ Supabase Edge     │
│ Function          │
│ chime-meeting-token│
└────────┬──────────┘
         │
         ▼
┌──────────────────────────┐
│ AWS Lambda               │
│ chime-meeting-manager    │
│ (Creates meeting +       │
│  starts recording &      │
│  transcription)          │
└────────┬─────────────────┘
         │
         ├─────────────────┐
         │                 │
         ▼                 ▼
┌─────────────────┐  ┌──────────────┐
│ Chime SDK       │  │ Media        │
│ Meeting         │  │ Capture      │
│                 │  │ Pipeline     │
└─────────────────┘  └──────┬───────┘
                            │
                            ▼
                     ┌─────────────┐
                     │ S3 Bucket   │
                     │ (Recording) │
                     └──────┬──────┘
                            │
         ┌──────────────────┴──────────────┐
         ▼                                 ▼
┌────────────────────┐          ┌──────────────────┐
│ Lambda:            │          │ Lambda:          │
│ recording-         │          │ transcription-   │
│ processor          │          │ processor        │
│ (Triggers          │          │ (AWS Transcribe  │
│  transcription)    │          │  Medical)        │
└────────────────────┘          └────────┬─────────┘
                                         │
                                         ▼
                                ┌─────────────────┐
                                │ Lambda:         │
                                │ medical-entity- │
                                │ extraction      │
                                │ (Comprehend     │
                                │  Medical)       │
                                └─────────────────┘
```

## 📦 Prerequisites

### 1. AWS Account Setup
```bash
# Configure AWS CLI
aws configure
# Enter:
# AWS Access Key ID
# AWS Secret Access Key
# Default region: eu-central-1
# Default output format: json

# Verify account
aws sts get-caller-identity
```

### 2. Required AWS Services
Enable these services in AWS Console for `eu-central-1`:
- ✅ Amazon Chime SDK
- ✅ Amazon Chime SDK Media Pipelines
- ✅ Amazon Transcribe Medical
- ✅ Amazon Comprehend Medical
- ✅ AWS Lambda
- ✅ Amazon S3
- ✅ Amazon DynamoDB
- ✅ Amazon EventBridge

### 3. Install Dependencies
```bash
# Navigate to each Lambda function and install dependencies
cd aws-lambda/chime-meeting-manager
npm install

cd ../chime-recording-processor
npm install

cd ../chime-transcription-processor
npm install

cd ../medical-entity-extraction
npm install
```

## 🚀 Deployment Steps

### Step 1: Create S3 Buckets

```bash
# Recordings bucket
aws s3 mb s3://medzen-chime-recordings --region eu-central-1

# Transcripts bucket
aws s3 mb s3://medzen-chime-transcripts --region eu-central-1

# Medical data bucket
aws s3 mb s3://medzen-medical-data --region eu-central-1

# Enable versioning on recordings bucket
aws s3api put-bucket-versioning \
  --bucket medzen-chime-recordings \
  --versioning-configuration Status=Enabled

# Configure lifecycle policy for recordings (optional - auto-delete after 90 days)
cat > lifecycle-policy.json <<EOF
{
  "Rules": [{
    "Id": "DeleteOldRecordings",
    "Status": "Enabled",
    "ExpirationInDays": 90,
    "Filter": {
      "Prefix": "recordings/"
    }
  }]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
  --bucket medzen-chime-recordings \
  --lifecycle-configuration file://lifecycle-policy.json
```

### Step 2: Create DynamoDB Table

```bash
aws dynamodb create-table \
  --table-name medzen-meeting-audit \
  --attribute-definitions \
    AttributeName=pk,AttributeType=S \
    AttributeName=sk,AttributeType=S \
  --key-schema \
    AttributeName=pk,KeyType=HASH \
    AttributeName=sk,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --region eu-central-1 \
  --tags Key=Environment,Value=Production Key=Service,Value=VideoCall
```

### Step 3: Create IAM Role for Lambda

Create `lambda-trust-policy.json`:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {
      "Service": "lambda.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }]
}
```

Create IAM role:
```bash
aws iam create-role \
  --role-name MedZen-Chime-Lambda-Role \
  --assume-role-policy-document file://lambda-trust-policy.json

# Attach policies
aws iam attach-role-policy \
  --role-name MedZen-Chime-Lambda-Role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

aws iam attach-role-policy \
  --role-name MedZen-Chime-Lambda-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonChimeSDKMediaPipelinesServiceLinkedRolePolicy
```

Create custom policy `chime-lambda-policy.json`:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "chime:CreateMeeting",
        "chime:CreateAttendee",
        "chime:DeleteMeeting",
        "chime:GetMeeting",
        "chime:CreateMediaCapturePipeline",
        "chime:DeleteMediaCapturePipeline",
        "transcribe:StartMedicalTranscriptionJob",
        "transcribe:GetMedicalTranscriptionJob",
        "comprehendmedical:DetectEntitiesV2",
        "comprehendmedical:DetectPHI",
        "comprehendmedical:InferICD10CM",
        "comprehendmedical:InferRxNorm",
        "comprehendmedical:InferSNOMEDCT",
        "s3:PutObject",
        "s3:GetObject",
        "s3:HeadObject",
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "lambda:InvokeFunction"
      ],
      "Resource": "*"
    }
  ]
}
```

Apply policy:
```bash
aws iam put-role-policy \
  --role-name MedZen-Chime-Lambda-Role \
  --policy-name ChimeLambdaPolicy \
  --policy-document file://chime-lambda-policy.json
```

### Step 4: Deploy Lambda Functions

#### 4.1 Deploy Meeting Manager

```bash
cd aws-lambda/chime-meeting-manager

# Zip function
zip -r function.zip index.js node_modules/

# Get IAM role ARN
ROLE_ARN=$(aws iam get-role --role-name MedZen-Chime-Lambda-Role --query 'Role.Arn' --output text)

# Create Lambda function
aws lambda create-function \
  --function-name medzen-chime-meeting-manager \
  --runtime nodejs20.x \
  --role $ROLE_ARN \
  --handler index.handler \
  --zip-file fileb://function.zip \
  --timeout 60 \
  --memory-size 512 \
  --environment "Variables={
    SUPABASE_URL=https://noaeltglphdlkbflipit.supabase.co,
    SUPABASE_SERVICE_KEY=YOUR_SUPABASE_SERVICE_KEY,
    RECORDINGS_BUCKET=medzen-chime-recordings,
    TRANSCRIPTS_BUCKET=medzen-chime-transcripts,
    DYNAMODB_TABLE=medzen-meeting-audit,
    AWS_ACCOUNT_ID=YOUR_AWS_ACCOUNT_ID
  }" \
  --region eu-central-1

# Create function URL (for API Gateway alternative)
aws lambda create-function-url-config \
  --function-name medzen-chime-meeting-manager \
  --auth-type NONE \
  --cors AllowOrigins='*',AllowMethods='POST,OPTIONS',AllowHeaders='*'

# Get function URL
aws lambda get-function-url-config \
  --function-name medzen-chime-meeting-manager \
  --query 'FunctionUrl' \
  --output text
```

#### 4.2 Deploy Recording Processor

```bash
cd ../chime-recording-processor

zip -r function.zip index.js node_modules/

aws lambda create-function \
  --function-name medzen-recording-processor \
  --runtime nodejs20.x \
  --role $ROLE_ARN \
  --handler index.handler \
  --zip-file fileb://function.zip \
  --timeout 120 \
  --memory-size 1024 \
  --environment "Variables={
    SUPABASE_URL=https://noaeltglphdlkbflipit.supabase.co,
    SUPABASE_SERVICE_KEY=YOUR_SUPABASE_SERVICE_KEY,
    DYNAMODB_TABLE=medzen-meeting-audit,
    TRANSCRIBE_FUNCTION_ARN=arn:aws:lambda:eu-central-1:ACCOUNT_ID:function:medzen-transcription-processor
  }" \
  --region eu-central-1

# Configure S3 trigger
aws lambda add-permission \
  --function-name medzen-recording-processor \
  --statement-id S3InvokeFunction \
  --action lambda:InvokeFunction \
  --principal s3.amazonaws.com \
  --source-arn arn:aws:s3:::medzen-chime-recordings

# Add S3 event notification
aws s3api put-bucket-notification-configuration \
  --bucket medzen-chime-recordings \
  --notification-configuration '{
    "LambdaFunctionConfigurations": [{
      "LambdaFunctionArn": "arn:aws:lambda:eu-central-1:ACCOUNT_ID:function:medzen-recording-processor",
      "Events": ["s3:ObjectCreated:*"],
      "Filter": {
        "Key": {
          "FilterRules": [{"Name": "prefix", "Value": "recordings/"}]
        }
      }
    }]
  }'
```

#### 4.3 Deploy Transcription Processor

```bash
cd ../chime-transcription-processor

zip -r function.zip index.js node_modules/

aws lambda create-function \
  --function-name medzen-transcription-processor \
  --runtime nodejs20.x \
  --role $ROLE_ARN \
  --handler index.handler \
  --zip-file fileb://function.zip \
  --timeout 180 \
  --memory-size 1024 \
  --environment "Variables={
    SUPABASE_URL=https://noaeltglphdlkbflipit.supabase.co,
    SUPABASE_SERVICE_KEY=YOUR_SUPABASE_SERVICE_KEY,
    TRANSCRIPTS_BUCKET=medzen-chime-transcripts,
    DYNAMODB_TABLE=medzen-meeting-audit,
    COMPREHEND_MEDICAL_FUNCTION_ARN=arn:aws:lambda:eu-central-1:ACCOUNT_ID:function:medzen-medical-entity-extraction
  }" \
  --region eu-central-1

# Create EventBridge rule to poll for completed transcriptions every 5 minutes
aws events put-rule \
  --name medzen-transcription-checker \
  --schedule-expression "rate(5 minutes)" \
  --state ENABLED

aws events put-targets \
  --rule medzen-transcription-checker \
  --targets "Id"="1","Arn"="arn:aws:lambda:eu-central-1:ACCOUNT_ID:function:medzen-transcription-processor"

aws lambda add-permission \
  --function-name medzen-transcription-processor \
  --statement-id EventBridgeInvokeFunction \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:eu-central-1:ACCOUNT_ID:rule/medzen-transcription-checker
```

#### 4.4 Deploy Medical Entity Extraction

```bash
cd ../medical-entity-extraction

zip -r function.zip index.js node_modules/

aws lambda create-function \
  --function-name medzen-medical-entity-extraction \
  --runtime nodejs20.x \
  --role $ROLE_ARN \
  --handler index.handler \
  --zip-file fileb://function.zip \
  --timeout 300 \
  --memory-size 2048 \
  --environment "Variables={
    SUPABASE_URL=https://noaeltglphdlkbflipit.supabase.co,
    SUPABASE_SERVICE_KEY=YOUR_SUPABASE_SERVICE_KEY,
    S3_BUCKET=medzen-medical-data,
    DYNAMODB_TABLE=medzen-meeting-audit
  }" \
  --region eu-central-1
```

### Step 5: Update Supabase Secrets

```bash
# Set Lambda endpoint in Supabase
npx supabase secrets set CHIME_API_ENDPOINT=https://YOUR_LAMBDA_URL.lambda-url.eu-central-1.on.aws

# Set AWS Account ID
npx supabase secrets set AWS_ACCOUNT_ID=YOUR_AWS_ACCOUNT_ID

# Set Firebase Project ID (for token verification)
npx supabase secrets set FIREBASE_PROJECT_ID=medzen-bf20e
```

### Step 6: Deploy Supabase Edge Function

```bash
# Deploy updated edge function with recording/transcription support
npx supabase functions deploy chime-meeting-token
```

## 🧪 Testing

### Test 1: Manual Lambda Test

Create `test-event.json`:
```json
{
  "action": "create",
  "appointmentId": "test-appt-123",
  "userId": "test-user-456",
  "enableRecording": true,
  "enableTranscription": true,
  "transcriptionLanguage": "en-US",
  "medicalSpecialty": "PRIMARYCARE"
}
```

Test:
```bash
aws lambda invoke \
  --function-name medzen-chime-meeting-manager \
  --payload file://test-event.json \
  --region eu-central-1 \
  response.json

cat response.json
```

Expected response:
```json
{
  "statusCode": 200,
  "body": "{\"meeting\":{...},\"attendee\":{...},\"recording\":{\"pipelineId\":\"...\"},\"transcription\":{\"jobName\":\"...\"}}"
}
```

### Test 2: End-to-End Video Call Test

1. **Start a video call from the app**
2. **Verify recording started**:
```bash
# Check DynamoDB for recording event
aws dynamodb query \
  --table-name medzen-meeting-audit \
  --key-condition-expression "pk = :pk" \
  --expression-attribute-values '{":pk":{"S":"MEETING#YOUR_MEETING_ID"}}' \
  --region eu-central-1
```

3. **End the call and wait 5-10 minutes**
4. **Check S3 for recording**:
```bash
aws s3 ls s3://medzen-chime-recordings/recordings/ --recursive
```

5. **Check transcription status**:
```bash
aws transcribe get-medical-transcription-job \
  --medical-transcription-job-name medical-transcript-test-appt-123-...
```

6. **Check Supabase database**:
```sql
SELECT
  id,
  meeting_id,
  recording_url,
  transcript,
  medical_entities,
  transcription_status
FROM video_call_sessions
WHERE appointment_id = 'test-appt-123';
```

## 📊 Monitoring

### CloudWatch Logs

```bash
# Meeting Manager logs
aws logs tail /aws/lambda/medzen-chime-meeting-manager --follow

# Recording Processor logs
aws logs tail /aws/lambda/medzen-recording-processor --follow

# Transcription Processor logs
aws logs tail /aws/lambda/medzen-transcription-processor --follow

# Medical Entity Extraction logs
aws logs tail /aws/lambda/medzen-medical-entity-extraction --follow
```

### Metrics Dashboard

Create CloudWatch dashboard:
```bash
aws cloudwatch put-dashboard \
  --dashboard-name MedZen-Chime-Dashboard \
  --dashboard-body file://dashboard.json
```

`dashboard.json`:
```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/Lambda", "Invocations", {"stat": "Sum", "label": "Meeting Manager"}],
          ["...", "Errors", {"stat": "Sum", "label": "Errors"}]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "eu-central-1",
        "title": "Lambda Invocations"
      }
    }
  ]
}
```

## 💰 Cost Estimation

### Monthly Costs (Estimated for 1000 consultations/month)

| Service | Usage | Cost |
|---------|-------|------|
| Chime SDK Meetings | 1000 meetings × 30 min | $150 |
| Media Capture Pipelines | 1000 recordings × 30 min | $30 |
| Transcribe Medical | 1000 × 30 min | $120 |
| Comprehend Medical | 1000 transcripts | $10 |
| S3 Storage | 500 GB | $12 |
| Lambda | 10,000 invocations | $2 |
| DynamoDB | On-demand | $5 |
| **Total** | | **~$329/month** |

## 🔒 Security Considerations

1. **Enable S3 encryption**:
```bash
aws s3api put-bucket-encryption \
  --bucket medzen-chime-recordings \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

2. **Enable S3 bucket policies** for HIPAA compliance
3. **Use VPC endpoints** for Lambda (recommended)
4. **Enable CloudTrail** for audit logging
5. **Rotate IAM credentials** regularly

## 🐛 Troubleshooting

### Recording not starting
```bash
# Check Lambda logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/medzen-chime-meeting-manager \
  --filter-pattern "startRecording" \
  --region eu-central-1

# Check IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT_ID:role/MedZen-Chime-Lambda-Role \
  --action-names chime:CreateMediaCapturePipeline
```

### Transcription failing
```bash
# Check Transcribe job status
aws transcribe list-medical-transcription-jobs \
  --status FAILED \
  --region eu-central-1

# View job details
aws transcribe get-medical-transcription-job \
  --medical-transcription-job-name JOB_NAME
```

### Missing recordings in S3
- Verify S3 bucket notification is configured
- Check recording processor Lambda has S3 invoke permission
- Verify S3 bucket exists and has correct permissions

## 📚 Additional Resources

- [AWS Chime SDK Documentation](https://docs.aws.amazon.com/chime-sdk/)
- [AWS Transcribe Medical](https://docs.aws.amazon.com/transcribe/latest/dg/transcribe-medical.html)
- [AWS Comprehend Medical](https://docs.aws.amazon.com/comprehend-medical/)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)

## ✅ Next Steps

1. ✅ Deploy all Lambda functions
2. ✅ Configure S3 buckets and triggers
3. ✅ Test end-to-end flow
4. ✅ Monitor CloudWatch logs
5. ✅ Set up alerts for failures
6. ✅ Configure backup and disaster recovery
7. ✅ Update Flutter UI to enable/disable recording

---

**Need help?** Check the logs first, then review the troubleshooting section above.
