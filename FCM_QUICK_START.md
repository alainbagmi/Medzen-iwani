# FCM Push Notifications - Quick Start 🚀

**TL;DR:** FCM is configured for Android and Web. iOS requires Xcode setup. VAPID key required for Web.

---

## ⚡ Immediate Action Required

### 1. Get VAPID Key for Web (2 minutes)

```
1. Go to: https://console.firebase.google.com/project/medzen-bf20e/settings/cloudmessaging
2. Scroll to "Web Push certificates"
3. Click "Generate key pair"
4. Copy the key (starts with "B...")
5. Update web/index.html line 94:
   vapidKey: 'PASTE_YOUR_KEY_HERE',
```

---

## 📱 What's Already Configured

### ✅ Android (Ready to Test)

**Files Modified:**
- `android/app/src/main/AndroidManifest.xml` - FCM service configured
- `android/app/src/main/kotlin/.../MainActivity.kt` - Notification channels created

**Features:**
- Blue LED light indicator
- Custom vibration pattern
- High-priority notifications
- Badge counter

**Test Now:**
```bash
flutter build apk --release
flutter install
# Grant notification permission when prompted
```

---

### ✅ Web (Needs VAPID Key)

**Files Created:**
- `web/firebase-messaging-sw.js` - Service worker for background notifications
- `web/index.html` - Firebase SDK and foreground handling

**Features:**
- Background notifications when app is closed
- Foreground notifications when app is open
- Custom actions (Join Call, Dismiss)
- Auto-focus app window on click

**After Adding VAPID Key:**
```bash
flutter run -d chrome
# Grant notification permission when prompted
# Check console for "Service Worker registered successfully"
```

---

### ⏳ iOS (Requires Xcode Setup)

**Manual Steps:**
```
1. Open ios/Runner.xcodeproj in Xcode
2. Select Runner target → Signing & Capabilities
3. Add "+ Capability" → "Push Notifications"
4. Add "Background Modes" → Check "Remote notifications"
5. Upload APNs key to Firebase Console
```

**See Full Guide:** `FCM_PUSH_NOTIFICATIONS_SETUP_COMPLETE.md` (iOS Configuration section)

---

## 🧪 Quick Test

### Test Notification Manually

```bash
# 1. Get FCM token from app logs
# 2. Send test notification

cd firebase/functions
node

> const admin = require('firebase-admin');
> const serviceAccount = require('./service-account-key.json');
> admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

> admin.messaging().send({
    token: 'PASTE_FCM_TOKEN_HERE',
    notification: {
      title: 'Test Video Call',
      body: 'Dr. Smith started the call'
    },
    data: {
      type: 'video_call_started',
      appointmentId: 'test-123'
    },
    android: {
      channelId: 'video_calls',
      priority: 'high'
    }
  }).then(response => {
    console.log('✅ Notification sent:', response);
  }).catch(error => {
    console.log('❌ Error:', error);
  });
```

---

## 📋 Next Steps

1. **[ ] Add VAPID key to web/index.html**
   - Get key from Firebase Console
   - Update line 94

2. **[ ] Test on Android device**
   ```bash
   flutter build apk --release
   flutter install
   ```

3. **[ ] Test on Web browser**
   ```bash
   flutter run -d chrome
   ```

4. **[ ] Configure iOS in Xcode**
   - Add Push Notifications capability
   - Upload APNs key to Firebase
   - Test on physical device

5. **[ ] Integrate AnimatedJoinButton in FlutterFlow**
   - See: `VIDEO_CALL_REAL_TIME_NOTIFICATIONS_COMPLETE.md`
   - Remove existing join button
   - Add custom AnimatedJoinButton widget
   - Set parameters: appointmentId, providerId, patientId, etc.

---

## 🔍 Troubleshooting

**No notifications on Android:**
- Check notification permission is granted
- Check FCM token is saved in Firestore users collection
- View Firebase function logs: `firebase functions:log --limit 50`

**No notifications on Web:**
- Verify VAPID key is configured
- Check browser console for errors
- Ensure HTTPS is enabled (required for service workers)
- Check notification permission in browser settings

**Service worker errors:**
- Clear browser cache
- Check `firebase-messaging-sw.js` is accessible at `/firebase-messaging-sw.js`
- Verify Firebase config matches your project

---

## 📚 Full Documentation

**Detailed Guides:**
- `FCM_PUSH_NOTIFICATIONS_SETUP_COMPLETE.md` - Complete FCM configuration guide
- `VIDEO_CALL_REAL_TIME_NOTIFICATIONS_COMPLETE.md` - Real-time video call system
- `REAL_TIME_VIDEO_CALL_NOTIFICATIONS.md` - Technical implementation details

**Firebase Functions:**
- `sendVideoCallNotification` - Send push notification (callable)
- `onVideoCallStatusChange` - Webhook for status changes (HTTP)

**Flutter Code:**
- `lib/custom_code/actions/listen_for_call_status.dart` - Real-time status stream
- `lib/custom_code/widgets/animated_join_button.dart` - Animated button widget

---

**Status:** Android ✅ | Web ✅ (needs VAPID) | iOS ⏳ (needs Xcode)

**Estimated Setup Time:**
- VAPID key: 2 minutes
- iOS Xcode: 15 minutes
- Testing: 30 minutes
- FlutterFlow integration: 45 minutes

**Total:** ~90 minutes to full production deployment
