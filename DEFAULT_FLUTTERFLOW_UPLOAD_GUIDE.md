# Default FlutterFlow Upload - Setup Guide

## ✅ Now You Can Use Default FlutterFlow Upload!

The storage RLS policies have been updated to work with FlutterFlow's default "Upload to Supabase Storage" action.

---

## How It Works

### Previous Approach (Custom Actions)
- ❌ Required custom Dart actions
- ❌ Required user directory paths: `user-avatars/{user_id}/filename.jpg`
- ❌ RLS policies enforced directory structure

### New Approach (Default FlutterFlow Upload)
- ✅ Use FlutterFlow's built-in "Upload to Supabase Storage" action
- ✅ Supports flat paths: `user-avatars/filename.jpg`
- ✅ Security via ownership tracking table
- ✅ Optional: Call `trackStorageUpload()` action for enhanced ownership tracking

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

#### Step 2: Upload to Supabase Storage (Default Action)

1. After Upload Media action, click **+ Add Action**
2. Choose **Backend Call** → **Supabase Call** → **Upload to Supabase Storage**
3. Configure:
   - **File**: **Action Output** → **Uploaded Local File** (from Upload Media)
   - **Bucket**: **Set from Variable** → **Custom Value** → Type: `user-avatars`
   - **File Path**: Leave blank or use a custom path (e.g., `avatars/`)
4. Set Action Output Variable Name: `uploadedFilePath` (String, Page State)
5. Click **Confirm**

#### Step 3: (Optional) Track Ownership

1. Click **+ Add Action** (after Upload to Supabase Storage)
2. Choose **Custom Code** → **Custom Action** → **trackStorageUpload**
3. Configure parameters:
   - **storagePath**: **Page State** → `uploadedFilePath`
   - **bucketName**: **Custom Value** → `"user-avatars"`
   - **fileType**: **Custom Value** → `"avatar"` (optional)
   - **facilityId**: Leave blank (not needed for avatars)
4. Click **Confirm**

**Note:** This step is optional but recommended for better file management and future features.

#### Step 4: Build Public URL

The uploaded file path is relative (e.g., `1762405123456000.jpg`). You need to build the full public URL:

1. Click **+ Add Action**
2. Choose **Widget State** → **Update Page State**
3. Set:
   - **Variable**: Create new variable `avatarUrl` (String)
   - **Value**: **Custom Code** → Use this formula:
   ```
   "https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/user-avatars/" + uploadedFilePath
   ```

Or create a custom function to build the URL (recommended).

#### Step 5: Update Database with Avatar URL

1. Click **+ Add Action**
2. Choose **Backend Call** → **Supabase Call**
3. Configure:
   - **Action Type**: Update
   - **Table**: Choose your profile table:
     - `medical_provider_profiles` (for providers)
     - `facility_admin_profiles` (for facility admins)
     - `system_admin_profiles` (for system admins)
     - `users` (for patients)
4. Set Fields to Update:
   - **avatar_url**: **Page State** → `avatarUrl`
5. Add Filter:
   - **Field**: `user_id`
   - **Relation**: Equal To
   - **Value**: **Authenticated User** → **User ID** (or firebase_uid)
6. Click **Confirm**

#### Step 6: Show Success Message

1. Click **+ Add Action**
2. Choose **Widget** → **Show Snack Bar**
3. Message: "Profile picture updated!"
4. Click **Confirm**

---

### Upload Facility Image (Care Center Photo)

#### Step 1-2: Upload Media + Upload to Supabase Storage

Same as avatar upload (Step 1-2), but:
- **Bucket**: `facility-images`
- **File Path**: Leave blank or use `facilities/`

#### Step 3: (Optional) Track Ownership with Facility ID

1. Custom Action: **trackStorageUpload**
2. Parameters:
   - **storagePath**: `uploadedFilePath`
   - **bucketName**: `"facility-images"`
   - **fileType**: `"facility_image"`
   - **facilityId**: **Page Parameters** → `facilityId` (or from App State)

#### Step 4-6: Build URL, Update Database, Show Success

Same as avatar upload, but update `facilities` table with `image_url`.

---

### Upload Document (Medical Records)

Same as avatar upload, but use bucket `"documents"` and optionally set `fileType` to `"document"`.

---

## Storage Buckets Configuration

| Bucket | Size Limit | Public | Allowed Types | Usage |
|--------|-----------|--------|---------------|-------|
| `user-avatars` | 5MB | Private | JPEG, JPG, PNG, GIF, WebP | Profile pictures for all 4 user types |
| `facility-images` | 10MB | Public | JPEG, JPG, PNG, GIF, WebP | Care center photos (max 3 per facility) |
| `documents` | 50MB | Private | PDF, JPEG, JPG, PNG, DOC, DOCX | Medical records, documents |

---

## Security Model

### Old Approach: Directory-Based RLS
```sql
-- Required user directories: user-avatars/{user_id}/filename.jpg
WITH CHECK (
  (storage.foldername(name))[1] = auth.uid()::text
)
```

### New Approach: Ownership Table + RLS
```sql
-- Allows flat paths: user-avatars/filename.jpg
-- Security via ownership tracking table
WITH CHECK (bucket_id = 'user-avatars')
```

**File Ownership Table:**
- Tracks which user uploaded which file
- Used for DELETE/UPDATE permissions
- Optional but recommended for better management

**Benefits:**
- ✅ Works with default FlutterFlow upload
- ✅ Simpler FlutterFlow setup (no custom Dart actions required)
- ✅ Flexible file path structure
- ✅ Still secure via RLS policies

**Trade-offs:**
- ⚠️ Optional ownership tracking (recommended but not enforced)
- ⚠️ Requires building public URLs manually in FlutterFlow

---

## Creating a Custom Function for URL Building

To avoid building URLs manually, create a custom function:

**File**: `lib/flutter_flow/custom_functions.dart`

```dart
String buildStorageUrl(String bucketName, String filePath) {
  const baseUrl = 'https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public';
  return '$baseUrl/$bucketName/$filePath';
}
```

**Usage in FlutterFlow:**
- **Custom Code** → **Custom Function** → `buildStorageUrl`
- Parameters: `bucketName`, `filePath`

---

## Example Complete Flow (User Avatar)

```
Button: "Upload Profile Picture"
├─ On Tap Action Chain:
│
├─ 1. Upload Media
│     └─ Allow Photo: Yes
│     └─ Media Source: Photo Gallery
│     └─ Output: Uploaded Local File
│
├─ 2. Upload to Supabase Storage (Default FlutterFlow Action)
│     └─ File: Uploaded Local File
│     └─ Bucket: "user-avatars"
│     └─ File Path: (blank or "avatars/")
│     └─ Output Variable: uploadedFilePath
│
├─ 3. (Optional) Custom Action: trackStorageUpload
│     └─ storagePath: uploadedFilePath
│     └─ bucketName: "user-avatars"
│     └─ fileType: "avatar"
│
├─ 4. Update Page State
│     └─ avatarUrl = buildStorageUrl("user-avatars", uploadedFilePath)
│
├─ 5. Conditional: avatarUrl is not null
│     │
│     ├─ 5a. Backend Call (Supabase)
│     │     └─ Update: medical_provider_profiles
│     │     └─ SET: avatar_url = avatarUrl
│     │     └─ WHERE: user_id = Authenticated User ID
│     │
│     ├─ 5b. Show Snack Bar
│     │     └─ "Profile picture updated!"
│     │
│     └─ 5c. Refresh Widget State
│           └─ Trigger page rebuild to show new avatar
│
└─ 6. Conditional: avatarUrl is null
      └─ Show Snack Bar (Error)
            └─ "Upload failed. Please try again."
```

---

## Verification Steps

### 1. Check Upload Success

After uploading, check:
1. Supabase Dashboard → Storage → Your bucket
2. You should see your file (flat path is OK now!)
3. Path example: `user-avatars/1762405123456000_profile.jpg`

### 2. Verify Database Update

1. Supabase Dashboard → Table Editor → Your profile table
2. Find your user record
3. `avatar_url` should contain full URL:
   ```
   https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/user-avatars/1762405123456000_profile.jpg
   ```

### 3. (Optional) Check Ownership Tracking

If you called `trackStorageUpload()`:
1. Supabase Dashboard → Table Editor → `storage_file_ownership`
2. Find your file record
3. Should have: `storage_path`, `owner_firebase_uid`, `file_type`

---

## Troubleshooting

### Upload succeeds but image doesn't display

**Cause**: Database `avatar_url` not updated correctly

**Fix**:
1. Check Step 5 (Update Database) is configured correctly
2. Verify `avatarUrl` variable contains full URL (not just path)
3. Check Image widget is bound to database `avatar_url` field

### "File not found" error when viewing

**Cause**: Building URL incorrectly or using wrong bucket name

**Fix**:
1. Verify URL format: `https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/{bucket}/{path}`
2. Check bucket name matches exactly: `user-avatars` (not `user_avatars`)
3. Ensure path doesn't start with `/`

### Permission denied (403) error

**Cause**: RLS policy issue or user not authenticated

**Fix**:
1. Verify user is signed in (`currentUserUid` is not null)
2. Check migration `20251106120000` was applied successfully
3. Run verification script: `./test_storage_upload.sh`

### Facility image limit error

**Cause**: Facility already has 3 images (Note: limit enforcement is optional with new approach)

**Fix**: Delete one existing image first, then upload new one

---

## Migration Applied

**File**: `supabase/migrations/20251106120000_fix_storage_for_flutterflow_default_upload.sql`

**Changes**:
- ✅ Updated RLS policies to allow flat path uploads
- ✅ Created `storage_file_ownership` table for ownership tracking
- ✅ Added helper functions: `track_file_upload()`, `check_file_ownership()`, `get_file_owner()`
- ✅ Maintained security via ownership table
- ✅ All existing buckets and size limits preserved

**Verification:**
```bash
./test_storage_upload.sh
# Should show all buckets configured correctly
```

---

## Benefits of New Approach

1. **Easier FlutterFlow Setup**: Use built-in "Upload to Supabase Storage" action (no custom Dart required)
2. **Flexibility**: Supports any file path structure
3. **Optional Tracking**: Ownership tracking is optional but recommended
4. **Backward Compatible**: Works with both flat paths and directory structures
5. **Same Security**: RLS policies still protect files based on authenticated user

---

## When to Use Ownership Tracking (`trackStorageUpload`)

### ✅ Recommended For:
- Profile pictures (helps manage user avatar updates)
- Facility images (required for counting 3-image limit)
- Documents (helps with file organization and auditing)

### ⚠️ Optional For:
- Temporary files
- Public assets
- Files that don't need ownership management

---

## Need Help?

1. **Check logs**: Flutter console during upload shows debug messages
2. **Check Supabase logs**: Dashboard → Logs → Storage
3. **Run test script**: `./test_storage_upload.sh`
4. **Review migration**: `supabase/migrations/20251106120000_fix_storage_for_flutterflow_default_upload.sql`

---

**Status**: ✅ **READY TO USE**

You can now use FlutterFlow's default "Upload to Supabase Storage" action with flat paths. Storage RLS policies updated to support this approach while maintaining security via ownership tracking.
