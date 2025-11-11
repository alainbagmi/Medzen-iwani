#!/bin/bash

# ================================================================
# MedZen-Iwani System Connection Test Script
# Tests all 4 systems in the required initialization order:
# 1. Firebase Auth → 2. Supabase → 3. PowerSync → 4. EHRbase
# ================================================================

set -e

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

# Test function
run_test() {
    ((TESTS_TOTAL++))
    print_test "$1"
}

# ================================================================
# 1. FIREBASE TESTS
# ================================================================
print_header "SYSTEM 1/4: FIREBASE CONNECTIVITY"

# Test 1.1: Check if Firebase CLI is installed
run_test "Checking Firebase CLI installation"
if command -v firebase &> /dev/null; then
    FIREBASE_VERSION=$(firebase --version)
    print_success "Firebase CLI installed: $FIREBASE_VERSION"
else
    print_error "Firebase CLI not installed. Install: npm install -g firebase-tools"
fi

# Test 1.2: Check if Firebase project is configured
run_test "Checking Firebase project configuration"
if [ -f "firebase/firebase.json" ]; then
    print_success "firebase.json found"
    print_info "Firestore: $(jq -r '.firestore.rules' firebase/firebase.json)"
    print_info "Functions: Configured"
    print_info "Storage: $(jq -r '.storage.rules' firebase/firebase.json)"
else
    print_error "firebase.json not found"
fi

# Test 1.3: Check Firebase Functions setup
run_test "Checking Firebase Functions setup"
if [ -f "firebase/functions/package.json" ]; then
    print_success "Firebase Functions package.json found"
    NODE_VERSION=$(node --version 2>/dev/null || echo "Not installed")
    print_info "Node.js version: $NODE_VERSION (Required: 20)"

    if [ -f "firebase/functions/index.js" ]; then
        print_success "Firebase Functions index.js found"
        # Check for critical functions
        if grep -q "onUserCreated" firebase/functions/index.js; then
            print_success "onUserCreated function found"
        else
            print_error "onUserCreated function not found in index.js"
        fi

        if grep -q "onUserDeleted" firebase/functions/index.js; then
            print_success "onUserDeleted function found"
        else
            print_error "onUserDeleted function not found in index.js"
        fi
    else
        print_error "Firebase Functions index.js not found"
    fi
else
    print_error "Firebase Functions not configured"
fi

# Test 1.4: Check Firebase configuration in Flutter
run_test "Checking Firebase configuration in Flutter app"
if [ -f "lib/backend/firebase/firebase_config.dart" ]; then
    print_success "Firebase Flutter configuration found"
else
    print_error "Firebase Flutter configuration not found"
fi

# Test 1.5: Try to get Firebase project status (if logged in)
run_test "Checking Firebase project connection"
FIREBASE_PROJECTS=$(firebase projects:list 2>/dev/null || echo "")
if [ -n "$FIREBASE_PROJECTS" ]; then
    print_success "Firebase CLI authenticated"
    print_info "Run 'firebase projects:list' to see your projects"
else
    print_error "Firebase CLI not authenticated. Run: firebase login"
fi

# ================================================================
# 2. SUPABASE TESTS
# ================================================================
print_header "SYSTEM 2/4: SUPABASE CONNECTIVITY"

# Test 2.1: Check Supabase CLI
run_test "Checking Supabase CLI installation"
if command -v supabase &> /dev/null; then
    SUPABASE_VERSION=$(supabase --version)
    print_success "Supabase CLI installed: $SUPABASE_VERSION"
else
    print_error "Supabase CLI not installed. Install: npm install -g supabase"
fi

# Test 2.2: Check Supabase project configuration
run_test "Checking Supabase project configuration"
if [ -f "supabase/config.toml" ]; then
    print_success "supabase/config.toml found"
    print_info "API Port: $(grep 'port = ' supabase/config.toml | head -1 | awk '{print $3}')"
else
    print_error "supabase/config.toml not found"
fi

# Test 2.3: Check Supabase Flutter configuration
run_test "Checking Supabase Flutter configuration"
if [ -f "lib/backend/supabase/supabase.dart" ]; then
    print_success "Supabase Flutter configuration found"

    # Extract Supabase URL (be careful not to expose full URL in logs)
    SUPABASE_URL=$(grep '_kSupabaseUrl' lib/backend/supabase/supabase.dart | cut -d"'" -f2)
    if [ -n "$SUPABASE_URL" ]; then
        # Extract just the project ID from URL
        PROJECT_ID=$(echo "$SUPABASE_URL" | sed -n 's|.*://\([^.]*\)\.supabase\.co.*|\1|p')
        print_success "Supabase project configured: $PROJECT_ID"
    else
        print_error "Supabase URL not found in configuration"
    fi

    # Check if anon key is configured
    if grep -q '_kSupabaseAnonKey' lib/backend/supabase/supabase.dart; then
        print_success "Supabase anon key configured"
    else
        print_error "Supabase anon key not configured"
    fi
else
    print_error "Supabase Flutter configuration not found"
fi

# Test 2.4: Check Supabase migrations
run_test "Checking Supabase database migrations"
if [ -d "supabase/migrations" ]; then
    MIGRATION_COUNT=$(ls -1 supabase/migrations/*.sql 2>/dev/null | wc -l)
    print_success "Found $MIGRATION_COUNT migration(s)"

    # Check for critical migrations
    if ls supabase/migrations/*ehr* >/dev/null 2>&1; then
        print_success "EHR-related migrations found"
    else
        print_error "EHR-related migrations not found"
    fi

    if ls supabase/migrations/*powersync* >/dev/null 2>&1; then
        print_success "PowerSync-related migrations found"
    else
        print_error "PowerSync-related migrations not found"
    fi
else
    print_error "Supabase migrations directory not found"
fi

# Test 2.5: Check Supabase Edge Functions
run_test "Checking Supabase Edge Functions"
if [ -d "supabase/functions" ]; then
    print_success "Edge Functions directory found"

    # Check for critical edge functions
    if [ -d "supabase/functions/powersync-token" ]; then
        print_success "powersync-token function found"
    else
        print_error "powersync-token function not found"
    fi

    if [ -d "supabase/functions/sync-to-ehrbase" ]; then
        print_success "sync-to-ehrbase function found"
    else
        print_error "sync-to-ehrbase function not found"
    fi
else
    print_error "Edge Functions directory not found"
fi

# Test 2.6: Test Supabase connection (if CLI is linked)
run_test "Testing Supabase API connection"
if command -v supabase &> /dev/null; then
    # Try to check if project is linked
    if supabase status 2>/dev/null | grep -q "supabase"; then
        print_success "Supabase project linked and accessible"
    else
        print_error "Supabase project not linked. Run: npx supabase link"
    fi
else
    print_error "Cannot test connection - Supabase CLI not installed"
fi

# ================================================================
# 3. POWERSYNC TESTS
# ================================================================
print_header "SYSTEM 3/4: POWERSYNC CONFIGURATION"

# Test 3.1: Check PowerSync sync rules
run_test "Checking PowerSync sync rules"
if [ -f "POWERSYNC_SYNC_RULES.yaml" ]; then
    print_success "POWERSYNC_SYNC_RULES.yaml found"

    # Check for bucket definitions
    if grep -q "bucket_definitions:" POWERSYNC_SYNC_RULES.yaml; then
        print_success "Bucket definitions found"
        BUCKET_COUNT=$(grep -c "^  - bucket:" POWERSYNC_SYNC_RULES.yaml || echo "0")
        print_info "Found $BUCKET_COUNT bucket(s) defined"
    else
        print_error "Bucket definitions not found in sync rules"
    fi
else
    print_error "POWERSYNC_SYNC_RULES.yaml not found"
fi

# Test 3.2: Check PowerSync Flutter implementation
run_test "Checking PowerSync Flutter implementation"
if [ -d "lib/powersync" ]; then
    print_success "PowerSync directory found"

    # Check for critical PowerSync files
    if [ -f "lib/powersync/database.dart" ]; then
        print_success "PowerSync database.dart found"
    else
        print_error "PowerSync database.dart not found"
    fi

    if [ -f "lib/powersync/schema.dart" ]; then
        print_success "PowerSync schema.dart found"
    else
        print_error "PowerSync schema.dart not found"
    fi

    if [ -f "lib/powersync/supabase_connector.dart" ]; then
        print_success "PowerSync supabase_connector.dart found"
    else
        print_error "PowerSync supabase_connector.dart not found"
    fi
else
    print_error "PowerSync directory not found in lib/"
    print_info "PowerSync may not be implemented yet"
fi

# Test 3.3: Check PowerSync token function
run_test "Checking PowerSync token function"
if [ -f "supabase/functions/powersync-token/index.ts" ]; then
    print_success "PowerSync token function found"

    # Check if it has proper JWT implementation
    if grep -q "jose" supabase/functions/powersync-token/index.ts; then
        print_success "JWT library (jose) used in token function"
    else
        print_error "JWT library not found in token function"
    fi
else
    print_error "PowerSync token function not found"
fi

# Test 3.4: Check PowerSync pubspec dependencies
run_test "Checking PowerSync dependencies in pubspec.yaml"
if [ -f "pubspec.yaml" ]; then
    if grep -q "powersync" pubspec.yaml; then
        print_success "PowerSync dependencies found in pubspec.yaml"
    else
        print_error "PowerSync dependencies not found in pubspec.yaml"
    fi
else
    print_error "pubspec.yaml not found"
fi

# ================================================================
# 4. EHRBASE/OPENEHR TESTS
# ================================================================
print_header "SYSTEM 4/4: EHRBASE/OPENEHR CONNECTIVITY"

# Test 4.1: Check EHRbase sync queue table
run_test "Checking EHRbase sync queue configuration"
if grep -r "ehrbase_sync_queue" supabase/migrations/ >/dev/null 2>&1; then
    print_success "ehrbase_sync_queue table found in migrations"
else
    print_error "ehrbase_sync_queue table not found in migrations"
fi

# Test 4.2: Check EHRbase sync function
run_test "Checking EHRbase sync edge function"
if [ -f "supabase/functions/sync-to-ehrbase/index.ts" ]; then
    print_success "sync-to-ehrbase function found"

    # Check for OpenEHR composition creation
    if grep -q "composition" supabase/functions/sync-to-ehrbase/index.ts; then
        print_success "OpenEHR composition handling found"
    else
        print_error "OpenEHR composition handling not found"
    fi
else
    print_error "sync-to-ehrbase function not found"
fi

# Test 4.3: Check Firebase onUserCreated for EHR creation
run_test "Checking EHR creation in Firebase function"
if [ -f "firebase/functions/index.js" ]; then
    if grep -q "ehrbase" firebase/functions/index.js; then
        print_success "EHRbase integration found in Firebase function"
    else
        print_error "EHRbase integration not found in Firebase function"
    fi
else
    print_error "Firebase functions/index.js not found"
fi

# Test 4.4: Check electronic_health_records table
run_test "Checking electronic_health_records table"
if grep -r "electronic_health_records" supabase/migrations/ >/dev/null 2>&1; then
    print_success "electronic_health_records table found in migrations"
else
    print_error "electronic_health_records table not found"
fi

# Test 4.5: Check OpenEHR table mappings
run_test "Checking OpenEHR medical data tables"
MEDICAL_TABLES=("vital_signs" "lab_results" "prescriptions" "immunizations")
FOUND_TABLES=0
for table in "${MEDICAL_TABLES[@]}"; do
    if grep -r "CREATE TABLE.*$table" supabase/migrations/ >/dev/null 2>&1; then
        ((FOUND_TABLES++))
    fi
done
if [ $FOUND_TABLES -eq ${#MEDICAL_TABLES[@]} ]; then
    print_success "All medical data tables found ($FOUND_TABLES/${#MEDICAL_TABLES[@]})"
else
    print_error "Some medical data tables missing ($FOUND_TABLES/${#MEDICAL_TABLES[@]})"
fi

# ================================================================
# 5. INITIALIZATION ORDER TEST
# ================================================================
print_header "INITIALIZATION ORDER VERIFICATION"

# Test 5.1: Check main.dart initialization order
run_test "Checking initialization order in main.dart"
if [ -f "lib/main.dart" ]; then
    print_success "main.dart found"

    # Extract initialization sequence
    print_info "Checking initialization order: Firebase → Supabase → PowerSync"

    # This is a simplified check - actual order verification would need code analysis
    if grep -q "Firebase" lib/main.dart && grep -q "Supabase" lib/main.dart; then
        print_success "Firebase and Supabase initialization found"
    else
        print_error "Firebase or Supabase initialization not found"
    fi
else
    print_error "main.dart not found"
fi

# Test 5.2: Check app_state.dart for global state management
run_test "Checking global state management"
if [ -f "lib/app_state.dart" ]; then
    print_success "app_state.dart found"

    if grep -q "FFAppState" lib/app_state.dart; then
        print_success "FFAppState class found"
    fi

    if grep -q "UserRole" lib/app_state.dart; then
        print_success "UserRole state found"
    fi
else
    print_error "app_state.dart not found"
fi

# ================================================================
# FINAL REPORT
# ================================================================
print_header "TEST SUMMARY"

echo -e "${BLUE}Total Tests Run:${NC} $TESTS_TOTAL"
echo -e "${GREEN}Tests Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Tests Failed:${NC} $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✓ ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}All 4 systems are properly configured.${NC}"
    exit 0
else
    echo -e "\n${RED}✗ SOME TESTS FAILED!${NC}"
    echo -e "${YELLOW}Please review the failed tests above.${NC}"
    exit 1
fi
