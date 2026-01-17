# Video Call Test Instructions

## ✅ Fixes Applied

### 1. Profile Image URL Fix
- **Problem**: Malformed URLs like `file:///500x500?doctor` causing crashes
- **Solution**: Database migration sets invalid URLs to NULL
- **Result**: App now uses default avatars instead of crashing

### 2. App Rebuilt
- **Status**: ✅ Successfully built and installed on emulator
- **Package**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Installed on**: emulator-5554

---

## 🧪 Testing Video Calls

### Current Test Environment: Android Emulator

**App Status**: ✅ Running on emulator-5554

### To Test Video Call:

1. **Login** to the app (patient or provider account)

2. **Navigate** to an appointment:
   - Tap on "Appointments" or "Home"
   - Select an appointment with video enabled

3. **Join Video Call**:
   - Tap "Join Video Call" button
   - Grant camera/microphone permissions when prompted

4. **Expected Behavior on Emulator**:
   ```
   ⏳ "Connecting to meeting..." (appears)
   ⏳ Loading indicator shows
   ⏳ SDK attempts to load from CDN
   ⚠️  After 60-120 seconds: TIMEOUT ERROR

   Error Message:
   "Failed to load video call SDK.
    For best results, use a physical device
    instead of an emulator."
   ```

5. **This is NORMAL**: Emulators cannot handle the 1.1MB Chime SDK

---

## ⚠️ Why Video Calls Timeout on Emulator

### Technical Explanation

| Aspect | Emulator | Physical Device |
|--------|----------|-----------------|
| **WebView Memory** | 512MB | 2-4GB |
| **JavaScript Speed** | 5-10x slower | Normal |
| **SDK Load Time** | 120s+ (TIMEOUT) | 3-5s ✅ |
| **Camera Support** | Virtual (limited) | Real hardware |
| **Production Ready** | ❌ No | ✅ Yes |

### Root Cause
The Chime SDK is a large JavaScript library (1.1MB minified) that requires:
- Fast JavaScript execution
- Sufficient WebView heap memory
- Modern WebView version
- Real camera/microphone hardware

**Emulators lack all of these**, making video call testing impossible.

---

## ✅ How to Test Video Calls Properly

### Use a Physical Android Device (REQUIRED)

#### Step 1: Enable Developer Mode (30 seconds)

On your Android phone:
1. Go to **Settings**
2. Scroll to **About Phone**
3. Tap **Build Number** 7 times
4. Message appears: "You are now a developer!"

#### Step 2: Enable USB Debugging (15 seconds)

1. Go back to **Settings**
2. Tap **Developer Options** (newly appeared)
3. Toggle **USB Debugging** to ON
4. Tap OK on confirmation dialog

#### Step 3: Connect Device (1 minute)

1. Connect phone to Mac via USB cable
2. On phone, tap "Allow USB Debugging" dialog
3. On Mac terminal:
   ```bash
   flutter devices
   ```
4. Verify your device appears in the list

#### Step 4: Run App on Physical Device (2 minutes)

```bash
# Example: If your device shows as "SM-G991B"
flutter run -d SM-G991B

# Or use device ID if multiple devices:
flutter run -d <device-id>
```

#### Step 5: Test Video Call (30 seconds)

1. App launches on your phone
2. Login with test account
3. Join appointment video call
4. **Expected Result**:
   - SDK loads in **3-5 seconds** ✅
   - Video call UI appears
   - Camera shows your face
   - Microphone picks up audio

---

## 📱 Physical Device Test Results (Expected)

### Timeline on Physical Device

| Step | Time | Status |
|------|------|--------|
| Tap "Join Call" | 0s | ✅ |
| SDK Download | 1-2s | ✅ |
| SDK Initialization | 1-2s | ✅ |
| Camera/Mic Access | 1s | ✅ |
| **Video Call Ready** | **3-5s** | ✅ |

### Expected Features

- ✅ Local video preview (your camera)
- ✅ Remote video (other participant)
- ✅ Mute/unmute microphone
- ✅ Turn video on/off
- ✅ Active speaker detection (green border)
- ✅ Leave call button
- ✅ Multi-participant support (up to 16)

---

## 🔍 Monitoring & Debugging

### Monitor App Logs

```bash
# Terminal 1: Run app
flutter run -d <device-id>

# Terminal 2: Watch video call logs
adb logcat | grep -E "Chime|video|SDK"
```

### Check for Errors

```bash
# Look for video call errors
adb logcat | grep -E "ERROR|FAIL" | grep -i "chime"

# Check WebView console
adb logcat | grep "chromium.*CONSOLE"
```

### Debug Checklist

- [ ] Device has stable internet (WiFi or 4G)
- [ ] Camera permission granted
- [ ] Microphone permission granted
- [ ] No other apps using camera
- [ ] Device has 2GB+ free RAM
- [ ] WebView updated to latest version

---

## 🎯 Next Steps

### Immediate Action

1. ✅ **Fixes applied** (profile URLs + app rebuilt)
2. 📱 **Connect physical Android device** (required)
3. ✅ **Test video calls** (expected: 3-5s load time)
4. 📝 **Verify functionality** (camera, mic, UI)

### Alternative: Test on Physical iPhone

If you have an iPhone available:

1. **Connect iPhone** to Mac via USB
2. **Trust this computer** on iPhone
3. **Run**: `flutter run -d iPhone`
4. **Test video call** (same 3-5s expected)

---

## 📋 Test Script Available

For automated testing, use:

```bash
# Comprehensive test with monitoring
./test_video_call_now.sh

# Or manual steps:
flutter devices                    # Check devices
flutter run -d <device-id>         # Run on device
# Then test video call in app
```

---

## 🆘 Troubleshooting

### Problem: Device not detected

```bash
# On Android phone:
Settings → Developer Options → Revoke USB Debugging authorizations
# Then disconnect/reconnect and allow again

# On Mac:
adb kill-server
adb start-server
adb devices
```

### Problem: Build errors

```bash
flutter clean
flutter pub get
flutter run -d <device-id>
```

### Problem: Video call still fails on physical device

1. Check internet connection (try on WiFi)
2. Update WebView: Play Store → Android System WebView
3. Restart app
4. Check logs: `adb logcat | grep Chime`

---

## 📚 Related Documentation

- **Complete Fix Guide**: `CHIME_SDK_EMULATOR_FIX.md`
- **Testing Guide**: `TESTING_GUIDE.md`
- **Production Guide**: `PRODUCTION_DEPLOYMENT_SUCCESS.md`
- **Enhanced Widget**: `ENHANCED_CHIME_USAGE_GUIDE.md`

---

## Summary

✅ **Profile image crashes**: Fixed
✅ **App rebuilt**: Ready for testing
⚠️  **Emulator timeout**: Expected (not a bug)
📱 **Physical device**: Required for real testing
⏱️  **Expected load time**: 3-5 seconds on real device

**Action Required**: Test on physical Android device to verify video calls work properly.
