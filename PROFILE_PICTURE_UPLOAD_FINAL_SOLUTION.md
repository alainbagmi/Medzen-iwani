# Profile Picture Upload - Final Solution

**Date:** November 11, 2025
**Issue:** Multiple profile pictures accumulating per user
**Root Cause:** Files uploaded to flat `pics/` directory without user identification
**Solution:** Custom Action + Edge Function for proper structure and auto-cleanup

---

## 🎯 Complete Solution

### What Was Wrong

**Current structure:** Files stored as `pics/1762820147767000.png` (just timestamp)
**Problem:** No way to identify which user owns which picture

**Correct structure:** Files should be stored as `pics/{user_id}/timestamp.ext`
**Benefit:** Can identify and clean up old pictures per user

---

## ✅ Already Done For You

1. **✅ Edge Function Deployed:** `cleanup-old-profile-pictures` is LIVE
2. **✅ Custom Action Created:** `uploadProfilePictureWithCleanup()` in `lib/custom_code/actions/`
3. **✅ Exported:** Already added to `lib/custom_code/actions/index.dart`

---

## 🔧 How to Integrate (FlutterFlow)

### Step 1: Use the New Custom Action

In FlutterFlow, update your Patient Settings page:

1. **Open Patient Settings Page** (patients_settings_page)

2. **Find the Upload Action** (currently using `uploadSupabaseStorageFiles`)

3. **Replace with New Custom Action:**
   - Action: **Custom Action**
   - Action name: `uploadProfilePictureWithCleanup`
   - Parameters:
     - `uploadedFile`: Pass the selected file (`uploadedLocalFile_uploadData6b2`)

4. **Update Avatar Display:**
   - The action returns the public URL
   - Use this URL to update the avatar display widget

### Example Action Chain

```
On Upload Button Tap:
  1. Upload Media (get uploadedFile)
  2. Call Custom Action: uploadProfilePictureWithCleanup
     - Input: uploadedFile
     - Output: Save to variable "newAvatarUrl"
  3. Show Success Message
  4. Update Avatar Widget with newAvatarUrl
```

---

## 📱 What the Custom Action Does

```dart
Future<String?> uploadProfilePictureWithCleanup(
  FFUploadedFile uploadedFile,
) async
```

**Automatic steps:**
1. ✅ Gets current user ID from Firebase Auth
2. ✅ Creates unique filename: `{timestamp}.{extension}`
3. ✅ Uploads to: `pics/{userId}/{timestamp}.ext`
4. ✅ Updates `users.avatar_url` in database
5. ✅ Calls Edge Function to delete old pictures
6. ✅ Returns public URL for display

**Benefits:**
- Single action replaces multiple steps
- Proper path structure for user identification
- Automatic cleanup of old pictures
- Error handling built-in

---

## 🧹 Clean Up Existing Duplicates NOW

Before users start uploading with the new structure, clean up the existing flat-structure files:

### Option A: SQL Query (Recommended)

Run this in Supabase Dashboard → SQL Editor:

```sql
-- Delete ALL current profile pictures (they're in wrong structure)
DELETE FROM storage.objects
WHERE bucket_id = 'profile_pictures'
  AND name LIKE 'pics/%'
  AND name NOT LIKE 'pics/.emptyFolderPlaceholder';

-- Verify cleanup
SELECT COUNT(*) as remaining_files
FROM storage.objects
WHERE bucket_id = 'profile_pictures';
```

**Why delete all?**
- Current files are in flat `pics/filename.ext` structure
- No way to identify which user owns which file
- Users will re-upload with correct structure

### Option B: Keep Most Recent Per User (Complex)

If you want to preserve the most recent upload for each user, you'll need to cross-reference with `users.avatar_url`:

```sql
-- Find orphaned files (not referenced in users.avatar_url)
WITH current_avatars AS (
  SELECT avatar_url
  FROM users
  WHERE avatar_url LIKE '%profile_pictures%'
)
DELETE FROM storage.objects
WHERE bucket_id = 'profile_pictures'
  AND id NOT IN (
    SELECT id
    FROM storage.objects o
    INNER JOIN current_avatars ca
      ON ca.avatar_url LIKE '%' || o.name || '%'
  )
  AND name != 'pics/.emptyFolderPlaceholder';
```

---

## 🧪 Testing

### Test 1: Upload First Picture

1. **Login as patient**
2. **Navigate to Settings** → Profile Picture section
3. **Upload an image** (JPG, PNG, GIF, or WebP, max 5MB)
4. **Expected:**
   - Upload succeeds
   - Avatar displays immediately
   - In Supabase Storage: See `pics/{your_user_id}/timestamp.ext`

### Test 2: Upload Second Picture (Auto-Delete Test)

1. **Upload a DIFFERENT image** (same steps as Test 1)
2. **Expected:**
   - New upload succeeds
   - Avatar updates to new image
   - In Supabase Storage: Only the NEWEST picture exists
   - Old picture automatically deleted

### Verification Query

Check storage structure:

```sql
SELECT
    name,
    created_at,
    (storage.foldername(name))[2] as user_folder
FROM storage.objects
WHERE bucket_id = 'profile_pictures'
  AND name != 'pics/.emptyFolderPlaceholder'
ORDER BY created_at DESC
LIMIT 10;
```

**Expected:** Each user has exactly 1 file in their own subfolder (`pics/{user_id}/...`)

---

## 📊 Check Edge Function Logs

Monitor the cleanup function activity:

```bash
npx supabase functions logs cleanup-old-profile-pictures --tail
```

Or in Dashboard:
- Functions → cleanup-old-profile-pictures → Logs
- Look for: `{deleted: X, users_processed: Y}`

---

## 🔧 Troubleshooting

### Issue: Upload fails with "User not logged in"

**Fix:** Ensure Firebase Auth is initialized and user is logged in before upload

### Issue: Old pictures not being deleted

**Check:**
1. Edge Function is deployed: `npx supabase functions list`
2. Custom Action is calling the function (check logs)
3. File path structure is correct (`pics/{user_id}/...`)

**Debug:**
```sql
-- Check current storage structure
SELECT name FROM storage.objects WHERE bucket_id = 'profile_pictures';
```

### Issue: Can't find Custom Action in FlutterFlow

**Fix:**
1. Sync your code with FlutterFlow (re-export or pull latest)
2. Check `lib/custom_code/actions/index.dart` contains the export
3. Refresh FlutterFlow editor

---

## 📝 Migration Checklist

### Immediate (Before Users Upload More)

- [ ] Clean up existing duplicates (SQL query)
- [ ] Integrate Custom Action in FlutterFlow
- [ ] Test upload flow (Tests 1 & 2)
- [ ] Verify auto-delete works

### Within 24 Hours

- [ ] Monitor Edge Function logs for errors
- [ ] Check storage bucket for proper structure
- [ ] Verify no new duplicates accumulating
- [ ] Update any other pages that upload profile pictures

### Optional Improvements

- [ ] Add loading indicator during upload
- [ ] Add success/error toast messages
- [ ] Add image preview before upload
- [ ] Add file size validation in UI (currently 5MB limit)

---

## 🎯 Summary

| Component | Status | Location |
|-----------|--------|----------|
| **Edge Function** | ✅ DEPLOYED | `cleanup-old-profile-pictures` |
| **Custom Action** | ✅ CREATED | `lib/custom_code/actions/upload_profile_picture_with_cleanup.dart` |
| **Export** | ✅ DONE | `lib/custom_code/actions/index.dart` |
| **RLS Policy** | ✅ APPLIED | Permissive upload policy |
| **FlutterFlow Integration** | ⏳ PENDING | Update Patient Settings page |
| **Cleanup Old Files** | ⏳ PENDING | Run SQL query |
| **Testing** | ⏳ PENDING | Tests 1 & 2 |

---

## 🚀 Next Steps

1. **NOW:** Run cleanup SQL to remove old duplicates
2. **NOW:** Integrate Custom Action in FlutterFlow Patient Settings page
3. **NOW:** Test upload flow (2 uploads to verify auto-delete)
4. **LATER:** Monitor logs and storage for first 24 hours

**The solution is COMPLETE and ready to integrate!** 🎉

---

## 📄 Related Files

- `lib/custom_code/actions/upload_profile_picture_with_cleanup.dart` - Main upload action
- `supabase/functions/cleanup-old-profile-pictures/index.ts` - Edge Function (deployed)
- `PROFILE_UPLOAD_FIX_COMPLETE.md` - RLS policy fix documentation
- `AUTO_DELETE_FIX_INSTRUCTIONS.md` - Original trigger-based approach (not used)

---

## ⚠️ Important Notes

1. **Path Structure:** Files MUST be uploaded to `pics/{user_id}/filename` for cleanup to work
2. **Edge Function:** Requires correct path structure to identify user folders
3. **Old Files:** Current flat-structure files (`pics/timestamp.ext`) won't be auto-cleaned
4. **One-Time Cleanup:** Run the SQL cleanup query ONCE before going live with new structure
5. **Testing:** Always test in non-production environment first

**All components are ready - just integrate and test!** ✅
