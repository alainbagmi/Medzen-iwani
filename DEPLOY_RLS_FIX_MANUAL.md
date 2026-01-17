# Manual Deployment: Video Call Messaging RLS Fix

## Issue
The `npx supabase db push` command is experiencing connection pool issues. Use this manual deployment method instead.

## Option 1: Supabase Dashboard (Recommended)

1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/noaeltglphdlkbflipit/sql)
2. Click "SQL Editor" in the left sidebar
3. Click "New Query"
4. Copy and paste the entire content from:
   `supabase/migrations/20251214220000_fix_chime_messages_select_rls.sql`
5. Click "Run" (or press Cmd/Ctrl + Enter)
6. Verify success message appears

## Option 2: Direct SQL Execution

Run this command from your terminal:

```bash
# Read the migration file and execute it
PGPASSWORD="your-db-password" psql \
  -h aws-1-us-east-2.pooler.supabase.com \
  -U postgres.noaeltglphdlkbflipit \
  -d postgres \
  -f supabase/migrations/20251214220000_fix_chime_messages_select_rls.sql
```

## Verification

After deployment, run this test query in SQL Editor:

```sql
-- Check if migration was applied
SELECT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'chime_messages'
    AND policyname = 'video_call_messaging_select'
) AS migration_applied;
```

Expected result: `migration_applied: true`

## Test the Fix

1. Start a video call with two users (Provider + Patient)
2. Send message from Provider → should appear in Patient's chat
3. Send message from Patient → should appear in Provider's chat
4. Check browser console - should have NO RLS policy errors

---

**Date:** 2025-12-14
**Migration:** 20251214220000
**Status:** Ready for manual deployment
