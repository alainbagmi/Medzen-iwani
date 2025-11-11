#!/bin/bash
echo "=============================================================================="
echo "FIREBASE vs SUPABASE - User Comparison"
echo "=============================================================================="
echo ""
echo "🔥 FIREBASE AUTH USERS:"
echo "------------------------------------------------------------------------------"
gcloud auth application-default print-access-token 2>/dev/null | head -1 > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Firebase users would be listed here via Firebase Admin SDK"
    echo "   (Requires GOOGLE_APPLICATION_CREDENTIALS)"
else
    echo "⚠️  Cannot list Firebase users via CLI (requires service account)"
    echo "   But we know the user exists from the signup API response:"
    echo ""
    echo "   Email: test-verification-1762748536@medzen-test.com"
    echo "   UID:   BsMVrYMboue8K3GlP7rOksAa7G22"
    echo ""
    echo "   You can verify at:"
    echo "   https://console.firebase.google.com/project/medzen-bf20e/authentication/users"
fi

echo ""
echo "=============================================================================="
echo ""
echo "💧 SUPABASE AUTH USERS:"
echo "------------------------------------------------------------------------------"

SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

response=$(curl -s "$SUPABASE_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

user_count=$(echo "$response" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['users']))" 2>/dev/null || echo "0")

if [ "$user_count" -gt 0 ]; then
    echo "✅ Found $user_count user(s) in Supabase Auth:"
    echo ""
    echo "$response" | python3 -m json.tool | grep -A 8 '"email"' | head -20
    echo ""
    echo "Full details:"
    echo "$response" | python3 -m json.tool
else
    echo "❌ No users found in Supabase Auth"
fi

echo ""
echo "=============================================================================="
echo "📍 WHERE TO FIND IN SUPABASE:"
echo "------------------------------------------------------------------------------"
echo "1. Go to: https://supabase.com/dashboard/project/noaeltglphdlkbflipit/auth/users"
echo "2. Click: Authentication (left sidebar) → Users (top tab)"
echo "3. You should see: test-verification-1762748536@medzen-test.com"
echo ""
echo "❌ DON'T look in: Database → Table Editor → users (that's a different table)"
echo "=============================================================================="
