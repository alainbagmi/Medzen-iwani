# AWS Transcribe Medical Transcription Fix - Deployment Status
**Date:** January 8, 2026
**Status:** ✅ CODE FIXED | ⚠️ DEPLOYMENT BLOCKED BY NETWORK ISSUES

## Summary

The root cause of the transcription issue has been **successfully identified and fixed** in code. However, deployment to AWS Lambda is **blocked by network connectivity issues** when uploading the 5.7MB package.

## What Was Fixed

### Root Cause
AWS Chime meetings were being created **without** `TranscriptionConfiguration`, preventing audio from being routed to AWS Transcribe Medical service.

### Code Changes
**File:** `aws-lambda/chime-meeting-manager/index.js:288-321`

**Added:**
```javascript
// ✅ CRITICAL FIX: Add TranscriptionConfiguration at meeting creation
// This enables audio routing to AWS Transcribe Medical for real-time transcription
...(enableTranscription && {
  TranscriptionConfiguration: {
    EngineTranscribeMedicalSettings: {
      LanguageCode: transcriptionLanguage,
      Specialty: medicalSpecialty,
      Type: 'CONVERSATION',
      VocabularyName: process.env.MEDICAL_VOCABULARY_NAME,
      ContentIdentificationType: 'PHI' // Identify Protected Health Information
    }
  }
})
```

This change ensures that when `enableTranscription=true` is passed during meeting creation, the Chime SDK will:
1. Configure audio routing to Transcribe Medical
2. Enable real-time medical transcription
3. Capture audio segments with PHI detection
4. Store transcripts in `video_call_sessions.transcript`

## Deployment Attempts

### What Was Tried:
1. ✅ **Lambda code updated locally** at `aws-lambda/chime-meeting-manager/index.js`
2. ✅ **Package created** (`npm install` + `zip`) - 5.7MB
3. ❌ **Direct AWS Lambda upload** - Connection closed/timeout errors
4. ❌ **S3 upload (eu-west-1)** - Region mismatch with Lambda
5. ✅ **S3 bucket created** (`medzen-lambda-deployments-eu-central-1`)
6. ⏳ **S3 upload (eu-central-1)** - Stalls at 4.0-5.0 MiB repeatedly

### Network Issues Encountered:
```
Error 1: Connection was closed before we received a valid response from endpoint URL
Error 2: Could not connect to the endpoint URL: "https://lambda.eu-central-1.amazonaws.com/..."
Error 3: S3 uploads stall at 4.0-5.0 MiB out of 5.7 MiB (70-87% complete)
```

These errors suggest:
- Intermittent network connectivity issues
- Possible firewall/proxy interference with large file uploads
- AWS service timeouts (though unlikely given successful small operations)

## Alternative Deployment Methods

### Option 1: AWS Console (RECOMMENDED - Easiest)
1. Navigate to [AWS Lambda Console](https://eu-central-1.console.aws.amazon.com/lambda/home?region=eu-central-1#/functions/medzen-meeting-manager)
2. Click "Upload from" → ".zip file"
3. Select `aws-lambda/chime-meeting-manager/function.zip` (5.7MB)
4. Click "Save"
5. Wait for "Successfully updated" message (30-60 seconds)

**Pros:** Most reliable, visual confirmation
**Cons:** Manual process, requires AWS Console access

### Option 2: Retry AWS CLI Upload from Different Network
If the issue is local network/ISP related:
```bash
# From a different network (mobile hotspot, VPN, different location):
cd aws-lambda/chime-meeting-manager
aws lambda update-function-code \
  --function-name medzen-meeting-manager \
  --zip-file fileb://function.zip \
  --region eu-central-1
```

### Option 3: Use S3 Upload Completed to eu-west-1
The file successfully uploaded to eu-west-1:
```bash
# Update Lambda to read from eu-west-1 S3 (if cross-region is enabled):
aws lambda update-function-code \
  --function-name medzen-meeting-manager \
  --s3-bucket medzen-lambda-deployments \
  --s3-key chime-meeting-manager/function-20260108-184356.zip \
  --region eu-central-1
```
Note: This failed before with region redirect error. May need IAM policy adjustment.

### Option 4: Manual File Transfer via S3 Console
1. Go to [S3 Console](https://s3.console.aws.amazon.com/s3/buckets/medzen-lambda-deployments-eu-central-1)
2. Create folder `chime-meeting-manager/`
3. Upload `function.zip` manually (browser upload often handles large files better)
4. Then run:
```bash
aws lambda update-function-code \
  --function-name medzen-meeting-manager \
  --s3-bucket medzen-lambda-deployments-eu-central-1 \
  --s3-key chime-meeting-manager/function.zip \
  --region eu-central-1
```

### Option 5: Split Upload with Multipart
For very unstable connections:
```bash
# Upload in parts
cd aws-lambda/chime-meeting-manager
aws s3api put-object \
  --bucket medzen-lambda-deployments-eu-central-1 \
  --key chime-meeting-manager/function.zip \
  --body function.zip \
  --region eu-central-1 \
  --storage-class STANDARD

# Then update Lambda
aws lambda update-function-code \
  --function-name medzen-meeting-manager \
  --s3-bucket medzen-lambda-deployments-eu-central-1 \
  --s3-key chime-meeting-manager/function.zip \
  --region eu-central-1
```

## Verification Steps

After successful deployment, verify the fix works:

### 1. Check Lambda Update Timestamp
```bash
aws lambda get-function \
  --function-name medzen-meeting-manager \
  --region eu-central-1 \
  --query 'Configuration.[LastModified,CodeSize,State]'
```
Expected output:
```json
[
  "2026-01-08T...",  // Should be today's date
  5985672,           // Should be ~5.7MB
  "Active"
]
```

### 2. Test with New Video Call
1. Create a new appointment in the app
2. Start video call with `Enable Transcription` ON
3. Speak during the call for 30+ seconds
4. End the call
5. Check `video_call_sessions` table:
```sql
SELECT
  transcript,
  transcription_status,
  speaker_segments,
  transcription_duration_seconds
FROM video_call_sessions
WHERE appointment_id = '<your-appointment-id>'
ORDER BY created_at DESC LIMIT 1;
```
Expected: `transcript` should contain text, not be empty/null

### 3. Verify Live Captions
```sql
SELECT COUNT(*) as segment_count,
       STRING_AGG(transcript_text, ' ') as full_transcript
FROM live_caption_segments
WHERE session_id = '<your-session-id>';
```
Expected: `segment_count > 0` and `full_transcript` contains spoken words

### 4. Check Edge Function Logs
```bash
npx supabase functions logs start-medical-transcription --tail
```
Look for:
- `"Medical transcription started"` message
- `"segmentCount": > 0` in stop response
- No connection errors to AWS Lambda

## Files Ready for Deployment

| File | Location | Size | Status |
|------|----------|------|--------|
| Lambda code | `aws-lambda/chime-meeting-manager/index.js` | 685 lines | ✅ Fixed |
| Lambda package | `aws-lambda/chime-meeting-manager/function.zip` | 5.7 MB | ✅ Ready |
| S3 (eu-west-1) | `s3://medzen-lambda-deployments/...` | 5.7 MB | ✅ Uploaded |
| S3 (eu-central-1) | `s3://medzen-lambda-deployments-eu-central-1/` | - | ⏳ Pending |

## Cost Impact

**Current waste** (per failed transcription):
- $0.0912 for 73 seconds of transcription with zero output
- If 10 calls/day fail: ~$1/day = **$365/year** wasted

**After fix:**
- Only charged for actual transcription time
- Successful transcriptions produce usable transcripts
- Estimated savings: $300-350/year

## Support Resources

### AWS Documentation:
- [Chime SDK Meeting Transcription](https://docs.aws.amazon.com/chime-sdk/latest/dg/meeting-transcription.html)
- [Transcribe Medical](https://docs.aws.amazon.com/transcribe/latest/dg/transcribe-medical.html)
- [Lambda Deployment Packages](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-package.html)

### Related Files:
- Diagnostic report: `TRANSCRIPTION_DIAGNOSIS_FINAL.md`
- Edge function: `supabase/functions/start-medical-transcription/index.ts`
- Meeting token function: `supabase/functions/chime-meeting-token/index.ts`

## Next Steps

1. **Deploy using one of the alternative methods above** (recommend Option 1: AWS Console)
2. **Verify deployment** using the verification steps
3. **Test with new video call** to confirm transcription works
4. **Monitor for 24 hours** to ensure stability
5. **Update documentation** once confirmed working

## Questions?

If deployment continues to fail:
- Check AWS CloudWatch logs for Lambda function errors
- Verify IAM permissions for Lambda/S3 access
- Contact AWS Support if persistent connectivity issues
- Consider deploying from AWS CloudShell (built-in to AWS Console)

---

**Status Legend:**
- ✅ = Completed successfully
- ⏳ = In progress / pending
- ❌ = Failed / blocked
- ⚠️ = Warning / attention needed
