# AWS IAM Setup for Medical Transcription Service

## Overview
This guide walks you through creating an AWS IAM user with appropriate permissions for the MedZen transcription service.

## Step 1: Create IAM User

### Using AWS Console:
1. Go to AWS IAM Console: https://console.aws.amazon.com/iam/
2. Navigate to **Users** → **Add users**
3. Set username: `medzen-transcription-service`
4. Select: **Access key - Programmatic access** (NOT console access)
5. Click **Next: Permissions**

### Using AWS CLI:
```bash
aws iam create-user --user-name medzen-transcription-service
```

## Step 2: Create and Attach IAM Policy

### Using AWS Console:
1. In the permissions step, click **Attach existing policies directly**
2. Click **Create policy**
3. Select **JSON** tab
4. Copy the contents of `aws-deployment/iam-policies/transcription-service-policy.json`
5. Paste into the policy editor
6. Click **Next: Tags** (optional)
7. Click **Next: Review**
8. Set policy name: `MedZenTranscriptionServicePolicy`
9. Set description: `Permissions for MedZen medical transcription and video call transcription`
10. Click **Create policy**
11. Go back to the user creation screen
12. Refresh the policy list
13. Search for `MedZenTranscriptionServicePolicy`
14. Check the box next to it
15. Click **Next: Tags** → **Next: Review** → **Create user**

### Using AWS CLI:
```bash
# Create the policy
aws iam create-policy \
  --policy-name MedZenTranscriptionServicePolicy \
  --policy-document file://aws-deployment/iam-policies/transcription-service-policy.json \
  --description "Permissions for MedZen medical transcription and video call transcription"

# Attach the policy to the user (replace ACCOUNT_ID with your AWS account ID)
aws iam attach-user-policy \
  --user-name medzen-transcription-service \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/MedZenTranscriptionServicePolicy
```

## Step 3: Create Access Key

### Using AWS Console:
1. After user is created, you'll see a success screen with **Access key ID** and **Secret access key**
2. **IMPORTANT**: Download the CSV or copy these values immediately - you cannot retrieve the secret key again!
3. Save these securely - you'll need them in the next step

### Using AWS CLI:
```bash
aws iam create-access-key --user-name medzen-transcription-service
```

**Output will look like:**
```json
{
  "AccessKey": {
    "UserName": "medzen-transcription-service",
    "AccessKeyId": "AKIA...",
    "Status": "Active",
    "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/...",
    "CreateDate": "2024-01-08T12:00:00Z"
  }
}
```

**SAVE THESE VALUES IMMEDIATELY!**

## Step 4: Set Supabase Secrets

Now that you have the access key credentials, set them as Supabase secrets:

```bash
# Replace with your actual values
npx supabase secrets set AWS_ACCESS_KEY_ID="AKIA..."
npx supabase secrets set AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/..."
npx supabase secrets set AWS_REGION="eu-central-1"

# Optional: Set daily transcription budget (in USD)
npx supabase secrets set DAILY_TRANSCRIPTION_BUDGET_USD="50"

# Verify secrets are set (won't show actual values, just keys)
npx supabase secrets list
```

**Expected output:**
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
DAILY_TRANSCRIPTION_BUDGET_USD
```

## Step 5: Redeploy Edge Function

After setting secrets, redeploy the transcription edge function:

```bash
npx supabase functions deploy start-medical-transcription
```

## Step 6: Test Transcription

### Test Video Call with Transcription:
1. Login as a provider
2. Start a video call from an appointment
3. Wait 2-3 seconds for transcription to auto-start
4. Check browser console for: `🎙️ Auto-starting transcription for provider...`
5. Speak for 30-60 seconds
6. Check console for: `✅ Caption stored to database`
7. End the call as provider
8. Check console for: `🛑 Stopping transcription before ending call...`
9. **Expected**: PostCallClinicalNotesDialog appears with transcript and AI-generated SOAP notes

### Verify in Database:
```sql
-- Check live caption segments
SELECT session_id, speaker_name, transcript_text, created_at
FROM live_caption_segments
WHERE created_at > NOW() - INTERVAL '10 minutes'
ORDER BY created_at DESC
LIMIT 20;

-- Check video call session transcript
SELECT id, appointment_id, transcript, transcription_status,
       transcription_duration_seconds, live_transcription_enabled
FROM video_call_sessions
WHERE created_at > NOW() - INTERVAL '10 minutes'
ORDER BY created_at DESC
LIMIT 5;
```

## Troubleshooting

### Issue: "AccessDeniedException" in Logs
**Cause**: IAM policy not attached or incorrect permissions
**Fix**: Verify policy is attached to user and has correct permissions

### Issue: "InvalidClientTokenId"
**Cause**: Access key ID is incorrect or not set
**Fix**: Verify `AWS_ACCESS_KEY_ID` secret is set correctly

### Issue: "SignatureDoesNotMatch"
**Cause**: Secret access key is incorrect
**Fix**: Verify `AWS_SECRET_ACCESS_KEY` secret is set correctly

### Issue: No transcription starts
**Cause**: Secrets not loaded by edge function
**Fix**: Redeploy edge function after setting secrets

### Issue: Transcription starts but no captions appear
**Cause**: AWS Transcribe not sending data or network issues
**Fix**: Check AWS CloudWatch logs for Transcribe errors

## Security Best Practices

1. **Never commit credentials** - Access keys should only be in Supabase secrets
2. **Rotate keys regularly** - Consider rotating access keys every 90 days
3. **Use least privilege** - The provided policy only grants necessary permissions
4. **Monitor usage** - Set up AWS CloudWatch alarms for unusual activity
5. **Enable MFA on root account** - Protect your AWS account with multi-factor authentication

## Cost Monitoring

AWS Transcribe Medical pricing (as of 2024):
- $0.0004 per second for medical transcription
- ~$0.024 per minute
- ~$1.44 per hour

The edge function tracks costs in `transcription_usage_daily` table and respects the `DAILY_TRANSCRIPTION_BUDGET_USD` limit.

## Policy Permissions Explained

| Permission | Purpose |
|------------|---------|
| `chime:StartMeetingTranscription` | Start transcription for video calls |
| `chime:StopMeetingTranscription` | Stop transcription when call ends |
| `transcribe:StartMedicalTranscriptionJob` | Start medical transcription jobs |
| `transcribe:StartMedicalStreamTranscription` | Real-time medical transcription streaming |
| `transcribe:GetMedicalTranscriptionJob` | Check transcription job status |
| `s3:GetObject`, `s3:PutObject` | Store/retrieve transcripts from S3 |
| `logs:CreateLogStream`, `logs:PutLogEvents` | CloudWatch logging |

## Next Steps

After successful setup:
1. ✅ Test video call transcription
2. ✅ Verify SOAP notes dialog appears
3. ✅ Monitor transcription costs in database
4. ✅ Set up AWS CloudWatch alarms (optional)
5. ✅ Document the access key location for your team

## References

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Transcribe Medical Documentation](https://docs.aws.amazon.com/transcribe/latest/dg/transcribe-medical.html)
- [AWS Chime SDK Transcription](https://docs.aws.amazon.com/chime-sdk/latest/dg/meeting-transcription.html)
- [Supabase Edge Function Secrets](https://supabase.com/docs/guides/functions/secrets)
