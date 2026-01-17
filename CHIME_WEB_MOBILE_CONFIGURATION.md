# Chime Video Call - Web & Mobile Configuration Guide

## Overview
This guide provides complete configuration for the `ChimeMeetingEnhanced` widget to work seamlessly across **Web (Chrome)**, **iOS**, and **Android** platforms.

---

## 1. Platform-Specific Configurations

### 1.1 Android Configuration

#### Permissions (AndroidManifest.xml)
```xml
<!-- android/app/src/main/AndroidManifest.xml -->

<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />

<!-- WebRTC Permissions -->
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
<uses-feature android:name="android.hardware.microphone" android:required="false" />

<!-- In application tag -->
<application>
    <activity
        android:name=".MainActivity"
        android:usesCleartextTraffic="true">
        <!-- ... -->
    </activity>
</application>
```

#### Gradle Configuration (build.gradle)
```gradle
android {
    compileSdkVersion 34
    minSdkVersion 21  // Minimum for WebRTC support
    targetSdkVersion 34

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }

    defaultConfig {
        // Enable multidex for larger apps
        multiDexEnabled true
    }
}

dependencies {
    // WebView (for flutter_inappwebview)
    implementation 'androidx.webkit:webkit:1.9.0'
}
```

#### Java Code (MainActivity.kt)
```kotlin
package com.example.medzen

import android.os.Build
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Enable WebView debugging in development
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            WebView.setWebContentsDebuggingEnabled(true)
        }
    }
}
```

**Critical Notes:**
- ✅ `minSdkVersion 21` minimum for WebRTC support
- ✅ `android:usesCleartextTraffic="true"` for development (use HTTPS in production)
- ✅ Permissions automatically requested via `permission_handler` package
- ⚠️ Real device testing recommended (emulator camera is unreliable)

---

### 1.2 iOS Configuration

#### Info.plist Permissions
```xml
<!-- ios/Runner/Info.plist -->

<dict>
    <!-- Camera Permission -->
    <key>NSCameraUsageDescription</key>
    <string>We need camera access for video consultations</string>

    <!-- Microphone Permission -->
    <key>NSMicrophoneUsageDescription</key>
    <string>We need microphone access for video consultations</string>

    <!-- Network Permissions -->
    <key>NSLocalNetworkUsageDescription</key>
    <string>We need to access your local network for video calls</string>

    <key>NSBonjourServices</key>
    <array>
        <string>_http._tcp</string>
        <string>_https._tcp</string>
    </array>

    <!-- Allow arbitrary loads for video streaming -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
        <key>NSAllowsArbitraryLoadsInWebContent</key>
        <true/>
    </dict>

    <!-- WebRTC Audio Settings -->
    <key>AVAudioSession</key>
    <dict>
        <key>AVAudioSessionCategory</key>
        <string>PlayAndRecord</string>
        <key>AVAudioSessionOptions</key>
        <array>
            <string>DuckOthers</string>
            <string>DefaultToSpeaker</string>
        </array>
    </dict>
</dict>
```

#### Podfile Configuration
```ruby
# ios/Podfile

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_root = File.expand_path(File.join(packages_path, 'flutter'))
  load File.join(flutter_root, 'packages', 'flutter_tools', 'bin', 'podhelper.rb')

  flutter_ios_podfile_setup

  # WebRTC support
  pod 'WebRTC', '~> 118.0'

  post_install do |installer|
    installer.pods_project.targets.each do |target|
      flutter_additional_ios_build_settings(target)

      # Enable bitcode (required for some dependencies)
      target.build_configurations.each do |config|
        config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
      end
    end
  end
end
```

**Critical Notes:**
- ✅ iOS 11+ required for WebRTC
- ✅ Both NSCameraUsageDescription and NSMicrophoneUsageDescription mandatory
- ✅ Must enable arbitrary loads for WebRTC CDN resources
- ⚠️ Run `cd ios && pod deintegrate && pod install` after Podfile changes

---

### 1.3 Web (Chrome) Configuration

#### Required pubspec.yaml Dependencies
```yaml
dependencies:
  # Already required by flutter_inappwebview
  flutter_inappwebview: ^6.0.0

dev_dependencies:
  # For testing web builds
  integration_test:
    sdk: flutter
```

#### Web-Specific Notes
- ✅ No special permissions needed (browser handles camera/mic prompts)
- ✅ HTTPS required in production (HTTP only for localhost development)
- ✅ Chime SDK loads from CloudFront CDN automatically
- ✅ Service workers not required but recommended for offline support

#### Chrome DevTools for Debugging
```bash
# Run web with debug enabled
flutter run -d chrome --dart-define=FLUTTER_WEB_AUTO_REFRESH=true

# Press 'w' to open Chrome DevTools
# Press 'Ctrl+Shift+I' to toggle DevTools
# Check Console tab for JavaScript errors
# Check Network tab for SDK CDN loading
```

---

## 2. Required Dependencies

### pubspec.yaml (Complete)
```yaml
dependencies:
  flutter:
    sdk: flutter

  # WebRTC/Video
  flutter_inappwebview: ^6.0.0
  permission_handler: ^11.4.0

  # Firebase & Supabase
  firebase_auth: ^4.10.0
  supabase_flutter: ^1.10.0

  # Storage & Files
  image_picker: ^1.0.0

  # Utilities
  http: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
```

**Installation:**
```bash
flutter pub get
cd ios && pod install && cd ..  # iOS only
```

---

## 3. Deployment Checklist

### Pre-Deployment Verification

#### Code Quality
```bash
# ✅ Analyze code
dart analyze lib/

# ✅ Format code
dart format lib/

# ✅ Run tests
flutter test
```

#### Platform-Specific Builds

**Android:**
```bash
# ✅ Build and test on Android emulator
flutter run -d emulator-5554

# ✅ Build APK
flutter build apk --release

# ✅ Verify APK
aapt dump badging build/app/outputs/apk/release/app-release.apk
```

**iOS:**
```bash
# ✅ Build and test on iOS simulator
flutter run -d iPhone

# ✅ Build IPA
flutter build ios --release

# ✅ Archive for App Store
cd ios && xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive && cd ..
```

**Web:**
```bash
# ✅ Build web
flutter build web

# ✅ Test web build locally
python3 -m http.server --directory build/web 8000
# Open http://localhost:8000
```

---

## 4. Testing Checklist

### Manual Testing Procedures

#### Android Testing
- [ ] **Emulator (API 21+)**
  - Camera permission prompt appears
  - Microphone permission prompt appears
  - Video call connects successfully
  - Audio from both sides works
  - No "CheckMediaAccessPermission" errors in logcat

- [ ] **Real Device**
  - Video/audio working with actual camera/mic
  - Permissions persist after app restart
  - Background app switching doesn't drop call
  - Noise suppression enabled (reduces feedback)

#### iOS Testing
- [ ] **Simulator**
  - Camera permission prompt appears
  - Microphone permission prompt appears
  - Video call connects (simulated video)

- [ ] **Real Device**
  - Actual camera and microphone work
  - Speakerphone audio routing correct
  - Device orientation changes handled
  - Lock screen doesn't interrupt call

#### Web Testing
- [ ] **Chrome/Chromium**
  - Camera/mic selection dialog appears
  - Video stream displays correctly
  - Audio input/output working
  - Network tab shows SDK loads from CDN

- [ ] **Safari/Firefox**
  - Falls back gracefully if WebRTC not supported
  - Shows appropriate error messages

---

## 5. Troubleshooting Guide

### Common Issues & Solutions

#### Android: "Camera in use by another app"
```
Symptom: Video won't start, NotReadableError
Solution:
1. Close camera apps (stock camera, Instagram, etc.)
2. Restart the app
3. Force stop and clear app data if persistent
4. Check logcat: adb logcat | grep -i "camera"
```

#### Android: "CheckMediaAccessPermission: Not supported"
```
Symptom: Permission checks loop infinitely
Root Cause: Multiple calls to enumerateDevices() without releasing stream
Solution: Already handled in widget via:
- Device enumeration caching (30s TTL)
- 2000ms delay after stream release
- Permission state caching after first request
Monitor: Check browser console for "📹 Using cached device list"
```

#### iOS: Microphone not working
```
Symptom: Others can't hear you, local audio plays
Solution:
1. Check iOS Settings > Privacy > Microphone
2. Ensure app is listed and enabled
3. Toggle mic off/on in app controls
4. Force app reload (full app restart)
Monitor: Check device Settings > Privacy
```

#### iOS: Speaker not working (hearing nothing)
```
Symptom: Can send audio, can't receive
Solution:
1. Check AVAudioSession configuration (already set in widget)
2. Ensure speaker_phone mode is correct
3. Verify Info.plist has correct audio settings
Monitor: Check Safari console for audio element binding
```

#### Web: SDK fails to load from CDN
```
Symptom: "SDK load failed" message appears
Root Cause: CDN blocked, slow connection, HTTPS issue
Solution:
1. Check network tab for https://du6iimxem4mh7.cloudfront.net
2. Verify no CORS headers blocking
3. Check internet connection speed
4. Retry: SDK has automatic retry with exponential backoff
Monitor: Browser console shows "SDK script loaded from CDN"
```

---

## 6. Performance Optimization

### Device Resource Management
```dart
// Already implemented in widget:
- ✅ Device enumeration caching (prevents permission loops)
- ✅ Stream pre-acquisition + immediate release (prevents device locks)
- ✅ No camera mode fallback (graceful degradation)
- ✅ Throttled permission checks (2s minimum between checks)
- ✅ Processed message deduplication (prevents memory leaks)
```

### Bandwidth Optimization
```javascript
// Already implemented in HTML:
- ✅ Video grid responsive (1-16 participants)
- ✅ Active speaker detection and highlighting
- ✅ Device audio profile set to "music" (reduces noise suppression)
- ✅ Audio binding for speaker output
```

### CPU Optimization
```javascript
// Recommendations:
- Use GPU acceleration for video rendering (browser default)
- Limit UI redraws with Flutter const constructors
- Lazy-load chat messages (implemented)
- Unsubscribe from unused Realtime channels
```

---

## 7. Security Best Practices

### HTTPS & TLS
```
✅ Production: All HTTPS connections mandatory
✅ Staging: HTTPS recommended
⚠️ Development: HTTP + localhost only
```

### Permission Handling
```dart
// Already implemented:
- ✅ Runtime permissions checked before SDK init
- ✅ Graceful fallback for missing devices
- ✅ User-friendly error messages
- ✅ No permissions stored (OS handles persistence)
```

### Data Privacy
```
✅ Messages encrypted in transit (HTTPS)
✅ Supabase RLS policies enforce access control
✅ Firebase Auth integrates with Supabase user IDs
✅ Session tokens refreshed automatically (getIdToken(true))
```

---

## 8. Monitoring & Logging

### Development Logging
```bash
# Android
adb logcat | grep -E "(ChimeMeetingEnhanced|flutter)"

# iOS
log stream --predicate 'process == "Runner"' --level debug

# Web
# Open Chrome DevTools > Console
# Look for messages prefixed with emojis (🎬, 📹, 🔊, etc.)
```

### Production Monitoring
```dart
// Recommendations:
- Log errors to Sentry or Firebase Crashlytics
- Track permission denial rates
- Monitor video call duration and success rates
- Alert on SDK load failures
```

---

## 9. Quick Start Commands

```bash
# Clean and rebuild for specific platform
flutter clean && flutter pub get

# Android
flutter run -d emulator-5554 -v     # Verbose logging
flutter build apk --release

# iOS
flutter run -d iPhone -v
flutter build ios --release

# Web
flutter run -d chrome --dart-define=FLUTTER_WEB_AUTO_REFRESH=true
flutter build web --release

# Check versions
flutter --version
dart --version
java -version
```

---

## 10. Support & Documentation

### Useful Resources
- [Chime SDK Documentation](https://aws.amazon.com/chime/web-client-sdk/)
- [Flutter WebView Plugin](https://pub.dev/packages/flutter_inappwebview)
- [Permission Handler](https://pub.dev/packages/permission_handler)
- [Firebase Auth Documentation](https://firebase.flutter.dev/docs/auth/overview)
- [Supabase Flutter Docs](https://supabase.com/docs/reference/flutter/introduction)

### Debugging Tools
- **Android**: Android Studio Logcat + Chrome DevTools (WebView remote debugging)
- **iOS**: Xcode Console + Safari Web Inspector
- **Web**: Chrome DevTools + Network tab
- **All**: Flutter DevTools (`flutter pub global run devtools`)

---

## Conclusion

The `ChimeMeetingEnhanced` widget is now configured for:
- ✅ **Android 21+** with full WebRTC support
- ✅ **iOS 11+** with camera/microphone integration
- ✅ **Web (Chrome)** with browser-native WebRTC
- ✅ **Error handling & graceful degradation** across all platforms
- ✅ **Permission management** with user-friendly prompts
- ✅ **Performance optimization** for real-time video/audio

**Next Steps:**
1. Run platform-specific builds and test on real devices
2. Verify Chime SDK loads from CDN without errors
3. Test all permission scenarios (allow/deny/revoke)
4. Monitor production logs for any platform-specific issues
5. Gather user feedback and iterate on UX

