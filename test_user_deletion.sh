#!/bin/bash
# Test script for verifying onUserDeleted function
# Deletes a Firebase user and verifies deletion across all systems
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

# User to delete
FIREBASE_UID="OIxua8BeqlQIfiBsfcds07ltr2j1"
SUPABASE_USER_ID="e7ed893a-7d05-4117-b007-cd95581ece26"
EHR_ID="e07b070b-8e48-4b66-a8f2-dec7be47596a"

echo "📝 Deleting user from Firebase Auth..."
echo "   Firebase UID: $FIREBASE_UID"
echo ""

# Delete user via Node.js script (uses Firebase Admin SDK from firebase/functions)
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/firebase/functions
node ../../delete_test_user.js $FIREBASE_UID

if [ $? -ne 0 ]; then
  echo "❌ FAILED: Could not delete Firebase user"
  exit 1
fi

echo "✅ Firebase Auth user deleted"
echo ""

echo "⏳ Waiting 10 seconds for Cloud Function to complete..."
sleep 10
echo ""

# Verify deletions
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 1: Checking Supabase Auth..."
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
echo "📝 Step 2: Checking users table..."
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
echo "📝 Step 3: Checking electronic_health_records..."
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
echo "📝 Step 4: Verifying EHR preserved in EHRbase (should NOT be deleted)..."
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
echo "📝 Step 5: Function execution logs..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

firebase functions:log --only onUserDeleted --project medzen-bf20e | head -30
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
