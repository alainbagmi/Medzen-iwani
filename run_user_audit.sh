#!/bin/bash

# =====================================================
# Comprehensive User Signup/Signin Audit Script
# Date: 2025-11-03
# =====================================================

SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║     USER SIGNUP/SIGNIN COMPREHENSIVE AUDIT REPORT                  ║"
echo "║     Date: $(date)                                  ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# =====================================================
# SECTION 1: User Account Statistics
# =====================================================
echo ""
echo "═══ SECTION 1: USER ACCOUNT STATISTICS ═══"
echo ""

TOTAL_USERS=$(curl -s "$SUPABASE_URL/rest/v1/users?select=count" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Prefer: count=exact" | jq -r '.[0].count // 0')

echo "Total users in database: $TOTAL_USERS"

# Users created in last 24 hours
USERS_24H=$(curl -s "$SUPABASE_URL/rest/v1/users?select=count&created_at=gte.$(date -u -v-1d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%SZ)" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Prefer: count=exact" | jq -r '.[0].count // 0')

echo "Users created in last:"
echo "  - 24 hours: $USERS_24H"

# =====================================================
# SECTION 2: Data Integrity Checks
# =====================================================
echo ""
echo "═══ SECTION 2: DATA INTEGRITY CHECKS ═══"
echo ""

# Get all users
ALL_USERS=$(curl -s "$SUPABASE_URL/rest/v1/users?select=id,email,created_at" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

# Get all EHRs
ALL_EHRS=$(curl -s "$SUPABASE_URL/rest/v1/electronic_health_records?select=patient_id,ehr_id" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

# Get all user_profiles
ALL_PROFILES=$(curl -s "$SUPABASE_URL/rest/v1/user_profiles?select=user_id,role" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

# Check for users without EHRs
echo "Checking for users without EHRs..."
USERS_WITHOUT_EHR=0
MISSING_EHR_USERS=""

for user_id in $(echo "$ALL_USERS" | jq -r '.[].id'); do
  HAS_EHR=$(echo "$ALL_EHRS" | jq -r --arg id "$user_id" '.[] | select(.patient_id == $id) | .ehr_id')
  if [ -z "$HAS_EHR" ]; then
    USERS_WITHOUT_EHR=$((USERS_WITHOUT_EHR + 1))
    USER_EMAIL=$(echo "$ALL_USERS" | jq -r --arg id "$user_id" '.[] | select(.id == $id) | .email')
    USER_CREATED=$(echo "$ALL_USERS" | jq -r --arg id "$user_id" '.[] | select(.id == $id) | .created_at')
    MISSING_EHR_USERS="${MISSING_EHR_USERS}   - ${USER_EMAIL} (ID: ${user_id}, created: ${USER_CREATED})\n"
  fi
done

if [ $USERS_WITHOUT_EHR -gt 0 ]; then
  echo "❌ CRITICAL: $USERS_WITHOUT_EHR users without EHR records"
  echo "   Users:"
  echo -e "$MISSING_EHR_USERS" | head -10
  if [ $USERS_WITHOUT_EHR -gt 10 ]; then
    echo "   ... and $((USERS_WITHOUT_EHR - 10)) more"
  fi
else
  echo "✅ All users have EHR records"
fi

# Check for users without profiles
echo ""
echo "Checking for users without user_profiles..."
USERS_WITHOUT_PROFILE=0

for user_id in $(echo "$ALL_USERS" | jq -r '.[].id'); do
  HAS_PROFILE=$(echo "$ALL_PROFILES" | jq -r --arg id "$user_id" '.[] | select(.user_id == $id) | .role')
  if [ -z "$HAS_PROFILE" ]; then
    USERS_WITHOUT_PROFILE=$((USERS_WITHOUT_PROFILE + 1))
  fi
done

if [ $USERS_WITHOUT_PROFILE -gt 0 ]; then
  echo "ℹ️  INFO: $USERS_WITHOUT_PROFILE users without user_profiles (may be newly created)"
  echo "   Note: User profiles are created when users select their role in the app"
else
  echo "✅ All users have user_profiles"
fi

# Check profile completeness by role
echo ""
echo "Profile completeness by role:"

PATIENT_PROFILES=$(curl -s "$SUPABASE_URL/rest/v1/patient_profiles?select=count" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Prefer: count=exact" | jq -r '.[0].count // 0')

PROVIDER_PROFILES=$(curl -s "$SUPABASE_URL/rest/v1/medical_provider_profiles?select=count" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Prefer: count=exact" | jq -r '.[0].count // 0')

FACILITY_PROFILES=$(curl -s "$SUPABASE_URL/rest/v1/facility_admin_profiles?select=count" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Prefer: count=exact" | jq -r '.[0].count // 0')

SYSTEM_PROFILES=$(curl -s "$SUPABASE_URL/rest/v1/system_admin_profiles?select=count" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Prefer: count=exact" | jq -r '.[0].count // 0')

PATIENT_USERS=$(echo "$ALL_PROFILES" | jq -r '.[] | select(.role == "patient") | .user_id' | wc -l)
PROVIDER_USERS=$(echo "$ALL_PROFILES" | jq -r '.[] | select(.role == "medical_provider") | .user_id' | wc -l)
FACILITY_USERS=$(echo "$ALL_PROFILES" | jq -r '.[] | select(.role == "facility_admin") | .user_id' | wc -l)
SYSTEM_USERS=$(echo "$ALL_PROFILES" | jq -r '.[] | select(.role == "system_admin") | .user_id' | wc -l)

echo "  - patient: $PATIENT_PROFILES/$PATIENT_USERS have role-specific profile"
echo "  - medical_provider: $PROVIDER_PROFILES/$PROVIDER_USERS have role-specific profile"
echo "  - facility_admin: $FACILITY_PROFILES/$FACILITY_USERS have role-specific profile"
echo "  - system_admin: $SYSTEM_PROFILES/$SYSTEM_USERS have role-specific profile"

# =====================================================
# SECTION 3: Recent Signup Activity
# =====================================================
echo ""
echo "═══ SECTION 3: RECENT SIGNUP ACTIVITY ═══"
echo ""

echo "Last 10 user signups:"
RECENT_USERS=$(curl -s "$SUPABASE_URL/rest/v1/users?select=id,email,created_at&order=created_at.desc&limit=10" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY")

echo "$RECENT_USERS" | jq -r '.[] | "  " + .created_at + " | " + .email + " | ID:" + .id' | while read -r line; do
  USER_ID=$(echo "$line" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}')

  HAS_EHR=$(echo "$ALL_EHRS" | jq -r --arg id "$USER_ID" '.[] | select(.patient_id == $id) | .ehr_id')
  HAS_PROFILE=$(echo "$ALL_PROFILES" | jq -r --arg id "$USER_ID" '.[] | select(.user_id == $id) | .role')

  EHR_STATUS="❌"
  if [ -n "$HAS_EHR" ]; then
    EHR_STATUS="✅"
  fi

  PROFILE_STATUS="⏳"
  if [ -n "$HAS_PROFILE" ]; then
    PROFILE_STATUS="✅"
  fi

  echo "$line | EHR:$EHR_STATUS Profile:$PROFILE_STATUS"
done

# =====================================================
# SECTION 4: Summary
# =====================================================
echo ""
echo "═══ SECTION 4: AUDIT SUMMARY ═══"
echo ""

ISSUES=0

if [ $USERS_WITHOUT_EHR -gt 0 ]; then
  ISSUES=$((ISSUES + 1))
fi

if [ $ISSUES -eq 0 ]; then
  echo "✅ ✅ ✅  ALL CHECKS PASSED - System is healthy!  ✅ ✅ ✅"
else
  echo "⚠️  TOTAL ISSUES FOUND: $ISSUES"
  echo ""
  echo "RECOMMENDED ACTIONS:"

  if [ $USERS_WITHOUT_EHR -gt 0 ]; then
    echo "  1. Investigate users without EHRs - check Firebase Cloud Function logs"
    echo "     Command: firebase functions:log --only onUserCreated"
  fi
fi

echo ""
echo "Audit completed: $(date)"
echo "════════════════════════════════════════════════════════════════════"
