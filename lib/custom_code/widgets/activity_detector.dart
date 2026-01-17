// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets
// import '/custom_code/actions/index.dart'; // Not needed - widget is self-contained

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '/flutter_flow/nav/nav.dart' show appNavigatorKey;

/// A widget that detects user activity and records it to the session manager.
///
/// Wrap your main app content with this widget to enable inactivity timeout.
///
/// Usage: ```dart ActivityDetector( child: YourMainContent(), ) ```
class ActivityDetector extends StatefulWidget {
  const ActivityDetector({
    super.key,
    required this.child,
    this.width,
    this.height,
  });

  final Widget child;
  final double? width;
  final double? height;

  @override
  State<ActivityDetector> createState() => _ActivityDetectorState();
}

class _ActivityDetectorState extends State<ActivityDetector>
    with WidgetsBindingObserver {
  bool _isInitialized = false;
  late StreamSubscription<fb_auth.User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize session tracking after first frame if user is logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeIfLoggedIn();
    });

    // Listen for auth state changes to initialize/dispose session tracking
    _authSubscription = fb_auth.FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && !_isInitialized) {
        _initializeIfLoggedIn();
      } else if (user == null && _isInitialized) {
        _SessionActivityManager.instance.dispose();
        _isInitialized = false;
      }
    });
  }

  void _initializeIfLoggedIn() {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user != null && !_isInitialized && mounted) {
      _SessionActivityManager.instance.initialize(context);
      _isInitialized = true;
      debugPrint('ActivityDetector: Session tracking initialized for user');
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_isInitialized) {
      _SessionActivityManager.instance.dispose();
      _isInitialized = false;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!_isInitialized) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - record activity
        debugPrint('ActivityDetector: App resumed');
        _SessionActivityManager.instance.recordActivity();
        break;
      case AppLifecycleState.paused:
        // App went to background
        debugPrint('ActivityDetector: App paused');
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onUserActivity() {
    if (_isInitialized) {
      _SessionActivityManager.instance.recordActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _onUserActivity(),
      onPointerMove: (_) => _onUserActivity(),
      onPointerUp: (_) => _onUserActivity(),
      behavior: HitTestBehavior.translucent,
      child: GestureDetector(
        onTap: _onUserActivity,
        onPanUpdate: (_) => _onUserActivity(),
        onScaleUpdate: (_) => _onUserActivity(),
        behavior: HitTestBehavior.translucent,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            _onUserActivity();
            return false; // Allow notification to continue propagating
          },
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EMBEDDED SessionActivityManager - Self-contained for FlutterFlow
// ============================================================================

/// Session timeout duration (5 minutes)
const Duration _sessionTimeout = Duration(minutes: 5);

/// Warning time before logout (1 minute before timeout = 4 minutes)
const Duration _warningTime = Duration(minutes: 4);

/// Check interval for inactivity
const Duration _checkInterval = Duration(seconds: 30);

/// Singleton instance for session activity management
/// Named with underscore prefix to be private to this file
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
      await fb_auth.FirebaseAuth.instance.signOut();
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
