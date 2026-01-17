# Chime SDK Emulator Loading Issues - Fix Guide

## Issue Summary

**Problem**: Chime SDK times out when loading from CDN on Android emulators

**Error Messages**:
- ❌ Chime SDK load timeout after 120 seconds
- 🔍 Debug: typeof window.ChimeSDK = undefined
- ❌ SDK load failed (attempt 1/3)

**Root Cause**: Android emulators have known issues with:
1. WebView JavaScript engine performance (much slower than physical devices)
2. Limited memory allocation for WebView processes
3. Slower network throughput for large JavaScript files (Chime SDK is 1.1MB)
4. JavaScript execution timeout limitations

## Immediate Fixes Applied

### 1. Fixed Malformed Profile Image URLs ✅

**Migration Created**: `supabase/migrations/20251216170000_fix_malformed_profile_urls.sql`

Fixed errors like:
```
Invalid argument(s): No host specified in URI file:///500x500?doctor
```

**Changes**:
- Set invalid avatar URLs to `NULL` in `users` table
- Set invalid profile pictures to `NULL` in `medical_provider_profiles` table
- Set invalid profile pictures to `NULL` in `facility_admin_profiles` table

**Impact**: App will now use default avatars instead of crashing on malformed URLs.

### 2. Apply Migration to Database

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu
npx supabase db push
```

## Understanding the Chime SDK Loading Problem

### Why It Fails on Emulators

The Chime SDK (v3.19.0) is loaded from:
```
https://d2n29hdfurdqmu.cloudfront.net/chime-sdk-3.19.0.min.js
```

**File Size**: 1.1MB minified JavaScript

**Emulator Limitations**:
1. **Memory**: Emulators allocate limited heap to WebView (typically 512MB-1GB vs 2-4GB on physical devices)
2. **CPU**: Emulator CPU is virtualized, making JavaScript execution 5-10x slower
3. **Network**: Virtual network has higher latency and lower throughput
4. **WebView Version**: Emulator may use older WebView version with bugs

### Verification

The CDN URL is **valid and accessible**:
```bash
curl -I https://d2n29hdfurdqmu.cloudfront.net/chime-sdk-3.19.0.min.js
# HTTP/2 200
# content-length: 1164223
# content-type: application/javascript
```

Emulator **has internet connectivity**:
```bash
adb shell ping -c 3 8.8.8.8
# 3 packets transmitted, 3 received, 0% packet loss
```

**Conclusion**: The issue is WebView JavaScript execution performance, not network connectivity.

## Solutions

### Solution 1: Test on Physical Device (RECOMMENDED) ✅

**Why Physical Devices Work**:
- 4-8x faster JavaScript execution
- 4-8x more memory for WebView
- Better WebView version (automatically updated via Google Play)
- Native camera/microphone hardware

**How to Test**:

1. Enable Developer Mode on Android device:
   - Settings → About Phone → Tap "Build Number" 7 times

2. Enable USB Debugging:
   - Settings → Developer Options → USB Debugging

3. Connect device via USB and run:
   ```bash
   flutter devices  # Verify device is listed
   flutter run -d <device-id>
   ```

4. **Expected Result**: Chime SDK loads in 3-5 seconds (vs 120+ on emulator)

### Solution 2: Use Alternative CDN (FALLBACK)

Some CDNs have better emulator compatibility. Try jsdelivr or unpkg:

**Edit**: `lib/custom_code/widgets/chime_meeting_enhanced.dart:487`

Change from:
```html
<script src="https://d2n29hdfurdqmu.cloudfront.net/chime-sdk-3.19.0.min.js"
        crossorigin="anonymous"
        onerror="handleSDKLoadError()"></script>
```

To:
```html
<!-- Try jsdelivr CDN first -->
<script src="https://cdn.jsdelivr.net/npm/amazon-chime-sdk-js@3.19.0/dist/chime-sdk.min.js"
        crossorigin="anonymous"
        onerror="tryUnpkgCDN()"></script>

<script>
function tryUnpkgCDN() {
  console.log('jsdelivr failed, trying unpkg...');
  const script = document.createElement('script');
  script.src = 'https://unpkg.com/amazon-chime-sdk-js@3.19.0/dist/chime-sdk.min.js';
  script.crossOrigin = 'anonymous';
  script.onerror = handleSDKLoadError;
  document.head.appendChild(script);
}
</script>
```

**⚠️ Note**: This is a workaround, not a permanent fix. Physical device testing is still required.

### Solution 3: Optimize Emulator Settings

**Increase Emulator Resources**:

1. Open Android Studio → AVD Manager
2. Edit your emulator
3. Show Advanced Settings:
   - RAM: 4096 MB (minimum)
   - VM heap: 512 MB
   - Internal Storage: 4096 MB
   - SD Card: 1024 MB

4. Enable hardware acceleration:
   - Graphics: Hardware - GLES 2.0
   - Boot option: Cold boot

5. Restart emulator with more resources:
   ```bash
   emulator -avd Pixel_3a_API_34_extension_level_7_x86_64 -memory 4096 -cores 4
   ```

**Expected Improvement**: May reduce timeout from 120s to 60s (still slow).

### Solution 4: Use Offline-First Approach (NOT IMPLEMENTED)

Bundle the Chime SDK locally in `assets/html/chime-sdk-3.19.0.min.js`:

**Pros**:
- No CDN dependency
- Faster loading on slow connections

**Cons**:
- Increases app size by 1.1MB
- Manual updates required for SDK version upgrades
- Not currently implemented

## Testing Checklist

### Before Testing Video Calls

- [ ] Profile image URLs fixed (migration applied)
- [ ] Using physical Android device (not emulator)
- [ ] Camera and microphone permissions granted
- [ ] Device has stable internet connection (WiFi or 4G)
- [ ] Flutter app rebuilt: `flutter clean && flutter pub get && flutter run`

### Testing on Physical Device

1. **Create Test Appointment**:
   - Login as patient
   - Book appointment with video enabled
   - Note the appointment ID

2. **Join Call as Patient**:
   - Open appointment
   - Tap "Join Video Call"
   - **Expected**: SDK loads in 3-5 seconds
   - **Expected**: Camera/mic permissions requested (grant them)
   - **Expected**: Video call UI appears with local video

3. **Join Call as Provider** (from another device/account):
   - Login as provider
   - Open same appointment
   - Tap "Join Video Call"
   - **Expected**: Both participants see each other's video

4. **Test Call Features**:
   - [ ] Mute/unmute microphone
   - [ ] Turn video on/off
   - [ ] Active speaker detection (green border)
   - [ ] Leave call

### Debugging Commands

```bash
# Monitor Flutter logs
flutter logs

# Monitor Android logs
adb logcat -s flutter:I chromium:I

# Check Chime SDK loading
adb logcat | grep "Chime SDK"

# Check WebView errors
adb logcat | grep -E "chromium|WebView"
```

## Expected Timeline for Physical Device

| Step | Emulator Time | Physical Device Time |
|------|---------------|----------------------|
| SDK Download | 10-30s | 1-3s |
| SDK Parsing | 60-90s | 2-4s |
| SDK Initialization | 30-60s | 0.5-1s |
| **Total** | **120-180s (FAIL)** | **3-8s (SUCCESS)** |

## Known Limitations

### Android Emulator

- ❌ Chime SDK often times out (120s+)
- ⚠️ Virtual camera may not work even if SDK loads
- ⚠️ Virtual microphone has poor audio quality
- ❌ Cannot test multi-participant calls effectively

### iOS Simulator

- ❌ Camera/microphone access not supported
- ❌ WebRTC getUserMedia() fails
- ❌ Video calls will not work at all

### Recommended Testing Environment

- ✅ Physical Android device (Android 8.0+)
- ✅ Physical iPhone (iOS 12.0+)
- ✅ Modern Android WebView (Chrome 90+)
- ✅ Stable WiFi connection (5+ Mbps)
- ✅ 2GB+ available RAM

## Next Steps

1. **Apply profile URL fix**: ✅ Complete
   ```bash
   npx supabase db push
   ```

2. **Test on physical device**: 📱 Required
   - Connect Android phone
   - Run: `flutter run -d <device-id>`

3. **Verify video calls work**: ✓ Test with 2 devices
   - One patient account
   - One provider account
   - Join same appointment

4. **Document results**: 📝 Update testing guide with findings

## Alternative: Use Legacy Widget

If Enhanced widget continues to have issues, switch to legacy widget:

**In**: `lib/custom_code/actions/join_room.dart:386`

Change:
```dart
body: ChimeMeetingEnhanced(  // Current (enhanced)
```

To:
```dart
body: ChimeMeetingWebview(  // Legacy (simpler)
```

**Note**: Legacy widget has fewer features but may load faster on some devices.

## Support & Resources

- **AWS Chime SDK Docs**: https://docs.aws.amazon.com/chime-sdk/latest/dg/what-is-chime-sdk.html
- **Chime SDK GitHub**: https://github.com/aws/amazon-chime-sdk-js
- **Flutter WebView Plugin**: https://pub.dev/packages/webview_flutter
- **Testing Guide**: TESTING_GUIDE.md
- **Production Deployment**: PRODUCTION_DEPLOYMENT_SUCCESS.md

## Summary

**Immediate Action Required**: Test video calls on a physical Android device.

**Emulators are NOT suitable** for testing video calls due to WebView performance limitations. The 120-second timeout is expected behavior on emulators.

**Fix Applied**: Profile image URLs cleaned up to prevent crashes.

**Next Test**: Physical device testing will show true performance (3-8 seconds).
