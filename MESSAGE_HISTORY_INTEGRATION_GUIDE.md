# Message History Integration Guide

**Date:** December 17, 2025
**Status:** ✅ Complete - Read-only message viewer widget created

## Overview

This guide explains how to integrate message history viewing into FlutterFlow. The system supports two message viewing modes:

1. **During Video Call**: Full chat functionality (send + receive) - `ChimeMeetingEnhanced` widget
2. **After Video Call**: Read-only message history viewer - `ChimeMessageHistoryViewer` widget

## Architecture

### User Creation Flow
```
User Signs Up
    ↓
Firebase Auth creates user → Firebase UID
    ↓
onUserCreated Cloud Function
    ↓
Creates Supabase user → Supabase UUID
    ↓
Stores in Firestore: /users/{firebase_uid}/supabase_uuid
```

### Message Flow

**During Call:**
```
User in video call
    ↓
ChimeMeetingEnhanced widget
    ↓
User sends message
    ↓
Gets Supabase UUID from Firestore (using Firebase UID)
    ↓
Inserts into chime_messages table
    ↓
Real-time sync to all participants
```

**After Call:**
```
User taps Messages button
    ↓
ChimeMessageHistoryViewer widget
    ↓
Fetches Supabase UUID from Firestore
    ↓
Queries chime_messages (filtered by channel_id)
    ↓
Displays read-only message history
```

## Widget: ChimeMessageHistoryViewer

### Location
`lib/custom_code/widgets/chime_message_history_viewer.dart`

### Features
- ✅ Read-only message viewing (no send/edit capability)
- ✅ Displays text messages, images, files, system messages
- ✅ Shows sender name and avatar
- ✅ Timestamps with smart formatting (Today, Yesterday, etc.)
- ✅ Differentiates own messages from received messages
- ✅ Loading state and error handling
- ✅ Empty state for calls with no messages
- ✅ Works with Firebase Auth → Firestore → Supabase UUID flow

### Usage in FlutterFlow

#### Step 1: Add Custom Widget to FlutterFlow

1. Open your FlutterFlow project
2. Go to **Custom Code** → **Widgets**
3. The widget should already be available: `ChimeMessageHistoryViewer`
4. If not, re-export from FlutterFlow to sync custom code

#### Step 2: Add Widget to Your Page

**Example: Appointments Page**

1. Create a new page or open existing appointments detail page
2. Add a button labeled "View Messages" or "Chat History"
3. Set button action to **Navigate** → **New Page**
4. Create a new page called "MessageHistoryPage"
5. On MessageHistoryPage, add the custom widget:

```dart
ChimeMessageHistoryViewer(
  width: MediaQuery.of(context).size.width,
  height: MediaQuery.of(context).size.height,
  channelId: appointmentMeetingId,  // Pass the meeting_id
)
```

#### Step 3: Pass Meeting ID Parameter

The widget requires `channelId` (the meeting_id from the video call). You need to:

**Option A: Pass via Page Parameters**
1. Add page parameter to MessageHistoryPage: `meetingId` (String)
2. Pass the meeting_id when navigating:
   ```dart
   Navigator.pushNamed(
     context,
     'MessageHistoryPage',
     arguments: {'meetingId': appointment.meetingId},
   );
   ```
3. Use the page parameter in the widget:
   ```dart
   channelId: FFAppState().meetingId,  // or from page parameter
   ```

**Option B: Get from Appointment**
1. Query `video_call_sessions` table to get meeting_id:
   ```dart
   final session = await SupaFlow.client
     .from('video_call_sessions')
     .select('meeting_id')
     .eq('appointment_id', appointmentId)
     .single();

   final meetingId = session['meeting_id'];
   ```
2. Pass to widget:
   ```dart
   channelId: meetingId,
   ```

### Widget Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `width` | double? | No | Widget width (default: full screen) |
| `height` | double? | No | Widget height (default: full screen) |
| `channelId` | String | **Yes** | Meeting ID from video_call_sessions.meeting_id |

## Database Schema

### chime_messages Table

Messages are stored with the following key fields:

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `channel_id` | TEXT | Meeting ID (links to video_call_sessions.meeting_id) |
| `channel_arn` | TEXT | Alternative channel identifier |
| `message_content` | TEXT | Message text content |
| `message_type` | TEXT | 'text', 'image', 'file', 'system' |
| `sender_id` | UUID | Supabase UUID of message sender (FK to users.id) |
| `user_id` | UUID | Supabase UUID of message owner (FK to users.id) |
| `metadata` | JSONB | Sender name, image, file info |
| `created_at` | TIMESTAMPTZ | Message timestamp |

### RLS Policies

**SELECT Policy: "Video call participants can view messages"**
- Allows users who participated in a video call to view messages
- Works during the call AND after the call ends
- Checks if user was provider_id or patient_id in video_call_sessions
- Also allows viewing if user_id or sender_id matches

**INSERT Policy: "Authenticated users can insert messages"**
- Only allows INSERT during active video calls (via ChimeMeetingEnhanced)
- Requires user_id AND (channel_id OR channel_arn)

**UPDATE/DELETE Policies:**
- Users can update/delete their own messages
- Checks sender_id = auth.uid() OR user_id = auth.uid()

## FlutterFlow Integration Examples

### Example 1: Appointments List Page

Add a "View Messages" button next to each appointment:

```dart
// In appointments list item
Row(
  children: [
    // ... appointment details ...

    if (appointment.status == 'completed')
      IconButton(
        icon: Icon(Icons.chat_bubble_outline),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChimeMessageHistoryViewer(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                channelId: appointment.meetingId,
              ),
            ),
          );
        },
      ),
  ],
)
```

### Example 2: Appointment Detail Page

Add a "Chat History" tab or button:

```dart
// In appointment detail page
FloatingActionButton(
  onPressed: () async {
    // Get meeting_id from appointment
    final meetingId = await _getMeetingIdFromAppointment(appointmentId);

    if (meetingId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChimeMessageHistoryViewer(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            channelId: meetingId,
          ),
        ),
      );
    }
  },
  child: Icon(Icons.message),
  label: Text('View Messages'),
)

// Helper function
Future<String?> _getMeetingIdFromAppointment(String appointmentId) async {
  try {
    final response = await SupaFlow.client
        .from('video_call_sessions')
        .select('meeting_id')
        .eq('appointment_id', appointmentId)
        .maybeSingle();

    return response?['meeting_id'];
  } catch (e) {
    debugPrint('Error fetching meeting_id: $e');
    return null;
  }
}
```

### Example 3: Bottom Navigation Messages Tab

Add a messages tab that shows all message threads:

```dart
// Create a MessagesListPage that queries all user's conversations
class MessagesListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Messages')),
      body: FutureBuilder(
        future: _getUserConversations(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data as List;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(conversation['otherUserImage']),
                ),
                title: Text(conversation['otherUserName']),
                subtitle: Text(conversation['lastMessage']),
                trailing: Text(conversation['lastMessageTime']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChimeMessageHistoryViewer(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        channelId: conversation['channelId'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List> _getUserConversations() async {
    // Get current user's Supabase UUID
    final userId = await _getSupabaseUserId();

    // Query video_call_sessions where user participated
    final sessions = await SupaFlow.client
        .from('video_call_sessions')
        .select('*')
        .or('provider_id.eq.$userId,patient_id.eq.$userId')
        .order('created_at', ascending: false);

    // Return list of conversations with last message info
    // ... implementation details ...
  }
}
```

## Testing

### Prerequisites
- Two test accounts (provider and patient)
- Completed appointment with video call
- Messages sent during the video call

### Test Steps

1. **Test Message Viewing**
   - Log in as provider
   - Navigate to completed appointment
   - Tap "View Messages" button
   - Verify message history loads
   - Verify messages display correctly (text, images, timestamps)
   - Verify you can identify which messages are yours (right side, blue)
   - Verify received messages show sender name and avatar (left side)

2. **Test Read-Only Mode**
   - Verify there is NO send message input field
   - Verify there is NO send button
   - Verify you CANNOT edit messages
   - Verify footer shows: "Messages can only be sent during active video calls"

3. **Test Empty State**
   - Create appointment without starting video call
   - Tap "View Messages"
   - Verify shows: "No messages yet" with icon
   - Verify shows helpful text

4. **Test Error Handling**
   - Pass invalid channelId
   - Verify error message displays
   - Verify "Retry" button works

5. **Test Cross-User Viewing**
   - Log in as patient
   - View same appointment's messages
   - Verify patient sees all messages from the call
   - Verify messages are properly aligned (own vs received)

## Firestore Requirements

### Required Field
Each user document in Firestore must have:

**Path:** `/users/{firebase_uid}`

**Required Field:**
```json
{
  "supabase_uuid": "123e4567-e89b-12d3-a456-426614174000"
}
```

This field is automatically created by the `onUserCreated` Firebase Cloud Function during user registration.

### Verification

Check if a user has the required field:

```javascript
// Firebase Console or Admin SDK
const userDoc = await admin.firestore()
  .collection('users')
  .doc(firebaseUid)
  .get();

const supabaseUuid = userDoc.data().supabase_uuid;
console.log('Supabase UUID:', supabaseUuid);
```

If missing, the widget will show an error: "Unable to identify user. Please ensure you are logged in."

## Troubleshooting

### Issue 1: "Unable to identify user"
**Cause:** Firestore document missing `supabase_uuid` field
**Fix:**
1. Check if user document exists in Firestore
2. Verify `supabase_uuid` field is present
3. Ensure `onUserCreated` Cloud Function is deployed and working
4. Manually add field if needed

### Issue 2: Messages Not Loading
**Cause:** Incorrect channelId or RLS policy blocking access
**Fix:**
1. Verify channelId matches `video_call_sessions.meeting_id`
2. Check RLS policy allows user to view messages:
   ```sql
   SELECT * FROM video_call_sessions
   WHERE meeting_id = 'YOUR_CHANNEL_ID'
   AND (provider_id = 'USER_UUID' OR patient_id = 'USER_UUID');
   ```
3. Check browser console for errors

### Issue 3: "Failed to load messages"
**Cause:** Database error or network issue
**Fix:**
1. Check Supabase connection
2. Verify user has SELECT permission
3. Check Supabase logs for errors
4. Verify video_call_sessions table has matching record

### Issue 4: Images Not Displaying
**Cause:** Invalid image URL or storage permissions
**Fix:**
1. Verify image URL starts with `http://` or `https://`
2. Check chime_storage bucket is public
3. Verify storage RLS policies allow public reads
4. Check browser console for CORS errors

## Security Considerations

### RLS Policy Protection
- Users can ONLY view messages from video calls they participated in
- Enforced at database level via RLS policies
- Cannot bypass by modifying channelId in widget

### Data Privacy
- Messages are stored with sender_id (UUID)
- Foreign key constraint ensures data integrity
- ON DELETE CASCADE removes messages when user is deleted

### Authentication
- Widget verifies Firebase Auth before loading
- Fetches Supabase UUID from Firestore
- All database queries use authenticated user's UUID

## Performance

### Query Optimization
- Messages are indexed by `channel_id` and `created_at`
- Widget limits initial load to 50 messages
- Real-time updates disabled (read-only mode)

### Loading States
- Shows loading spinner while fetching messages
- Displays helpful empty state if no messages
- Shows error with retry button if loading fails

## Related Files

### Widget Code
- `lib/custom_code/widgets/chime_message_history_viewer.dart` - Read-only message viewer

### Migrations
- `20251217040000_update_chime_messages_for_enhanced_chat.sql` - Schema updates
- `20251217050000_create_chime_storage_bucket.sql` - Storage bucket
- `20251217060000_change_sender_id_to_uuid.sql` - UUID sender_id
- `20251217070000_fix_select_policy_for_firebase_auth.sql` - RLS policy fix

### Documentation
- `SENDER_ID_UUID_UPDATE_SUMMARY.md` - Sender ID implementation
- `CHIME_MESSAGES_SCHEMA_UPDATE_SUMMARY.md` - Database schema
- `ENHANCED_CHIME_USAGE_GUIDE.md` - Video call widget guide

## Next Steps

1. ✅ **Widget Created** - ChimeMessageHistoryViewer ready
2. ✅ **RLS Policies Updated** - SELECT policy works for historical viewing
3. ⏭️ **FlutterFlow Integration** - Add widget to appointments page
4. ⏭️ **Test in App** - Verify message viewing works
5. ⏭️ **Production Deployment** - Deploy updated code

## Summary

The message history integration is complete and ready for use:

- ✅ Read-only message viewer widget created
- ✅ RLS policies support post-call message viewing
- ✅ Works with Firebase Auth → Firestore → Supabase UUID flow
- ✅ Displays all message types (text, images, files, system)
- ✅ Proper security via RLS policies
- ✅ Error handling and loading states
- ✅ Mobile-friendly UI with proper styling

**To integrate:** Add `ChimeMessageHistoryViewer` widget to your FlutterFlow page and pass the `channelId` (meeting_id) from the appointment.

---

**Questions or issues?** Check the troubleshooting section or review the related documentation files.
