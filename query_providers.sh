#!/bin/bash

# Query Medical Provider Details from Supabase
# This script retrieves all provider data similar to the GraphQL query

SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

echo "============================================================"
echo "MEDICAL PROVIDER PROFILE DETAILS"
echo "============================================================"
echo ""

# Query 1: Get provider count and summary
echo "=== PROVIDER SUMMARY ==="
curl -s "$SUPABASE_URL/rest/v1/user_profiles?role=in.(provider,doctor,nurse,specialist)&select=user_id,role" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" | jq -r '
  group_by(.role) |
  map({
    role: .[0].role,
    count: length
  }) |
  .[] |
  "\(.role): \(.count)"
' 2>/dev/null

if [ $? -ne 0 ]; then
  echo "No providers found or error occurred"
fi

echo ""
echo "=== PROVIDER USER IDs ==="
PROVIDER_IDS=$(curl -s "$SUPABASE_URL/rest/v1/user_profiles?role=in.(provider,doctor,nurse,specialist)&select=user_id&limit=5" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" | jq -r '.[].user_id' 2>/dev/null)

if [ -z "$PROVIDER_IDS" ]; then
  echo "No provider IDs found"
  echo ""
  echo "Checking if any users exist at all..."
  curl -s "$SUPABASE_URL/rest/v1/users?select=id,email,full_name&limit=5" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" | jq .

  echo ""
  echo "Checking if any user_profiles exist..."
  curl -s "$SUPABASE_URL/rest/v1/user_profiles?select=id,user_id,role&limit=5" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" | jq .

  exit 0
fi

echo "$PROVIDER_IDS"
echo ""

# Get the first provider ID for detailed query
FIRST_PROVIDER_ID=$(echo "$PROVIDER_IDS" | head -1)

if [ -n "$FIRST_PROVIDER_ID" ]; then
  echo "=== DETAILED PROFILE FOR PROVIDER: $FIRST_PROVIDER_ID ==="
  echo ""

  echo "--- User Details ---"
  curl -s "$SUPABASE_URL/rest/v1/users?id=eq.$FIRST_PROVIDER_ID&select=*" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" | jq '.[0]'

  echo ""
  echo "--- User Profile ---"
  curl -s "$SUPABASE_URL/rest/v1/user_profiles?user_id=eq.$FIRST_PROVIDER_ID&select=*" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" | jq '.[0]'

  echo ""
  echo "--- Medical Provider Profile ---"
  curl -s "$SUPABASE_URL/rest/v1/medical_provider_profiles?user_id=eq.$FIRST_PROVIDER_ID&select=*" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" | jq '.[0]'

  echo ""
  echo "--- Provider Facilities ---"
  curl -s "$SUPABASE_URL/rest/v1/provider_facilities?provider_id=eq.$FIRST_PROVIDER_ID&select=*,healthcare_facilities(*)" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" | jq '.'
fi

echo ""
echo "============================================================"
echo "Query complete!"
echo "============================================================"
