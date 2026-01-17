# Test 1: Basic Transcription Start/Stop - Execution Guide

**Status:** Ready for Execution
**Date:** January 12, 2026
**Duration:** 5-10 minutes
**Prerequisites:** Medical vocabularies deployed to AWS Transcribe (✅ COMPLETE)

---

## Overview

This test validates the core medical transcription flow:
1. Provider initiates video call
2. System creates Chime meeting with medical transcription support
3. Provider starts transcription with medical vocabulary
4. Real-time captions display
5. Provider stops transcription
6. Transcript is saved to database

**Success Criteria:**
- ✅ Chime meeting created successfully
- ✅ Transcription starts without errors
- ✅ Medical vocabulary "medzen-medical-vocab-en" is loaded
- ✅ Real-time captions appear in UI
- ✅ Transcription stops cleanly
- ✅ Transcript stored in database
- ✅ Cost calculated and stored

---

## Phase 1: Test Data Setup

### Step 1.1: Create Test Users

**In Supabase SQL Editor, run:**

```sql
-- Create test provider
INSERT INTO users (
  id, firebase_uid, email, name, role, language_preference,
  created_at, updated_at
) VALUES (
  gen_random_uuid()::text,
  'test-provider-' || floor(random() * 1000000)::text,
  'test-provider@medzen.test',
  'Dr. Test Provider',
  'provider',
  'en',
  NOW(),
  NOW()
) ON CONFLICT (firebase_uid) DO NOTHING
RETURNING id, email, role;

-- Create test patient
INSERT INTO users (
  id, firebase_uid, email, name, role, language_preference,
  created_at, updated_at
) VALUES (
  gen_random_uuid()::text,
  'test-patient-' || floor(random() * 1000000)::text,
  'test-patient@medzen.test',
  'Test Patient',
  'patient',
  'en',
  NOW(),
  NOW()
) ON CONFLICT (firebase_uid) DO NOTHING
RETURNING id, email, role;

-- Create provider profile
INSERT INTO medical_provider_profiles (
  user_id, license_number, specialties
)
SELECT id, 'TEST-LICENSE-001', ARRAY['Cardiology', 'General Practice']
FROM users WHERE email = 'test-provider@medzen.test'
ON CONFLICT (user_id) DO NOTHING;
```

**Expected Output:** 2 users created (provider + patient)

### Step 1.2: Create Test Appointment

```sql
-- Get test user IDs
WITH test_users AS (
  SELECT
    (SELECT id FROM users WHERE email = 'test-provider@medzen.test') as provider_id,
    (SELECT id FROM users WHERE email = 'test-patient@medzen.test') as patient_id
)
INSERT INTO appointments (
  provider_id, patient_id, appointment_time, appointment_duration_minutes,
  appointment_status, appointment_type, language_code,
  created_at, updated_at
)
SELECT
  provider_id,
  patient_id,
  NOW() + INTERVAL '5 minutes',  -- Start in 5 minutes
  30,
  'scheduled',
  'consultation',
  'en-US',
  NOW(),
  NOW()
FROM test_users
RETURNING id, provider_id, patient_id, appointment_time;
```

**Expected Output:** Appointment ID (save this for Step 2.2)

---

## Phase 2: Initiate Video Call

### Step 2.1: Provider Logs In

**In Flutter app:**
1. Launch app (web, Android, or iOS emulator)
2. Login with test provider credentials:
   - Email: `test-provider@medzen.test`
   - Password: (check Firebase console or .env file)
3. Navigate to "Appointments" → Find test appointment
4. Click "Start Call"

**Expected Result:** Appointment detail page loads with "Start Video Call" button

### Step 2.2: Start Chime Meeting

**In app:**
1. Click "Start Video Call" button
2. Grant camera/microphone permissions when prompted
3. Wait for Chime meeting to load (10-15 seconds)

**In Database (verify Chime meeting created):**

```sql
-- Check video_call_sessions table
SELECT
  id,
  appointment_id,
  chime_meeting_id,
  video_call_status,
  live_transcription_enabled,
  live_transcription_language,
  live_transcription_medical_vocabulary,
  created_at
FROM video_call_sessions
WHERE appointment_id = 'YOUR_APPOINTMENT_ID'  -- Replace with actual ID
ORDER BY created_at DESC
LIMIT 1;
```

**Expected Results:**
- ✅ `chime_meeting_id` populated (UUID format)
- ✅ `video_call_status` = 'active'
- ✅ `live_transcription_enabled` = false (will enable in next step)
- ✅ `live_transcription_language` = 'en-US'
- ✅ Row created in last 30 seconds

---

## Phase 3: Start Transcription with Medical Vocabulary

### Step 3.1: Click "Start Transcription" Button

**In Chime widget UI:**
1. Look for "Start Transcription" button in video call controls
2. Verify language dropdown shows "English (United States)" or similar
3. Click "Start Transcription"

**Expected UI Response:**
- Button changes to "Stop Transcription"
- Status message shows "Transcription started..."
- Real-time caption area appears below video

### Step 3.2: Verify Edge Function Called with Medical Vocabulary

**In Supabase Edge Function Logs:**

```bash
npx supabase functions logs start-medical-transcription --tail
```

**Watch for logs containing:**
- ✅ `[START] Starting transcription for session: <session_id>`
- ✅ `Language: en-US → Medical Engine`
- ✅ `Medical Vocabulary: medzen-medical-vocab-en`
- ✅ `StartMeetingTranscription command sent to AWS`
- ✅ Response should include `MeetingTranscriptionSettings`

**Example Log Output:**
```
[10:23:45] [START] Starting transcription for session: abc123def456
[10:23:46] Session found: appointment_id=appt-123, meeting_id=meeting-abc123
[10:23:46] Language configuration: en-US
[10:23:46] Using engine: medical (AWS Transcribe Medical)
[10:23:47] Medical Vocabulary loaded: medzen-medical-vocab-en (1,849 terms)
[10:23:48] StartMeetingTranscriptionCommand sent to AWS
[10:23:48] ✅ Transcription started successfully
[10:23:49] Event broadcast to listening clients
```

### Step 3.3: Verify Database State

```sql
-- Check video_call_sessions for transcription metadata
SELECT
  id,
  live_transcription_enabled,
  live_transcription_language,
  live_transcription_engine,
  live_transcription_medical_vocabulary,
  transcription_status,
  media_region
FROM video_call_sessions
WHERE appointment_id = 'YOUR_APPOINTMENT_ID'
ORDER BY created_at DESC
LIMIT 1;
```

**Expected Results:**
- ✅ `live_transcription_enabled` = **true**
- ✅ `live_transcription_language` = **'en-US'**
- ✅ `live_transcription_engine` = **'medical'**
- ✅ `live_transcription_medical_vocabulary` = **'medzen-medical-vocab-en'**
- ✅ `transcription_status` = **'started'** or **'active'**
- ✅ `media_region` = **'eu-central-1'**

---

## Phase 4: Verify Real-Time Captions

### Step 4.1: Speak Medical Terms

**In Chime video call:**

Have the provider (or patient, if unmuted) speak medical terminology:

> "The patient has **hypertension** and **diabetes mellitus**. We should check their **cardiac** function and consider **antihypertensive** medications."

**Important:** Use medical terms from the deployed vocabulary to test the boost effect.

### Step 4.2: Monitor Caption Display

**In UI:**
- Watch the caption area below the video feed
- Medical terms should appear within 2-5 seconds of being spoken
- Speaker name should show ("Provider" or "Patient")

**In Database (verify captions being stored):**

```sql
-- Check live_caption_segments
SELECT
  id,
  video_call_session_id,
  start_time,
  end_time,
  transcript,
  speaker,
  confidence
FROM live_caption_segments
WHERE video_call_session_id IN (
  SELECT id FROM video_call_sessions
  WHERE appointment_id = 'YOUR_APPOINTMENT_ID'
)
ORDER BY start_time DESC
LIMIT 10;
```

**Expected Results:**
- ✅ Multiple rows created (one per caption segment)
- ✅ `transcript` contains spoken words
- ✅ `speaker` shows provider/patient
- ✅ `confidence` >= 0.8 (high confidence)
- ✅ Medical terms present if spoken

### Step 4.3: Verify Medical Vocabulary Boost

**In Supabase (check caption accuracy):**

Look for medical terms in the transcript:
- ✅ "hypertension" (not "hi per tension" or "high pertension")
- ✅ "diabetes" (not "diabetes mellitus" as separate words)
- ✅ "cardiac" (not "car tick" or "cardio")
- ✅ "antihypertensive" (not "anti hypertensive")

If medical terms are accurately transcribed, the vocabulary boost is working.

---

## Phase 5: Stop Transcription

### Step 5.1: Click "Stop Transcription" Button

**In Chime widget UI:**
1. Click "Stop Transcription" button
2. System should aggregate all caption segments
3. Wait for status message "Transcription stopped and saved"

**Expected UI Response:**
- Button changes back to "Start Transcription"
- Caption history visible
- Status shows cost (e.g., "$0.15 for 3:45 of transcription")

### Step 5.2: Verify Edge Function Stop Handler

**In Supabase Edge Function Logs:**

```bash
npx supabase functions logs start-medical-transcription --tail
```

**Watch for logs containing:**
- ✅ `[STOP] Stopping transcription for session: <session_id>`
- ✅ `Aggregating <N> caption segments`
- ✅ `Total duration: <MM:SS>`
- ✅ `Cost calculation: <duration> minutes × $0.0004/sec`
- ✅ `Updating database with transcript`

**Example Log Output:**
```
[10:28:15] [STOP] Stopping transcription for session: abc123def456
[10:28:16] Fetching live_caption_segments (45 segments found)
[10:28:17] Aggregating segments into full transcript
[10:28:18] Duration: 4 minutes 32 seconds
[10:28:18] Cost calculation: 272 seconds × $0.0004 = $0.1088 (Medical)
[10:28:19] Budget check: $0.11 < Daily limit: $50.00 ✅
[10:28:20] Updating video_call_sessions with transcript and cost
[10:28:21] ✅ Transcription stopped and saved successfully
```

### Step 5.3: Verify Transcript Stored

```sql
-- Check final transcript stored
SELECT
  id,
  appointment_id,
  live_transcription_enabled,
  transcription_status,
  transcript,
  speaker_segments,
  transcription_duration_seconds,
  transcription_estimated_cost_usd
FROM video_call_sessions
WHERE appointment_id = 'YOUR_APPOINTMENT_ID'
ORDER BY created_at DESC
LIMIT 1;
```

**Expected Results:**
- ✅ `transcription_status` = **'stopped'** or **'completed'**
- ✅ `transcript` contains full conversation (NOT NULL)
- ✅ `speaker_segments` contains segment metadata (JSON format)
- ✅ `transcription_duration_seconds` > 0 (actual duration)
- ✅ `transcription_estimated_cost_usd` > 0 (calculated cost)

**Example transcript:**
```
Provider: "The patient has hypertension and diabetes mellitus.
We should check their cardiac function and consider antihypertensive medications.
Let me review the ECG results."
Patient: "How long do I need to stay on these medications?"
```

---

## Phase 6: Cost Tracking Verification

### Step 6.1: Check Daily Usage Tracking

```sql
-- Check transcription_usage_daily table
SELECT
  user_id,
  usage_date,
  language_code,
  transcription_duration_seconds,
  cost,
  daily_cost_limit_cents,
  cost_remaining_cents
FROM transcription_usage_daily
WHERE usage_date = CURRENT_DATE
  AND user_id = (SELECT id FROM users WHERE email = 'test-provider@medzen.test')
ORDER BY created_at DESC
LIMIT 5;
```

**Expected Results:**
- ✅ Row created with today's date
- ✅ `language_code` = 'en-US'
- ✅ `transcription_duration_seconds` ≈ (time spoken in seconds)
- ✅ `cost` ≈ (duration × $0.0004)
- ✅ `daily_cost_limit_cents` = 500000 (Provider $50/day)
- ✅ `cost_remaining_cents` = (limit - cost)

### Step 6.2: Verify Budget Enforcement

```sql
-- Check if future calls would be blocked
WITH cost_totals AS (
  SELECT
    user_id,
    SUM(cost) as total_cost_cents
  FROM transcription_usage_daily
  WHERE usage_date = CURRENT_DATE
    AND user_id = (SELECT id FROM users WHERE email = 'test-provider@medzen.test')
  GROUP BY user_id
)
SELECT
  user_id,
  total_cost_cents,
  (500000 - total_cost_cents) as remaining_cents,
  CASE
    WHEN (500000 - total_cost_cents) < 0 THEN 'BLOCKED'
    WHEN (500000 - total_cost_cents) < 100000 THEN 'WARNING (80% used)'
    ELSE 'OK'
  END as budget_status
FROM cost_totals;
```

**Expected Results:**
- ✅ `total_cost_cents` = (actual cost from transcript)
- ✅ `remaining_cents` > 0 (budget not exceeded)
- ✅ `budget_status` = 'OK' or 'WARNING'

---

## Test Execution Checklist

Complete this checklist as you progress through the test:

### Setup ✓
- [ ] Test provider user created
- [ ] Test patient user created
- [ ] Test appointment created
- [ ] Appointment ID: _______________

### Video Call ✓
- [ ] Provider logged in
- [ ] Video call initiated
- [ ] Chime meeting created (verify in DB)
- [ ] Meeting ID: _______________

### Transcription Start ✓
- [ ] "Start Transcription" button clicked
- [ ] Medical vocabulary loaded (check logs)
- [ ] Database updated (transcription_enabled = true)
- [ ] Medical vocabulary name: _______________

### Real-Time Captions ✓
- [ ] Medical terms spoken
- [ ] Captions displayed in UI
- [ ] Captions stored in database
- [ ] Medical terms accurately transcribed

### Transcription Stop ✓
- [ ] "Stop Transcription" button clicked
- [ ] Transcript aggregated
- [ ] Database updated (status = completed)
- [ ] Cost calculated: $_______________

### Cost Tracking ✓
- [ ] transcription_usage_daily row created
- [ ] Cost matches calculation
- [ ] Budget remaining tracked
- [ ] Daily limit enforced

---

## Success Criteria Summary

**All of the following must be true:**

1. ✅ **Chime Meeting Created**
   - Video call established without errors
   - Meeting ID stored in database

2. ✅ **Transcription Started**
   - Medical vocabulary "medzen-medical-vocab-en" loaded
   - AWS Transcribe Medical engine activated (en-US)
   - Edge function logs show successful startup

3. ✅ **Real-Time Captions Working**
   - Captions appear in UI within 5 seconds of speech
   - Medical terms transcribed accurately
   - Segments stored in live_caption_segments table

4. ✅ **Transcription Stopped**
   - Transcription cleanly stopped without errors
   - Full transcript aggregated
   - Transcript stored in video_call_sessions

5. ✅ **Cost Calculated**
   - Cost = (duration in seconds) × $0.0004
   - Cost stored in video_call_sessions
   - Cost recorded in transcription_usage_daily
   - Budget remaining calculated correctly

6. ✅ **Medical Vocabulary Impact Verified**
   - Medical terms transcribed accurately
   - No errors in transcription logs
   - Vocabulary boost evident in accuracy

---

## Troubleshooting

### Issue: "Start Transcription" button not appearing
**Solution:**
1. Verify app is on latest version
2. Check browser console for JavaScript errors
3. Verify Chime widget is fully loaded
4. Try refreshing the page

### Issue: Medical vocabulary not loading
**Solution:**
1. Check edge function logs for errors
2. Verify vocabulary exists in AWS: `aws transcribe get-vocabulary --vocabulary-name medzen-medical-vocab-en --region eu-central-1`
3. Ensure vocabulary is in READY state

### Issue: Captions not appearing
**Solution:**
1. Check browser console for WebSocket errors
2. Verify Supabase realtime is enabled
3. Check live_caption_segments table for any entries
4. Verify user has permission to read that table (RLS)

### Issue: Cost calculation incorrect
**Solution:**
1. Check transcription duration in database
2. Verify cost formula: duration (seconds) × $0.0004 / 100 = cost in cents
3. Check for any retries or restarts that might increase duration

### Issue: Database constraints violated
**Solution:**
1. Check Supabase logs for constraint violations
2. Verify all required columns have values
3. Ensure UUIDs are valid format

---

## What to Do After Test 1 Passes

Once this test passes successfully (all checkboxes ✅):

1. **Document Results:**
   - Take screenshots of successful transcription
   - Note any performance metrics (latency, accuracy)
   - Record medical vocabulary effectiveness

2. **Execute Test 2:**
   - Test 2: Medical Vocabulary Verification
   - Compare transcription accuracy with vs without medical vocabulary

3. **Proceed to Test 3:**
   - Test 3: Real-Time Caption Display
   - Focus on UI responsiveness and caption quality

---

## Test Execution Log

**Start Time:** _____________
**Completed By:** _____________
**Total Duration:** _____________

**Observations:**
```
[Space for notes]
```

**Medical Vocabulary Performance:**
```
[Space for vocabulary-specific observations]
```

**Issues Encountered:**
```
[Space for any problems encountered]
```

**Sign-Off:**
- [ ] Test 1 PASSED - All criteria met
- [ ] Test 1 PASSED WITH MINOR ISSUES - (describe)
- [ ] Test 1 FAILED - (describe failure)

---

**Next Step:** Execute Test 2 or address any issues from Test 1
