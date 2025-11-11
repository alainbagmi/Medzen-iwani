#!/bin/bash

# PowerSync Sync Rules Fix - Automated Deployment Script
# This script deploys the complete PowerSync multi-role sync solution

set -e  # Exit on any error

echo "=================================================="
echo "PowerSync Multi-Role Sync Fix - Deployment Script"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Apply database migration
echo "📦 Step 1: Applying database migration..."
echo ""
if npx supabase db push; then
    echo -e "${GREEN}✓ Migration applied successfully${NC}"
else
    echo -e "${RED}✗ Migration failed${NC}"
    exit 1
fi
echo ""

# Step 2: Refresh materialized views
echo "🔄 Step 2: Refreshing materialized views (initial refresh)..."
echo ""
echo "Please run the following command in Supabase SQL Editor:"
echo ""
echo -e "${YELLOW}SELECT refresh_powersync_materialized_views();${NC}"
echo ""
echo "Press Enter after you've run the SQL command above..."
read -r

# Step 3: Deploy Edge Function
echo "☁️  Step 3: Deploying Edge Function for automatic view refresh..."
echo ""
if npx supabase functions deploy refresh-powersync-views; then
    echo -e "${GREEN}✓ Edge Function deployed successfully${NC}"
else
    echo -e "${RED}✗ Edge Function deployment failed${NC}"
    exit 1
fi
echo ""

# Step 4: Instructions for PowerSync Dashboard
echo "🌐 Step 4: Deploy sync rules to PowerSync Dashboard"
echo ""
echo "Next steps:"
echo "  1. Copy the contents of: ${YELLOW}POWERSYNC_SYNC_RULES_COMPLETE.yaml${NC}"
echo "  2. Go to: https://YOUR_INSTANCE.journeyapps.com/"
echo "  3. Navigate to: Sync Rules"
echo "  4. Paste the rules"
echo "  5. Click: Validate → Save → Deploy"
echo ""

# Step 5: Set up automatic refresh
echo "⏰ Step 5: Set up automatic view refresh"
echo ""
echo "Choose one of the following options:"
echo ""
echo "Option A: pg_cron (Recommended)"
echo "  Run in Supabase SQL Editor:"
echo ""
echo -e "${YELLOW}CREATE EXTENSION IF NOT EXISTS pg_cron;${NC}"
echo -e "${YELLOW}SELECT cron.schedule("
echo "    'refresh-powersync-views',"
echo "    '*/5 * * * *',"
echo "    'SELECT refresh_powersync_materialized_views();'"
echo -e ");${NC}"
echo ""
echo "Option B: External Cron Service"
echo "  Schedule a cron job to call:"
echo ""
echo -e "${YELLOW}curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/refresh-powersync-views \\
  -H \"Authorization: Bearer YOUR_ANON_KEY\"${NC}"
echo ""

# Final checks
echo "=================================================="
echo "🎉 Deployment Steps Complete!"
echo "=================================================="
echo ""
echo "Checklist:"
echo "  [✓] Database migration applied"
echo "  [✓] Edge Function deployed"
echo "  [ ] Materialized views refreshed (manual step)"
echo "  [ ] Sync rules deployed to PowerSync Dashboard"
echo "  [ ] Automatic refresh scheduled"
echo ""
echo "For detailed instructions, see:"
echo "  📖 POWERSYNC_SYNC_RULES_FIX_GUIDE.md"
echo ""
echo "For testing:"
echo "  🧪 Test each role (Patient, Provider, Facility Admin, System Admin)"
echo "  🧪 Monitor PowerSync Dashboard → Metrics"
echo "  🧪 Check Supabase → Database → Logs"
echo ""
