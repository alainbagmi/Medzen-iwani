# AWS EHRbase Deployment - Issues and Fixes

**Deployment Date:** 2025-10-29
**Stack Name:** medzen-ehrbase-prod
**Region:** us-east-1

## Deployment Attempts Summary

### Attempt 1: ECS Service-Linked Role Issue
**Error:** `Unable to assume the service linked role. Please verify that the ECS service linked role exists.`
**Root Cause:** ECS Cluster configuration with `CapacityProviders` and `DefaultCapacityProviderStrategy` was too complex for initial setup.
**Fix:** Simplified ECS Cluster configuration by removing capacity provider settings.

### Attempt 2: RDS Instance Type Not Available
**Error:** `This instance size isn't available with free plan accounts. To remove all limitations, upgrade your account plan.`
**Root Cause:** AWS free tier account doesn't support `db.t3.medium` instance type.
**Fixes:**
- Changed `DBInstanceClass` from `db.t3.medium` to `db.t3.micro`
- Reduced `AllocatedStorage` from 100GB to 20GB
- Updated PostgreSQL version from `14.10` to `14.19` (available version)

### Attempt 3: PostgreSQL Version Not Available
**Error:** `Cannot find version 14.10 for postgres`
**Root Cause:** PostgreSQL 14.10 is not available in AWS RDS.
**Fix:** Updated `EngineVersion` to `14.19` (latest 14.x available)

### Attempt 4: DeletionProtection Blocking Rollback
**Error:** `The following resource(s) failed to delete: [DBInstance]`
**Root Cause:** DBInstance had `DeletionProtection: true` enabled, preventing cleanup during rollback.
**Fix:**
- Disabled DeletionProtection in template (set to `false` for testing)
- Manually disabled protection on stuck instance: `aws rds modify-db-instance --db-instance-identifier medzen-ehrbase-postgres --no-deletion-protection`

### Attempt 5-6: ECS Service Circuit Breaker Triggered
**Error:** `Error occurred during operation 'ECS Deployment Circuit Breaker was triggered'`
**Root Cause:** EHRbase container failed to start properly due to missing configuration.

**Issues Identified:**
1. **Missing Database:** RDS didn't create `ehrbase` database by default (only `postgres`)
2. **Multiple Tasks:** `DesiredCount: 2` caused two tasks to compete during startup
3. **Missing Credentials:** EHRbase requires both admin and regular DB credentials

**Fixes:**
- Added `DBName: 'ehrbase'` to RDS configuration to create database on initialization
- Reduced `DesiredCount` from 2 to 1 for initial deployment
- Updated `MinCapacity` from 2 to 1 in auto-scaling configuration
- Added missing environment variables:
  - `DB_USER_ADMIN`
  - `DB_PASS_ADMIN`

## Final Configuration

### RDS PostgreSQL
```yaml
DBInstanceClass: 'db.t3.micro'     # Free tier eligible
EngineVersion: '14.19'             # Latest available 14.x
DBName: 'ehrbase'                  # Database created on init
AllocatedStorage: 20               # Free tier limit
DeletionProtection: false          # Disabled for testing
```

### ECS Service
```yaml
DesiredCount: 1                    # Single task initially
MinCapacity: 1                     # Match desired count
MaxCapacity: 4                     # Scale up to 4 tasks
```

### EHRbase Environment Variables
```yaml
DB_URL: jdbc:postgresql://<endpoint>:5432/ehrbase
DB_USER: ehrbase_admin
DB_PASS: <password>
DB_USER_ADMIN: ehrbase_admin       # Required for schema operations
DB_PASS_ADMIN: <password>          # Required for schema operations
SECURITY_AUTHTYPE: BASIC
SECURITY_AUTHUSER: ehrbase_user
SECURITY_AUTHPASSWORD: <password>
SERVER_NODENAME: medzen-ehrbase-node
```

## Lessons Learned

1. **Free Tier Limitations:** Always verify instance types and storage limits for free tier accounts
2. **PostgreSQL Versions:** Check available RDS engine versions before deployment
3. **EHRbase Requirements:** Requires TWO sets of database credentials (admin + regular)
4. **Database Initialization:** RDS doesn't create custom databases by default - use `DBName` parameter
5. **Gradual Scaling:** Start with 1 task and scale up after confirming health
6. **DeletionProtection:** Disable during testing to avoid cleanup issues
7. **Container Logs:** Enable and preserve CloudWatch logs for debugging

## Next Steps

1. ✅ Deploy with all fixes applied
2. ⏳ Verify EHRbase health check passes
3. ⏳ Test ALB endpoint connectivity
4. ⏳ Verify EHRbase REST API functionality
5. ⏳ Update Supabase/Firebase with new endpoint
6. ⏳ Test end-to-end EHR creation flow

## Credentials Location

Deployment credentials stored in: `aws-deployment/secrets.txt`
**⚠️ NEVER commit this file to version control!**

## Estimated Costs (Free Tier)

- **RDS db.t3.micro:** Free (750 hours/month)
- **20GB Storage:** Free (20GB limit)
- **ECS Fargate:** ~$30/month (0.25 vCPU, 0.5GB RAM)
- **ALB:** ~$25/month
- **NAT Gateway:** ~$35/month
- **Data Transfer:** ~$10/month

**Total:** ~$100/month (outside free tier components)

## References

- CloudFormation Template: `cloudformation/ehrbase-infrastructure.yaml`
- Quick Start Guide: `AWS_EHRBASE_QUICK_START.md`
- Full Deployment Guide: `AWS_EHRBASE_DEPLOYMENT_GUIDE.md`
- EHRbase Docker Documentation: https://ehrbase.readthedocs.io/
