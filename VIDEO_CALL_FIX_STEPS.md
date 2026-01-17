# Video Call Fix - Step-by-Step Solution

**Problem:** Video calls won't start in current deployment

**Root Cause:** `CHIME_API_ENDPOINT` environment variable not configured in Supabase edge functions

**Solution:** 3 simple steps (5-10 minutes)

---

## Step 1: Retrieve AWS Chime API Endpoint

Run this command to get your API Gateway endpoint from CloudFormation:

```bash
# Get the Chime API Gateway endpoint from AWS
CHIME_API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name medzen-chime-sdk-multi-region-eu-central-1 \
  --region eu-central-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiGatewayEndpoint`].OutputValue' \
  --output text)

# Verify it worked (should print a URL like https://abc123.execute-api.eu-central-1.amazonaws.com/prod)
echo "API Endpoint: $CHIME_API_ENDPOINT"
```

**Expected output:**
```
API Endpoint: https://your-api-id.execute-api.eu-central-1.amazonaws.com/prod
```

**If it returns empty or error:**

```bash
# Check which CloudFormation stacks exist
aws cloudformation describe-stacks \
  --region eu-central-1 \
  --query 'Stacks[*].[StackName,StackStatus]' \
  --output table

# Or search for stacks with "chime" in the name
aws cloudformation describe-stacks \
  --region eu-central-1 \
  --query 'Stacks[*].StackName' \
  | grep -i chime
```

If no Chime stack exists, you may need to:
1. Deploy CloudFormation stack for Chime infrastructure
2. Or provide the API Gateway endpoint manually

---

## Step 2: Set Environment Variable in Supabase

Once you have the endpoint, configure it in Supabase:

```bash
# Link to your Supabase project (if not already linked)
npx supabase link --project-ref noaeltglphdlkbflipit

# Set the CHIME_API_ENDPOINT secret
npx supabase secrets set CHIME_API_ENDPOINT="https://your-api-id.execute-api.eu-central-1.amazonaws.com/prod"

# Verify it was set
npx supabase secrets list
```

**Expected output from `secrets list`:**
```
name                      | value
--------------------------|------------------
CHIME_API_ENDPOINT        | https://your-api-...
FIREBASE_PROJECT_ID       | medzen-bf20e
...
```

---

## Step 3: Redeploy Edge Function

The edge function needs to be redeployed to pick up the new environment variable:

```bash
# Redeploy the chime-meeting-token function
npx supabase functions deploy chime-meeting-token

# Watch for success message
# Expected: "✓ Function chime-meeting-token deployed successfully"
```

**That's it!** The fix is complete.

---

## Verify the Fix Works

### Test 1: Check Edge Function Can Access AWS

```bash
# Get a valid Firebase token from your app
# In Flutter console: window.localStorage.getItem('firebase:authUser:...')
# Or from Firebase CLI: firebase auth:export --format json | jq '.users[0]'

FIREBASE_TOKEN="your-valid-firebase-jwt"

# Test the edge function
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "x-firebase-token: $FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create",
    "appointmentId": "test-appt-123",
    "enableRecording": false,
    "enableTranscription": false
  }' | jq .
```

**Expected successful response:**
```json
{
  "meeting": {
    "MeetingId": "meeting-...",
    "MediaRegion": "eu-central-1",
    "MediaPlacement": {...}
  },
  "attendee": {
    "AttendeeId": "attendee-...",
    "JoinToken": "..."
  }
}
```

**If it fails with `CHIME_API_ENDPOINT not configured`:**
- Verify step 2 was done correctly
- Check `npx supabase secrets list` shows the endpoint
- Redeploy the function again: `npx supabase functions deploy chime-meeting-token`

### Test 2: Manual Video Call in App

1. Open https://4ea68cf7.medzen-dev.pages.dev
2. Login with valid Firebase credentials
3. Go to Appointments page
4. Select an appointment
5. **As Provider:** Click "Start Video Call"
6. Watch browser console (F12 → Console)

**Expected console logs:**
```
✅ FlutterChannel shim installed for Web (iframe)
📦 SDK script loaded from CDN
✅ Chime SDK ready - notifying Flutter
📊 Meeting created: meeting-...
✓ New video session created in database
✅ Meeting joined successfully via postMessage
```

**Video grid should appear with:**
- Local video (small box in corner)
- Remote video placeholder (waiting for other participant)
- Mute, video, leave buttons

---

## If Still Not Working

### Collect Debugging Information

```bash
# 1. Verify environment variable is set
npx supabase secrets list | grep CHIME

# 2. Check edge function was deployed
npx supabase functions list | grep chime-meeting

# 3. Test AWS Lambda directly (without going through Supabase)
curl https://your-api-id.execute-api.eu-central-1.amazonaws.com/prod/meetings \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"action":"create","appointmentId":"test-123"}'

# 4. Check browser console on deployed app
# Open DevTools (F12) and look for error messages
# Check Network tab for failed requests to /functions/v1/chime-meeting-token
```

### Common Issues

**Issue 1: API Endpoint is wrong format**
```
Error: "Lambda API returned 404"
Cause: URL doesn't end with /prod/meetings
Fix: Verify CHIME_API_ENDPOINT ends with /prod (not just /prod/meetings)
```

**Issue 2: AWS Credentials not configured**
```
Error: "Unable to assume role" or "UnauthorizedOperation"
Cause: AWS CLI doesn't have credentials
Fix: Run `aws configure` with valid AWS access keys
```

**Issue 3: CloudFormation stack doesn't exist**
```
Error: "Stack ... does not exist"
Cause: Chime infrastructure not deployed to eu-central-1
Fix: Need to deploy CloudFormation template or provide API endpoint manually
```

---

## Quick Reference

**Environment Variable Required:**
- **Name:** `CHIME_API_ENDPOINT`
- **Value:** API Gateway endpoint from CloudFormation (format: `https://xxx.execute-api.eu-central-1.amazonaws.com/prod`)
- **Location:** Supabase Secrets (environment variables)
- **Used By:** `chime-meeting-token` edge function

**CloudFormation Stack:**
- **Name:** `medzen-chime-sdk-multi-region-eu-central-1`
- **Region:** `eu-central-1` (Frankfurt)
- **Output Key:** `ApiGatewayEndpoint`

**After Fix:**
- ✅ Video calls will start
- ✅ Chime meetings will be created in AWS
- ✅ Users can join video calls
- ✅ Transcription can be enabled during calls

---

## Next: After Video Calls Are Fixed

Once video calls work:

1. **Test Transcription:**
   - Start a video call as provider
   - Click "Start Transcription" button
   - Speak clearly: "The patient has hypertension and diabetes"
   - Watch for live captions
   - Click "Stop Transcription"
   - Verify transcript saved

2. **Check Medical Vocabulary:**
   - All 10 languages should have medical terminology boost
   - English uses AWS Transcribe Medical
   - Other languages use Standard + medical vocabulary

3. **Verify AI Clinical Notes:**
   - After call ends, review AI-generated clinical note
   - Confirm medical entities are extracted
   - Sign and save note

4. **Run Full Test Suite:**
   - Follow instructions in `PRACTICAL_VIDEO_CALL_TRANSCRIPTION_TEST.md`
   - Execute all 6 test scenarios

---

## Summary

| Component | Status | Action |
|-----------|--------|--------|
| Flutter App | ✅ Deployed | None |
| Chime Widget | ✅ Implemented | None |
| Edge Functions | ✅ Deployed | Need config |
| AWS Lambda | ❓ Deployed | Get endpoint |
| **CHIME_API_ENDPOINT** | ❌ **NOT SET** | **Set this variable** |

**After setting the variable → video calls work → transcription ready → clinical notes ready**

Execute the 3 steps above and you'll have a fully functional medical video calling system with transcription, AI, and clinical notes! 🎉
