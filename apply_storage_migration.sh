#!/bin/bash

# Apply Storage Migration to Supabase
# This script manually applies the storage buckets migration

echo "🚀 Applying storage migration to Supabase..."
echo ""

# Migration file
MIGRATION_FILE="supabase/migrations/20251106000001_fix_storage_buckets_setup.sql"

# Check if migration file exists
if [ ! -f "$MIGRATION_FILE" ]; then
    echo "❌ Error: Migration file not found: $MIGRATION_FILE"
    exit 1
fi

echo "📄 Migration file: $MIGRATION_FILE"
echo ""

# Apply using npx supabase db push
echo "Applying migration..."
npx supabase db push --include-all

echo ""
echo "✅ Migration application complete!"
echo ""

# Verify buckets created
echo "🔍 Verifying storage buckets..."
curl -s "https://noaeltglphdlkbflipit.supabase.co/storage/v1/bucket" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM" | python3 -m json.tool

echo ""
echo "✅ Done! Check output above for buckets: user-avatars, facility-images, documents"
