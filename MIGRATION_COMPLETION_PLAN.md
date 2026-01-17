# MedZen AWS Migration Completion Plan

## Executive Summary

This document outlines the final steps to complete MedZen's AWS multi-region migration strategy, including real-time medical scribing, health endpoint fixes, and infrastructure consolidation.

## Current Status (December 2025)

### ✅ Already Migrated/Deployed

1. **Chime SDK → eu-central-1 (Primary)**
   - Status: ✅ Deployed and operational
   - API Endpoint: `https://156da6e3xb.execute-api.eu-central-1.amazonaws.com`
   - Lambda Functions: 5 (meeting-manager, recording-handler, transcription-processor, messaging-handler, polly-tts)
   - DynamoDB: medzen-meeting-audit
   - S3 Buckets: Shared across regions (eu-west-1)

2. **Bedrock AI → eu-central-1**
   - Status: ✅ Already deployed (December 2025)
   - Model: `eu.amazon.nova-pro-v1:0` (EU inference profile)
   - Stack: `medzen-bedrock-ai-eu-central-1`
   - Region: eu-central-1
   - **NO MIGRATION NEEDED** - Already in target region

3. **Post-Recording Transcription**
   - Status: ✅ Fully operational
   - Multi-language support: 100+ languages
   - Medical entity extraction: AWS Comprehend Medical
   - Custom vocabularies: Medical terms, African languages, Pidgin, Camfranglais

### ⚠️ Pending Fixes & Enhancements

1. **Real-Time Medical Scribing**
   - Status: ⚠️ Implementation plan created
   - File: `REAL_TIME_SCRIBING_IMPLEMENTATION.md`
   - Impact: Enables live captions during video calls
   - Effort: 2-3 hours implementation

2. **Health Endpoint Fix**
   - Status: ✅ Fixed in CloudFormation template
   - Issue: `/health` was routing to MeetingManager Lambda (wrong handler)
   - Solution: Created dedicated `HealthCheckLambda` function
   - Needs: Deployment to eu-central-1

3. **EHRbase Migration to EU**
   - Status: ⚠️ Optional - Currently in af-south-1
   - Reason: EU data residency compliance (GDPR)
   - Decision: Evaluate business requirements
   - Complexity: High (requires database migration)

4. **Decommission eu-west-1 Chime Stack**
   - Status: ⚠️ Legacy stack still running
   - Stack: `medzen-chime-sdk-eu-west-1`
   - Cost: ~$50-100/month (idle resources)
   - Risk: Low (traffic already routed to eu-central-1)

## Implementation Phases

### Phase 1: Deploy Health Endpoint Fix (30 minutes)

**Priority**: HIGH - Production issue fix

**Steps**:
```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/aws-deployment

# Deploy updated Chime SDK stack to eu-central-1
aws cloudformation deploy \
  --template-file cloudformation/chime-sdk-multi-region.yaml \
  --stack-name medzen-chime-sdk-eu-central-1 \
  --region eu-central-1 \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ProjectName=medzen \
    Environment=production \
    LambdaMemory=1024 \
    SupabaseUrl=https://noaeltglphdlkbflipit.supabase.co \
    SupabaseServiceKey=$SUPABASE_SERVICE_KEY \
    ExistingRecordingsBucket=medzen-meeting-recordings-558069890522 \
    ExistingTranscriptsBucket=medzen-meeting-transcripts-558069890522 \
    ExistingMedicalDataBucket=medzen-medical-data-558069890522 \
    ExistingKMSKeyArn=arn:aws:kms:eu-central-1:558069890522:key/1ebd1f17-d0ba-4cc2-bec3-eebf582f5939

# Test health endpoint
curl https://156da6e3xb.execute-api.eu-central-1.amazonaws.com/health
```

**Expected Output**:
```json
{
  "status": "healthy",
  "timestamp": "2025-12-11T...",
  "region": "eu-central-1",
  "service": "medzen-chime-sdk",
  "version": "1.0.0",
  "components": {
    "api": "healthy",
    "lambda": "healthy",
    "dynamodb": "healthy"
  }
}
```

**Rollback**: CloudFormation automatic rollback on failure

---

### Phase 2: Implement Real-Time Medical Scribing (2-3 hours)

**Priority**: MEDIUM - Feature enhancement

**Prerequisites**:
- Health endpoint deployed and verified
- Development environment set up
- Flutter dependencies up to date

**Steps**:

1. **Update Chime SDK Widget** (1 hour)
   ```bash
   # Implementation details in REAL_TIME_SCRIBING_IMPLEMENTATION.md
   # Modify lib/custom_code/widgets/chime_meeting_webview.dart
   # Add live transcription JavaScript code
   # Add UI overlay for captions
   ```

2. **Database Schema Updates** (30 minutes)
   ```sql
   -- Run migration
   npx supabase db push

   -- Or manually apply:
   ALTER TABLE video_call_sessions ADD COLUMN IF NOT EXISTS
     live_transcription_enabled BOOLEAN DEFAULT false,
     live_transcript_language VARCHAR(10),
     live_transcript_segments JSONB DEFAULT '[]'::jsonb;
   ```

3. **Update Supabase Edge Function** (30 minutes)
   ```bash
   # Update chime-meeting-token/index.ts to include transcription config
   npx supabase functions deploy chime-meeting-token
   ```

4. **Testing** (30 minutes)
   - Test in development environment
   - Create test appointment
   - Enable live captions
   - Verify transcription accuracy
   - Check database storage

**Success Criteria**:
- ✅ Live captions appear within 2 seconds of speech
- ✅ Captions display in correct language
- ✅ Toggle captions on/off works
- ✅ Transcript segments stored in database
- ✅ No impact on video/audio quality

---

### Phase 3: Verify Bedrock AI (15 minutes)

**Priority**: LOW - Verification only (already migrated)

**Steps**:
```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/aws-deployment

# Check stack status
aws cloudformation describe-stacks \
  --stack-name medzen-bedrock-ai-eu-central-1 \
  --region eu-central-1 \
  --query 'Stacks[0].{Status:StackStatus,Outputs:Outputs}'

# Test AI endpoint
API_URL=$(aws cloudformation describe-stacks \
  --stack-name medzen-bedrock-ai-eu-central-1 \
  --region eu-central-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
  --output text)

curl -X POST "$API_URL/health" | jq .
```

**Verification**:
- ✅ Stack status: UPDATE_COMPLETE or CREATE_COMPLETE
- ✅ Model ID: `eu.amazon.nova-pro-v1:0`
- ✅ Region: eu-central-1
- ✅ Health endpoint returns 200 OK

**No Action Required** - Already in target region

---

### Phase 4: Decommission eu-west-1 Chime Stack (30 minutes)

**Priority**: LOW - Cost optimization

**Risk Assessment**:
- **Risk**: LOW - All traffic routed to eu-central-1
- **Impact**: Save ~$50-100/month
- **Rollback**: Re-deploy stack if needed (< 30 minutes)

**Pre-Decommission Checklist**:
```bash
# 1. Verify no active meetings in eu-west-1
aws cloudformation describe-stack-resources \
  --stack-name medzen-chime-sdk-eu-west-1 \
  --region eu-west-1 \
  --query 'StackResources[?ResourceType==`AWS::Lambda::Function`]'

# 2. Check CloudWatch metrics for traffic
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=medzen-meeting-manager \
  --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 86400 \
  --statistics Sum \
  --region eu-west-1

# 3. Update Supabase Edge Functions (if they reference eu-west-1)
# Check supabase/functions/chime-meeting-token/index.ts
grep -r "eu-west-1" supabase/functions/
```

**Decommission Steps**:
```bash
# If no traffic and all verifications pass:
aws cloudformation delete-stack \
  --stack-name medzen-chime-sdk-eu-west-1 \
  --region eu-west-1

# Monitor deletion
aws cloudformation wait stack-delete-complete \
  --stack-name medzen-chime-sdk-eu-west-1 \
  --region eu-west-1

echo "✅ eu-west-1 Chime stack decommissioned"
```

**Post-Decommission**:
- Update documentation to remove eu-west-1 references
- Update disaster recovery runbook
- Verify cost savings in AWS Cost Explorer (7-14 days)

---

### Phase 5: EHRbase EU Migration (OPTIONAL - 4-6 hours)

**Priority**: LOW - Optional compliance measure

**Current State**:
- Location: af-south-1 (Cape Town)
- Reason: Optimized for Cameroon/Africa traffic
- Service: EHRbase (OpenEHR health records)

**Business Decision Required**:
1. **Keep in af-south-1** (Recommended if primary users are in Africa)
   - ✅ Lower latency for African users
   - ✅ No migration risk
   - ✅ No downtime
   - ⚠️ Data stored outside EU

2. **Migrate to eu-central-1** (If EU data residency required)
   - ✅ EU data residency (GDPR compliance)
   - ⚠️ Higher latency for African users
   - ⚠️ Complex migration (database + historical data)
   - ⚠️ Risk of data loss during migration
   - ⏱️ 4-6 hours downtime

**If Migration Approved**:
```bash
# See: aws-deployment/EHRBASE_EU_MIGRATION_PLAN.md (to be created)
# High-level steps:
# 1. Provision RDS PostgreSQL in eu-central-1
# 2. Deploy EHRbase application stack
# 3. Create database snapshot in af-south-1
# 4. Restore snapshot to eu-central-1
# 5. Run data validation scripts
# 6. Update Supabase Edge Functions
# 7. Switch traffic to new endpoint
# 8. Decommission af-south-1 stack (after 30 days)
```

**Recommendation**: **Keep EHRbase in af-south-1** unless specific EU compliance requirements mandate migration.

---

## Updated Architecture Diagram

### After All Migrations Complete

```
┌─────────────────────────────────────────────────────────────┐
│                     MULTI-REGION ARCHITECTURE                │
│                          (Dec 2025)                          │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│   eu-central-1       │  PRIMARY REGION (Frankfurt)
│   (Frankfurt)        │
├──────────────────────┤
│ ✅ Chime SDK         │  Video calling control plane
│   - Meetings API     │  - Real-time transcription
│   - Messaging        │  - Live medical scribing
│   - Transcription    │  - Multi-language support
│   - Health endpoint  │  ← FIXED
│                      │
│ ✅ Bedrock AI        │  AI chat assistant
│   - Nova Pro v1:0    │  - Streaming responses
│   - EU inference     │  - Multi-language translation
│                      │
│ ⬜ EHRbase (Optional)│  OpenEHR health records
│   - If EU compliance │  - Database migration required
│     required         │
└──────────────────────┘

┌──────────────────────┐
│   af-south-1         │  AFRICA REGION (Cape Town)
│   (Cape Town)        │
├──────────────────────┤
│ ✅ EHRbase           │  OpenEHR health records
│   - Production DB    │  - Optimized for Africa
│   - Historical data  │  - Low latency for Cameroon
└──────────────────────┘

┌──────────────────────┐
│   eu-west-1          │  STORAGE REGION (Ireland)
│   (Ireland)          │
├──────────────────────┤
│ ✅ S3 Storage        │  Long-term storage
│   - Recordings       │  - 7-year HIPAA retention
│   - Transcripts      │  - Encrypted at rest
│   - Medical data     │
│                      │
│ ❌ Chime SDK         │  ← TO BE DECOMMISSIONED
│   (Legacy stack)     │
└──────────────────────┘

┌──────────────────────┐
│   Global Services    │
├──────────────────────┤
│ ✅ Firebase Auth     │  Authentication
│ ✅ Supabase          │  Database & real-time
│ ✅ Route 53          │  DNS & failover routing
│ ✅ CloudFront        │  CDN (if configured)
└──────────────────────┘
```

---

## Cost Impact Analysis

### Current Monthly Costs (Estimated)

| Service | Region | Monthly Cost | Notes |
|---------|--------|--------------|-------|
| Chime SDK | eu-central-1 | $200-500 | Based on meeting minutes |
| Chime SDK | eu-west-1 (legacy) | $50-100 | **Idle resources - TO REMOVE** |
| Bedrock AI | eu-central-1 | $150-300 | Based on message volume |
| EHRbase | af-south-1 | $100-200 | RDS + ECS Fargate |
| S3 Storage | eu-west-1 | $50-100 | 7-year retention |
| Transcribe | eu-central-1 | $100-200 | Post-recording batch |
| DynamoDB | eu-central-1 | $20-50 | Audit logs |
| **TOTAL** | | **$670-1,450/month** | |

### After Migration & Optimizations

| Service | Region | Monthly Cost | Savings |
|---------|--------|--------------|---------|
| Chime SDK | eu-central-1 | $200-500 | - |
| ~~Chime SDK~~ | ~~eu-west-1~~ | ~~$0~~ | **-$50-100** ✅ |
| Chime + Real-Time Transcribe | eu-central-1 | +$50-100 | New feature cost |
| Bedrock AI | eu-central-1 | $150-300 | - |
| EHRbase | af-south-1 | $100-200 | - |
| S3 Storage | eu-west-1 | $50-100 | - |
| DynamoDB | eu-central-1 | $20-50 | - |
| **TOTAL** | | **$570-1,250/month** | **$100-200/month savings** |

**Net Impact**:
- Cost savings: $100-200/month (-15%)
- New features: Real-time scribing (+$50-100/month)
- Infrastructure consolidation: Reduced complexity

---

## Testing & Validation

### Automated Test Suite

```bash
# Run comprehensive system tests
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# 1. Test Chime SDK health endpoint
./test_chime_deployment.sh

# 2. Test video call functionality
./test_chime_video_complete.sh

# 3. Test Bedrock AI
./test_ai_chat_e2e.sh

# 4. Test complete integration
./test_complete_flow.sh

# 5. Verify appointments data
./verify_appointment_data.sh
```

### Manual Verification Checklist

- [ ] Health endpoint responds with 200 OK
- [ ] Video calls initiate successfully
- [ ] Live captions display during calls
- [ ] Transcripts stored in database
- [ ] Medical entity extraction working
- [ ] AI chat responses streaming correctly
- [ ] No errors in CloudWatch logs
- [ ] Cost metrics within expected range

---

## Rollback Plans

### If Health Endpoint Fails
```bash
# Rollback to previous CloudFormation stack version
aws cloudformation update-stack \
  --stack-name medzen-chime-sdk-eu-central-1 \
  --region eu-central-1 \
  --use-previous-template \
  --parameters UsePreviousValue=true
```

### If Real-Time Scribing Causes Issues
```bash
# Disable via feature flag in code
# Fallback to existing post-recording transcription
# No infrastructure rollback needed
```

### If eu-west-1 Decommission Causes Problems
```bash
# Re-deploy eu-west-1 stack from template
aws cloudformation create-stack \
  --stack-name medzen-chime-sdk-eu-west-1 \
  --region eu-west-1 \
  --template-body file://cloudformation/chime-sdk-multi-region.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ... # Use previous parameter values
```

---

## Documentation Updates

After implementation, update:

1. **README.md** - Remove eu-west-1 references
2. **CLAUDE.md** - Update region information
3. **SYSTEM_INTEGRATION_STATUS.md** - Reflect current architecture
4. **CHIME_VIDEO_TESTING_GUIDE.md** - Add live captions testing
5. **PRODUCTION_DEPLOYMENT_GUIDE.md** - Update deployment procedures

---

## Success Criteria

### Phase 1 (Health Endpoint)
- ✅ GET /health returns 200 OK
- ✅ Response time < 100ms
- ✅ No Lambda errors in CloudWatch

### Phase 2 (Real-Time Scribing)
- ✅ Live captions display within 2 seconds
- ✅ 95%+ transcription accuracy (English)
- ✅ Support for 20+ languages
- ✅ Segments stored in database
- ✅ No impact on video quality

### Phase 3 (Bedrock Verification)
- ✅ Stack in eu-central-1
- ✅ Using EU inference profile
- ✅ Health endpoint operational

### Phase 4 (Decommission)
- ✅ eu-west-1 stack deleted
- ✅ No traffic to old endpoint
- ✅ Cost reduction verified

---

## Timeline

| Phase | Duration | Start | End | Status |
|-------|----------|-------|-----|--------|
| 1. Health Endpoint | 30 min | Now | +30min | ⬜ Ready to deploy |
| 2. Real-Time Scribing | 2-3 hrs | +30min | +4hrs | ⬜ Implementation needed |
| 3. Bedrock Verify | 15 min | +4hrs | +4.25hrs | ⬜ Verification only |
| 4. Decommission | 30 min | +4.25hrs | +5hrs | ⬜ After verification |
| 5. EHRbase (Optional) | 4-6 hrs | TBD | TBD | ⬜ Business decision |

**Total Estimated Time**: 3.75 - 5 hours (excluding optional EHRbase migration)

---

## Next Steps

1. **Review this plan** ✅ (You are here)
2. **Get approval for**:
   - Health endpoint deployment (recommended: immediate)
   - Real-time scribing implementation (recommended: yes)
   - eu-west-1 decommission (recommended: after 7 days verification)
   - EHRbase migration (recommended: no - keep in af-south-1)
3. **Execute Phase 1** (Health endpoint fix)
4. **Monitor and verify**
5. **Proceed with Phase 2** (Real-time scribing)
6. **Complete Phases 3-4** (Verification and cleanup)

---

## Questions & Decisions

### Decision 1: Real-Time Scribing
**Question**: Deploy real-time medical scribing now or later?

**Options**:
- A) Deploy with Phase 1 (adds 2-3 hours)
- B) Deploy separately in next sprint (allows more testing)

**Recommendation**: **Option B** - Deploy health fix immediately, test thoroughly, then add real-time scribing in controlled rollout.

---

### Decision 2: EHRbase Migration
**Question**: Migrate EHRbase to eu-central-1?

**Options**:
- A) Keep in af-south-1 (recommended)
  - ✅ Lower latency for African users
  - ✅ No migration risk
  - ⚠️ Data outside EU

- B) Migrate to eu-central-1
  - ✅ EU data residency
  - ⚠️ Higher latency for Africa
  - ⚠️ Complex migration
  - ⚠️ 4-6 hours downtime

**Recommendation**: **Option A** - Keep in af-south-1 unless specific compliance requirements mandate EU-only data residency.

---

### Decision 3: eu-west-1 Decommission
**Question**: When to decommission legacy Chime stack?

**Options**:
- A) Immediately after Phase 1 deployment
- B) After 7 days of monitoring
- C) After 30 days of zero traffic

**Recommendation**: **Option B** - Wait 7 days to verify zero traffic and no issues, then decommission.

---

## Support & Escalation

### If Issues Arise

1. **Check CloudWatch Logs**
   ```bash
   aws logs tail /aws/lambda/medzen-meeting-manager --follow --region eu-central-1
   ```

2. **Check CloudFormation Events**
   ```bash
   aws cloudformation describe-stack-events \
     --stack-name medzen-chime-sdk-eu-central-1 \
     --region eu-central-1 \
     --max-items 20
   ```

3. **Rollback if Critical**
   - Follow rollback plans above
   - Document issue for post-mortem

4. **Contact AWS Support**
   - Use AWS Console → Support Center
   - Reference stack names and error messages

---

## Appendix

### Related Documentation
- `REAL_TIME_SCRIBING_IMPLEMENTATION.md` - Detailed scribing implementation
- `aws-deployment/HEALTH_ENDPOINT_FIX.md` - Bedrock AI health endpoint reference
- `SYSTEM_INTEGRATION_STATUS.md` - Current architecture
- `aws-deployment/README.md` - Infrastructure overview

### CloudFormation Templates
- `aws-deployment/cloudformation/chime-sdk-multi-region.yaml` - Main Chime template
- `aws-deployment/cloudformation/bedrock-ai-multi-region.yaml` - Bedrock AI template
- `aws-deployment/cloudformation/global-infrastructure.yaml` - Shared resources

### Deployment Scripts
- `aws-deployment/scripts/deploy-all-regions.sh` - Multi-region deployment
- `aws-deployment/scripts/validate-deployment.sh` - Post-deployment validation
- `aws-deployment/scripts/failover-test.sh` - Disaster recovery test

---

**Document Version**: 1.0
**Last Updated**: December 11, 2025
**Author**: Claude (AI Assistant)
**Review Status**: ⬜ Pending approval
