#!/bin/bash
echo "=============================================================================="
echo "Testing Updated onUserCreated Function"
echo "=============================================================================="
echo ""

SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

# Generate unique test email
TEST_EMAIL="test-updated-$(date +%s)@medzen-test.com"

echo "📝 Step 1: Creating Firebase Auth user..."
echo "   Email: $TEST_EMAIL"
echo ""

# Create Firebase user
firebase_response=$(curl -s -X POST 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyCWGcgzxeKgytwlIVMs6_7Dmu0e2EEmBTQ' \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"TestPassword123!\",\"returnSecureToken\":true}")

firebase_uid=$(echo "$firebase_response" | python3 -c "import sys, json; print(json.load(sys.stdin).get('localId', ''))")

if [ -z "$firebase_uid" ]; then
  echo "❌ Failed to create Firebase user"
  echo "Response: $firebase_response"
  exit 1
fi

echo "✅ Firebase user created: $firebase_uid"
echo ""

echo "⏳ Waiting 15 seconds for Cloud Function to execute..."
sleep 15
echo ""

echo "=============================================================================="
echo "📝 Step 2: Checking Supabase Auth..."
echo "=============================================================================="

auth_response=$(curl -s "$SUPABASE_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

supabase_user=$(echo "$auth_response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for user in data.get('users', []):
    if user.get('email') == '$TEST_EMAIL':
        print(json.dumps(user, indent=2))
        sys.exit(0)
")

if [ -z "$supabase_user" ]; then
  echo "❌ Supabase Auth user NOT found"
  exit 1
fi

echo "✅ Supabase Auth user found:"
echo "$supabase_user" | python3 -m json.tool
echo ""

supabase_id=$(echo "$supabase_user" | python3 -c "import sys, json; print(json.load(sys.stdin).get('id', ''))")

echo "=============================================================================="
echo "📝 Step 3: Checking Supabase users table..."
echo "=============================================================================="

table_response=$(curl -s "$SUPABASE_URL/rest/v1/users?id=eq.$supabase_id&select=id,firebase_uid,email" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

echo "Response: $table_response"
echo ""

table_count=$(echo "$table_response" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))")

if [ "$table_count" -eq "0" ]; then
  echo "❌ Users table record NOT found"
  exit 1
fi

echo "✅ Users table record found:"
echo "$table_response" | python3 -m json.tool
echo ""

# Verify firebase_uid matches
table_firebase_uid=$(echo "$table_response" | python3 -c "import sys, json; print(json.load(sys.stdin)[0].get('firebase_uid', ''))")

if [ "$table_firebase_uid" != "$firebase_uid" ]; then
  echo "❌ Firebase UID mismatch!"
  echo "   Expected: $firebase_uid"
  echo "   Got: $table_firebase_uid"
  exit 1
fi

echo "=============================================================================="
echo "🎉 SUCCESS! All checks passed:"
echo "=============================================================================="
echo "✅ Firebase Auth user created: $firebase_uid"
echo "✅ Supabase Auth user created: $supabase_id"
echo "✅ Supabase users table record created"
echo "✅ Firebase UID matches: $table_firebase_uid"
echo ""
echo "Test Email: $TEST_EMAIL"
echo "=============================================================================="
