# Android Camera Fix - January 12, 2026

## Problem
Video calls on Android emulator were failing with camera not found errors:
```
📹 Available devices: 0 cameras, 2 microphones
⚠️ Attempt 1 failed: NotFoundError Requested device not found
❌ Media permission request failed: NotFoundError Requested device not found
💡 To fix: AVD Manager → Edit → Camera → Set to "Webcam0" (not "Emulated")
```

The app was falling back to audio-only mode because no cameras were detected on the emulator.

## Root Cause
The Android emulator camera was configured to use `emulated` (virtual camera) which doesn't provide actual camera devices to WebView/Chrome. The emulator needs to be configured to use the host machine's webcam instead.

## Fix Applied
Updated the AVD configuration at `~/.android/avd/MedZen_Primary.avd/config.ini`:

**Before:**
```ini
hw.camera.back = emulated
hw.camera.front = none
```

**After:**
```ini
hw.camera.back = webcam0
hw.camera.front = webcam0
```

## Testing
After restarting the emulator and rebuilding the app:
1. Navigate to a video call
2. Camera should now be detected (should show 1-2 cameras instead of 0)
3. Video should display in the video call interface
4. No more "Camera unavailable" fallback messages
5. Both video and audio should work properly

## Related Files
- `~/.android/avd/MedZen_Primary.avd/config.ini` - AVD camera configuration
- `lib/custom_code/widgets/chime_meeting_enhanced.dart` - Video call widget that uses camera
- `lib/custom_code/actions/join_room.dart` - Video call initialization
- `ANDROID_MICROPHONE_FIX_JAN12.md` - Related microphone fix (already applied)

## Notes
- This fix enables the emulator to use your Mac's webcam for video calls
- Both front and back camera are configured to use webcam0
- The microphone fix from the previous session is still working correctly
- App permissions (CAMERA, RECORD_AUDIO, MODIFY_AUDIO_SETTINGS) are already properly configured in AndroidManifest.xml
- If you have multiple emulators, you may need to apply the same fix to other AVDs

## Alternative Camera Options
If `webcam0` doesn't work, you can try:
- `virtualscene` - Uses a virtual 3D environment scene
- `emulated` - Virtual camera (limited functionality, may not work with WebView)

## Verification Steps
1. Start video call in the app
2. Check WebView console for camera detection: "📹 Available devices: X cameras, Y microphones"
3. Verify X > 0 (at least one camera detected)
4. Confirm video stream displays in the video call UI
5. Test both video and audio functionality
