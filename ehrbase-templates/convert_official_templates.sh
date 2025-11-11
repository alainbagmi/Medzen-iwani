#!/bin/bash

# Convert Official OpenEHR Templates (.oet to .opt)
# Streamlined workflow for converting 26 officially accepted templates from CKM
# Usage: ./convert_official_templates.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration
OET_DIR="ehrbase-templates/official-templates"
OPT_DIR="ehrbase-templates/converted-opt"
TEMPLATE_DESIGNER_URL="https://tools.openehr.org/designer/"
PROGRESS_FILE="ehrbase-templates/.official_conversion_progress"

# Create converted-opt directory if it doesn't exist
mkdir -p "$OPT_DIR"

# Create or read progress file
if [ ! -f "$PROGRESS_FILE" ]; then
    echo "0" > "$PROGRESS_FILE"
fi

CURRENT_INDEX=$(cat "$PROGRESS_FILE")

# Get all OET files
OET_FILES=($(ls -1 "$OET_DIR"/*.oet 2>/dev/null | sort))
TOTAL_FILES=${#OET_FILES[@]}

# Print header
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🔄 Official OpenEHR Template Conversion Helper         ║${NC}"
echo -e "${BLUE}║   Converting CKM templates from .oet to .opt format      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

# Check if we've completed all templates
if [ $CURRENT_INDEX -ge $TOTAL_FILES ]; then
    echo -e "${GREEN}✅ All official templates have been processed!${NC}\n"
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Run ./ehrbase-templates/upload_all_templates.sh to upload"
    echo "  2. Update upload script to use converted-opt directory"
    echo ""
    rm -f "$PROGRESS_FILE"
    exit 0
fi

# Show progress
COMPLETED=$CURRENT_INDEX
REMAINING=$((TOTAL_FILES - CURRENT_INDEX))
PROGRESS=$(awk "BEGIN {printf \"%.1f\", ($COMPLETED/$TOTAL_FILES)*100}")

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📊 Conversion Progress${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BLUE}Total Templates:${NC} $TOTAL_FILES (from OpenEHR CKM)"
echo -e "${GREEN}Completed:${NC} $COMPLETED"
echo -e "${YELLOW}Remaining:${NC} $REMAINING"
echo -e "${CYAN}Progress:${NC} $PROGRESS%"
echo ""

# Get current template
CURRENT_OET="${OET_FILES[$CURRENT_INDEX]}"
TEMPLATE_NAME=$(basename "$CURRENT_OET" .oet)

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📝 Current Template: #$((CURRENT_INDEX + 1)) of $TOTAL_FILES${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "${BOLD}Template:${NC} $TEMPLATE_NAME"
echo -e "${BOLD}File:${NC} $CURRENT_OET"
echo ""

# Show template content preview
echo -e "${CYAN}Template Preview (first 20 lines):${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
head -20 "$CURRENT_OET" | cat -n
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Instructions
echo -e "${GREEN}${BOLD}Conversion Steps:${NC}"
echo ""
echo -e "${YELLOW}1.${NC} ${BOLD}Open Template Designer${NC}"
echo -e "   ${CYAN}URL:${NC} $TEMPLATE_DESIGNER_URL"
if command -v open &> /dev/null; then
    echo -e "   ${BLUE}Opening in browser...${NC}"
    open "$TEMPLATE_DESIGNER_URL" 2>/dev/null || true
elif command -v xdg-open &> /dev/null; then
    echo -e "   ${BLUE}Opening in browser...${NC}"
    xdg-open "$TEMPLATE_DESIGNER_URL" 2>/dev/null || true
else
    echo -e "   ${YELLOW}(Copy URL to browser manually)${NC}"
fi
echo ""

echo -e "${YELLOW}2.${NC} ${BOLD}Copy template content${NC}"
echo -e "   Run this command to copy to clipboard:"
if command -v pbcopy &> /dev/null; then
    echo -e "   ${CYAN}cat \"$CURRENT_OET\" | pbcopy${NC}"
    echo ""
    echo -e "   ${BLUE}Copying to clipboard now...${NC}"
    cat "$CURRENT_OET" | pbcopy
    echo -e "   ${GREEN}✅ Content copied to clipboard!${NC}"
elif command -v xclip &> /dev/null; then
    echo -e "   ${CYAN}cat \"$CURRENT_OET\" | xclip -selection clipboard${NC}"
    echo ""
    echo -e "   ${BLUE}Copying to clipboard now...${NC}"
    cat "$CURRENT_OET" | xclip -selection clipboard
    echo -e "   ${GREEN}✅ Content copied to clipboard!${NC}"
else
    echo -e "   ${CYAN}cat \"$CURRENT_OET\"${NC}"
    echo -e "   ${YELLOW}(Install pbcopy or xclip for automatic clipboard)${NC}"
fi
echo ""

echo -e "${YELLOW}3.${NC} ${BOLD}In Template Designer:${NC}"
echo "   • Click 'Import' or 'New Template'"
echo "   • Paste the copied .oet content"
echo "   • Wait for validation (check for errors)"
echo "   • Click 'Export' → 'Operational Template (OPT)'"
echo "   • Save as: ${CYAN}$TEMPLATE_NAME.opt${NC}"
echo ""

echo -e "${YELLOW}4.${NC} ${BOLD}Save OPT file${NC}"
echo -e "   ${CYAN}Save location:${NC} $OPT_DIR/$TEMPLATE_NAME.opt"
echo ""

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Wait for user confirmation
echo -e "${BOLD}After converting and saving the OPT file:${NC}"
echo ""
echo "  Press ${GREEN}ENTER${NC} to mark complete and move to next template"
echo "  Press ${YELLOW}S${NC} + ENTER to skip this template"
echo "  Press ${RED}Q${NC} + ENTER to quit"
echo ""
read -p "> " -r USER_INPUT

case "${USER_INPUT^^}" in
    Q)
        echo ""
        echo -e "${YELLOW}⏸️  Paused conversion process${NC}"
        echo -e "${BLUE}Progress saved:${NC} $COMPLETED of $TOTAL_FILES completed"
        echo ""
        echo -e "${BLUE}To resume:${NC} ./ehrbase-templates/convert_official_templates.sh"
        echo ""
        exit 0
        ;;
    S)
        echo ""
        echo -e "${YELLOW}⏭️  Skipped: $TEMPLATE_NAME${NC}"
        echo ""
        ;;
    *)
        # Verify OPT file was created
        if [ -f "$OPT_DIR/$TEMPLATE_NAME.opt" ]; then
            echo ""
            echo -e "${GREEN}✅ Verified: $TEMPLATE_NAME.opt exists${NC}"

            # Check XML namespace
            if grep -q 'xmlns="http://schemas.openehr.org/v1"' "$OPT_DIR/$TEMPLATE_NAME.opt"; then
                echo -e "${GREEN}✅ Valid XML namespace${NC}"
            else
                echo -e "${RED}⚠️  Warning: XML namespace may be incorrect${NC}"
                echo -e "${YELLOW}   Expected: xmlns=\"http://schemas.openehr.org/v1\"${NC}"
            fi

            # Check for concept element (OPT requirement)
            if grep -q '<concept>' "$OPT_DIR/$TEMPLATE_NAME.opt"; then
                echo -e "${GREEN}✅ Has <concept> element (OPT format)${NC}"
            else
                echo -e "${RED}⚠️  Warning: Missing <concept> element${NC}"
                echo -e "${YELLOW}   This may indicate .oet format instead of .opt${NC}"
            fi
            echo ""
        else
            echo ""
            echo -e "${RED}⚠️  Warning: OPT file not found at:${NC}"
            echo -e "   $OPT_DIR/$TEMPLATE_NAME.opt"
            echo -e "${YELLOW}   Marking as complete anyway (you can re-run later)${NC}"
            echo ""
        fi
        ;;
esac

# Update progress
echo $((CURRENT_INDEX + 1)) > "$PROGRESS_FILE"

# Calculate time estimate for remaining
REMAINING_MIN=$((REMAINING * 15))
REMAINING_MAX=$((REMAINING * 30))
REMAINING_HOURS_MIN=$(awk "BEGIN {printf \"%.1f\", $REMAINING_MIN/60}")
REMAINING_HOURS_MAX=$(awk "BEGIN {printf \"%.1f\", $REMAINING_MAX/60}")

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Updated Progress${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

NEW_COMPLETED=$((CURRENT_INDEX + 1))
NEW_REMAINING=$((TOTAL_FILES - NEW_COMPLETED))
NEW_PROGRESS=$(awk "BEGIN {printf \"%.1f\", ($NEW_COMPLETED/$TOTAL_FILES)*100}")

echo -e "${GREEN}Completed:${NC} $NEW_COMPLETED of $TOTAL_FILES ($NEW_PROGRESS%)"
echo -e "${YELLOW}Remaining:${NC} $NEW_REMAINING templates"

if [ $NEW_REMAINING -gt 0 ]; then
    echo -e "${BLUE}Est. Time:${NC} $REMAINING_HOURS_MIN-$REMAINING_HOURS_MAX hours"
    echo ""
    echo -e "${CYAN}Continue to next template...${NC}"
    sleep 2
    echo ""

    # Recursively call itself for next template
    exec "$0"
else
    echo ""
    echo -e "${GREEN}${BOLD}🎉 All Official Templates Converted!${NC}"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "  1. Update upload script:"
    echo "     ${CYAN}sed -i '' 's|opt-templates|converted-opt|g' ehrbase-templates/upload_all_templates.sh${NC}"
    echo ""
    echo "  2. Upload templates:"
    echo "     ${CYAN}./ehrbase-templates/upload_all_templates.sh${NC}"
    echo ""
    echo "  3. Verify upload:"
    echo "     ${CYAN}./ehrbase-templates/verify_templates.sh${NC}"
    echo ""
    rm -f "$PROGRESS_FILE"
fi
