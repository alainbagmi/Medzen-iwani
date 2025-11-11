# EHRbase AWS Deployment Package

This directory contains all scripts and documentation needed to deploy EHRbase from Proxmox to AWS ECS Fargate + RDS PostgreSQL.

## Overview

**Migration:** Proxmox K3s (10.10.10.x) → AWS ECS Fargate + RDS PostgreSQL
**Target Capacity:** 10,000-50,000 users, 500-1,000 concurrent users
**Monthly Cost:** ~$260
**Timeline:** 2-3 days with focused effort

## Directory Structure

```
aws-deployment/
├── README.md                          # This file
├── 00-prerequisites.sh                # Check prerequisites and setup environment
├── 01-setup-infrastructure.sh         # Create VPC, subnets, security groups
├── 02-setup-database.sh               # Create RDS PostgreSQL instance
├── 03-migrate-database.sh             # Export from Proxmox, import to RDS
├── 04-setup-ecs.sh                    # Create ECS cluster, ALB, task definition
├── 05-update-integrations.sh          # Update Firebase and Supabase configs
├── 06-setup-monitoring.sh             # Create CloudWatch dashboard and alarms
├── 07-validate-deployment.sh          # Run all validation tests
├── 08-setup-dns-ssl.sh                # Configure DNS and SSL (optional)
├── rollback.sh                        # Emergency rollback to Proxmox
├── cleanup.sh                         # Remove all AWS resources (use carefully!)
├── configs/
│   ├── task-definition-template.json  # ECS task definition template
│   ├── dashboard-template.json        # CloudWatch dashboard template
│   └── init-database.sql              # Database initialization script
└── docs/
    ├── DEPLOYMENT_GUIDE.md            # Complete step-by-step guide
    ├── ARCHITECTURE.md                # AWS architecture documentation
    ├── TROUBLESHOOTING.md             # Common issues and solutions
    └── COST_BREAKDOWN.md              # Detailed cost analysis
```

## Quick Start

### Step 1: Prerequisites

```bash
# Navigate to deployment directory
cd aws-deployment

# Check prerequisites
./00-prerequisites.sh
```

### Step 2: Configure Environment

```bash
# Edit the environment file (created by prerequisites script)
nano .env

# Required variables:
# - AWS_REGION (default: us-east-1)
# - PROJECT_NAME (default: medzen-ehrbase)
# - PROXMOX_HOST (your Proxmox cluster IP)
```

### Step 3: Run Deployment Scripts in Order

```bash
# 1. Setup infrastructure (~30 minutes)
./01-setup-infrastructure.sh

# 2. Setup database (~45 minutes including RDS provisioning)
./02-setup-database.sh

# 3. Migrate database (~30 minutes)
./03-migrate-database.sh

# 4. Setup ECS (~45 minutes)
./04-setup-ecs.sh

# 5. Update integrations (~20 minutes)
./05-update-integrations.sh

# 6. Setup monitoring (~20 minutes)
./06-setup-monitoring.sh

# 7. Validate deployment (~30 minutes)
./07-validate-deployment.sh

# 8. Setup DNS/SSL (optional, ~30 minutes)
./08-setup-dns-ssl.sh
```

### Step 4: Post-Deployment

After successful deployment:

1. **Monitor for 24-48 hours** - Check CloudWatch dashboard regularly
2. **Test with real users** - Have a small group test all functionality
3. **Validate cost** - Ensure daily spend is ~$8-9
4. **Keep Proxmox running** - Maintain for 30 days as backup
5. **Decommission after validation** - Remove Proxmox cluster after 30 days

## Emergency Rollback

If critical issues occur:

```bash
./rollback.sh
```

This will:
- Point DNS back to Proxmox
- Revert Firebase configurations
- Revert Supabase configurations
- Keep AWS infrastructure for investigation

## Scripts Overview

### 00-prerequisites.sh
- Checks AWS CLI, Firebase CLI, Supabase CLI, kubectl
- Verifies AWS credentials and permissions
- Creates `.env` file for configuration
- Tests connectivity to Proxmox cluster

### 01-setup-infrastructure.sh
- Creates VPC with public/private subnets
- Sets up Internet Gateway and NAT Gateway
- Configures route tables
- Creates security groups for ALB, ECS, RDS
- Exports infrastructure IDs to `.env`

### 02-setup-database.sh
- Generates strong passwords
- Stores passwords in AWS Secrets Manager
- Creates RDS PostgreSQL instance (db.t3.medium)
- Configures Multi-AZ, backups, monitoring
- Waits for RDS to be available

### 03-migrate-database.sh
- Exports database from Proxmox PostgreSQL
- Initializes RDS database schema
- Creates users and sets permissions
- Imports data from backup
- Validates migration success

### 04-setup-ecs.sh
- Creates ECS cluster with Fargate capacity
- Creates Application Load Balancer
- Creates target group with health checks
- Registers ECS task definition
- Creates ECS service with 2 tasks
- Configures auto-scaling (2-4 tasks)

### 05-update-integrations.sh
- Updates Firebase Cloud Functions config
- Deploys updated Firebase functions
- Updates Supabase Edge Function secrets
- Redeploys Supabase edge functions
- Tests integration endpoints

### 06-setup-monitoring.sh
- Creates CloudWatch log group
- Creates CloudWatch dashboard
- Sets up alarms for:
  - ECS CPU/memory high
  - RDS CPU high
  - ALB slow response
  - RDS connection count
- Configures SNS topics for alerts (optional)

### 07-validate-deployment.sh
- Tests EHRbase API health
- Tests database connectivity
- Verifies ECS service health
- Tests ALB health checks
- Validates Firebase integration
- Validates Supabase integration
- Runs end-to-end test scenarios
- Generates validation report

### 08-setup-dns-ssl.sh
- Option A: Configures Cloudflare Tunnel
- Option B: Requests AWS Certificate Manager cert
- Creates HTTPS listener on ALB
- Updates integrations to use HTTPS
- Validates SSL configuration

## Important Notes

### Before You Start

1. **Backup Everything** - Take full backup of Proxmox database before starting
2. **Test Environment** - Consider testing in AWS dev environment first
3. **Maintenance Window** - Plan 2-4 hour maintenance window for cutover
4. **User Notification** - Notify users 48 hours before migration
5. **Team Availability** - Ensure all team members available during migration

### During Migration

1. **Follow Order** - Execute scripts in numerical order
2. **Check Outputs** - Review each script output before proceeding
3. **Save Credentials** - All passwords saved in Secrets Manager and `.env`
4. **Monitor Logs** - Watch CloudWatch logs during deployment
5. **Test Incrementally** - Test after each major step

### After Migration

1. **Monitor Closely** - Check CloudWatch every 2-3 hours for first 24 hours
2. **User Feedback** - Collect feedback from early users
3. **Performance Tuning** - Adjust resources based on actual usage
4. **Cost Tracking** - Verify daily costs match expectations (~$8-9/day)
5. **Documentation** - Update internal documentation with new endpoints

## Cost Breakdown

| Component | Configuration | Monthly Cost |
|-----------|---------------|--------------|
| ECS Fargate (2 tasks) | 2 × 2vCPU × 4GB RAM | $87 |
| ECS Fargate (auto-scale) | Avg 0.5 extra tasks | $22 |
| RDS db.t3.medium | Multi-AZ, 100GB | $120 |
| RDS Storage | 100GB gp3 | $12 |
| Application Load Balancer | Standard ALB | $18 |
| Data Transfer | ~100GB/month | $9 |
| **Total** | | **~$268/month** |

## Support

### Getting Help

1. **Check Troubleshooting Guide** - `docs/TROUBLESHOOTING.md`
2. **Review Logs** - CloudWatch, Firebase, Supabase logs
3. **AWS Support** - Use AWS Support if infrastructure issues
4. **Rollback if Critical** - Use `rollback.sh` if severe issues

### Common Issues

- **ECS tasks not starting** - Check security groups, RDS connectivity
- **Health checks failing** - Verify EHRbase API responding on port 8080
- **Database connection errors** - Check RDS security group, credentials
- **Integration failures** - Verify Firebase/Supabase configs updated
- **High costs** - Check auto-scaling, data transfer, RDS backups

## Next Steps

1. Read `docs/DEPLOYMENT_GUIDE.md` for detailed walkthrough
2. Review `docs/ARCHITECTURE.md` to understand AWS setup
3. Run `./00-prerequisites.sh` to check readiness
4. Execute deployment scripts in order
5. Monitor and validate for 7 days
6. Optimize based on actual usage patterns

## Security Notes

- **`.env` file** - Contains sensitive information, never commit to git
- **Secrets Manager** - All passwords stored in AWS Secrets Manager
- **Security Groups** - Restrictive rules, only necessary ports open
- **IAM Roles** - Least privilege access for ECS tasks
- **Encryption** - RDS encrypted at rest, SSL for data in transit
- **Backups** - Automated daily backups, 7-day retention

## Maintenance

### Daily (First Week)
- Check CloudWatch dashboard
- Review error logs
- Verify sync queue processing
- Monitor costs

### Weekly
- Review RDS slow query log
- Check auto-scaling patterns
- Analyze CloudWatch Insights
- Review security group rules

### Monthly
- Update EHRbase container image
- Review and optimize costs
- Test disaster recovery
- Update documentation

---

**Deployment Version:** 1.0
**Last Updated:** 2025-01-29
**Project:** MedZen Iwani EHRbase Migration
