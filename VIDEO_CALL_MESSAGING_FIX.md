# Video Call Messaging RLS Fix

## Problem
Video call in-app messaging was failing due to restrictive RLS policies on the `chime_messages` table.

### Root Cause
1. **SELECT Policy** required lookup in `chime_messaging_channels` table
2. Video calls don't create `chime_messaging_channels` records
3. Result: Users couldn't read messages during video calls, even though INSERT was working

### Previous Attempts
- `20251214200000_fix_chime_messages_rls_for_video_calls.sql` - Fixed INSERT only
- `20251214210000_emergency_fix_chime_messages_rls.sql` - Also fixed INSERT only
- **SELECT policy was never fixed**

## Solution
Migration `20251214220000_fix_chime_messages_select_rls.sql` fixes all CRUD operations:

### New RLS Policies

**SELECT Policy** - Users can view messages if:
1. They are a participant in the video call session (via `video_call_sessions.meeting_id`)
2. OR they have access via `chime_messaging_channels` (backward compatible)
3. OR they are the sender (can always see own messages)

**INSERT Policy** (from previous fix):
- User must be authenticated
- `user_id` or `sender_id` must match `auth.uid()`

**UPDATE/DELETE Policies**:
- User can only modify their own messages
- Validates `user_id` or `sender_id` matches `auth.uid()`

## Key Mapping
In video calls:
```dart
// chime_meeting_webview.dart:269
'channel_arn': data['meeting_id']  // Maps meeting_id to channel_arn
```

SQL join:
```sql
WHERE vcs.meeting_id = chime_messages.channel_arn
```

## Testing

### Send Test Message
1. Start video call with two users
2. Send message from Provider
3. Verify Patient receives it
4. Send message from Patient
5. Verify Provider receives it

### Expected Behavior ✅
- Messages appear instantly in chat
- No RLS errors in console
- Bidirectional messaging works

---

**Date:** 2025-12-14
**Migration:** 20251214220000
**Status:** Deploying
