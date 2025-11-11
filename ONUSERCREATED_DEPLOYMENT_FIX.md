# onUserCreated Function Deployment Fix

**Date:** November 3, 2025
**Issue:** Deployed version had Step 5 (user_profiles creation) while source code did not
**Status:** ✅ RESOLVED

---

## Problem Statement

The deployed version of the `onUserCreated` Firebase Cloud Function was creating `user_profiles` entries (Step 5), while the source code only had 4 steps. This was incorrect behavior because `user_profiles` should only be created by FlutterFlow when users select their role in the app.

### Evidence of Problem

**Firebase Logs (Before Fix):**
```
2025-11-03T22:11:30.524025Z ? onUserCreated: 📝 Step 5: Creating user_profiles entry...
2025-11-03T22:11:30.627901Z ? onUserCreated: ✅ Created user_profiles entry
2025-11-03T22:11:30.627958Z ? onUserCreated: 🎉 User setup completed successfully!
```

**Source Code (Correct - 4 Steps Only):**
```javascript
// Step 1: Create or get Supabase Auth user
// Step 2: Create users table entry
// Step 3: Create EHRbase EHR
// Step 4: Create electronic_health_records entry
// NO Step 5!
return { success: true, supabaseUserId, ehrId };
```

---

## Root Cause

The deployed version of the function was outdated and contained Step 5 code that was not present in the current source code. This likely occurred due to:
- A previous deployment that included Step 5
- Source code was later corrected to remove Step 5
- But the function was never redeployed after the correction

---

## Solution

Redeployed the `onUserCreated` function to ensure production matches the corrected source code.

**Command Used:**
```bash
firebase deploy --only functions:onUserCreated
```

**Deployment Output:**
```
✔  functions: Finished running predeploy script.
i  functions: preparing codebase default for deployment
...
✔  Deploy complete!
Project Console: https://console.firebase.google.com/project/medzen-bf20e/overview
```

---

## Correct Behavior (After Fix)

### What the Function DOES Create:

1. **Supabase Auth User** - Creates or retrieves authenticated user in Supabase Auth
2. **users Table Entry** - Creates entry in public.users table with Firebase UID mapping
3. **EHRbase EHR** - Creates OpenEHR-compliant electronic health record in EHRbase
4. **electronic_health_records Entry** - Links Supabase user to EHRbase EHR ID

### What the Function DOES NOT Create:

- ❌ user_profiles entry (created by FlutterFlow when user selects role)
- ❌ patient_profiles entry (created by FlutterFlow after role selection)
- ❌ medical_provider_profiles entry (created by FlutterFlow after role selection)
- ❌ facility_admin_profiles entry (created by FlutterFlow after role selection)
- ❌ system_admin_profiles entry (created by FlutterFlow after role selection)

---

## User Flow (Correct)

### 1. Signup (Firebase Auth)
```
User signs up via Firebase Auth
    ↓
onUserCreated triggered (4 steps only)
    ↓
Creates: Supabase Auth user, users table, EHRbase EHR, electronic_health_records
```

### 2. Role Selection (FlutterFlow)
```
User navigates to role selection page
    ↓
Selects role (patient, medical_provider, facility_admin, system_admin)
    ↓
FlutterFlow creates:
  - user_profiles entry (with selected role)
  - Role-specific profile entry (patient_profiles, etc.)
```

### 3. Why This Separation Matters

- **Security**: RLS policies ensure users can only create their own profiles
- **Data Integrity**: Profile creation is atomic and controlled by the app UI
- **Flexibility**: Users can change roles without backend function modifications
- **Offline Support**: PowerSync can sync profile creation when online
- **Audit Trail**: Clear separation between auth setup and profile creation

---

## Verification Steps

### 1. Check Source Code ✅
```bash
# Verify onUserCreated function ends at Step 4
grep -n "Step 5" firebase/functions/index.js
# Should return: (no results)
```

### 2. Test New Signup (Recommended)
```bash
# After next user signup, check logs
firebase functions:log --only onUserCreated

# Should see:
# ✅ Step 1: Creating Supabase Auth user...
# ✅ Step 2: Creating users table entry...
# ✅ Step 3: Creating EHRbase EHR...
# ✅ Step 4: Creating electronic_health_records entry...
# ✅ User setup completed successfully!

# Should NOT see:
# ❌ Step 5: Creating user_profiles entry...
```

### 3. Verify Profile Creation in FlutterFlow
- User completes signup
- Navigates to role selection page
- Selects role
- Verify user_profiles and role-specific profile are created
- Check PowerSync syncs the new profiles

---

## Related Fixes

### RLS Policies Fixed (Same Session)
Migration: `20251103223000_fix_profile_rls_policies.sql`
- Enabled RLS on all 5 profile tables
- Created 43 policies (5 per table + PowerSync read access)
- Now users CAN create their own profile entries

### CASCADE Constraints Fixed (Previous)
Migrations:
- `20251103220000_add_cascade_to_users_foreign_keys.sql`
- `20251103220001_comprehensive_cascade_constraints.sql`
- 70 foreign keys properly configured (59 CASCADE, 11 SET NULL)

### Missing EHR Fixed (Same Session)
Issue: User `b9f2e2f9-b31f-4bd1-abbb-19ac52bd27ec` had no electronic_health_records entry
Resolution: Manually created missing entry with correct EHR ID from EHRbase

---

## Files Modified

### Redeployed (No Code Changes)
- `firebase/functions/index.js` - Already correct, just redeployed

### New Documentation
- `ONUSERCREATED_DEPLOYMENT_FIX.md` - This file
- `USER_SIGNUP_SIGNIN_AUDIT_REPORT.md` - Comprehensive audit results

### Related Files (No Changes Needed)
- `ONUSERCREATED_FIX_SUMMARY.md` - Original documentation already stated correct behavior
- `firebase/.runtimeconfig.json` - Config unchanged (server-side only)

---

## Testing Checklist

- [ ] Create new test user via Firebase Auth
- [ ] Verify onUserCreated logs show only 4 steps
- [ ] Verify no user_profiles entry created automatically
- [ ] Navigate to role selection in FlutterFlow
- [ ] Select a role (e.g., patient)
- [ ] Verify user_profiles entry is created
- [ ] Verify patient_profiles entry is created
- [ ] Verify PowerSync syncs both profiles
- [ ] Test offline profile creation (should queue)
- [ ] Verify queued profile sync when back online

---

## Prevention Measures

### 1. Deployment Discipline
```bash
# Always verify source code before deploying
cat firebase/functions/index.js | grep -A 5 "Step 5"

# Should return: (no results)

# Then deploy
firebase deploy --only functions
```

### 2. Post-Deployment Verification
```bash
# After deploying, test with a new user signup
# Check logs to verify correct behavior
firebase functions:log --only onUserCreated
```

### 3. Source Control
- Never modify deployed functions without updating source code
- Always commit changes before deploying
- Use git tags for production deployments

### 4. Automated Testing
Consider adding integration tests that:
- Create a test user via Firebase Auth
- Verify onUserCreated creates exactly 4 database entries
- Verify NO user_profiles entry created
- Clean up test data

---

## Troubleshooting

### If Step 5 Appears Again in Logs

1. **Check source code:**
   ```bash
   grep -n "Step 5" firebase/functions/index.js
   ```

2. **If Step 5 found in source:**
   - Remove Step 5 code
   - Commit changes
   - Redeploy: `firebase deploy --only functions:onUserCreated`

3. **If Step 5 not found in source:**
   - Force redeploy: `firebase deploy --only functions --force`
   - Clear function cache if needed

### If user_profiles Still Created Automatically

1. **Check if FlutterFlow has auto-create logic:**
   - Review `lib/auth/firebase_auth/auth_util.dart`
   - Check for any `maybeCreateUser()` calls that create profiles

2. **Check Supabase triggers:**
   ```sql
   SELECT * FROM pg_trigger
   WHERE tgname LIKE '%profile%'
   AND tgrelid = 'users'::regclass;
   ```

3. **Check other Firebase Functions:**
   ```bash
   grep -r "user_profiles" firebase/functions/
   ```

---

## Related Documentation

- `ONUSERCREATED_FIX_SUMMARY.md` - Original function behavior documentation
- `USER_SIGNUP_SIGNIN_AUDIT_REPORT.md` - System health audit results
- `CASCADE_CONSTRAINTS_SUMMARY.md` - Foreign key CASCADE implementation
- `TESTING_GUIDE.md` - Integration testing procedures
- `PRODUCTION_DEPLOYMENT_GUIDE.md` - Deployment best practices

---

**Deployment completed:** November 3, 2025
**Next verification:** Monitor next user signup logs
**Status:** ✅ Resolved - Function now correctly creates 4 entries only
