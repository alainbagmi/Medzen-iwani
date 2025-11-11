# FlutterFlow Storage Upload Setup Guide

## ⚠️ IMPORTANT: Do NOT Use Default "Upload to Supabase Storage"

The default FlutterFlow "Upload to Supabase Storage" action creates **flat paths** which our RLS policies block.

You MUST use our **custom actions** instead.

---

## Step-by-Step Setup in FlutterFlow

### Upload User Avatar (Profile Picture)

#### Step 1: Add Upload Media Widget/Action

1. Go to your page (e.g., Profile Page, Edit Profile Page)
2. Add a button: "Upload Photo" or use an avatar image with onTap
3. Click the button → Add Action → **Upload/Download** → **Upload Media**
4. Configure Upload Media:
   - **Allow Photo**: ✅ Yes
   - **Allow Video**: ❌ No
   - **Media Source**: Photo Gallery (or Camera, or both)
   - **Max Width**: 800 (optional)
   - **Max Height**: 800 (optional)
   - **Image Quality**: 80 (optional)
5. Click **Confirm**

#### Step 2: Store Uploaded File in Page State

1. After Upload Media action, click **+ Add Action**
2. Choose **Widget State** → **Update Page State**
3. Create a new page state variable (if not exists):
   - **Name**: `uploadedFile`
   - **Type**: `FFUploadedFile`
4. Set Field: `uploadedFile`
5. Set Value: **Action Output** → **Uploaded Local File** (from Upload Media)
6. Click **Confirm**

#### Step 3: Call Custom Action

1. Click **+ Add Action** (after Update Page State)
2. Choose **Custom Code** → **Custom Action** → **uploadToSupabaseStorage**
3. Configure parameters:
   - **context**: Automatically filled
   - **uploadedFile**: **Page State** → `uploadedFile`
   - **bucketName**: **Set from Variable** → **Custom Value** → Type: `"user-avatars"`
   - **customPath**: Leave blank (uses current user's Firebase UID automatically)
4. Set Action Output Variable Name: `uploadedAvatarUrl` (String, Page State)
5. Click **Confirm**

#### Step 4: Update Database with Avatar URL

1. Click **+ Add Action** (after custom action)
2. Choose **Backend Call** → **Supabase Call**
3. Configure:
   - **Action Type**: Update
   - **Table**: Choose your profile table:
     - `medical_provider_profiles` (for providers)
     - `facility_admin_profiles` (for facility admins)
     - `system_admin_profiles` (for system admins)
     - `users` (for patients, or any user)
4. Set Fields to Update:
   - **avatar_url**: **Page State** → `uploadedAvatarUrl`
5. Add Filter:
   - **Field**: `user_id`
   - **Relation**: Equal To
   - **Value**: **Authenticated User** → **User ID** (or firebase_uid if using Firebase Auth)
6. Click **Confirm**

#### Step 5: Show Success Message (Optional)

1. Click **+ Add Action**
2. Choose **Widget** → **Show Snack Bar**
3. Message: "Profile picture updated!"
4. Click **Confirm**

#### Step 6: Refresh UI

1. Click **+ Add Action**
2. Choose **Widget State** → **Update Page State**
3. Update any image widgets to show the new avatar

---

### Upload Facility Image (Care Center Photo)

#### Step 1: Upload Media

Same as above (Step 1-2)

#### Step 2: Call Custom Action - uploadToSupabaseStorage

1. Click **+ Add Action**
2. Choose **Custom Code** → **Custom Action** → **uploadToSupabaseStorage**
3. Configure parameters:
   - **context**: Automatically filled
   - **uploadedFile**: **Page State** → `uploadedFile`
   - **bucketName**: `"facility-images"` (or your preferred bucket)
4. Set Action Output Variable Name: `facilityImageUrl` (String, Page State)
5. Click **Confirm**

#### Step 3: Update Facilities Table

1. Click **+ Add Action**
2. Choose **Backend Call** → **Supabase Call**
3. Configure:
   - **Action Type**: Update
   - **Table**: `facilities`
4. Set Fields:
   - **image_url**: **Page State** → `facilityImageUrl`
5. Add Filter:
   - **Field**: `id`
   - **Relation**: Equal To
   - **Value**: Your facility ID (from page param or app state)
6. Click **Confirm**

---

## Common Mistakes to Avoid

### ❌ WRONG: Using Default Supabase Upload

```
Actions:
1. Upload Media
2. Upload to Supabase Storage ❌ DON'T USE THIS
   - Bucket: user-avatars
   - Path: uploads/
```

**Problem**: Creates flat path `user-avatars/filename.jpg` → RLS blocks it → 400 error

### ✅ CORRECT: Using Custom Action

```
Actions:
1. Upload Media → uploadedFile
2. Custom Action: uploadToSupabaseStorage ✅ USE THIS
   - uploadedFile: uploadedFile
   - bucketName: "user-avatars"
3. Update Database
   - SET avatar_url = uploadedAvatarUrl
```

**Result**: Creates user directory path `user-avatars/{user_id}/filename.jpg` → RLS allows → Success!

---

## Troubleshooting

### "I don't see the image in storage"

**Check**:
1. Are you using the **custom action** (not default upload)?
2. In Supabase Dashboard → Storage → user-avatars bucket
3. Look inside the folder named with your Firebase UID
4. Path should be: `user-avatars/{your-firebase-uid}/filename.jpg`

### "400 Bad Request error"

**Cause**: Using flat path (wrong upload method)

**Fix**: Remove "Upload to Supabase Storage" action, use custom action instead

### "403 Unauthorized error"

**Cause**: User not authenticated

**Fix**: Ensure user is signed in (check `currentUserUid` is not null)

### "Facility image limit reached"

**Cause**: Facility already has 3 images

**Fix**: Delete one existing image first, then upload new one

### "File too large"

**Limits**:
- User avatars: 5MB max
- Facility images: 10MB max
- Documents: 50MB max

**Fix**: Compress image before upload or use smaller file

---

## Testing Your Setup

### Test 1: Check Upload Flow

1. Click Upload button
2. Select image from gallery
3. Wait for upload (should show success message)
4. Check Supabase Dashboard → Storage → user-avatars
5. Find folder with your Firebase UID
6. Image should be inside that folder

### Test 2: Verify Database Update

1. After upload, check Supabase Dashboard → Table Editor
2. Open your profile table (e.g., medical_provider_profiles)
3. Find your user record
4. `avatar_url` field should contain full URL:
   ```
   https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/user-avatars/{your-uid}/1762404758074000.jpg
   ```

### Test 3: Display Image

1. Add Image widget to your page
2. Set Image Path:
   - **Source**: Network
   - **Path**: **Backend Call** → Query your profile table → Get `avatar_url`
3. Image should load and display

---

## Quick Reference: Action Parameters

### uploadToSupabaseStorage

| Parameter | Type | Required | Example |
|-----------|------|----------|---------|
| context | BuildContext | Yes | Auto-filled |
| uploadedFile | FFUploadedFile | Yes | From Upload Media action |
| bucketName | String | Yes | `"user-avatars"`, `"documents"` |
| customPath | String | No | Leave blank for current user |

**Returns**: String (public URL) or null (on error)

---

## Example Complete Flow (Copy This!)

```
Button: "Upload Profile Picture"
├─ On Tap Action Chain:
│
├─ 1. Upload Media
│     └─ Allow Photo: Yes
│     └─ Media Source: Photo Gallery
│
├─ 2. Update Page State
│     └─ Set: uploadedFile = Uploaded Local File
│
├─ 3. Custom Action: uploadToSupabaseStorage
│     └─ uploadedFile: uploadedFile (Page State)
│     └─ bucketName: "user-avatars" (Custom Value)
│     └─ Output Variable: uploadedAvatarUrl
│
├─ 4. Conditional: uploadedAvatarUrl is not null
│     │
│     ├─ 4a. Backend Call (Supabase)
│     │     └─ Update: medical_provider_profiles
│     │     └─ SET: avatar_url = uploadedAvatarUrl
│     │     └─ WHERE: user_id = Authenticated User ID
│     │
│     ├─ 4b. Show Snack Bar
│     │     └─ "Profile picture updated!"
│     │
│     └─ 4c. Refresh Widget State
│           └─ Trigger page rebuild to show new avatar
│
└─ 5. Conditional: uploadedAvatarUrl is null
      └─ Show Snack Bar (Error)
            └─ "Upload failed. Please try again."
```

---

## Need Help?

1. **Check logs**: Flutter console during upload shows debug messages
2. **Check Supabase logs**: Dashboard → Logs → Storage
3. **Run test script**: `./test_storage_upload.sh`
4. **Review docs**: `SUPABASE_STORAGE_UPLOAD_GUIDE.md`

---

**Remember**: ALWAYS use the custom actions, NEVER use the default FlutterFlow "Upload to Supabase Storage" action!
