#!/bin/bash

# Template Conversion Progress Tracker
# Tracks ADL-to-OPT conversion progress and validates converted files
# Usage: ./ehrbase-templates/track_conversion_progress.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Configuration
ADL_DIR="ehrbase-templates/proper-templates"
OPT_DIR="ehrbase-templates/opt-templates"

# Counters
TOTAL_TEMPLATES=0
CONVERTED_TEMPLATES=0
PENDING_TEMPLATES=0
VALID_OPT=0
INVALID_OPT=0

# Arrays for tracking
declare -a PENDING_LIST
declare -a CONVERTED_LIST
declare -a INVALID_OPT_LIST

# Print header
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   📊 OpenEHR Template Conversion Progress Tracker        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

# Check if directories exist
if [ ! -d "$ADL_DIR" ]; then
    echo -e "${RED}❌ ERROR: ADL directory not found: $ADL_DIR${NC}"
    exit 1
fi

if [ ! -d "$OPT_DIR" ]; then
    echo -e "${YELLOW}⚠️  OPT directory not found, creating: $OPT_DIR${NC}"
    mkdir -p "$OPT_DIR"
fi

# Count total ADL templates (excluding .md files)
ADL_FILES=("$ADL_DIR"/*.adl)
TOTAL_TEMPLATES=${#ADL_FILES[@]}

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Conversion Status${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Process each ADL file
for adl_file in "${ADL_FILES[@]}"; do
    if [ ! -e "$adl_file" ]; then
        continue
    fi

    # Extract base filename without extension
    base_name=$(basename "$adl_file" .adl)
    opt_file="$OPT_DIR/${base_name}.opt"

    # Check if corresponding OPT file exists
    if [ -f "$opt_file" ]; then
        # Validate OPT file structure
        if grep -q 'xmlns="http://schemas.openehr.org/v1"' "$opt_file" 2>/dev/null; then
            echo -e "  ${GREEN}✅${NC} $base_name"
            CONVERTED_LIST+=("$base_name")
            ((CONVERTED_TEMPLATES++))
            ((VALID_OPT++))
        else
            echo -e "  ${YELLOW}⚠️${NC}  $base_name ${RED}(Invalid XML namespace)${NC}"
            CONVERTED_LIST+=("$base_name")
            INVALID_OPT_LIST+=("$base_name")
            ((CONVERTED_TEMPLATES++))
            ((INVALID_OPT++))
        fi
    else
        echo -e "  ${GRAY}⏳${NC} $base_name ${GRAY}(Not converted)${NC}"
        PENDING_LIST+=("$base_name")
        ((PENDING_TEMPLATES++))
    fi
done

echo ""

# Summary statistics
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📊 Summary Statistics${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BLUE}Total ADL Templates:${NC} $TOTAL_TEMPLATES"
echo -e "${GREEN}Converted to OPT:${NC} $CONVERTED_TEMPLATES"
echo -e "${GRAY}Pending Conversion:${NC} $PENDING_TEMPLATES"
echo ""

if [ $CONVERTED_TEMPLATES -gt 0 ]; then
    echo -e "${GREEN}Valid OPT Files:${NC} $VALID_OPT"
fi

if [ $INVALID_OPT -gt 0 ]; then
    echo -e "${RED}Invalid OPT Files:${NC} $INVALID_OPT ${RED}(namespace issue)${NC}"
fi

echo ""

# Calculate progress percentage
if [ $TOTAL_TEMPLATES -gt 0 ]; then
    PROGRESS=$(awk "BEGIN {printf \"%.1f\", ($CONVERTED_TEMPLATES/$TOTAL_TEMPLATES)*100}")
    echo -e "${CYAN}Conversion Progress:${NC} $PROGRESS%"

    # Visual progress bar
    FILLED=$(awk "BEGIN {printf \"%.0f\", ($CONVERTED_TEMPLATES/$TOTAL_TEMPLATES)*50}")
    EMPTY=$((50 - FILLED))

    echo -ne "${CYAN}["
    for ((i=0; i<FILLED; i++)); do echo -ne "█"; done
    for ((i=0; i<EMPTY; i++)); do echo -ne "░"; done
    echo -e "]${NC}"
fi

echo ""

# Show pending templates list
if [ $PENDING_TEMPLATES -gt 0 ]; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}⏳ Pending Conversion (${PENDING_TEMPLATES} templates)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    for template in "${PENDING_LIST[@]}"; do
        echo -e "  ${GRAY}•${NC} $template"
    done

    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "  1. Open OpenEHR Template Designer: https://tools.openehr.org/designer/"
    echo "  2. Import ADL file: $ADL_DIR/[template-name].adl"
    echo "  3. Export as OPT and save to: $OPT_DIR/"
    echo "  4. Run this script again to track progress"
    echo ""
fi

# Show invalid OPT files
if [ $INVALID_OPT -gt 0 ]; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}⚠️  Invalid OPT Files (${INVALID_OPT} templates)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    echo -e "${RED}The following OPT files have incorrect XML namespace:${NC}\n"

    for template in "${INVALID_OPT_LIST[@]}"; do
        echo -e "  ${RED}•${NC} $template.opt"
    done

    echo ""
    echo -e "${BLUE}Fix Required:${NC}"
    echo "  Open each OPT file and ensure the root element has:"
    echo '  <template xmlns="http://schemas.openehr.org/v1">'
    echo ""
    echo "  NOT:"
    echo '  <template xmlns="openEHR/v1/Template">'
    echo ""
fi

# Final status message
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $PENDING_TEMPLATES -eq 0 ] && [ $INVALID_OPT -eq 0 ]; then
    echo -e "${GREEN}✅ ALL TEMPLATES CONVERTED!${NC}\n"
    echo -e "${BLUE}Ready for upload:${NC}"
    echo "  ./ehrbase-templates/upload_all_templates.sh"
    echo ""
    echo -e "${BLUE}Verify after upload:${NC}"
    echo "  ./ehrbase-templates/verify_templates.sh"
elif [ $PENDING_TEMPLATES -eq 0 ] && [ $INVALID_OPT -gt 0 ]; then
    echo -e "${YELLOW}⚠️  CONVERSION COMPLETE BUT $INVALID_OPT FILE(S) NEED NAMESPACE FIX${NC}"
    echo ""
    echo "  Fix XML namespace issues before uploading"
elif [ $CONVERTED_TEMPLATES -gt 0 ]; then
    echo -e "${YELLOW}⏳ CONVERSION IN PROGRESS${NC}"
    echo ""
    echo "  $CONVERTED_TEMPLATES of $TOTAL_TEMPLATES templates converted ($PROGRESS%)"
    echo "  Continue converting remaining $PENDING_TEMPLATES templates"
else
    echo -e "${YELLOW}⏳ CONVERSION NOT STARTED${NC}"
    echo ""
    echo "  Begin conversion using OpenEHR Template Designer"
    echo "  See TEMPLATE_CONVERSION_STATUS.md for detailed instructions"
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Estimated time remaining
if [ $PENDING_TEMPLATES -gt 0 ]; then
    MIN_TIME=$((PENDING_TEMPLATES * 15))
    MAX_TIME=$((PENDING_TEMPLATES * 30))
    MIN_HOURS=$(awk "BEGIN {printf \"%.1f\", $MIN_TIME/60}")
    MAX_HOURS=$(awk "BEGIN {printf \"%.1f\", $MAX_TIME/60}")

    echo ""
    echo -e "${BLUE}Estimated Time Remaining:${NC} ${MIN_HOURS}-${MAX_HOURS} hours"
    echo -e "${GRAY}(Based on 15-30 minutes per template)${NC}"
fi

echo ""
echo -e "${GRAY}For detailed status: see ehrbase-templates/TEMPLATE_CONVERSION_STATUS.md${NC}"
echo ""

exit 0
