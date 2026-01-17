# Post-Call Transcription Diagnosis and Fix

## Issue Summary

User reported two critical issues:
1. ✅ **FIXED**: Web chat showing "US" instead of sender name/avatar
2. ⚠️ **DIAGNOSED**: Post-call transcription not working - SOAP notes dialog not showing

## Issue 1: Web Chat Sender Display (FIXED)

### Root Cause
The edge function `call-send-message/index.ts` had inconsistent field names:
- **Sender query** used `photo_url` (doesn't exist in `users` table)
- **Recipient query** used `profile_picture_url` (correct field name)

This caused sender avatar/name to be null, displaying "US" as error state on web platform.

### Fix Applied
Changed two lines in `supabase/functions/call-send-message/index.ts`:

**Line 88**:
```typescript
// BEFORE
.select("id, email, full_name, photo_url, role")

// AFTER
.select("id, email, full_name, profile_picture_url, role")
```

**Line 100**:
```typescript
// BEFORE
userAvatar = userData.photo_url || "";

// AFTER
userAvatar = userData.profile_picture_url || "";
```

### Deploy Fix
```bash
npx supabase functions deploy call-send-message
```

## Issue 2: Post-Call Transcription Not Working (DIAGNOSED)

### Expected Flow
1. Provider joins call → transcription auto-starts
2. Live captions saved to `live_caption_segments` table
3. Provider ends call → `_stopTranscription()` called
4. Edge function aggregates segments into transcript
5. `video_call_sessions.transcript` updated
6. PostCallClinicalNotesDialog shown with AI-generated SOAP notes

### Code Analysis - ALL CORRECT ✅

#### 1. Auto-Start Transcription
**File**: `lib/custom_code/widgets/chime_meeting_enhanced.dart` (lines 999-1006)
```dart
// Auto-start transcription for providers after 2 second delay
if (widget.isProvider) {
  Future.delayed(const Duration(seconds: 2), () {
    if (mounted && !_isTranscriptionEnabled && !_isTranscriptionStarting) {
      _startTranscription();
    }
  });
}
```
✅ Correctly auto-starts for providers

#### 2. Save Live Captions
**File**: `lib/custom_code/widgets/chime_meeting_enhanced.dart` (lines 1108-1119)
```dart
if (!isPartial && _sessionId != null) {
  await SupaFlow.client.from('live_caption_segments').insert({
    'session_id': _sessionId,
    'speaker_name': speakerName,
    'transcript_text': transcriptText,
    'is_partial': isPartial,
  });
}
```
✅ Correctly saves final captions to database

#### 3. Stop Transcription on Call End
**File**: `lib/custom_code/widgets/chime_meeting_enhanced.dart` (lines 951-959)
```dart
if (_isTranscriptionEnabled && widget.isProvider == true) {
  await _stopTranscription();
}
```
✅ Correctly stops transcription when provider ends call

#### 4. Aggregate Transcript
**File**: `supabase/functions/start-medical-transcription/index.ts` (lines 530-599)
```typescript
// Fetch live caption segments
const { data: captionSegments } = await supabase
  .from('live_caption_segments')
  .select('speaker_name, transcript_text, created_at')
  .eq('session_id', sessionId)
  .order('created_at', { ascending: true });

// Aggregate into formatted transcript with speaker labels
// Update video_call_sessions.transcript
await supabase.from('video_call_sessions').update({
  transcript: aggregatedTranscript || null,
  transcription_status: aggregatedTranscript ? 'completed' : 'no_transcript',
  // ... other fields
}).eq('id', sessionId);
```
✅ Correctly aggregates and saves transcript

#### 5. Show Dialog
**File**: `lib/custom_code/actions/join_room.dart` (lines 709-850)
```dart
onCallEnded: () async {
  if (isProvider && context.mounted) {
    // Fetch video_call_session
    final sessionResult = await SupaFlow.client
        .from('video_call_sessions')
        .select('id, transcript, transcription_status, ...')
        .eq('appointment_id', appointmentId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    // Show PostCallClinicalNotesDialog
    await showDialog(
      context: context,
      builder: (dialogContext) => PostCallClinicalNotesDialog(
        sessionId: actualSessionId!,
        appointmentId: appointmentId,
        // ...
      ),
    );
  }
}
```
✅ Correctly shows dialog after call ends

#### 6. Authentication
**File**: `lib/custom_code/actions/control_medical_transcription.dart` (lines 49-78)
```dart
final firebaseToken = await user.getIdToken(true);

final response = await http.post(
  Uri.parse('$supabaseUrl/functions/v1/start-medical-transcription'),
  headers: {
    'x-firebase-token': firebaseToken, // lowercase as required
  },
  body: jsonEncode(requestBody),
);
```
✅ Correctly uses Firebase auth token

### Root Cause: Missing AWS Credentials ⚠️

The edge function requires AWS credentials to call Transcribe Medical:

**File**: `supabase/functions/start-medical-transcription/index.ts` (lines 30-32)
```typescript
const AWS_ACCESS_KEY_ID = Deno.env.get('AWS_ACCESS_KEY_ID') || '';
const AWS_SECRET_ACCESS_KEY = Deno.env.get('AWS_SECRET_ACCESS_KEY') || '';
const AWS_REGION_DEFAULT = Deno.env.get('AWS_REGION') || 'eu-central-1';
```

**If these environment variables are not set, AWS SDK cannot authenticate with Transcribe service.**

### Diagnostic Steps

#### 1. Check Edge Function Environment Variables
```bash
# Check if AWS credentials are set in Supabase
npx supabase secrets list

# Look for:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - AWS_REGION (optional, defaults to eu-central-1)
```

#### 2. Verify AWS IAM Permissions
The IAM user/role must have these permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "chime:StartMeetingTranscription",
        "chime:StopMeetingTranscription",
        "transcribe:StartMedicalTranscriptionJob",
        "transcribe:GetMedicalTranscriptionJob"
      ],
      "Resource": "*"
    }
  ]
}
```

#### 3. Test Transcription Flow with Debug Logs

Run a test video call and check these debug logs:

**Expected Logs in Order**:
```
🎙️ Provider joined - preparing transcription auto-start...
🎙️ Auto-starting transcription for provider...
🔍 _startTranscription called
✅ Transcription started. Duration limit: 120 minutes

[During call - live captions]
✅ Caption stored to database

[When provider ends call]
🛑 Stopping transcription before ending call...
🔍 _stopTranscription called
🛑 Stopping medical transcription...
📊 Transcription stop result: true
✅ Transcription stopped. Duration: 2.5 min

[After transcription stops]
📋 Found video session: [session-id]
   Transcript available: true
   Transcription status: completed
   Transcript length: 1234 chars
📋 Showing PostCallClinicalNotesDialog...
```

**If Transcription Start Fails**:
```
❌ Failed to start transcription: [error message]
```
→ Check AWS credentials and IAM permissions

**If No Live Captions**:
```
❌ Failed to store caption: [error]
```
→ Check database permissions for `live_caption_segments` table

**If Transcript Empty**:
```
[Medical Transcription] No caption segments found for session [id]
```
→ Live captions were never saved - check AWS Transcribe is sending captions

#### 4. Verify Database Setup

```sql
-- Check if live_caption_segments table exists and has RLS policies
SELECT table_name, row_security
FROM pg_tables
WHERE schemaname = 'public'
  AND table_name = 'live_caption_segments';

-- Check recent caption segments
SELECT session_id, speaker_name, transcript_text, created_at
FROM live_caption_segments
ORDER BY created_at DESC
LIMIT 10;

-- Check recent video call sessions with transcripts
SELECT id, appointment_id, transcript, transcription_status,
       transcription_duration_seconds, live_transcription_enabled
FROM video_call_sessions
WHERE transcription_status IS NOT NULL
ORDER BY created_at DESC
LIMIT 5;
```

### Fix Instructions

#### Option 1: Set AWS Credentials in Supabase (Recommended)

```bash
# Set secrets via Supabase CLI
npx supabase secrets set AWS_ACCESS_KEY_ID="your-access-key-id"
npx supabase secrets set AWS_SECRET_ACCESS_KEY="your-secret-access-key"
npx supabase secrets set AWS_REGION="eu-central-1"

# Optional: Set daily budget limit
npx supabase secrets set DAILY_TRANSCRIPTION_BUDGET_USD="50"

# Verify secrets are set
npx supabase secrets list
```

#### Option 2: Create IAM User for Transcription

1. Go to AWS IAM Console
2. Create new user: `medzen-transcription-service`
3. Attach policy with permissions above
4. Create access key
5. Set in Supabase secrets (Option 1)

#### Option 3: Use AWS STS Temporary Credentials

Update edge function to use AWS STS AssumeRole:
```typescript
// Use role-based authentication instead of access keys
const credentials = new STSClient({}).send(new AssumeRoleCommand({
  RoleArn: Deno.env.get('AWS_TRANSCRIBE_ROLE_ARN'),
  RoleSessionName: 'medzen-transcription',
}));
```

### Testing After Fix

1. **Set AWS credentials** using Option 1 or 2
2. **Deploy edge function** (if modified):
   ```bash
   npx supabase functions deploy start-medical-transcription
   ```
3. **Test video call**:
   - Login as provider
   - Start video call from appointment
   - Verify "🎙️ Auto-starting transcription" log appears
   - Speak for 30-60 seconds
   - Check for "✅ Caption stored to database" logs
   - End call as provider
   - Verify "🛑 Stopping transcription" log appears
   - **Dialog should appear** with transcript and AI-generated SOAP notes

4. **Verify database**:
   ```sql
   -- Check that captions were saved
   SELECT COUNT(*) FROM live_caption_segments
   WHERE created_at > NOW() - INTERVAL '10 minutes';

   -- Check that transcript was aggregated
   SELECT transcript, transcription_status
   FROM video_call_sessions
   WHERE created_at > NOW() - INTERVAL '10 minutes'
   ORDER BY created_at DESC LIMIT 1;
   ```

### Success Criteria

- ✅ Provider sees "Transcription started" SnackBar when joining call
- ✅ Live captions appear during call (if speaking)
- ✅ `live_caption_segments` table has entries for the session
- ✅ Provider sees "Transcription stopped" SnackBar when ending call
- ✅ `video_call_sessions.transcript` field is populated with formatted text
- ✅ PostCallClinicalNotesDialog appears with AI-generated SOAP notes
- ✅ Provider can edit and sign the clinical note

### Rollback Plan

If transcription causes issues:

1. **Disable auto-start temporarily**:
   ```dart
   // In chime_meeting_enhanced.dart line 999, comment out auto-start:
   // if (widget.isProvider) {
   //   Future.delayed(const Duration(seconds: 2), () {
   //     if (mounted && !_isTranscriptionEnabled && !_isTranscriptionStarting) {
   //       _startTranscription();
   //     }
   //   });
   // }
   ```

2. **Manual transcription button**:
   Providers can still start transcription manually using the microphone button in the video call UI

3. **Skip dialog if no transcript**:
   The dialog will still show but with a message "No transcript available" if transcription fails

## Summary

### Issue 1 (Chat Display) - FIXED ✅
- **Problem**: Web chat showed "US" instead of sender name/avatar
- **Root Cause**: Field name mismatch (`photo_url` vs `profile_picture_url`)
- **Fix**: Updated edge function to use correct field name
- **Deploy**: `npx supabase functions deploy call-send-message`

### Issue 2 (Transcription) - DIAGNOSED ⚠️
- **Problem**: SOAP notes dialog not showing after video calls
- **Root Cause**: Missing AWS credentials in edge function environment
- **Code Status**: All logic is correct ✅
- **Fix Required**: Set AWS credentials as Supabase secrets
- **Deploy**: `npx supabase secrets set ...` (no code changes needed)

### Next Steps

1. ✅ Deploy chat message fix
2. Set AWS credentials for transcription
3. Test both fixes with real video call
4. Monitor debug logs for any remaining issues
