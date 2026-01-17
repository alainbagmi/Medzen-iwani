# Amazon Chime SDK Deployment Guide

**Prerequisites Verified:** S3 buckets deployed, KMS encryption configured, generic Lambda functions active
**Target Region:** eu-west-1 (Primary)
**Deployment Method:** CloudFormation (Recommended) + Supabase Edge Functions
**Estimated Time:** 30-45 minutes

## Pre-Deployment Checklist

Before starting deployment, verify these prerequisites:

### ✅ AWS CLI Configured
```bash
aws sts get-caller-identity --region eu-west-1
# Should show: Account ID 558069890522
```

### ✅ Supabase CLI Authenticated
```bash
npx supabase login
npx supabase projects list
# Should show: medzen project
```

### ✅ Required Permissions
- CloudFormation: Create/Update stacks
- Lambda: Create/Update functions
- IAM: Create/Attach roles and policies
- API Gateway: Create REST APIs
- S3: Read bucket policies (already have buckets)
- KMS: Use encryption key (already configured)

### ✅ Project Files Ready
```bash
ls aws-deployment/cloudformation/chime-sdk-multi-region.yaml  # Should exist
ls -d supabase/functions/chime-*  # Should show 5 directories
```

## Phase 1: Deploy AWS Infrastructure (CloudFormation)

### Step 1.1: Review CloudFormation Template

```bash
# Open template in editor to review parameters
cat aws-deployment/cloudformation/chime-sdk-multi-region.yaml | head -100
```

**Key Parameters to Note:**
- ProjectName: medzen (default)
- Environment: production
- RetentionDays: 2555 (7 years for HIPAA)
- EnableMultiRegion: false (we'll deploy eu-west-1 only initially)

### Step 1.2: Deploy CloudFormation Stack

```bash
cd aws-deployment/cloudformation

# Deploy to eu-west-1
aws cloudformation create-stack \
  --stack-name medzen-chime-sdk-eu-west-1 \
  --template-body file://chime-sdk-multi-region.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=medzen \
    ParameterKey=Environment,ParameterValue=production \
    ParameterKey=RetentionDays,ParameterValue=2555 \
  --capabilities CAPABILITY_IAM \
  --region eu-west-1 \
  --tags \
    Key=Project,Value=MedZen \
    Key=Environment,Value=Production \
    Key=Component,Value=ChimeSDK \
    Key=HIPAA,Value=Compliant
```

**Expected Output:**
```json
{
  "StackId": "arn:aws:cloudformation:eu-west-1:558069890522:stack/medzen-chime-sdk-eu-west-1/..."
}
```

### Step 1.3: Monitor Stack Creation

```bash
# Watch stack creation progress (updates every 10 seconds)
watch -n 10 "aws cloudformation describe-stacks \
  --stack-name medzen-chime-sdk-eu-west-1 \
  --region eu-west-1 \
  --query 'Stacks[0].[StackStatus,StackStatusReason]' \
  --output text"
```

**Status Progression:**
1. `CREATE_IN_PROGRESS` - Stack creation started
2. Individual resources creating (Lambda, API Gateway, IAM roles)
3. `CREATE_COMPLETE` - Stack created successfully (15-20 minutes)

**If Status Shows `ROLLBACK_IN_PROGRESS`:**
```bash
# Check what failed
aws cloudformation describe-stack-events \
  --stack-name medzen-chime-sdk-eu-west-1 \
  --region eu-west-1 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
  --output table

# Common issues:
# - Insufficient IAM permissions → Run as admin or add permissions
# - Service quota exceeded → Request quota increase
# - Resource name conflict → Stack already exists, use update-stack instead
```

### Step 1.4: Capture Stack Outputs

```bash
# Get all stack outputs (save these for Supabase configuration)
aws cloudformation describe-stacks \
  --stack-name medzen-chime-sdk-eu-west-1 \
  --region eu-west-1 \
  --query 'Stacks[0].Outputs' \
  --output table > chime-stack-outputs.txt

# Display outputs
cat chime-stack-outputs.txt
```

**Expected Outputs:**
```
|                        Key                       |                    Value                     |
|--------------------------------------------------|----------------------------------------------|
| ChimeApiEndpoint                                 | https://xxxxx.execute-api.eu-west-1.amazonaws.com/prod |
| MeetingManagerFunctionArn                        | arn:aws:lambda:eu-west-1:558069890522:function:medzen-meeting-manager |
| RecordingHandlerFunctionArn                      | arn:aws:lambda:eu-west-1:558069890522:function:medzen-recording-handler |
| TranscriptionProcessorFunctionArn                | arn:aws:lambda:eu-west-1:558069890522:function:medzen-transcription-processor |
| MessagingHandlerFunctionArn                      | arn:aws:lambda:eu-west-1:558069890522:function:medzen-messaging-handler |
| KMSKeyId                                         | arn:aws:kms:eu-west-1:558069890522:key/5e84763b-0627-410f-b9bf-661e4021fba3 |
```

**Save These Values:** You'll need them for Phase 2 (Supabase configuration)

### Step 1.5: Verify Lambda Functions Created

```bash
# List all medzen Lambda functions
aws lambda list-functions \
  --region eu-west-1 \
  --query 'Functions[?contains(FunctionName, `medzen`)].[FunctionName, Runtime, LastModified]' \
  --output table
```

**Expected:** 8 functions total
- ✅ medzen-medical-entity-extractor (already existed)
- ✅ medzen-bedrock-ai-chat (already existed)
- ✅ medzen-data-retention-cleanup (already existed)
- ✅ medzen-compliance-monitor (already existed)
- 🆕 medzen-meeting-manager (newly created)
- 🆕 medzen-recording-handler (newly created)
- 🆕 medzen-transcription-processor (newly created)
- 🆕 medzen-messaging-handler (newly created)

### Step 1.6: Verify API Gateway Created

```bash
# Find API Gateway ID
aws apigateway get-rest-apis \
  --region eu-west-1 \
  --query 'items[?contains(name, `medzen`) || contains(name, `chime`)].{Name:name, ID:id, Endpoint:endpoint}' \
  --output table
```

**Expected:** 1 REST API named "medzen-chime-api" or similar

**Test API Gateway Endpoint:**
```bash
# Get endpoint from stack outputs
export CHIME_API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name medzen-chime-sdk-eu-west-1 \
  --region eu-west-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ChimeApiEndpoint`].OutputValue' \
  --output text)

echo "Chime API Endpoint: $CHIME_API_ENDPOINT"

# Test health endpoint (if implemented)
curl -X GET "$CHIME_API_ENDPOINT/health"
# Expected: {"status": "healthy", "service": "chime-sdk"}
```

## Phase 2: Deploy Supabase Edge Functions

### Step 2.1: Set Environment Variables

```bash
# From CloudFormation outputs
export CHIME_API_ENDPOINT="https://xxxxx.execute-api.eu-west-1.amazonaws.com/prod"
export AWS_CHIME_REGION="eu-west-1"

# Get messaging Lambda URL (if exposed as Function URL)
export MESSAGING_LAMBDA_ARN=$(aws cloudformation describe-stacks \
  --stack-name medzen-chime-sdk-eu-west-1 \
  --region eu-west-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`MessagingHandlerFunctionArn`].OutputValue' \
  --output text)

echo "Messaging Lambda ARN: $MESSAGING_LAMBDA_ARN"
```

### Step 2.2: Configure Supabase Secrets

```bash
cd supabase

# Set Chime API endpoint
npx supabase secrets set CHIME_API_ENDPOINT="$CHIME_API_ENDPOINT"

# Set AWS region
npx supabase secrets set AWS_CHIME_REGION="$AWS_CHIME_REGION"

# Set messaging Lambda ARN (for direct invocation from edge functions)
npx supabase secrets set CHIME_MESSAGING_LAMBDA_ARN="$MESSAGING_LAMBDA_ARN"

# Verify secrets set
npx supabase secrets list | grep -E "(CHIME|AWS_CHIME)"
```

**Expected Output:**
```
AWS_CHIME_REGION
CHIME_API_ENDPOINT
CHIME_MESSAGING_LAMBDA_ARN
```

### Step 2.3: Deploy Edge Functions (One by One)

```bash
cd functions

# Deploy meeting token generation
npx supabase functions deploy chime-meeting-token
# Expected: ✔ Deployed chime-meeting-token to Supabase

# Deploy messaging handler
npx supabase functions deploy chime-messaging
# Expected: ✔ Deployed chime-messaging to Supabase

# Deploy recording callback webhook
npx supabase functions deploy chime-recording-callback
# Expected: ✔ Deployed chime-recording-callback to Supabase

# Deploy transcription callback webhook
npx supabase functions deploy chime-transcription-callback
# Expected: ✔ Deployed chime-transcription-callback to Supabase

# Deploy entity extraction (processes transcriptions)
npx supabase functions deploy chime-entity-extraction
# Expected: ✔ Deployed chime-entity-extraction to Supabase
```

**Deployment Time:** ~2-3 minutes per function

**If Deployment Fails:**
```bash
# Check function syntax errors
cd chime-meeting-token
npx supabase functions serve chime-meeting-token
# Fix any TypeScript/Deno errors shown

# Check secrets are accessible
npx supabase secrets list

# Retry deployment with --debug flag
npx supabase functions deploy chime-meeting-token --debug
```

### Step 2.4: Verify All Edge Functions Deployed

```bash
npx supabase functions list
```

**Expected Output:**
```
Function Name                    | Status | Version
---------------------------------|--------|--------
chime-meeting-token              | ACTIVE | v1
chime-messaging                  | ACTIVE | v1
chime-recording-callback         | ACTIVE | v1
chime-transcription-callback     | ACTIVE | v1
chime-entity-extraction          | ACTIVE | v1
sync-to-ehrbase                  | ACTIVE | v35    (existing)
powersync-token                  | ACTIVE | v15    (existing)
upload-profile-picture           | ACTIVE | v11    (existing)
cleanup-old-profile-pictures     | ACTIVE | v11    (existing)
payunit                          | ACTIVE | v15    (existing)
resetpwd                         | ACTIVE | v26    (existing)
```

**Total:** 11 edge functions (5 new Chime + 6 existing)

### Step 2.5: Test Edge Function Connectivity

```bash
# Test meeting token generation (requires valid user ID)
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token" \
  -H "Authorization: Bearer YOUR_SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"userId": "test-user-123", "meetingTitle": "Test Meeting"}'

# Expected response (if successful):
# {"token": "...", "meetingId": "...", "attendeeId": "..."}

# Check function logs for errors
npx supabase functions logs chime-meeting-token --tail
```

## Phase 3: Configure Database Tables

### Step 3.1: Verify Chime Tables Exist

```bash
# Check if Chime-related tables exist in Supabase
npx supabase db remote commit
# This will show any pending migrations

# Query for Chime tables
psql "postgresql://postgres.noaeltglphdlkbflipit:PASSWORD@aws-0-eu-central-1.pooler.supabase.com:6543/postgres" \
  -c "\dt *chime*"
```

**Expected Tables:**
- `chime_meetings` - Meeting metadata
- `chime_attendees` - Meeting participants
- `chime_messages` - Messaging channel messages
- `chime_recordings` - Recording metadata and S3 URLs

**If Tables Don't Exist:**
```bash
# Check if migration file exists
ls supabase/migrations/*chime*.sql

# If exists, apply migration
npx supabase db push

# If doesn't exist, create migration
# See "Create Chime Tables Migration" section below
```

### Step 3.2: Create Chime Tables Migration (If Needed)

```bash
cd supabase/migrations

# Create new migration file
cat > $(date +%Y%m%d%H%M%S)_create_chime_tables.sql << 'EOF'
-- Chime SDK Tables for MedZen

-- Meetings table
CREATE TABLE IF NOT EXISTS chime_meetings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id TEXT UNIQUE NOT NULL,  -- Chime meeting ID
  external_meeting_id TEXT,  -- Our internal reference
  title TEXT NOT NULL,
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT CHECK (status IN ('active', 'ended', 'failed')) DEFAULT 'active',
  started_at TIMESTAMPTZ DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  recording_enabled BOOLEAN DEFAULT true,
  transcription_enabled BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Attendees table
CREATE TABLE IF NOT EXISTS chime_attendees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id UUID REFERENCES chime_meetings(id) ON DELETE CASCADE,
  attendee_id TEXT UNIQUE NOT NULL,  -- Chime attendee ID
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  external_user_id TEXT,  -- For guests
  join_token TEXT,  -- Chime join token
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  left_at TIMESTAMPTZ,
  is_host BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages table (for Chime messaging)
CREATE TABLE IF NOT EXISTS chime_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_arn TEXT NOT NULL,  -- Chime channel ARN
  message_id TEXT UNIQUE NOT NULL,  -- Chime message ID
  sender_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Recordings table
CREATE TABLE IF NOT EXISTS chime_recordings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id UUID REFERENCES chime_meetings(id) ON DELETE CASCADE,
  s3_bucket TEXT NOT NULL DEFAULT 'medzen-meeting-recordings-558069890522',
  s3_key TEXT NOT NULL,  -- S3 object key
  recording_id TEXT UNIQUE,  -- Chime recording ID
  status TEXT CHECK (status IN ('recording', 'processing', 'available', 'failed')) DEFAULT 'recording',
  duration_seconds INTEGER,
  file_size_bytes BIGINT,
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  transcription_s3_key TEXT,  -- Link to transcription
  transcription_status TEXT CHECK (transcription_status IN ('pending', 'processing', 'completed', 'failed')),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_chime_meetings_status ON chime_meetings(status);
CREATE INDEX idx_chime_meetings_created_by ON chime_meetings(created_by);
CREATE INDEX idx_chime_attendees_meeting_id ON chime_attendees(meeting_id);
CREATE INDEX idx_chime_attendees_user_id ON chime_attendees(user_id);
CREATE INDEX idx_chime_messages_channel_arn ON chime_messages(channel_arn);
CREATE INDEX idx_chime_recordings_meeting_id ON chime_recordings(meeting_id);
CREATE INDEX idx_chime_recordings_status ON chime_recordings(status);

-- Row Level Security (RLS) Policies
ALTER TABLE chime_meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE chime_attendees ENABLE ROW LEVEL SECURITY;
ALTER TABLE chime_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chime_recordings ENABLE ROW LEVEL SECURITY;

-- Meetings: Users can view meetings they created or are attending
CREATE POLICY "Users can view own meetings"
  ON chime_meetings FOR SELECT
  USING (
    auth.uid() = created_by OR
    auth.uid() IN (SELECT user_id FROM chime_attendees WHERE meeting_id = chime_meetings.id)
  );

CREATE POLICY "Users can create meetings"
  ON chime_meetings FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Hosts can update meetings"
  ON chime_meetings FOR UPDATE
  USING (auth.uid() = created_by);

-- Attendees: Users can view attendees of meetings they're in
CREATE POLICY "Users can view meeting attendees"
  ON chime_attendees FOR SELECT
  USING (
    auth.uid() = user_id OR
    auth.uid() IN (SELECT user_id FROM chime_attendees a2 WHERE a2.meeting_id = chime_attendees.meeting_id)
  );

-- Messages: Users can view messages in channels they're members of
CREATE POLICY "Users can view channel messages"
  ON chime_messages FOR SELECT
  USING (true);  -- TODO: Implement proper channel membership check

CREATE POLICY "Users can send messages"
  ON chime_messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- Recordings: Users can view recordings of meetings they attended
CREATE POLICY "Users can view meeting recordings"
  ON chime_recordings FOR SELECT
  USING (
    auth.uid() IN (
      SELECT a.user_id
      FROM chime_attendees a
      WHERE a.meeting_id = chime_recordings.meeting_id
    )
  );

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_chime_meetings_updated_at BEFORE UPDATE ON chime_meetings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_chime_messages_updated_at BEFORE UPDATE ON chime_messages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_chime_recordings_updated_at BEFORE UPDATE ON chime_recordings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

EOF

# Apply migration
npx supabase db push

# Verify tables created
npx supabase db remote commit
```

## Phase 4: Update Flutter App Configuration

### Step 4.1: Add Chime API Endpoint to Environment Config

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Update environment config
cat > assets/environment_values/chime_config.json << EOF
{
  "chime_api_endpoint": "$CHIME_API_ENDPOINT",
  "chime_region": "eu-west-1",
  "chime_meetings_enabled": true,
  "chime_messaging_enabled": true,
  "chime_recording_enabled": true,
  "chime_transcription_enabled": true
}
EOF

# Add to pubspec.yaml assets (if not already there)
grep -q "chime_config.json" pubspec.yaml || \
  sed -i '' '/assets:$/a\    - assets/environment_values/chime_config.json' pubspec.yaml
```

### Step 4.2: Update environment_values.dart

```bash
# Add Chime configuration to lib/environment_values.dart
cat >> lib/environment_values.dart << 'EOF'

// Chime SDK Configuration
class ChimeConfig {
  static const String apiEndpoint = String.fromEnvironment(
    'CHIME_API_ENDPOINT',
    defaultValue: 'https://placeholder.execute-api.eu-west-1.amazonaws.com/prod',
  );

  static const String region = 'eu-west-1';
  static const bool meetingsEnabled = true;
  static const bool messagingEnabled = true;
  static const bool recordingEnabled = true;
  static const bool transcriptionEnabled = true;
}
EOF
```

### Step 4.3: Test Flutter App Build

```bash
flutter clean
flutter pub get
flutter analyze

# Test build for iOS
flutter build ios --release --no-codesign

# Test build for Android
flutter build apk --release

# Test build for Web
flutter build web --release
```

**Expected:** No build errors related to Chime SDK

## Phase 5: End-to-End Testing

### Test 1: Meeting Token Generation

```bash
# Get Supabase anon key
export SUPABASE_ANON_KEY=$(grep 'SUPABASE_ANON_KEY' supabase/.env | cut -d'=' -f2)

# Create test meeting
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user-001",
    "meetingTitle": "Integration Test Meeting",
    "attendeeName": "Test User"
  }'

# Expected response:
# {
#   "Meeting": {
#     "MeetingId": "...",
#     "ExternalMeetingId": "...",
#     "MediaPlacement": { ... }
#   },
#   "Attendee": {
#     "AttendeeId": "...",
#     "JoinToken": "..."
#   }
# }

# Check edge function logs
npx supabase functions logs chime-meeting-token --tail
```

✅ **Pass Criteria:** Valid meeting ID and join token returned

### Test 2: Recording Start

```bash
# Trigger recording start (requires active meeting)
export TEST_MEETING_ID="<meeting-id-from-test-1>"

# Call Lambda directly to start recording
aws lambda invoke \
  --function-name medzen-recording-handler \
  --region eu-west-1 \
  --payload '{"action": "start", "meetingId": "'$TEST_MEETING_ID'"}' \
  /tmp/recording-response.json

cat /tmp/recording-response.json

# Check S3 bucket for recording
aws s3 ls s3://medzen-meeting-recordings-558069890522/ --recursive | tail -5
```

✅ **Pass Criteria:** Recording started, S3 object created

### Test 3: Transcription Processing

```bash
# Trigger transcription (after recording available)
export TEST_RECORDING_S3_KEY="recordings/${TEST_MEETING_ID}/recording.mp4"

aws lambda invoke \
  --function-name medzen-transcription-processor \
  --region eu-west-1 \
  --payload '{
    "Records": [{
      "s3": {
        "bucket": {"name": "medzen-meeting-recordings-558069890522"},
        "object": {"key": "'$TEST_RECORDING_S3_KEY'"}
      }
    }]
  }' \
  /tmp/transcription-response.json

cat /tmp/transcription-response.json

# Check transcripts bucket
aws s3 ls s3://medzen-meeting-transcripts-558069890522/ --recursive | tail -5
```

✅ **Pass Criteria:** Transcription job started, transcript written to S3

### Test 4: Medical Entity Extraction

```bash
# Trigger entity extraction (after transcription complete)
export TEST_TRANSCRIPT_S3_KEY="transcripts/${TEST_MEETING_ID}/transcript.json"

aws lambda invoke \
  --function-name medzen-medical-entity-extractor \
  --region eu-west-1 \
  --payload '{
    "s3Bucket": "medzen-meeting-transcripts-558069890522",
    "s3Key": "'$TEST_TRANSCRIPT_S3_KEY'",
    "meetingId": "'$TEST_MEETING_ID'"
  }' \
  /tmp/entity-extraction-response.json

cat /tmp/entity-extraction-response.json

# Check medical data bucket
aws s3 ls s3://medzen-medical-data-558069890522/ --recursive | tail -5
```

✅ **Pass Criteria:** Medical entities extracted (ICD-10 codes, medications, conditions)

### Test 5: Flutter App End-to-End

1. **Launch Flutter App:**
   ```bash
   flutter run -d chrome  # or iOS/Android device
   ```

2. **Navigate to Video Call:**
   - Sign in as test user
   - Navigate to "Video Calls" or "Appointments"
   - Click "Start New Call"

3. **Verify Meeting Creation:**
   - Check Supabase `chime_meetings` table:
     ```sql
     SELECT * FROM chime_meetings ORDER BY created_at DESC LIMIT 1;
     ```
   - Verify meeting_id, status='active', created_by=user_id

4. **Join Meeting:**
   - Click "Join" button
   - Verify video/audio preview appears
   - Join meeting room

5. **Verify Attendee:**
   - Check Supabase `chime_attendees` table:
     ```sql
     SELECT * FROM chime_attendees ORDER BY joined_at DESC LIMIT 1;
     ```
   - Verify attendee_id, user_id, joined_at populated

6. **Test Recording:**
   - Click "Start Recording" button
   - Wait 1 minute
   - Click "Stop Recording"
   - Check `chime_recordings` table and S3 bucket

7. **End Meeting:**
   - Click "End Call"
   - Verify meeting status updated to 'ended' in database

✅ **Pass Criteria:** All steps complete without errors, data persisted correctly

## Post-Deployment Verification

### Verification Checklist

```bash
# Run comprehensive verification
cat > verify-chime-deployment.sh << 'EOF'
#!/bin/bash
echo "=== Chime SDK Deployment Verification ==="
echo ""

# 1. CloudFormation Stack
echo "✓ CloudFormation Stack:"
aws cloudformation describe-stacks \
  --stack-name medzen-chime-sdk-eu-west-1 \
  --region eu-west-1 \
  --query 'Stacks[0].StackStatus' \
  --output text
echo ""

# 2. Lambda Functions
echo "✓ Lambda Functions:"
aws lambda list-functions \
  --region eu-west-1 \
  --query 'Functions[?contains(FunctionName, `medzen`)].FunctionName' \
  --output text | tr '\t' '\n' | grep -E "(meeting|recording|transcription|messaging)"
echo ""

# 3. S3 Buckets
echo "✓ S3 Buckets:"
aws s3 ls | grep medzen-meeting
echo ""

# 4. Supabase Edge Functions
echo "✓ Supabase Edge Functions:"
npx supabase functions list | grep chime
echo ""

# 5. Supabase Secrets
echo "✓ Supabase Secrets:"
npx supabase secrets list | grep -E "(CHIME|AWS_CHIME)"
echo ""

# 6. Database Tables
echo "✓ Database Tables:"
psql "$DATABASE_URL" -c "\dt chime*" 2>/dev/null || echo "⚠️  Connect to database manually to verify tables"
echo ""

echo "=== Verification Complete ==="
EOF

chmod +x verify-chime-deployment.sh
./verify-chime-deployment.sh
```

**Expected Output:**
```
=== Chime SDK Deployment Verification ===

✓ CloudFormation Stack:
CREATE_COMPLETE

✓ Lambda Functions:
medzen-meeting-manager
medzen-recording-handler
medzen-transcription-processor
medzen-messaging-handler

✓ S3 Buckets:
medzen-meeting-recordings-558069890522
medzen-meeting-transcripts-558069890522

✓ Supabase Edge Functions:
chime-meeting-token              | ACTIVE | v1
chime-messaging                  | ACTIVE | v1
chime-recording-callback         | ACTIVE | v1
chime-transcription-callback     | ACTIVE | v1
chime-entity-extraction          | ACTIVE | v1

✓ Supabase Secrets:
AWS_CHIME_REGION
CHIME_API_ENDPOINT
CHIME_MESSAGING_LAMBDA_ARN

✓ Database Tables:
chime_meetings
chime_attendees
chime_messages
chime_recordings

=== Verification Complete ===
```

## Troubleshooting Common Issues

### Issue 1: CloudFormation Stack Creation Fails

**Symptom:** Stack status shows `ROLLBACK_IN_PROGRESS` or `ROLLBACK_COMPLETE`

**Diagnosis:**
```bash
aws cloudformation describe-stack-events \
  --stack-name medzen-chime-sdk-eu-west-1 \
  --region eu-west-1 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`].[LogicalResourceId,ResourceStatusReason]' \
  --output table
```

**Common Causes:**
1. **Insufficient IAM Permissions**
   - Solution: Add `AdministratorAccess` policy temporarily or add specific permissions:
     ```bash
     aws iam attach-user-policy \
       --user-name YOUR_USERNAME \
       --policy-arn arn:aws:iam::aws:policy/AWSCloudFormationFullAccess
     ```

2. **Service Quota Exceeded**
   - Solution: Request quota increase in AWS Service Quotas console
   - Check current limits:
     ```bash
     aws service-quotas get-service-quota \
       --service-code lambda \
       --quota-code L-B99A9384  # Concurrent executions
     ```

3. **Resource Name Conflict**
   - Solution: Stack already exists, use `update-stack` instead of `create-stack`

### Issue 2: Edge Function Deployment Fails

**Symptom:** `npx supabase functions deploy` returns error

**Diagnosis:**
```bash
npx supabase functions deploy chime-meeting-token --debug
```

**Common Causes:**
1. **Syntax Errors in TypeScript**
   - Solution: Test locally first:
     ```bash
     cd supabase/functions/chime-meeting-token
     npx supabase functions serve chime-meeting-token
     # Fix any errors shown
     ```

2. **Missing Secrets**
   - Solution: Verify secrets exist:
     ```bash
     npx supabase secrets list
     # Set missing secrets
     npx supabase secrets set CHIME_API_ENDPOINT="..."
     ```

3. **Supabase CLI Not Authenticated**
   - Solution: Re-authenticate:
     ```bash
     npx supabase login
     npx supabase link --project-ref noaeltglphdlkbflipit
     ```

### Issue 3: Meeting Token Generation Returns Error

**Symptom:** Edge function returns 500 error or timeout

**Diagnosis:**
```bash
npx supabase functions logs chime-meeting-token --tail
```

**Common Causes:**
1. **CHIME_API_ENDPOINT Not Configured**
   - Solution: Set secret:
     ```bash
     npx supabase secrets set CHIME_API_ENDPOINT="$(aws cloudformation describe-stacks --stack-name medzen-chime-sdk-eu-west-1 --region eu-west-1 --query 'Stacks[0].Outputs[?OutputKey==`ChimeApiEndpoint`].OutputValue' --output text)"
     ```

2. **Lambda Function Not Responding**
   - Check Lambda logs:
     ```bash
     aws logs tail /aws/lambda/medzen-meeting-manager --region eu-west-1 --follow
     ```
   - Verify IAM role has Chime SDK permissions

3. **Network Timeout**
   - Increase edge function timeout in Supabase dashboard
   - Check VPC configuration (if Lambda in VPC)

### Issue 4: Recordings Not Appearing in S3

**Symptom:** Meeting records but no files in S3 bucket

**Diagnosis:**
```bash
# Check recording Lambda logs
aws logs tail /aws/lambda/medzen-recording-handler --region eu-west-1 --follow

# Check S3 bucket
aws s3 ls s3://medzen-meeting-recordings-558069890522/ --recursive
```

**Common Causes:**
1. **Lambda Lacks S3 Write Permissions**
   - Verify IAM role:
     ```bash
     aws lambda get-function \
       --function-name medzen-recording-handler \
       --region eu-west-1 \
       --query 'Configuration.Role'

     # Check role permissions
     aws iam get-role-policy \
       --role-name <role-name> \
       --policy-name <policy-name>
     ```
   - Add S3 write permission if missing

2. **KMS Key Policy Doesn't Allow Lambda**
   - Update KMS key policy to allow Lambda encryption:
     ```bash
     aws kms put-key-policy \
       --key-id <key-id> \
       --policy-name default \
       --policy file://kms-policy.json
     ```

3. **Recording Not Started**
   - Verify Chime recording API called successfully
   - Check Chime SDK console for active recordings

## Monitoring and Maintenance

### CloudWatch Alarms (Recommended)

```bash
# Create alarm for Lambda errors
aws cloudwatch put-metric-alarm \
  --alarm-name medzen-chime-lambda-errors \
  --alarm-description "Alert on Chime Lambda function errors" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --region eu-west-1

# Create alarm for S3 bucket size
aws cloudwatch put-metric-alarm \
  --alarm-name medzen-recordings-bucket-size \
  --alarm-description "Alert when recordings bucket exceeds 100 GB" \
  --metric-name BucketSizeBytes \
  --namespace AWS/S3 \
  --dimensions Name=BucketName,Value=medzen-meeting-recordings-558069890522 Name=StorageType,Value=StandardStorage \
  --statistic Average \
  --period 86400 \
  --threshold 107374182400 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --region eu-west-1
```

### Regular Maintenance Tasks

**Weekly:**
- Review CloudWatch logs for errors
- Check S3 bucket sizes and costs
- Verify edge function success rates

**Monthly:**
- Review Chime SDK usage and costs
- Test end-to-end meeting creation and recording
- Update Lambda function runtime versions if needed
- Review and rotate KMS keys

**Quarterly:**
- Review S3 lifecycle policies and retention
- Audit IAM permissions
- Test disaster recovery procedures
- Review compliance reports

## Cost Optimization

**Expected Monthly Costs:**
- Lambda: ~$10-20 (depends on meeting volume)
- API Gateway: ~$5
- S3 Storage: ~$10-50 (depends on recordings kept)
- KMS: $1
- CloudWatch Logs: ~$5
- **Chime SDK:** Variable (pay-per-use):
  - Video attendee-minutes: $0.00375/min
  - Audio attendee-minutes: $0.0017/min
  - Messaging: $0.00125 per message

**Total Estimated:** $30-100/month + Chime usage

**Optimization Tips:**
1. Enable S3 lifecycle policies to transition old recordings to Glacier
2. Set shorter CloudWatch log retention (7 days vs 30 days)
3. Use Chime SDK meeting features wisely (disable recording when not needed)
4. Monitor and delete inactive messaging channels

## Success Criteria

Deployment is complete when:

- ✅ CloudFormation stack status: `CREATE_COMPLETE`
- ✅ 8 Lambda functions exist (4 new Chime + 4 existing)
- ✅ 5 Supabase edge functions deployed and ACTIVE
- ✅ 3 Chime secrets configured in Supabase
- ✅ 4 Chime database tables created with RLS policies
- ✅ Flutter app builds without errors
- ✅ End-to-end test: Create meeting → Join → Record → Transcribe → Extract entities
- ✅ All verification checks pass

**Next Steps After Deployment:**
1. Update CLAUDE.md with Chime SDK usage patterns
2. Create user documentation for video calling features
3. Train support team on troubleshooting common issues
4. Set up monitoring dashboards in CloudWatch
5. Plan multi-region deployment (af-south-1) for disaster recovery
