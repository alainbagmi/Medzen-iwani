#!/bin/bash
# Manual Backup Script for MedZen Iwani Critical Files
# Created: 2025-11-11
# Purpose: Create timestamped backup of Firebase functions and critical documentation

set -e  # Exit on any error

# Determine script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_NAME="medzen-iwani-t1nrnu"
BACKUP_BASE="$HOME/backups-medzen"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$BACKUP_BASE/backup_$TIMESTAMP"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}MedZen Iwani Manual Backup${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Create backup directory
echo -e "${YELLOW}Creating backup directory...${NC}"
mkdir -p "$BACKUP_DIR"
echo -e "${GREEN}✓${NC} Created: $BACKUP_DIR"
echo ""

# Backup Firebase Functions
echo -e "${YELLOW}Backing up Firebase Functions...${NC}"
if [ -d "$SCRIPT_DIR/firebase/functions" ]; then
    mkdir -p "$BACKUP_DIR/firebase/functions"
    cp -r "$SCRIPT_DIR/firebase/functions/index.js" "$BACKUP_DIR/firebase/functions/"
    cp -r "$SCRIPT_DIR/firebase/functions/package.json" "$BACKUP_DIR/firebase/functions/"
    cp -r "$SCRIPT_DIR/firebase/functions/pre-deploy-check.sh" "$BACKUP_DIR/firebase/functions/" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Backed up: firebase/functions/"
else
    echo -e "${YELLOW}⚠️${NC}  firebase/functions/ not found"
fi

# Backup Firebase config files
echo -e "${YELLOW}Backing up Firebase configuration...${NC}"
if [ -f "$SCRIPT_DIR/firebase/firebase.json" ]; then
    mkdir -p "$BACKUP_DIR/firebase"
    cp "$SCRIPT_DIR/firebase/firebase.json" "$BACKUP_DIR/firebase/"
    echo -e "${GREEN}✓${NC} Backed up: firebase/firebase.json"
fi

if [ -f "$SCRIPT_DIR/firebase/firestore.rules" ]; then
    cp "$SCRIPT_DIR/firebase/firestore.rules" "$BACKUP_DIR/firebase/"
    echo -e "${GREEN}✓${NC} Backed up: firebase/firestore.rules"
fi

if [ -f "$SCRIPT_DIR/firebase/storage.rules" ]; then
    cp "$SCRIPT_DIR/firebase/storage.rules" "$BACKUP_DIR/firebase/"
    echo -e "${GREEN}✓${NC} Backed up: firebase/storage.rules"
fi
echo ""

# Backup Supabase migrations
echo -e "${YELLOW}Backing up Supabase migrations...${NC}"
if [ -d "$SCRIPT_DIR/supabase/migrations" ]; then
    mkdir -p "$BACKUP_DIR/supabase"
    cp -r "$SCRIPT_DIR/supabase/migrations" "$BACKUP_DIR/supabase/"
    MIGRATION_COUNT=$(find "$SCRIPT_DIR/supabase/migrations" -name "*.sql" | wc -l)
    echo -e "${GREEN}✓${NC} Backed up: supabase/migrations/ ($MIGRATION_COUNT files)"
else
    echo -e "${YELLOW}⚠️${NC}  supabase/migrations/ not found"
fi
echo ""

# Backup Supabase functions
echo -e "${YELLOW}Backing up Supabase edge functions...${NC}"
if [ -d "$SCRIPT_DIR/supabase/functions" ]; then
    mkdir -p "$BACKUP_DIR/supabase"
    cp -r "$SCRIPT_DIR/supabase/functions" "$BACKUP_DIR/supabase/"
    FUNCTION_COUNT=$(find "$SCRIPT_DIR/supabase/functions" -type d -maxdepth 1 -mindepth 1 | wc -l)
    echo -e "${GREEN}✓${NC} Backed up: supabase/functions/ ($FUNCTION_COUNT functions)"
else
    echo -e "${YELLOW}⚠️${NC}  supabase/functions/ not found"
fi
echo ""

# Backup PowerSync configuration
echo -e "${YELLOW}Backing up PowerSync configuration...${NC}"
if [ -f "$SCRIPT_DIR/POWERSYNC_SYNC_RULES.yaml" ]; then
    cp "$SCRIPT_DIR/POWERSYNC_SYNC_RULES.yaml" "$BACKUP_DIR/"
    echo -e "${GREEN}✓${NC} Backed up: POWERSYNC_SYNC_RULES.yaml"
fi

if [ -d "$SCRIPT_DIR/lib/powersync" ]; then
    mkdir -p "$BACKUP_DIR/lib"
    cp -r "$SCRIPT_DIR/lib/powersync" "$BACKUP_DIR/lib/"
    echo -e "${GREEN}✓${NC} Backed up: lib/powersync/"
fi
echo ""

# Backup critical documentation
echo -e "${YELLOW}Backing up critical documentation...${NC}"
DOCS=(
    "CLAUDE.md"
    "ONUSERCREATED_COMPLETE_IMPLEMENTATION.md"
    "ONUSERCREATED_FIX_REPORT.md"
    "DEMOGRAPHICS_SYNC_IMPLEMENTATION.md"
    "EHR_SYSTEM_README.md"
    "POWERSYNC_QUICK_START.md"
    "TESTING_GUIDE.md"
)

DOC_COUNT=0
for doc in "${DOCS[@]}"; do
    if [ -f "$SCRIPT_DIR/$doc" ]; then
        cp "$SCRIPT_DIR/$doc" "$BACKUP_DIR/"
        DOC_COUNT=$((DOC_COUNT + 1))
    fi
done

if [ $DOC_COUNT -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Backed up: $DOC_COUNT documentation files"
else
    echo -e "${YELLOW}⚠️${NC}  No documentation files found"
fi
echo ""

# Backup Git repository (if exists)
echo -e "${YELLOW}Backing up Git repository...${NC}"
if [ -d "$SCRIPT_DIR/.git" ]; then
    # Get latest commit info
    cd "$SCRIPT_DIR"
    LATEST_COMMIT=$(git log -1 --format="%H %s" 2>/dev/null || echo "No commits")

    # Create Git bundle (portable backup)
    git bundle create "$BACKUP_DIR/repository.bundle" --all 2>/dev/null || true

    # Save commit info
    echo "Latest commit: $LATEST_COMMIT" > "$BACKUP_DIR/git-info.txt"
    git log --oneline -10 >> "$BACKUP_DIR/git-info.txt" 2>/dev/null || true

    echo -e "${GREEN}✓${NC} Backed up: Git repository (bundle + commit info)"
else
    echo -e "${YELLOW}⚠️${NC}  No Git repository found"
fi
echo ""

# Create backup manifest
echo -e "${YELLOW}Creating backup manifest...${NC}"
cat > "$BACKUP_DIR/BACKUP_MANIFEST.txt" << EOF
MedZen Iwani Backup Manifest
========================================
Backup Created: $(date)
Backup Location: $BACKUP_DIR
Project Root: $SCRIPT_DIR

Contents:
- Firebase Functions (onUserCreated)
- Firebase Configuration (firebase.json, firestore.rules, storage.rules)
- Supabase Migrations ($MIGRATION_COUNT files)
- Supabase Edge Functions
- PowerSync Configuration
- Critical Documentation ($DOC_COUNT files)
- Git Repository (if exists)

To restore:
1. Copy files back to project directory
2. Run 'npm install' in firebase/functions/
3. Run 'firebase deploy --only functions:onUserCreated'
4. Verify deployment with 'firebase functions:list'

Important Notes:
- This backup does NOT include sensitive credentials (.runtimeconfig.json, .env)
- Firebase Functions config must be set separately via 'firebase functions:config:set'
- Supabase secrets must be set via 'npx supabase secrets set'
========================================
EOF

echo -e "${GREEN}✓${NC} Created: BACKUP_MANIFEST.txt"
echo ""

# Calculate backup size
BACKUP_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

# Summary
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Backup Complete!${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "Location: ${GREEN}$BACKUP_DIR${NC}"
echo -e "Size:     ${GREEN}$BACKUP_SIZE${NC}"
echo -e "Time:     ${GREEN}$(date)${NC}"
echo ""
echo "To restore, copy files back to:"
echo "  $SCRIPT_DIR"
echo ""
echo "To list all backups:"
echo "  ls -lh $BACKUP_BASE"
echo ""
