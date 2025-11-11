#!/bin/bash

################################################################################
# EHRbase AWS Production - Update Integrations
# Updates Firebase Cloud Functions and Supabase Edge Functions with AWS EHRbase
################################################################################

set -e  # Exit on error

echo "=========================================="
echo "EHRbase Production - Update Integrations"
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
if [ -z "$ALB_DNS" ]; then
    echo -e "${RED}Error:${NC} ALB_DNS not found in .env"
    echo "Run ./04-setup-ecs.sh first"
    exit 1
fi

if [ -z "$EHRBASE_USER_PASS" ]; then
    echo -e "${RED}Error:${NC} EHRBASE_USER_PASS not found"
    echo "Run ./02-setup-database.sh first"
    exit 1
fi

EHRBASE_URL="http://${ALB_DNS}/ehrbase/rest"
EHRBASE_USER="ehrbase-user"

echo -e "${BLUE}Production EHRbase Configuration:${NC}"
echo "  URL:      $EHRBASE_URL"
echo "  Username: $EHRBASE_USER"
echo "  Password: [stored in AWS Secrets Manager]"
echo ""

################################################################################
# 1. UPDATE FIREBASE CLOUD FUNCTIONS
################################################################################

echo "=========================================="
echo "Step 1: Updating Firebase Cloud Functions"
echo "=========================================="
echo ""

# Check if Firebase is configured
if ! firebase --version > /dev/null 2>&1; then
    echo -e "${RED}Error:${NC} Firebase CLI not found"
    echo "Install with: npm install -g firebase-tools"
    exit 1
fi

# Check if logged in
if ! firebase projects:list > /dev/null 2>&1; then
    echo -e "${RED}Error:${NC} Not logged into Firebase"
    echo "Run: firebase login"
    exit 1
fi

# Check if in Firebase project directory
if [ ! -f "firebase/firebase.json" ] && [ ! -f "../firebase/firebase.json" ]; then
    echo -e "${YELLOW}⚠${NC}  Firebase directory not found in current or parent directory"
    echo ""
    read -p "Enter path to Firebase project directory (or press Enter to skip): " FIREBASE_DIR

    if [ -n "$FIREBASE_DIR" ]; then
        if [ ! -d "$FIREBASE_DIR" ]; then
            echo -e "${RED}Error:${NC} Directory not found: $FIREBASE_DIR"
            exit 1
        fi
        cd "$FIREBASE_DIR"
    else
        echo -e "${YELLOW}Skipping Firebase configuration${NC}"
        SKIP_FIREBASE=true
    fi
fi

if [ "$SKIP_FIREBASE" != "true" ]; then
    # Check if we're in the right directory
    if [ ! -f "firebase.json" ] && [ -f "firebase/firebase.json" ]; then
        cd firebase
    fi

    echo "Current Firebase project:"
    FIREBASE_PROJECT=$(firebase projects:list | grep -v "Project" | grep -v "^$" | head -n 1 | awk '{print $1}')
    echo "  $FIREBASE_PROJECT"
    echo ""

    read -p "Update Firebase Cloud Functions config for this project? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Setting Firebase Cloud Functions configuration..."

        firebase functions:config:set \
            ehrbase.url="${EHRBASE_URL}" \
            ehrbase.username="${EHRBASE_USER}" \
            ehrbase.password="${EHRBASE_USER_PASS}"

        echo ""
        echo -e "${GREEN}✓${NC} Firebase configuration updated"
        echo ""
        echo -e "${YELLOW}Important:${NC} Deploy functions for changes to take effect"
        echo "  cd firebase/functions && firebase deploy --only functions"
        echo ""

        read -p "Deploy Firebase Functions now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Deploying Firebase Functions..."
            cd functions
            firebase deploy --only functions
            cd ../
            echo -e "${GREEN}✓${NC} Firebase Functions deployed"
        else
            echo -e "${YELLOW}⚠${NC}  Firebase Functions not deployed - deploy manually later"
        fi
    else
        echo "Skipped Firebase configuration"
    fi

    # Return to deployment directory
    if [ -d "../aws-deployment" ]; then
        cd ../aws-deployment
    elif [ -d "aws-deployment" ]; then
        cd aws-deployment
    fi
fi

################################################################################
# 2. UPDATE SUPABASE EDGE FUNCTIONS
################################################################################

echo ""
echo "=========================================="
echo "Step 2: Updating Supabase Edge Functions"
echo "=========================================="
echo ""

# Check if Supabase CLI is configured
if ! npx supabase --version > /dev/null 2>&1; then
    echo -e "${RED}Error:${NC} Supabase CLI not found"
    echo "Install with: npm install -g supabase"
    exit 1
fi

# Check if in Supabase project directory
if [ ! -f "supabase/config.toml" ] && [ ! -f "../supabase/config.toml" ]; then
    echo -e "${YELLOW}⚠${NC}  Supabase directory not found in current or parent directory"
    echo ""
    read -p "Enter path to project directory with supabase/ folder (or press Enter to skip): " SUPABASE_DIR

    if [ -n "$SUPABASE_DIR" ]; then
        if [ ! -d "$SUPABASE_DIR" ]; then
            echo -e "${RED}Error:${NC} Directory not found: $SUPABASE_DIR"
            exit 1
        fi
        cd "$SUPABASE_DIR"
    else
        echo -e "${YELLOW}Skipping Supabase configuration${NC}"
        SKIP_SUPABASE=true
    fi
fi

if [ "$SKIP_SUPABASE" != "true" ]; then
    # Check if linked to a project
    if ! npx supabase projects list > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠${NC}  Not linked to a Supabase project"
        echo "Run: npx supabase link"
        SKIP_SUPABASE=true
    fi
fi

if [ "$SKIP_SUPABASE" != "true" ]; then
    echo "Updating Supabase Edge Function secrets..."

    # Set secrets for EHRbase connection
    npx supabase secrets set \
        EHRBASE_URL="${EHRBASE_URL}" \
        EHRBASE_USERNAME="${EHRBASE_USER}" \
        EHRBASE_PASSWORD="${EHRBASE_USER_PASS}"

    echo ""
    echo -e "${GREEN}✓${NC} Supabase secrets updated"
    echo ""
    echo -e "${BLUE}Updated secrets:${NC}"
    echo "  EHRBASE_URL"
    echo "  EHRBASE_USERNAME"
    echo "  EHRBASE_PASSWORD"
    echo ""

    # List edge functions that might need redeployment
    echo "Edge functions that use EHRbase:"
    echo "  - sync-to-ehrbase        (processes ehrbase_sync_queue)"
    echo ""

    read -p "Redeploy sync-to-ehrbase function? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Deploying sync-to-ehrbase function..."
        npx supabase functions deploy sync-to-ehrbase
        echo -e "${GREEN}✓${NC} sync-to-ehrbase function deployed"
    else
        echo -e "${YELLOW}⚠${NC}  Edge function not deployed - changes will apply on next deployment"
    fi

    # Return to deployment directory
    if [ -d "aws-deployment" ]; then
        cd aws-deployment
    fi
fi

################################################################################
# 3. VERIFY CONFIGURATION
################################################################################

echo ""
echo "=========================================="
echo "Step 3: Verifying Configuration"
echo "=========================================="
echo ""

echo "Testing EHRbase connectivity..."

# Test with new credentials
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${EHRBASE_USER}:${EHRBASE_USER_PASS}" \
    "${EHRBASE_URL}/status")

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC} EHRbase API accessible (HTTP $HTTP_CODE)"
else
    echo -e "${RED}✗${NC} EHRbase API returned HTTP $HTTP_CODE"
    echo "  Check credentials and URL"
fi

# Test template endpoint
echo "Testing template endpoint..."
TEMPLATE_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "${EHRBASE_USER}:${EHRBASE_USER_PASS}" \
    "${EHRBASE_URL}/openehr/v1/definition/template/adl1.4")

if [ "$TEMPLATE_CODE" = "200" ]; then
    echo -e "${GREEN}✓${NC} Template endpoint accessible (HTTP $TEMPLATE_CODE)"
else
    echo -e "${YELLOW}⚠${NC}  Template endpoint returned HTTP $TEMPLATE_CODE"
fi

################################################################################
# 4. CREATE CONFIGURATION SUMMARY
################################################################################

echo ""
echo "Creating configuration summary..."

cat > integration-config-summary.md << EOF
# Integration Configuration Summary

**Date:** $(date)
**AWS EHRbase Endpoint:** $EHRBASE_URL

## Production Configuration

### EHRbase Details
- **URL:** $EHRBASE_URL
- **Username:** $EHRBASE_USER
- **Password:** [Stored in AWS Secrets Manager: ${PROJECT_NAME}/ehrbase_basic_auth]

### AWS Resources
- **ALB DNS:** $ALB_DNS
- **ECS Cluster:** ${PROJECT_NAME}-cluster
- **ECS Service:** ${PROJECT_NAME}-service
- **Region:** $AWS_REGION

## Firebase Cloud Functions

**Configuration:**
\`\`\`
ehrbase.url = "${EHRBASE_URL}"
ehrbase.username = "${EHRBASE_USER}"
ehrbase.password = "[set via firebase functions:config:set]"
\`\`\`

**Functions affected:**
- onUserCreated - Creates EHR in EHRbase when user signs up
- onUserDeleted - Cleanup operations

**Deployment command:**
\`\`\`bash
cd firebase/functions
firebase deploy --only functions
\`\`\`

## Supabase Edge Functions

**Secrets configured:**
- EHRBASE_URL
- EHRBASE_USERNAME
- EHRBASE_PASSWORD

**Functions affected:**
- sync-to-ehrbase - Processes ehrbase_sync_queue to sync data to EHRbase

**Deployment command:**
\`\`\`bash
npx supabase functions deploy sync-to-ehrbase
\`\`\`

## Verification Steps

1. **Test EHRbase API:**
   \`\`\`bash
   curl -u "${EHRBASE_USER}:\${EHRBASE_PASSWORD}" \\
     ${EHRBASE_URL}/status
   \`\`\`

2. **Test Firebase Function:**
   - Create a test user in Firebase Auth
   - Check Cloud Function logs: \`firebase functions:log --only onUserCreated\`
   - Verify EHR created in Supabase: \`SELECT * FROM electronic_health_records ORDER BY created_at DESC LIMIT 1\`

3. **Test Supabase Sync:**
   - Insert test data: \`INSERT INTO vital_signs (...) VALUES (...)\`
   - Check sync queue: \`SELECT * FROM ehrbase_sync_queue WHERE sync_status = 'pending'\`
   - Check function logs: \`npx supabase functions logs sync-to-ehrbase\`

4. **Test End-to-End:**
   - Run: \`./06-validate-deployment.sh\`

## Rollback Instructions

If issues occur, rollback to dev environment:

1. **Firebase:**
   \`\`\`bash
   firebase functions:config:set \\
     ehrbase.url="$DEV_EHRBASE_URL" \\
     ehrbase.username="$DEV_EHRBASE_USER" \\
     ehrbase.password="$DEV_EHRBASE_PASS"
   firebase deploy --only functions
   \`\`\`

2. **Supabase:**
   \`\`\`bash
   npx supabase secrets set \\
     EHRBASE_URL="$DEV_EHRBASE_URL" \\
     EHRBASE_USERNAME="$DEV_EHRBASE_USER" \\
     EHRBASE_PASSWORD="$DEV_EHRBASE_PASS"
   npx supabase functions deploy sync-to-ehrbase
   \`\`\`

## Next Steps

1. Validate deployment: \`./06-validate-deployment.sh\`
2. Monitor logs for 24 hours
3. Test user creation flow
4. Test offline sync functionality
5. Configure DNS and SSL for production domain

EOF

echo -e "${GREEN}✓${NC} Configuration summary saved: integration-config-summary.md"

################################################################################
# SUMMARY
################################################################################

echo ""
echo "=========================================="
echo "Integration Update Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}Configuration Updated:${NC}"

if [ "$SKIP_FIREBASE" != "true" ]; then
    echo "  ✓ Firebase Cloud Functions"
else
    echo "  ⚠ Firebase Cloud Functions (skipped)"
fi

if [ "$SKIP_SUPABASE" != "true" ]; then
    echo "  ✓ Supabase Edge Functions"
else
    echo "  ⚠ Supabase Edge Functions (skipped)"
fi

echo ""
echo -e "${BLUE}Production EHRbase:${NC}"
echo "  URL:      $EHRBASE_URL"
echo "  Status:   Active"
echo "  Auth:     HTTP Basic ($EHRBASE_USER)"
echo ""

echo -e "${YELLOW}Important:${NC}"
echo "  - Test end-to-end user creation flow"
echo "  - Monitor Cloud Function and Edge Function logs"
echo "  - Verify EHR sync queue processing"
echo "  - Keep integration-config-summary.md for reference"
echo ""

echo -e "${GREEN}Next step:${NC}"
echo "  ./06-validate-deployment.sh"
echo ""
