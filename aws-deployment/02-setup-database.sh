#!/bin/bash

################################################################################
# EHRbase AWS Migration - RDS Database Setup
# Creates RDS PostgreSQL instance, generates passwords, stores in Secrets Manager
################################################################################

set -e  # Exit on error

echo "=========================================="
echo "EHRbase AWS Migration - RDS Database Setup"
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
if [ -z "$VPC_ID" ] || [ -z "$PRIVATE_SUBNET_1" ] || [ -z "$PRIVATE_SUBNET_2" ] || [ -z "$RDS_SG" ]; then
    echo -e "${RED}Error:${NC} Required infrastructure variables not found"
    echo "Run ./01-setup-infrastructure.sh first"
    exit 1
fi

echo -e "${BLUE}Configuration:${NC}"
echo "  Project: $PROJECT_NAME"
echo "  Region: $AWS_REGION"
echo "  Multi-AZ: $ENABLE_MULTI_AZ"
echo ""

################################################################################
# 1. CREATE DB SUBNET GROUP
################################################################################

echo "=========================================="
echo "Step 1: Creating DB Subnet Group"
echo "=========================================="

aws rds create-db-subnet-group \
    --db-subnet-group-name ${PROJECT_NAME}-db-subnet-group \
    --db-subnet-group-description "Subnet group for EHRbase RDS" \
    --subnet-ids $PRIVATE_SUBNET_1 $PRIVATE_SUBNET_2 \
    --tags Key=Project,Value=MedZen \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} DB subnet group created: ${PROJECT_NAME}-db-subnet-group"

################################################################################
# 2. GENERATE PASSWORDS
################################################################################

echo ""
echo "=========================================="
echo "Step 2: Generating Secure Passwords"
echo "=========================================="

# Generate strong passwords
DB_ADMIN_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
DB_USER_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
EHRBASE_USER_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

echo -e "${GREEN}✓${NC} Generated database admin password"
echo -e "${GREEN}✓${NC} Generated database user password"
echo -e "${GREEN}✓${NC} Generated EHRbase API password"

################################################################################
# 3. STORE PASSWORDS IN SECRETS MANAGER
################################################################################

echo ""
echo "=========================================="
echo "Step 3: Storing Passwords in Secrets Manager"
echo "=========================================="

# Store DB admin password
aws secretsmanager create-secret \
    --name ${PROJECT_NAME}/db_admin_password \
    --description "RDS admin password for EHRbase PostgreSQL" \
    --secret-string "$DB_ADMIN_PASS" \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} Stored: ${PROJECT_NAME}/db_admin_password"

# Store DB user password
aws secretsmanager create-secret \
    --name ${PROJECT_NAME}/db_user_password \
    --description "RDS restricted user password for EHRbase" \
    --secret-string "$DB_USER_PASS" \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} Stored: ${PROJECT_NAME}/db_user_password"

# Store EHRbase basic auth credentials
aws secretsmanager create-secret \
    --name ${PROJECT_NAME}/ehrbase_basic_auth \
    --description "EHRbase API Basic Auth credentials" \
    --secret-string "{\"username\":\"ehrbase-user\",\"password\":\"$EHRBASE_USER_PASS\"}" \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} Stored: ${PROJECT_NAME}/ehrbase_basic_auth"

# Update .env file
sed -i '' "s|^DB_ADMIN_PASS=.*|DB_ADMIN_PASS=$DB_ADMIN_PASS|" .env
sed -i '' "s|^DB_USER_PASS=.*|DB_USER_PASS=$DB_USER_PASS|" .env
sed -i '' "s|^EHRBASE_USER_PASS=.*|EHRBASE_USER_PASS=$EHRBASE_USER_PASS|" .env

# Save passwords to secure file
cat > .passwords << EOF
EHRbase AWS Deployment - Credentials
=====================================
IMPORTANT: Store these securely and delete this file after recording

Database Admin Password: $DB_ADMIN_PASS
Database User Password:  $DB_USER_PASS
EHRbase API Password:    $EHRBASE_USER_PASS

These passwords are also stored in AWS Secrets Manager:
- ${PROJECT_NAME}/db_admin_password
- ${PROJECT_NAME}/db_user_password
- ${PROJECT_NAME}/ehrbase_basic_auth

Generated: $(date)
EOF

chmod 600 .passwords

echo -e "${YELLOW}⚠${NC}  Passwords saved to .passwords file (secure this file!)"

################################################################################
# 4. CREATE RDS INSTANCE
################################################################################

echo ""
echo "=========================================="
echo "Step 4: Creating RDS PostgreSQL Instance"
echo "=========================================="
echo ""
echo -e "${BLUE}Instance Configuration:${NC}"
echo "  Instance Class: db.t3.medium"
echo "  CPU: 2 vCPU"
echo "  Memory: 4 GB"
echo "  Storage: 100 GB gp3"
echo "  Multi-AZ: $ENABLE_MULTI_AZ"
echo "  PostgreSQL Version: 16.1"
echo ""
echo -e "${YELLOW}⏳${NC} This will take 10-15 minutes..."
echo ""

read -p "Create RDS instance? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted"
    exit 1
fi

aws rds create-db-instance \
    --db-instance-identifier ${PROJECT_NAME}-db \
    --db-instance-class db.t3.medium \
    --engine postgres \
    --engine-version 16.1 \
    --master-username ehrbase_admin \
    --master-user-password "$DB_ADMIN_PASS" \
    --allocated-storage 100 \
    --storage-type gp3 \
    --storage-encrypted \
    --vpc-security-group-ids $RDS_SG \
    --db-subnet-group-name ${PROJECT_NAME}-db-subnet-group \
    --backup-retention-period 7 \
    --preferred-backup-window "03:00-04:00" \
    --preferred-maintenance-window "sun:04:00-sun:05:00" \
    --multi-az $ENABLE_MULTI_AZ \
    --publicly-accessible false \
    --enable-cloudwatch-logs-exports postgresql \
    --tags Key=Project,Value=MedZen Key=Environment,Value=Production Key=ManagedBy,Value=ehrbase-migration \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} RDS instance creation initiated: ${PROJECT_NAME}-db"
echo ""
echo -e "${YELLOW}⏳${NC} Waiting for RDS instance to become available..."
echo "  This typically takes 10-15 minutes"
echo "  You can monitor progress with:"
echo "  aws rds describe-db-instances --db-instance-identifier ${PROJECT_NAME}-db --query 'DBInstances[0].DBInstanceStatus'"
echo ""

# Wait for RDS to be ready
START_TIME=$(date +%s)
aws rds wait db-instance-available \
    --db-instance-identifier ${PROJECT_NAME}-db \
    --region $AWS_REGION

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo -e "${GREEN}✓${NC} RDS instance is now available (took ${MINUTES}m ${SECONDS}s)"

################################################################################
# 5. GET RDS ENDPOINT
################################################################################

echo ""
echo "=========================================="
echo "Step 5: Retrieving RDS Endpoint"
echo "=========================================="

RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier ${PROJECT_NAME}-db \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text \
    --region $AWS_REGION)

RDS_PORT=$(aws rds describe-db-instances \
    --db-instance-identifier ${PROJECT_NAME}-db \
    --query 'DBInstances[0].Endpoint.Port' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}✓${NC} RDS Endpoint: $RDS_ENDPOINT:$RDS_PORT"

# Update .env
sed -i '' "s|^RDS_ENDPOINT=.*|RDS_ENDPOINT=$RDS_ENDPOINT|" .env

################################################################################
# SUMMARY
################################################################################

echo ""
echo "=========================================="
echo "RDS Database Setup Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}Database Information:${NC}"
echo "  Instance ID:    ${PROJECT_NAME}-db"
echo "  Endpoint:       $RDS_ENDPOINT:$RDS_PORT"
echo "  Database:       ehrbase (to be created)"
echo "  Admin User:     ehrbase_admin"
echo "  Restricted User: ehrbase_restricted (to be created)"
echo ""
echo -e "${GREEN}Secrets Stored:${NC}"
echo "  ${PROJECT_NAME}/db_admin_password"
echo "  ${PROJECT_NAME}/db_user_password"
echo "  ${PROJECT_NAME}/ehrbase_basic_auth"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  - Passwords saved to .passwords file"
echo "  - Store these credentials securely"
echo "  - Delete .passwords file after recording"
echo ""
echo -e "${GREEN}Next step:${NC}"
echo "  ./03-migrate-database.sh"
echo ""
