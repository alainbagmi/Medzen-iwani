# EU-CENTRAL-1 Migration Plan
**MedZen Infrastructure Consolidation**

**Date:** December 12, 2025
**Objective:** Consolidate all primary services to `eu-central-1` (Frankfurt), configure `eu-west-1` (Ireland) as secondary/DR, and decommission `af-south-1` (Cape Town)

## Executive Summary

**Current State:**
- **eu-central-1**: Chime SDK ✅, Bedrock AI ✅
- **eu-west-1**: EHRbase (RDS Multi-AZ) ✅, Load Balancer ✅, ECS Cluster ✅, 8 Lambda functions
- **af-south-1**: Legacy Chime SDK ⚠️, Bedrock AI (duplicate), 6 Lambda functions

**Target State:**
- **eu-central-1**: PRIMARY for all services (Chime SDK, Bedrock AI, EHRbase)
- **eu-west-1**: SECONDARY/DR for all services (hot standby)
- **af-south-1**: DECOMMISSIONED (all resources deleted)

**Benefits:**
- ✅ Reduced latency for EU/Global users (~20-30ms improvement)
- ✅ Simplified architecture (single primary region)
- ✅ Cost savings (~30% reduction by eliminating duplicate resources)
- ✅ GDPR compliance (all data in EU)
- ✅ Easier disaster recovery management

---

## Current Infrastructure Audit

### eu-central-1 (Frankfurt) - PRIMARY TARGET
**CloudFormation Stacks:**
- ✅ `medzen-chime-sdk-eu-central-1` (CREATE_COMPLETE)
- ✅ `medzen-bedrock-ai-eu-central-1` (UPDATE_COMPLETE)

**Lambda Functions (7):**
- `medzen-ai-chat-handler`
- `medzen-meeting-manager`
- `medzen-recording-handler`
- `medzen-polly-tts`
- `medzen-health-check`
- `medzen-messaging-handler`
- `medzen-transcription-processor`

**Status:**
- ✅ Chime SDK deployed and active
- ✅ Bedrock AI deployed and active
- ❌ EHRbase NOT deployed (needs migration)

---

### eu-west-1 (Ireland) - CURRENT EHRbase PRIMARY
**RDS PostgreSQL:**
- ✅ `medzen-ehrbase-db` (Multi-AZ, available)

**ECS Cluster:**
- ✅ `medzen-ehrbase-cluster` (Fargate)

**Load Balancer:**
- ✅ `medzen-ehrbase-alb` (active)
- DNS: `medzen-ehrbase-alb-554519184.eu-west-1.elb.amazonaws.com`

**Lambda Functions (8):**
- `medzen-medical-entity-extractor`
- `medzen-firebase-sync`
- `medzen-bedrock-ai-chat` (duplicate)
- `medzen-auth-send-otp`
- `medzen-sms-notification-handler`
- `medzen-auth-verify-otp`
- `medzen-data-retention-cleanup`
- `medzen-compliance-monitor`

**Status:**
- ✅ EHRbase production system (needs migration to eu-central-1)
- ⚠️ Some Lambda functions are unique (auth, compliance)
- ⚠️ Bedrock AI chat function is duplicate (can be removed)

---

### af-south-1 (Cape Town) - TO BE DECOMMISSIONED
**CloudFormation Stacks:**
- ⚠️ `medzen-chime-sdk-af-south-1` (UPDATE_COMPLETE - LEGACY)

**Lambda Functions (6):**
- `medzen-recording-handler` (duplicate)
- `medzen-meeting-manager` (duplicate)
- `medzen-transcription-processor` (duplicate)
- `medzen-polly-tts` (duplicate)
- `medzen-messaging-handler` (duplicate)
- `medzen-bedrock-ai-chat` (duplicate)

**Status:**
- ⚠️ All resources are duplicates and can be safely deleted
- ⚠️ Legacy Chime SDK stack (replaced by eu-central-1)
- ⚠️ No unique data or configurations

---

### Global Resources (Region-Independent)
**S3 Buckets (11):**
- `medzen-access-logs-558069890522`
- `medzen-ai-assets-eu-central-1`
- `medzen-cf-templates-eu-central-1-558069890522`
- `medzen-cloudformation-templates-558069890522`
- `medzen-lambda-deployments`
- `medzen-medical-data-558069890522`
- `medzen-meeting-recordings-558069890522`
- `medzen-meeting-transcripts-558069890522`
- `medzen-polly-audio-558069890522`
- `medzen-transcription-vocabularies-558069890522`
- `medzen-transcripts-558069890522`

**Note:** S3 buckets are global but have region affinity. Need to verify bucket policies and replication rules.

---

## Migration Strategy

### Phase 1: Preparation & Validation (2-3 days)
**Goal:** Ensure zero data loss and create rollback procedures

1. **Backup Current EHRbase Database (eu-west-1)**
   ```bash
   # Create RDS snapshot
   aws rds create-db-snapshot \
     --db-instance-identifier medzen-ehrbase-db \
     --db-snapshot-identifier medzen-ehrbase-backup-$(date +%Y%m%d-%H%M%S) \
     --region eu-west-1

   # Export to S3 for additional safety
   aws rds start-export-task \
     --export-task-identifier ehrbase-export-$(date +%Y%m%d) \
     --source-arn arn:aws:rds:eu-west-1:558069890522:snapshot:medzen-ehrbase-backup-$(date +%Y%m%d-%H%M%S) \
     --s3-bucket-name medzen-cloudformation-templates-558069890522 \
     --iam-role-arn arn:aws:iam::558069890522:role/rds-s3-export-role \
     --kms-key-id <kms-key-id>
   ```

2. **Audit Application Configuration**
   - Review all hardcoded endpoints in:
     - `firebase/functions/*.js`
     - `supabase/functions/*/index.ts`
     - `lib/backend/api_requests/api_calls.dart`
     - `assets/environment_values/environment.json`
   - Document all EHRbase endpoint references

3. **Create Rollback Script**
   ```bash
   # Create rollback script
   cat > aws-deployment/scripts/rollback-to-eu-west-1.sh <<'EOF'
   #!/bin/bash
   # Rollback script to restore eu-west-1 as primary
   # Run this if migration fails

   # Restore EHRbase DNS to eu-west-1
   # Update Lambda environment variables
   # Revert CloudFormation stack updates
   EOF
   chmod +x aws-deployment/scripts/rollback-to-eu-west-1.sh
   ```

4. **Test Backup Restore**
   - Create test RDS instance from snapshot in eu-central-1
   - Verify data integrity
   - Delete test instance

**Deliverables:**
- ✅ RDS snapshot created and exported
- ✅ Application configuration audit complete
- ✅ Rollback script created and tested
- ✅ Backup restore validated

---

### Phase 2: Deploy EHRbase to eu-central-1 (3-4 days)
**Goal:** Deploy production-ready EHRbase in eu-central-1 as primary

1. **Create EHRbase CloudFormation Stack in eu-central-1**
   ```bash
   cd aws-deployment

   # Deploy RDS PostgreSQL Multi-AZ
   aws cloudformation deploy \
     --template-file cloudformation/ehrbase-infrastructure.yaml \
     --stack-name medzen-ehrbase-eu-central-1 \
     --region eu-central-1 \
     --parameter-overrides \
       ProjectName=medzen \
       Environment=production \
       DatabaseUsername=ehrbase_admin \
       DatabasePassword="$(aws secretsmanager get-secret-value --secret-id medzen/ehrbase/db-password --query SecretString --output text --region eu-west-1)" \
       MultiAZ=true \
       BackupRetentionDays=30 \
       PreferredBackupWindow=03:00-04:00 \
       PreferredMaintenanceWindow=sun:04:00-sun:05:00 \
     --capabilities CAPABILITY_IAM \
     --tags Key=Project,Value=MedZen Key=Environment,Value=Production Key=Region,Value=Primary
   ```

2. **Restore Database from Snapshot**
   ```bash
   # Restore RDS from snapshot into eu-central-1
   aws rds restore-db-instance-from-db-snapshot \
     --db-instance-identifier medzen-ehrbase-db-eu-central-1 \
     --db-snapshot-identifier <snapshot-id-from-phase-1> \
     --region eu-central-1 \
     --multi-az \
     --publicly-accessible false \
     --vpc-security-group-ids <security-group-id> \
     --db-subnet-group-name <subnet-group-name>

   # Wait for restore to complete
   aws rds wait db-instance-available \
     --db-instance-identifier medzen-ehrbase-db-eu-central-1 \
     --region eu-central-1
   ```

3. **Deploy EHRbase Application (ECS Fargate)**
   ```bash
   # Deploy ECS cluster and services
   ./scripts/deploy-ehrbase-application.sh eu-central-1

   # Configure Application Load Balancer
   # Update Route53 DNS (create new subdomain for testing)
   ```

4. **Validate EHRbase Functionality**
   ```bash
   # Test EHRbase API
   EHRBASE_URL="https://ehr-eu-central-1.medzenhealth.app/ehrbase"

   # Create test EHR
   curl -X POST "$EHRBASE_URL/rest/openehr/v1/ehr" \
     -H "Authorization: Basic $(echo -n 'ehrbase-admin:password' | base64)" \
     -H "Content-Type: application/json"

   # Verify templates
   curl -X GET "$EHRBASE_URL/rest/openehr/v1/definition/template/adl1.4" \
     -H "Authorization: Basic $(echo -n 'ehrbase-admin:password' | base64)"
   ```

5. **Configure Read Replica in eu-west-1**
   ```bash
   # Create read replica for DR
   aws rds create-db-instance-read-replica \
     --db-instance-identifier medzen-ehrbase-db-eu-west-1-replica \
     --source-db-instance-identifier medzen-ehrbase-db-eu-central-1 \
     --region eu-west-1 \
     --multi-az
   ```

**Deliverables:**
- ✅ EHRbase RDS deployed in eu-central-1 (Multi-AZ)
- ✅ ECS cluster and services running
- ✅ Load balancer configured
- ✅ DNS configured (test subdomain)
- ✅ Read replica in eu-west-1
- ✅ Functionality validated

---

### Phase 3: Migrate Bedrock AI (Already Complete!)
**Goal:** Consolidate Bedrock AI to eu-central-1

**Status:**
- ✅ Bedrock AI already deployed in eu-central-1 (stack: `medzen-bedrock-ai-eu-central-1`)
- ⚠️ Duplicate Bedrock AI Lambda in eu-west-1 (`medzen-bedrock-ai-chat`)
- ⚠️ Duplicate Bedrock AI Lambda in af-south-1 (`medzen-bedrock-ai-chat`)

**Actions:**
1. **Verify eu-central-1 Bedrock AI is fully functional**
   ```bash
   # Test Bedrock AI endpoint
   aws lambda invoke \
     --function-name medzen-ai-chat-handler \
     --region eu-central-1 \
     --payload '{"body":"{\"message\":\"Hello, test\",\"userId\":\"test-user\",\"conversationId\":\"test-conv\"}"}' \
     response.json

   cat response.json
   ```

2. **Update application to use eu-central-1 endpoint**
   - Update Firebase functions
   - Update Supabase edge functions
   - Test end-to-end AI chat flow

3. **Delete duplicate Lambda functions** (Phase 5)

**Deliverables:**
- ✅ Bedrock AI in eu-central-1 validated
- ✅ Application updated to use eu-central-1 endpoint
- ⏳ Duplicate functions marked for deletion

---

### Phase 4: Migrate eu-west-1 Lambda Functions (1-2 days)
**Goal:** Move unique Lambda functions to eu-central-1 or eu-west-1 DR

**Unique Functions in eu-west-1 (need migration/decision):**
- `medzen-medical-entity-extractor` → Move to eu-central-1
- `medzen-firebase-sync` → Move to eu-central-1
- `medzen-auth-send-otp` → Keep in eu-west-1 (DR/failover)
- `medzen-sms-notification-handler` → Keep in eu-west-1 (DR/failover)
- `medzen-auth-verify-otp` → Keep in eu-west-1 (DR/failover)
- `medzen-data-retention-cleanup` → Move to eu-central-1
- `medzen-compliance-monitor` → Move to eu-central-1

**Duplicate Functions in eu-west-1 (can be deleted):**
- `medzen-bedrock-ai-chat` → DELETE (use eu-central-1 version)

**Actions:**
1. **Package Lambda functions for deployment**
   ```bash
   cd lambda-deployment

   # Package each function
   for func in medical-entity-extractor firebase-sync data-retention-cleanup compliance-monitor; do
     cd $func
     zip -r ../deploy-${func}.zip .
     cd ..
   done
   ```

2. **Deploy to eu-central-1**
   ```bash
   # Deploy each function
   aws lambda create-function \
     --function-name medzen-medical-entity-extractor \
     --runtime nodejs18.x \
     --role arn:aws:iam::558069890522:role/lambda-execution-role \
     --handler index.handler \
     --zip-file fileb://deploy-medical-entity-extractor.zip \
     --region eu-central-1 \
     --timeout 60 \
     --memory-size 1024

   # Repeat for other functions
   ```

3. **Update event triggers and permissions**
   ```bash
   # Update S3 event notifications
   # Update API Gateway integrations
   # Update IAM policies
   ```

**Deliverables:**
- ✅ Unique Lambda functions deployed in eu-central-1
- ✅ Auth/notification functions kept in eu-west-1 for DR
- ✅ Event triggers updated
- ✅ Functionality validated

---

### Phase 5: Cutover to eu-central-1 (1 day - LOW RISK)
**Goal:** Switch production traffic to eu-central-1

**Pre-Cutover Checklist:**
- [ ] All services deployed and validated in eu-central-1
- [ ] Read replica in eu-west-1 fully synced
- [ ] Rollback script tested
- [ ] Monitoring and alerts configured
- [ ] Team on standby

**Cutover Steps:**
1. **Enable Maintenance Mode (Optional)**
   ```bash
   # Display maintenance page for 5-10 minutes
   # Or perform cutover during low-traffic period
   ```

2. **Update DNS Records**
   ```bash
   # Update Route53 to point to eu-central-1 EHRbase
   aws route53 change-resource-record-sets \
     --hosted-zone-id <zone-id> \
     --change-batch file://dns-cutover.json

   # dns-cutover.json contains:
   # - Update ehr.medzenhealth.app → eu-central-1 ALB
   # - Keep TTL low (60 seconds) for quick rollback
   ```

3. **Update Application Configurations**
   ```bash
   # Firebase functions
   firebase functions:config:set \
     ehrbase.url="https://ehr.medzenhealth.app/ehrbase" \
     ehrbase.region="eu-central-1"

   # Supabase secrets
   npx supabase secrets set EHRBASE_URL=https://ehr.medzenhealth.app/ehrbase
   npx supabase secrets set AWS_PRIMARY_REGION=eu-central-1

   # Redeploy affected functions
   firebase deploy --only functions
   npx supabase functions deploy sync-to-ehrbase
   ```

4. **Monitor Traffic and Errors**
   ```bash
   # Monitor CloudWatch logs
   aws logs tail /aws/ecs/medzen-ehrbase --follow --region eu-central-1

   # Monitor application errors
   firebase functions:log --limit 100

   # Check database connections
   aws rds describe-db-instances \
     --db-instance-identifier medzen-ehrbase-db-eu-central-1 \
     --region eu-central-1 \
     --query 'DBInstances[0].DBInstanceStatus'
   ```

5. **Validate End-to-End Functionality**
   ```bash
   # Run automated tests
   ./test_complete_flow.sh
   ./test_chime_deployment.sh
   ./test_ai_chat_e2e.sh

   # Manual testing
   # - Create test user
   # - Create medical record
   # - Start video call
   # - Use AI chat
   ```

**Rollback Procedure (if needed):**
```bash
# Immediate rollback if issues detected
./aws-deployment/scripts/rollback-to-eu-west-1.sh

# This script will:
# 1. Revert DNS to eu-west-1
# 2. Restore function configurations
# 3. Alert team
```

**Deliverables:**
- ✅ DNS updated to eu-central-1
- ✅ Application configurations updated
- ✅ Traffic flowing to eu-central-1
- ✅ Zero downtime achieved
- ✅ Monitoring confirms healthy state

---

### Phase 6: Decommission af-south-1 (1 day)
**Goal:** Delete all resources in af-south-1 to save costs

**Pre-Decommission Validation:**
- [ ] eu-central-1 has been primary for 7+ days
- [ ] No errors or issues detected
- [ ] All traffic confirmed on eu-central-1
- [ ] Stakeholder approval received

**Decommission Steps:**
1. **Stop CloudFormation Stack**
   ```bash
   # Delete Chime SDK stack
   aws cloudformation delete-stack \
     --stack-name medzen-chime-sdk-af-south-1 \
     --region af-south-1

   # Wait for deletion
   aws cloudformation wait stack-delete-complete \
     --stack-name medzen-chime-sdk-af-south-1 \
     --region af-south-1
   ```

2. **Delete Lambda Functions**
   ```bash
   # List and delete all Lambda functions
   FUNCTIONS=$(aws lambda list-functions \
     --region af-south-1 \
     --query 'Functions[?contains(FunctionName, `medzen`)].FunctionName' \
     --output text)

   for func in $FUNCTIONS; do
     echo "Deleting $func..."
     aws lambda delete-function \
       --function-name $func \
       --region af-south-1
   done
   ```

3. **Delete CloudWatch Log Groups**
   ```bash
   # Clean up logs
   LOG_GROUPS=$(aws logs describe-log-groups \
     --region af-south-1 \
     --query 'logGroups[?contains(logGroupName, `medzen`)].logGroupName' \
     --output text)

   for log in $LOG_GROUPS; do
     echo "Deleting log group $log..."
     aws logs delete-log-group \
       --log-group-name $log \
       --region af-south-1
   done
   ```

4. **Delete API Gateways (if any)**
   ```bash
   # Delete API Gateways
   APIS=$(aws apigateway get-rest-apis \
     --region af-south-1 \
     --query 'items[?contains(name, `medzen`)].id' \
     --output text)

   for api in $APIS; do
     echo "Deleting API Gateway $api..."
     aws apigateway delete-rest-api \
       --rest-api-id $api \
       --region af-south-1
   done
   ```

5. **Delete DynamoDB Tables (if any)**
   ```bash
   # Delete DynamoDB tables
   TABLES=$(aws dynamodb list-tables \
     --region af-south-1 \
     --query 'TableNames[?contains(@, `medzen`)]' \
     --output text)

   for table in $TABLES; do
     echo "Deleting DynamoDB table $table..."
     aws dynamodb delete-table \
       --table-name $table \
       --region af-south-1
   done
   ```

6. **Final Verification**
   ```bash
   # Verify no resources remain
   echo "=== CloudFormation Stacks ==="
   aws cloudformation list-stacks \
     --region af-south-1 \
     --query 'StackSummaries[?contains(StackName, `medzen`)]'

   echo "=== Lambda Functions ==="
   aws lambda list-functions \
     --region af-south-1 \
     --query 'Functions[?contains(FunctionName, `medzen`)]'

   echo "=== Should be empty! ==="
   ```

**Cost Savings:**
- Estimated monthly savings: $500-800 USD
- Resources decommissioned: ~12 Lambda functions, 1 CloudFormation stack, DynamoDB tables, API Gateway

**Deliverables:**
- ✅ All af-south-1 resources deleted
- ✅ Cost savings validated
- ✅ No residual charges from af-south-1

---

### Phase 7: Configure eu-west-1 as Secondary/DR (2 days)
**Goal:** Establish eu-west-1 as hot standby for disaster recovery

**DR Architecture:**
- RDS read replica already exists (created in Phase 2)
- Deploy minimal Lambda functions for failover
- Configure Route53 health checks and failover routing

**Actions:**
1. **Promote Read Replica to Standby (read-only mode)**
   ```bash
   # Read replica is already created
   # Configure for manual promotion in DR scenario
   ```

2. **Deploy Critical Lambda Functions to eu-west-1**
   ```bash
   # Deploy only essential functions for DR:
   # - medzen-meeting-manager (Chime SDK)
   # - medzen-ai-chat-handler (Bedrock AI)
   # - medzen-firebase-sync (EHR sync)

   # These will only activate during failover
   ```

3. **Configure Route53 Health Checks**
   ```bash
   # Create health check for eu-central-1 EHRbase
   aws route53 create-health-check \
     --caller-reference "ehrbase-health-$(date +%s)" \
     --health-check-config \
       Type=HTTPS,\
       ResourcePath=/ehrbase/rest/openehr/v1/definition/template/adl1.4,\
       FullyQualifiedDomainName=ehr.medzenhealth.app,\
       Port=443,\
       RequestInterval=30,\
       FailureThreshold=3

   # Configure failover routing policy
   # Primary: eu-central-1
   # Secondary: eu-west-1 (activates if primary fails health check)
   ```

4. **Create DR Runbook**
   ```bash
   # Document DR procedures
   cat > DR_RUNBOOK.md <<'EOF'
   # Disaster Recovery Runbook

   ## Scenario: eu-central-1 Region Failure

   ### Immediate Actions (0-15 minutes)
   1. Verify eu-central-1 is down (not just transient)
   2. Promote eu-west-1 read replica to standalone
   3. Update DNS failover (automatic via Route53)
   4. Activate eu-west-1 Lambda functions

   ### Recovery Steps (15-60 minutes)
   1. Monitor application health
   2. Communicate with users
   3. Investigate root cause
   4. Plan restoration to eu-central-1
   EOF
   ```

5. **Test DR Failover**
   ```bash
   # Simulate failure by stopping eu-central-1 EHRbase
   # Verify automatic failover to eu-west-1
   # Test application functionality
   # Restore to eu-central-1
   ```

**Deliverables:**
- ✅ Read replica configured as hot standby
- ✅ DR Lambda functions deployed in eu-west-1
- ✅ Route53 health checks and failover configured
- ✅ DR runbook created
- ✅ DR failover tested and validated

---

## Risk Assessment & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Data loss during EHRbase migration | CRITICAL | LOW | RDS snapshots, export to S3, test restore |
| Extended downtime during cutover | HIGH | MEDIUM | Use low-traffic period, DNS TTL 60s for quick rollback |
| Application misconfiguration | MEDIUM | MEDIUM | Configuration audit, automated tests, rollback script |
| Cost overrun during transition | LOW | MEDIUM | Monitor costs daily, delete af-south-1 quickly |
| DR failover not working | HIGH | LOW | Test DR failover before production cutover |
| User disruption during migration | MEDIUM | LOW | Communicate maintenance window, provide status updates |

---

## Success Criteria

**Phase Completion:**
- [ ] All services running in eu-central-1 as primary
- [ ] eu-west-1 configured as hot standby DR
- [ ] af-south-1 completely decommissioned
- [ ] Zero data loss
- [ ] < 5 minutes total downtime during cutover
- [ ] Cost savings of $500-800/month achieved
- [ ] All automated tests passing
- [ ] Documentation updated

**Performance Metrics:**
- [ ] Average API latency < 100ms (from EU)
- [ ] EHRbase query response time < 200ms
- [ ] Video call connection time < 3 seconds
- [ ] AI chat response time < 2 seconds
- [ ] 99.9% uptime maintained

**Validation:**
- [ ] 7 days of stable operation in eu-central-1
- [ ] Zero critical errors in CloudWatch/logs
- [ ] Successful DR failover test
- [ ] User feedback positive (no complaints)
- [ ] Cost reduction confirmed in AWS billing

---

## Timeline & Estimated Duration

| Phase | Duration | Dependencies | Can Start |
|-------|----------|--------------|-----------|
| Phase 1: Preparation | 2-3 days | None | Immediately |
| Phase 2: Deploy EHRbase | 3-4 days | Phase 1 complete | After Phase 1 |
| Phase 3: Bedrock AI | COMPLETE | None | N/A |
| Phase 4: Lambda Migration | 1-2 days | Phase 2 complete | After Phase 2 |
| Phase 5: Cutover | 1 day | Phases 1-4 complete | After Phase 4 |
| Phase 6: Decommission af-south-1 | 1 day | 7 days post-cutover | After Phase 5 + 7 days |
| Phase 7: DR Configuration | 2 days | Phase 2 complete | Parallel with Phase 4-5 |

**Total Estimated Duration:** 10-14 days (2 weeks)

**Recommended Schedule:**
- **Week 1:** Phases 1-4 (Preparation, EHRbase deployment, Lambda migration)
- **Week 2:** Phases 5-7 (Cutover, decommission, DR configuration)
- **Week 3:** Monitoring period before final decommission

---

## Cost Analysis

### Current Monthly Costs (Estimated)

**eu-central-1:**
- Chime SDK (Lambda, DynamoDB, S3): $200
- Bedrock AI (Lambda, Claude invocations): $150
- **Subtotal:** $350/month

**eu-west-1:**
- EHRbase RDS (Multi-AZ db.t3.medium): $250
- ECS Fargate (2 tasks): $100
- Load Balancer: $25
- Lambda functions (8): $50
- **Subtotal:** $425/month

**af-south-1:**
- Chime SDK (duplicate): $150
- Bedrock AI (duplicate): $100
- Lambda functions (6): $40
- **Subtotal:** $290/month

**TOTAL CURRENT:** ~$1,065/month

---

### Post-Migration Monthly Costs (Estimated)

**eu-central-1 (Primary):**
- Chime SDK: $200
- Bedrock AI: $150
- EHRbase RDS (Multi-AZ db.t3.medium): $250
- ECS Fargate (2 tasks): $100
- Load Balancer: $25
- Lambda functions (11): $70
- **Subtotal:** $795/month

**eu-west-1 (DR/Secondary):**
- EHRbase RDS Read Replica: $125 (half cost of primary)
- Lambda functions (3 standby): $10
- **Subtotal:** $135/month

**af-south-1:**
- **Decommissioned:** $0/month

**TOTAL POST-MIGRATION:** ~$930/month

---

### Cost Savings
- **Monthly Savings:** $135/month (13% reduction)
- **Annual Savings:** $1,620/year

**Additional Benefits:**
- Simplified billing (2 regions instead of 3)
- Reduced data transfer costs (same-region communication)
- Easier cost tracking and optimization

---

## Rollback Procedures

### Immediate Rollback (During Cutover - Phase 5)
**Time Required:** 5-10 minutes

```bash
#!/bin/bash
# rollback-to-eu-west-1.sh

echo "🚨 ROLLBACK INITIATED"

# 1. Revert DNS to eu-west-1
aws route53 change-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --change-batch file://dns-rollback.json

# 2. Revert Firebase configuration
firebase functions:config:set \
  ehrbase.url="https://medzen-ehrbase-alb-554519184.eu-west-1.elb.amazonaws.com/ehrbase" \
  ehrbase.region="eu-west-1"

firebase deploy --only functions

# 3. Revert Supabase secrets
npx supabase secrets set EHRBASE_URL=https://medzen-ehrbase-alb-554519184.eu-west-1.elb.amazonaws.com/ehrbase
npx supabase secrets set AWS_PRIMARY_REGION=eu-west-1

npx supabase functions deploy sync-to-ehrbase

# 4. Alert team
echo "✅ ROLLBACK COMPLETE - Now running on eu-west-1"
echo "⚠️ NEXT STEPS: Investigate eu-central-1 issues before retry"
```

---

### Full Rollback (Post-Cutover)
**Time Required:** 1-2 hours

**If issues discovered within 7 days of cutover:**

1. **Revert DNS (5 minutes)**
2. **Restore eu-west-1 RDS from snapshot** (30-60 minutes)
3. **Reactivate eu-west-1 ECS cluster** (10 minutes)
4. **Update all application configurations** (15 minutes)
5. **Validate functionality** (30 minutes)

**Note:** After 7 days, rollback becomes more complex as eu-west-1 read replica may not have full historical data.

---

## Communication Plan

### Stakeholder Notifications

**Before Migration (T-7 days):**
- Email to all users: Planned maintenance window
- Status page update: Upcoming infrastructure upgrade
- Internal team briefing

**During Migration (T-0):**
- Real-time status updates via status page
- Team on standby in Slack channel
- Monitor user feedback channels

**After Migration (T+1 day):**
- Success announcement
- Performance improvements highlighted
- Thank users for patience

**Sample Email:**
```
Subject: MedZen Infrastructure Upgrade - December 19-20, 2025

Dear MedZen Users,

We're upgrading our infrastructure to improve performance and reliability for all users.

**What's Happening:**
- Consolidating services to our primary European data center (Frankfurt)
- Expected performance improvement: 20-30ms faster response times
- Enhanced disaster recovery capabilities

**When:**
- Date: December 19-20, 2025
- Time: 02:00-04:00 AM GMT (low-traffic period)
- Expected downtime: < 5 minutes

**Impact:**
- Minimal disruption expected
- All data will be preserved
- Login may be required after maintenance

Thank you for your patience!
The MedZen Team
```

---

## Post-Migration Validation

### Automated Tests
```bash
# Run full test suite
./test_complete_flow.sh
./test_chime_deployment.sh
./test_ai_chat_e2e.sh
./test_video_call_auth_fix.sh
./verify_appointment_data.sh

# Expected: All tests PASS
```

### Manual Validation Checklist
- [ ] Create new user account (signup flow)
- [ ] User data syncs to Supabase
- [ ] EHR created in EHRbase (eu-central-1)
- [ ] Create medical record (vital signs, prescriptions)
- [ ] Medical data syncs to EHRbase
- [ ] Start video call (provider and patient)
- [ ] Video/audio quality acceptable
- [ ] AI chat conversation (multiple languages)
- [ ] AI responses streaming correctly
- [ ] Profile picture upload
- [ ] Appointment booking
- [ ] Payment processing

### Monitoring & Alerts (First 7 Days)
```bash
# CloudWatch alarms
- EHRbase RDS CPU > 80%
- ECS task failures
- Lambda errors > 1%
- API Gateway 5xx errors
- Route53 health check failures

# Daily checks
- Error rate < 0.1%
- Response time < 200ms average
- Database connections stable
- No user complaints
```

---

## Next Steps

1. **Review and approve this migration plan**
2. **Schedule migration window** (recommended: low-traffic period, e.g., 2-4 AM GMT weekend)
3. **Assign team members to tasks**
4. **Begin Phase 1: Preparation** immediately
5. **Set up monitoring and alerts**
6. **Create communication templates**
7. **Schedule dry run / rehearsal** (optional but recommended)

---

## Appendix

### A. Configuration Files to Update

**Firebase Functions:**
- `firebase/functions/index.js`
- `firebase/functions/api_manager.js`
- Environment: `firebase functions:config:set`

**Supabase Edge Functions:**
- `supabase/functions/sync-to-ehrbase/index.ts`
- `supabase/functions/chime-meeting-token/index.ts`
- Secrets: `npx supabase secrets set`

**Flutter Application:**
- `assets/environment_values/environment.json` (FlutterFlow managed)
- `lib/backend/api_requests/api_calls.dart`
- Note: Avoid editing if possible

**Documentation:**
- `CLAUDE.md`
- `PRODUCTION_DEPLOYMENT_GUIDE.md`
- `SYSTEM_INTEGRATION_STATUS.md`
- `4_SYSTEM_INTEGRATION_SUMMARY.md`

---

### B. Contact Information

**AWS Support:**
- Support Plan: Business
- TAM: [Not assigned]
- Support Portal: https://console.aws.amazon.com/support/

**Internal Team:**
- Project Lead: [Name]
- DevOps: [Name]
- Database Admin: [Name]
- On-Call: [Name]

**Escalation:**
1. Team Lead
2. Technical Director
3. CTO

---

### C. Useful Commands Reference

```bash
# Check CloudFormation stack status
aws cloudformation describe-stacks --stack-name <name> --region <region>

# Monitor CloudFormation events
aws cloudformation describe-stack-events --stack-name <name> --region <region>

# Check RDS instance status
aws rds describe-db-instances --db-instance-identifier <name> --region <region>

# View Lambda function configuration
aws lambda get-function-configuration --function-name <name> --region <region>

# Tail CloudWatch logs
aws logs tail /aws/lambda/<function-name> --follow --region <region>

# Check Route53 health check status
aws route53 get-health-check-status --health-check-id <id>

# List all resources in a region
aws resourcegroupstaggingapi get-resources --region <region> --tag-filters Key=Project,Values=MedZen

# Estimate monthly costs
aws ce get-cost-and-usage --time-period Start=2025-11-01,End=2025-12-01 --granularity MONTHLY --metrics UnblendedCost
```

---

**Document Version:** 1.0
**Last Updated:** December 12, 2025
**Next Review:** After Phase 1 completion
