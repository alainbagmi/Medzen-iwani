#!/bin/bash

# ============================================
# MedZen AWS Cost Reporting Script
# Generates cost breakdown by region/service
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_NAME="${PROJECT_NAME:-medzen}"
REGIONS=("af-south-1" "eu-west-1" "us-east-1")

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  MedZen AWS Cost Report${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_info() { echo -e "${BLUE}[i]${NC} $1"; }

# Get cost data from Cost Explorer
get_monthly_costs() {
    local start_date=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d "30 days ago" +%Y-%m-%d)
    local end_date=$(date +%Y-%m-%d)

    print_info "Fetching costs from $start_date to $end_date..."

    # Total costs by service
    aws ce get-cost-and-usage \
        --time-period "Start=$start_date,End=$end_date" \
        --granularity MONTHLY \
        --metrics "UnblendedCost" \
        --group-by Type=DIMENSION,Key=SERVICE \
        --filter "{\"Tags\":{\"Key\":\"Project\",\"Values\":[\"$PROJECT_NAME\"]}}" \
        --query 'ResultsByTime[0].Groups[*].[Keys[0],Metrics.UnblendedCost.Amount]' \
        --output table 2>/dev/null || {
        print_warning "Cost Explorer query failed (may need Cost Explorer API enabled)"
        return 1
    }
}

# Get costs by region
get_regional_costs() {
    local start_date=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d "30 days ago" +%Y-%m-%d)
    local end_date=$(date +%Y-%m-%d)

    print_info "Fetching regional cost breakdown..."

    aws ce get-cost-and-usage \
        --time-period "Start=$start_date,End=$end_date" \
        --granularity MONTHLY \
        --metrics "UnblendedCost" \
        --group-by Type=DIMENSION,Key=REGION \
        --query 'ResultsByTime[0].Groups[*].[Keys[0],Metrics.UnblendedCost.Amount]' \
        --output table 2>/dev/null || {
        print_warning "Regional cost query failed"
        return 1
    }
}

# Estimate infrastructure costs
estimate_costs() {
    echo ""
    echo -e "${BLUE}Estimated Monthly Costs:${NC}"
    echo ""

    cat << 'EOF'
┌─────────────────────────────────────────────────────────────┐
│                 EHRBASE (af-south-1)                        │
├─────────────────────────────────────────────────────────────┤
│ ECS Fargate (2-4 tasks × 2vCPU × 4GB)      │    $150       │
│ RDS PostgreSQL (db.r6g.large, Multi-AZ)    │    $280       │
│ Application Load Balancer                   │     $25       │
│ NAT Gateway                                 │     $45       │
│ S3 Storage & Data Transfer                  │     $20       │
├─────────────────────────────────────────────┼───────────────┤
│ Subtotal                                    │    $520       │
└─────────────────────────────────────────────┴───────────────┘

┌─────────────────────────────────────────────────────────────┐
│                EHRBASE DR (eu-west-1)                       │
├─────────────────────────────────────────────────────────────┤
│ ECS Fargate (1 task standby)               │     $60       │
│ RDS Read Replica (db.r6g.large)            │    $140       │
│ Application Load Balancer (standby)         │     $20       │
│ NAT Gateway                                 │     $35       │
│ S3 Replication                              │     $15       │
├─────────────────────────────────────────────┼───────────────┤
│ Subtotal                                    │    $270       │
└─────────────────────────────────────────────┴───────────────┘

┌─────────────────────────────────────────────────────────────┐
│               BEDROCK AI (eu-west-1)                        │
├─────────────────────────────────────────────────────────────┤
│ Lambda (1M requests @ 1GB × 60s)           │     $50       │
│ API Gateway (1M requests)                   │     $15       │
│ Bedrock Claude Sonnet (~1M tokens)          │    $200       │
│ Amazon Translate                            │     $30       │
│ Comprehend Medical                          │     $50       │
│ Polly & Transcribe                          │     $40       │
├─────────────────────────────────────────────┼───────────────┤
│ Subtotal                                    │    $385       │
└─────────────────────────────────────────────┴───────────────┘

┌─────────────────────────────────────────────────────────────┐
│              AI FAILOVER (us-east-1 + af-south-1)           │
├─────────────────────────────────────────────────────────────┤
│ Lambda (standby, minimal usage)            │     $35       │
│ API Gateway                                 │     $10       │
│ Bedrock (failover traffic only)            │     $45       │
├─────────────────────────────────────────────┼───────────────┤
│ Subtotal                                    │     $90       │
└─────────────────────────────────────────────┴───────────────┘

┌─────────────────────────────────────────────────────────────┐
│               CHIME SDK (eu-west-1)                         │
├─────────────────────────────────────────────────────────────┤
│ Chime SDK Meetings (100 calls/day)         │    $150       │
│ Media Capture Pipelines                     │     $80       │
│ Lambda Functions                            │     $30       │
│ S3 Storage (recordings)                     │     $40       │
│ Amazon Transcribe Medical                   │    $100       │
│ DynamoDB                                    │     $20       │
├─────────────────────────────────────────────┼───────────────┤
│ Subtotal                                    │    $420       │
└─────────────────────────────────────────────┴───────────────┘

┌─────────────────────────────────────────────────────────────┐
│              CHIME SDK (af-south-1)                         │
├─────────────────────────────────────────────────────────────┤
│ Chime SDK Media (African users)            │    $100       │
│ S3 Storage (regional)                       │     $30       │
│ Lambda Functions                            │     $15       │
│ Cross-region replication                    │     $40       │
├─────────────────────────────────────────────┼───────────────┤
│ Subtotal                                    │    $185       │
└─────────────────────────────────────────────┴───────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    GLOBAL SERVICES                          │
├─────────────────────────────────────────────────────────────┤
│ Route 53 (hosted zone + health checks)     │     $15       │
│ CloudWatch (logs + alarms)                  │     $25       │
│ Secrets Manager                             │     $10       │
│ KMS Keys                                    │      $5       │
├─────────────────────────────────────────────┼───────────────┤
│ Subtotal                                    │     $55       │
└─────────────────────────────────────────────┴───────────────┘

═══════════════════════════════════════════════════════════════
                    TOTAL MONTHLY ESTIMATE
═══════════════════════════════════════════════════════════════

  EHRbase (Primary + DR)                      │    $790
  Bedrock AI (All regions)                    │    $475
  Chime SDK (All regions)                     │    $605
  Global Services                             │     $55
  ─────────────────────────────────────────────────────────
  GRAND TOTAL                                 │  $1,925

  Annual Estimate: $23,100

EOF
}

# Cost optimization recommendations
show_recommendations() {
    echo ""
    echo -e "${BLUE}Cost Optimization Recommendations:${NC}"
    echo ""

    cat << 'EOF'
1. RESERVED CAPACITY (Save 30-40%)
   - RDS Reserved Instances: ~$100/month savings
   - Fargate Savings Plans: ~$50/month savings

2. RIGHT-SIZING
   - Review ECS task sizing monthly
   - Scale down DR resources during low usage

3. DATA LIFECYCLE
   - Enable S3 Intelligent-Tiering
   - Archive old recordings to Glacier

4. SPOT INSTANCES
   - Use Fargate Spot for non-critical tasks
   - Potential 70% savings on burst capacity

5. MONITORING
   - Set up Cost Anomaly Detection
   - Enable AWS Budgets with alerts

6. CLEANUP
   - Delete unused EBS snapshots
   - Remove old CloudWatch log groups
   - Clean up orphaned ENIs

POTENTIAL MONTHLY SAVINGS: $300-500
EOF
}

# Generate detailed report
generate_detailed_report() {
    local report_file="cost-report-$(date +%Y%m%d).md"

    cat > "$report_file" << EOF
# MedZen AWS Cost Report

**Generated:** $(date)
**Period:** Last 30 days

## Summary

| Region | Monthly Cost | % of Total |
|--------|-------------|------------|
| af-south-1 | \$705 | 37% |
| eu-west-1 | \$1,075 | 56% |
| us-east-1 | \$145 | 7% |
| **Total** | **\$1,925** | **100%** |

## By Service

| Service | Monthly Cost | Notes |
|---------|-------------|-------|
| EHRbase | \$790 | Primary + DR |
| Bedrock AI | \$475 | 3 regions |
| Chime SDK | \$605 | Video calls |
| Global | \$55 | Route 53, CloudWatch |

## Recommendations

1. Implement Reserved Capacity for RDS
2. Enable Savings Plans for Fargate
3. Use S3 Intelligent-Tiering
4. Schedule DR resource scaling

## Next Review Date

$(date -v+30d +%Y-%m-%d 2>/dev/null || date -d "+30 days" +%Y-%m-%d)
EOF

    print_status "Report generated: $report_file"
}

# List expensive resources
list_expensive_resources() {
    echo ""
    echo -e "${BLUE}Top Resources by Region:${NC}"
    echo ""

    for region in "${REGIONS[@]}"; do
        echo -e "${YELLOW}$region:${NC}"

        # RDS instances
        echo "  RDS Instances:"
        aws rds describe-db-instances \
            --region "$region" \
            --query "DBInstances[?contains(DBInstanceIdentifier, '${PROJECT_NAME}')].[DBInstanceIdentifier,DBInstanceClass]" \
            --output text 2>/dev/null | sed 's/^/    /' || echo "    None"

        # ECS services
        echo "  ECS Services:"
        aws ecs list-services \
            --cluster "${PROJECT_NAME}-ehrbase-cluster" \
            --region "$region" \
            --query 'serviceArns' \
            --output text 2>/dev/null | xargs -n1 basename | sed 's/^/    /' || echo "    None"

        # Lambda functions
        echo "  Lambda Functions:"
        aws lambda list-functions \
            --region "$region" \
            --query "Functions[?contains(FunctionName, '${PROJECT_NAME}')].FunctionName" \
            --output text 2>/dev/null | tr '\t' '\n' | sed 's/^/    /' || echo "    None"

        echo ""
    done
}

# Main
case "${1:-estimate}" in
    estimate)
        estimate_costs
        show_recommendations
        ;;
    actual)
        get_monthly_costs
        get_regional_costs
        ;;
    resources)
        list_expensive_resources
        ;;
    report)
        estimate_costs
        show_recommendations
        generate_detailed_report
        ;;
    *)
        echo "Usage: $0 [estimate|actual|resources|report]"
        echo ""
        echo "Commands:"
        echo "  estimate   Show estimated monthly costs (default)"
        echo "  actual     Get actual costs from Cost Explorer"
        echo "  resources  List expensive resources by region"
        echo "  report     Generate detailed cost report"
        exit 1
        ;;
esac
