# Sender ID UUID Update Summary

**Date:** December 17, 2025
**Status:** ✅ Complete - sender_id changed to UUID with Firestore integration

## What Was Changed

### 1. Database Schema: sender_id Column Changed to UUID ✅

Applied migration: `20251217060000_change_sender_id_to_uuid.sql`

**Changes:**
- ✅ Dropped all RLS policies that referenced sender_id (to allow column modification)
- ✅ Converted `sender_id` from TEXT to UUID
- ✅ Added foreign key constraint: `sender_id` → `users(id)` ON DELETE CASCADE
- ✅ Recreated all RLS policies with UUID-compatible checks
- ✅ Recreated index on sender_id

**Migration Status:** Successfully applied

### 2. ChimeMeetingEnhanced Widget Updated ✅

Updated file: `lib/custom_code/widgets/chime_meeting_enhanced.dart`

**Changes:**

#### Added Firestore Import
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
```

#### Added Helper Method to Fetch Supabase UUID
```dart
/// Fetch Supabase UUID from Firestore using Firebase Auth UID
Future<String?> _getSupabaseUserId() async {
  try {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    final firebaseUid = firebaseUser.uid;

    // Fetch Supabase UUID from Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUid)
        .get();

    if (!doc.exists) {
      return null;
    }

    final supabaseUuid = doc.data()?['supabase_uuid'] as String?;
    return supabaseUuid;
  } catch (e) {
    debugPrint('❌ Error fetching Supabase UUID: $e');
    return null;
  }
}
```

#### Updated All Three Locations Where userId is Used

**Location 1: _handleSendMessage() method (line ~471)**
```dart
// Before:
final userId = SupaFlow.client.auth.currentUser?.id;

// After:
final userId = await _getSupabaseUserId();
```

**Location 2: _loadMessages() method (line ~545)**
```dart
// Before:
final userId = SupaFlow.client.auth.currentUser?.id;

// After:
final userId = await _getSupabaseUserId();
```

**Location 3: _subscribeToMessages() realtime listener (line ~579)**
```dart
// Before (synchronous callback):
.listen((data) {
  final userId = SupaFlow.client.auth.currentUser?.id;
  ...
})

// After (async callback):
.listen((data) async {
  final userId = await _getSupabaseUserId();
  ...
})
```

## Architecture Flow

### Authentication & User ID Flow

```
Firebase Auth (User Login)
    ↓
Firebase UID (String)
    ↓
Firestore: /users/{firebase_uid}/supabase_uuid
    ↓
Supabase UUID (UUID)
    ↓
chime_messages.sender_id (UUID)
    ↓
Foreign Key: users(id)
```

### Message Creation Flow

1. User sends message in video call chat
2. Widget calls `_handleSendMessage()`
3. Helper method `_getSupabaseUserId()`:
   - Gets current Firebase Auth user UID
   - Queries Firestore: `/users/{firebase_uid}`
   - Extracts `supabase_uuid` field (UUID)
4. Message inserted into `chime_messages` with:
   - `user_id`: Supabase UUID
   - `sender_id`: Supabase UUID (same value)
   - `channel_id`: Meeting ID
   - `message_content`: Message text
   - `message_type`: 'text', 'image', 'file', or 'system'

## Database Schema

### chime_messages Table (Updated)

| Column | Type | Nullable | Constraint |
|--------|------|----------|------------|
| sender_id | **UUID** | NULL | FK to users(id) ON DELETE CASCADE |
| user_id | UUID | NOT NULL | FK to users(id) ON DELETE CASCADE |
| channel_id | TEXT | NULL | Meeting/channel identifier |
| message_content | TEXT | NULL | Message text |
| message_type | TEXT | NULL | 'text', 'image', 'file', 'system' |
| metadata | JSONB | NULL | File metadata, sender info |

### Updated Constraints

- **Foreign Key:** `sender_id` → `users(id)` ON DELETE CASCADE
- **Check Constraint:** `message_type IN ('text', 'system', 'file', 'image')`

### Updated RLS Policies

| Policy Name | Operation | Description |
|-------------|-----------|-------------|
| Authenticated users can insert messages | INSERT | Requires user_id AND (channel_id OR channel_arn) |
| Video call participants can view messages | SELECT | Allows participants to view messages in their calls |
| Users can update their own messages | UPDATE | `sender_id = auth.uid() OR user_id = auth.uid()` |
| Users can delete their own messages | DELETE | `sender_id = auth.uid() OR user_id = auth.uid()` |

## Firestore Requirements

### Required Field in Firestore

**Document Path:** `/users/{firebase_uid}`

**Required Field:**
```json
{
  "supabase_uuid": "123e4567-e89b-12d3-a456-426614174000"
}
```

**Field Type:** String (UUID format)

**Purpose:** Links Firebase Auth UID to Supabase users table UUID

### How to Set Up (If Not Already Present)

This field should be automatically set by the `onUserCreated` Firebase Cloud Function when a new user is created. If missing, it can be set manually or via the user creation flow.

**Example User Creation Flow:**
1. User signs up → Firebase Auth creates user with Firebase UID
2. `onUserCreated` Cloud Function triggers
3. Function creates Supabase user with UUID
4. Function writes to Firestore: `/users/{firebase_uid}` with `supabase_uuid` field

## Testing

### 1. Verify Firestore Setup

Check that users have the `supabase_uuid` field:

```javascript
// In Firebase Console or using Firebase Admin SDK
db.collection('users').doc(FIREBASE_UID).get().then(doc => {
  console.log('supabase_uuid:', doc.data().supabase_uuid);
});
```

### 2. Test Video Call Chat

**Prerequisites:**
- Two test accounts with valid Firestore `supabase_uuid` fields
- Active video call appointment

**Test Steps:**

1. **Start Video Call**
   - Provider and patient join call
   - Both see video streams

2. **Send Chat Message**
   - Open chat panel (💬 button)
   - Type message and send
   - Check browser console for logs:
     ```
     🔑 Firebase UID: [firebase_uid]
     ✅ Supabase UUID: [supabase_uuid]
     💬 Handling chat message: text
     ✅ Message saved to Supabase
     ```

3. **Verify Database**
   - Check `chime_messages` table
   - Confirm `sender_id` is UUID (not text)
   - Confirm foreign key relationship works

### 3. Verify Database Records

```sql
-- Check message with sender_id
SELECT
    id,
    sender_id,
    user_id,
    message_content,
    message_type,
    channel_id,
    created_at
FROM chime_messages
ORDER BY created_at DESC
LIMIT 10;

-- Verify foreign key constraint
SELECT
    conname,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'chime_messages'::regclass
AND conname = 'chime_messages_sender_id_fkey';

-- Verify sender_id links to users table
SELECT
    cm.id,
    cm.sender_id,
    u.email,
    u.display_name
FROM chime_messages cm
JOIN users u ON cm.sender_id = u.id
ORDER BY cm.created_at DESC
LIMIT 10;
```

## Error Handling

### Common Issues

**Issue 1: "No Supabase user ID available"**
- **Cause:** Firestore document doesn't have `supabase_uuid` field
- **Fix:** Ensure `onUserCreated` Cloud Function properly creates Firestore document
- **Check:** Query Firestore for user document

**Issue 2: "User document not found in Firestore"**
- **Cause:** User document wasn't created during signup
- **Fix:** Manually create Firestore document with `supabase_uuid`
- **Check:** Verify Firebase Auth user exists

**Issue 3: Foreign key violation on INSERT**
- **Cause:** Supabase UUID in Firestore doesn't match any user in `users` table
- **Fix:** Sync Firestore `supabase_uuid` with Supabase `users.id`
- **Check:** Query both Firestore and Supabase to verify IDs match

**Issue 4: Messages not appearing**
- **Cause:** Async callback in realtime listener not resolving
- **Fix:** Check browser console for JavaScript errors
- **Check:** Verify network connectivity to Supabase

## Migration Files

1. **20251217040000_update_chime_messages_for_enhanced_chat.sql**
   - Added 'image' message type
   - Added indexes
   - Updated INSERT policy

2. **20251217050000_create_chime_storage_bucket.sql**
   - Created chime_storage bucket

3. **20251217060000_change_sender_id_to_uuid.sql** ✅
   - Changed sender_id from TEXT to UUID
   - Added foreign key constraint
   - Updated all RLS policies

## Verification Status

| Component | Status | Notes |
|-----------|--------|-------|
| sender_id column type | ✅ UUID | Changed from TEXT to UUID |
| Foreign key constraint | ✅ Added | Links to users(id) ON DELETE CASCADE |
| RLS policies updated | ✅ Complete | All policies recreated with UUID checks |
| Widget code updated | ✅ Complete | Uses Firestore to fetch Supabase UUID |
| Firestore integration | ✅ Complete | _getSupabaseUserId() helper method added |
| Compilation check | ✅ Passing | No errors, only minor warnings |

## Benefits of UUID sender_id

1. **Data Integrity**: Foreign key ensures sender_id always points to valid user
2. **Automatic Cleanup**: ON DELETE CASCADE removes messages when user is deleted
3. **Type Safety**: UUID type prevents invalid string values
4. **Database Optimization**: UUID is more efficient than TEXT for joins and indexes
5. **Referential Integrity**: Database enforces relationship between messages and users

## Next Steps

1. ✅ **Database Migration** - Complete
2. ✅ **Widget Update** - Complete
3. ⏭️ **Test in Flutter App** - Test video call chat functionality
4. ⏭️ **Verify Firestore Setup** - Ensure all users have `supabase_uuid` field
5. ⏭️ **Production Deployment** - Deploy updated widget to production

## Related Documentation

- `CHIME_MESSAGES_SCHEMA_UPDATE_SUMMARY.md` - Previous schema updates
- `ENHANCED_CHIME_USAGE_GUIDE.md` - Video call widget usage guide
- `CLAUDE.md` - Architecture and system integration overview

---

**Summary:** Successfully changed sender_id from TEXT to UUID with foreign key constraint. Widget now fetches Supabase UUID from Firestore using Firebase Auth UID. All three locations in the widget updated to use new helper method. Ready for testing in Flutter app.
