#!/bin/bash

# ============================================
# Clean Up Old Avatar Files from Supabase Storage
# ============================================
#
# This script deletes ALL files from user-avatars bucket
# Use this to clean up duplicate/old avatar files
#
# WARNING: This will delete ALL avatars!
# Users will need to re-upload their profile pictures.
#
# Run: chmod +x cleanup_old_avatars.sh && ./cleanup_old_avatars.sh
# ============================================

SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Clean Up Old Avatar Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: List all files in user-avatars bucket
echo "📋 Step 1: Listing all files in user-avatars bucket..."
echo ""

FILES=$(curl -s "$SUPABASE_URL/storage/v1/object/list/user-avatars" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"limit": 1000, "offset": 0}')

# Check if we got files
if echo "$FILES" | grep -q "error"; then
  echo "❌ Error listing files:"
  echo "$FILES" | jq '.'
  exit 1
fi

# Count files
FILE_COUNT=$(echo "$FILES" | jq '. | length')
echo "Found $FILE_COUNT files in user-avatars bucket"
echo ""

if [ "$FILE_COUNT" -eq 0 ]; then
  echo "✅ No files to delete. Bucket is already empty."
  exit 0
fi

# Show files
echo "Files to be deleted:"
echo "$FILES" | jq -r '.[].name' | head -20
if [ "$FILE_COUNT" -gt 20 ]; then
  echo "... and $((FILE_COUNT - 20)) more files"
fi
echo ""

# Confirmation
echo "⚠️  WARNING: This will delete ALL $FILE_COUNT files from user-avatars bucket!"
echo "Users will need to re-upload their profile pictures."
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "❌ Cancelled. No files were deleted."
  exit 0
fi

echo ""
echo "🗑️  Step 2: Deleting files..."
echo ""

# Delete each file
DELETED=0
FAILED=0

echo "$FILES" | jq -r '.[].name' | while read -r filename; do
  if [ -z "$filename" ]; then
    continue
  fi

  echo -n "Deleting: $filename ... "

  RESPONSE=$(curl -s -X DELETE \
    "$SUPABASE_URL/storage/v1/object/user-avatars/$filename" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY")

  if echo "$RESPONSE" | grep -q "error"; then
    echo "❌ FAILED"
    echo "Error: $RESPONSE" | jq -r '.error'
    ((FAILED++))
  else
    echo "✅ DELETED"
    ((DELETED++))
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Cleanup Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Total files found: $FILE_COUNT"
echo "Successfully deleted: $DELETED"
echo "Failed to delete: $FAILED"
echo ""

if [ "$FAILED" -eq 0 ]; then
  echo "✅ All files deleted successfully!"
else
  echo "⚠️  Some files failed to delete. Check errors above."
fi

echo ""
echo "Next steps:"
echo "1. Users need to re-upload their profile pictures"
echo "2. Make sure to use fixed filename: {user_id}_avatar.jpg"
echo "3. Use 1024x1024 pixel images for sharp quality"
echo ""
