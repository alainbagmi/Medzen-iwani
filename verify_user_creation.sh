#!/bin/bash

# Verification script for complete user creation flow
# Tests all 4 systems: Firebase Auth -> Supabase Auth -> users table -> EHRbase EHR -> electronic_health_records

set -e

SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"
EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase"
EHRBASE_USER="ehrbase-admin"
EHRBASE_PASS="EvenMoreSecretPassword"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 USER CREATION VERIFICATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get user email from argument or prompt
if [ -z "$1" ]; then
  read -p "Enter the email of the user to verify: " USER_EMAIL
else
  USER_EMAIL="$1"
fi

echo "Verifying user: $USER_EMAIL"
echo ""

# Step 1: Check Supabase Auth
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 STEP 1: Checking Supabase Auth..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SUPABASE_AUTH_RESPONSE=$(curl -s "$SUPABASE_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

SUPABASE_USER_ID=$(echo "$SUPABASE_AUTH_RESPONSE" | grep -o "\"id\":\"[^\"]*\".*\"email\":\"$USER_EMAIL\"" | head -1 | grep -o "\"id\":\"[^\"]*\"" | cut -d'"' -f4)

if [ -z "$SUPABASE_USER_ID" ]; then
  echo "❌ FAILED: Supabase Auth user NOT found for $USER_EMAIL"
  echo ""
  echo "This means the onUserCreated function failed at Step 1."
  echo "Check Firebase function logs:"
  echo "  firebase functions:log --only onUserCreated --project medzen-bf20e"
  exit 1
else
  echo "✅ Supabase Auth user found"
  echo "   User ID: $SUPABASE_USER_ID"
  echo ""
fi

# Step 2: Check users table
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 STEP 2: Checking users table..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

USERS_TABLE_RESPONSE=$(curl -s "$SUPABASE_URL/rest/v1/users?id=eq.$SUPABASE_USER_ID&select=id,firebase_uid,email,first_name,last_name,full_name,avatar_url" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

if echo "$USERS_TABLE_RESPONSE" | grep -q "\"id\":\"$SUPABASE_USER_ID\""; then
  echo "✅ users table entry found"
  echo "$USERS_TABLE_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$USERS_TABLE_RESPONSE"
  echo ""
else
  echo "❌ FAILED: users table entry NOT found for $SUPABASE_USER_ID"
  echo ""
  echo "This means the onUserCreated function failed at Step 2."
  echo "Check Firebase function logs for 'Step 2' errors:"
  echo "  firebase functions:log --only onUserCreated --project medzen-bf20e"
  exit 1
fi

# Step 3: Check EHRbase EHR
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 STEP 3: Checking EHRbase EHR..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

EHRBASE_RESPONSE=$(curl -s "$EHRBASE_URL/rest/openehr/v1/ehr?subject_id=$SUPABASE_USER_ID&subject_namespace=medzen" \
  -H "Accept: application/json" \
  -u "$EHRBASE_USER:$EHRBASE_PASS")

EHR_ID=$(echo "$EHRBASE_RESPONSE" | grep -o '"value":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$EHR_ID" ]; then
  echo "❌ FAILED: EHRbase EHR NOT found for subject_id=$SUPABASE_USER_ID"
  echo "Response: $EHRBASE_RESPONSE"
  echo ""
  echo "This means the onUserCreated function failed at Step 3."
  echo "Check Firebase function logs for 'Step 3' errors:"
  echo "  firebase functions:log --only onUserCreated --project medzen-bf20e"
  exit 1
else
  echo "✅ EHRbase EHR found"
  echo "   EHR ID: $EHR_ID"
  echo "   Subject ID: $SUPABASE_USER_ID"
  echo "   Namespace: medzen"
  echo ""
fi

# Step 4: Check electronic_health_records link
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 STEP 4: Checking electronic_health_records..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

EHR_LINK_RESPONSE=$(curl -s "$SUPABASE_URL/rest/v1/electronic_health_records?patient_id=eq.$SUPABASE_USER_ID&select=patient_id,ehrbase_ehr_id,role_type,created_at" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

if echo "$EHR_LINK_RESPONSE" | grep -q "\"patient_id\":\"$SUPABASE_USER_ID\""; then
  echo "✅ electronic_health_records entry found"
  echo "$EHR_LINK_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$EHR_LINK_RESPONSE"
  echo ""
else
  echo "❌ FAILED: electronic_health_records entry NOT found for $SUPABASE_USER_ID"
  echo ""
  echo "This means the onUserCreated function failed at Step 4."
  echo "Check Firebase function logs for 'Step 4' errors:"
  echo "  firebase functions:log --only onUserCreated --project medzen-bf20e"
  exit 1
fi

# Success summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ALL VERIFICATIONS PASSED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "User: $USER_EMAIL"
echo "Supabase ID: $SUPABASE_USER_ID"
echo "EHRbase EHR ID: $EHR_ID"
echo ""
echo "✓ Step 1: Supabase Auth user created"
echo "✓ Step 2: users table entry created (with first_name, last_name, auto-generated full_name)"
echo "✓ Step 3: EHRbase EHR created"
echo "✓ Step 4: electronic_health_records link created"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
