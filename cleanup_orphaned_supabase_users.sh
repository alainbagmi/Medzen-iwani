#!/bin/bash

#===============================================================================
# Cleanup Orphaned Supabase Users
#===============================================================================
# This script deletes ALL Supabase Auth users. Use with caution!
#
# Usage: ./cleanup_orphaned_supabase_users.sh
#===============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}⚠️  WARNING: This will delete ALL Supabase Auth users!${NC}"
echo ""
echo "This script will delete the following 16 users:"
echo "1. test-simplified-1762748904@medzen-test.com"
echo "2. test-function-1762748526@medzen-test.com"
echo "3. +14437229723@medzen.com"
echo "4. +15714472698@medzen.com"
echo "5. +12025978286@medzen.com"
echo "6. +12406156089@medzen.com"
echo "7. +237691959357@medzen.com"
echo "8-14. Various test-* users"
echo "15. +12404604692@medzen.com"
echo "16. firebase@flutterflow.io"
echo ""
echo -e "${YELLOW}Are you sure you want to delete ALL these users? (yes/no)${NC}"
read -r confirmation

if [ "$confirmation" != "yes" ]; then
    echo -e "${GREEN}Aborted. No users were deleted.${NC}"
    exit 0
fi

SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

echo ""
echo -e "${BLUE}🗑️  Deleting Supabase Auth users...${NC}"
echo ""

# Array of Supabase user IDs to delete
declare -a USER_IDS=(
    "f1b4af65-9880-4a7c-af32-abced439d4d1"  # test-simplified-1762748904@medzen-test.com
    "9ca9b8e5-ceba-44dc-bbca-45297378b3d8"  # test-function-1762748526@medzen-test.com
    "2401efe3-04ed-4286-a55f-090b47dd029e"  # +14437229723@medzen.com
    "8d39fda0-9d60-4d6f-8296-32ded455c502"  # +15714472698@medzen.com
    "6d88934e-e8e4-47b1-84c2-367d830527bf"  # +12025978286@medzen.com
    "af1e0503-bdb1-4035-8a66-e928d24dc4b7"  # +12406156089@medzen.com
    "33c60aec-8b9e-4459-9dde-0ebd99a88a74"  # +237691959357@medzen.com
    "5ec47004-923b-4cb9-8947-1a1cebb1dd70"  # test-1762203499@medzen-test.com
    "8c50a547-4f25-44ab-85bb-5e2a4bfacdf5"  # test-1762203208@medzen-test.com
    "e91c6dab-e533-4549-a633-86daf614f303"  # test-1762203043@medzen-test.com
    "4594b294-50a4-4d67-8195-330bbbe106aa"  # test-1762202873@medzen-test.com
    "817bd3b7-78e7-41f7-b624-f6917df6d108"  # test-1762202726@medzen-test.com
    "72e271c4-b53c-43c9-8ce0-83acf896cc2c"  # test-1762202579@medzen-test.com
    "e22d5913-6876-4df2-8c0f-de81f97ea88d"  # test-1762202265@medzen-test.com
    "a26f980c-e790-41bd-81c4-d1139475f5ce"  # +12404604692@medzen.com
    "93bc5eec-e92f-4805-af64-a536832d7d21"  # firebase@flutterflow.io
)

deleted_count=0
failed_count=0

for user_id in "${USER_IDS[@]}"; do
    echo -n "Deleting user: $user_id ... "

    response=$(curl -s -w "\n%{http_code}" -X DELETE \
        "$SUPABASE_URL/auth/v1/admin/users/$user_id" \
        -H "apikey: $SERVICE_KEY" \
        -H "Authorization: Bearer $SERVICE_KEY")

    http_code=$(echo "$response" | tail -n1)

    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ Deleted${NC}"
        ((deleted_count++))
    else
        echo -e "${RED}❌ Failed (HTTP $http_code)${NC}"
        ((failed_count++))
    fi
done

echo ""
echo "================================================================================"
echo -e "${GREEN}✅ Deletion complete!${NC}"
echo "   Deleted: $deleted_count users"
echo "   Failed: $failed_count users"
echo ""
echo -e "${YELLOW}⚠️  Note: You should now update the onUserDeleted function to also delete${NC}"
echo -e "${YELLOW}   from Supabase in the future to prevent orphaned users.${NC}"
echo ""
