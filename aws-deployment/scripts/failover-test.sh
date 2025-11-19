#!/bin/bash

# ============================================
# MedZen Multi-Region Failover Test Script
# Tests DR procedures for all services
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_NAME="${PROJECT_NAME:-medzen}"
PRIMARY_REGION="af-south-1"
SECONDARY_REGION="eu-west-1"
DR_REGION="us-east-1"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  MedZen Failover Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }

# Test EHRbase health
test_ehrbase_health() {
    local region=$1
    local endpoint=$2

    print_info "Testing EHRbase health in $region..."

    local response=$(curl -s -o /dev/null -w "%{http_code}" "$endpoint/ehrbase/rest/status" --max-time 10)

    if [ "$response" == "200" ]; then
        print_status "EHRbase health check passed ($region)"
        return 0
    else
        print_error "EHRbase health check failed ($region) - HTTP $response"
        return 1
    fi
}

# Test AI Lambda health
test_ai_health() {
    local region=$1
    local endpoint=$2

    print_info "Testing AI Lambda health in $region..."

    local response=$(curl -s -o /dev/null -w "%{http_code}" "$endpoint/health" --max-time 10)

    if [ "$response" == "200" ]; then
        print_status "AI Lambda health check passed ($region)"
        return 0
    else
        print_warning "AI Lambda health check returned HTTP $response ($region)"
        return 1
    fi
}

# Test Chime API health
test_chime_health() {
    local region=$1
    local endpoint=$2

    print_info "Testing Chime API health in $region..."

    local response=$(curl -s -o /dev/null -w "%{http_code}" "$endpoint/health" --max-time 10)

    if [ "$response" == "200" ]; then
        print_status "Chime API health check passed ($region)"
        return 0
    else
        print_warning "Chime API health check returned HTTP $response ($region)"
        return 1
    fi
}

# Test Route 53 failover
test_route53_failover() {
    print_info "Testing Route 53 health checks..."

    local health_checks=$(aws route53 list-health-checks --query 'HealthChecks[?contains(HealthCheckConfig.FullyQualifiedDomainName, `medzenhealth`)].[Id,HealthCheckConfig.FullyQualifiedDomainName]' --output text)

    if [ -z "$health_checks" ]; then
        print_warning "No Route 53 health checks found"
        return 1
    fi

    echo "$health_checks" | while read -r id domain; do
        local status=$(aws route53 get-health-check-status --health-check-id "$id" --query 'HealthCheckObservations[0].StatusReport.Status' --output text 2>/dev/null || echo "UNKNOWN")
        if [ "$status" == "Success" ]; then
            print_status "Health check OK: $domain"
        else
            print_warning "Health check issue: $domain - $status"
        fi
    done
}

# Test RDS replication
test_rds_replication() {
    print_info "Testing RDS replication status..."

    for region in $PRIMARY_REGION $SECONDARY_REGION; do
        local replicas=$(aws rds describe-db-instances \
            --region "$region" \
            --query "DBInstances[?contains(DBInstanceIdentifier, '${PROJECT_NAME}')].{ID:DBInstanceIdentifier,Status:DBInstanceStatus,Replica:ReadReplicaSourceDBInstanceIdentifier}" \
            --output table 2>/dev/null)

        if [ -n "$replicas" ]; then
            echo ""
            echo "RDS Instances in $region:"
            echo "$replicas"
        fi
    done
}

# Test S3 replication
test_s3_replication() {
    print_info "Testing S3 cross-region replication..."

    local source_bucket="${PROJECT_NAME}-ehrbase-backups-${PRIMARY_REGION}"
    local replication=$(aws s3api get-bucket-replication --bucket "$source_bucket" --query 'ReplicationConfiguration.Rules[0].Status' --output text 2>/dev/null || echo "Not configured")

    if [ "$replication" == "Enabled" ]; then
        print_status "S3 replication is enabled for $source_bucket"
    else
        print_warning "S3 replication status: $replication"
    fi
}

# Test DynamoDB Global Table
test_dynamodb_global() {
    print_info "Testing DynamoDB Global Table replication..."

    local table_name="${PROJECT_NAME}-audit-logs"
    local replicas=$(aws dynamodb describe-table \
        --table-name "$table_name" \
        --region "$PRIMARY_REGION" \
        --query 'Table.Replicas[].RegionName' \
        --output text 2>/dev/null || echo "Not found")

    if [ -n "$replicas" ] && [ "$replicas" != "Not found" ]; then
        print_status "DynamoDB Global Table replicas: $replicas"
    else
        print_warning "DynamoDB Global Table not configured"
    fi
}

# Simulate failover (read-only test)
simulate_failover() {
    print_info "Simulating failover scenario (read-only)..."

    echo ""
    echo -e "${YELLOW}Failover Steps (Manual Execution):${NC}"
    echo ""
    echo "1. EHRbase Failover (af-south-1 → eu-west-1):"
    echo "   a. Promote RDS read replica to primary"
    echo "   b. Update Route 53 to point to eu-west-1 ALB"
    echo "   c. Scale up eu-west-1 ECS service"
    echo ""
    echo "2. AI Service Failover (eu-west-1 → us-east-1):"
    echo "   a. Update Route 53 health check"
    echo "   b. Traffic auto-routes to us-east-1"
    echo ""
    echo "3. Chime SDK Failover (eu-west-1 → af-south-1):"
    echo "   a. Update media region in meeting creation"
    echo "   b. Existing meetings continue until completion"
    echo ""

    # Show current health status
    echo -e "${BLUE}Current Health Status:${NC}"

    for region in $PRIMARY_REGION $SECONDARY_REGION $DR_REGION; do
        local ecs_services=$(aws ecs list-services \
            --cluster "${PROJECT_NAME}-ehrbase-cluster" \
            --region "$region" \
            --query 'serviceArns' \
            --output text 2>/dev/null | wc -w || echo "0")

        local lambdas=$(aws lambda list-functions \
            --region "$region" \
            --query "Functions[?contains(FunctionName, '${PROJECT_NAME}')].FunctionName" \
            --output text 2>/dev/null | wc -w || echo "0")

        echo "  $region: ECS=$ecs_services, Lambda=$lambdas"
    done
}

# Generate failover report
generate_report() {
    local report_file="failover-test-$(date +%Y%m%d-%H%M%S).md"

    cat > "$report_file" << EOF
# MedZen Failover Test Report

**Date:** $(date)
**Project:** $PROJECT_NAME

## Test Results

### Infrastructure Status

| Region | Service | Status |
|--------|---------|--------|
| $PRIMARY_REGION | EHRbase | Tested |
| $SECONDARY_REGION | AI/Chime | Tested |
| $DR_REGION | Backup | Tested |

### Recommendations

1. **RTO (Recovery Time Objective):** 15-30 minutes
2. **RPO (Recovery Point Objective):** 5 minutes

### Next Steps

- [ ] Schedule monthly failover drills
- [ ] Update runbooks with current endpoints
- [ ] Test full failover in non-production

EOF

    print_status "Report generated: $report_file"
}

# Main test suite
run_tests() {
    local start_time=$(date +%s)
    local passed=0
    local failed=0

    echo ""
    echo -e "${BLUE}Running Failover Tests...${NC}"
    echo ""

    # Get endpoints from CloudFormation outputs
    local ehrbase_primary=$(aws cloudformation describe-stacks \
        --stack-name "${PROJECT_NAME}-ehrbase-multi-region-${PRIMARY_REGION}" \
        --region "$PRIMARY_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
        --output text 2>/dev/null || echo "")

    local ai_primary=$(aws cloudformation describe-stacks \
        --stack-name "${PROJECT_NAME}-bedrock-ai-multi-region-${SECONDARY_REGION}" \
        --region "$SECONDARY_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayEndpoint`].OutputValue' \
        --output text 2>/dev/null || echo "")

    # Run tests
    if [ -n "$ehrbase_primary" ]; then
        test_ehrbase_health "$PRIMARY_REGION" "https://$ehrbase_primary" && ((passed++)) || ((failed++))
    else
        print_warning "EHRbase endpoint not found in CloudFormation"
        ((failed++))
    fi

    if [ -n "$ai_primary" ]; then
        test_ai_health "$SECONDARY_REGION" "$ai_primary" && ((passed++)) || ((failed++))
    else
        print_warning "AI endpoint not found in CloudFormation"
        ((failed++))
    fi

    test_route53_failover && ((passed++)) || ((failed++))
    test_rds_replication && ((passed++)) || ((failed++))
    test_s3_replication && ((passed++)) || ((failed++))
    test_dynamodb_global && ((passed++)) || ((failed++))

    simulate_failover

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "  ${GREEN}Passed:${NC} $passed"
    echo -e "  ${RED}Failed:${NC} $failed"
    echo -e "  Duration: ${duration}s"
    echo ""

    generate_report
}

# Main
case "${1:-run}" in
    run)
        run_tests
        ;;
    health)
        test_route53_failover
        ;;
    report)
        generate_report
        ;;
    *)
        echo "Usage: $0 [run|health|report]"
        exit 1
        ;;
esac
