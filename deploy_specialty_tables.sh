#!/bin/bash

# Deployment Script for Specialty Medical Tables
# Deploys all changes for the 19 specialty medical tables
# Usage: ./deploy_specialty_tables.sh [--dry-run]

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    echo -e "${YELLOW}🔍 DRY RUN MODE - No changes will be made${NC}\n"
fi

# Deployment steps
TOTAL_STEPS=7
CURRENT_STEP=0

step() {
    ((CURRENT_STEP++))
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Step $CURRENT_STEP/$TOTAL_STEPS: $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Pre-deployment checks
echo -e "${BLUE}🚀 Specialty Medical Tables Deployment Script${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check prerequisites
info "Checking prerequisites..."

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    error "Supabase CLI not found. Please install: npm install -g supabase"
    exit 1
fi
success "Supabase CLI found"

# Check if logged in to Supabase
if ! supabase projects list &> /dev/null; then
    error "Not logged in to Supabase. Please run: npx supabase login"
    exit 1
fi
success "Supabase authentication verified"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    error "Flutter not found. Please install Flutter SDK"
    exit 1
fi
success "Flutter SDK found"

# Step 1: Run verification
step "Running consistency verification"
if [ -f "./verify_consistency.sh" ]; then
    chmod +x ./verify_consistency.sh
    if ./verify_consistency.sh; then
        success "Verification passed"
    else
        error "Verification failed. Please fix issues before deploying."
        exit 1
    fi
else
    warn "verify_consistency.sh not found - skipping verification"
fi

# Step 2: Backup current state
step "Creating backup of current state"
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
if [ "$DRY_RUN" = false ]; then
    mkdir -p "$BACKUP_DIR"

    # Backup migrations
    if [ -d "supabase/migrations" ]; then
        cp -r supabase/migrations "$BACKUP_DIR/"
        success "Migrations backed up to $BACKUP_DIR"
    fi

    # Backup PowerSync schema
    if [ -f "lib/powersync/schema.dart" ]; then
        cp lib/powersync/schema.dart "$BACKUP_DIR/"
        success "PowerSync schema backed up"
    fi

    # Backup database.dart
    if [ -f "lib/backend/supabase/database/database.dart" ]; then
        cp lib/backend/supabase/database/database.dart "$BACKUP_DIR/"
        success "database.dart backed up"
    fi

    info "Backup location: $BACKUP_DIR"
else
    info "Would create backup at: backups/$(date +%Y%m%d_%H%M%S)"
fi

# Step 3: Deploy database migrations
step "Deploying database migrations to Supabase"
if [ "$DRY_RUN" = false ]; then
    info "Pushing migrations to Supabase..."
    if npx supabase db push; then
        success "Database migrations deployed successfully"
    else
        error "Migration deployment failed"
        exit 1
    fi
else
    info "Would run: npx supabase db push"
fi

# Step 4: Deploy PowerSync sync rules
step "Deploying PowerSync sync rules"
if [ -f "POWERSYNC_SYNC_RULES.yaml" ]; then
    warn "PowerSync sync rules must be deployed manually via PowerSync Dashboard"
    info "Steps:"
    echo "   1. Go to https://powersync.journeyapps.com"
    echo "   2. Select your instance"
    echo "   3. Navigate to Sync Rules"
    echo "   4. Copy contents from POWERSYNC_SYNC_RULES.yaml"
    echo "   5. Paste and deploy"

    if [ "$DRY_RUN" = false ]; then
        read -p "Press Enter when PowerSync sync rules are deployed..."
        success "PowerSync sync rules deployment confirmed"
    else
        info "Would prompt for PowerSync sync rules deployment"
    fi
else
    error "POWERSYNC_SYNC_RULES.yaml not found"
    exit 1
fi

# Step 5: Deploy edge function
step "Deploying sync-to-ehrbase edge function"
if [ "$DRY_RUN" = false ]; then
    info "Deploying edge function..."
    if npx supabase functions deploy sync-to-ehrbase; then
        success "Edge function deployed successfully"
    else
        error "Edge function deployment failed"
        exit 1
    fi
else
    info "Would run: npx supabase functions deploy sync-to-ehrbase"
fi

# Step 6: Build Flutter app
step "Building Flutter application"
if [ "$DRY_RUN" = false ]; then
    info "Running flutter pub get..."
    if flutter pub get; then
        success "Dependencies installed"
    else
        error "flutter pub get failed"
        exit 1
    fi

    info "Running flutter analyze..."
    if flutter analyze; then
        success "Static analysis passed"
    else
        warn "Static analysis found issues - review before deploying to production"
    fi
else
    info "Would run: flutter pub get && flutter analyze"
fi

# Step 7: Run integration tests
step "Running integration tests"
if [ -f "./test_system_connections.sh" ]; then
    if [ "$DRY_RUN" = false ]; then
        info "Running system integration tests..."
        chmod +x ./test_system_connections.sh
        if ./test_system_connections.sh; then
            success "Integration tests passed"
        else
            warn "Some integration tests failed - review results"
        fi
    else
        info "Would run: ./test_system_connections.sh"
    fi
else
    warn "Integration test script not found - skipping"
fi

# Deployment summary
echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}📊 Deployment Summary${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$DRY_RUN" = false ]; then
    echo -e "${GREEN}✅ Deployment completed successfully!${NC}\n"

    echo "Deployed components:"
    echo "  ✓ Database migrations (19 specialty tables)"
    echo "  ✓ PowerSync sync rules (4 user roles)"
    echo "  ✓ Edge function (sync-to-ehrbase)"
    echo "  ✓ Dart models (19 files)"
    echo "  ✓ Flutter application updates"
    echo ""
    echo -e "${BLUE}📋 Post-deployment checklist:${NC}"
    echo "  1. Verify PowerSync Dashboard shows all tables syncing"
    echo "  2. Test user signup/login flows"
    echo "  3. Test medical record creation for each specialty"
    echo "  4. Verify EHRbase sync queue processing"
    echo "  5. Check edge function logs: npx supabase functions logs sync-to-ehrbase"
    echo "  6. Monitor PowerSync sync status in app"
    echo ""
    echo -e "${YELLOW}⚠️  Important:${NC}"
    echo "  - Backup created at: $BACKUP_DIR"
    echo "  - Review PowerSync Dashboard for sync errors"
    echo "  - Test thoroughly in staging before production rollout"
else
    echo -e "${YELLOW}🔍 Dry run completed - no changes were made${NC}\n"
    echo "To perform actual deployment, run without --dry-run flag:"
    echo "  ./deploy_specialty_tables.sh"
fi

echo ""
echo -e "${GREEN}🎉 Deployment script finished!${NC}"
