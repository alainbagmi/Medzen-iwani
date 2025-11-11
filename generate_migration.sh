#!/bin/bash

# Migration Generator Script
# Generates a new Supabase migration file with timestamp and template structure
# Usage: ./generate_migration.sh <migration_name> [table_name]

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if migration name provided
if [ -z "$1" ]; then
    echo -e "${RED}❌ Error: Migration name required${NC}"
    echo "Usage: ./generate_migration.sh <migration_name> [table_name]"
    echo "Example: ./generate_migration.sh create_user_profiles user_profiles"
    exit 1
fi

MIGRATION_NAME=$1
TABLE_NAME=${2:-""}
TIMESTAMP=$(date -u +"%Y%m%d%H%M%S")
MIGRATION_FILE="supabase/migrations/${TIMESTAMP}_${MIGRATION_NAME}.sql"

echo -e "${BLUE}📝 Generating migration file...${NC}"
echo "Migration name: $MIGRATION_NAME"
echo "Timestamp: $TIMESTAMP"
echo "File: $MIGRATION_FILE"

# Create migration file with template
if [ -n "$TABLE_NAME" ]; then
    # Template with table creation
    cat > "$MIGRATION_FILE" << EOF
-- Migration: $MIGRATION_NAME
-- Created: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
-- Table: $TABLE_NAME

-- Create table
CREATE TABLE IF NOT EXISTS public.$TABLE_NAME (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
    -- Add your columns here
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_${TABLE_NAME}_created_at ON public.$TABLE_NAME(created_at);
CREATE INDEX IF NOT EXISTS idx_${TABLE_NAME}_updated_at ON public.$TABLE_NAME(updated_at);

-- Enable Row Level Security
ALTER TABLE public.$TABLE_NAME ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own ${TABLE_NAME}"
    ON public.$TABLE_NAME
    FOR SELECT
    USING (auth.uid() = user_id); -- Adjust based on your auth column

CREATE POLICY "Users can insert their own ${TABLE_NAME}"
    ON public.$TABLE_NAME
    FOR INSERT
    WITH CHECK (auth.uid() = user_id); -- Adjust based on your auth column

CREATE POLICY "Users can update their own ${TABLE_NAME}"
    ON public.$TABLE_NAME
    FOR UPDATE
    USING (auth.uid() = user_id); -- Adjust based on your auth column

-- Create updated_at trigger
CREATE TRIGGER set_${TABLE_NAME}_updated_at
    BEFORE UPDATE ON public.$TABLE_NAME
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- Add comments
COMMENT ON TABLE public.$TABLE_NAME IS 'TODO: Add table description';
EOF
else
    # Generic template
    cat > "$MIGRATION_FILE" << EOF
-- Migration: $MIGRATION_NAME
-- Created: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

-- Add your SQL commands here

-- Example:
-- ALTER TABLE public.users ADD COLUMN new_column TEXT;
-- CREATE INDEX idx_new_column ON public.users(new_column);
EOF
fi

echo -e "${GREEN}✅ Migration file created successfully!${NC}"
echo -e "${YELLOW}📄 Location: $MIGRATION_FILE${NC}"
echo ""
echo "Next steps:"
echo "1. Edit the migration file to add your schema changes"
echo "2. Test locally: npx supabase db reset"
echo "3. Apply to production: npx supabase db push"
echo ""
echo -e "${BLUE}💡 Tip: Don't forget to:${NC}"
echo "   - Update PowerSync schema (lib/powersync/schema.dart)"
echo "   - Create Dart model file (lib/backend/supabase/database/tables/)"
echo "   - Add export to database.dart"
echo "   - Update sync rules if needed (POWERSYNC_SYNC_RULES.yaml)"
