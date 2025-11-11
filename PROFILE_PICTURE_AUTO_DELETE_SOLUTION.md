# Profile Picture Auto-Delete - Complete Solution

**Date:** November 11, 2025
**Issue:** Multiple profile pictures accumulating per user in storage
**Solution:** Edge Function + Flutter integration (automatic cleanup after upload)

---

## 🎯 Solution Overview

Since the database trigger approach requires manual Dashboard access (API permission restrictions), I've deployed an **Edge Function** that automatically cleans up old profile pictures.

**How it works:**
1. User uploads new profile picture → Supabase Storage
2. Flutter app calls Edge Function after successful upload
3. Edge Function finds all pictures in that user's folder
4. Edge Function keeps only the newest picture, deletes the rest
5. User's avatar_url is updated in database

---

## ✅ Already Deployed

**Edge Function:** `cleanup-old-profile-pictures`
**URL:** `https://noaeltglphdlkbflipit.supabase.co/functions/v1/cleanup-old-profile-pictures`
**Status:** LIVE ✅

**What it does:**
- Accepts optional `user_folder` parameter (user ID)
- Lists all files in `pics/{user_folder}/`
- Sorts by created_at (newest first)
- Keeps the newest picture
- Deletes all older pictures
- Returns count of deleted files

---

## 🔧 Flutter Integration Options

### Option 1: Call After Upload (Recommended)

Modify your existing upload action to call the cleanup function after successful upload:

```dart
// In your upload Custom Action or page logic:

// 1. Upload the file (existing code)
final uploadedFiles = await uploadSupabaseStorageFiles(
  bucketName: 'profile_pictures',
  selectedFiles: selectedFiles,
  selectedUploadType: SelectedMediaType.image,
  selectedMedia: selectedMedia,
);

if (uploadedFiles.isNotEmpty) {
  final newAvatarUrl = uploadedFiles.first.storagePath;

  // 2. Update database with new avatar_url (existing code)
  await SupaFlow.client.from('users').update({
    'avatar_url': newAvatarUrl,
  }).eq('firebase_uid', currentUserUid);

  // 3. NEW: Call cleanup function to delete old pictures
  final userFolder = currentUserUid; // or extract from path
  await SupaFlow.client.functions.invoke(
    'cleanup-old-profile-pictures',
    body: {'user_folder': userFolder},
  );

  print('✅ Old profile pictures cleaned up');
}
```

### Option 2: Create Dedicated Custom Action

Create `lib/custom_code/actions/upload_and_cleanup_profile_picture.dart`:

```dart
import 'package:medzen_iwani/backend/supabase/supabase.dart';
import 'package:medzen_iwani/auth/firebase_auth/auth_util.dart';
import 'package:medzen_iwani/flutter_flow/upload_data.dart';

Future<String?> uploadAndCleanupProfilePicture(
  FFUploadedFile uploadedFile,
) async {
  try {
    // 1. Upload to Supabase Storage
    final uploadedFiles = await uploadSupabaseStorageFiles(
      bucketName: 'profile_pictures',
      selectedFiles: [uploadedFile],
    );

    if (uploadedFiles.isEmpty) {
      print('❌ Upload failed');
      return null;
    }

    final newAvatarUrl = uploadedFiles.first.storagePath;
    final userId = currentUserUid;

    // 2. Update user's avatar_url in database
    await SupaFlow.client.from('users').update({
      'avatar_url': newAvatarUrl,
    }).eq('firebase_uid', userId);

    // 3. Call cleanup function to delete old pictures
    final response = await SupaFlow.client.functions.invoke(
      'cleanup-old-profile-pictures',
      body: {'user_folder': userId},
    );

    if (response.data != null) {
      final deleted = response.data['deleted'] ?? 0;
      print('✅ Cleaned up $deleted old picture(s)');
    }

    return newAvatarUrl;
  } catch (e) {
    print('❌ Error uploading profile picture: $e');
    return null;
  }
}
```

---

## 🧹 Manual Cleanup of Existing Duplicates

To clean up pictures that already exist (before this fix was deployed):

### Option A: Call Edge Function Manually (No Parameters)

```bash
curl -X POST \
  "https://noaeltglphdlkbflipit.supabase.co/functions/v1/cleanup-old-profile-pictures" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{}'
```

This will clean up ALL users' duplicate pictures at once.

### Option B: Run SQL Query (Supabase Dashboard)

Use the query from `cleanup_duplicate_pictures.sql`:

```sql
-- Preview duplicates first
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
)
SELECT
    user_folder,
    COUNT(*) as total_files,
    COUNT(*) FILTER (WHERE row_num = 1) as files_to_keep,
    COUNT(*) FILTER (WHERE row_num > 1) as files_to_delete
FROM user_files
GROUP BY user_folder
HAVING COUNT(*) > 1
ORDER BY total_files DESC;
```

Then delete duplicates:

```sql
WITH user_files AS (
    SELECT
        id,
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
        SELECT id FROM user_files WHERE row_num > 1
    )
    RETURNING id, name
)
SELECT COUNT(*) as deleted_count FROM deleted;
```

---

## 🧪 Testing

### Test Auto-Cleanup Works

1. **Upload First Picture:**
   ```bash
   flutter run -d chrome
   # Login as patient → Settings → Upload profile picture
   ```

2. **Verify Upload:**
   - Go to Supabase Storage: https://supabase.com/dashboard/project/noaeltglphdlkbflipit/storage/files/buckets/profile_pictures/pics
   - Navigate to your user folder
   - Should see 1 picture

3. **Upload Second Picture (Different Image):**
   - Select and upload a different image
   - Upload should succeed

4. **Verify Auto-Cleanup:**
   - Refresh storage bucket view
   - Should see only the NEWEST picture
   - Old picture should be gone

### Check Edge Function Logs

```bash
npx supabase functions logs cleanup-old-profile-pictures --tail
```

Or in Dashboard:
- Functions → cleanup-old-profile-pictures → Logs
- Look for: "Cleanup completed" messages with deleted count

---

## 📊 Verify Current Storage Status

Check how many duplicates exist right now:

```sql
SELECT
    (storage.foldername(name))[2] as user_folder,
    COUNT(*) as picture_count
FROM storage.objects
WHERE bucket_id = 'profile_pictures'
  AND (storage.foldername(name))[1] = 'pics'
GROUP BY (storage.foldername(name))[2]
HAVING COUNT(*) > 1
ORDER BY picture_count DESC;
```

**Expected after fix:** All users should have `picture_count = 1`

---

## 🔄 Two-Step Implementation

### Step 1: Integrate Flutter Code (Choose Option 1 or 2)

**Option 1 (Quick):** Add cleanup call to existing upload code
**Option 2 (Clean):** Create new Custom Action for upload + cleanup

### Step 2: Clean Up Existing Duplicates

Run either:
- Edge Function via curl (cleans all users at once)
- SQL query in Dashboard (more control, see preview first)

---

## 🎯 Summary

| Component | Status | Action |
|-----------|--------|--------|
| Edge Function | ✅ DEPLOYED | Already live |
| Flutter Integration | ⏳ PENDING | Add cleanup call after upload |
| Existing Duplicates | ⏳ PENDING | Run manual cleanup (curl or SQL) |
| Future Uploads | ✅ READY | Will auto-cleanup once Flutter integrated |

---

## 🚨 Important Notes

1. **Edge Function is LIVE** - You can call it right now to clean up existing duplicates
2. **Flutter integration needed** - Add the cleanup call to your upload code
3. **No Dashboard access required** - Everything works via API
4. **Service role not needed** - Edge Function uses service role internally

---

## 💡 Alternative: Database Trigger (Optional)

If you prefer the database trigger approach (automatic, no Flutter code changes):

1. Open Supabase Dashboard → SQL Editor
2. Copy contents of `fix_auto_delete_trigger.sql`
3. Run the SQL
4. Trigger will fire automatically on every upload (no Flutter changes needed)

**Trade-off:**
- ✅ Fully automatic (no app code changes)
- ⚠️ Requires manual Dashboard access (can't be deployed via API)

---

## 📝 Next Steps

1. **Clean up existing duplicates NOW:**
   ```bash
   curl -X POST \
     "https://noaeltglphdlkbflipit.supabase.co/functions/v1/cleanup-old-profile-pictures" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk0NDc2MzksImV4cCI6MjA3NTAyMzYzOX0.t8doxWhvLDsu27jad_T1IvACBl5HpfFmo8IillYBppk" \
     -H "Content-Type: application/json" \
     -d '{}'
   ```

2. **Integrate Flutter code** (Option 1 recommended for speed)

3. **Test upload flow** to verify auto-cleanup works

**The Edge Function is ready to use RIGHT NOW!** 🎉
