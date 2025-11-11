#!/bin/bash
# Restoration script for FlutterFlow re-export
# Run this if re-export causes issues

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BACKUP_DIR="/Users/alainbagmi/Desktop/medzen-iwani-backup-20251029-132805"
PROJECT_DIR="/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu"

echo "============================================"
echo "FlutterFlow Re-Export Restoration Script"
echo "============================================"
echo ""

# Check if backup exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo -e "${RED}❌ Backup directory not found: $BACKUP_DIR${NC}"
    echo ""
    echo "Available backups:"
    ls -lh /Users/alainbagmi/Desktop/medzen-iwani-backup-* 2>/dev/null || echo "No backups found"
    exit 1
fi

echo -e "${YELLOW}⚠️  WARNING: This will REPLACE your current project with the backup${NC}"
echo ""
echo "Backup location: $BACKUP_DIR"
echo "Project location: $PROJECT_DIR"
echo ""
read -p "Are you sure you want to restore? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Restoration cancelled"
    exit 0
fi

echo ""
echo "Step 1: Creating safety backup of current state..."
echo "----------------------------------------"
SAFETY_BACKUP="/Users/alainbagmi/Desktop/medzen-iwani-failed-$(date +%Y%m%d-%H%M%S)"
cp -r "$PROJECT_DIR" "$SAFETY_BACKUP"
echo -e "${GREEN}✅ Safety backup created: $SAFETY_BACKUP${NC}"

echo ""
echo "Step 2: Removing current project directory..."
echo "----------------------------------------"
rm -rf "$PROJECT_DIR"
echo -e "${GREEN}✅ Current project removed${NC}"

echo ""
echo "Step 3: Restoring from backup..."
echo "----------------------------------------"
cp -r "$BACKUP_DIR" "$PROJECT_DIR"
echo -e "${GREEN}✅ Project restored from backup${NC}"

echo ""
echo "Step 4: Running flutter pub get..."
echo "----------------------------------------"
cd "$PROJECT_DIR"
if flutter pub get; then
    echo -e "${GREEN}✅ flutter pub get succeeded${NC}"
else
    echo -e "${RED}❌ flutter pub get failed${NC}"
    exit 1
fi

echo ""
echo "Step 5: Running flutter analyze..."
echo "----------------------------------------"
flutter analyze || true

echo ""
echo "============================================"
echo "Restoration Complete"
echo "============================================"
echo ""
echo -e "${GREEN}✅ Project restored successfully${NC}"
echo ""
echo "Your project has been restored to the state before re-export."
echo ""
echo "Failed attempt saved to: $SAFETY_BACKUP"
echo "(You can delete this after verifying restoration worked)"
echo ""
echo "Next steps:"
echo "1. Run the app: flutter run -d chrome"
echo "2. Verify all functionality works"
echo "3. Review FLUTTERFLOW_REEXPORT_GUIDE.md for troubleshooting"
echo ""
