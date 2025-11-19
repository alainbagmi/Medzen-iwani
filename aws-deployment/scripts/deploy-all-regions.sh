#!/bin/bash

# ============================================
# MedZen Multi-Region Deployment Script
# Deploys to: af-south-1, eu-west-1, us-east-1
# ============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="${PROJECT_NAME:-medzen}"
ENVIRONMENT="${ENVIRONMENT:-production}"
PRIMARY_REGION="af-south-1"
SECONDARY_REGION="eu-west-1"
DR_REGION="us-east-1"

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/../.env" ]; then
    source "$SCRIPT_DIR/../.env"
fi

# Required environment variables
REQUIRED_VARS=("SUPABASE_URL" "SUPABASE_SERVICE_KEY" "DOMAIN_NAME")

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  MedZen Multi-Region Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi

    # Check required environment variables
    for var in "${REQUIRED_VARS[@]}"; do
        if [ -z "${!var}" ]; then
            print_error "Missing required environment variable: $var"
            exit 1
        fi
    done

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured"
        exit 1
    fi

    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_status "AWS Account: $AWS_ACCOUNT_ID"
    print_status "Prerequisites check passed"
}

# Deploy to a specific region
deploy_to_region() {
    local region=$1
    local stack_type=$2
    local stack_name="${PROJECT_NAME}-${stack_type}-${region}"
    local template_file="$SCRIPT_DIR/../cloudformation/${stack_type}.yaml"

    print_info "Deploying $stack_type to $region..."

    if [ ! -f "$template_file" ]; then
        print_error "Template file not found: $template_file"
        return 1
    fi

    # Build parameters based on stack type
    local parameters="ParameterKey=ProjectName,ParameterValue=$PROJECT_NAME"
    parameters="$parameters ParameterKey=Environment,ParameterValue=$ENVIRONMENT"

    case $stack_type in
        "global-infrastructure")
            parameters="$parameters ParameterKey=DomainName,ParameterValue=${DOMAIN_NAME:-medzenhealth.app}"
            parameters="$parameters ParameterKey=PrimaryRegion,ParameterValue=$PRIMARY_REGION"
            parameters="$parameters ParameterKey=SecondaryRegion,ParameterValue=$SECONDARY_REGION"
            parameters="$parameters ParameterKey=DRRegion,ParameterValue=$DR_REGION"
            ;;
        "ehrbase-multi-region")
            parameters="$parameters ParameterKey=DomainName,ParameterValue=${DOMAIN_NAME:-medzenhealth.app}"
            parameters="$parameters ParameterKey=EnableMultiAZ,ParameterValue=true"
            ;;
        "bedrock-ai-multi-region")
            parameters="$parameters ParameterKey=SupabaseUrl,ParameterValue=$SUPABASE_URL"
            parameters="$parameters ParameterKey=SupabaseServiceKey,ParameterValue=$SUPABASE_SERVICE_KEY"
            ;;
        "chime-sdk-multi-region")
            parameters="$parameters ParameterKey=SupabaseUrl,ParameterValue=$SUPABASE_URL"
            parameters="$parameters ParameterKey=SupabaseServiceKey,ParameterValue=$SUPABASE_SERVICE_KEY"
            ;;
    esac

    # Check if stack exists
    if aws cloudformation describe-stacks --stack-name "$stack_name" --region "$region" &> /dev/null; then
        print_info "Updating existing stack: $stack_name"
        aws cloudformation update-stack \
            --stack-name "$stack_name" \
            --template-body "file://$template_file" \
            --parameters $parameters \
            --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
            --region "$region" || {
            print_warning "No updates to perform or update failed"
            return 0
        }
    else
        print_info "Creating new stack: $stack_name"
        aws cloudformation create-stack \
            --stack-name "$stack_name" \
            --template-body "file://$template_file" \
            --parameters $parameters \
            --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
            --region "$region"
    fi

    # Wait for stack to complete
    print_info "Waiting for stack to complete..."
    aws cloudformation wait stack-create-complete --stack-name "$stack_name" --region "$region" 2>/dev/null || \
    aws cloudformation wait stack-update-complete --stack-name "$stack_name" --region "$region" 2>/dev/null || {
        print_error "Stack deployment failed"
        return 1
    }

    print_status "Successfully deployed $stack_name"
}

# Get stack outputs
get_stack_outputs() {
    local stack_name=$1
    local region=$2

    aws cloudformation describe-stacks \
        --stack-name "$stack_name" \
        --region "$region" \
        --query 'Stacks[0].Outputs' \
        --output table
}

# Main deployment function
deploy_all() {
    local start_time=$(date +%s)

    echo ""
    echo -e "${BLUE}Phase 1: Deploy Global Infrastructure${NC}"
    echo "----------------------------------------"
    deploy_to_region "$PRIMARY_REGION" "global-infrastructure"

    echo ""
    echo -e "${BLUE}Phase 2: Deploy EHRbase (Primary: $PRIMARY_REGION)${NC}"
    echo "----------------------------------------"
    deploy_to_region "$PRIMARY_REGION" "ehrbase-multi-region"

    echo ""
    echo -e "${BLUE}Phase 3: Deploy EHRbase DR (Secondary: $SECONDARY_REGION)${NC}"
    echo "----------------------------------------"
    deploy_to_region "$SECONDARY_REGION" "ehrbase-multi-region"

    echo ""
    echo -e "${BLUE}Phase 4: Deploy Bedrock AI (Primary: $SECONDARY_REGION)${NC}"
    echo "----------------------------------------"
    deploy_to_region "$SECONDARY_REGION" "bedrock-ai-multi-region"

    echo ""
    echo -e "${BLUE}Phase 5: Deploy Bedrock AI (Failover: $DR_REGION)${NC}"
    echo "----------------------------------------"
    deploy_to_region "$DR_REGION" "bedrock-ai-multi-region"

    echo ""
    echo -e "${BLUE}Phase 6: Deploy Bedrock AI (Edge: $PRIMARY_REGION)${NC}"
    echo "----------------------------------------"
    deploy_to_region "$PRIMARY_REGION" "bedrock-ai-multi-region"

    echo ""
    echo -e "${BLUE}Phase 7: Deploy Chime SDK (Primary: $SECONDARY_REGION)${NC}"
    echo "----------------------------------------"
    deploy_to_region "$SECONDARY_REGION" "chime-sdk-multi-region"

    echo ""
    echo -e "${BLUE}Phase 8: Deploy Chime SDK (Secondary: $PRIMARY_REGION)${NC}"
    echo "----------------------------------------"
    deploy_to_region "$PRIMARY_REGION" "chime-sdk-multi-region"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Deployment Complete!${NC}"
    echo -e "${GREEN}  Duration: $((duration / 60))m $((duration % 60))s${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# Show outputs
show_outputs() {
    echo ""
    echo -e "${BLUE}Stack Outputs:${NC}"
    echo ""

    echo "Global Infrastructure ($PRIMARY_REGION):"
    get_stack_outputs "${PROJECT_NAME}-global-infrastructure-${PRIMARY_REGION}" "$PRIMARY_REGION"

    echo ""
    echo "EHRbase Primary ($PRIMARY_REGION):"
    get_stack_outputs "${PROJECT_NAME}-ehrbase-multi-region-${PRIMARY_REGION}" "$PRIMARY_REGION"

    echo ""
    echo "AI Primary ($SECONDARY_REGION):"
    get_stack_outputs "${PROJECT_NAME}-bedrock-ai-multi-region-${SECONDARY_REGION}" "$SECONDARY_REGION"

    echo ""
    echo "Chime SDK Primary ($SECONDARY_REGION):"
    get_stack_outputs "${PROJECT_NAME}-chime-sdk-multi-region-${SECONDARY_REGION}" "$SECONDARY_REGION"
}

# Show usage
usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  deploy    Deploy all stacks to all regions"
    echo "  outputs   Show stack outputs"
    echo "  help      Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  PROJECT_NAME          Project name (default: medzen)"
    echo "  ENVIRONMENT           Environment (default: production)"
    echo "  SUPABASE_URL          Supabase project URL"
    echo "  SUPABASE_SERVICE_KEY  Supabase service role key"
    echo "  DOMAIN_NAME           Domain name (default: medzenhealth.app)"
}

# Main
case "${1:-deploy}" in
    deploy)
        check_prerequisites
        deploy_all
        show_outputs
        ;;
    outputs)
        show_outputs
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        print_error "Unknown command: $1"
        usage
        exit 1
        ;;
esac
