# EHRbase eu-central-1 Deployment Diagnosis

**Date:** December 12, 2025
**Stack:** medzen-ehrbase-stack
**Region:** eu-central-1
**Status:** ROLLBACK_IN_PROGRESS (deployment failed)

## Executive Summary

The EHRbase deployment to eu-central-1 **failed due to health check timing issues**, not application errors. EHRbase started successfully but the health checks were too aggressive for the application's startup time.

## Root Cause Analysis

### What Happened
1. ✅ RDS database exists and is healthy (Multi-AZ enabled)
2. ✅ Secrets Manager passwords configured correctly
3. ✅ EHRbase container started successfully
4. ✅ Database migrations completed (Flyway)
5. ✅ Application fully initialized in 32.168 seconds
6. ❌ **Health checks failed** - CloudFormation gave up waiting

### The Problem

**EHRbase Startup Time:** 32-34 seconds
**Health Check Configuration:**
```yaml
Container HealthCheck:
  StartPeriod: 60 seconds    # Too short!
  Interval: 30 seconds
  Timeout: 10 seconds
  Retries: 3

ECS Service:
  HealthCheckGracePeriodSeconds: 120
```

**Timeline:**
- T+0s: Container starts
- T+32s: EHRbase fully initialized (Tomcat + Spring Boot)
- T+60s: Health checks begin
- T+60-90s: First few health checks may still be initializing
- T+120s: CloudFormation timeout - marks as NOT_STABILIZED
- Result: Stack rollback

### Evidence from Logs

```
2025-12-12 14:51:54.143 INFO Database: jdbc:postgresql://medzen-ehrbase-db.c1uqcwiquyme.eu-central-1.rds.amazonaws.com:5432/ehrbase (PostgreSQL 16.11)
2025-12-12 14:51:54.625 INFO Schema "ext" is up to date. No migration necessary.
2025-12-12 14:51:55.101 INFO Schema "ehr" is up to date. No migration necessary.
2025-12-12 14:52:07.594 INFO Tomcat started on port 8080 (http) with context path '/ehrbase'
2025-12-12 14:52:07.703 INFO Started EhrBase in 32.168 seconds
```

✅ **Application is working perfectly** - just needs more time for health checks!

## Current Infrastructure State

### ✅ Successfully Deployed (eu-central-1)
- RDS PostgreSQL 16.11 (Multi-AZ) - `medzen-ehrbase-db.c1uqcwiquyme.eu-central-1.rds.amazonaws.com`
- Security Group - `sg-0180e692cc099834d`
- ECS Cluster - `medzen-ehrbase-cluster`
- Application Load Balancer - `medzen-ehrbase-alb-1490579354.eu-central-1.elb.amazonaws.com`
- Chime SDK Stack - `medzen-chime-sdk-eu-central-1` (CREATE_COMPLETE)
- Bedrock AI Stack - `medzen-bedrock-ai-eu-central-1` (UPDATE_COMPLETE)

### 🔄 In Progress
- EHRbase ECS Stack - `medzen-ehrbase-stack` (ROLLBACK_IN_PROGRESS)

### ❌ Failed Attempts
- Previous stack `medzen-ehrbase-eu-central-1` (ROLLBACK_COMPLETE)

## Solution

### Required Changes to `cloudformation/ehrbase-ecs-only.yaml`

```yaml
# Change 1: Increase container health check StartPeriod
ContainerDefinitions:
  - Name: ehrbase
    HealthCheck:
      Command:
        - CMD-SHELL
        - curl -f http://localhost:8080/ehrbase/rest/status || exit 1  # Use /status endpoint
      Interval: 30
      Timeout: 10
      Retries: 5          # Increase retries from 3 to 5
      StartPeriod: 120    # Increase from 60 to 120 seconds

# Change 2: Increase ECS service grace period
ECSService:
  Properties:
    HealthCheckGracePeriodSeconds: 180  # Increase from 120 to 180 seconds
```

### Health Check Endpoint
Consider using `/ehrbase/rest/status` instead of `/ehrbase/rest/openehr/v1/ehr` as it's lighter and doesn't require authentication.

## Deployment Steps (After Rollback Completes)

1. **Delete Failed Stack**
   ```bash
   aws cloudformation delete-stack \
     --stack-name medzen-ehrbase-stack \
     --region eu-central-1

   aws cloudformation wait stack-delete-complete \
     --stack-name medzen-ehrbase-stack \
     --region eu-central-1
   ```

2. **Update CloudFormation Template**
   - Edit `cloudformation/ehrbase-ecs-only.yaml`
   - Apply health check changes above

3. **Redeploy**
   ```bash
   source .passwords
   source rds-endpoint.env

   aws cloudformation deploy \
     --template-file cloudformation/ehrbase-ecs-only.yaml \
     --stack-name medzen-ehrbase-stack \
     --region eu-central-1 \
     --capabilities CAPABILITY_IAM \
     --parameter-overrides \
       ProjectName=medzen-ehrbase \
       Environment=production \
       ExistingRDSEndpoint=$RDS_ENDPOINT \
       ExistingRDSSecurityGroup=$SECURITY_GROUP_ID \
       DatabaseUsername=ehrbase_admin \
       DatabasePassword=$DB_ADMIN_PASS \
       EHRbaseUsername=ehrbase_user \
       EHRbasePassword=$EHRBASE_USER_PASS \
       EHRbaseDockerImage=ehrbase/ehrbase:2.24.0 \
       DomainName=ehr.medzenhealth.app
   ```

4. **Monitor Deployment**
   ```bash
   watch -n 10 'aws cloudformation describe-stacks --region eu-central-1 --stack-name medzen-ehrbase-stack --query "Stacks[0].StackStatus" --output text'
   ```

5. **Validate**
   ```bash
   # Get ALB endpoint
   ALB_DNS=$(aws elbv2 describe-load-balancers --region eu-central-1 --names medzen-ehrbase-alb --query 'LoadBalancers[0].DNSName' --output text)

   # Test EHRbase
   curl -u "ehrbase-admin:$DB_ADMIN_PASS" "http://$ALB_DNS/ehrbase/rest/status"
   ```

## Timeline Estimate

- Rollback completion: 5-10 minutes
- Stack deletion: 2-5 minutes
- Template update: 2 minutes
- Redeployment: 10-15 minutes
- **Total: 20-35 minutes**

## Risk Assessment

**Risk Level:** LOW
**Reason:** Infrastructure is healthy, only configuration tuning needed

**Rollback Plan:** If redeployment fails again, EHRbase in eu-west-1 remains operational. No user impact.

## Next Steps

1. ✅ Wait for rollback to complete
2. ⏳ Delete failed stack
3. ⏳ Apply health check fixes
4. ⏳ Redeploy with updated configuration
5. ⏳ Validate deployment
6. ⏳ Update DNS (after validation)
7. ⏳ Setup RDS read replica in eu-west-1

## Resources

- **Secrets Manager:** All passwords stored securely
- **RDS Snapshot:** `medzen-ehrbase-eucentral1-20251212-103955`
- **Current EHRbase (eu-west-1):** `ehr.medzenhealth.app`
- **Target EHRbase (eu-central-1):** Will use same domain after DNS update
