#!/bin/bash

################################################################################
# EHRbase AWS Production - Deployment Validation
# Comprehensive testing of EHRbase, Firebase, and Supabase integration
################################################################################

set -e  # Exit on error

echo "=========================================="
echo "EHRbase Production - Deployment Validation"
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

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test result function
test_result() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if [ "$1" = "pass" ]; then
        echo -e "${GREEN}✓${NC} $2"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $2"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        if [ -n "$3" ]; then
            echo -e "   ${YELLOW}Details:${NC} $3"
        fi
    fi
}

EHRBASE_URL="http://${ALB_DNS}/ehrbase/rest"
EHRBASE_USER="ehrbase-user"

echo -e "${BLUE}Testing Configuration:${NC}"
echo "  EHRbase URL: $EHRBASE_URL"
echo "  Username: $EHRBASE_USER"
echo ""

################################################################################
# 1. AWS INFRASTRUCTURE TESTS
################################################################################

echo "=========================================="
echo "Test Suite 1: AWS Infrastructure"
echo "=========================================="
echo ""

# Test VPC
VPC_STATE=$(aws ec2 describe-vpcs \
    --vpc-ids $VPC_ID \
    --query 'Vpcs[0].State' \
    --output text \
    --region $AWS_REGION 2>/dev/null || echo "error")

if [ "$VPC_STATE" = "available" ]; then
    test_result "pass" "VPC is available"
else
    test_result "fail" "VPC not available" "State: $VPC_STATE"
fi

# Test RDS
RDS_STATUS=$(aws rds describe-db-instances \
    --db-instance-identifier ${PROJECT_NAME}-db \
    --query 'DBInstances[0].DBInstanceStatus' \
    --output text \
    --region $AWS_REGION 2>/dev/null || echo "error")

if [ "$RDS_STATUS" = "available" ]; then
    test_result "pass" "RDS instance is available"
else
    test_result "fail" "RDS instance not available" "Status: $RDS_STATUS"
fi

# Test ECS Cluster
ECS_STATUS=$(aws ecs describe-clusters \
    --clusters ${PROJECT_NAME}-cluster \
    --query 'clusters[0].status' \
    --output text \
    --region $AWS_REGION 2>/dev/null || echo "error")

if [ "$ECS_STATUS" = "ACTIVE" ]; then
    test_result "pass" "ECS cluster is active"
else
    test_result "fail" "ECS cluster not active" "Status: $ECS_STATUS"
fi

# Test ECS Service
SERVICE_RUNNING=$(aws ecs describe-services \
    --cluster ${PROJECT_NAME}-cluster \
    --services ${PROJECT_NAME}-service \
    --query 'services[0].runningCount' \
    --output text \
    --region $AWS_REGION 2>/dev/null || echo "0")

if [ "$SERVICE_RUNNING" -ge 2 ]; then
    test_result "pass" "ECS service has $SERVICE_RUNNING running tasks"
else
    test_result "fail" "ECS service has insufficient tasks" "Running: $SERVICE_RUNNING (expected: 2+)"
fi

# Test ALB
ALB_STATE=$(aws elbv2 describe-load-balancers \
    --names ${PROJECT_NAME}-alb \
    --query 'LoadBalancers[0].State.Code' \
    --output text \
    --region $AWS_REGION 2>/dev/null || echo "error")

if [ "$ALB_STATE" = "active" ]; then
    test_result "pass" "Application Load Balancer is active"
else
    test_result "fail" "ALB not active" "State: $ALB_STATE"
fi

################################################################################
# 2. DATABASE TESTS
################################################################################

echo ""
echo "=========================================="
echo "Test Suite 2: Database"
echo "=========================================="
echo ""

# Test database connection
if PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -c "SELECT 1;" > /dev/null 2>&1; then
    test_result "pass" "Database connection successful"
else
    test_result "fail" "Database connection failed"
fi

# Test schemas
SCHEMAS=$(PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -t -c "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name IN ('ehr', 'ext');" 2>/dev/null | tr -d ' ')

if [ "$SCHEMAS" = "2" ]; then
    test_result "pass" "Required schemas exist (ehr, ext)"
else
    test_result "fail" "Missing schemas" "Found: $SCHEMAS (expected: 2)"
fi

# Test extensions
EXTENSION_COUNT=$(PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -t -c "SELECT COUNT(*) FROM pg_extension WHERE extname = 'uuid-ossp';" 2>/dev/null | tr -d ' ')

if [ "$EXTENSION_COUNT" = "1" ]; then
    test_result "pass" "Required extension installed (uuid-ossp)"
else
    test_result "fail" "Extension missing" "uuid-ossp"
fi

# Test users
USER_COUNT=$(PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -t -c "SELECT COUNT(*) FROM pg_roles WHERE rolname IN ('ehrbase_admin', 'ehrbase_restricted');" 2>/dev/null | tr -d ' ')

if [ "$USER_COUNT" = "2" ]; then
    test_result "pass" "Required users exist"
else
    test_result "fail" "Missing users" "Found: $USER_COUNT (expected: 2)"
fi

################################################################################
# 3. EHRBASE API TESTS
################################################################################

echo ""
echo "=========================================="
echo "Test Suite 3: EHRbase API"
echo "=========================================="
echo ""

# Test status endpoint
STATUS_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -u "${EHRBASE_USER}:${EHRBASE_USER_PASS}" \
    "${EHRBASE_URL}/status" 2>/dev/null)

STATUS_CODE=$(echo "$STATUS_RESPONSE" | tail -n 1)

if [ "$STATUS_CODE" = "200" ]; then
    test_result "pass" "Status endpoint accessible"
else
    test_result "fail" "Status endpoint not accessible" "HTTP $STATUS_CODE"
fi

# Test OpenEHR API endpoint
OPENEHR_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -u "${EHRBASE_USER}:${EHRBASE_USER_PASS}" \
    "${EHRBASE_URL}/openehr/v1/definition/template/adl1.4" 2>/dev/null)

OPENEHR_CODE=$(echo "$OPENEHR_RESPONSE" | tail -n 1)

if [ "$OPENEHR_CODE" = "200" ]; then
    test_result "pass" "OpenEHR API endpoint accessible"

    # Check template count
    TEMPLATE_BODY=$(echo "$OPENEHR_RESPONSE" | sed '$d')
    TEMPLATE_COUNT=$(echo "$TEMPLATE_BODY" | jq 'length' 2>/dev/null || echo "0")

    if [ "$TEMPLATE_COUNT" -gt 0 ]; then
        test_result "pass" "Templates available ($TEMPLATE_COUNT templates)"
    else
        test_result "fail" "No templates found" "Import templates with: ./04b-import-templates.sh"
    fi
else
    test_result "fail" "OpenEHR API not accessible" "HTTP $OPENEHR_CODE"
fi

# Test authentication
AUTH_TEST=$(curl -s -w "%{http_code}" -o /dev/null \
    "${EHRBASE_URL}/status" 2>/dev/null || echo "000")

if [ "$AUTH_TEST" = "401" ]; then
    test_result "pass" "Authentication is enforced"
else
    test_result "fail" "Authentication not working correctly" "HTTP $AUTH_TEST (expected 401 without auth)"
fi

# Test EHR creation
echo ""
echo "Testing EHR creation..."

EHR_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -u "${EHRBASE_USER}:${EHRBASE_USER_PASS}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d '{"_type":"EHR_STATUS","subject":{"external_ref":{"id":{"_type":"GENERIC_ID","value":"test-'$(date +%s)'","scheme":"id_scheme"},"namespace":"examples","type":"PERSON"}},"is_queryable":true,"is_modifiable":true}' \
    "${EHRBASE_URL}/openehr/v1/ehr" 2>/dev/null)

EHR_CODE=$(echo "$EHR_RESPONSE" | tail -n 1)
EHR_BODY=$(echo "$EHR_RESPONSE" | sed '$d')

if [ "$EHR_CODE" = "201" ] || [ "$EHR_CODE" = "200" ]; then
    test_result "pass" "EHR creation successful"

    # Extract EHR ID
    TEST_EHR_ID=$(echo "$EHR_BODY" | jq -r '.ehr_id.value' 2>/dev/null || echo "")

    if [ -n "$TEST_EHR_ID" ] && [ "$TEST_EHR_ID" != "null" ]; then
        test_result "pass" "EHR ID generated: $TEST_EHR_ID"
    else
        test_result "fail" "EHR ID not found in response"
    fi
else
    test_result "fail" "EHR creation failed" "HTTP $EHR_CODE"
fi

################################################################################
# 4. INTEGRATION TESTS (Optional)
################################################################################

echo ""
echo "=========================================="
echo "Test Suite 4: Integration (Optional)"
echo "=========================================="
echo ""

# Test Firebase Functions config
if firebase --version > /dev/null 2>&1; then
    echo "Testing Firebase configuration..."

    FB_CONFIG=$(firebase functions:config:get 2>/dev/null || echo "{}")

    if echo "$FB_CONFIG" | grep -q "ehrbase"; then
        FB_URL=$(echo "$FB_CONFIG" | jq -r '.ehrbase.url' 2>/dev/null || echo "")

        if [ "$FB_URL" = "$EHRBASE_URL" ]; then
            test_result "pass" "Firebase configured with production URL"
        else
            test_result "fail" "Firebase has incorrect URL" "Found: $FB_URL, Expected: $EHRBASE_URL"
        fi
    else
        test_result "fail" "Firebase EHRbase config not found"
    fi
else
    echo -e "${YELLOW}⚠${NC}  Firebase CLI not available - skipping Firebase tests"
fi

# Test Supabase Edge Functions secrets
if npx supabase --version > /dev/null 2>&1; then
    echo "Testing Supabase configuration..."

    SB_SECRETS=$(npx supabase secrets list 2>/dev/null || echo "")

    if echo "$SB_SECRETS" | grep -q "EHRBASE_URL"; then
        test_result "pass" "Supabase has EHRBASE_URL secret"
    else
        test_result "fail" "Supabase missing EHRBASE_URL secret"
    fi

    if echo "$SB_SECRETS" | grep -q "EHRBASE_USERNAME"; then
        test_result "pass" "Supabase has EHRBASE_USERNAME secret"
    else
        test_result "fail" "Supabase missing EHRBASE_USERNAME secret"
    fi

    if echo "$SB_SECRETS" | grep -q "EHRBASE_PASSWORD"; then
        test_result "pass" "Supabase has EHRBASE_PASSWORD secret"
    else
        test_result "fail" "Supabase missing EHRBASE_PASSWORD secret"
    fi
else
    echo -e "${YELLOW}⚠${NC}  Supabase CLI not available - skipping Supabase tests"
fi

################################################################################
# 5. PERFORMANCE TESTS
################################################################################

echo ""
echo "=========================================="
echo "Test Suite 5: Performance"
echo "=========================================="
echo ""

# Test response time
echo "Measuring response time..."
RESPONSE_TIME=$(curl -s -w "%{time_total}" -o /dev/null \
    -u "${EHRBASE_USER}:${EHRBASE_USER_PASS}" \
    "${EHRBASE_URL}/status" 2>/dev/null || echo "999")

RESPONSE_MS=$(echo "$RESPONSE_TIME * 1000" | bc)

if (( $(echo "$RESPONSE_TIME < 2.0" | bc -l) )); then
    test_result "pass" "Response time acceptable (${RESPONSE_MS}ms)"
else
    test_result "fail" "Response time too slow" "${RESPONSE_MS}ms (expected < 2000ms)"
fi

# Test concurrent requests
echo "Testing concurrent requests..."
TEMP_DIR=$(mktemp -d)
SUCCESS_COUNT=0

for i in {1..10}; do
    curl -s -o /dev/null -w "%{http_code}\n" \
        -u "${EHRBASE_USER}:${EHRBASE_USER_PASS}" \
        "${EHRBASE_URL}/status" > "$TEMP_DIR/result_$i.txt" 2>/dev/null &
done

wait

for i in {1..10}; do
    if [ -f "$TEMP_DIR/result_$i.txt" ]; then
        CODE=$(cat "$TEMP_DIR/result_$i.txt")
        if [ "$CODE" = "200" ]; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        fi
    fi
done

rm -rf "$TEMP_DIR"

if [ "$SUCCESS_COUNT" -ge 9 ]; then
    test_result "pass" "Concurrent requests handled ($SUCCESS_COUNT/10 successful)"
else
    test_result "fail" "Concurrent request handling issues" "$SUCCESS_COUNT/10 successful (expected 9+)"
fi

################################################################################
# SUMMARY
################################################################################

echo ""
echo "=========================================="
echo "Validation Complete!"
echo "=========================================="
echo ""

PASS_RATE=$(echo "scale=1; $TESTS_PASSED * 100 / $TESTS_TOTAL" | bc)

echo -e "${BLUE}Test Results:${NC}"
echo -e "  Total Tests:  $TESTS_TOTAL"
echo -e "  ${GREEN}Passed:${NC}       $TESTS_PASSED"
echo -e "  ${RED}Failed:${NC}       $TESTS_FAILED"
echo -e "  Pass Rate:    ${PASS_RATE}%"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo -e "${BLUE}Production EHRbase is ready for use${NC}"
    echo ""
    echo -e "${GREEN}Next Steps:${NC}"
    echo "  1. Configure DNS and SSL: ./08-setup-dns-ssl.sh"
    echo "  2. Set up monitoring: ./07-setup-monitoring.sh"
    echo "  3. Monitor logs for 24 hours"
    echo "  4. Test user creation flow in mobile app"
    echo ""
    exit 0
elif [ "$PASS_RATE" = "$(echo 'scale=1; 80' | bc)" ] || (( $(echo "$PASS_RATE >= 80" | bc -l) )); then
    echo -e "${YELLOW}⚠ Most tests passed, but some issues found${NC}"
    echo ""
    echo "Review failed tests above and address issues before production use"
    echo ""
    exit 1
else
    echo -e "${RED}✗ Multiple tests failed${NC}"
    echo ""
    echo "Critical issues detected - do not use in production"
    echo "Review failed tests above and re-run setup scripts"
    echo ""
    exit 1
fi
