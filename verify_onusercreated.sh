#!/bin/bash

#===============================================================================
# onUserCreated Function Verification Script
#===============================================================================
# This script verifies that the onUserCreated function is working correctly.
#
# Usage:
#   1. Create a test user manually in Firebase Console or your app
#   2. Note the test user's email
#   3. Run: ./verify_onusercreated.sh <test-email>
#
# Example:
#   ./verify_onusercreated.sh test@medzen-test.com
#===============================================================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if email is provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Please provide the test user's email${NC}"
    echo ""
    echo "Usage: $0 <test-email>"
    echo "Example: $0 test@medzen-test.com"
    exit 1
fi

TEST_EMAIL="$1"

echo -e "${BLUE}🚀 Verifying onUserCreated Function for: ${TEST_EMAIL}${NC}"
echo "================================================================================"
echo ""

# Supabase credentials
SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

# Step 1: Check Cloud Function Logs
echo -e "${YELLOW}📝 Step 1: Checking Cloud Function logs...${NC}"
echo ""

echo "Most recent onUserCreated executions:"
firebase functions:log --only onUserCreated --limit 5 2>&1 | grep -A 10 "$TEST_EMAIL" || echo "No logs found for this email yet. The function may still be running..."

echo ""
echo "Press ENTER to continue to Step 2..."
read

# Step 2: Find Supabase User
echo ""
echo -e "${YELLOW}📝 Step 2: Finding Supabase Auth user...${NC}"
echo ""

AUTH_RESPONSE=$(curl -s "$SUPABASE_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

# Extract user ID for this email (using grep and awk for better compatibility)
SUPABASE_USER_ID=$(echo "$AUTH_RESPONSE" | grep -o "\"email\":\"$TEST_EMAIL\"" -A 50 | grep -o "\"id\":\"[^\"]*\"" | head -1 | cut -d'"' -f4)

if [ -z "$SUPABASE_USER_ID" ]; then
    echo -e "${RED}❌ FAILED: Supabase Auth user not found${NC}"
    echo ""
    echo "This means the onUserCreated function did NOT create the Supabase Auth user."
    echo ""
    echo "Troubleshooting steps:"
    echo "1. Check Cloud Function logs: firebase functions:log --only onUserCreated"
    echo "2. Verify Firebase Functions config: firebase functions:config:get"
    echo "3. Check if the function completed successfully"
    exit 1
fi

echo -e "${GREEN}✅ PASSED: Supabase Auth user found${NC}"
echo "   Supabase User ID: ${SUPABASE_USER_ID}"
echo ""

# Step 3: Check electronic_health_records
echo -e "${YELLOW}📝 Step 3: Checking electronic_health_records table...${NC}"
echo ""

EHR_RESPONSE=$(curl -s "$SUPABASE_URL/rest/v1/electronic_health_records?patient_id=eq.$SUPABASE_USER_ID&select=*" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Prefer: return=representation")

# Check if response contains the patient_id
if echo "$EHR_RESPONSE" | grep -q "\"patient_id\":\"$SUPABASE_USER_ID\""; then
    echo -e "${GREEN}✅ PASSED: electronic_health_records entry found${NC}"
    echo ""
    echo "Entry details:"
    echo "$EHR_RESPONSE" | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin), indent=2))" 2>/dev/null || echo "$EHR_RESPONSE"
    echo ""

    # Extract key fields
    EHR_ID=$(echo "$EHR_RESPONSE" | grep -o "\"ehr_id\":\"[^\"]*\"" | cut -d'"' -f4)
    EHR_STATUS=$(echo "$EHR_RESPONSE" | grep -o "\"ehr_status\":\"[^\"]*\"" | cut -d'"' -f4)
    USER_ROLE=$(echo "$EHR_RESPONSE" | grep -o "\"user_role\":\"[^\"]*\"" | cut -d'"' -f4)

    echo -e "${BLUE}Key fields:${NC}"
    echo "   Patient ID: ${SUPABASE_USER_ID}"
    echo "   EHR ID: ${EHR_ID:-null (pending - this is correct)}"
    echo "   EHR Status: ${EHR_STATUS}"
    echo "   User Role: ${USER_ROLE}"

else
    echo -e "${RED}❌ FAILED: electronic_health_records entry NOT found${NC}"
    echo ""
    echo "Response from database:"
    echo "$EHR_RESPONSE"
    echo ""
    echo "This means the onUserCreated function did NOT create the electronic_health_records entry."
    exit 1
fi

# Step 4: Check Firestore (optional - requires Firebase Admin SDK)
echo ""
echo -e "${YELLOW}📝 Step 4: Checking Firestore (optional)...${NC}"
echo ""
echo "To check Firestore manually:"
echo "1. Open Firebase Console: https://console.firebase.google.com/project/medzen-bf20e/firestore/data"
echo "2. Navigate to: users collection"
echo "3. Look for a document with email: ${TEST_EMAIL}"
echo "4. Verify it has a 'supabase_user_id' field with value: ${SUPABASE_USER_ID}"
echo ""

# Success Summary
echo "================================================================================"
echo -e "${GREEN}🎉 SUCCESS! onUserCreated Function Verification Complete${NC}"
echo "================================================================================"
echo ""
echo -e "${GREEN}✅ Supabase Auth user created${NC}"
echo -e "${GREEN}✅ electronic_health_records entry created${NC}"
echo -e "${YELLOW}⚠️  EHR ID is pending (null) - this is CORRECT${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. The Edge Function will populate the EHR ID asynchronously"
echo "2. FlutterFlow should update the users table with profile details"
echo "3. Database trigger will update user_role when profile is created"
echo ""
echo -e "${YELLOW}Cleanup:${NC}"
echo "To delete this test user, run:"
echo "  firebase auth:delete ${TEST_EMAIL} (Firebase CLI doesn't support this directly)"
echo ""
echo "Or delete manually from:"
echo "  - Firebase Console: https://console.firebase.google.com/project/medzen-bf20e/authentication/users"
echo "  - Supabase Studio: https://supabase.com/dashboard/project/noaeltglphdlkbflipit/auth/users"
echo ""
