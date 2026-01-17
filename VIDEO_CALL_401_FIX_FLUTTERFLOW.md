# Video Call 401 Error Fix (FlutterFlow UI)

## Problem
Video calls fail with 401 Unauthorized error when testing in FlutterFlow:
```json
{
  "event_message": "POST | 401 | https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token"
}
```

The edge function logs show: `"Missing X-Firebase-Token header"`

## Root Cause
The `X-Firebase-Token` header (containing the Firebase JWT) is not being sent with the HTTP request. This happens when:

1. **User is not logged in** - Firebase Auth returns null
2. **Stale code cache** - FlutterFlow is running old code version
3. **Firebase Auth not initialized** - Auth initialization failed in main.dart
4. **Code path issue** - A different code path is executing

## Solution Steps

### Step 1: Verify User is Logged In

**In FlutterFlow:**
1. Go to your login page
2. Ensure you're successfully logged in BEFORE testing video calls
3. Check Firebase Auth state:
   - Add a Text widget showing: `currentUser.displayName` or `currentUser.email`
   - If it shows "null", you're not logged in

**Debug Code (add to join_room.dart before line 199):**
```dart
debugPrint('🔍 Firebase Auth Status:');
debugPrint('  Current user: ${FirebaseAuth.instance.currentUser?.email ?? "NOT LOGGED IN"}');
debugPrint('  User ID: ${FirebaseAuth.instance.currentUser?.uid ?? "NULL"}');
```

### Step 2: Clear Cache and Rebuild

**FlutterFlow has aggressive caching. You MUST do a full rebuild:**

1. **In FlutterFlow UI:**
   - Settings → Developer → Clear Build Cache
   - Settings → Developer → Clear Asset Cache

2. **Stop the running app completely**
   - Don't just refresh
   - Force close the app

3. **Rebuild from scratch:**
   - Click "Run" or "Test" again
   - Wait for full build (not hot reload)

**Alternative (Command Line):**
```bash
flutter clean
flutter pub get
flutter run
```

### Step 3: Verify Code Version

**Check if your local code has the latest changes:**

1. Open `lib/custom_code/actions/join_room.dart`
2. Go to line ~253 (search for `X-Firebase-Token`)
3. Verify this line exists:
   ```dart
   'X-Firebase-Token': userToken,
   ```

4. If it's missing, you have old code. Re-export from FlutterFlow or pull latest changes.

### Step 4: Check Firebase Initialization Order

**Critical:** Firebase must be initialized BEFORE the app tries to get the current user.

1. Open `lib/main.dart`
2. Verify this initialization order (lines 22-37):
   ```dart
   await Firebase.initializeApp();  // FIRST
   await authManager.initialize();  // SECOND
   await FFAppState.initialize();   // THIRD
   ```

3. If order is different, Firebase Auth will not work properly.

### Step 5: Test with Enhanced Logging

I've added enhanced logging to `join_room.dart`. When you run the video call now, you'll see:

```
=== Token Debug ===
User ID: abc123...
User email: test@example.com
Token length: 847
Token first 50 chars: eyJhbGciOiJSUzI1NiIsImtpZCI6Ijk5MzQ3...
==================

=== Request Headers Debug ===
Content-Type: application/json
apikey: eyJhbGciOiJIUzI1NiIs...
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
X-Firebase-Token: eyJhbGciOiJSUzI1NiIsImtpZCI6Ijk5MzQ3...
X-Firebase-Token length: 847
==============================
```

**If you see:**
- ✅ `Token length: 847` → Token is present, good
- ❌ `Token length: 0` → Token is empty, user not authenticated
- ❌ `X-Firebase-Token: null` → Token not set, Firebase Auth failed

### Step 6: Manual Test

Run the diagnostic script:
```bash
./test_video_call_auth_flutterflow.sh
```

This will:
- Test the edge function endpoint
- Check recent logs
- Provide specific troubleshooting steps

## Common Scenarios & Fixes

### Scenario 1: User Not Logged In
**Symptoms:**
- Console shows: `User not authenticated`
- Or: `Failed to get authentication token`

**Fix:**
1. Ensure login flow completes successfully
2. Check that `FirebaseAuth.instance.currentUser` is not null
3. Verify Firebase configuration in `firebase_options.dart`

### Scenario 2: Stale FlutterFlow Cache
**Symptoms:**
- Code looks correct in IDE
- But error persists
- "It works in VS Code but not FlutterFlow"

**Fix:**
1. Clear ALL caches (see Step 2)
2. Close FlutterFlow completely
3. Reopen project
4. Full rebuild (not hot reload)

### Scenario 3: Wrong Code Version
**Symptoms:**
- `join_room.dart` doesn't have `X-Firebase-Token` on line ~253
- Code looks different than expected

**Fix:**
1. Export latest project from FlutterFlow
2. Compare exported code with your local version
3. Merge changes if needed
4. Re-import to FlutterFlow if necessary

### Scenario 4: Firebase Config Issue
**Symptoms:**
- `FirebaseAuth.instance.currentUser` is always null
- Login appears to work but user is not persisted

**Fix:**
1. Verify `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are present
2. Check Firebase project ID matches in FlutterFlow settings
3. Verify Firebase initialization in `main.dart`

## Verification Checklist

Before testing video calls, verify:

- [ ] ✅ User is logged in (check `currentUser.email` in UI)
- [ ] ✅ Firebase Auth initialized in `main.dart` (line 22-24)
- [ ] ✅ Code has latest changes (`X-Firebase-Token` on line ~253 in join_room.dart)
- [ ] ✅ Full rebuild completed (not hot reload)
- [ ] ✅ FlutterFlow cache cleared
- [ ] ✅ App completely restarted
- [ ] ✅ Appointment ID is valid
- [ ] ✅ User is provider or patient for the appointment

## Testing in FlutterFlow

### FlutterFlow Test Mode
1. Click "Test" in FlutterFlow UI
2. **IMPORTANT:** Login FIRST before joining a call
3. Navigate to Join Call page
4. Click "Start Call" or "Join Call"
5. Check console/logs for debug output

### FlutterFlow Run Mode (Recommended)
1. Export project from FlutterFlow
2. Open in VS Code or Android Studio
3. Run: `flutter run -d chrome` (or specific device)
4. This gives you full console access to see all debug logs

## What Success Looks Like

When working correctly, you'll see in the logs:
```
=== Token Debug ===
User ID: abc123...
User email: provider@example.com
Token length: 847
==================

=== Request Headers Debug ===
X-Firebase-Token length: 847
==============================

=== Edge Function Response ===
Status code: 200
Response body: {"meeting":{"MeetingId":"..."},"attendee":{"AttendeeId":"..."}}
==============================

✅ Connecting to video call...
```

## Still Not Working?

1. **Check edge function logs:**
   ```bash
   npx supabase functions logs chime-meeting-token --limit 10
   ```

2. **Verify edge function is deployed:**
   ```bash
   npx supabase functions list
   ```

3. **Test edge function directly:**
   ```bash
   ./test_video_call_auth_flutterflow.sh
   ```

4. **Check Firebase Auth in FlutterFlow:**
   - FlutterFlow Settings → Authentication → Firebase
   - Verify Firebase project is linked
   - Check that Firebase Auth is enabled

5. **Check network connectivity:**
   - Ensure device/emulator has internet access
   - Verify Supabase URL is reachable

## Contact Support

If issue persists after trying all steps:
1. Export logs from FlutterFlow (Console output)
2. Run `./test_video_call_auth_flutterflow.sh` and save output
3. Provide both to support team with:
   - FlutterFlow version
   - Device/emulator type
   - Steps to reproduce

## Files Modified

1. `lib/custom_code/actions/join_room.dart` - Enhanced logging (lines 214-264)
2. `test_video_call_auth_flutterflow.sh` - New diagnostic script
3. `VIDEO_CALL_401_FIX_FLUTTERFLOW.md` - This troubleshooting guide
