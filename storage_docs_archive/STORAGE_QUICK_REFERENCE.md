# Storage Upload - Quick Reference Card

## ✅ You Can Now Use Default FlutterFlow Upload!

Migration applied: `20251106120000_fix_storage_for_flutterflow_default_upload.sql`

---

## FlutterFlow Action Chain (Copy & Paste)

### For User Avatar Upload:

```
1. Upload Media
   └─ Allow Photo: Yes
   └─ Media Source: Gallery
   └─ Output: Uploaded Local File

2. Upload to Supabase Storage (Default Action)
   └─ File: Uploaded Local File
   └─ Bucket: "user-avatars"
   └─ Output Variable: uploadedFilePath (String)

3. (Optional) Custom Action: trackStorageUpload
   └─ storagePath: uploadedFilePath
   └─ bucketName: "user-avatars"
   └─ fileType: "avatar"

4. Update Page State
   └─ avatarUrl = "https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/user-avatars/" + uploadedFilePath

5. Backend Call → Supabase → Update
   └─ Table: medical_provider_profiles (or users, facility_admin_profiles, system_admin_profiles)
   └─ SET: avatar_url = avatarUrl
   └─ WHERE: user_id = Authenticated User ID

6. Show Snack Bar: "Profile picture updated!"
```

---

## Storage Buckets

| Bucket | Limit | Usage |
|--------|-------|-------|
| `user-avatars` | 5MB | All user profile pictures |
| `facility-images` | 10MB | Care center photos (max 3) |
| `documents` | 50MB | Medical records |

---

## Building Public URL

**Formula:**
```
"https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/" + bucketName + "/" + filePath
```

**Example:**
- File path from upload: `1762405123456000_profile.jpg`
- Bucket: `user-avatars`
- Full URL: `https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/user-avatars/1762405123456000_profile.jpg`

---

## Custom Function (Recommended)

Create in `lib/flutter_flow/custom_functions.dart`:

```dart
String buildStorageUrl(String bucketName, String filePath) {
  const baseUrl = 'https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public';
  return '$baseUrl/$bucketName/$filePath';
}
```

Then use in FlutterFlow:
- **Custom Code** → **Custom Function** → `buildStorageUrl(bucketName, filePath)`

---

## Facility Images (3-Image Limit)

For facility image uploads, same as above but:
- Bucket: `"facility-images"`
- **IMPORTANT**: Include facility ID in ownership tracking:
  ```
  trackStorageUpload(
    storagePath: uploadedFilePath,
    bucketName: "facility-images",
    fileType: "facility_image",
    facilityId: yourFacilityId
  )
  ```

---

## Documents

For document uploads:
- Bucket: `"documents"`
- fileType: `"document"`

---

## Quick Test

1. Upload a file in your app
2. Check Supabase Dashboard → Storage → `user-avatars`
3. File should appear (path: `filename.jpg` - flat path is OK!)
4. Check your profile table → `avatar_url` should have full URL
5. Image should display in your app

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Image doesn't display | Check full URL is saved to database (not just filename) |
| 403 error | User not authenticated or migration not applied |
| File not found | Verify URL format and bucket name |

---

## Verification Script

```bash
./test_storage_upload.sh
```

Should show:
- ✅ 3 storage buckets configured
- ✅ Helper functions working
- ✅ RLS policies active
- ✅ File size limits correct

---

## Need More Details?

- **Complete Guide**: `DEFAULT_FLUTTERFLOW_UPLOAD_GUIDE.md`
- **Implementation Checklist**: `STORAGE_IMPLEMENTATION_CHECKLIST.md`

---

**Last Updated**: Migration `20251106120000` applied successfully
**Status**: ✅ Ready to use default FlutterFlow upload
