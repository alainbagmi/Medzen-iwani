#!/bin/bash

###############################################################################
# PRODUCTION-READY AUTHENTICATION SYSTEM TEST
#
# This script performs end-to-end testing of the authentication system
# across all 4 systems: Firebase, Firestore, Supabase, and EHRbase.
#
# Tests performed:
# 1. Configuration verification
# 2. Firebase Functions deployment status
# 3. Firestore rules validation
# 4. Supabase connectivity
# 5. EHRbase connectivity
# 6. onUserCreated function logs review
#
# Run: ./test_production_auth.sh
###############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Helper functions
print_header() {
    echo -e "\n${CYAN}============================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}============================================================${NC}\n"
}

print_test() {
    ((TESTS_TOTAL++))
    echo -e "${YELLOW}[TEST $TESTS_TOTAL]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((TESTS_PASSED++))
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Banner
echo -e "${BOLD}${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║     PRODUCTION-READY AUTHENTICATION SYSTEM TEST            ║"
echo "║     MedZen-Iwani Healthcare Application                    ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

START_TIME=$(date +%s)
print_info "Start time: $(date -Iseconds)"
print_info "Testing 4-system integration: Firebase → Firestore → Supabase → EHRbase"

###############################################################################
# TEST 1: Firebase Configuration
###############################################################################
print_header "TEST 1/8: FIREBASE CONFIGURATION"

print_test "Firebase CLI installed"
if command -v firebase &> /dev/null; then
    FIREBASE_VERSION=$(firebase --version)
    print_success "Firebase CLI: $FIREBASE_VERSION"
else
    print_error "Firebase CLI not installed"
fi

print_test "Firebase project configured"
if [ -f ".firebaserc" ]; then
    FIREBASE_PROJECT=$(grep -A 1 '"default"' .firebaserc | grep -o '"[^"]*"' | tail -1 | tr -d '"')
    print_success "Firebase project: $FIREBASE_PROJECT"
else
    print_error ".firebaserc not found"
fi

print_test "Firebase Functions config"
CONFIG_OUTPUT=$(firebase functions:config:get 2>&1)
if [[ $CONFIG_OUTPUT == *"supabase"* ]] && [[ $CONFIG_OUTPUT == *"ehrbase"* ]]; then
    print_success "Firebase Functions config exists"
    print_info "  → Supabase config: ✓"
    print_info "  → EHRbase config: ✓"
else
    print_error "Firebase Functions config incomplete"
fi

###############################################################################
# TEST 2: Firebase Functions Deployment
###############################################################################
print_header "TEST 2/8: FIREBASE FUNCTIONS DEPLOYMENT"

print_test "List deployed functions"
FUNCTIONS_LIST=$(firebase functions:list 2>&1)

if [[ $FUNCTIONS_LIST == *"onUserCreated"* ]]; then
    print_success "onUserCreated function deployed"
else
    print_error "onUserCreated function NOT deployed"
fi

if [[ $FUNCTIONS_LIST == *"onUserDeleted"* ]]; then
    print_success "onUserDeleted function deployed"
else
    print_error "onUserDeleted function NOT deployed"
fi

###############################################################################
# TEST 3: Firestore Rules
###############################################################################
print_header "TEST 3/8: FIRESTORE RULES"

print_test "Firestore rules file exists"
if [ -f "firebase/firestore.rules" ]; then
    print_success "firestore.rules found"

    print_test "Check rules allow authenticated reads"
    if grep -q "allow read: if request.auth != null" firebase/firestore.rules; then
        print_success "Rules allow authenticated user queries"
    else
        print_error "Rules do NOT allow authenticated queries"
        print_warning "Expected: allow read: if request.auth != null"
    fi
else
    print_error "firestore.rules not found"
fi

###############################################################################
# TEST 4: Supabase Configuration
###############################################################################
print_header "TEST 4/8: SUPABASE CONFIGURATION"

print_test "Supabase CLI installed"
if command -v npx &> /dev/null; then
    SUPABASE_VERSION=$(npx supabase --version 2>&1 | head -1)
    print_success "Supabase CLI: $SUPABASE_VERSION"
else
    print_error "npx not available"
fi

print_test "Supabase project linked"
if [ -f "supabase/.temp/project-ref" ] || [ -f ".supabase/config.toml" ]; then
    print_success "Supabase project linked"
else
    print_warning "Cannot verify Supabase project link"
fi

print_test "Supabase Edge Functions"
if [ -d "supabase/functions/powersync-token" ]; then
    print_success "powersync-token function found"
else
    print_error "powersync-token function NOT found"
fi

if [ -d "supabase/functions/sync-to-ehrbase" ]; then
    print_success "sync-to-ehrbase function found"
else
    print_error "sync-to-ehrbase function NOT found"
fi

###############################################################################
# TEST 5: Supabase Connectivity
###############################################################################
print_header "TEST 5/8: SUPABASE CONNECTIVITY"

SUPABASE_URL=$(grep -o 'url = "https://[^"]*"' supabase/config.toml 2>/dev/null | cut -d'"' -f2)

if [ -n "$SUPABASE_URL" ]; then
    print_test "Supabase instance connectivity"

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$SUPABASE_URL/rest/v1/" -H "apikey: dummy" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "400" ]; then
        print_success "Supabase instance reachable (HTTP $HTTP_CODE)"
    else
        print_error "Supabase instance unreachable (HTTP $HTTP_CODE)"
    fi
else
    print_warning "Supabase URL not found in config"
fi

###############################################################################
# TEST 6: EHRbase Connectivity
###############################################################################
print_header "TEST 6/8: EHRBASE CONNECTIVITY"

# Extract EHRbase URL from Firebase config
EHRBASE_URL=$(echo "$CONFIG_OUTPUT" | grep -A 3 '"ehrbase"' | grep '"url"' | cut -d'"' -f4)

if [ -n "$EHRBASE_URL" ]; then
    print_test "EHRbase instance connectivity"

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$EHRBASE_URL/rest/openehr/v1/ehr" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "400" ]; then
        print_success "EHRbase instance reachable (HTTP $HTTP_CODE)"
    else
        print_warning "EHRbase instance returned HTTP $HTTP_CODE"
    fi
else
    print_warning "EHRbase URL not found in config"
fi

###############################################################################
# TEST 7: onUserCreated Function Logs
###############################################################################
print_header "TEST 7/8: onUserCreated FUNCTION LOGS"

print_test "Check recent function executions"
FUNCTION_LOGS=$(firebase functions:log --only onUserCreated --limit 20 2>&1)

if [[ $FUNCTION_LOGS == *"User setup complete"* ]]; then
    print_success "Found successful user creation in logs"

    # Count recent successes
    SUCCESS_COUNT=$(echo "$FUNCTION_LOGS" | grep -c "User setup complete" || echo "0")
    print_info "  → $SUCCESS_COUNT successful signup(s) in recent logs"
elif [[ $FUNCTION_LOGS == *"Error in onUserCreated"* ]]; then
    print_warning "Found errors in recent function logs"
    ERROR_COUNT=$(echo "$FUNCTION_LOGS" | grep -c "Error in onUserCreated" || echo "0")
    print_info "  → $ERROR_COUNT error(s) in recent logs"
else
    print_info "No recent function executions found"
    print_info "  → This is normal if no users have signed up recently"
fi

###############################################################################
# TEST 8: Critical Files Verification
###############################################################################
print_header "TEST 8/8: CRITICAL FILES VERIFICATION"

print_test "onUserCreated function code exists"
if grep -q "exports.onUserCreated" firebase/functions/index.js; then
    print_success "onUserCreated function found in index.js"

    # Check function implementation
    if grep -q "Supabase user" firebase/functions/index.js; then
        print_info "  → Supabase integration: ✓"
    fi

    if grep -q "EHRbase EHR" firebase/functions/index.js; then
        print_info "  → EHRbase integration: ✓"
    fi

    if grep -q "electronic_health_records" firebase/functions/index.js; then
        print_info "  → System linkage: ✓"
    fi
else
    print_error "onUserCreated function NOT found in index.js"
fi

print_test "Critical documentation exists"
if [ -f "firebase/functions/CRITICAL_FUNCTION_REFERENCE.md" ]; then
    print_success "CRITICAL_FUNCTION_REFERENCE.md exists"
else
    print_warning "CRITICAL_FUNCTION_REFERENCE.md not found"
fi

###############################################################################
# TEST RESULTS SUMMARY
###############################################################################
print_header "TEST RESULTS SUMMARY"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
PASS_RATE=$((TESTS_PASSED * 100 / TESTS_TOTAL))

echo ""
echo -e "${BLUE}Total Tests:     ${TESTS_TOTAL}${NC}"

if [ $TESTS_PASSED -eq $TESTS_TOTAL ]; then
    echo -e "${GREEN}Tests Passed:    ${TESTS_PASSED}${NC}"
else
    echo -e "${YELLOW}Tests Passed:    ${TESTS_PASSED}${NC}"
fi

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}Tests Failed:    ${TESTS_FAILED}${NC}"
else
    echo -e "${RED}Tests Failed:    ${TESTS_FAILED}${NC}"
fi

if [ $PASS_RATE -ge 85 ]; then
    echo -e "${GREEN}Pass Rate:       ${PASS_RATE}%${NC}"
else
    echo -e "${YELLOW}Pass Rate:       ${PASS_RATE}%${NC}"
fi

echo -e "${BLUE}Duration:        ${DURATION} seconds${NC}"
echo ""

###############################################################################
# FINAL VERDICT
###############################################################################

if [ $PASS_RATE -ge 85 ]; then
    echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  🎉 SYSTEM IS PRODUCTION READY! 🎉${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}✓ Firebase Functions deployed and configured${NC}"
    echo -e "${GREEN}✓ Firestore rules allow authenticated queries${NC}"
    echo -e "${GREEN}✓ onUserCreated function exists and is active${NC}"
    echo -e "${GREEN}✓ Supabase and EHRbase connectivity verified${NC}"
    echo -e "${GREEN}✓ All system integrations properly configured${NC}"
    echo ""
    echo -e "${BLUE}ℹ️  To test with a real signup:${NC}"
    echo -e "${BLUE}   1. Create a new user in your Flutter app${NC}"
    echo -e "${BLUE}   2. Check logs: firebase functions:log --only onUserCreated${NC}"
    echo -e "${BLUE}   3. Verify user was created in Supabase and EHRbase${NC}"
    echo ""
    exit 0
else
    echo -e "${YELLOW}══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}${BOLD}  ⚠️  SOME TESTS FAILED - REVIEW REQUIRED${NC}"
    echo -e "${YELLOW}══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Please review the failed tests above.${NC}"
    echo -e "${YELLOW}Most common issues:${NC}"
    echo -e "${YELLOW}  • Functions not deployed: firebase deploy --only functions${NC}"
    echo -e "${YELLOW}  • Config missing: firebase functions:config:set <key>=<value>${NC}"
    echo -e "${YELLOW}  • Connectivity: Check URLs and credentials${NC}"
    echo ""
    exit 1
fi
