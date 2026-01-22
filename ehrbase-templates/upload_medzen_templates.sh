#!/bin/bash

# Batch Upload Script for MedZen OpenEHR Templates
# Uploads all OPT files from opt-templates-medzen/ directory to EHRbase
# Usage: ./ehrbase-templates/upload_medzen_templates.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4"
EHRBASE_USER="ehrbase-admin"
EHRBASE_PASSWORD="EvenMoreSecretPassword"
OPT_DIR="ehrbase-templates/opt-templates-medzen"
LOG_FILE="ehrbase-templates/upload_log_medzen_$(date +%Y%m%d_%H%M%S).txt"
MAX_RETRIES=3
RETRY_DELAY=5

# Counters
TOTAL_TEMPLATES=0
SUCCESSFUL_UPLOADS=0
FAILED_UPLOADS=0
SKIPPED_UPLOADS=0

# Arrays for tracking
declare -a FAILED_TEMPLATE_NAMES
declare -a SKIPPED_TEMPLATE_NAMES

# Print header
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   📤 MedZen Template Batch Upload Script                  ║${NC}"
echo -e "${BLUE}║   EHRbase URL: ${EHRBASE_URL%%/rest*}${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

# Initialize log file
echo "MedZen OpenEHR Template Upload Log - $(date)" > "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Check if opt-templates-medzen directory exists
if [ ! -d "$OPT_DIR" ]; then
    echo -e "${RED}❌ ERROR: Directory not found: $OPT_DIR${NC}"
    echo -e "${YELLOW}ℹ️  Please ensure ADL templates have been converted to OPT format${NC}"
    echo -e "${YELLOW}ℹ️  Run: python3 ehrbase-templates/generate_opt_from_adl.py${NC}"
    exit 1
fi

# Count OPT files
OPT_FILES=("$OPT_DIR"/*.opt)
if [ ! -e "${OPT_FILES[0]}" ]; then
    echo -e "${RED}❌ ERROR: No .opt files found in $OPT_DIR${NC}"
    echo -e "${YELLOW}ℹ️  Please convert ADL templates to OPT format first${NC}"
    exit 1
fi

TOTAL_TEMPLATES=${#OPT_FILES[@]}

echo -e "${CYAN}📂 Found $TOTAL_TEMPLATES OPT templates to upload${NC}\n"
echo "Found $TOTAL_TEMPLATES OPT templates to upload" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Function to upload a single template with retry logic
upload_template() {
    local template_file="$1"
    local template_name=$(basename "$template_file" .opt)
    local attempt=1
    local success=false

    echo -e "${BLUE}📤 Uploading: ${template_name}${NC}"
    echo "Uploading: ${template_name}" >> "$LOG_FILE"

    while [ $attempt -le $MAX_RETRIES ] && [ "$success" = false ]; do
        if [ $attempt -gt 1 ]; then
            echo -e "   ${YELLOW}⟳ Retry attempt $attempt/$MAX_RETRIES${NC}"
            echo "   Retry attempt $attempt/$MAX_RETRIES" >> "$LOG_FILE"
            sleep $RETRY_DELAY
        fi

        # Perform upload
        HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$EHRBASE_URL" \
            -H "Content-Type: application/xml" \
            -u "$EHRBASE_USER:$EHRBASE_PASSWORD" \
            --data-binary "@$template_file" 2>&1)

        HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n1)
        RESPONSE_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')

        case $HTTP_CODE in
            201)
                echo -e "   ${GREEN}✅ SUCCESS (HTTP 201 Created)${NC}"
                echo "   SUCCESS (HTTP 201 Created)" >> "$LOG_FILE"
                ((SUCCESSFUL_UPLOADS++))
                success=true
                ;;
            400)
                echo -e "   ${RED}❌ FAILED (HTTP 400 Bad Request)${NC}"
                echo "   Error: $RESPONSE_BODY" >> "$LOG_FILE"
                echo -e "   ${YELLOW}⚠️  Possible namespace or XML structure issue${NC}"
                FAILED_TEMPLATE_NAMES+=("$template_name (400 Bad Request)")
                ((FAILED_UPLOADS++))
                break
                ;;
            401)
                echo -e "   ${RED}❌ FAILED (HTTP 401 Unauthorized)${NC}"
                echo "   FAILED (HTTP 401 Unauthorized)" >> "$LOG_FILE"
                echo -e "   ${YELLOW}⚠️  Invalid credentials${NC}"
                FAILED_TEMPLATE_NAMES+=("$template_name (401 Unauthorized)")
                ((FAILED_UPLOADS++))
                break
                ;;
            409)
                echo -e "   ${YELLOW}⚠️  SKIPPED (HTTP 409 Conflict - Template already exists)${NC}"
                echo "   SKIPPED (HTTP 409 Conflict - Template already exists)" >> "$LOG_FILE"
                SKIPPED_TEMPLATE_NAMES+=("$template_name (already exists)")
                ((SKIPPED_UPLOADS++))
                success=true
                ;;
            000)
                echo -e "   ${RED}❌ FAILED (Connection error)${NC}"
                echo "   FAILED (Connection error)" >> "$LOG_FILE"
                if [ $attempt -eq $MAX_RETRIES ]; then
                    FAILED_TEMPLATE_NAMES+=("$template_name (Connection error)")
                    ((FAILED_UPLOADS++))
                fi
                ;;
            *)
                echo -e "   ${RED}❌ FAILED (HTTP $HTTP_CODE)${NC}"
                echo "   FAILED (HTTP $HTTP_CODE)" >> "$LOG_FILE"
                echo "   Response: $RESPONSE_BODY" >> "$LOG_FILE"
                if [ $attempt -eq $MAX_RETRIES ]; then
                    FAILED_TEMPLATE_NAMES+=("$template_name (HTTP $HTTP_CODE)")
                    ((FAILED_UPLOADS++))
                fi
                ;;
        esac

        ((attempt++))
    done

    echo "" >> "$LOG_FILE"
    echo ""
}

# Upload all templates
for template_file in "${OPT_FILES[@]}"; do
    upload_template "$template_file"
done

# Generate summary report
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📊 Upload Summary Report${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "========================================" >> "$LOG_FILE"
echo "Upload Summary Report" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

echo -e "${BLUE}Total Templates Processed:${NC} $TOTAL_TEMPLATES"
echo -e "${GREEN}Successful Uploads:${NC} $SUCCESSFUL_UPLOADS"
echo -e "${YELLOW}Skipped (Already Exist):${NC} $SKIPPED_UPLOADS"
echo -e "${RED}Failed Uploads:${NC} $FAILED_UPLOADS"
echo ""

echo "Total Templates Processed: $TOTAL_TEMPLATES" >> "$LOG_FILE"
echo "Successful Uploads: $SUCCESSFUL_UPLOADS" >> "$LOG_FILE"
echo "Skipped (Already Exist): $SKIPPED_UPLOADS" >> "$LOG_FILE"
echo "Failed Uploads: $FAILED_UPLOADS" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Calculate success rate
if [ $TOTAL_TEMPLATES -gt 0 ]; then
    SUCCESS_RATE=$(awk "BEGIN {printf \"%.1f\", (($SUCCESSFUL_UPLOADS+$SKIPPED_UPLOADS)/$TOTAL_TEMPLATES)*100}")
    echo -e "${CYAN}Success Rate:${NC} $SUCCESS_RATE%"
    echo "Success Rate: $SUCCESS_RATE%" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
fi

# Print failed templates if any
if [ $FAILED_UPLOADS -gt 0 ]; then
    echo -e "${RED}Failed Templates:${NC}"
    echo "Failed Templates:" >> "$LOG_FILE"
    for failed in "${FAILED_TEMPLATE_NAMES[@]}"; do
        echo -e "  ${RED}•${NC} $failed"
        echo "  • $failed" >> "$LOG_FILE"
    done
    echo ""
    echo "" >> "$LOG_FILE"
fi

# Print skipped templates if any
if [ $SKIPPED_UPLOADS -gt 0 ]; then
    echo -e "${YELLOW}Skipped Templates (Already Exist):${NC}"
    echo "Skipped Templates (Already Exist):" >> "$LOG_FILE"
    for skipped in "${SKIPPED_TEMPLATE_NAMES[@]}"; do
        echo -e "  ${YELLOW}•${NC} $skipped"
        echo "  • $skipped" >> "$LOG_FILE"
    done
    echo ""
    echo "" >> "$LOG_FILE"
fi

# Final verdict
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $FAILED_UPLOADS -eq 0 ]; then
    echo -e "${GREEN}✅ UPLOAD COMPLETED SUCCESSFULLY!${NC}"
    echo "UPLOAD COMPLETED SUCCESSFULLY!" >> "$LOG_FILE"

    if [ $SKIPPED_UPLOADS -gt 0 ]; then
        echo -e "${YELLOW}Note: $SKIPPED_UPLOADS templates were skipped (already existed)${NC}"
    fi

    echo -e "\n${BLUE}Next Steps:${NC}"
    echo "  1. Run verification: ./ehrbase-templates/verify_templates.sh"
    echo "  2. Test composition creation for each template"
    echo "  3. Monitor edge function logs: npx supabase functions logs sync-to-ehrbase"
    echo "  4. Verify sync queue processing"

    echo "" >> "$LOG_FILE"
    echo "Next Steps:" >> "$LOG_FILE"
    echo "  1. Run verification: ./ehrbase-templates/verify_templates.sh" >> "$LOG_FILE"
    echo "  2. Test composition creation for each template" >> "$LOG_FILE"

    exit 0
else
    echo -e "${RED}❌ UPLOAD COMPLETED WITH ERRORS${NC}"
    echo "UPLOAD COMPLETED WITH ERRORS" >> "$LOG_FILE"
    echo -e "\n${BLUE}Troubleshooting:${NC}"
    echo "  1. Check log file: $LOG_FILE"
    echo "  2. For 400 errors: Verify XML namespace in OPT files"
    echo "  3. For 401 errors: Check EHRbase credentials"
    echo "  4. For connection errors: Verify EHRbase URL is accessible"
    echo "  5. Retry failed templates individually"

    echo "" >> "$LOG_FILE"
    echo "Troubleshooting:" >> "$LOG_FILE"
    echo "  1. Check log file: $LOG_FILE" >> "$LOG_FILE"
    echo "  2. For 400 errors: Verify XML namespace in OPT files" >> "$LOG_FILE"

    exit 1
fi

echo -e "\n${CYAN}📄 Detailed log saved to: $LOG_FILE${NC}"
echo "" >> "$LOG_FILE"
echo "Upload completed at: $(date)" >> "$LOG_FILE"
