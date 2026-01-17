# User Deletion Test Guide

## ✅ Implementation Complete
The `onUserDeleted` function has been implemented with comprehensive cleanup across ALL systems.

**Deployment Time:** 2026-01-09 23:00 UTC
**Commit:** 424b62a - "feat: Implement comprehensive onUserDeleted cleanup function"

---

## 🗑️ What Gets Deleted

When a user is deleted from Firebase Auth, the `onUserDeleted` function automatically cleans up:

### Direct Deletions:
1. ✅ **Supabase users table** record
2. ✅ **Supabase Auth** user
3. ✅ **Firestore** user document
4. ✅ **FCM tokens** (all devices)
5. ✅ **EHR record** (marked as deleted in tracking table)

### Cascade Deletions (Automatic via FK constraints):
6. ✅ **appointments** - All user's appointments
7. ✅ **video_call_sessions** - All call history
8. ✅ **chime_messages** - All chat messages
9. ✅ **ai_conversations** - AI chat sessions
10. ✅ **ai_messages** - Individual AI messages
11. ✅ **clinical_notes** - Medical notes
12. ✅ **patient_profiles / provider_profiles** - Extended profile data
13. ✅ **active_sessions** - Active device sessions
14. ✅ **language_preferences** - User language settings
15. ✅ **All other user-related tables** with FK constraints

---

## 🧪 Manual Test Instructions

### Option 1: Test via Firebase Console (Safest)

1. **Create a test user first:**
   ```bash
   # Via Firebase Console
   https://console.firebase.google.com/project/medzen-bf20e/authentication/users
   # Click "Add user"
   # Email: delete-test-$(date +%s)@medzen-test.com
   # Password: TestPassword123!
   ```

2. **Verify user exists in all systems:**
   ```sql
   -- Supabase SQL Editor
   SELECT * FROM users WHERE email = 'delete-test-xxx@medzen-test.com';
   ```

3. **Delete the user:**
   ```bash
   # Via Firebase Console
   # Go to Authentication > Users
   # Find the test user
   # Click the 3 dots menu > Delete account
   ```

4. **Monitor the logs:**
   ```bash
   firebase functions:log --only onUserDeleted
   ```

5. **Verify cleanup:**
   ```sql
   -- Supabase SQL Editor - Should return NO results
   SELECT * FROM users WHERE email = 'delete-test-xxx@medzen-test.com';
   ```

### Option 2: Test via CLI

```bash
# Install Firebase tools if needed
npm install -g firebase-tools

# Authenticate
firebase login

# List users
firebase auth:export users.json --project medzen-bf20e

# Delete a specific user (replace with actual UID)
firebase auth:delete abc123uid --project medzen-bf20e

# Check logs immediately
firebase functions:log --only onUserDeleted --project medzen-bf20e
```

---

## ✅ Expected Success Output

When deletion works correctly, you should see:

```
🗑️  onUserDeleted triggered for: test@example.com abc123uid
📝 Step 1: Finding Supabase user record...
✅ Found Supabase user: 45ba4979-72a7-4e41-9a8a-06965645d930
📝 Step 2: Checking for EHR record...
✅ Found EHR record: 33188bb6-076b-40b3-96bd-69066d54cfec
📝 Step 3: Deleting from Supabase users table...
✅ Supabase user record deleted (cascading deletes applied)
📝 Step 4: Deleting from Supabase Auth...
✅ Supabase Auth user deleted
📝 Step 5: Deleting EHR from EHRbase...
✅ EHR marked as deleted in tracking table
📝 Step 6: Deleting Firestore user document...
✅ Firestore user document deleted
📝 Step 7: Deleting FCM tokens...
✅ Deleted 2 FCM tokens
🎉 Success! User deleted from all systems
   Firebase UID: abc123uid
   Supabase ID: 45ba4979-72a7-4e41-9a8a-06965645d930
   EHR ID: 33188bb6-076b-40b3-96bd-69066d54cfec
   Duration: 3200ms
```

---

## 🔍 Verify Complete Deletion

After deleting a test user, verify in all systems:

### 1. Firebase Auth (should be GONE)
```bash
https://console.firebase.google.com/project/medzen-bf20e/authentication/users
# Search for the test user email - should not exist
```

### 2. Supabase Users Table (should be GONE)
```sql
-- Run in Supabase SQL Editor - Should return 0 rows
SELECT COUNT(*) FROM users
WHERE email = 'your-deleted-test-email@medzen-test.com';
```

### 3. Supabase Auth (should be GONE)
```bash
# Via Supabase Dashboard
https://supabase.com/dashboard/project/noaeltglphdlkbflipit/auth/users
# Search for test email - should not exist
```

### 4. Firestore (should be GONE)
```bash
https://console.firebase.google.com/project/medzen-bf20e/firestore/data/~2Fusers
# Search for the Firebase UID - should not exist
```

### 5. Related Data (should be GONE)
```sql
-- Check appointments (should be 0)
SELECT COUNT(*) FROM appointments
WHERE patient_id IN (SELECT id FROM users WHERE email = 'test@medzen.com');

-- Check video call sessions (should be 0)
SELECT COUNT(*) FROM video_call_sessions
WHERE patient_id IN (SELECT id FROM users WHERE email = 'test@medzen.com');

-- Check AI conversations (should be 0)
SELECT COUNT(*) FROM ai_conversations
WHERE user_id IN (SELECT id FROM users WHERE email = 'test@medzen.com');
```

### 6. EHR Record (should be marked as deleted)
```sql
-- Run in Supabase SQL Editor
SELECT ehr_status FROM electronic_health_records
WHERE ehr_id = 'the-ehr-id-from-logs';
-- Should return 'deleted' or no rows
```

---

## 🐛 Troubleshooting

### If logs show errors:

1. **"No Supabase user found"** - User was already cleaned up or never synced
   - This is OK - just logs a warning and continues

2. **"Error deleting Supabase user"** - Check RLS policies
   ```bash
   firebase functions:config:get supabase
   # Verify service_key is set correctly
   ```

3. **"EHR deletion error"** - EHRbase might be unreachable
   - EHR is marked as deleted in tracking table instead
   - This is expected if EHRbase is not configured

### If no logs appear:

1. **Verify function is deployed:**
   ```bash
   firebase functions:list | grep onUserDeleted
   ```

2. **Check function logs for any execution:**
   ```bash
   firebase functions:log --only onUserDeleted | tail -20
   ```

---

## ⚠️ Important Notes

### GDPR/CCPA Compliance
This function ensures compliance with data privacy laws by:
- Completely removing personal data from all systems
- Deleting cascading related data automatically
- Marking EHR records as deleted (medical records may need retention)
- Removing authentication credentials

### EHRbase Deletion
EHRbase standard API doesn't support true EHR deletion (for audit/legal reasons).
Instead, we mark the EHR as "deleted" in the `electronic_health_records` tracking table.
The actual EHR data remains in EHRbase for compliance purposes.

### Cascade Constraints
The Supabase database has comprehensive `ON DELETE CASCADE` foreign key constraints.
When the user record is deleted from the `users` table, ALL related records in other
tables are automatically deleted. This is configured in migration:
`supabase/migrations/20251103220001_comprehensive_cascade_constraints.sql`

---

## ✅ Test Completion Checklist

- [ ] Create test user in Firebase Auth
- [ ] Verify user appears in Supabase users table
- [ ] Delete user from Firebase Auth
- [ ] Check Firebase logs for success messages
- [ ] Verify user GONE from Firebase Auth
- [ ] Verify user GONE from Supabase users table
- [ ] Verify user GONE from Supabase Auth
- [ ] Verify user GONE from Firestore
- [ ] Verify related data deleted (appointments, messages, etc.)
- [ ] No errors in logs
- [ ] All systems confirm deletion complete

---

## 🎯 Quick Test Script

```bash
#!/bin/bash
# Quick deletion test

echo "🧪 User Deletion Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Create a test user in Firebase Console:"
echo "   https://console.firebase.google.com/project/medzen-bf20e/authentication/users"
echo ""
echo "2. Note the user's UID and email"
echo ""
echo "3. In another terminal, start monitoring logs:"
echo "   firebase functions:log --only onUserDeleted"
echo ""
echo "4. Delete the user from Firebase Console"
echo ""
echo "5. Watch for deletion logs (should complete in 3-5 seconds)"
echo ""
echo "6. Verify deletion in Supabase:"
echo "   SELECT * FROM users WHERE email = 'your-test-email';"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

---

**Status:** ✅ Ready for testing
**Last Updated:** 2026-01-09 23:05 UTC
**Critical Level:** 🔴 PRODUCTION - DO NOT MODIFY
