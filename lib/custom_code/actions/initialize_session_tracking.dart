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

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '/flutter_flow/nav/nav.dart' show appNavigatorKey;

/// Session timeout duration (5 minutes)
const Duration _sessionTimeout = Duration(minutes: 5);

/// Warning time before logout (1 minute before timeout = 4 minutes)
const Duration _warningTime = Duration(minutes: 4);

/// Check interval for inactivity
const Duration _checkInterval = Duration(seconds: 30);

/// Private singleton for session activity management
/// Uses underscore prefix to be private to this file (FlutterFlow compatible)
class _SessionActivityManager {
  static _SessionActivityManager? _instance;
  static _SessionActivityManager get instance {
    _instance ??= _SessionActivityManager._internal();
    return _instance!;
  }

  _SessionActivityManager._internal();

  DateTime _lastActivityTime = DateTime.now();
  Timer? _inactivityTimer;
  bool _isPaused = false;
  bool _isWarningShown = false;
  bool _isInitialized = false;
  VoidCallback? _onSessionExpired;

  bool get isInitialized => _isInitialized;

  void initialize(BuildContext context, {VoidCallback? onSessionExpired}) {
    if (_isInitialized) {
      debugPrint('SessionActivityManager: Already initialized, skipping');
      return;
    }

    _onSessionExpired = onSessionExpired;
    _lastActivityTime = DateTime.now();
    _isWarningShown = false;
    _isPaused = false;
    _isInitialized = true;
    _startInactivityTimer();
    debugPrint('SessionActivityManager: Initialized with 5-minute timeout');
  }

  void dispose() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _isWarningShown = false;
    _isInitialized = false;
    _isPaused = false;
    debugPrint('SessionActivityManager: Disposed');
  }

  void recordActivity() {
    if (_isPaused || !_isInitialized) return;

    final wasInactive =
        DateTime.now().difference(_lastActivityTime).inSeconds > 30;
    _lastActivityTime = DateTime.now();

    if (wasInactive) {
      debugPrint('SessionActivityManager: Activity recorded');
    }

    if (_isWarningShown) {
      _isWarningShown = false;
      _dismissWarningDialog();
    }
  }

  void _dismissWarningDialog() {
    try {
      final navigator = appNavigatorKey.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.pop();
      }
    } catch (e) {
      debugPrint('SessionActivityManager: Error dismissing dialog: $e');
    }
  }

  void pauseTimer() {
    _isPaused = true;
    debugPrint('SessionActivityManager: Timer paused');
  }

  void resumeTimer() {
    _isPaused = false;
    _lastActivityTime = DateTime.now();
    debugPrint('SessionActivityManager: Timer resumed');
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer.periodic(_checkInterval, (_) {
      _checkInactivity();
    });
  }

  void _checkInactivity() {
    if (_isPaused || !_isInitialized) return;

    final now = DateTime.now();
    final inactiveFor = now.difference(_lastActivityTime);

    if (inactiveFor >= _sessionTimeout) {
      debugPrint('SessionActivityManager: Session timeout - logging out');
      _handleSessionExpired();
      return;
    }

    if (inactiveFor >= _warningTime && !_isWarningShown) {
      _showTimeoutWarning();
    }
  }

  void _showTimeoutWarning() {
    if (_isWarningShown) return;

    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    _isWarningShown = true;

    showDialog(
      context: navigator.context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _TimeoutWarningDialog(
          onStayLoggedIn: () {
            recordActivity();
            Navigator.of(dialogContext).pop();
          },
          onLogout: () {
            Navigator.of(dialogContext).pop();
            _handleSessionExpired();
          },
        );
      },
    ).then((_) {
      _isWarningShown = false;
    }).catchError((e) {
      _isWarningShown = false;
    });
  }

  Future<void> _handleSessionExpired() async {
    dispose();
    _onSessionExpired?.call();

    try {
      await FirebaseAuth.instance.signOut();
      debugPrint('SessionActivityManager: User signed out due to inactivity');
    } catch (e) {
      debugPrint('SessionActivityManager: Error signing out: $e');
    }
  }

  Duration get remainingTime {
    final elapsed = DateTime.now().difference(_lastActivityTime);
    final remaining = _sessionTimeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isActive =>
      _isInitialized && !_isPaused && remainingTime > Duration.zero;

  String get debugStatus {
    final remaining = remainingTime;
    return 'Init: $_isInitialized, Paused: $_isPaused, '
        'Remaining: ${remaining.inMinutes}m ${remaining.inSeconds % 60}s';
  }
}

/// Timeout warning dialog
class _TimeoutWarningDialog extends StatefulWidget {
  final VoidCallback onStayLoggedIn;
  final VoidCallback onLogout;

  const _TimeoutWarningDialog({
    required this.onStayLoggedIn,
    required this.onLogout,
  });

  @override
  State<_TimeoutWarningDialog> createState() => _TimeoutWarningDialogState();
}

class _TimeoutWarningDialogState extends State<_TimeoutWarningDialog> {
  late Timer _countdownTimer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsRemaining--;
          if (_secondsRemaining <= 0) {
            timer.cancel();
            widget.onLogout();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          SizedBox(width: 8),
          Text('Session Timeout'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'You have been inactive. For security, you will be logged out soon.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Logging out in $_secondsRemaining seconds',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onLogout,
          child: const Text('Logout Now'),
        ),
        ElevatedButton(
          onPressed: widget.onStayLoggedIn,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Stay Logged In'),
        ),
      ],
    );
  }
}

// ============================================================================
// PUBLIC HELPER FUNCTIONS - These are what FlutterFlow actions should call
// ============================================================================

/// Initialize session activity tracking (call after login)
Future<void> initializeSessionTracking(BuildContext context) async {
  _SessionActivityManager.instance.initialize(context);
}

/// Record user activity (call on user interactions)
void recordUserActivity() {
  _SessionActivityManager.instance.recordActivity();
}

/// Pause session timeout (call when entering video call)
void pauseSessionTimeout() {
  _SessionActivityManager.instance.pauseTimer();
}

/// Resume session timeout (call when exiting video call)
void resumeSessionTimeout() {
  _SessionActivityManager.instance.resumeTimer();
}

/// Dispose session tracking (call on logout)
void disposeSessionTracking() {
  _SessionActivityManager.instance.dispose();
}

/// Get session debug status
String getSessionDebugStatus() {
  return _SessionActivityManager.instance.debugStatus;
}
