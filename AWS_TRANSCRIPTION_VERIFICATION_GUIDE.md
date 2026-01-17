# AWS Transcription Verification Guide

## Issues Fixed

### 1. ✅ Post-Call SOAP Note Dialog Now Appears
**What was fixed:**
- Modified `lib/custom_code/actions/join_room.dart` (lines 674-725)
- Added logic to show `PostCallClinicalNotesDialog` when provider ends call
- Fetches patient name from database before showing dialog
- Dialog checks for transcript and generates clinical note automatically

**How it works now:**
1. Provider ends video call
2. System fetches patient information
3. Post-call dialog appears automatically
4. Dialog checks if transcript exists in `video_call_sessions` table
5. If transcript exists, calls `generate-clinical-note` edge function
6. Provider reviews/edits AI-generated SOAP note
7. Saves to `clinical_notes` table for EHR sync

### 2. ⚠️ AWS Transcription - Requires Credential Verification

## Required AWS Credentials

The `start-medical-transcription` edge function requires these environment variables:

```bash
AWS_ACCESS_KEY_ID=<your-aws-access-key>
AWS_SECRET_ACCESS_KEY=<your-aws-secret-key>
AWS_REGION=eu-central-1  # Optional, defaults to eu-central-1
```

## Verification Steps

### Step 1: Check if credentials are set

```bash
# List all edge function secrets
npx supabase secrets list

# Should show:
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_REGION (optional)
```

### Step 2: Set credentials (if missing)

```bash
# Set AWS credentials for edge functions
npx supabase secrets set AWS_ACCESS_KEY_ID=<your-key>
npx supabase secrets set AWS_SECRET_ACCESS_KEY=<your-secret>
npx supabase secrets set AWS_REGION=eu-central-1
```

### Step 3: Deploy the edge function

```bash
# Deploy the updated function
npx supabase functions deploy start-medical-transcription
```

### Step 4: Test transcription

```bash
# Start a video call as a provider
# Transcription should auto-start after 2 seconds
# Check browser console for logs:
# - "🎙️ Auto-starting transcription for provider..."
# - "✅ Medical transcription started successfully"

# Or check Supabase logs:
npx supabase functions logs start-medical-transcription --tail
```

## AWS IAM Policy Required

Your AWS user/role needs these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "chime:StartMeetingTranscription",
        "chime:StopMeetingTranscription",
        "chime:GetMeeting",
        "transcribe:StartMedicalStreamTranscription",
        "transcribe:StartStreamTranscription",
        "cloudwatch:PutMetricData"
      ],
      "Resource": "*"
    }
  ]
}
```

## Transcription Flow

1. **Provider joins call** → `ChimeMeetingEnhanced` widget loads
2. **Auto-start (2s delay)** → Calls `_startTranscription()` method
3. **Edge function call** → `controlMedicalTranscription()` action
4. **AWS API call** → `start-medical-transcription` edge function
5. **Transcription starts** → AWS Transcribe Medical begins streaming
6. **Live captions** → Saved to `live_caption_segments` table
7. **Provider ends call** → Stops transcription, aggregates transcript
8. **Transcript saved** → Stored in `video_call_sessions.transcript`
9. **SOAP note dialog** → Shows with AI-generated clinical note

## Troubleshooting

### Issue: "AWS credentials not configured" error

**Solution:**
```bash
# Verify credentials are set
npx supabase secrets list

# If missing, set them:
npx supabase secrets set AWS_ACCESS_KEY_ID=<key>
npx supabase secrets set AWS_SECRET_ACCESS_KEY=<secret>

# Redeploy function
npx supabase functions deploy start-medical-transcription
```

### Issue: Transcription doesn't start

**Check these:**
1. **Browser console** - Look for error messages starting with "🎙️" or "❌"
2. **Edge function logs** - `npx supabase functions logs start-medical-transcription --tail`
3. **Session status** - Video call session must be 'active' in database
4. **Provider role** - Only providers can start transcription
5. **Meeting region** - Check `video_call_sessions.media_region` matches AWS region

### Issue: Transcript is empty in SOAP note dialog

**Possible causes:**
1. Transcription was never started (check logs)
2. Transcription failed to stop properly (check logs)
3. No speech detected during call (check audio setup)
4. Call ended before transcription aggregation completed (wait 5-10 seconds)

**Check transcript status:**
```sql
-- Check if transcript exists
SELECT
  id,
  status,
  transcript IS NOT NULL as has_transcript,
  length(transcript) as transcript_length,
  transcription_status,
  transcription_language
FROM video_call_sessions
WHERE id = '<session-id>';

-- Check live caption segments
SELECT
  speaker_label,
  text,
  start_time,
  end_time
FROM live_caption_segments
WHERE video_call_session_id = '<session-id>'
ORDER BY start_time;
```

## Debug Logging

The following logs help track transcription status:

**Client-side (Browser Console):**
- `🎙️ Provider joined - preparing transcription auto-start...`
- `🎙️ Auto-starting transcription for provider...`
- `✅ Medical transcription started successfully`
- `🛑 Stopping transcription before ending call...`
- `❌ Failed to start transcription: <error>`

**Server-side (Edge Function Logs):**
- `[Medical Transcription] start for meeting <meeting-id>`
- `[Medical Transcription] Using region: <region>`
- `[Medical Transcription] Transcription started successfully`
- `[Medical Transcription] stop for meeting <meeting-id>`
- `[Medical Transcription] Aggregating live caption segments`
- `[Medical Transcription] Transcript saved successfully`

## Testing Checklist

- [ ] AWS credentials are set in Supabase secrets
- [ ] Edge function deployed successfully
- [ ] Video call starts without errors
- [ ] Browser console shows "🎙️ Auto-starting transcription"
- [ ] Edge function logs show "Transcription started successfully"
- [ ] Speaking during call produces live captions
- [ ] Ending call shows "🛑 Stopping transcription"
- [ ] Post-call SOAP note dialog appears for provider
- [ ] Dialog shows "Generating clinical note from transcript..."
- [ ] AI-generated SOAP note appears in dialog text field
- [ ] Saving note creates record in `clinical_notes` table

## Cost Monitoring

AWS Transcribe Medical costs $0.075 per minute ($4.50/hour).

**Check daily usage:**
```sql
SELECT
  usage_date,
  total_minutes,
  total_cost_usd,
  session_count
FROM transcription_usage_daily
ORDER BY usage_date DESC
LIMIT 30;
```

**Daily budget limit:** $100 (configurable in edge function)
**Maximum call duration:** 4 hours (240 minutes)

## Next Steps

1. ✅ Verify AWS credentials are set in Supabase
2. ✅ Deploy edge function
3. ✅ Test video call with transcription
4. ✅ Verify post-call SOAP note appears
5. ✅ Check transcript quality and speaker labels
6. ✅ Monitor costs in `transcription_usage_daily` table

## Support

If transcription still doesn't work after following this guide:

1. Check **complete logs** from both client and server
2. Verify AWS IAM permissions are correct
3. Ensure video call session is active in database
4. Test with a fresh video call (don't reuse old sessions)
5. Contact AWS support if Transcribe Medical API calls fail
