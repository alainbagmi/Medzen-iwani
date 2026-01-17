# Production EHR Setup - EU Multi-Region

## Overview
This guide deploys EHRbase for **production** in two EU regions with Multi-AZ architecture:
- **eu-west-1 (Ireland)** - Primary production region
- **eu-central-1 (Frankfurt)** - Secondary production region (failover)
- **af-south-1 (Cape Town)** - Reserved for pre-production/staging

## Architecture

```
Production (EU Only):
┌─────────────────────────────────────────────────────────┐
│   Route53: ehr.medzenhealth.app (Production)          │
│   Health-check based failover                          │
└───────────┬─────────────────────┬───────────────────────┘
            │                     │
    ┌───────▼────────┐    ┌──────▼──────────┐
    │  eu-west-1     │    │  eu-central-1   │
    │  (Ireland)     │    │  (Frankfurt)    │
    │  PRIMARY       │    │  SECONDARY      │
    └───────┬────────┘    └──────┬──────────┘
            │                     │
    ┌───────▼────────┐    ┌──────▼──────────┐
    │  Multi-AZ      │    │  Multi-AZ       │
    │  RDS + ECS     │    │  RDS + ECS      │
    └────────────────┘    └─────────────────┘
```

Pre-Production (Africa):
```
┌─────────────────────────────────────────────────────────┐
│   Route53: ehr-preprod.medzenhealth.app               │
└───────────────────────┬─────────────────────────────────┘
                        │
                ┌───────▼────────┐
                │  af-south-1    │
                │  (Cape Town)   │
                │  PRE-PROD      │
                └────────────────┘
```

## Cost Estimate (Production Only - 2 EU Regions)

**Per Region Monthly Cost:**
- ECS Fargate (2.5 tasks avg): ~$109
- RDS Multi-AZ db.t3.medium: ~$120
- RDS Storage (100GB): ~$12
- Application Load Balancer: ~$18
- Data Transfer: ~$9
- **Per Region Total: ~$268/month**

**Total Production Cost (2 EU Regions):**
- Infrastructure: ~$536/month ($268 × 2)
- Route53 Health Checks: ~$1/month
- Cross-region Data Transfer: ~$30/month
- CloudWatch: ~$20/month
- **Total: ~$587/month**

**Pre-Production Cost (1 Africa Region):**
- ~$268/month (separate environment)

## Deployment Steps

### Prerequisites
```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/aws-deployment

# Verify AWS access
aws sts get-caller-identity

# Test EU region access
aws ec2 describe-availability-zones --region eu-west-1
aws ec2 describe-availability-zones --region eu-central-1
```

### Phase 1: Deploy eu-west-1 (Primary)

```bash
export AWS_REGION=eu-west-1
export ENVIRONMENT=production

# 1. Infrastructure
./01-setup-infrastructure.sh --region eu-west-1 --env production

# 2. Database
./02-setup-database.sh --region eu-west-1 --env production

# 3. Initialize DB
./03-init-database.sh --region eu-west-1

# 4. Deploy ECS
./04-setup-ecs.sh --region eu-west-1 --env production

# 5. Test
ALB_DNS=$(aws elbv2 describe-load-balancers --region eu-west-1 \
  --names medzen-ehrbase-alb-eu-west-1 \
  --query 'LoadBalancers[0].DNSName' --output text)
curl http://$ALB_DNS/ehrbase/rest/status
```

### Phase 2: Deploy eu-central-1 (Secondary)

```bash
export AWS_REGION=eu-central-1

# 1. Infrastructure
./01-setup-infrastructure.sh --region eu-central-1 --env production

# 2. Database
./02-setup-database.sh --region eu-central-1 --env production

# 3. Initialize DB
./03-init-database.sh --region eu-central-1

# 4. Deploy ECS
./04-setup-ecs.sh --region eu-central-1 --env production

# 5. Test
ALB_DNS=$(aws elbv2 describe-load-balancers --region eu-central-1 \
  --names medzen-ehrbase-alb-eu-central-1 \
  --query 'LoadBalancers[0].DNSName' --output text)
curl http://$ALB_DNS/ehrbase/rest/status
```

### Phase 3: Configure Production DNS

```bash
# Create Route53 records for production
./scripts/setup-production-dns.sh

# Creates:
# - ehr.medzenhealth.app → PRIMARY (eu-west-1)
# - ehr.medzenhealth.app → SECONDARY (eu-central-1)
# - Health checks for both regions
# - Automatic failover
```

### Phase 4: Update Production Integrations

```bash
# Firebase Functions
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/firebase/functions
firebase functions:config:set \
  ehrbase.url="https://ehr.medzenhealth.app/ehrbase/rest" \
  ehrbase.username="ehrbase-user" \
  ehrbase.password="<FROM_SECRETS_MANAGER>"

# Supabase Edge Functions
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu
npx supabase secrets set \
  EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase/rest" \
  EHRBASE_USERNAME="ehrbase-user" \
  EHRBASE_PASSWORD="<FROM_SECRETS_MANAGER>"

# Redeploy
firebase deploy --only functions
npx supabase functions deploy sync-to-ehrbase
npx supabase functions deploy powersync-token
```

### Phase 5: Test Failover

```bash
# Test primary (eu-west-1)
curl https://ehr.medzenhealth.app/ehrbase/rest/status

# Simulate failure
aws ecs update-service \
  --cluster medzen-ehrbase-cluster-eu-west-1 \
  --service ehrbase-service \
  --desired-count 0 \
  --region eu-west-1

# Wait 60-90 seconds for health check
sleep 90

# Should now route to eu-central-1
curl https://ehr.medzenhealth.app/ehrbase/rest/status

# Restore primary
aws ecs update-service \
  --cluster medzen-ehrbase-cluster-eu-west-1 \
  --service ehrbase-service \
  --desired-count 2 \
  --region eu-west-1
```

## Pre-Production Setup (af-south-1)

Deploy separately for pre-production testing:

```bash
export AWS_REGION=af-south-1
export ENVIRONMENT=preprod

# Full deployment
./01-setup-infrastructure.sh --region af-south-1 --env preprod
./02-setup-database.sh --region af-south-1 --env preprod
./03-init-database.sh --region af-south-1
./04-setup-ecs.sh --region af-south-1 --env preprod

# Create separate DNS
# ehr-preprod.medzenhealth.app → af-south-1
```

## Monitoring

Production monitoring focuses on EU regions:

```bash
./07-setup-monitoring.sh --regions eu-west-1,eu-central-1 --env production
```

**Alarms:**
- EU region health checks
- RDS CPU/Memory in both EU regions
- ECS task count
- Cross-region failover events

## Summary

**Production (Live):**
- Domain: `ehr.medzenhealth.app`
- Regions: eu-west-1 (primary), eu-central-1 (failover)
- Cost: ~$587/month
- SLA: 99.99% uptime

**Pre-Production (Testing):**
- Domain: `ehr-preprod.medzenhealth.app`
- Region: af-south-1
- Cost: ~$268/month
- Purpose: Testing, staging, development

**Next Steps:**
1. Deploy eu-west-1 (primary production)
2. Deploy eu-central-1 (failover production)
3. Configure production DNS with health checks
4. Update all production integrations
5. Test failover thoroughly
6. (Optional) Deploy af-south-1 for pre-prod later
