# SOAP Note Display Testing Guide

## Overview
This guide tests the UI/UX improvements for SOAP note display in pre-call and post-call dialogs.

**Compilation Status**: ✅ All errors fixed, build successful

---

## Test 1: Pre-Call SOAP Display (Patient with Prior Notes)

### Prerequisites
- Patient with at least one existing SOAP note in database
- Provider role logged in
- Appointment scheduled with that patient

### Steps
1. Navigate to Patient Landing Page
2. Select an appointment with a patient who has prior SOAP notes
3. Click "Start Call" or "Join Call" button
4. **Expected**: PreCallClinicalNotesDialog appears with:
   - ✅ Patient information section (blood type, allergies, medications, conditions)
   - ✅ "Previous Clinical Context" section
   - ✅ All 12 SOAP sections visible and expanded:
     - Subjective: HPI, ROS, Medications, Allergies, History
     - Objective: Vital Signs, Physical Exam
     - Assessment: Problem List
     - Plan: 5 sub-sections (Medications, Labs, Follow-up, Education, Precautions)
     - Safety Alerts
     - Coding

### Verification
- [ ] Dialog displays without errors
- [ ] All patient biometrics load correctly
- [ ] Prior SOAP note sections display with data
- [ ] Scrolling works smoothly
- [ ] "Start Call" button enabled and clickable

---

## Test 2: Pre-Call SOAP Display (Patient with No Prior Notes)

### Prerequisites
- Newly created patient with no prior SOAP notes
- Provider role logged in
- Appointment scheduled

### Steps
1. Navigate to Patient Landing Page
2. Select an appointment with a new patient (no prior notes)
3. Click "Start Call" button
4. **Expected**: PreCallClinicalNotesDialog appears with:
   - ✅ Patient information section (if available)
   - ✅ "Previous Clinical Context" section shows empty state
   - ✅ All 12 SOAP sections visible but empty

### Verification
- [ ] Dialog displays without errors
- [ ] Empty SOAP structure renders correctly
- [ ] No error messages about missing data
- [ ] UI shows "No data" or empty fields gracefully
- [ ] "Start Call" button still enabled

---

## Test 3: Post-Call SOAP Display (Generated from Transcript)

### Prerequisites
- Completed video call with transcript
- Provider role
- Medication for SOAP generation

### Steps
1. End a video call with transcript
2. **Expected**: PostCallClinicalNotesDialog appears with:
   - ✅ Shows "Generating clinical note from transcript..." initially
   - ✅ After generation, displays all 12 SOAP sections with AI-populated data
   - ✅ All fields editable (can modify text, add/remove items)

### Verification
- [ ] Dialog displays loading state
- [ ] SOAP data generates within 10-15 seconds
- [ ] All 12 sections have appropriate data from transcript
- [ ] Edit fields are functional (can click and modify)
- [ ] Section titles are correct

---

## Test 4: Post-Call SOAP Editing

### Prerequisites
- Post-call dialog open with generated SOAP data

### Steps
1. In the Subjective section, click on HPI narrative field
2. Edit the text (add/remove content)
3. Scroll to Objective section, click on a vital sign
4. Modify a vital sign value
5. Expand the Plan section and modify a medication or follow-up item
6. Click "Save to EHR"

### Verification
- [ ] Text fields accept input
- [ ] Changes are visible in the UI
- [ ] Save button processes without errors
- [ ] Success message appears after save
- [ ] Dialog closes after successful save

---

## Test 5: Session Timeout Pause During Call

### Prerequisites
- Provider in active video call
- Session inactivity timeout enabled (5 minutes default)

### Steps
1. Start a video call
2. Wait more than 5 minutes of inactivity (no mouse movement, no interaction)
3. **Expected**: Session timeout should NOT trigger during call
4. End the call and show post-call dialog
5. Spend 5+ minutes in post-call dialog editing SOAP notes
6. **Expected**: Session timeout should NOT trigger while editing

### Verification
- [ ] No logout/redirect during active call
- [ ] No logout/redirect while viewing/editing SOAP notes
- [ ] Session remains active throughout the workflow

---

## Test 6: Discard Button (No Unexpected Logout)

### Prerequisites
- Post-call dialog open with SOAP data
- Session has been idle for some time

### Steps
1. In post-call dialog, wait for 3+ minutes of inactivity
2. Click "Discard" button
3. **Expected**:
   - ✅ Dialog closes
   - ✅ Returns to previous page
   - ✅ User remains logged in
   - ✅ Session does NOT timeout
4. Navigate to another appointment or page
5. **Verify**: User can continue using app normally

### Verification
- [ ] Dialog closes without errors
- [ ] Navigation works smoothly
- [ ] User stays logged in
- [ ] No error messages appear
- [ ] App state is consistent

---

## Test 7: Session Timeout After Call (Normal Inactivity)

### Prerequisites
- Post-call dialog closed
- User has completed their clinical work

### Steps
1. Complete/discard post-call dialog
2. Return to appointments page
3. Do NOT interact with app for 5 minutes
4. **Expected**:
   - ✅ After 5 minutes of true inactivity, session timeout warning appears
   - ✅ User sees "Session about to expire" dialog
   - ✅ Option to extend session or logout

### Verification
- [ ] Timeout warning appears after ~5 min
- [ ] Countdown timer visible
- [ ] Can extend session by clicking "Continue Session"
- [ ] Auto-logout happens if no action taken

---

## Test 8: Browser Compatibility

### Steps
Test in multiple browsers:
- Chrome
- Firefox
- Safari
- Edge

For each browser:
1. Log in as provider
2. Start a call and reach post-call dialog
3. Verify SOAP sections display correctly
4. Test editing and saving

### Verification per Browser
- [ ] Chrome: Displays correctly, all features work
- [ ] Firefox: Displays correctly, all features work
- [ ] Safari: Displays correctly, all features work
- [ ] Edge: Displays correctly, all features work

---

## Test 9: Mobile Responsive (if applicable)

### Steps (on tablet/mobile)
1. Open app on iPad/tablet
2. Start appointment leading to SOAP dialogs
3. Verify dialogs fit screen
4. Test scrolling and editing on mobile

### Verification
- [ ] Dialogs responsive on tablet
- [ ] Text readable without zooming
- [ ] Buttons tappable
- [ ] Scrolling smooth

---

## Quick Checklist

**Pre-Call Dialog**:
- [ ] Loads patient data correctly
- [ ] Shows prior SOAP notes or empty state
- [ ] All 12 sections visible
- [ ] No errors in console

**Post-Call Dialog**:
- [ ] Generates from transcript
- [ ] Shows loading state
- [ ] All 12 sections populate
- [ ] Edit functionality works
- [ ] Save persists to database

**Session Management**:
- [ ] Timeout paused during calls
- [ ] Timeout paused during SOAP editing
- [ ] Discard doesn't cause logout
- [ ] Normal timeout works after call

**UI/UX**:
- [ ] No layout breaks
- [ ] All text readable
- [ ] Sections collapse/expand smoothly
- [ ] Error messages clear and helpful

---

## Troubleshooting

### Issue: SOAP data shows empty
**Solution**:
- Check `soap_notes` table for existing records
- Verify transcript generated successfully
- Check browser console for API errors

### Issue: Timeout triggers during call
**Solution**:
- Verify `pauseSessionTimeout()` called at call start (join_room.dart:33)
- Verify `resumeSessionTimeout()` called at call end (join_room.dart:38)
- Check `_SessionActivityManager._isPaused` flag in activity_detector.dart

### Issue: Discard causes logout
**Solution**:
- Verify session timeout is paused during dialog
- Check that navigator.pop() doesn't trigger logout
- Review app state management

### Issue: Dialog doesn't render sections
**Solution**:
- Check SoapSectionsViewer widget props
- Verify _soapData structure matches expected format
- Check browser console for rendering errors

---

## Sign-Off

**Tester**: [Name]
**Date**: [Date]
**Platform**: [Browser/Device]

**All Tests Passed**: [ ] Yes [ ] No

**Notes**:
