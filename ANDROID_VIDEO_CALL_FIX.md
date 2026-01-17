# Android Video Call Audio Fix - COMPLETE

## Issue Summary

Video calls were failing with "Could not start audio source" error on Android due to missing `MODIFY_AUDIO_SETTINGS` permission in AndroidManifest.xml.

## Changes Made

### 1. Updated AndroidManifest.xml

**File:** `android/app/src/main/AndroidManifest.xml`

**Added Permissions:**
```xml
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

**Added Hardware Features (not required for emulator compatibility):**
```xml
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
<uses-feature android:name="android.hardware.microphone" android:required="false" />
```

### 2. Complete Permission List for Video Calls

The app now has all required permissions:
- ✅ `INTERNET` - Network communication
- ✅ `CAMERA` - Video capture
- ✅ `RECORD_AUDIO` - Audio capture
- ✅ `MODIFY_AUDIO_SETTINGS` - Audio device control (NEWLY ADDED)

## Testing Instructions

### Option 1: Test on Real Android Device (RECOMMENDED)

1. **Build and install:**
   ```bash
   flutter run -d <device-id>
   ```

2. **Grant permissions when prompted:**
   - Camera permission
   - Microphone permission

3. **Join a video call:**
   - Navigate to an appointment
   - Click "Join Video Call"
   - Should work without audio errors

### Option 2: Test on Android Emulator

**⚠️ IMPORTANT:** Android emulator requires special configuration for camera/audio.

#### Configure Emulator Camera

1. **Stop the emulator if running**

2. **Edit emulator config:**
   ```bash
   # Find your emulator
   emulator -list-avds

   # Edit the config file (replace <emulator-name> with your AVD name)
   nano ~/.android/avd/<emulator-name>.avd/config.ini
   ```

3. **Add/modify these lines:**
   ```ini
   hw.camera.back=emulated
   hw.camera.front=emulated
   hw.audioInput=yes
   hw.audioOutput=yes
   ```

4. **Start emulator with camera:**
   ```bash
   emulator -avd <emulator-name> -camera-back emulated -camera-front emulated
   ```

#### Alternative: Create New Emulator with Camera

1. **Open Android Studio → Device Manager**

2. **Create new Virtual Device:**
   - Select hardware (e.g., Pixel 6)
   - Select system image
   - **In "Verify Configuration":**
     - Camera: Front = Emulated, Back = Emulated
     - Enable "Device Frame"
   - Finish

3. **Run app on new emulator:**
   ```bash
   flutter devices
   flutter run -d <emulator-id>
   ```

### Option 3: Use Physical Android Device via WiFi

1. **Enable WiFi debugging on phone:**
   - Settings → Developer Options → Wireless debugging → ON
   - Tap "Wireless debugging" → "Pair device with pairing code"

2. **Connect from computer:**
   ```bash
   adb pair <ip>:<port>  # Use IP and port from phone
   adb connect <ip>:5555
   ```

3. **Run app:**
   ```bash
   flutter devices
   flutter run -d <device-id>
   ```

## Expected Behavior After Fix

### Before Fix:
```
W/cr_media(13840): Requires MODIFY_AUDIO_SETTINGS and RECORD_AUDIO.
                   No audio device will be available for recording
E/chromium(13840): [ERROR:audio_manager_android.cc(319)] Unable to select audio device!
I/flutter: 🌐 JS: ERROR: ❌ Error: Could not start audio source
I/flutter: 📱 Message from WebView: JOIN_ERROR:Could not start audio source
```

### After Fix:
```
I/flutter: ✅ Chime SDK loaded and ready
I/flutter: === Starting Chime Meeting Join ===
I/chromium: [INFO] ChimeMeeting - API/DefaultAudioVideoFacade/.../addObserver
I/flutter: 📱 Message from WebView: MEETING_STARTED
I/flutter: ✅ Audio and video streams active
```

## Rebuild and Test

```bash
# 1. Clean previous build
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Rebuild app
flutter build apk --debug  # For testing

# OR run directly
flutter run

# 4. Test video call
# - Create/join appointment
# - Click "Join Video Call"
# - Verify audio/video works
```

## Troubleshooting

### Issue: Still getting audio errors on emulator

**Solution:** Emulator may not support full audio I/O. Use a real device for testing.

### Issue: Camera errors on emulator

**Solution:**
1. Configure emulator camera (see above)
2. Or test on real device

### Issue: Permissions denied

**Solution:**
```bash
# Uninstall app completely
adb uninstall mylestech.medzenhealth

# Reinstall
flutter run
```

### Issue: App crashes on startup

**Solution:**
```bash
# Check logs
adb logcat | grep -E "flutter|chromium|VideoCapture"

# Clean and rebuild
flutter clean && flutter pub get && flutter run
```

## Verification Checklist

- [ ] App builds successfully
- [ ] No manifest merge errors
- [ ] Camera permission requested at runtime
- [ ] Microphone permission requested at runtime
- [ ] Video call page loads
- [ ] No "Could not start audio source" error
- [ ] Audio is captured (check with another participant)
- [ ] Video is captured (check with another participant)

## Next Steps

1. **Test on real Android device** (most reliable)
2. **Test video call end-to-end** with another user
3. **Verify audio quality** during call
4. **Verify video quality** during call
5. **Test on different Android versions** (API 21+)

## Files Changed

- `android/app/src/main/AndroidManifest.xml` - Added MODIFY_AUDIO_SETTINGS permission and hardware features

## Commit Message

```
fix: Add MODIFY_AUDIO_SETTINGS permission for Android video calls

- Add missing MODIFY_AUDIO_SETTINGS permission to AndroidManifest.xml
- Add camera and microphone hardware features (not required)
- Fixes "Could not start audio source" error in Chime SDK
- Enables proper audio device selection for WebView/Chromium
```

## References

- [Android Permissions Documentation](https://developer.android.com/reference/android/Manifest.permission)
- [WebRTC on Android](https://webrtc.org/getting-started/android)
- [Chime SDK for JavaScript](https://aws.github.io/amazon-chime-sdk-js/)
- Error log: `E/chromium: [ERROR:audio_manager_android.cc(319)] Unable to select audio device!`
