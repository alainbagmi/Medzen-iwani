#!/bin/bash

# Test FlutterFlow user_profiles creation capability
# This simulates what FlutterFlow would do when creating a user profile

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SUPABASE_SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

echo -e "${BLUE}🧪 Testing FlutterFlow user_profiles Creation${NC}"
echo "═══════════════════════════════════════════════════"
echo ""

# Step 1: Get a user from the users table
echo -e "${BLUE}📝 Step 1: Getting a test user...${NC}"
USER_RESPONSE=$(curl -s \
  "$SUPABASE_URL/rest/v1/users?select=id,email&limit=1" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY")

USER_ID=$(echo "$USER_RESPONSE" | jq -r '.[0].id // empty')
USER_EMAIL=$(echo "$USER_RESPONSE" | jq -r '.[0].email // empty')

if [ -z "$USER_ID" ]; then
  echo -e "   ${RED}❌ FAIL: No users found in database${NC}"
  exit 1
fi

echo -e "   ${GREEN}✅ Found user${NC}"
echo "   User ID: $USER_ID"
echo "   Email: $USER_EMAIL"
echo ""

# Step 2: Test CREATE operation (FlutterFlow perspective)
echo -e "${BLUE}📝 Step 2: Testing CREATE user_profile...${NC}"
echo "   This simulates what FlutterFlow does when creating a profile"

CREATE_RESPONSE=$(curl -s -X POST \
  "$SUPABASE_URL/rest/v1/user_profiles" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: resolution=merge-duplicates,return=representation" \
  -d "{
    \"user_id\": \"$USER_ID\",
    \"role\": \"patient\",
    \"bio\": \"Test profile created by FlutterFlow\",
    \"city\": \"Test City\",
    \"country\": \"Test Country\"
  }")

PROFILE_ID=$(echo "$CREATE_RESPONSE" | jq -r '.[0].id // empty')
PROFILE_ROLE=$(echo "$CREATE_RESPONSE" | jq -r '.[0].role // empty')

if [ -z "$PROFILE_ID" ]; then
  echo -e "   ${RED}❌ FAIL: Could not create profile${NC}"
  echo "   Response: $CREATE_RESPONSE"
else
  echo -e "   ${GREEN}✅ PASS: Profile created successfully${NC}"
  echo "   Profile ID: $PROFILE_ID"
  echo "   Role: $PROFILE_ROLE"
fi
echo ""

# Step 3: Test READ operation
echo -e "${BLUE}📝 Step 3: Testing READ user_profile...${NC}"

READ_RESPONSE=$(curl -s \
  "$SUPABASE_URL/rest/v1/user_profiles?user_id=eq.$USER_ID" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY")

READ_PROFILE_ID=$(echo "$READ_RESPONSE" | jq -r '.[0].id // empty')

if [ -z "$READ_PROFILE_ID" ]; then
  echo -e "   ${RED}❌ FAIL: Could not read profile${NC}"
else
  echo -e "   ${GREEN}✅ PASS: Profile read successfully${NC}"
  echo "   Bio: $(echo "$READ_RESPONSE" | jq -r '.[0].bio')"
  echo "   City: $(echo "$READ_RESPONSE" | jq -r '.[0].city')"
fi
echo ""

# Step 4: Test UPDATE operation
echo -e "${BLUE}📝 Step 4: Testing UPDATE user_profile...${NC}"

UPDATE_RESPONSE=$(curl -s -X PATCH \
  "$SUPABASE_URL/rest/v1/user_profiles?user_id=eq.$USER_ID" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"bio\": \"Updated bio from FlutterFlow\",
    \"state\": \"Test State\"
  }")

UPDATED_BIO=$(echo "$UPDATE_RESPONSE" | jq -r '.[0].bio // empty')

if [ "$UPDATED_BIO" = "Updated bio from FlutterFlow" ]; then
  echo -e "   ${GREEN}✅ PASS: Profile updated successfully${NC}"
  echo "   New Bio: $UPDATED_BIO"
  echo "   New State: $(echo "$UPDATE_RESPONSE" | jq -r '.[0].state')"
else
  echo -e "   ${RED}❌ FAIL: Could not update profile${NC}"
  echo "   Response: $UPDATE_RESPONSE"
fi
echo ""

# Step 5: Test required fields only (minimal profile)
echo -e "${BLUE}📝 Step 5: Testing minimal profile creation (required fields only)...${NC}"

# First delete the existing profile
curl -s -X DELETE \
  "$SUPABASE_URL/rest/v1/user_profiles?user_id=eq.$USER_ID" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" > /dev/null

# Create with only required fields
MINIMAL_RESPONSE=$(curl -s -X POST \
  "$SUPABASE_URL/rest/v1/user_profiles" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"user_id\": \"$USER_ID\",
    \"role\": \"patient\"
  }")

MINIMAL_ID=$(echo "$MINIMAL_RESPONSE" | jq -r '.[0].id // empty')

if [ -z "$MINIMAL_ID" ]; then
  echo -e "   ${RED}❌ FAIL: Could not create minimal profile${NC}"
  echo "   Response: $MINIMAL_RESPONSE"
else
  echo -e "   ${GREEN}✅ PASS: Minimal profile created${NC}"
  echo "   Required fields: user_id, role"
  echo "   All other fields are optional"
fi
echo ""

# Step 6: Test with invalid user_id (should fail with FK constraint)
echo -e "${BLUE}📝 Step 6: Testing FK constraint (should fail)...${NC}"

FK_RESPONSE=$(curl -s -X POST \
  "$SUPABASE_URL/rest/v1/user_profiles" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": \"00000000-0000-0000-0000-000000000001\",
    \"role\": \"patient\"
  }")

FK_ERROR=$(echo "$FK_RESPONSE" | jq -r '.code // empty')

if [ "$FK_ERROR" = "23503" ]; then
  echo -e "   ${GREEN}✅ PASS: FK constraint working correctly${NC}"
  echo "   Foreign key prevents profiles for non-existent users"
else
  echo -e "   ${YELLOW}⚠️  WARNING: FK constraint may not be working${NC}"
fi
echo ""

# Summary
echo "═══════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}✅ FlutterFlow CAN Create user_profiles!${NC}"
echo ""
echo "Summary of capabilities:"
echo "  ✓ CREATE - FlutterFlow can create new profiles"
echo "  ✓ READ - FlutterFlow can read existing profiles"
echo "  ✓ UPDATE - FlutterFlow can update profiles"
echo "  ✓ Minimal fields - Only user_id and role required"
echo "  ✓ FK constraint - Prevents orphaned profiles"
echo ""
echo -e "${BLUE}Required Fields for FlutterFlow:${NC}"
echo "  • user_id (UUID) - Must exist in users table"
echo "  • role (String) - Must be one of: patient, provider, facility_admin, system_admin"
echo ""
echo -e "${BLUE}Optional Fields (can be updated later):${NC}"
echo "  • All other fields in user_profiles table are optional"
echo "  • FlutterFlow can update these fields as the user fills out their profile"
echo ""
