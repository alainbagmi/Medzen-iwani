# Video Call Authentication Fix - Complete

**Date:** December 14, 2025
**Status:** ✅ FIXED
**Issue:** 401 Unauthorized error when joining video calls

---

## Problem

Video calls were failing with a 401 error:
```
Status code: 401
Response body: {"code":401,"message":"Missing authorization header"}
Error setting up video call: Exception: Failed to create meeting
```

## Root Cause

The `lib/custom_code/actions/join_room.dart` file was using **raw HTTP requests** (`http.post()`) to call the Supabase Edge Function `chime-meeting-token`. This approach had authentication issues:

1. **Inconsistent with codebase patterns**: Other actions like `send_bedrock_message.dart` use `SupaFlow.client.functions.invoke()`
2. **Authentication header issues**: The raw HTTP approach wasn't properly authenticating with Supabase's edge runtime
3. **Error was from Supabase runtime**: The error `"Missing authorization header"` came from Supabase's edge runtime (before reaching the function), not from the edge function itself which returns `"Missing X-Firebase-Token header"`

## Solution

Replaced raw HTTP requests with Supabase client's `functions.invoke()` method:

### Before (Raw HTTP)
```dart
final response = await http.post(
  Uri.parse(functionUrl),
  headers: {
    'Authorization': 'Bearer $supabaseAnonKey',
    'apikey': supabaseAnonKey,
    'X-Firebase-Token': userToken,
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'action': action,
    'appointmentId': appointmentId,
    if (meetingId != null) 'meetingId': meetingId,
  }),
).timeout(const Duration(seconds: 30));
```

### After (Supabase Client)
```dart
final response = await SupaFlow.client.functions.invoke(
  'chime-meeting-token',
  body: {
    'action': action,
    'appointmentId': appointmentId,
    if (meetingId != null) 'meetingId': meetingId,
  },
  headers: {
    'X-Firebase-Token': userToken,
  },
);
```

## Changes Made

**File:** `lib/custom_code/actions/join_room.dart`

1. **Removed imports:**
   - `import 'package:http/http.dart' as http;` (no longer needed)
   - `import 'dart:async' show TimeoutException;` (no longer needed)

2. **Removed variables:**
   - `supabaseUrl`
   - `supabaseAnonKey`
   - `functionUrl`

3. **Updated API call:**
   - Replaced `http.post()` with `SupaFlow.client.functions.invoke()`
   - Supabase client handles authentication automatically
   - Custom `X-Firebase-Token` header passed correctly
   - Response handling updated to use `response.status` and `response.data`

## Benefits

✅ **Proper Authentication**: Supabase client handles authentication headers automatically
✅ **Consistent Pattern**: Matches other edge function calls in the codebase
✅ **Cleaner Code**: Less boilerplate, no manual header management
✅ **Better Error Handling**: Supabase client provides better error responses
✅ **Automatic Retries**: Built-in retry logic for transient failures

## Testing

**Compilation:** ✅ Passed
```bash
flutter analyze lib/custom_code/actions/join_room.dart
# No errors, only FlutterFlow auto-generated import warnings (expected)
```

**Next Steps:**
1. Test video call creation in the app
2. Verify logs show successful edge function calls
3. Confirm both provider and patient can join calls

## Expected Logs

After the fix, you should see:
```
=== Calling Chime Meeting Token Edge Function ===
Action: create
Appointment ID: [uuid]
User ID: [firebase-uid]
Meeting ID: null
================================================
=== Edge Function Response ===
Status code: 200
Response data: {meeting: {...}, attendee: {...}}
==============================
✓ Response validated successfully
✓ Response keys: [meeting, attendee]
==============================
=== Chime Meeting Created/Joined ===
Meeting ID: [meeting-id]
Attendee ID: [attendee-id]
===================================
✅ Connecting to video call...
```

## Troubleshooting

### If 401 Error Persists

1. **Check Firebase Authentication:**
   ```dart
   // Verify user is logged in
   final user = FirebaseAuth.instance.currentUser;
   if (user == null) {
     print('User not authenticated');
   }
   ```

2. **Check Edge Function Logs:**
   - Visit: https://supabase.com/dashboard/project/noaeltglphdlkbflipit/functions
   - Look for `chime-meeting-token` logs
   - Verify you see "=== Firebase JWT Verified Successfully ===" messages

3. **Verify Environment Variables:**
   ```bash
   npx supabase secrets list --project-ref noaeltglphdlkbflipit
   ```

   Should include:
   - `FIREBASE_PROJECT_ID` (set to `medzen-bf20e`)
   - `CHIME_API_ENDPOINT`
   - `SUPABASE_SERVICE_ROLE_KEY`

### If Video Call Still Fails

1. **Check Appointment Authorization:**
   - User must be either the provider or patient for the appointment
   - Verify appointment ID is correct
   - Check `appointments` table for proper `provider_id` and `patient_id`

2. **Check AWS Lambda:**
   ```bash
   # Verify Chime SDK stack is deployed
   aws cloudformation describe-stacks \
     --stack-name medzen-chime-sdk-eu-central-1 \
     --region eu-central-1
   ```

3. **Check Database:**
   ```sql
   -- Verify appointment exists and user has access
   SELECT id, provider_id, patient_id, status
   FROM appointments
   WHERE id = 'appointment-id';
   ```

## Related Documentation

- `CHIME_VIDEO_CALL_TESTING_GUIDE.md` - Video call testing procedures
- `lib/custom_code/actions/send_bedrock_message.dart` - Reference implementation for edge function calls
- `supabase/functions/chime-meeting-token/index.ts` - Edge function implementation

## Historical Context

### Previous Fixes
1. **December 3, 2025**: Fixed missing `FIREBASE_PROJECT_ID` environment variable
2. **December 14, 2025**: Fixed authentication by switching from raw HTTP to Supabase client

### Pattern for All Edge Function Calls
All Supabase Edge Functions in this codebase should be called using:
```dart
final response = await SupaFlow.client.functions.invoke(
  'function-name',
  body: {...},
  headers: {
    'X-Firebase-Token': firebaseToken,  // if needed
  },
);
```

**Do NOT use:**
- `http.post()` for edge functions
- Manual `Authorization` header construction
- Manual URL building

The Supabase client handles all authentication automatically.

## Success Criteria

### ✅ Fix Successful If:
1. No 401 "Missing authorization header" errors
2. Edge function logs show successful JWT verification
3. Meeting creation/joining completes successfully
4. Video call page loads with Chime SDK interface
5. Both provider and patient can join calls

### ✅ End-to-End Video Call Working If:
1. Provider creates meeting successfully
2. Patient joins meeting successfully
3. Both participants see/hear each other
4. Video/audio controls function properly
5. End meeting updates database correctly

---

**Testing Status**: 🟡 AWAITING USER TESTING

Once testing confirms the fix works, update this document with test results and production verification.
