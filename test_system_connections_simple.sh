#!/bin/bash

# ================================================================
# MedZen-Iwani System Connection Test Script (Simplified)
# Tests all 4 systems in the required initialization order
# ================================================================

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

echo "========================================"
echo "MEDZEN-IWANI SYSTEM CONNECTION TESTS"
echo "========================================"
echo ""

# Helper functions
test_passed() {
    echo "✓ PASS: $1"
    ((TESTS_PASSED++))
    ((TESTS_TOTAL++))
}

test_failed() {
    echo "✗ FAIL: $1"
    ((TESTS_FAILED++))
    ((TESTS_TOTAL++))
}

test_info() {
    echo "  ℹ Info: $1"
}

# ================================================================
# 1. FIREBASE TESTS
# ================================================================
echo "========================================"
echo "SYSTEM 1/4: FIREBASE"
echo "========================================"
echo ""

# Test Firebase CLI
if command -v firebase &> /dev/null; then
    FIREBASE_VERSION=$(firebase --version)
    test_passed "Firebase CLI installed: $FIREBASE_VERSION"
else
    test_failed "Firebase CLI not installed"
fi

# Test Firebase config
if [ -f "firebase/firebase.json" ]; then
    test_passed "firebase.json found"
else
    test_failed "firebase.json not found"
fi

# Test Firebase Functions
if [ -f "firebase/functions/index.js" ]; then
    test_passed "Firebase Functions index.js found"

    if grep -q "onUserCreated" firebase/functions/index.js; then
        test_passed "onUserCreated function exists"
    else
        test_failed "onUserCreated function not found"
    fi

    if grep -q "onUserDeleted" firebase/functions/index.js; then
        test_passed "onUserDeleted function exists"
    else
        test_failed "onUserDeleted function not found"
    fi
else
    test_failed "Firebase Functions index.js not found"
fi

# Test Firebase Flutter config
if [ -f "lib/backend/firebase/firebase_config.dart" ]; then
    test_passed "Firebase Flutter configuration found"
else
    test_failed "Firebase Flutter configuration not found"
fi

echo ""

# ================================================================
# 2. SUPABASE TESTS
# ================================================================
echo "========================================"
echo "SYSTEM 2/4: SUPABASE"
echo "========================================"
echo ""

# Test Supabase CLI
if command -v supabase &> /dev/null; then
    SUPABASE_VERSION=$(supabase --version)
    test_passed "Supabase CLI installed: $SUPABASE_VERSION"
else
    test_failed "Supabase CLI not installed"
fi

# Test Supabase config
if [ -f "supabase/config.toml" ]; then
    test_passed "supabase/config.toml found"
else
    test_failed "supabase/config.toml not found"
fi

# Test Supabase Flutter config
if [ -f "lib/backend/supabase/supabase.dart" ]; then
    test_passed "Supabase Flutter configuration found"

    SUPABASE_URL=$(grep '_kSupabaseUrl' lib/backend/supabase/supabase.dart | cut -d"'" -f2)
    if [ -n "$SUPABASE_URL" ]; then
        PROJECT_ID=$(echo "$SUPABASE_URL" | sed -n 's|.*://\([^.]*\)\.supabase\.co.*|\1|p')
        test_passed "Supabase project: $PROJECT_ID"
    else
        test_failed "Supabase URL not configured"
    fi

    if grep -q '_kSupabaseAnonKey' lib/backend/supabase/supabase.dart; then
        test_passed "Supabase anon key configured"
    else
        test_failed "Supabase anon key not configured"
    fi
else
    test_failed "Supabase Flutter configuration not found"
fi

# Test Supabase migrations
if [ -d "supabase/migrations" ]; then
    MIGRATION_COUNT=$(ls -1 supabase/migrations/*.sql 2>/dev/null | wc -l | tr -d ' ')
    test_passed "Found $MIGRATION_COUNT database migration(s)"
else
    test_failed "Supabase migrations directory not found"
fi

# Test Edge Functions
if [ -d "supabase/functions/powersync-token" ]; then
    test_passed "powersync-token edge function found"
else
    test_failed "powersync-token edge function not found"
fi

if [ -d "supabase/functions/sync-to-ehrbase" ]; then
    test_passed "sync-to-ehrbase edge function found"
else
    test_failed "sync-to-ehrbase edge function not found"
fi

echo ""

# ================================================================
# 3. POWERSYNC TESTS
# ================================================================
echo "========================================"
echo "SYSTEM 3/4: POWERSYNC"
echo "========================================"
echo ""

# Test PowerSync sync rules
if [ -f "POWERSYNC_SYNC_RULES.yaml" ]; then
    test_passed "POWERSYNC_SYNC_RULES.yaml found"
else
    test_failed "POWERSYNC_SYNC_RULES.yaml not found"
fi

# Test PowerSync Flutter implementation
if [ -d "lib/powersync" ]; then
    test_passed "PowerSync directory exists"

    if [ -f "lib/powersync/database.dart" ]; then
        test_passed "PowerSync database.dart found"
    else
        test_failed "PowerSync database.dart not found"
    fi

    if [ -f "lib/powersync/schema.dart" ]; then
        test_passed "PowerSync schema.dart found"
    else
        test_failed "PowerSync schema.dart not found"
    fi

    if [ -f "lib/powersync/supabase_connector.dart" ]; then
        test_passed "PowerSync supabase_connector.dart found"
    else
        test_failed "PowerSync supabase_connector.dart not found"
    fi
else
    test_failed "PowerSync directory not found (not implemented yet)"
fi

# Test PowerSync dependencies
if [ -f "pubspec.yaml" ]; then
    if grep -q "powersync" pubspec.yaml; then
        test_passed "PowerSync dependencies in pubspec.yaml"
    else
        test_failed "PowerSync dependencies not in pubspec.yaml"
    fi
else
    test_failed "pubspec.yaml not found"
fi

echo ""

# ================================================================
# 4. EHRBASE/OPENEHR TESTS
# ================================================================
echo "========================================"
echo "SYSTEM 4/4: EHRBASE/OPENEHR"
echo "========================================"
echo ""

# Test ehrbase_sync_queue
if grep -r "ehrbase_sync_queue" supabase/migrations/ >/dev/null 2>&1; then
    test_passed "ehrbase_sync_queue table found"
else
    test_failed "ehrbase_sync_queue table not found"
fi

# Test sync-to-ehrbase function
if [ -f "supabase/functions/sync-to-ehrbase/index.ts" ]; then
    test_passed "sync-to-ehrbase edge function found"

    if grep -q "composition" supabase/functions/sync-to-ehrbase/index.ts; then
        test_passed "OpenEHR composition handling exists"
    else
        test_failed "OpenEHR composition handling not found"
    fi
else
    test_failed "sync-to-ehrbase function not found"
fi

# Test EHR creation in Firebase
if [ -f "firebase/functions/index.js" ]; then
    if grep -q "ehrbase" firebase/functions/index.js; then
        test_passed "EHRbase integration in Firebase function"
    else
        test_failed "EHRbase integration not in Firebase function"
    fi
fi

# Test electronic_health_records table
if grep -r "electronic_health_records" supabase/migrations/ >/dev/null 2>&1; then
    test_passed "electronic_health_records table found"
else
    test_failed "electronic_health_records table not found"
fi

# Test medical data tables
FOUND=0
for table in vital_signs lab_results prescriptions immunizations; do
    if grep -r "CREATE TABLE.*$table" supabase/migrations/ >/dev/null 2>&1; then
        ((FOUND++))
    fi
done
if [ $FOUND -eq 4 ]; then
    test_passed "All 4 medical data tables found"
else
    test_failed "Some medical data tables missing ($FOUND/4)"
fi

echo ""

# ================================================================
# 5. INITIALIZATION ORDER
# ================================================================
echo "========================================"
echo "INITIALIZATION ORDER CHECK"
echo "========================================"
echo ""

if [ -f "lib/main.dart" ]; then
    test_passed "main.dart found"

    if grep -q "Firebase" lib/main.dart && grep -q "Supabase" lib/main.dart; then
        test_passed "Firebase and Supabase init found"
    else
        test_failed "Missing Firebase/Supabase init"
    fi
else
    test_failed "main.dart not found"
fi

if [ -f "lib/app_state.dart" ]; then
    test_passed "app_state.dart found"

    if grep -q "UserRole" lib/app_state.dart; then
        test_passed "UserRole state management found"
    else
        test_failed "UserRole state not found"
    fi
else
    test_failed "app_state.dart not found"
fi

echo ""

# ================================================================
# SUMMARY
# ================================================================
echo "========================================"
echo "TEST SUMMARY"
echo "========================================"
echo ""
echo "Total Tests: $TESTS_TOTAL"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "✓ ALL TESTS PASSED!"
    echo "All 4 systems are properly configured."
    exit 0
else
    PASS_RATE=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    echo "⚠ $TESTS_FAILED TEST(S) FAILED"
    echo "Pass rate: $PASS_RATE%"
    echo ""
    echo "Please review failed tests above."
    exit 1
fi
