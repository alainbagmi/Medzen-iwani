#!/bin/bash
# Safe FlutterFlow Re-Export Script
# Created: 2025-11-11
# Purpose: Safely re-export code from FlutterFlow without overwriting critical custom code
# Usage: ./safe-reexport.sh /path/to/flutterflow-export.zip

set -e  # Exit on any error

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMP_DIR="$SCRIPT_DIR/.reexport-temp"
BACKUP_CREATED=false

# Cleanup function
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        echo -e "${YELLOW}Cleaning up temporary files...${NC}"
        rm -rf "$TEMP_DIR"
    fi
}

# Trap cleanup on exit
trap cleanup EXIT

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Safe FlutterFlow Re-Export${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check if ZIP file provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: No ZIP file provided${NC}"
    echo ""
    echo "Usage: $0 /path/to/flutterflow-export.zip"
    echo ""
    echo "Steps to export from FlutterFlow:"
    echo "1. Open FlutterFlow web interface"
    echo "2. Load project (wait 30-60 seconds for full load)"
    echo "3. Click 'Download Code' → Export as ZIP"
    echo "4. Save to Downloads folder"
    echo "5. Run: $0 ~/Downloads/medzen-iwani-export.zip"
    echo ""
    exit 1
fi

ZIP_FILE="$1"

# Check if ZIP file exists
if [ ! -f "$ZIP_FILE" ]; then
    echo -e "${RED}❌ Error: ZIP file not found: $ZIP_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found ZIP file: $ZIP_FILE"
echo ""

# STEP 1: Create backup
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 1: Creating Safety Backup${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

if [ -f "$SCRIPT_DIR/create-backup.sh" ]; then
    "$SCRIPT_DIR/create-backup.sh"
    BACKUP_CREATED=true
    echo -e "${GREEN}✓${NC} Safety backup created"
else
    echo -e "${YELLOW}⚠️  Warning: Backup script not found. Continuing without backup.${NC}"
    read -p "Press Enter to continue or Ctrl+C to abort..."
fi
echo ""

# STEP 2: Extract ZIP to temp directory
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 2: Extracting FlutterFlow Export${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

mkdir -p "$TEMP_DIR"
unzip -q "$ZIP_FILE" -d "$TEMP_DIR"

# Find the actual project directory (may be nested)
PROJECT_TEMP=$(find "$TEMP_DIR" -type f -name "pubspec.yaml" -exec dirname {} \; | head -n 1)

if [ -z "$PROJECT_TEMP" ]; then
    echo -e "${RED}❌ Error: Invalid FlutterFlow export (no pubspec.yaml found)${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Extracted to: $PROJECT_TEMP"
echo ""

# STEP 3: Identify safe directories to copy
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 3: Analyzing Changes${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

echo "Safe directories to update:"
echo "  ✓ lib/flutter_flow/ (FlutterFlow-managed)"
echo "  ✓ Generated page widgets (lib/*_page/)"
echo ""

echo -e "${RED}PROTECTED directories (will NOT be touched):${NC}"
echo "  🔒 lib/powersync/ (offline-first database)"
echo "  🔒 lib/custom_code/ (custom actions/widgets)"
echo "  🔒 firebase/ (Cloud Functions)"
echo "  🔒 supabase/ (migrations, edge functions)"
echo "  🔒 graphql_queries/ (custom GraphQL)"
echo ""

# Check if protected directories exist in export (they shouldn't)
WARNINGS=0

if [ -d "$PROJECT_TEMP/lib/powersync" ]; then
    echo -e "${YELLOW}⚠️  Warning: Export contains lib/powersync/ (will be ignored)${NC}"
    ((WARNINGS++))
fi

if [ -d "$PROJECT_TEMP/lib/custom_code" ]; then
    echo -e "${YELLOW}⚠️  Warning: Export contains lib/custom_code/ (will be ignored)${NC}"
    ((WARNINGS++))
fi

if [ -d "$PROJECT_TEMP/firebase" ]; then
    echo -e "${YELLOW}⚠️  Warning: Export contains firebase/ (will be ignored)${NC}"
    ((WARNINGS++))
fi

if [ -d "$PROJECT_TEMP/supabase" ]; then
    echo -e "${YELLOW}⚠️  Warning: Export contains supabase/ (will be ignored)${NC}"
    ((WARNINGS++))
fi

echo ""

# STEP 4: Show diff summary
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 4: Changes Summary${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

echo "Comparing lib/flutter_flow/..."

if [ -d "$SCRIPT_DIR/lib/flutter_flow" ] && [ -d "$PROJECT_TEMP/lib/flutter_flow" ]; then
    # Count changed files
    CHANGED_COUNT=0

    for file in "$PROJECT_TEMP/lib/flutter_flow"/*.dart; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if [ -f "$SCRIPT_DIR/lib/flutter_flow/$filename" ]; then
                if ! diff -q "$file" "$SCRIPT_DIR/lib/flutter_flow/$filename" > /dev/null 2>&1; then
                    ((CHANGED_COUNT++))
                fi
            fi
        fi
    done

    if [ $CHANGED_COUNT -gt 0 ]; then
        echo -e "${YELLOW}  $CHANGED_COUNT file(s) changed${NC}"
    else
        echo -e "${GREEN}  No changes detected${NC}"
    fi
else
    echo -e "${YELLOW}  Directory not found in one or both locations${NC}"
fi

echo ""

# STEP 5: Confirmation
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 5: Confirmation${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  $WARNINGS warning(s) detected${NC}"
    echo ""
fi

echo "This will update:"
echo "  ✓ lib/flutter_flow/ (FlutterFlow-managed files)"
echo ""

echo "This will NOT touch:"
echo "  🔒 lib/powersync/"
echo "  🔒 lib/custom_code/"
echo "  🔒 firebase/"
echo "  🔒 supabase/"
echo ""

if [ "$BACKUP_CREATED" = true ]; then
    echo -e "${GREEN}✓${NC} Safety backup created"
    echo ""
fi

read -p "Do you want to proceed? (yes/no): " -r CONFIRM
echo ""

if [[ ! $CONFIRM =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Re-export cancelled."
    exit 0
fi

# STEP 6: Apply changes
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 6: Applying Changes${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Copy lib/flutter_flow/ (safe - FlutterFlow-managed)
if [ -d "$PROJECT_TEMP/lib/flutter_flow" ]; then
    echo "Updating lib/flutter_flow/..."
    cp -r "$PROJECT_TEMP/lib/flutter_flow"/* "$SCRIPT_DIR/lib/flutter_flow/"
    echo -e "${GREEN}✓${NC} Updated lib/flutter_flow/"
else
    echo -e "${YELLOW}⚠️  lib/flutter_flow/ not found in export${NC}"
fi

echo ""

# STEP 7: Verification
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 7: Post-Export Verification${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

echo "Running verification checks..."
echo ""

# Check protected directories still exist
PROTECTED_DIRS=("lib/powersync" "lib/custom_code" "firebase/functions" "supabase/migrations")
ALL_PROTECTED=true

for dir in "${PROTECTED_DIRS[@]}"; do
    if [ -d "$SCRIPT_DIR/$dir" ]; then
        echo -e "${GREEN}✓${NC} Protected: $dir"
    else
        echo -e "${RED}✗${NC} MISSING: $dir"
        ALL_PROTECTED=false
    fi
done

echo ""

# Check critical files
CRITICAL_FILES=("firebase/functions/index.js" "CLAUDE.md" "ONUSERCREATED_COMPLETE_IMPLEMENTATION.md")
ALL_FILES_OK=true

for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        echo -e "${GREEN}✓${NC} Exists: $file"
    else
        echo -e "${RED}✗${NC} MISSING: $file"
        ALL_FILES_OK=false
    fi
done

echo ""

# Run Flutter pub get
echo "Running flutter pub get..."
if cd "$SCRIPT_DIR" && flutter pub get > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} flutter pub get succeeded"
else
    echo -e "${YELLOW}⚠️  flutter pub get failed - run manually${NC}"
fi

echo ""

# Summary
echo -e "${BLUE}=========================================${NC}"
if [ "$ALL_PROTECTED" = true ] && [ "$ALL_FILES_OK" = true ]; then
    echo -e "${GREEN}✅ Re-Export Complete - All Checks Passed${NC}"
else
    echo -e "${YELLOW}⚠️  Re-Export Complete - Some Issues Detected${NC}"
fi
echo -e "${BLUE}=========================================${NC}"
echo ""

if [ "$BACKUP_CREATED" = true ]; then
    echo "If something went wrong, restore from backup:"
    echo "  ls -lh $HOME/backups-medzen/"
    echo ""
fi

echo "Next steps:"
echo "1. Run: flutter analyze"
echo "2. Test the app: flutter run"
echo "3. Verify functions: firebase functions:list"
echo "4. Commit changes: git add . && git commit -m 'Safe re-export from FlutterFlow'"
echo ""
