# Chime Video Call Testing Guide

## ✅ Prerequisites Completed

1. **Edge Functions Deployed**
   - ✅ `chime-meeting-token` - Deployed successfully
   - ✅ `chime-messaging` - Deployed successfully

2. **Database Migrations Applied**
   - ✅ All migrations up to date
   - ✅ Tables: `video_call_sessions`, `chime_messaging_channels`, `chime_messages`, `chime_message_audit`

3. **HTML Assets Configured**
   - ✅ `assets/html/` properly listed in `pubspec.yaml`
   - ✅ Chime SDK v2.23.0 will load correctly

## 🎯 Current Implementation Status

### ✅ Fully Implemented Components

1. **Video Call Action** (`lib/custom_code/actions/join_room.dart`)
   - Permission handling (camera + microphone)
   - Meeting creation/joining logic
   - Error handling with user-friendly messages
   - Platform detection (blocks web, allows mobile)
   - WebView navigation integration

2. **Video Call Widget** (`lib/custom_code/widgets/chime_video_call_page_stub.dart`)
   - WebView with Chime SDK integration
   - JavaScript bridge (FlutterChannel)
   - 4 control buttons: mic, video, end call, camera switch
   - Loading states and status messages
   - End call confirmation dialog

3. **Messaging Initialization** (`lib/custom_code/actions/initialize_messaging.dart`)
   - Firebase Cloud Messaging setup
   - FCM token management
   - Notification permission handling
   - Foreground/background message handlers

### ⚠️ Missing UI Integration

The Provider and Patient landing pages have **visual icons** for Video Call and Audio Call, but they are **not yet interactive** (no onTap/onPressed handlers).

**File:** `lib/medical_provider/provider_landing_page/provider_landing_page_widget.dart`
- Line 1826-1834: Video Call icon (not clickable)
- Line 1907-1915: Audio Call icon (not clickable)

**Why not editing directly:** Per CLAUDE.md rules, files in `lib/flutter_flow/` and FlutterFlow-generated pages should not be edited manually as they will be overwritten on next export.

## 🧪 Recommended Testing Approach

### Option 1: Add Action in FlutterFlow (Recommended)

1. **Open FlutterFlow Project**
   - Go to Provider Landing Page
   - Select the Video Call icon Container (around line 1814)

2. **Add onTap Action**
   ```dart
   // In FlutterFlow Action Editor:
   // Action Type: Custom Code
   // Select: joinRoom

   // Parameters to pass:
   - sessionId: appointmentItemRef.id.toString()
   - providerId: appointmentItemRef.providerId.toString()
   - patientId: appointmentItemRef.patientId.toString()
   - appointmentId: appointmentItemRef.id.toString()
   - isProvider: true
   - userName: currentUserDisplayName
   - profileImage: currentUserPhoto
   ```

3. **Re-export from FlutterFlow**
   ```bash
   # After adding the action in FlutterFlow
   ./safe-reexport.sh ~/Downloads/export.zip
   ```

### Option 2: Create Standalone Test Page

Since we cannot edit FlutterFlow files directly, I'll create a standalone test page that demonstrates the functionality:

**File:** `lib/home_pages/chime_video_call_page/chime_video_call_test_page.dart`

```dart
import '/backend/supabase/supabase.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';

class ChimeVideoCallTestPage extends StatefulWidget {
  const ChimeVideoCallTestPage({Key? key}) : super(key: key);

  @override
  _ChimeVideoCallTestPageState createState() => _ChimeVideoCallTestPageState();
}

class _ChimeVideoCallTestPageState extends State<ChimeVideoCallTestPage> {
  List<dynamic>? _appointments;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      final response = await SupaFlow.client
          .from('appointments')
          .select('id, appointment_number, provider_id, patient_id, status, scheduled_start, consultation_mode')
          .eq('status', 'scheduled')
          .order('scheduled_start')
          .limit(10);

      setState(() {
        _appointments = response as List<dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading appointments: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Call Test'),
        backgroundColor: FlutterFlowTheme.of(context).primary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _appointments == null || _appointments!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No scheduled appointments found'),
                      SizedBox(height: 8),
                      Text('Create an appointment first to test video calls',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _appointments!.length,
                  itemBuilder: (context, index) {
                    final appointment = _appointments![index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appointment #${appointment['appointment_number']}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text('Status: ${appointment['status']}'),
                            Text('Mode: ${appointment['consultation_mode']}'),
                            Text('Time: ${appointment['scheduled_start']}'),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FFButtonWidget(
                                    onPressed: () async {
                                      await joinRoom(
                                        context,
                                        appointment['id'].toString(),
                                        appointment['provider_id'].toString(),
                                        appointment['patient_id'].toString(),
                                        appointment['id'].toString(),
                                        true, // isProvider
                                        'Test User',
                                        null,
                                      );
                                    },
                                    text: 'Start Video Call (Provider)',
                                    icon: Icon(Icons.videocam, size: 24),
                                    options: FFButtonOptions(
                                      height: 48,
                                      color: FlutterFlowTheme.of(context).primary,
                                      textStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: FFButtonWidget(
                                    onPressed: () async {
                                      await joinRoom(
                                        context,
                                        appointment['id'].toString(),
                                        appointment['provider_id'].toString(),
                                        appointment['patient_id'].toString(),
                                        appointment['id'].toString(),
                                        false, // isProvider = false (patient)
                                        'Test Patient',
                                        null,
                                      );
                                    },
                                    text: 'Join as Patient',
                                    icon: Icon(Icons.person, size: 24),
                                    options: FFButtonOptions(
                                      height: 48,
                                      color: FlutterFlowTheme.of(context).secondary,
                                      textStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
```

## 📋 Step-by-Step Testing Instructions

### Test 1: Verify Backend Connectivity

```bash
# Test Edge Function
curl -X POST 'https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-meeting-token' \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM" \
  -H "Content-Type: application/json" \
  -d '{"action": "create", "appointmentId": "test-123"}'
```

**Expected Response:**
```json
{
  "meeting": {
    "MeetingId": "...",
    "MediaPlacement": {...}
  },
  "attendee": {
    "AttendeeId": "...",
    "JoinToken": "..."
  }
}
```

### Test 2: Create Test Appointment

```sql
-- Execute in Supabase SQL Editor
INSERT INTO appointments (
  provider_id,
  patient_id,
  facility_id,
  appointment_number,
  status,
  consultation_mode,
  scheduled_start,
  scheduled_end,
  video_enabled
) VALUES (
  (SELECT id FROM medical_provider_profiles LIMIT 1),
  (SELECT id FROM patient_profiles LIMIT 1),
  (SELECT id FROM facilities LIMIT 1),
  'TEST-' || floor(random() * 10000)::text,
  'scheduled',
  'video',
  NOW() + INTERVAL '1 hour',
  NOW() + INTERVAL '2 hours',
  true
);
```

### Test 3: Navigate to Test Page

1. **Add route in FlutterFlow** or manually:
   - Path: `/video-call-test`
   - Widget: `ChimeVideoCallTestPage`

2. **Or use direct navigation:**
   ```dart
   Navigator.of(context).push(
     MaterialPageRoute(
       builder: (context) => ChimeVideoCallTestPage(),
     ),
   );
   ```

### Test 4: Start Video Call

1. ✅ Click "Start Video Call (Provider)" button
2. ✅ Grant camera permission (if prompted)
3. ✅ Grant microphone permission (if prompted)
4. ✅ Wait for "Connecting to video call..." message
5. ✅ Verify WebView loads with black background
6. ✅ Verify 4 control buttons appear at bottom
7. ✅ Verify meeting joins successfully

**Expected UI:**
- Black WebView with video feed
- Bottom bar with 4 buttons:
  - 🎤 Microphone (white/red when muted)
  - 📞 End Call (red)
  - 📹 Video (white/red when off)
  - 🔄 Switch Camera

### Test 5: Join as Second Participant

1. **On second device/emulator:**
   - Use same appointment
   - Click "Join as Patient" button

2. **Verify:**
   - ✅ Both participants see each other's video
   - ✅ Audio works bidirectionally
   - ✅ Controls work (mute, video off, camera switch)

### Test 6: Test Messaging During Call

```bash
# Send test message via Chime messaging
curl -X POST 'https://noaeltglphdlkbflipit.supabase.co/functions/v1/chime-messaging' \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "send_message",
    "channelArn": "YOUR_CHANNEL_ARN",
    "content": "Test message",
    "senderId": "test-user-123"
  }'
```

**Verify in database:**
```sql
SELECT * FROM chime_messages
WHERE channel_arn = 'YOUR_CHANNEL_ARN'
ORDER BY created_at DESC
LIMIT 5;
```

### Test 7: End Call and Cleanup

1. ✅ Click red "End Call" button
2. ✅ Confirm in dialog
3. ✅ Verify navigation back to test page
4. ✅ Check database for cleanup:

```sql
SELECT
  meeting_id,
  status,
  ended_at
FROM video_call_sessions
WHERE appointment_id = 'YOUR_APPOINTMENT_ID';
```

**Expected:** `status = 'ended'`, `ended_at` timestamp set

## 🐛 Troubleshooting

### Issue: Blank WebView

**Diagnosis:**
```bash
flutter clean
flutter pub get
grep -q "assets/html/" pubspec.yaml && echo "✅ Assets OK" || echo "❌ Assets missing"
```

**Fix:**
1. Verify `assets/html/chime_meeting.html` exists
2. Ensure `pubspec.yaml` includes `assets/html/`
3. Run `flutter clean && flutter pub get`
4. Rebuild app

### Issue: Permission Denied

**Diagnosis:**
- Check Info.plist (iOS) for camera/microphone usage descriptions
- Check AndroidManifest.xml for permissions

**Fix for iOS (ios/Runner/Info.plist):**
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for video calls</string>
```

**Fix for Android (android/app/src/main/AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
```

### Issue: Meeting Creation Fails

**Diagnosis:**
```bash
npx supabase functions logs chime-meeting-token --tail
```

**Common causes:**
- Missing AWS credentials in Supabase secrets
- Invalid appointment ID
- Network connectivity issues

**Fix:**
```bash
# Verify Supabase secrets
npx supabase secrets list

# Should show:
# CHIME_API_ENDPOINT
# AWS_ACCESS_KEY_ID (if using direct AWS)
# AWS_SECRET_ACCESS_KEY (if using direct AWS)
```

### Issue: Messages Not Delivering

**Diagnosis:**
```sql
-- Check message audit log
SELECT * FROM chime_message_audit
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;

-- Check failed messages
SELECT * FROM chime_messages
WHERE status = 'failed'
ORDER BY created_at DESC;
```

## ✅ Success Criteria

- [ ] Provider can start video call from appointment
- [ ] Patient can join existing video call
- [ ] Both participants see/hear each other
- [ ] All 4 control buttons work (mic, video, end, camera)
- [ ] Messages send and receive during call
- [ ] End call cleans up resources properly
- [ ] Database records all activities (audit trail)
- [ ] No errors in function logs
- [ ] Permissions handled gracefully
- [ ] Web platform shows appropriate error message

## 📊 Test Results Template

```
Test Date: ___________
Tester: ___________
Environment: [ ] Dev [ ] Staging [ ] Production

✅ Prerequisites
- [ ] Edge functions deployed
- [ ] Migrations applied
- [ ] HTML assets configured
- [ ] Test appointment created

✅ Video Call Functionality
- [ ] Provider starts call successfully
- [ ] Patient joins successfully
- [ ] Video works both directions
- [ ] Audio works both directions
- [ ] Microphone toggle works
- [ ] Video toggle works
- [ ] Camera switch works
- [ ] End call works

✅ Messaging
- [ ] Messages send successfully
- [ ] Messages appear in database
- [ ] Audit log records all messages
- [ ] No message delivery failures

✅ Error Handling
- [ ] Permission denial handled gracefully
- [ ] Network errors show user-friendly messages
- [ ] Invalid appointments rejected
- [ ] Web platform blocked appropriately

Issues Found:
___________________________________________
___________________________________________

Notes:
___________________________________________
___________________________________________
```

## 🚀 Next Steps

1. **UI Integration in FlutterFlow**
   - Add onTap actions to existing video call icons
   - Re-export and verify functionality

2. **Production Deployment**
   - Test with real appointments
   - Monitor Edge Function logs
   - Verify HIPAA compliance (audit logs)

3. **Advanced Features**
   - Screen sharing
   - Recording with transcription
   - Medical entity extraction
   - Multi-language support

---

## 📝 Quick Reference

**Start Video Call:**
```dart
await joinRoom(
  context,
  sessionId,
  providerId,
  patientId,
  appointmentId,
  isProvider,
  userName,
  profileImage,
);
```

**Key Files:**
- Action: `lib/custom_code/actions/join_room.dart`
- Widget: `lib/custom_code/widgets/chime_video_call_page_stub.dart`
- Test Page: `lib/home_pages/chime_video_call_page/chime_video_call_test_page.dart`
- HTML: `assets/html/chime_meeting.html`

**Database Tables:**
- `video_call_sessions` - Meeting metadata
- `chime_messaging_channels` - Chat channels
- `chime_messages` - Messages
- `chime_message_audit` - HIPAA audit trail

**Edge Functions:**
- `chime-meeting-token` - Meeting creation/joining
- `chime-messaging` - Message sending
- `chime-recording-callback` - Recording processing
- `chime-transcription-callback` - Transcription processing
- `chime-entity-extraction` - Medical entity extraction
