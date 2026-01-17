# Android Emulator Setup for Video Calls

## Problem Overview

When testing video calls on an Android emulator, you may encounter camera/microphone errors even though app permissions are granted. This is because **Android emulators don't have virtual cameras enabled by default**.

### Common Error Symptoms

```
E/cr_VideoCapture: getCameraCharacteristics: Unable to retrieve camera characteristics for unknown device 0
E/chromium: WebContentsDelegate::CheckMediaAccessPermission: Not supported
```

These errors indicate the emulator doesn't have a virtual camera configured.

---

## Solution 1: Use a Physical Device (Recommended)

**The best way to test video calls is on a physical Android device.**

### Why Physical Devices Are Better:
- ✅ Real camera and microphone hardware
- ✅ Better performance (no emulator overhead)
- ✅ Accurate representation of user experience
- ✅ No configuration needed
- ✅ WebRTC works properly

### How to Connect a Physical Device:
1. Enable Developer Mode on your Android device:
   - Go to **Settings → About Phone**
   - Tap **Build Number** 7 times
   - Developer options will be unlocked

2. Enable USB Debugging:
   - Go to **Settings → Developer Options**
   - Enable **USB Debugging**

3. Connect via USB cable and run:
   ```bash
   flutter devices  # Should show your connected device
   flutter run -d <device-id>
   ```

---

## Solution 2: Configure Android Emulator Virtual Camera

If you must use an emulator (e.g., for automated testing), follow these steps to enable the virtual camera:

### Step 1: Open AVD Manager

**From Android Studio:**
- Click **Tools → AVD Manager**
- Or click the device manager icon in the toolbar

**From Command Line:**
```bash
# Open Android Studio's AVD Manager
$ANDROID_HOME/tools/bin/avdmanager list avd
```

### Step 2: Edit Your Emulator

1. In AVD Manager, find your virtual device
2. Click the **pencil icon (✏️)** to edit
3. Click **Show Advanced Settings** at the bottom

### Step 3: Configure Camera Settings

Scroll down to the **Camera** section:

**Front Camera:**
- Change from `None` to **`Webcam0`** (or `Emulated`)
- This uses your computer's webcam as the emulator's front camera

**Back Camera:**
- Change from `None` to **`Webcam0`** (or `Emulated`)
- Can use the same webcam or a different one if you have multiple

**Important Options:**
- **`Webcam0`**: Uses your computer's actual webcam (most realistic)
- **`Emulated`**: Uses a simulated camera feed (animated patterns)
- **`VirtualScene`**: Uses a 3D virtual environment

### Step 4: Configure Microphone

While in Advanced Settings:

**Audio:**
- **Microphone**: Ensure it's set to **`Host microphone`**
- This uses your computer's microphone

### Step 5: Apply and Restart

1. Click **Finish** to save changes
2. **Completely close** the emulator if it's running
3. Start the emulator fresh from AVD Manager

---

## Solution 3: Create a New Emulator with Camera Support

If editing doesn't work, create a fresh emulator with camera enabled:

### From Android Studio UI:

1. **AVD Manager → Create Virtual Device**
2. Select a device definition (e.g., Pixel 6)
3. Select a system image (API 33+ recommended)
4. **Before clicking Finish**, click **Show Advanced Settings**
5. In the **Camera** section:
   - Front camera: **Webcam0**
   - Back camera: **Webcam0**
6. In the **Audio** section:
   - Microphone: **Host microphone**
7. Click **Finish**

### From Command Line:

```bash
# List available system images
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --list

# Create emulator with camera support
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager create avd \
  --name "MedZen_Test" \
  --package "system-images;android-33;google_apis;x86_64" \
  --device "pixel_6"

# Edit the config file to enable camera
echo "hw.camera.back=webcam0" >> ~/.android/avd/MedZen_Test.avd/config.ini
echo "hw.camera.front=webcam0" >> ~/.android/avd/MedZen_Test.avd/config.ini
echo "hw.audioInput=yes" >> ~/.android/avd/MedZen_Test.avd/config.ini
```

---

## Solution 4: Grant Camera Permissions (macOS)

If using **Webcam0** on macOS, ensure the emulator can access your camera:

1. **System Settings → Privacy & Security → Camera**
2. Find **`qemu-system-x86_64`** (the emulator process)
3. Enable the toggle to grant camera access
4. Restart the emulator

---

## Testing Video Calls in the Emulator

Once configured, test that the camera works:

### 1. Launch the Emulator
```bash
flutter run -d emulator-5554
```

### 2. Test Camera Access

Open Chrome in the emulator and navigate to:
```
https://webcamtests.com/
```

Click "Test my cam" to verify the virtual camera is working.

### 3. Test MedZen Video Call

1. Log in to the app
2. Navigate to a video call
3. Grant camera/microphone permissions when prompted
4. You should see your computer's webcam feed

---

## Troubleshooting

### Error: "No camera found"

**Cause:** Virtual camera not enabled
**Solution:** Follow steps above to set Front/Back camera to `Webcam0`

### Error: "Camera permission denied"

**Cause:** macOS blocking emulator's camera access
**Solution:** Grant camera permission in System Settings → Privacy & Security

### Error: "Camera already in use"

**Cause:** Your webcam is being used by another application
**Solution:** Close other apps using the camera (Zoom, Teams, Photo Booth, etc.)

### WebView still shows "CheckMediaAccessPermission: Not supported"

**Cause:** Emulator was not fully restarted after camera configuration
**Solution:**
1. Close emulator completely (don't just minimize)
2. In AVD Manager, click "Cold Boot Now" instead of regular start
3. This forces a full restart with new hardware configuration

### Emulator performance is slow with virtual camera

**Cause:** Emulator overhead + camera processing
**Solution:**
- Allocate more RAM to emulator (4GB+ recommended)
- Enable hardware acceleration:
  - **Settings → Advanced → Emulated Performance → Graphics: Hardware**
- Or use a physical device instead

### Camera shows black screen or pixelated image

**Cause:** Insufficient emulator resources
**Solution:**
1. Increase RAM: **AVD Manager → Edit → RAM: 4096 MB**
2. Enable QEMU acceleration (Intel HAXM or Apple Silicon)
3. Close other resource-intensive applications

---

## Recommended Emulator Specifications for Video Calls

For best performance when testing video calls:

```
Device: Pixel 6 or Pixel 7
API Level: 33 or higher (Android 13+)
ABI: x86_64 (Intel) or arm64-v8a (Apple Silicon)
RAM: 4096 MB minimum
Internal Storage: 2048 MB minimum
Graphics: Hardware - GLES 3.0
Front Camera: Webcam0
Back Camera: Webcam0
Audio Input: Host microphone
Audio Output: Host audio output
```

---

## Why Physical Devices Are Still Better

Despite proper emulator configuration, physical devices offer:

| Feature | Physical Device | Emulator |
|---------|----------------|----------|
| Camera quality | ✅ Native | ⚠️ Simulated |
| Performance | ✅ Full speed | ⚠️ Slower |
| WebRTC support | ✅ Complete | ⚠️ Limited |
| Network conditions | ✅ Real-world | ⚠️ Simulated |
| Battery impact | ✅ Measurable | ❌ N/A |
| User experience | ✅ Accurate | ⚠️ Approximate |

---

## Quick Reference Commands

```bash
# List all emulators
flutter emulators

# Create new emulator with camera
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager create avd \
  --name "MedZen_Camera_Test" \
  --package "system-images;android-33;google_apis;x86_64" \
  --device "pixel_6"

# Edit config to enable camera
echo "hw.camera.back=webcam0" >> ~/.android/avd/MedZen_Camera_Test.avd/config.ini
echo "hw.camera.front=webcam0" >> ~/.android/avd/MedZen_Camera_Test.avd/config.ini
echo "hw.audioInput=yes" >> ~/.android/avd/MedZen_Camera_Test.avd/config.ini

# Launch emulator
flutter emulators --launch MedZen_Camera_Test

# Run app on emulator
flutter run -d emulator-5554

# Check camera devices in emulator (via adb)
adb shell dumpsys media.camera | grep "Camera"
```

---

## Additional Resources

- [Android Emulator Camera Documentation](https://developer.android.com/studio/run/emulator-camera)
- [Flutter Device Testing](https://docs.flutter.dev/testing/integration-tests)
- [WebRTC Troubleshooting](https://webrtc.org/getting-started/testing)

---

## Summary

**For Production Testing:**
- ✅ **Always use physical Android devices**
- ✅ Test on multiple device models and Android versions
- ✅ Test under real network conditions

**For Development/Debugging:**
- ⚠️ Emulator is acceptable but requires proper camera configuration
- ⚠️ Performance will be slower than physical devices
- ⚠️ Some WebRTC features may not work identically

**MedZen Video Call Requirements:**
- Android 8.0+ (API 26+)
- Camera and microphone permissions
- WebView with JavaScript enabled
- Internet connection

For questions or issues, see the main [TESTING_GUIDE.md](TESTING_GUIDE.md) documentation.
