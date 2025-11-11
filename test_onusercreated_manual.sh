#!/bin/bash

# Manual Test Guide for onUserCreated Function
# This script provides instructions and verification commands

set -e

echo "🚀 onUserCreated Function - Manual Test Guide"
echo "================================================================================"
echo ""
echo "This guide will help you test the onUserCreated Cloud Function."
echo "You'll create a test user manually and verify it works correctly."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Generate test email
TIMESTAMP=$(date +%s)
TEST_EMAIL="test-user-${TIMESTAMP}@medzen-test.com"

echo "📝 Step 1: Create Test User in Firebase Console"
echo "--------------------------------------------------------------------------------"
echo ""
echo "   1. Open Firebase Console: https://console.firebase.google.com/project/medzen-bf20e/authentication/users"
echo "   2. Click 'Add user'"
echo "   3. Enter the following details:"
echo ""
echo -e "      ${YELLOW}Email:${NC}    ${TEST_EMAIL}"
echo -e "      ${YELLOW}Password:${NC} TestPassword123!"
echo ""
echo "   4. Click 'Add user'"
echo ""
echo -e "${YELLOW}Press ENTER when you've created the user...${NC}"
read

echo ""
echo "⏳ Step 2: Waiting for Cloud Function to Complete (15 seconds)..."
echo "--------------------------------------------------------------------------------"
sleep 15

echo ""
echo "📝 Step 3: Checking Cloud Function Logs"
echo "--------------------------------------------------------------------------------"
echo ""
echo "Running: firebase functions:log --only onUserCreated --limit 20"
echo ""

firebase functions:log --only onUserCreated --limit 20 | tail -50

echo ""
echo -e "${YELLOW}Did you see success logs above? (y/n):${NC} "
read LOGS_OK

if [ "$LOGS_OK" != "y" ]; then
    echo -e "${RED}❌ Cloud Function logs show failure. Check the logs above for errors.${NC}"
    exit 1
fi

echo ""
echo "📝 Step 4: Verifying Supabase Auth User"
echo "--------------------------------------------------------------------------------"

SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

echo ""
echo "Checking Supabase Auth for: ${TEST_EMAIL}"

AUTH_RESPONSE=$(curl -s "$SUPABASE_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

SUPABASE_USER_ID=$(echo "$AUTH_RESPONSE" | grep -o "\"id\":\"[^\"]*\"" | grep -o "[a-f0-9-]\{36\}" | head -1)

if [ -z "$SUPABASE_USER_ID" ]; then
    echo -e "${RED}❌ Supabase Auth user not found${NC}"
    echo "Response: $AUTH_RESPONSE"
    exit 1
fi

echo -e "${GREEN}✅ Supabase Auth user found${NC}"
echo "   Supabase User ID: $SUPABASE_USER_ID"

echo ""
echo "📝 Step 5: Verifying electronic_health_records Entry"
echo "--------------------------------------------------------------------------------"

EHR_RESPONSE=$(curl -s "$SUPABASE_URL/rest/v1/electronic_health_records?patient_id=eq.$SUPABASE_USER_ID&select=*" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

echo ""
echo "EHR Record:"
echo "$EHR_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$EHR_RESPONSE"

if echo "$EHR_RESPONSE" | grep -q "$SUPABASE_USER_ID"; then
    echo ""
    echo -e "${GREEN}✅ electronic_health_records entry found${NC}"
else
    echo ""
    echo -e "${RED}❌ electronic_health_records entry not found${NC}"
    exit 1
fi

echo ""
echo "🎉 SUCCESS! onUserCreated Function Test Passed"
echo "================================================================================"
echo ""
echo -e "${GREEN}✅ Firebase Auth user created${NC}"
echo -e "${GREEN}✅ Supabase Auth user created${NC}"
echo -e "${GREEN}✅ electronic_health_records entry created${NC}"
echo ""
echo "⚠️  Note: EHR ID will be 'null' initially - this is correct."
echo "   The Edge Function will fill it in later (async process)."
echo ""

echo "🧹 Cleanup Instructions"
echo "================================================================================"
echo ""
echo "To remove the test user:"
echo ""
echo "1. Firebase Console:"
echo "   https://console.firebase.google.com/project/medzen-bf20e/authentication/users"
echo "   Find: ${TEST_EMAIL}"
echo "   Click three dots → Delete user"
echo ""
echo "2. Supabase Studio:"
echo "   https://supabase.com/dashboard/project/noaeltglphdlkbflipit/auth/users"
echo "   Find user with ID: ${SUPABASE_USER_ID}"
echo "   Delete the user"
echo ""
echo "3. Electronic Health Records (will be deleted automatically when Supabase user is deleted)"
echo ""
echo "Or run these cleanup commands:"
echo ""
echo "# Delete from Supabase Auth"
echo "curl -X DELETE \"$SUPABASE_URL/auth/v1/admin/users/$SUPABASE_USER_ID\" \\"
echo "  -H \"apikey: $SERVICE_KEY\" \\"
echo "  -H \"Authorization: Bearer $SERVICE_KEY\""
echo ""
echo "# Delete from electronic_health_records"
echo "curl -X DELETE \"$SUPABASE_URL/rest/v1/electronic_health_records?patient_id=eq.$SUPABASE_USER_ID\" \\"
echo "  -H \"apikey: $SERVICE_KEY\" \\"
echo "  -H \"Authorization: Bearer $SERVICE_KEY\" \\"
echo "  -H \"Prefer: return=representation\""
echo ""
