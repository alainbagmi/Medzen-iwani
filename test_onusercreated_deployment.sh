#!/bin/bash
# Complete test script for onUserCreated function after deployment
# Creates a NEW user and verifies all 4 systems
# Created: 2025-11-11

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 COMPLETE onUserCreated TEST - POST DEPLOYMENT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Configuration
SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="${SUPABASE_SERVICE_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM}"
EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase"
EHRBASE_USER="ehrbase-admin"
EHRBASE_PASS="EvenMoreSecretPassword"

# Generate unique test email
TIMESTAMP=$(date +%s)
TEST_EMAIL="test-function-${TIMESTAMP}@medzen-test.com"
TEST_PASSWORD="TestPass123!"

echo "📝 Creating test user in Firebase Auth..."
echo "   Email: $TEST_EMAIL"
echo ""

# Create user using Firebase Auth REST API
USER_CREATE_RESPONSE=$(curl -s -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyCWGcgzxeKgytwlIVMs6_7Dmu0e2EEmBTQ" \
  -H 'Content-Type: application/json' \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"returnSecureToken\": true
  }")

# Check for error
if echo "$USER_CREATE_RESPONSE" | jq -e '.error' > /dev/null; then
  echo "❌ FAILED: Could not create Firebase user"
  echo "$USER_CREATE_RESPONSE" | jq '.error'
  exit 1
fi

FIREBASE_UID=$(echo "$USER_CREATE_RESPONSE" | jq -r '.localId')
echo "✅ Firebase Auth user created"
echo "   Firebase UID: $FIREBASE_UID"
echo ""

echo "⏳ Waiting 10 seconds for Cloud Function to complete..."
sleep 10
echo ""

# Step 1: Check Supabase Auth
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 1: Checking Supabase Auth..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

AUTH_RESPONSE=$(curl -s "$SUPABASE_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

SUPABASE_USER_ID=$(echo "$AUTH_RESPONSE" | jq -r ".users[] | select(.email == \"$TEST_EMAIL\") | .id")

if [ -z "$SUPABASE_USER_ID" ]; then
  echo "❌ FAILED: Supabase Auth user not found"
  echo "   This means onUserCreated failed at Step 1"
  echo ""
  echo "🔍 Checking function logs..."
  firebase functions:log --only onUserCreated --project medzen-bf20e | head -30
  exit 1
fi

echo "✅ Supabase Auth user found"
echo "   User ID: $SUPABASE_USER_ID"
echo ""

# Step 2: Check users table
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 2: Checking users table..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

USERS_RESPONSE=$(curl -s "$SUPABASE_URL/rest/v1/users?id=eq.$SUPABASE_USER_ID&select=id,firebase_uid,email" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

if [ "$(echo "$USERS_RESPONSE" | jq '. | length')" -eq 0 ]; then
  echo "❌ FAILED: users table entry not found"
  echo "   This means onUserCreated failed at Step 2"
  exit 1
fi

echo "✅ users table entry found"
echo "$USERS_RESPONSE" | jq '.'
echo ""

# Step 3: Check electronic_health_records
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 3: Checking electronic_health_records..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

EHR_RECORD=$(curl -s "$SUPABASE_URL/rest/v1/electronic_health_records?patient_id=eq.$SUPABASE_USER_ID&select=ehr_id,created_at" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

EHR_ID=$(echo "$EHR_RECORD" | jq -r '.[0].ehr_id // empty')

if [ -z "$EHR_ID" ]; then
  echo "❌ FAILED: No EHR record found in electronic_health_records table"
  echo "   This means onUserCreated failed at Step 3 (EHRbase EHR creation)"
  echo ""
  echo "🔍 Checking function logs for this user..."
  firebase functions:log --only onUserCreated --project medzen-bf20e | grep -A 20 "$TEST_EMAIL"
  exit 1
fi

echo "✅ EHR record found in electronic_health_records table"
echo "   EHR ID: $EHR_ID"
echo "   Created: $(echo "$EHR_RECORD" | jq -r '.[0].created_at')"
echo ""

# Step 4: Verify EHR in EHRbase
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 4: Verifying EHR in EHRbase..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

EHRBASE_RESPONSE=$(curl -s -u "$EHRBASE_USER:$EHRBASE_PASS" \
  "$EHRBASE_URL/rest/openehr/v1/ehr/$EHR_ID")

if echo "$EHRBASE_RESPONSE" | jq -e '.error' > /dev/null; then
  echo "❌ FAILED: EHR not found in EHRbase"
  echo "Response: $EHRBASE_RESPONSE"
  exit 1
fi

echo "✅ EHR verified in EHRbase"
echo "$EHRBASE_RESPONSE" | jq '{
  ehr_id: .ehr_id.value,
  system_id: .system_id.value,
  time_created: .time_created.value
}'
echo ""

# Step 5: Show function logs for this execution
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 5: Function execution logs..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

firebase functions:log --only onUserCreated --project medzen-bf20e | grep -A 30 "$TEST_EMAIL" || echo "No logs found yet (may take a moment to appear)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 SUCCESS! User creation verified across all 4 systems:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   ✅ Firebase Auth:              $FIREBASE_UID"
echo "   ✅ Supabase Auth:              $SUPABASE_USER_ID"
echo "   ✅ Supabase users table:       ✓ Record created"
echo "   ✅ EHRbase EHR:                $EHR_ID"
echo "   ✅ electronic_health_records:  ✓ Linkage created"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test user credentials (for cleanup if needed):"
echo "   Email: $TEST_EMAIL"
echo "   Firebase UID: $FIREBASE_UID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
