# FlutterFlow Upload Widget Setup for Profile Pictures

**Date:** November 10, 2025
**Status:** Ready to configure in FlutterFlow UI

---

## Overview

This guide shows how to set up profile picture uploads using FlutterFlow's built-in upload widget instead of custom code. The RLS policies and bucket configuration are already in place and will work with this approach.

---

## FlutterFlow Configuration Steps

### 1. Add Upload Widget to Patient Settings Page

**In FlutterFlow UI:**

1. Open the **Patient Settings** page
2. Find the profile picture section
3. Add or configure the **Upload/UploadData** widget

**Widget Settings:**

| Setting | Value |
|---------|-------|
| **Upload Type** | Media (Image) |
| **Allow Multiple** | No (single file only) |
| **Max File Size** | 5 MB |
| **Allowed File Types** | JPG, JPEG, PNG, GIF, WebP |

### 2. Configure the Upload Action

**On File Selected → Add Action:**

**Action Type:** Upload Data
- **Upload To:** Supabase Storage
- **Bucket:** `profile_pictures`
- **Path:** `pics/profile_${currentUserUid}_${DateTime.now().millisecondsSinceEpoch}.jpg`
- **File:** Use the selected file from upload widget
- **Overwrite:** No

**Example Path Format:**
```
pics/profile_abc123def456_1699876543210.jpg
```

### 3. Delete Old Pictures (Optional but Recommended)

**Before Upload Action → Add Action:**

**Action Type:** Backend Call
- **Type:** Supabase Query
- **Table:** `storage.objects`
- **Query Type:** Delete
- **Filter:**
  - `bucket_id` equals `profile_pictures`
  - `owner` equals `currentUserUid`

This ensures only one picture per user (automatic cleanup).

### 4. Update User Profile with New URL

**After Upload Action → Add Action:**

**Action Type:** Backend Call
- **Type:** Supabase Update
- **Table:** `users` (or your profile table)
- **Filter:** `id` equals `currentUserUid`
- **Set Fields:**
  - `avatar_url` = `uploadedFileUrl` (from upload widget)

### 5. Display the Uploaded Image

**Widget:** CircleImage or NetworkImage
- **Image Path:** `${user.avatar_url}` or `uploadedFileUrl`
- **Fallback:** Default avatar icon

---

## Alternative: Simpler Approach (Direct Upload Only)

If you don't need automatic cleanup of old files:

1. **Upload Widget** → Select image
2. **On Selected** → Upload to Supabase Storage
   - Bucket: `profile_pictures`
   - Path: `pics/${currentUserUid}.jpg`
   - Overwrite: Yes (this automatically replaces old file)
3. **After Upload** → Update user profile with new URL

---

## Database Configuration (Already Complete ✅)

The following are already configured and working:

### Bucket Settings ✅
- **Name:** `profile_pictures`
- **Public:** Yes
- **Size Limit:** 5MB
- **File Types:** JPEG, JPG, PNG, GIF, WebP

### RLS Policies ✅
- **INSERT:** Authenticated users can upload (`auth.uid() IS NOT NULL`)
- **SELECT:** Public can view
- **UPDATE:** Owner only
- **DELETE:** Owner only

---

## Code-Free Implementation

For a completely code-free approach in FlutterFlow:

### Upload Button Action Chain:

```
1. Delete Old Files (Optional)
   └─ Action: Supabase Query
      └─ Table: storage.objects
      └─ Type: Delete
      └─ Filter: bucket_id='profile_pictures' AND owner=currentUserUid

2. Upload New File
   └─ Action: Upload Data
      └─ Storage: Supabase
      └─ Bucket: profile_pictures
      └─ Path: pics/${currentUserUid}_${timestamp}.jpg

3. Update User Profile
   └─ Action: Supabase Update
      └─ Table: users
      └─ Set: avatar_url = uploadedFileUrl

4. Show Success Snackbar
   └─ Action: Show Snackbar
      └─ Message: "Profile picture updated!"
```

---

## Testing Checklist

### In FlutterFlow Preview:

- [ ] Click upload button
- [ ] Select an image file (< 5MB, JPG/PNG/GIF/WebP)
- [ ] Confirm upload succeeds
- [ ] Verify old picture is deleted (if cleanup enabled)
- [ ] Check new picture displays correctly
- [ ] Verify public URL works (open in incognito)

### Test Invalid Uploads:

- [ ] Try uploading > 5MB file (should fail with error)
- [ ] Try uploading PDF or non-image (should fail)
- [ ] Try uploading while logged out (should fail)

---

## FlutterFlow Supabase Storage API

FlutterFlow automatically handles:
- ✅ Authentication (passes user JWT token)
- ✅ Path construction
- ✅ File upload to storage
- ✅ Public URL generation
- ✅ Error handling

The upload widget will return:
- `uploadedFileUrl` - Public URL of the uploaded file
- `uploadedFileName` - Name of the file
- `uploadedBytes` - File size in bytes

---

## Advanced: Using Edge Function (Optional)

If you want the automatic one-picture-per-user enforcement via edge function:

### Custom Action (Simple HTTP Call):

```dart
// In FlutterFlow Custom Action
import 'package:http/http.dart' as http;

Future<String?> uploadViaEdgeFunction(
  List<int> imageBytes,
  String fileName,
) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('https://noaeltglphdlkbflipit.supabase.co/functions/v1/upload-profile-picture'),
  );

  request.headers['Authorization'] = 'Bearer ${SupaFlow.client.auth.currentSession?.accessToken}';
  request.headers['apikey'] = 'YOUR_ANON_KEY';

  request.files.add(
    http.MultipartFile.fromBytes('file', imageBytes, filename: fileName),
  );

  final response = await http.Response.fromStream(await request.send());

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['data']['publicUrl'];
  }

  return null;
}
```

**But this is NOT recommended** - the direct upload approach is simpler and works great with the RLS policies already in place.

---

## Troubleshooting

### Upload Fails with "Policy Violation"
- **Check:** User is authenticated (`currentUserUid` is not null)
- **Fix:** Ensure user is logged in before upload

### Upload Succeeds but File Not Found
- **Check:** Bucket is public (`storage.buckets.public = true`)
- **Fix:** Already configured, run `verify_profile_picture_rls.sql` to confirm

### Old Files Not Deleted
- **Check:** Delete action runs BEFORE upload action
- **Fix:** Reorder actions in FlutterFlow action chain

### File Too Large Error
- **Check:** File size < 5MB
- **Fix:** Add file size validation before upload

---

## Summary

✅ **Recommended Approach:** FlutterFlow built-in upload widget with direct Supabase Storage upload

**Why?**
- No custom code needed
- Automatic authentication
- Built-in error handling
- Easier to maintain
- Works with existing RLS policies

**Benefits:**
- Simpler implementation
- Less code to maintain
- FlutterFlow handles all the complexity
- Visual configuration (no code changes needed)

---

## Files Removed

- ❌ `lib/custom_code/actions/upload_profile_picture.dart` (deleted)
- ✅ Updated `lib/custom_code/actions/index.dart` (export removed)

**Edge function still exists** at `supabase/functions/upload-profile-picture/index.ts` but is not needed for this approach. You can delete it if you want, or keep it as a backup option.

---

## Related Documentation

- **RLS Policies:** `RLS_FIX_SUMMARY.md`
- **Bucket Config:** `FINAL_STATUS_REPORT.md`
- **SQL Verification:** `verify_profile_picture_rls.sql`

---

**Last Updated:** November 10, 2025
**Status:** ✅ Ready to configure in FlutterFlow UI
