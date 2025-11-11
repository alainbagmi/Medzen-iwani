#!/bin/bash

# PowerSync Setup Verification Script
# Run this to check if your PowerSync integration is correctly configured before deployment

set -e

echo "╔══════════════════════════════════════════════════════╗"
echo "║   PowerSync Setup Verification for MedZen Iwani     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

echo "════════════════════════════════════════════════════════"
echo "Step 1: Checking File Structure"
echo "════════════════════════════════════════════════════════"

# Check PowerSync files exist
if [ -f "POWERSYNC_SYNC_RULES.yaml" ]; then
    check_pass "POWERSYNC_SYNC_RULES.yaml exists"
else
    check_fail "POWERSYNC_SYNC_RULES.yaml not found"
fi

if [ -f "lib/powersync/database.dart" ]; then
    check_pass "lib/powersync/database.dart exists"
else
    check_fail "lib/powersync/database.dart not found"
fi

if [ -f "lib/powersync/schema.dart" ]; then
    check_pass "lib/powersync/schema.dart exists"
else
    check_fail "lib/powersync/schema.dart not found"
fi

if [ -f "lib/powersync/supabase_connector.dart" ]; then
    check_pass "lib/powersync/supabase_connector.dart exists"
else
    check_fail "lib/powersync/supabase_connector.dart not found"
fi

if [ -f "supabase/functions/powersync-token/index.ts" ]; then
    check_pass "supabase/functions/powersync-token/index.ts exists"
else
    check_fail "supabase/functions/powersync-token/index.ts not found"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "Step 2: Extracting Tables from Sync Rules (CRITICAL)"
echo "════════════════════════════════════════════════════════"

# Extract table names from sync rules
if [ -f "POWERSYNC_SYNC_RULES.yaml" ]; then
    sync_tables=$(grep -oP 'FROM \K[a-z_]+' POWERSYNC_SYNC_RULES.yaml | sort -u)
    table_count=$(echo "$sync_tables" | wc -l)
    print_info "Found $table_count unique tables referenced in sync rules"
else
    check_fail "Cannot read POWERSYNC_SYNC_RULES.yaml"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "Step 3: Extracting Tables from Schema (CRITICAL)"
echo "════════════════════════════════════════════════════════"

# Extract table names from schema.dart
if [ -f "lib/powersync/schema.dart" ]; then
    schema_tables=$(grep -oP "Table\('\K[a-z_]+(?=')" lib/powersync/schema.dart | sort -u)
    schema_count=$(echo "$schema_tables" | wc -l)
    print_info "Found $schema_count tables defined in schema.dart"
else
    check_fail "Cannot read lib/powersync/schema.dart"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "Step 4: Comparing Tables (MOST CRITICAL CHECK)"
echo "════════════════════════════════════════════════════════"

# Find tables in sync rules but not in schema
missing_count=0
echo ""
print_info "Checking for tables in sync rules missing from schema..."
while IFS= read -r table; do
    if ! echo "$schema_tables" | grep -q "^$table$"; then
        check_fail "Table '$table' in sync rules but NOT in schema.dart"
        missing_count=$((missing_count + 1))
    fi
done <<< "$sync_tables"

if [ $missing_count -eq 0 ]; then
    check_pass "All sync rule tables exist in schema.dart"
else
    echo ""
    echo -e "${RED}════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}CRITICAL ERROR: $missing_count table(s) missing from schema${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "This WILL cause PowerSync to fail!"
    echo "You must add these tables to lib/powersync/schema.dart"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "Step 5: Checking Supabase Secrets"
echo "════════════════════════════════════════════════════════"

if command -v npx &> /dev/null; then
    secrets_output=$(npx supabase secrets list 2>&1 || echo "error")

    if echo "$secrets_output" | grep -q "POWERSYNC_URL"; then
        check_pass "POWERSYNC_URL secret is set"
    else
        check_fail "POWERSYNC_URL not set. Run: npx supabase secrets set POWERSYNC_URL=https://YOUR_INSTANCE.journeyapps.com"
    fi

    if echo "$secrets_output" | grep -q "POWERSYNC_KEY_ID"; then
        check_pass "POWERSYNC_KEY_ID secret is set"
    else
        check_fail "POWERSYNC_KEY_ID not set. Run: npx supabase secrets set POWERSYNC_KEY_ID=abc123..."
    fi

    if echo "$secrets_output" | grep -q "POWERSYNC_PRIVATE_KEY"; then
        check_pass "POWERSYNC_PRIVATE_KEY secret is set"
    else
        check_fail "POWERSYNC_PRIVATE_KEY not set. Run: npx supabase secrets set POWERSYNC_PRIVATE_KEY='-----BEGIN...'"
    fi
else
    check_warn "npx not found, skipping Supabase secrets check"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "Step 6: Checking Sync Rules Syntax"
echo "════════════════════════════════════════════════════════"

# Check for common PowerSync issues
if grep -q "JOIN" POWERSYNC_SYNC_RULES.yaml 2>/dev/null; then
    check_warn "Found JOIN in sync rules - PowerSync doesn't support JOINs, use subqueries"
fi

if grep -q "token_parameters.user_id()" POWERSYNC_SYNC_RULES.yaml 2>/dev/null; then
    check_pass "Sync rules use token_parameters.user_id() correctly"
else
    check_fail "Sync rules must use token_parameters.user_id() for authentication"
fi

if grep -q "bucket_definitions:" POWERSYNC_SYNC_RULES.yaml 2>/dev/null; then
    check_pass "Sync rules define bucket_definitions"
else
    check_fail "Sync rules missing bucket_definitions"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "Step 7: Checking PowerSync Token Function"
echo "════════════════════════════════════════════════════════"

if [ -f "supabase/functions/powersync-token/index.ts" ]; then
    if grep -q "POWERSYNC_PRIVATE_KEY" supabase/functions/powersync-token/index.ts; then
        check_pass "Token function uses POWERSYNC_PRIVATE_KEY"
    else
        check_fail "Token function missing POWERSYNC_PRIVATE_KEY"
    fi

    if grep -q "jose" supabase/functions/powersync-token/index.ts; then
        check_pass "Token function imports jose library for JWT"
    else
        check_fail "Token function missing jose library import"
    fi

    if grep -q "RS256" supabase/functions/powersync-token/index.ts; then
        check_pass "Token function uses RS256 algorithm"
    else
        check_fail "Token function must use RS256 algorithm"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo "FINAL SUMMARY"
echo "════════════════════════════════════════════════════════"
echo ""
echo -e "Passed:   ${GREEN}$PASSED${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo -e "Failed:   ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ Review $WARNINGS warning(s) but you can proceed${NC}"
    fi
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "DEPLOYMENT STEPS:"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "1. Deploy PowerSync Token Function:"
    echo "   npx supabase functions deploy powersync-token"
    echo ""
    echo "2. Test the token function:"
    echo "   npx supabase functions invoke powersync-token \\"
    echo "     --headers \"Authorization: Bearer YOUR_USER_TOKEN\""
    echo ""
    echo "3. Deploy Sync Rules to PowerSync Dashboard:"
    echo "   a. Go to https://powersync.journeyapps.com/"
    echo "   b. Select your instance"
    echo "   c. Navigate to: Sync Rules"
    echo "   d. Copy entire contents of POWERSYNC_SYNC_RULES.yaml"
    echo "   e. Paste and click: Save → Deploy"
    echo ""
    echo "4. Test in your app with Connection Test Page"
    echo ""
else
    echo -e "${RED}✗ CRITICAL: $FAILED error(s) must be fixed before deploying!${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ Also found $WARNINGS warning(s)${NC}"
    fi
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "MOST COMMON FIXES:"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "1. Add missing tables to lib/powersync/schema.dart"
    echo "   - Check Step 4 output above for missing table names"
    echo "   - Add each table with proper column definitions"
    echo ""
    echo "2. Set PowerSync secrets:"
    echo "   npx supabase secrets set POWERSYNC_URL=https://YOUR_INSTANCE.journeyapps.com"
    echo "   npx supabase secrets set POWERSYNC_KEY_ID=your_key_id"
    echo "   npx supabase secrets set POWERSYNC_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----...'"
    echo ""
    echo "3. Deploy Edge Function:"
    echo "   npx supabase functions deploy powersync-token"
    echo ""
    echo "DO NOT deploy sync rules to PowerSync until all checks pass!"
    echo ""
    exit 1
fi

echo ""
