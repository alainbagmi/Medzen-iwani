# Video Call Transcription Fix Guide

## Problem Identified

The transcription auto-start feature was failing silently. The logs showed:

```
🎙️ Provider joined - preparing transcription auto-start...
```

But the timer callback **never executed** (missing "⏰ Auto-start timer fired" log).

**Result:** Transcription was never started, leading to "transcription wasn't started" errors when the call ended.

## Root Cause

The `Future.delayed` callback in `_handleMeetingJoined()` was not executing, likely due to:
- Widget lifecycle issues
- Silent exception in the callback chain
- Event loop scheduling problems on Android emulator

## Fix Applied

**File:** `lib/custom_code/widgets/chime_meeting_enhanced.dart:1031-1049`

**Changed:**
```dart
// OLD (silent failure)
Future.delayed(const Duration(seconds: 2), () {
  // callback code
});

// NEW (with error handling)
Future.delayed(const Duration(seconds: 2)).then((_) {
  // callback code
}).catchError((error) {
  debugPrint('❌ Auto-start timer error: $error');
});
```

This ensures any exceptions in the auto-start flow are logged.

## How to Test

### 1. Hot Restart the App

```bash
# If running in emulator
flutter run -d emulator-5554

# Or hot restart in your IDE
# Press 'R' in terminal or click Hot Restart button
```

**CRITICAL:** You must do a **full restart** (not just hot reload) because the widget initialization code changed.

### 2. Start a Video Call as Provider

1. Login as a provider user
2. Navigate to Appointments
3. Join a video call
4. **Watch the logs carefully**

### 3. Look for These Log Messages

**✅ SUCCESSFUL AUTO-START:**
```
🔍 Checking auto-start eligibility:
   widget.isProvider: true
   _isTranscriptionEnabled: false
   _isTranscriptionStarting: false
🎙️ Provider joined - preparing transcription auto-start...
⏰ Auto-start timer fired (2 seconds elapsed)     ← THIS IS CRITICAL
   mounted: true
   _isTranscriptionEnabled: false
   _isTranscriptionStarting: false
🎙️ Auto-starting transcription for provider...
🎙️ [TRANSCRIPTION] Starting start transcription
   Meeting ID: <uuid>
   Session ID: <uuid>
   Language: en-US
   Specialty: PRIMARYCARE
✅ [TRANSCRIPTION] Success!
   Message: Medical transcription started
✅ Transcription started successfully
```

**❌ FAILED AUTO-START (if still happening):**
```
🎙️ Provider joined - preparing transcription auto-start...
❌ Auto-start timer error: <error message>     ← NEW: Will now show error
```

### 4. Verify Transcription is Running

During the call, you should see:

- **In the UI:** Microphone icon shows "Transcription active" status
- **In logs:** Real-time caption segments being captured:
  ```
  📝 New caption segment received
     Speaker: Provider/Patient
     Text: [transcribed audio]
  ```

### 5. End the Call and Check Results

When the provider ends the call, look for:

```
📋 Found video session: <uuid>
   Transcript available: true          ← Should be TRUE now
   Transcription status: completed     ← Should be "completed" not "no_transcript"
   Transcript length: >0 chars         ← Should have content
   Duration: XX seconds
   Was enabled: true                   ← Should be TRUE now
```

## Manual Transcription Start (Fallback)

If auto-start still doesn't work, providers can **manually start transcription**:

### Option A: Tap Microphone Icon

1. During the video call
2. Tap the microphone icon in the controls
3. Select "Start Transcription" from menu (if available)

### Option B: Add a Manual Start Button

If the UI doesn't have a visible transcription button, you may need to:

1. Check the video call controls in `chime_meeting_enhanced.dart:7010`
2. Ensure the transcription button is visible:
   ```dart
   // Provider can manually start transcription
   if (widget.isProvider && !_isTranscriptionEnabled) {
     InkWell(
       onTap: _startTranscription,
       child: Icon(Icons.mic, color: Colors.white),
     ),
   }
   ```

## Troubleshooting

### Issue: Timer still not firing

**Check:**
1. Is the widget mounted when the timer fires?
   ```
   debugPrint('   mounted: $mounted');  // Should be true
   ```

2. Is there an error in the catchError?
   ```
   ❌ Auto-start timer error: <check for this log>
   ```

3. Try increasing the delay:
   ```dart
   // In chime_meeting_enhanced.dart:1032
   Future.delayed(const Duration(seconds: 5)).then((_) {  // Increased to 5 seconds
   ```

### Issue: "Session not found" error

This means the `video_call_sessions` database record doesn't exist yet. The code already has retry logic (3 attempts with 1-second delays), but you may need to:

1. Check database RLS policies for `video_call_sessions`
2. Verify the session is created in `chime-meeting-token` edge function
3. Add more delay before starting transcription:
   ```dart
   Future.delayed(const Duration(seconds: 4)).then((_) {
   ```

### Issue: "Cannot start transcription - video call is not active"

The edge function checks `sessionData?.status !== 'active'`. Verify:

1. The session status is set to `'active'` when the meeting starts
2. Check the `chime-meeting-token` edge function updates status correctly
3. Query the database:
   ```sql
   SELECT id, status, live_transcription_enabled
   FROM video_call_sessions
   WHERE appointment_id = '<your-appointment-id>'
   ORDER BY created_at DESC
   LIMIT 1;
   ```

### Issue: AWS credentials not configured

If you see:
```
AWS credentials not configured
```

Then the Supabase edge function environment variables are missing:

```bash
# Check edge function secrets
npx supabase secrets list

# Should have:
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_REGION (default: eu-central-1)
```

Set them if missing:
```bash
npx supabase secrets set AWS_ACCESS_KEY_ID=<your-key>
npx supabase secrets set AWS_SECRET_ACCESS_KEY=<your-secret>
```

## Expected Behavior After Fix

1. **Auto-start** happens 2 seconds after provider joins
2. **Transcript** is captured in real-time during the call
3. **Clinical notes** are generated automatically when call ends
4. **No errors** about "transcription wasn't started"

## Testing Checklist

- [ ] Hot restart the app (full restart, not hot reload)
- [ ] Login as provider
- [ ] Start a video call
- [ ] Watch logs for "⏰ Auto-start timer fired"
- [ ] Verify "✅ Transcription started successfully"
- [ ] Speak during the call (generate audio for transcription)
- [ ] End the call
- [ ] Check `Transcript available: true` in logs
- [ ] Verify clinical notes dialog shows transcript data

## Next Steps

1. **Test the fix** with a hot restart
2. **Monitor the logs** for the critical "⏰ Auto-start timer fired" message
3. **Report back** with the results:
   - Did auto-start work?
   - Any new errors in the logs?
   - Was transcript captured successfully?

If the auto-start still fails after this fix, we may need to:
- Add more diagnostic logging
- Increase the delay timer
- Implement a manual start button as the primary method
- Investigate widget lifecycle issues on Android emulator
