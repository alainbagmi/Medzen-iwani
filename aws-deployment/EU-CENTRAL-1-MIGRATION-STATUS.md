# MedZen EHRbase Migration to eu-central-1

**Date:** December 12, 2025
**Status:** IN PROGRESS
**Migration Script PID:** Running in background

## Migration Overview

### Objective
Consolidate all MedZen infrastructure to:
- **Primary Region:** eu-central-1 (Frankfurt) - ALL services
- **Secondary/DR Region:** eu-west-1 (Ireland) - Read replicas and failover
- **Decommissioned:** af-south-1 (Cape Town) - All resources deleted

### Current State (Before Migration)

| Service | eu-central-1 | eu-west-1 | af-south-1 |
|---------|--------------|-----------|------------|
| Chime SDK | ✅ Primary | ❌ Not deployed | ✅ **DELETED** |
| Bedrock AI | ✅ Primary | ❌ Not deployed | ❌ Not deployed |
| EHRbase | ❌ Not deployed | ✅ **Current Primary** | ✅ Production (DNS points here) |
| Lambda Functions | ✅ 7 functions | ❌ Not deployed | ✅ 1 function **DELETED** |

### Target State (After Migration)

| Service | eu-central-1 | eu-west-1 | af-south-1 |
|---------|--------------|-----------|------------|
| Chime SDK | ✅ Primary | ❌ Not deployed | ✅ **DELETED** |
| Bedrock AI | ✅ Primary | ❌ Not deployed | ❌ Not deployed |
| EHRbase | ✅ **NEW Primary** | ✅ Read Replica (DR) | ⏳ To be deleted |
| Lambda Functions | ✅ 7 functions | ✅ 3 DR functions | ⏳ To be deleted |

## Migration Steps

### ✅ Completed Steps

1. **Infrastructure Audit** ✅
   - Identified production EHRbase in af-south-1 (DNS: ehr.medzenhealth.app)
   - Identified backup EHRbase in eu-west-1
   - Confirmed Chime SDK and Bedrock AI in eu-central-1

2. **Cleanup af-south-1 Chime SDK** ✅
   - Deleted CloudFormation stack: `medzen-chime-sdk-af-south-1`
   - Deleted Lambda function: `medzen-bedrock-ai-chat`
   - Kept EHRbase resources for migration

3. **Prepare eu-central-1** ✅
   - Created Secrets Manager secrets:
     - `ehrbase/db-password` (ARN: arn:aws:secretsmanager:eu-central-1:558069890522:secret:ehrbase/db-password-JENPGv)
     - `ehrbase/ehrbase-password` (ARN: arn:aws:secretsmanager:eu-central-1:558069890522:secret:ehrbase/ehrbase-password-oQPsqO)
   - Requested ACM certificate for `ehr.medzenhealth.app`
   - Certificate validated and **ISSUED** ✅

4. **Create Database Snapshot** 🔄 IN PROGRESS
   - Snapshot ID: `medzen-ehrbase-euwest1-to-eucentral1-20251212-103534`
   - Source: eu-west-1 RDS (medzen-ehrbase-db)
   - Size: 100GB, PostgreSQL 16.11
   - Status: Creating (0% → will complete in 5-15 minutes)

### 🔄 In Progress

5. **Deploy EHRbase to eu-central-1** ⏳ AUTOMATED
   - CloudFormation stack: `medzen-ehrbase-eu-central-1`
   - Template: `cloudformation/ehrbase-infrastructure.yaml`
   - Configuration:
     - Multi-AZ RDS (PostgreSQL 16.11, 100GB)
     - ECS Fargate cluster
     - Application Load Balancer with HTTPS
     - Auto-scaling (min 2, max 6 tasks)

6. **Copy Snapshot to eu-central-1** ⏳ AUTOMATED
   - Source: eu-west-1 snapshot
   - Target: eu-central-1 (encrypted with KMS)

7. **Restore Database** ⏳ AUTOMATED
   - Restore from copied snapshot
   - Replace CloudFormation-created empty database

8. **Update DNS** ⏳ AUTOMATED
   - Route53 hosted zone: Z040140914A2BW6RNW984
   - Update CNAME: ehr.medzenhealth.app → eu-central-1 ALB

### ⏳ Pending Steps

9. **Update Application Configurations**
   - Supabase Edge Function secrets (EHRBASE_URL)
   - Firebase Functions config (EHRBASE_URL)

10. **Configure eu-west-1 as Read Replica**
    - Convert eu-west-1 RDS to read replica of eu-central-1
    - Setup automatic failover with Route53 health checks

11. **Validate System**
    - Test EHRbase API endpoints
    - Test medical data sync from Supabase
    - Test video calls (Chime SDK)
    - Test AI chat (Bedrock)

12. **Delete af-south-1 Resources**
    - ECS cluster: medzen-ehrbase-cluster
    - RDS instance: medzen-ehrbase-db
    - Application Load Balancer
    - Associated security groups, subnets, VPC

## Credentials and Configuration

### Database Credentials
- **Username:** ehrbase_admin
- **Password:** (Stored in Secrets Manager)
- **Database:** postgres
- **Port:** 5432

### EHRbase API Credentials
- **Username:** ehrbase_user
- **Password:** (Stored in Secrets Manager)
- **Auth Type:** BASIC

### ECS Configuration
- **Docker Image:** 558069890522.dkr.ecr.af-south-1.amazonaws.com/ehrbase:2.24.0
- **Task CPU:** 512
- **Task Memory:** 1024 MB
- **Desired Count:** 2 (auto-scaling enabled)

## DNS Configuration

### Route53 Hosted Zone
- **Zone ID:** Z040140914A2BW6RNW984
- **Domain:** medzenhealth.app
- **Current Record:** ehr.medzenhealth.app → medzen-ehrbase-alb-762044994.af-south-1.elb.amazonaws.com
- **Target Record:** ehr.medzenhealth.app → (eu-central-1 ALB DNS)

## Cost Savings Analysis

### Before Migration (3 Regions)
- **af-south-1:** ~$290/month (EHRbase + Chime SDK + Bedrock AI)
- **eu-west-1:** ~$250/month (EHRbase standby)
- **eu-central-1:** ~$180/month (Chime SDK + Bedrock AI)
- **Total:** ~$720/month

### After Migration (2 Regions)
- **af-south-1:** $0 (decommissioned)
- **eu-west-1:** ~$100/month (read replica only)
- **eu-central-1:** ~$430/month (all services)
- **Total:** ~$530/month

**Monthly Savings:** $190/month ($2,280/year)

## Risk Mitigation

### Rollback Plan
If migration fails:
1. DNS still points to af-south-1 (no downtime)
2. Revert DNS if needed
3. Delete failed eu-central-1 resources
4. Original infrastructure remains intact

### High Availability
- Multi-AZ RDS in eu-central-1
- Auto-scaling ECS tasks (2-6)
- eu-west-1 read replica for DR
- Route53 health checks and failover

### Data Integrity
- Snapshot-based migration (no data loss)
- Encrypted at rest (KMS)
- Encrypted in transit (TLS/HTTPS)
- Backup retention: 7 days

## Post-Migration Validation

### Health Checks
- [ ] EHRbase API responding (https://ehr.medzenhealth.app/ehrbase/rest/status)
- [ ] Database connectivity
- [ ] Template definitions accessible
- [ ] Composition creation working
- [ ] Supabase → EHRbase sync functional
- [ ] Firebase Functions → EHRbase integration
- [ ] Chime SDK video calls
- [ ] Bedrock AI chat

### Performance Benchmarks
- [ ] API response time < 200ms
- [ ] Database query time < 100ms
- [ ] DNS resolution time < 50ms
- [ ] End-to-end sync latency < 2s

## Timeline

- **Start Time:** 2025-12-12 10:35 UTC
- **Snapshot Creation:** 5-15 minutes
- **Infrastructure Deployment:** 15-20 minutes
- **Snapshot Copy:** 10-15 minutes
- **Database Restore:** 15-20 minutes
- **DNS Propagation:** 5 minutes
- **Total Estimated Time:** 60-90 minutes

**Expected Completion:** 2025-12-12 12:00 UTC

## Monitoring

### Migration Script Log
- **Location:** `/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/aws-deployment/migration-20251212-*.log`
- **Monitoring:** `tail -f aws-deployment/migration-*.log`

### AWS CloudWatch
- **RDS Metrics:** CPU, Connections, Storage
- **ECS Metrics:** Task count, CPU, Memory
- **ALB Metrics:** Request count, Latency, HTTP errors

### Application Logs
- **EHRbase:** CloudWatch Logs /ecs/medzen-ehrbase
- **Supabase Edge Functions:** Supabase Dashboard
- **Firebase Functions:** Firebase Console

## Next Steps After Migration

1. **Update Supabase Secrets**
   ```bash
   npx supabase secrets set EHRBASE_URL=https://ehr.medzenhealth.app/ehrbase --region eu-central-1
   ```

2. **Update Firebase Functions Config**
   ```bash
   firebase functions:config:set ehrbase.url="https://ehr.medzenhealth.app/ehrbase"
   firebase deploy --only functions
   ```

3. **Configure Read Replica**
   ```bash
   aws rds create-db-instance-read-replica \
     --db-instance-identifier medzen-ehrbase-db-replica \
     --source-db-instance-identifier medzen-ehrbase-db \
     --region eu-west-1
   ```

4. **Setup Route53 Failover**
   - Create health check for eu-central-1 ALB
   - Configure weighted routing: 100% eu-central-1, 0% eu-west-1
   - Enable automatic failover on health check failure

5. **Delete af-south-1 Resources**
   ```bash
   # After 7 days of validation
   ./aws-deployment/cleanup-af-south-1.sh
   ```

## Support and Troubleshooting

### Common Issues

**Issue:** Database connection timeouts
**Solution:** Check security group rules allow ECS tasks to access RDS

**Issue:** EHRbase returning 500 errors
**Solution:** Check ECS task logs in CloudWatch, verify database connectivity

**Issue:** DNS not resolving
**Solution:** Check Route53 record, verify TTL expired (300s)

### Useful Commands

```bash
# Check snapshot progress
aws rds describe-db-snapshots \
  --db-snapshot-identifier medzen-ehrbase-euwest1-to-eucentral1-20251212-103534 \
  --region eu-west-1

# Check stack status
aws cloudformation describe-stacks \
  --stack-name medzen-ehrbase-eu-central-1 \
  --region eu-central-1

# Test EHRbase endpoint
curl -u ehrbase_user:$EHRBASE_PASSWORD \
  https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4

# View ECS task logs
aws logs tail /ecs/medzen-ehrbase --follow --region eu-central-1
```

---

**Last Updated:** 2025-12-12 10:45 UTC
**Status:** Migration in progress - waiting for snapshot completion
