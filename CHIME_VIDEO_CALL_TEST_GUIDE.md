# Chime Video Call Testing Guide

## Status: ✅ All Implementation Complete - Ready for Testing

All three blockers have been resolved:
1. ✅ 401 Authentication Error - JWT token properly passed to Edge Function
2. ✅ Missing HTML File - Complete Chime SDK implementation created (315 lines)
3. ✅ Missing Asset Declaration - pubspec.yaml updated with `assets/html/`

---

## Pre-Testing Setup

### 1. Apply Asset Changes
```bash
# Navigate to project root
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Clean cached assets
flutter clean

# Apply pubspec.yaml changes
flutter pub get

# Verify HTML asset is declared
grep -q "assets/html/" pubspec.yaml && echo "✅ Assets OK" || echo "❌ Assets missing!"
```

### 2. Rebuild Application
```bash
# For iOS
flutter build ios --debug

# For Android
flutter build apk --debug

# Or run directly on connected device
flutter run -d <device-id>

# List available devices
flutter devices
```

### 3. Verify Backend Services

**Check Supabase Edge Function:**
```bash
# Ensure chime-meeting-token function is deployed
npx supabase functions list

# View recent logs
npx supabase functions logs chime-meeting-token --tail
```

**Verify Authentication:**
- User must be logged into the app
- Valid Firebase + Supabase session required
- JWT token will be automatically retrieved from `SupaFlow.client.auth.currentSession`

---

## Test Environment Requirements

### ⚠️ Critical: Physical Device Required
- **iOS Simulator/Android Emulator will NOT work** - camera/microphone access is limited
- Use a physical iPhone or Android device
- Connect via USB or wireless debugging

### Network Requirements
- Active internet connection
- Access to AWS Chime SDK endpoints
- Access to Supabase Edge Functions (https://noaeltglphdlkbflipit.supabase.co)

### Database Requirements
- Valid appointment record in `appointments` table
- Appointment must have:
  - `id` (appointment UUID)
  - `provider_id` (provider UUID)
  - `patient_id` (patient UUID)
  - `status` = 'scheduled' or 'confirmed'

---

## Testing Steps

### Phase 1: Permission Flow Testing

1. **First-time Permission Request**
   - Launch app and navigate to appointment/consultation page
   - Tap "Join Video Call" or equivalent button
   - **Expected**: App requests camera permission
   - **Action**: Grant permission
   - **Expected**: App requests microphone permission
   - **Action**: Grant permission
   - **Watch console for**: `[Chime] Setting up devices...`

2. **Permission Denial Testing**
   - If permissions denied initially, app should show dialog
   - **Expected**: "Permissions Required" AlertDialog
   - **Action**: Tap "Open Settings"
   - **Expected**: Navigate to iOS Settings or Android App Info
   - Enable Camera and Microphone permissions manually
   - Return to app and retry

3. **iOS Simulator Warning**
   - If testing on simulator (not recommended)
   - **Expected**: Orange snackbar with simulator limitation message
   - Message should read: "⚠️ Video calls require camera and microphone access. iOS Simulator has known issues..."

### Phase 2: Meeting Creation/Join Flow

1. **Provider Creates Meeting**
   - Log in as Provider
   - Navigate to scheduled appointment
   - Tap "Start Video Call" button
   - **Watch console for**:
     ```
     === Chime Meeting Action: create ===
     Appointment ID: <uuid>
     Existing Meeting ID: null
     Role: Provider
     ```
   - **Expected**: Loading snackbar "Setting up video call..."
   - **Expected**: Success snackbar "✅ Connecting to video call..."
   - **Expected**: Navigate to video call page

2. **Patient Joins Meeting**
   - Log in as Patient (on different device)
   - Navigate to same appointment
   - Tap "Join Video Call" button
   - **Watch console for**:
     ```
     === Chime Meeting Action: join ===
     Appointment ID: <uuid>
     Existing Meeting ID: <meeting-uuid>
     Role: Patient
     ```
   - **Expected**: Join existing meeting (not create new)

### Phase 3: Video Call Interface Testing

1. **Chime SDK Initialization**
   - After navigation, WebView should load
   - **Watch console for** (in order):
     ```
     [Chime] HTML loaded and ready
     [Chime] Initializing meeting session...
     [Chime] Meeting ID: <meeting-uuid>
     [Chime] Attendee ID: <attendee-uuid>
     [Chime] Setting up devices...
     [Chime] Selected audio input: <device-name>
     [Chime] Selected video input: <device-name>
     [Chime] Selected audio output: <device-name>
     [Chime] Devices configured successfully
     [Chime] Audio-video session started
     ```

2. **Video Tile Verification**
   - **Local Video (small overlay, top-right)**:
     ```
     [Chime] Video tile updated: <tile-id>
     [Chime] Bound local video tile: <tile-id>
     ```
     - Should show your own camera feed
     - 150x200px size
     - Rounded corners with white border
     - Positioned top-right corner

   - **Remote Video (full screen)**:
     ```
     [Chime] Video tile updated: <tile-id>
     [Chime] Bound remote video tile: <tile-id>
     ```
     - Should show other participant when they join
     - Full screen, object-fit: cover
     - Appears behind local video

3. **Status Indicator**
   - Top-left corner, should show:
     - "Connecting..." (initially)
     - "Initializing..." (during setup)
     - "Joining meeting..." (before start)
     - "Connected" (when session starts, green text)
     - Any errors in red text

### Phase 4: Control Button Testing

**Note**: Control buttons are implemented in `ChimeVideoCallPageStub` widget, not in HTML. Test the following:

1. **Mute/Unmute Audio**
   - Tap microphone button
   - **Expected**: `[Chime] Audio muted`
   - Tap again
   - **Expected**: `[Chime] Audio unmuted`

2. **Toggle Video On/Off**
   - Tap video button
   - **Expected**: `[Chime] Video stopped`
   - Local video tile should disappear
   - Tap again
   - **Expected**: `[Chime] Video started`
   - Local video tile should reappear

3. **Switch Camera** (if device has multiple cameras)
   - Tap camera switch button
   - **Expected**: `[Chime] Switched to camera: <device-name>`
   - Local video should flip between front/back camera

4. **Leave Meeting**
   - Tap leave/end call button
   - **Expected**:
     ```
     [Chime] Leaving meeting...
     [Chime] Audio-video session stopped: <status>
     [Flutter] MEETING_LEFT
     ```
   - Navigate back to previous screen

### Phase 5: Error Scenarios Testing

1. **Network Disconnection**
   - During active call, disable WiFi/cellular
   - **Expected**: Chime SDK should handle gracefully
   - **Watch for**: `audioVideoDidStop` callback triggered

2. **Invalid Appointment ID**
   - Call `join_room` with non-existent appointment
   - **Expected**: Edge Function returns 404 error
   - **Expected**: Red snackbar "❌ Video call session not found"

3. **Unauthenticated User**
   - Log out user
   - Try to join video call
   - **Expected**: Exception "User not authenticated"
   - **Expected**: Red snackbar "❌ Please log in to start a video call"

4. **Edge Function Failure**
   - If Edge Function returns error
   - **Expected**: Red snackbar with specific error message
   - **Watch console for**: Stack trace and error details

---

## Expected Console Log Patterns

### Successful Flow (Complete)
```
=== Permission Status Check START ===
✓ Camera status retrieved
✓ Microphone status retrieved
Camera isGranted: true
Microphone isGranted: true
=== Permission Status Check END ===

=== Chime Meeting Action: create ===
Appointment ID: 288597e5-6c1e-46ef-9e4c-2c298671d569
Existing Meeting ID: null
Role: Provider

=== Chime Meeting Created/Joined ===
Meeting ID: 12345678-1234-1234-1234-123456789012
Attendee ID: abcdef12-3456-7890-abcd-ef1234567890
===================================

[Chime] HTML loaded and ready
[Chime] Initializing meeting session...
[Chime] Meeting ID: 12345678-1234-1234-1234-123456789012
[Chime] Attendee ID: abcdef12-3456-7890-abcd-ef1234567890
[Chime] Setting up devices...
[Chime] Selected audio input: iPhone Microphone
[Chime] Selected video input: Front Camera
[Chime] Selected audio output: Speaker
[Chime] Devices configured successfully
[Chime] Audio-video session started
[Chime] Video tile updated: 1
[Chime] Bound local video tile: 1
[Chime] Video tile updated: 2
[Chime] Bound remote video tile: 2
[Flutter] MEETING_JOINED
```

### Error Patterns to Watch For

**Permission Denied:**
```
ERROR checking camera isGranted: <error>
❌ Camera and microphone permissions are required for video calls
```

**Authentication Failure:**
```
Error setting up video call: Exception: User not authenticated
❌ Please log in to start a video call
```

**Edge Function Error:**
```
Error setting up video call: FunctionException(status: 401, details: {error: Invalid or expired token})
❌ Please log in to start a video call
```

**Asset Loading Failure:**
```
[ERROR:flutter/runtime/dart_vm_initializer.cc(41)]
Failed to load asset: assets/html/chime_meeting.html
```
If this occurs, run `flutter clean && flutter pub get` and rebuild.

---

## Debugging Tips

### 1. Enable Verbose Logging
```dart
// In join_room.dart, all debug logs are already present
// Look for debugPrint() statements in console
```

### 2. Monitor Supabase Edge Function
```bash
# Real-time function logs
npx supabase functions logs chime-meeting-token --tail

# Look for authentication errors or missing parameters
```

### 3. WebView JavaScript Console
- iOS: Connect device to Mac, use Safari Web Inspector
- Android: Use Chrome DevTools remote debugging
- Navigate to: chrome://inspect#devices

### 4. Check Video Call Sessions Table
```sql
-- Verify meeting records are created
SELECT
  meeting_id,
  appointment_id,
  status,
  created_at
FROM video_call_sessions
ORDER BY created_at DESC
LIMIT 5;
```

### 5. Verify Chime SDK Version
The HTML file uses Amazon Chime SDK v0.23.0:
```html
<script src="https://static.sdkassets.chime.aws/amazon-chime-sdk-js/0.23.0/amazon-chime-sdk.min.js"></script>
```

---

## Common Issues & Solutions

| Issue | Symptoms | Solution |
|-------|----------|----------|
| **Blank WebView** | WebView loads but shows nothing | Run `flutter clean && flutter pub get`, verify `assets/html/` in pubspec.yaml |
| **Permission Dialog Not Appearing** | iOS Simulator limitation | **Must test on physical device** |
| **401 Authentication Error** | Edge Function returns 401 | Verify user is logged in, check JWT token retrieval |
| **No Remote Video** | Only local video shows | Verify other participant has joined, check network connectivity |
| **Audio Not Working** | Video works but no audio | Check device audio output, verify audioOutputDevice selection |
| **Camera Not Switching** | Switch button doesn't work | Verify device has multiple cameras (front/back) |
| **Meeting Not Found** | 404 error when joining | Provider must create meeting first, verify appointment_id is correct |

---

## Success Criteria

✅ **Video Call is Working When:**
1. Permissions granted without errors
2. Console shows complete Chime SDK initialization sequence
3. Local video tile displays your camera feed (top-right overlay)
4. Remote video tile displays other participant (full screen)
5. Status shows "Connected" in green
6. Mute/unmute audio works with console confirmation
7. Video on/off toggle works with visual feedback
8. Camera switch works on devices with multiple cameras
9. Leave meeting cleanly exits and navigates back
10. No red error messages in status or snackbars

---

## Next Steps After Testing

### If Testing Succeeds:
- Document any user experience improvements needed
- Consider adding UI controls for audio/video level indicators
- Plan for recording feature if needed
- Test with multiple participants (3+)

### If Testing Fails:
- Capture complete console logs (both Flutter and WebView JavaScript)
- Note exact error messages and reproduction steps
- Check Supabase Edge Function logs for backend errors
- Verify all environment variables are set correctly
- Share error logs for debugging

---

## File Locations Reference

- **Main Action**: `/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/lib/custom_code/actions/join_room.dart`
- **HTML Interface**: `/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/assets/html/chime_meeting.html`
- **Asset Config**: `/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/pubspec.yaml` (line 213: `- assets/html/`)
- **Widget Stub**: `/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/lib/custom_code/widgets/chime_video_call_page_stub.dart`

---

## Questions or Issues?

If you encounter any issues during testing:
1. Capture full console output
2. Note exact reproduction steps
3. Check Supabase Edge Function logs
4. Verify WebView JavaScript console (Safari/Chrome DevTools)
5. Share error messages for troubleshooting
