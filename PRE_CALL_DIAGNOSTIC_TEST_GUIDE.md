# Pre-Call Dialog Diagnostic Test Guide

**Date:** January 16, 2026
**Status:** ✅ ENHANCED DIAGNOSTIC LOGGING DEPLOYED

---

## What Changed

Enhanced diagnostic logging has been added to the **pre-call clinical notes dialog** in `lib/custom_code/actions/join_room.dart` (lines 602-660) to capture exact condition values and any exceptions.

This matches the diagnostic framework already deployed for the post-call dialog, enabling systematic identification of why the dialog may not be appearing.

---

## Test Steps

### 1. **Clean and Rebuild**
```bash
flutter clean
flutter pub get
```

### 2. **Run App in Debug Mode**

**Web (Chrome) - RECOMMENDED:**
```bash
flutter run -d chrome -v 2>&1 | tee pre_call_test.log
```

**Android Emulator:**
```bash
flutter run -d emulator-5554 -v 2>&1 | tee pre_call_test.log
```

### 3. **Log in as Medical Provider**
- Use provider account (not patient)
- Navigate to Appointments page
- Find an upcoming appointment with a patient

### 4. **Start Video Call**
- Click "Start Call" button
- Pre-joining dialog should appear (microphone/camera permissions)
- Grant all permissions
- **OBSERVE:** Pre-call clinical notes dialog should appear BEFORE "Join Call" button

### 5. **Capture Debug Output**

**Chrome DevTools (Web):**
1. Press `Ctrl+Shift+I` to open DevTools
2. Click **Console** tab
3. Search for: `🔍 Checking if pre-call dialog`

**Terminal Log File:**
```bash
grep -n -E "(🔍 Checking|isProvider value|context.mounted value|Conditions not met|Both conditions|Error in pre-call)" pre_call_test.log
```

---

## Expected Debug Output - 5 Scenarios

### ✅ **Scenario 1: SUCCESS** (Dialog Should Appear)

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

**What it means:** Both conditions are met, dialog displays correctly. User should see the clinical notes review screen with patient information.

---

### ⚠️ **Scenario 2: NOT PROVIDER** (Dialog Won't Show)

```
🔍 Checking if pre-call dialog should be shown...
🔍 isProvider value: false
🔍 context.mounted value: true
⚠️ Conditions not met - isProvider: false, context.mounted: true
   → Not a provider - only providers see pre-call dialog
```

**What it means:** User is not recognized as a provider.
- **If you logged in as PROVIDER:** This is a bug - investigate parameter passing in `appointments_widget.dart` line 839
- **If you logged in as PATIENT:** This is correct - patients don't see pre-call dialog

---

### ⚠️ **Scenario 3: CONTEXT NOT MOUNTED** (Context Lifecycle Issue)

```
🔍 Checking if pre-call dialog should be shown...
🔍 isProvider value: true
🔍 context.mounted value: false
⚠️ Conditions not met - isProvider: true, context.mounted: false
   → Context not mounted - cannot show pre-call dialog
```

**What it means:** BuildContext became invalid before dialog could show.
- **Likely cause:** Appointments page disposed too quickly
- **Solution to try:** May need refactoring of navigation flow

---

### ⚠️ **Scenario 4: CONTEXT BECOMES UNMOUNTED AFTER DIALOG ATTEMPT** (Rare)

```
🔍 Checking if pre-call dialog should be shown...
🔍 isProvider value: true
🔍 context.mounted value: true
✅ Both conditions met - showing pre-call clinical notes dialog
⚠️ Context became unmounted before pre-call dialog could show
```

**What it means:** Context became invalid while trying to show dialog.
- **Likely cause:** Widget tree changed during dialog initialization
- **Solution:** May need deeper navigation flow refactoring

---

### ❌ **Scenario 5: EXCEPTION THROWN** (Error in Dialog Logic)

```
🔍 Checking if pre-call dialog should be shown...
🔍 isProvider value: true
🔍 context.mounted value: true
✅ Both conditions met - showing pre-call clinical notes dialog
❌ Error showing pre-call dialog: [Error message here]
   Stack trace: [Stack trace details]
```

**What it means:** An exception occurred while trying to show the dialog.
- Check the error message and stack trace for specific issue
- Common causes:
  - Missing or invalid `patientId` parameter
  - Database query failure (patient_profiles not found)
  - Widget tree corruption

---

## Interpretation & Next Steps

| Scenario | Action |
|----------|--------|
| **1 - SUCCESS** | Dialog working correctly. If not visible on screen, check if dialog is rendered off-screen. |
| **2 - NOT PROVIDER (but you are)** | Bug in isProvider parameter. Check `appointments_widget.dart` line 839. |
| **2 - NOT PROVIDER (you're patient)** | Expected behavior - patients don't see this dialog. |
| **3 - CONTEXT NOT MOUNTED** | Architecture issue - may need Navigator refactoring. |
| **4 - CONTEXT UNMOUNTED DURING** | Similar to #3 - navigation flow issue. |
| **5 - EXCEPTION** | Fix specific exception based on error message. Check patient_profiles table for missing data. |

---

## Visual Quick Reference

```
Pre-Call Dialog Flow:
┌─────────────────────────────────────────┐
│ Provider starts video call from         │
│ appointments page                       │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ isProvider check (line 607)              │
│ context.mounted check (line 605)         │
└──────────────┬──────────────────────────┘
               │
      ┌────────┴────────┐
      │                 │
    PASS               FAIL
      │                 │
      ▼                 ▼
┌──────────────┐  ┌──────────────────┐
│ Show Dialog  │  │ Skip Dialog      │
│ (Scenario 1) │  │ (Scenarios 2-4)  │
└──────────────┘  └──────────────────┘
      │
      ▼
 User reviews patient
 biometrics & history
      │
      ▼
 User clicks "Start Call"
 or dismisses dialog
```

---

## Files Modified This Session

```
📝 lib/custom_code/actions/join_room.dart
   ├─ Lines 602-660: Enhanced diagnostic logging for pre-call dialog
   │  ├─ Captures isProvider value explicitly
   │  ├─ Captures context.mounted value explicitly
   │  ├─ Logs which condition fails if either is false
   │  ├─ Exception handling with stack trace
   │  └─ Step-by-step progress logging
   └─ Compilation verified: ✅ No errors
```

---

## Important Notes

1. **Diagnostic logging pattern** matches post-call dialog (lines 726-789) for consistency
2. **Context safety:** Added explicit `context.mounted` check after async gaps (line 615)
3. **Exception handling:** All dialog operations wrapped in try-catch for complete error visibility
4. **Backward compatible:** No behavior changes - only added logging

---

## Test Checklist

- [ ] Code compiled successfully (`dart analyze` shows no errors)
- [ ] App running in debug mode with `-v` flag
- [ ] Logged in as a **medical provider**
- [ ] Navigated to an appointment
- [ ] Started video call
- [ ] Observed whether pre-call dialog appeared or not
- [ ] Captured debug output from logs
- [ ] Identified which scenario matches the output
- [ ] Saved the diagnostic output for analysis

---

## Expected Timeline

1. **Run test:** 5-10 minutes
2. **Capture logs:** 1 minute
3. **Identify scenario:** 2-3 minutes using this guide
4. **Report results:** Provide scenario number and log output
5. **Implement fix:** Depends on scenario identified

---

**Status:** ✅ READY FOR TESTING - Enhanced diagnostic logging deployed and verified
