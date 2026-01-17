# Video Call Implementation Testing Guide
**Test Date**: January 14, 2026
**Implementation**: Post-call SOAP note generation + Receiver data capture for web messages
**Status**: Ready for testing

---

## Overview

This guide verifies two critical fixes:
1. **Post-call SOAP Note Generation** - Transcriptions automatically generate clinical notes for provider review
2. **Web Message Receiver Tracking** - Video call messages capture both sender AND receiver information

**All code changes deployed**: ✅
**All edge functions deployed**: ✅
**Ready to test**: ✅

---

## Quick Start Test (5 minutes)

### Prerequisites
- Provider account with active appointment
- Patient account linked to same appointment
- Web or mobile device with microphone
- Basic medical terminology for transcription

### Test Steps

#### 1. Start Video Call
```
1. Provider: Log in and navigate to upcoming appointment
2. Provider: Click "Start Video Call"
3. Patient: Accept call within 30 seconds
4. Both: Confirm microphone enabled
5. Both: Wait 5 seconds for call to stabilize
```

#### 2. Perform Transcription Test
```
1. Provider: Speak 2-3 sentences like:
   "Patient presents with persistent headache for three days.
    Onset was gradual, worse with activity.
    No fever or vision changes reported."
2. Wait 3-5 seconds for Chime SDK to process captions
3. Provider: Send test message "Test message" via chat
4. Patient: Reply with message (triggers receiver capture)
5. Provider: Review captions appearing on screen
```

#### 3. End Call & Review Post-Call Dialog
```
1. Provider: Click "End Call" button
2. System: Should show "Finalizing..." loading indicator
3. System: Post-call dialog should appear (2-5 seconds later)
4. Dialog: Should contain AI-generated SOAP note with:
   - Subjective: Patient symptoms from transcription
   - Objective: Any vital signs or observations
   - Assessment: Clinical impression
   - Plan: Recommended actions
```

#### 4. Provider Actions
```
Option A - Confirm Note:
1. Review the prefilled SOAP note
2. Edit any fields as needed
3. Click "Confirm" button
4. Dialog closes, note saved to database

Option B - Discard Note:
1. Click "Discard" button
2. Dialog closes without saving
3. Note is NOT saved to database
```

---

## Detailed Test Scenarios

### Test 1: Post-Call SOAP Note Generation

**Purpose**: Verify transcription merges and SOAP note auto-generates
**Expected Duration**: 3-5 minutes
**Success Criteria**: SOAP note appears with clinically relevant content

#### Steps

1. **Provider initiates call with transcription enabled**
   ```
   - Open appointment details
   - Click "Start Video Call"
   - Confirm transcription toggle is ON
   ```

2. **Both participants join successfully**
   ```
   - Patient accepts call
   - Both see video feeds
   - Both see real-time captions appearing
   ```

3. **Provider speaks medical content (minimum 20 seconds)**
   ```
   "Patient reports experiencing chest discomfort for 2 days.
    Pain is described as sharp, located centrally.
    Associated with shortness of breath on exertion.
    No radiation to arms or jaw.
    Medical history includes hypertension treated with lisinopril.
    Currently taking aspirin 81mg daily.
    Denies smoking or recent travel."
   ```

4. **End call naturally**
   ```
   - Wait for all captions to finish processing
   - Provider clicks "End Call"
   - System initiates finalization (watch browser console)
   ```

5. **Verify SOAP note appears**
   ```
   Expected: Dialog with populated sections
   - Subjective: Patient complaints from speech
   - Objective: Vital signs or observations
   - Assessment: Clinical impression
   - Plan: Treatment recommendations
   ```

#### Expected Debug Logs (Browser Console)

```
📞 Call ended - initiating finalization workflow...
🔄 Calling finalizeVideoCall...
   Session ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   Meeting ID: MeetingId#xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   Appointment ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   Provider ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   Patient ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
✅ Video call finalization successful!
   Transcript ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   SOAP Note ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
📝 Showing post-call clinical notes dialog for provider...
```

#### Database Verification (Run in Supabase)

```sql
-- Check if video call session was created and finalized
SELECT
    id,
    appointment_id,
    provider_id,
    patient_id,
    status,
    transcription_status,
    created_at,
    ended_at
FROM video_call_sessions
WHERE appointment_id = 'YOUR_APPOINTMENT_ID'
ORDER BY created_at DESC
LIMIT 1;
```

Expected output:
- `status`: 'completed' or 'ended'
- `transcription_status`: 'completed' or 'processing'
- `ended_at`: Should have recent timestamp

```sql
-- Check if transcript was saved
SELECT
    id,
    session_id,
    transcript_text,
    speaker_segments,
    status,
    created_at
FROM video_transcripts
WHERE session_id IN (
    SELECT id FROM video_call_sessions
    WHERE appointment_id = 'YOUR_APPOINTMENT_ID'
)
ORDER BY created_at DESC
LIMIT 1;
```

Expected output:
- `transcript_text`: Should contain merged captions
- `speaker_segments`: Should show provider/patient speakers
- `status`: 'completed'

```sql
-- Check if SOAP note was generated
SELECT
    id,
    session_id,
    appointment_id,
    provider_id,
    soap_content,
    status,
    created_at
FROM clinical_notes
WHERE appointment_id = 'YOUR_APPOINTMENT_ID'
ORDER BY created_at DESC
LIMIT 1;
```

Expected output:
- `soap_content`: Should contain JSON with Subjective, Objective, Assessment, Plan
- `status`: 'draft' (unsaved) or 'confirmed' (if provider confirmed)

---

### Test 2: Web Message Receiver Tracking

**Purpose**: Verify receiver_id, receiver_name, receiver_avatar are captured
**Expected Duration**: 2-3 minutes
**Success Criteria**: Both sender and receiver fields populated

#### Steps

1. **Both participants in video call**
   ```
   - Provider and patient both joined and visible
   - Video feeds showing
   - Chat interface ready
   ```

2. **Provider sends message**
   ```
   - Provider types in chat: "How are you feeling?"
   - Provider clicks "Send"
   - Message appears in chat
   ```

3. **Patient replies**
   ```
   - Patient sees message from provider
   - Patient types: "I'm doing well, no pain"
   - Patient clicks "Send"
   - Message appears in chat
   ```

4. **Verify both directions recorded**
   ```
   - Messages should be visible to both parties
   - Both directions should have complete metadata
   ```

#### Expected Debug Logs (Browser Console)

**Provider sending message:**
```
✅ Message saved with receiver info:
   Sender: Provider Dr. Smith [ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx]
   Receiver: Patient John Doe [ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx]
✅ Message saved to Supabase (appointment: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
```

**Patient sending message:**
```
✅ Message saved with receiver info:
   Sender: Patient John Doe [ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx]
   Receiver: Provider Dr. Smith [ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx]
✅ Message saved to Supabase (appointment: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
```

#### Database Verification (Run in Supabase)

```sql
-- Check message sender and receiver fields
SELECT
    id,
    appointment_id,
    sender_id,
    sender_name,
    sender_avatar,
    receiver_id,
    receiver_name,
    receiver_avatar,
    message,
    message_type,
    created_at
FROM chime_messages
WHERE appointment_id = 'YOUR_APPOINTMENT_ID'
ORDER BY created_at DESC
LIMIT 5;
```

Expected output for each message:
- `sender_id`: Not NULL (UUID of sender)
- `sender_name`: Should show role and name (e.g., "Provider Dr. Smith")
- `receiver_id`: Not NULL (UUID of receiver)
- `receiver_name`: Should show role and name (e.g., "Patient John Doe")
- All fields should have values (no NULLs except avatar which may be empty)

**Critical Check**:
- Message 1 (provider → patient): `sender_id` = provider, `receiver_id` = patient
- Message 2 (patient → provider): `sender_id` = patient, `receiver_id` = provider
- Never should sender_id equal receiver_id

---

### Test 3: SOAP Note Dialog Workflow

**Purpose**: Verify provider can edit, confirm, or discard note
**Expected Duration**: 2-3 minutes
**Success Criteria**: All three workflow paths work correctly

#### Test 3A: Edit and Confirm

1. **Post-call dialog appears after call ends**
   - Dialog should not be dismissible by clicking outside
   - Should show "Loading..." briefly then populate with SOAP note

2. **Edit SOAP content**
   ```
   - Locate Subjective section
   - Click to edit or find edit button
   - Add text: " - Also reports recent stress."
   - Verify change is visible
   ```

3. **Confirm the note**
   ```
   - Locate "Confirm" or "Save" button
   - Click it
   - Dialog should close
   - Should show success toast or confirmation message
   ```

4. **Verify persistence**
   ```sql
   -- Check note was saved with "confirmed" status
   SELECT
       id,
       appointment_id,
       soap_content,
       status,
       is_signed,
       created_at,
       updated_at
   FROM clinical_notes
   WHERE appointment_id = 'YOUR_APPOINTMENT_ID'
   ORDER BY updated_at DESC
   LIMIT 1;
   ```
   Expected:
   - `status`: 'confirmed' or 'draft'
   - `soap_content`: Should contain edited text
   - `updated_at`: Should be recent (within last 30 seconds)

#### Test 3B: Discard Note

1. **Start fresh call with transcription**
   - Perform another test call (can be shorter, ~30 seconds of speech)
   - End call

2. **When dialog appears**
   ```
   - Locate "Discard" or "Cancel" button
   - Click it
   - Dialog should close
   ```

3. **Verify note was NOT saved**
   ```sql
   -- Check no new clinical note was created
   SELECT COUNT(*) as note_count
   FROM clinical_notes
   WHERE appointment_id = 'YOUR_APPOINTMENT_ID'
   AND created_at > NOW() - INTERVAL '5 minutes';

   -- Should return 0 or same count as before
   ```

---

## Debug Logging Reference

### Location: Browser DevTools Console

**Open DevTools**: `F12` or `Ctrl+Shift+I` (Windows/Linux) or `Cmd+Option+I` (Mac)

**Filter for test logs**:
```
1. Click "Console" tab
2. In filter field type: "📞|🔄|✅|❌|📝"
3. Only logs related to video calls will show
```

### Key Log Prefixes

| Icon | Meaning | Expected Occurrence |
|------|---------|---------------------|
| 📞 | Call lifecycle event | When call ends |
| 🔄 | Finalization starting | After "End Call" clicked |
| ✅ | Success condition | After processing completes |
| ⚠️ | Warning/incomplete data | When optional fields missing |
| ❌ | Error occurred | Only if something fails |
| 📝 | Dialog action | When post-call dialog shown |

### Sample Log Timeline

```
[14:32:15] 📞 Call ended - initiating finalization workflow...
[14:32:16] 🔄 Calling finalizeVideoCall...
[14:32:20] ✅ Video call finalization successful!
[14:32:21] 📝 Showing post-call clinical notes dialog for provider...
[14:32:35] ✅ Provider saved SOAP note
```

### Troubleshooting Logs

**If you see this**: `⚠️ Missing required data for finalization`
- Check: Meeting ID, Session ID, Appointment ID must be set
- Verify: Call completed normally (both parties present)
- Fix: Refresh page and retry

**If you see this**: `❌ Error during video call finalization`
- Check browser console for full error message
- Verify Firebase token is valid: `getIdToken(true)`
- Check Supabase edge function logs:
  ```bash
  npx supabase functions logs finalize-video-call --tail
  ```

---

## Verification Checklist

### Pre-Test Checklist
- [ ] Provider account created and verified
- [ ] Patient account created and linked to provider
- [ ] Appointment created for both users
- [ ] Microphone working on test device
- [ ] Browser console open (F12)
- [ ] Supabase dashboard ready for SQL queries

### During-Test Checklist - SOAP Generation

- [ ] Post-call dialog appears within 5 seconds of call end
- [ ] Dialog title shows appointment/patient info
- [ ] SOAP content populated (not blank)
- [ ] Subjective section contains speech content
- [ ] Objective/Assessment/Plan sections have reasonable content
- [ ] Confirm and Discard buttons are clickable
- [ ] Dialog cannot be dismissed by clicking outside
- [ ] Console shows all success logs (✅ symbols)

### During-Test Checklist - Receiver Tracking

- [ ] Messages visible in both directions
- [ ] Browser logs show "receiver_id" for every message
- [ ] Database query shows non-NULL receiver fields
- [ ] sender_id ≠ receiver_id for all messages
- [ ] receiver_name correctly identifies the other participant
- [ ] No messages have both sender and receiver as same person

### Post-Test Verification

**SOAP Note Persistence**:
- [ ] Query `clinical_notes` table for appointment
- [ ] Note status is 'confirmed' (if provider saved)
- [ ] Note status is null/missing (if provider discarded)
- [ ] Note content visible in database (not truncated)
- [ ] timestamps are recent and correct

**Message Persistence**:
- [ ] Query `chime_messages` for appointment
- [ ] Row count matches number of messages sent
- [ ] All receiver fields populated (not NULL)
- [ ] sender_id and receiver_id correctly paired

---

## Expected vs Actual Outcomes

### Scenario 1: Complete Happy Path

**Steps**:
1. Call with speech → End call → Confirm note

**Expected**:
- Dialog appears with AI-generated SOAP
- Provider edits note
- Note saved to database with 'confirmed' status
- Messages all have sender and receiver

**Actual** (To be filled after testing):
- Dialog appears: [ ] Yes [ ] No [ ] Delayed
- Content generated: [ ] Complete [ ] Partial [ ] Missing
- Note saved: [ ] Yes [ ] No [ ] Error

---

### Scenario 2: Discard Workflow

**Steps**:
1. Call with speech → End call → Discard note

**Expected**:
- Dialog appears
- Provider clicks Discard
- No note record in database
- Messages still captured with receiver info

**Actual** (To be filled after testing):
- Dialog appeared: [ ] Yes [ ] No
- Note in DB: [ ] None [ ] Unexpected note
- Messages captured: [ ] Yes [ ] No

---

### Scenario 3: Web Messaging

**Steps**:
1. Both participants in call
2. Provider sends message
3. Patient replies

**Expected**:
- Both messages visible in chat UI
- Database has 2 rows in chime_messages
- Each row has complete sender/receiver fields
- No NULL values in receiver_* columns

**Actual** (To be filled after testing):
- Messages visible: [ ] Yes [ ] No
- Receiver fields populated: [ ] Yes [ ] No
- Database counts: [ ] Correct [ ] Wrong

---

## SQL Queries for Verification

Copy and paste these into Supabase dashboard → SQL Editor

### Quick Status Check
```sql
-- Get latest call and notes for an appointment
WITH latest_call AS (
  SELECT id, appointment_id, status, transcription_status, created_at
  FROM video_call_sessions
  WHERE appointment_id = 'YOUR_APPOINTMENT_ID'
  ORDER BY created_at DESC LIMIT 1
)
SELECT
  'Call Status' as check_type,
  CASE WHEN lc.id IS NOT NULL THEN 'Found' ELSE 'Not found' END as result,
  lc.status,
  lc.transcription_status,
  lc.created_at
FROM latest_call lc
UNION ALL
SELECT
  'SOAP Note Status',
  CASE WHEN cn.id IS NOT NULL THEN 'Found' ELSE 'Not found' END,
  cn.status,
  'N/A',
  cn.created_at
FROM clinical_notes cn
WHERE cn.appointment_id = 'YOUR_APPOINTMENT_ID'
ORDER BY created_at DESC LIMIT 1;
```

### Message Quality Check
```sql
-- Verify all messages have complete sender/receiver info
SELECT
  COUNT(*) as total_messages,
  COUNT(CASE WHEN sender_id IS NOT NULL THEN 1 END) as sender_complete,
  COUNT(CASE WHEN receiver_id IS NOT NULL THEN 1 END) as receiver_complete,
  COUNT(CASE WHEN sender_id IS NOT NULL AND receiver_id IS NOT NULL THEN 1 END) as fully_complete,
  COUNT(CASE WHEN sender_id = receiver_id THEN 1 END) as error_same_person
FROM chime_messages
WHERE appointment_id = 'YOUR_APPOINTMENT_ID';
```

Expected:
- All counts should be equal
- `error_same_person` should be 0

---

## Common Issues & Solutions

### Issue 1: Dialog Never Appears

**Symptom**: Call ends, no post-call dialog shown
**Likely Cause**: Finalization function returned success=false
**Check**:
1. Browser console for error logs
2. Edge function logs:
   ```bash
   npx supabase functions logs finalize-video-call --tail
   ```
3. Meeting ID extraction (may be different format in response)

**Solution**:
1. Check meeting ID is extracting correctly:
   ```dart
   // In join_room.dart, add temporary log:
   print('Meeting response: ${jsonEncode(meetingResponse)}');
   ```
2. Verify appointment/session IDs are correct
3. Check Firebase token is valid and not expired

### Issue 2: Empty SOAP Content

**Symptom**: Dialog appears but SOAP note is blank or missing sections
**Likely Cause**: Transcription empty, Bedrock call failed
**Check**:
1. Did Chime captions appear during call? (Check screen)
2. Bedrock function logs:
   ```bash
   npx supabase functions logs generate-soap-from-transcript --tail
   ```
3. Transcript exists in database:
   ```sql
   SELECT transcript_text, speaker_segments
   FROM video_transcripts
   WHERE session_id = 'YOUR_SESSION_ID';
   ```

**Solution**:
1. Ensure at least 30 seconds of clear speech in call
2. Check medical vocabulary tables are populated
3. Verify Bedrock API credentials in environment

### Issue 3: Receiver Fields NULL in Database

**Symptom**: Query shows receiver_id as NULL
**Likely Cause**: Message insertion code not executing correctly
**Check**:
1. Browser console for message save logs
2. `isProvider` boolean passed to ChimeMeetingEnhanced widget
3. Patient/provider IDs passed to widget are not empty

**Solution**:
1. Verify patient/provider IDs in navigation call:
   ```dart
   await joinRoom(
     context,
     sessionId,
     providerId,      // Should be UUID
     patientId,       // Should be UUID
     appointmentId,
     isProvider,      // true for provider, false for patient
     userName,
     profileImage,
     providerName,
     providerRole,
   );
   ```
2. Check that both IDs are valid UUIDs (not null or empty)
3. Clear browser cache and reload

### Issue 4: Finalization Timeout

**Symptom**: "Finalization request timed out after 60 seconds"
**Likely Cause**: Large transcription being processed, network delay
**Check**:
1. Transcription length (longer calls take longer)
2. Bedrock availability in eu-central-1 region
3. Network connectivity

**Solution**:
1. Increase timeout in `finalize_video_call.dart` line 107:
   ```dart
   const Duration(seconds: 120),  // Increased from 60
   ```
2. Check Bedrock throttling limits
3. Verify Supabase function cold start time

---

## Advanced Debugging

### Enable Verbose Logging

**Add to join_room.dart after line 688**:
```dart
debugPrint('🔧 Debug - Meeting Response: ${jsonEncode(meetingResponse)}');
debugPrint('🔧 Debug - Session ID: $sessionId');
debugPrint('🔧 Debug - All Parameters:');
debugPrint('   appointmentId: $appointmentId');
debugPrint('   providerId: $providerId');
debugPrint('   patientId: $patientId');
debugPrint('   isProvider: $isProvider');
```

### Monitor Edge Function

**Real-time logs**:
```bash
npx supabase functions logs finalize-video-call --tail
```

**Previous logs**:
```bash
npx supabase functions logs finalize-video-call
```

**Check specific error**:
```bash
npx supabase functions logs finalize-video-call | grep "ERROR"
```

### Database Monitoring

**Watch for new notes in real-time**:
```sql
-- Terminal 1: Start watching
SELECT id, created_at, status
FROM clinical_notes
WHERE appointment_id = 'YOUR_APPOINTMENT_ID'
ORDER BY created_at DESC;

-- Keep refreshing this every 5 seconds during test
```

---

## Test Report Template

```
TEST SESSION REPORT
==================
Date: [YYYY-MM-DD]
Tester: [Name]
Environment: [Web/Mobile/Emulator]
Browser: [Chrome/Safari/Firefox]

TEST 1: SOAP Note Generation
Status: [ ] PASS [ ] FAIL [ ] PARTIAL
Notes:
- Dialog appeared: [ ] Yes [ ] No
- Content quality: [ ] Complete [ ] Partial [ ] Empty
- Time to appear: [___] seconds
- Issues: [__________________]

TEST 2: Receiver Tracking
Status: [ ] PASS [ ] FAIL [ ] PARTIAL
Notes:
- Messages captured: [__] count
- Receiver fields: [ ] All populated [ ] Some NULL
- sender_id ≠ receiver_id: [ ] Yes [ ] No
- Issues: [__________________]

TEST 3: Dialog Workflow
Status: [ ] PASS [ ] FAIL [ ] PARTIAL
Notes:
- Confirm path: [ ] Works [ ] Fails
- Discard path: [ ] Works [ ] Fails
- Database persistence: [ ] Correct [ ] Wrong
- Issues: [__________________]

OVERALL: [ ] PASS [ ] FAIL
Next Steps: [________________________]
```

---

## Success Criteria Summary

### ✅ PASS Conditions (All Required)

1. **Post-call dialog appears** within 5 seconds of ending call
2. **SOAP note is populated** with clinically relevant content
3. **Provider can edit** the SOAP note in dialog
4. **Confirm/Discard** buttons function correctly
5. **Confirmed notes** persist in `clinical_notes` table
6. **Discarded notes** do NOT create database records
7. **Every message** has non-NULL receiver_id and receiver_name
8. **No messages** have sender_id equal to receiver_id
9. **All debug logs** show success indicators (✅)
10. **No ERROR logs** in browser or Supabase logs

### ❌ FAIL Conditions (Any One)

1. Dialog never appears
2. SOAP note is empty or mostly blank
3. Receiver fields are NULL in database
4. Buttons don't respond to clicks
5. Confirmed notes aren't saved
6. Discarded notes create orphaned records
7. Transcription doesn't process
8. Finalization times out repeatedly
9. Console shows red ERROR messages
10. Database queries return unexpected results

---

## Next Steps After Testing

### If PASS ✅
1. Move to staging environment for extended testing
2. Test with multiple patient-provider pairs
3. Test with longer calls (15-30 minutes)
4. Deploy to production
5. Monitor error logs for 24 hours

### If FAIL ❌
1. Document error messages and timing
2. Check logs for specific error codes
3. Review code changes for regressions
4. Check edge function deployments
5. Verify database schema integrity
6. Contact support with logs and test steps

---

## Contact & Support

**For errors during testing**:
1. Capture browser console screenshot
2. Run the SQL verification queries
3. Check edge function logs with: `npx supabase functions logs <function-name> --tail`
4. Document exact reproduction steps
5. Include test report template with findings

**Critical Files**:
- Video call widget: `/lib/custom_code/widgets/chime_meeting_enhanced.dart`
- Room joining: `/lib/custom_code/actions/join_room.dart`
- Finalization: `/lib/custom_code/actions/finalize_video_call.dart`
- Post-call dialog: `/lib/custom_code/widgets/post_call_clinical_notes_dialog.dart`
- Edge function: `/supabase/functions/finalize-video-call/index.ts`

**Deployed Functions (Check Status)**:
```bash
npx supabase functions list
# Should show all functions in "Deployed Functions" section
```

---

## Appendix: Test Data Setup

### Create Test Users

```sql
-- Create test provider
INSERT INTO users (id, firebase_uid, email, name, role, created_at)
VALUES (
  'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',  -- Use actual UUID
  'firebase-uid-provider',
  'provider@test.com',
  'Dr. Test Provider',
  'medical_provider',
  NOW()
);

-- Create test patient
INSERT INTO users (id, firebase_uid, email, name, role, created_at)
VALUES (
  'yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy',  -- Use actual UUID
  'firebase-uid-patient',
  'patient@test.com',
  'Test Patient',
  'patient',
  NOW()
);

-- Create test appointment
INSERT INTO appointments (
  id,
  provider_id,
  patient_id,
  scheduled_date,
  appointment_type,
  status,
  created_at
)
VALUES (
  'zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz',  -- Use actual UUID
  'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',  -- provider ID
  'yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy',  -- patient ID
  NOW() + INTERVAL '1 hour',
  'video_consultation',
  'scheduled',
  NOW()
);
```

### Clear Test Data After Testing

```sql
-- Delete messages
DELETE FROM chime_messages
WHERE appointment_id = 'zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz';

-- Delete notes
DELETE FROM clinical_notes
WHERE appointment_id = 'zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz';

-- Delete transcripts
DELETE FROM video_transcripts
WHERE session_id IN (
  SELECT id FROM video_call_sessions
  WHERE appointment_id = 'zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz'
);

-- Delete call sessions
DELETE FROM video_call_sessions
WHERE appointment_id = 'zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz';

-- Delete appointment
DELETE FROM appointments
WHERE id = 'zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz';
```

---

**Document Version**: 1.0
**Last Updated**: January 14, 2026
**Implementation**: Deployed ✅
