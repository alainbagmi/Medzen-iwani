# Android Emulator Camera Error Fix

## The Errors You're Seeing

```
E/cr_VideoCapture( 9770): getCameraCharacteristics:
E/cr_VideoCapture( 9770): java.lang.IllegalArgumentException: getCameraCharacteristics:784:
Unable to retrieve camera characteristics for unknown device 0: No such file or directory (-2)
```

These errors appear because the **Android emulator's virtual camera is not properly configured**.

## Impact

- ❌ Camera permissions fail
- ❌ Video preview doesn't work properly
- ⚠️ May affect transcription (if audio is also affected)
- ⚠️ Poor testing experience for video calls

## Quick Fix - Enable Webcam Passthrough

### Method 1: AVD Manager (Recommended)

1. **Open Android Studio**
2. **Tools → AVD Manager**
3. **Click ✏️ (Edit) on your emulator**
4. **Click "Show Advanced Settings"**
5. **Scroll to Camera section:**
   - **Front camera:** Webcam0 or Emulated
   - **Back camera:** Webcam0 or Emulated
6. **Click "Finish"**
7. **Restart the emulator**

### Method 2: config.ini (Manual)

1. **Stop the emulator**
2. **Find your AVD config:**
   ```bash
   # macOS
   cd ~/.android/avd/<your-avd-name>.avd/

   # Look for config.ini
   ```
3. **Edit config.ini:**
   ```ini
   # Change these lines:
   hw.camera.back=emulated
   hw.camera.front=emulated

   # Or use webcam:
   hw.camera.back=webcam0
   hw.camera.front=webcam0
   ```
4. **Save and restart emulator**

### Method 3: Script Fix (Automated)

Run the existing fix script:

```bash
# From project root
chmod +x fix_emulator_camera.sh
./fix_emulator_camera.sh
```

## Test Camera is Working

After applying the fix:

1. **Launch emulator:**
   ```bash
   flutter run -d emulator-5554
   ```

2. **Open the default Camera app** on the emulator
3. **You should see:**
   - ✅ Your MacBook webcam feed
   - ✅ No camera errors in the logs
   - ✅ Camera flips between front/back

4. **Test in MedZen app:**
   - Start a video call
   - Logs should show: `📹 Device list fetched` with actual devices
   - No `getCameraCharacteristics` errors

## Alternative: Use a Real Android Device

For better testing (especially for transcription):

```bash
# 1. Enable USB Debugging on Android phone
# 2. Connect via USB
# 3. Run:
flutter devices
flutter run -d <device-id>
```

**Benefits:**
- ✅ Real camera and microphone
- ✅ Better audio quality for transcription testing
- ✅ More realistic performance
- ✅ No emulator quirks

## What This Fixes

| Issue | Before | After |
|-------|--------|-------|
| Camera errors | ❌ Constant `getCameraCharacteristics` errors | ✅ Clean logs |
| Video preview | ❌ Black screen or errors | ✅ Shows webcam feed |
| Permission requests | ⚠️ May fail | ✅ Works properly |
| Testing experience | 😞 Frustrating | 😊 Smooth |

## Does This Affect Transcription?

**Indirectly, yes:**

1. **Camera errors spam the logs** → harder to debug transcription issues
2. **Permission issues** → may affect microphone permissions too
3. **WebView rendering issues** → could affect Chime SDK initialization
4. **Overall instability** → cascading problems

**Fix the camera = cleaner testing environment = easier to debug transcription**

## Verification

After fixing, your logs should show:

```
I/flutter ( 9770): 📹 Device list fetched (pre-permission, not cached, 4 devices)
I/flutter ( 9770): 📹 Devices: [webcam0-front, webcam0-back, ...]
```

**NOT:**
```
E/cr_VideoCapture( 9770): getCameraCharacteristics: Unable to retrieve...
```

## Next Steps

1. ✅ **Fix the emulator camera** (using one of the methods above)
2. ✅ **Hot restart the app** to test transcription fix
3. ✅ **Check both fixes work together**
4. 📝 **Report back with clean logs**

Clean camera setup = Better testing = Easier debugging! 🎥
