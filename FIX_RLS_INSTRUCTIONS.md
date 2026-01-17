# Fix RLS Policies for Video Call Messaging

## Issue Summary

**Problem:** Users cannot send/receive messages during video calls due to Row Level Security (RLS) policies blocking operations.

**Root Cause:** Video calls don't create `chime_messaging_channels` records, but the old RLS policies required them.

**Solution:** Apply new RLS policies that check `video_call_sessions` instead.

---

## ✅ OPTION 1: Apply via Supabase Dashboard (RECOMMENDED)

This is the **easiest and most reliable** method when CLI has connection issues.

### Steps:

1. **Open Supabase Dashboard**
   - Go to: https://supabase.com/dashboard/project/noaeltglphdlkbflipit
   - Login if needed

2. **Open SQL Editor**
   - Click **SQL Editor** in the left sidebar
   - Or go to: https://supabase.com/dashboard/project/noaeltglphdlkbflipit/sql/new

3. **Paste the SQL Script**
   - Open the file: `apply_rls_fixes.sql`
   - Copy ALL contents (Cmd+A, Cmd+C)
   - Paste into the SQL Editor

4. **Run the Script**
   - Click **Run** button (or press Cmd+Enter)
   - Wait for execution (~2-3 seconds)

5. **Verify Success**
   - You should see output:
     ```
     ✅ SUCCESS: All 4 RLS policies created for chime_messages
        - video_call_messaging_insert
        - video_call_messaging_select
        - video_call_messaging_update
        - video_call_messaging_delete
     ```

6. **Done!** 🎉
   - The RLS policies are now active
   - Test messaging in a video call

---

## ⚡ OPTION 2: Apply via Supabase CLI

If you prefer using the CLI (when connection works):

```bash
# Navigate to project directory
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Method A: Push all pending migrations
npx supabase db push

# Method B: Apply the consolidated SQL file directly
npx supabase db execute --file apply_rls_fixes.sql
```

---

## 🔍 OPTION 3: Apply via psql (Direct Database Connection)

If you have the database password:

```bash
# Get the database connection string from Supabase Dashboard:
# Settings → Database → Connection string → Connection pooling

# Run the SQL file
psql "postgresql://postgres.noaeltglphdlkbflipit:[YOUR-PASSWORD]@aws-1-us-east-2.pooler.supabase.com:5432/postgres" \
  -f apply_rls_fixes.sql
```

---

## 🧪 Testing After Deployment

1. **Start a video call**
   - Use the app to create/join a video call session
   - Have both provider and patient join

2. **Send messages**
   - Provider sends: "Hello from provider"
   - Patient sends: "Hello from patient"

3. **Verify both users see both messages**
   - Check the chat interface shows all messages
   - No "permission denied" errors

4. **Check for errors**
   - Open browser DevTools (F12)
   - Check Console tab for RLS errors
   - Should see NO errors related to `chime_messages`

---

## 📋 What the Fix Does

### Old Behavior (BROKEN):
```
❌ Video call starts
❌ User tries to send message
❌ RLS checks: "Is there a chime_messaging_channels record?"
❌ Result: NO → Message blocked
❌ Error: "new row violates row-level security policy"
```

### New Behavior (FIXED):
```
✅ Video call starts
✅ User tries to send message
✅ RLS checks: "Is user authenticated?"
✅ RLS checks: "Does user_id match sender?"
✅ RLS checks: "Is user a participant in video_call_sessions?"
✅ Result: YES → Message allowed
✅ Success: Message sent and visible to both participants
```

---

## 🔐 RLS Policies Created

| Policy | Operation | Description |
|--------|-----------|-------------|
| `video_call_messaging_insert` | INSERT | Users can send messages if `user_id` or `sender_id` matches their auth ID |
| `video_call_messaging_select` | SELECT | Users can view messages if they're in the video call or are the sender |
| `video_call_messaging_update` | UPDATE | Users can edit their own messages only |
| `video_call_messaging_delete` | DELETE | Users can delete their own messages only |

---

## ⚠️ Troubleshooting

### "Error: relation 'chime_messages' does not exist"
**Solution:** The table hasn't been created yet. First run:
```sql
-- Check if table exists
SELECT EXISTS (
    SELECT FROM pg_tables
    WHERE schemaname = 'public'
    AND tablename = 'chime_messages'
);
```

If it doesn't exist, apply migration `20251120040000_create_chime_messages_table.sql` first.

### "Error: policy already exists"
**Solution:** The script handles this with `DROP POLICY IF EXISTS`. Just re-run the script.

### Messages still not working after applying
**Checklist:**
1. ✅ Policies applied successfully (check SQL Editor output)
2. ✅ User is authenticated (check `auth.uid()` is not null)
3. ✅ `video_call_sessions` record exists with correct `meeting_id`
4. ✅ `user_id` or `sender_id` in message matches sender's auth ID
5. ✅ Hard refresh the app (Cmd+Shift+R) to clear cache

---

## 📊 Verify Policies in Database

Run this query in SQL Editor to see all policies:

```sql
SELECT
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'chime_messages'
ORDER BY policyname;
```

Expected output: 4 policies starting with `video_call_messaging_*`

---

## 🎯 Next Steps After Fix

1. ✅ **Apply the RLS fix** (via Dashboard recommended)
2. ✅ **Test video call messaging** (send/receive messages)
3. ✅ **Monitor for errors** (check browser console)
4. ✅ **Fix emulator camera** (see ANDROID_EMULATOR_VIDEO_CALL_SETUP.md)

---

## 📞 Support

If you encounter issues:
1. Check Supabase logs: https://supabase.com/dashboard/project/noaeltglphdlkbflipit/logs/explorer
2. Check browser console for detailed error messages
3. Verify `video_call_sessions` table has active records
4. Test with a fresh video call session

---

## 📝 Files Created

- `apply_rls_fixes.sql` - Consolidated SQL script with all RLS fixes
- `FIX_RLS_INSTRUCTIONS.md` - This guide (step-by-step instructions)

Execute the SQL file via **Supabase Dashboard → SQL Editor** for immediate fix.
