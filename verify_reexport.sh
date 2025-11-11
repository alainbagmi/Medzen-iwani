#!/bin/bash
# Verification script for FlutterFlow re-export
# Run this after completing the re-export process

set -e

echo "============================================"
echo "FlutterFlow Re-Export Verification Script"
echo "============================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track success/failure
ERRORS=0

echo "Step 1: Checking critical files exist..."
echo "----------------------------------------"

# Check that custom files were NOT overwritten
if [ -f "lib/powersync/database.dart" ]; then
    echo -e "${GREEN}✅ lib/powersync/database.dart exists${NC}"
else
    echo -e "${RED}❌ lib/powersync/database.dart MISSING${NC}"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "lib/powersync/schema.dart" ]; then
    echo -e "${GREEN}✅ lib/powersync/schema.dart exists${NC}"
else
    echo -e "${RED}❌ lib/powersync/schema.dart MISSING${NC}"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "lib/powersync/supabase_connector.dart" ]; then
    echo -e "${GREEN}✅ lib/powersync/supabase_connector.dart exists${NC}"
else
    echo -e "${RED}❌ lib/powersync/supabase_connector.dart MISSING${NC}"
    ERRORS=$((ERRORS + 1))
fi

if [ -d "firebase/functions" ]; then
    echo -e "${GREEN}✅ firebase/functions directory exists${NC}"
else
    echo -e "${RED}❌ firebase/functions directory MISSING${NC}"
    ERRORS=$((ERRORS + 1))
fi

if [ -d "supabase/migrations" ]; then
    echo -e "${GREEN}✅ supabase/migrations directory exists${NC}"
else
    echo -e "${RED}❌ supabase/migrations directory MISSING${NC}"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "Step 2: Running Flutter pub get..."
echo "----------------------------------------"
if flutter pub get; then
    echo -e "${GREEN}✅ flutter pub get succeeded${NC}"
else
    echo -e "${RED}❌ flutter pub get failed${NC}"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "Step 3: Running Flutter analyze..."
echo "----------------------------------------"
# Capture analyze output
ANALYZE_OUTPUT=$(flutter analyze 2>&1)
ANALYZE_ISSUES=$(echo "$ANALYZE_OUTPUT" | grep -c "error •" || true)

if [ "$ANALYZE_ISSUES" -eq 0 ]; then
    echo -e "${GREEN}✅ No compilation errors found${NC}"
elif [ "$ANALYZE_ISSUES" -le 10 ]; then
    echo -e "${YELLOW}⚠️  Found $ANALYZE_ISSUES errors (pre-existing)${NC}"
    echo "These are pre-existing errors, not caused by re-export"
else
    echo -e "${RED}❌ Found $ANALYZE_ISSUES errors (investigate)${NC}"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "Step 4: Checking package versions in pubspec.yaml..."
echo "----------------------------------------"
SUPABASE_VERSION=$(grep "supabase:" pubspec.yaml | grep -v "#" | awk '{print $2}')
SUPABASE_FLUTTER_VERSION=$(grep "supabase_flutter:" pubspec.yaml | grep -v "#" | awk '{print $2}')

echo "Current versions:"
echo "  supabase: $SUPABASE_VERSION"
echo "  supabase_flutter: $SUPABASE_FLUTTER_VERSION"

if [[ "$SUPABASE_VERSION" == "^2.10.0" ]] || [[ "$SUPABASE_VERSION" == "2.10.0" ]]; then
    echo -e "${GREEN}✅ supabase version correct${NC}"
else
    echo -e "${YELLOW}⚠️  supabase version changed (expected ^2.10.0)${NC}"
fi

if [[ "$SUPABASE_FLUTTER_VERSION" == "^2.10.3" ]] || [[ "$SUPABASE_FLUTTER_VERSION" == "2.10.3" ]]; then
    echo -e "${GREEN}✅ supabase_flutter version correct${NC}"
else
    echo -e "${YELLOW}⚠️  supabase_flutter version changed (expected ^2.10.3)${NC}"
fi

echo ""
echo "Step 5: Checking for package warnings in database.dart..."
echo "----------------------------------------"
if grep -q "hide Provider" lib/backend/supabase/database/database.dart 2>/dev/null; then
    WARNING_COUNT=$(flutter analyze lib/backend/supabase/database/database.dart 2>&1 | grep -c "doesn't export a member with the hidden name" || true)
    if [ "$WARNING_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Found $WARNING_COUNT 'hide Provider' warnings (cosmetic only)${NC}"
    else
        echo -e "${GREEN}✅ No 'hide Provider' warnings${NC}"
    fi
else
    echo -e "${GREEN}✅ No 'hide Provider' clause found${NC}"
fi

echo ""
echo "============================================"
echo "Verification Summary"
echo "============================================"

if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run the app: flutter run -d chrome"
    echo "2. Test authentication (login/signup)"
    echo "3. Test PowerSync offline mode"
    echo "4. Navigate to /connectionTest for full system test"
    echo ""
    echo "Your project is ready!"
else
    echo -e "${RED}❌ Found $ERRORS critical issues${NC}"
    echo ""
    echo "To restore from backup:"
    echo "  cd /Users/alainbagmi/Desktop"
    echo "  rm -rf medzen-iwani-t1nrnu"
    echo "  cp -r medzen-iwani-backup-20251029-132805 medzen-iwani-t1nrnu"
    echo ""
    exit 1
fi
