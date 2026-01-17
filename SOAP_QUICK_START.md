# SOAP Notes Implementation - Quick Start Checklist

## 🎯 What You Have (Complete & Ready)

```
✅ Database Schema
   └─ File: supabase/migrations/20260115100000_add_soap_notes_and_transcription_schema.sql
   └─ Tables: soap_notes, call_transcripts, live_caption_segments, speaker_mappings, video_call_participants, video_call_recordings

✅ Edge Functions
   ├─ generate-soap-from-transcript/index.ts (NEW)
   ├─ finalize-video-call/index.ts (NEW)
   └─ start-medical-transcription/index.ts (UPDATED - now idempotent)

✅ Dart Actions
   └─ lib/custom_code/actions/finalize_video_call.dart (NEW)

✅ Documentation
   ├─ SOAP_NOTES_IMPLEMENTATION_GUIDE.md (comprehensive)
   └─ SOAP_QUICK_START.md (this file)
```

---

## 📋 Your Next Steps (In Order)

### STEP 1: Deploy Database Schema (5 minutes)

```bash
# Terminal
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Link Supabase (should already be linked)
npx supabase link --project-ref noaeltglphdlkbflipit

# Run migration
npx supabase migration up

# VERIFY: Check Supabase dashboard or run:
# psql $DATABASE_URL -c "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name LIKE '%soap%';"
# Should see: soap_notes, call_transcripts, live_caption_segments, speaker_mappings, video_call_participants, video_call_recordings
```

**Status**: [ ] Not started | [ ] In progress | [✓] Complete

---

### STEP 2: Deploy Edge Functions (10 minutes)

```bash
# Terminal - from project root

# Deploy the new functions
npx supabase functions deploy generate-soap-from-transcript
npx supabase functions deploy finalize-video-call

# Verify deployment (check Supabase dashboard Functions tab)
# Both functions should show "Deployed"
```

**Status**: [ ] Not started | [ ] In progress | [✓] Complete

---

### STEP 3: Update Chime Widget End-Of-Call Handler (30 minutes)

**File**: `lib/custom_code/widgets/chime_meeting_enhanced.dart`

Find the method that handles call ending (look for `onCallEnded`, `endCall`, or similar).

**Add this code block** before `Navigator.pop()`:

```dart
// Finalize video call workflow (SOAP generation)
if (mounted && widget.appointmentId.isNotEmpty) {
  final finResult = await finalizeVideoCall(
    _sessionId ?? '',
    _meetingId ?? '',
    widget.appointmentId,
    'provider-id',  // TODO: Replace with actual provider ID
    'patient-id',   // TODO: Replace with actual patient ID
    _isTranscriptionEnabled,
    false,  // Recording not enabled yet (Phase 2)
  );

  if (mounted && finResult['success'] == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ SOAP draft generated: ${finResult['data']?['soapNoteId']}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
```

**Important**: Replace `'provider-id'` and `'patient-id'` with actual values from your context.

**Status**: [ ] Not started | [ ] In progress | [ ] Complete

---

### STEP 4: Add Participant Tracking (15 minutes)

**Where**: In the Chime SDK event handler when participants join/leave

**Add code** to track participants:

```dart
// When participant joins (in audioVideo.onRemoteAudioSessionStarted or similar)
await SupaFlow.client.from('video_call_participants').insert({
  'session_id': _sessionId,
  'meeting_id': _meetingId,
  'user_id': participantUserId,
  'attendee_id': attendeeId,  // From Chime
  'display_name': participantName,
  'role': isProvider ? 'provider' : 'patient',
  'joined_at': DateTime.now().toIso8601String(),
});

// When participant leaves
await SupaFlow.client
  .from('video_call_participants')
  .update({ 'left_at': DateTime.now().toIso8601String() })
  .eq('attendee_id', attendeeId)
  .eq('session_id', _sessionId);
```

**Status**: [ ] Not started | [ ] In progress | [ ] Complete

---

### STEP 5: Manual Testing (1 hour)

**Test Scenario 1: Happy Path**
- [ ] Provider starts video call
- [ ] Patient joins
- [ ] Both see live captions (transcription enabled)
- [ ] Provider clicks "End Call"
- [ ] Check logs → "Finalizing Video Call" message appears
- [ ] Check Supabase → `soap_notes` table has new draft entry
- [ ] Check `call_transcripts` → merged transcript exists
- [ ] Check `speaker_mappings` → provider/patient mapped

**Test Scenario 2: Idempotent Transcription Start**
- [ ] Start call, transcription begins
- [ ] Call `controlMedicalTranscription(..., 'start', ...)` again
- [ ] Should return success immediately (idempotent)
- [ ] No duplicate billing or errors

**Test Scenario 3: Empty Transcript**
- [ ] Start call, but don't speak (no captions)
- [ ] End call
- [ ] Should not crash, SOAP generation should skip gracefully
- [ ] Check `call_transcripts` → status should be 'no_transcript' or 'pending'

**Status**: [ ] Not started | [ ] In progress | [ ] Complete

---

### STEP 6 (OPTIONAL): Build SOAP Editor Page (4 hours)

Create a FlutterFlow page for doctors to review/edit SOAP drafts.

**Minimal Implementation**:
```dart
// Page: SOAPNoteEditor
// Inputs: soapNoteId

// On page load:
final soap = await SupaFlow.client
  .from('soap_notes')
  .select()
  .eq('id', soapNoteId)
  .single();

// Display in TextFields:
// - Chief Complaint (read-only, shows from transcript)
// - Subjective (editable)
// - Objective (editable)
// - Assessment (editable)
// - Plan (editable)

// Buttons:
// - "View Transcript" (shows call_transcripts.raw_text in modal)
// - "Save Draft" (update soap_notes with edits)
// - "Submit to EHR" (set status='submitted', record timestamp)
// - "Discard" (delete draft)
```

**Status**: [ ] Not started | [ ] In progress | [ ] Complete

---

## 🔑 Critical Environment Variables

**Must be set in Supabase Dashboard** → Project Settings → Functions → Environment Variables:

```
AWS_REGION=eu-central-1
AWS_ACCESS_KEY_ID=<your-key>
AWS_SECRET_ACCESS_KEY=<your-secret>
DAILY_TRANSCRIPTION_BUDGET_USD=50
```

**Verify Bedrock Access**:
```bash
aws bedrock list-foundation-models \
  --region eu-central-1 \
  --query 'modelSummaries[?modelId==`anthropic.claude-3-opus-20250219-v1:0`]'
# Should return model details (if not, request access in AWS console)
```

---

## 🧪 Quick Validation Commands

```bash
# Check if migration worked
psql $DATABASE_URL -c "\dt public.*soap*"
# Should show: public | soap_notes

# Check if edge functions deployed
curl -X OPTIONS "https://noaeltglphdlkbflipit.supabase.co/functions/v1/generate-soap-from-transcript" \
  -H "apikey: $ANON_KEY"
# Should return 200 with CORS headers

# Test finalize endpoint (mock call)
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/finalize-video-call" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId":"test-123",
    "meetingId":"chime-123",
    "appointmentId":"apt-123",
    "providerId":"prov-123",
    "patientId":"pat-123",
    "transcriptionEnabled":true,
    "recordingEnabled":false
  }'
# May return 500 if session doesn't exist (expected), but function is callable
```

---

## ⚠️ Common Issues & Fixes

### "Function not found" Error
**Fix**: Re-run `npx supabase functions deploy generate-soap-from-transcript`

### "Missing required fields" Error
**Fix**: Check finalization call includes all parameters (sessionId, meetingId, etc.)

### "Database error: table soap_notes doesn't exist"
**Fix**: Run `npx supabase migration up` to create tables

### "Bedrock model not available"
**Fix**:
1. Check AWS region (must be eu-central-1)
2. Request model access in AWS console → Bedrock → Model Access → Request

### "Daily budget exceeded"
**Fix**: Increase `DAILY_TRANSCRIPTION_BUDGET_USD` environment variable

---

## 📊 Expected Results After Complete Setup

**After a video call ends, you should see:**

1. **Immediately in database**:
   - ✅ New `call_transcripts` row with merged captions
   - ✅ `video_call_participants` showing provider + patient
   - ✅ `speaker_mappings` showing attendee→role mapping

2. **Within 15 seconds**:
   - ✅ New `soap_notes` row with status='draft'
   - ✅ `ai_generated_at` timestamp set
   - ✅ Full SOAP JSON in `ai_raw_json`

3. **Visible to user**:
   - ✅ Success message: "✅ SOAP draft generated"
   - ✅ SOAP ID displayed

---

## 🚀 Production Checklist

Before going live:

- [ ] All migrations deployed and verified
- [ ] All edge functions deployed and tested
- [ ] Chime widget updated with finalization code
- [ ] Participant tracking implemented
- [ ] AWS IAM permissions granted (Bedrock + Transcribe)
- [ ] Environment variables set
- [ ] Error handling tested
- [ ] Load testing done (e.g., 5 concurrent calls)
- [ ] Doctor review workflow documented

---

## 📞 Deployment Support

**File Locations** (everything ready to use):

```
supabase/
├─ migrations/
│  └─ 20260115100000_add_soap_notes_and_transcription_schema.sql ← Deploy first
├─ functions/
│  ├─ generate-soap-from-transcript/
│  │  └─ index.ts ← Deploy second
│  ├─ finalize-video-call/
│  │  └─ index.ts ← Deploy third
│  └─ start-medical-transcription/
│     └─ index.ts ← Already exists, idempotency check added

lib/custom_code/actions/
└─ finalize_video_call.dart ← Use in widget

└─ SOAP_NOTES_IMPLEMENTATION_GUIDE.md ← Full reference
```

---

**Status Summary**:
- Database: ✅ READY TO DEPLOY
- Edge Functions: ✅ READY TO DEPLOY
- Client Code: ✅ READY TO INTEGRATE
- Testing: 🔄 IN YOUR HANDS

**Estimated Total Time to Production**: 2-3 hours
**Critical Path**: Deploy migrations → Deploy functions → Test → Integrate into widget

Good luck! 🚀
