# User Role and EHR Integration Fix

**Date:** 2025-11-06
**Issues:** Role naming inconsistency + Missing EHR records
**Priority:** 🔴 **CRITICAL** - System violates user requirements

---

## Problem Summary

### Issue 1: Incorrect Role Naming (⚠️ HIGH)
**Current State:**
- User "dr.dummy@example.com" has role=`'doctor'`
- **Expected:** role=`'medical_provider'` (per user requirement)

**User Requirement:**
> "i have four users.
> 1. patient
> 2. medical_provider
> 3. system_admim
> 4. facility_admin"

### Issue 2: Missing EHR Records (🔴 CRITICAL)
**Current State:**
- `electronic_health_records` table has **0 records**
- 3 users exist in the system but NO EHR integration

**User Requirement:**
> "make sure this roles are in the ehr"

**Impact:**
- Users have no EHRbase EHR ID linkage
- Medical records cannot sync to EHRbase
- System violates OpenEHR integration architecture

---

## Current System State

### Users in System:
| Full Name | Email | Role (Current) | Role (Expected) |
|-----------|-------|----------------|-----------------|
| Dummy Doctor | dr.dummy@example.com | `doctor` ⚠️ | `medical_provider` |
| Akah Patient | +237691959357@medzen.com | `patient` ✅ | `patient` |
| Maurice M Temou | +12406156089@medzen.com | `patient` ✅ | `patient` |

### Role Distribution:
- ✅ `patient`: 2 users
- ⚠️ `doctor`: 1 user (should be `medical_provider`)
- ❌ `provider`: 0 users
- ❌ `medical_provider`: 0 users
- ❌ `facility_admin`: 0 users
- ❌ `system_admin`: 0 users

### EHR Records:
- **Total:** 0 records (EMPTY TABLE) 🔴
- **Expected:** 3 records (one per user)

---

## Root Cause Analysis

### Why EHR Records Are Missing:

**Possible Causes:**
1. **Users created before Firebase integration:** `onUserCreated` Cloud Function wasn't triggered
2. **Function execution failed:** Check Firebase Functions logs for errors
3. **EHRbase connection failed:** Edge function couldn't create EHR IDs
4. **Manual user creation:** Users added directly to Supabase bypassing Firebase Auth

**Verification Needed:**
```bash
# Check Firebase Cloud Function logs
firebase functions:log --only onUserCreated --limit 10

# Check Supabase edge function logs
npx supabase functions logs sync-to-ehrbase --limit 20
```

### Why Role is "doctor" instead of "medical_provider":

**Likely Cause:** FlutterFlow role selection page may use legacy role names or manual creation used wrong value.

---

## Solution

### Fix 1: Update Role Name (Execute in Supabase Dashboard)

**SQL to Execute:**
```sql
-- =====================================================
-- Fix User Role Naming
-- =====================================================
-- Change 'doctor' to 'medical_provider' to match system requirements
-- Date: 2025-11-06

-- Update the role
UPDATE user_profiles
SET role = 'medical_provider'
WHERE role = 'doctor';

-- Verify the change
SELECT user_id, role
FROM user_profiles
WHERE role IN ('doctor', 'medical_provider');
```

**Expected Result:**
- 1 row updated
- Verification query shows: `role = 'medical_provider'` (no more "doctor" roles)

### Fix 2A: Create Missing EHR Records (If EHRbase is Available)

**Prerequisite:** Verify EHRbase is accessible at `https://ehr.medzenhealth.app/ehrbase`

**Option A - Use Firebase Cloud Function:**
```bash
# Test EHRbase connection first
curl -u "ehrbase-admin:EvenMoreSecretPassword" \
  https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/ehr

# If successful, trigger EHR creation for existing users via Firebase
# (This would require custom function deployment)
```

**Option B - Manual EHR Creation via Supabase Edge Function:**
```sql
-- Create placeholder EHR records (will be populated by edge function)
-- WARNING: This requires sync-to-ehrbase edge function to be working

-- For each user, insert placeholder EHR record
-- The edge function will create actual EHRbase EHR and update the ehrbase_ehr_id

-- Patient 1: Akah Patient
INSERT INTO electronic_health_records (user_id, created_at, updated_at)
VALUES ('33c60aec-8b9e-4459-9dde-0ebd99a88a74', NOW(), NOW());

-- Patient 2: Maurice M Temou
INSERT INTO electronic_health_records (user_id, created_at, updated_at)
VALUES ('af1e0503-bdb1-4035-8a66-e928d24dc4b7', NOW(), NOW());

-- Provider: Dummy Doctor
INSERT INTO electronic_health_records (user_id, created_at, updated_at)
VALUES ('ae6a139c-51fd-4d7c-877d-4bf19834a07d', NOW(), NOW());
```

**IMPORTANT:** This assumes the edge function will populate `ehrbase_ehr_id` asynchronously.

### Fix 2B: Create EHR Records with Actual EHRbase EHR IDs

**If you have EHRbase credentials and it's accessible:**

```bash
# Create EHR in EHRbase for each user
EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase"
EHRBASE_USER="ehrbase-admin"
EHRBASE_PASS="EvenMoreSecretPassword"

# Create EHR for Patient 1
EHR_ID_1=$(curl -X POST \
  "$EHRBASE_URL/rest/openehr/v1/ehr" \
  -H "Content-Type: application/json" \
  -u "$EHRBASE_USER:$EHRBASE_PASS" \
  -d '{"_type":"EHR_STATUS","subject":{"external_ref":{"id":{"_type":"GENERIC_ID","value":"33c60aec-8b9e-4459-9dde-0ebd99a88a74","scheme":"user_id"},"namespace":"medzen","type":"PERSON"}},"is_modifiable":true,"is_queryable":true}' \
  | jq -r '.ehr_id.value')

# Insert into Supabase with actual EHR ID
# Then repeat for other users...
```

---

## Verification Steps

### After Applying Fix 1 (Role Update):

```sql
-- Verify role update
SELECT
  u.full_name,
  u.email,
  up.role,
  mp.professional_role
FROM users u
JOIN user_profiles up ON up.user_id = u.id
LEFT JOIN medical_provider_profiles mp ON mp.user_id = u.id
ORDER BY up.role;
```

**Expected Output:**
| full_name | email | role | professional_role |
|-----------|-------|------|-------------------|
| Dummy Doctor | dr.dummy@example.com | medical_provider | Medical Doctor |
| Akah Patient | ... | patient | NULL |
| Maurice M Temou | ... | patient | NULL |

### After Creating EHR Records:

```sql
-- Check EHR records exist
SELECT
  u.full_name,
  u.email,
  up.role,
  e.ehrbase_ehr_id,
  e.created_at
FROM users u
JOIN user_profiles up ON up.user_id = u.id
LEFT JOIN electronic_health_records e ON e.user_id = u.id
ORDER BY up.role;
```

**Expected:**
- 3 rows returned
- All rows have `ehrbase_ehr_id` populated (or will be populated by edge function)

---

## Testing

### Test 1: Verify Role-Based Access

```bash
# Test script to verify all 4 roles are recognized
cat > /tmp/test_role_system.sh << 'EOF'
#!/bin/bash
SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

for role in patient medical_provider facility_admin system_admin; do
  COUNT=$(curl -s "$SUPABASE_URL/rest/v1/user_profiles?select=count&role=eq.$role" \
    -H "apikey: $SERVICE_KEY" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "Prefer: count=exact" | jq -r '.[0].count')
  echo "$role: $COUNT users"
done
EOF

chmod +x /tmp/test_role_system.sh
/tmp/test_role_system.sh
```

### Test 2: Verify EHR Integration

```bash
# Check EHR count matches user count
USER_COUNT=$(curl -s "$SUPABASE_URL/rest/v1/users?select=count" \
  -H "Prefer: count=exact" | jq -r '.[0].count')

EHR_COUNT=$(curl -s "$SUPABASE_URL/rest/v1/electronic_health_records?select=count" \
  -H "Prefer: count=exact" | jq -r '.[0].count')

echo "Users: $USER_COUNT"
echo "EHR Records: $EHR_COUNT"

if [ "$USER_COUNT" -eq "$EHR_COUNT" ]; then
  echo "✅ EHR count matches user count"
else
  echo "⚠️  Mismatch: $USER_COUNT users but $EHR_COUNT EHR records"
fi
```

---

## Implementation Checklist

- [ ] **Step 1:** Execute Fix 1 SQL (role update) in Supabase Dashboard
- [ ] **Step 2:** Verify role update with verification query
- [ ] **Step 3:** Check EHRbase accessibility (`curl` test)
- [ ] **Step 4:** Choose Fix 2A or 2B based on EHRbase availability
- [ ] **Step 5:** Execute chosen EHR creation method
- [ ] **Step 6:** Run verification queries
- [ ] **Step 7:** Run test scripts
- [ ] **Step 8:** Check edge function logs for EHR sync activity
- [ ] **Step 9:** Document in system logs

---

## Additional Considerations

### Role Constraint (Recommended)

After fixing current data, add check constraint to prevent future issues:

```sql
-- Add check constraint for valid roles
ALTER TABLE user_profiles
ADD CONSTRAINT user_profiles_role_check
CHECK (role IN ('patient', 'medical_provider', 'facility_admin', 'system_admin'));
```

**Note:** This will prevent any role value outside the 4 approved roles.

### Firebase Function Investigation

Check if `onUserCreated` needs to be re-run for existing users:

```javascript
// Potential fix in Firebase Functions
// Re-create EHR for users missing records
exports.backfillEHRRecords = functions.https.onRequest(async (req, res) => {
  // Query Supabase for users without EHR records
  // Create EHRbase EHR for each
  // Insert into electronic_health_records table
});
```

---

## Files Created

| File | Purpose |
|------|---------|
| `USER_ROLE_FIX.md` | This document (comprehensive fix guide) |
| `/tmp/check_ehr_and_constraints.sh` | Investigation script (used for diagnosis) |
| `/tmp/test_role_system.sh` | Role verification test |

---

## Priority Level

**Overall Priority:** 🔴 **CRITICAL**

**Reasoning:**
1. System violates explicit user requirements (4 roles)
2. Missing EHR records breaks core EHR integration
3. Role naming prevents proper role-based access control
4. Affects all users attempting medical data operations

**Time to Fix:**
- Role update: 2 minutes
- EHR creation: 10-30 minutes (depending on method)
- Testing: 5 minutes
- **Total:** 15-40 minutes

---

**Last Updated:** 2025-11-06
**Status:** ⏳ Awaiting Manual Execution
**Documentation:** Complete and ready for deployment
