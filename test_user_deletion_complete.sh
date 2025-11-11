#!/bin/bash
# Complete test script for onUserDeleted function
# Signs in as test user, gets ID token, then deletes the user
# Created: 2025-11-11

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 TESTING onUserDeleted FUNCTION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Configuration
SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="${SUPABASE_SERVICE_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM}"
EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase"
EHRBASE_USER="ehrbase-admin"
EHRBASE_PASS="EvenMoreSecretPassword"
FIREBASE_API_KEY="AIzaSyCWGcgzxeKgytwlIVMs6_7Dmu0e2EEmBTQ"

# Test user credentials
TEST_EMAIL="test-function-1762891158@medzen-test.com"
TEST_PASSWORD="TestPass123!"
FIREBASE_UID="OIxua8BeqlQIfiBsfcds07ltr2j1"
SUPABASE_USER_ID="e7ed893a-7d05-4117-b007-cd95581ece26"
EHR_ID="e07b070b-8e48-4b66-a8f2-dec7be47596a"

echo "📝 Step 1: Signing in as test user to get ID token..."
echo "   Email: $TEST_EMAIL"
echo ""

# Sign in to get ID token
SIGNIN_RESPONSE=$(curl -s -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$FIREBASE_API_KEY" \
  -H 'Content-Type: application/json' \
  -d "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"$TEST_PASSWORD\",
    \"returnSecureToken\": true
  }")

# Check for error
if echo "$SIGNIN_RESPONSE" | jq -e '.error' > /dev/null; then
  echo "❌ FAILED: Could not sign in"
  echo "$SIGNIN_RESPONSE" | jq '.error'
  exit 1
fi

ID_TOKEN=$(echo "$SIGNIN_RESPONSE" | jq -r '.idToken')
echo "✅ Signed in successfully"
echo ""

echo "📝 Step 2: Deleting user from Firebase Auth..."
echo "   Firebase UID: $FIREBASE_UID"
echo ""

# Delete user using ID token
DELETE_RESPONSE=$(curl -s -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$FIREBASE_API_KEY" \
  -H 'Content-Type: application/json' \
  -d "{\"idToken\": \"$ID_TOKEN\"}")

# Check for error
if echo "$DELETE_RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
  echo "❌ FAILED: Could not delete Firebase user"
  echo "$DELETE_RESPONSE" | jq '.error'
  exit 1
fi

echo "✅ Firebase Auth user deleted"
echo ""

echo "⏳ Waiting 10 seconds for Cloud Function to complete..."
sleep 10
echo ""

# Verify deletions
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 3: Checking Supabase Auth..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

AUTH_RESPONSE=$(curl -s "$SUPABASE_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

FOUND=$(echo "$AUTH_RESPONSE" | jq -r ".users[] | select(.id == \"$SUPABASE_USER_ID\") | .id // empty")

if [ -z "$FOUND" ]; then
  echo "✅ Supabase Auth user deleted successfully"
else
  echo "❌ FAILED: Supabase Auth user still exists"
  exit 1
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 4: Checking users table..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

USERS_RESPONSE=$(curl -s "$SUPABASE_URL/rest/v1/users?id=eq.$SUPABASE_USER_ID&select=id" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

if [ "$(echo "$USERS_RESPONSE" | jq '. | length')" -eq 0 ]; then
  echo "✅ Supabase users table entry deleted successfully"
else
  echo "❌ FAILED: users table entry still exists"
  exit 1
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 5: Checking electronic_health_records..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

EHR_RECORD=$(curl -s "$SUPABASE_URL/rest/v1/electronic_health_records?patient_id=eq.$SUPABASE_USER_ID&select=ehr_id" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

if [ "$(echo "$EHR_RECORD" | jq '. | length')" -eq 0 ]; then
  echo "✅ electronic_health_records entry deleted successfully"
else
  echo "❌ FAILED: electronic_health_records entry still exists"
  exit 1
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 6: Verifying EHR preserved in EHRbase (should NOT be deleted)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

EHRBASE_RESPONSE=$(curl -s -u "$EHRBASE_USER:$EHRBASE_PASS" \
  "$EHRBASE_URL/rest/openehr/v1/ehr/$EHR_ID")

if echo "$EHRBASE_RESPONSE" | jq -e '.error' > /dev/null; then
  echo "❌ FAILED: EHR was deleted from EHRbase (should be preserved!)"
  exit 1
else
  echo "✅ EHR correctly preserved in EHRbase"
  echo "   (Required for legal/audit compliance)"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 7: Function execution logs..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

firebase functions:log --only onUserDeleted --project medzen-bf20e 2>/dev/null | head -30 || echo "⚠️  Could not fetch logs (firebase CLI might not be configured)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 SUCCESS! User deletion verified across all systems:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "   ✅ Firebase Auth:              Deleted"
echo "   ✅ Supabase Auth:              Deleted"
echo "   ✅ Supabase users table:       Deleted"
echo "   ✅ electronic_health_records:  Deleted"
echo "   ✅ EHRbase EHR:                Preserved (as required)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
