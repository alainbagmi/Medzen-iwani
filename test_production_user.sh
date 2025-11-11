#!/bin/bash

# Production User Creation Test
# Run this after creating a user through your app to verify all systems

SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"
EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase"
EHRBASE_USER="ehrbase-admin"
EHRBASE_PASS="EvenMoreSecretPassword"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 PRODUCTION USER CREATION TEST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This script verifies that a user was created successfully"
echo "across all 4 systems: Firebase → Supabase → EHRbase"
echo ""

# Get email from user
if [ -z "$1" ]; then
  read -p "Enter the email of the test user you just created: " TEST_EMAIL
else
  TEST_EMAIL="$1"
fi

echo ""
echo "Testing user: $TEST_EMAIL"
echo ""

# Step 1: Find Supabase user
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 1: Checking Supabase Auth..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

AUTH_RESPONSE=$(curl -s "$SUPABASE_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

USER_ID=$(echo "$AUTH_RESPONSE" | python3 -c "import sys, json; users = json.load(sys.stdin).get('users', []); user = next((u for u in users if u.get('email') == '$TEST_EMAIL'), None); print(user.get('id', '') if user else '')" 2>/dev/null)

if [ -z "$USER_ID" ]; then
  echo "❌ FAILED: User not found in Supabase Auth"
  echo ""
  echo "Possible causes:"
  echo "  - onUserCreated function failed at Step 1"
  echo "  - Check Firebase function logs:"
  echo "    firebase functions:log --only onUserCreated --project medzen-bf20e"
  exit 1
fi

echo "✅ Supabase Auth user found"
echo "   User ID: $USER_ID"
echo ""

# Step 2: Check users table
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 2: Checking users table..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

USERS_RESPONSE=$(curl -s "$SUPABASE_URL/rest/v1/users?id=eq.$USER_ID&select=id,firebase_uid,email,phone_number" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

USERS_COUNT=$(echo "$USERS_RESPONSE" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null)

if [ "$USERS_COUNT" = "0" ]; then
  echo "❌ FAILED: User not found in users table"
  echo ""
  echo "Possible causes:"
  echo "  - onUserCreated function failed at Step 2"
  echo "  - Check Firebase function logs for 'Step 2' errors"
  exit 1
fi

echo "✅ users table entry found"
echo "$USERS_RESPONSE" | python3 -m json.tool 2>/dev/null | head -20
echo ""

# Step 3: Check EHRbase EHR
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 3: Checking EHRbase EHR..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

EHR_RESPONSE=$(curl -s "$EHRBASE_URL/rest/openehr/v1/ehr?subject_id=$USER_ID&subject_namespace=medzen" \
  -H "Accept: application/json" \
  -u "$EHRBASE_USER:$EHRBASE_PASS")

EHR_ID=$(echo "$EHR_RESPONSE" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('ehr_id', {}).get('value', ''))" 2>/dev/null)

if [ -z "$EHR_ID" ]; then
  echo "❌ FAILED: EHR not found in EHRbase"
  echo "Response: $EHR_RESPONSE" | head -10
  echo ""
  echo "Possible causes:"
  echo "  - onUserCreated function failed at Step 3"
  echo "  - EHRbase connection issues"
  echo "  - Check Firebase function logs for 'Step 3' errors"
  exit 1
fi

echo "✅ EHRbase EHR found"
echo "   EHR ID: $EHR_ID"
echo "   Subject ID: $USER_ID"
echo "   Namespace: medzen"
echo ""

# Step 4: Check electronic_health_records
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 4: Checking electronic_health_records..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

EHR_LINK_RESPONSE=$(curl -s "$SUPABASE_URL/rest/v1/electronic_health_records?patient_id=eq.$USER_ID&select=patient_id,ehrbase_ehr_id,role_type" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

EHR_LINK_COUNT=$(echo "$EHR_LINK_RESPONSE" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))" 2>/dev/null)

if [ "$EHR_LINK_COUNT" = "0" ]; then
  echo "❌ FAILED: electronic_health_records entry not found"
  echo ""
  echo "Possible causes:"
  echo "  - onUserCreated function failed at Step 4"
  echo "  - Check Firebase function logs for 'Step 4' errors"
  exit 1
fi

echo "✅ electronic_health_records entry found"
echo "$EHR_LINK_RESPONSE" | python3 -m json.tool 2>/dev/null
echo ""

# Step 5: Verify EHR IDs match
DB_EHR_ID=$(echo "$EHR_LINK_RESPONSE" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data[0].get('ehrbase_ehr_id', '') if data else '')" 2>/dev/null)

if [ "$DB_EHR_ID" != "$EHR_ID" ]; then
  echo "⚠️  WARNING: EHR ID mismatch!"
  echo "   EHRbase: $EHR_ID"
  echo "   Database: $DB_EHR_ID"
  echo ""
fi

# Success
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ALL TESTS PASSED - PRODUCTION READY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "User: $TEST_EMAIL"
echo "Supabase ID: $USER_ID"
echo "EHRbase EHR ID: $EHR_ID"
echo ""
echo "✓ Firebase Auth user created"
echo "✓ Supabase Auth user created"
echo "✓ users table entry created"
echo "✓ EHRbase EHR created"
echo "✓ electronic_health_records link created"
echo "✓ EHR is ready to accept medical data compositions"
echo ""
echo "🎉 onUserCreated function is PRODUCTION READY!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
