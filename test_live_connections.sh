#!/bin/bash

# Live Connection Test Script for MedZen-Iwani
# Tests actual connectivity to all 4 systems

echo "========================================="
echo "MedZen-Iwani Live Connection Tests"
echo "========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

# Test 1: Firebase Project Access
echo -e "${YELLOW}[1/6] Testing Firebase Project Access...${NC}"
if firebase projects:list | grep -q "medzen"; then
    echo -e "${GREEN}✓ Firebase project access confirmed${NC}"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo -e "${RED}✗ Cannot access Firebase project${NC}"
    TESTS_FAILED=$((TESTS_FAILED+1))
fi
echo ""

# Test 2: Supabase Project Link
echo -e "${YELLOW}[2/6] Testing Supabase Project Link...${NC}"
if npx supabase link --project-ref noaeltglphdlkbflipit 2>&1 | grep -q "Finished"; then
    echo -e "${GREEN}✓ Supabase project linked successfully${NC}"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo -e "${RED}✗ Supabase project link failed${NC}"
    TESTS_FAILED=$((TESTS_FAILED+1))
fi
echo ""

# Test 3: Supabase Secrets Check
echo -e "${YELLOW}[3/6] Checking Supabase Secrets...${NC}"
SECRET_COUNT=$(npx supabase secrets list --project-ref noaeltglphdlkbflipit 2>/dev/null | grep -c "EHRBASE\|SUPABASE\|POWERSYNC")
if [ "$SECRET_COUNT" -gt 5 ]; then
    echo -e "${GREEN}✓ Found $SECRET_COUNT secrets configured${NC}"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo -e "${YELLOW}⚠ Only $SECRET_COUNT secrets found (need PowerSync secrets)${NC}"
    TESTS_FAILED=$((TESTS_FAILED+1))
fi
echo ""

# Test 4: Flutter Dependencies
echo -e "${YELLOW}[4/6] Checking Flutter Dependencies...${NC}"
if flutter pub get 2>&1 | grep -q "Got dependencies"; then
    echo -e "${GREEN}✓ Flutter dependencies resolved${NC}"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo -e "${RED}✗ Flutter dependency issues${NC}"
    TESTS_FAILED=$((TESTS_FAILED+1))
fi
echo ""

# Test 5: Firebase Functions Created
echo -e "${YELLOW}[5/6] Checking Firebase Functions...${NC}"
if grep -q "exports.onUserCreated" firebase/functions/index.js; then
    echo -e "${GREEN}✓ onUserCreated function exists in code${NC}"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo -e "${RED}✗ onUserCreated function not found${NC}"
    TESTS_FAILED=$((TESTS_FAILED+1))
fi
echo ""

# Test 6: PowerSync Configuration
echo -e "${YELLOW}[6/6] Checking PowerSync Configuration...${NC}"
if grep -q "PowerSyncDatabase" lib/powersync/database.dart; then
    echo -e "${GREEN}✓ PowerSync implementation found${NC}"
    TESTS_PASSED=$((TESTS_PASSED+1))
else
    echo -e "${RED}✗ PowerSync implementation missing${NC}"
    TESTS_FAILED=$((TESTS_FAILED+1))
fi
echo ""

# Summary
echo "========================================="
echo "Test Results Summary"
echo "========================================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED/6${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED/6${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All connectivity tests passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Some tests failed. Review the output above.${NC}"
    echo ""
    echo "Common issues:"
    echo "  • PowerSync secrets not configured (need POWERSYNC_URL, POWERSYNC_KEY_ID, POWERSYNC_PRIVATE_KEY)"
    echo "  • Firebase project not selected (run: firebase use medzen-bf20e)"
    echo "  • Firebase functions not deployed (run: firebase deploy --only functions)"
    exit 1
fi
