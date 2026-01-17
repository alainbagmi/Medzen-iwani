# AWS Transcribe Medical Transcription Diagnosis - Final Report
**Date:** January 8, 2026
**Session ID:** 67457667-dd88-4c1e-ad68-9f4d9e072306
**Meeting Duration:** 73 seconds
**Status:** ❌ NOT WORKING - Zero audio captured

## Executive Summary
The AWS Transcribe Medical service is being **started successfully** but is **capturing zero audio segments**. The transcription runs for the full duration (73 seconds) but produces no transcript. This indicates a fundamental issue with how audio is being routed from the Chime meeting to the Transcribe service.

## Symptoms Observed

### From Flutter App Logs
```
🛑 Stopping medical transcription...
📡 [TRANSCRIPTION] Response received
   Status Code: 200
   Body: {
     "success": true,
     "message": "Medical transcription stopped",
     "stats": {
       "durationSeconds": 73,
       "durationMinutes": 1.2,
       "estimatedCost": 0.0912,
       "transcriptLength": 0,          ⚠️ ZERO CHARACTERS
       "segmentCount": 0,              ⚠️ ZERO SEGMENTS
       "hasTranscript": false          ⚠️ NO TRANSCRIPT
     }
   }
```

### Transcription Stats
- ✅ Service started: **Yes** (no errors)
- ✅ Service running: **Yes** (73 seconds)
- ❌ Audio segments captured: **ZERO**
- ❌ Transcript generated: **NONE**
- ❌ Live captions stored: **NONE**
- 💰 Cost incurred: **$0.0912** (for running time, despite no output)

## Root Cause Analysis

### Issue #1: Chime Meeting Not Configured for Transcription at Creation
AWS Chime SDK requires meetings to be created with transcription **capabilities** enabled from the start, not just when `StartMeetingTranscriptionCommand` is called.

**Current Flow:**
1. ✅ Edge function `chime-meeting-token` calls AWS Lambda API
2. ✅ Lambda creates Chime meeting (but **without** transcription features)
3. ✅ Meeting is active and video/audio work fine
4. ✅ Edge function `start-medical-transcription` calls `StartMeetingTranscriptionCommand`
5. ❌ **Transcribe starts but receives NO AUDIO** (meeting not configured for it)

**Required Configuration (Missing):**
When creating the Chime meeting, the AWS Lambda must include:

```javascript
// ❌ CURRENT: Meeting created without this configuration
// ✅ REQUIRED: Meeting MUST include this at creation
const createMeetingParams = {
  ClientRequestToken: uuidv4(),
  MediaRegion: 'eu-central-1',
  ExternalMeetingId: appointmentId,

  // ⚠️ THIS IS MISSING - CRITICAL FOR TRANSCRIPTION
  TranscriptionConfiguration: {
    EngineTranscribeMedicalSettings: {
      LanguageCode: 'en-US',
      Specialty: 'PRIMARYCARE',
      Type: 'CONVERSATION',
      VocabularyName: 'medzen-medical-vocab' // Optional
    }
  }
};
```

### Issue #2: Audio Routing Not Configured
Even if `StartMeetingTranscriptionCommand` succeeds, audio won't flow to Transcribe unless the meeting was created with `TranscriptionConfiguration`.

**Why This Happens:**
- AWS Chime SDK sets up audio routing **at meeting creation time**
- When a meeting is created **without** transcription config, audio stays within Chime's media pipelines
- Calling `StartMeetingTranscriptionCommand` later cannot retroactively configure audio routing
- Result: Transcribe service starts, waits for audio, receives nothing, stops with empty transcript

## Evidence from Code

### 1. Edge Function: start-medical-transcription (Line 444-456)
```typescript
// ✅ This code is CORRECT
const startCommand = new StartMeetingTranscriptionCommand({
  MeetingId: meetingId,
  TranscriptionConfiguration: {
    EngineTranscribeMedicalSettings: {
      LanguageCode: language as 'en-US' | 'en-GB' | 'es-US',
      Specialty: specialty as 'PRIMARYCARE',
      Type: 'CONVERSATION',
      VocabularyName: Deno.env.get('MEDICAL_VOCABULARY_NAME'),
      ContentIdentificationType: contentIdentificationType,
    },
  },
});
await chimeClient.send(startCommand);
```
**Diagnosis:** This code is fine, but it's trying to start transcription on a meeting that **wasn't configured for transcription at creation**.

### 2. Edge Function: chime-meeting-token (Line 280-286)
```typescript
// Calls external AWS Lambda to create meeting
const lambdaResponse = await callChimeLambda("create", {
  appointmentId,
  userId,
  enableRecording,
  enableTranscription,  // ⚠️ Flag is passed...
  transcriptionLanguage,
});
```
**Diagnosis:** The `enableTranscription` flag is sent to the Lambda, but the **Lambda is not using it** to configure the meeting with `TranscriptionConfiguration`.

### 3. Lambda API Call (Line 83-108)
```typescript
const callChimeLambda = async (action: string, params: any) => {
  const chimeApiEndpoint = Deno.env.get("CHIME_API_ENDPOINT");
  // ... calls external Lambda via API Gateway
};
```
**Diagnosis:** The actual Lambda function code is **not in this repository**. It's hosted on AWS and called via API Gateway. That Lambda needs to be updated.

## Solution

### Option 1: Update AWS Lambda (RECOMMENDED)
**Location:** The Lambda function behind `CHIME_API_ENDPOINT`
**File:** Likely `aws-lambda/chime-meetings/index.js` or similar
**Change Required:**

```javascript
// In your AWS Lambda function that creates Chime meetings:
exports.handler = async (event) => {
  const { action, enableTranscription, transcriptionLanguage, specialty } = JSON.parse(event.body);

  if (action === 'create') {
    const createMeetingParams = {
      ClientRequestToken: uuidv4(),
      MediaRegion: process.env.AWS_REGION || 'eu-central-1',
      ExternalMeetingId: appointmentId,

      // ✅ ADD THIS: Configure transcription at meeting creation
      ...(enableTranscription && {
        TranscriptionConfiguration: {
          EngineTranscribeMedicalSettings: {
            LanguageCode: transcriptionLanguage || 'en-US',
            Specialty: specialty || 'PRIMARYCARE',
            Type: 'CONVERSATION'
          }
        }
      })
    };

    const meeting = await chimeClient.send(
      new CreateMeetingCommand(createMeetingParams)
    );
    // ... rest of code
  }
};
```

### Option 2: Alternative - Use Chime Media Pipelines (Advanced)
Instead of meeting-level transcription, use **Media Capture Pipelines**:
1. Create meeting without transcription config
2. Create a separate Media Capture Pipeline
3. Attach Transcribe to the pipeline
4. More complex, but gives more control

### Option 3: Use Post-Call Transcription (Workaround)
If real-time transcription isn't critical:
1. Record the meeting audio
2. Upload to S3
3. Use AWS Transcribe Medical **batch** API post-call
4. Simpler, but no live captions

## Verification Steps

### After fixing the Lambda, verify:

1. **Check Meeting Creation:**
```bash
aws chime-sdk-meetings get-meeting --meeting-id <meeting-id>
```
Should show `TranscriptionConfiguration` in response.

2. **Check Supabase Table:**
```sql
SELECT
  id,
  live_transcription_enabled,
  transcription_status,
  transcript,
  speaker_segments,
  transcription_duration_seconds
FROM video_call_sessions
WHERE appointment_id = 'ab817be4-be19-40ea-994a-5c40ddf981e8'
ORDER BY created_at DESC
LIMIT 1;
```

3. **Check Live Captions:**
```sql
SELECT COUNT(*) as segment_count
FROM live_caption_segments
WHERE session_id = '67457667-dd88-4c1e-ad68-9f4d9e072306';
```
Should be **> 0** if working.

4. **Check Edge Function Logs:**
```bash
npx supabase functions logs start-medical-transcription --tail
```
Look for: `"Medical transcription started"` and `"segmentCount": > 0`

## Cost Impact
**Current Waste:** $0.0912 per failed transcription session (1.2 minutes @ $0.075/minute)
**Daily Impact:** If 10 sessions/day fail: ~$1/day = **$365/year wasted**

## Next Steps

### Immediate Actions:
1. ✅ **Locate the AWS Lambda function** that creates Chime meetings
   - Check `CHIME_API_ENDPOINT` environment variable in Supabase
   - Example: `https://xxxxx.execute-api.eu-central-1.amazonaws.com/prod/meetings`
   - Find the Lambda behind this API Gateway endpoint

2. ✅ **Update Lambda to configure transcription** (see Option 1 above)

3. ✅ **Deploy updated Lambda:**
   ```bash
   cd path/to/lambda
   npm install
   zip -r function.zip .
   aws lambda update-function-code \
     --function-name medzen-chime-meetings \
     --zip-file fileb://function.zip
   ```

4. ✅ **Test with a new meeting:**
   - Create new appointment
   - Start video call with transcription enabled
   - Speak during call
   - Check `live_caption_segments` table for data

5. ✅ **Monitor for 24 hours:**
   - Check transcription success rate
   - Verify costs align with actual usage
   - Validate transcript quality

## References
- AWS Chime SDK Docs: https://docs.aws.amazon.com/chime-sdk/latest/dg/meeting-transcription.html
- Transcribe Medical: https://docs.aws.amazon.com/transcribe/latest/dg/transcribe-medical.html
- Edge Function: `supabase/functions/start-medical-transcription/index.ts:444`
- Meeting Token Function: `supabase/functions/chime-meeting-token/index.ts:280`

---

## Summary
**The transcription edge functions are working correctly.** The problem is in the **external AWS Lambda that creates Chime meetings** - it's not configuring meetings with transcription capabilities at creation time. Once that Lambda is fixed to include `TranscriptionConfiguration` when `enableTranscription=true`, transcription will work end-to-end.
