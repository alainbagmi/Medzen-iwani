# Database Verification SQL Queries

This document contains SQL queries to verify database setup and diagnose patient landing page data loading issues.

## Prerequisites

Run these queries in **Supabase SQL Editor** (Dashboard → SQL Editor → New Query)

Replace `YOUR_FIREBASE_UID_HERE` with the actual Firebase UID of the user experiencing issues.

---

## 1. Verify User Exists in Users Table

```sql
-- Check if user exists in the users table
SELECT
  id as user_id,
  firebase_uid,
  email,
  full_name,
  created_at
FROM users
WHERE firebase_uid = 'YOUR_FIREBASE_UID_HERE';
```

**Expected Result:** 1 row with non-null values
**If Empty:** User was not created during signup - check Firebase `onUserCreated` function logs

---

## 2. Check User Profile Exists

```sql
-- Check if user_profile exists for the user
SELECT
  up.id as profile_id,
  up.user_id,
  up.display_name,
  up.date_of_birth,
  up.gender,
  up.phone_number,
  up.avatar_url,
  up.created_at,
  u.firebase_uid,
  u.email
FROM user_profiles up
JOIN users u ON u.id = up.user_id
WHERE u.firebase_uid = 'YOUR_FIREBASE_UID_HERE';
```

**Expected Result:** 1 row with `display_name` populated
**If Empty:** User profile not created - need to complete profile setup
**If display_name is NULL:** User hasn't set their display name yet

---

## 3. Check Patient Profile Exists

```sql
-- Check if patient_profile exists (for patients only)
SELECT
  pp.id as patient_profile_id,
  pp.user_id,
  pp.patient_number,
  pp.blood_type,
  pp.allergies,
  pp.created_at,
  u.firebase_uid,
  u.email,
  up.display_name
FROM patient_profiles pp
JOIN users u ON u.id = pp.user_id
LEFT JOIN user_profiles up ON up.user_id = u.id
WHERE u.firebase_uid = 'YOUR_FIREBASE_UID_HERE';
```

**Expected Result:** 1 row with `patient_number` populated (for patients)
**If Empty:** Patient profile not created during signup
**If patient_number is NULL:** Auto-generation trigger didn't fire

---

## 4. Verify Complete User Data (All Profiles)

```sql
-- Complete view of user and all related profiles
SELECT
  u.id as user_id,
  u.firebase_uid,
  u.email,
  u.full_name,
  up.display_name,
  up.date_of_birth,
  up.gender,
  up.phone_number,
  pp.patient_number,
  pp.blood_type,
  mpp.provider_number,
  mpp.specialization,
  fap.admin_number,
  fap.facility_id,
  sap.admin_number as system_admin_number,
  sap.permissions
FROM users u
LEFT JOIN user_profiles up ON up.user_id = u.id
LEFT JOIN patient_profiles pp ON pp.user_id = u.id
LEFT JOIN medical_provider_profiles mpp ON mpp.user_id = u.id
LEFT JOIN facility_admin_profiles fap ON fap.user_id = u.id
LEFT JOIN system_admin_profiles sap ON sap.user_id = u.id
WHERE u.firebase_uid = 'YOUR_FIREBASE_UID_HERE';
```

**Expected Result:** 1 row with appropriate profile columns populated based on user role
**Diagnosis:**
- If all profile columns are NULL → Profiles not created
- If only display_name is NULL → User profile incomplete
- If patient_number is NULL (for patients) → Patient profile incomplete

---

## 5. Check Row-Level Security (RLS) Policies

```sql
-- List all RLS policies for user-related tables
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd as operation,
  qual as using_expression,
  with_check
FROM pg_policies
WHERE tablename IN ('users', 'user_profiles', 'patient_profiles',
                    'medical_provider_profiles', 'facility_admin_profiles',
                    'system_admin_profiles')
ORDER BY tablename, cmd;
```

**Expected Result:** List of policies allowing authenticated users to read their own data
**Check For:**
- `SELECT` policies that allow users to read their own records
- Policies using `auth.uid()` or similar expressions
- No overly restrictive policies blocking legitimate access

---

## 6. Test RLS Policy for Current User (Run as User)

```sql
-- This query should be run while authenticated as the user
-- (Use Supabase Studio's "Run as" feature or API)
SELECT
  id,
  firebase_uid,
  email
FROM users
WHERE id = auth.uid();
```

**Expected Result:** 1 row (the current authenticated user)
**If Empty:** RLS policy is blocking access - policy needs adjustment

---

## 7. Check Electronic Health Records

```sql
-- Verify EHRbase EHR was created
SELECT
  ehr.id,
  ehr.user_id,
  ehr.patient_id,
  ehr.ehrbase_ehr_id,
  ehr.created_at,
  u.firebase_uid,
  u.email,
  up.display_name
FROM electronic_health_records ehr
JOIN users u ON u.id = ehr.user_id
LEFT JOIN user_profiles up ON up.user_id = u.id
WHERE u.firebase_uid = 'YOUR_FIREBASE_UID_HERE';
```

**Expected Result:** 1 row with non-null `ehrbase_ehr_id`
**If Empty:** EHRbase EHR not created - check Firebase `onUserCreated` function

---

## 8. Find Users Without Display Names

```sql
-- List all users missing display names (potential data issue)
SELECT
  u.id,
  u.firebase_uid,
  u.email,
  u.created_at,
  CASE
    WHEN up.id IS NULL THEN 'No user_profile'
    WHEN up.display_name IS NULL THEN 'display_name is NULL'
    WHEN up.display_name = '' THEN 'display_name is empty string'
    ELSE 'OK'
  END as status
FROM users u
LEFT JOIN user_profiles up ON up.user_id = u.id
WHERE up.display_name IS NULL OR up.display_name = ''
ORDER BY u.created_at DESC
LIMIT 20;
```

**Use Case:** Identify users affected by the missing display name issue

---

## 9. Test GraphQL Query (Simulated)

```sql
-- Simulate the GraphQL query used by the landing page
-- This mimics: SupagraphqlGroup.userDetailsCall
WITH user_data AS (
  SELECT id FROM users WHERE firebase_uid = 'YOUR_FIREBASE_UID_HERE'
)
SELECT
  json_build_object(
    'user_profilesCollection', json_build_object(
      'edges', json_agg(
        json_build_object(
          'node', json_build_object(
            'display_name', up.display_name,
            'date_of_birth', up.date_of_birth,
            'gender', up.gender,
            'phone_number', up.phone_number,
            'avatar_url', up.avatar_url
          )
        )
      )
    )
  ) as graphql_response
FROM user_profiles up
WHERE up.user_id = (SELECT id FROM user_data);
```

**Expected Result:** JSON response with `display_name` field populated
**If NULL or Empty Array:** Data doesn't exist or RLS is blocking

---

## 10. Check Database Triggers

```sql
-- Verify that necessary database triggers exist
SELECT
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE event_object_table IN ('users', 'user_profiles', 'patient_profiles')
  AND trigger_name LIKE '%ehrbase%'
ORDER BY event_object_table, trigger_name;
```

**Expected Result:** List of EHRbase sync triggers
**If Empty:** Triggers not created - migrations may not have been applied

---

## 11. Quick Health Check (All-in-One)

```sql
-- Comprehensive health check for a user
WITH user_check AS (
  SELECT id, firebase_uid, email FROM users WHERE firebase_uid = 'YOUR_FIREBASE_UID_HERE'
),
profile_check AS (
  SELECT user_id, display_name FROM user_profiles WHERE user_id = (SELECT id FROM user_check)
),
patient_check AS (
  SELECT user_id, patient_number FROM patient_profiles WHERE user_id = (SELECT id FROM user_check)
)
SELECT
  CASE
    WHEN uc.id IS NULL THEN '❌ User not found'
    WHEN pc.user_id IS NULL THEN '❌ Profile not found'
    WHEN pc.display_name IS NULL THEN '⚠️ Display name not set'
    WHEN pc.display_name = '' THEN '⚠️ Display name empty'
    ELSE '✅ All checks passed'
  END as status,
  uc.firebase_uid,
  uc.email,
  pc.display_name,
  pat.patient_number
FROM user_check uc
LEFT JOIN profile_check pc ON true
LEFT JOIN patient_check pat ON true;
```

**One Query to Rule Them All:** Quick diagnosis of user data completeness

---

## Troubleshooting Based on Results

### Issue: User not found in users table
**Cause:** Firebase `onUserCreated` function didn't execute or failed
**Fix:**
1. Check Firebase Functions logs: `firebase functions:log --only onUserCreated`
2. Verify function is deployed: `firebase functions:list`
3. Check Supabase credentials in Firebase config: `firebase functions:config:get`

### Issue: User profile doesn't exist
**Cause:** Signup flow incomplete or profile creation failed
**Fix:**
1. User needs to complete profile setup
2. Or manually create profile:
```sql
INSERT INTO user_profiles (user_id, display_name, created_at)
VALUES ('USER_ID_HERE', 'User Name', NOW());
```

### Issue: Display name is NULL
**Cause:** User hasn't set their display name yet
**Fix:**
1. Update profile:
```sql
UPDATE user_profiles
SET display_name = 'User Name'
WHERE user_id = 'USER_ID_HERE';
```

### Issue: RLS blocking access
**Cause:** RLS policies too restrictive
**Fix:**
1. Temporarily disable RLS for testing:
```sql
ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;
-- Test if data appears
-- Re-enable:
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
```
2. If data appears, fix RLS policies

### Issue: GraphQL query returns empty edges
**Cause:** Either no data or RLS blocking
**Fix:**
1. Run query #9 to see raw results
2. If raw query works but GraphQL doesn't → RLS issue
3. If raw query also fails → data doesn't exist

---

## Monitoring Queries (Production)

### Count users by profile completeness
```sql
SELECT
  COUNT(*) FILTER (WHERE up.display_name IS NOT NULL) as users_with_display_name,
  COUNT(*) FILTER (WHERE up.display_name IS NULL) as users_without_display_name,
  COUNT(*) FILTER (WHERE up.id IS NULL) as users_without_profile
FROM users u
LEFT JOIN user_profiles up ON up.user_id = u.id
WHERE u.created_at > NOW() - INTERVAL '7 days';
```

### Recent signups without profiles
```sql
SELECT
  u.id,
  u.firebase_uid,
  u.email,
  u.created_at,
  CASE WHEN up.id IS NULL THEN 'No profile' ELSE 'Has profile' END as status
FROM users u
LEFT JOIN user_profiles up ON up.user_id = u.id
WHERE u.created_at > NOW() - INTERVAL '24 hours'
ORDER BY u.created_at DESC;
```

---

## Notes

1. **Always replace** `YOUR_FIREBASE_UID_HERE` with actual Firebase UID
2. **Get Firebase UID** from Firebase Console → Authentication → Users → UID column
3. **Run queries as authenticated user** when testing RLS (use Supabase Studio's "Run as" feature)
4. **Production queries** should be run with caution and proper access controls
5. **Never expose** user data or Firebase UIDs in logs or screenshots

---

## Related Documentation

- POWERSYNC_QUICK_START.md - PowerSync setup and troubleshooting
- TESTING_GUIDE.md - System integration testing procedures
- EHR_SYSTEM_README.md - Complete EHR system architecture
- CLAUDE.md - Project overview and development guidelines
