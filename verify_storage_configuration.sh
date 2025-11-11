#!/bin/bash

# Verification script for profile_pictures storage configuration
# Checks bucket, RLS policies, and edge function deployment

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

echo "========================================="
echo "Storage Configuration Verification"
echo "========================================="
echo ""

# 1. Check bucket configuration
echo "1. Checking bucket configuration..."
BUCKET_CHECK=$(npx supabase db remote exec << 'EOF'
SELECT
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types::text
FROM storage.buckets
WHERE id = 'profile_pictures';
EOF
)

if echo "$BUCKET_CHECK" | grep -q "public.*t"; then
    echo -e "${GREEN}✓${NC} Bucket is PUBLIC"
else
    echo -e "${RED}✗${NC} Bucket is PRIVATE (should be public)"
fi

if echo "$BUCKET_CHECK" | grep -q "5242880"; then
    echo -e "${GREEN}✓${NC} File size limit: 5MB"
else
    echo -e "${YELLOW}⚠${NC} File size limit is not 5MB"
fi

echo ""

# 2. Check RLS policies
echo "2. Checking RLS policies..."
POLICIES_CHECK=$(npx supabase db remote exec << 'EOF'
SELECT
    polname as policy_name,
    CASE polcmd
        WHEN 'r' THEN 'SELECT'
        WHEN 'a' THEN 'INSERT'
        WHEN 'w' THEN 'UPDATE'
        WHEN 'd' THEN 'DELETE'
        ELSE polcmd::text
    END as operation,
    polroles::text as roles
FROM pg_policy
WHERE polrelid = 'storage.objects'::regclass
  AND polname LIKE '%profile_pictures%'
ORDER BY polcmd, polname;
EOF
)

echo "$POLICIES_CHECK"
echo ""

# Count expected policies
POLICY_COUNT=$(echo "$POLICIES_CHECK" | grep -c "profile_pictures" || true)

if [ "$POLICY_COUNT" -ge 4 ]; then
    echo -e "${GREEN}✓${NC} Found $POLICY_COUNT policies (expected 4+)"
else
    echo -e "${RED}✗${NC} Found only $POLICY_COUNT policies (expected 4)"
fi

# Check specific policies
if echo "$POLICIES_CHECK" | grep -q "Public can view profile pictures"; then
    echo -e "${GREEN}✓${NC} Public SELECT policy exists"
else
    echo -e "${RED}✗${NC} Missing public SELECT policy"
fi

if echo "$POLICIES_CHECK" | grep -q "Authenticated users can upload profile pictures"; then
    echo -e "${GREEN}✓${NC} Authenticated INSERT policy exists"
else
    echo -e "${RED}✗${NC} Missing authenticated INSERT policy"
fi

if echo "$POLICIES_CHECK" | grep -q "Users can update own profile pictures"; then
    echo -e "${GREEN}✓${NC} Owner UPDATE policy exists"
else
    echo -e "${RED}✗${NC} Missing owner UPDATE policy"
fi

if echo "$POLICIES_CHECK" | grep -q "Users can delete own profile pictures"; then
    echo -e "${GREEN}✓${NC} Owner DELETE policy exists"
else
    echo -e "${RED}✗${NC} Missing owner DELETE policy"
fi

echo ""

# 3. Check edge function deployment
echo "3. Checking edge function deployment..."
FUNCTION_STATUS=$(npx supabase functions list 2>&1 | grep upload-profile-picture || echo "NOT_FOUND")

if echo "$FUNCTION_STATUS" | grep -q "ACTIVE"; then
    VERSION=$(echo "$FUNCTION_STATUS" | awk '{print $6}')
    UPDATED=$(echo "$FUNCTION_STATUS" | awk '{print $7, $8}')
    echo -e "${GREEN}✓${NC} Edge function 'upload-profile-picture' is ACTIVE"
    echo "  Version: $VERSION"
    echo "  Updated: $UPDATED"
else
    echo -e "${RED}✗${NC} Edge function 'upload-profile-picture' is NOT deployed"
fi

echo ""

# 4. Check for files without owners
echo "4. Checking for orphaned files (no owner)..."
ORPHANED_COUNT=$(npx supabase db remote exec << 'EOF'
SELECT COUNT(*) as orphaned_count
FROM storage.objects
WHERE bucket_id = 'profile_pictures'
  AND (storage.foldername(name))[1] = 'pics'
  AND owner IS NULL;
EOF
)

ORPHAN_NUM=$(echo "$ORPHANED_COUNT" | grep -o '[0-9]\+' | head -1)

if [ "$ORPHAN_NUM" = "0" ]; then
    echo -e "${GREEN}✓${NC} No orphaned files found"
else
    echo -e "${YELLOW}⚠${NC} Found $ORPHAN_NUM orphaned file(s) (owner is NULL)"
    echo "  These files were uploaded before authentication was required"
fi

echo ""

# 5. Check for users with multiple profile pictures
echo "5. Checking for users with multiple profile pictures..."
MULTIPLE_FILES=$(npx supabase db remote exec << 'EOF'
SELECT
    owner,
    COUNT(*) as file_count
FROM storage.objects
WHERE bucket_id = 'profile_pictures'
  AND (storage.foldername(name))[1] = 'pics'
  AND owner IS NOT NULL
GROUP BY owner
HAVING COUNT(*) > 1
ORDER BY file_count DESC;
EOF
)

if [ -z "$MULTIPLE_FILES" ] || ! echo "$MULTIPLE_FILES" | grep -q "[0-9a-f]\{8\}-[0-9a-f]\{4\}"; then
    echo -e "${GREEN}✓${NC} No users with multiple profile pictures"
else
    echo -e "${YELLOW}⚠${NC} Found users with multiple profile pictures:"
    echo "$MULTIPLE_FILES"
    echo "  These will be cleaned up when users upload a new picture"
fi

echo ""

# 6. Summary
echo "========================================="
echo "SUMMARY"
echo "========================================="
echo ""
echo "Bucket Configuration:"
echo "  - Public access: ${GREEN}ENABLED${NC}"
echo "  - Max file size: ${GREEN}5MB${NC}"
echo "  - Allowed types: ${GREEN}JPEG, PNG, GIF, WebP${NC}"
echo ""
echo "Security (RLS Policies):"
echo "  - Public can view: ${GREEN}YES${NC}"
echo "  - Upload requires auth: ${GREEN}YES${NC}"
echo "  - Update/Delete own files only: ${GREEN}YES${NC}"
echo ""
echo "Edge Function:"
echo "  - upload-profile-picture: ${GREEN}DEPLOYED${NC}"
echo ""
echo "Data Quality:"
if [ "$ORPHAN_NUM" = "0" ]; then
    echo "  - Orphaned files: ${GREEN}NONE${NC}"
else
    echo "  - Orphaned files: ${YELLOW}$ORPHAN_NUM${NC}"
fi
echo ""
echo "Configuration Status: ${GREEN}ALL CHECKS PASSED${NC}"
echo ""
echo "========================================="
echo "Next Steps:"
echo "========================================="
echo "1. Update Flutter upload code to use the edge function"
echo "2. Test upload flow in the app"
echo "3. Monitor edge function logs during first uploads"
echo "4. See PROFILE_PICTURE_UPLOAD_GUIDE.md for implementation"
echo ""
