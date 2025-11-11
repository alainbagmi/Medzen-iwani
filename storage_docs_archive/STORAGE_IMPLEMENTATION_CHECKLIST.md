# Storage Upload Implementation Checklist

## ✅ Backend Setup (COMPLETE)

- [x] Database migration applied (`20251106000002_apply_storage_policies_final.sql`)
- [x] 3 storage buckets created:
  - `user-avatars` (5MB limit, private)
  - `facility-images` (10MB limit, public)
  - `documents` (50MB limit, private)
- [x] RLS policies configured for user-directory isolation
- [x] Helper functions created:
  - `get_user_avatar_storage_path()`
  - `get_facility_image_storage_path()`
  - `get_document_storage_path()`
  - `count_facility_images()`
- [x] Custom actions created and exported:
  - `uploadToSupabaseStorage()` - For user avatars & documents
  - `uploadFacilityImage()` - For care center images
- [x] Test suite passing (`./test_storage_upload.sh`)

## 🔧 FlutterFlow Setup (YOUR NEXT STEPS)

### For User Avatar Upload (Patients, Providers, Admins)

**Find your upload button/widget and configure:**

1. **Action 1: Upload Media**
   - Allow Photo: ✅ Yes
   - Media Source: Photo Gallery
   - Store in page state: `uploadedFile` (FFUploadedFile)

2. **Action 2: Custom Action → uploadToSupabaseStorage**
   - `context`: Auto-filled
   - `uploadedFile`: Page State → `uploadedFile`
   - `bucketName`: Custom Value → `"user-avatars"`
   - `customPath`: Leave blank (auto-uses current user UID)
   - **Store Output**: Page State → `avatarUrl` (String)

3. **Action 3: Conditional (if avatarUrl is not null)**
   - **Backend Call**: Update Supabase
   - **Table**: Choose based on role:
     - `medical_provider_profiles` (for providers)
     - `facility_admin_profiles` (for facility admins)
     - `system_admin_profiles` (for system admins)
     - `users` (for patients)
   - **Set Field**: `avatar_url = avatarUrl`
   - **Filter**: `user_id = Authenticated User ID`

4. **Action 4: Show Snack Bar** (success message)

### For Facility Image Upload (Care Centers)

**Find your upload button on facility page:**

1. **Action 1: Upload Media** (same as above)

2. **Action 2: Custom Action → uploadFacilityImage**
   - `context`: Auto-filled
   - `uploadedFile`: Page State → `uploadedFile`
   - `facilityId`: Page Parameter or App State
   - **Store Output**: Page State → `facilityImageUrl` (String)

3. **Action 3: Conditional (if facilityImageUrl is not null)**
   - **Backend Call**: Update Supabase
   - **Table**: `facilities`
   - **Set Field**: `image_url = facilityImageUrl`
   - **Filter**: `id = facilityId`

4. **Action 4: Show Snack Bar** (shows "x/3 images")

## ⚠️ CRITICAL: What NOT to Do

**❌ DO NOT USE:**
- FlutterFlow's default "Upload to Supabase Storage" action
- Any action that creates flat paths like `user-avatars/filename.jpg`

**✅ ALWAYS USE:**
- Custom Actions: `uploadToSupabaseStorage` or `uploadFacilityImage`
- These create proper user directories: `user-avatars/{user_id}/filename.jpg`

## 🧪 Quick Test

**After implementing in FlutterFlow:**

1. **Run the app** and sign in
2. **Upload a profile picture**
3. **Check Supabase Dashboard**:
   - Go to Storage → `user-avatars` bucket
   - You should see a folder named with your Firebase UID
   - Inside that folder, your uploaded image

**Expected Path:**
```
user-avatars/{your-firebase-uid}/1762405123456000_profile.jpg
```

**If you see a flat path like:**
```
user-avatars/1762405123456000_profile.jpg  ❌ WRONG
```
→ You're using the default upload action instead of custom action

## 📊 Verify Database Update

After upload, check your profile table in Supabase:

1. Open **Table Editor** → Your profile table
2. Find your user record
3. `avatar_url` should contain full public URL:
```
https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/user-avatars/{your-uid}/filename.jpg
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Image not in storage | Check you're using custom action (not default) |
| 400 Bad Request | RLS blocking flat path - use custom action |
| 403 Unauthorized | User not authenticated - check login |
| Facility limit error | Facility has 3 images - delete one first |
| File too large | Check limits: 5MB (avatar), 10MB (facility) |

## 📚 Detailed Documentation

- **Step-by-step guide**: `FLUTTERFLOW_UPLOAD_SETUP.md`
- **Technical details**: `SUPABASE_STORAGE_UPLOAD_GUIDE.md`
- **Implementation summary**: `STORAGE_FIX_COMPLETE.md`

## ✅ Success Criteria

You'll know it's working when:
1. ✅ Upload completes without errors
2. ✅ Image appears in Supabase Storage inside user directory
3. ✅ Database `avatar_url` field updated with public URL
4. ✅ Image displays correctly in your app UI

---

**Current Status**: ✅ All backend setup complete. Ready for FlutterFlow implementation.

**Next Step**: Configure upload actions in FlutterFlow UI using the steps above.
