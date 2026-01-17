# Chime Video Call - Quick Verification Checklist

## Pre-Flight Checklist (Before Testing)

### Code Configuration
- [ ] `pubspec.yaml` has all required dependencies
- [ ] `AndroidManifest.xml` has camera & microphone permissions
- [ ] `Info.plist` has NSCameraUsageDescription & NSMicrophoneUsageDescription
- [ ] `build.gradle` has minSdkVersion 21 or higher
- [ ] `Podfile` includes flutter_ios_podfile_setup

### Firebase & Supabase Setup
- [ ] Firebase project ID matches: `medzen-bf20e`
- [ ] Supabase project ID matches: `noaeltglphdlkbflipit`
- [ ] Firebase Auth is initialized
- [ ] Supabase client is initialized
- [ ] AWS Chime credentials edge function is deployed

---

## Android Testing Checklist

### Emulator Setup
```bash
# List available AVDs
emulator -list-avds

# Launch emulator with WebRTC support (API 24+)
emulator -avd Pixel_4_API_24 -no-snapshot-load -gpu angle_indirect
```

### Pre-Run Verification
- [ ] Emulator running with at least API 24 (API 21+ minimum, but 24+ recommended for testing)
- [ ] Emulator has 4GB+ allocated RAM
- [ ] Camera support enabled in AVD settings
- [ ] Microphone support enabled in AVD settings
- [ ] Network access verified (can reach medzenhealth.app)

### First Run
```bash
flutter run -d emulator-5554 -v
```

**Watch for these logs:**
- ✅ "🚀 Initializing Enhanced Chime Meeting (AWS Demo Features)"
- ✅ "📹 Checking camera/microphone permissions..."
- ✅ "📹 Camera permission: PermissionStatus.granted"
- ✅ "🎤 Microphone permission: PermissionStatus.granted"
- ✅ "📦 SDK script loaded from CDN"
- ✅ "✅ Chime SDK ready - notifying Flutter"

**Watch out for these errors:**
- ❌ "CheckMediaAccessPermission: Not supported" (indicates permission loop)
- ❌ "NotReadableError" (camera busy)
- ❌ "❌ Chime SDK not found on window.load"

### Runtime Testing
- [ ] Permission dialogs appear when app launches
- [ ] Grant permissions and video call loads
- [ ] Mute button toggles mic (check status icon changes 🔊 → 🔇)
- [ ] Video button toggles camera (profile picture appears when off)
- [ ] Active speaker border highlights (green border appears)
- [ ] Chat opens/closes (swipe animation works)
- [ ] Send message appears in chat (white background bubble)
- [ ] Receive message notification shows (green banner at top)
- [ ] Leave button ends call (returns to previous screen)

### Emulator-Specific Issues
| Issue | Solution |
|-------|----------|
| Camera frozen | Disable -> Enable camera in AVD settings, restart emulator |
| Microphone not working | Go to Android Settings > Apps > Permissions > Microphone, ensure enabled |
| SDK won't load | Check logcat: `adb logcat \| grep ChimeSDK` |
| App crashes on startup | Run `flutter clean && flutter pub get` |
| Extreme lag/stuttering | Close other emulator instances, increase RAM allocation |

---

## iOS Testing Checklist

### Simulator Setup
```bash
# List available simulators
xcrun simctl list devices available

# Launch simulator with camera support (physical device recommended)
flutter run -d iPhone
```

### Pre-Run Verification
- [ ] Simulator running (iPhone 12+)
- [ ] Xcode installed and up to date
- [ ] CocoaPods dependencies updated
  ```bash
  cd ios && pod install && cd ..
  ```
- [ ] Sufficient storage on Mac (5GB+)

### First Run
```bash
flutter run -d iPhone -v
```

**Watch for these logs:**
- ✅ "Building with iOS SDK"
- ✅ "🚀 Initializing Enhanced Chime Meeting"
- ✅ "✅ Chime SDK ready"
- ✅ "✅ Meeting started successfully"

### Runtime Testing
- [ ] Camera/Microphone permission dialogs appear
- [ ] Allow permissions (system native prompts)
- [ ] Video call loads successfully
- [ ] Speaker phone is working (hear audio from both sides)
- [ ] Mute button works (system mute indicator appears)
- [ ] Video toggle works (local video on/off)
- [ ] Chat functionality works
- [ ] Device rotation handled (landscape/portrait switching)
- [ ] Call ends when back button pressed

### Real Device Testing (Recommended)
```bash
# Connect iPhone
xcrun instruments -s devices

# Run on device
flutter run -d <device-id>
```

**Real Device Testing Steps:**
1. Open app and grant camera/microphone permissions
2. Initiate video call
3. Verify:
   - [ ] Actual camera feed displays
   - [ ] Actual microphone audio works
   - [ ] Remote speaker audio clear
   - [ ] Switching to headphones audio routes correctly
   - [ ] Locking phone doesn't drop call
   - [ ] Unlocking phone resumes video
   - [ ] Battery usage reasonable (<20% per minute)

---

## Web Testing Checklist

### Browser Verification
```bash
# Ensure Chrome/Chromium browser
google-chrome --version

# If using Chromium
chromium-browser --version
```

### First Run
```bash
flutter run -d chrome --dart-define=FLUTTER_WEB_AUTO_REFRESH=true
```

### DevTools Inspection
1. **Open DevTools**: Ctrl+Shift+I (Windows/Linux) or Cmd+Option+I (Mac)
2. **Check Console Tab**:
   - ✅ No red error messages
   - ✅ See "🚀 Video call HTML loaded" message
   - ✅ See "✅ Chime SDK ready"

3. **Check Network Tab**:
   - ✅ Request to `du6iimxem4mh7.cloudfront.net` succeeds
   - ✅ SDK file loads (amazon-chime-sdk-medzen.min.js)
   - ✅ Status 200 responses (no 403/404)

4. **Check Permission Prompts**:
   - ✅ Camera selection dialog appears
   - ✅ Microphone selection dialog appears
   - ✅ Allow/Deny buttons work

### Runtime Testing
- [ ] Video preview displays
- [ ] Audio input/output working
- [ ] Chat sends/receives messages
- [ ] Transcription starts (if provider)
- [ ] Captions display (if transcription enabled)
- [ ] Leave call returns to app
- [ ] Refresh page doesn't cause issues

### Browser Compatibility
| Browser | Status | Notes |
|---------|--------|-------|
| Chrome/Chromium | ✅ Full Support | Recommended |
| Firefox | ✅ Full Support | May need hardware acceleration enabled |
| Safari | ⚠️ Limited | WebRTC supported but some issues possible |
| Edge | ✅ Full Support | Chromium-based, same as Chrome |

---

## Cross-Platform Testing

### Scenario 1: Android ↔ Android
```bash
# Terminal 1: Launch first Android emulator
emulator -avd Pixel_4_API_24 -no-snapshot-load

# Terminal 2: Launch second Android emulator
emulator -avd Pixel_4_API_24 -port 5556 -no-snapshot-load

# Run app on both
flutter run -d emulator-5554  # First emulator
flutter run -d emulator-5556  # Second emulator (in another terminal)

# Test video call between them
```

- [ ] Both participants see each other's video
- [ ] Audio flows both directions
- [ ] Chat messages sync in realtime
- [ ] Active speaker indicator works

### Scenario 2: iOS ↔ iOS (Simulator)
```bash
# Open two Xcode windows or use different simulators
flutter run -d <simulator-1>
flutter run -d <simulator-2>  # In another terminal
```

- [ ] Video call connects
- [ ] Simulated video displays
- [ ] Chat works (note: audio won't work well in simulator)

### Scenario 3: Android ↔ Web
```bash
# Terminal 1: Web version
flutter run -d chrome

# Terminal 2: Android emulator
flutter run -d emulator-5554
```

**Test Points:**
- [ ] Web participant sees Android video
- [ ] Android participant sees web video
- [ ] Chat messages sync
- [ ] Video quality consistent

### Scenario 4: iOS ↔ Web
```bash
# Terminal 1: Web version
flutter run -d chrome

# Terminal 2: iOS simulator
flutter run -d iPhone
```

**Test Points:**
- [ ] Same as Android ↔ Web above
- [ ] Speaker audio routing correct

---

## Stress Testing

### High-Participant Scenario
- [ ] Test with 3+ participants (local)
- [ ] Verify video grid adapts properly
- [ ] Check for memory leaks (watch task manager)
- [ ] Monitor CPU usage (should stay under 60%)

### Long-Duration Call
```bash
# Run for at least 30 minutes
- [ ] App doesn't crash
- [ ] Memory usage stable (no continuous growth)
- [ ] Audio quality remains consistent
- [ ] Chat continues to work
- [ ] Video stream doesn't freeze
```

### Network Latency Test
- [ ] Simulate poor network (use browser throttling)
  - Settings > Network > "Slow 3G"
- [ ] Verify graceful degradation
- [ ] Check for helpful error messages

### Permission Revocation
- [ ] Revoke camera permission (Settings > Apps > Permissions)
- [ ] Verify app shows "Camera unavailable" gracefully
- [ ] Revoke microphone permission
- [ ] Verify app shows "Microphone unavailable" gracefully

---

## Troubleshooting Quick Reference

### No Video or Audio Appears
1. Check permission status in device Settings
2. Verify Chime SDK loaded (see Console)
3. Check browser/app has internet access
4. Restart app completely
5. Check that other participant also connected

### "CheckMediaAccessPermission: Not supported"
1. This is normal debug message (search filter adds noise)
2. If video doesn't work, this indicates a problem
3. Check Android logcat: `adb logcat | grep -E "MediaRecorder|Camera"`
4. Restart emulator with fresh `-no-snapshot-load`

### SDK Fails to Load
1. Check network connectivity
2. Verify no firewall blocking CDN access
3. Check browser console for CORS errors
4. Try incognito/private mode (clears cache)
5. Try different browser

### Chat Messages Not Syncing
1. Check Supabase connection
2. Verify Firebase token is valid: `getIdToken(true)`
3. Check Realtime channel subscription in browser console
4. Verify RLS policies allow message access

### Video One-Way (You See Other, Other Sees Frozen)
1. Check if your video button is off (toggle it)
2. Verify local video tile shows something
3. Check browser console for video binding errors
4. Restart app and rejoin call

---

## Performance Metrics

### Acceptable Ranges (Mobile)
| Metric | Threshold | Note |
|--------|-----------|------|
| App startup time | < 3 seconds | After permissions granted |
| SDK load time | < 5 seconds | From HTML load to SDK_READY |
| First video frame | < 2 seconds | After joining meeting |
| Audio latency | < 300ms | One-way latency |
| Memory usage (Android) | < 150MB | After stabilizing |
| Memory usage (iOS) | < 200MB | After stabilizing |
| CPU usage | < 40% | On single video stream |

### Acceptable Ranges (Web)
| Metric | Threshold |
|--------|-----------|
| Initial load | < 3 seconds |
| SDK load | < 4 seconds |
| First video frame | < 1 second |
| Memory (background) | < 100MB |
| Memory (active call) | < 200MB |
| CPU | < 30% |

---

## Sign-Off Checklist

**Developer:** ________________  **Date:** ____________

**Android Emulator:**
- [ ] Permissions work ✅
- [ ] Video/audio functional ✅
- [ ] Chat working ✅
- [ ] No crashes ✅

**iOS Simulator:**
- [ ] Permissions work ✅
- [ ] Video/audio functional ✅
- [ ] Chat working ✅
- [ ] No crashes ✅

**Web (Chrome):**
- [ ] Camera/mic prompts appear ✅
- [ ] Video stream displays ✅
- [ ] Chat functional ✅
- [ ] No console errors ✅

**Cross-Platform:**
- [ ] Participants can see each other ✅
- [ ] Chat syncs across platforms ✅
- [ ] No unexpected errors ✅

**Performance:**
- [ ] Memory stable ✅
- [ ] No CPU spikes ✅
- [ ] Call quality acceptable ✅

**Ready for Production:** ☐ YES ☐ NO

**Notes:**
```
_________________________________________________________________
_________________________________________________________________
```

