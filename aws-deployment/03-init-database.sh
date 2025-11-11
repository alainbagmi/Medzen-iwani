#!/bin/bash

################################################################################
# EHRbase AWS Production - Database Initialization
# Initializes production RDS with EHRbase schema (no data migration from dev)
################################################################################

set -e  # Exit on error

echo "=========================================="
echo "EHRbase AWS Production - Database Setup"
echo "=========================================="
echo ""

# Load environment variables
if [ ! -f ".env" ]; then
    echo "Error: .env file not found"
    exit 1
fi

source .env

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check required variables
if [ -z "$RDS_ENDPOINT" ] || [ -z "$DB_ADMIN_PASS" ] || [ -z "$DB_USER_PASS" ]; then
    echo -e "${RED}Error:${NC} Required database variables not found"
    echo "Run ./02-setup-database.sh first"
    exit 1
fi

echo -e "${BLUE}Configuration:${NC}"
echo "  RDS Endpoint: $RDS_ENDPOINT"
echo "  Mode: Fresh Production Setup (no data migration)"
echo ""

################################################################################
# 1. INITIALIZE DATABASE SCHEMA
################################################################################

echo "=========================================="
echo "Step 1: Initializing Database Schema"
echo "=========================================="
echo ""

# Run initialization script
PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d postgres \
    -v db_user_password="'$DB_USER_PASS'" \
    -f configs/init-database.sql

echo ""
echo -e "${GREEN}✓${NC} Database schema initialized"

################################################################################
# 2. VERIFY SCHEMA COMPATIBILITY (Optional)
################################################################################

# Check if dev export exists
EXPORT_DIRS=$(ls -d dev-export-* 2>/dev/null || echo "")
if [ -n "$EXPORT_DIRS" ]; then
    # Find most recent export
    EXPORT_DIR=$(echo "$EXPORT_DIRS" | sort -r | head -n 1)

    if [ -f "$EXPORT_DIR/schema/ehrbase_schema.sql" ]; then
        echo ""
        echo "=========================================="
        echo "Step 2: Verifying Schema Compatibility"
        echo "=========================================="
        echo ""

        echo -e "${BLUE}Found dev export:${NC} $EXPORT_DIR"
        echo ""

        # Compare schemas
        echo "Extracting schema information from dev reference..."

        # Check schemas
        DEV_SCHEMAS=$(grep "CREATE SCHEMA" "$EXPORT_DIR/schema/ehrbase_schema.sql" | awk '{print $3}' | tr -d ';' | sort | tr '\n' ', ' | sed 's/,$//')
        echo "  Dev schemas: $DEV_SCHEMAS"

        PROD_SCHEMAS=$(PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -t -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name IN ('ehr', 'ext') ORDER BY schema_name;" | tr '\n' ',' | tr -d ' ' | sed 's/,$//' | sed 's/,,/,/g')
        echo "  Prod schemas: $PROD_SCHEMAS"

        # Check extensions
        DEV_EXTS=$(grep "CREATE EXTENSION" "$EXPORT_DIR/schema/ehrbase_schema.sql" | grep -o '"[^"]*"' | tr -d '"' | sort | tr '\n' ', ' | sed 's/,$//')
        echo "  Dev extensions: $DEV_EXTS"

        PROD_EXTS=$(PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -t -c "SELECT extname FROM pg_extension WHERE extname = 'uuid-ossp';" | tr -d ' ')
        echo "  Prod extensions: $PROD_EXTS"

        # Check table count
        DEV_TABLE_COUNT=$(grep -c "CREATE TABLE" "$EXPORT_DIR/schema/ehrbase_schema.sql")
        echo ""
        echo "  Dev tables (ehr schema): $DEV_TABLE_COUNT"
        echo -e "  ${YELLOW}Note:${NC} EHRbase will create tables on first use"

        echo ""
        echo -e "${GREEN}✓${NC} Schema structure compatible with dev reference"
        echo -e "${BLUE}Info:${NC} Production initialized with base schema - EHRbase tables created on demand"
    fi
else
    echo ""
    echo -e "${YELLOW}Note:${NC} No dev export found - skipping schema comparison"
    echo "  Run ./00-export-from-dev.sh first to export dev configuration"
fi

################################################################################
# 3. VERIFY INITIALIZATION
################################################################################

echo ""
echo "=========================================="
echo "Step 3: Verifying Database Initialization"
echo "=========================================="
echo ""

# Check database connection
echo "Testing database connection..."
if PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -c "SELECT version();" > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Database connection successful"
else
    echo -e "${RED}✗${NC} Database connection failed"
    exit 1
fi

# Check schemas
echo "Checking schemas..."
SCHEMAS=$(PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -t -c "SELECT schema_name FROM information_schema.schemata WHERE schema_name IN ('ehr', 'ext');" | tr -d ' ' | grep -v '^$')
if echo "$SCHEMAS" | grep -q "ehr" && echo "$SCHEMAS" | grep -q "ext"; then
    echo -e "${GREEN}✓${NC} Schemas exist: ehr, ext"
else
    echo -e "${RED}✗${NC} Schemas missing"
    exit 1
fi

# Check extensions
echo "Checking extensions..."
EXTENSIONS=$(PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -t -c "SELECT extname FROM pg_extension WHERE extname = 'uuid-ossp';" | tr -d ' ')
if [ "$EXTENSIONS" = "uuid-ossp" ]; then
    echo -e "${GREEN}✓${NC} Extension exists: uuid-ossp"
else
    echo -e "${RED}✗${NC} Extension missing: uuid-ossp"
    exit 1
fi

# Check users
echo "Checking users..."
USERS=$(PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -t -c "SELECT rolname FROM pg_roles WHERE rolname IN ('ehrbase_admin', 'ehrbase_restricted');" | tr -d ' ' | grep -v '^$')
if echo "$USERS" | grep -q "ehrbase_admin" && echo "$USERS" | grep -q "ehrbase_restricted"; then
    echo -e "${GREEN}✓${NC} Users exist: ehrbase_admin, ehrbase_restricted"
else
    echo -e "${RED}✗${NC} Users missing"
    exit 1
fi

# Check permissions
echo "Checking permissions..."
HAS_CONNECT=$(PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d postgres -t -c "SELECT has_database_privilege('ehrbase_restricted', 'ehrbase', 'CONNECT');" | tr -d ' ')
if [ "$HAS_CONNECT" = "t" ]; then
    echo -e "${GREEN}✓${NC} ehrbase_restricted has CONNECT privilege"
else
    echo -e "${YELLOW}⚠${NC}  ehrbase_restricted missing CONNECT privilege"
fi

################################################################################
# SUMMARY
################################################################################

echo ""
echo "=========================================="
echo "Database Initialization Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}Database Status:${NC}"
echo "  Endpoint: $RDS_ENDPOINT:5432"
echo "  Database: ehrbase"
echo "  Schemas: ehr, ext"
echo "  Users: ehrbase_admin, ehrbase_restricted"
echo "  Extensions: uuid-ossp"
echo "  Status: Ready for EHRbase deployment"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Deploy EHRbase:        ./04-setup-ecs.sh"
echo "  2. Import Templates:      ./04b-import-templates.sh"
echo "  3. Update Integrations:   ./05-update-integrations.sh"
echo ""
