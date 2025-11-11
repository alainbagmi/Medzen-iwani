# AWS EHRbase Production Deployment Guide

**Project:** MedZen-Iwani Healthcare Platform
**Target:** AWS Production Environment (Fresh Deployment)
**EHRbase Version:** 2.11.0
**Estimated Total Time:** 4-6 hours
**Estimated Monthly Cost:** ~$260/month

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture Summary](#architecture-summary)
- [Network Configuration](#network-configuration)
- [Phase 0: Pre-Flight Checks](#phase-0-pre-flight-checks)
- [Phase 1: Export Templates from Dev](#phase-1-export-templates-from-dev)
- [Phase 2: AWS Network Infrastructure](#phase-2-aws-network-infrastructure)
- [Phase 3: RDS PostgreSQL Database](#phase-3-rds-postgresql-database)
- [Phase 4: Initialize Database Schema](#phase-4-initialize-database-schema)
- [Phase 5: Deploy EHRbase on ECS Fargate](#phase-5-deploy-ehrbase-on-ecs-fargate)
- [Phase 6: Import OpenEHR Templates](#phase-6-import-openehr-templates)
- [Phase 7: Update Firebase/Supabase Integrations](#phase-7-update-firebasesupabase-integrations)
- [Phase 8: Comprehensive Validation](#phase-8-comprehensive-validation)
- [Phase 9: Monitoring Setup](#phase-9-monitoring-setup)
- [Phase 10: Post-Deployment Tasks](#phase-10-post-deployment-tasks)
- [Rollback Procedures](#rollback-procedures)
- [Troubleshooting](#troubleshooting)
- [Cost Breakdown](#cost-breakdown)

---

## Overview

This guide provides step-by-step instructions for deploying a **production-grade EHRbase OpenEHR server** on AWS infrastructure. The deployment:

- **Does NOT migrate data** from dev Proxmox environment
- **Exports and imports OpenEHR templates** to ensure compatibility
- **Integrates with existing Firebase and Supabase** without code changes
- **Follows AWS best practices** (Multi-AZ, auto-scaling, monitoring)
- **Uses custom network configuration** (VPC 10.0.0.0/20 with /22 subnets)

---

## Prerequisites

### Required Accounts & Access
- AWS Account with CLI configured (`aws configure`)
- Firebase project access with admin role
- Supabase project access
- Domain registrar access (for DNS/SSL setup)

### Required Tools
- AWS CLI v2+ (`aws --version`)
- Firebase CLI (`firebase --version`)
- Supabase CLI (`npx supabase --version`)
- PostgreSQL client 16+ (`psql --version`)
- jq for JSON parsing (`jq --version`)
- curl (`curl --version`)

### Required Credentials
- AWS Access Key ID and Secret Access Key
- Firebase service account key or logged-in session
- Supabase project reference and credentials
- Dev EHRbase credentials (for template export)

---

## Architecture Summary

### AWS Resources Created

| Resource | Type | Configuration | Purpose |
|----------|------|---------------|---------|
| VPC | Network | 10.0.0.0/20 (4,096 IPs) | Isolated network |
| Public Subnets | Network | 2x /22 (1,024 IPs each) | ALB placement |
| Private Subnets | Network | 2x /22 (1,024 IPs each) | ECS/RDS placement |
| Internet Gateway | Network | 1 | Public internet access |
| NAT Gateway | Network | 1 | Private outbound access |
| ALB | Load Balancer | Application Layer 7 | HTTP/HTTPS routing |
| ECS Cluster | Container | Fargate serverless | EHRbase containers |
| ECS Service | Container | 2-4 tasks auto-scaling | EHRbase instances |
| RDS PostgreSQL | Database | db.t3.medium, Multi-AZ | Production database |
| Secrets Manager | Security | 2 secrets | Credential storage |
| CloudWatch | Monitoring | Dashboard + 9 alarms | Observability |
| SNS | Notifications | 1 topic | Alert delivery |

### Multi-AZ Architecture

```
VPC 10.0.0.0/20
├── us-east-1a
│   ├── Public Subnet (10.0.0.0/22)  → ALB
│   ├── Private Subnet (10.0.8.0/22) → ECS Task 1, RDS Primary
├── us-east-1b
│   ├── Public Subnet (10.0.4.0/22)  → ALB
│   └── Private Subnet (10.0.12.0/22) → ECS Task 2, RDS Standby
```

---

## Network Configuration

### VPC and Subnets

**VPC CIDR:** 10.0.0.0/20 (4,096 total IPs)

**Subnet Allocation:**

| Name | CIDR | AZ | Type | IPs | Purpose |
|------|------|----|-|------|---------|
| public-1a | 10.0.0.0/22 | us-east-1a | Public | 1,024 | ALB, NAT Gateway |
| public-1b | 10.0.4.0/22 | us-east-1b | Public | 1,024 | ALB (Multi-AZ) |
| private-1a | 10.0.8.0/22 | us-east-1a | Private | 1,024 | ECS tasks, RDS primary |
| private-1b | 10.0.12.0/22 | us-east-1b | Private | 1,024 | ECS tasks, RDS standby |

**Why /22 Subnets?**
- 1,024 IP addresses per subnet (minus 5 AWS reserved)
- Supports 1,019 resources per subnet
- Room for growth beyond initial 2-4 ECS tasks
- No additional cost vs. smaller subnets

**Route Tables:**
- **Public RT:** 0.0.0.0/0 → Internet Gateway
- **Private RT:** 0.0.0.0/0 → NAT Gateway

---

## Phase 0: Pre-Flight Checks

**Duration:** 10-15 minutes
**Script:** `./00-prerequisites.sh`
**Cost Impact:** $0

### Step 0.1: Verify AWS CLI Installation

```bash
aws --version
```

**Expected Output:**
```
aws-cli/2.x.x Python/3.x.x Darwin/24.x.x botocore/2.x.x
```

**If not installed:**
```bash
# macOS
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Step 0.2: Configure AWS Credentials

```bash
aws configure
```

**Prompt responses:**
```
AWS Access Key ID [None]: YOUR_ACCESS_KEY_ID
AWS Secret Access Key [None]: YOUR_SECRET_ACCESS_KEY
Default region name [None]: us-east-1
Default output format [None]: json
```

**Validate configuration:**
```bash
aws sts get-caller-identity
```

**Expected Output:**
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

### Step 0.3: Verify Required CLI Tools

```bash
# Check all tools
firebase --version    # Should show version 13.x.x or higher
npx supabase --version  # Should show version 1.x.x or higher
psql --version        # Should show version 16.x or higher
jq --version          # Should show version 1.6 or higher
curl --version        # Should show version 7.x.x or higher
```

**If tools missing, install:**
```bash
# Firebase CLI
npm install -g firebase-tools

# Supabase CLI (via npx - no install needed)
npx supabase --version

# PostgreSQL client (macOS)
brew install postgresql@16

# jq (macOS)
brew install jq
```

### Step 0.4: Run Automated Prerequisites Script

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/aws-deployment
chmod +x 00-prerequisites.sh
./00-prerequisites.sh
```

**What it checks:**
1. ✅ AWS CLI installed and configured
2. ✅ AWS credentials valid with required permissions
3. ✅ Firebase CLI installed
4. ✅ Supabase CLI available
5. ✅ PostgreSQL client installed
6. ✅ jq installed for JSON parsing
7. ✅ All deployment scripts present and executable

**Expected Output:**
```
==========================================
EHRbase AWS Migration - Prerequisites Check
==========================================

✓ AWS CLI: aws-cli/2.x.x
✓ AWS credentials configured
✓ AWS account: 123456789012
✓ AWS region: us-east-1
✓ Firebase CLI: 13.x.x
✓ Supabase CLI: 1.x.x
✓ PostgreSQL client: psql 16.x
✓ jq: jq-1.6

==========================================
All Prerequisites Met!
==========================================

Next step: ./00-export-from-dev.sh
```

### Step 0.5: Review Cost Estimate

**Estimated monthly costs:**
- **RDS db.t3.medium (Multi-AZ):** $100
- **ECS Fargate (2-4 tasks, 2 vCPU, 4GB each):** $70-140
- **ALB:** $22
- **NAT Gateway:** $32
- **CloudWatch (Dashboard, Alarms, Logs):** $10-30
- **Data Transfer:** $5-15
- **Secrets Manager:** $1
- **Total:** ~$260/month (scales with traffic)

**Validation:** ✅ All prerequisites met, proceed to Phase 1

---

## Phase 1: Export Templates from Dev

**Duration:** 5-10 minutes
**Script:** `./00-export-from-dev.sh`
**Cost Impact:** $0

### Purpose

Export OpenEHR templates from your dev Proxmox EHRbase to ensure production uses the **exact same data structures**. This is **critical** for compatibility with Firebase Cloud Functions and Supabase Edge Functions.

### Step 1.1: Verify Dev EHRbase Accessibility

```bash
# Test dev EHRbase connection
curl -u "ehrbase-user:your-dev-password" \
  http://ehr.medzenhealth.app/ehrbase/rest/status

# Expected output: {"status": "OK"}
```

### Step 1.2: Run Export Script

```bash
chmod +x 00-export-from-dev.sh
./00-export-from-dev.sh
```

**Interactive prompts:**
```
Dev EHRbase URL: http://ehr.medzenhealth.app/ehrbase/rest
Username: ehrbase-user
Password: [hidden]
```

**What it does:**
1. Connects to dev EHRbase
2. Lists all available templates
3. Downloads each template as .opt (XML) file
4. Exports PostgreSQL schema (tables, functions, triggers)
5. Creates timestamped export directory: `dev-export-YYYYMMDD-HHMMSS/`

**Expected Output:**
```
==========================================
Dev Export Complete!
==========================================

Exported Resources:
  Templates: 12 templates
  Database Schema: schema.sql (45 KB)
  Export Directory: dev-export-20250129-143022/

Templates exported:
  - ehrbase.demographics.v1.opt
  - ehrbase.vital_signs.v1.opt
  - ehrbase.lab_results.v1.opt
  - ehrbase.prescriptions.v1.opt
  - ehrbase.immunizations.v1.opt
  - ehrbase.allergies.v1.opt
  - ehrbase.medical_history.v1.opt
  - (... 5 more)

Next step: ./01-setup-infrastructure.sh
```

### Step 1.3: Verify Export Completeness

```bash
# Check export directory
ls -lh dev-export-*/

# Expected files:
# - templates/ (directory with .opt files)
# - schema.sql
# - export-summary.txt
```

**Validation:** ✅ Templates exported successfully, proceed to Phase 2

---

## Phase 2: AWS Network Infrastructure

**Duration:** 15-20 minutes
**Script:** `./01-setup-infrastructure.sh`
**Cost Impact:** ~$32/month (NAT Gateway starts immediately)

### Purpose

Create the foundational AWS network infrastructure:
- VPC with DNS support
- 4 subnets across 2 availability zones
- Internet Gateway for public access
- NAT Gateway for private outbound access
- Route tables with proper routing
- Security groups for ALB, ECS, and RDS

### Step 2.1: Initialize Environment Configuration

```bash
chmod +x 01-setup-infrastructure.sh
./01-setup-infrastructure.sh
```

**Interactive prompts:**
```
AWS Region: us-east-1
Project Name: medzen-ehrbase
AWS Account: 123456789012

Continue with infrastructure setup? (y/N): y
```

### Step 2.2: VPC Creation

**Command executed:**
```bash
aws ec2 create-vpc \
  --cidr-block 10.0.0.0/20 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=medzen-ehrbase-vpc},{Key=Project,Value=MedZen}]' \
  --query 'Vpc.VpcId' \
  --output text \
  --region us-east-1
```

**Expected Output:**
```
✓ VPC created: vpc-0abc123def456789
✓ DNS support enabled
```

**What was created:**
- VPC with 4,096 IP addresses (10.0.0.0/20)
- DNS resolution enabled
- DNS hostnames enabled

### Step 2.3: Subnet Creation

**Four subnets created:**

```bash
# Public Subnet 1a
aws ec2 create-subnet \
  --vpc-id vpc-0abc123def456789 \
  --cidr-block 10.0.0.0/22 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=medzen-ehrbase-public-1a},{Key=Type,Value=public}]'

# Public Subnet 1b
aws ec2 create-subnet \
  --vpc-id vpc-0abc123def456789 \
  --cidr-block 10.0.4.0/22 \
  --availability-zone us-east-1b

# Private Subnet 1a
aws ec2 create-subnet \
  --vpc-id vpc-0abc123def456789 \
  --cidr-block 10.0.8.0/22 \
  --availability-zone us-east-1a

# Private Subnet 1b
aws ec2 create-subnet \
  --vpc-id vpc-0abc123def456789 \
  --cidr-block 10.0.12.0/22 \
  --availability-zone us-east-1b
```

**Expected Output:**
```
✓ Public subnet 1a created: subnet-0aaa111
✓ Public subnet 1b created: subnet-0bbb222
✓ Private subnet 1a created: subnet-0ccc333
✓ Private subnet 1b created: subnet-0ddd444
```

### Step 2.4: Internet Gateway

**Command:**
```bash
aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=medzen-ehrbase-igw}]'

aws ec2 attach-internet-gateway \
  --vpc-id vpc-0abc123def456789 \
  --internet-gateway-id igw-0xyz789
```

**Expected Output:**
```
✓ Internet Gateway created: igw-0xyz789
✓ Internet Gateway attached to VPC
```

### Step 2.5: NAT Gateway (⏳ Wait 2-3 minutes)

**Command:**
```bash
# Allocate Elastic IP
aws ec2 allocate-address \
  --domain vpc \
  --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=medzen-ehrbase-nat-eip}]'

# Create NAT Gateway
aws ec2 create-nat-gateway \
  --subnet-id subnet-0aaa111 \
  --allocation-id eipalloc-0rst456 \
  --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=medzen-ehrbase-nat}]'

# Wait for NAT Gateway to become available
aws ec2 wait nat-gateway-available --nat-gateway-ids nat-0uvw123
```

**Expected Output:**
```
✓ Elastic IP allocated: eipalloc-0rst456
✓ NAT Gateway created: nat-0uvw123
⏳ Waiting for NAT Gateway to become available (2-3 minutes)...
✓ NAT Gateway is now available
```

**Cost starts now:** $0.045/hour = $32/month

### Step 2.6: Route Tables

**Public Route Table:**
```bash
# Create public route table
aws ec2 create-route-table \
  --vpc-id vpc-0abc123def456789 \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=medzen-ehrbase-public-rt}]'

# Add route to Internet Gateway
aws ec2 create-route \
  --route-table-id rtb-0aaa111 \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id igw-0xyz789

# Associate with public subnets
aws ec2 associate-route-table --subnet-id subnet-0aaa111 --route-table-id rtb-0aaa111
aws ec2 associate-route-table --subnet-id subnet-0bbb222 --route-table-id rtb-0aaa111
```

**Private Route Table:**
```bash
# Create private route table
aws ec2 create-route-table \
  --vpc-id vpc-0abc123def456789 \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=medzen-ehrbase-private-rt}]'

# Add route to NAT Gateway
aws ec2 create-route \
  --route-table-id rtb-0bbb222 \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id nat-0uvw123

# Associate with private subnets
aws ec2 associate-route-table --subnet-id subnet-0ccc333 --route-table-id rtb-0bbb222
aws ec2 associate-route-table --subnet-id subnet-0ddd444 --route-table-id rtb-0bbb222
```

**Expected Output:**
```
✓ Public route table created: rtb-0aaa111
✓ Route to Internet Gateway added
✓ Public subnets associated with route table
✓ Private route table created: rtb-0bbb222
✓ Route to NAT Gateway added
✓ Private subnets associated with route table
```

### Step 2.7: Security Groups

**ALB Security Group (public-facing):**
```bash
aws ec2 create-security-group \
  --group-name medzen-ehrbase-alb-sg \
  --description "Security group for EHRbase ALB" \
  --vpc-id vpc-0abc123def456789

# Allow HTTP (port 80)
aws ec2 authorize-security-group-ingress \
  --group-id sg-0alb111 \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Allow HTTPS (port 443)
aws ec2 authorize-security-group-ingress \
  --group-id sg-0alb111 \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0
```

**ECS Security Group (private):**
```bash
aws ec2 create-security-group \
  --group-name medzen-ehrbase-ecs-sg \
  --description "Security group for EHRbase ECS tasks" \
  --vpc-id vpc-0abc123def456789

# Allow traffic from ALB on port 8080
aws ec2 authorize-security-group-ingress \
  --group-id sg-0ecs222 \
  --protocol tcp \
  --port 8080 \
  --source-group sg-0alb111

# Allow HTTPS for Docker image pulls
aws ec2 authorize-security-group-ingress \
  --group-id sg-0ecs222 \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0
```

**RDS Security Group (private):**
```bash
aws ec2 create-security-group \
  --group-name medzen-ehrbase-rds-sg \
  --description "Security group for EHRbase RDS database" \
  --vpc-id vpc-0abc123def456789

# Allow PostgreSQL from ECS only
aws ec2 authorize-security-group-ingress \
  --group-id sg-0rds333 \
  --protocol tcp \
  --port 5432 \
  --source-group sg-0ecs222
```

**Expected Output:**
```
✓ ALB security group created: sg-0alb111
✓ ALB ingress rules configured (ports 80, 443)
✓ ECS security group created: sg-0ecs222
✓ ECS ingress rules configured
✓ RDS security group created: sg-0rds333
✓ RDS ingress rules configured (port 5432 from ECS)
```

### Step 2.8: Summary

**Resources Created:**
```
VPC:               vpc-0abc123def456789
Public Subnets:    subnet-0aaa111, subnet-0bbb222
Private Subnets:   subnet-0ccc333, subnet-0ddd444
Internet Gateway:  igw-0xyz789
NAT Gateway:       nat-0uvw123
Public Route Table: rtb-0aaa111
Private Route Table: rtb-0bbb222
ALB Security Group: sg-0alb111
ECS Security Group: sg-0ecs222
RDS Security Group: sg-0rds333
```

**Configuration saved to `.env` file**

**Validation:** ✅ Network infrastructure ready, proceed to Phase 3

---

## Phase 3: RDS PostgreSQL Database

**Duration:** 15-20 minutes (plus 10-15 min for RDS creation)
**Script:** `./02-setup-database.sh`
**Cost Impact:** ~$100/month (Multi-AZ db.t3.medium)

### Purpose

Create a production-grade PostgreSQL 16 database with:
- Multi-AZ deployment for high availability
- Encrypted storage (AES-256)
- Automated backups (7-day retention)
- Performance Insights enabled
- Secure credential storage in AWS Secrets Manager

### Step 3.1: Run Database Setup Script

```bash
chmod +x 02-setup-database.sh
./02-setup-database.sh
```

**Interactive prompts:**
```
Continue with database creation? (y/N): y
```

### Step 3.2: Create DB Subnet Group

**Command:**
```bash
aws rds create-db-subnet-group \
  --db-subnet-group-name medzen-ehrbase-db-subnet-group \
  --db-subnet-group-description "Subnet group for EHRbase RDS" \
  --subnet-ids subnet-0ccc333 subnet-0ddd444 \
  --region us-east-1
```

**Expected Output:**
```
✓ DB subnet group created: medzen-ehrbase-db-subnet-group
  Subnets: subnet-0ccc333 (us-east-1a), subnet-0ddd444 (us-east-1b)
```

### Step 3.3: Generate Secure Passwords

**Script auto-generates passwords:**
```bash
# Admin password (32 chars, alphanumeric + special chars)
DB_ADMIN_PASS=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)

# Restricted user password
DB_USER_PASS=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-32)
```

**Passwords stored in AWS Secrets Manager (never in .env):**

```bash
# Create secret for admin credentials
aws secretsmanager create-secret \
  --name medzen-ehrbase/db_admin \
  --description "EHRbase PostgreSQL admin credentials" \
  --secret-string "{\"username\":\"ehrbase_admin\",\"password\":\"${DB_ADMIN_PASS}\"}" \
  --region us-east-1

# Create secret for restricted user credentials
aws secretsmanager create-secret \
  --name medzen-ehrbase/db_user \
  --description "EHRbase PostgreSQL restricted user credentials" \
  --secret-string "{\"username\":\"ehrbase_restricted\",\"password\":\"${DB_USER_PASS}\"}" \
  --region us-east-1
```

**Expected Output:**
```
✓ Generated secure passwords
✓ Admin credentials stored in Secrets Manager: medzen-ehrbase/db_admin
✓ User credentials stored in Secrets Manager: medzen-ehrbase/db_user
```

### Step 3.4: Create RDS Instance (⏳ 10-15 minutes)

**Command:**
```bash
aws rds create-db-instance \
  --db-instance-identifier medzen-ehrbase-db \
  --db-instance-class db.t3.medium \
  --engine postgres \
  --engine-version 16.1 \
  --master-username ehrbase_admin \
  --master-user-password "${DB_ADMIN_PASS}" \
  --allocated-storage 100 \
  --storage-type gp3 \
  --storage-encrypted \
  --iops 3000 \
  --multi-az \
  --db-subnet-group-name medzen-ehrbase-db-subnet-group \
  --vpc-security-group-ids sg-0rds333 \
  --backup-retention-period 7 \
  --preferred-backup-window "03:00-04:00" \
  --preferred-maintenance-window "sun:04:00-sun:05:00" \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --enable-cloudwatch-logs-exports '["postgresql"]' \
  --publicly-accessible false \
  --region us-east-1
```

**What's being created:**
- **Instance Class:** db.t3.medium (2 vCPU, 4GB RAM)
- **Storage:** 100GB GP3 (3,000 IOPS baseline, scalable to 16,000)
- **Multi-AZ:** Yes (automatic failover to standby in another AZ)
- **Encryption:** AES-256 at rest
- **Backups:** Automated daily backups, 7-day retention
- **Performance Insights:** 7-day metric retention
- **CloudWatch Logs:** PostgreSQL logs streamed to CloudWatch

**Expected Output:**
```
⏳ Creating RDS instance: medzen-ehrbase-db
⏳ This will take 10-15 minutes...
```

### Step 3.5: Wait for RDS Availability

**Command:**
```bash
aws rds wait db-instance-available \
  --db-instance-identifier medzen-ehrbase-db \
  --region us-east-1
```

**Progress monitoring:**
```
⏳ Waiting for RDS instance to become available...
⏳ Status: creating (2 minutes elapsed)
⏳ Status: creating (5 minutes elapsed)
⏳ Status: backing-up (10 minutes elapsed)
✓ RDS instance is now available (12 minutes total)
```

### Step 3.6: Retrieve Database Endpoint

**Command:**
```bash
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier medzen-ehrbase-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text \
  --region us-east-1)
```

**Expected Output:**
```
✓ Database endpoint: medzen-ehrbase-db.c1abc2def3g.us-east-1.rds.amazonaws.com
```

**Saved to `.env`:**
```bash
RDS_ENDPOINT=medzen-ehrbase-db.c1abc2def3g.us-east-1.rds.amazonaws.com
```

### Step 3.7: Test Database Connection

**Command:**
```bash
# Retrieve password from Secrets Manager
DB_ADMIN_PASS=$(aws secretsmanager get-secret-value \
  --secret-id medzen-ehrbase/db_admin \
  --query SecretString \
  --output text | jq -r '.password')

# Test connection
PGPASSWORD=$DB_ADMIN_PASS psql \
  -h $RDS_ENDPOINT \
  -U ehrbase_admin \
  -d postgres \
  -c "SELECT version();"
```

**Expected Output:**
```
✓ Database connection successful
PostgreSQL 16.1 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 7.3.1 20180712 (Red Hat 7.3.1-12), 64-bit
```

### Step 3.8: Summary

**RDS Configuration:**
```
DB Identifier:  medzen-ehrbase-db
Endpoint:       medzen-ehrbase-db.c1abc2def3g.us-east-1.rds.amazonaws.com:5432
Engine:         PostgreSQL 16.1
Instance Class: db.t3.medium (2 vCPU, 4GB RAM)
Storage:        100GB GP3 (3,000 IOPS)
Multi-AZ:       Enabled
Encryption:     Enabled (AES-256)
Backups:        7-day retention
Cost:           ~$100/month
```

**Credentials:**
```
Admin:       ehrbase_admin (in Secrets Manager)
Restricted:  ehrbase_restricted (in Secrets Manager)
```

**Validation:** ✅ Database created and accessible, proceed to Phase 4

---

## Phase 4: Initialize Database Schema

**Duration:** 5-10 minutes
**Script:** `./03-init-database.sh`
**Cost Impact:** $0

### Purpose

Initialize the PostgreSQL database with EHRbase-required schema:
- Create `ehrbase` database with UTF-8 encoding
- Create `ehr` and `ext` schemas
- Install `uuid-ossp` extension
- Create `ehrbase_restricted` user with limited permissions
- Configure database settings for EHRbase

### Step 4.1: Run Database Initialization Script

```bash
chmod +x 03-init-database.sh
./03-init-database.sh
```

**Interactive prompts:**
```
Initialize database schema? (y/N): y
```

### Step 4.2: Database Creation

**SQL executed:**
```sql
-- Create ehrbase database
CREATE DATABASE ehrbase
  ENCODING 'UTF-8'
  LOCALE 'C'
  TEMPLATE template0;

-- Connect to ehrbase database
\c ehrbase
```

**Expected Output:**
```
✓ Database 'ehrbase' created with UTF-8 encoding
```

### Step 4.3: Schema Creation

**SQL executed:**
```sql
-- Create ehr schema (main EHRbase schema)
CREATE SCHEMA IF NOT EXISTS ehr AUTHORIZATION ehrbase_admin;

-- Create ext schema (extensions)
CREATE SCHEMA IF NOT EXISTS ext AUTHORIZATION ehrbase_admin;

-- Set default schemas
ALTER DATABASE ehrbase SET search_path TO ehr, ext, public;
```

**Expected Output:**
```
✓ Schema 'ehr' created
✓ Schema 'ext' created
✓ Default search_path configured
```

### Step 4.4: Install Extensions

**SQL executed:**
```sql
-- Install UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA ext;
```

**Expected Output:**
```
✓ Extension 'uuid-ossp' installed in schema 'ext'
```

### Step 4.5: Configure Database Settings

**SQL executed:**
```sql
-- Set interval style for ISO 8601 compliance
ALTER DATABASE ehrbase SET intervalstyle = 'iso_8601';

-- Set timezone to UTC
ALTER DATABASE ehrbase SET timezone = 'UTC';
```

**Expected Output:**
```
✓ Database settings configured for EHRbase
```

### Step 4.6: Create Restricted User

**SQL executed:**
```sql
-- Retrieve restricted user password from Secrets Manager
-- (password retrieved securely, not shown in logs)

-- Create restricted user
CREATE ROLE ehrbase_restricted WITH LOGIN PASSWORD :'db_user_password';

-- Grant CONNECT privilege
GRANT CONNECT ON DATABASE ehrbase TO ehrbase_restricted;

-- Grant USAGE on schemas
GRANT USAGE ON SCHEMA ehr, ext TO ehrbase_restricted;

-- Note: Table-level permissions will be granted by EHRbase on first startup
```

**Expected Output:**
```
✓ User 'ehrbase_restricted' created
✓ Basic permissions granted
✓ EHRbase will grant table permissions on first startup
```

### Step 4.7: Verify Schema

**Verification commands:**
```bash
# List databases
PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -l

# List schemas in ehrbase database
PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -c "\dn"

# List extensions
PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -c "\dx"

# List users
PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -c "\du"
```

**Expected Output:**
```
Databases:
  ehrbase | ehrbase_admin | UTF8

Schemas:
  ehr | ehrbase_admin
  ext | ehrbase_admin

Extensions:
  uuid-ossp | ext

Users:
  ehrbase_admin
  ehrbase_restricted
```

### Step 4.8: Test Restricted User Connection

**Command:**
```bash
# Retrieve restricted user password
DB_USER_PASS=$(aws secretsmanager get-secret-value \
  --secret-id medzen-ehrbase/db_user \
  --query SecretString \
  --output text | jq -r '.password')

# Test connection as restricted user
PGPASSWORD=$DB_USER_PASS psql \
  -h $RDS_ENDPOINT \
  -U ehrbase_restricted \
  -d ehrbase \
  -c "SELECT current_database(), current_user;"
```

**Expected Output:**
```
✓ Restricted user connection successful
 current_database | current_user
------------------+-------------------
 ehrbase          | ehrbase_restricted
```

### Step 4.9: Summary

**Database Initialization Complete:**
```
Database:   ehrbase (UTF-8, C locale)
Schemas:    ehr, ext
Extensions: uuid-ossp
Users:      ehrbase_admin (superuser)
            ehrbase_restricted (limited)
Settings:   intervalstyle=iso_8601
            timezone=UTC
            search_path=ehr,ext,public
```

**Note:** EHRbase will create its tables automatically on first startup. The database is now ready for EHRbase deployment.

**Validation:** ✅ Database schema initialized, proceed to Phase 5

---

## Phase 5: Deploy EHRbase on ECS Fargate

**Duration:** 20-30 minutes
**Script:** `./04-setup-ecs.sh`
**Cost Impact:** ~$70-140/month (2-4 Fargate tasks) + $22/month (ALB)

### Purpose

Deploy EHRbase 2.11.0 as containerized tasks on ECS Fargate with:
- Application Load Balancer (ALB) for HTTP routing
- Auto-scaling (2-4 tasks based on CPU)
- Health checks and automated recovery
- CloudWatch logging
- Secure credential injection via environment variables

### Step 5.1: Run ECS Setup Script

```bash
chmod +x 04-setup-ecs.sh
./04-setup-ecs.sh
```

**Interactive prompts:**
```
Continue with ECS setup? (y/N): y
```

### Step 5.2: Create ECS Cluster

**Command:**
```bash
aws ecs create-cluster \
  --cluster-name medzen-ehrbase-cluster \
  --capacity-providers FARGATE FARGATE_SPOT \
  --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 \
  --region us-east-1
```

**Expected Output:**
```
✓ ECS cluster created: medzen-ehrbase-cluster
  Capacity providers: FARGATE, FARGATE_SPOT
```

### Step 5.3: Create ALB

**Command:**
```bash
aws elbv2 create-load-balancer \
  --name medzen-ehrbase-alb \
  --subnets subnet-0aaa111 subnet-0bbb222 \
  --security-groups sg-0alb111 \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4 \
  --region us-east-1
```

**Expected Output:**
```
✓ Application Load Balancer created: medzen-ehrbase-alb
  DNS: medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com
  Subnets: subnet-0aaa111 (us-east-1a), subnet-0bbb222 (us-east-1b)
```

**ALB DNS saved to `.env`:**
```bash
ALB_DNS=medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com
```

### Step 5.4: Create Target Group

**Command:**
```bash
aws elbv2 create-target-group \
  --name medzen-ehrbase-tg \
  --protocol HTTP \
  --port 8080 \
  --vpc-id vpc-0abc123def456789 \
  --target-type ip \
  --health-check-enabled \
  --health-check-protocol HTTP \
  --health-check-path /ehrbase/rest/status \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --matcher HttpCode=200 \
  --region us-east-1
```

**Expected Output:**
```
✓ Target group created: medzen-ehrbase-tg
  Health check: /ehrbase/rest/status (30s interval, 200 OK)
```

### Step 5.5: Create ALB Listener

**Command:**
```bash
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/medzen-ehrbase-alb/abc123 \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/medzen-ehrbase-tg/def456 \
  --region us-east-1
```

**Expected Output:**
```
✓ ALB listener created (HTTP port 80)
  Forwards to: medzen-ehrbase-tg
```

### Step 5.6: Create CloudWatch Log Group

**Command:**
```bash
aws logs create-log-group \
  --log-group-name /ecs/medzen-ehrbase \
  --region us-east-1

aws logs put-retention-policy \
  --log-group-name /ecs/medzen-ehrbase \
  --retention-in-days 7 \
  --region us-east-1
```

**Expected Output:**
```
✓ CloudWatch log group created: /ecs/medzen-ehrbase
  Retention: 7 days
```

### Step 5.7: Create IAM Roles

**Task Execution Role (pulls image, writes logs):**
```bash
# Create role
aws iam create-role \
  --role-name medzen-ehrbase-task-execution-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

# Attach policies
aws iam attach-role-policy \
  --role-name medzen-ehrbase-task-execution-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

aws iam attach-role-policy \
  --role-name medzen-ehrbase-task-execution-role \
  --policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite
```

**Task Role (application runtime permissions):**
```bash
aws iam create-role \
  --role-name medzen-ehrbase-task-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ecs-tasks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'
```

**Expected Output:**
```
✓ Task execution role created: medzen-ehrbase-task-execution-role
✓ Task role created: medzen-ehrbase-task-role
```

### Step 5.8: Create ECS Task Definition

**Retrieve database password from Secrets Manager:**
```bash
DB_USER_PASS=$(aws secretsmanager get-secret-value \
  --secret-id medzen-ehrbase/db_user \
  --query SecretString \
  --output text | jq -r '.password')
```

**Create task definition JSON:**
```json
{
  "family": "medzen-ehrbase",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "2048",
  "memory": "4096",
  "executionRoleArn": "arn:aws:iam::123456789012:role/medzen-ehrbase-task-execution-role",
  "taskRoleArn": "arn:aws:iam::123456789012:role/medzen-ehrbase-task-role",
  "containerDefinitions": [
    {
      "name": "ehrbase",
      "image": "ehrbase/ehrbase:2.11.0",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "SPRING_DATASOURCE_URL",
          "value": "jdbc:postgresql://medzen-ehrbase-db.c1abc2def3g.us-east-1.rds.amazonaws.com:5432/ehrbase"
        },
        {
          "name": "SPRING_DATASOURCE_USERNAME",
          "value": "ehrbase_restricted"
        },
        {
          "name": "SPRING_DATASOURCE_PASSWORD",
          "value": "DB_USER_PASS_HERE"
        },
        {
          "name": "EHRBASE_REST_CONTEXT_PATH",
          "value": "/ehrbase/rest"
        },
        {
          "name": "SECURITY_AUTHTYPE",
          "value": "BASIC"
        },
        {
          "name": "SECURITY_AUTHUSER",
          "value": "ehrbase-user"
        },
        {
          "name": "SECURITY_AUTHPASSWORD",
          "value": "ehrbase-password"
        },
        {
          "name": "SPRING_PROFILES_ACTIVE",
          "value": "docker"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/medzen-ehrbase",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "curl -f http://localhost:8080/ehrbase/rest/status || exit 1"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ]
}
```

**Register task definition:**
```bash
aws ecs register-task-definition \
  --cli-input-json file://task-definition.json \
  --region us-east-1
```

**Expected Output:**
```
✓ Task definition registered: medzen-ehrbase:1
  CPU: 2048 (2 vCPU)
  Memory: 4096 MB (4 GB)
  Container: ehrbase/ehrbase:2.11.0
```

### Step 5.9: Create ECS Service

**Command:**
```bash
aws ecs create-service \
  --cluster medzen-ehrbase-cluster \
  --service-name medzen-ehrbase-service \
  --task-definition medzen-ehrbase:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-0ccc333,subnet-0ddd444],securityGroups=[sg-0ecs222],assignPublicIp=DISABLED}" \
  --load-balancers "targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/medzen-ehrbase-tg/def456,containerName=ehrbase,containerPort=8080" \
  --health-check-grace-period-seconds 60 \
  --region us-east-1
```

**Expected Output:**
```
✓ ECS service created: medzen-ehrbase-service
  Desired count: 2 tasks
  Launch type: FARGATE
  Private subnets: subnet-0ccc333, subnet-0ddd444
```

### Step 5.10: Configure Auto-Scaling

**Register scalable target:**
```bash
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/medzen-ehrbase-cluster/medzen-ehrbase-service \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 2 \
  --max-capacity 4 \
  --region us-east-1
```

**Create scaling policy (target CPU 70%):**
```bash
aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --scalable-dimension ecs:service:DesiredCount \
  --resource-id service/medzen-ehrbase-cluster/medzen-ehrbase-service \
  --policy-name cpu-scaling-policy \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
    },
    "ScaleInCooldown": 300,
    "ScaleOutCooldown": 60
  }' \
  --region us-east-1
```

**Expected Output:**
```
✓ Auto-scaling configured
  Min tasks: 2
  Max tasks: 4
  Target CPU: 70%
  Scale out cooldown: 60s
  Scale in cooldown: 300s
```

### Step 5.11: Wait for Tasks to Start (⏳ 3-5 minutes)

**Monitor task status:**
```bash
aws ecs describe-services \
  --cluster medzen-ehrbase-cluster \
  --services medzen-ehrbase-service \
  --query 'services[0].[runningCount,desiredCount]' \
  --output text \
  --region us-east-1
```

**Expected progression:**
```
⏳ Starting ECS tasks...
⏳ Running: 0/2 (1 minute elapsed)
⏳ Running: 1/2 (2 minutes elapsed)
⏳ Running: 2/2 (3 minutes elapsed)
✓ All tasks running and healthy
```

### Step 5.12: Wait for Target Health (⏳ 2-3 minutes)

**Monitor target health:**
```bash
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/medzen-ehrbase-tg/def456 \
  --region us-east-1
```

**Expected progression:**
```
⏳ Waiting for targets to become healthy...
⏳ Target 1: initial (0 minutes elapsed)
⏳ Target 1: initial, Target 2: initial (1 minute elapsed)
⏳ Target 1: healthy, Target 2: initial (2 minutes elapsed)
✓ All targets healthy (2/2)
```

### Step 5.13: Test EHRbase API

**Command:**
```bash
# Test status endpoint
curl http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/status
```

**Expected Output:**
```json
{
  "status": "OK",
  "version": "2.11.0"
}
```

**Test with authentication:**
```bash
curl -u "ehrbase-user:ehrbase-password" \
  http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/openehr/v1/definition/template/adl1.4
```

**Expected Output:**
```json
[]
```
*(Empty array is expected - no templates imported yet)*

### Step 5.14: Summary

**ECS Deployment Complete:**
```
Cluster:        medzen-ehrbase-cluster
Service:        medzen-ehrbase-service
Tasks:          2/2 running (auto-scaling 2-4)
ALB:            medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com
Health Check:   /ehrbase/rest/status (all healthy)
Logs:           /ecs/medzen-ehrbase (CloudWatch)
Auto-scaling:   CPU target 70%
```

**Access URLs:**
```
Status:     http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/status
Templates:  http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/openehr/v1/definition/template/adl1.4
```

**Validation:** ✅ EHRbase deployed and accessible, proceed to Phase 6

---

## Phase 6: Import OpenEHR Templates

**Duration:** 10-15 minutes
**Script:** `./04b-import-templates.sh`
**Cost Impact:** $0

### Purpose

Import OpenEHR templates from dev export to production EHRbase. This ensures production uses the **same data structures** as your existing Firebase/Supabase integration expects.

### Step 6.1: Verify Templates Exported

```bash
# Check for most recent dev export
ls -lht dev-export-*/templates/

# Expected output:
# -rw-r--r--  ehrbase.demographics.v1.opt
# -rw-r--r--  ehrbase.vital_signs.v1.opt
# -rw-r--r--  ehrbase.lab_results.v1.opt
# ... (and more .opt files)
```

### Step 6.2: Run Template Import Script

```bash
chmod +x 04b-import-templates.sh
./04b-import-templates.sh
```

**Script automatically finds most recent export directory**

### Step 6.3: Verify EHRbase Ready

**Script checks EHRbase status (max 30 retries, 10s each):**
```bash
curl -u "ehrbase-user:ehrbase-password" \
  http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/status
```

**Expected Output:**
```
Testing EHRbase connection...
✓ EHRbase is responding (HTTP 200)
```

### Step 6.4: Import Each Template

**For each .opt file in templates directory:**
```bash
# Example: ehrbase.vital_signs.v1.opt

# Check if template already exists
curl -s -u "ehrbase-user:ehrbase-password" \
  http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/openehr/v1/definition/template/adl1.4/ehrbase.vital_signs.v1

# If not exists (HTTP 404), import it
curl -X POST \
  -u "ehrbase-user:ehrbase-password" \
  -H "Content-Type: application/xml" \
  --data-binary @ehrbase.vital_signs.v1.opt \
  http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/openehr/v1/definition/template/adl1.4
```

**Expected Output (per template):**
```
Importing: ehrbase.demographics.v1
  ✓ Imported successfully

Importing: ehrbase.vital_signs.v1
  ✓ Imported successfully

Importing: ehrbase.lab_results.v1
  ⚠ Template already exists - skipping

... (continues for all templates)
```

### Step 6.5: Verify Template Imports

**Command:**
```bash
curl -u "ehrbase-user:ehrbase-password" \
  http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/openehr/v1/definition/template/adl1.4
```

**Expected Output:**
```json
[
  {
    "template_id": "ehrbase.demographics.v1",
    "created_timestamp": "2025-01-29T15:30:00.000Z"
  },
  {
    "template_id": "ehrbase.vital_signs.v1",
    "created_timestamp": "2025-01-29T15:30:01.000Z"
  },
  {
    "template_id": "ehrbase.lab_results.v1",
    "created_timestamp": "2025-01-29T15:30:02.000Z"
  }
  // ... more templates
]
```

### Step 6.6: Summary

**Template Import Complete:**
```
Import Summary:
  Imported:  12 templates
  Skipped:   0 (already existed)
  Failed:    0
  Total:     12

Templates in production:
  - ehrbase.demographics.v1
  - ehrbase.vital_signs.v1
  - ehrbase.lab_results.v1
  - ehrbase.prescriptions.v1
  - ehrbase.immunizations.v1
  - ehrbase.allergies.v1
  - ehrbase.medical_history.v1
  - ehrbase.lab_results_extended.v1
  - ehrbase.clinical_notes.v1
  - ehrbase.appointments.v1
  - ehrbase.procedures.v1
  - ehrbase.diagnoses.v1
```

**Validation:** ✅ All templates imported, proceed to Phase 7

---

## Phase 7: Update Firebase/Supabase Integrations

**Duration:** 15-20 minutes
**Script:** `./05-update-integrations.sh`
**Cost Impact:** $0

### Purpose

Update Firebase Cloud Functions and Supabase Edge Functions to use the **production AWS EHRbase** endpoint. This requires NO code changes - only configuration updates.

### Step 7.1: Run Integration Update Script

```bash
chmod +x 05-update-integrations.sh
./05-update-integrations.sh
```

**Script displays production configuration:**
```
Production EHRbase Configuration:
  URL:      http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest
  Username: ehrbase-user
  Password: [stored in AWS Secrets Manager]
```

### Step 7.2: Update Firebase Cloud Functions

**Interactive prompts:**
```
Current Firebase project: medzen-bf20e

Update Firebase Cloud Functions config for this project? (y/N): y
```

**Configuration command executed:**
```bash
firebase functions:config:set \
  ehrbase.url="http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest" \
  ehrbase.username="ehrbase-user" \
  ehrbase.password="ehrbase-password"
```

**Expected Output:**
```
✓ Firebase configuration updated

Functions affected:
  - onUserCreated (creates EHR when user signs up)
  - onUserDeleted (cleanup operations)
```

**Deploy prompt:**
```
Deploy Firebase Functions now? (y/N): y
```

**If yes, deployment command:**
```bash
cd firebase/functions
firebase deploy --only functions
```

**Expected Output:**
```
⏳ Deploying functions...
✓ functions[onUserCreated(us-central1)] deployed
✓ functions[onUserDeleted(us-central1)] deployed

Functions deployed in 45 seconds
```

### Step 7.3: Update Supabase Edge Functions

**Configuration command executed:**
```bash
npx supabase secrets set \
  EHRBASE_URL="http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest" \
  EHRBASE_USERNAME="ehrbase-user" \
  EHRBASE_PASSWORD="ehrbase-password"
```

**Expected Output:**
```
✓ Supabase secrets updated

Updated secrets:
  - EHRBASE_URL
  - EHRBASE_USERNAME
  - EHRBASE_PASSWORD
```

**Functions affected:**
```
Edge functions that use EHRbase:
  - sync-to-ehrbase (processes ehrbase_sync_queue)
```

**Deploy prompt:**
```
Redeploy sync-to-ehrbase function? (y/N): y
```

**If yes, deployment command:**
```bash
npx supabase functions deploy sync-to-ehrbase
```

**Expected Output:**
```
⏳ Deploying edge function...
✓ sync-to-ehrbase deployed
  Version: 2025-01-29T15:45:00.000Z
```

### Step 7.4: Verify Configuration

**Test EHRbase connectivity:**
```bash
# Test with credentials
curl -s -w "\n%{http_code}\n" \
  -u "ehrbase-user:ehrbase-password" \
  "http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/status"
```

**Expected Output:**
```
{"status":"OK","version":"2.11.0"}
200
```

**Test template endpoint:**
```bash
curl -s -w "\n%{http_code}\n" \
  -u "ehrbase-user:ehrbase-password" \
  "http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/openehr/v1/definition/template/adl1.4"
```

**Expected Output:**
```
[{"template_id":"ehrbase.demographics.v1",...}, ...]
200
```

### Step 7.5: Configuration Summary Created

**Script creates `integration-config-summary.md`:**
```markdown
# Integration Configuration Summary

**Date:** 2025-01-29
**AWS EHRbase Endpoint:** http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest

## Production Configuration

### EHRbase Details
- URL: http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest
- Username: ehrbase-user
- Password: [Stored in AWS Secrets Manager]

### Firebase Cloud Functions
- onUserCreated: Creates EHR in EHRbase when user signs up
- onUserDeleted: Cleanup operations

### Supabase Edge Functions
- sync-to-ehrbase: Processes ehrbase_sync_queue to sync data

## Verification Steps
1. Test EHRbase API
2. Test Firebase Function (create test user)
3. Test Supabase Sync (insert test data)
4. Run comprehensive validation

## Rollback Instructions
(Instructions for reverting to dev environment if issues occur)
```

**Expected Output:**
```
✓ Configuration summary saved: integration-config-summary.md
```

### Step 7.6: Summary

**Integration Update Complete:**
```
Configuration Updated:
  ✓ Firebase Cloud Functions
  ✓ Supabase Edge Functions

Production EHRbase:
  URL:      http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest
  Status:   Active
  Auth:     HTTP Basic (ehrbase-user)

Important:
  - Test end-to-end user creation flow
  - Monitor Cloud Function and Edge Function logs
  - Verify EHR sync queue processing
  - Keep integration-config-summary.md for reference
```

**Validation:** ✅ Integrations updated, proceed to Phase 8

---

## Phase 8: Comprehensive Validation

**Duration:** 20-30 minutes
**Script:** `./06-validate-deployment.sh`
**Cost Impact:** $0

### Purpose

Run comprehensive tests across all AWS infrastructure, database, EHRbase API, and integration points to ensure production readiness.

### Test Suites

1. **AWS Infrastructure** (5 tests)
2. **Database** (4 tests)
3. **EHRbase API** (6 tests)
4. **Integration** (3 tests - optional)
5. **Performance** (2 tests)

**Total: 20 tests**

### Step 8.1: Run Validation Script

```bash
chmod +x 06-validate-deployment.sh
./06-validate-deployment.sh
```

### Step 8.2: Test Suite 1 - AWS Infrastructure

**VPC Test:**
```bash
aws ec2 describe-vpcs \
  --vpc-ids vpc-0abc123def456789 \
  --query 'Vpcs[0].State' \
  --region us-east-1
```
**Expected:** `available` ✅

**RDS Test:**
```bash
aws rds describe-db-instances \
  --db-instance-identifier medzen-ehrbase-db \
  --query 'DBInstances[0].DBInstanceStatus' \
  --region us-east-1
```
**Expected:** `available` ✅

**ECS Cluster Test:**
```bash
aws ecs describe-clusters \
  --clusters medzen-ehrbase-cluster \
  --query 'clusters[0].status' \
  --region us-east-1
```
**Expected:** `ACTIVE` ✅

**ECS Service Test:**
```bash
aws ecs describe-services \
  --cluster medzen-ehrbase-cluster \
  --services medzen-ehrbase-service \
  --query 'services[0].runningCount' \
  --region us-east-1
```
**Expected:** `2` or higher ✅

**ALB Test:**
```bash
aws elbv2 describe-load-balancers \
  --names medzen-ehrbase-alb \
  --query 'LoadBalancers[0].State.Code' \
  --region us-east-1
```
**Expected:** `active` ✅

**Expected Output:**
```
==========================================
Test Suite 1: AWS Infrastructure
==========================================

✓ VPC is available
✓ RDS instance is available
✓ ECS cluster is active
✓ ECS service has 2 running tasks
✓ Application Load Balancer is active
```

### Step 8.3: Test Suite 2 - Database

**Connection Test:**
```bash
PGPASSWORD=$DB_ADMIN_PASS psql \
  -h $RDS_ENDPOINT \
  -U ehrbase_admin \
  -d ehrbase \
  -c "SELECT 1;"
```
**Expected:** Connection successful ✅

**Schemas Test:**
```sql
SELECT COUNT(*) FROM information_schema.schemata
WHERE schema_name IN ('ehr', 'ext');
```
**Expected:** `2` ✅

**Extensions Test:**
```sql
SELECT COUNT(*) FROM pg_extension WHERE extname = 'uuid-ossp';
```
**Expected:** `1` ✅

**Users Test:**
```sql
SELECT COUNT(*) FROM pg_roles
WHERE rolname IN ('ehrbase_admin', 'ehrbase_restricted');
```
**Expected:** `2` ✅

**Expected Output:**
```
==========================================
Test Suite 2: Database
==========================================

✓ Database connection successful
✓ Required schemas exist (ehr, ext)
✓ Required extension installed (uuid-ossp)
✓ Required users exist
```

### Step 8.4: Test Suite 3 - EHRbase API

**Status Endpoint Test:**
```bash
curl -s -w "\n%{http_code}" \
  -u "ehrbase-user:ehrbase-password" \
  "http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/status"
```
**Expected:** HTTP 200 ✅

**OpenEHR API Test:**
```bash
curl -s -w "\n%{http_code}" \
  -u "ehrbase-user:ehrbase-password" \
  "http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/openehr/v1/definition/template/adl1.4"
```
**Expected:** HTTP 200, JSON array with templates ✅

**Authentication Test:**
```bash
curl -s -w "%{http_code}" -o /dev/null \
  "http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/status"
```
**Expected:** HTTP 401 (authentication required) ✅

**EHR Creation Test:**
```bash
curl -s -w "\n%{http_code}" \
  -u "ehrbase-user:ehrbase-password" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "_type":"EHR_STATUS",
    "subject":{
      "external_ref":{
        "id":{"_type":"GENERIC_ID","value":"test-123456","scheme":"id_scheme"},
        "namespace":"examples",
        "type":"PERSON"
      }
    },
    "is_queryable":true,
    "is_modifiable":true
  }' \
  "http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/openehr/v1/ehr"
```
**Expected:** HTTP 201, EHR ID returned ✅

**Expected Output:**
```
==========================================
Test Suite 3: EHRbase API
==========================================

✓ Status endpoint accessible
✓ OpenEHR API endpoint accessible
✓ Templates available (12 templates)
✓ Authentication is enforced
✓ EHR creation successful
✓ EHR ID generated: 12345678-abcd-1234-abcd-123456789abc
```

### Step 8.5: Test Suite 4 - Integration (Optional)

**Firebase Functions Config Test:**
```bash
firebase functions:config:get
```
**Expected:** Config includes `ehrbase.url` matching production ✅

**Supabase Secrets Test:**
```bash
npx supabase secrets list
```
**Expected:** List includes `EHRBASE_URL`, `EHRBASE_USERNAME`, `EHRBASE_PASSWORD` ✅

**Expected Output:**
```
==========================================
Test Suite 4: Integration (Optional)
==========================================

Testing Firebase configuration...
✓ Firebase configured with production URL

Testing Supabase configuration...
✓ Supabase has EHRBASE_URL secret
✓ Supabase has EHRBASE_USERNAME secret
✓ Supabase has EHRBASE_PASSWORD secret
```

### Step 8.6: Test Suite 5 - Performance

**Response Time Test:**
```bash
curl -s -w "%{time_total}" -o /dev/null \
  -u "ehrbase-user:ehrbase-password" \
  "http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/status"
```
**Expected:** < 2.0 seconds ✅

**Concurrent Requests Test:**
```bash
# Run 10 concurrent requests
for i in {1..10}; do
  curl -s -o /dev/null -w "%{http_code}\n" \
    -u "ehrbase-user:ehrbase-password" \
    "http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest/status" &
done
wait
```
**Expected:** 9/10 or 10/10 successful ✅

**Expected Output:**
```
==========================================
Test Suite 5: Performance
==========================================

Measuring response time...
✓ Response time acceptable (450ms)

Testing concurrent requests...
✓ Concurrent requests handled (10/10 successful)
```

### Step 8.7: Validation Summary

**Expected Final Output:**
```
==========================================
Validation Complete!
==========================================

Test Results:
  Total Tests:  20
  Passed:       20
  Failed:       0
  Pass Rate:    100.0%

✓ All tests passed!

Production EHRbase is ready for use

Next Steps:
  1. Configure DNS and SSL: ./08-setup-dns-ssl.sh
  2. Set up monitoring: ./07-setup-monitoring.sh
  3. Monitor logs for 24 hours
  4. Test user creation flow in mobile app
```

**If any tests fail:**
```
⚠ Most tests passed, but some issues found

Review failed tests above and address issues before production use
```

**Validation:** ✅ All tests passed, proceed to Phase 9

---

## Phase 9: Monitoring Setup

**Duration:** 10-15 minutes
**Script:** `./07-setup-monitoring.sh`
**Cost Impact:** ~$10-30/month (Dashboard, Alarms, Log storage)

### Purpose

Set up comprehensive CloudWatch monitoring:
- SNS topic for alert notifications
- 9 CloudWatch alarms (ECS, RDS, ALB)
- CloudWatch dashboard with 6 widgets
- Log Insights queries for troubleshooting
- Monitoring documentation

### Step 9.1: Run Monitoring Setup Script

```bash
chmod +x 07-setup-monitoring.sh
./07-setup-monitoring.sh
```

### Step 9.2: Create SNS Topic for Alerts

**Command:**
```bash
aws sns create-topic \
  --name medzen-ehrbase-alerts \
  --region us-east-1
```

**Expected Output:**
```
✓ SNS topic created: medzen-ehrbase-alerts
  Topic ARN: arn:aws:sns:us-east-1:123456789012:medzen-ehrbase-alerts
```

**Email subscription prompt:**
```
Enter email address for alerts (or press Enter to skip): your@email.com
```

**If email provided:**
```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:123456789012:medzen-ehrbase-alerts \
  --protocol email \
  --notification-endpoint your@email.com \
  --region us-east-1
```

**Expected Output:**
```
✓ Email subscription created
Important: Check your@email.com and confirm the subscription
```

### Step 9.3: Create ECS CloudWatch Alarms

**3 alarms created:**

1. **ECS High CPU:**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name medzen-ehrbase-ecs-high-cpu \
  --alarm-description "ECS service CPU utilization is above 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=ClusterName,Value=medzen-ehrbase-cluster Name=ServiceName,Value=medzen-ehrbase-service \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:medzen-ehrbase-alerts
```
**Triggers:** CPU > 80% for 10 minutes

2. **ECS High Memory:**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name medzen-ehrbase-ecs-high-memory \
  --alarm-description "ECS service memory utilization is above 80%" \
  --metric-name MemoryUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=ClusterName,Value=medzen-ehrbase-cluster Name=ServiceName,Value=medzen-ehrbase-service \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:medzen-ehrbase-alerts
```
**Triggers:** Memory > 80% for 10 minutes

3. **ECS Low Task Count:**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name medzen-ehrbase-ecs-low-tasks \
  --alarm-description "ECS service has less than 2 running tasks" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic SampleCount \
  --period 60 \
  --evaluation-periods 2 \
  --threshold 2 \
  --comparison-operator LessThanThreshold \
  --dimensions Name=ClusterName,Value=medzen-ehrbase-cluster Name=ServiceName,Value=medzen-ehrbase-service \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:medzen-ehrbase-alerts
```
**Triggers:** Running tasks < 2 for 2 minutes

**Expected Output:**
```
✓ ECS CPU alarm created
✓ ECS memory alarm created
✓ ECS task count alarm created
```

### Step 9.4: Create RDS CloudWatch Alarms

**3 alarms created:**

1. **RDS High CPU:**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name medzen-ehrbase-rds-high-cpu \
  --alarm-description "RDS CPU utilization is above 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=DBInstanceIdentifier,Value=medzen-ehrbase-db \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:medzen-ehrbase-alerts
```
**Triggers:** CPU > 80% for 10 minutes

2. **RDS Low Storage:**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name medzen-ehrbase-rds-low-storage \
  --alarm-description "RDS free storage space is below 10GB" \
  --metric-name FreeStorageSpace \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --evaluation-periods 1 \
  --threshold 10737418240 \
  --comparison-operator LessThanThreshold \
  --dimensions Name=DBInstanceIdentifier,Value=medzen-ehrbase-db \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:medzen-ehrbase-alerts
```
**Triggers:** Free storage < 10GB

3. **RDS High Connections:**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name medzen-ehrbase-rds-high-connections \
  --alarm-description "RDS database connections are above 80" \
  --metric-name DatabaseConnections \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=DBInstanceIdentifier,Value=medzen-ehrbase-db \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:medzen-ehrbase-alerts
```
**Triggers:** Connections > 80 for 10 minutes

**Expected Output:**
```
✓ RDS CPU alarm created
✓ RDS storage alarm created
✓ RDS connection count alarm created
```

### Step 9.5: Create ALB CloudWatch Alarms

**3 alarms created:**

1. **ALB High Response Time:**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name medzen-ehrbase-alb-high-response-time \
  --alarm-description "ALB target response time is above 2 seconds" \
  --metric-name TargetResponseTime \
  --namespace AWS/ApplicationELB \
  --statistic Average \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 2 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=LoadBalancer,Value=app/medzen-ehrbase-alb/abc123 \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:medzen-ehrbase-alerts
```
**Triggers:** Response time > 2s for 10 minutes

2. **ALB Unhealthy Targets:**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name medzen-ehrbase-alb-unhealthy-targets \
  --alarm-description "ALB has unhealthy targets" \
  --metric-name UnHealthyHostCount \
  --namespace AWS/ApplicationELB \
  --statistic Average \
  --period 60 \
  --evaluation-periods 2 \
  --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold \
  --dimensions Name=LoadBalancer,Value=app/medzen-ehrbase-alb/abc123 Name=TargetGroup,Value=targetgroup/medzen-ehrbase-tg/def456 \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:medzen-ehrbase-alerts
```
**Triggers:** Unhealthy targets >= 1 for 2 minutes

3. **ALB High 5xx Errors:**
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name medzen-ehrbase-alb-high-5xx-errors \
  --alarm-description "ALB 5xx error rate is above 5%" \
  --metric-name HTTPCode_Target_5XX_Count \
  --namespace AWS/ApplicationELB \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=LoadBalancer,Value=app/medzen-ehrbase-alb/abc123 \
  --alarm-actions arn:aws:sns:us-east-1:123456789012:medzen-ehrbase-alerts
```
**Triggers:** > 10 5xx errors in 5 minutes for 10 minutes

**Expected Output:**
```
✓ ALB response time alarm created
✓ ALB unhealthy target alarm created
✓ ALB 5xx error alarm created
```

### Step 9.6: Create CloudWatch Dashboard

**Command:**
```bash
aws cloudwatch put-dashboard \
  --dashboard-name medzen-ehrbase-production \
  --dashboard-body file://dashboard-body.json
```

**Dashboard widgets:**
1. ECS Service - CPU & Memory
2. RDS - CPU & Connections
3. ALB - Response Time & Request Count
4. ALB - HTTP Response Codes (2xx, 4xx, 5xx)
5. RDS - Storage Space
6. ALB - Target Health

**Expected Output:**
```
✓ CloudWatch dashboard created

  Dashboard URL:
  https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=medzen-ehrbase-production
```

### Step 9.7: Create Log Insights Queries

**4 queries created in `log-insights-queries/` directory:**

1. **recent-errors.txt** - Shows recent ERROR and Exception messages
2. **response-times.txt** - Analyzes API response times with percentiles
3. **top-errors.txt** - Lists most frequent error messages
4. **database-issues.txt** - Filters database connection issues

**Expected Output:**
```
✓ Created query: recent-errors.txt
✓ Created query: response-times.txt
✓ Created query: top-errors.txt
✓ Created query: database-issues.txt

Log Insights queries saved to: log-insights-queries/
```

### Step 9.8: Create Monitoring Documentation

**Script creates `monitoring-guide.md` with:**
- Dashboard access instructions
- Alarm descriptions and thresholds
- SNS topic management
- Log access commands
- Troubleshooting guides
- Operational runbook
- Cost monitoring tips

**Expected Output:**
```
✓ Monitoring guide saved: monitoring-guide.md
```

### Step 9.9: Summary

**Expected Final Output:**
```
==========================================
Monitoring Setup Complete!
==========================================

Created Resources:
  ✓ SNS Topic: medzen-ehrbase-alerts
  ✓ CloudWatch Alarms: 9 alarms
    - ECS: CPU, Memory, Task Count
    - RDS: CPU, Storage, Connections
    - ALB: Response Time, Health, 5xx Errors
  ✓ CloudWatch Dashboard: medzen-ehrbase-production
  ✓ Log Insights Queries: 4 queries
  ✓ Monitoring Documentation

Important:
  Confirm email subscription for your@email.com
  Check your inbox for AWS SNS confirmation email

Access Dashboard:
  https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=medzen-ehrbase-production

View Alarms:
  https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#alarmsV2:

View Logs:
  aws logs tail /ecs/medzen-ehrbase --follow --region us-east-1

Next Steps:
  1. Confirm email subscription
  2. Review dashboard and alarms
  3. Test notifications
  4. Monitor system for 24 hours

Documentation:
  - Monitoring Guide: monitoring-guide.md
  - Log Insights Queries: log-insights-queries/
```

**Validation:** ✅ Monitoring configured, proceed to Phase 10

---

## Phase 10: Post-Deployment Tasks

**Duration:** Ongoing (24+ hours)
**Cost Impact:** $0 (operational tasks)

### Purpose

Final operational tasks to ensure production stability and readiness for live traffic.

### Step 10.1: Confirm Email Subscription

**Check email inbox for:**
```
Subject: AWS Notification - Subscription Confirmation

You have chosen to subscribe to the topic:
arn:aws:sns:us-east-1:123456789012:medzen-ehrbase-alerts

To confirm this subscription, click or visit the link below:
https://sns.us-east-1.amazonaws.com/confirm-subscription?...
```

**Click confirmation link**

**Verify subscription:**
```bash
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:123456789012:medzen-ehrbase-alerts \
  --region us-east-1
```

**Expected Output:**
```json
{
  "Subscriptions": [
    {
      "Protocol": "email",
      "Endpoint": "your@email.com",
      "SubscriptionArn": "arn:aws:sns:us-east-1:123456789012:medzen-ehrbase-alerts:12345678-abcd-1234-abcd-123456789abc"
    }
  ]
}
```

### Step 10.2: Test Alert Notifications

**Send test alert:**
```bash
aws sns publish \
  --topic-arn arn:aws:sns:us-east-1:123456789012:medzen-ehrbase-alerts \
  --subject "Test Alert - EHRbase Production" \
  --message "This is a test notification to verify SNS alert delivery. If you receive this, email notifications are working correctly." \
  --region us-east-1
```

**Expected:** Email received within 1-2 minutes ✅

### Step 10.3: Monitor Logs (First 24 Hours)

**Tail logs in real-time:**
```bash
aws logs tail /ecs/medzen-ehrbase --follow --region us-east-1
```

**Filter for errors:**
```bash
aws logs tail /ecs/medzen-ehrbase --follow --filter-pattern "ERROR" --region us-east-1
```

**Watch for:**
- ✅ Successful EHR creations
- ✅ Template queries
- ✅ Database connection pool health
- ⚠️ Any errors or exceptions
- ⚠️ Slow query warnings

### Step 10.4: Test User Creation Flow

**Option 1: Firebase Cloud Function test**

Create test user in Firebase Auth Console:
```
Email: test+production@example.com
Password: TestPassword123!
```

**Watch Cloud Function logs:**
```bash
firebase functions:log --only onUserCreated
```

**Expected output:**
```
onUserCreated triggered for user: test+production@example.com
Creating EHR in production EHRbase...
✓ EHR created: 12345678-abcd-1234-abcd-123456789abc
✓ Supabase user created
✓ electronic_health_records entry created
```

**Option 2: Mobile app test**

1. Build Flutter app with production configuration
2. Sign up with test account
3. Verify EHR created in Supabase:
   ```sql
   SELECT * FROM electronic_health_records
   WHERE user_id = 'firebase-user-id'
   ORDER BY created_at DESC LIMIT 1;
   ```

### Step 10.5: Test Data Sync (Offline→Online)

**Create test vital signs record:**
```sql
-- In Supabase SQL Editor or mobile app
INSERT INTO vital_signs (
  patient_id,
  systolic_bp,
  diastolic_bp,
  heart_rate,
  recorded_at
) VALUES (
  'test-user-id',
  120,
  80,
  72,
  NOW()
);
```

**Check sync queue:**
```sql
SELECT * FROM ehrbase_sync_queue
WHERE sync_status = 'pending'
ORDER BY created_at DESC LIMIT 5;
```

**Expected:** Queue entry created ✅

**Watch Supabase Edge Function logs:**
```bash
npx supabase functions logs sync-to-ehrbase
```

**Expected output:**
```
Processing sync queue...
✓ Vital signs synced to EHRbase
  Composition ID: abc123-def456-...
  Status: completed
```

**Verify in sync queue:**
```sql
SELECT * FROM ehrbase_sync_queue
WHERE id = 'queue-entry-id';
```

**Expected:** `sync_status = 'completed'`, `ehrbase_composition_id` populated ✅

### Step 10.6: Review CloudWatch Dashboard

**Access dashboard:**
```
https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=medzen-ehrbase-production
```

**Check after 24 hours:**
- ✅ ECS CPU: < 70% average
- ✅ ECS Memory: < 70% average
- ✅ RDS CPU: < 50% average
- ✅ RDS Connections: < 20 average
- ✅ ALB Response Time: < 1s average
- ✅ ALB 2xx Responses: > 99%
- ✅ Target Health: All healthy

### Step 10.7: Review CloudWatch Alarms

**Check alarm states:**
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix medzen-ehrbase \
  --region us-east-1
```

**Expected:** All alarms in `OK` state ✅

**If any alarms in `ALARM` state:**
1. Click alarm in CloudWatch Console
2. Review "History" tab
3. Investigate cause (high CPU, failed health checks, etc.)
4. Take corrective action
5. Document incident

### Step 10.8: Cost Validation (After 7 Days)

**Check actual costs:**
```
AWS Console → Billing → Cost Explorer
```

**Filter by:**
- Service: EC2, ECS, RDS, ElasticLoadBalancing, CloudWatch
- Time period: Last 7 days
- Group by: Service

**Expected monthly projection:**
```
ECS Fargate:       $70-140
RDS:               $100
ALB:               $22
NAT Gateway:       $32
CloudWatch:        $10-30
Data Transfer:     $5-15
Total:             ~$260/month
```

**If costs higher than expected:**
- Check ECS task count (should be 2-4, not higher)
- Check CloudWatch log ingestion volume
- Check data transfer (NAT Gateway, ALB)
- Review RDS storage auto-scaling

### Step 10.9: Optional - Configure DNS and SSL

**If you have a custom domain (e.g., ehrbase.yourapp.com):**

1. **Request ACM Certificate:**
   ```bash
   aws acm request-certificate \
     --domain-name ehrbase.yourapp.com \
     --validation-method DNS \
     --region us-east-1
   ```

2. **Add CNAME validation records to DNS**

3. **Wait for certificate validation** (5-30 minutes)

4. **Add HTTPS listener to ALB:**
   ```bash
   aws elbv2 create-listener \
     --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/medzen-ehrbase-alb/abc123 \
     --protocol HTTPS \
     --port 443 \
     --certificates CertificateArn=arn:aws:acm:us-east-1:123456789012:certificate/def456 \
     --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/medzen-ehrbase-tg/def456
   ```

5. **Create Route 53 record (or external DNS):**
   ```bash
   aws route53 change-resource-record-sets \
     --hosted-zone-id Z123456789ABC \
     --change-batch '{
       "Changes": [{
         "Action": "CREATE",
         "ResourceRecordSet": {
           "Name": "ehrbase.yourapp.com",
           "Type": "A",
           "AliasTarget": {
             "HostedZoneId": "Z35SXDOTRQ7X7K",
             "DNSName": "medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com",
             "EvaluateTargetHealth": true
           }
         }
       }]
     }'
   ```

6. **Update Firebase/Supabase config:**
   ```bash
   # Firebase
   firebase functions:config:set ehrbase.url="https://ehrbase.yourapp.com/ehrbase/rest"
   firebase deploy --only functions

   # Supabase
   npx supabase secrets set EHRBASE_URL="https://ehrbase.yourapp.com/ehrbase/rest"
   npx supabase functions deploy sync-to-ehrbase
   ```

### Step 10.10: Create Production Runbook

**Document key procedures:**

**`production-runbook.md`:**
```markdown
# EHRbase Production Runbook

## Emergency Contacts
- AWS Account Owner: contact@yourcompany.com
- DevOps Lead: devops@yourcompany.com
- EHRbase Admin: admin@yourcompany.com

## Quick Reference

### Access EHRbase
URL: http://medzen-ehrbase-alb-1234567890.us-east-1.elb.amazonaws.com/ehrbase/rest
Auth: HTTP Basic (credentials in AWS Secrets Manager)

### View Logs
aws logs tail /ecs/medzen-ehrbase --follow --region us-east-1

### Restart ECS Service
aws ecs update-service \
  --cluster medzen-ehrbase-cluster \
  --service medzen-ehrbase-service \
  --force-new-deployment \
  --region us-east-1

### Scale ECS Tasks
aws ecs update-service \
  --cluster medzen-ehrbase-cluster \
  --service medzen-ehrbase-service \
  --desired-count 4 \
  --region us-east-1

### Connect to Database
DB_ADMIN_PASS=$(aws secretsmanager get-secret-value --secret-id medzen-ehrbase/db_admin --query SecretString --output text | jq -r '.password')
PGPASSWORD=$DB_ADMIN_PASS psql -h RDS_ENDPOINT -U ehrbase_admin -d ehrbase

## Incident Response

### High CPU on ECS
1. Check CloudWatch dashboard for traffic spikes
2. Review logs for slow queries or errors
3. Scale to 4 tasks if needed
4. Investigate database performance

### Database Connection Issues
1. Check RDS connection count alarm
2. Review application logs for connection errors
3. Verify security group rules
4. Check RDS status in Console

### 5xx Errors
1. Check ECS task logs immediately
2. Verify database connectivity
3. Check target health in ALB
4. Review recent code deployments

## Maintenance Windows
- Database backups: Daily at 3:00-4:00 AM UTC
- RDS maintenance: Sundays 4:00-5:00 AM UTC
- Recommended deployment: Fridays after 5 PM UTC
```

### Step 10.11: Schedule Regular Health Checks

**Weekly tasks:**
- Review CloudWatch dashboard trends
- Check all alarms are in OK state
- Review CloudWatch Logs Insights for errors
- Check RDS storage trends
- Verify backup retention

**Monthly tasks:**
- Review AWS costs vs. budget
- Test backup restore procedure
- Review and update monitoring thresholds
- Update documentation with lessons learned
- Test incident response procedures

### Step 10.12: Summary

**Post-Deployment Complete:**
```
✓ Email alerts confirmed and tested
✓ Logs monitored for 24 hours (no critical errors)
✓ User creation flow tested (EHR created successfully)
✓ Data sync tested (offline→online working)
✓ CloudWatch dashboard reviewed (all metrics healthy)
✓ CloudWatch alarms verified (all in OK state)
✓ Costs validated (~$260/month as expected)
✓ Production runbook created

System Status: PRODUCTION READY ✅

Next Steps:
  - Gradual rollout to production users
  - Monitor logs and metrics daily
  - Respond to any alarms promptly
  - Schedule regular health checks
  - Keep documentation updated
```

**Validation:** ✅ Production deployment complete and stable

---

## Rollback Procedures

### Rollback Scenario 1: Critical EHRbase Issue

**If EHRbase is not functioning correctly:**

1. **Immediately revert Firebase/Supabase to dev:**
   ```bash
   # Firebase
   firebase functions:config:set \
     ehrbase.url="http://ehr.medzenhealth.app/ehrbase/rest" \
     ehrbase.username="ehrbase-user" \
     ehrbase.password="dev-password"
   firebase deploy --only functions

   # Supabase
   npx supabase secrets set \
     EHRBASE_URL="http://ehr.medzenhealth.app/ehrbase/rest" \
     EHRBASE_USERNAME="ehrbase-user" \
     EHRBASE_PASSWORD="dev-password"
   npx supabase functions deploy sync-to-ehrbase
   ```

2. **Investigate AWS EHRbase issue:**
   - Check ECS task logs
   - Verify database connectivity
   - Check ALB target health

3. **Fix issue and re-deploy**

### Rollback Scenario 2: Database Corruption

**If database is corrupted:**

1. **Stop ECS service:**
   ```bash
   aws ecs update-service \
     --cluster medzen-ehrbase-cluster \
     --service medzen-ehrbase-service \
     --desired-count 0 \
     --region us-east-1
   ```

2. **Restore RDS from automated backup:**
   ```bash
   aws rds restore-db-instance-to-point-in-time \
     --source-db-instance-identifier medzen-ehrbase-db \
     --target-db-instance-identifier medzen-ehrbase-db-restored \
     --restore-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
     --region us-east-1
   ```

3. **Wait for restore (10-20 minutes)**

4. **Update task definition with new endpoint**

5. **Restart ECS service**

### Rollback Scenario 3: Infrastructure Issue

**If AWS infrastructure has issues:**

1. **Check AWS Service Health Dashboard**

2. **If regional outage, consider multi-region failover** (requires pre-configuration)

3. **If isolated issue:**
   - Check security groups
   - Check route tables
   - Check NAT Gateway status
   - Check ECS task placement

### Rollback Scenario 4: Complete Rollback

**To completely remove AWS deployment:**

1. **Revert Firebase/Supabase to dev** (see Scenario 1)

2. **Delete AWS resources in reverse order:**
   ```bash
   # Delete ECS service
   aws ecs delete-service --cluster medzen-ehrbase-cluster --service medzen-ehrbase-service --force --region us-east-1

   # Delete ALB
   aws elbv2 delete-load-balancer --load-balancer-arn <ARN> --region us-east-1

   # Delete RDS (with final snapshot)
   aws rds delete-db-instance \
     --db-instance-identifier medzen-ehrbase-db \
     --final-db-snapshot-identifier medzen-ehrbase-final-snapshot \
     --region us-east-1

   # Delete NAT Gateway
   aws ec2 delete-nat-gateway --nat-gateway-id <ID> --region us-east-1

   # Wait 5 minutes, then delete Elastic IP
   aws ec2 release-address --allocation-id <ID> --region us-east-1

   # Delete VPC (auto-deletes subnets, IGW, route tables, security groups)
   aws ec2 delete-vpc --vpc-id <ID> --region us-east-1
   ```

3. **Verify dev environment is functioning**

---

## Troubleshooting

### Issue: ECS Tasks Not Starting

**Symptoms:**
- ECS service shows 0 running tasks
- CloudWatch logs show container errors

**Diagnosis:**
```bash
aws ecs describe-tasks \
  --cluster medzen-ehrbase-cluster \
  --tasks $(aws ecs list-tasks --cluster medzen-ehrbase-cluster --service medzen-ehrbase-service --query 'taskArns[0]' --output text) \
  --region us-east-1
```

**Common causes:**
1. **Database connection failed** - Check RDS endpoint, credentials, security group
2. **Image pull failed** - Check ECS task execution role has ECR permissions
3. **Insufficient resources** - Check task CPU/memory allocation

**Solutions:**
```bash
# Check logs
aws logs tail /ecs/medzen-ehrbase --since 5m --region us-east-1

# Verify database connectivity
PGPASSWORD=$DB_USER_PASS psql -h $RDS_ENDPOINT -U ehrbase_restricted -d ehrbase -c "SELECT 1;"

# Force new deployment
aws ecs update-service \
  --cluster medzen-ehrbase-cluster \
  --service medzen-ehrbase-service \
  --force-new-deployment \
  --region us-east-1
```

### Issue: Targets Unhealthy in ALB

**Symptoms:**
- ALB shows 0 healthy targets
- HTTP 503 errors when accessing EHRbase

**Diagnosis:**
```bash
aws elbv2 describe-target-health \
  --target-group-arn <TG_ARN> \
  --region us-east-1
```

**Common causes:**
1. **Health check failing** - EHRbase not responding on `/ehrbase/rest/status`
2. **Security group issue** - ALB cannot reach ECS tasks on port 8080
3. **Database not accessible** - EHRbase container cannot connect to RDS

**Solutions:**
```bash
# Check ECS task private IP
TASK_IP=$(aws ecs describe-tasks \
  --cluster medzen-ehrbase-cluster \
  --tasks $(aws ecs list-tasks --cluster medzen-ehrbase-cluster --service medzen-ehrbase-service --query 'taskArns[0]' --output text) \
  --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' \
  --output text \
  --region us-east-1)

# From a bastion host or AWS Console Session Manager, test:
curl http://$TASK_IP:8080/ehrbase/rest/status

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-0ecs222 --region us-east-1
```

### Issue: High Database Connections

**Symptoms:**
- RDS connection count alarm triggered
- Application errors: "Too many connections"

**Diagnosis:**
```sql
-- Connect to database
PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase

-- Check active connections
SELECT count(*), usename, application_name
FROM pg_stat_activity
GROUP BY usename, application_name;

-- Check long-running queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;
```

**Solutions:**
1. **Increase max_connections** (requires RDS parameter group change + reboot)
2. **Optimize connection pool** in EHRbase configuration
3. **Kill idle connections**:
   ```sql
   SELECT pg_terminate_backend(pid)
   FROM pg_stat_activity
   WHERE state = 'idle'
   AND query_start < now() - interval '10 minutes';
   ```

### Issue: Slow API Response Times

**Symptoms:**
- ALB response time > 2 seconds
- Users complaining about slow performance

**Diagnosis:**
```bash
# Check RDS performance
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=medzen-ehrbase-db \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --region us-east-1

# Check slow query logs in CloudWatch
aws logs tail /aws/rds/instance/medzen-ehrbase-db/postgresql --follow --region us-east-1
```

**Solutions:**
1. **Add database indexes** (consult EHRbase schema documentation)
2. **Increase RDS instance size** (e.g., db.t3.large)
3. **Enable RDS Performance Insights** and review top SQL
4. **Increase ECS task count** for more parallelism

### Issue: 5xx Errors

**Symptoms:**
- ALB 5xx error alarm triggered
- Users seeing "Internal Server Error"

**Diagnosis:**
```bash
# Check application logs for exceptions
aws logs tail /ecs/medzen-ehrbase --follow --filter-pattern "ERROR" --region us-east-1

# Check ECS service events
aws ecs describe-services \
  --cluster medzen-ehrbase-cluster \
  --services medzen-ehrbase-service \
  --query 'services[0].events[:10]' \
  --region us-east-1
```

**Solutions:**
1. **Database connection timeout** - Increase connection timeout in task definition
2. **Application exception** - Review stack trace in logs, may require code fix
3. **Resource exhaustion** - Scale ECS tasks or increase CPU/memory

---

## Cost Breakdown

### Monthly Recurring Costs

| Resource | Configuration | Monthly Cost |
|----------|--------------|--------------|
| **RDS PostgreSQL** | db.t3.medium Multi-AZ | $100 |
| **ECS Fargate** | 2-4 tasks (2 vCPU, 4GB each) | $70-140 |
| **Application Load Balancer** | 1 ALB | $22 |
| **NAT Gateway** | 1 NAT GW + data transfer | $32-45 |
| **CloudWatch** | Dashboard, alarms, logs | $10-30 |
| **Secrets Manager** | 2 secrets | $1 |
| **Data Transfer** | Variable | $5-15 |
| **Total** | | **~$260/month** |

### Cost Optimization Tips

1. **RDS Storage Auto-Scaling:** Only pay for storage used
2. **ECS Fargate Spot:** Use FARGATE_SPOT for 70% savings (may be interrupted)
3. **CloudWatch Log Retention:** Reduce to 3 days to save on storage
4. **Reserved Instances:** Commit to 1-year RDS RI for 30-40% savings
5. **Right-Sizing:** Monitor actual usage and downsize if underutilized

### Free Tier (First 12 Months)

- **RDS:** 750 hours/month of db.t3.micro (not used in this deployment)
- **ECS Fargate:** First 20 GB storage free
- **Data Transfer:** 100 GB/month outbound
- **CloudWatch:** 10 custom metrics, 10 alarms free

**Note:** This deployment exceeds free tier limits, so expect full charges.

---

## Deployment Complete!

You now have a **production-grade EHRbase OpenEHR server** running on AWS with:

✅ Multi-AZ high availability
✅ Auto-scaling (2-4 tasks)
✅ Encrypted database with automated backups
✅ Comprehensive monitoring and alerting
✅ Security best practices (private subnets, security groups)
✅ Integration with Firebase and Supabase
✅ CloudWatch logs and dashboards
✅ Cost-optimized architecture (~$260/month)

**Next Steps:**
- Gradual production rollout
- 24-hour monitoring period
- Test end-to-end user flows
- Document any issues encountered
- Schedule regular maintenance windows

**Support Resources:**
- AWS Support Center: https://console.aws.amazon.com/support/home
- EHRbase Documentation: https://ehrbase.readthedocs.io/
- OpenEHR Specifications: https://specifications.openehr.org/

---

**Document Version:** 1.0
**Last Updated:** 2025-01-29
**Maintained By:** DevOps Team
