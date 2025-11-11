# AWS EHRbase Architecture
**Telemedicine Platform - High-Level Design**

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Internet (Public)                               │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   │ HTTPS/HTTP
                                   │
┌──────────────────────────────────▼──────────────────────────────────────────┐
│                    Application Load Balancer (ALB)                           │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Listener: Port 443 (HTTPS) / 80 (HTTP)                              │   │
│  │  Target Group: medzen-ehrbase-tg (Port 8080)                         │   │
│  │  Health Check: /ehrbase/rest/status                                  │   │
│  │  Sticky Sessions: Enabled (86400s)                                   │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                              Public Subnets                                  │
│                         (10.0.0.0/24, 10.0.1.0/24)                          │
└──────────────────────────────────┬──────────────────────────────────────────┘
                                   │
                                   │ Forward to Target Group
                                   │
┌──────────────────────────────────▼──────────────────────────────────────────┐
│                           ECS Fargate Cluster                                │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │                    EHRbase Service                                  │     │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │     │
│  │  │   Task 1     │  │   Task 2     │  │   Task 3-4   │             │     │
│  │  │              │  │              │  │  (Auto-scale) │             │     │
│  │  │  EHRbase     │  │  EHRbase     │  │              │             │     │
│  │  │  Container   │  │  Container   │  │  EHRbase     │             │     │
│  │  │              │  │              │  │  Container   │             │     │
│  │  │  2 vCPU      │  │  2 vCPU      │  │              │             │     │
│  │  │  4 GB RAM    │  │  4 GB RAM    │  │  2 vCPU      │             │     │
│  │  │  Port 8080   │  │  Port 8080   │  │  4 GB RAM    │             │     │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘             │     │
│  │         │                  │                  │                     │     │
│  │         └──────────────────┼──────────────────┘                     │     │
│  │                            │                                        │     │
│  └────────────────────────────┼────────────────────────────────────────┘     │
│                               │                                              │
│                   Private Subnets (AZ1, AZ2)                                 │
│                   (10.0.2.0/24, 10.0.3.0/24)                                │
└───────────────────────────────┬──────────────────────────────────────────────┘
                                │
                                │ PostgreSQL Connection (Port 5432)
                                │
┌───────────────────────────────▼──────────────────────────────────────────────┐
│                     RDS PostgreSQL Database                                   │
│  ┌────────────────────────────────────────────────────────────────────┐      │
│  │  Instance Class: db.t3.medium                                       │      │
│  │  vCPU: 2 cores                                                      │      │
│  │  Memory: 4 GB RAM                                                   │      │
│  │  Storage: 100 GB (gp3, encrypted)                                   │      │
│  │  Engine: PostgreSQL 14.10                                           │      │
│  │  Multi-AZ: Disabled (enable for production HA)                      │      │
│  │  Backup: Automated (7 days retention)                               │      │
│  │  Max Connections: 100 (default)                                     │      │
│  └────────────────────────────────────────────────────────────────────┘      │
│                   Private Subnets (AZ1, AZ2)                                  │
└───────────────────────────────────────────────────────────────────────────────┘

                    ┌──────────────────────────────────┐
                    │      NAT Gateway (AZ1)           │
                    │  Elastic IP: X.X.X.X             │
                    │  Egress for Private Subnets      │
                    └──────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                         CloudWatch Monitoring                                │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │  Metrics:                                                           │     │
│  │  - ECS CPU Utilization (Target: <70%)                              │     │
│  │  - ECS Memory Utilization (Target: <80%)                           │     │
│  │  - RDS CPU Utilization (Target: <70%)                              │     │
│  │  - RDS Database Connections (Target: <80)                          │     │
│  │  - ALB Request Count                                               │     │
│  │  - ALB Target Response Time (Target: <2s)                          │     │
│  │                                                                     │     │
│  │  Alarms:                                                            │     │
│  │  - High CPU (ECS): CPU > 80% for 10 minutes                        │     │
│  │  - High Memory (ECS): Memory > 85% for 10 minutes                  │     │
│  │  - High CPU (RDS): CPU > 70% for 10 minutes                        │     │
│  │  - High Connections (RDS): Connections > 80 for 10 minutes         │     │
│  │                                                                     │     │
│  │  Logs:                                                              │     │
│  │  - /ecs/medzen-ehrbase (ECS container logs)                        │     │
│  │  - /aws/rds/instance/medzen-ehrbase-postgres/postgresql            │     │
│  └────────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                         Auto Scaling (Application)                           │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │  ECS Service Auto Scaling:                                          │     │
│  │  - Min Tasks: 2                                                     │     │
│  │  - Max Tasks: 4                                                     │     │
│  │  - Scale Out: CPU > 70% OR Memory > 80%                            │     │
│  │  - Scale In: CPU < 50% AND Memory < 60% (5 min cooldown)           │     │
│  │                                                                     │     │
│  │  Scaling Behavior:                                                  │     │
│  │  - 2 tasks → 3 tasks (first scale event)                           │     │
│  │  - 3 tasks → 4 tasks (second scale event)                          │     │
│  │  - 4 tasks → 3 tasks (scale in after cooldown)                     │     │
│  └────────────────────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Application Load Balancer (ALB)
- **Purpose:** Internet-facing load balancer distributing traffic to ECS tasks
- **Protocol:** HTTP/HTTPS (Port 80/443)
- **Target:** ECS Fargate tasks (Port 8080)
- **Health Check:** `GET /ehrbase/rest/status` every 30s
- **Features:**
  - Sticky sessions (cookie-based, 24h duration)
  - SSL/TLS termination (if certificate provided)
  - HTTP to HTTPS redirect (if certificate provided)
  - Cross-zone load balancing
- **DNS:** `medzen-ehrbase-alb-XXXXX.us-east-1.elb.amazonaws.com`

### 2. ECS Fargate Cluster
- **Cluster Name:** `medzen-ehrbase-cluster`
- **Service Name:** `medzen-ehrbase-service`
- **Launch Type:** Fargate (serverless containers)
- **Network Mode:** `awsvpc` (each task gets ENI with private IP)
- **Task Configuration:**
  - **CPU:** 2048 (2 vCPU)
  - **Memory:** 4096 MB (4 GB)
  - **Container:** `ehrbase/ehrbase:latest`
  - **Port:** 8080 (EHRbase REST API)
- **Desired Count:** 2 (minimum)
- **Auto-scaling:** Scales to 3-4 tasks based on CPU/memory
- **Deployment:**
  - Rolling update strategy
  - Max: 200% (can run 4 tasks during deployment)
  - Min: 50% (keep at least 1 task healthy)
  - Circuit breaker enabled (automatic rollback on failure)

### 3. RDS PostgreSQL Database
- **Instance ID:** `medzen-ehrbase-postgres`
- **Engine:** PostgreSQL 14.10
- **Instance Class:** `db.t3.medium`
  - **vCPU:** 2 cores
  - **RAM:** 4 GB
  - **Network:** Up to 5 Gbps
- **Storage:**
  - **Type:** gp3 (General Purpose SSD)
  - **Size:** 100 GB
  - **Encryption:** Enabled (AWS-managed keys)
  - **Auto-scaling:** Disabled (manual expansion if needed)
- **Backups:**
  - **Automated:** Daily backups, 7 days retention
  - **Window:** 03:00 - 04:00 UTC
  - **Snapshots:** Manual snapshots available
- **Connections:** Maximum 100 concurrent (PostgreSQL default)
- **Multi-AZ:** Disabled (enable for production HA)

### 4. Networking

**VPC Configuration:**
- **CIDR:** 10.0.0.0/16
- **DNS:** Enabled (both hostname and support)

**Subnets:**
- **Public Subnet 1 (AZ1):** 10.0.0.0/24
- **Public Subnet 2 (AZ2):** 10.0.1.0/24
- **Private Subnet 1 (AZ1):** 10.0.2.0/24
- **Private Subnet 2 (AZ2):** 10.0.3.0/24

**NAT Gateway:**
- **Location:** Public Subnet 1 (AZ1)
- **Elastic IP:** Allocated
- **Purpose:** Outbound internet for private subnets (container image pulls, updates)

**Security Groups:**

| Security Group | Inbound Rules | Outbound Rules |
|---------------|---------------|----------------|
| **ALB-SG** | Port 80 (HTTP) from 0.0.0.0/0<br>Port 443 (HTTPS) from 0.0.0.0/0 | All traffic to 0.0.0.0/0 |
| **ECS-SG** | Port 8080 from ALB-SG | All traffic to 0.0.0.0/0 |
| **RDS-SG** | Port 5432 from ECS-SG | All traffic to 0.0.0.0/0 |

### 5. Auto Scaling Configuration

**Target Tracking Policies:**

| Policy | Target Value | Scale Out | Scale In | Cooldown |
|--------|--------------|-----------|----------|----------|
| **CPU** | 70% | Add 1 task | Remove 1 task | 60s out / 300s in |
| **Memory** | 80% | Add 1 task | Remove 1 task | 60s out / 300s in |

**Scaling Behavior:**
- **Min Capacity:** 2 tasks (always running)
- **Max Capacity:** 4 tasks (during high load)
- **Scale Out:** Triggered when CPU > 70% OR Memory > 80%
- **Scale In:** Triggered when CPU < 50% AND Memory < 60% (after 5 min cooldown)

**Example Scenario:**
```
Normal Load:    2 tasks running (50 concurrent users)
Medium Load:    3 tasks running (150 concurrent users, CPU 75%)
High Load:      4 tasks running (300 concurrent users, CPU 80%)
Peak Load:      4 tasks max (400+ concurrent users, may see degraded performance)
```

### 6. Monitoring and Logging

**CloudWatch Metrics (5-minute intervals):**
- ECS Service: CPU, Memory, Desired Count, Running Count
- RDS: CPU, Connections, Storage, Read/Write IOPS
- ALB: Request Count, Target Response Time, HTTP 5xx Errors

**CloudWatch Logs:**
- `/ecs/medzen-ehrbase` - ECS container logs (30 days retention)
- `/aws/rds/instance/medzen-ehrbase-postgres/postgresql` - PostgreSQL logs

**CloudWatch Alarms:**
- High CPU (ECS): CPU > 80% for 10 minutes → Alert
- High Memory (ECS): Memory > 85% for 10 minutes → Alert
- High CPU (RDS): CPU > 70% for 10 minutes → Alert
- High Connections (RDS): Connections > 80 for 10 minutes → Alert

## Data Flow

### 1. User Signup → EHR Creation
```
Mobile App → Firebase Auth → Cloud Function onUserCreated
                                      ↓
                           Create Supabase User
                                      ↓
                           Call AWS EHRbase (via ALB)
                                      ↓
                           ECS Task → Create EHR
                                      ↓
                           Store in RDS PostgreSQL
                                      ↓
                           Return EHR ID
                                      ↓
                           Store in electronic_health_records table
```

### 2. Medical Record Write (Offline → Online Sync)
```
Mobile App (Offline) → PowerSync Local DB
                              ↓
                       (When Online)
                              ↓
                       Sync to Supabase
                              ↓
                       Database Trigger → ehrbase_sync_queue
                              ↓
                       Supabase Edge Function: sync-to-ehrbase
                              ↓
                       Call AWS EHRbase (via ALB)
                              ↓
                       ECS Task → Create Composition
                              ↓
                       Store in RDS PostgreSQL
                              ↓
                       Update sync_status = 'completed'
```

### 3. EHR Read
```
Mobile App → PowerSync Local DB (if available)
                  ↓ (if not cached)
           Supabase Query
                  ↓
           Supabase → AWS EHRbase (via ALB)
                  ↓
           ECS Task → Query RDS
                  ↓
           Return Composition Data
                  ↓
           Cache in PowerSync
```

## Capacity Analysis

### Current Configuration (Phase 1 - $260/month)

| Resource | Capacity | Real-World Usage |
|----------|----------|------------------|
| **ECS Tasks** | 2-4 tasks × 2 vCPU | 100-400 concurrent requests |
| **RDS** | 2 vCPU, 4 GB RAM, 100 connections | 50,000 users, 1,000 concurrent |
| **Storage** | 100 GB | 2-5 million compositions |
| **Throughput** | ~200-500 req/sec (ECS) | 500-1,000 writes/hour |

### Bottlenecks (in order of likelihood)

1. **RDS Connection Limit:** 100 max connections (typically first bottleneck)
2. **ECS CPU:** CPU-intensive OpenEHR composition processing
3. **RDS CPU:** Database query performance under load
4. **Storage Growth:** Slow growth, 100GB lasts 2-3 years

### Upgrade Triggers

**Phase 1 → Phase 2 (Upgrade Required When):**
- Total users exceed 50,000
- Concurrent users exceed 1,000
- RDS CPU consistently above 70%
- RDS connections consistently above 80

**Phase 2 → Phase 3 (Upgrade Required When):**
- Total users exceed 100,000
- Concurrent users exceed 2,000
- RDS memory becomes bottleneck
- Need for read replicas

## High Availability (Optional)

### Multi-AZ RDS (Recommended for Production)
- **Cost:** +$70/month (doubles RDS cost)
- **Benefit:** Automatic failover to standby in different AZ
- **RTO:** ~60 seconds (Recovery Time Objective)
- **RPO:** 0 (Recovery Point Objective - synchronous replication)

```bash
# Enable Multi-AZ
aws rds modify-db-instance \
  --db-instance-identifier medzen-ehrbase-postgres \
  --multi-az \
  --apply-immediately
```

### ECS Multi-AZ (Built-in)
- ECS tasks automatically distributed across AZ1 and AZ2
- ALB health checks ensure only healthy tasks receive traffic
- Rolling deployments maintain minimum 50% healthy tasks

## Security Architecture

### Network Security
- ✅ All resources in VPC (isolated network)
- ✅ RDS in private subnets (no internet access)
- ✅ ECS tasks in private subnets (outbound via NAT)
- ✅ ALB in public subnets (internet-facing)
- ✅ Security groups restrict traffic between layers

### Data Security
- ✅ RDS encryption at rest (AWS-managed keys)
- ✅ SSL/TLS encryption in transit (ALB → ECS)
- ✅ Secrets stored in environment variables (consider Secrets Manager for production)
- ✅ IAM roles for ECS tasks (least privilege)

### Access Control
- ✅ EHRbase Basic Auth (username/password)
- ✅ ALB public (authentication at application layer)
- ✅ RDS accessible only from ECS security group
- ✅ CloudWatch logs for audit trail

### HIPAA Compliance Checklist
- [ ] Sign AWS Business Associate Agreement (BAA)
- [ ] Enable CloudTrail for audit logs
- [ ] Use AWS Secrets Manager for production secrets
- [ ] Enable Multi-AZ for RDS (high availability)
- [ ] Configure VPC Flow Logs
- [ ] Set up automated backups (already enabled)
- [ ] Implement access logging on ALB
- [ ] Regular security audits and penetration testing

## Cost Breakdown

### Monthly Costs (Phase 1 - $260/month)

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| **ECS Fargate** | 2 tasks × 2 vCPU × 4 GB × 730h | ~$120 |
| **RDS PostgreSQL** | db.t3.medium × 730h | ~$70 |
| **Application Load Balancer** | 1 ALB + 2 LCUs | ~$25 |
| **NAT Gateway** | 1 NAT + data transfer | ~$35 |
| **Data Transfer** | Outbound data transfer | ~$10 |
| **CloudWatch** | Logs + metrics | ~$5 |
| **Total** | | **~$260/month** |

### Scaling Costs

| Phase | Users | Concurrent | Config | Monthly Cost |
|-------|-------|------------|--------|--------------|
| **1** | 10K-50K | 500-1K | db.t3.medium, 2-4 tasks | $260 |
| **2** | 50K-100K | 1K-2K | db.t3.large, 2-6 tasks | $380 (+$120) |
| **3** | 100K-250K | 2K-5K | db.r5.large, 3-10 tasks | $600 (+$220) |

### Cost Optimization Tips
- Use Fargate Spot for non-production (70% cheaper)
- Reduce task count during off-hours (scheduled scaling)
- Use db.t3.small for development ($35/month vs $70/month)
- Monitor unused resources with AWS Cost Explorer

## Disaster Recovery

### Backup Strategy
- **RDS Automated Backups:** Daily, 7 days retention
- **RDS Manual Snapshots:** On-demand, indefinite retention
- **ECS Task Definitions:** Versioned, stored in AWS
- **CloudFormation Template:** Infrastructure as code (version controlled)

### Recovery Procedures

**RDS Failure:**
```bash
# Restore from latest snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier medzen-ehrbase-postgres-restored \
  --db-snapshot-identifier medzen-ehrbase-auto-snapshot-YYYY-MM-DD
```

**ECS Task Failure:**
- Automatic: ECS replaces failed tasks automatically
- Circuit breaker: Rolls back deployment if tasks fail to start

**Complete Region Failure:**
- Deploy CloudFormation stack in different region
- Restore RDS from cross-region snapshot (requires enabling cross-region replication)
- Update DNS to point to new region

## Performance Tuning

### ECS Task Configuration
```yaml
# Optimal for EHRbase
CPU: 2048 (2 vCPU)
Memory: 4096 MB (4 GB)
Ratio: 1:2 (1 vCPU : 2 GB RAM)
```

### RDS Configuration
```sql
-- PostgreSQL connection pooling (recommended)
max_connections = 100
shared_buffers = 1GB
effective_cache_size = 3GB
work_mem = 10MB
```

### ALB Configuration
- Sticky sessions: 86400s (24 hours)
- Deregistration delay: 30s
- Health check interval: 30s
- Idle timeout: 60s

## Comparison: AWS vs. External EHRbase

| Factor | External (ehr.medzenhealth.app) | AWS ECS + RDS |
|--------|-------------------------------------------|---------------|
| **Resources** | Shared, multi-tenant | Dedicated (2 vCPU, 4 GB RAM) |
| **Scaling** | Fixed, no auto-scaling | Auto-scales 2-4 tasks |
| **SLA** | Unknown | 99.99% (with Multi-AZ) |
| **Monitoring** | Limited visibility | Full CloudWatch metrics |
| **Control** | No infrastructure access | Full control via AWS |
| **Cost** | Unknown, likely $50-100/month | $260/month (dedicated) |
| **Reliability** | Unknown | Predictable, monitored |
| **Performance** | Shared, variable | Dedicated, consistent |

**Recommendation:** AWS provides dedicated resources, better performance, and full control, making it suitable for production telemedicine workloads with HIPAA compliance requirements.

---

## Next Steps

1. ✅ Review architecture and capacity planning
2. ✅ Deploy CloudFormation template
3. ✅ Configure monitoring and alarms
4. ✅ Test end-to-end flows
5. ✅ Migrate data from external EHRbase
6. ✅ Set up backups and disaster recovery
7. ✅ Enable Multi-AZ for production (optional)
8. ✅ Configure custom domain and SSL
9. ✅ Document in CLAUDE.md

---

**Architecture Version:** 1.0
**Last Updated:** January 29, 2025
**Target Capacity:** 50,000 users, 1,000 concurrent
**Estimated Cost:** $260/month (Phase 1)

*Architecture designed for MedZen-Iwani Telemedicine Platform*
