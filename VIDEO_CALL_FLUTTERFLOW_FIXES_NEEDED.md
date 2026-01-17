# Video Call FlutterFlow Fixes Needed

**Date:** December 17, 2025
**Status:** ✅ Code Analysis Complete - FlutterFlow Fixes Required
**Priority:** HIGH

## Executive Summary

Two critical issues identified in video call implementation:

1. ✅ **Legacy Widget Removal** - COMPLETE (no code changes needed)
2. ⚠️ **Placeholder Image URLs** - FlutterFlow configuration needed

## Issue 1: Legacy ChimeMeetingWebview Widget ✅ RESOLVED

### Error
```
Asset for key "assets/html/chime_meeting.html" not found
```

### Analysis
- ✅ **Legacy widget file:** Already deleted from filesystem
- ✅ **Widget index:** Already cleaned (only `ChimeMeetingEnhanced` exported)
- ✅ **Code references:** NO references to `ChimeMeetingWebview` found in `lib/` directory
- ✅ **HTML asset references:** NO references to `assets/html/chime_meeting.html` found

### Conclusion
The legacy `ChimeMeetingWebview` widget and associated HTML files have already been completely removed from the codebase. The error may be coming from:
- Cached FlutterFlow build artifacts
- Old app installation on device

### Fix
```bash
# Clean build artifacts
flutter clean && flutter pub get

# Uninstall old app from device
adb uninstall mylestech.medzenhealth

# Rebuild and install fresh
flutter run
```

---

## Issue 2: Hardcoded Placeholder Image URLs ⚠️ FLUTTERFLOW FIX REQUIRED

### Error
```
Invalid argument(s): No host specified in URI file:///500x500?doctor
```

### Root Cause
FlutterFlow-generated widget files contain hardcoded placeholder URLs instead of dynamic user profile images.

### Affected Files (FlutterFlow-generated - DO NOT EDIT MANUALLY)
1. `lib/patients_folder/patient_landing_page/patient_landing_page_widget.dart:859`
2. `lib/home_pages/video_call/video_call_widget.dart:164`
3. `lib/home_pages/chime_video_call_page/chime_video_call_page_widget.dart:164`
4. `lib/all_users_page/appointments/appointments_widget.dart:557,1065,1587`
5. `lib/medical_provider/provider_landing_page/provider_landing_page_widget.dart:570`

### Example of Problem Code
```dart
// ❌ WRONG - Hardcoded placeholder
decoration: BoxDecoration(
  image: DecorationImage(
    fit: BoxFit.cover,
    image: Image.network(
      '500x500?doctor',  // ← HARDCODED PLACEHOLDER
    ).image,
  ),
  shape: BoxShape.circle,
)

// ✅ CORRECT - Dynamic user image
decoration: BoxDecoration(
  image: DecorationImage(
    fit: BoxFit.cover,
    image: Image.network(
      currentUserPhoto ?? 'https://ui-avatars.com/api/?name=User',
    ).image,
  ),
  shape: BoxShape.circle,
)
```

### Fix in FlutterFlow

For each affected page, you need to:

#### 1. Patient Landing Page
1. Open `PatientLandingPage` in FlutterFlow
2. Find the avatar/profile image widget (around line 859 area)
3. Change image source from static `'500x500?doctor#1'` to:
   - **Dynamic:** `currentUserPhoto` with fallback
   - **Or use:** `https://ui-avatars.com/api/?name=${currentUserDisplayName}`

#### 2. Video Call Pages
1. Open `VideoCallPage` and `ChimeVideoCallPage` in FlutterFlow
2. Find profile image widgets (around line 164)
3. Change from static `'500x500?doctor'` to dynamic user photo field

#### 3. Appointments Pages
1. Open appointments widgets in FlutterFlow
2. Find provider/patient avatar images
3. Replace all `'500x500?doctor#1'` with dynamic fields like:
   - Provider image: `providerProfileImage`
   - Patient image: `patientProfileImage`
   - Fallback: `https://ui-avatars.com/api/?name=${userName}`

#### 4. Provider Landing Page
1. Open `ProviderLandingPage` in FlutterFlow
2. Find avatar widget (around line 570)
3. Change to dynamic user photo field

### Alternative: UI Avatars Fallback
For a robust solution, use conditional expressions in FlutterFlow:

```dart
// Pseudo-FlutterFlow expression
if (userPhoto != null && userPhoto.startsWith('http')) {
  userPhoto
} else {
  'https://ui-avatars.com/api/?name=' + userName + '&size=500'
}
```

### Database Migration (Already Applied)
The following database migrations have already been applied to fix any malformed URLs in the database:
- ✅ `20251203000000_fix_malformed_image_urls.sql`
- ✅ `20251213120000_fix_all_malformed_urls.sql`
- ✅ `20251213210000_fix_all_profile_image_urls.sql`
- ✅ `20251215170000_fix_all_malformed_image_urls.sql`

These migrations set any malformed URLs to NULL, allowing proper fallback behavior.

---

## Quick Verification

After fixing in FlutterFlow and re-exporting:

```bash
# 1. Search for remaining hardcoded placeholders
grep -r "500x500" lib/ | grep -v "migrations" | grep -v ".md"

# 2. Should return NO results (or only documentation files)

# 3. Clean and rebuild
flutter clean && flutter pub get
flutter run
```

---

## Expected Results After Fix

### Before (Current)
```
❌ Multiple errors: Invalid argument(s): No host specified in URI file:///500x500?doctor
❌ Profile images show error icons
❌ App may crash when loading certain pages
```

### After (Fixed)
```
✅ No URL parsing errors
✅ Profile images load correctly from database
✅ Fallback to UI Avatars for users without photos
✅ Smooth video call experience
```

---

## Why This Happened

FlutterFlow uses placeholder values during design time:
- Design mode: `'500x500?doctor'` shows a placeholder
- Production mode: Should be replaced with dynamic data binding

**The placeholders were not replaced with dynamic fields before export.**

---

## Prevention

1. **Before each FlutterFlow export:**
   - Review all image widgets
   - Ensure they use dynamic data bindings, not static strings
   - Test with real user data in FlutterFlow preview

2. **After export:**
   - Run: `grep -r "500x500" lib/ | grep -v ".md"`
   - Fix any hardcoded placeholders found

3. **Use the safe re-export script:**
   ```bash
   ./safe-reexport.sh ~/Downloads/export.zip
   ```

---

## Summary

| Issue | Status | Action Required |
|-------|--------|-----------------|
| Legacy ChimeMeetingWebview | ✅ Complete | Clean build + reinstall app |
| Placeholder image URLs | ⚠️ Needs FlutterFlow fix | Update 5 pages in FlutterFlow UI |
| Database malformed URLs | ✅ Complete | Migrations already applied |

**Next Steps:**
1. Fix image widgets in FlutterFlow (5 pages)
2. Re-export from FlutterFlow
3. Run `flutter clean && flutter pub get`
4. Uninstall old app from device
5. Rebuild and test

---

## Support

If you need help with FlutterFlow configuration:
1. See FlutterFlow docs on dynamic image binding
2. Check `CLAUDE.md` for FlutterFlow best practices
3. Review `FLUTTERFLOW_UI_SETUP_GUIDE.md` for detailed instructions
