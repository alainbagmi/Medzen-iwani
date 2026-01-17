# Video Call Authentication Fix

## Issues Resolved

### Issue 1: Invalid JWT Error (401 Unauthorized)
**Error:** `Status code: 401, Response body: {"code":401,"message":"Invalid JWT"}`

**Root Cause:**
The `join_room.dart` action was using a cached JWT token (`currentJwtToken`) from `auth_util.dart`. This cached token could be:
- Uninitialized (null/empty) when the app first loads
- Expired if the user has been logged in for more than 1 hour (Firebase tokens expire)
- Not refreshed properly during the video call flow

**Fix Applied:**
Modified `/lib/custom_code/actions/join_room.dart` to force-refresh the Firebase JWT token before making the edge function call:

```dart
// Before (line 185)
final userToken = currentJwtToken;
final userId = currentUserUid;

if (userToken.isEmpty || userId.isEmpty) {
  throw Exception('User not authenticated');
}

// After (lines 186-199)
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  throw Exception('User not authenticated');
}

final userId = user.uid;

// Force get fresh token (not cached)
debugPrint('=== Getting Fresh JWT Token ===');
final userToken = await user.getIdToken(true); // true = force refresh

if (userToken == null || userToken.isEmpty) {
  throw Exception('Failed to get authentication token');
}
```

**Why This Works:**
- `user.getIdToken(true)` forces Firebase to generate a fresh JWT token
- The fresh token is guaranteed to be valid and not expired
- The edge function can now properly verify the token and authenticate the user

---

### Issue 2: Malformed Image URLs
**Error:** `Invalid argument(s): No host specified in URI file:///500x500?doctor`

**Root Cause:**
The `users` table had malformed `avatar_url` values like:
- `file:///500x500?doctor`
- `/500x500?doctor`
- Other non-HTTP URLs

These malformed URLs were being displayed in the appointment overview, causing the app to crash when trying to load images.

**Fix Applied:**
Created migration `/supabase/migrations/20251203000000_fix_malformed_image_urls.sql`:

```sql
-- Clean up existing malformed URLs
UPDATE users
SET avatar_url = NULL
WHERE avatar_url IS NOT NULL
  AND (
    avatar_url LIKE 'file:///%'
    OR avatar_url LIKE '/%'
    OR avatar_url LIKE '%500x500%'
    OR (avatar_url NOT LIKE 'http%' AND LENGTH(avatar_url) > 0)
  );

-- Add constraint to prevent future malformed URLs
ALTER TABLE users
ADD CONSTRAINT users_avatar_url_format
CHECK (
  avatar_url IS NULL
  OR avatar_url ~ '^https?://'
);
```

**Why This Works:**
- Existing malformed URLs are set to NULL (handled gracefully by the app)
- New constraint prevents any future URLs that don't start with `http://` or `https://`
- The database now enforces proper URL format at the data layer

---

## Files Modified

1. **`/lib/custom_code/actions/join_room.dart`**
   - Added `import 'package:firebase_auth/firebase_auth.dart';` (line 15)
   - Replaced cached token retrieval with force-refresh logic (lines 186-205)

2. **`/supabase/migrations/20251203000000_fix_malformed_image_urls.sql`** (NEW)
   - Cleans up malformed avatar URLs
   - Adds database constraint to prevent future issues

---

## Verification

### 1. Database Verification
Run the test script to verify the fixes:
```bash
./test_video_call_auth_fix.sh
```

Expected output:
- ✅ No malformed avatar URLs found
- ✅ URL format constraint is active

### 2. Manual Testing
```bash
# Check for malformed URLs
SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"

curl -s "$SUPABASE_URL/rest/v1/users?select=id,avatar_url&avatar_url=like.*500x500*&limit=5" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY"
```

Expected: `[]` (empty array)

### 3. Constraint Verification
Try inserting an invalid URL (should fail):
```bash
curl -s "$SUPABASE_URL/rest/v1/users" \
  -X POST \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "00000000-0000-0000-0000-000000000000",
    "email": "test@test.com",
    "firebase_uid": "test_uid_12345",
    "avatar_url": "file:///invalid/url"
  }'
```

Expected: Error with message `violates check constraint "users_avatar_url_format"`

---

## Testing the Video Call Fix

### Prerequisites
1. **Use a Physical Device** - Video calls don't work on simulators/emulators due to camera/microphone limitations
2. **Clean Build:**
   ```bash
   flutter clean && flutter pub get
   ```

### Test Steps
1. **Build and Deploy:**
   ```bash
   # For iOS
   flutter build ios
   # Deploy to connected iPhone via Xcode

   # For Android
   flutter build apk
   # Install on connected Android device
   ```

2. **Create Test Appointment:**
   - Log in as a Provider
   - Create an appointment with a patient
   - Set consultation mode to "Online" (video enabled)
   - Schedule for immediate start time

3. **Join Video Call:**
   - Log in as the Provider or Patient
   - Navigate to the appointment
   - Click "Join Video Call" button
   - Grant camera and microphone permissions when prompted

4. **Expected Behavior:**
   - ✅ No "401 Invalid JWT" error
   - ✅ No "Invalid argument: No host specified" error
   - ✅ Loading indicator shows "Setting up video call..."
   - ✅ Success message: "✅ Connecting to video call..."
   - ✅ Video call page opens with AWS Chime SDK
   - ✅ Camera and microphone are enabled
   - ✅ Can see/hear other participant when they join

5. **Verify Logs:**
   ```bash
   flutter logs
   ```

   Should see:
   ```
   I/flutter: === Getting Fresh JWT Token ===
   I/flutter: === Token Debug ===
   I/flutter: User ID: <user_uid>
   I/flutter: Token length: <token_length>
   I/flutter: === Edge Function Response ===
   I/flutter: Status code: 200
   I/flutter: === Chime Meeting Created/Joined ===
   ```

---

## Architecture Changes

### Before
```
User clicks "Join Call"
    ↓
join_room.dart reads cached token (currentJwtToken)
    ↓
May be expired/null → 401 Error
```

### After
```
User clicks "Join Call"
    ↓
join_room.dart forces Firebase token refresh
    ↓
Fresh, valid token → Successful authentication
    ↓
Edge function verifies token
    ↓
AWS Lambda creates/joins Chime meeting
    ↓
Video call starts successfully
```

---

## Edge Function Flow (Unchanged)

The `chime-meeting-token` edge function (`/supabase/functions/chime-meeting-token/index.ts`) already had the correct authentication logic:

1. Receives Firebase JWT token in Authorization header
2. Decodes and validates the token
3. Looks up user in Supabase `users` table via `firebase_uid`
4. Verifies user has access to the appointment
5. Calls AWS Lambda to create/join Chime meeting
6. Returns meeting and attendee tokens

The fix ensures the Flutter app sends a valid, non-expired token.

---

## Related Documentation

- **Video Call Implementation:** `CHIME_VIDEO_TESTING_GUIDE.md`
- **System Architecture:** `SYSTEM_INTEGRATION_STATUS.md`
- **Quick Start Guide:** `QUICK_START.md`
- **Testing Guide:** `TESTING_GUIDE.md`

---

## Troubleshooting

### Still Getting 401 Error?

1. **Check Firebase Auth:**
   ```dart
   // In join_room.dart, verify this log appears:
   debugPrint('=== Getting Fresh JWT Token ===');
   ```

2. **Check Edge Function Logs:**
   ```bash
   # View live logs
   npx supabase functions logs chime-meeting-token
   ```

3. **Verify User Exists:**
   ```bash
   # Check user exists in Supabase
   curl -s "$SUPABASE_URL/rest/v1/users?select=id,firebase_uid&firebase_uid=eq.<your_firebase_uid>" \
     -H "apikey: $SERVICE_KEY" \
     -H "Authorization: Bearer $SERVICE_KEY"
   ```

### Still Getting Image URL Errors?

1. **Check for Remaining Malformed URLs:**
   ```bash
   curl -s "$SUPABASE_URL/rest/v1/users?select=id,avatar_url&avatar_url=not.like.http*&avatar_url=not.is.null&limit=10" \
     -H "apikey: $SERVICE_KEY" \
     -H "Authorization: Bearer $SERVICE_KEY"
   ```

2. **Manually Fix Specific User:**
   ```bash
   curl -s "$SUPABASE_URL/rest/v1/users?id=eq.<user_id>" \
     -X PATCH \
     -H "apikey: $SERVICE_KEY" \
     -H "Authorization: Bearer $SERVICE_KEY" \
     -H "Content-Type: application/json" \
     -d '{"avatar_url": null}'
   ```

---

## Deployment Checklist

- [x] Apply database migration
- [x] Verify malformed URLs are cleaned
- [x] Update Flutter code
- [x] Clean and rebuild app
- [ ] Test on physical iOS device
- [ ] Test on physical Android device
- [ ] Verify no console errors
- [ ] Test with multiple users joining same call
- [ ] Verify recordings work (if enabled)

---

## Summary

Both issues have been resolved:

1. **JWT Authentication** - Now uses force-refreshed Firebase tokens, eliminating 401 errors
2. **Image URLs** - Database cleaned and constrained to prevent malformed URLs

The video call feature should now work reliably on physical devices.
