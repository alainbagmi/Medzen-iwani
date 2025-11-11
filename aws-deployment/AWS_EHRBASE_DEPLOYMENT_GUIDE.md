# AWS EHRbase Deployment Guide
**Telemedicine Platform - ECS Fargate + RDS PostgreSQL**

## Overview

This guide walks you through deploying EHRbase on AWS using the infrastructure configuration outlined in the capacity planning document.

**Infrastructure:**
- **ECS Fargate:** 2-4 tasks × 2 vCPU × 4GB RAM
- **RDS PostgreSQL:** db.t3.medium (2 vCPU, 4GB RAM, 100GB storage)
- **Application Load Balancer:** Internet-facing with health checks
- **Auto-scaling:** CPU and memory-based (70% CPU, 80% Memory)
- **Estimated Cost:** $260/month

**Capacity:**
- 10,000 - 50,000 registered users
- 500 - 1,000 concurrent active users
- 50 - 100 EHR creations per hour
- 500 - 1,000 composition writes per hour
- 2,000 - 5,000 EHR reads per hour

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Pre-Deployment Setup](#pre-deployment-setup)
3. [Deploy Infrastructure](#deploy-infrastructure)
4. [Post-Deployment Configuration](#post-deployment-configuration)
5. [Update Application](#update-application)
6. [Data Migration](#data-migration)
7. [Testing](#testing)
8. [Monitoring](#monitoring)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools
```bash
# Verify installations
aws --version          # AWS CLI v2.x
node --version         # Node.js 20+
npx supabase --version # Supabase CLI
```

### AWS Account Setup
- Active AWS account with admin access
- AWS CLI configured with credentials
- Default region set (recommend: `us-east-1`)

### Domain and SSL (Optional but Recommended)
- Domain name (e.g., `ehrbase.medzen.example.com`)
- SSL certificate in AWS Certificate Manager (ACM)

---

## Pre-Deployment Setup

### Step 1: Configure AWS CLI

```bash
# Configure AWS credentials
aws configure

# Test connection
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AIDA...",
#     "Account": "558069890522",
#     "Arn": "arn:aws:iam::558069890522:user/mylestech"
# }
```

### Step 2: Create SSL Certificate (Optional)

If using a custom domain with HTTPS:

```bash
# Request certificate in ACM
aws acm request-certificate \
  --domain-name ehrbase.medzen.example.com \
  --validation-method DNS \
  --region us-east-1

# Note the CertificateArn from the output
# Follow DNS validation instructions in AWS Console
```

### Step 3: Prepare Secrets

Create a file `aws-deployment/secrets.txt` with your credentials:

```bash
# Database credentials
DATABASE_USERNAME=ehrbase_admin
DATABASE_PASSWORD=<strong-password-min-8-chars>

# EHRbase API credentials
EHRBASE_USERNAME=ehrbase_user
EHRBASE_PASSWORD=<strong-password>

# Domain (if using custom domain)
DOMAIN_NAME=ehrbase.medzen.example.com
CERTIFICATE_ARN=arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT-ID
```

**⚠️ CRITICAL:** Never commit `secrets.txt` to Git. Add to `.gitignore`.

---

## Deploy Infrastructure

### Option 1: Deploy via AWS CLI (Recommended)

```bash
cd aws-deployment

# Deploy CloudFormation stack
aws cloudformation create-stack \
  --stack-name medzen-ehrbase-prod \
  --template-body file://cloudformation/ehrbase-infrastructure.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=medzen-ehrbase \
    ParameterKey=Environment,ParameterValue=production \
    ParameterKey=DatabaseUsername,ParameterValue=ehrbase_admin \
    ParameterKey=DatabasePassword,ParameterValue=YOUR_DB_PASSWORD \
    ParameterKey=EHRbaseUsername,ParameterValue=ehrbase_user \
    ParameterKey=EHRbasePassword,ParameterValue=YOUR_EHRBASE_PASSWORD \
    ParameterKey=DomainName,ParameterValue=ehrbase.medzen.example.com \
    ParameterKey=CertificateArn,ParameterValue=YOUR_CERT_ARN \
  --capabilities CAPABILITY_IAM \
  --region us-east-1

# Monitor stack creation (takes 15-20 minutes)
aws cloudformation wait stack-create-complete \
  --stack-name medzen-ehrbase-prod \
  --region us-east-1

# Check status
aws cloudformation describe-stacks \
  --stack-name medzen-ehrbase-prod \
  --region us-east-1 \
  --query 'Stacks[0].StackStatus'
```

### Option 2: Deploy via AWS Console

1. Open AWS CloudFormation Console
2. Click **Create Stack** → **With new resources**
3. Upload `cloudformation/ehrbase-infrastructure.yaml`
4. Enter stack name: `medzen-ehrbase-prod`
5. Fill in parameters (database password, EHRbase credentials, domain, certificate ARN)
6. Click **Next** through configuration
7. Acknowledge IAM resource creation
8. Click **Create Stack**

### Verify Deployment

```bash
# Get stack outputs
aws cloudformation describe-stacks \
  --stack-name medzen-ehrbase-prod \
  --region us-east-1 \
  --query 'Stacks[0].Outputs'

# Key outputs:
# - LoadBalancerDNS: ALB DNS name
# - EHRbaseEndpoint: Full EHRbase API URL
# - DatabaseEndpoint: RDS PostgreSQL endpoint
# - ECSClusterName: ECS cluster name
```

---

## Post-Deployment Configuration

### Step 1: Initialize EHRbase Database

The EHRbase container automatically initializes the database schema on first start. Wait 3-5 minutes after deployment, then verify:

```bash
# Get ALB DNS
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name medzen-ehrbase-prod \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text)

# Check EHRbase status
curl -u ehrbase_user:YOUR_EHRBASE_PASSWORD \
  http://$ALB_DNS/ehrbase/rest/status

# Expected response:
# {"status": "UP", ...}
```

### Step 2: Configure DNS (If Using Custom Domain)

If you specified a custom domain:

1. Get ALB DNS from stack outputs
2. Create CNAME record in your DNS provider:
   ```
   ehrbase.medzen.example.com → medzen-ehrbase-alb-123456789.us-east-1.elb.amazonaws.com
   ```
3. Wait for DNS propagation (5-30 minutes)
4. Test HTTPS endpoint:
   ```bash
   curl -u ehrbase_user:YOUR_EHRBASE_PASSWORD \
     https://ehrbase.medzen.example.com/ehrbase/rest/status
   ```

### Step 3: Upload OpenEHR Templates

Upload your OpenEHR templates to the new EHRbase instance:

```bash
# Set endpoint
EHRBASE_URL="https://ehrbase.medzen.example.com/ehrbase/rest"
EHRBASE_AUTH="ehrbase_user:YOUR_EHRBASE_PASSWORD"

# Upload templates (from your existing templates)
# Example: Demographics template
curl -X POST \
  -u $EHRBASE_AUTH \
  -H "Content-Type: application/xml" \
  --data @templates/ehrbase.demographics.v1.xml \
  $EHRBASE_URL/openehr/v1/definition/template/adl1.4

# Upload vital signs template
curl -X POST \
  -u $EHRBASE_AUTH \
  -H "Content-Type: application/xml" \
  --data @templates/ehrbase.vital_signs.v1.xml \
  $EHRBASE_URL/openehr/v1/definition/template/adl1.4

# List templates to verify
curl -u $EHRBASE_AUTH \
  $EHRBASE_URL/openehr/v1/definition/template/adl1.4
```

---

## Update Application

### Step 1: Update Supabase Edge Function

Update the `sync-to-ehrbase` function to use the new endpoint:

```bash
# Set new EHRbase URL
npx supabase secrets set \
  EHRBASE_URL="https://ehrbase.medzen.example.com/ehrbase/rest" \
  EHRBASE_USERNAME="ehrbase_user" \
  EHRBASE_PASSWORD="YOUR_EHRBASE_PASSWORD"

# Verify secrets
npx supabase secrets list

# Redeploy edge function
npx supabase functions deploy sync-to-ehrbase

# Test edge function
curl -X POST \
  -H "Authorization: Bearer YOUR_SUPABASE_ANON_KEY" \
  https://YOUR_PROJECT.supabase.co/functions/v1/sync-to-ehrbase
```

### Step 2: Update Firebase Cloud Functions

Update the `onUserCreated` function if it directly references EHRbase:

```bash
cd firebase/functions

# Update Firebase config
firebase functions:config:set \
  ehrbase.url="https://ehrbase.medzen.example.com/ehrbase/rest" \
  ehrbase.username="ehrbase_user" \
  ehrbase.password="YOUR_EHRBASE_PASSWORD"

# View config to verify
firebase functions:config:get

# Deploy
firebase deploy --only functions:onUserCreated
```

### Step 3: Update OpenEHR MCP Server

Update the local OpenEHR MCP server configuration:

```bash
# Edit .mcp.json
cd openehr-mcp-server

# Update EHRBASE_URL
vi .mcp.json
# Change:
# "EHRBASE_URL": "https://ehrbase.medzen.example.com/ehrbase/rest"

# Restart MCP server
# (handled automatically by Claude Code on next request)
```

---

## Data Migration

### Step 1: Export from External EHRbase

```bash
# Set old endpoint
OLD_EHRBASE="https://ehr.medzenhealth.app/ehrbase/rest"
OLD_AUTH="old_user:old_password"

# Export all EHRs (this requires custom migration script)
# Recommended: Use OpenEHR MCP tools

# List all EHRs
curl -u $OLD_AUTH \
  "$OLD_EHRBASE/openehr/v1/ehr" > old_ehrs.json
```

### Step 2: Migrate EHR Data

**Option A: Manual Migration (Small Dataset)**

For each EHR in your system:
1. Create new EHR in AWS EHRbase
2. Query compositions from old EHRbase
3. Upload compositions to new EHRbase
4. Update `electronic_health_records` table with new EHR ID

**Option B: Automated Migration (Recommended)**

Use the migration script provided:

```bash
# Run migration script (to be created)
node aws-deployment/scripts/migrate-ehrbase.js \
  --old-url "https://ehr.medzenhealth.app/ehrbase/rest" \
  --old-auth "old_user:old_password" \
  --new-url "https://ehrbase.medzen.example.com/ehrbase/rest" \
  --new-auth "ehrbase_user:YOUR_EHRBASE_PASSWORD" \
  --dry-run

# Review dry-run output, then run actual migration
node aws-deployment/scripts/migrate-ehrbase.js \
  --old-url "https://ehr.medzenhealth.app/ehrbase/rest" \
  --old-auth "old_user:old_password" \
  --new-url "https://ehrbase.medzen.example.com/ehrbase/rest" \
  --new-auth "ehrbase_user:YOUR_EHRBASE_PASSWORD"
```

### Step 3: Update Supabase Database

Update the `electronic_health_records` table to point to new EHRbase:

```sql
-- This is handled automatically by the migration script
-- Manual update if needed:
UPDATE electronic_health_records
SET ehrbase_url = 'https://ehrbase.medzen.example.com/ehrbase/rest'
WHERE ehrbase_url = 'https://ehr.medzenhealth.app/ehrbase/rest';
```

---

## Testing

### Step 1: Test EHRbase API

```bash
EHRBASE_URL="https://ehrbase.medzen.example.com/ehrbase/rest"
EHRBASE_AUTH="ehrbase_user:YOUR_EHRBASE_PASSWORD"

# Test status endpoint
curl -u $EHRBASE_AUTH $EHRBASE_URL/status

# Test EHR creation
curl -X POST \
  -u $EHRBASE_AUTH \
  -H "Content-Type: application/json" \
  -d '{"_type":"EHR_STATUS","subject":{"external_ref":{"id":{"_type":"GENERIC_ID","value":"test-patient-001","scheme":"id_scheme"},"namespace":"local","type":"PERSON"}},"is_modifiable":true,"is_queryable":true}' \
  $EHRBASE_URL/openehr/v1/ehr

# Note the EHR ID from response
```

### Step 2: Test End-to-End Flow

Use the connection test page in your Flutter app:

```dart
// Navigate to test page
context.pushNamed('ConnectionTestPage');

// Run all tests:
// 1. Signup Flow (creates EHR in new AWS EHRbase)
// 2. Login Online (validates connectivity)
// 3. Data Operations Online (tests CRUD)
```

### Step 3: Test Auto-Scaling

```bash
# Generate load (optional - use load testing tool)
# Monitor CloudWatch metrics in AWS Console

# Watch ECS task count
watch -n 5 'aws ecs describe-services \
  --cluster medzen-ehrbase-cluster \
  --services medzen-ehrbase-service \
  --query "services[0].desiredCount"'

# Expected: Starts at 2, scales to 3-4 under load
```

---

## Monitoring

### CloudWatch Dashboards

Access metrics in AWS Console → CloudWatch → Dashboards

**Key Metrics to Monitor:**
- **ECS CPU Utilization:** Should stay below 70% (triggers scaling)
- **ECS Memory Utilization:** Should stay below 80% (triggers scaling)
- **RDS CPU Utilization:** Should stay below 70%
- **RDS Database Connections:** Should stay below 80
- **ALB Request Count:** Total requests per minute
- **ALB Target Response Time:** Should be < 2 seconds
- **RDS Storage:** Monitor growth rate

### CloudWatch Alarms

Pre-configured alarms in CloudFormation:
- **High CPU Alarm:** ECS CPU > 80%
- **High Memory Alarm:** ECS Memory > 85%
- **RDS High CPU:** RDS CPU > 70%
- **RDS High Connections:** RDS connections > 80

**Add SNS notifications:**
```bash
# Create SNS topic
aws sns create-topic --name medzen-ehrbase-alerts

# Subscribe your email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT:medzen-ehrbase-alerts \
  --protocol email \
  --notification-endpoint admin@medzen.example.com

# Update alarms to notify SNS topic
# (requires updating CloudFormation template)
```

### Logs

```bash
# View ECS logs
aws logs tail /ecs/medzen-ehrbase --follow

# View RDS logs
aws rds describe-db-log-files \
  --db-instance-identifier medzen-ehrbase-postgres

# Download RDS log file
aws rds download-db-log-file-portion \
  --db-instance-identifier medzen-ehrbase-postgres \
  --log-file-name error/postgresql.log.2025-01-29-00
```

---

## Troubleshooting

### ECS Tasks Not Starting

```bash
# Check task logs
aws logs tail /ecs/medzen-ehrbase --follow

# Common issues:
# 1. Database connection failure - check RDS security group
# 2. Docker image pull failure - check ECR permissions
# 3. Health check failure - check health check path
```

### Database Connection Issues

```bash
# Test database connectivity from ECS task
aws ecs execute-command \
  --cluster medzen-ehrbase-cluster \
  --task TASK_ID \
  --container ehrbase \
  --interactive \
  --command "psql -h RDS_ENDPOINT -U ehrbase_admin -d ehrbase"

# Check security groups
aws ec2 describe-security-groups \
  --group-ids sg-XXXXXX \
  --query 'SecurityGroups[0].IpPermissions'
```

### High Latency

```bash
# Check RDS CPU
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=medzen-ehrbase-postgres \
  --start-time 2025-01-29T00:00:00Z \
  --end-time 2025-01-29T23:59:59Z \
  --period 3600 \
  --statistics Average

# Check RDS connections
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=medzen-ehrbase-postgres \
  --start-time 2025-01-29T00:00:00Z \
  --end-time 2025-01-29T23:59:59Z \
  --period 300 \
  --statistics Average

# If connections > 80: Upgrade RDS to db.t3.large
# If CPU > 70%: Upgrade RDS to db.t3.large
```

### Auto-Scaling Not Working

```bash
# Check scaling policies
aws application-autoscaling describe-scaling-policies \
  --service-namespace ecs

# Check target tracking alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix medzen-ehrbase

# Manually scale (temporary)
aws ecs update-service \
  --cluster medzen-ehrbase-cluster \
  --service medzen-ehrbase-service \
  --desired-count 4
```

---

## Upgrade Path

### Phase 1 to Phase 2 (+$120/month = $380 total)

When you reach 50,000+ users or 1,000+ concurrent users:

```bash
# Upgrade RDS to db.t3.large
aws rds modify-db-instance \
  --db-instance-identifier medzen-ehrbase-postgres \
  --db-instance-class db.t3.large \
  --apply-immediately

# Increase ECS max capacity
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/medzen-ehrbase-cluster/medzen-ehrbase-service \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 2 \
  --max-capacity 6
```

### Phase 2 to Phase 3 (+$220/month = $600 total)

When you reach 100,000+ users or 2,000+ concurrent users:

```bash
# Upgrade RDS to db.r5.large (memory-optimized)
aws rds modify-db-instance \
  --db-instance-identifier medzen-ehrbase-postgres \
  --db-instance-class db.r5.large \
  --apply-immediately

# Increase ECS max capacity
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/medzen-ehrbase-cluster/medzen-ehrbase-service \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 3 \
  --max-capacity 10
```

---

## Cost Optimization

### Development Environment

For non-production environments, reduce costs:

```bash
# Use FARGATE_SPOT (70% cheaper)
# Update task definition with FARGATE_SPOT capacity provider

# Reduce task count
aws ecs update-service \
  --cluster medzen-ehrbase-cluster \
  --service medzen-ehrbase-service \
  --desired-count 1

# Use db.t3.small for RDS ($35/month vs $70/month)
```

### Scheduled Scaling

Scale down during off-hours:

```bash
# Add scheduled scaling (requires additional configuration)
# Scale down to 1 task at night (10pm - 6am)
# Scale up to 2 tasks during business hours (6am - 10pm)
```

---

## Backup and Disaster Recovery

### RDS Automated Backups

- **Retention:** 7 days (configurable up to 35 days)
- **Backup Window:** 3:00 AM - 4:00 AM UTC
- **Snapshots:** Taken automatically

```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier medzen-ehrbase-postgres \
  --db-snapshot-identifier medzen-ehrbase-manual-$(date +%Y%m%d)

# List snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier medzen-ehrbase-postgres

# Restore from snapshot (disaster recovery)
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier medzen-ehrbase-postgres-restored \
  --db-snapshot-identifier medzen-ehrbase-manual-20250129
```

### Multi-AZ Deployment (Production)

For production high availability:

```bash
# Enable Multi-AZ (doubles RDS cost, ~$140/month for db.t3.medium)
aws rds modify-db-instance \
  --db-instance-identifier medzen-ehrbase-postgres \
  --multi-az \
  --apply-immediately
```

---

## Security Considerations

### HIPAA Compliance

1. **Sign AWS BAA:** Contact AWS to sign Business Associate Agreement
2. **Enable Encryption:** All resources encrypted (RDS, EBS, S3)
3. **Access Logging:** Enable CloudTrail for audit logs
4. **VPC Isolation:** All resources in private subnets
5. **Secrets Management:** Use AWS Secrets Manager for production

### Secrets Manager (Recommended for Production)

```bash
# Store database password
aws secretsmanager create-secret \
  --name medzen-ehrbase/db-password \
  --secret-string "YOUR_DB_PASSWORD"

# Store EHRbase credentials
aws secretsmanager create-secret \
  --name medzen-ehrbase/api-credentials \
  --secret-string '{"username":"ehrbase_user","password":"YOUR_PASSWORD"}'

# Update ECS task definition to retrieve from Secrets Manager
# (requires updating CloudFormation template)
```

---

## Support and Resources

- **AWS Support:** https://console.aws.amazon.com/support/
- **EHRbase Documentation:** https://docs.ehrbase.org/
- **CloudFormation Template:** `aws-deployment/cloudformation/ehrbase-infrastructure.yaml`
- **Capacity Planning:** See capacity planning document
- **Architecture Diagram:** See AWS_EHRBASE_ARCHITECTURE.md

---

## Next Steps

1. ✅ Deploy infrastructure via CloudFormation
2. ✅ Configure DNS and SSL certificate
3. ✅ Upload OpenEHR templates
4. ✅ Update Supabase and Firebase configuration
5. ✅ Migrate data from external EHRbase
6. ✅ Run end-to-end tests
7. ✅ Set up monitoring and alarms
8. ✅ Configure backups and disaster recovery
9. ✅ Document architecture in CLAUDE.md

---

**Estimated Deployment Time:** 2-4 hours (infrastructure + configuration)
**Estimated Migration Time:** 1-3 hours (depending on data volume)
**Total Project Time:** 4-8 hours

---

*Generated by Claude Code - AWS EHRbase Deployment Project*
