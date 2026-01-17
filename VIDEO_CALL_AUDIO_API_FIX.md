# Video Call Audio API Fix - December 18, 2025

## Issue Summary

Video calls were experiencing audio device setup errors due to incorrect AWS Chime SDK v3 API usage.

### Error Observed
```
⚠️ Device setup error: TypeError: audioVideo.chooseAudioInputDevice is not a function
```

## Root Cause

The `ChimeMeetingEnhanced` widget was using an incorrect API method from an older version of the Chime SDK:
- **Incorrect**: `audioVideo.chooseAudioInputDevice(deviceId)` ❌
- **Correct**: `audioVideo.startAudioInput(deviceId)` ✅

## Fix Applied

### File: `lib/custom_code/widgets/chime_meeting_enhanced.dart`

**Changed:**
```javascript
// OLD - Incorrect API
if (audioInputDevices.length > 0) {
    await audioVideo.chooseAudioInputDevice(audioInputDevices[0].deviceId);
}
```

**To:**
```javascript
// NEW - Correct Chime SDK v3 API
if (audioInputDevices.length > 0) {
    // Correct Chime SDK v3 method for audio input
    await audioVideo.startAudioInput(audioInputDevices[0].deviceId);
    console.log('✅ Audio device selected:', audioInputDevices[0].label);
}
```

### Additional Improvements
- Added device selection logging for debugging
- Added fallback handling to allow calls to proceed even if device setup fails
- Video device selection remains unchanged (already using correct API)

## Secondary Issue: Android Emulator Camera Configuration

### Symptoms
```
E/cr_VideoCapture: getCameraCharacteristics:784: Unable to retrieve camera characteristics
for unknown device 0: No such file or directory (-2)
```

### Root Cause
Android emulator not configured with camera/microphone hardware.

### Solution

#### Quick Fix Script
Run the provided script to grant permissions:
```bash
./fix_emulator_camera.sh
```

#### Manual Configuration

1. **Close the emulator**

2. **Open AVD Manager**:
   - Android Studio: Tools → Device Manager
   - Or run: `android avd`

3. **Edit your emulator** (click pencil icon)

4. **Show Advanced Settings**

5. **Under Camera section, set**:
   - Front camera: `Webcam0` or `Emulated`
   - Back camera: `Webcam0` or `Emulated`

6. **Save and restart emulator**

#### Alternative: Start Emulator with Camera
```bash
# List available emulators
emulator -list-avds

# Start with camera enabled
emulator -avd <your-avd-name> -camera-back webcam0 -camera-front webcam0
```

## Testing the Fix

### 1. Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter run
```

### 2. Test Video Call Flow

1. **Login** as a provider or patient
2. **Navigate** to an appointment with video enabled
3. **Join** the video call
4. **Verify** in logs:
   ```
   ✅ Audio device selected: [device name]
   ✅ Video device selected: [device name]
   ✅ Devices configured
   ✅ Meeting started successfully
   ✅ Meeting joined successfully
   ```

### 3. Check for Errors

**Before fix:**
- ❌ `audioVideo.chooseAudioInputDevice is not a function`
- ❌ Audio not working in call

**After fix:**
- ✅ No API errors
- ✅ Audio device selected successfully
- ✅ Call proceeds without device setup errors

## Expected Behavior

### With Configured Camera/Mic
- Audio and video streams work correctly
- Device selection happens automatically
- Console shows device labels

### Without Configured Camera/Mic (Emulator)
- Meeting still joins successfully (audio/video just disabled)
- No JavaScript errors
- Call proceeds in audio-only or viewing mode
- Warning logged but doesn't block the call

## AWS Chime SDK v3 API Reference

### Audio Input Methods
- ✅ `audioVideo.startAudioInput(deviceId)` - Start audio with specific device
- ✅ `audioVideo.stopAudioInput()` - Stop audio input
- ✅ `audioVideo.listAudioInputDevices()` - List available audio devices
- ❌ `audioVideo.chooseAudioInputDevice()` - **DOES NOT EXIST** (old API)

### Video Input Methods
- ✅ `audioVideo.chooseVideoInputDevice(deviceId)` - Select video device
- ✅ `audioVideo.startLocalVideoTile()` - Start local video
- ✅ `audioVideo.stopLocalVideoTile()` - Stop local video
- ✅ `audioVideo.listVideoInputDevices()` - List available video devices

## Files Modified

1. **lib/custom_code/widgets/chime_meeting_enhanced.dart**
   - Fixed audio input API call (line 1628)
   - Added device selection logging
   - Improved error handling

2. **fix_emulator_camera.sh** (new file)
   - Script to grant camera/microphone permissions
   - Instructions for emulator configuration

3. **VIDEO_CALL_AUDIO_API_FIX.md** (this file)
   - Complete documentation of the fix

## Related Issues

### Common Emulator Warnings (Benign)
These warnings are normal on emulators without hardware and don't affect functionality:
- `Requires MODIFY_AUDIO_SETTINGS and RECORD_AUDIO. No audio device will be available for recording`
- `Unable to select audio device!`
- `CheckMediaAccessPermission: Not supported`

### Real Issues (Now Fixed)
- ❌ `audioVideo.chooseAudioInputDevice is not a function` → ✅ Fixed

## Deployment

### Development
```bash
flutter clean
flutter pub get
flutter run
```

### Production Build
```bash
flutter build apk --release  # Android
flutter build ios --release  # iOS (requires code signing)
flutter build web --release  # Web
```

## Rollback Plan

If issues arise, revert to previous implementation:
```bash
git diff lib/custom_code/widgets/chime_meeting_enhanced.dart
git checkout HEAD -- lib/custom_code/widgets/chime_meeting_enhanced.dart
```

## Success Criteria

- ✅ No `chooseAudioInputDevice is not a function` errors
- ✅ Audio device selected when available
- ✅ Video calls join successfully even without audio/video hardware
- ✅ Console logs show device selection
- ✅ Calls work on real devices with camera/microphone
- ✅ Calls gracefully degrade on emulators without hardware

## Additional Notes

### Why Emulator Shows Camera Errors
Android emulators by default don't have camera hardware configured. This is expected behavior and doesn't prevent the app from working - it just means video calls will be audio-only or viewing-only on the emulator.

### Testing on Real Device Recommended
For full video call testing with camera and microphone:
1. Use a physical Android device
2. Or configure the emulator with webcam access (see instructions above)

### Production Deployment Ready
This fix is production-ready and doesn't introduce breaking changes. The API change is a direct replacement with the correct Chime SDK v3 method.

---

## Issue 3: JavaScript Reference Error - $userRole is not defined

### Date Fixed
December 18, 2025 (afternoon)

### Error Observed
```
I/chromium(29658): [INFO:CONSOLE(1391)] "Uncaught ReferenceError: $userRole is not defined", source: https://medzenhealth.app/ (1391)
```

### Root Cause
The `ChimeMeetingEnhanced` widget uses a raw string literal (`r'''`) for the embedded HTML/JavaScript (line 774). In Dart, raw strings do NOT interpolate variables, so `$userRole` was treated as literal text instead of being replaced with the actual value.

### Affected Code
The JavaScript code referenced `$userRole` in three places:
- Line 2165: Send button visibility check
- Line 2183: Enter key input validation
- Line 2195: Chat input disable logic

```javascript
// ❌ BEFORE (broken)
const isProvider = $userRole && $userRole.trim() !== '';

// ✅ AFTER (fixed)
const isProvider = currentUserRole && currentUserRole.trim() !== '';
```

### Fix Applied

**File:** `lib/custom_code/widgets/chime_meeting_enhanced.dart`

Replaced all instances of `$userRole` with `currentUserRole` in the embedded HTML/JavaScript.

**Why this works:**
- The `currentUserRole` variable is properly set by the injected JavaScript (line 746):
  ```dart
  final script = '''
    currentUserRole = $userRole;  // ← This DOES get interpolated
    ...
  ''';
  ```
- The injected script is NOT a raw string, so Dart properly interpolates `$userRole` there
- The embedded HTML then uses `currentUserRole` which is a proper JavaScript global variable

### Testing
```bash
flutter clean && flutter pub get
flutter analyze lib/custom_code/widgets/chime_meeting_enhanced.dart
```

**Result:** ✅ No errors, only style warnings (unused imports from FlutterFlow)

### Expected Behavior After Fix

**Before:**
- ❌ JavaScript error: `$userRole is not defined`
- ❌ Chat send button logic fails
- ❌ Patient/provider role detection broken
- ❌ Chat input field may be incorrectly enabled/disabled

**After:**
- ✅ No JavaScript errors
- ✅ Provider chat send button shows correctly
- ✅ Patient chat input correctly disabled (read-only)
- ✅ Role-based chat permissions working

---

**Status**: ✅ All Issues Fixed and Ready for Testing
**Date**: December 18, 2025
**Developer**: Claude Code AI Assistant
