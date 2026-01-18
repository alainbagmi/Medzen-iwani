# Firebase Auth Emulator Fix Guide

## Problem Resolved
Fixed Firebase reCAPTCHA network errors preventing login on Android emulators:
- ❌ `E/RecaptchaCallWrapper: Initial task failed for action RecaptchaAction(action=signInWithPassword) with exception - A network error`
- ❌ `W/LocalRequestInterceptor: Error getting App Check token`

## What Was Fixed

### 1. **Network Security Configuration**
- Created `android/app/src/main/res/xml/network_security_config.xml`
- Allows HTTPS traffic to Firebase and reCAPTCHA services
- Explicitly allows: `firebaseapp.com`, `googleapis.com`, `recaptcha.net`, `identitytoolkit.googleapis.com`

### 2. **Disabled reCAPTCHA for Testing**
- Modified `lib/auth/firebase_auth/email_auth.dart`
- Added `setAppVerificationDisabledForTesting(true)` in debug mode
- Prevents reCAPTCHA network verification on emulators
- Only applies in `kDebugMode` - production unaffected

## How to Test

### Clean Build for Fresh Start
```bash
flutter clean
flutter pub get
```

### Rebuild on Android Emulator
```bash
# Start emulator(s) first if not already running
flutter emulators launch emulator-5554
# Or for second emulator: flutter emulators launch emulator-5556

# Run app with clean rebuild
flutter run -d emulator-5554 --no-fast-start
```

### Test Login
1. **Sign In/Register** - Try email and password authentication
2. **Monitor Logs** - You should NO LONGER see:
   - `E/RecaptchaCallWrapper` errors
   - Network timeouts for reCAPTCHA
3. **Success Indicator** - Login completes and you see:
   - App initializes normally
   - No "network error" messages
   - `I/flutter: FCM: User signed out` (if logged out after test)

## Both Emulators
These fixes apply to both emulators:
- `emulator-5554` (port 61753)
- `emulator-5556` (port 61754)

Run on both with:
```bash
flutter run -d emulator-5554
flutter run -d emulator-5556  # In another terminal
```

## Technical Details

### reCAPTCHA Disabled Only in Debug
```dart
if (kDebugMode) {
  await FirebaseAuth.instance.setAppVerificationDisabledForTesting(true);
}
```
- Release builds (production) still use reCAPTCHA
- Testing flag prevents unnecessary verification on emulators
- Catches exceptions for platforms that don't support it (web)

### Network Config Applied
- Allows cleartext to localhost (10.0.2.2, 127.0.0.1)
- Enforces HTTPS for all external services
- Referenced in `AndroidManifest.xml` via `android:networkSecurityConfig`

## Troubleshooting

### Still Getting Network Errors?
1. Ensure you rebuilt after pulling code: `flutter clean && flutter pub get`
2. Restart emulator: `flutter emulators launch emulator-5554`
3. Check adb connectivity: `adb devices`
4. Verify Firebase config is correct in `lib/backend/firebase/firebase_config.dart`

### "No AppCheckProvider Installed" Warning
This is **expected and not an error**:
- Development/testing uses placeholder App Check tokens
- Production deployment will have real App Check
- Safe to ignore in debug mode

### Still Can't Login After Fix?
Check that:
- Emulator has internet access (DNS working)
- Firewall not blocking HTTPS traffic
- Firebase project credentials are correct
- Try manual emulator reset: `emulator -avd emulator-5554 -wipe-data`

## What's Next

After confirming login works:
1. ✅ Three critical fixes previously applied (SDK CORS, End Call button, dialog layout)
2. ✅ Malformed image URL database cleanup migration
3. ✅ Firebase reCAPTCHA/auth network fix

You can now:
- Test video calls with authentication working
- Verify SOAP form performance improvements
- Test post-call clinical notes workflow

## Summary of Changes

| File | Change | Purpose |
|------|--------|---------|
| `android/app/src/main/res/xml/network_security_config.xml` | Created | Allow HTTPS Firebase traffic |
| `android/app/src/main/AndroidManifest.xml` | Updated | Reference network security config |
| `lib/auth/firebase_auth/email_auth.dart` | Updated | Disable reCAPTCHA in debug mode |
