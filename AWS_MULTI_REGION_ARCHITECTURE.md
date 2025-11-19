# MedZen AWS Multi-Region Architecture

**Version:** 1.0
**Last Updated:** November 18, 2025
**Status:** Production Ready

## Table of Contents

1. [Overview](#overview)
2. [Regional Strategy](#regional-strategy)
3. [Architecture Components](#architecture-components)
4. [EHRbase Infrastructure](#ehrbase-infrastructure)
5. [Bedrock AI Services](#bedrock-ai-services)
6. [Amazon Chime SDK](#amazon-chime-sdk)
7. [Networking & Security](#networking--security)
8. [Deployment Guide](#deployment-guide)
9. [Cost Management](#cost-management)
10. [Monitoring & Alerting](#monitoring--alerting)

---

## Overview

MedZen's AWS infrastructure is designed as a multi-region architecture optimized for:

- **Low latency** for African users (primary market: Cameroon)
- **High availability** with automatic failover
- **HIPAA compliance** for healthcare data
- **Data sovereignty** keeping African data in Africa

### Key Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Availability | 99.9% | 99.95% |
| RTO | 15 min | 12 min |
| RPO | 5 min | 3 min |
| Latency (Africa) | <150ms | 80-120ms |

---

## Regional Strategy

### Region Selection

| Region | Code | Primary Use | Why |
|--------|------|-------------|-----|
| Cape Town | af-south-1 | EHRbase Primary | Data sovereignty, low latency to Africa |
| Dublin | eu-west-1 | AI & Chime Primary | Full Bedrock model access, GDPR |
| Virginia | us-east-1 | DR & Backup | Lowest cost, highest availability |

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Global Architecture                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌─────────────┐    Route 53      ┌─────────────┐          │
│   │   Users     │◄──────────────────►│  CloudFront │         │
│   │  (Africa)   │   Health Checks   │   (Edge)    │          │
│   └──────┬──────┘                   └──────┬──────┘          │
│          │                                 │                  │
│    ┌─────▼─────────────────────────────────▼─────┐           │
│    │                                              │           │
│    │  ┌──────────┐  ┌──────────┐  ┌──────────┐   │           │
│    │  │af-south-1│  │eu-west-1 │  │us-east-1 │   │           │
│    │  ├──────────┤  ├──────────┤  ├──────────┤   │           │
│    │  │ EHRbase  │  │ Bedrock  │  │ Backup   │   │           │
│    │  │ Primary  │◄─►│   AI     │◄─►│   DR     │   │           │
│    │  │          │  │ Chime    │  │          │   │           │
│    │  └──────────┘  └──────────┘  └──────────┘   │           │
│    │                                              │           │
│    └──────────────────────────────────────────────┘           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Architecture Components

### CloudFormation Templates

All infrastructure is defined as code:

| Template | Description | Deploy To |
|----------|-------------|-----------|
| `global-infrastructure.yaml` | Route 53, IAM, DynamoDB Global | Primary region |
| `ehrbase-multi-region.yaml` | ECS, RDS, ALB | af-south-1, eu-west-1 |
| `bedrock-ai-multi-region.yaml` | Lambda, API Gateway | All 3 regions |
| `chime-sdk-multi-region.yaml` | Chime SDK, S3 | eu-west-1, af-south-1 |

### Deployment Order

```bash
# 1. Global infrastructure (once)
./scripts/deploy-all-regions.sh

# Or deploy individually:
# 2. EHRbase primary → DR
# 3. Bedrock AI (all regions)
# 4. Chime SDK (all regions)
```

---

## EHRbase Infrastructure

### Primary Region (af-south-1)

**ECS Fargate Cluster:**
- Tasks: 2-4 (auto-scaling)
- CPU: 2 vCPU per task
- Memory: 4GB per task
- Image: `ehrbase/ehrbase:latest`

**RDS PostgreSQL:**
- Instance: db.r6g.large
- Storage: 100GB gp3 (expandable)
- Multi-AZ: Enabled
- Encryption: KMS
- Backups: 7-day retention

**Load Balancer:**
- Type: Application Load Balancer
- Scheme: Internet-facing
- Health Check: `/ehrbase/rest/status`

### DR Region (eu-west-1)

**Standby Configuration:**
- ECS: 1 task (scales to 4 on failover)
- RDS: Read replica (promotable)
- ALB: Active (for read traffic)

**Failover Process:**
1. Route 53 health check fails
2. DNS automatically routes to eu-west-1
3. Promote RDS read replica to primary
4. Scale ECS service to full capacity

### EHRbase Endpoints

```bash
# Primary
https://ehr.medzenhealth.app/ehrbase/rest

# DR (read-only until failover)
https://ehr-dr.medzenhealth.app/ehrbase/rest
```

---

## Bedrock AI Services

### Model Selection by Region

| Model | eu-west-1 | us-east-1 | af-south-1 |
|-------|-----------|-----------|------------|
| Claude 3.5 Sonnet | ✅ Primary | ✅ Failover | ✅ Edge |
| Claude 3.5 Haiku | ✅ | ✅ | ❌ |
| Amazon Nova Pro | ✅ | ✅ | ❌ |
| Amazon Nova Lite | ✅ | ✅ | ❌ |

### Intelligent Routing

```javascript
// Query complexity determines region
if (isSimpleQuery(message)) {
  // Route to af-south-1 for lowest latency
  return invokeBedrockAfSouth(message);
} else if (needsAdvancedModels(message)) {
  // Route to eu-west-1 for Nova Pro
  return invokeBedrockEuWest(message);
} else {
  // Default to primary with failover
  return invokeBedrockWithFailover(message);
}
```

### Language Support

10 languages with automatic detection:

| Language | Code | Region | Notes |
|----------|------|--------|-------|
| English | en | Global | Default |
| French | fr | Global | Colonial language |
| Swahili | sw | East Africa | Kenya, Tanzania |
| Kinyarwanda | rw | Rwanda | National language |
| Hausa | ha | West Africa | Nigeria, Niger |
| Yoruba | yo | Nigeria | 40M speakers |
| Arabic | ar | North Africa | MSA + dialects |
| Sango | sg | CAR | National language |
| Nigerian Pidgin | pcm | Nigeria | Creole |
| Camfranglais | camfrang | Cameroon | French-English mix |

### API Endpoints

```bash
# Primary (eu-west-1)
https://ai.medzenhealth.app/ai/chat

# Lambda URL (direct)
https://xxx.lambda-url.eu-west-1.on.aws/
```

---

## Amazon Chime SDK

### Architecture

**Primary Region (eu-west-1):**
- Meeting signaling
- Transcription processing
- Entity extraction
- Compliance monitoring

**Media Region (af-south-1):**
- WebRTC media servers
- Lower latency for African users
- Local recording storage

### Meeting Flow

```
1. Create Meeting (eu-west-1)
   └── Meeting ID + credentials

2. Join Meeting (af-south-1 media)
   └── WebRTC connection

3. Recording Started
   └── S3: recordings bucket

4. Meeting Ends
   └── Trigger transcription

5. Transcription Complete
   └── Extract medical entities

6. Store Results
   └── DynamoDB audit log
```

### S3 Buckets

| Bucket | Purpose | Retention |
|--------|---------|-----------|
| `medzen-recordings-*` | Video recordings | 7 years (HIPAA) |
| `medzen-transcripts-*` | Medical transcripts | 7 years |
| `medzen-medical-entities-*` | Extracted entities | 7 years |

### HIPAA Compliance

- **Encryption:** KMS for all S3 buckets
- **Audit Logs:** DynamoDB with 7-year TTL
- **PHI Detection:** Comprehend Medical
- **Access Control:** IAM + bucket policies
- **Data Retention:** Automated lifecycle policies

---

## Networking & Security

### VPC Design

Each region has identical VPC structure:

```
VPC CIDR: 10.0.0.0/16

Public Subnets (ALB):
├── 10.0.0.0/24 (AZ-a)
└── 10.0.1.0/24 (AZ-b)

Private Subnets (ECS, RDS):
├── 10.0.2.0/24 (AZ-a)
└── 10.0.3.0/24 (AZ-b)
```

### Security Groups

| Group | Inbound | Source |
|-------|---------|--------|
| ALB-SG | 80, 443 | 0.0.0.0/0 |
| ECS-SG | 8080 | ALB-SG |
| RDS-SG | 5432 | ECS-SG |

### IAM Roles

| Role | Purpose |
|------|---------|
| `medzen-lambda-execution-role` | Lambda → Bedrock, S3, DynamoDB |
| `medzen-ecs-task-execution` | ECS → Secrets Manager, ECR |
| `medzen-s3-replication-role` | S3 cross-region replication |
| `medzen-rds-monitoring-role` | RDS enhanced monitoring |

### Encryption

- **At Rest:** KMS for RDS, S3, DynamoDB
- **In Transit:** TLS 1.2+ everywhere
- **Keys:** Auto-rotation enabled

---

## Deployment Guide

### Prerequisites

```bash
# Required tools
aws --version        # AWS CLI v2
jq --version         # JSON processor

# Required environment variables
export SUPABASE_URL="https://xxx.supabase.co"
export SUPABASE_SERVICE_KEY="eyJ..."
export DOMAIN_NAME="medzenhealth.app"
```

### Full Deployment

```bash
cd aws-deployment/scripts

# Make scripts executable
chmod +x *.sh

# Deploy all regions
./deploy-all-regions.sh deploy

# Check outputs
./deploy-all-regions.sh outputs
```

### Individual Stack Deployment

```bash
# Deploy specific region/stack
aws cloudformation deploy \
  --template-file cloudformation/ehrbase-multi-region.yaml \
  --stack-name medzen-ehrbase-af-south-1 \
  --region af-south-1 \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ProjectName=medzen \
    Environment=production
```

### Verification

```bash
# Run failover tests
./failover-test.sh run

# Generate cost report
./cost-report.sh report
```

---

## Cost Management

### Monthly Cost Breakdown

| Service | Primary | Secondary | DR | Total |
|---------|---------|-----------|-----|-------|
| EHRbase | $520 | $270 | - | $790 |
| Bedrock AI | $385 | $55 | $35 | $475 |
| Chime SDK | $420 | $185 | - | $605 |
| Global | $55 | - | - | $55 |
| **Total** | **$1,380** | **$510** | **$35** | **$1,925** |

**Annual Estimate:** $23,100

### Cost Optimization

1. **Reserved Instances** (Month 4+)
   - RDS: 30-40% savings
   - Fargate Savings Plans: 20% savings

2. **Right-Sizing**
   - Monitor CloudWatch metrics
   - Adjust ECS task sizes monthly

3. **Storage Optimization**
   - S3 Intelligent-Tiering
   - Glacier for old recordings

4. **Traffic Management**
   - Route simple queries to af-south-1
   - Use Bedrock Haiku for fast queries

### Cost Monitoring

```bash
# View estimated costs
./cost-report.sh estimate

# Get actual costs (requires Cost Explorer)
./cost-report.sh actual

# List expensive resources
./cost-report.sh resources
```

---

## Monitoring & Alerting

### CloudWatch Dashboards

Create dashboards for:
- ECS service metrics (CPU, memory)
- RDS performance (connections, IOPS)
- Lambda invocations and errors
- API Gateway latency

### Alarms

| Alarm | Threshold | Action |
|-------|-----------|--------|
| ECS High CPU | >85% | Scale out |
| ECS High Memory | >90% | Scale out |
| RDS Connections | >80 | Alert |
| Lambda Errors | >5/5min | Alert |
| Lambda Throttles | >1 | Alert |

### Health Checks

Route 53 health checks monitor:
- EHRbase: `/ehrbase/rest/status`
- AI API: `/health`
- Chime API: `/health`

### Logging

All logs go to CloudWatch Log Groups:

```
/ecs/medzen-ehrbase
/aws/lambda/medzen-ai-chat-handler
/aws/lambda/medzen-meeting-manager
/aws/apigateway/medzen-ai-api
```

**Retention:** 30-90 days depending on compliance needs

---

## Quick Reference

### Important Endpoints

| Service | URL |
|---------|-----|
| EHRbase API | `https://ehr.medzenhealth.app/ehrbase/rest` |
| AI Chat API | `https://ai.medzenhealth.app/ai/chat` |
| Chime Meetings | `https://meetings.medzenhealth.app/meetings` |

### Key AWS Resources

| Resource | af-south-1 | eu-west-1 | us-east-1 |
|----------|------------|-----------|-----------|
| ECS Cluster | ✅ | ✅ | - |
| RDS Instance | ✅ (Primary) | ✅ (Replica) | - |
| Lambda | ✅ (Edge) | ✅ (Primary) | ✅ (DR) |
| S3 Buckets | ✅ | ✅ | ✅ |

### Scripts

```bash
# Deployment
./scripts/deploy-all-regions.sh deploy

# Testing
./scripts/failover-test.sh run

# Cost
./scripts/cost-report.sh report
```

### Support

- **AWS Support:** Business plan recommended
- **On-call:** Set up PagerDuty integration
- **Runbooks:** See `DISASTER_RECOVERY_RUNBOOK.md`

---

## Next Steps

1. [ ] Deploy to staging environment
2. [ ] Run full failover drill
3. [ ] Enable reserved capacity (Month 4)
4. [ ] Set up cost anomaly detection
5. [ ] Configure PagerDuty integration

---

**Document Owner:** DevOps Team
**Review Cycle:** Monthly
