#!/bin/bash

# Template Verification Script
# Verifies all OpenEHR templates have been uploaded to EHRbase
# Usage: ./ehrbase-templates/verify_templates.sh

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

# Expected templates (19 specialty + 7 additional = 26 total)
EXPECTED_TEMPLATES=(
    # 19 Specialty Tables (Priority 1)
    "medzen.antenatal_care_encounter.v1"
    "medzen.surgical_procedure_report.v1"
    "medzen.admission_discharge_summary.v1"
    "medzen.medication_dispensing_record.v1"
    "medzen.pharmacy_stock_management.v1"
    "medzen.clinical_consultation.v1"
    "medzen.oncology_treatment.v1"
    "medzen.infectious_disease_encounter.v1"
    "medzen.cardiology_encounter.v1"
    "medzen.emergency_encounter.v1"
    "medzen.nephrology_encounter.v1"
    "medzen.gastroenterology_procedures.v1"
    "medzen.endocrinology_management.v1"
    "medzen.pulmonology_encounter.v1"
    "medzen.psychiatric_assessment.v1"
    "medzen.neurology_examination.v1"
    "medzen.radiology_report.v1"
    "medzen.pathology_report.v1"
    "medzen.physiotherapy_session.v1"

    # 7 Additional Core Templates (Priority 2)
    "medzen.patient_demographics.v1"
    "medzen.vital_signs.v1"
    "medzen.lab_results.v1"
    "medzen.lab_results.v1"  # Note: Used by both lab test request and result report
    "medzen.prescriptions.v1"
    "medzen.dermatology.v1"
    "medzen.palliative_care.v1"
)

# Counters
TOTAL_EXPECTED=26
TEMPLATES_FOUND=0
TEMPLATES_MISSING=0
CHECKS_PASSED=0
CHECKS_FAILED=0

# Arrays for tracking
declare -a MISSING_TEMPLATE_NAMES
declare -a FOUND_TEMPLATE_NAMES

# Print header
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🔍 OpenEHR Template Verification Script                ║${NC}"
echo -e "${BLUE}║   EHRbase URL: ${EHRBASE_URL%%/rest*}${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

# Test 1: Check EHRbase connectivity
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 1: EHRbase Connectivity${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

CONNECTIVITY_TEST=$(curl -s -w "%{http_code}" -o /dev/null -u "$EHRBASE_USER:$EHRBASE_PASSWORD" "$EHRBASE_URL")

if [ "$CONNECTIVITY_TEST" = "200" ] || [ "$CONNECTIVITY_TEST" = "204" ]; then
    echo -e "${GREEN}✅ PASS: EHRbase is accessible${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}❌ FAIL: Cannot connect to EHRbase (HTTP $CONNECTIVITY_TEST)${NC}"
    ((CHECKS_FAILED++))
    echo -e "\n${YELLOW}Troubleshooting:${NC}"
    echo "  - Check EHRbase URL: $EHRBASE_URL"
    echo "  - Verify credentials are correct"
    echo "  - Ensure EHRbase server is running"
    exit 1
fi

echo ""

# Test 2: Retrieve all templates from EHRbase
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 2: Retrieve Template List${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

TEMPLATES_JSON=$(curl -s -X GET "$EHRBASE_URL" \
    -H "Accept: application/json" \
    -u "$EHRBASE_USER:$EHRBASE_PASSWORD" 2>&1)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ PASS: Successfully retrieved template list${NC}"
    ((CHECKS_PASSED++))

    # Check if jq is available
    if command -v jq &> /dev/null; then
        TOTAL_TEMPLATES=$(echo "$TEMPLATES_JSON" | jq -r '.templates | length' 2>/dev/null || echo "0")
        echo -e "${BLUE}ℹ️  Total templates in EHRbase: $TOTAL_TEMPLATES${NC}"
    else
        echo -e "${YELLOW}⚠️  jq not installed - skipping detailed JSON parsing${NC}"
    fi
else
    echo -e "${RED}❌ FAIL: Could not retrieve template list${NC}"
    ((CHECKS_FAILED++))
    exit 1
fi

echo ""

# Test 3: Check for expected medzen templates
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 3: Verify MedZen Templates${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BLUE}Checking for $TOTAL_EXPECTED expected templates...${NC}\n"

for template_id in "${EXPECTED_TEMPLATES[@]}"; do
    # Check if template exists in EHRbase
    CHECK_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null \
        -X GET "$EHRBASE_URL/$template_id" \
        -H "Accept: application/xml" \
        -u "$EHRBASE_USER:$EHRBASE_PASSWORD")

    if [ "$CHECK_RESPONSE" = "200" ]; then
        echo -e "  ${GREEN}✅${NC} $template_id"
        FOUND_TEMPLATE_NAMES+=("$template_id")
        ((TEMPLATES_FOUND++))
    else
        echo -e "  ${RED}❌${NC} $template_id (HTTP $CHECK_RESPONSE)"
        MISSING_TEMPLATE_NAMES+=("$template_id")
        ((TEMPLATES_MISSING++))
    fi
done

echo ""

if [ $TEMPLATES_MISSING -eq 0 ]; then
    echo -e "${GREEN}✅ PASS: All $TOTAL_EXPECTED expected templates found in EHRbase${NC}"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}❌ FAIL: $TEMPLATES_MISSING templates missing from EHRbase${NC}"
    ((CHECKS_FAILED++))
fi

echo ""

# Test 4: Template structure validation (sample check)
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Test 4: Template Structure Validation${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if [ ${#FOUND_TEMPLATE_NAMES[@]} -gt 0 ]; then
    # Check first found template for valid XML structure
    SAMPLE_TEMPLATE="${FOUND_TEMPLATE_NAMES[0]}"
    echo -e "${BLUE}Validating structure of: $SAMPLE_TEMPLATE${NC}\n"

    TEMPLATE_XML=$(curl -s -X GET "$EHRBASE_URL/$SAMPLE_TEMPLATE" \
        -H "Accept: application/xml" \
        -u "$EHRBASE_USER:$EHRBASE_PASSWORD")

    if echo "$TEMPLATE_XML" | grep -q "<template xmlns=\"http://schemas.openehr.org/v1\">"; then
        echo -e "${GREEN}✅ PASS: Template has valid OpenEHR namespace${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}❌ FAIL: Template namespace validation failed${NC}"
        ((CHECKS_FAILED++))
    fi

    if echo "$TEMPLATE_XML" | grep -q "<template_id>"; then
        echo -e "${GREEN}✅ PASS: Template has valid template_id element${NC}"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}❌ FAIL: Template missing template_id element${NC}"
        ((CHECKS_FAILED++))
    fi
else
    echo -e "${YELLOW}⚠️  SKIPPED: No templates found to validate${NC}"
fi

echo ""

# Summary Report
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📊 Verification Summary${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BLUE}Expected Templates:${NC} $TOTAL_EXPECTED"
echo -e "${GREEN}Templates Found:${NC} $TEMPLATES_FOUND"
echo -e "${RED}Templates Missing:${NC} $TEMPLATES_MISSING"
echo ""

echo -e "${BLUE}Total Verification Checks:${NC} $((CHECKS_PASSED + CHECKS_FAILED))"
echo -e "${GREEN}Checks Passed:${NC} $CHECKS_PASSED"
echo -e "${RED}Checks Failed:${NC} $CHECKS_FAILED"
echo ""

# Print missing templates if any
if [ $TEMPLATES_MISSING -gt 0 ]; then
    echo -e "${RED}Missing Templates:${NC}"
    for missing in "${MISSING_TEMPLATE_NAMES[@]}"; do
        echo -e "  ${RED}•${NC} $missing"
    done
    echo ""
fi

# Calculate success rate
if [ $TOTAL_EXPECTED -gt 0 ]; then
    SUCCESS_RATE=$(awk "BEGIN {printf \"%.1f\", ($TEMPLATES_FOUND/$TOTAL_EXPECTED)*100}")
    echo -e "${CYAN}Template Coverage:${NC} $SUCCESS_RATE%"
    echo ""
fi

# Final verdict
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $CHECKS_FAILED -eq 0 ] && [ $TEMPLATES_MISSING -eq 0 ]; then
    echo -e "${GREEN}✅ ALL VERIFICATION CHECKS PASSED!${NC}"
    echo -e "\n${GREEN}🎉 All MedZen templates are properly deployed to EHRbase!${NC}"

    echo -e "\n${BLUE}System Ready For:${NC}"
    echo "  ✓ Patient data synchronization"
    echo "  ✓ Medical record composition creation"
    echo "  ✓ Edge function processing (sync-to-ehrbase)"
    echo "  ✓ Production deployment"

    echo -e "\n${BLUE}Next Steps:${NC}"
    echo "  1. Test composition creation: See OPENEHR_TEMPLATE_DEPLOYMENT_GUIDE.md"
    echo "  2. Create sample medical records for each specialty"
    echo "  3. Monitor sync queue: SELECT * FROM ehrbase_sync_queue"
    echo "  4. Check edge function logs: npx supabase functions logs sync-to-ehrbase"

    exit 0
else
    echo -e "${RED}❌ VERIFICATION FAILED${NC}"
    echo -e "\n${RED}$CHECKS_FAILED check(s) failed${NC}"

    if [ $TEMPLATES_MISSING -gt 0 ]; then
        echo -e "${RED}$TEMPLATES_MISSING template(s) missing${NC}"
    fi

    echo -e "\n${BLUE}Troubleshooting:${NC}"
    echo "  1. Convert missing ADL templates to OPT format"
    echo "  2. Run upload script: ./ehrbase-templates/upload_all_templates.sh"
    echo "  3. Check upload logs in ehrbase-templates/ directory"
    echo "  4. Verify XML namespace in OPT files"
    echo "  5. See OPENEHR_TEMPLATE_DEPLOYMENT_GUIDE.md for detailed instructions"

    exit 1
fi
