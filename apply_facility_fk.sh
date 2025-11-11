#!/bin/bash

# Apply facility foreign key migration
# This script connects to Supabase PostgreSQL directly

# Supabase connection details
SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SUPABASE_DB_HOST="aws-0-us-east-2.pooler.supabase.com"
SUPABASE_DB_PORT="6543"
SUPABASE_DB_NAME="postgres"
SUPABASE_DB_USER="postgres.noaeltglphdlkbflipit"

# Get password from environment or prompt
if [ -z "$SUPABASE_DB_PASSWORD" ]; then
    echo "Please set SUPABASE_DB_PASSWORD environment variable"
    echo "Example: export SUPABASE_DB_PASSWORD='your-password'"
    exit 1
fi

echo "Connecting to Supabase database..."
echo "Host: $SUPABASE_DB_HOST"
echo "Database: $SUPABASE_DB_NAME"
echo ""

# Run the migration
PGPASSWORD="$SUPABASE_DB_PASSWORD" psql \
    -h "$SUPABASE_DB_HOST" \
    -p "$SUPABASE_DB_PORT" \
    -U "$SUPABASE_DB_USER" \
    -d "$SUPABASE_DB_NAME" \
    -f fix_facility_foreign_key.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Migration applied successfully!"
    echo ""
    echo "Verifying changes..."

    # Verify the changes
    PGPASSWORD="$SUPABASE_DB_PASSWORD" psql \
        -h "$SUPABASE_DB_HOST" \
        -p "$SUPABASE_DB_PORT" \
        -U "$SUPABASE_DB_USER" \
        -d "$SUPABASE_DB_NAME" \
        -c "SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'medical_provider_profiles' AND column_name = 'facility_id';"
else
    echo ""
    echo "❌ Migration failed. Check the error messages above."
    exit 1
fi
