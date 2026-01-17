# EHRbase AWS ECS Fargate Deployment - Complete

**Date:** December 5, 2025
**Region:** eu-west-1 (Ireland)
**Status:** ✅ Successfully Deployed

## Deployment Summary

Successfully deployed EHRbase 2.26.0 to AWS ECS Fargate with production-grade security using AWS Secrets Manager for credential management.

### Infrastructure Components

| Component | Details |
|-----------|---------|
| **ECS Cluster** | medzen-ehrbase-cluster |
| **ECS Service** | medzen-ehrbase-service |
| **Task Definition** | medzen-ehrbase-ehrbase:6 |
| **Running Tasks** | 2 (Fargate) |
| **Load Balancer** | medzen-ehrbase-alb-554519184.eu-west-1.elb.amazonaws.com |
| **Target Group** | medzen-ehrbase-tg (2/2 healthy) |
| **Database** | medzen-ehrbase-db.c702q40oic90.eu-west-1.rds.amazonaws.com |
| **DB Engine** | PostgreSQL 16.11 (Multi-AZ) |

### EHRbase Configuration

| Setting | Value |
|---------|-------|
| **Version** | 2.26.0 |
| **Container Image** | ehrbase/ehrbase:2.26.0 |
| **CPU** | 1024 (1 vCPU) |
| **Memory** | 2048 MB (2 GB) |
| **Port** | 8080 |
| **Context Path** | /ehrbase |
| **Schema Version (ext)** | 4 (up to date) |
| **Schema Version (ehr)** | 23 (up to date) |

### Security Implementation

#### AWS Secrets Manager
All sensitive credentials are stored in AWS Secrets Manager and injected at runtime:

1. **Database User Password**
   - ARN: `arn:aws:secretsmanager:eu-west-1:558069890522:secret:medzen-ehrbase/db_user_password-UFbgXy`
   - Used by: EHRbase runtime database connection

2. **Database Admin Password**
   - ARN: `arn:aws:secretsmanager:eu-west-1:558069890522:secret:medzen-ehrbase/db_admin_password-XbPJVv`
   - Used by: Flyway database migrations

3. **EHRbase Basic Auth**
   - ARN: `arn:aws:secretsmanager:eu-west-1:558069890522:secret:medzen-ehrbase/ehrbase_basic_auth-HM8gue`
   - Used by: API authentication
   - Username: ehrbase-user

#### IAM Roles
- **Execution Role**: `medzen-ehrbase-ecs-execution-role`
  - Permissions: Pull images, write logs, read secrets
- **Task Role**: `medzen-ehrbase-ecs-task-role`
  - Permissions: Application runtime permissions

### Network Configuration

#### VPC Setup
- **VPC**: vpc-0b482017966403649
- **Private Subnets**:
  - subnet-0d7b26b521301a351 (AZ: eu-west-1a)
  - subnet-063ded44488304e7c (AZ: eu-west-1b)
- **Security Group**: sg-0c0c1a8b694abe201
  - Ingress: Port 8080 from ALB
  - Egress: All traffic

#### Load Balancer
- **Type**: Application Load Balancer
- **Scheme**: Internet-facing
- **DNS**: medzen-ehrbase-alb-554519184.eu-west-1.elb.amazonaws.com
- **Health Check**:
  - Path: `/ehrbase/rest/status`
  - Matcher: HTTP 200,401 (401 accepted due to auth requirement)
  - Interval: 30 seconds
  - Timeout: 5 seconds
  - Healthy threshold: 2
  - Unhealthy threshold: 2

### Database Configuration

#### RDS Instance
- **Identifier**: medzen-ehrbase-db
- **Instance Class**: db.t3.medium (2 vCPU, 4 GB RAM)
- **Engine**: PostgreSQL 16.11
- **Storage**: 100 GB gp3 (encrypted)
- **Multi-AZ**: Enabled (High Availability)
- **Backup Retention**: 7 days
- **Backup Window**: 03:00-04:00 UTC
- **Maintenance Window**: Sunday 04:00-05:00 UTC

#### Database Users
1. **ehrbase_admin** (Admin)
   - Used for: Schema migrations via Flyway
   - Permissions: Full database admin rights

2. **ehrbase_restricted** (Runtime)
   - Used for: EHRbase application runtime
   - Permissions: Limited to application needs

### Deployment Resolution

#### Issue Encountered
EHRbase containers were failing to start with no logs generated, indicating a crash before logging initialization.

#### Root Cause
EHRbase 2.26.0 requires both standard database credentials (`DB_USER`, `DB_PASS`) and admin credentials (`DB_USER_ADMIN`, `DB_PASS_ADMIN`) for Flyway schema migrations. The task definition was missing the admin credentials.

#### Resolution Steps
1. Created test task definition with direct environment variables to isolate issue
2. Identified missing `DB_USER_ADMIN` and `DB_PASS_ADMIN` environment variables
3. Retrieved admin credentials from deployment scripts and Secrets Manager
4. Updated production task definition to include:
   - `DB_USER_ADMIN=ehrbase_admin` (environment variable)
   - `DB_PASS_ADMIN` from Secrets Manager (secret)
5. Fixed ALB health check to accept HTTP 401 responses (auth-protected endpoint)
6. Deployed production task definition with Secrets Manager integration
7. Verified successful container startup and Flyway migrations

### API Endpoints

Base URL: `http://medzen-ehrbase-alb-554519184.eu-west-1.elb.amazonaws.com/ehrbase`

#### Available Endpoints
- `GET /ehrbase/rest/status` - System status (requires auth)
- `GET /ehrbase/rest/openehr/v1/ehr` - List EHRs
- `POST /ehrbase/rest/openehr/v1/ehr` - Create new EHR
- `GET /ehrbase/rest/openehr/v1/ehr/{ehr_id}` - Get EHR by ID
- `POST /ehrbase/rest/openehr/v1/definition/template/adl1.4` - Upload template
- `GET /ehrbase/rest/openehr/v1/definition/template/adl1.4` - List templates

#### Authentication
All API endpoints require HTTP Basic Authentication:
- **Username**: ehrbase-user
- **Password**: Stored in `medzen-ehrbase/ehrbase_basic_auth` secret

### Logging

#### CloudWatch Logs
- **Log Group**: /ecs/medzen-ehrbase
- **Log Stream Pattern**: ehrbase/ehrbase/{task-id}
- **Retention**: 7 days (configurable)
- **Region**: eu-west-1

#### Key Log Events
- Flyway migrations execution and validation
- Schema version verification
- Application startup (Spring Boot)
- Tomcat server initialization on port 8080
- HTTP request/response logging

### High Availability Configuration

#### Service Configuration
- **Desired Count**: 2 tasks
- **Minimum Healthy Percent**: 100%
- **Maximum Percent**: 200%
- **Deployment Strategy**: Rolling update
- **Circuit Breaker**: Enabled with automatic rollback

#### Failure Handling
- Failed tasks automatically replaced by ECS
- ALB health checks ensure traffic only to healthy targets
- Multi-AZ deployment (tasks spread across 2 availability zones)
- Multi-AZ database with automatic failover

### Cost Optimization

#### Current Configuration Costs (Estimated)
- **ECS Fargate**: ~$30/month (2 tasks × 1 vCPU × 2 GB RAM)
- **RDS db.t3.medium**: ~$60/month (Multi-AZ)
- **Application Load Balancer**: ~$20/month
- **Data Transfer**: Variable based on usage
- **CloudWatch Logs**: ~$5/month (7-day retention)
- **Secrets Manager**: ~$1/month (3 secrets)

**Total Estimated Monthly Cost**: ~$116/month

### Next Steps

1. ✅ **ECS Deployment** - Complete
2. ⏳ **Import OpenEHR Templates** - Use `./04b-import-templates.sh`
3. ⏳ **Update Integrations** - Run `./05-update-integrations.sh` to update:
   - Firebase Functions with new EHRbase endpoint
   - Supabase Edge Functions configuration
4. ⏳ **Validation** - Execute `./06-validate-deployment.sh`
5. ⏳ **Monitoring** - Set up CloudWatch alarms with `./07-setup-monitoring.sh`
6. ⏳ **Multi-Region** - Deploy to eu-central-1 for disaster recovery

### Production Readiness Checklist

- [x] Infrastructure provisioned (VPC, subnets, security groups)
- [x] RDS database created with Multi-AZ
- [x] Database schema initialized via Flyway
- [x] ECS cluster and service deployed
- [x] Application Load Balancer configured
- [x] Health checks passing (2/2 targets healthy)
- [x] Secrets Manager integration for credentials
- [x] CloudWatch logging enabled
- [x] End-to-end connectivity verified
- [ ] OpenEHR templates imported
- [ ] Integration endpoints updated
- [ ] CloudWatch alarms configured
- [ ] Backup strategy validated
- [ ] Disaster recovery tested

### Access Information

#### For Deployment Team
```bash
# Check service status
aws ecs describe-services \
  --cluster medzen-ehrbase-cluster \
  --service medzen-ehrbase-service \
  --region eu-west-1

# View logs
aws logs get-log-events \
  --log-group-name /ecs/medzen-ehrbase \
  --log-stream-name ehrbase/ehrbase/{task-id} \
  --region eu-west-1

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:eu-west-1:558069890522:targetgroup/medzen-ehrbase-tg/d4c91b998217d4b3 \
  --region eu-west-1
```

#### For Application Integration
```bash
# Base URL
EHRBASE_URL="http://medzen-ehrbase-alb-554519184.eu-west-1.elb.amazonaws.com/ehrbase"

# Get credentials
EHRBASE_USER="ehrbase-user"
EHRBASE_PASS=$(aws secretsmanager get-secret-value \
  --secret-id medzen-ehrbase/ehrbase_basic_auth \
  --query 'SecretString' \
  --output text \
  --region eu-west-1 | jq -r '.password')

# Test connection
curl -u "$EHRBASE_USER:$EHRBASE_PASS" \
  "$EHRBASE_URL/rest/status"
```

### Support Contacts

- **AWS Account**: 558069890522
- **Region**: eu-west-1 (Ireland)
- **Project**: MedZen Healthcare Platform
- **Component**: EHRbase OpenEHR Server

---

**Deployment completed successfully on December 5, 2025**
