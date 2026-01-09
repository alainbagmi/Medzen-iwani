#!/bin/bash
# ⚠️  CRITICAL FUNCTION VALIDATION SCRIPT ⚠️
# Run this script anytime to verify critical functions are intact
# Usage: ./validate-critical-functions.sh

set -e

echo "========================================"
echo "🔒 CRITICAL FUNCTIONS VALIDATION"
echo "========================================"
echo ""

ERRORS=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
    ERRORS=$((ERRORS + 1))
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

# Check 1: Verify index.js exists
echo "📁 Checking file existence..."
if [ ! -f "firebase/functions/index.js" ]; then
    error "firebase/functions/index.js is MISSING!"
else
    success "firebase/functions/index.js exists"
fi

if [ ! -f "firebase/functions/package.json" ]; then
    error "firebase/functions/package.json is MISSING!"
else
    success "firebase/functions/package.json exists"
fi

echo ""

# Check 2: Verify critical functions exist
echo "🔍 Checking critical functions..."

if ! grep -q "exports.onUserCreated" firebase/functions/index.js 2>/dev/null; then
    error "onUserCreated function is MISSING from index.js!"
else
    success "onUserCreated function present"
fi

if ! grep -q "exports.onUserDeleted" firebase/functions/index.js 2>/dev/null; then
    error "onUserDeleted function is MISSING from index.js!"
else
    success "onUserDeleted function present"
fi

if ! grep -q "exports.addFcmToken" firebase/functions/index.js 2>/dev/null; then
    error "addFcmToken function is MISSING from index.js!"
else
    success "addFcmToken function present"
fi

if ! grep -q "exports.sendPushNotificationsTrigger" firebase/functions/index.js 2>/dev/null; then
    error "sendPushNotificationsTrigger function is MISSING from index.js!"
else
    success "sendPushNotificationsTrigger function present"
fi

echo ""

# Check 3: Verify critical dependencies
echo "📦 Checking critical dependencies..."

if ! grep -q '"@supabase/supabase-js"' firebase/functions/package.json 2>/dev/null; then
    error "@supabase/supabase-js dependency is MISSING from package.json!"
else
    # Extract version
    version=$(grep '@supabase/supabase-js' firebase/functions/package.json | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    success "@supabase/supabase-js dependency present (v$version)"
fi

echo ""

# Check 4: Verify function implementations
echo "🔎 Checking function implementations..."

if [ -f "firebase/functions/index.js" ]; then
    # Check onUserCreated implementation
    if ! grep -q "createClient.*@supabase/supabase-js" firebase/functions/index.js 2>/dev/null; then
        error "onUserCreated missing Supabase client initialization!"
    else
        success "onUserCreated has Supabase client initialization"
    fi

    if ! grep -q "Step 1: Creating Supabase Auth user" firebase/functions/index.js 2>/dev/null; then
        error "onUserCreated implementation is corrupted or incomplete!"
    else
        success "onUserCreated implementation verified"
    fi

    # Check onUserDeleted implementation
    if ! grep -q "Step 1: Finding Supabase user record" firebase/functions/index.js 2>/dev/null; then
        error "onUserDeleted implementation is corrupted or incomplete!"
    else
        success "onUserDeleted implementation verified"
    fi
fi

echo ""

# Check 5: Verify file integrity (line count)
echo "📊 Checking file integrity..."

if [ -f "firebase/functions/index.js" ]; then
    line_count=$(wc -l < firebase/functions/index.js)

    if [ "$line_count" -lt 500 ]; then
        error "index.js only has $line_count lines (expected 500+) - file may be truncated!"
    else
        success "index.js has $line_count lines (healthy)"
    fi
fi

echo ""

# Check 6: Verify git hooks are in place
echo "🪝 Checking git hooks..."

if [ -f ".git/hooks/pre-commit" ]; then
    if grep -q "CRITICAL PRODUCTION PROTECTION" .git/hooks/pre-commit 2>/dev/null; then
        success "Pre-commit hook is active and protecting critical functions"
    else
        warning "Pre-commit hook exists but may not have full protection"
    fi
else
    warning "Pre-commit hook is not installed"
fi

if [ -f ".git/hooks/pre-push" ]; then
    if grep -q "CRITICAL PRODUCTION PROTECTION" .git/hooks/pre-push 2>/dev/null; then
        success "Pre-push hook is active and protecting critical functions"
    else
        warning "Pre-push hook exists but may not have full protection"
    fi
else
    warning "Pre-push hook is not installed"
fi

echo ""
echo "========================================"

# Final summary
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ VALIDATION PASSED - All critical functions are intact!${NC}"
    echo ""
    echo "Your user lifecycle functions are protected and ready for production."
    exit 0
else
    echo -e "${RED}❌ VALIDATION FAILED - $ERRORS error(s) found!${NC}"
    echo ""
    echo "CRITICAL: Your user lifecycle functions are compromised!"
    echo "Action required:"
    echo "  1. Restore from git: git checkout HEAD -- firebase/functions/index.js"
    echo "  2. Or restore from backup documentation"
    echo "  3. Verify package.json has @supabase/supabase-js dependency"
    echo ""
    exit 1
fi
