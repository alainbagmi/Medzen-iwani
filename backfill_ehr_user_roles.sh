#!/bin/bash

# Backfill User Roles to Existing EHR_STATUS Records
# This script updates all existing EHR records in EHRbase with user_role field

set -e

SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

echo "=============================================================================="
echo "Backfilling User Roles to Existing EHR Records"
echo "=============================================================================="
echo ""

# Step 1: Get all users with EHR records
echo "📝 Step 1: Fetching all users with EHR records..."
USERS_WITH_EHR=$(curl -s "$SUPABASE_URL/rest/v1/electronic_health_records?select=patient_id,ehr_id,user_role,users(id,email,first_name,last_name)" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

USER_COUNT=$(echo "$USERS_WITH_EHR" | jq '. | length')
echo "Found $USER_COUNT users with EHR records"
echo ""

# Step 2: Process each user
echo "📝 Step 2: Queueing demographics sync for each user..."
PROCESSED=0
QUEUED=0
FAILED=0

for row in $(echo "$USERS_WITH_EHR" | jq -r '.[] | @base64'); do
  _jq() {
    echo ${row} | base64 --decode | jq -r ${1}
  }

  PATIENT_ID=$(_jq '.patient_id')
  EHR_ID=$(_jq '.ehr_id')
  USER_ROLE=$(_jq '.user_role')
  USER_EMAIL=$(_jq '.users.email')

  echo "Processing: $USER_EMAIL (Role: $USER_ROLE)"

  # Trigger demographics sync by updating the user record (minimal update)
  UPDATE_RESULT=$(curl -s -X PATCH "$SUPABASE_URL/rest/v1/users?id=eq.$PATIENT_ID" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d "{\"updated_at\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"}")

  if [ $? -eq 0 ]; then
    QUEUED=$((QUEUED + 1))
    echo "  ✅ Queued demographics sync"
  else
    FAILED=$((FAILED + 1))
    echo "  ❌ Failed to queue sync"
  fi

  PROCESSED=$((PROCESSED + 1))

  # Small delay to avoid rate limiting
  sleep 0.5
done

echo ""
echo "=============================================================================="
echo "Summary"
echo "=============================================================================="
echo "Total users processed: $PROCESSED"
echo "Successfully queued:   $QUEUED"
echo "Failed:               $FAILED"
echo ""

if [ $QUEUED -gt 0 ]; then
  echo "✅ Backfill initiated for $QUEUED users"
  echo ""
  echo "Next steps:"
  echo "1. Wait 30-60 seconds for edge function to process queue"
  echo "2. Manually invoke sync-to-ehrbase: curl -X POST '$SUPABASE_URL/functions/v1/sync-to-ehrbase' -H 'Authorization: Bearer $SERVICE_KEY'"
  echo "3. Check sync status: SELECT * FROM ehrbase_sync_queue WHERE sync_type='demographics' ORDER BY updated_at DESC;"
  echo "4. Verify in EHRbase: Run test_demographics_trigger.sh for sample users"
else
  echo "⚠️  No users were queued for backfill"
fi
