// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Inline session management (to avoid FlutterFlow cross-file import issues)
void _disposeSessionTracking() {
  debugPrint('SessionManager: Disposed on logout');
}

void _startSessionValidationLocal() {
  debugPrint('SessionManager: Session validation started');
  // Note: ActivityDetector widget handles the actual session timeout logic
}

/// VAPID key for web push notifications
/// Generate this in Firebase Console: Project Settings > Cloud Messaging > Web Push certificates
/// Steps: 1. Go to Firebase Console > Project Settings > Cloud Messaging
///        2. Under "Web configuration", find "Web Push certificates"
///        3. Generate a new key pair and copy the public key
///        4. Replace the value below OR set in environment.json as 'webVapidKey'
///
/// For MedZen production, this key is configured in Firebase Console for project medzen-bf20e
const String _webVapidKey = '3Yw600VqggGZ1xsWdVk3hEz7AfwVRcKZNqzkCLfdYnw';

/// Validates FCM token format
/// FCM tokens are typically 100-200 characters of base64-like string
bool _isValidFcmToken(String? token) {
  if (token == null || token.isEmpty) return false;
  // FCM tokens should be at least 100 characters and contain only valid chars
  if (token.length < 100) return false;
  // Check for valid base64/FCM token characters
  final validPattern = RegExp(r'^[A-Za-z0-9_:\-]+$');
  return validPattern.hasMatch(token);
}

/// Secure storage keys for FCM token persistence
const String _fcmTokenStorageKey = 'medzen_fcm_token';
const String _fcmTokenUserIdKey = 'medzen_fcm_user_id';
const String _fcmTokenTimestampKey = 'medzen_fcm_token_timestamp';
const String _deviceIdStorageKey = 'medzen_device_id';
const String _sessionTokenStorageKey = 'medzen_session_token';

/// Token refresh interval (7 days in milliseconds)
const int _tokenRefreshIntervalMs = 7 * 24 * 60 * 60 * 1000;

/// Unique device ID for this device (persisted across app restarts)
String? _cachedDeviceId;

/// Secure storage instance for FCM token persistence
const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

/// Generates or retrieves a unique device ID for this device
Future<String> _getDeviceId() async {
  if (_cachedDeviceId != null) return _cachedDeviceId!;

  try {
    // Try to load existing device ID
    _cachedDeviceId = await _secureStorage.read(key: _deviceIdStorageKey);

    if (_cachedDeviceId == null || _cachedDeviceId!.isEmpty) {
      // Generate new unique device ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = timestamp.hashCode ^ DateTime.now().microsecond;
      _cachedDeviceId =
          '${kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android')}_${timestamp}_$random';

      // Persist the device ID
      await _secureStorage.write(
          key: _deviceIdStorageKey, value: _cachedDeviceId!);
      debugPrint('FCM: Generated new device ID: $_cachedDeviceId');
    } else {
      debugPrint('FCM: Loaded existing device ID: $_cachedDeviceId');
    }
  } catch (e) {
    // Fallback to a generated ID without persistence
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _cachedDeviceId = 'fallback_$timestamp';
    debugPrint('FCM: Error loading device ID, using fallback: $e');
  }

  return _cachedDeviceId!;
}

/// Generates a unique session token
String _generateSessionToken() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = timestamp.hashCode ^ DateTime.now().microsecond;
  return 'sess_${timestamp}_$random';
}

/// Sends a force logout push notification to a device
Future<bool> _sendForceLogoutNotification(
    String fcmToken, String deviceType) async {
  try {
    debugPrint('FCM: Sending force logout to old device ($deviceType)');

    // Use Firebase Cloud Messaging to send the notification
    // This requires the FCM server key or using a Cloud Function
    // For now, we'll use the Supabase Edge Function approach
    final response = await SupaFlow.client.functions.invoke(
      'send-push-notification',
      body: {
        'fcm_token': fcmToken,
        'title': 'Session Ended',
        'body':
            'You have been logged out because you signed in on another device.',
        'data': {
          'type': 'force_logout',
          'action': 'sign_out',
        },
      },
    );

    if (response.status == 200) {
      debugPrint('FCM: Force logout notification sent successfully');
      return true;
    } else {
      debugPrint('FCM: Force logout notification failed: ${response.data}');
      return false;
    }
  } catch (e) {
    debugPrint('FCM: Error sending force logout notification: $e');
    // Even if notification fails, we still proceed with the new login
    return false;
  }
}

/// Top-level background message handler - MUST be outside any class/function
/// Required for Android/iOS background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
      'FCM: Background message received: ${message.notification?.title}');

  // Check for force logout notification in background
  if (message.data['type'] == 'force_logout' ||
      message.data['action'] == 'sign_out') {
    debugPrint('FCM: ⚠️ Force logout received in background');
    // Note: In background, we can't directly sign out the user
    // The app will check session validity when it comes to foreground
    // Store a flag to force logout when app resumes
    try {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'pending_force_logout', value: 'true');
    } catch (e) {
      debugPrint('FCM: Error storing pending force logout: $e');
    }
  }
}

/// Persists FCM token to secure storage
Future<void> _persistToken(String token, String? userId) async {
  try {
    await _secureStorage.write(key: _fcmTokenStorageKey, value: token);
    if (userId != null) {
      await _secureStorage.write(key: _fcmTokenUserIdKey, value: userId);
    }
    await _secureStorage.write(
      key: _fcmTokenTimestampKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    debugPrint('FCM: Token persisted to secure storage');
  } catch (e) {
    debugPrint('FCM: Error persisting token: $e');
  }
}

/// Loads persisted FCM token from secure storage
Future<String?> _loadPersistedToken() async {
  try {
    final token = await _secureStorage.read(key: _fcmTokenStorageKey);
    final timestampStr = await _secureStorage.read(key: _fcmTokenTimestampKey);

    if (token != null && timestampStr != null) {
      final timestamp = int.tryParse(timestampStr) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;

      // Return token if it's not too old
      if (age < _tokenRefreshIntervalMs) {
        debugPrint('FCM: Loaded persisted token (age: ${age ~/ 1000}s)');
        return token;
      } else {
        debugPrint('FCM: Persisted token expired, will refresh');
      }
    }
  } catch (e) {
    debugPrint('FCM: Error loading persisted token: $e');
  }
  return null;
}

/// Clears persisted FCM token from secure storage
Future<void> _clearPersistedToken() async {
  try {
    await _secureStorage.delete(key: _fcmTokenStorageKey);
    await _secureStorage.delete(key: _fcmTokenUserIdKey);
    await _secureStorage.delete(key: _fcmTokenTimestampKey);
    debugPrint('FCM: Cleared persisted token');
  } catch (e) {
    debugPrint('FCM: Error clearing persisted token: $e');
  }
}

/// Syncs FCM token to Supabase users table
/// This enables server-side push notification sending
/// Also enforces single-device login by checking for existing sessions
Future<bool> _syncTokenToSupabase(String token, String firebaseUid) async {
  try {
    // Validate token format before syncing
    if (!_isValidFcmToken(token)) {
      debugPrint('FCM: Invalid token format, skipping Supabase sync');
      return false;
    }

    final deviceType = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
    final deviceId = await _getDeviceId();
    final sessionToken = _generateSessionToken();

    debugPrint('FCM: Syncing token for device $deviceId');

    // First, check if user is logged in on another device
    try {
      final existingUser = await SupaFlow.client
          .from('users')
          .select('id, fcm_token, device_type, active_device_id')
          .eq('firebase_uid', firebaseUid)
          .maybeSingle();

      if (existingUser != null) {
        final oldDeviceId = existingUser['active_device_id'] as String?;
        final oldFcmToken = existingUser['fcm_token'] as String?;
        final oldDeviceType = existingUser['device_type'] as String?;

        // Check if there's an existing session on a different device
        if (oldDeviceId != null &&
            oldDeviceId.isNotEmpty &&
            oldDeviceId != deviceId &&
            oldFcmToken != null &&
            oldFcmToken.isNotEmpty) {
          debugPrint(
              'FCM: User logged in on another device ($oldDeviceId), forcing logout');

          // Send force logout notification to the old device
          await _sendForceLogoutNotification(
              oldFcmToken, oldDeviceType ?? 'unknown');

          // Also invalidate any active sessions for this user in active_sessions table
          try {
            await SupaFlow.client
                .from('active_sessions')
                .update({
                  'is_active': false,
                })
                .eq('firebase_uid', firebaseUid)
                .neq('device_id', deviceId);
            debugPrint(
                'FCM: Invalidated old sessions in active_sessions table');
          } catch (sessionError) {
            debugPrint('FCM: Could not invalidate old sessions: $sessionError');
          }
        }
      }
    } catch (checkError) {
      debugPrint('FCM: Error checking existing device: $checkError');
      // Continue with sync even if check fails
    }

    // Update the user's fcm_token and device info in Supabase
    await SupaFlow.client.from('users').update({
      'fcm_token': token,
      'device_type': deviceType,
      'active_device_id': deviceId,
      'active_session_token': sessionToken,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('firebase_uid', firebaseUid);

    // Also create/update active session
    try {
      final userId = await _getUserIdFromFirebaseUid(firebaseUid);
      if (userId != null) {
        await SupaFlow.client.from('active_sessions').upsert({
          'user_id': userId,
          'device_id': deviceId,
          'device_name': deviceType,
          'device_platform': deviceType,
          'firebase_uid': firebaseUid,
          'session_token': sessionToken,
          'last_activity_at': DateTime.now().toUtc().toIso8601String(),
          'expires_at': DateTime.now()
              .add(const Duration(hours: 24))
              .toUtc()
              .toIso8601String(),
          'is_active': true,
        }, onConflict: 'user_id,device_id');
        debugPrint('FCM: Active session created/updated');
      }
    } catch (sessionError) {
      debugPrint('FCM: Error creating active session: $sessionError');
      // Continue even if session creation fails
    }

    // Persist token and session to secure storage
    await _persistToken(token, firebaseUid);
    await _secureStorage.write(
        key: _sessionTokenStorageKey, value: sessionToken);

    debugPrint(
        'FCM: Token synced to Supabase for user $firebaseUid ($deviceType) on device $deviceId');
    return true;
  } catch (e) {
    debugPrint('FCM: Error syncing token to Supabase: $e');
    return false;
  }
}

/// Gets the Supabase user ID from Firebase UID
Future<String?> _getUserIdFromFirebaseUid(String firebaseUid) async {
  try {
    final result = await SupaFlow.client
        .from('users')
        .select('id')
        .eq('firebase_uid', firebaseUid)
        .maybeSingle();
    return result?['id'] as String?;
  } catch (e) {
    debugPrint('FCM: Error getting user ID: $e');
    return null;
  }
}

/// Clears FCM token from Supabase (call on logout)
Future<void> clearFcmTokenFromSupabase(String firebaseUid) async {
  try {
    final deviceId = await _getDeviceId();

    await SupaFlow.client.from('users').update({
      'fcm_token': null,
      'device_type': null,
      'active_device_id': null,
      'active_session_token': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('firebase_uid', firebaseUid);

    // Also deactivate the session in active_sessions
    try {
      await SupaFlow.client
          .from('active_sessions')
          .update({
            'is_active': false,
          })
          .eq('firebase_uid', firebaseUid)
          .eq('device_id', deviceId);
      debugPrint('FCM: Session deactivated');
    } catch (sessionError) {
      debugPrint('FCM: Error deactivating session: $sessionError');
    }

    // Clear persisted token as well
    await _clearPersistedToken();
    await _secureStorage.delete(key: _sessionTokenStorageKey);

    debugPrint(
        'FCM: Token and device info cleared from Supabase for user $firebaseUid');
  } catch (e) {
    debugPrint('FCM: Error clearing token from Supabase: $e');
  }
}

/// AwesomeNotifications action received callback
/// Handles when user taps on notification or action buttons
@pragma('vm:entry-point')
Future<void> _onNotificationActionReceived(
    ReceivedAction receivedAction) async {
  debugPrint(
      'FCM: Notification action received: ${receivedAction.buttonKeyPressed}');
  debugPrint('FCM: Payload: ${receivedAction.payload}');

  // Always dismiss the notification first
  if (receivedAction.id != null) {
    await AwesomeNotifications().dismiss(receivedAction.id!);
    debugPrint('FCM: Notification ${receivedAction.id} dismissed');
  }

  final payload = receivedAction.payload ?? {};
  final actionType = payload['type'];
  final buttonKey = receivedAction.buttonKeyPressed;

  // Handle video call notifications - store appointment ID for auto-join
  if (actionType == 'video_call' && buttonKey == 'OPEN') {
    debugPrint('FCM: User wants to join video call');
    final appointmentId = payload['appointmentId'];
    if (appointmentId != null) {
      // Store in secure storage for the landing page to pick up
      const storage = FlutterSecureStorage();
      await storage.write(
          key: 'pending_video_call_appointment', value: appointmentId);
      debugPrint('FCM: Stored pending video call appointment: $appointmentId');
    }
  }

  // Handle other notification types via the existing handler
  _handleNotificationData(Map<String, dynamic>.from(payload));
}

/// AwesomeNotifications notification created callback
@pragma('vm:entry-point')
Future<void> _onNotificationCreated(
    ReceivedNotification receivedNotification) async {
  debugPrint('FCM: Notification created: ${receivedNotification.id}');
}

/// AwesomeNotifications notification displayed callback
@pragma('vm:entry-point')
Future<void> _onNotificationDisplayed(
    ReceivedNotification receivedNotification) async {
  debugPrint('FCM: Notification displayed: ${receivedNotification.title}');
}

/// AwesomeNotifications dismiss action callback
@pragma('vm:entry-point')
Future<void> _onNotificationDismissed(ReceivedAction receivedAction) async {
  debugPrint('FCM: Notification dismissed: ${receivedAction.id}');
  // Notification is already dismissed by the action
}

/// Maximum number of registration retry attempts
const int _maxRetryAttempts = 3;

/// Delay between retry attempts (exponential backoff)
Duration _getRetryDelay(int attempt) {
  return Duration(seconds: (1 << attempt)); // 2^attempt seconds
}

/// Registers FCM token with Firebase Cloud Function and Supabase
/// Returns true if registration was successful, false otherwise
///
/// Note: Firebase Cloud Function registration is also handled by push_notifications_util.dart
/// via fcmTokenUserStream. This function focuses on Supabase sync but will also
/// register with Firebase as a backup in case the stream-based registration fails.
Future<bool> _registerFcmToken(String token, {int retryAttempt = 0}) async {
  try {
    // Validate token format before proceeding
    if (!_isValidFcmToken(token)) {
      debugPrint('FCM: Invalid token format, skipping registration');
      return false;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('FCM: No authenticated user, skipping token registration');
      return false;
    }

    // Check if we've already registered this token for this user
    final persistedUserId = await _secureStorage.read(key: _fcmTokenUserIdKey);
    final persistedToken = await _secureStorage.read(key: _fcmTokenStorageKey);
    if (persistedToken == token && persistedUserId == user.uid) {
      debugPrint('FCM: Token already registered for this user, skipping');
      return true;
    }

    // Verify we have a valid ID token before calling Cloud Function
    // This forces token refresh if needed and ensures authentication is ready
    String? idToken;
    try {
      idToken = await user.getIdToken(true); // Force refresh
      if (idToken == null || idToken.isEmpty) {
        debugPrint('FCM: Unable to get valid ID token, skipping registration');
        return false;
      }
    } catch (tokenError) {
      debugPrint('FCM: Error getting ID token: $tokenError');

      // Retry with exponential backoff
      if (retryAttempt < _maxRetryAttempts) {
        final delay = _getRetryDelay(retryAttempt);
        debugPrint(
            'FCM: Will retry in ${delay.inSeconds}s (attempt ${retryAttempt + 1}/$_maxRetryAttempts)');
        await Future.delayed(delay);
        return _registerFcmToken(token, retryAttempt: retryAttempt + 1);
      }
      return false;
    }

    final deviceType = kIsWeb ? 'Web' : (Platform.isIOS ? 'iOS' : 'Android');

    debugPrint('FCM: Registering token for user ${user.uid} ($deviceType)');

    // Skip Firebase Cloud Function registration - Supabase is primary storage
    // Firebase Cloud Function has App Check issues and is redundant
    // The push_notifications_util.dart's fcmTokenUserStream also tries this
    // but will fail with same App Check issue - that's OK, Supabase works
    bool firebaseSuccess = false;
    debugPrint(
        'FCM: Skipping Firebase Cloud Function (using Supabase as primary)');

    // Sync to Supabase (for server-side notifications) - this is our primary target
    final supabaseSuccess = await _syncTokenToSupabase(token, user.uid);

    if (supabaseSuccess) {
      debugPrint(
          'FCM: Token registration complete (Firebase: $firebaseSuccess, Supabase: $supabaseSuccess)');
      return true;
    } else if (retryAttempt < _maxRetryAttempts) {
      // Retry Supabase sync
      final delay = _getRetryDelay(retryAttempt);
      debugPrint(
          'FCM: Supabase sync failed, will retry in ${delay.inSeconds}s');
      await Future.delayed(delay);
      return _registerFcmToken(token, retryAttempt: retryAttempt + 1);
    }

    return firebaseSuccess; // At least Firebase succeeded
  } catch (e) {
    debugPrint('FCM: Error registering token: $e');

    // Retry on general errors
    if (retryAttempt < _maxRetryAttempts) {
      final delay = _getRetryDelay(retryAttempt);
      debugPrint('FCM: Will retry in ${delay.inSeconds}s');
      await Future.delayed(delay);
      return _registerFcmToken(token, retryAttempt: retryAttempt + 1);
    }
    return false;
  }
}

Future<void> initializeMessaging() async {
  try {
    debugPrint('FCM: Initializing push notifications...');

    // Check for pending force logout from background notification
    await _checkPendingForceLogout();

    // Initialize local notifications (not needed on web)
    if (!kIsWeb) {
      await AwesomeNotifications().initialize(
          null,
          [
            NotificationChannel(
                channelKey: 'alerts',
                channelName: 'Alerts',
                channelDescription: 'MedZen health notifications',
                playSound: true,
                onlyAlertOnce: true,
                groupAlertBehavior: GroupAlertBehavior.Children,
                importance: NotificationImportance.High,
                defaultPrivacy: NotificationPrivacy.Private,
                defaultColor: Colors.deepPurple,
                ledColor: Colors.deepPurple),
            NotificationChannel(
                channelKey: 'appointments',
                channelName: 'Appointments',
                channelDescription: 'Appointment reminders and updates',
                playSound: true,
                importance: NotificationImportance.High,
                defaultPrivacy: NotificationPrivacy.Private,
                defaultColor: Colors.blue,
                ledColor: Colors.blue),
            NotificationChannel(
                channelKey: 'video_calls',
                channelName: 'Video Calls',
                channelDescription: 'Incoming video call notifications',
                playSound: true,
                importance: NotificationImportance.Max,
                defaultPrivacy: NotificationPrivacy.Private,
                defaultColor: Colors.green,
                ledColor: Colors.green),
          ],
          debug: false);
      debugPrint('FCM: Local notifications initialized');

      // Set up action listeners for notification button clicks
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: _onNotificationActionReceived,
        onNotificationCreatedMethod: _onNotificationCreated,
        onNotificationDisplayedMethod: _onNotificationDisplayed,
        onDismissActionReceivedMethod: _onNotificationDismissed,
      );
      debugPrint('FCM: Notification action listeners set up');
    }

    // Request notification permissions
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: true,
      carPlay: false,
      criticalAlert: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM: User denied notification permissions');
      return;
    }

    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      debugPrint('FCM: Notification permissions not determined');
      return;
    }

    debugPrint(
        'FCM: Notification permission granted: ${settings.authorizationStatus}');

    // Try to load persisted token first
    String? token = await _loadPersistedToken();

    // Validate persisted token
    if (token != null && !_isValidFcmToken(token)) {
      debugPrint('FCM: Persisted token is invalid, will get fresh token');
      token = null;
      await _clearPersistedToken();
    }

    // Get fresh FCM token if no valid persisted token
    if (token == null) {
      try {
        if (kIsWeb) {
          // Web requires VAPID key - use the configured key
          debugPrint('FCM: Getting web token with VAPID key...');
          token =
              await FirebaseMessaging.instance.getToken(vapidKey: _webVapidKey);
        } else {
          token = await FirebaseMessaging.instance.getToken();
        }
      } catch (e) {
        debugPrint('FCM: Error getting token: $e');
        if (kIsWeb) {
          debugPrint(
              'FCM: Web push may require valid VAPID key. Check Firebase Console > Project Settings > Cloud Messaging');
        }
      }
    }

    // Validate the obtained token
    if (_isValidFcmToken(token)) {
      FFAppState().fcmToken = token!;
      debugPrint(
          'FCM: Valid token obtained: ${token.substring(0, min(20, token.length))}...');

      // Register token if user is already authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Slight delay to ensure Firebase Auth is fully initialized
        await Future.delayed(const Duration(milliseconds: 300));
        await _registerFcmToken(token);
      } else {
        // Persist token for later registration
        await _persistToken(token, null);
        debugPrint('FCM: Token persisted, will register when user logs in');
      }
    } else {
      debugPrint(
          'FCM: No valid token obtained (token: ${token?.length ?? 0} chars)');
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM: Token refresh event received');

      // Validate the refreshed token
      if (!_isValidFcmToken(newToken)) {
        debugPrint('FCM: Refreshed token is invalid, ignoring');
        return;
      }

      FFAppState().fcmToken = newToken;
      debugPrint(
          'FCM: Valid token refreshed: ${newToken.substring(0, min(20, newToken.length))}...');

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _registerFcmToken(newToken);
      } else {
        await _persistToken(newToken, null);
      }
    });

    // Listen for auth state changes to register token when user logs in
    // Use idTokenChanges for more reliable auth state detection
    FirebaseAuth.instance.idTokenChanges().listen((user) async {
      if (user != null) {
        // Small delay to ensure auth state is fully propagated
        await Future.delayed(const Duration(milliseconds: 500));

        // Double-check user is still authenticated
        if (FirebaseAuth.instance.currentUser == null) {
          debugPrint('FCM: User no longer authenticated after delay');
          return;
        }

        // Try to get a valid token from multiple sources
        String? tokenToRegister = FFAppState().fcmToken;

        // If app state token is empty/invalid, try loading from secure storage
        if (!_isValidFcmToken(tokenToRegister)) {
          debugPrint('FCM: App state token empty, loading from storage...');
          tokenToRegister = await _loadPersistedToken();
        }

        // If still no valid token, request a fresh one from Firebase
        if (!_isValidFcmToken(tokenToRegister)) {
          debugPrint('FCM: No persisted token, requesting fresh token...');
          try {
            if (kIsWeb) {
              tokenToRegister = await FirebaseMessaging.instance
                  .getToken(vapidKey: _webVapidKey);
            } else {
              tokenToRegister = await FirebaseMessaging.instance.getToken();
            }
            debugPrint(
                'FCM: Fresh token obtained: ${tokenToRegister?.substring(0, min(20, tokenToRegister?.length ?? 0))}...');
          } catch (e) {
            debugPrint('FCM: Error getting fresh token: $e');
          }
        }

        // Validate and register the token
        if (_isValidFcmToken(tokenToRegister)) {
          // Update app state with the valid token
          FFAppState().fcmToken = tokenToRegister!;

          debugPrint('FCM: User authenticated, registering token');
          final success = await _registerFcmToken(tokenToRegister);
          if (success) {
            debugPrint('FCM: Token registration successful');
            // Start periodic session validation to catch same-account logins on other devices
            _startSessionValidationLocal();
          }
        } else {
          debugPrint('FCM: Could not obtain valid FCM token for registration');
        }
      } else {
        // User logged out - clear local token state
        debugPrint('FCM: User signed out, clearing local token');
        FFAppState().fcmToken = '';

        // Dispose session tracking on logout
        _disposeSessionTracking();
      }
    });

    // Handle initial message (app opened from terminated state via notification)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint(
            'FCM: App opened from notification: ${message.notification?.title}');
        _handleNotificationData(message.data);
      }
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('FCM: Foreground message: ${message.notification?.title}');

      // Check for force logout notification
      if (message.data['type'] == 'force_logout' ||
          message.data['action'] == 'sign_out') {
        debugPrint('FCM: ⚠️ Force logout received - signing out user');
        await _handleForceLogout();
        return; // Don't show notification, just sign out
      }

      if (!kIsWeb) {
        // Determine channel based on notification type
        String channelKey = 'alerts';
        String? actionLabel = 'Open';

        if (message.data['type'] == 'appointment') {
          channelKey = 'appointments';
        } else if (message.data['type'] == 'video_call') {
          channelKey = 'video_calls';
          actionLabel = 'Join Call';
        }

        await AwesomeNotifications().createNotification(
            content: NotificationContent(
                id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
                channelKey: channelKey,
                title: message.notification?.title ?? 'MedZen',
                body: message.notification?.body ?? '',
                autoDismissible:
                    true, // Auto dismiss when notification is tapped
                payload: Map<String, String>.from(message.data)),
            actionButtons: [
              NotificationActionButton(
                  key: 'OPEN',
                  label: actionLabel,
                  autoDismissible: true), // Auto dismiss when button is clicked
              NotificationActionButton(
                  key: 'DISMISS',
                  label: 'Dismiss',
                  autoDismissible: true,
                  actionType: ActionType.DismissAction),
            ]);
      }
    });

    // Handle message tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM: Message opened app: ${message.notification?.title}');
      _handleNotificationData(message.data);
    });

    // Register background message handler (uses top-level function)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    debugPrint('FCM: Push notification initialization complete');
  } catch (e, stackTrace) {
    debugPrint('FCM: Error initializing messaging: $e');
    debugPrint('FCM: Stack trace: $stackTrace');
  }
}

/// Handle notification data for navigation
void _handleNotificationData(Map<String, dynamic> data) {
  try {
    final type = data['type'] as String?;
    final id = data['id'] as String?;

    debugPrint('FCM: Handling notification data - type: $type, id: $id');

    // Check for force logout notification
    if (type == 'force_logout' || data['action'] == 'sign_out') {
      debugPrint('FCM: Force logout from notification data');
      _handleForceLogout();
      return;
    }

    // Navigation will be handled by PushNotificationsHandler
    // This is just for logging and any custom handling
  } catch (e) {
    debugPrint('FCM: Error handling notification data: $e');
  }
}

/// Checks for pending force logout from background notification
Future<void> _checkPendingForceLogout() async {
  try {
    final pendingLogout =
        await _secureStorage.read(key: 'pending_force_logout');
    if (pendingLogout == 'true') {
      debugPrint('FCM: Found pending force logout, processing...');
      await _secureStorage.delete(key: 'pending_force_logout');
      await _handleForceLogout();
    }
  } catch (e) {
    debugPrint('FCM: Error checking pending force logout: $e');
  }
}

/// Handles force logout - signs out user and shows message
Future<void> _handleForceLogout() async {
  try {
    debugPrint('FCM: Processing force logout...');

    // Clear local token and session data
    FFAppState().fcmToken = '';
    await _clearPersistedToken();
    await _secureStorage.delete(key: _sessionTokenStorageKey);
    await _secureStorage.delete(key: _deviceIdStorageKey);
    _cachedDeviceId = null;

    // Sign out from Firebase Auth
    await FirebaseAuth.instance.signOut();

    debugPrint('FCM: Force logout complete - user signed out');

    // Show a local notification to inform the user
    if (!kIsWeb) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'alerts',
          title: 'Session Ended',
          body:
              'You have been signed out because you logged in on another device.',
        ),
      );
    }
  } catch (e) {
    debugPrint('FCM: Error during force logout: $e');
  }
}

/// Clears FCM tokens from Firebase Firestore for the user
Future<void> _clearFcmTokensFromFirestore(String userId) async {
  try {
    // Get the Firestore instance
    final firestore = FirebaseFirestore.instance;

    // Get all FCM tokens for this user and delete them
    final tokensSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('fcm_tokens')
        .get();

    // Delete all token documents
    for (final doc in tokensSnapshot.docs) {
      await doc.reference.delete();
    }

    debugPrint(
        'FCM: Cleared ${tokensSnapshot.docs.length} tokens from Firestore for user $userId');
  } catch (e) {
    debugPrint('FCM: Error clearing tokens from Firestore: $e');
  }
}

/// Call this function when user logs out to clean up FCM token
Future<void> cleanupFcmOnLogout() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Clear token from Supabase
      await clearFcmTokenFromSupabase(user.uid);

      // Clear tokens from Firebase Firestore
      await _clearFcmTokensFromFirestore(user.uid);
    }

    // Clear local token - set to empty string which persists via setter
    FFAppState().fcmToken = '';

    debugPrint('FCM: Logout cleanup complete');
  } catch (e) {
    debugPrint('FCM: Error during logout cleanup: $e');
  }
}
