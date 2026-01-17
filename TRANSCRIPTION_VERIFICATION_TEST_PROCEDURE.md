# Transcription Verification Test Procedure

## Overview
This test validates that the transcription pipeline is properly initialized during video calls with sufficient duration. The enhanced debug logging will provide visibility into every step of the transcription flow.

**Critical Requirement:** Call duration must be **minimum 5-10 seconds** to allow the 2-second auto-start delay to complete before the provider ends the session.

---

## Pre-Test Setup

### 1. Environment Verification
- Ensure app is running with latest code containing enhanced logging
- Open Flutter DevTools (if testing on web) or Android Studio Logcat (Android/emulator)
- Prepare to capture full console output during test
- Have Supabase dashboard open for post-test database verification

### 2. Test Appointment Creation
Create a test appointment scheduled for a few minutes from now:
- **Appointment Type:** Telehealth/Video Consultation
- **Provider:** Use any medical provider account
- **Patient:** Use a patient account
- **Scheduled Time:** Next 5 minutes (to join immediately after creation)
- **Note:** Do NOT enable transcription flag on appointment (we want to test auto-start)

### 3. Account Setup
- Login as **Provider account** first
- Complete landing page and navigation
- Navigate to upcoming appointments
- Have the appointment ready to join

---

## Test Execution Steps

### Phase 1: Join as Provider (Will Auto-Start Transcription)

**Step 1.1:** Click on the test appointment
- Should load appointment details page
- Verify `videoCallId` is present (visible in debug logs)

**Step 1.2:** Click "Join Video Call"
- App should navigate to ChimeMeetingEnhanced widget
- Watch logs for initial startup messages

**Step 1.3:** Grant camera/microphone permissions
- Flutter should request permissions (Phase 1 warmup)
- Monitor logs for permission request handling

**Step 1.4:** Monitor Meeting Join Sequence
After successfully joining meeting, expect these log markers (in order):

```
✅ Successfully joined meeting
🎙️ Provider joined - preparing transcription auto-start...
   ⏱️  Will auto-start transcription in 2 seconds
   📊 Current state: _isTranscriptionEnabled=false, _isTranscriptionStarting=false
```

**Step 1.5:** CRITICAL - Wait 2+ Seconds
Count to 3 before proceeding. This allows the auto-start delay to complete.

**Step 1.6:** Monitor Auto-Start Completion
After 2-second delay, expect:

```
⏰ 2-second auto-start delay completed
   📊 Mounted=true, _isTranscriptionEnabled=false, _isTranscriptionStarting=false
✅ All conditions met - Auto-starting transcription for provider...
```

**Step 1.7:** Monitor Transcription Initialization
Now watch for comprehensive [TRANSCRIPTION-START] logs:

```
[TRANSCRIPTION-START] Beginning transcription initialization
[TRANSCRIPTION-START] PRE-CHECK Phase:
   ✅ appointmentId found: [UUID]
   ✅ meetingId found: [ID]
   ✅ userName: [Provider Name]
   📍 sessionId: [Will be fetched from database]

[TRANSCRIPTION-START] FETCH-SESSION Phase:
   🔄 Fetching session_id from database...
   📝 Query: appointmentId=[UUID], providerId=[UUID]
   [Attempt 1] Fetching...
   ✅ Session found: [SESSION-UUID]

[TRANSCRIPTION-START] FINAL-CHECK Phase:
   ✅ All required IDs collected:
      - appointmentId: [UUID]
      - meetingId: [ID]
      - sessionId: [SESSION-UUID]
      - userName: [Provider Name]
      - isProvider: true

[TRANSCRIPTION-START] EDGE-FUNCTION-CALL Phase:
   📤 Calling controlMedicalTranscription() with:
      meetingId: [ID]
      appointmentId: [UUID]
      language: en-US
      specialty: PRIMARYCARE
      enableLiveTranscription: true
      transcriptionEnabled: true
```

**Expected Outcome:** If all these logs appear, transcription is properly initialized. If logs stop or error markers appear, see **Troubleshooting** section below.

---

### Phase 2: Extended Call Duration (Maintain 5-10 Seconds Minimum)

**Step 2.1:** Keep the video call active for at least 5-10 seconds
- You can keep yourself unmuted or muted (doesn't matter)
- The important thing is that the call stays active
- Watch for any caption-related logs (live transcription)

**Step 2.2:** Monitor for Caption Subscription
If using a patient account to join, expect:

```
👤 Patient joined - will subscribe to captions when available
[CAPTIONS] Subscribing to captions for session: [SESSION-UUID]
```

If provider is solo in call:
```
📡 No patients in this call yet - captions will be available when patient joins
```

**Step 2.3:** Optional - Join as Patient
If you want to test full caption flow:
1. In another browser/device, login as **patient** account
2. Navigate to the same appointment
3. Click "Join Video Call"
4. Watch for caption subscription logs

**Step 2.4:** Keep Call Active
Maintain the video call for 5-10 seconds total. The provider should NOT end the call too quickly.

---

### Phase 3: Provider Ends Call

**Step 3.1:** When ready, provider clicks "End Call" button
- After 5-10 seconds of active call time
- Do NOT end call before 5 seconds (transcription won't have time to initialize)

**Step 3.2:** Monitor Call Cleanup
Expect logs showing:

```
🛑 Call ended by provider
✅ Cleanup initiated...
📊 Final call statistics:
   - Duration: [X seconds]
   - Participants: [N]
   - Transcription status: [PROCESSING|ERROR|etc]
```

**Step 3.3:** Return to Appointments List
Navigation should complete without errors.

---

## Post-Test Database Verification

### Query 1: Verify Transcription Session Data
Run in Supabase dashboard SQL editor:

```sql
SELECT
  id,
  appointment_id,
  provider_id,
  patient_id,
  meeting_id,
  transcription_enabled,
  transcription_status,
  transcript,
  speaker_segments,
  medical_entities,
  transcription_completed_at,
  created_at,
  updated_at
FROM video_call_sessions
WHERE appointment_id = '[YOUR_TEST_APPOINTMENT_ID]'
ORDER BY created_at DESC
LIMIT 1;
```

**Expected Results:**
- `transcription_enabled`: `true`
- `transcription_status`: One of: `PENDING`, `PROCESSING`, `COMPLETED`, `FAILED`
- `transcript`: Either `null` (still processing) or populated with text
- `speaker_segments`: Should have structure if transcription has started
- `medical_entities`: Will be populated after transcription completes

### Query 2: Check Transcription Duration
```sql
SELECT
  created_at,
  updated_at,
  is_recording,
  recording_enabled,
  duration_seconds,
  transcription_duration_seconds
FROM video_call_sessions
WHERE appointment_id = '[YOUR_TEST_APPOINTMENT_ID]'
ORDER BY created_at DESC
LIMIT 1;
```

**Expected Results:**
- `is_recording`: `true` if enabled
- `duration_seconds`: Should reflect call duration (5-10 seconds)
- `transcription_duration_seconds`: Will be set once transcription completes

### Query 3: Check for Any Error Messages
```sql
SELECT
  id,
  appointment_id,
  transcription_error,
  error_message,
  error_occurred_at
FROM video_call_sessions
WHERE appointment_id = '[YOUR_TEST_APPOINTMENT_ID]'
AND (transcription_error IS NOT NULL OR error_message IS NOT NULL)
ORDER BY created_at DESC;
```

**Expected Results:**
- Should return empty (no errors)
- If rows appear, note the error message for troubleshooting

---

## Expected Log Markers Checklist

Use this checklist to validate each phase of transcription:

### Meeting Join Phase
- [ ] `✅ Successfully joined meeting`
- [ ] `🎙️ Provider joined - preparing transcription auto-start...`
- [ ] `⏱️  Will auto-start transcription in 2 seconds`

### Auto-Start Delay Phase
- [ ] `⏰ 2-second auto-start delay completed`
- [ ] `✅ All conditions met - Auto-starting transcription for provider...`

### Transcription Initialization Phase
- [ ] `[TRANSCRIPTION-START] Beginning transcription initialization`
- [ ] `[TRANSCRIPTION-START] PRE-CHECK Phase` with:
  - [ ] `✅ appointmentId found`
  - [ ] `✅ meetingId found`
  - [ ] `✅ userName`
- [ ] `[TRANSCRIPTION-START] FETCH-SESSION Phase` with:
  - [ ] `🔄 Fetching session_id from database...`
  - [ ] `✅ Session found` (not failed after 3 retries)
- [ ] `[TRANSCRIPTION-START] FINAL-CHECK Phase` showing all IDs collected
- [ ] `[TRANSCRIPTION-START] EDGE-FUNCTION-CALL Phase` with parameters logged

### Success Outcome
- [ ] No `❌ [TRANSCRIPTION-START] EXCEPTION CAUGHT` messages
- [ ] No error stack traces in logs
- [ ] Call completes and database query shows `transcription_enabled = true`

---

## Troubleshooting

### Issue 1: No Transcription Logs Appear
**Symptoms:** Meeting joined successfully, but no `[TRANSCRIPTION-START]` logs appear

**Possible Causes:**
- **Widget not mounted:** Check for `Mounted=false` in logs
- **Transcription already enabled:** Check for `_isTranscriptionEnabled=true` in logs
- **Transcription already starting:** Check for `_isTranscriptionStarting=true` in logs
- **Provider account:** Verify you're logged in as a provider, not patient

**Fix:** Check the auto-start delay completion logs. If they're missing, the 2-second delay may not have completed before logs scroll past. Try again and watch more carefully.

### Issue 2: Session ID Not Found
**Log markers:**
```
[TRANSCRIPTION-START] FETCH-SESSION Phase:
[Attempt 1] Query failed...
[Attempt 2] Query failed...
[Attempt 3] Query failed...
❌ Session ID could not be fetched after 3 attempts
```

**Possible Causes:**
- Appointment not properly created in database
- `video_call_sessions` record doesn't exist for this appointment
- Appointment ID is mismatched

**Fix:**
1. Verify appointment exists: Query `SELECT * FROM appointments WHERE id = '[APPOINTMENT_ID]'`
2. Verify video session was created: Query `SELECT * FROM video_call_sessions WHERE appointment_id = '[APPOINTMENT_ID]'`
3. If session doesn't exist, meeting initialization may have failed

### Issue 3: Exception in Catch Block
**Log markers:**
```
❌ [TRANSCRIPTION-START] EXCEPTION CAUGHT:
   Error type: [Type]
   Error message: [Message]
   Stack trace: [Trace]
```

**Possible Causes:**
- Network issue calling edge function
- Firebase token expired or invalid
- Edge function not deployed
- Invalid parameters passed to edge function

**Fix:**
1. Note the exact error message and type
2. Check edge function logs: `npx supabase functions logs controlMedicalTranscription --tail`
3. Verify Firebase token is fresh: User should call `getIdToken(true)` to refresh
4. Check Supabase edge function deployment status

### Issue 4: Database Shows No Transcription Data
**Symptoms:** Query returns `transcription_enabled = false` or row doesn't exist

**Possible Causes:**
- Video call session not created
- Call ended before transcription initialization completed
- Database insert failed
- Recording not enabled at appointment level

**Fix:**
1. Verify call duration was 5+ seconds
2. Check if `transcription_enabled` is explicitly disabled at appointment level
3. Review logs to see if transcription initialization completed
4. Check Supabase edge function logs for any errors processing transcription request

---

## Success Criteria

Test is **SUCCESSFUL** if:

1. ✅ All meeting join phase logs appear
2. ✅ Auto-start delay completion logs appear
3. ✅ All [TRANSCRIPTION-START] phase logs appear with no errors
4. ✅ No exception caught in error handler
5. ✅ Database query shows `transcription_enabled = true`
6. ✅ Call duration was 5+ seconds

Test is **PARTIAL SUCCESS** if:
- Transcription initialized but hasn't completed yet (check status after 30-60 seconds)
- Database shows `transcription_status = PROCESSING` (expected for AWS Transcribe Medical)

Test is **FAILED** if:
- Transcription logs are missing entirely
- Exception appears in catch block
- Database shows `transcription_enabled = false`
- Call ended before 2-second auto-start delay (verify in auto-start completion logs)

---

## Next Steps After Test

1. **If SUCCESSFUL:** Proceed to Task 2 - Add `recording_enabled` column to appointments table for explicit control
2. **If PARTIAL SUCCESS:** Wait 30-60 seconds and re-query database to check if transcription completed
3. **If FAILED:** Review troubleshooting section and run test again with corrections
