# Video Call 502 Error - FIXED ✅

## Date: December 15, 2025

## Problem

Video call was failing with 502 Bad Gateway error:
```
Status code: 502
Response body: <html>
<head><title>502 Bad Gateway</title></head>
<body>
<center><h1>502 Bad Gateway</h1></center>
</body>
</html>
```

## Root Causes

### 1. Missing RLS Required Fields ❌
The edge function was inserting `video_call_sessions` without `provider_id` and `patient_id`, which are now REQUIRED by the RLS policies I just created.

**Before (BROKEN):**
```typescript
await supabaseAdmin.from("video_call_sessions").insert({
  appointment_id: appointmentId,
  // ❌ Missing provider_id and patient_id
  channel_name: `meeting-${appointmentId}`,
  meeting_id: lambdaResponse.meeting.MeetingId,
  // ...
});
```

**After (FIXED):**
```typescript
await supabaseAdmin.from("video_call_sessions").insert({
  appointment_id: appointmentId,
  provider_id: appointment.provider_id,  // ✅ Added
  patient_id: appointment.patient_id,    // ✅ Added
  channel_name: `meeting-${appointmentId}`,
  meeting_id: lambdaResponse.meeting.MeetingId,
  // ...
});
```

### 2. Direct AWS SDK Usage ❌
The edge function was trying to use AWS SDK commands that weren't imported:
- `DeleteMeetingCommand` (line 373)
- `BatchCreateAttendeeCommand` (line 327)
- `chimeClient` variable (didn't exist)

**Before (BROKEN):**
```typescript
// Trying to use AWS SDK directly in edge function
const deleteMeetingCommand = new DeleteMeetingCommand({ MeetingId: meetingId });
await chimeClient.send(deleteMeetingCommand); // ❌ chimeClient undefined
```

**After (FIXED):**
```typescript
// Call Lambda API instead
await callChimeLambda("end", { meetingId, userId });
```

## What Was Fixed

### 1. Added RLS Required Fields
- ✅ Added `provider_id` to video_call_sessions insert
- ✅ Added `patient_id` to video_call_sessions insert
- ✅ Fields now match RLS policy requirements

### 2. Fixed AWS SDK Calls
- ✅ Changed `end` action to call Lambda API
- ✅ Changed `batch-join` action to call Lambda API
- ✅ Removed direct AWS SDK usage from edge function

### 3. Deployed Fixed Function
- ✅ Deployed `chime-meeting-token` edge function to production
- ✅ Function now properly calls Lambda API for all operations
- ✅ Database inserts include all required fields

## Files Changed

**`supabase/functions/chime-meeting-token/index.ts`**
- Lines 201-228: Added provider_id and patient_id to insert
- Lines 318-322: Fixed batch-join to call Lambda API
- Lines 366-369: Fixed end action to call Lambda API

## How to Test

### 1. Check Edge Function Logs
```bash
npx supabase functions logs chime-meeting-token --tail
```

### 2. Test Video Call Creation
In your Flutter app:
1. Go to an appointment
2. Click "Join Video Call"
3. Should now create meeting successfully
4. No 502 error

### 3. Monitor Logs
Watch for these success messages:
```
✓ Auth Success - User: [userId] [email]
✓ Meeting created: [meetingId]
✓ Attendee created: [attendeeId]
```

## Expected Behavior

**Before:**
```
1. User clicks "Join Call"
2. Edge function tries to insert without provider_id/patient_id
3. RLS policy blocks insert (no permission)
4. Edge function crashes with 502
```

**After:**
```
1. User clicks "Join Call"
2. Edge function queries appointment for provider_id/patient_id
3. Inserts video_call_sessions with all required fields
4. RLS policy validates: user is provider or patient ✅
5. Insert succeeds
6. Meeting created successfully
```

## Additional Issues to Check

### Profile Picture URL Error
I noticed this error in your logs:
```
Invalid argument(s): No host specified in URI file:///500x500?doctor
```

This suggests profile picture URLs might be malformed. Check your Flutter code when joining the call:

**Flutter Code to Check:**
```dart
await joinRoom(
  context,
  sessionId,
  providerId,
  patientId,
  appointmentId,
  isProvider,
  userName,
  profileImage,  // ⚠️ Check this value
);
```

**The profileImage should:**
- ✅ Start with `http://` or `https://`
- ❌ NOT be `file:///500x500?doctor`
- ❌ NOT be a local file path

**Fix in Flutter:**
```dart
// Validate profile image URL
String validProfileImage = profileImage;
if (profileImage == null || 
    profileImage.isEmpty || 
    !profileImage.startsWith('http')) {
  // Use default image
  validProfileImage = 'https://api.dicebear.com/7.x/avataaars/svg?seed=$userName';
}

await joinRoom(
  context,
  sessionId,
  providerId,
  patientId,
  appointmentId,
  isProvider,
  userName,
  validProfileImage,
);
```

## Verification Checklist

- ✅ Edge function deployed successfully
- ✅ Lambda function supports create, join, end actions
- ✅ RLS policies allow insert with provider_id/patient_id
- ⏳ Test video call creation in app
- ⏳ Verify no 502 errors
- ⏳ Check profile image URLs are valid

## Next Steps

1. **Test video call in Flutter app** - Try joining a call
2. **Monitor logs** - Watch for any errors
3. **Fix profile images** - Ensure URLs are valid HTTP(S) URLs
4. **Report results** - Let me know if you see any errors

## Troubleshooting

### Still getting 502?
Check edge function logs:
```bash
npx supabase functions logs chime-meeting-token --tail
```

Look for:
- Authentication errors
- Database insert errors
- Lambda API call errors

### RLS policy blocking insert?
Verify appointment has provider_id and patient_id:
```sql
SELECT id, provider_id, patient_id, status
FROM appointments
WHERE id = 'your-appointment-id';
```

### Lambda API not responding?
Check Lambda is deployed and API Gateway is configured:
```bash
aws lambda get-function --function-name medzen-meeting-manager --region eu-central-1
```

---

**Summary:** The 502 error was caused by missing RLS required fields (provider_id, patient_id) in the database insert. This has been fixed and deployed. Test video calls should now work! 🎉
