#!/bin/bash

################################################################################
# EHRbase AWS Migration - Export Dev Environment Reference
# Exports OpenEHR templates and database schema from Proxmox dev environment
################################################################################

set -e  # Exit on error

echo "=========================================="
echo "EHRbase Dev Environment Export"
echo "=========================================="
echo ""

# Load environment variables
if [ ! -f ".env" ]; then
    echo "Error: .env file not found"
    echo "Run ./00-prerequisites.sh first"
    exit 1
fi

source .env

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Configuration:${NC}"
echo "  Dev EHRbase URL: $DEV_EHRBASE_URL"
echo "  Dev EHRbase User: $DEV_EHRBASE_USER"
echo "  Proxmox K8s Namespace: $PROXMOX_K8S_NAMESPACE"
echo ""

# Create export directory
EXPORT_DIR="dev-export-$(date +%Y%m%d-%H%M%S)"
mkdir -p $EXPORT_DIR/{templates,schema,config}
echo -e "${GREEN}✓${NC} Created export directory: $EXPORT_DIR"

################################################################################
# 1. EXPORT OPENEHR TEMPLATES
################################################################################

echo ""
echo "=========================================="
echo "Step 1: Exporting OpenEHR Templates"
echo "=========================================="
echo ""

echo "Fetching template list from dev EHRbase..."

# Get list of templates
TEMPLATES=$(curl -s -u "${DEV_EHRBASE_USER}:${DEV_EHRBASE_PASS}" \
    "${DEV_EHRBASE_URL}/definition/template/adl1.4" \
    -H "Accept: application/json")

if [ -z "$TEMPLATES" ] || [ "$TEMPLATES" = "[]" ]; then
    echo -e "${YELLOW}⚠${NC}  No templates found in dev EHRbase"
    echo "  This might be normal if templates are loaded dynamically"
else
    # Parse template IDs
    TEMPLATE_IDS=$(echo "$TEMPLATES" | jq -r '.[].template_id' 2>/dev/null || echo "")

    if [ -z "$TEMPLATE_IDS" ]; then
        echo -e "${YELLOW}⚠${NC}  Could not parse template list"
        echo "  Response: $TEMPLATES"
    else
        TEMPLATE_COUNT=$(echo "$TEMPLATE_IDS" | wc -l | tr -d ' ')
        echo -e "${GREEN}✓${NC} Found $TEMPLATE_COUNT templates"
        echo ""

        # Export each template
        for TEMPLATE_ID in $TEMPLATE_IDS; do
            echo "  Exporting: $TEMPLATE_ID"

            # Get template in operational template format
            curl -s -u "${DEV_EHRBASE_USER}:${DEV_EHRBASE_PASS}" \
                "${DEV_EHRBASE_URL}/definition/template/adl1.4/${TEMPLATE_ID}" \
                -H "Accept: application/xml" \
                -o "$EXPORT_DIR/templates/${TEMPLATE_ID}.opt"

            if [ -f "$EXPORT_DIR/templates/${TEMPLATE_ID}.opt" ]; then
                SIZE=$(du -h "$EXPORT_DIR/templates/${TEMPLATE_ID}.opt" | cut -f1)
                echo -e "    ${GREEN}✓${NC} Saved ($SIZE)"
            else
                echo -e "    ${RED}✗${NC} Failed to export"
            fi
        done
    fi
fi

################################################################################
# 2. EXPORT DATABASE SCHEMA
################################################################################

echo ""
echo "=========================================="
echo "Step 2: Exporting Database Schema"
echo "=========================================="
echo ""

# Check kubectl connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error:${NC} Cannot connect to Kubernetes cluster"
    echo ""
    echo "Manual schema export required:"
    echo "1. SSH to Proxmox: ssh root@$PROXMOX_HOST"
    echo "2. Find PostgreSQL pod:"
    echo "   kubectl get pods -n $PROXMOX_K8S_NAMESPACE | grep postgres"
    echo "3. Export schema only (no data):"
    echo "   kubectl exec -n $PROXMOX_K8S_NAMESPACE <POD_NAME> -- \\"
    echo "   pg_dump -U ehrbase -d ehrbase --schema-only \\"
    echo "   --file=/tmp/ehrbase_schema.sql"
    echo "4. Copy to local machine:"
    echo "   kubectl cp $PROXMOX_K8S_NAMESPACE/<POD_NAME>:/tmp/ehrbase_schema.sql ./$EXPORT_DIR/schema/ehrbase_schema.sql"
    echo ""
    read -p "Press Enter when schema file is ready in $EXPORT_DIR/schema/..."
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
    echo "Exporting schema (no data)..."
    kubectl exec -n $PROXMOX_K8S_NAMESPACE $POSTGRES_POD -- \
        pg_dump -U ehrbase -d ehrbase --schema-only \
        --file=/tmp/ehrbase_schema.sql

    echo -e "${GREEN}✓${NC} Schema exported in pod"
    echo ""
    echo "Copying schema to local machine..."
    kubectl cp $PROXMOX_K8S_NAMESPACE/$POSTGRES_POD:/tmp/ehrbase_schema.sql ./$EXPORT_DIR/schema/ehrbase_schema.sql

    if [ -f "$EXPORT_DIR/schema/ehrbase_schema.sql" ]; then
        SIZE=$(du -h "$EXPORT_DIR/schema/ehrbase_schema.sql" | cut -f1)
        echo -e "${GREEN}✓${NC} Schema saved ($SIZE)"
    else
        echo -e "${RED}✗${NC} Failed to copy schema"
        exit 1
    fi
fi

################################################################################
# 3. EXPORT CONFIGURATION REFERENCE
################################################################################

echo ""
echo "=========================================="
echo "Step 3: Documenting Configuration"
echo "=========================================="
echo ""

# Test API endpoints
echo "Testing dev EHRbase endpoints..."

# Status endpoint
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${DEV_EHRBASE_USER}:${DEV_EHRBASE_PASS}" \
    "${DEV_EHRBASE_URL}/status")

echo "  Status endpoint: HTTP $STATUS_CODE"

# Create configuration reference document
cat > $EXPORT_DIR/config/dev-configuration.md << EOF
# Dev EHRbase Configuration Reference

**Export Date:** $(date)
**Export Directory:** $EXPORT_DIR

## API Endpoints

**Base URL:** $DEV_EHRBASE_URL

**Key Endpoints:**
- Status: \`${DEV_EHRBASE_URL}/status\`
- OpenEHR API: \`${DEV_EHRBASE_URL}/rest/openehr/v1\`
- Definitions: \`${DEV_EHRBASE_URL}/definition\`
- Templates: \`${DEV_EHRBASE_URL}/definition/template/adl1.4\`

**Status Check:** HTTP $STATUS_CODE

## Authentication

**Type:** HTTP Basic Authentication
**Username:** $DEV_EHRBASE_USER
**Password:** [stored in .env as DEV_EHRBASE_PASS]

## Database Configuration

**Host:** (from Kubernetes)
**Port:** 5432
**Database:** ehrbase
**Schemas:** ehr, ext
**Extensions:** uuid-ossp

## Exported Templates

EOF

# List exported templates
if [ -d "$EXPORT_DIR/templates" ] && [ "$(ls -A $EXPORT_DIR/templates)" ]; then
    ls -lh $EXPORT_DIR/templates/*.opt | awk '{print "- " $9 " (" $5 ")"}' >> $EXPORT_DIR/config/dev-configuration.md
else
    echo "- No templates exported" >> $EXPORT_DIR/config/dev-configuration.md
fi

cat >> $EXPORT_DIR/config/dev-configuration.md << EOF

## Schema Export

**File:** schema/ehrbase_schema.sql
**Size:** $(du -h $EXPORT_DIR/schema/ehrbase_schema.sql 2>/dev/null | cut -f1 || echo "Not available")

## Integration Points

**Firebase Cloud Functions:**
- onUserCreated: Creates user in Supabase + EHR in EHRbase
- Uses: ehrbase.url, ehrbase.username, ehrbase.password from firebase config

**Supabase Edge Functions:**
- sync-to-ehrbase: Processes ehrbase_sync_queue
- powersync-token: JWT generation for PowerSync
- Uses: EHRBASE_URL, EHRBASE_USERNAME, EHRBASE_PASSWORD from secrets

## Production Migration Notes

1. **Templates:** Import all .opt files to production EHRbase
2. **Schema:** Verify production schema matches dev structure
3. **Authentication:** Generate NEW credentials for production
4. **Integrations:** Update Firebase and Supabase configs with production URL + credentials
5. **Testing:** Verify user creation flow end-to-end

## Schema Verification Checklist

- [ ] Schemas exist: ehr, ext
- [ ] Extension exists: uuid-ossp
- [ ] Users exist: ehrbase_admin, ehrbase_restricted
- [ ] Permissions configured correctly
- [ ] Default search path set to ext
- [ ] intervalstyle set to iso_8601

EOF

echo -e "${GREEN}✓${NC} Configuration documented: $EXPORT_DIR/config/dev-configuration.md"

################################################################################
# 4. CREATE SCHEMA COMPARISON SCRIPT
################################################################################

echo ""
echo "Creating schema comparison script..."

cat > $EXPORT_DIR/schema/compare-schemas.sh << 'EOF'
#!/bin/bash

# Schema Comparison Script
# Compares production RDS schema against dev reference

if [ -z "$1" ]; then
    echo "Usage: ./compare-schemas.sh <RDS_ENDPOINT>"
    exit 1
fi

RDS_ENDPOINT=$1
REFERENCE_SCHEMA="ehrbase_schema.sql"

echo "=========================================="
echo "Schema Comparison"
echo "=========================================="
echo ""
echo "Reference: $REFERENCE_SCHEMA"
echo "Target:    $RDS_ENDPOINT"
echo ""

# Extract schema names from reference
echo "Checking schemas..."
EXPECTED_SCHEMAS=$(grep "CREATE SCHEMA" $REFERENCE_SCHEMA | awk '{print $3}' | sort)
echo "Expected schemas:"
echo "$EXPECTED_SCHEMAS"
echo ""

# Check extensions
echo "Checking extensions..."
EXPECTED_EXTENSIONS=$(grep "CREATE EXTENSION" $REFERENCE_SCHEMA | grep -o '"[^"]*"' | tr -d '"' | sort)
echo "Expected extensions:"
echo "$EXPECTED_EXTENSIONS"
echo ""

# Check table count
echo "Checking tables..."
TABLE_COUNT=$(grep "CREATE TABLE" $REFERENCE_SCHEMA | wc -l | tr -d ' ')
echo "Expected tables: $TABLE_COUNT"
echo ""

echo "To verify production RDS, run:"
echo "  PGPASSWORD=\$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -c '\\dn'"
echo "  PGPASSWORD=\$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -c '\\dx'"
echo "  PGPASSWORD=\$DB_ADMIN_PASS psql -h $RDS_ENDPOINT -U ehrbase_admin -d ehrbase -c '\\dt ehr.*'"
echo ""
EOF

chmod +x $EXPORT_DIR/schema/compare-schemas.sh
echo -e "${GREEN}✓${NC} Schema comparison script created"

################################################################################
# 5. CREATE PRODUCTION IMPORT GUIDE
################################################################################

cat > $EXPORT_DIR/IMPORT_TO_PRODUCTION.md << EOF
# Import to Production Guide

This directory contains exports from the dev EHRbase environment that need to be imported to AWS production.

## Contents

1. **templates/** - OpenEHR templates in OPT format
2. **schema/** - Database schema reference
3. **config/** - Configuration documentation

## Import Steps

### Step 1: Setup AWS Infrastructure
\`\`\`bash
cd ../
./01-setup-infrastructure.sh  # VPC, subnets, security groups
./02-setup-database.sh         # RDS PostgreSQL
\`\`\`

### Step 2: Verify Schema Compatibility
\`\`\`bash
cd $EXPORT_DIR/schema
./compare-schemas.sh <RDS_ENDPOINT>
\`\`\`

### Step 3: Deploy EHRbase
\`\`\`bash
cd ../
./04-setup-ecs.sh              # ECS Fargate + EHRbase
\`\`\`

### Step 4: Import Templates
\`\`\`bash
./04b-import-templates.sh $EXPORT_DIR/templates
\`\`\`

### Step 5: Update Integrations
\`\`\`bash
./05-update-integrations.sh    # Firebase + Supabase configs
\`\`\`

### Step 6: Test Integration
\`\`\`bash
./06-validate-deployment.sh    # End-to-end testing
\`\`\`

## Production Configuration

**New Credentials:**
- Production will use NEW credentials (different from dev)
- Credentials stored in AWS Secrets Manager
- Firebase/Supabase configs will be updated automatically

**Templates:**
- All templates from dev will be imported to production
- Ensures compatibility with existing integration code

**Schema:**
- Production RDS will use same schema structure as dev
- No data migration (fresh production database)

## Verification Checklist

- [ ] All templates imported successfully
- [ ] Schema structure matches dev reference
- [ ] Firebase config updated with production URL
- [ ] Supabase secrets updated with production credentials
- [ ] User creation flow tested end-to-end
- [ ] EHR sync queue processing verified

EOF

################################################################################
# SUMMARY
################################################################################

echo ""
echo "=========================================="
echo "Dev Environment Export Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}Export Location:${NC} $EXPORT_DIR"
echo ""
echo -e "${GREEN}Exported Items:${NC}"

# Count templates
TEMPLATE_COUNT=$(ls $EXPORT_DIR/templates/*.opt 2>/dev/null | wc -l | tr -d ' ')
echo "  Templates:      $TEMPLATE_COUNT files"

# Check schema
if [ -f "$EXPORT_DIR/schema/ehrbase_schema.sql" ]; then
    SCHEMA_SIZE=$(du -h "$EXPORT_DIR/schema/ehrbase_schema.sql" | cut -f1)
    echo "  Schema:         $SCHEMA_SIZE"
else
    echo "  Schema:         Not exported"
fi

echo "  Configuration:  dev-configuration.md"
echo "  Import Guide:   IMPORT_TO_PRODUCTION.md"
echo ""

echo -e "${BLUE}Files Created:${NC}"
echo "  $EXPORT_DIR/templates/          - OpenEHR template files (.opt)"
echo "  $EXPORT_DIR/schema/ehrbase_schema.sql  - Database schema"
echo "  $EXPORT_DIR/schema/compare-schemas.sh  - Schema comparison script"
echo "  $EXPORT_DIR/config/dev-configuration.md - Dev config reference"
echo "  $EXPORT_DIR/IMPORT_TO_PRODUCTION.md    - Import guide"
echo ""

echo -e "${YELLOW}Important:${NC}"
echo "  - Review dev-configuration.md for API endpoints and auth"
echo "  - Templates will be imported during production setup"
echo "  - Schema reference used for verification (not applied directly)"
echo "  - Production will use NEW credentials"
echo ""

echo -e "${GREEN}Next step:${NC}"
echo "  ./01-setup-infrastructure.sh  (or review exported files first)"
echo ""
