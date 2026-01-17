# How to Fix Video Call Widget Error in FlutterFlow

**Error:** `Asset for key "assets/html/chime_meeting.html" not found`

**Root Cause:** FlutterFlow's cloud project still has references to the old `ChimeMeetingWebview` widget

## Steps to Fix in FlutterFlow UI

### 1. Remove Old Widget Reference

1. Open your project at https://app.flutterflow.io
2. Go to **Custom Code** → **Widgets** (left sidebar)
3. Look for `ChimeMeetingWebview` widget
4. If it exists, **delete it** or mark it as deprecated
5. Ensure only `ChimeMeetingEnhanced` is active

### 2. Update Pages Using Video Calls

Search for pages that might be using the old widget:

1. **Provider Landing Page** (`lib/medical_provider/provider_landing_page/`)
2. **Patient Landing Page** (`lib/patients_folder/patient_landing_page/`)
3. **Join Call Page** (`lib/home_pages/join_call/`)
4. **Appointments Pages** (any page with "Join Call" buttons)

For each page:
1. Click on the page in FlutterFlow
2. Find any **Custom Widget** components
3. If it's set to `ChimeMeetingWebview`:
   - Replace with `ChimeMeetingEnhanced`
   - OR remove it (video calls are handled by the `join_room` custom action)

### 3. Check Custom Actions

1. Go to **Custom Code** → **Actions**
2. Open `join_room` action
3. Verify it uses `ChimeMeetingEnhanced` (should be lines 444-454)
4. If FlutterFlow shows the old widget, update it to:

```dart
body: ChimeMeetingEnhanced(
  meetingData: jsonEncode(meetingData),
  attendeeData: jsonEncode(attendeeData),
  userName: userName ?? 'User',
  userProfileImage: profileImage,
  userRole: isProvider ? 'Doctor' : null,
  providerName: providerName,
  providerRole: providerRole ?? (isProvider ? 'Doctor' : null),
  onCallEnded: () async {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  },
)
```

### 4. Remove Asset References (if any)

1. Go to **Settings & Integrations** → **Assets**
2. Check if there's an `assets/html/` folder listed
3. If it exists, **remove it**
4. Verify only these asset folders are present:
   - `assets/fonts/`
   - `assets/images/`
   - `assets/videos/`
   - `assets/audios/`
   - `assets/rive_animations/`
   - `assets/pdfs/`
   - `assets/jsons/`

### 5. Clean FlutterFlow Cache

1. Click the **three dots menu** (top right)
2. Select **Clear Cache**
3. Wait for cache to clear
4. **Refresh the page** (Ctrl+R or Cmd+R)

### 6. Re-test

1. Click **Run** or **Test** in FlutterFlow
2. Error should be gone
3. If error persists, export code and test locally

## Alternative: Export and Test Locally

If the error still appears in FlutterFlow's Run/Test mode:

1. Click **Export Code**
2. Download the ZIP file
3. Extract it
4. Run locally:
   ```bash
   cd /path/to/extracted/code
   flutter clean
   flutter pub get
   adb uninstall mylestech.medzenhealth
   flutter run
   ```
5. Local build will work correctly (as we verified)

## Why This Happens

FlutterFlow stores your project configuration in the cloud. When you:
- **Export code** → Gets the current cloud configuration as Dart files
- **Run/Test** → Generates code on-the-fly from cloud configuration

If the cloud configuration still has the old widget, the Run/Test feature will fail even if your local code is correct.

## Verification

After fixing, verify in FlutterFlow:
1. Custom Code → Widgets → Only `ChimeMeetingEnhanced` exists
2. No pages use `ChimeMeetingWebview`
3. No `assets/html/` folder in Assets
4. Run/Test works without asset errors

## If Problem Persists

If you can't find the old widget references in FlutterFlow:

1. Contact FlutterFlow support: https://flutterflow.io/support
2. Ask them to check for orphaned widget references in your project
3. They can see backend configuration that might not be visible in the UI

Or alternatively, just use local development:
- Export code from FlutterFlow
- Test locally (works perfectly as verified)
- Deploy from local build (not FlutterFlow's deployment)
