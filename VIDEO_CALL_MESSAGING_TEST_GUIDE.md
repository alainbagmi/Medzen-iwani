# Video Call In-Call Messaging Test Guide

## Overview

This guide provides step-by-step instructions to test the newly implemented in-call messaging functionality that connects to the Supabase database.

## Changes Implemented

### 1. End Call Button Styling ✅
- Changed end call button icon to clear white phone handset on red background
- Removed complex SVG paths for better clarity

### 2. In-Call Messaging Database Integration ✅
- Connected in-call chat to Supabase `chime_messages` table
- Implemented automatic chat initialization on meeting join
- Added real-time message synchronization between participants
- Added message history loading (last 50 messages)
- Added sender name tracking for better UX

## Test Requirements

### Prerequisites
1. Two test devices or one device + one emulator
2. Two different user accounts (Provider and Patient)
3. An active appointment with `video_enabled=true`
4. Camera and microphone permissions granted
5. Active internet connection

### Test Devices Options
- **Option 1**: Two physical devices (recommended)
- **Option 2**: One physical device + one emulator (Android)
- **Option 3**: Two emulators (requires proper camera setup - see ANDROID_EMULATOR_VIDEO_CALL_SETUP.md)

## Test Procedures

### Test 1: End Call Button Visual Verification

**Objective**: Verify end call button has correct styling

**Steps**:
1. Start the app on any device
2. Log in as either Provider or Patient
3. Navigate to an appointment with video enabled
4. Join the video call
5. Wait for the video call interface to load

**Expected Results**:
- ✅ End call button has red background (#FF3B30)
- ✅ End call button shows white phone handset icon
- ✅ Icon is clear and recognizable (not complex paths)
- ✅ Button is easily clickable

**Pass Criteria**: Button appearance matches description above

---

### Test 2: Single Message Send & Store

**Objective**: Verify messages are stored in Supabase database

**Steps**:
1. Device 1: Log in as Provider and join video call
2. Device 1: Open in-call chat (click chat icon)
3. Device 1: Type message "Test message 1" and send
4. Database: Check Supabase `chime_messages` table

**Query to run in Supabase SQL Editor**:
```sql
SELECT
  id,
  channel_id,
  sender_id,
  sender_name,
  message_content,
  message_type,
  created_at
FROM chime_messages
WHERE message_content = 'Test message 1'
ORDER BY created_at DESC
LIMIT 1;
```

**Expected Results**:
- ✅ Message appears in database within 2 seconds
- ✅ `channel_id` matches meeting ID
- ✅ `sender_id` matches Provider's user ID
- ✅ `sender_name` shows Provider's display name (not UUID)
- ✅ `message_content` is "Test message 1"
- ✅ `message_type` is "text"
- ✅ `created_at` timestamp is correct

**Pass Criteria**: All fields match expected values

---

### Test 3: Real-Time Message Synchronization

**Objective**: Verify messages appear in real-time for both participants

**Steps**:
1. Device 1: Log in as Provider and join video call
2. Device 2: Log in as Patient and join same video call
3. Both: Wait for "✅ Successfully joined Chime meeting" in debug logs
4. Both: Open in-call chat
5. Device 1 (Provider): Send message "Hello from Provider"
6. Device 2 (Patient): Observe chat window
7. Device 2 (Patient): Send message "Hello from Patient"
8. Device 1 (Provider): Observe chat window

**Expected Results**:
- ✅ Provider's message appears on Patient's screen within 2 seconds
- ✅ Patient's message appears on Provider's screen within 2 seconds
- ✅ Messages display sender names (not UUIDs)
- ✅ Messages are ordered chronologically
- ✅ Sent messages appear on sender's screen immediately
- ✅ No duplicate messages appear

**Debug Logs to Check**:
```
💬 Initializing chat...
💬 Chat meeting ID: <meeting-id>
💬 User ID: <user-id>
📥 Loading existing messages for meeting: <meeting-id>
📡 Subscribing to real-time messages...
✅ Chat initialized successfully
📨 Received X message updates
✅ Displayed received message from <sender-name>
```

**Pass Criteria**: All messages sync correctly in both directions

---

### Test 4: Message History Loading

**Objective**: Verify existing messages load when joining chat

**Setup**:
1. Device 1: Start video call and send 5 messages:
   - "Message 1"
   - "Message 2"
   - "Message 3"
   - "Message 4"
   - "Message 5"
2. Device 1: Close chat but stay in call
3. Device 2: Join the same video call
4. Device 2: Open in-call chat

**Expected Results**:
- ✅ All 5 previous messages appear in chronological order
- ✅ Messages display correct sender names
- ✅ Messages load within 3 seconds of opening chat
- ✅ No error messages in console

**Debug Logs to Check**:
```
📥 Loading existing messages for meeting: <meeting-id>
📥 Loaded 5 existing messages
✅ Existing messages loaded and displayed
```

**Pass Criteria**: All 5 messages load correctly with proper ordering

---

### Test 5: Message Persistence Across Sessions

**Objective**: Verify messages persist after call ends and are loaded in next session

**Steps**:
1. Device 1: Start video call
2. Device 1: Send 3 messages in chat
3. Device 1: End the call (click red end call button)
4. Wait 30 seconds
5. Device 1: Join the same appointment again (same meeting ID)
6. Device 1: Open in-call chat

**Expected Results**:
- ✅ Previous 3 messages appear in chat
- ✅ Messages are in correct order
- ✅ Timestamps are preserved

**Database Verification**:
```sql
SELECT COUNT(*) as message_count
FROM chime_messages
WHERE channel_id = '<meeting-id>';
-- Should show 3 messages
```

**Pass Criteria**: Messages persist across call sessions

---

### Test 6: Multiple Participants (3+ users)

**Objective**: Verify messaging works with more than 2 participants

**Requirements**: 3 devices/users minimum

**Steps**:
1. Device 1 (Provider): Join video call
2. Device 2 (Patient): Join same video call
3. Device 3 (Observer): Join same video call as allowed participant
4. Device 1: Send "Message from Provider"
5. Device 2: Send "Message from Patient"
6. Device 3: Send "Message from Observer"
7. All devices: Observe chat

**Expected Results**:
- ✅ All participants see all 3 messages
- ✅ Each message shows correct sender name
- ✅ Messages appear in chronological order on all devices
- ✅ No messages are duplicated
- ✅ No messages are missing

**Pass Criteria**: All participants receive all messages correctly

---

### Test 7: Chat Initialization After Meeting Join

**Objective**: Verify chat initializes automatically when meeting is joined

**Steps**:
1. Device 1: Join video call
2. Monitor debug logs
3. Wait for "MEETING_JOINED" message
4. Check if chat initialization occurs automatically

**Expected Debug Logs Sequence**:
```
✅ Successfully joined Chime meeting
💬 Initializing chat...
💬 Chat meeting ID: <meeting-id>
💬 User ID: <user-id>
💬 User name: <user-name>
📥 Loading existing messages for meeting: <meeting-id>
📡 Subscribing to real-time messages...
✅ Chat initialized successfully
```

**Expected Results**:
- ✅ Chat initializes automatically (no manual trigger needed)
- ✅ Meeting ID is passed to JavaScript correctly
- ✅ User ID and name are passed correctly
- ✅ Subscription to real-time messages is established

**Pass Criteria**: Chat initialization happens automatically and successfully

---

### Test 8: Error Handling

**Objective**: Verify graceful error handling for messaging failures

**Test 8A: Network Interruption**
1. Device 1: Join video call and open chat
2. Device 1: Send message "Before disconnect"
3. Device 1: Disable internet connection
4. Device 1: Attempt to send message "During disconnect"
5. Device 1: Re-enable internet connection
6. Device 1: Send message "After reconnect"

**Expected Results**:
- ✅ "Before disconnect" message sends successfully
- ✅ "During disconnect" shows error snackbar or fails gracefully
- ✅ "After reconnect" sends successfully after network recovery
- ✅ No app crashes occur

**Test 8B: Database Permission Error**
1. Temporarily disable RLS policies for `chime_messages` table
2. Attempt to send message
3. Re-enable RLS policies

**Expected Results**:
- ✅ Error is logged to console
- ✅ User sees error message (red snackbar)
- ✅ App remains functional
- ✅ No crash or freeze

**Pass Criteria**: Errors are handled gracefully without crashes

---

### Test 9: Message Display Formatting

**Objective**: Verify messages display correctly with proper formatting

**Steps**:
1. Device 1 & 2: Join video call
2. Device 1: Send messages with different content:
   - Short message: "Hi"
   - Long message: "This is a very long message that should wrap to multiple lines to test the display formatting and ensure it looks good in the chat interface"
   - Special characters: "Test @#$%^&* 123 🎉"
   - Newlines: "Line 1\nLine 2\nLine 3"

**Expected Results**:
- ✅ Short messages display normally
- ✅ Long messages wrap to multiple lines
- ✅ Special characters display correctly
- ✅ Emojis render properly (if supported)
- ✅ Newlines are preserved or converted to <br> in HTML

**Pass Criteria**: All message types display correctly

---

### Test 10: Performance with Many Messages

**Objective**: Verify performance doesn't degrade with many messages

**Setup**:
1. Pre-populate database with 50 messages for a meeting:
```sql
-- Run this in Supabase SQL Editor
INSERT INTO chime_messages (channel_id, sender_id, sender_name, message_content, message_type)
SELECT
  '<meeting-id>',
  '<user-id>',
  'Test User',
  'Performance test message ' || generate_series,
  'text'
FROM generate_series(1, 50);
```

**Steps**:
1. Device 1: Join video call
2. Device 1: Open chat
3. Measure load time and responsiveness

**Expected Results**:
- ✅ Messages load within 5 seconds
- ✅ Scrolling is smooth
- ✅ New messages still appear in real-time
- ✅ No UI lag or freezing
- ✅ Memory usage remains stable

**Debug Logs to Check**:
```
📥 Loaded 50 existing messages
✅ Existing messages loaded and displayed
```

**Pass Criteria**: Chat performs well even with 50+ messages

---

## Common Issues & Troubleshooting

### Issue 1: Messages Not Appearing

**Symptoms**: Messages send but don't appear in chat

**Diagnosis**:
1. Check debug logs for errors:
```
❌ Error sending message: <error-details>
❌ Error loading existing messages: <error-details>
```

2. Check Supabase RLS policies:
```sql
-- Verify user has INSERT permission
SELECT * FROM chime_messages WHERE sender_id = '<user-id>';
```

3. Check network connectivity:
```bash
# From device or emulator
ping noaeltglphdlkbflipit.supabase.co
```

**Solutions**:
- Ensure RLS policies allow INSERT and SELECT for authenticated users
- Verify internet connection is stable
- Check Firebase Auth is working (user is authenticated)
- Verify Supabase credentials in environment.json

---

### Issue 2: Real-Time Sync Not Working

**Symptoms**: Messages appear in database but not in other participant's chat

**Diagnosis**:
1. Check debug logs for subscription errors:
```
❌ Error subscribing to messages: <error-details>
```

2. Verify Supabase Realtime is enabled:
   - Go to Supabase Dashboard → Database → Replication
   - Ensure `chime_messages` table has Realtime enabled

3. Check subscription setup:
```
📡 Subscribing to real-time messages...
✅ Subscribed to real-time messages
```

**Solutions**:
- Enable Realtime for `chime_messages` table in Supabase
- Verify subscription filter: `.eq('channel_id', meetingId)`
- Check for JavaScript console errors in WebView

---

### Issue 3: Sender Names Not Showing

**Symptoms**: Messages display with UUIDs instead of names

**Diagnosis**:
1. Check database for sender_name field:
```sql
SELECT sender_name FROM chime_messages
WHERE message_content = '<test-message>'
LIMIT 1;
-- Should show actual name, not NULL or UUID
```

2. Check if widget.userName is populated:
```
💬 User name: <should-not-be-empty>
```

**Solutions**:
- Ensure `userName` parameter is passed to `joinRoom()` action
- Verify `widget.userName` has value in ChimeMeetingWebview
- Check database schema allows sender_name field

---

### Issue 4: Chat Not Initializing

**Symptoms**: Chat opens but shows no initialization logs

**Diagnosis**:
1. Check for MEETING_JOINED message:
```
✅ Successfully joined Chime meeting
```

2. Verify _initializeChat() is called:
```
💬 Initializing chat...
```

3. Check JavaScript console for errors

**Solutions**:
- Verify Chime SDK is fully loaded before joining
- Check JavaScript function `window.initializeChat()` exists
- Ensure meetingData contains valid MeetingId

---

## Testing Checklist

Use this checklist to track test completion:

- [ ] Test 1: End Call Button Visual Verification
- [ ] Test 2: Single Message Send & Store
- [ ] Test 3: Real-Time Message Synchronization
- [ ] Test 4: Message History Loading
- [ ] Test 5: Message Persistence Across Sessions
- [ ] Test 6: Multiple Participants (3+ users)
- [ ] Test 7: Chat Initialization After Meeting Join
- [ ] Test 8: Error Handling
  - [ ] Test 8A: Network Interruption
  - [ ] Test 8B: Database Permission Error
- [ ] Test 9: Message Display Formatting
- [ ] Test 10: Performance with Many Messages

## Success Criteria

The implementation is considered successful when:

1. ✅ All 10 tests pass
2. ✅ No compilation errors
3. ✅ No runtime crashes
4. ✅ Messages sync reliably between participants
5. ✅ Message history persists across sessions
6. ✅ Performance is acceptable with 50+ messages
7. ✅ Error handling is graceful
8. ✅ End call button has correct styling

## Next Steps After Testing

Once testing is complete:

1. **If All Tests Pass**:
   - Mark feature as complete
   - Update production deployment documentation
   - Consider user acceptance testing
   - Monitor production for any issues

2. **If Tests Fail**:
   - Document specific failures
   - Review debug logs
   - Check Supabase configuration
   - Verify Firebase Auth is working
   - Review code changes for bugs

## Additional Resources

- **Supabase Realtime Docs**: https://supabase.com/docs/guides/realtime
- **Chime SDK Messaging**: See `lib/custom_code/widgets/chime_meeting_webview.dart`
- **Database Schema**: `supabase/migrations/20251119020000_create_chime_messaging_tables.sql`
- **Android Emulator Setup**: `ANDROID_EMULATOR_VIDEO_CALL_SETUP.md`
- **General Testing Guide**: `TESTING_GUIDE.md`

## Contact & Support

For issues or questions:
1. Check debug logs first
2. Review this testing guide
3. Check database and Realtime status in Supabase Dashboard
4. Verify Firebase Auth is working
5. Check network connectivity

---

**Document Version**: 1.0
**Last Updated**: December 14, 2025
**Implemented By**: Claude Code
**Related Changes**: End call button styling + in-call messaging database integration
