#!/bin/bash

################################################################################
# EHRbase AWS Production - Import OpenEHR Templates
# Imports templates from dev export to production EHRbase
################################################################################

set -e  # Exit on error

echo "=========================================="
echo "EHRbase Production - Import Templates"
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
if [ -z "$ALB_DNS" ]; then
    echo -e "${RED}Error:${NC} ALB_DNS not found in .env"
    echo "Run ./04-setup-ecs.sh first"
    exit 1
fi

if [ -z "$EHRBASE_USER_PASS" ]; then
    echo -e "${RED}Error:${NC} EHRBASE_USER_PASS not found"
    echo "Run ./02-setup-database.sh first"
    exit 1
fi

EHRBASE_URL="http://${ALB_DNS}/ehrbase"
EHRBASE_USER="ehrbase-user"

echo -e "${BLUE}Configuration:${NC}"
echo "  EHRbase URL: $EHRBASE_URL"
echo "  Username: $EHRBASE_USER"
echo ""

################################################################################
# 1. FIND TEMPLATE DIRECTORY
################################################################################

echo "=========================================="
echo "Step 1: Locating Templates"
echo "=========================================="
echo ""

TEMPLATE_DIR=""

# Check if template directory provided as argument
if [ -n "$1" ]; then
    if [ -d "$1" ]; then
        TEMPLATE_DIR="$1"
        echo -e "${GREEN}✓${NC} Using provided directory: $TEMPLATE_DIR"
    else
        echo -e "${RED}Error:${NC} Directory not found: $1"
        exit 1
    fi
else
    # Look for dev export directories
    EXPORT_DIRS=$(ls -d dev-export-* 2>/dev/null || echo "")
    if [ -n "$EXPORT_DIRS" ]; then
        # Find most recent export
        EXPORT_DIR=$(echo "$EXPORT_DIRS" | sort -r | head -n 1)

        if [ -d "$EXPORT_DIR/templates" ]; then
            TEMPLATE_DIR="$EXPORT_DIR/templates"
            echo -e "${GREEN}✓${NC} Found templates in: $TEMPLATE_DIR"
        fi
    fi
fi

# If still no directory, ask user
if [ -z "$TEMPLATE_DIR" ]; then
    echo -e "${YELLOW}No template directory found${NC}"
    echo ""
    echo "Options:"
    echo "  1. Run ./00-export-from-dev.sh to export from dev"
    echo "  2. Provide template directory: ./04b-import-templates.sh /path/to/templates"
    echo "  3. Skip template import (manual import required)"
    echo ""
    read -p "Continue without importing templates? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted"
        exit 1
    fi
    echo -e "${YELLOW}⚠${NC}  Skipping template import"
    echo "  Templates must be imported manually for EHRbase to function"
    exit 0
fi

# Count templates
TEMPLATE_COUNT=$(ls -1 "$TEMPLATE_DIR"/*.opt 2>/dev/null | wc -l | tr -d ' ')

if [ "$TEMPLATE_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠${NC}  No .opt template files found in $TEMPLATE_DIR"
    echo "  Continuing without importing templates"
    exit 0
fi

echo ""
echo -e "${BLUE}Found $TEMPLATE_COUNT template(s) to import${NC}"

################################################################################
# 2. VERIFY EHRBASE IS READY
################################################################################

echo ""
echo "=========================================="
echo "Step 2: Verifying EHRbase Status"
echo "=========================================="
echo ""

echo "Testing EHRbase connection..."

# Test status endpoint
MAX_RETRIES=30
RETRY_COUNT=0
STATUS_OK=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -u "${EHRBASE_USER}:${EHRBASE_USER_PASS}" \
        "${EHRBASE_URL}/rest/status" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ]; then
        STATUS_OK=true
        break
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo "  Attempt $RETRY_COUNT/$MAX_RETRIES - HTTP $HTTP_CODE (retrying in 10s...)"
        sleep 10
    fi
done

if [ "$STATUS_OK" = false ]; then
    echo -e "${RED}✗${NC} EHRbase not responding (HTTP $HTTP_CODE)"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check ECS service: aws ecs describe-services --cluster ${PROJECT_NAME}-cluster --services ${PROJECT_NAME}-service"
    echo "  2. Check target health: aws elbv2 describe-target-health --target-group-arn <TG_ARN>"
    echo "  3. Check logs: aws logs tail /ecs/${PROJECT_NAME} --follow"
    exit 1
fi

echo -e "${GREEN}✓${NC} EHRbase is responding"

################################################################################
# 3. IMPORT TEMPLATES
################################################################################

echo ""
echo "=========================================="
echo "Step 3: Importing Templates"
echo "=========================================="
echo ""

IMPORTED=0
FAILED=0
SKIPPED=0

for TEMPLATE_FILE in "$TEMPLATE_DIR"/*.opt; do
    TEMPLATE_NAME=$(basename "$TEMPLATE_FILE")
    TEMPLATE_ID="${TEMPLATE_NAME%.opt}"

    echo "Importing: $TEMPLATE_ID"

    # Check if template already exists
    EXISTING=$(curl -s -u "${EHRBASE_USER}:${EHRBASE_USER_PASS}" \
        "${EHRBASE_URL}/rest/openehr/v1/definition/template/adl1.4/${TEMPLATE_ID}" \
        -w "\n%{http_code}" 2>/dev/null | tail -n 1)

    if [ "$EXISTING" = "200" ]; then
        echo -e "  ${YELLOW}⚠${NC}  Template already exists - skipping"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Import template
    RESPONSE=$(curl -s -w "\n%{http_code}" \
        -u "${EHRBASE_USER}:${EHRBASE_USER_PASS}" \
        -H "Content-Type: application/xml" \
        --data-binary "@${TEMPLATE_FILE}" \
        "${EHRBASE_URL}/rest/openehr/v1/definition/template/adl1.4" \
        2>/dev/null)

    HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
    RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

    if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
        echo -e "  ${GREEN}✓${NC} Imported successfully"
        IMPORTED=$((IMPORTED + 1))
    elif [ "$HTTP_CODE" = "409" ]; then
        echo -e "  ${YELLOW}⚠${NC}  Template already exists"
        SKIPPED=$((SKIPPED + 1))
    else
        echo -e "  ${RED}✗${NC} Failed (HTTP $HTTP_CODE)"
        if [ -n "$RESPONSE_BODY" ]; then
            echo "     Response: $RESPONSE_BODY"
        fi
        FAILED=$((FAILED + 1))
    fi

    # Small delay between imports
    sleep 1
done

################################################################################
# 4. VERIFY IMPORTS
################################################################################

echo ""
echo "=========================================="
echo "Step 4: Verifying Template Imports"
echo "=========================================="
echo ""

echo "Fetching template list from production..."

PROD_TEMPLATES=$(curl -s -u "${EHRBASE_USER}:${EHRBASE_USER_PASS}" \
    "${EHRBASE_URL}/rest/openehr/v1/definition/template/adl1.4" \
    -H "Accept: application/json" 2>/dev/null || echo "[]")

if [ "$PROD_TEMPLATES" = "[]" ] || [ -z "$PROD_TEMPLATES" ]; then
    echo -e "${YELLOW}⚠${NC}  No templates found in production"
    echo "  This may indicate an API issue"
else
    PROD_COUNT=$(echo "$PROD_TEMPLATES" | jq 'length' 2>/dev/null || echo "0")
    echo -e "${GREEN}✓${NC} Production has $PROD_COUNT template(s) available"

    # List templates
    if [ "$PROD_COUNT" -gt 0 ]; then
        echo ""
        echo "Templates in production:"
        echo "$PROD_TEMPLATES" | jq -r '.[].template_id' 2>/dev/null | while read -r tid; do
            echo "  - $tid"
        done
    fi
fi

################################################################################
# SUMMARY
################################################################################

echo ""
echo "=========================================="
echo "Template Import Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}Import Summary:${NC}"
echo "  Imported:  $IMPORTED"
echo "  Skipped:   $SKIPPED (already existed)"
echo "  Failed:    $FAILED"
echo "  Total:     $TEMPLATE_COUNT"
echo ""

if [ $FAILED -gt 0 ]; then
    echo -e "${YELLOW}⚠${NC}  Some templates failed to import"
    echo "  Review errors above and try manual import if needed"
    echo ""
fi

echo -e "${BLUE}Template Storage:${NC}"
echo "  Source:     $TEMPLATE_DIR"
echo "  Production: $EHRBASE_URL"
echo ""

echo -e "${GREEN}Next Steps:${NC}"
echo "  1. Update integrations:  ./05-update-integrations.sh"
echo "  2. Test user creation:   ./06-validate-deployment.sh"
echo ""

# Exit with error if any imports failed
if [ $FAILED -gt 0 ]; then
    exit 1
fi
