# 📱 FlutterFlow UI Setup Guide - Chime Video Calls

## ✅ VERIFIED AGAINST ACTUAL CODEBASE

This guide is based on actual analysis of:
- Provider Landing Page: `lib/medical_provider/provider_landing_page/provider_landing_page_widget.dart`
- Patient Landing Page: `lib/patients_folder/patient_landing_page/patient_landing_page_widget.dart`
- Custom Actions: `lib/custom_code/actions/index.dart` (verified exports)
- Custom Widgets: `lib/custom_code/widgets/index.dart` (verified exports)
- Database schema: `appointment_overview` view

---

## 🎯 OVERVIEW

You will add video call functionality to Provider and Patient landing pages by:
1. Making the existing video call icon interactive
2. Binding it to the `joinRoom` custom action
3. Adding conditional visibility for video appointments only
4. Initializing messaging on app start

**No code writing required** - all done in FlutterFlow visual editor.

---

## 📋 PREREQUISITES

Before starting, verify in FlutterFlow:

### ✅ Custom Actions Available
1. Go to **Custom Code** → **Actions**
2. Verify you see:
   - `joinRoom` ✓
   - `initializeMessaging` ✓

### ✅ Custom Widgets Available
1. Go to **Custom Code** → **Widgets**
2. Verify you see:
   - `ChimeVideoCallPageStub` ✓

### ✅ Data Source Has Required Fields
1. Go to **Provider Landing Page** or **Patient Landing Page**
2. Select the **Appointments ListView**
3. Check **Backend Query** or **Data Source**
4. Verify these fields are selected:
   - `appointment_id` (UUID)
   - `provider_id` (UUID)
   - `patient_id` (UUID)
   - `consultation_mode` (text)
   - `patient_fullname` (text)

If any are missing, add them to the SELECT clause.

---

## STEP 1: Add Video Call Action to Provider Landing Page

### 1.1 Locate the Video Call Icon

1. Open **Provider Landing Page** in FlutterFlow
2. In the **Widget Tree** (left panel), expand the Appointments ListView
3. Look for Container with **video_call icon** (it's already there - line 1814-1831 in code)
4. Select the **Container** wrapping the video_call icon

**Visual Identifier**:
- Icon: `Icons.video_call`
- Color: Primary color
- Background: Light gray container

### 1.2 Add On Tap Action

With the Container selected:

1. Go to **Properties Panel** (right side)
2. Scroll to **Actions** section
3. Click **+ Add Action** on **On Tap** event
4. Choose **Custom Code** → **Custom Action**
5. Select **joinRoom** from dropdown

### 1.3 Configure Parameters

Now you'll see parameter inputs. Fill them EXACTLY as shown:

| Parameter | Source Type | Value / Binding |
|-----------|-------------|-----------------|
| `context` | *Auto-filled* | (leave as-is) |
| `sessionId` | **Set from Variable** | Select: **ListView Item** → `appointmentId` |
| `providerId` | **Set from Variable** | Select: **ListView Item** → `providerId` |
| `patientId` | **Set from Variable** | Select: **ListView Item** → `patientId` |
| `appointmentId` | **Set from Variable** | Select: **ListView Item** → `appointmentId` |
| `isProvider` | **Specific Value** | Type: `true` (boolean) |
| `userName` | **Set from Variable** | Select: **Authenticated User** → `displayName` |
| `profileImage` | **Set from Variable** | Select: **Authenticated User** → `photoUrl` |

**Critical Notes**:
- `appointmentId` appears TWICE (for `sessionId` and `appointmentId` params)
- `isProvider` must be boolean `true` (not string "true")
- If `displayName` or `photoUrl` don't exist, use `email` for userName

### 1.4 Save Changes

1. Click **Confirm** to close parameter dialog
2. FlutterFlow will validate the action
3. If errors appear, check parameter types match exactly

---

## STEP 2: Add Conditional Visibility (Provider Page)

**Why**: Only show video call icon for online/video appointments

### 2.1 Add Condition

With the same Container selected:

1. In **Properties Panel**, find **Conditional Visibility** section
2. Toggle **ON** (enable conditional visibility)
3. Click **+ Add Condition**

### 2.2 Configure Condition

Set up the condition:

1. **Field**: Select **ListView Item** → `consultationMode`
2. **Operator**: Select **Equals (==)**
3. **Value Type**: Select **Specific Value**
4. **Value**: Type `Online` (case-sensitive)

### 2.3 Add Alternative Condition (Optional)

If appointments can also have `consultation_mode = 'video'`:

1. Click **Add Condition** again (creates OR logic)
2. **Field**: **ListView Item** → `consultationMode`
3. **Operator**: **Equals (==)**
4. **Value**: `video`

**Result**: Icon shows if `consultationMode` is `'Online'` OR `'video'`

---

## STEP 3: Add Video Call Action to Patient Landing Page

**Repeat Step 1 and Step 2, but with ONE critical difference:**

### 3.1 Locate Video Call Icon in Patient Page

1. Open **Patient Landing Page**
2. Find the Appointments ListView
3. Locate the video call icon Container (or add one if missing)

**If icon doesn't exist**, add it:
1. Inside ListView item, add **Container**
2. Add **Icon** widget inside Container
3. Set icon to `Icons.video_call`
4. Style to match Provider page

### 3.2 Add On Tap Action

Same as Step 1.2, select **joinRoom** custom action.

### 3.3 Configure Parameters

**IMPORTANT**: Same as Step 1.3, but with ONE CHANGE:

| Parameter | Source Type | Value / Binding |
|-----------|-------------|-----------------|
| `context` | *Auto-filled* | (leave as-is) |
| `sessionId` | **Set from Variable** | Select: **ListView Item** → `appointmentId` |
| `providerId` | **Set from Variable** | Select: **ListView Item** → `providerId` |
| `patientId` | **Set from Variable** | Select: **ListView Item** → `patientId` |
| `appointmentId` | **Set from Variable** | Select: **ListView Item** → `appointmentId` |
| `isProvider` | **Specific Value** | **`false`** ← THIS IS DIFFERENT! |
| `userName` | **Set from Variable** | Select: **Authenticated User** → `displayName` |
| `profileImage` | **Set from Variable** | Select: **Authenticated User** → `photoUrl` |

**Critical**: `isProvider = false` for patients!

### 3.4 Add Conditional Visibility

Same as Step 2 - show only for `consultationMode = 'Online'` or `'video'`

---

## STEP 4: Initialize Messaging on App Start

**Why**: Firebase Cloud Messaging (FCM) must initialize when app launches

### Option A: Using App Settings (Recommended)

1. Go to **App Settings** (gear icon in FlutterFlow)
2. Find **App State Management** or **Lifecycle Hooks**
3. Look for **On App Start** or **Initialize App** section
4. Click **+ Add Action**
5. Select **Custom Code** → **Custom Action** → **initializeMessaging**
6. No parameters needed (context is auto-provided)
7. Save

### Option B: On Initial Page Load

If Option A doesn't exist:

1. Open your **initial page** (usually SignIn or Splash screen)
2. Select the **Page** (not a widget, the page itself in widget tree)
3. Go to **Page Lifecycle** section
4. Find **On Page Load** actions
5. Click **+ Add Action**
6. Select **Custom Code** → **Custom Action** → **initializeMessaging**
7. Save

**Important**: This should run ONCE when app first launches, not on every page navigation.

---

## STEP 5: Export from FlutterFlow (Critical Step)

### 5.1 Download Code

1. In FlutterFlow, click **Download Code** (top-right)
2. Choose **Flutter Project** (not Web-only or Mobile-only)
3. Wait for export to complete
4. Download zip file to `~/Downloads/`

### 5.2 DO NOT Extract Manually

**STOP!** Do not unzip and copy files manually. Custom code will be overwritten.

---

## STEP 6: Safe Merge with Existing Code

### 6.1 Use Safe Re-export Script

```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu

# Run safe merge (preserves custom code)
./safe-reexport.sh ~/Downloads/export.zip
```

**What this does**:
- ✅ Merges FlutterFlow-managed files (pages, components)
- ✅ Preserves ALL custom code files
- ✅ Keeps `assets/html/chime_meeting.html` intact
- ✅ Protects `pubspec.yaml` assets section
- ✅ Maintains git history

### 6.2 Verify Merge Success

After merge, run these checks:

```bash
# Check assets configuration (CRITICAL)
grep -q "assets/html/" pubspec.yaml && echo "✅ Assets OK" || echo "❌ VIDEO WILL FAIL!"

# Check custom files exist
ls -la lib/custom_code/actions/join_room.dart
ls -la lib/custom_code/widgets/chime_video_call_page_stub.dart
ls -la assets/html/chime_meeting.html
```

**All 4 checks must pass** before proceeding.

---

## STEP 7: Build and Test

### 7.1 Clean Build

```bash
flutter clean
flutter pub get
```

### 7.2 Run on Device

```bash
# iOS Simulator
flutter run -d "iPhone 15 Pro"

# Android Emulator
flutter run -d emulator-5554

# Physical device (list devices first)
flutter devices
flutter run -d [device-id]
```

**Do NOT test on web** - video calls are mobile-only.

### 7.3 Navigate to Test Page (Quick Test)

**Recommended**: Use the dedicated test page first.

Add this temporary button somewhere in your app:

```dart
FFButtonWidget(
  onPressed: () {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ChimeVideoCallTestPage()
    ));
  },
  text: 'Test Video Calls',
)
```

Or navigate directly in code:
```dart
context.pushNamed('ChimeVideoCallTestPage');
```

### 7.4 Test Full Flow

**On Test Page:**

1. You'll see list of scheduled video-enabled appointments
2. Click **"Start as Provider"** button
3. Expected behavior:
   - Camera permission dialog appears → Grant
   - Microphone permission dialog appears → Grant
   - "Connecting to video call..." message
   - WebView loads with black background
   - 4 control buttons appear at bottom: 🎤 📞 📹 🔄
   - Video feed starts within 5 seconds

**On Provider/Patient Landing Pages:**

1. Navigate to Provider Landing Page
2. Find an appointment with `consultation_mode = 'Online'`
3. Tap the video call icon
4. Same expected behavior as above

### 7.5 Two-Device Test

**Device 1 (Provider):**
1. Login as provider
2. Tap video call icon on appointment

**Device 2 (Patient):**
1. Login as patient
2. Tap video call icon on SAME appointment
3. Both devices should see/hear each other

---

## 🐛 TROUBLESHOOTING

### Issue: Video Call Icon Not Appearing

**Diagnosis**:
1. Check appointment in database has `consultation_mode = 'Online'` or `'video'`
2. Verify conditional visibility is configured correctly
3. Check FlutterFlow query includes `consultation_mode` field

**Quick Fix**: Temporarily remove conditional visibility to test

### Issue: "Video calling is currently only available on mobile devices"

**Cause**: Running on web (Chrome, Safari, Firefox)

**Fix**:
- Use iOS Simulator: `flutter run -d "iPhone 15 Pro"`
- Or Android Emulator: `flutter run -d emulator-5554`
- Or physical device

### Issue: Permission Dialogs Don't Appear

**iOS Fix** - Edit `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for video calls</string>
```

**Android Fix** - Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

Then rebuild: `flutter clean && flutter run`

### Issue: Blank WebView / Black Screen Forever

**Diagnosis**:
```bash
grep -q "assets/html/" pubspec.yaml && echo "✅ OK" || echo "❌ Assets missing"
```

**Fix if assets missing**:
1. Verify `assets/html/chime_meeting.html` exists
2. Open `pubspec.yaml`
3. Add under `flutter:` section:
   ```yaml
   assets:
     - assets/html/
   ```
4. Run: `flutter clean && flutter pub get`
5. Rebuild

### Issue: "Failed to start video call" / Network Error

**Check Edge Function logs**:
```bash
npx supabase functions logs chime-meeting-token --tail
```

**Common causes**:
- Invalid appointment ID (not UUID format)
- Missing Supabase secret: `CHIME_API_ENDPOINT`
- AWS Lambda function error
- Network connectivity issue

**Fix secrets**:
```bash
# Verify secrets exist
npx supabase secrets list

# Set if missing
npx supabase secrets set CHIME_API_ENDPOINT="https://your-api-endpoint.execute-api.eu-west-1.amazonaws.com"

# Re-deploy function
npx supabase functions deploy chime-meeting-token
```

### Issue: "appointmentId is null" or Parameter Binding Error

**Diagnosis in FlutterFlow**:
1. Select the **joinRoom action**
2. View **Action Output Panel** (bottom)
3. For each parameter, check:
   - Source Type is correct (ListView Item, Authenticated User, Specific Value)
   - Field name matches exactly (case-sensitive!)
   - Preview shows actual data (not "null" or empty)

**Common mistakes**:
- Using `id` instead of `appointmentId` (field names must match database)
- Mixing up provider/patient IDs
- Wrong source type selected

---

## ✅ VERIFICATION CHECKLIST

After completing all steps, verify:

- [ ] Video call icon visible on Provider Landing Page (for video appointments only)
- [ ] Video call icon visible on Patient Landing Page (for video appointments only)
- [ ] Icon hidden for non-video appointments (In-Person, Phone)
- [ ] Tapping icon shows camera permission prompt
- [ ] Tapping icon shows microphone permission prompt
- [ ] After granting permissions, WebView loads (not blank)
- [ ] 4 control buttons appear (mic, video, end, camera)
- [ ] Video feed starts within 5 seconds
- [ ] Audio works bidirectionally (both hear each other)
- [ ] End call confirmation dialog works
- [ ] After ending, navigates back to landing page
- [ ] Database `video_call_sessions` table updates
- [ ] Edge Function logs show success (no errors)
- [ ] `flutter analyze` shows no errors

---

## 📊 EXPECTED DATABASE RECORDS

After successful video call, check in Supabase SQL Editor:

```sql
-- Verify meeting was created
SELECT
  id,
  meeting_id,
  status,
  provider_id,
  patient_id,
  started_at,
  ended_at
FROM video_call_sessions
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 5;
```

**Expected results**:
- `meeting_id`: Populated with AWS Chime meeting ID
- `status`: `'active'` during call, `'ended'` after
- `started_at`: Timestamp when call started
- `ended_at`: Timestamp when call ended (null if still active)

---

## 🎯 NEXT STEPS

### Immediate (Testing)
1. ✅ Complete Steps 1-4 in FlutterFlow UI
2. ✅ Export and merge (Steps 5-6)
3. ✅ Test video call functionality (Step 7)
4. ✅ Verify checklist above

### Short-term (Production Integration)
1. Add error logging to `joinRoom` action
2. Implement retry logic for network failures
3. Add analytics tracking (call duration, success rate)
4. Monitor Edge Function logs in production

### Long-term (Enhancements)
1. Add screen sharing functionality
2. Implement recording with transcription
3. Add medical entity extraction from conversations
4. Build analytics dashboard
5. Multi-language support for transcriptions

---

## 💡 QUICK REFERENCE

**Start a video call (Provider)**:
```dart
await joinRoom(
  context,
  appointmentId.toString(),  // sessionId
  providerId.toString(),
  patientId.toString(),
  appointmentId.toString(),  // appointmentId
  true,                      // isProvider
  currentUserDisplayName,
  currentUserPhoto,
);
```

**Start a video call (Patient)**:
```dart
await joinRoom(
  context,
  appointmentId.toString(),  // sessionId
  providerId.toString(),
  patientId.toString(),
  appointmentId.toString(),  // appointmentId
  false,                     // isProvider ← KEY DIFFERENCE
  currentUserDisplayName,
  currentUserPhoto,
);
```

**Navigate to Test Page**:
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => ChimeVideoCallTestPage(),
  ),
);
```

---

## 📚 RELATED DOCUMENTATION

- **Technical Implementation**: `CHIME_IMPLEMENTATION_COMPLETE.md`
- **Testing Guide**: `CHIME_VIDEO_TESTING_GUIDE.md`
- **Production Readiness**: `/Users/alainbagmi/.claude/plans/flickering-napping-pearl.md`
- **System Integration**: `4_SYSTEM_INTEGRATION_SUMMARY.md`

---

## ✅ SUCCESS CRITERIA

You'll know the setup is complete when:

1. ✓ Provider can start video call from landing page
2. ✓ Patient can join video call from landing page
3. ✓ Both participants see and hear each other
4. ✓ All control buttons work (mute, video toggle, end call)
5. ✓ Database updates correctly
6. ✓ No errors in Edge Function logs
7. ✓ Video call ends cleanly and navigates back

**Questions or Issues?**
- Check Troubleshooting section above
- Review Edge Function logs: `npx supabase functions logs chime-meeting-token`
- Test with dedicated test page first before production pages
