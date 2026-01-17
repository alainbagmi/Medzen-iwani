# Facility Admin AI Reporting - Test Guide

This guide provides step-by-step instructions for testing the facility admin AI reporting system, including database functions, RLS policies, edge functions, and AI-powered reporting capabilities.

**Date:** January 14, 2026
**Implementation:** Facility Admin Reporting Functions + AI Integration

---

## Overview

The facility admin reporting system enables facility administrators to request operational reports and metrics through an AI assistant. The system:

1. **Database Functions** - Four PL/pgSQL functions for facility statistics
2. **RLS Policies** - Enforced access control at database level
3. **Edge Function** - Enhanced bedrock-ai-chat that fetches statistics for facility admins
4. **AI Prompt** - System prompt includes instructions for using database functions

### Architecture Flow

```
Facility Admin → Chat Message
       ↓
bedrock-ai-chat Edge Function
       ↓
   [1] Detect role = 'operations'
   [2] Fetch facility_admin_profiles
   [3] Call get_facility_summary(facility_id, admin_user_id)
       ↓
   Database Functions
       ↓
   [Access Check] managed_facilities + can_view_reports
       ↓
   Return: patient_count, staff_count, active_users_count,
           operational_efficiency_score, patient_satisfaction_avg
       ↓
   Include in Lambda request → facilityStats
       ↓
   Lambda (Bedrock) uses stats in response context
       ↓
   AI Response with operational insights
```

---

## Prerequisites

### Test Data Requirements

You need a facility admin account with:

1. **Facility Admin Profile** with:
   - `user_id` linked to Firebase user
   - `primary_facility_id` set to a valid facility
   - `can_view_reports = true`
   - Facility ID in `managed_facilities` array

2. **Facility** record with:
   - Valid UUID
   - At least one assigned patient
   - At least one assigned provider/staff

3. **Patient Records** (for test facility):
   - Several patients with `preferred_hospital_id` = test facility

4. **Provider Records** (for test facility):
   - Entries in `facility_providers` table
   - `is_active = true`
   - `end_date IS NULL`

### Test User Setup

```sql
-- Verify facility admin has access
SELECT
  fap.id,
  fap.user_id,
  fap.primary_facility_id,
  fap.can_view_reports,
  fap.managed_facilities,
  f.name as facility_name
FROM facility_admin_profiles fap
LEFT JOIN facilities f ON f.id = fap.primary_facility_id
WHERE can_view_reports = true
LIMIT 1;
```

---

## Phase 1: Database Function Testing

### Test 1.1 - get_facility_patients_count()

**Purpose:** Verify patient count function respects access control

**Test Case:**
```sql
-- Should return patient count
SELECT * FROM get_facility_patients_count(
  'YOUR_FACILITY_ID',
  'YOUR_ADMIN_USER_ID'
);

-- Expected:
-- | patient_count | error_message |
-- | >=0           | (null)        |
```

**Verification:**
```sql
-- Verify count matches actual patients
SELECT COUNT(*) as actual_patient_count
FROM patient_profiles pp
WHERE pp.preferred_hospital_id = 'YOUR_FACILITY_ID'
  AND EXISTS (
    SELECT 1 FROM users u
    WHERE u.id = pp.user_id AND u.is_active = true
  );
```

**Access Control Test:**
```sql
-- Should be denied for admin without permission
SELECT * FROM get_facility_patients_count(
  'DIFFERENT_FACILITY_ID',
  'YOUR_ADMIN_USER_ID'
);

-- Expected: error_message = 'Access Denied: ...'
```

### Test 1.2 - get_facility_staff_count()

**Purpose:** Verify active staff count function

**Test Case:**
```sql
SELECT * FROM get_facility_staff_count(
  'YOUR_FACILITY_ID',
  'YOUR_ADMIN_USER_ID'
);

-- Expected:
-- | staff_count | error_message |
-- | >=0         | (null)        |
```

**Verification:**
```sql
-- Verify count matches actual active staff
SELECT COUNT(*) as actual_staff_count
FROM facility_providers fp
WHERE fp.facility_id = 'YOUR_FACILITY_ID'
  AND fp.is_active = true
  AND fp.end_date IS NULL;
```

### Test 1.3 - get_facility_active_users_count()

**Purpose:** Verify total active users across all roles

**Test Case:**
```sql
SELECT * FROM get_facility_active_users_count(
  'YOUR_FACILITY_ID',
  'YOUR_ADMIN_USER_ID'
);

-- Expected:
-- | user_count | error_message |
-- | >=0        | (null)        |
```

**Verification:**
```sql
-- Verify count includes patients, providers, and admins
SELECT COUNT(DISTINCT u.id) as actual_user_count
FROM users u
WHERE u.is_active = true
  AND (
    EXISTS (SELECT 1 FROM patient_profiles pp WHERE pp.user_id = u.id AND pp.preferred_hospital_id = 'YOUR_FACILITY_ID')
    OR EXISTS (SELECT 1 FROM facility_providers fp WHERE fp.facility_id = 'YOUR_FACILITY_ID' AND EXISTS (SELECT 1 FROM medical_provider_profiles mpp WHERE mpp.user_id = u.id AND mpp.id = fp.provider_id AND fp.is_active = true AND fp.end_date IS NULL))
    OR EXISTS (SELECT 1 FROM facility_admin_profiles fap WHERE fap.user_id = u.id AND fap.managed_facilities @> ARRAY['YOUR_FACILITY_ID']::TEXT[])
  );
```

### Test 1.4 - get_facility_summary()

**Purpose:** Verify comprehensive facility metrics

**Test Case:**
```sql
SELECT * FROM get_facility_summary(
  'YOUR_FACILITY_ID',
  'YOUR_ADMIN_USER_ID'
);

-- Expected:
-- | patient_count | staff_count | active_users_count | operational_efficiency_score | patient_satisfaction_avg | error_message |
-- | >=0           | >=0         | >=0                | 0-100                        | 0-5                      | (null)        |
```

**Verification:**
```sql
-- Verify efficiency and satisfaction scores come from facility admin profile
SELECT
  operational_efficiency_score,
  patient_satisfaction_avg
FROM facility_admin_profiles
WHERE managed_facilities @> ARRAY['YOUR_FACILITY_ID']::TEXT[]
LIMIT 1;
```

### Test 1.5 - RLS Policy Enforcement

**Purpose:** Verify functions enforce access control

**Test Case - Denied Access:**
```sql
-- Create a test case with:
-- 1. Facility admin A managing facility 1
-- 2. Facility admin B managing facility 2

-- Admin A tries to access facility 2:
SELECT * FROM get_facility_summary(
  'FACILITY_2_ID',
  'ADMIN_A_USER_ID'
);

-- Expected: error_message containing "Access Denied"
```

**Test Case - Denied Without Permission:**
```sql
-- Set facility admin's can_view_reports = false

UPDATE facility_admin_profiles
SET can_view_reports = false
WHERE id = 'TEST_ADMIN_ID';

-- Now try to call function:
SELECT * FROM get_facility_summary(
  'YOUR_FACILITY_ID',
  'YOUR_ADMIN_USER_ID'
);

-- Expected: error_message containing "Access Denied"

-- Restore permission:
UPDATE facility_admin_profiles
SET can_view_reports = true
WHERE id = 'TEST_ADMIN_ID';
```

---

## Phase 2: Edge Function Testing

### Test 2.1 - Facility Statistics Fetching

**Purpose:** Verify bedrock-ai-chat edge function fetches facility stats

**Test Case:**
```bash
#!/bin/bash

FACILITY_ADMIN_USER_ID="YOUR_FACILITY_ADMIN_FIREBASE_UID"
SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
ANON_KEY="YOUR_ANON_KEY"

# Step 1: Create AI conversation for facility admin
CONV_ID=$(curl -s "${SUPABASE_URL}/rest/v1/ai_conversations" \
  -X POST \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "'${FACILITY_ADMIN_USER_ID}'",
    "user_id": "'${FACILITY_ADMIN_USER_ID}'",
    "assistant_id": "b2c3d4e5-6789-01bc-def1-222222222222",
    "status": "active"
  }' | jq -r '.id // .id')

echo "Created conversation: $CONV_ID"

# Step 2: Call bedrock-ai-chat with a reporting question
curl -s "${SUPABASE_URL}/functions/v1/bedrock-ai-chat" \
  -X POST \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Give me an overview of our facility operations",
    "conversationId": "'${CONV_ID}'",
    "userId": "'${FACILITY_ADMIN_USER_ID}'",
    "preferredLanguage": "en"
  }' | jq .

# Expected Response:
# {
#   "success": true,
#   "response": "Based on current facility data...",
#   "language": "en",
#   "usage": { "inputTokens": N, "outputTokens": N, "totalTokens": N }
# }
```

**Verification - Check Edge Function Logs:**
```bash
# View edge function logs
npx supabase functions logs bedrock-ai-chat --tail

# Look for:
# "Detected user role: operations for user: ..."
# "Fetched facility statistics for facility admin: { ... }"
```

### Test 2.2 - Statistics Passed to Lambda

**Purpose:** Verify facility stats are included in Lambda request

**Test Case - AWS CloudWatch Logs:**

1. Go to AWS CloudWatch
2. Find logs for Bedrock Lambda function
3. Search for recent invocations from test
4. Look for:
   ```
   Input: {
     facilityStats: {
       patient_count: N,
       staff_count: N,
       active_users_count: N,
       operational_efficiency_score: N,
       patient_satisfaction_avg: N
     }
   }
   ```

---

## Phase 3: AI Response Testing

### Test 3.1 - Facility Admin Gets Operational Insights

**Purpose:** Verify AI includes facility statistics in response

**Test Cases:**

#### Q1: "What's our current facility status?"

Expected Response Should Include:
- Current patient count
- Current staff count
- Operational efficiency score
- Patient satisfaction metrics
- Actionable recommendations

#### Q2: "How can we improve patient flow?"

Expected Response Should:
- Reference actual facility metrics
- Suggest efficiency improvements
- Provide data-driven recommendations

#### Q3: "What are our staffing levels?"

Expected Response Should:
- Report accurate staff count
- Identify any staffing gaps
- Suggest optimization strategies

### Test 3.2 - Error Handling

**Test Case - Facility Without Permission:**

```bash
# Use a facility admin who doesn't have can_view_reports = true
# Or who doesn't manage the facility

curl -s "${SUPABASE_URL}/functions/v1/bedrock-ai-chat" \
  -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Show me facility metrics",
    "conversationId": "'${CONV_ID}'",
    "userId": "'${ADMIN_WITHOUT_PERMISSION}'",
    "preferredLanguage": "en"
  }' | jq .

# Expected:
# AI should respond explaining they lack permission to view those metrics
# No actual stats should be included
```

---

## Phase 4: Integration Testing

### Test 4.1 - Multi-Facility Admin

**Purpose:** Verify admin managing multiple facilities can query any of them

**Setup:**
```sql
-- Create facility admin managing 2 facilities
UPDATE facility_admin_profiles
SET managed_facilities = ARRAY['FACILITY_1_ID', 'FACILITY_2_ID']::TEXT[]
WHERE id = 'TEST_ADMIN_ID';
```

**Test:**
```bash
# Ask about facility 1
curl -s "${SUPABASE_URL}/functions/v1/bedrock-ai-chat" \
  -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What are the metrics for facility 1?",
    "conversationId": "'${CONV_ID}'",
    "userId": "'${ADMIN_USER_ID}'",
    "preferredLanguage": "en"
  }' | jq .

# Should return facility 1 stats

# Ask about facility 2
# Should return facility 2 stats
```

### Test 4.2 - System Admin (No Facility Stats)

**Purpose:** Verify system admins don't get facility stats (role-specific behavior)

**Test:**
```bash
# Use a system admin user (role = 'platform')

curl -s "${SUPABASE_URL}/functions/v1/bedrock-ai-chat" \
  -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Show me operational metrics",
    "conversationId": "'${CONV_ID}'",
    "userId": "'${SYSTEM_ADMIN_ID}'",
    "preferredLanguage": "en"
  }' | jq .

# Expected:
# Response should NOT include facilityStats (not 'operations' role)
# AI should provide platform-level guidance instead
```

---

## Phase 5: Performance Testing

### Test 5.1 - Query Performance

**Measure:** Time to fetch facility statistics

```sql
-- Benchmark get_facility_summary performance
SELECT
  'get_facility_summary' as function_name,
  COUNT(*) as calls,
  AVG(EXTRACT(EPOCH FROM (response_time_ms || ' ms')::interval)) as avg_response_time_ms,
  MAX(EXTRACT(EPOCH FROM (response_time_ms || ' ms')::interval)) as max_response_time_ms
FROM ai_messages
WHERE created_at > NOW() - INTERVAL '1 hour'
  AND model_used LIKE '%nova%';
```

**Acceptance Criteria:**
- Function executes in < 500ms
- Edge function roundtrip < 2 seconds (including Lambda)
- AI response generation < 10 seconds

### Test 5.2 - Concurrent Requests

**Test Case:**
```bash
#!/bin/bash

# Simulate 5 concurrent facility admin requests
for i in {1..5}; do
  curl -s "${SUPABASE_URL}/functions/v1/bedrock-ai-chat" \
    -X POST \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
      "message": "Facility metrics request #'$i'",
      "conversationId": "'${CONV_ID}'",
      "userId": "'${ADMIN_USER_ID}'",
      "preferredLanguage": "en"
    }' | jq '.success' &
done

wait
# All should return true
```

---

## Troubleshooting

### Issue: "Access Denied: You do not have permission to view reports"

**Solution:**
1. Verify `can_view_reports = true` in facility_admin_profiles
2. Verify facility_id is in `managed_facilities` array
3. Check exact facility_id match (case-sensitive, UUID format)

### Issue: "Function returned error for facility stats"

**Logs:**
```bash
# Check edge function logs
npx supabase functions logs bedrock-ai-chat --tail

# Look for: "Function returned error for facility stats: ..."
```

**Solution:**
1. Verify facility_id exists in facilities table
2. Verify admin user has access to facility
3. Check database function permissions

### Issue: facilityStats not included in Lambda request

**Logs:**
```bash
# Check edge function logs
npx supabase functions logs bedrock-ai-chat --tail

# Should see: "Detected user role: operations"
# Should see: "Fetched facility statistics for facility admin: ..."
```

**Solution:**
1. Verify assistant_type is being detected as 'operations'
2. Verify facilityAdminProfile query is returning data
3. Check RPC call for errors

### Issue: AI response doesn't mention facility metrics

**Check:**
1. Verify facilityStats were fetched (check logs)
2. Verify facilityStats were passed to Lambda
3. Verify Lambda is using the facilityStats in context
4. Update system prompt if needed

---

## Sign-Off Checklist

- [ ] Database function calls return correct data
- [ ] RLS policies correctly deny unauthorized access
- [ ] Edge function detects facility admin role
- [ ] Edge function fetches facility statistics
- [ ] Facility stats passed to Lambda
- [ ] AI responses include facility metrics
- [ ] Error handling works for denied access
- [ ] Performance meets acceptance criteria
- [ ] Multi-facility admins work correctly
- [ ] System admins don't get facility stats
- [ ] Concurrent requests handled correctly

---

## Reference

**Database Functions:**
- `get_facility_patients_count(facility_id, admin_user_id)`
- `get_facility_staff_count(facility_id, admin_user_id)`
- `get_facility_active_users_count(facility_id, admin_user_id)`
- `get_facility_summary(facility_id, admin_user_id)`

**Edge Function:**
- `supabase/functions/bedrock-ai-chat/index.ts`

**System Prompt:**
- Updated in migration: `20260114100000_update_facility_admin_system_prompt_with_db_queries.sql`

**Files Modified:**
- `supabase/functions/bedrock-ai-chat/index.ts` - Added facility stats fetching
- Migrations applied:
  - `20260114000000_create_facility_admin_reporting_functions.sql`
  - `20260114100000_update_facility_admin_system_prompt_with_db_queries.sql`
