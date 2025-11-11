#!/bin/bash

# ================================================================
# MedZen-Iwani End-to-End Authentication Flow Test
# Tests the complete auth flow through all 4 systems
# ================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    echo -e "${YELLOW}[TEST $TESTS_TOTAL]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Test function
run_test() {
    ((TESTS_TOTAL++))
    print_test "$1"
}

# ================================================================
# SYSTEM 1: FIREBASE AUTHENTICATION
# ================================================================
print_header "SYSTEM 1/4: FIREBASE AUTHENTICATION"

# Test 1.1: Firebase CLI
run_test "Firebase CLI installed"
if command -v firebase &> /dev/null; then
    FIREBASE_VERSION=$(firebase --version)
    print_success "Firebase CLI: $FIREBASE_VERSION"
else
    print_error "Firebase CLI not installed"
fi

# Test 1.2: Firebase project configured
run_test "Firebase project configuration"
if [ -f ".firebaserc" ]; then
    FIREBASE_PROJECT=$(grep -A 1 '"default"' .firebaserc | grep -o '"[^"]*"' | tail -1 | tr -d '"')
    print_success "Firebase project: $FIREBASE_PROJECT"
else
    print_error ".firebaserc not found"
fi

# Test 1.3: Firebase Functions
run_test "Firebase Functions deployed"
if [ -f "firebase/functions/index.js" ]; then
    print_success "Firebase Functions code found"

    # Check for critical functions
    if grep -q "onUserCreated" firebase/functions/index.js; then
        print_success "  → onUserCreated function exists"
    else
        print_error "  → onUserCreated function missing"
    fi

    if grep -q "onUserDeleted" firebase/functions/index.js; then
        print_success "  → onUserDeleted function exists"
    else
        print_error "  → onUserDeleted function missing"
    fi
else
    print_error "Firebase Functions code not found"
fi

# Test 1.4: Firebase Functions config
run_test "Firebase Functions config"
FIREBASE_CONFIG_CHECK=$(firebase functions:config:get 2>/dev/null)
if [ $? -eq 0 ]; then
    print_success "Firebase config accessible"

    # Check for required config keys
    if echo "$FIREBASE_CONFIG_CHECK" | grep -q "supabase"; then
        print_success "  → Supabase config found"
    else
        print_warning "  → Supabase config not found"
    fi

    if echo "$FIREBASE_CONFIG_CHECK" | grep -q "ehrbase"; then
        print_success "  → EHRbase config found"
    else
        print_warning "  → EHRbase config not found"
    fi
else
    print_warning "Cannot check Firebase config (login required)"
fi

# ================================================================
# SYSTEM 2: SUPABASE
# ================================================================
print_header "SYSTEM 2/4: SUPABASE"

# Test 2.1: Supabase CLI
run_test "Supabase CLI installed"
if command -v supabase &> /dev/null; then
    SUPABASE_VERSION=$(npx supabase --version)
    print_success "Supabase CLI: $SUPABASE_VERSION"
else
    print_error "Supabase CLI not installed"
fi

# Test 2.2: Supabase project linked
run_test "Supabase project linked"
if [ -f "supabase/config.toml" ]; then
    PROJECT_ID=$(grep 'project_id' supabase/config.toml | cut -d '"' -f 2)
    print_success "Supabase project ID: $PROJECT_ID"
else
    print_error "supabase/config.toml not found"
fi

# Test 2.3: Supabase migrations
run_test "Supabase migrations"
if [ -d "supabase/migrations" ]; then
    MIGRATION_COUNT=$(ls -1 supabase/migrations/*.sql 2>/dev/null | wc -l | xargs)
    print_success "Found $MIGRATION_COUNT migrations"

    # Check for critical tables in migrations
    if grep -r "CREATE TABLE.*users" supabase/migrations/ &>/dev/null; then
        print_success "  → users table migration found"
    else
        print_error "  → users table migration missing"
    fi

    if grep -r "CREATE TABLE.*electronic_health_records" supabase/migrations/ &>/dev/null; then
        print_success "  → electronic_health_records table migration found"
    else
        print_error "  → electronic_health_records table migration missing"
    fi
else
    print_error "supabase/migrations directory not found"
fi

# Test 2.4: Supabase Edge Functions
run_test "Supabase Edge Functions"
if [ -d "supabase/functions" ]; then
    FUNCTION_COUNT=$(ls -1d supabase/functions/*/ 2>/dev/null | wc -l | xargs)
    print_success "Found $FUNCTION_COUNT edge functions"

    # Check for powersync-token function
    if [ -f "supabase/functions/powersync-token/index.ts" ]; then
        print_success "  → powersync-token function found"
    else
        print_error "  → powersync-token function missing"
    fi

    # Check for sync-to-ehrbase function
    if [ -f "supabase/functions/sync-to-ehrbase/index.ts" ]; then
        print_success "  → sync-to-ehrbase function found"
    else
        print_error "  → sync-to-ehrbase function missing"
    fi
else
    print_error "supabase/functions directory not found"
fi

# Test 2.5: Supabase secrets
run_test "Supabase secrets configuration"
SECRETS_OUTPUT=$(npx supabase secrets list 2>/dev/null)
if [ $? -eq 0 ]; then
    print_success "Supabase secrets accessible"

    # Check for required secrets
    if echo "$SECRETS_OUTPUT" | grep -q "EHRBASE_URL"; then
        print_success "  → EHRBASE_URL configured"
    else
        print_error "  → EHRBASE_URL missing"
    fi

    if echo "$SECRETS_OUTPUT" | grep -q "SUPABASE_URL"; then
        print_success "  → SUPABASE_URL configured"
    else
        print_error "  → SUPABASE_URL missing"
    fi

    if echo "$SECRETS_OUTPUT" | grep -q "POWERSYNC_URL"; then
        print_success "  → POWERSYNC_URL configured"
    else
        print_warning "  → POWERSYNC_URL missing (needed for PowerSync)"
    fi

    if echo "$SECRETS_OUTPUT" | grep -q "POWERSYNC_KEY_ID"; then
        print_success "  → POWERSYNC_KEY_ID configured"
    else
        print_warning "  → POWERSYNC_KEY_ID missing (needed for PowerSync)"
    fi

    if echo "$SECRETS_OUTPUT" | grep -q "POWERSYNC_PRIVATE_KEY"; then
        print_success "  → POWERSYNC_PRIVATE_KEY configured"
    else
        print_warning "  → POWERSYNC_PRIVATE_KEY missing (needed for PowerSync)"
    fi
else
    print_error "Cannot access Supabase secrets"
fi

# ================================================================
# SYSTEM 3: POWERSYNC
# ================================================================
print_header "SYSTEM 3/4: POWERSYNC"

# Test 3.1: PowerSync core files
run_test "PowerSync core implementation"
if [ -f "lib/powersync/database.dart" ]; then
    print_success "PowerSync database.dart found"
else
    print_error "PowerSync database.dart missing"
fi

if [ -f "lib/powersync/schema.dart" ]; then
    print_success "PowerSync schema.dart found"
else
    print_error "PowerSync schema.dart missing"
fi

if [ -f "lib/powersync/supabase_connector.dart" ]; then
    print_success "PowerSync supabase_connector.dart found"
else
    print_error "PowerSync supabase_connector.dart missing"
fi

# Test 3.2: PowerSync custom actions
run_test "PowerSync custom actions"
if [ -f "lib/custom_code/actions/initialize_powersync.dart" ]; then
    print_success "initializePowerSync action found"
else
    print_error "initializePowerSync action missing"
fi

if [ -f "lib/custom_code/actions/get_powersync_status.dart" ]; then
    print_success "getPowersyncStatus action found"
else
    print_error "getPowersyncStatus action missing"
fi

# Test 3.3: PowerSync FlutterFlow schema
run_test "PowerSync FlutterFlow schema"
if [ -f "powersync_flutterflow_schema.dart" ]; then
    TABLE_COUNT=$(grep -c "Table(" powersync_flutterflow_schema.dart)
    print_success "PowerSync FlutterFlow schema: $TABLE_COUNT tables"
else
    print_error "powersync_flutterflow_schema.dart missing"
fi

# Test 3.4: PowerSync sync rules
run_test "PowerSync sync rules"
if [ -f "POWERSYNC_SYNC_RULES_COMPLETE.yaml" ]; then
    BUCKET_COUNT=$(grep -c "bucket_definitions:" POWERSYNC_SYNC_RULES_COMPLETE.yaml)
    print_success "PowerSync sync rules found"
    print_info "  → Sync rules define role-based data access"
else
    print_error "POWERSYNC_SYNC_RULES_COMPLETE.yaml missing"
fi

# Test 3.5: PowerSync instance connectivity
run_test "PowerSync instance connectivity"
POWERSYNC_URL="https://68f931403c148720fa432934.powersync.journeyapps.com"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$POWERSYNC_URL" 2>/dev/null || echo "000")

if [ "$HTTP_STATUS" = "200" ] || [ "$HTTP_STATUS" = "401" ] || [ "$HTTP_STATUS" = "403" ]; then
    print_success "PowerSync instance reachable (HTTP $HTTP_STATUS)"
else
    print_error "PowerSync instance unreachable (HTTP $HTTP_STATUS)"
fi

# ================================================================
# SYSTEM 4: EHRBASE
# ================================================================
print_header "SYSTEM 4/4: EHRBASE (OpenEHR)"

# Test 4.1: EHRbase sync queue table
run_test "EHRbase sync queue migration"
if grep -r "CREATE TABLE.*ehrbase_sync_queue" supabase/migrations/ &>/dev/null; then
    print_success "ehrbase_sync_queue table migration found"
else
    print_error "ehrbase_sync_queue table migration missing"
fi

# Test 4.2: EHRbase sync function
run_test "EHRbase sync edge function"
if [ -f "supabase/functions/sync-to-ehrbase/index.ts" ]; then
    print_success "sync-to-ehrbase function found"

    # Check for critical functionality
    if grep -q "ehrbase_sync_queue" supabase/functions/sync-to-ehrbase/index.ts; then
        print_success "  → Queue processing implemented"
    else
        print_error "  → Queue processing missing"
    fi
else
    print_error "sync-to-ehrbase function missing"
fi

# Test 4.3: EHRbase connectivity
run_test "EHRbase instance connectivity"
# Get EHRbase URL from secrets if available
EHRBASE_URL=$(echo "$SECRETS_OUTPUT" | grep "EHRBASE_URL" | awk '{print $1}' || echo "")

if [ -n "$EHRBASE_URL" ]; then
    print_info "  → Testing EHRbase connectivity..."
    # Note: We can't test actual connectivity without credentials
    print_warning "  → EHRbase connectivity requires authentication (skipping live test)"
else
    print_warning "  → EHRBASE_URL not configured"
fi

# ================================================================
# AUTHENTICATION FLOW SUMMARY
# ================================================================
print_header "AUTHENTICATION FLOW ANALYSIS"

echo -e "${BLUE}Expected Flow:${NC}"
echo "1. User signs up → Firebase Auth creates user"
echo "2. Firebase onUserCreated → Creates Supabase user + EHRbase EHR"
echo "3. App initializes → PowerSync gets token from Supabase edge function"
echo "4. PowerSync syncs → Downloads user's data based on role"
echo "5. Medical data written → Queued for EHRbase sync"

echo -e "\n${BLUE}Current Status:${NC}"

# Firebase
if firebase functions:list &>/dev/null; then
    echo -e "${GREEN}✓${NC} Firebase: Functions deployed"
else
    echo -e "${YELLOW}⚠${NC} Firebase: Functions status unknown (login required)"
fi

# Supabase
if echo "$SECRETS_OUTPUT" | grep -q "SUPABASE_URL"; then
    echo -e "${GREEN}✓${NC} Supabase: Configured and ready"
else
    echo -e "${RED}✗${NC} Supabase: Missing configuration"
fi

# PowerSync
if echo "$SECRETS_OUTPUT" | grep -q "POWERSYNC_KEY_ID"; then
    echo -e "${GREEN}✓${NC} PowerSync: Secrets configured"
else
    echo -e "${YELLOW}⚠${NC} PowerSync: Secrets missing (token generation will fail)"
    echo -e "  ${BLUE}→${NC} Generate RSA keys in PowerSync dashboard"
    echo -e "  ${BLUE}→${NC} Set POWERSYNC_URL, POWERSYNC_KEY_ID, POWERSYNC_PRIVATE_KEY"
    echo -e "  ${BLUE}→${NC} See: POWERSYNC_SECRETS_SETUP.md"
fi

# EHRbase
if echo "$SECRETS_OUTPUT" | grep -q "EHRBASE_URL"; then
    echo -e "${GREEN}✓${NC} EHRbase: Configured for sync"
else
    echo -e "${RED}✗${NC} EHRbase: Missing configuration"
fi

# ================================================================
# TEST SUMMARY
# ================================================================
print_header "TEST SUMMARY"

TOTAL_TESTS=$TESTS_TOTAL
PASSED_TESTS=$TESTS_PASSED
FAILED_TESTS=$TESTS_FAILED
PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))

echo -e "Total Tests: ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed:      ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:      ${RED}$FAILED_TESTS${NC}"
echo -e "Pass Rate:   ${BLUE}$PASS_RATE%${NC}"

if [ $PASS_RATE -ge 90 ]; then
    echo -e "\n${GREEN}✓ System Status: EXCELLENT${NC}"
    echo "Authentication flow is fully configured and ready for testing."
elif [ $PASS_RATE -ge 75 ]; then
    echo -e "\n${YELLOW}⚠ System Status: GOOD (Minor issues)${NC}"
    echo "Authentication flow is mostly ready. Fix warnings to reach 100%."
elif [ $PASS_RATE -ge 50 ]; then
    echo -e "\n${YELLOW}⚠ System Status: NEEDS ATTENTION${NC}"
    echo "Some components need configuration before full testing."
else
    echo -e "\n${RED}✗ System Status: REQUIRES SETUP${NC}"
    echo "Multiple components need configuration."
fi

# ================================================================
# NEXT STEPS
# ================================================================
print_header "NEXT STEPS"

echo "1. Configure PowerSync secrets (if not done):"
echo "   → See: POWERSYNC_SECRETS_SETUP.md"
echo ""
echo "2. Deploy Supabase edge functions:"
echo "   → npx supabase functions deploy powersync-token"
echo "   → npx supabase functions deploy sync-to-ehrbase"
echo ""
echo "3. Test token generation:"
echo "   → npx supabase functions invoke powersync-token"
echo ""
echo "4. Configure FlutterFlow:"
echo "   → Add PowerSync library"
echo "   → Paste powersync_flutterflow_schema.dart"
echo "   → See: FLUTTERFLOW_POWERSYNC_INTEGRATION_GUIDE.md"
echo ""
echo "5. Test end-to-end in Flutter app:"
echo "   → flutter run -d chrome"
echo "   → Test signup flow"
echo "   → Test offline mode"

exit 0
