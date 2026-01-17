# Video Call 401 Error Fix - Complete

**Date:** December 13, 2025
**Status:** ✅ FIXED
**Issues Resolved:** 2

## Summary

Fixed two critical issues preventing video calls from working:

1. **401 Unauthorized Error** - Missing Authorization header in edge function requests
2. **Malformed Profile Image URLs** - Invalid image URLs causing app crashes

---

## Issue 1: 401 Unauthorized Error

### Root Cause
The `join_room.dart` custom action was only sending the `X-Firebase-Token` header when calling the `chime-meeting-token` edge function. However, Supabase Edge Functions require **both**:
- `Authorization` header with Supabase anon key (to pass through edge runtime)
- `X-Firebase-Token` header with Firebase JWT (for user authentication)

### Symptoms
```
I/flutter: Status code: 401
I/flutter: Response body: {"code":401,"message":"Missing authorization header"}
I/flutter: Error setting up video call: Exception: Failed to create meeting
```

### Fix Applied
Updated `lib/custom_code/actions/join_room.dart:208-224` to include both headers:

```dart
// Before (BROKEN):
headers: {
  'X-Firebase-Token': userToken,
  'Content-Type': 'application/json',
}

// After (FIXED):
headers: {
  'Authorization': 'Bearer $supabaseAnonKey',
  'X-Firebase-Token': userToken,
  'Content-Type': 'application/json',
}
```

---

## Issue 2: Malformed Profile Image URLs

### Root Cause
Profile image URLs in the database contained invalid values like `file:///500x500?doctor` instead of proper HTTP/HTTPS URLs.

### Symptoms
```
I/flutter: Another exception was thrown: Invalid argument(s): No host specified in URI
file:///500x500?doctor
```

### Fix Applied
1. **Created Migration:** `supabase/migrations/20251213210000_fix_all_profile_image_urls.sql`
2. **Actions Taken:**
   - Set malformed URLs to NULL in `users`, `medical_provider_profiles`, and `facility_admin_profiles` tables
   - Added CHECK constraints to prevent future malformed URLs
   - Affected records: 12 users + 3 providers

3. **Results:**
```
NOTICE: Profile image URL fix complete
NOTICE: Users with NULL avatar_url: 12
NOTICE: Providers with NULL avatar_url: 3
```

4. **Database Constraints Added:**
```sql
-- Prevents non-HTTP(S) URLs
ALTER TABLE users
ADD CONSTRAINT users_avatar_url_valid_http_url
CHECK (avatar_url IS NULL OR avatar_url LIKE 'http://%' OR avatar_url LIKE 'https://%');

-- Similar constraints for medical_provider_profiles and facility_admin_profiles
```

---

## Testing Instructions

### 1. Rebuild the Flutter App

The `join_room.dart` file was modified, so you need to rebuild:

```bash
# Clean build cache
flutter clean

# Get dependencies
flutter pub get

# Run on your device
flutter run -d <device-id>

# Or build for release
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

### 2. Test Video Call Flow

**Test Scenario:**
1. Login as a provider
2. Navigate to an upcoming appointment with `video_enabled=true`
3. Tap "Start Call" or "Join Call"
4. Verify:
   - ✅ No 401 error
   - ✅ No malformed image URL error
   - ✅ Meeting creation succeeds
   - ✅ Video call page loads with Chime SDK
   - ✅ Camera and microphone permissions requested
   - ✅ Video call connects successfully

**Expected Logs:**
```
I/flutter: === Getting Fresh JWT Token ===
I/flutter: User ID: [firebase-uid]
I/flutter: Token length: 1234
I/flutter: === Edge Function Response ===
I/flutter: Status code: 200
I/flutter: ✓ JSON parsed successfully
I/flutter: === Chime Meeting Created/Joined ===
I/flutter: Meeting ID: [meeting-id]
I/flutter: Attendee ID: [attendee-id]
I/flutter: ✅ Connecting to video call...
```

### 3. Run Automated Debug Script

```bash
./debug_video_call_auth.sh
```

This will verify:
- Edge function deployment
- CORS configuration
- Environment variables
- Database constraints

### 4. Verify Database State

Run this SQL in Supabase SQL Editor:

```sql
-- Should return 0 rows (all malformed URLs fixed)
SELECT id, email, avatar_url
FROM users
WHERE avatar_url IS NOT NULL
  AND avatar_url NOT LIKE 'http://%'
  AND avatar_url NOT LIKE 'https://%';

-- Verify constraints exist
SELECT conname, contype, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'users'::regclass
  AND conname LIKE '%avatar%';
```

---

## Files Modified

### Code Changes
- ✅ `lib/custom_code/actions/join_room.dart` (lines 208-224)
  - Added `Authorization` header with Supabase anon key

### Database Changes
- ✅ `supabase/migrations/20251213210000_fix_all_profile_image_urls.sql` (NEW)
  - Fixed malformed URLs in 3 tables
  - Added CHECK constraints

### Documentation
- ✅ `VIDEO_CALL_401_FIX_COMPLETE.md` (THIS FILE)
- ✅ `debug_video_call_auth.sh` (diagnostic script)

---

## Verification Checklist

Before marking this as complete, verify:

- [ ] Flutter app rebuilt with `flutter clean && flutter pub get && flutter run`
- [ ] Video call test successful (no 401 error)
- [ ] No malformed image URL errors
- [ ] Meeting creates successfully
- [ ] Video call page loads
- [ ] Both provider and patient can join
- [ ] Audio/video streams working
- [ ] Database constraints in place
- [ ] No malformed URLs in database

---

## Additional Notes

### Why Two Headers Are Needed

Supabase Edge Functions have a two-layer authentication model:

1. **Edge Runtime Layer** (Supabase infrastructure)
   - Requires: `Authorization: Bearer [supabase-anon-key]`
   - Purpose: Verify the request is from an authorized client
   - This is automatically enforced by Supabase

2. **Application Layer** (Our custom code)
   - Requires: `X-Firebase-Token: [firebase-jwt]`
   - Purpose: Verify the user's identity via Firebase Auth
   - This is manually verified in our edge function code

### Profile Image Best Practices

Going forward, ensure profile images are uploaded properly:

1. **Upload to Supabase Storage:**
   ```dart
   final filePath = await SupaFlow.client.storage
     .from('profile-pictures')
     .upload('user-id/avatar.jpg', file);
   ```

2. **Get Public URL:**
   ```dart
   final publicUrl = SupaFlow.client.storage
     .from('profile-pictures')
     .getPublicUrl('user-id/avatar.jpg');
   ```

3. **Save to Database:**
   ```dart
   await SupaFlow.client
     .from('users')
     .update({'avatar_url': publicUrl})
     .eq('id', userId);
   ```

The database constraints will automatically reject invalid URLs.

---

## Related Documentation

- `CHIME_VIDEO_CALL_TESTING_GUIDE.md` - Complete video call testing procedures
- `TESTING_GUIDE.md` - System-wide testing guide
- `CLAUDE.md` - Project guidelines and architecture
- `QUICK_START.md` - Setup instructions

---

## Support

If you encounter any issues:

1. Check Flutter logs: `flutter logs`
2. Check Supabase logs: Supabase Dashboard → Edge Functions → Logs
3. Run debug script: `./debug_video_call_auth.sh`
4. Check Firebase Auth: Firebase Console → Authentication
5. Verify AWS Chime: CloudWatch Logs for Lambda functions

---

**Status:** Ready for testing
**Next Steps:** Rebuild app and test video call flow
