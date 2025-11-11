#!/bin/bash

################################################################################
# EHRbase AWS Migration - Infrastructure Setup
# Creates VPC, subnets, security groups, Internet Gateway, NAT Gateway
################################################################################

set -e  # Exit on error

echo "=========================================="
echo "EHRbase AWS Migration - Infrastructure Setup"
echo "=========================================="
echo ""

# Load environment variables
if [ ! -f ".env" ]; then
    echo "Error: .env file not found"
    echo "Run ./00-prerequisites.sh first"
    exit 1
fi

source .env

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Configuration:${NC}"
echo "  AWS Region: $AWS_REGION"
echo "  Project Name: $PROJECT_NAME"
echo "  AWS Account: $AWS_ACCOUNT_ID"
echo ""

read -p "Continue with infrastructure setup? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted"
    exit 1
fi

################################################################################
# 1. CREATE VPC
################################################################################

echo ""
echo "=========================================="
echo "Step 1: Creating VPC"
echo "=========================================="

VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/20 \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${PROJECT_NAME}-vpc},{Key=Project,Value=MedZen},{Key=ManagedBy,Value=ehrbase-migration}]" \
    --query 'Vpc.VpcId' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}✓${NC} VPC created: $VPC_ID"

# Enable DNS support and hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support --region $AWS_REGION
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames --region $AWS_REGION
echo -e "${GREEN}✓${NC} DNS support enabled"

# Update .env
sed -i '' "s|^VPC_ID=.*|VPC_ID=$VPC_ID|" .env

################################################################################
# 2. CREATE SUBNETS
################################################################################

echo ""
echo "=========================================="
echo "Step 2: Creating Subnets"
echo "=========================================="

# Public Subnet AZ-1a
PUBLIC_SUBNET_1=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.0.0/22 \
    --availability-zone ${AWS_REGION}a \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_NAME}-public-1a},{Key=Type,Value=public}]" \
    --query 'Subnet.SubnetId' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}✓${NC} Public subnet 1a created: $PUBLIC_SUBNET_1"

# Public Subnet AZ-1b
PUBLIC_SUBNET_2=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.4.0/22 \
    --availability-zone ${AWS_REGION}b \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_NAME}-public-1b},{Key=Type,Value=public}]" \
    --query 'Subnet.SubnetId' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}✓${NC} Public subnet 1b created: $PUBLIC_SUBNET_2"

# Private Subnet AZ-1a
PRIVATE_SUBNET_1=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.8.0/22 \
    --availability-zone ${AWS_REGION}a \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_NAME}-private-1a},{Key=Type,Value=private}]" \
    --query 'Subnet.SubnetId' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}✓${NC} Private subnet 1a created: $PRIVATE_SUBNET_1"

# Private Subnet AZ-1b
PRIVATE_SUBNET_2=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.12.0/22 \
    --availability-zone ${AWS_REGION}b \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_NAME}-private-1b},{Key=Type,Value=private}]" \
    --query 'Subnet.SubnetId' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}✓${NC} Private subnet 1b created: $PRIVATE_SUBNET_2"

# Update .env
sed -i '' "s|^PUBLIC_SUBNET_1=.*|PUBLIC_SUBNET_1=$PUBLIC_SUBNET_1|" .env
sed -i '' "s|^PUBLIC_SUBNET_2=.*|PUBLIC_SUBNET_2=$PUBLIC_SUBNET_2|" .env
sed -i '' "s|^PRIVATE_SUBNET_1=.*|PRIVATE_SUBNET_1=$PRIVATE_SUBNET_1|" .env
sed -i '' "s|^PRIVATE_SUBNET_2=.*|PRIVATE_SUBNET_2=$PRIVATE_SUBNET_2|" .env

################################################################################
# 3. CREATE INTERNET GATEWAY
################################################################################

echo ""
echo "=========================================="
echo "Step 3: Creating Internet Gateway"
echo "=========================================="

IGW_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${PROJECT_NAME}-igw}]" \
    --query 'InternetGateway.InternetGatewayId' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}✓${NC} Internet Gateway created: $IGW_ID"

# Attach to VPC
aws ec2 attach-internet-gateway \
    --vpc-id $VPC_ID \
    --internet-gateway-id $IGW_ID \
    --region $AWS_REGION

echo -e "${GREEN}✓${NC} Internet Gateway attached to VPC"

################################################################################
# 4. CREATE NAT GATEWAY
################################################################################

echo ""
echo "=========================================="
echo "Step 4: Creating NAT Gateway"
echo "=========================================="

# Allocate Elastic IP
EIP_ALLOC=$(aws ec2 allocate-address \
    --domain vpc \
    --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=${PROJECT_NAME}-nat-eip}]" \
    --query 'AllocationId' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}✓${NC} Elastic IP allocated: $EIP_ALLOC"

# Create NAT Gateway
NAT_GW_ID=$(aws ec2 create-nat-gateway \
    --subnet-id $PUBLIC_SUBNET_1 \
    --allocation-id $EIP_ALLOC \
    --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=${PROJECT_NAME}-nat}]" \
    --query 'NatGateway.NatGatewayId' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}✓${NC} NAT Gateway created: $NAT_GW_ID"
echo -e "${YELLOW}⏳${NC} Waiting for NAT Gateway to become available (2-3 minutes)..."

# Wait for NAT Gateway
aws ec2 wait nat-gateway-available \
    --nat-gateway-ids $NAT_GW_ID \
    --region $AWS_REGION

echo -e "${GREEN}✓${NC} NAT Gateway is now available"

################################################################################
# 5. CREATE ROUTE TABLES
################################################################################

echo ""
echo "=========================================="
echo "Step 5: Creating Route Tables"
echo "=========================================="

# Create public route table
PUBLIC_RT=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT_NAME}-public-rt}]" \
    --query 'RouteTable.RouteTableId' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}✓${NC} Public route table created: $PUBLIC_RT"

# Add route to Internet Gateway
aws ec2 create-route \
    --route-table-id $PUBLIC_RT \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} Route to Internet Gateway added"

# Associate public subnets
aws ec2 associate-route-table \
    --subnet-id $PUBLIC_SUBNET_1 \
    --route-table-id $PUBLIC_RT \
    --region $AWS_REGION > /dev/null

aws ec2 associate-route-table \
    --subnet-id $PUBLIC_SUBNET_2 \
    --route-table-id $PUBLIC_RT \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} Public subnets associated with route table"

# Create private route table
PRIVATE_RT=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT_NAME}-private-rt}]" \
    --query 'RouteTable.RouteTableId' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}✓${NC} Private route table created: $PRIVATE_RT"

# Add route to NAT Gateway
aws ec2 create-route \
    --route-table-id $PRIVATE_RT \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id $NAT_GW_ID \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} Route to NAT Gateway added"

# Associate private subnets
aws ec2 associate-route-table \
    --subnet-id $PRIVATE_SUBNET_1 \
    --route-table-id $PRIVATE_RT \
    --region $AWS_REGION > /dev/null

aws ec2 associate-route-table \
    --subnet-id $PRIVATE_SUBNET_2 \
    --route-table-id $PRIVATE_RT \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} Private subnets associated with route table"

################################################################################
# 6. CREATE SECURITY GROUPS
################################################################################

echo ""
echo "=========================================="
echo "Step 6: Creating Security Groups"
echo "=========================================="

# ALB Security Group
ALB_SG=$(aws ec2 create-security-group \
    --group-name ${PROJECT_NAME}-alb-sg \
    --description "Security group for EHRbase ALB" \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${PROJECT_NAME}-alb-sg}]" \
    --query 'GroupId' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}✓${NC} ALB security group created: $ALB_SG"

# Allow HTTP from anywhere
aws ec2 authorize-security-group-ingress \
    --group-id $ALB_SG \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region $AWS_REGION > /dev/null

# Allow HTTPS from anywhere
aws ec2 authorize-security-group-ingress \
    --group-id $ALB_SG \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} ALB ingress rules configured (ports 80, 443)"

# ECS Security Group
ECS_SG=$(aws ec2 create-security-group \
    --group-name ${PROJECT_NAME}-ecs-sg \
    --description "Security group for EHRbase ECS tasks" \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${PROJECT_NAME}-ecs-sg}]" \
    --query 'GroupId' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}✓${NC} ECS security group created: $ECS_SG"

# Allow traffic from ALB
aws ec2 authorize-security-group-ingress \
    --group-id $ECS_SG \
    --protocol tcp \
    --port 8080 \
    --source-group $ALB_SG \
    --region $AWS_REGION > /dev/null

# Allow HTTPS for Docker image pulls
aws ec2 authorize-security-group-ingress \
    --group-id $ECS_SG \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0 \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} ECS ingress rules configured"

# RDS Security Group
RDS_SG=$(aws ec2 create-security-group \
    --group-name ${PROJECT_NAME}-rds-sg \
    --description "Security group for EHRbase RDS database" \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${PROJECT_NAME}-rds-sg}]" \
    --query 'GroupId' \
    --output text \
    --region $AWS_REGION)

echo -e "${GREEN}✓${NC} RDS security group created: $RDS_SG"

# Allow PostgreSQL from ECS
aws ec2 authorize-security-group-ingress \
    --group-id $RDS_SG \
    --protocol tcp \
    --port 5432 \
    --source-group $ECS_SG \
    --region $AWS_REGION > /dev/null

echo -e "${GREEN}✓${NC} RDS ingress rules configured (port 5432 from ECS)"

# Update .env
sed -i '' "s|^ALB_SG=.*|ALB_SG=$ALB_SG|" .env
sed -i '' "s|^ECS_SG=.*|ECS_SG=$ECS_SG|" .env
sed -i '' "s|^RDS_SG=.*|RDS_SG=$RDS_SG|" .env

################################################################################
# SUMMARY
################################################################################

echo ""
echo "=========================================="
echo "Infrastructure Setup Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}Resources Created:${NC}"
echo "  VPC:               $VPC_ID"
echo "  Public Subnets:    $PUBLIC_SUBNET_1, $PUBLIC_SUBNET_2"
echo "  Private Subnets:   $PRIVATE_SUBNET_1, $PRIVATE_SUBNET_2"
echo "  Internet Gateway:  $IGW_ID"
echo "  NAT Gateway:       $NAT_GW_ID"
echo "  Public Route Table: $PUBLIC_RT"
echo "  Private Route Table: $PRIVATE_RT"
echo "  ALB Security Group: $ALB_SG"
echo "  ECS Security Group: $ECS_SG"
echo "  RDS Security Group: $RDS_SG"
echo ""
echo -e "${BLUE}Configuration saved to .env${NC}"
echo ""
echo -e "${GREEN}Next step:${NC}"
echo "  ./02-setup-database.sh"
echo ""
