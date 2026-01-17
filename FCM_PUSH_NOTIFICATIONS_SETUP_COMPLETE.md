# FCM Push Notifications Setup - Complete ✅

**Status:** Platform configurations complete, VAPID key setup required
**Date:** December 17, 2025
**System:** Real-time Video Call Notifications

---

## 🎯 What Was Configured

### ✅ Android Configuration (Complete)

**Files Modified:**

1. **`android/app/src/main/AndroidManifest.xml`**
   - Added FCM service declaration
   - Configured default notification channel: `video_calls`
   - Service handles incoming FCM messages

2. **`android/app/src/main/kotlin/com/example/my_project/MainActivity.kt`**
   - Created `video_calls` notification channel (IMPORTANCE_HIGH)
   - Created `general` notification channel (IMPORTANCE_DEFAULT)
   - Configured LED light (blue), vibration pattern, badges
   - Auto-initializes on app start (Android API 26+)

**Android Features:**
- ✅ High-priority notifications for video calls
- ✅ LED light indicator (blue)
- ✅ Custom vibration pattern (500ms, 250ms, 500ms)
- ✅ Badge counter support
- ✅ Channel-specific importance levels
- ✅ Backwards compatibility (API 26+)

---

### ✅ Web Configuration (Complete*)

**Files Created:**

1. **`web/firebase-messaging-sw.js`**
   - Service worker for background message handling
   - Custom notification actions (Join Call, Dismiss)
   - Notification click handler with app navigation
   - Persistent notification display for video calls

2. **`web/index.html`** (Modified)
   - Firebase SDK scripts loaded from CDN
   - Automatic service worker registration
   - FCM token generation on page load
   - Foreground message handler
   - Notification permission request

**Web Features:**
- ✅ Background notifications when app is closed
- ✅ Foreground notifications when app is open
- ✅ Custom notification actions
- ✅ Automatic app focus/open on click
- ✅ Persistent notifications for video calls
- ✅ Token auto-generation

**⚠️ VAPID Key Required:**
The Web configuration requires a VAPID key to be added. See setup instructions below.

---

### 📋 iOS Configuration (Manual Setup Required)

iOS push notifications require manual configuration in Xcode:

1. **Enable Push Notifications Capability**
   ```
   1. Open project in Xcode: ios/Runner.xcodeproj
   2. Select "Runner" target → "Signing & Capabilities"
   3. Click "+ Capability" → Add "Push Notifications"
   4. Add "Background Modes" → Check "Remote notifications"
   ```

2. **Configure APNs Authentication**
   ```
   1. Go to Apple Developer Portal
   2. Certificates, Identifiers & Profiles
   3. Create APNs Key or Certificate
   4. Upload to Firebase Console:
      - Firebase Console → Project Settings → Cloud Messaging
      - iOS app configuration → Upload APNs key/certificate
   ```

3. **Update Info.plist** (if needed)
   ```xml
   <key>UIBackgroundModes</key>
   <array>
     <string>remote-notification</string>
   </array>
   ```

---

## 🔑 Web VAPID Key Setup

The Web FCM integration requires a VAPID (Voluntary Application Server Identification) key.

### How to Get Your VAPID Key

1. **Firebase Console**
   ```
   1. Go to: https://console.firebase.google.com/project/medzen-bf20e
   2. Project Settings (gear icon) → Cloud Messaging
   3. Web Push certificates → Generate key pair
   4. Copy the "Key pair" value
   ```

2. **Update `web/index.html`**
   - Replace placeholder on line 94:
   ```javascript
   vapidKey: 'BKagOny0KF_2pCJQ3m....pKWHjwoFCNCdkxW', // Replace with your actual VAPID key
   ```
   - With your actual key:
   ```javascript
   vapidKey: 'YOUR_ACTUAL_VAPID_KEY_HERE',
   ```

3. **Verify Configuration**
   ```bash
   # Test in Chrome/Firefox
   1. Open web app in browser
   2. Check browser console for:
      - "Service Worker registered successfully"
      - "Notification permission granted"
      - "FCM Token: ..."
   3. Grant notification permission when prompted
   ```

---

## 📱 How It All Works Together

### Video Call Notification Flow

```
1. Provider starts call
   ↓
2. Supabase: video_call_sessions.status = 'active'
   ↓
3. Database trigger OR manual call to Firebase function
   ↓
4. Firebase Cloud Function: sendVideoCallNotification()
   ↓
5. FCM sends notification to patient's device
   ↓
6. PLATFORM-SPECIFIC HANDLING:

   📱 Android:
   - FCM service receives message
   - Creates notification in "video_calls" channel
   - Shows with blue LED, vibration, badge
   - Tap → Opens app to appointment page

   🌐 Web:
   - Service worker receives message
   - Shows notification with "Join Call" action
   - Tap notification → Opens/focuses app window
   - Tap "Join Call" → Navigates to appointment

   🍎 iOS:
   - APNs receives message
   - Shows notification with category "VIDEO_CALL"
   - Tap → Opens app to appointment page
```

### Real-Time UI Update Flow

```
1. Provider starts call
   ↓
2. Supabase: video_call_sessions.status = 'active'
   ↓
3. Flutter widget: listen_for_call_status.dart
   - Subscribes to Supabase Stream
   - Filters by appointment_id
   ↓
4. Stream emits status change
   ↓
5. AnimatedJoinButton widget receives update
   ↓
6. UI updates INSTANTLY:
   - Button color: Green → Blue
   - Pulsing animation starts
   - Button text: "Waiting..." → "Join Call"
   ↓
7. Patient taps button → Calls joinRoom() action
```

---

## 🧪 Testing Instructions

### Test Android Notifications

```bash
# 1. Build and install app
flutter build apk --release
flutter install

# 2. Grant notification permission when prompted

# 3. Trigger notification manually (for testing)
cd firebase/functions
node
> const admin = require('firebase-admin');
> admin.initializeApp();
> admin.messaging().send({
    token: 'PATIENT_FCM_TOKEN',
    notification: {
      title: 'Dr. Smith started the call',
      body: 'Tap to join the video call now'
    },
    data: {
      type: 'video_call_started',
      appointmentId: 'test-123'
    },
    android: {
      channelId: 'video_calls',
      priority: 'high'
    }
  });

# 4. Verify notification appears with:
   - Blue LED light
   - Vibration pattern
   - Badge count
   - High priority (heads-up display)
```

### Test Web Notifications

```bash
# 1. Ensure VAPID key is configured in web/index.html

# 2. Start Flutter web app
flutter run -d chrome

# 3. Grant notification permission when prompted

# 4. Check browser console for:
   - "Service Worker registered successfully"
   - "Notification permission granted"
   - "FCM Token: ..." (copy this token)

# 5. Trigger notification manually
cd firebase/functions
node
> const admin = require('firebase-admin');
> admin.initializeApp();
> admin.messaging().send({
    token: 'WEB_FCM_TOKEN_FROM_STEP_4',
    notification: {
      title: 'Dr. Smith started the call',
      body: 'Tap to join the video call now'
    },
    data: {
      type: 'video_call_started',
      appointmentId: 'test-123'
    },
    webpush: {
      notification: {
        requireInteraction: true,
        actions: [
          { action: 'join', title: 'Join Now' },
          { action: 'dismiss', title: 'Dismiss' }
        ]
      }
    }
  });

# 6. Verify notification appears with:
   - Custom actions (Join Now, Dismiss)
   - Persistent display (requireInteraction)
   - Click handling (opens app window)
```

### Test iOS Notifications

```bash
# 1. Configure APNs in Firebase Console (see iOS Configuration above)

# 2. Build and run on physical iOS device (not simulator)
flutter run -d ios

# 3. Grant notification permission when prompted

# 4. Put app in background

# 5. Trigger notification manually
cd firebase/functions
node
> const admin = require('firebase-admin');
> admin.initializeApp();
> admin.messaging().send({
    token: 'IOS_FCM_TOKEN',
    notification: {
      title: 'Dr. Smith started the call',
      body: 'Tap to join the video call now'
    },
    data: {
      type: 'video_call_started',
      appointmentId: 'test-123'
    },
    apns: {
      headers: {
        'apns-priority': '10',
        'apns-push-type': 'alert'
      },
      payload: {
        aps: {
          alert: {
            title: 'Dr. Smith started the call',
            body: 'Tap to join the video call now'
          },
          sound: 'default',
          badge: 1,
          category: 'VIDEO_CALL'
        }
      }
    }
  });

# 6. Verify notification appears
# 7. Tap notification → App should open to appointment page
```

---

## 🔍 Troubleshooting

### Android Issues

**Problem:** Notifications not appearing
```
Solution:
1. Check notification permission is granted
2. Verify channel exists:
   adb shell dumpsys notification_listener | grep video_calls
3. Check FCM token is saved in Firestore users collection
4. Check Firebase function logs:
   firebase functions:log --limit 50
```

**Problem:** No sound/vibration
```
Solution:
1. Check device notification settings
2. Verify channel importance is HIGH
3. Ensure device is not in Do Not Disturb mode
```

### Web Issues

**Problem:** Service worker registration failed
```
Solution:
1. Check VAPID key is correct in web/index.html
2. Verify HTTPS is enabled (service workers require HTTPS)
3. Check browser console for errors
4. Clear browser cache and reload
```

**Problem:** No FCM token generated
```
Solution:
1. Ensure notification permission is granted
2. Check Firebase config is correct
3. Verify VAPID key is valid
4. Check browser console: messaging.getToken() errors
```

**Problem:** Notifications not showing
```
Solution:
1. Check browser notification settings
2. Verify service worker is active:
   Chrome DevTools → Application → Service Workers
3. Check notification permission:
   Chrome → Settings → Site Settings → Notifications
```

### iOS Issues

**Problem:** Notifications not appearing
```
Solution:
1. Verify APNs certificate/key is uploaded to Firebase
2. Check device is physical (not simulator)
3. Ensure Push Notifications capability is enabled
4. Verify Background Modes includes "remote-notification"
5. Check Firebase function logs for APNs errors
```

**Problem:** App doesn't open on notification tap
```
Solution:
1. Verify deep linking is configured
2. Check notification payload includes correct data
3. Test with app in different states:
   - Foreground
   - Background
   - Not running
```

---

## 📊 Monitoring & Analytics

### Firebase Console

**Real-time Monitoring:**
```
1. Go to: https://console.firebase.google.com/project/medzen-bf20e
2. Cloud Messaging → Notifications
3. View:
   - Sent count
   - Delivered count
   - Opened count
   - Delivery rate
```

**Function Logs:**
```bash
# View real-time logs
firebase functions:log --limit 50

# Filter by function
firebase functions:log --only sendVideoCallNotification

# Watch continuously
firebase functions:log --tail
```

### Firestore Logging

All notifications are logged in the `notification_logs` collection:
```javascript
{
  type: "video_call_started",
  appointmentId: "uuid",
  patientId: "uuid",
  providerId: "uuid",
  fcmToken: "...",
  sentAt: timestamp,
  messageId: "...",
  status: "sent"
}
```

**Query Example:**
```javascript
// Get notification history for appointment
db.collection('notification_logs')
  .where('appointmentId', '==', 'appointment-uuid')
  .orderBy('sentAt', 'desc')
  .limit(10)
  .get();
```

---

## ✅ Completion Checklist

### Android
- [x] AndroidManifest.xml configured with FCM service
- [x] MainActivity.kt creates notification channels
- [x] `video_calls` channel configured (IMPORTANCE_HIGH)
- [x] LED, vibration, badges enabled
- [ ] Test on physical Android device
- [ ] Verify notification appearance
- [ ] Verify notification tap handling

### Web
- [x] firebase-messaging-sw.js service worker created
- [x] index.html includes Firebase SDK
- [x] Foreground/background message handlers
- [x] Notification actions configured
- [ ] **VAPID key configured** (REQUIRED)
- [ ] Test in Chrome/Firefox
- [ ] Verify service worker registration
- [ ] Verify notification permission flow

### iOS
- [ ] Push Notifications capability enabled in Xcode
- [ ] Background Modes configured
- [ ] APNs certificate/key uploaded to Firebase
- [ ] Test on physical iOS device
- [ ] Verify notification appearance
- [ ] Verify app opens on tap

### Integration
- [x] Firebase functions deployed
- [x] Platform-specific configurations complete
- [ ] AnimatedJoinButton integrated in FlutterFlow
- [ ] FCM token storage verified
- [ ] End-to-end test on all platforms
- [ ] Production deployment

---

## 🎓 Additional Resources

**Firebase Documentation:**
- [FCM Flutter Setup](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [FCM Web Setup](https://firebase.google.com/docs/cloud-messaging/js/client)
- [FCM iOS Setup](https://firebase.google.com/docs/cloud-messaging/ios/client)

**Flutter Packages:**
- [firebase_messaging](https://pub.dev/packages/firebase_messaging)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

**Testing Tools:**
- [FCM Send Test](https://console.firebase.google.com/project/medzen-bf20e/notification)
- [Postman FCM API](https://www.postman.com/templates/7c7d3c4e-8e4c-4e4f-8c8e-3d8c3d8c3d8c)

---

## 📞 Support

For issues or questions:
1. Check Firebase function logs: `firebase functions:log`
2. Check Firestore notification_logs collection
3. Review browser/device console logs
4. Verify FCM token is saved in Firestore users collection

---

**Status:** FCM configuration complete for Android and Web. iOS requires manual Xcode setup. VAPID key setup required for Web.

**Next Steps:**
1. Add VAPID key to `web/index.html` (line 94)
2. Configure iOS in Xcode (see iOS Configuration section)
3. Integrate AnimatedJoinButton in FlutterFlow UI
4. Test on all platforms
5. Deploy to production
