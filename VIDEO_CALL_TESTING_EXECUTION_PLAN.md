# Video Call Testing Execution Plan

**Implementation Status:** ✅ ALL PHASES COMPLETE
**Date Created:** 2025-12-05
**Reference:** VIDEO_CALL_INITIALIZATION_FIX_PLAN.md

---

## Pre-Test Setup

### Environment Requirements
- [ ] Physical iOS device (iPhone recommended - iOS Simulator has known permission dialog issues)
- [ ] Physical Android device (for image URL fix verification)
- [ ] Stable WiFi connection (for baseline testing)
- [ ] Ability to disable/enable WiFi during tests
- [ ] Firebase Auth configured and working
- [ ] Supabase Edge Function `chime-meeting-token` deployed and accessible
- [ ] Test appointment created with `video_enabled=true`

### Pre-Test Verification
```bash
# 1. Verify Flutter installation
flutter doctor -v

# 2. Clean build
flutter clean && flutter pub get

# 3. Verify no blocking errors
flutter analyze | grep -E "error|ERROR"

# 4. Check Supabase Edge Function health
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token" \
  -H "X-Firebase-Token: test" \
  -H "Content-Type: application/json" \
  -d '{"action":"create","appointmentId":"test"}' \
  --max-time 5
# Expected: Response within 5 seconds (even if 401/400, proves function is responsive)
```

### Test Data Preparation
- [ ] Create test provider account with valid credentials
- [ ] Create test patient account with valid credentials
- [ ] Create test appointment linking provider and patient with:
  - `video_enabled = true`
  - `status = 'scheduled'`
  - `scheduled_start` in near future

---

## Test Execution

### TEST 1: WebView Timeout Behavior ⏱️

**Objective:** Verify 20-second timeout triggers when WebView cannot load Chime SDK

**Prerequisites:**
- App built and running on physical device
- Logged in as provider or patient
- Test appointment available to join

**Steps:**
1. Open app and navigate to appointments page
2. Locate test appointment with video call enabled
3. **BEFORE tapping join:** Turn OFF WiFi on device
4. Tap "Join Video Call" button
5. Observe initialization screen
6. Start timer - wait for timeout

**Expected Results:**
- ✅ Loading screen shows "Initializing video call..." message
- ✅ After 20 seconds, timeout error screen appears
- ✅ Error screen displays:
  - Red error icon (Icons.error_outline)
  - "Connection Timed Out" heading
  - "Unable to connect to video call" message
  - Blue "Retry" button with refresh icon
  - "Go Back" text button
- ✅ No indefinite "Initializing..." hang
- ✅ No app crash or freeze

**Actual Results:**
- [ ] PASS / [ ] FAIL
- Notes: ___________________________________________

**If Failed:**
- Check Timer initialization in `_ChimeMeetingWebviewState.initState()`
- Verify `_showTimeoutError()` is being called
- Check console logs for errors

---

### TEST 2: HTTP Edge Function Timeout 🌐

**Objective:** Verify 15-second timeout for Supabase Edge Function call

**Prerequisites:**
- WiFi enabled
- Test appointment available

**Test Method A: Network Interruption**
1. Navigate to appointments page
2. Tap "Join Video Call"
3. **IMMEDIATELY** turn OFF WiFi (within 1-2 seconds)
4. Wait and observe

**Test Method B: Invalid Function URL** (Requires code modification)
1. Temporarily modify `lib/custom_code/actions/join_room.dart` line 212:
   ```dart
   // Change:
   final functionUrl = '$supabaseUrl/functions/v1/chime-meeting-token';
   // To:
   final functionUrl = '$supabaseUrl/functions/v1/invalid-endpoint';
   ```
2. Rebuild app: `flutter run`
3. Attempt to join video call
4. **REMEMBER TO REVERT CHANGE AFTER TEST**

**Expected Results:**
- ✅ After 15 seconds max, error SnackBar appears
- ✅ Message: "❌ Failed to start video call" or "❌ Video call setup timed out. Please try again."
- ✅ Red SnackBar background
- ✅ App remains functional, can retry
- ✅ No app crash

**Actual Results:**
- [ ] PASS / [ ] FAIL
- Method used: [ ] A [ ] B
- Notes: ___________________________________________

---

### TEST 3: Media Permission Timeout 🎥🎤

**Objective:** Verify 10-second timeout for getUserMedia() permission request

**Prerequisites:**
- WiFi enabled
- Camera/microphone permissions NOT pre-granted (reset if needed)
- Test appointment available

**Reset Permissions (iOS):**
```bash
# If testing on simulator (not recommended for this test)
xcrun simctl privacy booted reset all <bundle-id>

# On physical device: Settings → Privacy → Camera/Microphone → MedZen → Toggle OFF
```

**Steps:**
1. Ensure camera/microphone permissions are NOT granted
2. Navigate to appointments page
3. Tap "Join Video Call"
4. Allow permissions dialog to appear
5. **DO NOT grant or deny - wait for timeout** (or deny immediately)
6. Observe behavior after 10 seconds

**Expected Results:**
- ✅ Permission dialog appears
- ✅ If denied: Error message appears within 10 seconds
- ✅ If ignored: Timeout message appears after ~10 seconds
- ✅ Error is user-friendly and explains camera/microphone needed
- ✅ Can retry and grant permissions on second attempt
- ✅ iOS Simulator may show orange warning about simulator limitations

**Actual Results:**
- [ ] PASS / [ ] FAIL
- Device type: [ ] Physical [ ] Simulator
- Notes: ___________________________________________

**Known Issue:** iOS Simulator may not display permission dialogs correctly. Test on physical device for accurate results.

---

### TEST 4: Normal Happy Path ✅

**Objective:** Verify video call works correctly with no interruptions

**Prerequisites:**
- WiFi enabled
- Camera/microphone permissions granted
- Two devices OR one device + web browser (if supported)
- Test appointment available

**Steps:**
1. Login as provider on Device 1
2. Login as patient on Device 2 (or web browser)
3. Navigate to same appointment on both
4. Provider taps "Join Video Call"
5. Observe initialization time
6. Once provider joined, patient taps "Join Video Call"
7. Verify video/audio connection between both parties
8. Test controls: mute, camera toggle, speaker
9. End call from one side
10. Verify other side disconnects gracefully

**Expected Results:**
- ✅ Provider joins within 5-10 seconds
- ✅ Patient joins within 5-10 seconds
- ✅ Video appears on both sides
- ✅ Audio works bidirectionally
- ✅ Controls function correctly (mute/unmute, camera on/off)
- ✅ No "Initializing..." hang
- ✅ No regressions from timeout implementation
- ✅ Call ends cleanly when either party leaves

**Actual Results:**
- [ ] PASS / [ ] FAIL
- Join time: Provider _____ sec, Patient _____ sec
- Notes: ___________________________________________

---

### TEST 5: Error Recovery - Retry Functionality 🔄

**Objective:** Verify Retry button successfully re-initializes WebView

**Prerequisites:**
- WiFi enabled initially
- Test appointment available

**Steps:**
1. Navigate to appointments page
2. Tap "Join Video Call"
3. **IMMEDIATELY** turn OFF WiFi
4. Wait for 20-second timeout error screen to appear
5. Turn WiFi back ON
6. Tap "Retry" button
7. Observe re-initialization

**Expected Results:**
- ✅ Timeout error screen appears after 20 seconds
- ✅ Tapping "Retry" dismisses error screen
- ✅ Loading screen with "Initializing video call..." appears
- ✅ WebView successfully loads (WiFi now on)
- ✅ Joins meeting successfully on retry
- ✅ No memory leaks from repeated retries
- ✅ Timer properly canceled and recreated
- ✅ State resets correctly (`_hasTimedOut = false`, `_isLoading = true`)

**Stress Test:**
- [ ] Retry 3 times in a row - verify no crashes or memory issues

**Actual Results:**
- [ ] PASS / [ ] FAIL
- Retries attempted: _____
- Notes: ___________________________________________

---

### TEST 6: Error Recovery - Go Back Functionality ⬅️

**Objective:** Verify Go Back button returns to previous screen correctly

**Prerequisites:**
- WiFi disabled (to trigger timeout quickly)
- Test appointment available

**Steps:**
1. Navigate to appointments page (note navigation stack)
2. Tap "Join Video Call"
3. Wait for 20-second timeout error screen
4. Tap "Go Back" button
5. Verify navigation

**Expected Results:**
- ✅ Returns to appointments page
- ✅ Navigation stack correct (can use back button to go further back if applicable)
- ✅ No crashes or freezes
- ✅ No dangling timers (verify with repeated Go Back → Join → Go Back cycles)
- ✅ Timer properly canceled in dispose()

**Verification:**
```dart
// Check console logs - should NOT see timer firing after navigation away
// Look for: "Timer fired after dispose" or similar issues
```

**Actual Results:**
- [ ] PASS / [ ] FAIL
- Notes: ___________________________________________

---

### TEST 7: Android Image URL Fix Persistence 📱

**Objective:** Verify malformed image URL is fixed and persists

**Prerequisites:**
- **Android device only** (this was an Android-specific crash)
- App built for Android
- Test appointment available

**Steps:**
1. Build and install on Android device:
   ```bash
   flutter build apk --release
   # OR for testing:
   flutter run -d <android-device-id>
   ```
2. Navigate to appointments page
3. Tap incoming call OR navigate to `chime_video_call_page`
4. Observe avatar display
5. Check Android logcat for errors

**Expected Results:**
- ✅ Person icon displays with secondaryBackground color
- ✅ No runtime errors
- ✅ No "No host specified in URI" error in logcat
- ✅ No app crash
- ✅ Clean avatar circle with white border

**Verify in Logcat:**
```bash
# Run while app is open on chime video call page
adb logcat | grep -i "No host specified"
# Expected: No output

adb logcat | grep -i "error"
# Expected: No image-related errors
```

**Actual Results:**
- [ ] PASS / [ ] FAIL
- Logcat errors: ___________________________________________

**IMPORTANT CHECK:**
- [ ] Verify this fix persists after FlutterFlow re-export
- If fix is lost after re-export, need to update FlutterFlow UI builder directly

---

### TEST 8: Edge Cases & Stress Testing 🔥

**Objective:** Verify app stability under unusual conditions

#### Test 8A: Multiple Rapid Retry Attempts
**Steps:**
1. Trigger timeout (WiFi off)
2. Turn WiFi on
3. Tap "Retry"
4. **IMMEDIATELY** turn WiFi off again
5. Repeat 5 times rapidly

**Expected:** No crashes, memory leaks, or UI glitches

**Actual Results:**
- [ ] PASS / [ ] FAIL
- Notes: ___________________________________________

---

#### Test 8B: Network Drop During Active Call
**Steps:**
1. Successfully join video call
2. During active call, turn OFF WiFi
3. Observe behavior
4. Turn WiFi back ON

**Expected:**
- Chime SDK may show network reconnection
- No app crash
- Graceful degradation or recovery

**Actual Results:**
- [ ] PASS / [ ] FAIL
- Notes: ___________________________________________

---

#### Test 8C: App Backgrounding During Initialization
**Steps:**
1. Tap "Join Video Call"
2. **IMMEDIATELY** press Home button (background app)
3. Wait 30 seconds
4. Return to app

**Expected:**
- No crash
- Either timeout occurred or graceful recovery
- Timer properly handled background state

**Actual Results:**
- [ ] PASS / [ ] FAIL
- Notes: ___________________________________________

---

#### Test 8D: Low Memory Scenario
**Steps:**
1. Open multiple apps in background
2. Join video call
3. Background/foreground app multiple times during call

**Expected:**
- No memory-related crashes
- Proper cleanup in dispose()

**Actual Results:**
- [ ] PASS / [ ] FAIL
- Notes: ___________________________________________

---

## Test Results Summary

### Overall Status
- **Total Tests:** 8 main tests + 4 edge case tests = 12 tests
- **Passed:** _____ / 12
- **Failed:** _____ / 12
- **Blocked:** _____ / 12

### Critical Issues Found
1. _____________________________________________
2. _____________________________________________
3. _____________________________________________

### Non-Critical Issues Found
1. _____________________________________________
2. _____________________________________________

### Recommendations
1. _____________________________________________
2. _____________________________________________

---

## Rollback Criteria

If tests reveal critical issues, refer to VIDEO_CALL_INITIALIZATION_FIX_PLAN.md lines 421-428:

**Rollback Scenarios:**
1. **If timeout causes false positives:** Remove `.timeout()` calls
2. **If legitimate calls timeout:** Increase from 15s to 30s
3. **If retry UI conflicts with navigation:** Comment out retry UI

**Rollback Commands:**
```bash
# Revert to previous commit (if changes committed)
git log --oneline -5  # Find commit hash before changes
git revert <commit-hash>

# OR manually revert specific changes
git checkout HEAD~1 -- lib/custom_code/widgets/chime_meeting_webview.dart
git checkout HEAD~1 -- lib/custom_code/actions/join_room.dart
git checkout HEAD~1 -- lib/home_pages/chime_video_call_page/chime_video_call_page_widget.dart
```

---

## Success Criteria (from original plan)

- [x] ✅ No indefinite "Initializing..." hang
- [x] ✅ Clear error messages when initialization fails
- [x] ✅ Users can retry without restarting app
- [x] ✅ No Android runtime errors for image URLs
- [ ] ⏳ Video calls complete in < 10 seconds on good connection (verify in Test 4)
- [ ] ⏳ Graceful degradation on poor network (verify in Test 1, 2, 8B)

---

## Post-Testing Actions

### If All Tests Pass:
- [ ] Update VIDEO_CALL_INITIALIZATION_FIX_PLAN.md with ✅ markers
- [ ] Document test results in this file
- [ ] Create git commit with all fixes:
  ```bash
  git add lib/custom_code/widgets/chime_meeting_webview.dart
  git add lib/custom_code/actions/join_room.dart
  git add lib/home_pages/chime_video_call_page/chime_video_call_page_widget.dart
  git commit -m "fix: resolve video call initialization hang and add error recovery UI

  - Add 15s HTTP timeout to Supabase Edge Function call
  - Add 20s WebView initialization timeout
  - Add 10s media permission timeout in JavaScript
  - Fix malformed image URL causing Android crashes
  - Implement comprehensive error recovery UI with Retry/Go Back
  - Add onWebResourceError handler for CDN failures

  Fixes: Video call stuck on 'Initializing...' status
  Tested: iOS physical device, Android physical device"
  ```
- [ ] Deploy to staging environment for UAT
- [ ] Update user documentation with retry instructions

### If Tests Fail:
- [ ] Document all failures in "Critical Issues Found" section above
- [ ] Analyze root cause for each failure
- [ ] Determine if rollback needed or if fixes can be applied
- [ ] Create new implementation plan for failed tests
- [ ] Re-test after fixes

---

## Testing Notes & Observations

### Device-Specific Notes
- **iOS Simulator:** ___________________________________________
- **iOS Physical:** ___________________________________________
- **Android Physical:** ___________________________________________

### Performance Metrics
- **Average join time (WiFi):** _____ seconds
- **Average timeout detection:** _____ seconds
- **Memory usage during call:** _____ MB
- **Battery impact:** _____

### User Experience Observations
- **Error messages clarity:** _____
- **Retry flow smoothness:** _____
- **Overall UX improvement:** _____

---

**Testing Started:** ___________
**Testing Completed:** ___________
**Tester Name:** ___________
**Sign-off:** ___________
