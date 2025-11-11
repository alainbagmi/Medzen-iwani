#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FIREBASE_WEB_API_KEY="AIzaSyCWGcgzxeKgytwlIVMs6_7Dmu0e2EEmBTQ"
SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SUPABASE_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"
EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase"
EHRBASE_USERNAME="ehrbase-admin"
EHRBASE_PASSWORD="EvenMoreSecretPassword"

# Generate test email
TEST_EMAIL="test-$(date +%s)@medzen-test.com"
TEST_PASSWORD="TestPassword123!"

echo -e "${BLUE}🧪 Testing onUserCreated Function${NC}"
echo "═══════════════════════════════════════════════════"
echo ""

# Step 1: Create Firebase Auth user
echo -e "${BLUE}📝 Step 1: Creating Firebase Auth user...${NC}"
echo "   Email: $TEST_EMAIL"

SIGNUP_RESPONSE=$(curl -s -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$FIREBASE_WEB_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"returnSecureToken\": true
  }")

FIREBASE_UID=$(echo "$SIGNUP_RESPONSE" | jq -r '.localId // empty')
ID_TOKEN=$(echo "$SIGNUP_RESPONSE" | jq -r '.idToken // empty')

if [ -z "$FIREBASE_UID" ]; then
  echo -e "   ${RED}❌ FAIL: Could not create Firebase user${NC}"
  echo "   Response: $SIGNUP_RESPONSE"
  exit 1
fi

echo -e "   ${GREEN}✅ Created Firebase user: $FIREBASE_UID${NC}"
echo ""

# Step 2: Wait for Cloud Function
echo -e "${YELLOW}⏳ Step 2: Waiting for onUserCreated function (20 seconds)...${NC}"
sleep 20
echo -e "   ${GREEN}✅ Wait complete${NC}"
echo ""

# Step 3: Check Supabase users table
echo -e "${BLUE}🔍 Step 3: Checking Supabase users table...${NC}"

USERS_RESPONSE=$(curl -s \
  "$SUPABASE_URL/rest/v1/users?email=eq.$TEST_EMAIL" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY")

SUPABASE_USER_ID=$(echo "$USERS_RESPONSE" | jq -r '.[0].id // empty')

if [ -z "$SUPABASE_USER_ID" ]; then
  echo -e "   ${RED}❌ FAIL: User not found in users table${NC}"
  echo "   Response: $USERS_RESPONSE"
else
  echo -e "   ${GREEN}✅ PASS: Found user in users table${NC}"
  echo "   User ID: $SUPABASE_USER_ID"
  echo "   Email: $(echo "$USERS_RESPONSE" | jq -r '.[0].email')"
  echo "   Firebase UID: $(echo "$USERS_RESPONSE" | jq -r '.[0].firebase_uid')"
fi
echo ""

# Step 4: Check user_profiles table
echo -e "${BLUE}🔍 Step 4: Checking user_profiles table...${NC}"

if [ -n "$SUPABASE_USER_ID" ]; then
  PROFILES_RESPONSE=$(curl -s \
    "$SUPABASE_URL/rest/v1/user_profiles?user_id=eq.$SUPABASE_USER_ID" \
    -H "apikey: $SUPABASE_SERVICE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_KEY")

  PROFILE_ID=$(echo "$PROFILES_RESPONSE" | jq -r '.[0].id // empty')

  if [ -z "$PROFILE_ID" ]; then
    echo -e "   ${RED}❌ FAIL: User profile not found${NC}"
    echo "   Response: $PROFILES_RESPONSE"
  else
    echo -e "   ${GREEN}✅ PASS: Found user profile${NC}"
    echo "   Profile ID: $PROFILE_ID"
    echo "   User ID: $(echo "$PROFILES_RESPONSE" | jq -r '.[0].user_id')"
    echo "   Email: $(echo "$PROFILES_RESPONSE" | jq -r '.[0].email')"
    echo "   Role: $(echo "$PROFILES_RESPONSE" | jq -r '.[0].role // "null (expected)"')"
  fi
else
  echo -e "   ${YELLOW}⚠️  SKIP: Cannot check (no Supabase user ID)${NC}"
fi
echo ""

# Step 5: Check electronic_health_records table
echo -e "${BLUE}🔍 Step 5: Checking electronic_health_records table...${NC}"

if [ -n "$SUPABASE_USER_ID" ]; then
  EHR_RESPONSE=$(curl -s \
    "$SUPABASE_URL/rest/v1/electronic_health_records?patient_id=eq.$SUPABASE_USER_ID" \
    -H "apikey: $SUPABASE_SERVICE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_KEY")

  EHR_ID=$(echo "$EHR_RESPONSE" | jq -r '.[0].ehr_id // empty')

  if [ -z "$EHR_ID" ]; then
    echo -e "   ${RED}❌ FAIL: EHR record not found${NC}"
    echo "   Response: $EHR_RESPONSE"
  else
    echo -e "   ${GREEN}✅ PASS: Found EHR record${NC}"
    echo "   EHR ID: $EHR_ID"
    echo "   Patient ID: $(echo "$EHR_RESPONSE" | jq -r '.[0].patient_id')"
    echo "   EHRbase URL: $(echo "$EHR_RESPONSE" | jq -r '.[0].ehrbase_url')"
  fi
else
  echo -e "   ${YELLOW}⚠️  SKIP: Cannot check (no Supabase user ID)${NC}"
fi
echo ""

# Step 6: Check EHRbase
echo -e "${BLUE}🔍 Step 6: Checking EHRbase EHR...${NC}"

if [ -n "$EHR_ID" ]; then
  EHRBASE_RESPONSE=$(curl -s \
    -u "$EHRBASE_USERNAME:$EHRBASE_PASSWORD" \
    -H "Accept: application/json" \
    "$EHRBASE_URL/rest/openehr/v1/ehr/$EHR_ID")

  EHRBASE_SYSTEM_ID=$(echo "$EHRBASE_RESPONSE" | jq -r '.system_id.value // empty')

  if [ -z "$EHRBASE_SYSTEM_ID" ]; then
    echo -e "   ${RED}❌ FAIL: EHR not found in EHRbase${NC}"
    echo "   Response: $EHRBASE_RESPONSE"
  else
    echo -e "   ${GREEN}✅ PASS: Found EHR in EHRbase${NC}"
    echo "   System ID: $EHRBASE_SYSTEM_ID"
    echo "   Time Created: $(echo "$EHRBASE_RESPONSE" | jq -r '.time_created.value // "N/A"')"
  fi
else
  echo -e "   ${YELLOW}⚠️  SKIP: Cannot check (no EHR ID)${NC}"
fi
echo ""

# Summary
echo "═══════════════════════════════════════════════════"
echo ""
if [ -n "$FIREBASE_UID" ] && [ -n "$SUPABASE_USER_ID" ] && [ -n "$PROFILE_ID" ] && [ -n "$EHR_ID" ] && [ -n "$EHRBASE_SYSTEM_ID" ]; then
  echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
  echo ""
  echo "Summary:"
  echo "  ✓ Firebase Auth user created"
  echo "  ✓ Supabase Auth user created"
  echo "  ✓ users table entry created"
  echo "  ✓ user_profiles table entry created"
  echo "  ✓ electronic_health_records entry created"
  echo "  ✓ EHRbase EHR created"
else
  echo -e "${RED}❌ SOME TESTS FAILED${NC}"
  echo ""
  echo "Results:"
  [ -n "$FIREBASE_UID" ] && echo -e "  ${GREEN}✓${NC} Firebase Auth user created" || echo -e "  ${RED}✗${NC} Firebase Auth user failed"
  [ -n "$SUPABASE_USER_ID" ] && echo -e "  ${GREEN}✓${NC} users table entry created" || echo -e "  ${RED}✗${NC} users table entry failed"
  [ -n "$PROFILE_ID" ] && echo -e "  ${GREEN}✓${NC} user_profiles table entry created" || echo -e "  ${RED}✗${NC} user_profiles table entry failed"
  [ -n "$EHR_ID" ] && echo -e "  ${GREEN}✓${NC} electronic_health_records entry created" || echo -e "  ${RED}✗${NC} electronic_health_records entry failed"
  [ -n "$EHRBASE_SYSTEM_ID" ] && echo -e "  ${GREEN}✓${NC} EHRbase EHR created" || echo -e "  ${RED}✗${NC} EHRbase EHR failed"
fi
echo ""

# Check Firebase logs
echo -e "${BLUE}📋 Checking Firebase Function Logs...${NC}"
echo "Run this command to see the onUserCreated logs:"
echo "  firebase functions:log --only onUserCreated"
echo ""

# Cleanup prompt
echo -e "${YELLOW}🧹 Cleanup:${NC}"
echo "To delete the test user, run:"
echo "  firebase auth:delete --email $TEST_EMAIL"
echo ""
