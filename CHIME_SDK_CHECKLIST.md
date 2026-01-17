# Chime SDK - Quick Verification Checklist

**Use this checklist to ensure Chime SDK loads properly**

---

## 📋 Pre-Flight Checklist (Before Every Deploy)

### 1️⃣ Assets Configuration

```bash
# Command to run:
grep -A 5 "flutter:" pubspec.yaml | grep "assets/js/"
```

- [ ] **MUST SEE:** `- assets/js/` in output
- [ ] If not present, add it and run `flutter clean && flutter pub get`

---

### 2️⃣ SDK File Present

```bash
# Command to run:
ls -lh assets/js/amazon-chime-sdk.min.js
```

- [ ] **MUST SEE:** File exists
- [ ] **MUST SEE:** Size is ~1.1 MB (1148576 bytes)
- [ ] If missing, download: `curl -o assets/js/amazon-chime-sdk.min.js https://d2n29hdfurdqmu.cloudfront.net/chime-sdk-3.19.0.min.js`

---

### 3️⃣ Android Permissions

```bash
# Command to run:
grep "CAMERA\|RECORD_AUDIO\|INTERNET" android/app/src/main/AndroidManifest.xml
```

- [ ] **MUST SEE:** `<uses-permission android:name="android.permission.INTERNET"/>`
- [ ] **MUST SEE:** `<uses-permission android:name="android.permission.CAMERA"/>`
- [ ] **MUST SEE:** `<uses-permission android:name="android.permission.RECORD_AUDIO"/>`

---

### 4️⃣ iOS Permissions

```bash
# Command to run:
grep -A 1 "Camera\|Microphone" ios/Runner/Info.plist
```

- [ ] **MUST SEE:** `NSCameraUsageDescription`
- [ ] **MUST SEE:** `NSMicrophoneUsageDescription`

---

### 5️⃣ WebView Package

```bash
# Command to run:
grep webview_flutter pubspec.yaml
```

- [ ] **MUST SEE:** `webview_flutter:` (any version 4.x)
- [ ] **MUST SEE:** `webview_flutter_android:`
- [ ] **MUST SEE:** `webview_flutter_wkwebview:` (or webview_flutter_platform_interface)

---

## 🧪 Runtime Verification (When Testing)

### Run app with verbose logging:

```bash
flutter run -v
```

### ✅ SUCCESS INDICATORS (must see ALL of these):

```
📦 Loading bundled Chime SDK from assets...
✅ Chime SDK loaded: 1148576 bytes
🔧 Configuring Android WebView for camera/microphone
🌐 Page loaded, checking Chime SDK...
✅ Chime SDK loaded successfully
📱 Message from WebView: SDK_READY
✅ Chime SDK loaded and ready
```

### ❌ FAILURE INDICATORS (if you see ANY of these, check config):

```
❌ Failed to load bundled Chime SDK
⚠️ Loading Chime SDK from CDN fallback
❌ Chime SDK not loaded
❌ Chime SDK load timeout after 60 seconds
WebView Resource Error
net::ERR_CLEARTEXT_NOT_PERMITTED
```

---

## 🚀 Quick Fix Script

Copy and run this if anything is wrong:

```bash
#!/bin/bash

echo "🔧 Fixing Chime SDK Configuration..."

# 1. Check if SDK file exists
if [ ! -f "assets/js/amazon-chime-sdk.min.js" ]; then
  echo "📥 Downloading Chime SDK..."
  mkdir -p assets/js
  curl -o assets/js/amazon-chime-sdk.min.js \
    https://d2n29hdfurdqmu.cloudfront.net/chime-sdk-3.19.0.min.js
  echo "✅ SDK downloaded"
else
  echo "✅ SDK file exists"
fi

# 2. Check pubspec.yaml
if grep -q "assets/js/" pubspec.yaml; then
  echo "✅ pubspec.yaml configured correctly"
else
  echo "⚠️  WARNING: assets/js/ NOT in pubspec.yaml"
  echo "   Please add manually:"
  echo "   flutter:"
  echo "     assets:"
  echo "       - assets/js/"
fi

# 3. Clean and rebuild
echo "🧹 Cleaning build..."
flutter clean
flutter pub get

echo ""
echo "✅ Done! Now run: flutter run -v"
```

Save this as `fix-chime-sdk.sh`, make executable with `chmod +x fix-chime-sdk.sh`, and run with `./fix-chime-sdk.sh`.

---

## 📱 Device Testing Checklist

### Test on Physical Device (Recommended):

- [ ] Run `flutter devices` to list devices
- [ ] Run `flutter run -d <device-id> -v`
- [ ] Grant camera permission when prompted
- [ ] Grant microphone permission when prompted
- [ ] Join video call as Provider
- [ ] Join same call as Patient (different device)
- [ ] Verify both see each other's video
- [ ] Test mute button (audio on/off)
- [ ] Test video button (camera on/off)
- [ ] Test chat messages
- [ ] Test end call button

### Performance Targets:

- [ ] SDK loads in < 3 seconds
- [ ] Meeting joins in < 5 seconds
- [ ] Video starts in < 10 seconds
- [ ] No lag or stuttering
- [ ] Audio syncs with video

---

## 🐛 Quick Troubleshooting

| Symptom | Quick Fix |
|---------|-----------|
| "Failed to load bundled Chime SDK" | Add `- assets/js/` to pubspec.yaml, run `flutter clean && flutter pub get` |
| "Chime SDK load timeout" | Use physical device instead of emulator |
| Blank screen | Check camera/microphone permissions, check WebView console |
| "CDN fallback" message | SDK not bundled, check pubspec.yaml |
| No video/audio | Check device permissions, restart app |
| "ERR_CLEARTEXT_NOT_PERMITTED" | Add `android:usesCleartextTraffic="true"` to AndroidManifest.xml |

---

## 📊 Current Status

**Your Setup:**
- SDK File: ✅ Present (1.1 MB)
- Widget Code: ✅ 1,859 lines
- Join Room: ✅ 467 lines
- pubspec.yaml: ⚠️ **MISSING** `- assets/js/`

**Action Required:**
1. Add `- assets/js/` to pubspec.yaml
2. Run `flutter clean && flutter pub get`
3. Test with `flutter run -v`

---

## 🎯 One-Command Verification

```bash
# Run this single command to check everything:
echo "1. SDK File:" && ls -lh assets/js/amazon-chime-sdk.min.js && \
echo -e "\n2. Pubspec Assets:" && grep -A 5 "assets:" pubspec.yaml && \
echo -e "\n3. Android Permissions:" && grep "CAMERA\|RECORD_AUDIO" android/app/src/main/AndroidManifest.xml && \
echo -e "\n4. WebView Package:" && grep webview_flutter pubspec.yaml && \
echo -e "\n✅ Check complete!"
```

---

## ✅ Ready for Production?

**Check ALL of these:**

- [ ] ✅ SDK file exists (1.1 MB)
- [ ] ✅ pubspec.yaml includes `assets/js/`
- [ ] ✅ Android permissions configured
- [ ] ✅ iOS permissions configured
- [ ] ✅ Tested on physical Android device
- [ ] ✅ Tested on physical iOS device
- [ ] ✅ Logs show "SDK loaded: 1148576 bytes"
- [ ] ✅ No "CDN fallback" messages
- [ ] ✅ Video call works offline (after initial app load)
- [ ] ✅ Both participants can see/hear each other
- [ ] ✅ All controls work (mute, video, chat, end)

**If all checked:** 🎉 **READY FOR PRODUCTION!**

**If any unchecked:** See troubleshooting section above.

---

*Print this checklist and keep it handy for quick verification!*
