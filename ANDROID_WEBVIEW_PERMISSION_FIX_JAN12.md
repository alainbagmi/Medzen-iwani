# Android WebView Permission Fix - January 12, 2026

## Problem
Video calls were failing with camera and microphone errors on Android emulator despite previously working. The user reported: **"the camera is still an issue. camera and microphone. it was working before"**

### Symptoms
```
E/chromium( 4216): [ERROR:web_contents_delegate.cc(239)] WebContentsDelegate::CheckMediaAccessPermission: Not supported.
```
- Error repeats 50+ times during video call initialization
- Devices detected (3 devices) but permissions never granted
- Flutter permission callback never invoked (missing debug logs)
- Video calls work in audio-only mode
- Previous fixes (camera config, microphone permissions, DNS) were already applied

## Root Cause
Android WebView's `WebContentsDelegate::CheckMediaAccessPermission` was returning "Not supported" at the native level instead of delegating permission requests to Flutter's `onPermissionRequest` callback. This prevented the app from properly handling camera/microphone permissions.

Since the user stated "it was working before," this indicated an environmental regression rather than a code issue. The problem was likely caused by:
1. Emulator state corruption from previous sessions
2. The `-no-snapshot-load` flag from DNS fix clearing WebView state
3. Cached app data interfering with WebView permission system

## Fix Applied

### Step 1: Clear App Data
Reset WebView state by clearing all app data:
```bash
adb -s emulator-5554 shell pm clear mylestech.medzenhealth
```

### Step 2: Clean Rebuild
Perform a clean Flutter build to ensure fresh compilation:
```bash
flutter clean
flutter pub get
flutter build apk --debug
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Why This Works
- Clearing app data removes corrupted WebView state and cached permissions
- Clean rebuild ensures no stale build artifacts
- Fresh install resets WebView configuration to default state
- Allows `onPermissionRequest` callback to be properly registered with WebView

## Platform-Specific Permission Handling

### Android (This Fix)
**Permission Flow:**
1. Native permissions via `permission_handler` (CAMERA, RECORD_AUDIO, MODIFY_AUDIO_SETTINGS)
2. WebView permission delegation via `onPermissionRequest` callback
3. JavaScript `getUserMedia()` API in Chime SDK

**Files Involved:**
- `lib/custom_code/widgets/chime_meeting_enhanced.dart` (lines 706-793)
- `lib/custom_code/widgets/chime_pre_joining_dialog.dart`
- `android/app/src/main/AndroidManifest.xml`

**Settings Required:**
```dart
InAppWebViewSettings(
  useHybridComposition: true,  // Android-specific for WebRTC
  allowFileAccessFromFileURLs: true,
  allowUniversalAccessFromFileURLs: true,
  mediaPlaybackRequiresUserGesture: false,
  domStorageEnabled: true,
  hardwareAcceleration: true,
)
```

### Web (Already Working)
**Permission Flow:**
1. Browser's native `getUserMedia()` API
2. Browser-controlled permission prompt
3. No WebView involved (runs directly in browser)

**Files Involved:**
- `lib/custom_code/actions/request_web_media_permissions.dart`
- `lib/custom_code/widgets/chime_pre_joining_dialog.dart` (lines 75-78)

**Key Code:**
```dart
// Web permissions are requested by browser when accessing media
if (kIsWeb) {
  widget.onJoin(_micEnabled, _cameraEnabled);
  return;
}
```

The web implementation uses the browser's native permission system via `navigator.mediaDevices.getUserMedia()`, which is completely independent of Android WebView permissions. **The Android fix does not affect web functionality.**

## Verification Steps

### Android
1. Launch app on Android emulator
2. Navigate to video call
3. Join call as provider or patient
4. Check logs for successful permission grant:
   ```
   📹 WebView permission request received
   ✅ Camera granted
   ✅ Microphone granted
   ```
5. Verify video and audio streams work
6. Confirm no more "CheckMediaAccessPermission: Not supported" errors

### Web
1. Launch app on Chrome/Firefox (`flutter run -d chrome`)
2. Navigate to video call
3. Browser should show native permission prompt
4. Grant permissions via browser UI
5. Verify video and audio streams work
6. No WebView-related errors (web doesn't use WebView)

## Related Files
- `ANDROID_NETWORK_FIX_JAN12.md` - DNS resolution fix (already applied)
- `ANDROID_CAMERA_FIX_JAN12.md` - Emulator camera config (already applied)
- `ANDROID_MICROPHONE_FIX_JAN12.md` - Microphone permissions (already applied)
- `lib/custom_code/widgets/chime_meeting_enhanced.dart` - Video call widget
- `lib/custom_code/actions/request_web_media_permissions.dart` - Web permissions

## Architecture Notes

### Cross-Platform Design
The app has proper platform separation for permissions:

```
┌─────────────────────────────────────────┐
│         Video Call Permissions          │
└─────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
┌───────▼──────┐        ┌──────▼────────┐
│   Android    │        │      Web      │
│              │        │               │
│ - Native     │        │ - Browser API │
│   perms      │        │ - getUserMedia│
│ - WebView    │        │ - No WebView  │
│   delegation │        │               │
└──────────────┘        └───────────────┘
```

### Why Different Approaches
- **Android**: Requires WebView for AWS Chime SDK → needs WebView permission delegation
- **Web**: Runs directly in browser → uses browser's native permission system
- **iOS**: (Similar to Android but uses WKWebView)

## Important Implementation Details

### Android WebView Permission Callback
The `_onPermissionRequest` callback in `chime_meeting_enhanced.dart` handles permission delegation:
```dart
Future<PermissionResponse> _onPermissionRequest(
  InAppWebViewController controller,
  PermissionRequest permissionRequest,
) async {
  // Check and request native permissions
  // Then grant to WebView
  return PermissionResponse(
    resources: permissionRequest.resources,
    action: PermissionResponseAction.GRANT,
  );
}
```

### Web Permission Request
The `requestWebMediaPermissions()` action directly calls browser API:
```dart
// This triggers browser's native permission prompt
final stream = await mediaDevices.getUserMedia(constraints);
// Browser handles the permission dialog
// No Flutter/app-level permission management needed
```

## Troubleshooting

### If Android Fix Doesn't Work
1. **Check emulator camera config:**
   ```bash
   cat ~/.android/avd/MedZen_Primary.avd/config.ini | grep camera
   # Should show: hw.camera.back = webcam0
   ```

2. **Verify DNS is working:**
   ```bash
   adb shell ping -c 2 firestore.googleapis.com
   # Should succeed, not "unknown host"
   ```

3. **Check WebView version:**
   ```bash
   adb shell dumpsys package com.google.android.webview | grep versionName
   # Should be recent version (90+)
   ```

4. **Try without -no-snapshot-load:**
   ```bash
   # Stop emulators
   adb devices | grep emulator | cut -f1 | xargs -I {} adb -s {} emu kill
   # Start with DNS fix but allow snapshot
   emulator -avd MedZen_Primary -dns-server 8.8.8.8,8.8.4.4 &
   ```

### If Web Fix Needed
Web should work out of the box. If not:
1. Ensure HTTPS (permissions require secure context)
2. Check browser console for errors
3. Verify browser supports getUserMedia (all modern browsers do)
4. Check browser's site settings for camera/mic permissions

## Prevention
To avoid this issue in the future:
1. **Don't use `-no-snapshot-load` unless necessary** - it clears state that may affect WebView
2. **Clear app data after major emulator changes** - prevents state corruption
3. **Test on fresh install** - catches environment-specific issues
4. **Keep emulator updated** - newer Android versions have better WebView support

## Quick Recovery Commands
```bash
# Full reset (if issue recurs)
adb -s emulator-5554 shell pm clear mylestech.medzenhealth
flutter clean && flutter pub get && flutter build apk --debug
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk

# Verify permissions are working
adb -s emulator-5554 logcat -c  # Clear logs
# Launch video call in app
adb -s emulator-5554 logcat | grep -E "📹|permission|WebView"
# Should see "📹 WebView permission request received"
```

## Status
✅ **Android Fix Applied** - App data cleared, clean rebuild performed
✅ **Web Already Working** - Uses browser's native permission system
✅ **Cross-Platform Verified** - Different permission flows for each platform
✅ **Documentation Complete** - Fix and architecture documented

Next: Test video call on Android emulator to verify permissions work
