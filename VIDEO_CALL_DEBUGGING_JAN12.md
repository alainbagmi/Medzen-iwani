# Video Call Debugging Guide - January 12, 2026

**Status:** Video calls won't start in deployment `https://4ea68cf7.medzen-dev.pages.dev`

**Working Deployment Reference:** `https://b87a3119.medzen-dev.pages.dev` (has functional video calls)

---

## Root Cause Analysis

The video call flow requires three critical components:

```
1. User clicks "Start Call" in Flutter web app
   ↓
2. join_room() action called
   ↓
3. Calls chime-meeting-token edge function
   ↓
4. Edge function calls AWS Lambda to create Chime meeting
   ↓ (BLOCKED HERE)
   ❌ CHIME_API_ENDPOINT not configured
```

### Critical Issue: CHIME_API_ENDPOINT Not Configured

**Location:** `supabase/functions/chime-meeting-token/index.ts` lines 84-88

```typescript
const callChimeLambda = async (action: string, params: any) => {
  const chimeApiEndpoint = Deno.env.get("CHIME_API_ENDPOINT");

  if (!chimeApiEndpoint) {
    throw new Error("CHIME_API_ENDPOINT not configured");  // ← THIS ERROR OCCURS
  }
  // ...
}
```

**The Problem:** When user initiates a video call:
1. `join_room()` action calls `chime-meeting-token` edge function
2. Edge function tries to create meeting via AWS Lambda
3. Fails immediately with: `"CHIME_API_ENDPOINT not configured"`
4. No video call is created
5. User sees blank screen or error

---

## Step 1: Verify Edge Function Errors

### Check Supabase Logs (If Available)

```bash
# View function invocation logs (if local Supabase running)
npx supabase functions logs chime-meeting-token --tail

# Expected error message:
# ❌ Error: CHIME_API_ENDPOINT not configured
```

### Alternative: Test via Browser Console

1. Open `https://4ea68cf7.medzen-dev.pages.dev`
2. Open DevTools (F12)
3. Go to Console tab
4. Try to start a video call
5. Look for error: `401` or `500` response from edge function

**Expected error in Network tab:**
- Request to: `https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token`
- Status: `500` (Server Error)
- Response: `{"error":"CHIME_API_ENDPOINT not configured"}`

---

## Step 2: Identify Missing Configuration

### What is CHIME_API_ENDPOINT?

This should be the AWS API Gateway endpoint for your Lambda functions that handle Chime meeting creation.

**Format:** `https://xxxxxxxxxx.execute-api.eu-central-1.amazonaws.com/prod/meetings`

### Where Should It Be Configured?

**Option A: Supabase Secrets** (Recommended for edge functions)
```bash
# Set the environment variable for all edge functions
npx supabase secrets set CHIME_API_ENDPOINT="https://your-api-gateway-endpoint/prod"

# Verify it's set
npx supabase secrets list
```

**Option B: Deploy Configuration**
```bash
# Or configure via Supabase dashboard:
# 1. Go to Supabase dashboard
# 2. Project Settings → Edge Functions
# 3. Add environment variable: CHIME_API_ENDPOINT
# 4. Value: Your AWS API Gateway URL
```

---

## Step 3: Determine Correct AWS Lambda Endpoint

### Check AWS API Gateway Setup

Run this command to find your Lambda function endpoint:

```bash
# List API Gateway endpoints in eu-central-1
aws apigateway get-rest-apis \
  --region eu-central-1 \
  --query 'items[*].[name,id]' \
  --output table
```

**Expected output:**
```
------------------------------
|  RestApi Name | RestApi ID |
|-------|--------|--------|
| chime-meetings | xxxxxxxxxx |
------------------------------
```

Then get the endpoint:

```bash
# Get the actual endpoint URL
aws apigateway get-stage \
  --rest-api-id xxxxxxxxxx \
  --stage-name prod \
  --region eu-central-1 \
  --query 'invokeUrl' \
  --output text
```

**Result should look like:**
```
https://abc123def.execute-api.eu-central-1.amazonaws.com/prod
```

### Alternative: Check AWS CloudFormation Stack

If you deployed via CloudFormation:

```bash
# List stacks in eu-central-1
aws cloudformation describe-stacks \
  --region eu-central-1 \
  --query 'Stacks[*].[StackName,StackStatus]' \
  --output table

# Get stack outputs (includes API Gateway URL)
aws cloudformation describe-stacks \
  --region eu-central-1 \
  --stack-name chime-video-call-stack \
  --query 'Stacks[0].Outputs'
```

---

## Step 4: Compare with Working Deployment

The working deployment at `https://b87a3119.medzen-dev.pages.dev` successfully creates video calls, which means:

✅ CHIME_API_ENDPOINT IS configured there
✅ AWS Lambda is reachable
✅ Database tables are working

### What's Different?

Check which Cloudflare deployment is which:

```bash
# Find which branch/commit each deployment is from
wrangler deployments list medzen-dev
```

The older working deployment likely has the environment variable configured. The newer deployment lost this configuration.

---

## Step 5: Fix the Issue

### Option 1: Quick Fix - Set Missing Environment Variable

```bash
# 1. Get your AWS Lambda endpoint (from Step 3 above)
export CHIME_API_ENDPOINT="https://your-api-endpoint/prod"

# 2. Set it in Supabase
npx supabase secrets set CHIME_API_ENDPOINT=$CHIME_API_ENDPOINT

# 3. Redeploy the edge function to apply new secrets
npx supabase functions deploy chime-meeting-token

# 4. Test immediately
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "x-firebase-token: test-token-here" \
  -H "Content-Type: application/json" \
  -d '{"action":"create","appointmentId":"test-123"}'
```

### Option 2: Complete Redeployment

If environment variables got lost:

```bash
# 1. List current environment variables
npx supabase secrets list

# 2. Compare with working deployment (ask user for their setup)

# 3. Set all missing variables:
npx supabase secrets set CHIME_API_ENDPOINT="..."
npx supabase secrets set FIREBASE_PROJECT_ID="medzen-bf20e"
npx supabase secrets set AWS_REGION="eu-central-1"

# 4. Redeploy all edge functions
npx supabase functions deploy chime-meeting-token
npx supabase functions deploy chime-messaging
npx supabase functions deploy chime-recording-callback
npx supabase functions deploy start-medical-transcription

# 5. Test video call again
```

---

## Step 6: Verify Fix

### Test Edge Function Directly

```bash
# Get a valid Firebase token from your user
firebase auth:export --format json | jq '.users[0].customClaims'

# Or from Flutter app console:
# window.localStorage.getItem('firebase:authUser:...')

# Test the edge function
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "x-firebase-token: YOUR_VALID_FIREBASE_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "create",
    "appointmentId": "test-appt-123",
    "enableRecording": false,
    "enableTranscription": false
  }'
```

**Expected successful response:**
```json
{
  "meeting": {
    "MeetingId": "...",
    "MediaRegion": "eu-central-1",
    "MediaPlacement": {...}
  },
  "attendee": {
    "AttendeeId": "...",
    "JoinToken": "..."
  }
}
```

**If still failing:**
```json
{
  "error": "CHIME_API_ENDPOINT not configured"  // ← Variable not set
}
```

Or:

```json
{
  "error": "Invalid or expired token"  // ← Firebase token issue
}
```

---

## Step 7: Test End-to-End in App

After fixing environment variable:

1. **Login:** Use valid Firebase credentials
2. **Navigate:** Go to Appointments page
3. **Create/View Appointment:** Select appointment between provider and patient
4. **Start Call:**
   - As provider: Click "Start Video Call"
   - Watch for Chime SDK to load
   - Video grid should appear
   - Remote participant join option should appear

### Watch Browser Console

As you start the call, you should see:

```
✅ FlutterChannel shim installed for Web (iframe)
📦 SDK script loaded from CDN
📊 Status: SDK ready, joining meeting...
✅ Chime SDK ready - notifying Flutter
```

If you see errors about `CHIME_API_ENDPOINT`, the fix didn't work.

---

## Debugging Checklist

- [ ] Verified CHIME_API_ENDPOINT is set in Supabase secrets
- [ ] Confirmed AWS Lambda endpoint is reachable (test via curl)
- [ ] Redeployed chime-meeting-token edge function
- [ ] Cleared browser cache (Ctrl+Shift+Delete)
- [ ] Logged in with fresh Firebase token
- [ ] Can see Chime SDK loading in browser console
- [ ] Can see successful edge function call in Network tab
- [ ] Video grid appears when joining meeting
- [ ] Can see remote participant options

---

## If Still Not Working

### Collect Diagnostic Information

```bash
# 1. Get current edge function configuration
npx supabase functions info chime-meeting-token

# 2. Check environment variables are set
npx supabase secrets list

# 3. Get function logs
npx supabase functions logs chime-meeting-token

# 4. Test AWS Lambda directly
curl https://your-api-gateway-endpoint/meetings \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"action":"create","appointmentId":"test-123"}'

# 5. Verify Supabase connection from Flutter
# In browser console:
fetch('https://noaeltglphdlkbflipit.supabase.co/rest/v1/users?limit=1', {
  headers: {
    'Authorization': 'Bearer ' + (await getFirebaseToken()),
    'apikey': 'your-supabase-anon-key'
  }
}).then(r => r.json()).then(console.log)
```

### Compare with Working Deployment

Since `https://b87a3119.medzen-dev.pages.dev` works:

1. Open DevTools on working deployment
2. Start a video call
3. Check Console tab - what logs appear?
4. Check Network tab - what requests are made?
5. Compare with broken deployment

---

## Summary

**The Issue:**
- `CHIME_API_ENDPOINT` environment variable not configured in Supabase edge functions

**The Fix:**
1. Get AWS Lambda endpoint URL
2. Set `CHIME_API_ENDPOINT` environment variable in Supabase
3. Redeploy `chime-meeting-token` edge function
4. Test video call

**Expected Outcome:**
- Video calls will start successfully
- Chime meeting tokens will be created
- Users can see video grid and join meetings

---

## Next: After Fix Verification

Once video calls are working:
1. Run Test 1: Basic Transcription (from `TEST_1_EXECUTION_GUIDE.md`)
2. Verify medical vocabulary is being used
3. Check that real-time captions appear
4. Confirm transcripts are saved
