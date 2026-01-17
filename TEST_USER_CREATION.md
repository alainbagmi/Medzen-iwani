# User Creation Test Guide

## ✅ Fix Deployed
The `onUserCreated` function has been fixed and deployed with the required `@supabase/supabase-js` dependency.

**Deployment Time:** 2026-01-09 22:31:38 UTC
**Commit:** a58930a - "fix: Re-add @supabase/supabase-js dependency for onUserCreated function"

---

## 🧪 Manual Test Instructions

### Option 1: Test via Mobile App

1. **Open your MedZen mobile app**
2. **Navigate to Sign Up page**
3. **Create a new test user:**
   - Email: `test_$(date +%s)@medzen-test.com` (or any unique email)
   - Password: TestPassword123! (or your preferred test password)
   - Phone: Any test phone number

4. **Complete registration**

5. **Check the logs immediately:**
   ```bash
   firebase functions:log --only onUserCreated
   ```

### Option 2: Test via Firebase Console

1. **Go to Firebase Console:** https://console.firebase.google.com/project/medzen-bf20e/authentication/users
2. **Click "Add user"**
3. **Enter test user details:**
   - Email: `console-test-$(date +%s)@medzen-test.com`
   - Password: TestPassword123!
4. **Click "Add user"**
5. **Check logs immediately** (see below)

### Option 3: Monitor Logs in Real-Time

Open a terminal and run:
```bash
# Terminal 1: Start log monitoring
firebase functions:log --only onUserCreated

# Terminal 2: Create user (via app or console)
```

---

## ✅ Expected Success Output

When user creation works correctly, you should see:

```
🚀 onUserCreated triggered for: user@example.com abc123uid
📝 Step 1: Creating Supabase Auth user...
✅ Supabase Auth user created: 45ba4979-72a7-4e41-9a8a-06965645d930
📝 Step 2: Creating Supabase users table record...
✅ Supabase users table record created
📝 Step 3: Checking for existing EHR linkage...
📝 Step 3b: Creating new EHRbase EHR...
✅ EHRbase EHR created: 33188bb6-076b-40b3-96bd-69066d54cfec
📝 Step 4: Creating electronic_health_records entry...
✅ electronic_health_records entry created
📝 Step 5: Updating Firestore user document...
✅ Firestore user document updated
🎉 Success! User created in all systems
   Firebase UID: abc123uid
   Supabase ID: 45ba4979-72a7-4e41-9a8a-06965645d930
   EHR ID: 33188bb6-076b-40b3-96bd-69066d54cfec
   Duration: 5448ms
```

## ❌ Previous Error (FIXED)

The previous error you saw was:
```
❌ Error: Cannot find module '@supabase/supabase-js'
```

This error **will no longer occur** because:
1. Dependency added to package.json
2. Function redeployed with dependency
3. Fix committed to git permanently

---

## 🔍 Verify User Creation in Databases

After creating a test user, verify in all systems:

### 1. Firebase Auth
```bash
# Via Firebase Console
https://console.firebase.google.com/project/medzen-bf20e/authentication/users
```

### 2. Supabase Users Table
```sql
-- Run in Supabase SQL Editor
SELECT
  id,
  firebase_uid,
  email,
  account_status,
  is_active,
  created_at
FROM users
WHERE email = 'your-test-email@medzen-test.com';
```

### 3. Firestore User Document
```bash
# Via Firebase Console
https://console.firebase.google.com/project/medzen-bf20e/firestore/data/~2Fusers
```

### 4. EHRbase Record (if configured)
```sql
-- Run in Supabase SQL Editor
SELECT
  patient_id,
  ehr_id,
  ehr_status,
  created_at
FROM electronic_health_records
WHERE patient_id = (
  SELECT id FROM users WHERE email = 'your-test-email@medzen-test.com'
);
```

---

## 🐛 Troubleshooting

### If logs show errors:

1. **Check exact error message** in Firebase logs
2. **Run this command** to see full details:
   ```bash
   firebase functions:log --only onUserCreated | grep -A 30 "Error"
   ```

3. **Common issues:**
   - **Missing Supabase config:** Check `firebase functions:config:get supabase`
   - **EHRbase connection:** Check `firebase functions:config:get ehrbase`
   - **Network timeout:** EHRbase might be unreachable

### If no logs appear:

1. **Verify function is deployed:**
   ```bash
   firebase functions:list | grep onUserCreated
   ```

2. **Check function is active:**
   ```bash
   firebase functions:log --only onUserCreated | tail -5
   ```

---

## ✅ Test Completion Checklist

- [ ] Create new test user (via app or console)
- [ ] Check Firebase logs for success messages
- [ ] Verify user in Firebase Auth
- [ ] Verify user in Supabase users table
- [ ] Verify user in Firestore
- [ ] (Optional) Verify EHR record created
- [ ] No "Cannot find module" errors
- [ ] All systems show user created

---

## 🎯 Quick Test Command

Run this in one terminal to monitor logs, then create a user in another window:

```bash
#!/bin/bash
echo "🔍 Monitoring onUserCreated function..."
echo "📝 Create a new user now in the app or Firebase Console"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
firebase functions:log --only onUserCreated
```

---

**Status:** ✅ Ready for testing
**Last Updated:** 2026-01-09 22:44 UTC
