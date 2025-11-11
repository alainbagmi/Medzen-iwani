# Avatar Upload - Quick Reference Card

## ⚡ Quick Fix Summary

**Problem:** Blurry 12 KB images with timestamp names
**Solution:** Add compression + fixed filename
**Result:** Sharp 250 KB images with user-specific names

---

## 🎯 FlutterFlow Action Chain

### What You Need to Build:

```
┌─────────────────────────────────────────────────────────────┐
│  Button OnTap → Upload Media Action                        │
└─────────────────────────────────────────────────────────────┘
                    ↓
                    Output: uploadedLocalFile
                    ↓
┌─────────────────────────────────────────────────────────────┐
│  Custom Action: compressAndResizeImage                      │
│  ├─ Input: uploadedLocalFile                               │
│  └─ Output: compressedImagePath                            │
└─────────────────────────────────────────────────────────────┘
                    ↓
                    Output: compressedImagePath (~250 KB, 1024x1024)
                    ↓
┌─────────────────────────────────────────────────────────────┐
│  Upload to Supabase Storage                                 │
│  ├─ Bucket: "user-avatars"                                 │
│  ├─ File: compressedImagePath     ← Use compressed!        │
│  ├─ File Path: "user_avatar-{Patient Number}.jpg"          │
│  └─ Output: uploadedPath                                   │
└─────────────────────────────────────────────────────────────┘
                    ↓
                    Result: user_avatar-PAT001.jpg created
                    ↓
┌─────────────────────────────────────────────────────────────┐
│  Update Page State: avatarUrl                               │
│  └─ Build URL with timestamp for cache refresh             │
└─────────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│  Update Database                                            │
│  ├─ Table: patient_profiles                                │
│  ├─ Match: user_id = {Auth User UID}                       │
│  └─ Set: avatar_url = {avatarUrl}                          │
└─────────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────────┐
│  Show Snack Bar: "✅ Profile picture updated!"             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 Critical Settings

### 1. compressAndResizeImage Action

| Parameter | Value |
|-----------|-------|
| imagePath | `uploadedLocalFile` (from Upload Media) |
| Output Variable | `compressedImagePath` |

**What it does:** Converts any image → 1024×1024 JPEG at 85% quality (~250 KB)

---

### 2. Upload to Supabase Storage

| Parameter | Value | Notes |
|-----------|-------|-------|
| Bucket | `user-avatars` | Existing bucket |
| File | `compressedImagePath` | ⚠️ NOT uploadedLocalFile |
| File Path | `user_avatar-{Patient Number}.jpg` | ⚠️ CRITICAL - must be set |
| Output | `uploadedPath` | For verification |

**File Path Examples:**
- Patient: `user_avatar-PAT001.jpg`
- Provider: `user_avatar-PRV042.jpg`
- Admin: `user_avatar-ADM005.jpg`

**What it does:** Uploads compressed image with fixed filename → replaces old file

---

### 3. Build URL (Page State Update)

**URL Format:**
```
https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/user-avatars/user_avatar-{Patient Number}.jpg?t={Current Timestamp}
```

**Build it in FlutterFlow using Combine Text:**

| Part | FlutterFlow Expression |
|------|----------------------|
| Base | `https://noaeltglphdlkbflipit.supabase.co/storage/v1/object/public/user-avatars/` |
| Filename | `user_avatar-` |
| User Number | `{Patient Number}` or `{Provider Number}` |
| Extension | `.jpg?t=` |
| Timestamp | `{Current Timestamp (Milliseconds)}` |

**Save to:** Page state variable `avatarUrl`

**What it does:** Creates cache-busting URL that forces browser reload

---

### 4. Database Update

| Parameter | Patient | Provider | Admin |
|-----------|---------|----------|-------|
| Table | `patient_profiles` | `medical_provider_profiles` | `facility_admin_profiles` |
| Match Column | `user_id` | `user_id` | `user_id` |
| Match Value | `{Auth User UID}` | `{Auth User UID}` | `{Auth User UID}` |
| Update Field | `avatar_url` | `avatar_url` | `avatar_url` |
| Update Value | `{avatarUrl}` | `{avatarUrl}` | `{avatarUrl}` |

**What it does:** Saves URL to database so app can display avatar

---

## ✅ Verification Checklist

### In FlutterFlow Editor:
- [ ] 6 actions in chain (Upload Media → Compress → Upload → State → DB → Snack)
- [ ] compressAndResizeImage receives `uploadedLocalFile`
- [ ] Upload uses `compressedImagePath` (not uploadedLocalFile)
- [ ] File Path set to `user_avatar-{Number}.jpg`
- [ ] URL includes `?t={timestamp}`

### After Upload:
- [ ] Check Supabase Storage → See `user_avatar-PAT001.jpg`
- [ ] File size: ~200-300 KB (not 12-18 KB)
- [ ] Upload again → File REPLACED (not duplicated)
- [ ] Image sharp on actual phone

---

## 🚨 Common Mistakes

| ❌ Wrong | ✅ Correct | Impact |
|---------|-----------|--------|
| File = `uploadedLocalFile` | File = `compressedImagePath` | No compression → blurry |
| File Path = empty | File Path = `user_avatar-PAT001.jpg` | Timestamp names → duplicates |
| URL without `?t=` | URL with `?t={timestamp}` | Browser shows old cached image |
| Hardcoded URL | Dynamic URL with user number | Wrong avatar shown |

---

## 🎨 Before vs After

### BEFORE (Current - Broken):
```
Action Chain:
Upload Media → Upload to Supabase (File Path empty)

Result:
├─ 1762407326884000.jpeg (12 KB) ❌ BLURRY
├─ 1762407439265000.png (18 KB) ❌ BLURRY
├─ 1762407500123456.jpeg (15 KB) ❌ DUPLICATE
└─ 1762407600234567.jpeg (14 KB) ❌ DUPLICATE
```

### AFTER (Fixed):
```
Action Chain:
Upload Media → compressAndResizeImage → Upload to Supabase (File Path set)

Result:
├─ user_avatar-PAT001.jpg (250 KB) ✅ SHARP
├─ user_avatar-PAT002.jpg (280 KB) ✅ SHARP
└─ user_avatar-PRV042.jpg (230 KB) ✅ SHARP

Each user = ONE file
Upload = REPLACE old file
No duplicates
```

---

## 📱 Test on Real Device

**Don't test on emulator!** Pixel density issues only show on real phones.

**Test checklist:**
1. Upload avatar on iPhone/Android
2. View on profile page → Should be sharp
3. Zoom in → Should not see pixels
4. Upload again → Should replace instantly
5. Check Storage → Only ONE file per user

---

## 🔗 File Path Patterns

Choose ONE pattern for each user type:

### Option 1: Patient/Provider Number (Recommended)
```
Patient:   user_avatar-PAT001.jpg
Provider:  user_avatar-PRV042.jpg
Admin:     user_avatar-ADM005.jpg
```

**Pros:** Clean, readable, matches your system
**Cons:** Need to get patient/provider number

### Option 2: User UID (Simpler)
```
user_avatar-abc123def456.jpg
```

**Pros:** Always available, unique
**Cons:** Long, not human-readable

---

## 💡 Pro Tips

1. **Test compression first:**
   - Add just the compression action
   - Log the output file size
   - Should see ~250 KB (not 12 KB)

2. **Test filename second:**
   - Start with hardcoded: `user_avatar-TEST.jpg`
   - Upload → Check Storage → See `user_avatar-TEST.jpg`
   - Upload again → Should still be ONE file

3. **Test dynamic filename last:**
   - Replace `TEST` with `{Patient Number}`
   - Upload for PAT001 → See `user_avatar-PAT001.jpg`
   - Upload for PAT002 → See `user_avatar-PAT002.jpg`

---

## 📚 Full Documentation

For complete details, see: `FLUTTERFLOW_AVATAR_FIX_GUIDE.md`

For technical explanation, see: `WHY_AVATARS_ARE_BLURRED.md`

---

**Status:** ✅ Ready to implement
**Time:** ~10 minutes in FlutterFlow
**Result:** Sharp, user-specific avatars! 🎉
