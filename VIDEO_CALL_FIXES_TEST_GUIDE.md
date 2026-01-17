# Video Call Fixes - Test Guide

## Date: 2026-01-07

This guide covers testing the two critical fixes for the video calling system:
1. Web messaging functionality
2. Call end notification for all participants

---

## ✅ Deployment Status

- **Edge Function**: `chime-meeting-token` deployed successfully
- **Widget**: `chime_meeting_enhanced.dart` updated with platform-specific messaging
- **Changes**: Live and ready for testing

---

## Fix #1: Web Messaging Test

### Problem Fixed
Web users could not see chat messages during video calls. Messages only worked on mobile.

### Root Cause
The `_loadMessages()` function used `evaluateJavascript()` which only works with InAppWebView on mobile. Web requires `postMessage()` for iframe communication.

### Test Steps

#### Test 1A: Web Provider → Web Patient
1. **Open provider app on web browser (Chrome/Firefox)**
   - Log in as a provider
   - Navigate to appointments
   - Start a video call with a patient

2. **Open patient app on web browser (different browser/incognito)**
   - Log in as the patient
   - Join the video call when notified

3. **Test messaging**:
   - Provider sends message: "Hello from provider web"
   - Patient should see message appear in chat panel
   - Patient sends message: "Hello from patient web"
   - Provider should see message appear in chat panel

4. **Expected Result**: ✅ Both users see all messages in real-time

#### Test 1B: Web → Mobile Cross-Platform
1. **Open provider app on web browser**
2. **Open patient app on mobile (Android/iOS emulator or device)**
3. **Test messaging both directions**:
   - Web provider sends message
   - Mobile patient should see it
   - Mobile patient sends message
   - Web provider should see it

4. **Expected Result**: ✅ Messages work bidirectionally between web and mobile

#### Test 1C: File Attachments on Web
1. **From web browser**:
   - Click file attachment icon in chat
   - Select a small image file (< 5MB)
   - Send the file

2. **Expected Result**: ✅ File uploads and appears as attachment in chat for both users

### Debug Points
If messaging fails, check browser console (F12):
- Look for `📨 Received RECEIVE_MESSAGE from Flutter` logs
- Check for `postMessage` errors
- Verify `receiveMessage` function exists in iframe window object

---

## Fix #2: Call End Notification Test

### Problem Fixed
When provider ended video call on web, only provider's UI closed. Patient remained in the call.

### Root Cause
Edge function updated database but didn't send realtime notifications to other participants.

### Test Steps

#### Test 2A: Provider Ends Call (Web)
1. **Start video call**:
   - Provider (web) starts call
   - Patient (web or mobile) joins

2. **Provider ends call**:
   - Provider clicks "End Call" button
   - Provider's UI should close immediately

3. **Verify patient side**:
   - Patient should see call UI close automatically within 1-2 seconds
   - Patient should not remain stuck in the call

4. **Expected Result**: ✅ Both users exit the call when provider ends it

#### Test 2B: Provider Ends Call (Mobile)
1. **Start video call**:
   - Provider (mobile) starts call
   - Patient (web) joins

2. **Provider ends call**:
   - Provider taps "End Call" button
   - Provider's UI should close

3. **Verify patient side**:
   - Patient (on web) should see call UI close automatically

4. **Expected Result**: ✅ Both users exit the call

#### Test 2C: Check Notification in Database
After ending a call, verify notification was created:

```bash
# Connect to Supabase
npx supabase db reset --linked

# Or use psql to query
psql "postgresql://postgres.noaeltglphdlkbflipit:@aws-0-eu-central-1.pooler.supabase.com:6543/postgres"

# Query recent notifications
SELECT
  recipient_id,
  type,
  title,
  body,
  payload,
  created_at
FROM call_notifications
WHERE type = 'call_ended'
ORDER BY created_at DESC
LIMIT 5;
```

Expected output:
```
recipient_id                          | type        | title                 | body
--------------------------------------|-------------|-----------------------|-----------------------------------
<patient-user-id>                     | call_ended  | 📞 Video Call Ended   | The provider has ended the video call.
```

### Debug Points
If call doesn't end for patient:

1. **Check browser console** (patient side):
   - Look for `🔔 Call notification received` logs
   - Look for `📞 Call ended notification received - closing call UI` logs

2. **Check edge function logs**:
```bash
npx supabase functions logs chime-meeting-token --tail
```
Look for:
- `✅ Call end notification sent to patient <user-id>`
- Or error: `❌ Failed to send call end notification`

3. **Verify notification subscription**:
   - Patient console should show: `✅ Subscribed to call notifications`

---

## Platform-Specific Code Changes

### Web (uses postMessage)
```dart
if (kIsWeb) {
  final messageData = {
    'type': 'RECEIVE_MESSAGE',
    'data': { /* message data */ }
  };
  _webIframe!.contentWindow!.postMessage(jsonEncode(messageData), '*');
}
```

### Mobile (uses evaluateJavascript)
```dart
else {
  await _webViewController?.evaluateJavascript(
    source: 'receiveMessage({...});'
  );
}
```

---

## Success Criteria

✅ **All tests must pass**:
- [ ] Web-to-web messaging works
- [ ] Web-to-mobile messaging works
- [ ] Mobile-to-web messaging works
- [ ] File attachments work on web
- [ ] Provider ending call closes patient's UI (web provider)
- [ ] Provider ending call closes patient's UI (mobile provider)
- [ ] Notification records created in database

---

## Rollback Plan

If tests fail and issues persist:

1. **Revert widget changes**:
```bash
git checkout HEAD~1 lib/custom_code/widgets/chime_meeting_enhanced.dart
```

2. **Redeploy edge function**:
```bash
npx supabase functions deploy chime-meeting-token
```

3. **Report specific errors** found in console/logs

---

## Next Steps After Testing

Once all tests pass:
1. Update `VIDEO_CALL_IMPLEMENTATION_SUMMARY.md` with fix details
2. Commit changes with message: `fix: Web messaging and call end notifications`
3. Monitor production logs for any edge cases
4. Consider adding automated tests for these scenarios

---

## Key Files Modified

1. `lib/custom_code/widgets/chime_meeting_enhanced.dart`:
   - Added `_notificationChannel` variable (line 119)
   - Modified `_loadMessages()` for platform-specific messaging (lines 1653-1703)
   - Added iframe message handler (lines 2675-2684)
   - Created `_subscribeToNotifications()` method (lines 1871-1914)
   - Added subscription initialization (lines 210, 349)
   - Added cleanup in dispose (lines 464-467)

2. `supabase/functions/chime-meeting-token/index.ts`:
   - Added notification insertion when call ends (lines 703-725)

---

## Support

If you encounter issues:
1. Check browser console for JavaScript errors
2. Check Supabase function logs: `npx supabase functions logs chime-meeting-token --tail`
3. Verify database notifications: Query `call_notifications` table
4. Ensure realtime is enabled on `call_notifications` table
