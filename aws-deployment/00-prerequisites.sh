#!/bin/bash

################################################################################
# EHRbase AWS Migration - Prerequisites Check
# This script verifies all prerequisites are met before starting deployment
################################################################################

set -e  # Exit on error

echo "=========================================="
echo "EHRbase AWS Migration - Prerequisites Check"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if all prerequisites are met
ALL_GOOD=true

# Function to check command exists
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✓${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 is NOT installed"
        ALL_GOOD=false
        return 1
    fi
}

# Function to check AWS credentials
check_aws_credentials() {
    if aws sts get-caller-identity &> /dev/null; then
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        AWS_USER=$(aws sts get-caller-identity --query Arn --output text)
        echo -e "${GREEN}✓${NC} AWS credentials configured"
        echo "  Account ID: $ACCOUNT_ID"
        echo "  User/Role: $AWS_USER"
        return 0
    else
        echo -e "${RED}✗${NC} AWS credentials NOT configured"
        echo "  Run: aws configure"
        ALL_GOOD=false
        return 1
    fi
}

# Function to check Firebase authentication
check_firebase() {
    if firebase projects:list &> /dev/null; then
        echo -e "${GREEN}✓${NC} Firebase CLI authenticated"
        return 0
    else
        echo -e "${RED}✗${NC} Firebase CLI NOT authenticated"
        echo "  Run: firebase login"
        ALL_GOOD=false
        return 1
    fi
}

# Function to check Supabase authentication
check_supabase() {
    if npx supabase projects list &> /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Supabase CLI authenticated"
        return 0
    else
        echo -e "${YELLOW}!${NC} Supabase CLI may need authentication"
        echo "  Run: npx supabase login"
        return 0
    fi
}

echo "1. Checking Required Commands"
echo "------------------------------"
check_command "aws"
check_command "firebase"
check_command "npx"
check_command "psql"
check_command "pg_dump"
check_command "pg_restore"
check_command "curl"
check_command "jq"
check_command "openssl"
echo ""

echo "2. Checking Authentication"
echo "--------------------------"
check_aws_credentials
check_firebase
check_supabase
echo ""

echo "3. Checking AWS Permissions"
echo "---------------------------"
# Check if user can create VPCs
if aws ec2 describe-vpcs --max-items 1 &> /dev/null; then
    echo -e "${GREEN}✓${NC} Can access EC2 (VPC creation)"
else
    echo -e "${RED}✗${NC} Cannot access EC2 - insufficient permissions"
    ALL_GOOD=false
fi

# Check if user can create RDS instances
if aws rds describe-db-instances --max-items 1 &> /dev/null; then
    echo -e "${GREEN}✓${NC} Can access RDS"
else
    echo -e "${RED}✗${NC} Cannot access RDS - insufficient permissions"
    ALL_GOOD=false
fi

# Check if user can create ECS clusters
if aws ecs list-clusters &> /dev/null; then
    echo -e "${GREEN}✓${NC} Can access ECS"
else
    echo -e "${RED}✗${NC} Cannot access ECS - insufficient permissions"
    ALL_GOOD=false
fi

# Check if user can create secrets
if aws secretsmanager list-secrets --max-results 1 &> /dev/null; then
    echo -e "${GREEN}✓${NC} Can access Secrets Manager"
else
    echo -e "${RED}✗${NC} Cannot access Secrets Manager - insufficient permissions"
    ALL_GOOD=false
fi
echo ""

echo "4. Creating Environment Configuration"
echo "-------------------------------------"

# Check if .env already exists
if [ -f ".env" ]; then
    echo -e "${YELLOW}!${NC} .env file already exists"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing .env file"
        echo ""
    else
        rm .env
    fi
fi

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    cat > .env << 'EOF'
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCOUNT_ID=
PROJECT_NAME=medzen-ehrbase

# Proxmox Configuration (for database export)
PROXMOX_HOST=10.10.10.201
PROXMOX_K8S_NAMESPACE=ehrbase

# Firebase Configuration
FIREBASE_PROJECT=medzen-bf20e

# Deployment Options
SKIP_DATABASE_MIGRATION=false  # Set to true if starting fresh
ENABLE_MULTI_AZ=true           # Multi-AZ for RDS (recommended)
MIN_ECS_TASKS=2                # Minimum ECS tasks
MAX_ECS_TASKS=4                # Maximum ECS tasks

# Generated during deployment (do not edit manually)
VPC_ID=
PUBLIC_SUBNET_1=
PUBLIC_SUBNET_2=
PRIVATE_SUBNET_1=
PRIVATE_SUBNET_2=
ALB_SG=
ECS_SG=
RDS_SG=
RDS_ENDPOINT=
ALB_DNS=
ALB_ARN=
TG_ARN=
DB_ADMIN_PASS=
DB_USER_PASS=
EHRBASE_USER_PASS=
EOF

    # Get AWS Account ID
    if command -v aws &> /dev/null && aws sts get-caller-identity &> /dev/null; then
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        sed -i '' "s/AWS_ACCOUNT_ID=/AWS_ACCOUNT_ID=$ACCOUNT_ID/" .env
    fi

    echo -e "${GREEN}✓${NC} Created .env file"
    echo "  Edit .env to customize deployment settings"
else
    echo -e "${GREEN}✓${NC} Using existing .env file"
fi
echo ""

echo "5. Checking Proxmox Connectivity (Optional)"
echo "-------------------------------------------"
source .env
if [ -n "$PROXMOX_HOST" ]; then
    if ping -c 1 -W 2 $PROXMOX_HOST &> /dev/null; then
        echo -e "${GREEN}✓${NC} Can reach Proxmox host: $PROXMOX_HOST"

        # Check kubectl access
        if kubectl cluster-info &> /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} kubectl configured and accessible"
        else
            echo -e "${YELLOW}!${NC} kubectl not configured or not accessible"
            echo "  Database migration will require manual export"
        fi
    else
        echo -e "${YELLOW}!${NC} Cannot reach Proxmox host: $PROXMOX_HOST"
        echo "  Database migration will require manual export"
    fi
else
    echo -e "${YELLOW}!${NC} PROXMOX_HOST not configured in .env"
fi
echo ""

echo "=========================================="
echo "Prerequisites Check Summary"
echo "=========================================="
echo ""

if [ "$ALL_GOOD" = true ]; then
    echo -e "${GREEN}✓ All prerequisites met!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Review and edit .env file with your settings"
    echo "2. Run: ./01-setup-infrastructure.sh"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some prerequisites are missing${NC}"
    echo ""
    echo "Please install missing dependencies and configure credentials:"
    echo ""
    echo "AWS CLI:"
    echo "  https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    echo "  Run: aws configure"
    echo ""
    echo "Firebase CLI:"
    echo "  npm install -g firebase-tools"
    echo "  Run: firebase login"
    echo ""
    echo "Supabase CLI:"
    echo "  npm install -g supabase"
    echo "  Run: npx supabase login"
    echo ""
    echo "PostgreSQL Client:"
    echo "  macOS: brew install postgresql"
    echo "  Linux: apt-get install postgresql-client"
    echo ""
    echo "jq (JSON processor):"
    echo "  macOS: brew install jq"
    echo "  Linux: apt-get install jq"
    echo ""
    exit 1
fi
