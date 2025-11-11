#!/bin/bash

################################################################################
# EHRbase AWS Production - ECS Fargate Setup
# Creates ECS cluster, task definition, ALB, target group, and service
################################################################################

set -e  # Exit on error

echo "=========================================="
echo "EHRbase AWS Production - ECS Fargate Setup"
echo "=========================================="
echo ""

# Load environment variables
if [ ! -f ".env" ]; then
    echo "Error: .env file not found"
    exit 1
fi

source .env

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check required variables
if [ -z "$VPC_ID" ] || [ -z "$RDS_ENDPOINT" ] || [ -z "$DB_USER_PASS" ]; then
    echo -e "${RED}Error:${NC} Required infrastructure variables not found"
    echo "Run previous setup scripts first"
    exit 1
fi

echo -e "${BLUE}Configuration:${NC}"
echo "  Project: $PROJECT_NAME"
echo "  Region: $AWS_REGION"
echo "  EHRbase Version: $EHRBASE_VERSION"
echo ""

################################################################################
# 1. CREATE ECS CLUSTER
################################################################################

echo "=========================================="
echo "Step 1: Creating ECS Cluster"
echo "=========================================="

aws ecs create-cluster \
    --cluster-name ${PROJECT_NAME}-cluster \
    --capacity-providers FARGATE FARGATE_SPOT \
    --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 \
    --tags key=Project,value=MedZen key=Environment,value=Production \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} ECS cluster created: ${PROJECT_NAME}-cluster"

################################################################################
# 2. CREATE APPLICATION LOAD BALANCER
################################################################################

echo ""
echo "=========================================="
echo "Step 2: Creating Application Load Balancer"
echo "=========================================="

ALB_ARN=$(aws elbv2 create-load-balancer \
    --name ${PROJECT_NAME}-alb \
    --subnets $PUBLIC_SUBNET_1 $PUBLIC_SUBNET_2 \
    --security-groups $ALB_SG \
    --scheme internet-facing \
    --type application \
    --ip-address-type ipv4 \
    --tags Key=Project,Value=MedZen \
    --region $AWS_REGION \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

echo -e "${GREEN}✓${NC} ALB created"

# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns $ALB_ARN \
    --query 'LoadBalancers[0].DNSName' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}✓${NC} ALB DNS: $ALB_DNS"

# Update .env
sed -i '' "s|^ALB_DNS=.*|ALB_DNS=$ALB_DNS|" .env

################################################################################
# 3. CREATE TARGET GROUP
################################################################################

echo ""
echo "=========================================="
echo "Step 3: Creating Target Group"
echo "=========================================="

TG_ARN=$(aws elbv2 create-target-group \
    --name ${PROJECT_NAME}-tg \
    --protocol HTTP \
    --port 8080 \
    --vpc-id $VPC_ID \
    --target-type ip \
    --health-check-enabled \
    --health-check-protocol HTTP \
    --health-check-path /ehrbase/rest/status \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --matcher HttpCode=200 \
    --region $AWS_REGION \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

echo -e "${GREEN}✓${NC} Target group created: ${PROJECT_NAME}-tg"

# Configure deregistration delay
aws elbv2 modify-target-group-attributes \
    --target-group-arn $TG_ARN \
    --attributes Key=deregistration_delay.timeout_seconds,Value=30 \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} Target group attributes configured"

################################################################################
# 4. CREATE ALB LISTENER
################################################################################

echo ""
echo "=========================================="
echo "Step 4: Creating ALB Listener"
echo "=========================================="

aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} HTTP listener created (port 80)"

################################################################################
# 5. CREATE IAM ROLES
################################################################################

echo ""
echo "=========================================="
echo "Step 5: Creating IAM Roles"
echo "=========================================="

# ECS Task Execution Role
cat > /tmp/ecs-task-execution-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Check if role exists
if aws iam get-role --role-name ${PROJECT_NAME}-ecs-execution-role --region $AWS_REGION > /dev/null 2>&1; then
    EXEC_ROLE_ARN=$(aws iam get-role \
        --role-name ${PROJECT_NAME}-ecs-execution-role \
        --query 'Role.Arn' \
        --output text)
    echo -e "${YELLOW}!${NC} ECS execution role already exists"
else
    EXEC_ROLE_ARN=$(aws iam create-role \
        --role-name ${PROJECT_NAME}-ecs-execution-role \
        --assume-role-policy-document file:///tmp/ecs-task-execution-trust-policy.json \
        --tags Key=Project,Value=MedZen \
        --query 'Role.Arn' \
        --output text)
    echo -e "${GREEN}✓${NC} ECS execution role created"
fi

# Attach AWS managed policies
aws iam attach-role-policy \
    --role-name ${PROJECT_NAME}-ecs-execution-role \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy \
    > /dev/null 2>&1 || true

aws iam attach-role-policy \
    --role-name ${PROJECT_NAME}-ecs-execution-role \
    --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess \
    > /dev/null 2>&1 || true

echo -e "${GREEN}✓${NC} Attached execution policies"

# Create inline policy for Secrets Manager access
cat > /tmp/secrets-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:${AWS_REGION}:${AWS_ACCOUNT_ID}:secret:${PROJECT_NAME}/*"
      ]
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name ${PROJECT_NAME}-ecs-execution-role \
    --policy-name SecretsManagerAccess \
    --policy-document file:///tmp/secrets-policy.json \
    > /dev/null 2>&1 || true

echo -e "${GREEN}✓${NC} Secrets Manager access configured"

# ECS Task Role (for application)
if aws iam get-role --role-name ${PROJECT_NAME}-ecs-task-role --region $AWS_REGION > /dev/null 2>&1; then
    TASK_ROLE_ARN=$(aws iam get-role \
        --role-name ${PROJECT_NAME}-ecs-task-role \
        --query 'Role.Arn' \
        --output text)
    echo -e "${YELLOW}!${NC} ECS task role already exists"
else
    TASK_ROLE_ARN=$(aws iam create-role \
        --role-name ${PROJECT_NAME}-ecs-task-role \
        --assume-role-policy-document file:///tmp/ecs-task-execution-trust-policy.json \
        --tags Key=Project,Value=MedZen \
        --query 'Role.Arn' \
        --output text)
    echo -e "${GREEN}✓${NC} ECS task role created"
fi

# Cleanup temp files
rm -f /tmp/ecs-task-execution-trust-policy.json /tmp/secrets-policy.json

################################################################################
# 6. CREATE CLOUDWATCH LOG GROUP
################################################################################

echo ""
echo "=========================================="
echo "Step 6: Creating CloudWatch Log Group"
echo "=========================================="

aws logs create-log-group \
    --log-group-name /ecs/${PROJECT_NAME} \
    --region $AWS_REGION \
    > /dev/null 2>&1 || echo -e "${YELLOW}!${NC} Log group already exists"

aws logs put-retention-policy \
    --log-group-name /ecs/${PROJECT_NAME} \
    --retention-in-days 30 \
    --region $AWS_REGION \
    > /dev/null 2>&1 || true

echo -e "${GREEN}✓${NC} Log group created: /ecs/${PROJECT_NAME}"

################################################################################
# 7. CREATE TASK DEFINITION
################################################################################

echo ""
echo "=========================================="
echo "Step 7: Creating ECS Task Definition"
echo "=========================================="

# Get secrets ARNs
DB_USER_PASS_ARN=$(aws secretsmanager describe-secret \
    --secret-id ${PROJECT_NAME}/db_user_password \
    --query 'ARN' \
    --output text \
    --region $AWS_REGION)

EHRBASE_AUTH_ARN=$(aws secretsmanager describe-secret \
    --secret-id ${PROJECT_NAME}/ehrbase_basic_auth \
    --query 'ARN' \
    --output text \
    --region $AWS_REGION)

# Use official EHRbase image
EHRBASE_IMAGE="ehrbase/ehrbase:${EHRBASE_VERSION}"

cat > configs/task-definition.json << EOF
{
  "family": "${PROJECT_NAME}-ehrbase",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "executionRoleArn": "${EXEC_ROLE_ARN}",
  "taskRoleArn": "${TASK_ROLE_ARN}",
  "containerDefinitions": [
    {
      "name": "ehrbase",
      "image": "${EHRBASE_IMAGE}",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "DB_URL",
          "value": "jdbc:postgresql://${RDS_ENDPOINT}:5432/ehrbase"
        },
        {
          "name": "DB_USER",
          "value": "ehrbase_restricted"
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
          "name": "SPRING_PROFILES_ACTIVE",
          "value": "docker"
        },
        {
          "name": "JAVA_TOOL_OPTIONS",
          "value": "-Xmx1536m"
        },
        {
          "name": "SERVER_NODENAME",
          "value": "aws-ecs-node"
        }
      ],
      "secrets": [
        {
          "name": "DB_PASS",
          "valueFrom": "${DB_USER_PASS_ARN}"
        },
        {
          "name": "SECURITY_AUTHPASSWORD",
          "valueFrom": "${EHRBASE_AUTH_ARN}:password::"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${PROJECT_NAME}",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "ehrbase"
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
EOF

# Register task definition
TASK_DEF_ARN=$(aws ecs register-task-definition \
    --cli-input-json file://configs/task-definition.json \
    --region $AWS_REGION \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

echo -e "${GREEN}✓${NC} Task definition registered: ${PROJECT_NAME}-ehrbase"

################################################################################
# 8. CREATE ECS SERVICE
################################################################################

echo ""
echo "=========================================="
echo "Step 8: Creating ECS Service"
echo "=========================================="

cat > /tmp/service-config.json << EOF
{
  "cluster": "${PROJECT_NAME}-cluster",
  "serviceName": "${PROJECT_NAME}-service",
  "taskDefinition": "${TASK_DEF_ARN}",
  "loadBalancers": [
    {
      "targetGroupArn": "${TG_ARN}",
      "containerName": "ehrbase",
      "containerPort": 8080
    }
  ],
  "desiredCount": 2,
  "launchType": "FARGATE",
  "platformVersion": "LATEST",
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "subnets": ["${PRIVATE_SUBNET_1}", "${PRIVATE_SUBNET_2}"],
      "securityGroups": ["${ECS_SG}"],
      "assignPublicIp": "DISABLED"
    }
  },
  "healthCheckGracePeriodSeconds": 120,
  "deploymentConfiguration": {
    "maximumPercent": 200,
    "minimumHealthyPercent": 100,
    "deploymentCircuitBreaker": {
      "enable": true,
      "rollback": true
    }
  },
  "enableExecuteCommand": true
}
EOF

aws ecs create-service \
    --cli-input-json file:///tmp/service-config.json \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} ECS service created: ${PROJECT_NAME}-service"
echo ""
echo -e "${YELLOW}⏳${NC} Waiting for service to stabilize (this may take 3-5 minutes)..."

# Wait for service to become stable
aws ecs wait services-stable \
    --cluster ${PROJECT_NAME}-cluster \
    --services ${PROJECT_NAME}-service \
    --region $AWS_REGION

echo -e "${GREEN}✓${NC} Service is now stable"

# Cleanup
rm -f /tmp/service-config.json

################################################################################
# 9. CONFIGURE AUTO-SCALING
################################################################################

echo ""
echo "=========================================="
echo "Step 9: Configuring Auto-Scaling"
echo "=========================================="

# Register scalable target
aws application-autoscaling register-scalable-target \
    --service-namespace ecs \
    --resource-id service/${PROJECT_NAME}-cluster/${PROJECT_NAME}-service \
    --scalable-dimension ecs:service:DesiredCount \
    --min-capacity 2 \
    --max-capacity 4 \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} Scalable target registered (min: 2, max: 4)"

# Create scaling policy
aws application-autoscaling put-scaling-policy \
    --service-namespace ecs \
    --resource-id service/${PROJECT_NAME}-cluster/${PROJECT_NAME}-service \
    --scalable-dimension ecs:service:DesiredCount \
    --policy-name ${PROJECT_NAME}-cpu-scaling \
    --policy-type TargetTrackingScaling \
    --target-tracking-scaling-policy-configuration '{
      "TargetValue": 70.0,
      "PredefinedMetricSpecification": {
        "PredefinedMetricType": "ECSServiceAverageCPUUtilization"
      },
      "ScaleInCooldown": 300,
      "ScaleOutCooldown": 60
    }' \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} Auto-scaling policy created (target: 70% CPU)"

################################################################################
# 10. VERIFY DEPLOYMENT
################################################################################

echo ""
echo "=========================================="
echo "Step 10: Verifying Deployment"
echo "=========================================="

echo "Testing ALB health..."
sleep 10  # Give ALB time to register targets

# Check target health
HEALTH_STATUS=$(aws elbv2 describe-target-health \
    --target-group-arn $TG_ARN \
    --region $AWS_REGION \
    --query 'TargetHealthDescriptions[0].TargetHealth.State' \
    --output text 2>/dev/null || echo "unknown")

echo "  Target health: $HEALTH_STATUS"

if [ "$HEALTH_STATUS" = "healthy" ]; then
    echo -e "${GREEN}✓${NC} Targets are healthy"
else
    echo -e "${YELLOW}⚠${NC}  Targets not yet healthy (may take 1-2 minutes)"
fi

# Test EHRbase API
echo ""
echo "Testing EHRbase API..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$ALB_DNS/ehrbase/rest/status)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC} EHRbase API is responding (HTTP $HTTP_CODE)"
else
    echo -e "${YELLOW}⚠${NC}  EHRbase API returned HTTP $HTTP_CODE (may need more time)"
fi

################################################################################
# SUMMARY
################################################################################

echo ""
echo "=========================================="
echo "ECS Fargate Setup Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}Resources Created:${NC}"
echo "  ECS Cluster:        ${PROJECT_NAME}-cluster"
echo "  ECS Service:        ${PROJECT_NAME}-service"
echo "  Task Definition:    ${PROJECT_NAME}-ehrbase"
echo "  Application LB:     ${PROJECT_NAME}-alb"
echo "  Target Group:       ${PROJECT_NAME}-tg"
echo "  Log Group:          /ecs/${PROJECT_NAME}"
echo ""
echo -e "${GREEN}EHRbase Access:${NC}"
echo "  Public URL:         http://$ALB_DNS/ehrbase/rest"
echo "  Status Endpoint:    http://$ALB_DNS/ehrbase/rest/status"
echo "  OpenEHR API:        http://$ALB_DNS/ehrbase/rest/openehr/v1"
echo ""
echo -e "${GREEN}Service Configuration:${NC}"
echo "  Desired Tasks:      2"
echo "  Auto-scaling Range: 2-4 tasks"
echo "  CPU Threshold:      70%"
echo "  Health Check:       /ehrbase/rest/status (30s interval)"
echo ""
echo -e "${BLUE}Task Configuration:${NC}"
echo "  Image:              $EHRBASE_IMAGE"
echo "  CPU:                1024 (1 vCPU)"
echo "  Memory:             2048 MB"
echo "  Java Heap:          1536 MB"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  - EHRbase is now accessible at: http://$ALB_DNS"
echo "  - Import templates before using: ./04b-import-templates.sh"
echo "  - Update Firebase and Supabase configurations with this URL"
echo "  - For production, configure DNS and SSL certificate"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo "  1. Import templates:      ./04b-import-templates.sh"
echo "  2. Update integrations:   ./05-update-integrations.sh"
echo "  3. Validate deployment:   ./06-validate-deployment.sh"
echo ""
