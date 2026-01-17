# FlutterFlow Cloud Project Cleanup - Step-by-Step Checklist

**Goal:** Remove all references to the old `ChimeMeetingWebview` widget from FlutterFlow's cloud project

**Time Required:** 10-15 minutes

---

## Pre-Cleanup Checklist

- [ ] Open https://app.flutterflow.io in your browser
- [ ] Log in to your account
- [ ] Open the MedZen project
- [ ] Have this checklist ready to mark off items

---

## Step 1: Clean Custom Widgets

1. **Navigate to Custom Code**
   - [ ] Click **Custom Code** in the left sidebar
   - [ ] Click **Widgets** tab

2. **Check for Old Widget**
   - [ ] Look for `ChimeMeetingWebview` in the widgets list
   - [ ] If found, click on it
   - [ ] Click **Delete** or **Archive**
   - [ ] Confirm deletion

3. **Verify New Widget**
   - [ ] Confirm `ChimeMeetingEnhanced` is present
   - [ ] Click on `ChimeMeetingEnhanced`
   - [ ] Verify it's marked as **Active**
   - [ ] Check that parameters include:
     - `meetingData` (String)
     - `attendeeData` (String)
     - `userName` (String)
     - `userProfileImage` (String)
     - `userRole` (String)
     - `providerName` (String)
     - `providerRole` (String)
     - `onCallEnded` (Callback)

---

## Step 2: Clean Custom Actions

1. **Check join_room Action**
   - [ ] Click **Custom Code** → **Actions**
   - [ ] Find and open `join_room`
   - [ ] Scroll to the video call widget instantiation (around line 444)
   - [ ] Verify it uses `ChimeMeetingEnhanced` (NOT `ChimeMeetingWebview`)
   - [ ] If it shows the old widget, update it in the code editor

2. **Check Other Video Call Actions**
   - [ ] Search for any other actions that might call video widgets
   - [ ] Update any old references to use `ChimeMeetingEnhanced`

---

## Step 3: Update Pages Using Video Calls

**Pages to check:**

### Provider Landing Page
- [ ] Open `medical_provider/provider_landing_page`
- [ ] Check for any Custom Widget components
- [ ] If any use `ChimeMeetingWebview`, replace with `ChimeMeetingEnhanced` or remove
- [ ] Save changes

### Patient Landing Page
- [ ] Open `patients_folder/patient_landing_page`
- [ ] Check for any Custom Widget components
- [ ] If any use `ChimeMeetingWebview`, replace with `ChimeMeetingEnhanced` or remove
- [ ] Save changes

### Join Call Page
- [ ] Open `home_pages/join_call`
- [ ] Check for any Custom Widget components
- [ ] If any use `ChimeMeetingWebview`, replace with `ChimeMeetingEnhanced` or remove
- [ ] Save changes

### Appointments Pages
- [ ] Search for pages with "appointment" in the name
- [ ] Check each for video call widgets
- [ ] Update any old references
- [ ] Save changes

### Video Call Page (Incoming Call UI)
- [ ] Open `home_pages/chime_video_call_page`
- [ ] This should be just UI (no actual video widget)
- [ ] Verify no Custom Widget components are present
- [ ] If found, remove them

---

## Step 4: Clean Asset References

1. **Check Assets Folder**
   - [ ] Click **Settings & Integrations** (gear icon)
   - [ ] Click **Assets** tab
   - [ ] Look for `assets/html/` folder
   - [ ] If found, click the **trash icon** to delete it
   - [ ] Confirm deletion

2. **Verify Remaining Assets**
   - [ ] Confirm only these folders remain:
     - `assets/fonts/`
     - `assets/images/`
     - `assets/videos/`
     - `assets/audios/`
     - `assets/rive_animations/`
     - `assets/pdfs/`
     - `assets/jsons/`

---

## Step 5: Clean Project Dependencies

1. **Check pubspec.yaml (if accessible in FlutterFlow)**
   - [ ] Click **Settings & Integrations**
   - [ ] Look for **Dependencies** or **pubspec.yaml** editor
   - [ ] Verify no references to `assets/html/`
   - [ ] Save if you made changes

---

## Step 6: Clear Cache

1. **Clear FlutterFlow Cache**
   - [ ] Click the **three dots menu** (⋮) in top right corner
   - [ ] Select **Clear Cache**
   - [ ] Wait for confirmation message
   - [ ] **Refresh the page** (Ctrl+R or Cmd+R / F5)

2. **Clear Browser Cache (optional but recommended)**
   - [ ] Press Ctrl+Shift+Delete (Windows/Linux) or Cmd+Shift+Delete (Mac)
   - [ ] Select "Cached images and files"
   - [ ] Clear for "Last hour" or "Last day"
   - [ ] Close and reopen browser

---

## Step 7: Rebuild Project

1. **Force Rebuild**
   - [ ] In FlutterFlow, click **Build** in top menu
   - [ ] Select **Clean Build** or **Rebuild**
   - [ ] Wait for build to complete

---

## Step 8: Test in FlutterFlow

1. **Run Test**
   - [ ] Click **Run** or **Test** button
   - [ ] Select your test device/emulator
   - [ ] Wait for app to load
   - [ ] Check console for errors
   - [ ] Verify NO asset errors appear

2. **Check Specific Errors**
   - [ ] Look for `Asset for key "assets/html/chime_meeting.html" not found` ❌
   - [ ] Should NOT appear anymore
   - [ ] Look for `ChimeMeetingWebview` references ❌
   - [ ] Should NOT appear anymore

---

## Step 9: Export and Verify Locally

1. **Export Code**
   - [ ] Click **Export Code** button
   - [ ] Download the ZIP file
   - [ ] Extract to a temporary folder

2. **Run Verification Script**
   - [ ] Open terminal
   - [ ] Navigate to this project directory
   - [ ] Run: `./verify_flutterflow_cleanup.sh`
   - [ ] Check results - should show all ✅

---

## Step 10: Final Verification

- [ ] No `ChimeMeetingWebview` references anywhere
- [ ] No `assets/html/` folder in assets
- [ ] Only `ChimeMeetingEnhanced` widget exists
- [ ] All pages using video calls updated
- [ ] FlutterFlow Run/Test works without asset errors
- [ ] Local build still works

---

## Troubleshooting

### If errors still appear after cleanup:

1. **Contact FlutterFlow Support**
   - Go to https://flutterflow.io/support
   - Create a ticket explaining:
     - "Old custom widget (ChimeMeetingWebview) still being referenced"
     - "Asset error for assets/html/chime_meeting.html persists"
     - "Already deleted widget and cleared cache"
   - Ask them to check backend for orphaned references

2. **Alternative: Work Locally**
   - Export code from FlutterFlow
   - Work and test locally (confirmed working)
   - Deploy from local build (skip FlutterFlow deployment)

---

## Success Criteria

✅ You've successfully cleaned up when:
- No asset errors when running in FlutterFlow
- No `ChimeMeetingWebview` found in widget search
- Video calls work using `ChimeMeetingEnhanced`
- Exported code matches local code
- Verification script shows all green checks

---

## Need Help?

- See: `FIX_FLUTTERFLOW_VIDEO_WIDGET.md` for detailed explanations
- See: `VIDEO_CALL_FIX_COMPLETE.md` for technical background
- Run: `./verify_flutterflow_cleanup.sh` for automated verification
