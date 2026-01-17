# Chime SDK Video Call Testing Guide

## Overview

This guide provides comprehensive testing procedures for the Amazon Chime SDK video calling integration in the MedZen telehealth app.

**Migration Status:** Completed migration from Agora RTC to Amazon Chime SDK
**Last Updated:** 2025-11-22
**Code Analysis:** ✅ Zero compilation errors in Chime implementation

---

## Pre-Testing Checklist

### ✅ Infrastructure Verified

- [x] CloudFormation stack deployed (medzen-chime-stack)
- [x] AWS API Gateway endpoint: `https://g840y1ewxb.execute-api.eu-west-1.amazonaws.com`
- [x] Supabase Edge Function deployed (`chime-meeting-token`)
- [x] CHIME_API_ENDPOINT configured in Supabase secrets
- [x] HTML assets exist (`assets/html/chime_meeting.html`)
- [x] Flutter code migrated to Chime SDK
- [x] WebView communication fixed (FlutterChannel)

### 📋 Required Test Accounts

You'll need the following test accounts:

1. **Provider Account**
   - Role: Medical Provider
   - Must have: Active profile, verified credentials
   - Location: `lib/medical_provider/provider_landing_page/`

2. **Patient Account**
   - Role: Patient
   - Must have: Active profile, basic demographics
   - Location: `lib/patients_folder/patient_landing_page/`

### 🔧 Environment Setup

Before testing, ensure:

```bash
# 1. Rebuild the Flutter app with all changes
flutter clean
flutter pub get
flutter build apk  # For Android
# OR
flutter build ios  # For iOS
# OR
flutter run -d chrome  # For web testing

# 2. Verify Supabase connection
npx supabase functions logs chime-meeting-token --tail

# 3. Verify AWS endpoint is accessible
curl -X POST https://g840y1ewxb.execute-api.eu-west-1.amazonaws.com/create-meeting \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Meeting"}'
```

---

## Test Scenarios

### Test 1: Create New Meeting (Provider Initiates)

**Objective:** Verify provider can create a new Chime meeting for an appointment

**Steps:**

1. **Login as Provider**
   - Open app
   - Navigate to provider login
   - Enter provider credentials
   - Verify successful login → Provider Landing Page

2. **Navigate to Appointments**
   - Click on "Appointments" section
   - Locate a scheduled appointment with status = 'scheduled'
   - Note the `appointmentId` for verification

3. **Initiate Video Call**
   - Click "Start Video Call" button
   - App should request camera/microphone permissions
   - Grant permissions when prompted

4. **Expected Behavior:**
   - ✅ Loading indicator: "Setting up video call..."
   - ✅ Supabase Edge Function called with action='create'
   - ✅ AWS API creates new Chime meeting
   - ✅ Meeting data stored in `video_call_sessions` table
   - ✅ Success message: "Connecting to video call..."
   - ✅ Navigation to ChimeVideoCallPage with WebView

5. **Verify WebView Loads:**
   - HTML page loads (`chime_meeting.html`)
   - Status shows: "Initializing..."
   - Chime SDK loads Amazon Chime scripts
   - Local video preview appears
   - Controls visible: 🎤 📷 📞

6. **Verify Database Entry:**
   ```sql
   SELECT
     meeting_id,
     attendee_id,
     status,
     created_at
   FROM video_call_sessions
   WHERE appointment_id = '<appointmentId>'
   ORDER BY created_at DESC
   LIMIT 1;
   ```

   **Expected:**
   - meeting_id: Not null (Chime meeting ID)
   - attendee_id: Not null (Provider's attendee ID)
   - status: 'active'
   - created_at: Recent timestamp

---

### Test 2: Join Existing Meeting (Patient Joins)

**Objective:** Verify patient can join provider's active meeting

**Prerequisites:**
- Provider has created meeting (Test 1 completed)
- Meeting status is 'active' in database

**Steps:**

1. **Login as Patient (Different Device/Browser)**
   - Open app in different browser/device
   - Navigate to patient login
   - Enter patient credentials
   - Verify successful login → Patient Landing Page

2. **Navigate to Appointments**
   - Click on "My Appointments"
   - Locate the SAME appointment from Test 1
   - Verify appointment shows "Call in Progress" or similar indicator

3. **Join Video Call**
   - Click "Join Video Call" button
   - App should request camera/microphone permissions
   - Grant permissions when prompted

4. **Expected Behavior:**
   - ✅ Loading indicator: "Setting up video call..."
   - ✅ Supabase Edge Function called with action='join'
   - ✅ AWS API adds patient as attendee to existing meeting
   - ✅ Patient attendee data created
   - ✅ Success message: "Connecting to video call..."
   - ✅ Navigation to ChimeVideoCallPage

5. **Verify Both Participants See Each Other:**
   - Provider's video should appear in patient's view
   - Patient's video should appear in provider's view
   - Each participant should see 2 video tiles total (self + remote)
   - Name tags should display correctly:
     - "You" for own video
     - Provider/Patient name for remote video

6. **Verify Database Update:**
   ```sql
   SELECT
     meeting_id,
     attendee_id,
     user_id,
     status
   FROM video_call_sessions
   WHERE appointment_id = '<appointmentId>'
   ORDER BY created_at;
   ```

   **Expected:**
   - Two rows returned (one for provider, one for patient)
   - Same meeting_id for both
   - Different attendee_id values
   - Both status = 'active'

---

### Test 3: Audio/Video Controls

**Objective:** Verify all call controls function correctly

**Prerequisites:** Both provider and patient in active call

**Steps:**

1. **Test Microphone Toggle (Provider Side)**
   - Click microphone button (🎤)
   - **Expected:**
     - Button changes to muted icon (🔇)
     - Background color changes to red
     - Patient should NOT hear provider's audio
   - Click again to unmute
   - **Expected:**
     - Button returns to 🎤
     - Background returns to green
     - Patient can hear provider again

2. **Test Camera Toggle (Provider Side)**
   - Click camera button (📷)
   - **Expected:**
     - Button shows camera off icon (📷❌)
     - Background color changes to red
     - Provider's video tile goes blank on patient's screen
   - Click again to turn camera on
   - **Expected:**
     - Button returns to 📷
     - Background returns to blue
     - Provider's video reappears on patient's screen

3. **Test Controls on Patient Side**
   - Repeat steps 1-2 for patient
   - Verify same behavior from patient's perspective

4. **Test Simultaneous Muting**
   - Both participants mute microphones
   - **Expected:** Silence from both sides
   - Both participants turn cameras off
   - **Expected:** Only name tags visible, no video

---

### Test 4: Call End Flow

**Objective:** Verify call termination works correctly

**Prerequisites:** Active call with both participants

**Steps:**

1. **Provider Ends Call**
   - Click end call button (📞 red button)
   - Confirm "End the call?" dialog
   - Click "OK"

2. **Expected Behavior - Provider Side:**
   - ✅ Local video stops
   - ✅ Chime session terminates (audioVideo.stop())
   - ✅ JavaScript calls `notifyFlutter('ended', 'Call ended')`
   - ✅ WebView closes
   - ✅ Returns to appointments page
   - ✅ Appointment status updates (if applicable)

3. **Expected Behavior - Patient Side:**
   - ✅ Provider's video tile disappears
   - ✅ Attendee presence event fires (provider left)
   - ✅ Patient can either:
     - Continue waiting (if they don't know provider left)
     - Also end call

4. **Verify Database Update:**
   ```sql
   SELECT
     meeting_id,
     status,
     ended_at
   FROM video_call_sessions
   WHERE appointment_id = '<appointmentId>';
   ```

   **Expected:**
   - status: 'ended'
   - ended_at: Recent timestamp

5. **Test Patient Ends Call**
   - Repeat test with patient ending call first
   - Verify same cleanup behavior

---

### Test 5: Error Handling

**Objective:** Verify graceful error handling

#### Test 5a: Permission Denied

**Steps:**
1. Start video call
2. Deny camera or microphone permission
3. **Expected:**
   - ✅ Error message: "❌ Camera and microphone permissions are required"
   - ✅ Red snackbar displayed
   - ✅ Call does NOT proceed
   - ✅ User remains on appointments page

#### Test 5b: Network Interruption

**Steps:**
1. Start active call
2. Disable network (airplane mode or disconnect WiFi)
3. **Expected:**
   - ✅ Chime SDK detects connection loss
   - ✅ Status indicator shows connection issue
   - ✅ Video freezes
   - ✅ User can still click "End Call"
4. Re-enable network
5. **Expected:**
   - ✅ Connection attempts to recover (Chime SDK auto-reconnect)
   - ✅ If recovery fails within timeout, call ends gracefully

#### Test 5c: Invalid Meeting

**Steps:**
1. Manually modify appointment_id to non-existent value
2. Attempt to join call
3. **Expected:**
   - ✅ Error message: "❌ Video call session not found"
   - ✅ Red snackbar displayed
   - ✅ User remains on appointments page
   - ✅ No crash or undefined behavior

#### Test 5d: Authentication Error

**Steps:**
1. Invalidate Supabase auth token (or log out mid-session)
2. Attempt to start call
3. **Expected:**
   - ✅ Error message: "❌ Please log in to start a video call"
   - ✅ Redirect to login page
   - ✅ No sensitive data leaked

---

### Test 6: Meeting Re-join

**Objective:** Verify users can rejoin meetings after accidental disconnect

**Steps:**

1. **Provider Creates Meeting**
   - Follow Test 1 steps
   - Verify meeting is active

2. **Provider Accidentally Closes App**
   - Close app (don't end call, just force-close)
   - Reopen app
   - Navigate back to appointment
   - Click "Join Video Call"

3. **Expected Behavior:**
   - ✅ Edge function detects existing meeting (action='join')
   - ✅ Provider rejoins as new attendee
   - ✅ Video resumes
   - ✅ Patient sees provider return (if still in call)

4. **Verify Database:**
   ```sql
   SELECT COUNT(*) as sessions
   FROM video_call_sessions
   WHERE appointment_id = '<appointmentId>'
   AND status = 'active';
   ```

   **Expected:** Potentially multiple rows (original + rejoin session)

---

## Troubleshooting Common Issues

### Issue: "Failed to start video call"

**Possible Causes:**
1. Supabase Edge Function not deployed
2. CHIME_API_ENDPOINT not configured
3. AWS API Gateway not responding

**Debug Steps:**
```bash
# Check Supabase function logs
npx supabase functions logs chime-meeting-token --tail

# Test AWS endpoint directly
curl -X POST https://g840y1ewxb.execute-api.eu-west-1.amazonaws.com/create-meeting \
  -H "Content-Type: application/json" \
  -d '{"title": "Debug Test"}'

# Check Supabase secrets
npx supabase secrets list
```

### Issue: "Blank WebView or Video Not Loading"

**Possible Causes:**
1. HTML file not included in assets
2. WebView permissions not granted
3. JavaScript channel not created

**Debug Steps:**
```bash
# Verify HTML exists
ls -lh assets/html/chime_meeting.html

# Check pubspec.yaml includes HTML assets
grep "assets/html/" pubspec.yaml

# Enable WebView debugging (Android)
# Add to ChimeVideoCallPage:
WebView.setWebContentsDebuggingEnabled(true);
```

**Flutter Console Logs to Check:**
```
Flutter: Joining meeting: {...}  # Should see meeting + attendee data
Flutter: FlutterChannel created  # Confirms JavaScript channel
Flutter: WebView ready           # Confirms HTML loaded
```

### Issue: "No Video/Audio from Remote Participant"

**Possible Causes:**
1. Firewall blocking WebRTC
2. Microphone/camera not granted
3. Chime SDK initialization failed

**Debug Steps:**
- Open browser console (web) or WebView debugger
- Check for Chime SDK errors:
  ```javascript
  // Look for these in console:
  "Failed to initialize Chime"
  "Failed to start audio/video"
  ```
- Verify attendee presence:
  ```javascript
  console.log('Attendee present:', attendeeId, present);
  ```

### Issue: "Flutter-WebView Communication Not Working"

**Symptoms:**
- Call ends but app doesn't respond
- Error messages not displayed

**Debug Steps:**
- Verify JavaScript channel exists:
  ```dart
  // In ChimeVideoCallPage, check:
  javascriptChannels: {
    JavascriptChannel(
      name: 'FlutterChannel',  // Must match HTML
      onMessageReceived: (JavascriptMessage message) {
        print('Received: ${message.message}');
      },
    ),
  }
  ```

- Verify HTML sends messages correctly:
  ```javascript
  // In chime_meeting.html:
  window.FlutterChannel.postMessage(JSON.stringify({
    type: 'ended',
    message: 'Call ended'
  }));
  ```

---

## Success Criteria

A successful test run should demonstrate:

- ✅ Provider can create new meetings
- ✅ Patient can join existing meetings
- ✅ Both participants see/hear each other
- ✅ Audio/video controls work correctly
- ✅ Call end flow works from both sides
- ✅ Errors are handled gracefully
- ✅ Database records are accurate
- ✅ Users can rejoin after disconnect
- ✅ No memory leaks or crashes
- ✅ WebView communication is reliable

---

## Database Verification Queries

### Check Active Meetings
```sql
SELECT
  vcs.meeting_id,
  vcs.appointment_id,
  vcs.user_id,
  vcs.attendee_id,
  vcs.status,
  vcs.created_at,
  u.email,
  u.role
FROM video_call_sessions vcs
JOIN users u ON vcs.user_id = u.id
WHERE vcs.status = 'active'
ORDER BY vcs.created_at DESC;
```

### Check Meeting History
```sql
SELECT
  meeting_id,
  COUNT(*) as participant_count,
  MIN(created_at) as meeting_start,
  MAX(ended_at) as meeting_end,
  status
FROM video_call_sessions
WHERE appointment_id = '<appointmentId>'
GROUP BY meeting_id, status
ORDER BY meeting_start DESC;
```

### Check for Failed Meetings
```sql
SELECT
  appointment_id,
  meeting_id,
  user_id,
  status,
  error_message,
  created_at
FROM video_call_sessions
WHERE status = 'failed'
ORDER BY created_at DESC
LIMIT 10;
```

---

## Performance Benchmarks

Expected performance metrics:

| Metric | Target | Acceptable |
|--------|--------|------------|
| Meeting Creation Time | < 2s | < 5s |
| Join Time | < 3s | < 7s |
| Video Start Delay | < 1s | < 3s |
| Audio Start Delay | < 500ms | < 2s |
| Control Response Time | Instant | < 200ms |
| Call End Cleanup | < 1s | < 3s |

---

## Next Steps After Testing

Once all tests pass:

1. **Update Main Documentation**
   - Document Chime architecture in `CLAUDE.md`
   - Add deployment guide to `CHIME_SDK_DEPLOYMENT_GUIDE.md`
   - Update API documentation

2. **Optional Cleanup**
   - Remove `lib/custom_code/widgets/pre_joining_dialog.dart` (old Agora widget)
   - Remove PreJoiningDialog export from index.dart
   - Search for any remaining Agora references

3. **Monitor Production**
   - Watch Supabase Edge Function logs
   - Monitor `video_call_sessions` table for errors
   - Track user feedback on call quality

4. **Future Enhancements**
   - Add call recording (S3 buckets ready)
   - Add transcription (infrastructure ready)
   - Add medical entity extraction (Lambda ready)
   - Migrate to full Chime Messaging integration

---

## Contact & Support

**AWS CloudFormation Stack:** medzen-chime-stack
**API Endpoint:** https://g840y1ewxb.execute-api.eu-west-1.amazonaws.com
**Supabase Project:** noaeltglphdlkbflipit
**Edge Function:** chime-meeting-token

For issues or questions, check:
- Supabase logs: `npx supabase functions logs chime-meeting-token`
- AWS CloudWatch: Monitor Lambda and API Gateway logs
- Flutter console: Check for JavaScript errors during WebView sessions
