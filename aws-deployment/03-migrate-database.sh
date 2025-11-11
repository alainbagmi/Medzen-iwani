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

if [ -d "dev-export-"* 2>/dev/null ] && [ -f dev-export-*/schema/ehrbase_schema.sql ]; then
    echo ""
    echo "=========================================="
    echo "Step 2: Exporting Database from Proxmox"
    echo "=========================================="
    echo ""

    if [ -f "ehrbase_backup.dump" ]; then
        echo -e "${YELLOW}!${NC} Backup file already exists: ehrbase_backup.dump"
        read -p "Use existing backup? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Creating new backup..."
            mv ehrbase_backup.dump ehrbase_backup.dump.old
        else
            echo "Using existing backup file"
            SKIP_EXPORT=true
        fi
    fi

    if [ "$SKIP_EXPORT" != "true" ]; then
        # Check kubectl connectivity
        if ! kubectl cluster-info &> /dev/null; then
            echo -e "${RED}Error:${NC} Cannot connect to Kubernetes cluster"
            echo ""
            echo "Manual export required:"
            echo "1. SSH to Proxmox: ssh root@$PROXMOX_HOST"
            echo "2. Find PostgreSQL pod:"
            echo "   kubectl get pods -n $PROXMOX_K8S_NAMESPACE | grep postgres"
            echo "3. Export database:"
            echo "   kubectl exec -n $PROXMOX_K8S_NAMESPACE <POD_NAME> -- \\"
            echo "   pg_dump -U ehrbase -d ehrbase --no-owner --no-acl \\"
            echo "   --format=custom --file=/tmp/ehrbase_backup.dump"
            echo "4. Copy to local machine:"
            echo "   kubectl cp $PROXMOX_K8S_NAMESPACE/<POD_NAME>:/tmp/ehrbase_backup.dump ./ehrbase_backup.dump"
            echo ""
            read -p "Press Enter when backup file is ready in current directory..."
        else
            # Automatic export
            echo "Finding PostgreSQL pod..."
            POSTGRES_POD=$(kubectl get pods -n $PROXMOX_K8S_NAMESPACE -l app=postgresql -o jsonpath='{.items[0].metadata.name}')

            if [ -z "$POSTGRES_POD" ]; then
                echo -e "${RED}Error:${NC} PostgreSQL pod not found"
                exit 1
            fi

            echo -e "${GREEN}✓${NC} Found pod: $POSTGRES_POD"
            echo ""
            echo "Exporting database..."
            kubectl exec -n $PROXMOX_K8S_NAMESPACE $POSTGRES_POD -- \
                pg_dump -U ehrbase -d ehrbase --no-owner --no-acl \
                --format=custom --file=/tmp/ehrbase_backup.dump

            echo -e "${GREEN}✓${NC} Database exported to pod"
            echo ""
            echo "Copying backup to local machine..."
            kubectl cp $PROXMOX_K8S_NAMESPACE/$POSTGRES_POD:/tmp/ehrbase_backup.dump ./ehrbase_backup.dump

            echo -e "${GREEN}✓${NC} Backup copied: ehrbase_backup.dump"
        fi
    fi

    # Verify backup file
    if [ ! -f "ehrbase_backup.dump" ]; then
        echo -e "${RED}Error:${NC} Backup file not found: ehrbase_backup.dump"
        exit 1
    fi

    BACKUP_SIZE=$(du -h ehrbase_backup.dump | cut -f1)
    echo ""
    echo -e "${BLUE}Backup file info:${NC}"
    echo "  File: ehrbase_backup.dump"
    echo "  Size: $BACKUP_SIZE"
    echo ""

    ############################################################################
    # 3. IMPORT TO RDS
    ############################################################################

    echo "=========================================="
    echo "Step 3: Importing Database to RDS"
    echo "=========================================="
    echo ""

    read -p "Start database import? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted"
        exit 1
    fi

    echo "Importing database (this may take several minutes)..."
    PGPASSWORD=$DB_ADMIN_PASS pg_restore \
        -h $RDS_ENDPOINT \
        -U ehrbase_admin \
        -d ehrbase \
        --no-owner \
        --no-acl \
        --verbose \
        ehrbase_backup.dump 2>&1 | tee import.log

    echo ""
    echo -e "${GREEN}✓${NC} Database import completed"
    echo -e "${BLUE}Import log saved to: import.log${NC}"

else
    echo ""
    echo -e "${YELLOW}⚠${NC}  Skipping database migration (SKIP_DATABASE_MIGRATION=true)"
    echo "  Starting with fresh database"
fi

################################################################################
# 4. VERIFY MIGRATION
################################################################################

echo ""
echo "=========================================="
echo "Step 4: Verifying Database Migration"
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

# Count tables (if migration was done)
if [ "$SKIP_DATABASE_MIGRATION" = "false" ]; then
    echo "Counting tables..."
    TABLE_COUNT=$(PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'ehr';" | tr -d ' ')
    echo -e "${GREEN}✓${NC} Tables in ehr schema: $TABLE_COUNT"

    # Check for EHR records
    if [ $TABLE_COUNT -gt 0 ]; then
        EHR_COUNT=$(PGPASSWORD=$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -t -c "SELECT COUNT(*) FROM ehr.ehr;" 2>/dev/null | tr -d ' ' || echo "0")
        echo -e "${GREEN}✓${NC} EHR records: $EHR_COUNT"
    fi
fi

################################################################################
# SUMMARY
################################################################################

echo ""
echo "=========================================="
echo "Database Migration Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}Database Status:${NC}"
echo "  Endpoint: $RDS_ENDPOINT:5432"
echo "  Database: ehrbase"
echo "  Schemas: ehr, ext"
echo "  Users: ehrbase_admin, ehrbase_restricted"
echo "  Extensions: uuid-ossp"
if [ "$SKIP_DATABASE_MIGRATION" = "false" ]; then
    echo "  Tables: $TABLE_COUNT"
    echo "  EHR Records: $EHR_COUNT"
fi
echo ""
echo -e "${GREEN}Next step:${NC}"
echo "  ./04-setup-ecs.sh"
echo ""
