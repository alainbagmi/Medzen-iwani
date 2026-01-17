# Video Call Transcription Testing Guide

**Date:** January 12, 2026
**App Status:** ✅ Running on Android Emulator 5556
**Firebase Auth:** ✅ User logged in (KWOYwZ9HWSS5FRhKWfC4uj4nP6g2)
**FCM:** ✅ Push notifications initialized

---

## Prerequisites Verified

✅ AWS credentials configured in Supabase secrets
✅ `start-medical-transcription` edge function deployed
✅ RLS policies verified (won't block workflow)
✅ PostCallClinicalNotesDialog fix deployed
✅ Flutter app running on emulator

---

## Testing Steps

### Step 1: Start a Video Call

1. **Navigate to Appointments**
   - Open the app on emulator 5556
   - Go to Appointments section
   - Look for an upcoming appointment

2. **Join as Provider**
   - Ensure you're logged in as a medical provider
   - Click "Join Call" or "Start Video Call" button
   - Grant camera and microphone permissions if prompted

**Expected Logs:**
```
I/flutter: 🎙️ Provider joined - preparing transcription auto-start...
I/flutter: 📱 Session ID: <uuid>
I/flutter: 👤 Provider ID: <uuid>
```

### Step 2: Auto-Start Transcription (2 seconds after provider joins)

After joining the call, transcription should auto-start automatically.

**Expected Logs:**
```
I/flutter: 🎙️ Auto-starting transcription for provider...
I/flutter: 🎙️ [Transcription Control] Starting start action
I/flutter:    Meeting ID: <meeting-id>
I/flutter:    Session ID: <session-id>
I/flutter:    Language: en-US
I/flutter:    Specialty: PRIMARYCARE
I/flutter: ✅ [Transcription Control] Firebase auth token obtained
I/flutter: 📡 [Transcription Control] Calling edge function...
I/flutter: 📨 [Transcription Control] Response received
I/flutter:    Status code: 200
I/flutter: ✅ [Transcription Control] start successful
I/flutter: ✅ Medical transcription started successfully
```

**If you see this error:**
```
❌ [Transcription Control] start failed
   Status: 401
   Error: Unauthorized
```
**Fix:** Firebase token expired, hot restart the app (`R` in terminal)

**If you see this error:**
```
⚠️ [Transcription Control] Daily budget exceeded
```
**Meaning:** Already spent $100 today on transcription, budget limit enforced

### Step 3: Generate Live Captions

While on the video call:

1. **Speak into the microphone** (for at least 10 seconds)
2. **Say medical terms** to test accuracy:
   - "Patient reports chest pain and shortness of breath"
   - "Blood pressure is 120 over 80"
   - "Prescribed ibuprofen 400mg twice daily"

**Expected Behavior:**
- Live captions should appear at the bottom of the video call screen
- Captions should show speaker labels (e.g., "Doctor:" or "Patient:")
- Real-time transcription should update continuously

**Database Check:**
```sql
-- Open new terminal and run:
# Connect to Supabase database
PGPASSWORD='<password>' psql "postgresql://postgres.noaeltglphdlkbflipit:@aws-0-eu-central-1.pooler.supabase.com:6543/postgres"

-- Check live captions are being saved
SELECT
  speaker_name,
  transcript_text,
  is_partial,
  start_time_ms
FROM live_caption_segments
WHERE session_id = '<session-id-from-logs>'
ORDER BY start_time_ms DESC
LIMIT 10;
```

**Expected Result:** You should see rows with your spoken text

### Step 4: End the Video Call

1. **Click "End Call" or "Leave" button**
2. **Wait for call to fully end** (about 5-10 seconds)

**Expected Logs:**
```
I/flutter: 🛑 Stopping transcription before ending call...
I/flutter: 🎙️ [Transcription Control] Starting stop action
I/flutter: ✅ [Transcription Control] stop successful
I/flutter: ✅ Transcription stopped successfully
```

**Edge Function Logs (check in separate terminal):**
```bash
npx supabase functions logs start-medical-transcription --tail
```

**Expected Output:**
```
[Medical Transcription] stop for meeting <meeting-id>
[Medical Transcription] Aggregating live caption segments
[Medical Transcription] Found X caption segments
[Medical Transcription] Transcript saved successfully
```

### Step 5: PostCallClinicalNotesDialog Should Appear

**CRITICAL TEST:** After call ends, a dialog should appear automatically for providers.

**Expected Dialog:**
- **Title:** "Post-Call Clinical Notes"
- **Subtitle:** "Patient: [Patient Name]"
- **Loading State:** "Generating clinical note from transcript..."
- **After 3-5 seconds:** AI-generated SOAP note should appear in text field

**Dialog Screenshot:**
```
┌──────────────────────────────────────────────┐
│ 🏥 Post-Call Clinical Notes         ✕       │
│    Patient: John Doe                         │
├──────────────────────────────────────────────┤
│                                              │
│ Clinical Notes (SOAP Format):               │
│ ┌──────────────────────────────────────────┐ │
│ │ S: Patient reports chest pain and        │ │
│ │ shortness of breath...                   │ │
│ │                                          │ │
│ │ O: Blood pressure 120/80, heart rate    │ │
│ │ 72 bpm...                                │ │
│ │                                          │ │
│ │ A: Possible angina, rule out MI...      │ │
│ │                                          │ │
│ │ P: Order EKG, start aspirin...          │ │
│ └──────────────────────────────────────────┘ │
│                                              │
│                    [Discard] [Save to EHR]  │
└──────────────────────────────────────────────┘
```

**If dialog doesn't appear:**
```bash
# Check browser console (if using Flutter web)
# OR check Flutter logs for errors:
grep -i "post.*call" /tmp/claude/-Users-alainbagmi-Desktop-medzen-iwani-t1nrnu/tasks/b0f5d9a.output
```

**Expected Logs:**
```
I/flutter: 📝 Showing post-call dialog for provider
I/flutter: 🔍 Checking transcript for session: <session-id>
I/flutter: ✅ Transcript found, generating clinical note...
I/flutter: 📡 Calling generate-clinical-note edge function
I/flutter: ✅ Clinical note generated successfully
```

### Step 6: Verify AI-Generated SOAP Note

The dialog should show a properly formatted SOAP note:

**Expected Format:**
```
S: (Subjective - what patient said)
Patient reports [symptoms and complaints]

O: (Objective - what was observed/measured)
[Physical examination findings]
[Vital signs if mentioned]

A: (Assessment - diagnosis/interpretation)
[Clinical assessment]
[Differential diagnoses]

P: (Plan - treatment/next steps)
[Treatment recommendations]
[Follow-up instructions]
[Medications prescribed]
```

### Step 7: Save Clinical Note

1. **Review the AI-generated note**
2. **Edit if needed** (you can modify the text)
3. **Click "Save to EHR" button**

**Expected Logs:**
```
I/flutter: 💾 Saving clinical note to database...
I/flutter: ✅ Clinical note saved successfully
I/flutter: 📋 Note ID: <uuid>
```

**Database Verification:**
```sql
-- Check clinical note was saved
SELECT
  id,
  video_call_session_id,
  appointment_id,
  provider_id,
  patient_id,
  note_type,
  status,
  note_content,
  created_at
FROM clinical_notes
WHERE video_call_session_id = '<session-id-from-logs>'
ORDER BY created_at DESC
LIMIT 1;
```

**Expected Result:** One row with `note_type = 'soap'` and `status = 'draft'`

### Step 8: Verify Complete Transcript

**Check video_call_sessions table:**
```sql
SELECT
  id,
  meeting_id,
  transcript,
  transcription_status,
  transcription_duration_seconds,
  transcription_estimated_cost_usd,
  transcription_language
FROM video_call_sessions
WHERE id = '<session-id-from-logs>';
```

**Expected Result:**
- `transcript` - Should contain full conversation text
- `transcription_status` - Should be 'COMPLETED'
- `transcription_duration_seconds` - Should match call length (e.g., 60 for 1-minute call)
- `transcription_estimated_cost_usd` - Should be ~$0.075 per minute

### Step 9: Verify Cost Tracking

**Check daily usage stats:**
```sql
SELECT
  usage_date,
  total_sessions,
  total_duration_seconds,
  ROUND(total_duration_seconds / 60.0, 2) as duration_minutes,
  total_cost_usd,
  successful_transcriptions,
  failed_transcriptions
FROM transcription_usage_daily
WHERE usage_date = CURRENT_DATE;
```

**Expected Result:**
- `total_sessions` incremented by 1
- `total_duration_seconds` increased by call duration
- `total_cost_usd` increased by estimated cost
- `successful_transcriptions` incremented by 1

---

## Troubleshooting

### Issue: No logs after joining call

**Solution:**
```bash
# Check if app is still running
ps aux | grep flutter

# Restart app if needed
# In the terminal where flutter run is running, press 'R' for hot restart
```

### Issue: Transcription doesn't start

**Check these in order:**

1. **AWS credentials set?**
```bash
npx supabase secrets list
# Should show: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION
```

2. **Edge function deployed?**
```bash
npx supabase functions list
# Should show: start-medical-transcription
```

3. **Firebase token valid?**
```
# In Flutter logs, look for:
✅ [Transcription Control] Firebase auth token obtained

# If you see:
❌ [Transcription Control] User not authenticated
# Then hot restart the app
```

4. **Check edge function logs:**
```bash
npx supabase functions logs start-medical-transcription --tail
```

### Issue: Dialog doesn't appear after call ends

**Debug steps:**

1. **Check join_room.dart was updated:**
```bash
grep -n "PostCallClinicalNotesDialog" lib/custom_code/actions/join_room.dart
```
Should show code around line 674-725

2. **Check user is a provider:**
```
# In logs, verify:
I/flutter: 👤 User role: provider
# NOT: patient, facility_admin, system_admin
```

3. **Hot restart required:**
```
# Press 'R' in terminal where flutter is running
```

### Issue: Clinical note is empty or generic

**Possible causes:**

1. **No speech detected during call**
   - Solution: Speak louder into microphone
   - Check microphone permissions granted

2. **Transcription stopped too early**
   - Solution: Wait longer before ending call (at least 30 seconds)

3. **Edge function error**
   - Check logs: `npx supabase functions logs generate-clinical-note --tail`

### Issue: "Daily budget exceeded" error

**Solution:**
```sql
-- Check current usage
SELECT total_cost_usd FROM transcription_usage_daily WHERE usage_date = CURRENT_DATE;

-- If needed, temporarily increase budget:
-- Edit supabase/functions/start-medical-transcription/index.ts
-- Change: const DAILY_BUDGET_USD = 100;
-- To: const DAILY_BUDGET_USD = 200;

-- Redeploy function:
npx supabase functions deploy start-medical-transcription
```

---

## Success Criteria

✅ **Video call starts successfully**
✅ **Transcription auto-starts after 2 seconds**
✅ **Live captions visible during call**
✅ **Live captions saved to `live_caption_segments` table**
✅ **Transcription stops when call ends**
✅ **Transcript aggregated to `video_call_sessions.transcript`**
✅ **PostCallClinicalNotesDialog appears for provider**
✅ **AI-generated SOAP note displayed in dialog**
✅ **Clinical note saves to `clinical_notes` table**
✅ **Daily usage stats updated in `transcription_usage_daily`**

---

## Next Steps After Successful Test

1. ✅ Test with different medical specialties (CARDIOLOGY, NEUROLOGY, etc.)
2. ✅ Test with multiple languages (French, Afrikaans, Arabic)
3. ✅ Test budget enforcement (simulate reaching $100 daily limit)
4. ✅ Test RLS security (patient shouldn't edit provider's notes)
5. ✅ Test OpenEHR sync (sign note and verify it syncs to EHRbase)

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `lib/custom_code/actions/control_medical_transcription.dart` | Client-side transcription control |
| `lib/custom_code/actions/join_room.dart` | Video call with auto-transcription |
| `lib/custom_code/widgets/post_call_clinical_notes_dialog.dart` | Post-call SOAP note dialog |
| `supabase/functions/start-medical-transcription/index.ts` | Transcription edge function |
| `supabase/functions/generate-clinical-note/index.ts` | AI SOAP note generation |
| `RLS_VERIFICATION_REPORT.md` | RLS policy verification |
| `AWS_TRANSCRIPTION_VERIFICATION_GUIDE.md` | Setup verification guide |

---

## Monitoring Commands

**Watch Flutter logs:**
```bash
tail -f /tmp/claude/-Users-alainbagmi-Desktop-medzen-iwani-t1nrnu/tasks/b0f5d9a.output | grep -i "transcription\|clinical\|soap"
```

**Watch edge function logs:**
```bash
npx supabase functions logs start-medical-transcription --tail
npx supabase functions logs generate-clinical-note --tail
```

**Check database in real-time:**
```bash
watch -n 2 "PGPASSWORD='<password>' psql 'postgresql://postgres.noaeltglphdlkbflipit:@aws-0-eu-central-1.pooler.supabase.com:6543/postgres' -c 'SELECT COUNT(*) FROM live_caption_segments;'"
```

---

## Support

If you encounter issues not covered in this guide:

1. Check full logs: `cat /tmp/claude/-Users-alainbagmi-Desktop-medzen-iwani-t1nrnu/tasks/b0f5d9a.output`
2. Check Supabase logs: `npx supabase functions logs start-medical-transcription`
3. Review RLS policies: See `RLS_VERIFICATION_REPORT.md`
4. Check AWS Transcribe Medical status in AWS Console
5. Verify Bedrock model quota for clinical note generation

**Emergency Recovery:**
```bash
# Full clean rebuild
flutter clean && flutter pub get && flutter run -d emulator-5556

# Redeploy all edge functions
npx supabase functions deploy start-medical-transcription generate-clinical-note

# Check AWS credentials
npx supabase secrets list | grep AWS
```
