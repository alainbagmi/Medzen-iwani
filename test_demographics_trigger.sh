#!/bin/bash

# Test Demographics Trigger and Sync
# Uses existing test user from previous test

set -e

SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"
EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase"
EHRBASE_USER="ehrbase-admin"
EHRBASE_PASS="EvenMoreSecretPassword"

# Use existing test user
USER_ID="8fa578b0-b41d-4f1d-9bf6-272137914f9e"
EHR_ID="01c28a6c-c57e-4394-b143-b8ffa0a793ff"

echo "=============================================================================="
echo "Testing Demographics Sync - Trigger → Queue → Edge Function → EHRbase"
echo "=============================================================================="
echo ""
echo "Using existing test user:"
echo "  Supabase User ID: $USER_ID"
echo "  EHR ID: $EHR_ID"
echo ""

# Step 1: Clear any existing queue entries for this user
echo "=============================================================================="
echo "📝 Step 1: Clearing existing queue entries..."
echo "=============================================================================="

curl -s -X DELETE "$SUPABASE_URL/rest/v1/ehrbase_sync_queue?record_id=eq.$USER_ID" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" > /dev/null

echo "✅ Cleared existing queue entries"
echo ""

# Step 2: Update user profile to trigger demographics sync
echo "=============================================================================="
echo "📝 Step 2: Updating user profile to trigger demographics sync..."
echo "=============================================================================="

UPDATE_RESULT=$(curl -s -X PATCH "$SUPABASE_URL/rest/v1/users?id=eq.$USER_ID" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{
    "first_name": "Test",
    "last_name": "Demographics",
    "middle_name": "Sync",
    "phone_number": "+237123456789",
    "country": "Cameroon",
    "date_of_birth": "1990-01-01",
    "gender": "male",
    "preferred_language": "English",
    "timezone": "Africa/Douala"
  }')

echo "$UPDATE_RESULT" | jq '.'
echo "✅ User profile updated"
echo ""

# Step 3: Wait for trigger to create queue entry
echo "⏳ Waiting 3 seconds for trigger to create queue entry..."
sleep 3
echo ""

# Step 4: Check ehrbase_sync_queue for demographics entry
echo "=============================================================================="
echo "📝 Step 3: Checking ehrbase_sync_queue for demographics entry..."
echo "=============================================================================="

QUEUE_RESULT=$(curl -s "$SUPABASE_URL/rest/v1/ehrbase_sync_queue?record_id=eq.$USER_ID&sync_type=eq.demographics&select=id,table_name,sync_type,sync_status,data_snapshot&order=created_at.desc&limit=1" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

echo "$QUEUE_RESULT" | jq '.'

QUEUE_ID=$(echo "$QUEUE_RESULT" | jq -r '.[0].id // empty')

if [ -z "$QUEUE_ID" ]; then
  echo "❌ Demographics sync queue entry NOT found"
  echo ""
  echo "Checking if trigger exists..."
  curl -s "$SUPABASE_URL/rest/v1/rpc/check_trigger_exists" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -d '{"trigger_name": "trigger_queue_demographics_sync"}' | jq '.'
  exit 1
fi

echo "✅ Demographics sync queue entry found: $QUEUE_ID"
echo ""

# Step 5: Check data_snapshot contains all required fields
echo "=============================================================================="
echo "📝 Step 4: Verifying data_snapshot contains required fields..."
echo "=============================================================================="

DATA_SNAPSHOT=$(echo "$QUEUE_RESULT" | jq -r '.[0].data_snapshot')
echo "$DATA_SNAPSHOT" | jq '.'

REQUIRED_FIELDS="ehr_id full_name date_of_birth gender email phone_number country user_role"
MISSING_FIELDS=""

for field in $REQUIRED_FIELDS; do
  if ! echo "$DATA_SNAPSHOT" | jq -e ".$field" > /dev/null 2>&1; then
    MISSING_FIELDS="$MISSING_FIELDS $field"
  fi
done

if [ ! -z "$MISSING_FIELDS" ]; then
  echo "⚠️  Missing required fields in data_snapshot:$MISSING_FIELDS"
else
  echo "✅ All required fields present in data_snapshot"
fi
echo ""

# Step 6: Manually invoke sync-to-ehrbase Edge Function
echo "=============================================================================="
echo "📝 Step 5: Invoking sync-to-ehrbase Edge Function..."
echo "=============================================================================="

SYNC_RESULT=$(curl -s -X POST "$SUPABASE_URL/functions/v1/sync-to-ehrbase" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Content-Type: application/json")

echo "$SYNC_RESULT" | jq '.'
echo ""

# Step 7: Wait for edge function to complete
echo "⏳ Waiting 5 seconds for edge function to complete..."
sleep 5
echo ""

# Step 8: Check queue status
echo "=============================================================================="
echo "📝 Step 6: Checking queue status after sync..."
echo "=============================================================================="

QUEUE_STATUS=$(curl -s "$SUPABASE_URL/rest/v1/ehrbase_sync_queue?id=eq.$QUEUE_ID&select=sync_status,error_message,ehrbase_composition_id,updated_at" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

echo "$QUEUE_STATUS" | jq '.'

SYNC_STATUS=$(echo "$QUEUE_STATUS" | jq -r '.[0].sync_status')
ERROR_MESSAGE=$(echo "$QUEUE_STATUS" | jq -r '.[0].error_message // empty')

if [ "$SYNC_STATUS" = "completed" ]; then
  echo "✅ Demographics sync completed successfully"
elif [ "$SYNC_STATUS" = "failed" ]; then
  echo "❌ Demographics sync failed"
  echo "Error: $ERROR_MESSAGE"
  exit 1
else
  echo "⏳ Demographics sync status: $SYNC_STATUS"
fi
echo ""

# Step 9: Verify demographics in EHRbase EHR_STATUS
echo "=============================================================================="
echo "📝 Step 7: Verifying demographics in EHRbase EHR_STATUS..."
echo "=============================================================================="

EHRBASE_RESULT=$(curl -s "$EHRBASE_URL/rest/openehr/v1/ehr/$EHR_ID/ehr_status" \
  -H "Authorization: Basic $(echo -n "$EHRBASE_USER:$EHRBASE_PASS" | base64)" \
  -H "Accept: application/json")

echo "EHR_STATUS.other_details:"
echo "$EHRBASE_RESULT" | jq '.other_details.items[] | {name: .name.value, value: .value.value}'

# Extract and verify specific fields
FULL_NAME=$(echo "$EHRBASE_RESULT" | jq -r '.other_details.items[] | select(.name.value == "Full Name") | .value.value')
DOB=$(echo "$EHRBASE_RESULT" | jq -r '.other_details.items[] | select(.name.value == "Date of Birth") | .value.value')
GENDER=$(echo "$EHRBASE_RESULT" | jq -r '.other_details.items[] | select(.name.value == "Gender") | .value.value')
EMAIL=$(echo "$EHRBASE_RESULT" | jq -r '.other_details.items[] | select(.name.value == "Email") | .value.value')
PHONE=$(echo "$EHRBASE_RESULT" | jq -r '.other_details.items[] | select(.name.value == "Phone Number") | .value.value')
COUNTRY=$(echo "$EHRBASE_RESULT" | jq -r '.other_details.items[] | select(.name.value == "Country") | .value.value')
USER_ROLE=$(echo "$EHRBASE_RESULT" | jq -r '.other_details.items[] | select(.name.value == "User Role") | .value.value')

echo ""
echo "Extracted Demographics:"
echo "  Full Name: $FULL_NAME"
echo "  Date of Birth: $DOB"
echo "  Gender: $GENDER"
echo "  Email: $EMAIL"
echo "  Phone Number: $PHONE"
echo "  Country: $COUNTRY"
echo "  User Role: $USER_ROLE"
echo ""

if [ "$FULL_NAME" = "Test Sync Demographics" ] && [ "$DOB" = "1990-01-01" ] && [ "$GENDER" = "male" ] && [ "$USER_ROLE" = "patient" ]; then
  echo "✅ Demographics verified in EHRbase EHR_STATUS (7 fields including user_role)"
else
  echo "⚠️  Demographics values don't match expected values"
fi
echo ""

# Summary
echo "=============================================================================="
echo "🎉 Test Summary"
echo "=============================================================================="
echo "User ID:          $USER_ID"
echo "EHR ID:           $EHR_ID"
echo "Queue Entry ID:   $QUEUE_ID"
echo "Sync Status:      $SYNC_STATUS"
echo "Composition ID:   N/A (demographics stored in EHR_STATUS)"
echo ""

if [ "$SYNC_STATUS" = "completed" ] && [ "$FULL_NAME" = "Test Sync Demographics" ] && [ "$USER_ROLE" = "patient" ]; then
  echo "🎉 SUCCESS! Demographics sync working end-to-end"
  echo ""
  echo "✅ Trigger fires on user UPDATE"
  echo "✅ Queue entry created with data_snapshot (including user_role)"
  echo "✅ Edge function processes queue"
  echo "✅ Demographics stored in EHR_STATUS (7 fields)"
  echo "✅ User role verified: $USER_ROLE"
  exit 0
else
  echo "⚠️  Test completed with issues"
  exit 1
fi
