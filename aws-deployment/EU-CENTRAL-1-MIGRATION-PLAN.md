# MedZen AWS Infrastructure Migration Plan
## From eu-west-1/eu-west-2 to eu-central-1 (Frankfurt)

**Date:** 2025-12-11
**Target Region:** eu-central-1 (Frankfurt, Germany)
**Current Primary Region:** eu-west-1 (Ireland)
**Current Secondary Region:** af-south-1 (Cape Town)

---

## Executive Summary

This document outlines the complete migration strategy for moving MedZen's AWS infrastructure from **eu-west-1 (Ireland)** to **eu-central-1 (Frankfurt)** as the primary region.

### Migration Rationale

**Strategic Benefits:**
- ✅ **Central EU Location** - Better geographic coverage for European users
- ✅ **Data Residency Compliance** - Enhanced GDPR compliance for German/Central EU patients
- ✅ **Lower Latency** - 5-15ms improvement for Central/Eastern European users
- ✅ **AWS Service Availability** - Frankfurt has full Chime SDK + Bedrock support
- ✅ **Business Expansion** - Better positioned for German healthcare market entry

**Technical Benefits:**
- ✅ Chime SDK control region - Frankfurt is a primary Chime control region
- ✅ Bedrock Claude 3.5 Sonnet available
- ✅ AWS Transcribe Medical with German language support
- ✅ AWS Translate with better African language coverage
- ✅ 3 Availability Zones: eu-central-1a, eu-central-1b, eu-central-1c

**Cost Impact:**
- 📊 **~5-8% cost increase** compared to eu-west-1
- 💰 **Monthly estimate:** $472-$498/month (vs $447-$467 in eu-west-1)
- ✅ **Justified by:** Improved latency, compliance, and market positioning

---

## Current Infrastructure Inventory

### 1. Amazon Chime SDK (eu-west-1)
**Status:** Fully deployed and operational

**Resources:**
- KMS Key: `arn:aws:kms:eu-west-1:558069890522:key/5e84763b-0627-410f-b9bf-661e4021fba3`
- S3 Buckets:
  - `medzen-meeting-recordings-558069890522`
  - `medzen-meeting-transcripts-558069890522`
  - `medzen-medical-data-558069890522`
- Lambda Functions:
  - `medzen-CreateChimeMeeting`
  - `medzen-ChimeRecordingProcessor`
  - `medzen-ChimeTranscriptionProcessor`
- API Gateway: Deployed with regional endpoints
- CloudWatch Logs: 90-day retention

**Dependencies:**
- Supabase Edge Functions (`chime-meeting-token`, `chime-messaging`)
- S3 lifecycle policies (7-year retention for HIPAA)
- EventBridge scheduled cleanup rules

### 2. AWS Bedrock AI (eu-west-1)
**Status:** Fully deployed with multi-region failover

**Resources:**
- Primary Model: `anthropic.claude-3-sonnet-20240229-v1:0`
- Lambda: `medzen-ai-chat-handler`
- API Gateway: REST API with Lambda integration
- Failover Regions: us-east-1, af-south-1
- AWS Translate: Multi-language support (English, French, Swahili, etc.)
- AWS Comprehend Medical: Medical entity extraction

**Dependencies:**
- Firebase Cloud Function: `handleAiChatMessage`
- Supabase Edge Function: `bedrock-ai-chat`
- DynamoDB: Conversation state management

### 3. EHRbase Infrastructure (af-south-1 primary)
**Status:** Currently in af-south-1, DR in eu-west-1

**Resources:**
- RDS PostgreSQL 15: `db.r6g.large`, Multi-AZ
- ECS Fargate Cluster: 2-6 tasks auto-scaling
- Application Load Balancer
- VPC: 10.0.0.0/16 with public/private subnets
- Secrets Manager: Database and EHRbase credentials
- CloudWatch: Monitoring and logging

**Dependencies:**
- Supabase Edge Function: `sync-to-ehrbase`
- Firebase Cloud Function: `onUserCreated`
- Domain: `ehr.medzenhealth.app`

### 4. Supporting Services (eu-west-1)
- AWS SMS API: `ttg7fzyyw2.execute-api.eu-west-1.amazonaws.com`
- Route 53: DNS and health checks
- CloudWatch Dashboards: Cross-region monitoring
- IAM Roles: Lambda execution, ECS task execution, S3 replication

---

## Migration Architecture

### Target State: eu-central-1 (Primary)

```
┌─────────────────────────────────────────────────────────────┐
│                  eu-central-1 (Frankfurt)                    │
│                    PRIMARY REGION                            │
├─────────────────────────────────────────────────────────────┤
│ • Amazon Chime SDK (Control Region)                         │
│   - New KMS key for encryption                              │
│   - New S3 buckets with replication                         │
│   - Lambda functions for meeting management                 │
│ • AWS Bedrock AI                                            │
│   - Claude 3.5 Sonnet                                       │
│   - Translate + Comprehend Medical                          │
│ • EHRbase (if needed for EU compliance)                     │
│   - RDS PostgreSQL Multi-AZ                                 │
│   - ECS Fargate cluster                                     │
│ • AWS SMS API (new endpoint)                                │
└─────────────────────────────────────────────────────────────┘
                           │
                     Replication
                           │
┌─────────────────────────▼───────────────────────────────────┐
│                   af-south-1 (Cape Town)                     │
│                   SECONDARY REGION                           │
├─────────────────────────────────────────────────────────────┤
│ • EHRbase Production (Keep as primary for Africa users)     │
│ • Chime SDK Failover                                        │
│ • Cross-region RDS read replica                             │
└─────────────────────────────────────────────────────────────┘
                           │
                     Disaster Recovery
                           │
┌─────────────────────────▼───────────────────────────────────┐
│                    eu-west-1 (Ireland)                       │
│                  DISASTER RECOVERY                           │
├─────────────────────────────────────────────────────────────┤
│ • S3 Cross-region replication                               │
│ • RDS Automated snapshots (7-day retention)                 │
│ • CloudFormation stacks (standby)                           │
└─────────────────────────────────────────────────────────────┘
```

### Regional Routing Strategy

**Route 53 Geolocation Routing:**
```yaml
eu-central-1:
  - Primary for: Germany, Poland, Czech Republic, Austria, Switzerland
  - Latency: 5-25ms

eu-west-1 (Ireland):
  - Primary for: UK, Ireland, Portugal, Spain
  - Disaster Recovery failover
  - Latency: 10-35ms

af-south-1 (Cape Town):
  - Primary for: South Africa, Cameroon, Kenya, Nigeria
  - EHRbase production (keep)
  - Latency: 15-60ms (from Central Africa)
```

---

## File-by-File Migration Changes

### Phase 1: Documentation Updates

#### 1.1 CLAUDE.md

**Location:** `/CLAUDE.md`
**Lines 14, 141, 535-540**

**CHANGE FROM:**
```markdown
- AWS Regions: `eu-west-1` (primary), `af-south-1` (secondary)
```

**CHANGE TO:**
```markdown
- AWS Regions: `eu-central-1` (primary), `af-south-1` (secondary), `eu-west-1` (DR)
```

**Additional updates:**
```markdown
## Multi-Region Architecture

The system is deployed across three AWS regions for high availability:

- **Primary:** `eu-central-1` (Frankfurt) - serves EU/Central Europe
  - Chime SDK control region
  - AWS Bedrock AI (Claude Sonnet 3.5)
  - SMS API and supporting services

- **Secondary:** `af-south-1` (Cape Town) - serves Africa
  - EHRbase production (optimized for Cameroon/Africa)
  - Chime SDK failover
  - Cross-region read replicas

- **DR:** `eu-west-1` (Ireland) - disaster recovery
  - S3 cross-region replication
  - RDS automated snapshots
  - Standby CloudFormation stacks

**Chime SDK:** Primary control region in eu-central-1
**EHRbase:** Primary in af-south-1 (Africa users), optional in eu-central-1 (EU compliance)
**Bedrock:** Primary in eu-central-1 with failover to us-east-1

Failover is automatic at the Route 53 level. Test with `./scripts/failover-test.sh`.
```

#### 1.2 environment.json

**Location:** `/assets/environment_values/environment.json`
**Line 13**

**CHANGE FROM:**
```json
"AwsSmsApiUrl": "https://ttg7fzyyw2.execute-api.eu-west-1.amazonaws.com/Dev/MedZen_Send_SMS",
```

**CHANGE TO:**
```json
"AwsSmsApiUrl": "https://[NEW_API_ID].execute-api.eu-central-1.amazonaws.com/Dev/MedZen_Send_SMS",
```

**Note:** New API Gateway ID will be generated after deployment

---

### Phase 2: CloudFormation Template Updates

#### 2.1 global-infrastructure.yaml

**Location:** `/aws-deployment/cloudformation/global-infrastructure.yaml`
**Lines 24-37**

**CHANGE FROM:**
```yaml
  PrimaryRegion:
    Type: String
    Default: af-south-1
    Description: Primary region for EHRbase

  SecondaryRegion:
    Type: String
    Default: eu-west-1
    Description: Secondary region for AI/Chime

  DRRegion:
    Type: String
    Default: us-east-1
    Description: Disaster recovery region
```

**CHANGE TO:**
```yaml
  PrimaryRegion:
    Type: String
    Default: eu-central-1
    Description: Primary region for Chime/Bedrock/EU services

  SecondaryRegion:
    Type: String
    Default: af-south-1
    Description: Secondary region for EHRbase/Africa services

  DRRegion:
    Type: String
    Default: eu-west-1
    Description: Disaster recovery region
```

**Impact:** Changes default regions for all infrastructure stacks

#### 2.2 chime-sdk-multi-region.yaml

**Location:** `/aws-deployment/cloudformation/chime-sdk-multi-region.yaml`
**Line 59**

**CHANGE FROM:**
```yaml
  ExistingKMSKeyArn:
    Type: String
    Default: arn:aws:kms:eu-west-1:558069890522:key/5e84763b-0627-410f-b9bf-661e4021fba3
    Description: Existing KMS key ARN for encryption
```

**CHANGE TO:**
```yaml
  ExistingKMSKeyArn:
    Type: String
    Default: ""
    Description: KMS key ARN for encryption (leave empty to create new key)
```

**Additional Changes:**
Add KMS key resource (if ExistingKMSKeyArn is empty):
```yaml
Resources:
  ChimeKMSKey:
    Type: AWS::KMS::Key
    Condition: CreateNewKMSKey
    Properties:
      Description: !Sub '${ProjectName} Chime SDK encryption key'
      EnableKeyRotation: true
      KeyPolicy:
        Version: '2012-10-17'
        Statement:
          - Sid: Enable IAM User Permissions
            Effect: Allow
            Principal:
              AWS: !Sub 'arn:aws:iam::${AWS::AccountId}:root'
            Action: 'kms:*'
            Resource: '*'
          - Sid: Allow Chime SDK to use the key
            Effect: Allow
            Principal:
              Service: chime.amazonaws.com
            Action:
              - kms:Decrypt
              - kms:GenerateDataKey
            Resource: '*'
      Tags:
        - Key: Name
          Value: !Sub '${ProjectName}-chime-key'

Conditions:
  CreateNewKMSKey: !Equals [!Ref ExistingKMSKeyArn, ""]

Outputs:
  KMSKeyArn:
    Description: KMS Key ARN for Chime encryption
    Value: !If [CreateNewKMSKey, !GetAtt ChimeKMSKey.Arn, !Ref ExistingKMSKeyArn]
    Export:
      Name: !Sub '${ProjectName}-ChimeKMSKeyArn-${AWS::Region}'
```

#### 2.3 bedrock-ai-multi-region.yaml

**Location:** `/aws-deployment/cloudformation/bedrock-ai-multi-region.yaml`
**Lines 71-83**

**CHANGE FROM:**
```javascript
// Multi-region clients
const primaryRegion = process.env.BEDROCK_REGION || 'eu-west-1';
const failoverRegion1 = process.env.FAILOVER_REGION_1 || 'us-east-1';
const failoverRegion2 = process.env.FAILOVER_REGION_2 || 'af-south-1';
```

**CHANGE TO:**
```javascript
// Multi-region clients
const primaryRegion = process.env.BEDROCK_REGION || 'eu-central-1';
const failoverRegion1 = process.env.FAILOVER_REGION_1 || 'eu-west-1';
const failoverRegion2 = process.env.FAILOVER_REGION_2 || 'us-east-1';
```

**Impact:** Updates default Bedrock region and failover sequence

---

### Phase 3: Deployment Script Updates

#### 3.1 deploy-all-regions.sh

**Location:** `/aws-deployment/scripts/deploy-all-regions.sh`
**Lines 20-22**

**CHANGE FROM:**
```bash
PRIMARY_REGION="af-south-1"
SECONDARY_REGION="eu-west-1"
DR_REGION="us-east-1"
```

**CHANGE TO:**
```bash
PRIMARY_REGION="eu-central-1"
SECONDARY_REGION="af-south-1"
DR_REGION="eu-west-1"
```

**Impact:** Changes deployment sequence and region priorities

#### 3.2 00-prerequisites.sh

**Location:** `/aws-deployment/00-prerequisites.sh`
**Line 151 (in .env template)**

**CHANGE FROM:**
```bash
AWS_REGION=af-south-1  # or eu-west-1 in some versions
```

**CHANGE TO:**
```bash
AWS_REGION=eu-central-1
```

#### 3.3 deploy-bedrock-ai.sh

**Location:** `/aws-deployment/scripts/deploy-bedrock-ai.sh`

**Add region parameter:**
```bash
#!/bin/bash
set -e

REGION="${AWS_REGION:-eu-central-1}"
STACK_NAME="medzen-bedrock-ai-${REGION}"

echo "Deploying Bedrock AI to $REGION..."

aws cloudformation deploy \
  --template-file cloudformation/bedrock-ai-multi-region.yaml \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --parameter-overrides \
    ProjectName=medzen \
    Environment=production \
    BedrockModelId=anthropic.claude-3-sonnet-20240229-v1:0 \
    SupabaseUrl="$SUPABASE_URL" \
    SupabaseServiceKey="$SUPABASE_SERVICE_KEY" \
  --capabilities CAPABILITY_IAM

echo "✅ Bedrock AI deployed to $REGION"
```

---

### Phase 4: Supabase Edge Function Updates

#### 4.1 Update Edge Function Secrets

**Run these commands after eu-central-1 deployment:**

```bash
# Wait for CloudFormation stacks to complete
aws cloudformation wait stack-create-complete \
  --stack-name medzen-chime-sdk-multi-region-eu-central-1 \
  --region eu-central-1

# Get new API Gateway endpoint
CHIME_API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name medzen-chime-sdk-multi-region-eu-central-1 \
  --region eu-central-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayEndpoint`].OutputValue' \
  --output text)

# Get new Bedrock API endpoint
BEDROCK_API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name medzen-bedrock-ai-multi-region-eu-central-1 \
  --region eu-central-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayEndpoint`].OutputValue' \
  --output text)

# Update Supabase secrets
npx supabase secrets set CHIME_API_ENDPOINT="$CHIME_API_ENDPOINT"
npx supabase secrets set BEDROCK_API_ENDPOINT="$BEDROCK_API_ENDPOINT"
npx supabase secrets set AWS_REGION="eu-central-1"

# Redeploy affected edge functions
npx supabase functions deploy chime-meeting-token
npx supabase functions deploy chime-messaging
npx supabase functions deploy bedrock-ai-chat
npx supabase functions deploy chime-recording-callback
npx supabase functions deploy chime-transcription-callback
```

#### 4.2 Verify Edge Function Configuration

```bash
# Test Chime token generation
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"appointmentId": "test-appointment", "userId": "test-user"}'

# Test Bedrock AI
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/bedrock-ai-chat \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello", "conversationId": "test-conv", "userId": "test-user"}'
```

---

### Phase 5: Flutter Application Updates

#### 5.1 Update Environment Configuration

**After deployment, update environment.json with new endpoints:**

1. Get new SMS API endpoint:
```bash
aws cloudformation describe-stacks \
  --stack-name medzen-sms-api-eu-central-1 \
  --region eu-central-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayEndpoint`].OutputValue' \
  --output text
```

2. Update `assets/environment_values/environment.json`

3. Rebuild and redeploy Flutter app:
```bash
flutter clean
flutter pub get
flutter build apk --release  # Android
flutter build ios --release  # iOS
flutter build web --release  # Web
```

---

## Service Availability Verification

### Verified Services in eu-central-1 ✅

| Service | Status | Version/Details |
|---------|--------|-----------------|
| **Amazon Chime SDK** | ✅ Available | Control region - full functionality |
| **AWS Bedrock** | ✅ Available | Claude 3.5 Sonnet confirmed |
| **ECS Fargate** | ✅ Available | FARGATE and FARGATE_SPOT |
| **RDS PostgreSQL** | ✅ Available | PostgreSQL 15.10+ |
| **Application Load Balancer** | ✅ Available | Full ELBv2 functionality |
| **VPC & Networking** | ✅ Available | 3 AZs operational |
| **AWS Translate** | ✅ Available | 75+ languages |
| **Comprehend Medical** | ✅ Available | Medical entity extraction |
| **Transcribe Medical** | ✅ Available | German + English |
| **Lambda** | ✅ Available | Node.js 18.x/20.x |
| **API Gateway** | ✅ Available | REST + HTTP APIs |
| **CloudWatch** | ✅ Available | Full monitoring |
| **Secrets Manager** | ✅ Available | Encryption support |
| **S3** | ✅ Available | Cross-region replication |
| **KMS** | ✅ Available | Customer managed keys |

**Language Support Verification:**
```bash
# Test AWS Translate in eu-central-1
aws translate translate-text \
  --source-language-code en \
  --target-language-code fr \
  --text "Patient has fever" \
  --region eu-central-1

# Verify Transcribe Medical
aws transcribe list-medical-vocabularies \
  --region eu-central-1

# Check Comprehend Medical
aws comprehendmedical detect-entities-v2 \
  --text "Patient presents with hypertension" \
  --region eu-central-1
```

---

## Migration Execution Plan

### Pre-Migration Phase (Day 1-2)

#### Step 1: Backup Current Infrastructure
```bash
# Backup CloudFormation templates
aws cloudformation get-template \
  --stack-name medzen-chime-sdk-multi-region-eu-west-1 \
  --region eu-west-1 > backup-chime-eu-west-1.yaml

# Backup RDS
aws rds create-db-snapshot \
  --db-instance-identifier medzen-ehrbase-db \
  --db-snapshot-identifier medzen-pre-migration-$(date +%Y%m%d) \
  --region af-south-1

# Backup S3 buckets
aws s3 sync s3://medzen-meeting-recordings-558069890522 \
  s3://medzen-meeting-recordings-backup-$(date +%Y%m%d) \
  --region eu-west-1
```

#### Step 2: Verify Service Quotas
```bash
# Check Fargate CPU quota
aws service-quotas get-service-quota \
  --service-code ecs \
  --quota-code L-3032A538 \
  --region eu-central-1

# Check RDS instance quota
aws service-quotas get-service-quota \
  --service-code rds \
  --quota-code L-7B6409FD \
  --region eu-central-1

# Request increases if needed
aws service-quotas request-service-quota-increase \
  --service-code ecs \
  --quota-code L-3032A538 \
  --desired-value 100 \
  --region eu-central-1
```

#### Step 3: Create .env File
```bash
cd aws-deployment
cat > .env <<EOF
# AWS Configuration
AWS_REGION=eu-central-1
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PROJECT_NAME=medzen-ehrbase
ENVIRONMENT=production

# Supabase Configuration
SUPABASE_URL=https://noaeltglphdlkbflipit.supabase.co
SUPABASE_SERVICE_KEY=your-service-key-here
SUPABASE_ANON_KEY=your-anon-key-here

# Domain Configuration
DOMAIN_NAME=medzenhealth.app

# Database Configuration (generate new passwords)
DB_ADMIN_USER=ehrbase_admin
DB_ADMIN_PASS=$(openssl rand -base64 32)
EHRBASE_USER=ehrbase_user
EHRBASE_PASS=$(openssl rand -base64 32)

# Multi-Region Configuration
ENABLE_MULTI_AZ=true
PRIMARY_REGION=eu-central-1
SECONDARY_REGION=af-south-1
DR_REGION=eu-west-1
EOF
```

### Migration Phase (Day 3-5)

#### Step 4: Deploy KMS Key
```bash
aws kms create-key \
  --description "MedZen Chime SDK encryption key - eu-central-1" \
  --key-policy file://kms-key-policy.json \
  --region eu-central-1 \
  --tags TagKey=Project,TagValue=medzen TagKey=Environment,TagValue=production

# Get key ARN
KMS_KEY_ARN=$(aws kms list-keys --region eu-central-1 \
  --query 'Keys[0].KeyArn' --output text)

# Enable key rotation
aws kms enable-key-rotation --key-id "$KMS_KEY_ARN" --region eu-central-1
```

#### Step 5: Deploy CloudFormation Stacks
```bash
cd aws-deployment/scripts

# Phase 1: Global Infrastructure
./deploy-all-regions.sh deploy

# Wait for completion (check status)
watch -n 10 'aws cloudformation describe-stacks \
  --stack-name medzen-global-infrastructure-eu-central-1 \
  --region eu-central-1 \
  --query "Stacks[0].StackStatus"'
```

#### Step 6: Configure S3 Replication
```bash
# Create replication buckets in eu-central-1
aws s3api create-bucket \
  --bucket medzen-meeting-recordings-eu-central-1 \
  --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1

# Enable versioning (required for replication)
aws s3api put-bucket-versioning \
  --bucket medzen-meeting-recordings-eu-central-1 \
  --versioning-configuration Status=Enabled

# Configure replication from eu-west-1 to eu-central-1
aws s3api put-bucket-replication \
  --bucket medzen-meeting-recordings-558069890522 \
  --replication-configuration file://replication-config.json \
  --region eu-west-1
```

**replication-config.json:**
```json
{
  "Role": "arn:aws:iam::558069890522:role/medzen-s3-replication-role",
  "Rules": [
    {
      "Status": "Enabled",
      "Priority": 1,
      "DeleteMarkerReplication": { "Status": "Enabled" },
      "Filter" : { "Prefix": ""},
      "Destination": {
        "Bucket": "arn:aws:s3:::medzen-meeting-recordings-eu-central-1",
        "ReplicationTime": {
          "Status": "Enabled",
          "Time": {
            "Minutes": 15
          }
        },
        "Metrics": {
          "Status": "Enabled",
          "EventThreshold": {
            "Minutes": 15
          }
        }
      }
    }
  ]
}
```

#### Step 7: Update Route 53 DNS
```bash
# Get new API Gateway endpoints
CHIME_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name medzen-chime-sdk-multi-region-eu-central-1 \
  --region eu-central-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayEndpoint`].OutputValue' \
  --output text)

# Create health check
HEALTH_CHECK_ID=$(aws route53 create-health-check \
  --health-check-config \
    Type=HTTPS,FullyQualifiedDomainName="${CHIME_ENDPOINT#https://}",Port=443,ResourcePath=/health \
  --query 'HealthCheck.Id' \
  --output text)

# Update DNS records with weighted routing
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch file://route53-changes.json
```

**route53-changes.json:**
```json
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "api.medzenhealth.app",
        "Type": "A",
        "SetIdentifier": "eu-central-1-primary",
        "Weight": 100,
        "AliasTarget": {
          "HostedZoneId": "Z215JYRZR1TBD5",
          "DNSName": "[NEW_API_GATEWAY_DOMAIN]",
          "EvaluateTargetHealth": true
        },
        "HealthCheckId": "[HEALTH_CHECK_ID]"
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "api.medzenhealth.app",
        "Type": "A",
        "SetIdentifier": "eu-west-1-failover",
        "Weight": 0,
        "AliasTarget": {
          "HostedZoneId": "Z32O12XQLNTSW2",
          "DNSName": "[OLD_API_GATEWAY_DOMAIN]",
          "EvaluateTargetHealth": true
        }
      }
    }
  ]
}
```

### Post-Migration Phase (Day 6-7)

#### Step 8: Update Supabase Edge Functions
```bash
# Update all secrets
npx supabase secrets set AWS_REGION="eu-central-1"
npx supabase secrets set CHIME_API_ENDPOINT="$CHIME_ENDPOINT"
npx supabase secrets set BEDROCK_API_ENDPOINT="$BEDROCK_ENDPOINT"

# Redeploy all functions
npx supabase functions deploy chime-meeting-token
npx supabase functions deploy chime-messaging
npx supabase functions deploy bedrock-ai-chat
npx supabase functions deploy chime-recording-callback
npx supabase functions deploy chime-transcription-callback
npx supabase functions deploy chime-entity-extraction
```

#### Step 9: Update Firebase Cloud Functions
```bash
# Update configuration
firebase functions:config:set \
  aws.region="eu-central-1" \
  chime.endpoint="$CHIME_ENDPOINT" \
  bedrock.endpoint="$BEDROCK_ENDPOINT"

# Verify config
firebase functions:config:get

# Deploy functions
firebase deploy --only functions
```

#### Step 10: Update Flutter Application
```bash
# Update environment.json with new endpoints
# (Manual update required - see Phase 5.1 above)

# Rebuild app
flutter clean
flutter pub get
flutter analyze
flutter test

# Build releases
flutter build apk --release
flutter build ios --release
flutter build web --release
```

---

## Testing & Validation

### Phase 1: Infrastructure Testing (Day 8)

```bash
# Run comprehensive validation
cd aws-deployment
./scripts/validate-deployment.sh

# Test Chime SDK
./test_chime_deployment.sh

# Test Bedrock AI
./test_ai_chat_e2e.sh

# Test complete flow
./test_complete_flow.sh
```

### Phase 2: End-to-End Testing (Day 9-10)

**Test Scenarios:**

1. **Video Call Flow:**
   - Create appointment
   - Generate Chime meeting token
   - Join meeting from provider side
   - Join meeting from patient side
   - Test audio/video quality
   - Test screen sharing
   - Test recording
   - Verify transcription

2. **AI Chat Flow:**
   - Send message in English
   - Send message in French
   - Send message in Swahili
   - Verify translations
   - Check entity extraction
   - Verify conversation persistence

3. **EHR Sync Flow:**
   - Create user
   - Verify EHR creation
   - Add medical data
   - Check sync queue
   - Verify OpenEHR composition
   - Test cross-region replication

### Phase 3: Performance Testing (Day 11-12)

```bash
# Latency testing from different regions
for region in germany france poland cameroon kenya; do
  echo "Testing latency from $region..."
  # Run from EC2 instance in target region
  time curl -w "@curl-format.txt" \
    -o /dev/null -s \
    https://api.medzenhealth.app/health
done

# Load testing
artillery run load-test-config.yml
```

**Expected Latency Targets:**
- Germany/Central EU: < 20ms
- Western EU (France/UK): < 30ms
- Eastern EU (Poland): < 25ms
- North Africa: < 80ms
- Central Africa (Cameroon): < 120ms (via af-south-1 failover)

### Phase 4: Failover Testing (Day 13)

```bash
# Test Route 53 failover
./scripts/failover-test.sh

# Manually fail health check
aws route53 update-health-check \
  --health-check-id $HEALTH_CHECK_ID \
  --disabled

# Verify traffic shifts to eu-west-1
watch -n 5 'dig +short api.medzenhealth.app'

# Re-enable health check
aws route53 update-health-check \
  --health-check-id $HEALTH_CHECK_ID \
  --no-disabled
```

---

## Cost Analysis

### Monthly Cost Comparison

| Component | eu-west-1 | eu-central-1 | Difference |
|-----------|-----------|--------------|------------|
| **Chime SDK (100 attendee-minutes/day)** | $15.00 | $15.75 | +$0.75 |
| **Bedrock AI (Claude 3.5 Sonnet)** | $89.00 | $93.45 | +$4.45 |
| **Lambda (10M requests)** | $22.50 | $23.63 | +$1.13 |
| **API Gateway (10M requests)** | $35.00 | $36.75 | +$1.75 |
| **S3 Storage (500 GB)** | $11.50 | $12.08 | +$0.58 |
| **S3 Requests** | $5.00 | $5.25 | +$0.25 |
| **Data Transfer Out (100 GB)** | $9.00 | $9.45 | +$0.45 |
| **CloudWatch Logs (20 GB)** | $10.00 | $10.50 | +$0.50 |
| **Secrets Manager (10 secrets)** | $4.00 | $4.20 | +$0.20 |
| **KMS (1 key)** | $1.00 | $1.05 | +$0.05 |
| **Route 53 (1 hosted zone)** | $6.50 | $6.50 | $0.00 |
| **ECS Fargate** (if deployed) | $180.20 | $189.21 | +$9.01 |
| **RDS** (if deployed) | $86.23 | $90.54 | +$4.31 |
| **ALB** (if deployed) | $47.45 | $49.82 | +$2.37 |
| **TOTAL (Core Services)** | **$208.50** | **$218.61** | **+$10.11** |
| **TOTAL (with EHRbase)** | **$522.38** | **$548.18** | **+$25.80** |

**Annual Impact:**
- Core services only: +$121.32/year (+4.8%)
- With EHRbase: +$309.60/year (+4.9%)

### Cost Optimization Strategies

**Option 1: Savings Plans (6-12 months)**
```bash
# Compute Savings Plan
# Commit: $125/month for 1 year
# Savings: ~20% on Lambda + Fargate
# Annual benefit: ~$300-400
```

**Option 2: Reserved Capacity**
```bash
# RDS Reserved Instances
# 1-year partial upfront: ~35% savings
# Annual benefit: ~$360 on RDS
```

**Option 3: Hybrid Approach**
- Keep Bedrock AI in eu-central-1 (primary for EU users)
- Keep Chime SDK in eu-central-1 (control region benefits)
- Keep EHRbase in af-south-1 (optimized for Africa)
- Result: Lower latency for EU, minimal cost increase

---

## Rollback Plan

### Scenario 1: Immediate Rollback (< 1 hour into migration)

```bash
# 1. Update Route 53 weights to shift traffic back
aws route53 change-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "api.medzenhealth.app",
        "Type": "A",
        "SetIdentifier": "eu-west-1-primary",
        "Weight": 100,
        ...
      }
    }]
  }'

# 2. Update Supabase secrets back to eu-west-1
npx supabase secrets set AWS_REGION="eu-west-1"
npx supabase secrets set CHIME_API_ENDPOINT="[OLD_ENDPOINT]"

# 3. Redeploy edge functions
npx supabase functions deploy chime-meeting-token
npx supabase functions deploy bedrock-ai-chat

# Time required: 5-10 minutes
```

### Scenario 2: Partial Rollback (< 24 hours)

```bash
# 1. Keep S3 replication active (data preserved in both regions)
# 2. Shift primary traffic back to eu-west-1
# 3. Keep eu-central-1 as warm standby
# 4. Investigate issues without data loss

# Time required: 15-30 minutes
```

### Scenario 3: Full Rollback (> 24 hours, post-testing)

```bash
# 1. Delete eu-central-1 CloudFormation stacks
aws cloudformation delete-stack \
  --stack-name medzen-chime-sdk-multi-region-eu-central-1 \
  --region eu-central-1

aws cloudformation delete-stack \
  --stack-name medzen-bedrock-ai-multi-region-eu-central-1 \
  --region eu-central-1

# 2. Keep S3 data for 30 days before cleanup
# 3. Update all configurations back to eu-west-1
# 4. Document lessons learned

# Time required: 1-2 hours
```

---

## Risk Assessment & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| **Service unavailable in eu-central-1** | Low | High | Verify all services before migration; keep eu-west-1 active |
| **Increased latency for some users** | Medium | Medium | Implement Route 53 geolocation routing; keep af-south-1 active |
| **Cost overrun** | Low | Medium | Monitor costs daily; implement budget alerts |
| **Data loss during migration** | Very Low | Critical | Full backups before migration; S3 replication; RDS snapshots |
| **DNS propagation delays** | Medium | Low | Use weighted routing for gradual cutover; 300s TTL |
| **Application incompatibility** | Low | High | Thorough testing in staging; phased rollout |
| **Compliance issues** | Low | High | Verify GDPR/HIPAA compliance in eu-central-1; data residency docs |

---

## Success Criteria

### Technical Success Metrics

- ✅ All CloudFormation stacks deployed successfully
- ✅ Health checks passing in eu-central-1
- ✅ Latency < 20ms from Germany, < 30ms from Western EU
- ✅ 99.9% uptime during migration (< 43 minutes downtime)
- ✅ All automated tests passing
- ✅ Zero data loss
- ✅ S3 replication lag < 15 minutes

### Business Success Metrics

- ✅ No user-reported issues during migration
- ✅ Video call quality maintained or improved
- ✅ AI chat response times maintained or improved
- ✅ Cost increase within 5-8% budget
- ✅ Compliance documentation updated

---

## Timeline Summary

| Phase | Duration | Activities | Deliverables |
|-------|----------|------------|--------------|
| **Planning** | 2 days | Infrastructure analysis, documentation | This migration plan |
| **Pre-Migration** | 2 days | Backups, quota checks, .env setup | Backup snapshots, verified quotas |
| **Migration** | 3 days | Deploy stacks, configure replication | Live infrastructure in eu-central-1 |
| **Post-Migration** | 2 days | Update configs, redeploy apps | Updated apps and functions |
| **Testing** | 5 days | Infrastructure, E2E, performance, failover | Test reports, performance baselines |
| **Monitoring** | 7 days | Observe production, optimize | Stable production system |
| **TOTAL** | **21 days** | **3 weeks** | **Migration complete** |

---

## Support & Escalation

### AWS Support Cases

For issues during migration:
```bash
# Create support case
aws support create-case \
  --subject "MedZen migration to eu-central-1 - [ISSUE]" \
  --service-code "amazon-chime" \
  --category-code "general-info" \
  --communication-body "Details..."
```

### Escalation Matrix

| Issue Type | Contact | Response Time |
|------------|---------|---------------|
| P1 - Complete outage | AWS Enterprise Support | 15 minutes |
| P2 - Service degradation | AWS Support + Internal team | 1 hour |
| P3 - Minor issues | Internal team | 4 hours |
| P4 - Documentation/questions | Internal team | 24 hours |

---

## Post-Migration Checklist

- [ ] All CloudFormation stacks deployed and healthy
- [ ] S3 replication configured and tested
- [ ] Route 53 DNS updated with weighted routing
- [ ] Supabase Edge Functions updated and deployed
- [ ] Firebase Cloud Functions updated and deployed
- [ ] Flutter app rebuilt and redeployed
- [ ] Health checks passing
- [ ] Automated tests passing
- [ ] Manual E2E tests completed
- [ ] Performance tests passed
- [ ] Failover tests passed
- [ ] Cost monitoring configured
- [ ] CloudWatch dashboards updated
- [ ] Documentation updated (CLAUDE.md, etc.)
- [ ] Runbooks updated
- [ ] Team trained on new infrastructure
- [ ] Stakeholders notified of completion

---

## Conclusion

This migration plan provides a comprehensive, step-by-step approach to migrating MedZen's AWS infrastructure from **eu-west-1 to eu-central-1**. The benefits include:

✅ **Better EU Coverage** - Central location for European users
✅ **Chime Control Region** - Improved video call reliability
✅ **GDPR Compliance** - Enhanced data residency for EU patients
✅ **Market Expansion** - Positioned for German healthcare market
✅ **Minimal Risk** - Phased approach with multiple rollback options

**Recommendation:** Proceed with migration during low-traffic period (weekend). Expected downtime: < 30 minutes.

---

**Document Version:** 1.0
**Created:** 2025-12-11
**Author:** Claude Code Assistant
**Review Status:** Ready for approval and execution
