# Video Call Emulator Issues - Quick Fix Guide

## Problem
You're seeing these errors on Android emulator:
```
❌ Chime SDK load timeout after 120 seconds
❌ Invalid argument(s): No host specified in URI file:///500x500?doctor
```

## Root Causes

### 1. Chime SDK Timeout (Primary Issue)
**Cause:** Android emulators have limited network capabilities that can block CDN resources.

**Evidence from your logs:**
- Running on `emulator-5554` (Android 13 ARM64)
- Timeout after exactly 120 seconds
- SDK loading from CloudFront CDN

### 2. Malformed Image URLs (Secondary Issue)
**Cause:** Profile picture URLs stored without proper `http://` or `https://` prefix.

**Evidence:**
- Error: `file:///500x500?doctor`
- Should be: `https://...` URL

---

## Solution 1: Use Physical Device (Recommended)

**Video calls should ALWAYS be tested on physical devices, not emulators.**

### Why Physical Devices?
- ✅ Real camera and microphone hardware
- ✅ Proper network stack for WebRTC
- ✅ CDN resources load correctly
- ✅ Better performance (no emulator overhead)
- ✅ Accurate user experience

### How to Connect Physical Device

**Android:**
1. Enable Developer Mode:
   - Settings → About Phone → Tap "Build Number" 7 times

2. Enable USB Debugging:
   - Settings → Developer Options → Enable "USB Debugging"

3. Connect via USB and run:
   ```bash
   flutter devices
   flutter run -d <device-id>
   ```

**iOS:**
1. Connect iPhone via USB cable
2. Trust the computer when prompted
3. Run:
   ```bash
   flutter devices
   flutter run -d <device-id>
   ```

---

## Solution 2: Fix Emulator Network (If You Must Use It)

If you absolutely need to test on emulator, try these fixes:

### Option A: Configure Emulator Network
```bash
# Stop the emulator
adb -s emulator-5554 emu kill

# Edit emulator config to enable proper networking
echo "hw.network.type=user" >> ~/.android/avd/<your-avd-name>.avd/config.ini

# Restart emulator with DNS settings
emulator -avd <your-avd-name> -dns-server 8.8.8.8,8.8.4.4
```

### Option B: Test Network in Emulator
```bash
# Open emulator and test CDN connectivity
adb -s emulator-5554 shell

# Test if CDN is reachable
ping d2n29hdfurdqmu.cloudfront.net

# Test HTTPS connectivity
curl -I https://d2n29hdfurdqmu.cloudfront.net/chime-sdk-3.19.0.min.js
```

If these commands fail, your emulator's network stack is broken.

### Option C: Use Legacy Widget with Local SDK
The `ChimeMeetingWebview` widget has better emulator support:

```dart
// In join_room.dart, replace ChimeMeetingEnhanced with:
ChimeMeetingWebview(
  meetingData: jsonEncode(meetingData),
  attendeeData: jsonEncode(attendeeData),
  userName: userName ?? 'User',
  onCallEnded: () async {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  },
)
```

**Note:** This is a temporary workaround. Production testing should still use physical devices.

---

## Solution 3: Fix Malformed Image URLs

The database migration is being applied automatically. To manually fix:

### Quick SQL Fix
```bash
# Apply the migration
npx supabase db push

# Or run directly
npx supabase db execute "
  UPDATE users
  SET avatar_url = NULL
  WHERE avatar_url LIKE '%500x500%' OR avatar_url NOT LIKE 'http%';

  UPDATE medical_provider_profiles
  SET profile_picture_url = NULL
  WHERE profile_picture_url LIKE '%500x500%' OR profile_picture_url NOT LIKE 'http%';

  UPDATE facility_admin_profiles
  SET profile_picture_url = NULL
  WHERE profile_picture_url LIKE '%500x500%' OR profile_picture_url NOT LIKE 'http%';
"
```

### Verify Fix
```bash
# Check for remaining malformed URLs
npx supabase db execute "
  SELECT 'users' as table_name, COUNT(*) as bad_urls
  FROM users
  WHERE avatar_url IS NOT NULL AND avatar_url NOT LIKE 'http%'
  UNION ALL
  SELECT 'providers', COUNT(*)
  FROM medical_provider_profiles
  WHERE profile_picture_url IS NOT NULL AND profile_picture_url NOT LIKE 'http%';
"
```

---

## Solution 4: Alternative Testing Approach

If you can't use a physical device right now:

### Test Video Call Flow Without Camera
1. **Test authentication and API calls:**
   ```bash
   # Run the flow test script
   ./test_video_call_auth_fix.sh
   ```

2. **Verify meeting creation:**
   - Check Supabase function logs
   - Verify video_call_sessions table has correct data

3. **Test UI flow:**
   - Navigate to join call page
   - Verify permissions prompts appear
   - Check console logs for API responses

### Use Web Platform for Quick Testing
```bash
# Test on Chrome instead of emulator
flutter run -d chrome

# Web has better emulator-like testing without hardware dependencies
```

**Note:** Web video calls work but have different UX than mobile.

---

## Recommended Testing Workflow

### Development Phase
1. ✅ Use **physical device** for video call testing
2. ⚠️ Use emulator/simulator for UI-only testing
3. ✅ Use automated tests for API/backend

### Production Testing
1. ✅ Test on **multiple physical Android devices** (different manufacturers)
2. ✅ Test on **multiple physical iOS devices** (different models)
3. ✅ Test different network conditions (WiFi, 4G, 5G)
4. ❌ **Never** deploy based solely on emulator testing

---

## Quick Reference: Your Current Error

```
I/flutter (13116): ❌ Chime SDK load timeout after 120 seconds
```

**This means:**
- The WebView couldn't load the Chime SDK JavaScript from CDN
- Network request to `https://d2n29hdfurdqmu.cloudfront.net/chime-sdk-3.19.0.min.js` failed
- Emulator's network stack likely blocked the request

**Fix:**
```bash
# Immediate solution
flutter run -d <physical-device-id>

# Or if you see "Alain's iPhone" in flutter devices:
flutter run -d 77EC1152-1299-4C50-93D3-648DD14E1725
```

---

## Additional Diagnostics

If physical device also fails, check:

1. **Internet connectivity:**
   ```bash
   ping google.com
   curl -I https://d2n29hdfurdqmu.cloudfront.net/chime-sdk-3.19.0.min.js
   ```

2. **Firebase authentication:**
   ```bash
   # Check if user is logged in
   firebase auth:export users.json
   ```

3. **Supabase function logs:**
   ```bash
   npx supabase functions logs chime-meeting-token --tail
   ```

4. **AWS Chime API status:**
   ```bash
   # Verify Chime SDK is deployed
   aws cloudformation describe-stacks \
     --stack-name medzen-chime-sdk-eu-central-1 \
     --region eu-central-1
   ```

---

## Summary

| Issue | Cause | Fix | Priority |
|-------|-------|-----|----------|
| Chime SDK timeout | Emulator network limitations | Use physical device | 🔴 Critical |
| Malformed image URLs | Database corruption | Apply migration | 🟡 Medium |
| ImageReader warnings | Failed image loads | Fixed by migration | 🟢 Low |

**Action Items:**
1. ✅ **Immediately:** Test on physical Android device
2. ✅ Apply database migration (running automatically)
3. ✅ Verify video calls work on physical device
4. ⚠️ Only use emulator for non-video features

---

## Need Help?

If issues persist on **physical device**:
1. Check logs: `flutter logs`
2. Check Supabase logs: `npx supabase functions logs chime-meeting-token`
3. Verify AWS Chime stack is deployed: See `DEPLOYMENT_COMPLETE.md`
4. Run full diagnostics: `./test_chime_deployment.sh`

**Remember:** Emulators are NOT suitable for testing video calls. Always use physical devices for video call features.
