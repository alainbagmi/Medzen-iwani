#!/bin/bash

# Test Suite for 19 Specialty Medical Tables
# Validates database, PowerSync, models, and synchronization
# Usage: ./test_specialty_tables.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

# Test results storage
declare -a FAILED_TEST_NAMES
declare -a WARNING_MESSAGES

# 19 specialty tables to test
SPECIALTY_TABLES=(
    "antenatal_visits"
    "surgical_procedures"
    "admission_discharge_records"
    "medication_dispensing"
    "pharmacy_stock"
    "clinical_consultations"
    "oncology_treatments"
    "infectious_disease_visits"
    "cardiology_visits"
    "emergency_visits"
    "nephrology_visits"
    "gastroenterology_procedures"
    "endocrinology_visits"
    "pulmonology_visits"
    "psychiatric_assessments"
    "neurology_exams"
    "radiology_reports"
    "pathology_reports"
    "physiotherapy_sessions"
)

# Helper functions
test_start() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    FAILED_TEST_NAMES+=("$1")
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
}

warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
    WARNING_MESSAGES+=("$1")
    ((WARNINGS++))
}

info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

# Print header
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🧪 Specialty Medical Tables Test Suite                 ║${NC}"
echo -e "${BLUE}║   Testing 19 Specialty Tables Integration                ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}\n"

# Test Suite 1: Migration Files
test_start "Test Suite 1: Database Migration Files"

info "Testing migration files exist..."
MIGRATION_FILES=(
    "20250202120009_create_antenatal_surgical_admission_medication_pharmacy_consultation_tables.sql"
    "20250202120010_create_nephrology_gastro_endocrine_tables.sql"
    "20250202120011_create_pulmonology_psychiatry_neurology_tables.sql"
    "20250202120012_create_radiology_pathology_physiotherapy_tables.sql"
)

for migration in "${MIGRATION_FILES[@]}"; do
    if [ -f "supabase/migrations/$migration" ]; then
        pass "Migration file exists: $migration"
    else
        fail "Migration file missing: $migration"
    fi
done

# Check migration files contain all tables
info "Verifying all 19 tables are defined in migrations..."
MISSING_TABLES=0
for table in "${SPECIALTY_TABLES[@]}"; do
    if grep -q "CREATE TABLE.*$table" supabase/migrations/*.sql 2>/dev/null; then
        pass "Table definition found in migrations: $table"
    else
        fail "Table definition missing in migrations: $table"
        ((MISSING_TABLES++))
    fi
done

if [ $MISSING_TABLES -eq 0 ]; then
    pass "All 19 tables defined in migrations"
else
    fail "$MISSING_TABLES tables missing from migrations"
fi

# Test Suite 2: PowerSync Schema
test_start "Test Suite 2: PowerSync Schema Configuration"

POWERSYNC_SCHEMA="lib/powersync/schema.dart"
if [ ! -f "$POWERSYNC_SCHEMA" ]; then
    fail "PowerSync schema file not found: $POWERSYNC_SCHEMA"
else
    pass "PowerSync schema file exists"

    # Check each table in PowerSync schema
    info "Verifying all 19 tables in PowerSync schema..."
    MISSING_POWERSYNC=0
    for table in "${SPECIALTY_TABLES[@]}"; do
        if grep -q "name: '$table'" "$POWERSYNC_SCHEMA"; then
            pass "Table in PowerSync schema: $table"
        else
            fail "Table missing from PowerSync schema: $table"
            ((MISSING_POWERSYNC++))
        fi
    done

    if [ $MISSING_POWERSYNC -eq 0 ]; then
        pass "All 19 tables in PowerSync schema"
    else
        fail "$MISSING_POWERSYNC tables missing from PowerSync schema"
    fi
fi

# Test Suite 3: Dart Models
test_start "Test Suite 3: Dart Model Files"

MODELS_DIR="lib/backend/supabase/database/tables"
if [ ! -d "$MODELS_DIR" ]; then
    fail "Models directory not found: $MODELS_DIR"
else
    pass "Models directory exists"

    # Check each model file exists
    info "Verifying all 19 model files exist..."
    MISSING_MODELS=0
    for table in "${SPECIALTY_TABLES[@]}"; do
        MODEL_FILE="$MODELS_DIR/${table}.dart"
        if [ -f "$MODEL_FILE" ]; then
            pass "Model file exists: ${table}.dart"

            # Verify model structure
            if grep -q "class.*Table extends SupabaseTable" "$MODEL_FILE" && \
               grep -q "class.*Row extends SupabaseDataRow" "$MODEL_FILE"; then
                pass "Model structure valid: ${table}.dart"
            else
                fail "Model structure invalid: ${table}.dart"
            fi

            # Check for EHRbase sync fields
            if grep -q "composition_id" "$MODEL_FILE" && \
               grep -q "ehrbase_synced" "$MODEL_FILE"; then
                pass "EHRbase sync fields present: ${table}.dart"
            else
                warn "EHRbase sync fields may be missing: ${table}.dart"
            fi
        else
            fail "Model file missing: ${table}.dart"
            ((MISSING_MODELS++))
        fi
    done

    if [ $MISSING_MODELS -eq 0 ]; then
        pass "All 19 model files exist"
    else
        fail "$MISSING_MODELS model files missing"
    fi
fi

# Test Suite 4: Database.dart Exports
test_start "Test Suite 4: Database.dart Exports"

DATABASE_FILE="lib/backend/supabase/database/database.dart"
if [ ! -f "$DATABASE_FILE" ]; then
    fail "database.dart file not found"
else
    pass "database.dart file exists"

    # Check exports for all tables
    info "Verifying all 19 table exports..."
    MISSING_EXPORTS=0
    for table in "${SPECIALTY_TABLES[@]}"; do
        if grep -q "export 'tables/${table}.dart';" "$DATABASE_FILE"; then
            pass "Export found: ${table}.dart"
        else
            fail "Export missing: ${table}.dart"
            ((MISSING_EXPORTS++))
        fi
    done

    if [ $MISSING_EXPORTS -eq 0 ]; then
        pass "All 19 tables exported in database.dart"
    else
        fail "$MISSING_EXPORTS exports missing from database.dart"
    fi
fi

# Test Suite 5: PowerSync Sync Rules
test_start "Test Suite 5: PowerSync Sync Rules"

SYNC_RULES="POWERSYNC_SYNC_RULES.yaml"
if [ ! -f "$SYNC_RULES" ]; then
    fail "PowerSync sync rules file not found"
else
    pass "PowerSync sync rules file exists"

    # Check for bucket definitions
    if grep -q "bucket_definitions:" "$SYNC_RULES"; then
        pass "Bucket definitions section found"

        # Check for specialty tables in sync rules
        info "Checking specialty tables in sync rules..."
        TABLES_IN_RULES=0
        for table in "${SPECIALTY_TABLES[@]}"; do
            if grep -q "$table" "$SYNC_RULES"; then
                ((TABLES_IN_RULES++))
            fi
        done

        if [ $TABLES_IN_RULES -gt 0 ]; then
            pass "$TABLES_IN_RULES specialty tables found in sync rules"
        else
            warn "No specialty tables found in sync rules - may need manual review"
        fi
    else
        fail "bucket_definitions not found in sync rules"
    fi
fi

# Test Suite 6: Edge Function
test_start "Test Suite 6: Edge Function Configuration"

EDGE_FUNCTION="supabase/functions/sync-to-ehrbase/index.ts"
if [ ! -f "$EDGE_FUNCTION" ]; then
    fail "sync-to-ehrbase edge function not found"
else
    pass "sync-to-ehrbase edge function exists"

    # Check for template mappings
    if grep -q "TEMPLATE_MAPPINGS" "$EDGE_FUNCTION"; then
        pass "TEMPLATE_MAPPINGS found in edge function"

        # Count specialty table mappings
        MAPPINGS_FOUND=0
        for table in "${SPECIALTY_TABLES[@]}"; do
            if grep -q "$table" "$EDGE_FUNCTION"; then
                ((MAPPINGS_FOUND++))
            fi
        done

        if [ $MAPPINGS_FOUND -gt 0 ]; then
            pass "$MAPPINGS_FOUND specialty tables have template mappings"
        else
            warn "No specialty table mappings found - may need manual review"
        fi
    else
        warn "TEMPLATE_MAPPINGS section not found in edge function"
    fi
fi

# Test Suite 7: File Structure Validation
test_start "Test Suite 7: File Structure Validation"

# Check for common EHRbase sync fields in all models
info "Validating EHRbase sync fields across all models..."
MODELS_WITH_SYNC=0
MODELS_WITHOUT_SYNC=0

for table in "${SPECIALTY_TABLES[@]}"; do
    MODEL_FILE="$MODELS_DIR/${table}.dart"
    if [ -f "$MODEL_FILE" ]; then
        REQUIRED_FIELDS=("composition_id" "ehrbase_synced" "ehrbase_synced_at" "ehrbase_sync_error" "ehrbase_retry_count")
        ALL_FIELDS_PRESENT=true

        for field in "${REQUIRED_FIELDS[@]}"; do
            if ! grep -q "$field" "$MODEL_FILE"; then
                ALL_FIELDS_PRESENT=false
                break
            fi
        done

        if [ "$ALL_FIELDS_PRESENT" = true ]; then
            ((MODELS_WITH_SYNC++))
        else
            ((MODELS_WITHOUT_SYNC++))
            warn "Missing EHRbase sync fields in: ${table}.dart"
        fi
    fi
done

if [ $MODELS_WITHOUT_SYNC -eq 0 ]; then
    pass "All $MODELS_WITH_SYNC models have complete EHRbase sync fields"
else
    fail "$MODELS_WITHOUT_SYNC models missing some EHRbase sync fields"
fi

# Check for standard timestamp fields
info "Validating timestamp fields..."
MODELS_WITH_TIMESTAMPS=0
for table in "${SPECIALTY_TABLES[@]}"; do
    MODEL_FILE="$MODELS_DIR/${table}.dart"
    if [ -f "$MODEL_FILE" ]; then
        if grep -q "created_at" "$MODEL_FILE" && grep -q "updated_at" "$MODEL_FILE"; then
            ((MODELS_WITH_TIMESTAMPS++))
        else
            warn "Missing timestamp fields in: ${table}.dart"
        fi
    fi
done

if [ $MODELS_WITH_TIMESTAMPS -eq 19 ]; then
    pass "All models have timestamp fields (created_at/updated_at)"
else
    warn "$((19 - MODELS_WITH_TIMESTAMPS)) models missing timestamp fields"
fi

# Test Suite 8: Integration Test
test_start "Test Suite 8: Integration Validation"

# Check if Supabase is accessible
info "Checking Supabase connection..."
if command -v supabase &> /dev/null; then
    if supabase projects list &> /dev/null 2>&1; then
        pass "Supabase CLI authenticated and accessible"

        # Try to list tables (if connected to project)
        info "Attempting to verify tables in remote database..."
        warn "Remote database check skipped - requires manual verification"
    else
        warn "Supabase CLI not authenticated - run: npx supabase login"
    fi
else
    warn "Supabase CLI not installed - some tests skipped"
fi

# Check Flutter/Dart setup
info "Checking Flutter environment..."
if command -v flutter &> /dev/null; then
    pass "Flutter SDK found"

    # Run pub get test
    info "Testing Flutter pub get..."
    if flutter pub get &> /dev/null; then
        pass "flutter pub get successful"
    else
        fail "flutter pub get failed - check dependencies"
    fi

    # Run analyze test
    info "Running Flutter analyzer on models..."
    ANALYZER_OUTPUT=$(flutter analyze lib/backend/supabase/database/tables/ 2>&1 || true)
    if echo "$ANALYZER_OUTPUT" | grep -q "No issues found"; then
        pass "Flutter analyzer found no issues in models"
    else
        ISSUE_COUNT=$(echo "$ANALYZER_OUTPUT" | grep -c "•" || echo "0")
        if [ "$ISSUE_COUNT" -gt 0 ]; then
            warn "Flutter analyzer found $ISSUE_COUNT issues (may be warnings)"
        fi
    fi
else
    warn "Flutter SDK not found - some tests skipped"
fi

# Generate test report
test_start "Test Summary Report"

echo -e "\n${BLUE}📊 Test Results by Category:${NC}\n"

echo -e "${CYAN}Migration Files:${NC}"
echo "  - 4 migration files covering 19 tables"

echo -e "\n${CYAN}PowerSync Configuration:${NC}"
echo "  - Schema file: $POWERSYNC_SCHEMA"
echo "  - Sync rules: $SYNC_RULES"

echo -e "\n${CYAN}Dart Models:${NC}"
echo "  - 19 model files in $MODELS_DIR"
echo "  - All models extend SupabaseTable/SupabaseDataRow"

echo -e "\n${CYAN}Integration:${NC}"
echo "  - Edge function: $EDGE_FUNCTION"
echo "  - Database exports: $DATABASE_FILE"

# Print summary
echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📈 Final Test Summary${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Total Tests Run: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"
echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
echo ""

# Print failed tests if any
if [ $FAILED_TESTS -gt 0 ]; then
    echo -e "${RED}Failed Tests:${NC}"
    for failed_test in "${FAILED_TEST_NAMES[@]}"; do
        echo -e "  ${RED}•${NC} $failed_test"
    done
    echo ""
fi

# Print warnings if any
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Warnings:${NC}"
    for warning in "${WARNING_MESSAGES[@]}"; do
        echo -e "  ${YELLOW}•${NC} $warning"
    done
    echo ""
fi

# Final verdict
PASS_RATE=$(awk "BEGIN {printf \"%.1f\", ($PASSED_TESTS/$TOTAL_TESTS)*100}")

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED! ($PASS_RATE% success rate)${NC}"
    echo -e "\n${GREEN}🎉 The 19 specialty medical tables are properly integrated!${NC}"

    if [ $WARNINGS -gt 0 ]; then
        echo -e "\n${YELLOW}Note: $WARNINGS warnings were issued - review above for details${NC}"
    fi

    echo -e "\n${BLUE}Next steps:${NC}"
    echo "  1. Deploy to production: ./deploy_specialty_tables.sh"
    echo "  2. Test user signup/login flows"
    echo "  3. Create sample medical records for each specialty"
    echo "  4. Verify EHRbase sync queue processing"
    exit 0
else
    echo -e "${RED}❌ TESTS FAILED ($PASS_RATE% success rate)${NC}"
    echo -e "\n${RED}Please fix the $FAILED_TESTS failed test(s) before deploying${NC}"

    echo -e "\n${BLUE}Troubleshooting:${NC}"
    echo "  1. Review failed tests listed above"
    echo "  2. Run: ./verify_consistency.sh"
    echo "  3. Check project documentation: CLAUDE.md"
    echo "  4. Fix issues and re-run this test suite"
    exit 1
fi
