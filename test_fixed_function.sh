#!/bin/bash
# Test script for verifying the fixed onUserCreated function
# Created: 2025-11-11

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 TESTING FIXED onUserCreated FUNCTION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Configuration
SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="${SUPABASE_SERVICE_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM}"
EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase"
EHRBASE_USER="ehrbase-admin"
EHRBASE_PASS="EvenMoreSecretPassword"

# Get most recent user from Firebase Auth export
echo "📝 Step 1: Getting most recent Firebase Auth user..."
firebase auth:export /tmp/users_current.json --project medzen-bf20e --format json 2>&1 | grep -v "Exporting"
LATEST_EMAIL=$(jq -r '.users | sort_by(.createdAt) | reverse | .[0].email' /tmp/users_current.json)
FIREBASE_UID=$(jq -r '.users | sort_by(.createdAt) | reverse | .[0].localId' /tmp/users_current.json)

echo "✅ Latest user: $LATEST_EMAIL (Firebase UID: $FIREBASE_UID)"
echo ""

# Check Supabase Auth
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 2: Checking Supabase Auth..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

AUTH_RESPONSE=$(curl -s "$SUPABASE_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

SUPABASE_USER_ID=$(echo "$AUTH_RESPONSE" | jq -r ".users[] | select(.email == \"$LATEST_EMAIL\") | .id")

if [ -z "$SUPABASE_USER_ID" ]; then
  echo "❌ FAILED: Supabase Auth user not found"
  exit 1
fi

echo "✅ Supabase Auth user found"
echo "   User ID: $SUPABASE_USER_ID"
echo ""

# Check users table
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 3: Checking users table..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

USERS_RESPONSE=$(curl -s "$SUPABASE_URL/rest/v1/users?id=eq.$SUPABASE_USER_ID&select=id,firebase_uid,email,phone_number" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

if [ "$(echo "$USERS_RESPONSE" | jq '. | length')" -eq 0 ]; then
  echo "❌ FAILED: users table entry not found"
  exit 1
fi

echo "✅ users table entry found"
echo "$USERS_RESPONSE" | jq '.'
echo ""

# Check EHRbase EHR
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 4: Checking EHRbase EHR..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get EHR ID from electronic_health_records table
EHR_RECORD=$(curl -s "$SUPABASE_URL/rest/v1/electronic_health_records?patient_id=eq.$SUPABASE_USER_ID&select=ehr_id,created_at" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

EHR_ID=$(echo "$EHR_RECORD" | jq -r '.[0].ehr_id // empty')

if [ -z "$EHR_ID" ]; then
  echo "❌ FAILED: No EHR record found in electronic_health_records table"
  echo "This means the function failed at Step 3 (EHRbase EHR creation)"
  echo ""
  echo "🔍 Checking recent function logs..."
  firebase functions:log --only onUserCreated --project medzen-bf20e | head -50
  exit 1
fi

echo "✅ EHR record found in electronic_health_records table"
echo "   EHR ID: $EHR_ID"
echo ""

# Verify EHR exists in EHRbase
echo "📝 Step 5: Verifying EHR in EHRbase..."
EHRBASE_RESPONSE=$(curl -s -u "$EHRBASE_USER:$EHRBASE_PASS" \
  "$EHRBASE_URL/rest/openehr/v1/ehr/$EHR_ID")

if echo "$EHRBASE_RESPONSE" | jq -e '.error' > /dev/null; then
  echo "❌ FAILED: EHR not found in EHRbase"
  echo "Response: $EHRBASE_RESPONSE"
  exit 1
fi

echo "✅ EHR verified in EHRbase"
echo "$EHRBASE_RESPONSE" | jq '{ehr_id: .ehr_id, time_created: .time_created, system_id: .system_id}'
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 SUCCESS! All 4 steps verified:"
echo "   ✅ Step 1: Firebase Auth"
echo "   ✅ Step 2: Supabase Auth"
echo "   ✅ Step 3: Supabase users table"
echo "   ✅ Step 4: EHRbase EHR"
echo "   ✅ Step 5: electronic_health_records linkage"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
