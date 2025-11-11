# EHRbase AWS Deployment Guide
**Complete Step-by-Step Migration from Proxmox to AWS ECS Fargate + RDS PostgreSQL**

## Table of Contents
1. [Overview](#overview)
2. [Before You Start](#before-you-start)
3. [Phase 1: Setup (Day 1)](#phase-1-setup-day-1)
4. [Phase 2: Infrastructure (Day 1-2)](#phase-2-infrastructure-day-1-2)
5. [Phase 3: Database (Day 2)](#phase-3-database-day-2)
6. [Phase 4: Application (Day 2-3)](#phase-4-application-day-2-3)
7. [Phase 5: Integration (Day 3)](#phase-5-integration-day-3)
8. [Phase 6: Testing (Day 3)](#phase-6-testing-day-3)
9. [Phase 7: Cutover (Day 4)](#phase-7-cutover-day-4)
10. [Post-Deployment](#post-deployment)
11. [Troubleshooting](#troubleshooting)

---

## Overview

### What This Guide Covers
This guide walks you through migrating your EHRbase deployment from Proxmox Kubernetes to AWS ECS Fargate with RDS PostgreSQL, while maintaining all integrations with:
- Firebase Cloud Functions
- Supabase Edge Functions
- FlutterFlow mobile app
- Agora video calling

### Target Architecture
- **Compute:** ECS Fargate (2-4 tasks, auto-scaling)
- **Database:** RDS PostgreSQL db.t3.medium (Multi-AZ, 100GB)
- **Load Balancer:** Application Load Balancer
- **Network:** VPC with public/private subnets across 2 AZs
- **Monitoring:** CloudWatch logs, metrics, and alarms
- **Cost:** ~$260/month
- **Capacity:** 10,000-50,000 users, 500-1,000 concurrent users

### Timeline
- **Total Duration:** 3-4 days with focused effort
- **Minimum Downtime:** 2-4 hours (during cutover)
- **Validation Period:** 7-30 days before Proxmox decommission

---

## Before You Start

### Prerequisites Checklist

#### Tools Installed
- [ ] AWS CLI installed and configured (`aws --version`)
- [ ] Firebase CLI (`firebase --version`)
- [ ] Supabase CLI (`npx supabase --version`)
- [ ] PostgreSQL client (`psql --version`)
- [ ] kubectl (if exporting from Proxmox)
- [ ] jq (`jq --version`)
- [ ] openssl (`openssl version`)

#### Access & Permissions
- [ ] AWS account with admin access
- [ ] AWS CLI configured (`aws sts get-caller-identity`)
- [ ] Firebase project access (`firebase projects:list`)
- [ ] Supabase project access
- [ ] kubectl access to Proxmox cluster (for export)
- [ ] Domain DNS management access

#### Environment
- [ ] macOS or Linux workstation
- [ ] Internet connection (stable, high-speed)
- [ ] Proxmox cluster accessible (if migrating data)
- [ ] ~300-500 MB free disk space (for database export)

#### Planning
- [ ] Maintenance window scheduled (2-4 hours)
- [ ] Users notified 48 hours in advance
- [ ] Team members available during migration
- [ ] Rollback plan reviewed and understood
- [ ] Backup of current Proxmox database taken

### Cost Estimate

| Component | Monthly Cost |
|-----------|--------------|
| ECS Fargate (avg 2.5 tasks) | ~$109 |
| RDS db.t3.medium (Multi-AZ) | ~$120 |
| RDS Storage (100GB gp3) | ~$12 |
| Application Load Balancer | ~$18 |
| Data Transfer (~100GB) | ~$9 |
| **Total** | **~$268/month** |

Daily cost: ~$8-9/day

### Important Notes

**⚠️ Critical Warnings:**
1. **Order Matters** - Execute scripts in numerical order (00 → 01 → 02 → etc.)
2. **Test First** - Consider testing in a dev AWS account first
3. **Backup Everything** - Take full Proxmox backup before starting
4. **Keep Proxmox Running** - Don't decommission for 30 days
5. **Monitor Closely** - Watch CloudWatch for first 48 hours

**✅ What's Automated:**
- VPC and network infrastructure creation
- Security group configuration
- RDS database provisioning
- Password generation and secure storage
- ECS cluster and service setup
- Auto-scaling configuration
- CloudWatch monitoring setup

**⚠️ What's Manual:**
- Database export from Proxmox (semi-automated with kubectl)
- Firebase functions configuration update
- Supabase secrets update
- DNS changes
- SSL certificate setup (optional)
- Final testing and validation

---

## Phase 1: Setup (Day 1)

### Step 1.1: Clone Repository and Navigate

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/aws-deployment
```

### Step 1.2: Run Prerequisites Check

```bash
./00-prerequisites.sh
```

**What This Does:**
- Checks all required CLI tools installed
- Verifies AWS, Firebase, Supabase authentication
- Tests AWS permissions (EC2, RDS, ECS, Secrets Manager)
- Creates `.env` file with default configuration
- Tests Proxmox connectivity (if applicable)

**Expected Output:**
```
✓ aws is installed
✓ firebase is installed
✓ AWS credentials configured
✓ Can access EC2 (VPC creation)
✓ Can access RDS
✓ Can access ECS
✓ Created .env file
```

### Step 1.3: Configure Environment

Edit the `.env` file:

```bash
nano .env
```

**Key Variables to Review:**

```bash
# AWS Configuration
AWS_REGION=us-east-1              # Your preferred region
PROJECT_NAME=medzen-ehrbase       # Keep as-is
AWS_ACCOUNT_ID=<auto-populated>   # Don't change

# Proxmox Configuration (for export)
PROXMOX_HOST=10.10.10.201         # Your Proxmox IP
PROXMOX_K8S_NAMESPACE=ehrbase     # Your namespace

# Deployment Options
SKIP_DATABASE_MIGRATION=false     # Set to true for fresh start
ENABLE_MULTI_AZ=true              # Keep true for production
MIN_ECS_TASKS=2                   # Min tasks (2 recommended)
MAX_ECS_TASKS=4                   # Max tasks for auto-scale
```

**Save and exit** (Ctrl+X, Y, Enter in nano)

### Step 1.4: Review Configuration

```bash
cat .env | grep -v "^#" | grep -v "^$"
```

Verify all values are correct before proceeding.

---

## Phase 2: Infrastructure (Day 1-2)

### Step 2.1: Create VPC and Network Infrastructure

```bash
./01-setup-infrastructure.sh
```

**Duration:** ~5-10 minutes
**What This Creates:**
- VPC (10.0.0.0/16)
- 2 Public subnets (for ALB)
- 2 Private subnets (for ECS and RDS)
- Internet Gateway
- NAT Gateway
- Route tables
- Security groups (ALB, ECS, RDS)

**Progress Indicator:**
```
Step 1: Creating VPC
✓ VPC created: vpc-xxxxx
✓ DNS support enabled

Step 2: Creating Subnets
✓ Public subnet 1a created: subnet-xxxxx
✓ Public subnet 1b created: subnet-xxxxx
✓ Private subnet 1a created: subnet-xxxxx
✓ Private subnet 1b created: subnet-xxxxx

Step 3: Creating Internet Gateway
✓ Internet Gateway created: igw-xxxxx
✓ Internet Gateway attached to VPC

Step 4: Creating NAT Gateway
✓ Elastic IP allocated: eipalloc-xxxxx
✓ NAT Gateway created: nat-xxxxx
⏳ Waiting for NAT Gateway (2-3 minutes)...
✓ NAT Gateway is now available

Step 5: Creating Route Tables
✓ Public route table created: rtb-xxxxx
✓ Route to Internet Gateway added
✓ Public subnets associated
✓ Private route table created: rtb-xxxxx
✓ Route to NAT Gateway added
✓ Private subnets associated

Step 6: Creating Security Groups
✓ ALB security group created: sg-xxxxx
✓ ALB ingress rules configured (ports 80, 443)
✓ ECS security group created: sg-xxxxx
✓ ECS ingress rules configured
✓ RDS security group created: sg-xxxxx
✓ RDS ingress rules configured (port 5432 from ECS)

Infrastructure Setup Complete!
```

**Validation:**
```bash
# Check VPC
aws ec2 describe-vpcs --vpc-ids $(grep VPC_ID .env | cut -d= -f2)

# Check subnets
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$(grep VPC_ID .env | cut -d= -f2)"

# Check security groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$(grep VPC_ID .env | cut -d= -f2)"
```

**If Errors Occur:**
- Check AWS permissions
- Verify region has available IPs
- Check NAT Gateway quota (default: 5 per AZ)
- See [Troubleshooting](#troubleshooting) section

---

## Phase 3: Database (Day 2)

### Step 3.1: Create RDS PostgreSQL Instance

```bash
./02-setup-database.sh
```

**Duration:** ~15-20 minutes
**What This Does:**
- Creates DB subnet group
- Generates 3 strong passwords (32 chars each)
- Stores passwords in AWS Secrets Manager
- Creates RDS PostgreSQL 16.1 instance
- Waits for RDS to become available
- Retrieves and stores RDS endpoint

**Progress Indicator:**
```
Step 1: Creating DB Subnet Group
✓ DB subnet group created

Step 2: Generating Secure Passwords
✓ Generated database admin password
✓ Generated database user password
✓ Generated EHRbase API password

Step 3: Storing Passwords in Secrets Manager
✓ Stored: medzen-ehrbase/db_admin_password
✓ Stored: medzen-ehrbase/db_user_password
✓ Stored: medzen-ehrbase/ehrbase_basic_auth
⚠  Passwords saved to .passwords file

Step 4: Creating RDS PostgreSQL Instance
Instance Configuration:
  Instance Class: db.t3.medium
  CPU: 2 vCPU
  Memory: 4 GB
  Storage: 100 GB gp3
  Multi-AZ: true
  PostgreSQL Version: 16.1

⏳ This will take 10-15 minutes...

Create RDS instance? (y/N): y
✓ RDS instance creation initiated
⏳ Waiting for RDS instance to become available...
  (took 12m 34s)
✓ RDS instance is now available

Step 5: Retrieving RDS Endpoint
✓ RDS Endpoint: medzen-ehrbase-db.xxx.us-east-1.rds.amazonaws.com:5432

RDS Database Setup Complete!
```

**Important Files Created:**
- `.passwords` - Contains all generated passwords (SECURE THIS!)
- `.env` (updated) - Contains RDS endpoint and passwords

**Validation:**
```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier medzen-ehrbase-db

# View passwords (secure file)
cat .passwords

# Test connection
source .env
psql -h $RDS_ENDPOINT -U ehrbase_admin -d postgres -c "SELECT version();"
```

**⚠️ Security Note:**
After recording passwords in your secure password manager:
```bash
# Secure the passwords file
chmod 600 .passwords

# Or delete it (passwords are in Secrets Manager)
# rm .passwords
```

### Step 3.2: Migrate Database

```bash
./03-migrate-database.sh
```

**Duration:** ~20-45 minutes (depends on database size)
**What This Does:**
- Initializes database schema (ehr, ext schemas)
- Creates database users and sets permissions
- Exports database from Proxmox (if not skipping)
- Imports data to RDS
- Verifies migration success

**Progress Indicator:**
```
Step 1: Initializing Database Schema
Creating ehrbase database...
Database created successfully
Creating schemas...
Schemas created: ehr, ext
Creating extensions...
Extension created: uuid-ossp
✓ Database schema initialized

Step 2: Exporting Database from Proxmox
Finding PostgreSQL pod...
✓ Found pod: postgresql-0
Exporting database...
✓ Database exported to pod
Copying backup to local machine...
✓ Backup copied: ehrbase_backup.dump

Backup file info:
  File: ehrbase_backup.dump
  Size: 245M

Step 3: Importing Database to RDS
Start database import? (y/N): y
Importing database (this may take several minutes)...
[Progress output...]
✓ Database import completed

Step 4: Verifying Database Migration
✓ Database connection successful
✓ Schemas exist: ehr, ext
✓ Extension exists: uuid-ossp
✓ Users exist: ehrbase_admin, ehrbase_restricted
✓ Tables in ehr schema: 42
✓ EHR records: 1,234

Database Migration Complete!
```

**If Manual Export Required:**
The script will provide instructions:
```bash
Manual export required:
1. SSH to Proxmox: ssh root@10.10.10.201
2. Find PostgreSQL pod:
   kubectl get pods -n ehrbase | grep postgres
3. Export database:
   kubectl exec -n ehrbase <POD_NAME> -- \
   pg_dump -U ehrbase -d ehrbase --no-owner --no-acl \
   --format=custom --file=/tmp/ehrbase_backup.dump
4. Copy to local machine:
   kubectl cp ehrbase/<POD_NAME>:/tmp/ehrbase_backup.dump ./ehrbase_backup.dump

Press Enter when backup file is ready in current directory...
```

**Validation:**
```bash
# Count tables
source .env
PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase \
  -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'ehr';"

# Check EHR records
PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase \
  -c "SELECT COUNT(*) FROM ehr.ehr;"

# List templates
PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase \
  -c "SELECT template_id FROM ehr.template_store;"
```

---

## Phase 4: Application (Day 2-3)

### Step 4.1: Deploy ECS Fargate

**Note:** The complete ECS deployment script (`04-setup-ecs.sh`) includes:
- ECS cluster creation
- Application Load Balancer setup
- Target group with health checks
- Task definition registration
- ECS service with auto-scaling

**Manual Steps for Now (scripts available in package):**

1. **Create ECS Cluster:**
```bash
aws ecs create-cluster \
  --cluster-name medzen-ehrbase-cluster \
  --capacity-providers FARGATE FARGATE_SPOT \
  --region us-east-1
```

2. **Create Application Load Balancer:**
```bash
source .env
aws elbv2 create-load-balancer \
  --name medzen-ehrbase-alb \
  --subnets $PUBLIC_SUBNET_1 $PUBLIC_SUBNET_2 \
  --security-groups $ALB_SG \
  --scheme internet-facing
```

3. **Get ALB DNS:**
```bash
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names medzen-ehrbase-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text)
echo "ALB DNS: $ALB_DNS"
```

4. **Create Task Definition:**
See `configs/task-definition-template.json` for template.

5. **Create ECS Service:**
```bash
aws ecs create-service \
  --cluster medzen-ehrbase-cluster \
  --service-name ehrbase-service \
  --task-definition medzen-ehrbase \
  --desired-count 2 \
  --launch-type FARGATE
```

**Validation:**
```bash
# Check ECS service
aws ecs describe-services \
  --cluster medzen-ehrbase-cluster \
  --services ehrbase-service

# Test EHRbase API
curl http://$ALB_DNS/ehrbase/rest/status
```

---

## Phase 5: Integration (Day 3)

### Step 5.1: Update Firebase Functions

```bash
cd firebase/functions

# Get ALB DNS from .env
source ../../aws-deployment/.env
ALB_DNS=$(grep ALB_DNS ../../aws-deployment/.env | cut -d= -f2)

# Update Firebase config
firebase use medzen-bf20e
firebase functions:config:set \
  ehrbase.url="http://${ALB_DNS}/ehrbase/rest" \
  ehrbase.username="ehrbase-user" \
  ehrbase.password="${EHRBASE_USER_PASS}"

# Verify config
firebase functions:config:get

# Deploy functions
firebase deploy --only functions
```

### Step 5.2: Update Supabase Edge Functions

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Update secrets
source aws-deployment/.env
npx supabase secrets set \
  EHRBASE_URL="http://${ALB_DNS}/ehrbase/rest" \
  EHRBASE_USERNAME="ehrbase-user" \
  EHRBASE_PASSWORD="${EHRBASE_USER_PASS}"

# Redeploy functions
npx supabase functions deploy sync-to-ehrbase
npx supabase functions deploy powersync-token
```

---

## Phase 6: Testing (Day 3)

### Test 1: EHRbase API Health
```bash
source aws-deployment/.env
curl http://$ALB_DNS/ehrbase/rest/status
# Expected: {"status":"OK"}
```

### Test 2: Create Test EHR
```bash
curl -X POST \
  -u ehrbase-user:$EHRBASE_USER_PASS \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  http://$ALB_DNS/ehrbase/rest/openehr/v1/ehr
```

### Test 3: Firebase Integration
```bash
# Create test user in Firebase console
# Check Cloud Function logs
firebase functions:log --only onUserCreated
```

### Test 4: Supabase Integration
```bash
# Insert test record
psql $SUPABASE_DB_URL -c "
  INSERT INTO vital_signs (patient_id, systolic_bp, diastolic_bp)
  VALUES ('test-user-id', 120, 80);
"

# Check sync queue
npx supabase functions logs sync-to-ehrbase
```

---

## Phase 7: Cutover (Day 4)

### Cutover Checklist

**Pre-Cutover (1 hour before):**
- [ ] All tests passing
- [ ] Backup verification complete
- [ ] Team members available
- [ ] Users notified

**Cutover Steps:**
1. Enable maintenance mode in app
2. Point DNS to AWS ALB
3. Wait for DNS propagation (5-15 minutes)
4. Test with real users
5. Monitor CloudWatch
6. Disable maintenance mode

**Post-Cutover:**
- Monitor for 2-4 hours
- Check error rates
- Validate user reports
- Keep Proxmox running as backup

---

## Post-Deployment

### Daily Tasks (First Week)
- Check CloudWatch dashboard
- Review error logs
- Monitor costs (~$8-9/day expected)
- Verify sync queue processing

### Weekly Tasks
- Review auto-scaling patterns
- Check RDS slow queries
- Validate backups
- Update documentation

---

## Troubleshooting

### Issue: RDS Connection Timeout
```bash
# Check security groups
aws ec2 describe-security-groups --group-ids $RDS_SG

# Verify ECS can reach RDS
# Check that RDS_SG allows port 5432 from ECS_SG
```

### Issue: ECS Tasks Failing
```bash
# Check logs
aws logs tail /ecs/medzen-ehrbase --follow

# Check task stopped reason
aws ecs describe-tasks --cluster medzen-ehrbase-cluster --tasks TASK_ID
```

### Issue: ALB Health Checks Failing
```bash
# Test from ECS task
curl http://localhost:8080/ehrbase/rest/status

# Check target health
aws elbv2 describe-target-health --target-group-arn TG_ARN
```

---

## Emergency Rollback

If critical issues occur:

```bash
cd aws-deployment
./rollback.sh
```

This will:
1. Point DNS back to Proxmox
2. Revert Firebase/Supabase configs
3. Keep AWS running for investigation
4. Notify you when rollback complete

---

## Support

- **AWS Support:** Use AWS Console → Support Center
- **Documentation:** See `aws-deployment/docs/` directory
- **Logs:** CloudWatch, Firebase, Supabase logs
- **Rollback:** `./rollback.sh` if needed

---

**Version:** 1.0
**Last Updated:** 2025-01-29
**Project:** MedZen Iwani EHRbase AWS Migration
