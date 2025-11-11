# Profile Picture Auto-Delete Fix - Instructions

**Date:** November 11, 2025
**Issue:** Old profile pictures are accumulating instead of being auto-deleted
**Root Cause:** Trigger checks `NEW.owner IS NOT NULL` but owner is NULL for anon key uploads

---

## Quick Fix Overview

The auto-delete trigger needs to be updated to use **path-based user identification** instead of the `owner` field, since uploads with the anon key don't set an owner.

**What You'll Do:**
1. Apply trigger fix via Supabase Dashboard SQL Editor
2. Clean up existing duplicate pictures
3. Test that new uploads automatically delete old pictures

**Time Required:** 5-10 minutes

---

## Step 1: Apply Trigger Fix

### Via Supabase Dashboard (Recommended)

1. **Open Supabase Dashboard:**
   - Go to: https://supabase.com/dashboard/project/noaeltglphdlkbflipit
   - Login if needed

2. **Open SQL Editor:**
   - Left sidebar → **SQL Editor**
   - Click **New Query**

3. **Run the Fix Script:**
   - Open `fix_auto_delete_trigger.sql` (in project root)
   - Copy the entire contents
   - Paste into SQL Editor
   - Click **Run** (or press Ctrl+Enter / Cmd+Enter)

4. **Verify Success:**
   - You should see: `ENABLED ✅` in the verification query results
   - If you see `DISABLED ❌`, the trigger did not enable correctly

**Expected Output:**
```
trigger_name                            | enabled | status
----------------------------------------|---------|---------------
enforce_one_profile_picture_per_user    | O       | ENABLED ✅
```

---

## Step 2: Clean Up Existing Duplicates

### Preview Duplicates First (Safe)

1. **Open SQL Editor** (if not already open)

2. **Run Preview Query:**
   - Open `cleanup_duplicate_pictures.sql`
   - Copy the **first query** (Preview section - lines 6-25)
   - Paste and run in SQL Editor

3. **Review Results:**
   - Shows which users have duplicates
   - Shows how many files will be kept vs deleted
   - Example output:
     ```
     user_folder | total_files | files_to_keep | files_to_delete
     ------------|-------------|---------------|----------------
     abc123      | 5           | 1             | 4
     xyz789      | 3           | 1             | 2
     ```

### Delete Duplicates (Destructive)

⚠️ **IMPORTANT:** This will permanently delete old profile pictures!

1. **Uncomment Deletion Query:**
   - In `cleanup_duplicate_pictures.sql`, find the commented section (lines 28-54)
   - Remove the `--` at the start of each line
   - OR copy this ready-to-run version:

```sql
WITH user_files AS (
    SELECT
        id,
        name,
        created_at,
        (storage.foldername(name))[2] as user_folder,
        ROW_NUMBER() OVER (
            PARTITION BY (storage.foldername(name))[2]
            ORDER BY created_at DESC
        ) as row_num
    FROM storage.objects
    WHERE bucket_id = 'profile_pictures'
      AND (storage.foldername(name))[1] = 'pics'
      AND array_length(storage.foldername(name), 1) >= 2
),
deleted AS (
    DELETE FROM storage.objects
    WHERE id IN (
        SELECT id
        FROM user_files
        WHERE row_num > 1
    )
    RETURNING id, name
)
SELECT
    COUNT(*) as deleted_count,
    array_agg(name) as deleted_files
FROM deleted;
```

2. **Run Deletion:**
   - Paste and execute in SQL Editor
   - Note the number of files deleted

3. **Verify Cleanup:**
   - Run the **third query** in `cleanup_duplicate_pictures.sql` (verification section)
   - Each user should now show `picture_count = 1`

**Expected Output:**
```
user_folder | picture_count | files
------------|---------------|----------------------------------
abc123      | 1             | {pics/abc123/avatar_123.jpg}
xyz789      | 1             | {pics/xyz789/profile_456.jpg}
```

---

## Step 3: Test Auto-Delete Works

### Test Procedure

1. **Login to App:**
   ```bash
   flutter run -d chrome
   ```

2. **Navigate to Patient Settings:**
   - Login as a patient user
   - Go to Settings page
   - Find profile picture upload section

3. **Upload First Picture:**
   - Select and upload an image
   - Note the filename (check storage bucket)
   - **Expected:** Upload succeeds, picture displays

4. **Upload Second Picture:**
   - Select a DIFFERENT image
   - Upload it
   - **Expected:** Upload succeeds, new picture displays

5. **Verify Old Picture Deleted:**
   - Go to Supabase Dashboard → Storage → profile_pictures bucket
   - Navigate to `pics/{your_user_id}/`
   - **Expected:** Only the NEWEST picture exists (first one auto-deleted)

### Verification SQL (Optional)

Check storage directly:

```sql
SELECT
    (storage.foldername(name))[2] as user_folder,
    name,
    created_at,
    updated_at
FROM storage.objects
WHERE bucket_id = 'profile_pictures'
  AND (storage.foldername(name))[1] = 'pics'
ORDER BY user_folder, created_at DESC;
```

**Expected:** Each user_folder should have exactly 1 file.

---

## Troubleshooting

### Issue: Trigger Shows `DISABLED ❌`

**Fix:**
```sql
-- Enable the trigger manually
ALTER TABLE storage.objects ENABLE TRIGGER enforce_one_profile_picture_per_user;

-- Verify
SELECT tgname, tgenabled FROM pg_trigger WHERE tgname = 'enforce_one_profile_picture_per_user';
```

### Issue: Old Pictures Still Not Deleting After Upload

**Check:**

1. **Verify trigger function updated:**
   ```sql
   SELECT prosrc FROM pg_proc WHERE proname = 'delete_old_profile_pictures';
   ```
   - Should include `storage.foldername(NEW.name)` logic (NOT `NEW.owner`)

2. **Check trigger is firing:**
   - Upload a picture
   - Check Supabase logs for NOTICE messages
   - Look for: "Auto-deleted X old profile picture(s) for user folder: Y"

3. **Check file path structure:**
   - Ensure uploads go to `pics/{user_id}/filename.jpg`
   - If path is different, trigger won't match

### Issue: Permission Denied When Running SQL

**Solution:** Make sure you're running the SQL in the Supabase Dashboard SQL Editor, NOT via the API. The dashboard has elevated permissions that bypass RLS restrictions.

---

## Summary

### What Changed

**Before (Broken):**
```sql
IF NEW.bucket_id = 'profile_pictures' AND NEW.owner IS NOT NULL THEN
  -- NEW.owner is always NULL for anon uploads → trigger never fires
```

**After (Fixed):**
```sql
IF NEW.bucket_id = 'profile_pictures' THEN
  v_path_parts := storage.foldername(NEW.name);  -- ['pics', 'user_id', 'file.jpg']
  v_user_folder := v_path_parts[2];              -- Extract user_id from path
  DELETE ... WHERE name LIKE 'pics/' || v_user_folder || '/%';
  -- Trigger fires and deletes based on path, not owner
```

### Files Created

| File | Purpose | Status |
|------|---------|--------|
| `fix_auto_delete_trigger.sql` | Update trigger function with path-based logic | ✅ Ready to apply |
| `cleanup_duplicate_pictures.sql` | Remove existing duplicates | ✅ Ready to run |
| `supabase/functions/cleanup-old-profile-pictures/index.ts` | Edge Function alternative (backup) | ⏳ Not deployed |
| `supabase/migrations/20251111000001_fix_profile_picture_auto_delete.sql` | Migration file (reference) | ⚠️ Cannot apply via API |

### Related Docs

- `PROFILE_UPLOAD_FIX_COMPLETE.md` - RLS policy fix (already applied)
- `RLS_POLICY_FIX_ALTERNATIVE.md` - Alternative RLS fix approaches
- `supabase/migrations/20251110201000_one_profile_picture_per_user.sql` - Original broken trigger

---

## Next Steps

1. ✅ **Now:** Apply `fix_auto_delete_trigger.sql` in Supabase Dashboard
2. ✅ **Now:** Run cleanup query to remove existing duplicates
3. ✅ **Now:** Test upload flow - verify old pictures auto-delete
4. ⏳ **Optional:** Deploy Edge Function as backup cleanup mechanism
5. ⏳ **Later:** Monitor storage usage to ensure no more duplicates accumulate

**The fix is ready - just run the SQL in the Supabase Dashboard!** 🎉
