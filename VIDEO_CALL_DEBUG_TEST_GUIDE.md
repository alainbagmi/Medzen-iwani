# Video Call Debug Testing Guide

**Date:** December 3, 2025
**Version:** Edge Function v36 (ASN.1 Parser Fix - DEPLOYED)
**Status:** ✅ READY FOR PRODUCTION TESTING

## Overview

This guide explains how to test the video call feature with the newly deployed debug logging (version 35) to diagnose the X-Firebase-Token header issue.

## What Was Done

### Deployment Complete ✅
- **Deployed:** Edge Function version 35 on 2025-12-03 16:54:31
- **Status:** ACTIVE and responding correctly
- **Changes:** Added comprehensive header logging to diagnose missing X-Firebase-Token header

### Debug Logging Added
The Edge Function now logs ALL incoming request headers to help identify if the X-Firebase-Token header is being received.

**Log output format:**
```
=== All Request Headers ===
authorization: Bearer eyJhbGci...
content-type: application/json
x-firebase-token: eyJhbGci... (if present)
===========================
```

## Testing Steps

### 1. Prerequisites
- Flutter app running on iOS device/simulator or Android device/emulator
- User logged in with valid Firebase account
- At least one appointment scheduled with video call enabled

### 2. Initiate Video Call
1. Open the MedZen app
2. Navigate to an appointment with scheduled video call
3. Click the **"Join Video Call"** button (or equivalent)
4. **Allow camera and microphone permissions** if prompted
5. Observe the app's response:
   - Does it show loading indicator?
   - Does it show any error messages?
   - Does it navigate to video call page?
   - Does video call succeed or fail?

### 3. Check Edge Function Logs

**Important:** You MUST check logs immediately after testing while the request is recent.

#### Access Logs:
🔗 **Direct link:** https://supabase.com/dashboard/project/noaeltglphdlkbflipit/functions/chime-meeting-token/logs

#### Alternative method:
1. Go to https://supabase.com/dashboard
2. Select project: `noaeltglphdlkbflipit`
3. Navigate to: **Edge Functions** → **chime-meeting-token** → **Logs** tab
4. Click **Refresh** to see latest logs

### 4. Analyze Log Output

Look for these specific sections in the logs:

#### Section 1: Request Headers (NEW - Version 35)
```
=== All Request Headers ===
authorization: Bearer eyJhbGci...
content-type: application/json
x-client-info: ...
apikey: ...
x-firebase-token: eyJhbGci... ← CHECK IF THIS LINE EXISTS
===========================
X-Firebase-Token header specifically: eyJhbGci... (or null)
```

**CRITICAL QUESTIONS:**
- ❓ Do you see the line "=== All Request Headers ==="?
- ❓ Is there a line starting with "x-firebase-token:"?
- ❓ What does "X-Firebase-Token header specifically:" show? (value or null)

#### Section 2: Token Debug Info (if header present)
```
=== Authentication Debug ===
Token received (first 50 chars): eyJhbGciOiJSUzI1NiIsImtpZCI...
Token length: 1234
Supabase URL: https://noaeltglphdlkbflipit.supabase.co
Anon Key available: true
```

#### Section 3: JWT Verification Steps (if header present)
```
=== JWT Verification START ===
Token length: 1234
[STEP 1] Splitting token into parts...
✓ Token has 3 parts
[STEP 2] Decoding JWT header...
✓ Header decoded: {"alg":"RS256","kid":"...","typ":"JWT"}
[STEP 3] Verifying algorithm...
✓ Algorithm is RS256
...
[STEP 12] Verifying signature...
✓ Signature valid
=== Firebase JWT Verified Successfully ===
```

#### Section 4: Errors (if any)
```
=== Auth Error Details ===
Error: Invalid or expired token
Error type: Error
Error message: Token expired
========================
```

### 5. Collect Information

Please provide the following information:

#### A. App Behavior
- [ ] Did permissions dialog appear?
- [ ] Did loading indicator show?
- [ ] What error message (if any) appeared in the app?
- [ ] Did the app navigate to video call page?
- [ ] Did video/audio streams work?

#### B. Log Analysis
**Copy the COMPLETE log output** from Supabase dashboard, especially:
1. The "=== All Request Headers ===" section
2. The "X-Firebase-Token header specifically:" line
3. Any error messages

#### C. Screenshots (Optional but helpful)
- Screenshot of app error message (if any)
- Screenshot of Supabase logs showing headers

## Expected Outcomes

### Scenario 1: Header IS Present ✅
**Log shows:**
```
x-firebase-token: eyJhbGci...
X-Firebase-Token header specifically: eyJhbGci...
```

**Meaning:**
- The two-header pattern is working correctly
- Client is sending the header properly
- JWT verification should proceed

**Next step:** Analyze JWT verification logs to see if token is valid

---

### Scenario 2: Header is MISSING ❌
**Log shows:**
```
X-Firebase-Token header specifically: null
```
**AND the list of headers does NOT include x-firebase-token**

**Meaning:**
- Flutter client is NOT sending the X-Firebase-Token header
- Problem is client-side in `join_room.dart`
- Need to debug Flutter HTTP client

**Next step:** Add debug logging to Flutter client to verify header is being set

---

### Scenario 3: Header Name Mismatch ⚠️
**Log shows:**
```
X-FIREBASE-TOKEN: eyJhbGci...  (wrong case)
or
firebase-token: eyJhbGci...  (missing X- prefix)
```

**Meaning:**
- Header is being sent but with wrong case/name
- HTTP headers are case-insensitive but header name must match

**Next step:** Adjust header name in client or server to match

---

### Scenario 4: Different Error 🔍
**Log shows unexpected error or behavior**

**Next step:** Analyze specific error and create targeted fix

## Common Issues & Quick Fixes

### Issue: "Missing X-Firebase-Token header" Error
**Cause:** Header not being received by Edge Function
**Check:** Look for x-firebase-token in header list
**Fix:** Debug Flutter client to ensure header is being sent

### Issue: "Invalid or expired token" Error
**Cause:** Token verification failed
**Check:** JWT verification logs (STEP 1-12)
**Fix:** Depends on which step failed (expiration, signature, issuer, etc.)

### Issue: "User not found in database" Error
**Cause:** Firebase UID doesn't match any Supabase user
**Check:** Verify user exists in Supabase `users` table
**Fix:** Check user creation flow (`onUserCreated` Firebase function)

### Issue: "Not authorized to create meeting for this appointment" Error
**Cause:** User ID doesn't match provider_id or patient_id for appointment
**Check:** Verify appointment exists and user has correct role
**Fix:** Check appointment data and user permissions

## Technical Details

### Two-Header Authentication Pattern
```
Request Headers:
├─ Authorization: Bearer <supabase_anon_key>  ← Satisfies Supabase middleware
└─ X-Firebase-Token: <firebase_jwt>           ← Our custom verification
```

**Why this pattern?**
- Supabase Edge Functions automatically validate Authorization header
- Expected format: `Bearer <supabase_jwt>`
- Firebase tokens are rejected before custom code runs
- Solution: Send Supabase key in Authorization, Firebase token in custom header

### Firebase JWT Token Format
```
Header:    {"alg":"RS256","kid":"abc123","typ":"JWT"}
Payload:   {"user_id":"xyz","aud":"medzen-bf20e","iss":"https://securetoken.google.com/medzen-bf20e","exp":1234567890}
Signature: <RSA-SHA256 signature>
```

### Edge Function Versions
- **Version 34:** Initial two-header implementation (deployed earlier)
- **Version 35:** Added comprehensive debug logging (deployed 2025-12-03 16:54:31)
- **Version 36:** ASN.1 parser fix for X.509 certificate handling (deployed 2025-12-03 18:08:45) ← CURRENT

## Support Information

### Dashboard Links
- **Edge Functions:** https://supabase.com/dashboard/project/noaeltglphdlkbflipit/functions
- **Logs:** https://supabase.com/dashboard/project/noaeltglphdlkbflipit/functions/chime-meeting-token/logs
- **Database:** https://supabase.com/dashboard/project/noaeltglphdlkbflipit/editor

### Environment Details
- **Firebase Project:** medzen-bf20e
- **Supabase Project:** noaeltglphdlkbflipit
- **AWS Region:** eu-west-1 (primary), af-south-1 (secondary)
- **Chime SDK:** Enabled for video calls

### Files Modified
1. ✅ `supabase/functions/chime-meeting-token/index.ts` (lines 24-32: debug logging)
2. ✅ `lib/custom_code/actions/join_room.dart` (lines 208-228: two-header pattern)
3. 📖 `VIDEO_CALL_JWT_FIX_COMPLETE.md` (documentation)

## After Testing

Once you've completed testing and collected the log output, provide:

1. **Log Output:** Complete header section from Supabase logs
2. **App Behavior:** What happened in the app (error message, navigation, etc.)
3. **Screenshots:** Any relevant screenshots from app or dashboard

This information will allow us to:
- Determine if X-Firebase-Token header is being received
- Identify the exact point of failure in the authentication flow
- Implement the appropriate fix based on root cause analysis

---

**Ready to test!** 🚀

Follow the steps above and report back with the log output and app behavior.
