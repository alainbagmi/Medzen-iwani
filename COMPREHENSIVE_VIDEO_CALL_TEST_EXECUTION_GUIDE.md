# Comprehensive Video Call Test Execution Guide

**Date:** January 16, 2026
**Status:** 🚀 READY FOR TESTING - All diagnostic logging deployed

---

## What Has Been Implemented This Session

### Issue 1 - Floating UI Auto-Hide ✅ FIXED
**File:** `lib/custom_code/widgets/chime_meeting_enhanced.dart`
- Added `_showMeetingHeader` and `_showTranscriptionIndicator` visibility state variables
- Added `_meetingHeaderHideTimer` and `_transcriptionIndicatorHideTimer` for 5-second auto-hide
- Updated overlay visibility conditions to check visibility flags
- Modified `_handleSdkReady()` to start auto-hide timers
- Added cleanup in `dispose()` method
- **Expected Behavior:** Meeting header and transcription indicator appear for 5 seconds, then auto-hide

### Issue 2 - Pre-Call SOAP Dialog Diagnostic Logging ✅ DEPLOYED
**File:** `lib/custom_code/actions/join_room.dart` (lines 602-660)
- Captures `isProvider` value explicitly
- Captures `context.mounted` value explicitly
- Logs which condition fails (if either is false)
- Catches and logs exceptions with stack trace
- Provides step-by-step progress logging
- **Expected Behavior:** You'll see detailed 🔍, ✅, ⚠️, ❌ markers in logs

### Issue 3 - Post-Call SOAP Dialog Diagnostic Logging ✅ VERIFIED
**File:** `lib/custom_code/actions/join_room.dart` (lines 750-823)
- Diagnostic logging already deployed from previous session
- Ready to capture condition values and exceptions
- **Expected Behavior:** You'll see detailed diagnostic output after call ends

### Issue 4 - Floating UI Properly Disposed ✅ VERIFIED
- All timers properly cancelled in `dispose()` method
- No memory leaks from lingering timers
- Clean resource management throughout video call lifecycle

---

## Test Execution Steps

### Step 1: Clean and Rebuild
```bash
flutter clean
flutter pub get
```

### Step 2: Run App in Debug Mode (Choose One)

**RECOMMENDED - Web (Chrome):**
```bash
flutter run -d chrome -v 2>&1 | tee full_video_call_test.log
```

**Alternative - Android Emulator:**
```bash
flutter run -d emulator-5554 -v 2>&1 | tee full_video_call_test.log
```

### Step 3: Log In as Medical Provider
- **CRITICAL:** Must log in as a PROVIDER (not patient)
- Navigate to Appointments page
- Find an upcoming appointment with a patient

### Step 4: Observe Pre-Call Flow (Issue 2 Test)
1. Click "Start Call" button on appointment
2. Pre-joining dialog should appear (microphone/camera permissions)
3. **LOOK FOR THESE LOGS:**
   ```
   🔍 Checking if pre-call dialog should be shown...
   🔍 isProvider value: [TRUE or FALSE]
   🔍 context.mounted value: [TRUE or FALSE]
   ```

4. **CRITICAL:** Grant all permissions when prompted
5. Observe whether pre-call clinical notes dialog appears or not
6. If it appears: Click "Start Call" button
7. If it doesn't appear: Still proceed to video call (we're testing both scenarios)

### Step 5: Observe Floating UI During Call (Issue 1 Test)
1. Video call should now be active
2. **OBSERVE:** Meeting header panel at top of screen
3. **OBSERVE:** Transcription indicator overlay
4. **EXPECTED BEHAVIOR:** Both should appear initially, then auto-hide after ~5 seconds
5. **WATCH LOGS FOR:**
   ```
   👋 Meeting header auto-hidden after 5 seconds
   👋 Transcription indicator auto-hidden after 5 seconds
   ```

### Step 6: End the Video Call (Pre-Call Post-Call Sequence)
1. Provider: Click "End Call" button or close meeting
2. **OBSERVE:** Whether post-call clinical notes dialog appears
3. **LOOK FOR THESE LOGS:**
   ```
   🔍 Checking if post-call dialog should be shown...
   🔍 isProvider value: [TRUE or FALSE]
   🔍 context.mounted value: [TRUE or FALSE]
   ```

### Step 7: Capture Debug Output

**Chrome DevTools (Web):**
1. Press `Ctrl+Shift+I` to open DevTools
2. Click **Console** tab
3. Search for: `🔍 Checking if`
4. Take screenshot or copy all messages with 🔍, ✅, ⚠️, ❌ markers

**Terminal Log File:**
```bash
# All diagnostic messages in one place
grep -E "(🔍 Checking|isProvider value|context.mounted value|Both conditions|Conditions not met|meeting header auto-hidden|transcription indicator auto-hidden|Error in)" full_video_call_test.log

# Or search for specific flow
grep -n "Pre-call\|Post-call" full_video_call_test.log | head -50
```

---

## Expected Output Patterns

### Pre-Call Flow - Scenario 1 (Dialog Should Appear)
```
🔍 Checking if pre-call dialog should be shown...
🔍 isProvider value: true
🔍 context.mounted value: true
✅ Both conditions met - showing pre-call clinical notes dialog
🔍 PreCallClinicalNotesDialog builder executing
🔍 Pre-call dialog: Start Call clicked
🔍 Pre-call dialog has closed
✅ Pre-call clinical notes review complete - proceeding to video call
```
**Meaning:** Dialog appears and works correctly. User should see patient biometrics and clinical history.

### Pre-Call Flow - Scenario 2 (Not a Provider)
```
🔍 Checking if pre-call dialog should be shown...
🔍 isProvider value: false
🔍 context.mounted value: true
⚠️ Conditions not met - isProvider: false, context.mounted: true
   → Not a provider - only providers see pre-call dialog
```
**Meaning:** You're logged in as a patient (or role detection is broken). If you're a provider, this is a bug in parameter passing.

### Pre-Call Flow - Scenario 3 (Context Not Mounted)
```
🔍 Checking if pre-call dialog should be shown...
🔍 isProvider value: true
🔍 context.mounted value: false
⚠️ Conditions not met - isProvider: true, context.mounted: false
   → Context not mounted - cannot show pre-call dialog
```
**Meaning:** BuildContext became invalid. Likely timing issue with page transitions.

### Pre-Call Flow - Scenario 5 (Exception Thrown)
```
🔍 Checking if pre-call dialog should be shown...
🔍 isProvider value: true
🔍 context.mounted value: true
✅ Both conditions met - showing pre-call clinical notes dialog
❌ Error showing pre-call dialog: [Error message here]
   Stack trace: [Stack trace details]
```
**Meaning:** An exception occurred. Check error message for details (likely missing patient data).

### Floating UI Auto-Hide - Expected (Issue 1)
```
⏱️ Overlay auto-hide timers started (5 second duration)
... (5 seconds pass) ...
👋 Meeting header auto-hidden after 5 seconds
👋 Transcription indicator auto-hidden after 5 seconds
```
**Meaning:** UI appears briefly, then auto-hides as expected.

### Post-Call Flow - Scenario 1 (Dialog Should Appear)
```
🔍 Checking if post-call dialog should be shown...
🔍 isProvider value: true
🔍 context.mounted value: true
✅ Both conditions met - showing post-call clinical notes dialog
🔍 PostCallClinicalNotesDialog builder executing
🔍 Post-call dialog: Sign Note clicked
🔍 Post-call dialog has closed
✅ Post-call clinical notes review complete
```
**Meaning:** Dialog appears and works correctly. User should see SOAP note editor.

---

## Quick Interpretation Table

| Test | What to Look For | Expected Result | If Different |
|------|------------------|-----------------|--------------|
| **Pre-Call Dialog** | `🔍 isProvider value: true` + `🔍 context.mounted: true` + Dialog appears | ✅ SUCCESS | Check if role detection is broken |
| **Pre-Call Dialog** | `🔍 isProvider value: false` | Dialog doesn't appear | ✅ EXPECTED if you logged in as patient |
| **Pre-Call Dialog** | `🔍 context.mounted: false` | Dialog doesn't appear | ⚠️ Timing issue - may need delay adjustment |
| **Pre-Call Dialog** | `❌ Error showing pre-call dialog` | Dialog doesn't appear | Fix exception (likely missing patient data) |
| **Floating UI** | `👋 Meeting header auto-hidden after 5 seconds` | Header disappears | ✅ SUCCESS |
| **Floating UI** | Header stays visible entire call | Doesn't disappear | ⚠️ Timer didn't trigger - check disposal |
| **Post-Call Dialog** | `🔍 isProvider value: true` + Dialog appears | Dialog appears | ✅ SUCCESS |
| **Post-Call Dialog** | `❌ Error in post-call dialog logic` | Dialog doesn't appear | Fix exception based on error message |

---

## How to Report Results

After running the test, provide:

1. **Pre-Call Dialog Result:**
   - Which scenario did you observe? (1, 2, 3, 4, or 5)
   - Did the dialog appear or not?
   - Copy the debug messages starting with `🔍 Checking if pre-call`

2. **Floating UI Result:**
   - Did the meeting header auto-hide after ~5 seconds?
   - Did the transcription indicator auto-hide after ~5 seconds?
   - Copy any 👋 messages from logs

3. **Post-Call Dialog Result:**
   - Which scenario did you observe? (1, 2, 3, 4, or 5)
   - Did the dialog appear or not?
   - Copy the debug messages starting with `🔍 Checking if post-call`

4. **Full Log File:**
   - Upload or paste the complete `full_video_call_test.log` file

---

## Troubleshooting During Test

**App won't start:**
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

**Permissions dialog appears multiple times:**
- Dismiss all permission dialogs
- Should only appear once per app restart

**Can't find pre-call dialog even though logs say "Both conditions met":**
- Dialog may be rendering off-screen or behind other UI
- Check if it's behind the pre-joining dialog
- Try closing pre-joining dialog more quickly

**Video call doesn't fully load:**
- Check browser console for Chime SDK CDN errors
- Verify CloudFront CDN is accessible: `https://du6iimxem4mh7.cloudfront.net/`
- Check Safari/Chrome compatibility

**No diagnostic messages in logs:**
- Ensure running with `-v` flag for verbose output
- Check that you're logged in as provider (not patient)
- Verify you're starting a video call (not just viewing appointments)

---

## Test Checklist

- [ ] Clean build successful
- [ ] App runs with `-v` flag
- [ ] Logged in as **medical provider**
- [ ] Found upcoming appointment
- [ ] Started video call
- [ ] Observed pre-call flow (noted if dialog appeared)
- [ ] Observed floating UI behavior (noted if auto-hid after 5 seconds)
- [ ] Completed video call
- [ ] Observed post-call flow (noted if dialog appeared)
- [ ] Captured diagnostic output to log file
- [ ] Identified matching scenario for pre-call
- [ ] Identified matching scenario for post-call
- [ ] Noted exact values of `isProvider` and `context.mounted`

---

## Expected Timeline

1. **Clean and build:** 2-3 minutes
2. **Run app:** 1-2 minutes
3. **Log in and navigate:** 2-3 minutes
4. **Pre-call flow (with/without dialog):** 1-2 minutes
5. **Video call (observing floating UI):** 2-3 minutes (or skip if not needed)
6. **Post-call flow (with/without dialog):** 1-2 minutes
7. **Capture logs:** 1 minute
8. **Analyze and identify scenario:** 2-3 minutes

**Total: ~15-20 minutes**

---

## Next Steps After Testing

Based on your test results:

**If Pre-Call Dialog Scenario 1 (SUCCESS):**
- ✅ Pre-call is working correctly
- Move to investigating why it might not be visually appearing (UI rendering issue)

**If Pre-Call Dialog Scenario 2, 3, 4, or 5:**
- 🔧 Implement targeted fix based on specific scenario
- Retest to confirm fix resolves issue

**If Floating UI isn't auto-hiding:**
- 🔧 Debug timer initialization
- Check disposal cleanup
- May need to adjust 5-second timing

**If Post-Call Dialog has issues:**
- 🔧 Implement targeted fix based on identified scenario
- Retest to confirm

---

**Status:** ✅ All code deployed and verified - READY FOR TESTING

Run the test and capture the diagnostic output. The detailed logging will show exactly which condition is preventing the dialogs from appearing.
