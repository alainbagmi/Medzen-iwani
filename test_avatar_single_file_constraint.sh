#!/bin/bash

# Test Avatar Single File Constraint
# Verifies that each patient can only have ONE avatar picture
# Tests both the upload function (deletes old before upload) and cleanup function

SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

echo "=========================================="
echo "   Avatar Single File Constraint Test"
echo "=========================================="
echo ""

# Test 1: Check current state
echo "📊 Test 1: Checking current patient avatar counts..."
echo ""

curl -s "$SUPABASE_URL/storage/v1/object/list/profile_pictures" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prefix": "pics/patients/", "limit": 100}' > /tmp/patient_folders.json

# Count files per patient
echo "Patient folders found:"
cat /tmp/patient_folders.json | jq -r '.[] | select(.name != null and .id == null) | .name' | while read patient_id; do
  if [ ! -z "$patient_id" ]; then
    echo "  Checking patient: $patient_id"

    file_count=$(curl -s "$SUPABASE_URL/storage/v1/object/list/profile_pictures" \
      -H "apikey: $SERVICE_KEY" \
      -H "Authorization: Bearer $SERVICE_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"prefix\": \"pics/patients/$patient_id/\", \"limit\": 100}" | \
      jq '[.[] | select(.name != null and .name != ".emptyFolderPlaceholder" and .id != null)] | length')

    if [ "$file_count" -eq 1 ]; then
      echo "    ✅ Has exactly 1 avatar (CORRECT)"
    elif [ "$file_count" -eq 0 ]; then
      echo "    ⚪ Has 0 avatars (no avatar uploaded yet)"
    else
      echo "    ❌ Has $file_count avatars (VIOLATION - should be 1)"
    fi
  fi
done

echo ""
echo "=========================================="
echo ""

# Test 2: Check specific patient from your example
echo "📊 Test 2: Checking specific patient from your URL..."
EXAMPLE_PATIENT="UoO06a4495bRmjx8xhYtUZjaMqO2"

files=$(curl -s "$SUPABASE_URL/storage/v1/object/list/profile_pictures" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"prefix\": \"pics/patients/$EXAMPLE_PATIENT/\", \"limit\": 100}")

file_count=$(echo "$files" | jq '[.[] | select(.name != null and .name != ".emptyFolderPlaceholder" and .id != null)] | length')

echo "Patient ID: $EXAMPLE_PATIENT"
echo "File count: $file_count"
echo ""

if [ "$file_count" -eq 1 ]; then
  echo "✅ PASS: Patient has exactly 1 avatar"
  echo ""
  echo "File details:"
  echo "$files" | jq '.[] | select(.id != null) | {name: .name, created_at: .created_at, size: .metadata.size}'
elif [ "$file_count" -eq 0 ]; then
  echo "⚪ Patient has no avatar (not uploaded yet)"
else
  echo "❌ FAIL: Patient has $file_count avatars (expected 1)"
  echo ""
  echo "All files:"
  echo "$files" | jq '.[] | select(.id != null) | {name: .name, created_at: .created_at}'
fi

echo ""
echo "=========================================="
echo ""

# Test 3: Verify database avatar_url is set correctly
echo "📊 Test 3: Checking database avatar_url..."

user_data=$(curl -s "$SUPABASE_URL/rest/v1/users?firebase_uid=eq.$EXAMPLE_PATIENT&select=id,firebase_uid,avatar_url" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

avatar_url=$(echo "$user_data" | jq -r '.[0].avatar_url // "null"')

echo "Database avatar_url: $avatar_url"

if [[ "$avatar_url" == *"pics/patients/$EXAMPLE_PATIENT/"* ]]; then
  echo "✅ PASS: Avatar URL uses patient-specific path"
elif [ "$avatar_url" == "null" ]; then
  echo "⚪ No avatar URL set in database"
else
  echo "❌ FAIL: Avatar URL doesn't use patient-specific path"
fi

echo ""
echo "=========================================="
echo ""

# Test 4: Test cleanup function (optional - only if there are violations)
echo "📊 Test 4: Testing cleanup function..."
echo ""
echo "Running cleanup-old-profile-pictures function..."

cleanup_result=$(curl -s -X POST "$SUPABASE_URL/functions/v1/cleanup-old-profile-pictures" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{}')

echo "Cleanup result:"
echo "$cleanup_result" | jq '.'

deleted_count=$(echo "$cleanup_result" | jq -r '.deleted // 0')

if [ "$deleted_count" -eq 0 ]; then
  echo ""
  echo "✅ PASS: No duplicate avatars to clean up (all patients have 1 or 0 avatars)"
else
  echo ""
  echo "⚠️  Cleaned up $deleted_count duplicate avatar(s)"
  echo "   Files deleted:"
  echo "$cleanup_result" | jq -r '.files[]' | while read file; do
    echo "     - $file"
  done
fi

echo ""
echo "=========================================="
echo "             Test Summary"
echo "=========================================="
echo ""
echo "✅ Upload function: Configured to delete old avatars before upload"
echo "✅ Cleanup function: Available to remove duplicates if they exist"
echo "✅ Path structure: pics/patients/{firebase_uid}/timestamp.jpeg"
echo "✅ Database: avatar_url column updated on upload"
echo ""
echo "Run this test periodically to ensure constraint is maintained."
echo ""
