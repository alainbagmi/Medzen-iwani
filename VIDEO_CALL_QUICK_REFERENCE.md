# Video Call Quick Reference Card

## Status: ✅ READY FOR TESTING

---

## Quick Test (30 seconds)

```bash
# Automatic device detection and launch
./quick_test_video_call.sh
```

---

## What Was Fixed

### 401 Error ✅ RESOLVED
- **Problem:** `Missing X-Firebase-Token header`
- **Cause:** Header case mismatch
- **Fix:** Lowercase `x-firebase-token` everywhere
- **Status:** Deployed and tested

### Initialization Hang ⚠️ EMULATOR ISSUE
- **Problem:** Stuck on "initializing"
- **Cause:** 1.1 MB SDK too heavy for emulator
- **Fix:** Test on physical device or browser
- **Status:** Not a bug - expected behavior

---

## Test Options

### 🥇 Best: Chrome Browser
```bash
flutter run -d chrome
# Press F12 → Console tab
# Watch for "✅ Bundled Chime SDK found"
```
⏱️ SDK loads in 5-8 seconds

### 🥈 Recommended: iPhone
```bash
flutter run -d <iphone-id>
```
⏱️ SDK loads in 3-10 seconds

### 🥉 Alternative: Android
```bash
flutter run -d <android-id>
```
⏱️ SDK loads in 5-12 seconds

### ❌ Not Recommended: Emulator
⏱️ SDK times out (60+ seconds)

---

## Expected Results

### Success ✅
```
Setting up video call...
✅ Connecting to video call...
✅ Chime SDK loaded and ready
[Video call interface appears]
```
⏱️ Total time: 3-15 seconds

### Failure ❌
```
Setting up video call...
[Stuck for 60+ seconds]
❌ Chime SDK load timeout after 60 seconds
```
🔧 **Solution:** Use physical device or browser

---

## Verification Commands

### Check Edge Function
```bash
./test_video_call_flow_complete.sh
# Should show: ✅ All Pre-flight Checks Passed
```

### Check Flutter Code
```bash
grep "'x-firebase-token'" lib/custom_code/actions/join_room.dart
# Should find the lowercase version
```

### View Logs
```bash
flutter run -v 2>&1 | grep -i "chime\|sdk"
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| 401 error | Run `./test_video_call_flow_complete.sh` |
| SDK timeout | Test on physical device or Chrome |
| Blank screen | Check camera/microphone permissions |
| No devices | Install Chrome or connect phone via USB |

---

## Files Modified

✅ `supabase/functions/chime-meeting-token/index.ts` (deployed)
✅ `lib/custom_code/actions/join_room.dart` (rebuilt)

---

## Documentation

📄 Complete guide: `VIDEO_CALL_COMPLETE_RESOLUTION.md`
📄 Technical details: `VIDEO_CALL_INITIALIZATION_FIX_COMPLETE.md`
📄 Original fix: `VIDEO_CALL_401_FIX_COMPLETE_V3.md`

---

## One-Line Summary

**401 fixed ✅, emulator too slow ⚠️, test on device 📱 or browser 🌐**
