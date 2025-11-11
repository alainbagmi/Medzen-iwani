# FlutterFlow PowerSync Configuration - Web Interface Guide

**Date**: 2025-10-31
**Project**: MedZen-Iwani (medzen-iwani-t1nrnu)
**Time Required**: 15-20 minutes
**Status**: Ready for Configuration ✅

---

## ✅ Pre-Configuration Checklist

Before starting, verify all code is in place:

```bash
# Check PowerSync core files
ls lib/powersync/
# Expected: database.dart, schema.dart, supabase_connector.dart ✅

# Check custom actions
ls lib/custom_code/actions/ | grep powersync
# Expected: initialize_powersync.dart, get_powersync_status.dart ✅

# Check FlutterFlow schema
ls powersync_flutterflow_schema.dart
# Expected: File exists ✅

# Verify backend ready
npx supabase secrets list | grep POWERSYNC_URL
# Expected: POWERSYNC_URL configured ✅
```

**All checks passed? Proceed to configuration!** 🚀

---

## Part 1: Open FlutterFlow Web Interface (2 min)

### Step 1: Access Your Project

1. Open browser and navigate to: **https://app.flutterflow.io/**
2. Login with your account (alainbagmi@gmail.com)
3. **Project List** → Click **"medzen-iwani"** project
4. Wait for project to fully load (~30-60 seconds)

**Visual Confirmation**: You should see the FlutterFlow editor with your app pages in the left sidebar

---

## Part 2: Configure PowerSync Library (10 min)

### Step 2: Navigate to Project Dependencies

1. Click **Settings & Integrations** icon (⚙️) in left sidebar
2. OR: Top menu → **Settings** → **Project Dependencies**
3. Look for **"FlutterFlow Libraries"** section (should be near bottom)

**What you're looking for**: A section titled "FlutterFlow Libraries" or "Libraries" with a list of available integrations

### Step 3: Find PowerSync Library

**Option A - If PowerSync is Listed:**
1. Scroll through the libraries list
2. Find **"PowerSync"** library
3. Click **"Configure"** or **"Add"** button

**Option B - If PowerSync is NOT Listed:**
1. Look for **"Add Library"** or **"+ Custom Library"** button
2. Click it
3. Search for "PowerSync"
4. Select **PowerSync** from results
5. Click **"Add to Project"**

### Step 4: Configure PowerSync Settings

Once PowerSync library configuration panel opens, you'll see several fields:

#### 4.1 PowerSync URL
```
Field: PowerSync Instance URL / PowerSync URL
Value: https://68f931403c148720fa432934.powersync.journeyapps.com
```

**Copy-paste exactly** (no trailing slash)

#### 4.2 Supabase URL
```
Field: Supabase URL / Backend URL
Value: https://noaeltglphdlkbflipit.supabase.co
```

**Copy-paste exactly** (no trailing slash)

#### 4.3 Enable Authentication
```
Field: Enable Auth / Authentication Enabled
Value: ✅ Checked / true
```

Toggle this ON or set to `true`

#### 4.4 Schema Definition (CRITICAL STEP)

**Field**: Schema / Database Schema / PowerSync Schema

**Action**: You'll see a large text box. You need to paste the entire schema from `powersync_flutterflow_schema.dart`

**Get the schema**:
```bash
# Open the schema file
cat powersync_flutterflow_schema.dart
```

**Or read it here** (I'll provide the content in the next section)

**IMPORTANT**:
- Select ALL content from the file
- Paste into the schema text box
- Do NOT modify the schema
- Ensure no formatting is lost

### Step 5: Save PowerSync Configuration

1. Scroll to bottom of PowerSync configuration panel
2. Click **"Save"** or **"Apply"** button
3. Wait for confirmation message: "PowerSync library configured successfully"
4. Close the configuration panel

**Troubleshooting**:
- If "Save" button is disabled → Check all required fields are filled
- If error "Invalid schema" → Verify you pasted the ENTIRE schema without modifications
- If error "Invalid URL" → Check URLs have no trailing slash and are exactly as shown above

---

## Part 3: Add PowerSync Initialization to Landing Pages (5 min)

You have 4 role-based landing pages that need PowerSync initialization. We'll add it to each one.

### Landing Pages to Update:
1. **Patient Landing Page**: `PatientHomePage` or `PatientLandingPage`
2. **Medical Provider Landing Page**: `MedicalProviderHomePage` or `ProviderLandingPage`
3. **Facility Admin Landing Page**: `FacilityAdminHomePage` or `AdminLandingPage`
4. **System Admin Landing Page**: `SystemAdminHomePage` or `SystemAdminLandingPage`

### For EACH Landing Page:

#### Step 6.1: Open the Landing Page

1. In FlutterFlow left sidebar, navigate to **Pages**
2. Find the landing page (e.g., "PatientHomePage")
3. Click to open it in the editor

#### Step 6.2: Add On Page Load Action

1. Select the **root widget** (usually Scaffold or Page)
2. In right sidebar, find **"Actions"** tab
3. Look for **"On Page Load"** section
4. Click **"+ Add Action"**

#### Step 6.3: Add Custom Action

1. In the action selector, choose **"Custom Action"**
2. From the dropdown, select **"initializePowerSync"**
3. **CRITICAL**: Set the **action order** correctly

**Action Order Must Be**:
```
On Page Load:
  1. Firebase Auth initialization (if present, leave as-is)
  2. Supabase initialization (if present, leave as-is)
  3. ⭐ initializePowerSync ← Add this HERE
  4. Other actions (any existing page logic)
```

**How to Set Order**:
- If you see numbers or arrows next to actions → Drag `initializePowerSync` to position 3
- If you see "Action Chain" → Place it AFTER Firebase and Supabase init
- If unclear → Use the "Order" or "Priority" field to set it to run 3rd

#### Step 6.4: Save the Page

1. Click **"Save"** in top-right corner
2. Wait for "Page saved successfully" message

#### Step 6.5: Repeat for Other Landing Pages

Repeat steps 6.1 - 6.4 for ALL FOUR landing pages:
- ✅ Patient Landing Page
- ✅ Medical Provider Landing Page
- ✅ Facility Admin Landing Page
- ✅ System Admin Landing Page

---

## Part 4: Verify Configuration (2 min)

### Step 7: Check PowerSync Library

1. Go back to **Settings** → **Project Dependencies**
2. Scroll to **"FlutterFlow Libraries"** section
3. Verify **PowerSync** is listed with status: **Configured** or **Active**

### Step 8: Check Custom Actions

1. In left sidebar, click **"Custom Code"** or **"Logic"**
2. Navigate to **"Actions"** tab
3. Verify these actions exist:
   - ✅ `initializePowerSync`
   - ✅ `getPowersyncStatus`

### Step 9: Check Landing Pages

For each landing page:
1. Open the page
2. Select root widget
3. Check **Actions** → **On Page Load**
4. Verify `initializePowerSync` is present and in correct order (after Firebase/Supabase init)

**All verified?** Configuration complete! ✅

---

## Part 5: Download and Test (5 min)

### Step 10: Download Updated Code

1. Top-right corner → Click **"Download Code"**
2. Select **"Flutter Project"**
3. Click **"Download"**
4. Wait for ZIP file to download

### Step 11: Extract and Verify

```bash
# Navigate to downloads
cd ~/Downloads

# Unzip the project
unzip medzen-iwani-export.zip

# Verify PowerSync is in dependencies (should already be there)
grep -A 5 "powersync" medzen-iwani-export/pubspec.yaml

# Expected: powersync dependency listed ✅
```

### Step 12: Copy FlutterFlow Changes (If Needed)

**IMPORTANT**: Only copy FlutterFlow-managed files, NOT custom code!

```bash
# Navigate to your project
cd ~/Desktop/medzen-iwani-t1nrnu

# Backup current state
cp -r lib/flutter_flow lib/flutter_flow.backup

# Copy ONLY FlutterFlow-managed files from export
# DO NOT overwrite: lib/powersync/, lib/custom_code/, supabase/, firebase/
```

**Safer Option**: Keep existing code and manually verify landing pages have the `initializePowerSync` action in FlutterFlow web interface

---

## Part 6: Test Offline Functionality (10 min)

### Step 13: Run the App

```bash
# From project directory
cd ~/Desktop/medzen-iwani-t1nrnu

# Install dependencies (if needed)
flutter pub get

# Run on Chrome for testing
flutter run -d chrome
```

### Step 14: Test Online Mode

1. **Sign Up New User**:
   - Email: test-powersync-001@example.com
   - Password: TestPass123!
   - Role: Patient

2. **Verify User Creation**:
   - Check Firebase Console → Authentication → Users
   - Check Supabase Dashboard → Table Editor → users
   - Check PowerSync Dashboard → Data Browser

3. **Create Test Data**:
   - Navigate to vital signs or medical records
   - Add a new record (e.g., Blood Pressure: 120/80)
   - Verify it appears immediately

### Step 15: Test Offline Mode

1. **Enable Airplane Mode**:
   - macOS: Control Center → Airplane Mode ON
   - OR: Disconnect WiFi and disable mobile data

2. **Verify Offline Icon**:
   - App should show "Offline" indicator
   - PowerSync status should show "Disconnected" but "Available"

3. **Create Offline Data**:
   - Add another vital signs record
   - App should accept it WITHOUT errors
   - Record stored locally in PowerSync SQLite

4. **Disable Airplane Mode**:
   - Turn off airplane mode / reconnect WiFi

5. **Verify Sync**:
   - Watch for sync indicator
   - Data should sync to Supabase automatically
   - Check Supabase Table Editor → vital_signs → New record appears

### Step 16: Verify EHRbase Sync Queue

```bash
# Check sync queue
npx supabase db remote query "SELECT * FROM ehrbase_sync_queue ORDER BY created_at DESC LIMIT 5"

# Expected: Records queued for EHRbase sync ✅
```

---

## Troubleshooting

### Issue: PowerSync Library Not Available in FlutterFlow

**Solution**:
- PowerSync might not be in the FlutterFlow libraries catalog
- Contact FlutterFlow support to request PowerSync library integration
- Alternative: Use custom code only (already implemented in `lib/powersync/`)

### Issue: "PowerSync not initialized" Error

**Causes**:
1. Action order incorrect → Ensure `initializePowerSync` runs AFTER Firebase & Supabase
2. Edge function not responding → Test: `curl https://noaeltglphdlkbflipit.supabase.co/functions/v1/powersync-token`
3. POWERSYNC_URL secret not set → Run: `npx supabase secrets list | grep POWERSYNC_URL`

**Fix**:
```bash
# Re-deploy edge function
npx supabase functions deploy powersync-token

# Verify secrets
npx supabase secrets list

# Check logs
npx supabase functions logs powersync-token
```

### Issue: Data Not Syncing

**Check**:
1. **PowerSync Status**: Call `getPowersyncStatus()` custom action
2. **Network Connectivity**: Verify internet connection
3. **Supabase Connection**: Check Supabase dashboard for activity
4. **Sync Queue**: Query `ehrbase_sync_queue` table

**Debug**:
```dart
// In FlutterFlow, add a debug button that calls:
final status = await getPowersyncStatus();
print('PowerSync Status: $status');
```

### Issue: Offline Mode Not Working

**Verify**:
1. PowerSync initialized successfully (check logs)
2. SQLite database created (should be in app data directory)
3. Custom actions using PowerSync `db` instance (not direct Supabase)

**Test**:
```bash
# Run with Flutter DevTools
flutter run -d chrome --dart-define=FLUTTER_WEB_USE_SKIA=true

# Check console for PowerSync logs:
# - "🚀 PowerSync initializing..."
# - "✅ PowerSync connected"
```

---

## Success Criteria

### ✅ Configuration Complete When:

1. **FlutterFlow Web**:
   - PowerSync library configured with correct URLs
   - All 4 landing pages have `initializePowerSync` action
   - Action order correct (Firebase → Supabase → PowerSync)

2. **App Runtime**:
   - App launches without errors
   - Console shows: "✅ Custom Action: PowerSync initialized successfully"
   - No "PowerSync not configured" errors

3. **Online Mode**:
   - User signup creates records in all 4 systems
   - Data written to PowerSync syncs to Supabase
   - EHRbase sync queue receives records

4. **Offline Mode**:
   - App works with airplane mode enabled
   - Data writes succeed locally
   - Sync occurs automatically when back online

---

## Quick Reference

### Configuration Values
```
PowerSync URL: https://68f931403c148720fa432934.powersync.journeyapps.com
Supabase URL: https://noaeltglphdlkbflipit.supabase.co
Enable Auth: true
```

### Custom Actions
```dart
initializePowerSync() // Returns: bool (success/failure)
getPowersyncStatus()  // Returns: Map (connection status)
```

### Landing Pages
```
Patient: PatientHomePage / PatientLandingPage
Provider: MedicalProviderHomePage / ProviderLandingPage
Facility Admin: FacilityAdminHomePage / AdminLandingPage
System Admin: SystemAdminHomePage / SystemAdminLandingPage
```

### Test Sequence
```
1. Sign up new user
2. Create record online
3. Enable airplane mode
4. Create record offline
5. Disable airplane mode
6. Verify sync
```

---

## Next Steps

After successful configuration:

1. ✅ Test all 4 user roles
2. ✅ Verify offline CRUD operations
3. ✅ Check EHRbase sync queue
4. ✅ Monitor PowerSync dashboard
5. ✅ Update production deployment docs

**Total Time**: ~25 minutes from start to fully functional offline app

---

## Documentation

**Related Files**:
- `POWERSYNC_AUTH_SIMPLIFIED.md` - Authentication approach explanation
- `FLUTTERFLOW_POWERSYNC_INTEGRATION_GUIDE.md` - Full integration guide
- `POWERSYNC_QUICK_START.md` - Quick reference
- `powersync_flutterflow_schema.dart` - Schema for FlutterFlow library

**Support**:
- FlutterFlow Docs: https://docs.flutterflow.io/
- PowerSync Docs: https://docs.powersync.com/
- Supabase Docs: https://supabase.com/docs

---

**Ready to configure? Let's do this!** 🚀
