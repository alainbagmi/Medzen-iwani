# AWS Three-Region Multi-AZ Deployment Guide
**Complete EHRbase Deployment with High Availability and Automatic Failover**

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Before You Start](#before-you-start)
4. [Phase 1: Setup](#phase-1-setup)
5. [Phase 2: Deploy Region 1 (eu-west-1)](#phase-2-deploy-region-1-eu-west-1)
6. [Phase 3: Deploy Region 2 (eu-central-1)](#phase-3-deploy-region-2-eu-central-1)
7. [Phase 4: Deploy Region 3 (af-south-1)](#phase-4-deploy-region-3-af-south-1)
8. [Phase 5: Configure Global DNS](#phase-5-configure-global-dns)
9. [Phase 6: Integration](#phase-6-integration)
10. [Phase 7: Testing](#phase-7-testing)
11. [Monitoring & Operations](#monitoring--operations)
12. [Troubleshooting](#troubleshooting)

---

## Overview

### What This Guide Covers
This guide deploys EHRbase across three AWS regions with Multi-AZ architecture, providing:
- **High Availability:** 99.99% uptime with automatic failover
- **Geographic Redundancy:** Three independent regions
- **Single Domain:** Users access `ehr.medzenhealth.app` (automatic routing)
- **Zero Downtime Deployments:** Rolling updates across regions
- **Disaster Recovery:** Each region can operate independently

### Target Architecture

**Three Regions (Multi-AZ in each):**
- **eu-west-1 (Ireland)** - Primary region, 2 availability zones
- **eu-central-1 (Frankfurt)** - Secondary region, 2 availability zones
- **af-south-1 (Cape Town)** - Africa region, 2 availability zones

**Per-Region Components:**
- **Compute:** ECS Fargate (2-4 tasks across 2 AZs, auto-scaling)
- **Database:** RDS PostgreSQL Multi-AZ (primary + standby in different AZs)
- **Load Balancer:** Application Load Balancer (spans 2 AZs)
- **Network:** VPC with public/private subnets in 2 AZs

**Global Components:**
- **DNS:** Route53 with health-check based routing
- **Domain:** Single domain `ehr.medzenhealth.app` for all regions
- **Monitoring:** Unified CloudWatch dashboard across all regions

### Multi-AZ Benefits

**What is Multi-AZ?**
Multi-AZ (Availability Zone) deployment means your application runs in multiple physically separate data centers within a region. Each AZ has independent power, networking, and cooling.

**Availability Zones:**
- **eu-west-1:** eu-west-1a, eu-west-1b (can use up to 1c)
- **eu-central-1:** eu-central-1a, eu-central-1b (can use up to 1c)
- **af-south-1:** af-south-1a, af-south-1b (can use up to 1c)

**Benefits:**
1. **Automatic Failover:** If one AZ fails, traffic routes to healthy AZ within seconds
2. **Zero Downtime Maintenance:** Update one AZ at a time
3. **Higher SLA:** 99.99% vs 99.95% for single-AZ
4. **Better Performance:** Load distributed across multiple data centers
5. **Data Replication:** RDS synchronously replicates to standby AZ

**How It Works:**
```
User Request → Route53 (DNS) → Regional ALB → Healthy AZ
                                      ↓
                              ECS Tasks in AZ-1a or AZ-1b
                                      ↓
                              RDS Multi-AZ (auto-failover)
```

### Cost Estimate (All Three Regions)

**Per Region Monthly Cost:**
| Component | Cost |
|-----------|------|
| ECS Fargate (avg 2.5 tasks) | ~$109 |
| RDS db.t3.medium (Multi-AZ) | ~$120 |
| RDS Storage (100GB gp3) | ~$12 |
| Application Load Balancer | ~$18 |
| Data Transfer (~100GB) | ~$9 |
| **Per Region Total** | **~$268/month** |

**Total Monthly Cost (3 Regions):**
- **Infrastructure:** ~$804/month ($268 × 3)
- **Route53 Health Checks:** ~$1.50/month
- **Data Transfer (cross-region):** ~$50-100/month
- **CloudWatch (enhanced):** ~$30/month
- **Total:** ~$885-935/month

**Daily Cost:** ~$29-31/day across all regions

### Timeline
- **Region 1 (eu-west-1):** 1 day (base deployment)
- **Region 2 (eu-central-1):** 4 hours (clone + configure)
- **Region 3 (af-south-1):** 4 hours (clone + configure)
- **DNS & Testing:** 2 hours
- **Total:** ~2 days for complete three-region deployment

---

## Architecture

### High-Level Architecture

```
                    ┌─────────────────────────────┐
                    │   Route53 (DNS)            │
                    │   ehr.medzenhealth.app     │
                    │   Health-check routing     │
                    └─────────────┬───────────────┘
                                  │
                ┌─────────────────┼─────────────────┐
                │                 │                 │
        ┌───────▼────────┐ ┌─────▼──────┐ ┌───────▼────────┐
        │  eu-west-1     │ │ eu-central-1│ │  af-south-1   │
        │  (Ireland)     │ │ (Frankfurt) │ │ (Cape Town)   │
        └───────┬────────┘ └─────┬──────┘ └───────┬────────┘
                │                 │                 │
        ┌───────▼────────┐ ┌─────▼──────┐ ┌───────▼────────┐
        │      ALB       │ │     ALB     │ │      ALB       │
        │  (Multi-AZ)    │ │ (Multi-AZ)  │ │  (Multi-AZ)    │
        └───────┬────────┘ └─────┬──────┘ └───────┬────────┘
                │                 │                 │
    ┌───────────┴────────┐┌──────┴───────┐┌───────┴────────┐
    │ AZ-1a    │  AZ-1b  ││ AZ-1a │ AZ-1b││ AZ-1a │ AZ-1b  │
    │ ECS Task │ ECS Task││ECS Task│ECS  ││ECS Task│ECS Task│
    └──────────┴─────────┘└───────┴──────┘└────────┴────────┘
                │                 │                 │
        ┌───────▼────────┐ ┌─────▼──────┐ ┌───────▼────────┐
        │ RDS Multi-AZ   │ │ RDS Multi-AZ│ │ RDS Multi-AZ   │
        │ Primary + Stby │ │Primary+Stby │ │ Primary + Stby │
        └────────────────┘ └────────────┘ └────────────────┘
```

### Per-Region Multi-AZ Architecture

```
Region: eu-west-1 (Ireland)
┌─────────────────────────────────────────────────────────────┐
│ VPC: 10.0.0.0/16                                           │
│                                                             │
│  ┌─────────────────────────┐  ┌─────────────────────────┐  │
│  │ Availability Zone 1a    │  │ Availability Zone 1b    │  │
│  │                         │  │                         │  │
│  │ ┌─────────────────────┐ │  │ ┌─────────────────────┐ │  │
│  │ │ Public Subnet       │ │  │ │ Public Subnet       │ │  │
│  │ │ 10.0.1.0/24        │ │  │ │ 10.0.2.0/24        │ │  │
│  │ │                     │ │  │ │                     │ │  │
│  │ │  ┌──────────────┐   │ │  │ │  ┌──────────────┐   │ │  │
│  │ │  │ ALB (part 1) │◄──┼─┼──┼─┼──│ ALB (part 2) │   │ │  │
│  │ │  └──────┬───────┘   │ │  │ │  └──────┬───────┘   │ │  │
│  │ └─────────┼───────────┘ │  │ └─────────┼───────────┘ │  │
│  │           │             │  │           │             │  │
│  │ ┌─────────▼───────────┐ │  │ ┌─────────▼───────────┐ │  │
│  │ │ Private Subnet      │ │  │ │ Private Subnet      │ │  │
│  │ │ 10.0.11.0/24       │ │  │ │ 10.0.12.0/24       │ │  │
│  │ │                     │ │  │ │                     │ │  │
│  │ │ ┌────────────────┐  │ │  │ │ ┌────────────────┐  │ │  │
│  │ │ │ ECS Task 1     │  │ │  │ │ │ ECS Task 2     │  │ │  │
│  │ │ │ (EHRbase)      │  │ │  │ │ │ (EHRbase)      │  │ │  │
│  │ │ └────────┬───────┘  │ │  │ │ └────────┬───────┘  │ │  │
│  │ └──────────┼──────────┘ │  │ └──────────┼──────────┘ │  │
│  └────────────┼────────────┘  └────────────┼────────────┘  │
│               └───────────────┬─────────────┘               │
│                               │                             │
│                    ┌──────────▼──────────┐                  │
│                    │ RDS PostgreSQL      │                  │
│                    │ Multi-AZ            │                  │
│                    │ Primary: AZ-1a      │                  │
│                    │ Standby: AZ-1b      │                  │
│                    │ (auto-failover)     │                  │
│                    └─────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### Traffic Flow with Failover

**Normal Operation:**
```
User → Route53 → Closest healthy region → Regional ALB → Healthy AZ → ECS → RDS
```

**Region Failure:**
```
User → Route53 (detects unhealthy region) → Next healthy region → ALB → ECS → RDS
   Failover time: 30-60 seconds
```

**Availability Zone Failure:**
```
User → Route53 → Region → ALB (detects unhealthy AZ) → Healthy AZ → ECS → RDS
   Failover time: <5 seconds
```

**RDS Failure (within region):**
```
ECS Task → RDS Primary (fails) → RDS auto-fails to Standby → Standby promoted to Primary
   Failover time: 60-120 seconds
```

### DNS Routing Strategy

**Route53 Configuration:**
```
ehr.medzenhealth.app
├─ A Record (Alias) → eu-west-1 ALB
│  ├─ Health Check: https://ehr.medzenhealth.app/ehrbase/rest/status
│  ├─ Routing Policy: Geolocation + Failover
│  └─ Priority: 1 (Primary)
│
├─ A Record (Alias) → eu-central-1 ALB
│  ├─ Health Check: https://ehr.medzenhealth.app/ehrbase/rest/status
│  ├─ Routing Policy: Geolocation + Failover
│  └─ Priority: 2 (Secondary)
│
└─ A Record (Alias) → af-south-1 ALB
   ├─ Health Check: https://ehr.medzenhealth.app/ehrbase/rest/status
   ├─ Routing Policy: Geolocation + Failover
   └─ Priority: 3 (Tertiary)
```

**Geographic Routing:**
- **Europe:** Routes to eu-west-1 (Ireland) or eu-central-1 (Frankfurt)
- **Africa:** Routes to af-south-1 (Cape Town)
- **Other regions:** Routes to eu-west-1 (default)

**Health Check Logic:**
1. Route53 checks each endpoint every 30 seconds
2. If endpoint fails 3 consecutive checks → marked unhealthy
3. Traffic automatically routes to next healthy region
4. When endpoint recovers → traffic gradually returns

---

## Before You Start

### Prerequisites Checklist

#### Tools Installed
- [ ] AWS CLI installed and configured (`aws --version`)
- [ ] Firebase CLI (`firebase --version`)
- [ ] Supabase CLI (`npx supabase --version`)
- [ ] PostgreSQL client (`psql --version`)
- [ ] jq (`jq --version`)
- [ ] openssl (`openssl version`)

#### Access & Permissions
- [ ] AWS account with admin access (or sufficient IAM permissions)
- [ ] AWS CLI configured with credentials for all three regions
- [ ] Firebase project access (`firebase projects:list`)
- [ ] Supabase project access
- [ ] Domain DNS management access (for Route53 setup)
- [ ] Ability to create Route53 hosted zones and health checks

#### Environment Requirements
- [ ] macOS or Linux workstation
- [ ] Stable internet connection (high-speed recommended)
- [ ] ~500MB free disk space (for database backups)
- [ ] SSH access to existing EHRbase (if migrating data)

#### Planning & Communication
- [ ] Maintenance window scheduled (if migrating from existing system)
- [ ] Users notified 48 hours in advance
- [ ] Team members available during deployment
- [ ] Rollback plan reviewed and understood
- [ ] Backup of current database taken (if applicable)

### AWS Region Verification

Verify you can access all three regions:
```bash
# Test eu-west-1
aws ec2 describe-availability-zones --region eu-west-1

# Test eu-central-1
aws ec2 describe-availability-zones --region eu-central-1

# Test af-south-1
aws ec2 describe-availability-zones --region af-south-1
```

### Important Notes

**⚠️ Critical:**
1. **Deploy Regions in Order:** eu-west-1 → eu-central-1 → af-south-1
2. **Don't Skip Steps:** Each region builds on previous configuration
3. **Monitor Costs:** Three regions = 3× infrastructure cost
4. **Test Thoroughly:** Verify failover before going live
5. **Database Sync:** This guide uses independent databases per region (active-active coming soon)

**✅ What's Automated:**
- VPC and Multi-AZ network setup in each region
- Security group configuration across AZs
- RDS Multi-AZ deployment with automatic failover
- ECS task distribution across AZs
- Auto-scaling policies per region
- CloudWatch dashboards per region

**⚠️ What's Manual:**
- Route53 DNS configuration (one-time setup)
- SSL certificate setup in ACM for each region
- Cross-region health check configuration
- Final failover testing

---

## Phase 1: Setup

### Step 1.1: Clone Repository and Navigate

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/aws-deployment
```

### Step 1.2: Run Prerequisites Check

```bash
./00-prerequisites.sh
```

**What This Does:**
- Checks all required CLI tools
- Verifies AWS credentials and region access
- Tests permissions for EC2, RDS, ECS, Route53
- Creates base `.env` configuration file
- Validates network connectivity

**Expected Output:**
```
✓ aws is installed (version 2.x)
✓ firebase is installed
✓ Can access eu-west-1
✓ Can access eu-central-1
✓ Can access af-south-1
✓ AWS credentials configured
✓ Created .env file
```

### Step 1.3: Configure Base Environment

Edit the `.env` file:
```bash
nano .env
```

**Key Variables:**
```bash
# Project Configuration
PROJECT_NAME=medzen-ehrbase
AWS_ACCOUNT_ID=<auto-populated>

# Deployment Settings
ENABLE_MULTI_AZ=true              # MUST be true for this guide
MIN_ECS_TASKS=2                   # Minimum 2 for Multi-AZ
MAX_ECS_TASKS=4                   # Auto-scale maximum
DESIRED_ECS_TASKS=2               # Start with 2 tasks

# Domain Configuration
DOMAIN_NAME=ehr.medzenhealth.app  # Your domain
ROUTE53_HOSTED_ZONE_ID=           # Will be created

# Database Configuration (per region)
DB_INSTANCE_CLASS=db.t3.medium    # 2 vCPU, 4GB RAM
DB_ALLOCATED_STORAGE=100          # 100GB
DB_ENABLE_MULTI_AZ=true           # MUST be true
```

**Save and exit** (Ctrl+X, Y, Enter)

---

## Phase 2: Deploy Region 1 (eu-west-1)

Ireland region serves as the primary region for Europe, Middle East, and default traffic.

### Step 2.1: Set Region Context

```bash
export AWS_REGION=eu-west-1
export REGION_NAME="Ireland"
echo "Deploying to $REGION_NAME ($AWS_REGION)"
```

### Step 2.2: Create Multi-AZ Network Infrastructure

```bash
./01-setup-infrastructure.sh --region eu-west-1
```

**Duration:** ~8-12 minutes

**What This Creates:**
- VPC (10.0.0.0/16)
- **2 Public subnets** (one in each AZ: eu-west-1a, eu-west-1b)
- **2 Private subnets** (one in each AZ for ECS and RDS)
- Internet Gateway
- **2 NAT Gateways** (one per AZ for high availability)
- Route tables (public and private)
- **3 Security groups** (ALB, ECS, RDS) with AZ-aware rules

**Multi-AZ Network Layout:**
```
VPC: 10.0.0.0/16
├─ AZ eu-west-1a
│  ├─ Public Subnet: 10.0.1.0/24 (ALB, NAT Gateway)
│  └─ Private Subnet: 10.0.11.0/24 (ECS, RDS Primary)
└─ AZ eu-west-1b
   ├─ Public Subnet: 10.0.2.0/24 (ALB, NAT Gateway)
   └─ Private Subnet: 10.0.12.0/24 (ECS, RDS Standby)
```

**Progress Indicator:**
```
Step 1: Creating VPC
✓ VPC created: vpc-xxxxx (10.0.0.0/16)
✓ DNS support enabled

Step 2: Creating Multi-AZ Subnets
✓ Public subnet eu-west-1a: subnet-xxxxx (10.0.1.0/24)
✓ Public subnet eu-west-1b: subnet-xxxxx (10.0.2.0/24)
✓ Private subnet eu-west-1a: subnet-xxxxx (10.0.11.0/24)
✓ Private subnet eu-west-1b: subnet-xxxxx (10.0.12.0/24)

Step 3: Creating Internet Gateway
✓ Internet Gateway created: igw-xxxxx

Step 4: Creating NAT Gateways (Multi-AZ)
✓ NAT Gateway 1a created: nat-xxxxx
✓ NAT Gateway 1b created: nat-xxxxx
⏳ Waiting for NAT Gateways to become available (3-5 min)...
✓ Both NAT Gateways available

Step 5: Configuring Route Tables
✓ Public route table: rtb-xxxxx
✓ Private route tables: rtb-xxxxx, rtb-xxxxx

Step 6: Creating Security Groups
✓ ALB SG (internet → ALB): sg-xxxxx
✓ ECS SG (ALB → ECS): sg-xxxxx
✓ RDS SG (ECS → RDS): sg-xxxxx

Infrastructure Setup Complete (eu-west-1)!
Multi-AZ enabled: 2 Availability Zones
```

**Validation:**
```bash
# Verify subnets across AZs
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$(grep VPC_ID .env | cut -d= -f2)" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]' \
  --output table

# Expected: 4 subnets across 2 AZs
```

### Step 2.3: Create RDS Multi-AZ Database

```bash
./02-setup-database.sh --region eu-west-1
```

**Duration:** ~15-20 minutes

**What This Creates:**
- DB subnet group spanning both AZs
- RDS PostgreSQL 16.1 instance
- **Multi-AZ deployment** (primary in 1a, standby in 1b)
- Automatic failover configuration
- Encrypted storage with KMS
- Automated backups (7-day retention)

**Multi-AZ RDS Configuration:**
```
Primary Instance: eu-west-1a (active, handles all traffic)
Standby Instance: eu-west-1b (synchronous replication, auto-failover)

Failover Process:
1. Primary fails or AZ unavailable
2. RDS automatically promotes standby to primary (~60-120 seconds)
3. New standby created in original AZ when it recovers
```

**Progress Indicator:**
```
Step 1: Creating Multi-AZ DB Subnet Group
✓ DB subnet group created (spans eu-west-1a, eu-west-1b)

Step 2: Generating Secure Passwords
✓ DB admin password: <32 chars>
✓ DB user password: <32 chars>
✓ EHRbase API password: <32 chars>

Step 3: Storing in Secrets Manager
✓ Stored: eu-west-1/medzen-ehrbase/db_admin_password
✓ Stored: eu-west-1/medzen-ehrbase/db_user_password
✓ Stored: eu-west-1/medzen-ehrbase/ehrbase_basic_auth

Step 4: Creating RDS Multi-AZ Instance
Configuration:
  Instance: db.t3.medium (2 vCPU, 4GB RAM)
  Multi-AZ: ENABLED
  Primary AZ: eu-west-1a
  Standby AZ: eu-west-1b
  Storage: 100GB gp3 (encrypted)
  Backup: 7-day retention

⏳ Creating RDS instance (12-15 minutes)...
✓ RDS instance available
✓ Multi-AZ confirmed: Primary + Standby active

Step 5: Retrieving RDS Endpoint
✓ Endpoint: medzen-ehrbase-db-eu-west-1.xxx.eu-west-1.rds.amazonaws.com:5432

RDS Multi-AZ Setup Complete (eu-west-1)!
```

**Test Multi-AZ Failover (Optional):**
```bash
# This will trigger automatic failover to test it
aws rds reboot-db-instance \
  --db-instance-identifier medzen-ehrbase-db-eu-west-1 \
  --force-failover

# Monitor failover (takes 60-120 seconds)
watch aws rds describe-db-instances \
  --db-instance-identifier medzen-ehrbase-db-eu-west-1 \
  --query 'DBInstances[0].[DBInstanceStatus,AvailabilityZone]'

# You should see:
# 1. Status changes to "rebooting"
# 2. AZ switches from eu-west-1a to eu-west-1b (or vice versa)
# 3. Status returns to "available"
```

### Step 2.4: Initialize Database

```bash
./03-migrate-database.sh --region eu-west-1
```

**Duration:** ~5-30 minutes (depends on data migration)

**What This Does:**
- Creates database schemas (ehr, ext)
- Creates database users and permissions
- Installs required PostgreSQL extensions
- (Optional) Migrates data from existing database
- Verifies database structure

**Progress Indicator:**
```
Step 1: Connecting to RDS (eu-west-1)
✓ Connected to primary instance
✓ Current AZ: eu-west-1a

Step 2: Creating Database and Schemas
✓ Database: ehrbase
✓ Schemas: ehr, ext
✓ Extensions: uuid-ossp, temporal_tables

Step 3: Creating Users
✓ Admin user: ehrbase_admin
✓ Application user: ehrbase_restricted

Step 4: Setting Permissions
✓ Schema permissions configured
✓ RLS policies applied

Database Initialization Complete (eu-west-1)!
```

### Step 2.5: Deploy ECS with Multi-AZ

```bash
./04-setup-ecs.sh --region eu-west-1
```

**Duration:** ~10-15 minutes

**What This Creates:**
- ECS Cluster (Fargate)
- **Application Load Balancer** (spans both AZs)
- Target groups with health checks
- Task definition for EHRbase
- **ECS Service** with tasks distributed across AZs
- Auto-scaling policies

**Multi-AZ ECS Configuration:**
```
ECS Cluster
├─ Service: ehrbase-service
│  ├─ Desired count: 2
│  ├─ Task 1: eu-west-1a (private subnet)
│  └─ Task 2: eu-west-1b (private subnet)
│
├─ Auto-scaling: 2-4 tasks
│  └─ Distributes across AZs automatically
│
└─ ALB: medzen-ehrbase-alb-eu-west-1
   ├─ Listener: Port 80, 443
   ├─ Target Group: Health check /ehrbase/rest/status
   └─ Spans: eu-west-1a, eu-west-1b
```

**Progress Indicator:**
```
Step 1: Creating ECS Cluster
✓ Cluster: medzen-ehrbase-cluster-eu-west-1

Step 2: Creating Application Load Balancer
✓ ALB: medzen-ehrbase-alb-eu-west-1
✓ Subnets: eu-west-1a, eu-west-1b (Multi-AZ)
✓ DNS: medzen-ehrbase-alb-eu-west-1-xxx.eu-west-1.elb.amazonaws.com

Step 3: Creating Target Group
✓ Target group: medzen-ehrbase-tg-eu-west-1
✓ Health check: /ehrbase/rest/status (every 30s)

Step 4: Registering Task Definition
✓ Task definition: medzen-ehrbase:1
✓ CPU: 1024 (1 vCPU)
✓ Memory: 2048 MB
✓ Environment variables configured

Step 5: Creating ECS Service
✓ Service: ehrbase-service
✓ Launch type: FARGATE
✓ Desired count: 2
✓ Tasks launching in eu-west-1a and eu-west-1b

Step 6: Configuring Auto-scaling
✓ Min: 2, Max: 4 tasks
✓ Target CPU: 70%
✓ Target Memory: 80%

Step 7: Waiting for Service Stability
⏳ Tasks starting (3-5 minutes)...
✓ Task 1: RUNNING in eu-west-1a
✓ Task 2: RUNNING in eu-west-1b
✓ Health checks: HEALTHY

ECS Multi-AZ Deployment Complete (eu-west-1)!
ALB DNS: medzen-ehrbase-alb-eu-west-1-xxx.eu-west-1.elb.amazonaws.com
```

**Test Regional Endpoint:**
```bash
# Get ALB DNS
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --region eu-west-1 \
  --names medzen-ehrbase-alb-eu-west-1 \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

# Test health endpoint
curl http://$ALB_DNS/ehrbase/rest/status
# Expected: {"status":"OK"}

# Test with authentication
curl -u ehrbase-user:PASSWORD \
  http://$ALB_DNS/ehrbase/rest/openehr/v1/ehr \
  -X POST \
  -H "Content-Type: application/json"
# Expected: EHR created response
```

**Summary of Region 1 (eu-west-1):**
```
✓ Multi-AZ VPC with 2 AZs
✓ RDS Multi-AZ (primary + standby)
✓ ALB spanning 2 AZs
✓ ECS tasks distributed across 2 AZs
✓ Auto-scaling enabled
✓ Health checks configured
✓ Region operational and tested
```

---

## Phase 3: Deploy Region 2 (eu-central-1)

Frankfurt region serves Central Europe and provides failover for Ireland.

### Step 3.1: Set Region Context

```bash
export AWS_REGION=eu-central-1
export REGION_NAME="Frankfurt"
echo "Deploying to $REGION_NAME ($AWS_REGION)"
```

### Step 3.2: Deploy Infrastructure (eu-central-1)

```bash
./01-setup-infrastructure.sh --region eu-central-1
```

**Duration:** ~8-12 minutes

**Multi-AZ Network for Frankfurt:**
```
VPC: 10.1.0.0/16
├─ AZ eu-central-1a
│  ├─ Public Subnet: 10.1.1.0/24
│  └─ Private Subnet: 10.1.11.0/24
└─ AZ eu-central-1b
   ├─ Public Subnet: 10.1.2.0/24
   └─ Private Subnet: 10.1.12.0/24
```

**Note:** Different VPC CIDR (10.1.0.0/16) to avoid conflicts with Ireland region.

### Step 3.3: Deploy RDS Multi-AZ (eu-central-1)

```bash
./02-setup-database.sh --region eu-central-1
```

**Duration:** ~15-20 minutes

**RDS Configuration:**
- Primary: eu-central-1a
- Standby: eu-central-1b
- Independent database (not replicated from eu-west-1)

**Note:** For active-active setup, you can configure logical replication between regions (advanced topic, not covered in this guide).

### Step 3.4: Initialize Database (eu-central-1)

```bash
./03-migrate-database.sh --region eu-central-1 --fresh-install
```

**Duration:** ~5-10 minutes

**Options:**
- `--fresh-install`: Creates empty database with schema
- `--clone-from eu-west-1`: Copies data from Ireland region (if needed)

### Step 3.5: Deploy ECS Multi-AZ (eu-central-1)

```bash
./04-setup-ecs.sh --region eu-central-1
```

**Duration:** ~10-15 minutes

**Test Frankfurt Endpoint:**
```bash
ALB_DNS_FRANKFURT=$(aws elbv2 describe-load-balancers \
  --region eu-central-1 \
  --names medzen-ehrbase-alb-eu-central-1 \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

curl http://$ALB_DNS_FRANKFURT/ehrbase/rest/status
```

**Summary of Region 2 (eu-central-1):**
```
✓ Multi-AZ VPC (eu-central-1a, eu-central-1b)
✓ RDS Multi-AZ deployed
✓ ECS tasks across 2 AZs
✓ ALB operational
✓ Independent from eu-west-1 (no cross-region dependencies)
```

---

## Phase 4: Deploy Region 3 (af-south-1)

Cape Town region serves Africa and provides geographic diversity.

### Step 4.1: Set Region Context

```bash
export AWS_REGION=af-south-1
export REGION_NAME="Cape Town"
echo "Deploying to $REGION_NAME ($AWS_REGION)"
```

### Step 4.2: Deploy Infrastructure (af-south-1)

```bash
./01-setup-infrastructure.sh --region af-south-1
```

**Multi-AZ Network for Cape Town:**
```
VPC: 10.2.0.0/16
├─ AZ af-south-1a
│  ├─ Public Subnet: 10.2.1.0/24
│  └─ Private Subnet: 10.2.11.0/24
└─ AZ af-south-1b
   ├─ Public Subnet: 10.2.2.0/24
   └─ Private Subnet: 10.2.12.0/24
```

### Step 4.3: Deploy RDS Multi-AZ (af-south-1)

```bash
./02-setup-database.sh --region af-south-1
```

### Step 4.4: Initialize Database (af-south-1)

```bash
./03-migrate-database.sh --region af-south-1 --fresh-install
```

### Step 4.5: Deploy ECS Multi-AZ (af-south-1)

```bash
./04-setup-ecs.sh --region af-south-1
```

**Test Cape Town Endpoint:**
```bash
ALB_DNS_CAPETOWN=$(aws elbv2 describe-load-balancers \
  --region af-south-1 \
  --names medzen-ehrbase-alb-af-south-1 \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

curl http://$ALB_DNS_CAPETOWN/ehrbase/rest/status
```

**Summary of Region 3 (af-south-1):**
```
✓ Multi-AZ VPC (af-south-1a, af-south-1b)
✓ RDS Multi-AZ deployed
✓ ECS tasks across 2 AZs
✓ ALB operational
✓ Ready for Africa traffic
```

---

## Phase 5: Configure Global DNS

Now we'll configure Route53 to route traffic to the appropriate region based on health and geography.

### Step 5.1: Create Route53 Hosted Zone

```bash
# Create hosted zone for your domain
aws route53 create-hosted-zone \
  --name medzenhealth.app \
  --caller-reference $(date +%s)

# Get the hosted zone ID
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name=='medzenhealth.app.'].Id" \
  --output text | cut -d/ -f3)

echo "Hosted Zone ID: $HOSTED_ZONE_ID"
echo "ROUTE53_HOSTED_ZONE_ID=$HOSTED_ZONE_ID" >> .env
```

**Note:** You'll need to update your domain registrar's nameservers to point to the Route53 nameservers provided in the hosted zone.

### Step 5.2: Create Health Checks for Each Region

```bash
./05-setup-route53-health-checks.sh
```

**What This Creates:**
- Health check for eu-west-1 ALB
- Health check for eu-central-1 ALB
- Health check for af-south-1 ALB
- CloudWatch alarms for health check failures

**Health Check Configuration:**
```json
{
  "Type": "HTTPS",
  "ResourcePath": "/ehrbase/rest/status",
  "FullyQualifiedDomainName": "<ALB_DNS>",
  "Port": 443,
  "RequestInterval": 30,
  "FailureThreshold": 3,
  "MeasureLatency": true,
  "EnableSNI": true
}
```

### Step 5.3: Create DNS Records with Failover

```bash
./06-setup-route53-records.sh
```

**What This Creates:**

**A Records for ehr.medzenhealth.app:**

1. **Primary Record (eu-west-1):**
```json
{
  "Name": "ehr.medzenhealth.app",
  "Type": "A",
  "SetIdentifier": "Primary-Ireland",
  "AliasTarget": {
    "HostedZoneId": "<ALB_ZONE_ID>",
    "DNSName": "<ALB_DNS_IRELAND>",
    "EvaluateTargetHealth": true
  },
  "Failover": "PRIMARY",
  "HealthCheckId": "<IRELAND_HEALTH_CHECK>"
}
```

2. **Secondary Record (eu-central-1):**
```json
{
  "Name": "ehr.medzenhealth.app",
  "Type": "A",
  "SetIdentifier": "Secondary-Frankfurt",
  "AliasTarget": {
    "HostedZoneId": "<ALB_ZONE_ID>",
    "DNSName": "<ALB_DNS_FRANKFURT>",
    "EvaluateTargetHealth": true
  },
  "Failover": "SECONDARY",
  "HealthCheckId": "<FRANKFURT_HEALTH_CHECK>"
}
```

3. **Tertiary Record (af-south-1):**
```json
{
  "Name": "ehr.medzenhealth.app",
  "Type": "A",
  "SetIdentifier": "Tertiary-CapeTown",
  "AliasTarget": {
    "HostedZoneId": "<ALB_ZONE_ID>",
    "DNSName": "<ALB_DNS_CAPETOWN>",
    "EvaluateTargetHealth": true
  },
  "Geolocation": {
    "ContinentCode": "AF"
  },
  "HealthCheckId": "<CAPETOWN_HEALTH_CHECK>"
}
```

**Routing Logic:**
```
1. User in Africa → af-south-1 (if healthy)
2. User in Africa + af-south-1 unhealthy → eu-west-1 or eu-central-1
3. User in Europe → eu-west-1 (if healthy), else eu-central-1
4. User elsewhere → eu-west-1 (primary), eu-central-1 (failover)
```

### Step 5.4: Verify DNS Configuration

```bash
# Test DNS resolution
dig ehr.medzenhealth.app

# Test from different locations (use online DNS tools)
# - From Europe: should resolve to eu-west-1 or eu-central-1
# - From Africa: should resolve to af-south-1
# - From US: should resolve to eu-west-1 (default)

# Test health checks
aws route53 get-health-check-status \
  --health-check-id <HEALTH_CHECK_ID>
```

### Step 5.5: Setup SSL Certificates (Optional but Recommended)

For each region, request an SSL certificate in ACM:

```bash
# eu-west-1
aws acm request-certificate \
  --domain-name ehr.medzenhealth.app \
  --validation-method DNS \
  --region eu-west-1

# eu-central-1
aws acm request-certificate \
  --domain-name ehr.medzenhealth.app \
  --validation-method DNS \
  --region eu-central-1

# af-south-1
aws acm request-certificate \
  --domain-name ehr.medzenhealth.app \
  --validation-method DNS \
  --region af-south-1
```

Then add HTTPS listener to each ALB:
```bash
./07-setup-alb-https.sh --all-regions
```

---

## Phase 6: Integration

### Step 6.1: Update Firebase Functions

Update Firebase to use the single domain:

```bash
cd firebase/functions

firebase functions:config:set \
  ehrbase.url="https://ehr.medzenhealth.app/ehrbase/rest" \
  ehrbase.username="ehrbase-user" \
  ehrbase.password="<PASSWORD_FROM_SECRETS_MANAGER>"

# Verify
firebase functions:config:get

# Deploy
firebase deploy --only functions
```

**Benefits of Single Domain:**
- No region-specific logic needed
- Route53 handles routing automatically
- Transparent failover for Firebase functions

### Step 6.2: Update Supabase Edge Functions

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

npx supabase secrets set \
  EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase/rest" \
  EHRBASE_USERNAME="ehrbase-user" \
  EHRBASE_PASSWORD="<PASSWORD>"

# Redeploy functions
npx supabase functions deploy sync-to-ehrbase
npx supabase functions deploy powersync-token
```

### Step 6.3: Update FlutterFlow App

In `assets/environment_values/environment.json`:

```json
{
  "ehrbaseUrl": "https://ehr.medzenhealth.app/ehrbase/rest",
  "ehrbaseUsername": "ehrbase-user",
  "ehrbasePassword": "<PASSWORD>"
}
```

**Note:** With the single domain approach, no region-specific configuration is needed in the app. Route53 automatically routes to the best available region.

---

## Phase 7: Testing

### Test 1: Verify All Regions Healthy

```bash
# Test all three regions
for region in eu-west-1 eu-central-1 af-south-1; do
  echo "Testing $region..."
  ALB_DNS=$(aws elbv2 describe-load-balancers \
    --region $region \
    --names medzen-ehrbase-alb-$region \
    --query 'LoadBalancers[0].DNSName' \
    --output text)
  curl -s http://$ALB_DNS/ehrbase/rest/status | jq
done
```

### Test 2: Verify DNS Failover

```bash
# Test primary domain
curl https://ehr.medzenhealth.app/ehrbase/rest/status

# Simulate eu-west-1 failure (don't do this in production!)
aws ecs update-service \
  --cluster medzen-ehrbase-cluster-eu-west-1 \
  --service ehrbase-service \
  --desired-count 0 \
  --region eu-west-1

# Wait 2-3 minutes for health check to detect failure
# Then test again - should now route to eu-central-1
curl https://ehr.medzenhealth.app/ehrbase/rest/status

# Restore eu-west-1
aws ecs update-service \
  --cluster medzen-ehrbase-cluster-eu-west-1 \
  --service ehrbase-service \
  --desired-count 2 \
  --region eu-west-1
```

### Test 3: Multi-AZ Failover within Region

```bash
# Test RDS Multi-AZ failover (eu-west-1)
aws rds reboot-db-instance \
  --db-instance-identifier medzen-ehrbase-db-eu-west-1 \
  --force-failover \
  --region eu-west-1

# Monitor ECS tasks - should remain healthy during RDS failover
watch "aws ecs describe-services \
  --cluster medzen-ehrbase-cluster-eu-west-1 \
  --services ehrbase-service \
  --region eu-west-1 \
  --query 'services[0].runningCount'"

# Test endpoint - should have brief interruption (~60s) then recover
while true; do
  curl -s https://ehr.medzenhealth.app/ehrbase/rest/status
  sleep 5
done
```

### Test 4: Geographic Routing

Use online DNS lookup tools from different locations:
- **From Africa:** Should resolve to af-south-1 IP
- **From Europe:** Should resolve to eu-west-1 or eu-central-1
- **From USA:** Should resolve to eu-west-1 (default)

### Test 5: End-to-End Integration

```bash
# Create test user in Firebase
# Should trigger onUserCreated function
# Which should create EHR via https://ehr.medzenhealth.app

firebase functions:log --only onUserCreated --limit 10

# Verify EHR created in the appropriate region
# Check CloudWatch logs in the region that handled the request
```

---

## Monitoring & Operations

### CloudWatch Dashboards

Create unified dashboard across all regions:

```bash
./08-setup-cloudwatch-dashboards.sh
```

**Dashboard Includes:**
- ECS CPU/Memory across all regions
- RDS metrics (connections, IOPS, CPU) per region
- ALB request count and latency per region
- Health check status for all regions
- Auto-scaling activities
- Cost breakdown by region

**Access Dashboard:**
```bash
echo "https://console.aws.amazon.com/cloudwatch/home?region=eu-west-1#dashboards:name=MedZen-EHRbase-Global"
```

### Set Up Alarms

```bash
./09-setup-cloudwatch-alarms.sh
```

**Alarms Created:**
- High CPU utilization (>80%) per region
- High memory (>80%) per region
- RDS connection count (>80% max)
- ALB 5XX errors (>1% of requests)
- Health check failures
- ECS service task count below minimum

**Alarm Actions:**
- SNS topic for email notifications
- Auto-scaling triggers
- PagerDuty integration (if configured)

### Cost Monitoring

```bash
# Enable Cost Explorer API
aws ce get-cost-and-usage \
  --time-period Start=2025-12-01,End=2025-12-05 \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=REGION

# Set budget alerts
aws budgets create-budget \
  --account-id <ACCOUNT_ID> \
  --budget file://budget.json \
  --notifications-with-subscribers file://budget-notifications.json
```

### Regular Maintenance

**Daily:**
- Check CloudWatch dashboard for anomalies
- Review error logs in all regions
- Verify health checks are green

**Weekly:**
- Review costs vs. budget
- Check RDS slow query log
- Verify backups are successful
- Review auto-scaling patterns

**Monthly:**
- Test failover scenarios
- Review and optimize costs
- Update security patches
- Review access logs

---

## Troubleshooting

### Issue: Region Unhealthy in Route53

**Symptoms:**
- Route53 health check shows unhealthy
- Traffic not routing to region

**Diagnosis:**
```bash
# Check health check status
aws route53 get-health-check-status --health-check-id <ID>

# Check ALB target health
aws elbv2 describe-target-health \
  --target-group-arn <TG_ARN> \
  --region <REGION>

# Check ECS service
aws ecs describe-services \
  --cluster medzen-ehrbase-cluster-<REGION> \
  --services ehrbase-service \
  --region <REGION>
```

**Solutions:**
1. If ECS tasks unhealthy → check CloudWatch logs
2. If ALB unhealthy → check security groups allow health check
3. If health check misconfigured → update endpoint/protocol

### Issue: Multi-AZ RDS Failover Slow

**Symptoms:**
- RDS failover takes >2 minutes
- Application errors during failover

**Diagnosis:**
```bash
# Check RDS events
aws rds describe-events \
  --source-identifier medzen-ehrbase-db-<REGION> \
  --region <REGION>

# Check Multi-AZ status
aws rds describe-db-instances \
  --db-instance-identifier medzen-ehrbase-db-<REGION> \
  --region <REGION> \
  --query 'DBInstances[0].[MultiAZ,SecondaryAvailabilityZone]'
```

**Solutions:**
1. Verify Multi-AZ is actually enabled
2. Check for high replication lag (should be <1s)
3. Increase connection pool timeouts in application
4. Consider using RDS Proxy for faster reconnection

### Issue: Cross-Region Traffic Not Routing Properly

**Symptoms:**
- Users report accessing wrong region
- High latency for some users

**Diagnosis:**
```bash
# Test DNS from different locations
dig @8.8.8.8 ehr.medzenhealth.app

# Check Route53 routing policy
aws route53 list-resource-record-sets \
  --hosted-zone-id <ZONE_ID> \
  --query "ResourceRecordSets[?Name=='ehr.medzenhealth.app.']"
```

**Solutions:**
1. Verify geolocation routing is configured correctly
2. Check health checks are passing in all regions
3. Use Route53 query logging to see actual routing decisions
4. Consider using latency-based routing if geographic routing issues persist

### Issue: High Costs

**Symptoms:**
- Monthly bill higher than expected
- Specific region driving costs

**Diagnosis:**
```bash
# Get cost by region
aws ce get-cost-and-usage \
  --time-period Start=2025-12-01,End=2025-12-05 \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=REGION

# Get cost by service
aws ce get-cost-and-usage \
  --time-period Start=2025-12-01,End=2025-12-05 \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE
```

**Solutions:**
1. **Data Transfer Costs High:**
   - Reduce cross-region API calls
   - Use CloudFront for static content
   - Minimize data replication

2. **RDS Costs High:**
   - Right-size instances (db.t3.small may suffice)
   - Reduce backup retention
   - Use Reserved Instances for 1-year commitment (-30% cost)

3. **Fargate Costs High:**
   - Reduce task count during low-traffic hours
   - Use Fargate Spot (up to 70% savings)
   - Right-size CPU/memory allocation

4. **NAT Gateway Costs High:**
   - Consider using NAT instances instead (more management overhead)
   - Reduce outbound data transfer
   - Use VPC endpoints for AWS services

### Emergency Rollback

If you need to rollback to previous architecture:

```bash
cd aws-deployment
./rollback-to-single-region.sh
```

**What This Does:**
1. Points DNS back to original endpoint
2. Scales down other regions (doesn't delete)
3. Reverts Firebase/Supabase configs
4. Provides detailed rollback report

---

## Summary

### What You've Deployed

**Three Regions with Multi-AZ in Each:**
- **eu-west-1 (Ireland):** Primary region, 2 AZs
- **eu-central-1 (Frankfurt):** Secondary region, 2 AZs
- **af-south-1 (Cape Town):** Africa region, 2 AZs

**Per Region:**
- VPC with public/private subnets across 2 AZs
- RDS PostgreSQL Multi-AZ (primary + standby)
- ECS Fargate with tasks distributed across AZs
- Application Load Balancer spanning both AZs
- Auto-scaling (2-4 tasks)
- CloudWatch monitoring and alarms

**Global:**
- Route53 with health-check based failover
- Single domain: `ehr.medzenhealth.app`
- Geographic routing (Africa → af-south-1, Europe → eu-west-1/eu-central-1)
- Automatic failover between regions
- Unified monitoring dashboard

### High Availability Achieved

**Uptime SLA:**
- **Single Region, Single AZ:** 99.5% (~3.6 hours/month downtime)
- **Single Region, Multi-AZ:** 99.95% (~22 minutes/month downtime)
- **Three Regions, Multi-AZ:** 99.99% (~4 minutes/month downtime)

**Failure Scenarios Handled:**
1. **Single AZ failure:** ALB routes to healthy AZ (~5 seconds)
2. **Single region failure:** Route53 routes to healthy region (~30-60 seconds)
3. **RDS failure:** Multi-AZ failover within region (~60-120 seconds)
4. **Application crash:** ECS auto-restarts task, ALB routes to healthy tasks

### Next Steps

1. **Monitor for 1 Week:** Watch CloudWatch, review costs
2. **Optimize:** Adjust task counts, fine-tune auto-scaling
3. **Test Failover:** Run regular failover drills
4. **Document:** Update runbooks with your specific configuration
5. **Train Team:** Ensure team knows how to respond to alerts

### Support & Resources

- **AWS Support:** Console → Support Center
- **Documentation:** `/aws-deployment/docs/`
- **Logs:** CloudWatch (all regions), Firebase, Supabase
- **Health Checks:** Route53 console
- **Cost Reports:** AWS Cost Explorer

---

**Version:** 2.0 (Multi-Region Multi-AZ)
**Last Updated:** 2025-12-05
**Project:** MedZen EHRbase AWS Multi-Region Deployment
