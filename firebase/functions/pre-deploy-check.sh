#!/bin/bash
# Pre-Deployment Verification Script for Firebase Cloud Functions
# Created: 2025-11-11
# Purpose: Verify all requirements before deploying functions to prevent errors

set -e  # Exit on any error

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "========================================="
echo "Firebase Functions Pre-Deployment Check"
echo "========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
    else
        echo -e "${RED}❌ FAIL${NC}: $2"
        ERRORS=$((ERRORS + 1))
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARNING${NC}: $1"
    WARNINGS=$((WARNINGS + 1))
}

echo "1. Checking Node.js version..."
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -eq 20 ]; then
    print_status 0 "Node.js version $NODE_VERSION (required: 20)"
elif [ "$NODE_VERSION" -gt 20 ]; then
    print_warning "Node.js version $NODE_VERSION (recommended: 20, but >= 20 should work)"
else
    print_status 1 "Node.js version $NODE_VERSION (required: 20 or higher)"
fi
echo ""

echo "2. Checking npm dependencies..."
if [ -f "package.json" ]; then
    print_status 0 "package.json exists"

    # Check if node_modules exists
    if [ -d "node_modules" ]; then
        print_status 0 "node_modules directory exists"
    else
        print_status 1 "node_modules directory missing - run 'npm install'"
    fi

    # Verify critical dependencies
    echo "   Checking critical dependencies..."
    for dep in "@supabase/supabase-js" "axios" "firebase-admin" "firebase-functions"; do
        if grep -q "\"$dep\"" package.json; then
            echo -e "   ${GREEN}✓${NC} $dep"
        else
            echo -e "   ${RED}✗${NC} $dep - MISSING"
            ERRORS=$((ERRORS + 1))
        fi
    done
else
    print_status 1 "package.json not found"
fi
echo ""

echo "3. Checking Firebase configuration..."
CONFIG_OUTPUT=$(firebase functions:config:get 2>&1 || echo "ERROR")

if [[ "$CONFIG_OUTPUT" == "ERROR" ]]; then
    print_status 1 "Failed to retrieve Firebase config - are you logged in?"
else
    # Check Supabase config
    if echo "$CONFIG_OUTPUT" | grep -q '"supabase"'; then
        if echo "$CONFIG_OUTPUT" | grep -q '"url"' && echo "$CONFIG_OUTPUT" | grep -q '"service_key"'; then
            print_status 0 "Supabase config set (url, service_key)"
        else
            print_status 1 "Supabase config incomplete (missing url or service_key)"
        fi
    else
        print_status 1 "Supabase config not set"
    fi

    # Check EHRbase config
    if echo "$CONFIG_OUTPUT" | grep -q '"ehrbase"'; then
        if echo "$CONFIG_OUTPUT" | grep -q '"url"' && echo "$CONFIG_OUTPUT" | grep -q '"username"' && echo "$CONFIG_OUTPUT" | grep -q '"password"'; then
            print_status 0 "EHRbase config set (url, username, password)"
        else
            print_status 1 "EHRbase config incomplete (missing url, username, or password)"
        fi
    else
        print_status 1 "EHRbase config not set"
    fi
fi
echo ""

echo "4. Checking critical function exists..."
if grep -q "exports.onUserCreated" index.js; then
    print_status 0 "onUserCreated function found in index.js"

    # Verify function creates EHR
    if grep -q "ehrbase" index.js && grep -q "electronic_health_records" index.js; then
        print_status 0 "Function includes EHRbase integration"
    else
        print_status 1 "Function missing EHRbase integration"
    fi

    # Verify minimal field creation
    if grep -q "FlutterFlow will populate" index.js; then
        print_status 0 "Function uses minimal field creation (correct approach)"
    else
        print_warning "Function may be capturing demographics (check implementation)"
    fi
else
    print_status 1 "onUserCreated function not found in index.js"
fi
echo ""

echo "5. Checking for sensitive data in code..."
# Check for actual credential assignments (long strings that look like secrets)
# Exclude: config.*, process.env, documentation strings, collection names, query fields
SENSITIVE_FOUND=false

if grep -iE "(password|secret|api_key|apikey|access_key)\s*=\s*['\"][a-zA-Z0-9_\-]{20,}['\"]" index.js | grep -v "config\." | grep -v "process.env" | grep -q .; then
    SENSITIVE_FOUND=true
    echo -e "   ${RED}✗${NC} Potential hardcoded credential found (long secret-like string)"
fi

if [ "$SENSITIVE_FOUND" = false ]; then
    print_status 0 "No hardcoded credentials detected"
else
    print_status 1 "Hardcoded credentials detected - use Firebase Functions config"
fi
echo ""

echo "6. Running linter..."
if npm run lint > /dev/null 2>&1; then
    print_status 0 "Linting passed"
else
    print_status 1 "Linting failed - run 'npm run lint' to see errors"
fi
echo ""

echo "7. Checking .runtimeconfig.json..."
if [ -f ".runtimeconfig.json" ]; then
    print_warning ".runtimeconfig.json exists (should be in .gitignore)"

    # Check if it's in .gitignore
    if [ -f "../../.gitignore" ]; then
        if grep -q ".runtimeconfig.json" ../../.gitignore; then
            echo -e "   ${GREEN}✓${NC} File is in .gitignore"
        else
            echo -e "   ${RED}✗${NC} File NOT in .gitignore - add it!"
        fi
    fi
else
    print_status 0 ".runtimeconfig.json does not exist (good - using firebase functions:config:get)"
fi
echo ""

echo "8. Checking Git status..."
if [ -d "../../.git" ]; then
    print_status 0 "Git repository exists"

    # Check if index.js is committed
    cd ../..
    if git ls-files --error-unmatch firebase/functions/index.js > /dev/null 2>&1; then
        print_status 0 "index.js is tracked by Git"

        # Check for uncommitted changes
        if git diff --quiet firebase/functions/index.js; then
            print_status 0 "No uncommitted changes to index.js"
        else
            print_warning "Uncommitted changes in index.js - consider committing before deploy"
        fi
    else
        print_status 1 "index.js is NOT tracked by Git - run 'git add' and commit"
    fi
    cd "$SCRIPT_DIR"
else
    print_status 1 "Git repository not initialized - run 'git init' in project root"
fi
echo ""

# Summary
echo "========================================="
echo "Summary:"
echo "========================================="
echo -e "Errors:   ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! Ready to deploy.${NC}"
    echo ""
    echo "To deploy, run:"
    echo "  firebase deploy --only functions:onUserCreated"
    echo ""
    exit 0
else
    echo -e "${RED}❌ Pre-deployment checks failed. Fix errors before deploying.${NC}"
    echo ""
    exit 1
fi
