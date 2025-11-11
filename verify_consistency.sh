#!/bin/bash

# Verification Script
# Verifies consistency between migrations, PowerSync schema, Dart models, and database exports
# Usage: ./verify_consistency.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Starting consistency verification...${NC}\n"

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Helper functions
pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
}

warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

# Check 1: Migration files exist and are numbered correctly
echo -e "${BLUE}1️⃣  Checking migration files...${NC}"
MIGRATION_DIR="supabase/migrations"
if [ -d "$MIGRATION_DIR" ]; then
    MIGRATION_COUNT=$(find "$MIGRATION_DIR" -name "*.sql" | wc -l | tr -d ' ')
    if [ "$MIGRATION_COUNT" -gt 0 ]; then
        pass "Found $MIGRATION_COUNT migration files"

        # Check for proper timestamp format
        INVALID_MIGRATIONS=$(find "$MIGRATION_DIR" -name "*.sql" ! -name "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_*.sql" | wc -l | tr -d ' ')
        if [ "$INVALID_MIGRATIONS" -eq 0 ]; then
            pass "All migrations follow timestamp naming convention"
        else
            fail "$INVALID_MIGRATIONS migrations have invalid naming format"
        fi
    else
        fail "No migration files found in $MIGRATION_DIR"
    fi
else
    fail "Migration directory not found: $MIGRATION_DIR"
fi

# Check 2: PowerSync schema exists and is valid
echo -e "\n${BLUE}2️⃣  Checking PowerSync schema...${NC}"
POWERSYNC_SCHEMA="lib/powersync/schema.dart"
if [ -f "$POWERSYNC_SCHEMA" ]; then
    pass "PowerSync schema file exists"

    # Check for Schema class
    if grep -q "class Schema" "$POWERSYNC_SCHEMA"; then
        pass "Schema class definition found"
    else
        fail "Schema class definition not found"
    fi

    # Check for tables array
    if grep -q "tables:" "$POWERSYNC_SCHEMA"; then
        TABLE_COUNT=$(grep -c "Table(" "$POWERSYNC_SCHEMA" || echo "0")
        pass "Found $TABLE_COUNT table definitions in PowerSync schema"
    else
        fail "Tables array not found in PowerSync schema"
    fi
else
    fail "PowerSync schema file not found: $POWERSYNC_SCHEMA"
fi

# Check 3: Dart models exist
echo -e "\n${BLUE}3️⃣  Checking Dart model files...${NC}"
MODELS_DIR="lib/backend/supabase/database/tables"
if [ -d "$MODELS_DIR" ]; then
    MODEL_COUNT=$(find "$MODELS_DIR" -name "*.dart" | wc -l | tr -d ' ')
    if [ "$MODEL_COUNT" -gt 0 ]; then
        pass "Found $MODEL_COUNT Dart model files"

        # Check each model follows the pattern
        INVALID_MODELS=0
        while IFS= read -r model_file; do
            if ! grep -q "extends SupabaseTable" "$model_file" || ! grep -q "extends SupabaseDataRow" "$model_file"; then
                ((INVALID_MODELS++))
                warn "Model may be incomplete: $(basename "$model_file")"
            fi
        done < <(find "$MODELS_DIR" -name "*.dart")

        if [ "$INVALID_MODELS" -eq 0 ]; then
            pass "All models follow SupabaseTable/SupabaseDataRow pattern"
        else
            fail "$INVALID_MODELS models may be incomplete"
        fi
    else
        fail "No model files found in $MODELS_DIR"
    fi
else
    fail "Models directory not found: $MODELS_DIR"
fi

# Check 4: Database.dart exports
echo -e "\n${BLUE}4️⃣  Checking database.dart exports...${NC}"
DATABASE_FILE="lib/backend/supabase/database/database.dart"
if [ -f "$DATABASE_FILE" ]; then
    pass "database.dart file exists"

    # Count exports
    EXPORT_COUNT=$(grep -c "^export 'tables/" "$DATABASE_FILE" || echo "0")
    if [ "$EXPORT_COUNT" -gt 0 ]; then
        pass "Found $EXPORT_COUNT table exports in database.dart"

        # Check if all model files are exported
        MISSING_EXPORTS=0
        while IFS= read -r model_file; do
            MODEL_NAME=$(basename "$model_file")
            if ! grep -q "export 'tables/$MODEL_NAME';" "$DATABASE_FILE"; then
                ((MISSING_EXPORTS++))
                warn "Missing export for: $MODEL_NAME"
            fi
        done < <(find "$MODELS_DIR" -name "*.dart")

        if [ "$MISSING_EXPORTS" -eq 0 ]; then
            pass "All models are exported in database.dart"
        else
            fail "$MISSING_EXPORTS models are not exported"
        fi
    else
        fail "No table exports found in database.dart"
    fi
else
    fail "database.dart file not found: $DATABASE_FILE"
fi

# Check 5: PowerSync sync rules
echo -e "\n${BLUE}5️⃣  Checking PowerSync sync rules...${NC}"
SYNC_RULES="POWERSYNC_SYNC_RULES.yaml"
if [ -f "$SYNC_RULES" ]; then
    pass "PowerSync sync rules file exists"

    # Check for bucket definitions
    if grep -q "bucket_definitions:" "$SYNC_RULES"; then
        BUCKET_COUNT=$(grep -c "^  - bucket:" "$SYNC_RULES" || echo "0")
        pass "Found $BUCKET_COUNT bucket definitions"
    else
        fail "bucket_definitions not found in sync rules"
    fi
else
    fail "PowerSync sync rules file not found: $SYNC_RULES"
fi

# Check 6: Edge function exists
echo -e "\n${BLUE}6️⃣  Checking edge function...${NC}"
EDGE_FUNCTION="supabase/functions/sync-to-ehrbase/index.ts"
if [ -f "$EDGE_FUNCTION" ]; then
    pass "sync-to-ehrbase edge function exists"

    # Check for template mappings
    if grep -q "TEMPLATE_MAPPINGS" "$EDGE_FUNCTION"; then
        pass "Template mappings found in edge function"
    else
        warn "Template mappings not found - may need to be added"
    fi
else
    fail "sync-to-ehrbase edge function not found: $EDGE_FUNCTION"
fi

# Check 7: Required dependencies in pubspec.yaml
echo -e "\n${BLUE}7️⃣  Checking pubspec.yaml dependencies...${NC}"
PUBSPEC="pubspec.yaml"
if [ -f "$PUBSPEC" ]; then
    pass "pubspec.yaml exists"

    REQUIRED_DEPS=("supabase_flutter" "powersync" "sqflite" "path_provider")
    MISSING_DEPS=0

    for dep in "${REQUIRED_DEPS[@]}"; do
        if grep -q "^  $dep:" "$PUBSPEC"; then
            pass "Dependency found: $dep"
        else
            fail "Missing dependency: $dep"
            ((MISSING_DEPS++))
        fi
    done
else
    fail "pubspec.yaml file not found"
fi

# Summary
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Verification Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Total checks: $TOTAL_CHECKS"
echo -e "${GREEN}Passed: $PASSED_CHECKS${NC}"
echo -e "${RED}Failed: $FAILED_CHECKS${NC}"
echo ""

if [ "$FAILED_CHECKS" -eq 0 ]; then
    echo -e "${GREEN}✅ All verification checks passed!${NC}"
    echo ""
    echo "System is ready for deployment."
    exit 0
else
    echo -e "${RED}❌ $FAILED_CHECKS verification check(s) failed!${NC}"
    echo ""
    echo "Please fix the issues above before deploying."
    exit 1
fi
