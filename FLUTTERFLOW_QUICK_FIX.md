# FlutterFlow Quick Fix - 5 Minutes

**Problem:** Video call shows `Asset for key "assets/html/chime_meeting.html" not found` when running in FlutterFlow

**Cause:** FlutterFlow's cloud project has cached references to old widget

**Solution:** 3 Quick Steps

---

## Step 1: Delete Old Widget (2 minutes)

1. Go to https://app.flutterflow.io
2. Open your MedZen project
3. Click **Custom Code** → **Widgets** (left sidebar)
4. Find `ChimeMeetingWebview`
5. Click it → Click **Delete** → Confirm
6. Verify only `ChimeMeetingEnhanced` remains

## Step 2: Remove Asset Folder (1 minute)

1. Click **Settings** (gear icon) → **Assets**
2. Look for `assets/html/` folder
3. If found: Click trash icon → Confirm deletion
4. Should only have: fonts, images, videos, audios, pdfs, jsons folders

## Step 3: Clear Cache & Test (2 minutes)

1. Click **⋮** (three dots, top right) → **Clear Cache**
2. Refresh page (F5 or Ctrl+R)
3. Click **Run** or **Test**
4. Error should be gone ✅

---

## If Still Not Working

**Option A: Use Local Build (Confirmed Working)**
```bash
# Your local code is 100% clean (verified)
flutter clean
flutter pub get
adb uninstall mylestech.medzenhealth
flutter run
```

**Option B: Contact FlutterFlow Support**
- Go to: https://flutterflow.io/support
- Subject: "Old widget reference persists after deletion"
- Details: "ChimeMeetingWebview still referenced, need backend cleanup"

---

## Verification

After cleanup, check:
- ✅ No `ChimeMeetingWebview` in widget list
- ✅ No `assets/html/` in assets
- ✅ FlutterFlow Run shows no asset errors
- ✅ Local build works (already confirmed)

---

## Files Created for Reference

- `FLUTTERFLOW_CLEANUP_CHECKLIST.md` - Detailed step-by-step guide
- `verify_flutterflow_cleanup.sh` - Automated verification script
- `FIX_FLUTTERFLOW_VIDEO_WIDGET.md` - Complete technical guide

**Run verification:**
```bash
./verify_flutterflow_cleanup.sh
```

All checks pass ✅ - your local code is perfect!
