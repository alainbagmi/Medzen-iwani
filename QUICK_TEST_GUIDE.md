# Quick Test Guide - onUserCreated Function

**Status:** ✅ Fixed and redeployed (2025-11-10 04:15 UTC)
**Fix:** Changed error check from `authError.message.includes()` to `authError.code === 'email_exists'`
**Date:** 2025-11-10

---

## Option 1: Quick Manual Test (Recommended - 2 minutes)

Since creating users programmatically requires Firebase Admin SDK credentials that aren't set up locally, here's the fastest way to test:

### Step 1: Create Test User (30 seconds)

Open Firebase Console and create a test user:

**Direct Link:** https://console.firebase.google.com/project/medzen-bf20e/authentication/users

1. Click "Add user"
2. Enter:
   - **Email:** `test-onusercreated-$(date +%s)@medzen-test.com`
     (Or just: `test123@medzen-test.com`)
   - **Password:** `TestPassword123!`
3. Click "Add user"

### Step 2: Verify Function (1 minute)

Run the verification script:

```bash
./verify_onusercreated.sh test123@medzen-test.com
```

The script will check:
- ✅ Supabase Auth user created
- ✅ electronic_health_records entry created
- ✅ Correct fields populated

### Step 3: Cleanup (30 seconds)

Delete the test user from:
1. **Firebase Console:** https://console.firebase.google.com/project/medzen-bf20e/authentication/users
2. **Supabase Studio:** https://supabase.com/dashboard/project/noaeltglphdlkbflipit/auth/users

---

## Option 2: Test via Your App (Recommended for Full Flow)

1. Open your MedZen app
2. Go to signup screen
3. Create a new user with a fresh email (never used before)
4. Wait 10 seconds for Cloud Function to complete
5. Run verification script:
   ```bash
   ./verify_onusercreated.sh <your-test-email>
   ```

---

## What the Function Does (Architecture)

```
Firebase Signup (your app or console)
      ↓
  onUserCreated Cloud Function triggers
      ↓
  Creates:
    1. Supabase Auth user (email only)
    2. electronic_health_records entry (ehr_id = null, status = pending)
    3. Firestore doc (with supabase_user_id linkage)
      ↓
  FlutterFlow (your responsibility)
    - Updates users table with profile details
    - Creates role-specific profile (patient_profiles, etc.)
      ↓
  Database Trigger (automatic)
    - Updates user_role in electronic_health_records
      ↓
  Edge Function (automatic, async)
    - Creates EHRbase EHR
    - Updates ehr_id in electronic_health_records
```

---

## Expected Results

### ✅ Success Looks Like:

**Supabase Auth:**
```json
{
  "id": "abc123-...",
  "email": "test@medzen-test.com",
  "created_at": "2025-11-10T..."
}
```

**electronic_health_records:**
```json
{
  "id": 123,
  "patient_id": "abc123-...",
  "ehr_id": null,  // ⚠️ This is CORRECT - filled later by Edge Function
  "ehr_status": "pending_ehr_creation",
  "user_role": "patient"
}
```

**Firestore:**
```json
{
  "uid": "firebase-uid-...",
  "email": "test@medzen-test.com",
  "supabase_user_id": "abc123-..."
}
```

---

## Troubleshooting

### ❌ Supabase Auth user not found

**Check Cloud Function logs:**
```bash
firebase functions:log --only onUserCreated --limit 10
```

**Look for:**
- "✅ Supabase Auth user created" (success)
- "❌ Supabase Auth creation failed" (error)

**Common fixes:**
- Verify Firebase Functions config: `firebase functions:config:get`
- Check Supabase URL and service key are correct

### ❌ electronic_health_records entry not found

**Check Cloud Function logs for:**
- "✅ electronic_health_records entry created"
- "❌ electronic_health_records insert failed"

**Common fixes:**
- Verify Supabase service key has INSERT permissions
- Check table exists: Query in Supabase Studio

### ❌ 422 "email_exists" error (Old Issue - Should be fixed now)

This was the original issue. The deployed function now handles this gracefully:
- Tries to create user
- If "already been registered" error, fetches existing user ID
- Continues with that ID instead of failing

---

## Why Programmatic Test Doesn't Work

The test scripts (`test_onusercreated_flow.js`) require Firebase Admin SDK credentials:

```
Error: Could not load the default credentials.
```

**Options to fix (for future):**
1. Set up service account JSON file
2. Use `gcloud auth application-default login`
3. Use Firebase Emulator (doesn't trigger real Cloud Functions)

**For now:** Manual testing via Firebase Console is fastest and most reliable.

---

## Next Steps After Verification

1. ✅ Verify function works (use this guide)
2. 🔨 Implement FlutterFlow action to:
   - Update users table with profile details
   - Create role-specific profile
3. ✅ Database trigger will update user_role automatically (already deployed)
4. ✅ Edge Function will create EHRbase EHR asynchronously (already deployed)

---

**Report Generated:** 2025-11-10
**Function Status:** ✅ Deployed with idempotency fix
