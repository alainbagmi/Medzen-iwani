# Android Microphone Fix - January 12, 2026

## Problem
Video calls on Android were failing with microphone errors:
```
W/cr_media: Requires MODIFY_AUDIO_SETTINGS and RECORD_AUDIO. No audio device will be available for recording
E/chromium: [ERROR:audio_manager_android.cc(319)] Unable to select audio device!
NotReadableError: Could not start audio source
```

Despite Flutter showing microphone permission as granted, the WebView could not access the audio hardware.

## Root Cause
The `AndroidManifest.xml` was missing the `MODIFY_AUDIO_SETTINGS` permission. While `RECORD_AUDIO` was present, both permissions are required for WebView/Chrome to control audio settings like:
- Echo cancellation
- Noise suppression
- Auto gain control

These audio enhancements are essential for the AWS Chime SDK to function properly in video calls.

## Fix Applied
Added the missing permission to `android/app/src/main/AndroidManifest.xml:19`:

```xml
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

## Testing
After rebuilding the app:
1. Navigate to a video call
2. Microphone should now work properly (on device or emulator with mic passthrough)
3. No more "NotReadableError: Could not start audio source" errors
4. Audio settings (echo cancellation, etc.) should be properly controlled by Chime SDK

## Related Files
- `android/app/src/main/AndroidManifest.xml` - Updated with MODIFY_AUDIO_SETTINGS permission
- `lib/custom_code/widgets/chime_meeting_enhanced.dart` - Video call widget that uses microphone
- `lib/custom_code/actions/join_room.dart` - Video call initialization

## Notes
- This fix resolves the microphone issue on Android
- Camera issues on emulator are separate (requires AVD camera config: Webcam0)
- Both RECORD_AUDIO and MODIFY_AUDIO_SETTINGS are now properly declared
- This was a past fix that got lost - the permission needs to stay in the manifest
