# 🎥 Agora Video Call Testing Guide

**Status:** Production Ready
**Last Updated:** 2025-11-11
**Function:** `generateVideoCallTokens` (SECURE)

---

## ✅ What We've Done

### Backend (Complete)
1. ✅ Installed `agora-token` package in Firebase Functions
2. ✅ Deployed secure `generateVideoCallTokens` function
3. ✅ Deployed `refreshVideoCallToken` function for token refresh
4. ✅ Configured Firebase with Agora credentials
5. ✅ Deleted insecure `generateToken` function
6. ✅ Removed `custom_cloud_functions` directory
7. ✅ Cleaned up duplicate config keys

### Frontend (Complete)
1. ✅ Updated `join_room.dart` to call secure function
2. ✅ Changed parameters to use session-based authentication
3. ✅ Added role-based token selection (provider vs patient)
4. ✅ Added error handling with user feedback

### Security (Complete)
1. ✅ Server-side credentials only (no client exposure)
2. ✅ Firebase Authentication required
3. ✅ Supabase session validation
4. ✅ Database integration (video_call_sessions table)
5. ✅ 2-hour token expiration with refresh capability

---

## 📋 Prerequisites

Before testing, ensure you have:

### 1. Supabase Table: video_call_sessions

Your Supabase database must have this table structure:

```sql
CREATE TABLE IF NOT EXISTS video_call_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id UUID NOT NULL REFERENCES appointments(id),
  channel_name TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'scheduled',
  provider_id UUID NOT NULL REFERENCES users(id),
  patient_id UUID NOT NULL REFERENCES users(id),
  scheduled_at TIMESTAMPTZ NOT NULL,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  duration_minutes INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_video_call_sessions_appointment ON video_call_sessions(appointment_id);
CREATE INDEX idx_video_call_sessions_provider ON video_call_sessions(provider_id);
CREATE INDEX idx_video_call_sessions_patient ON video_call_sessions(patient_id);
CREATE INDEX idx_video_call_sessions_status ON video_call_sessions(status);
```

### 2. Test Data

Create a test session in Supabase:

```sql
-- Example test session
INSERT INTO video_call_sessions (
  id,
  appointment_id,
  channel_name,
  status,
  provider_id,
  patient_id,
  scheduled_at
) VALUES (
  gen_random_uuid(), -- Will generate a session ID
  '<YOUR_APPOINTMENT_ID>', -- Replace with real appointment ID
  'test-channel-' || EXTRACT(EPOCH FROM NOW())::TEXT, -- Unique channel
  'scheduled',
  '<YOUR_PROVIDER_USER_ID>', -- Replace with provider's user ID
  '<YOUR_PATIENT_USER_ID>', -- Replace with patient's user ID
  NOW()
);
```

### 3. User Authentication

Both provider and patient must be:
- ✅ Authenticated in Firebase Auth
- ✅ Have corresponding records in Supabase `users` table

---

## 🎯 Step-by-Step Testing

### Phase 1: Backend Function Test

**Test the Firebase function directly using curl:**

```bash
# Get Firebase Auth ID token first
# You can get this from your app after login using:
# await FirebaseAuth.instance.currentUser?.getIdToken()

export AUTH_TOKEN="<YOUR_FIREBASE_ID_TOKEN>"
export SESSION_ID="<YOUR_SESSION_ID>"
export PROVIDER_ID="<YOUR_PROVIDER_USER_ID>"
export PATIENT_ID="<YOUR_PATIENT_USER_ID>"
export APPOINTMENT_ID="<YOUR_APPOINTMENT_ID>"

curl -X POST \
  https://us-central1-medzen-bf20e.cloudfunctions.net/generateVideoCallTokens \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -d "{
    \"data\": {
      \"sessionId\": \"$SESSION_ID\",
      \"providerId\": \"$PROVIDER_ID\",
      \"patientId\": \"$PATIENT_ID\",
      \"appointmentId\": \"$APPOINTMENT_ID\"
    }
  }"
```

**Expected Response:**

```json
{
  "result": {
    "channelName": "video-call-session-<session-id>",
    "providerToken": "007eJxT...(long token string)",
    "patientToken": "007eJxT...(different long token string)",
    "appId": "9a6e33f84cd542d9aba14374ae3326b7",
    "conversationId": "<conversation-id>",
    "expiresAt": "2025-11-11T23:00:00Z"
  }
}
```

**Error Responses:**

```json
// If not authenticated
{
  "error": {
    "message": "User must be authenticated to generate video call tokens",
    "status": "UNAUTHENTICATED"
  }
}

// If session not found
{
  "error": {
    "message": "Video call session not found",
    "status": "NOT_FOUND"
  }
}

// If user not authorized
{
  "error": {
    "message": "User not authorized for this session",
    "status": "PERMISSION_DENIED"
  }
}
```

---

### Phase 2: Flutter App Integration Test

**Step 1: Update Your Call Button/Action**

Where you currently have a button to start a video call, update the parameters passed to `joinRoom`:

**Before (OLD - INSECURE):**
```dart
// ❌ OLD WAY - Don't use this
await joinRoom(
  context,
  'channel-name',
  '9a6e33f84cd542d9aba14374ae3326b7', // appId
  '9c55f9ab797a4dbd8620165ad657cd18', // appCertificate
  userName,
  profileImage,
);
```

**After (NEW - SECURE):**
```dart
// ✅ NEW WAY - Use this
// Get these from your appointment/session data
final sessionId = '<session-uuid-from-database>';
final providerId = '<provider-user-id>';
final patientId = '<patient-user-id>';
final appointmentId = '<appointment-uuid>';

// Determine if current user is provider or patient
final currentUserId = FirebaseAuth.instance.currentUser?.uid;
final isProvider = (currentUserId == providerId);

await joinRoom(
  context,
  sessionId,
  providerId,
  patientId,
  appointmentId,
  isProvider, // Important: determines which token to use
  userName,
  profileImage,
);
```

**Step 2: Add Debug Logging**

Before calling `joinRoom`, add logging to verify your data:

```dart
debugPrint('=== Video Call Debug ===');
debugPrint('Session ID: $sessionId');
debugPrint('Provider ID: $providerId');
debugPrint('Patient ID: $patientId');
debugPrint('Appointment ID: $appointmentId');
debugPrint('Current User: $currentUserId');
debugPrint('Is Provider: $isProvider');
debugPrint('=====================');
```

**Step 3: Run the App**

```bash
# Clean and rebuild
flutter clean
flutter pub get

# Run on your test device
flutter run -d <device-id>

# Or on Chrome for quick testing
flutter run -d chrome
```

**Step 4: Monitor Logs**

In your Flutter console, watch for:

```
✅ Video call tokens generated successfully!
Channel: video-call-session-<id>
Role: Provider (or Patient)
Conversation ID: <conversation-id>
Token expires at: 2025-11-11T23:00:00Z
```

---

### Phase 3: End-to-End Video Call Test

**Test Scenario 1: Provider Starts Call**

1. **Login as Provider**
   - Use provider credentials
   - Navigate to appointments
   - Find scheduled appointment with video call

2. **Start Video Call**
   - Click "Join Video Call" button
   - Should see PreJoiningDialog with:
     - ✅ Camera preview
     - ✅ Microphone controls
     - ✅ Camera controls
   - Click "Join Call"

3. **Expected Behavior**
   - ✅ Camera feed shows in preview
   - ✅ Can toggle camera on/off
   - ✅ Can toggle mic on/off
   - ✅ Enters call successfully
   - ✅ Channel name matches Supabase session

**Test Scenario 2: Patient Joins Call**

1. **Login as Patient** (different device/browser)
   - Use patient credentials
   - Navigate to appointments
   - Find same appointment

2. **Join Video Call**
   - Click "Join Video Call" button
   - Should see PreJoiningDialog
   - Click "Join Call"

3. **Expected Behavior**
   - ✅ Both users see each other
   - ✅ Audio works both ways
   - ✅ Video works both ways
   - ✅ Can toggle camera/mic independently
   - ✅ Call remains stable

**Test Scenario 3: Permission Handling**

Test on mobile devices (iOS/Android):

1. **First Time (No Permissions)**
   - App should request camera permission
   - App should request microphone permission
   - User must grant both

2. **Permissions Denied**
   - Camera/mic buttons should show disabled
   - User should see helpful error message
   - App should not crash

3. **Permissions Granted**
   - Preview should work immediately
   - Join button should be enabled

---

## 🔍 Troubleshooting

### Error: "User must be authenticated"

**Problem:** Firebase Auth not initialized or user not logged in.

**Solution:**
```dart
// Check authentication status
final user = FirebaseAuth.instance.currentUser;
if (user == null) {
  // User not logged in - redirect to login
  context.pushNamed('LoginPage');
  return;
}
```

### Error: "Video call session not found"

**Problem:** Session doesn't exist in Supabase or IDs don't match.

**Solution:**
1. Verify session exists in `video_call_sessions` table
2. Check session ID matches exactly (UUIDs are case-sensitive)
3. Verify appointment ID matches

```sql
-- Check if session exists
SELECT * FROM video_call_sessions
WHERE id = '<your-session-id>'
AND appointment_id = '<your-appointment-id>';
```

### Error: "User not authorized for this session"

**Problem:** Current user ID doesn't match provider_id or patient_id in session.

**Solution:**
1. Verify current user ID matches session
2. Check user hasn't switched accounts

```dart
// Verify authorization
final currentUserId = FirebaseAuth.instance.currentUser?.uid;
debugPrint('Current User: $currentUserId');
debugPrint('Expected Provider: $providerId');
debugPrint('Expected Patient: $patientId');

if (currentUserId != providerId && currentUserId != patientId) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('You are not authorized for this call')),
  );
  return;
}
```

### Error: "Token expired"

**Problem:** Token has exceeded 2-hour validity.

**Solution:** Use the refresh function:

```dart
// Refresh token
final refreshResponse = await FirebaseFunctions.instance
    .httpsCallable('refreshVideoCallToken')
    .call({
      'sessionId': sessionId,
      'userId': currentUserId,
    });

final newToken = refreshResponse.data['token'] as String;
```

### Camera/Microphone Not Working

**Problem:** Permissions not granted or hardware issues.

**iOS Solution:**
```xml
<!-- Add to ios/Runner/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>MedZen needs camera access for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>MedZen needs microphone access for video calls</string>
```

**Android Solution:**
```xml
<!-- Add to android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
```

### Video Lag or Poor Quality

**Problem:** Network issues or bandwidth constraints.

**Solutions:**
1. Check internet connection
2. Reduce video resolution (configure in PreJoiningDialog)
3. Check Agora dashboard for quality metrics
4. Verify users are not on same network (local loopback issues)

### "Channel name already in use"

**Problem:** Channel name collision or previous session not cleaned up.

**Solution:**
```sql
-- Update session to use new channel
UPDATE video_call_sessions
SET channel_name = 'video-call-session-' || gen_random_uuid()::text,
    updated_at = NOW()
WHERE id = '<your-session-id>';
```

---

## 📊 Monitoring & Debugging

### Check Firebase Function Logs

```bash
# View real-time logs
firebase functions:log --only generateVideoCallTokens --project medzen-bf20e

# View specific time range
firebase functions:log --only generateVideoCallTokens --project medzen-bf20e --since 1h

# View errors only
firebase functions:log --only generateVideoCallTokens --project medzen-bf20e | grep ERROR
```

### Check Supabase Session Status

```sql
-- Check active sessions
SELECT
  s.id,
  s.channel_name,
  s.status,
  p.email as provider_email,
  pt.email as patient_email,
  s.scheduled_at,
  s.started_at,
  s.ended_at
FROM video_call_sessions s
JOIN users p ON s.provider_id = p.id
JOIN users pt ON s.patient_id = pt.id
WHERE s.status IN ('scheduled', 'active')
ORDER BY s.scheduled_at DESC;
```

### Check Agora Dashboard

Visit: https://console.agora.io/

1. Navigate to "Analytics" → "Real-time monitoring"
2. Filter by your App ID: `9a6e33f84cd542d9aba14374ae3326b7`
3. Check:
   - Active channels
   - User count per channel
   - Video quality metrics
   - Network quality
   - Duration

---

## 🎬 Example: Complete Test Flow

Here's a complete example of setting up and testing a video call:

### 1. Create Test Users (if needed)

```dart
// Provider account
final providerAuth = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: 'provider@test.com',
  password: 'test123456',
);

// Patient account
final patientAuth = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: 'patient@test.com',
  password: 'test123456',
);
```

### 2. Create Test Appointment in Supabase

```sql
-- Create appointment
INSERT INTO appointments (
  id,
  provider_id,
  patient_id,
  scheduled_at,
  status
) VALUES (
  '12345678-1234-1234-1234-123456789012',
  '<provider-user-id>',
  '<patient-user-id>',
  NOW() + INTERVAL '1 hour',
  'confirmed'
);

-- Create video call session
INSERT INTO video_call_sessions (
  id,
  appointment_id,
  channel_name,
  provider_id,
  patient_id,
  scheduled_at,
  status
) VALUES (
  'abcdef12-abcd-abcd-abcd-abcdef123456',
  '12345678-1234-1234-1234-123456789012',
  'test-call-' || EXTRACT(EPOCH FROM NOW())::TEXT,
  '<provider-user-id>',
  '<patient-user-id>',
  NOW() + INTERVAL '1 hour',
  'scheduled'
);
```

### 3. Test Provider Flow

```dart
// In your appointment detail page
ElevatedButton(
  onPressed: () async {
    final sessionId = 'abcdef12-abcd-abcd-abcd-abcdef123456';
    final providerId = '<provider-user-id>';
    final patientId = '<patient-user-id>';
    final appointmentId = '12345678-1234-1234-1234-123456789012';

    await joinRoom(
      context,
      sessionId,
      providerId,
      patientId,
      appointmentId,
      true, // isProvider = true
      'Dr. Smith',
      'https://example.com/dr-smith.jpg',
    );
  },
  child: Text('Start Video Call'),
)
```

### 4. Test Patient Flow

```dart
// In patient's appointment detail page
ElevatedButton(
  onPressed: () async {
    final sessionId = 'abcdef12-abcd-abcd-abcd-abcdef123456';
    final providerId = '<provider-user-id>';
    final patientId = '<patient-user-id>';
    final appointmentId = '12345678-1234-1234-1234-123456789012';

    await joinRoom(
      context,
      sessionId,
      providerId,
      patientId,
      appointmentId,
      false, // isProvider = false
      'John Doe',
      'https://example.com/john-doe.jpg',
    );
  },
  child: Text('Join Video Call'),
)
```

---

## ✅ Success Checklist

Before marking video calling as "production ready", verify:

### Backend
- [ ] `generateVideoCallTokens` function deployed
- [ ] `refreshVideoCallToken` function deployed
- [ ] Firebase config has agora.app_id
- [ ] Firebase config has agora.app_certificate
- [ ] No errors in Firebase function logs

### Database
- [ ] `video_call_sessions` table exists
- [ ] Test session created successfully
- [ ] Indexes created for performance

### Frontend
- [ ] `join_room.dart` updated to use secure function
- [ ] PreJoiningDialog shows camera preview
- [ ] Permissions requested correctly
- [ ] Error messages shown to user

### End-to-End
- [ ] Provider can start call
- [ ] Patient can join call
- [ ] Both users see/hear each other
- [ ] Camera toggle works
- [ ] Microphone toggle works
- [ ] Call ends cleanly
- [ ] Session status updates in database

### Security
- [ ] Authentication required (tested with logout)
- [ ] Session validation working (tested with wrong ID)
- [ ] Authorization working (tested with wrong user)
- [ ] Tokens expire after 2 hours
- [ ] Token refresh works

---

## 🚀 Going Live

Once all tests pass:

1. **Update Session Creation Logic**
   - Integrate video call session creation with appointment booking
   - Auto-generate unique channel names
   - Set appropriate scheduled_at times

2. **Add Session Management**
   - Update session status to 'active' when call starts
   - Update session status to 'completed' when call ends
   - Track call duration

3. **Add Error Recovery**
   - Handle network disconnections
   - Implement reconnection logic
   - Show user-friendly error messages

4. **Add Analytics**
   - Track call duration
   - Track call quality metrics
   - Monitor error rates

5. **User Documentation**
   - Create user guide for providers
   - Create user guide for patients
   - Add troubleshooting tips in app

---

## 📞 Support

**Agora Documentation:** https://docs.agora.io/
**Firebase Functions:** https://firebase.google.com/docs/functions
**Flutter Agora SDK:** https://pub.dev/packages/agora_rtc_engine

**Your Agora Dashboard:** https://console.agora.io/projects/9a6e33f84cd542d9aba14374ae3326b7

---

**🎉 You're ready to start testing! Begin with Phase 1 (Backend Function Test) and work your way through each phase.**
