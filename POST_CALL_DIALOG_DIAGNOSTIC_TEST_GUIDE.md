# Post-Call Dialog Diagnostic Test Guide

## Objective
Determine why the post-call clinical notes dialog is not appearing after a provider ends a video call.

**Enhanced diagnostic logging has been added to `lib/custom_code/actions/join_room.dart` (lines 726-789)** to capture the exact condition values and any exceptions.

---

## Test Steps

### 1. **Clean and Rebuild**
```bash
flutter clean
flutter pub get
```

### 2. **Run App in Debug Mode with Log Output**

**Option A: Flutter Web (Chrome) - RECOMMENDED**
```bash
flutter run -d chrome -v 2>&1 | tee video_call_test.log
```

**Option B: Android Emulator**
```bash
flutter run -d emulator-5554 -v 2>&1 | tee video_call_test.log
```

**Option C: iOS Simulator**
```bash
flutter run -d "iPhone 15" -v 2>&1 | tee video_call_test.log
```

### 3. **Navigate to a Provider Appointment**
- Log in as a **medical provider** (not a patient)
- Go to Appointments page
- Find an upcoming appointment
- Click "Start Call" or similar button

### 4. **Go Through the Pre-Call Flow**
- ✅ Allow permissions in the pre-joining dialog
- ✅ Click "Join Call" button
- ✅ Wait for video call to fully load (Chime SDK initializes)

### 5. **End the Video Call as Provider**
- In the video call interface, find the "End Call" or "Hang Up" button
- Click to end the call
- Wait for the video call page to close and return to appointments page

### 6. **Observe the Post-Call Dialog**
- **EXPECTED:** A clinical notes dialog should appear asking you to review/save SOAP notes
- **IF DIALOG APPEARS:** Great! The fix worked. Look for `✅ Both conditions met - showing post-call clinical notes dialog` in logs
- **IF DIALOG DOES NOT APPEAR:** Check the logs for the diagnostic output (see section below)

---

## Capturing Debug Output

### Where to Look for Logs

**Chrome DevTools (Web):**
1. Open Chrome DevTools: `Ctrl+Shift+I` (or `Cmd+Shift+I` on Mac)
2. Click **Console** tab
3. Search for messages starting with: `🔍 Checking if post-call dialog`

**Android Logcat (Emulator/Device):**
```bash
flutter logs | grep -E "(🔍|✅|⚠️|❌|Checking if post-call|isProvider|context.mounted)"
```

**iOS Console (Simulator):**
```bash
log stream --predicate 'eventMessage contains "post-call"' --level debug
```

**Terminal Log File (if using tee):**
```bash
grep -n -E "(🔍 Checking|isProvider value|context.mounted value|Conditions not met|Both conditions|Error in post-call)" video_call_test.log
```

---

## Expected Debug Output

### Scenario 1: SUCCESS ✅ (Dialog Should Appear)

```
🔍 RETURNED FROM NAVIGATOR.PUSH
🔍 Video call page was closed
🔍 Checking if post-call dialog should be shown...
🔍 isProvider value: true
🔍 context.mounted value: true
✅ Both conditions met - showing post-call clinical notes dialog
🔍 After delay - context.mounted: true
✅ Context still mounted - proceeding with dialog
🔍 PostCallClinicalNotesDialog builder executing
🔍 [User interacts with dialog...]
🔍 Post-call clinical notes saved
✅ Post-call dialog closed - running cleanup
🔥 Triggering video call process cleanup...
```

**What it means:** Both conditions are met, dialog displays, user saves notes, cleanup runs. This is the desired behavior.

---

### Scenario 2: isProvider is FALSE ❌ (Only providers should see dialog)

```
🔍 RETURNED FROM NAVIGATOR.PUSH
🔍 Video call page was closed
🔍 Checking if post-call dialog should be shown...
🔍 isProvider value: false
🔍 context.mounted value: true
⚠️ Conditions not met - isProvider: false, context.mounted: true
   → Not a provider - only providers see post-call dialog
```

**What it means:** The user is not recognized as a provider, so the dialog correctly doesn't show.
- **If you logged in as PROVIDER:** This is a bug - investigate why `isProvider` parameter is false
- **If you logged in as PATIENT:** This is correct - patients shouldn't see the dialog

---

### Scenario 3: Context NOT MOUNTED ❌ (Context lifecycle issue)

```
🔍 RETURNED FROM NAVIGATOR.PUSH
🔍 Video call page was closed
🔍 Checking if post-call dialog should be shown...
🔍 isProvider value: true
🔍 context.mounted value: false
⚠️ Conditions not met - isProvider: true, context.mounted: false
   → Context not mounted - cannot show dialog
```

**What it means:** The BuildContext became invalid/disposed before we tried to show the dialog.
- **Likely cause:** The appointments page was disposed or navigated away too quickly
- **Solution:** May need to add longer delay before showing dialog, or use a different context handling approach

---

### Scenario 4: Context Becomes Unmounted After Delay ⚠️

```
🔍 RETURNED FROM NAVIGATOR.PUSH
🔍 Video call page was closed
🔍 Checking if post-call dialog should be shown...
🔍 isProvider value: true
🔍 context.mounted value: true
✅ Both conditions met - showing post-call clinical notes dialog
🔍 After delay - context.mounted: false
⚠️ Context became unmounted after delay - skipping dialog
```

**What it means:** Context was valid initially, but became invalid during the 300ms delay.
- **Likely cause:** Widget tree changed or parent widget was disposed
- **Solution:** Extend the delay time, or use try-catch in dialog builder to handle disposal

---

### Scenario 5: EXCEPTION THROWN ❌

```
🔍 RETURNED FROM NAVIGATOR.PUSH
🔍 Video call page was closed
🔍 Checking if post-call dialog should be shown...
🔍 isProvider value: true
🔍 context.mounted value: true
✅ Both conditions met - showing post-call clinical notes dialog
🔍 After delay - context.mounted: true
✅ Context still mounted - proceeding with dialog
❌ Error in post-call dialog logic: [Error message here]
   Stack trace: [Stack trace]
```

**What it means:** An unexpected exception occurred while trying to show the dialog.
- Check the error message and stack trace for the specific issue
- Common issues:
  - Missing parameters to PostCallClinicalNotesDialog
  - Navigation stack issues
  - Parent widget disposal during dialog show

---

## Interpretation Guide

### If you see Scenario 1 (SUCCESS) ✅
The fix is working correctly. Post-call dialog should be visible on screen.

### If you see Scenario 2 (isProvider = false)
**Is the logged-in user a provider?**
- YES → Bug in isProvider parameter passing (investigate appointments_widget.dart line 839)
- NO → Expected behavior (patients don't see this dialog)

### If you see Scenario 3 (context not mounted initially)
The context became invalid immediately after returning from video call.
- **Fix to try:** Increase delay from 300ms to 500-800ms
- **If that doesn't work:** May need deeper investigation of page lifecycle

### If you see Scenario 4 (context valid then becomes unmounted)
The context is disposed during the delay.
- **Fix to try:** Increase delay duration (500ms, 1000ms)
- **Alternative:** Use `Navigator.push` to a new full-screen route instead of returning

### If you see Scenario 5 (Exception)
An error occurred. Review the exception message:
- If it's about PostCallClinicalNotesDialog parameters, check parameter names match
- If it's about Navigator, there may be a navigation stack issue
- If it's about context, try wrapping the dialog setup in a Future.delayed with longer duration

---

## Additional Debugging Checks

### Check that isProvider is being passed correctly:
```bash
grep -n "await actions.joinRoom" lib/all_users_page/appointments/appointments_widget.dart
```
You should see:
- `true` for medical_provider role (line ~839)
- `false` for patient role (line ~859)

### Check for any exceptions in the joinRoom function overall:
```bash
grep -n "❌ Error setting up video call" video_call_test.log
```
If you see this, there was a failure earlier in the joinRoom function before reaching post-call dialog logic.

### Check the video call itself completed successfully:
```bash
grep -n "Video call page was closed" video_call_test.log
```
If you don't see this message, the video call page didn't return properly (Navigator.pop issue).

---

## Next Steps After Test

1. **Run the test** and capture the full debug output
2. **Find the diagnostic section** (lines with 🔍, ✅, ⚠️, or ❌)
3. **Identify which Scenario** matches your output
4. **Report back with:**
   - Which scenario you're seeing
   - The exact logged output for the post-call dialog section
   - Whether the dialog appears on screen or not
5. **Based on the scenario**, a targeted fix will be implemented

---

## Test Checklist

- [ ] Code compiled successfully
- [ ] App running in debug mode
- [ ] Logged in as a **medical provider**
- [ ] Navigated to an appointment
- [ ] Started and joined video call
- [ ] Waited for video call to fully load
- [ ] Ended the call as provider
- [ ] Observed whether dialog appeared or not
- [ ] Captured debug output from logs
- [ ] Identified which scenario matches the output
- [ ] Saved the diagnostic output for analysis
