#!/bin/bash

# Test Account Creation Script
# Tests RLS policies for all account creation flows

echo "🧪 Testing Account Creation Flows"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

# Check if Supabase is linked
echo "Checking Supabase connection..."
if ! npx supabase link --project-ref $(grep 'SUPABASE_URL' .env 2>/dev/null | cut -d '=' -f2 | cut -d '/' -f3 | cut -d '.' -f1) 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Supabase not linked. Run: npx supabase link${NC}"
fi
echo ""

# Apply the new facilities RLS migration
echo "📦 Applying facilities RLS migration..."
if npx supabase db push; then
    echo -e "${GREEN}✅ Migration applied successfully${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ Migration failed to apply${NC}"
    ((FAILED++))
fi
echo ""

# Test 1: Check medical_provider_profiles RLS
echo "Test 1: Medical Provider Profiles RLS"
echo "-------------------------------------"
POLICIES=$(npx supabase db execute "SELECT COUNT(*) FROM pg_policies WHERE schemaname='public' AND tablename='medical_provider_profiles' AND cmd='INSERT'" 2>/dev/null | grep -o '[0-9]' | head -1)

if [ "$POLICIES" -ge "1" ]; then
    echo -e "${GREEN}✅ INSERT policy exists for medical_provider_profiles${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ No INSERT policy found for medical_provider_profiles${NC}"
    ((FAILED++))
fi
echo ""

# Test 2: Check system_admin_profiles RLS
echo "Test 2: System Admin Profiles RLS"
echo "----------------------------------"
POLICIES=$(npx supabase db execute "SELECT COUNT(*) FROM pg_policies WHERE schemaname='public' AND tablename='system_admin_profiles' AND cmd='INSERT'" 2>/dev/null | grep -o '[0-9]' | head -1)

if [ "$POLICIES" -ge "1" ]; then
    echo -e "${GREEN}✅ INSERT policy exists for system_admin_profiles${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ No INSERT policy found for system_admin_profiles${NC}"
    ((FAILED++))
fi
echo ""

# Test 3: Check facility_admin_profiles RLS
echo "Test 3: Facility Admin Profiles RLS"
echo "------------------------------------"
POLICIES=$(npx supabase db execute "SELECT COUNT(*) FROM pg_policies WHERE schemaname='public' AND tablename='facility_admin_profiles' AND cmd='INSERT'" 2>/dev/null | grep -o '[0-9]' | head -1)

if [ "$POLICIES" -ge "1" ]; then
    echo -e "${GREEN}✅ INSERT policy exists for facility_admin_profiles${NC}"
    ((PASSED++))
else
    echo -e "${RED}❌ No INSERT policy found for facility_admin_profiles${NC}"
    ((FAILED++))
fi
echo ""

# Test 4: Check facilities RLS
echo "Test 4: Facilities Table RLS"
echo "-----------------------------"
RLS_ENABLED=$(npx supabase db execute "SELECT relrowsecurity FROM pg_class WHERE relname='facilities' AND relnamespace=(SELECT oid FROM pg_namespace WHERE nspname='public')" 2>/dev/null | grep 't' | wc -l)

if [ "$RLS_ENABLED" -ge "1" ]; then
    echo -e "${GREEN}✅ RLS enabled on facilities table${NC}"
    ((PASSED++))

    # Check for INSERT policy
    POLICIES=$(npx supabase db execute "SELECT COUNT(*) FROM pg_policies WHERE schemaname='public' AND tablename='facilities' AND cmd='INSERT'" 2>/dev/null | grep -o '[0-9]' | head -1)

    if [ "$POLICIES" -ge "1" ]; then
        echo -e "${GREEN}✅ INSERT policy exists for facilities${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ No INSERT policy found for facilities${NC}"
        ((FAILED++))
    fi
else
    echo -e "${RED}❌ RLS not enabled on facilities table${NC}"
    ((FAILED++))
fi
echo ""

# Summary
echo "=================================="
echo "Test Summary"
echo "=================================="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All RLS policy tests PASSED!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run the Flutter app"
    echo "2. Navigate to a page with custom actions"
    echo "3. Call testAccountCreation() to test actual account creation"
    exit 0
else
    echo -e "${RED}⚠️  Some tests FAILED. Check RLS policies above.${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Ensure migrations are applied: npx supabase db push"
    echo "2. Check migration file: supabase/migrations/20251103230000_add_facilities_rls_policies.sql"
    echo "3. Verify all profile RLS policies: supabase/migrations/20251103223000_fix_profile_rls_policies.sql"
    exit 1
fi
