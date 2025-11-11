# FlutterFlow Avatar Upload Fix - Step-by-Step Guide

## Problem
- Images uploaded from FlutterFlow are **blurry** (only 12-18 KB)
- Files use **timestamp names** instead of user-specific names
- **Multiple files per user** (duplicates not being replaced)

## Solution
Update the FlutterFlow upload action chain to:
1. Compress/resize images to 1024×1024 pixels
2. Use fixed filename pattern per user
3. Replace old files automatically

---

## Implementation in FlutterFlow

### Step 1: Locate Your Avatar Upload Page

1. Open FlutterFlow web interface → Load your project
2. Navigate to the page where users upload avatars (e.g., Profile Edit page)
3. Find the "Upload Avatar" button/action

---

### Step 2: Modify the Upload Action Chain

**Current Action Chain (Broken):**
```
Button OnTap → Upload Media → Upload to Supabase Storage
```

**New Action Chain (Fixed):**
```
Button OnTap → Upload Media → compressAndResizeImage → Upload to Supabase Storage → Update Page State → Update Database
```

---

### Step 3: Configure Each Action

#### Action 1: Upload Media
- **Action:** Upload/Download → Upload Media
- **Source:** From Gallery / From Camera
- **Media Type:** Image
- **Output Variable Name:** `uploadedLocalFile`

✅ This is already correct, no changes needed.

---

#### Action 2: compressAndResizeImage (NEW - ADD THIS)

**Location:** Between "Upload Media" and "Upload to Supabase Storage"

**Configuration:**
- **Action:** Custom Action → `compressAndResizeImage`
- **Parameters:**
  - `imagePath`: **Set from Variable** → `uploadedLocalFile`
- **Output Variable Name:** `compressedImagePath`

**How to Add:**
1. Click the "+" button after "Upload Media" action
2. Select "Custom Action"
3. Find and select "compressAndResizeImage"
4. Set imagePath parameter to `uploadedLocalFile`
5. Name the output variable: `compressedImagePath`

---

#### Action 3: Upload to Supabase Storage (MODIFY THIS)

**Configuration:**
- **Action:** Supabase → Upload Data
- **Bucket:** `user-avatars`
- **File:** **Set from Variable** → `compressedImagePath` ← CHANGED from uploadedLocalFile
- **File Path:** ← **THIS IS CRITICAL**

**File Path Options:**

**For Patient Profile:**
```
user_avatar-{Patient Number}.jpg
```
Example result: `user_avatar-PAT001.jpg`

**For Provider Profile:**
```
user_avatar-{Provider Number}.jpg
```
Example result: `user_avatar-PRV042.jpg`

**For Admin Profile:**
```
user_avatar-{Admin Number}.jpg
```
Example result: `user_avatar-ADM005.jpg`

**Alternative (using User UID if simpler):**
```
user_avatar-{Authenticated User UID}.jpg
```
Example result: `user_avatar-abc123def456.jpg`

- **Output Variable Name:** `uploadedPath`

**Critical Settings:**
- ✅ File must be `compressedImagePath` (not `uploadedLocalFile`)
- ✅ File Path MUST be set (don't leave empty)
- ✅ Use consistent pattern per role

---

#### Action 4: Update Page State (NEW - ADD THIS)

**Purpose:** Build the complete URL with timestamp for cache busting

**Configuration:**
- **Action:** Widget State → Update Page State
- **Field to Update:** Create a new page state variable called `avatarUrl`
- **Set Value To:** Combine Text →

**URL Format:**
```
https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/user-avatars/user_avatar-{Patient Number}.jpg?t={Current Timestamp (Milliseconds)}
```

**How to Build in FlutterFlow:**
1. Base URL: `https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/user-avatars/`
2. + Filename: `user_avatar-`
3. + Patient Number (or Provider Number, etc.)
4. + `.jpg?t=`
5. + Current Timestamp (Milliseconds)

**Result Variable:** `avatarUrl` (page state)

---

#### Action 5: Update Database (NEW - ADD THIS)

**Purpose:** Save the avatar URL to the user's profile table

**Configuration:**
- **Action:** Backend Call → Supabase → Update Row(s)
- **Table:** (Your profile table - e.g., `patient_profiles`, `medical_provider_profiles`, etc.)
- **Match Column:** `id` or `user_id`
- **Match Value:** `{Authenticated User UID}` or `{Current User Record → id}`
- **Fields to Update:**
  - `avatar_url` = **Set from Variable** → `avatarUrl` (from page state)

**For Different Roles:**

**Patient:**
- Table: `patient_profiles`
- Match: `user_id = {Authenticated User UID}`
- Update: `avatar_url = {avatarUrl}`

**Provider:**
- Table: `medical_provider_profiles`
- Match: `user_id = {Authenticated User UID}`
- Update: `avatar_url = {avatarUrl}`

**Admin:**
- Table: `facility_admin_profiles` or `system_admin_profiles`
- Match: `user_id = {Authenticated User UID}`
- Update: `avatar_url = {avatarUrl}`

---

#### Action 6: Show Snack Bar (Optional)

**Configuration:**
- **Action:** Widget → Show Snack Bar
- **Message:** "✅ Profile picture updated!"
- **Duration:** 3 seconds

---

### Step 4: Complete Action Chain Summary

**Final Action Sequence:**

```
1. Upload Media
   └─ Output: uploadedLocalFile

2. compressAndResizeImage
   ├─ Input: uploadedLocalFile
   └─ Output: compressedImagePath

3. Upload to Supabase Storage
   ├─ Bucket: "user-avatars"
   ├─ File: compressedImagePath
   ├─ File Path: "user_avatar-{Patient Number}.jpg"
   └─ Output: uploadedPath

4. Update Page State
   └─ avatarUrl = "https://.../user_avatar-PAT001.jpg?t=1762407500000"

5. Update Database
   ├─ Table: patient_profiles (or appropriate table)
   ├─ Match: user_id = {Authenticated User UID}
   └─ Set: avatar_url = {avatarUrl}

6. Show Snack Bar
   └─ Message: "✅ Profile picture updated!"
```

---

## Verification Checklist

After implementing, verify:

### In FlutterFlow:
- [ ] `compressAndResizeImage` action exists in action chain
- [ ] Action receives `uploadedLocalFile` as input
- [ ] File Path is set to: `user_avatar-{Number}.jpg`
- [ ] File parameter uses `compressedImagePath` (not uploadedLocalFile)
- [ ] URL includes timestamp query parameter (`?t=...`)
- [ ] Database update action saves the URL

### Test Upload:
- [ ] Upload an avatar from the app
- [ ] Check Supabase Storage → user-avatars bucket
- [ ] Should see: `user_avatar-PAT001.jpg` (or similar)
- [ ] Check file size: Should be ~200-300 KB (not 12-18 KB)
- [ ] Upload again → verify file is REPLACED (not duplicated)

### Visual Quality:
- [ ] Image appears sharp on actual device (not emulator)
- [ ] Test on high-DPI phone (iPhone, modern Android)
- [ ] Zoom in → should not see pixelation

---

## Troubleshooting

### Issue: compressAndResizeImage action not found
**Solution:**
1. Verify `pubspec.yaml` has `image: 4.2.0` in `dependencies` (not dev_dependencies)
2. Run `flutter pub get`
3. Push to FlutterFlow again
4. Action should appear in Custom Actions list

### Issue: File still shows timestamp name
**Solution:**
1. Check File Path parameter is NOT empty
2. Should be: `user_avatar-{Patient Number}.jpg`
3. Curly braces indicate variable substitution
4. Test with a hardcoded value first: `user_avatar-TEST.jpg`

### Issue: Images still blurry
**Solution:**
1. Verify `compressAndResizeImage` is actually running
2. Check that File parameter uses `compressedImagePath` (not uploadedLocalFile)
3. Check Supabase Storage file size → should be 200-300 KB
4. If still 12-18 KB, compression didn't run

### Issue: Old images not being replaced
**Solution:**
1. Verify File Path is EXACTLY the same each time
2. Should be: `user_avatar-{Patient Number}.jpg`
3. Patient Number must be consistent for same user
4. Check Supabase Storage → should only see ONE file per user

---

## Clean Up Old Files (Optional)

If you want to delete existing blurry/duplicate files:

```bash
chmod +x cleanup_old_avatars.sh
./cleanup_old_avatars.sh
```

**Warning:** This deletes ALL files in user-avatars bucket. Users will need to re-upload.

---

## Expected Results

### Before Fix:
```
Storage:
├─ 1762407326884000.jpeg (12 KB) ❌ Blurry
├─ 1762407439265000.png (18 KB) ❌ Blurry
├─ 1762407500123456.jpeg (15 KB) ❌ Duplicate
└─ 1762407600234567.jpeg (14 KB) ❌ Duplicate

User Experience:
- Blurry images on modern phones
- Multiple old files
- Wastes storage space
```

### After Fix:
```
Storage:
├─ user_avatar-PAT001.jpg (250 KB) ✅ Sharp
├─ user_avatar-PAT002.jpg (280 KB) ✅ Sharp
├─ user_avatar-PRV042.jpg (230 KB) ✅ Sharp
└─ user_avatar-ADM005.jpg (265 KB) ✅ Sharp

User Experience:
- Sharp images on all devices
- One file per user
- Automatic replacement
- Fast loading
```

---

## Technical Details

### Why 1024×1024?
- Modern phones have 2x-3x pixel density
- 120px diameter circle needs:
  - 1x display: 120px → OK
  - 2x display: 240px physical → 1024px source = sharp
  - 3x display: 360px physical → 1024px source = sharp
- 1024×1024 covers all devices

### Why JPEG 85% quality?
- Perfect balance: Sharp image, reasonable file size
- 100% quality = 500-800 KB (too large)
- 85% quality = 200-300 KB (optimal)
- 70% quality = 100-150 KB (visible quality loss)

### Why timestamp in URL?
- Browser caches images
- Without timestamp, old image shows after upload
- `?t=1762407500000` forces browser to reload
- Timestamp changes each upload

---

## Related Documentation

- `WHY_AVATARS_ARE_BLURRED.md` - Technical explanation of pixel density
- `AVATAR_UPLOAD_FIX.md` - Complete solution overview
- `compress_and_resize_image.dart` - The compression action code
- `cleanup_old_avatars.sh` - Script to delete old files

---

**Status:** ✅ Ready to implement in FlutterFlow

**Next Step:** Open FlutterFlow web interface and follow steps above

**Result:** Sharp, user-specific avatars that automatically replace old uploads! 🎉
