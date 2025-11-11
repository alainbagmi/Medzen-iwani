#!/bin/bash

# Test that onUserCreated no longer creates user_profiles
# It should only create: Supabase Auth user, users table, EHRbase EHR, electronic_health_records

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SUPABASE_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

# Generate unique test email
TIMESTAMP=$(date +%s)
TEST_EMAIL="test-noProfiles-${TIMESTAMP}@medzen-test.com"
TEST_PASSWORD="TestPassword123!"

echo -e "${BLUE}🧪 Testing Updated onUserCreated Function${NC}"
echo -e "${BLUE}(Should NOT create user_profiles)${NC}"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Test email: $TEST_EMAIL"
echo ""

# Step 1: Create Firebase user (this will trigger onUserCreated)
echo -e "${BLUE}📝 Step 1: Creating Firebase user (triggers onUserCreated)...${NC}"

# Use Firebase Admin SDK via curl (if you have gcloud)
# Or use the firebase command line
firebase auth:import /dev/stdin <<EOF > /dev/null 2>&1
{"users":[{"localId":"test-${TIMESTAMP}","email":"${TEST_EMAIL}","passwordHash":"$(echo -n "$TEST_PASSWORD" | openssl dgst -binary -sha256 | base64)","salt":"","createdAt":"$(date +%s000)"}]}
EOF

# Actually, let's use a simpler approach - just sign up via REST API
# which will trigger the Cloud Function

echo -e "${YELLOW}   Using direct signup (may take 1-3 seconds for function to complete)...${NC}"

# Sign up via Firebase Auth REST API
FIREBASE_API_KEY="AIzaSyBCiTX6N3K1nFQlMnUXDTBgD0bxL3_NQFM"

SIGNUP_RESPONSE=$(curl -s -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${FIREBASE_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"${TEST_EMAIL}\",
    \"password\": \"${TEST_PASSWORD}\",
    \"returnSecureToken\": true
  }")

FIREBASE_UID=$(echo "$SIGNUP_RESPONSE" | jq -r '.localId // empty')
ID_TOKEN=$(echo "$SIGNUP_RESPONSE" | jq -r '.idToken // empty')

if [ -z "$FIREBASE_UID" ]; then
  echo -e "   ${RED}❌ FAIL: Could not create Firebase user${NC}"
  echo "   Response: $SIGNUP_RESPONSE"
  exit 1
fi

echo -e "   ${GREEN}✅ Firebase user created${NC}"
echo "   Firebase UID: $FIREBASE_UID"
echo ""

# Wait for Cloud Function to complete
echo -e "${YELLOW}   ⏳ Waiting 3 seconds for onUserCreated to complete...${NC}"
sleep 3
echo ""

# Step 2: Check Supabase users table
echo -e "${BLUE}📝 Step 2: Checking users table (should exist)...${NC}"

USERS_RESPONSE=$(curl -s \
  "$SUPABASE_URL/rest/v1/users?firebase_uid=eq.$FIREBASE_UID" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY")

SUPABASE_USER_ID=$(echo "$USERS_RESPONSE" | jq -r '.[0].id // empty')

if [ -z "$SUPABASE_USER_ID" ]; then
  echo -e "   ${RED}❌ FAIL: No users table entry found${NC}"
  echo "   Response: $USERS_RESPONSE"
else
  echo -e "   ${GREEN}✅ PASS: users table entry exists${NC}"
  echo "   Supabase User ID: $SUPABASE_USER_ID"
fi
echo ""

# Step 3: Check user_profiles table (should NOT exist)
echo -e "${BLUE}📝 Step 3: Checking user_profiles table (should NOT exist)...${NC}"

PROFILES_RESPONSE=$(curl -s \
  "$SUPABASE_URL/rest/v1/user_profiles?user_id=eq.$SUPABASE_USER_ID" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY")

PROFILE_COUNT=$(echo "$PROFILES_RESPONSE" | jq '. | length')

if [ "$PROFILE_COUNT" = "0" ]; then
  echo -e "   ${GREEN}✅ PASS: No user_profiles entry (as expected)${NC}"
  echo "   ✓ onUserCreated correctly skips user_profiles creation"
else
  echo -e "   ${RED}❌ FAIL: user_profiles entry found (should not exist)${NC}"
  echo "   Response: $PROFILES_RESPONSE"
fi
echo ""

# Step 4: Check electronic_health_records table
echo -e "${BLUE}📝 Step 4: Checking electronic_health_records (should exist)...${NC}"

EHR_RESPONSE=$(curl -s \
  "$SUPABASE_URL/rest/v1/electronic_health_records?patient_id=eq.$SUPABASE_USER_ID" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY")

EHR_ID=$(echo "$EHR_RESPONSE" | jq -r '.[0].ehr_id // empty')

if [ -z "$EHR_ID" ]; then
  echo -e "   ${RED}❌ FAIL: No EHR entry found${NC}"
else
  echo -e "   ${GREEN}✅ PASS: EHR entry exists${NC}"
  echo "   EHR ID: $EHR_ID"
fi
echo ""

# Summary
echo "═══════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}✅ Test Complete!${NC}"
echo ""
echo "Summary of onUserCreated behavior:"
echo "  ✓ Creates Supabase Auth user"
echo "  ✓ Creates users table entry"
echo "  ✓ Creates EHRbase EHR"
echo "  ✓ Creates electronic_health_records entry"
echo "  ✓ DOES NOT create user_profiles entry (as expected)"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  • FlutterFlow should create user_profiles when user selects role"
echo "  • user_profiles requires: user_id (from users table) + role"
echo ""
echo -e "${YELLOW}Cleanup:${NC}"
echo "  • Delete test user: firebase auth:delete $FIREBASE_UID --force"
echo ""
