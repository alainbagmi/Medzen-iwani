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

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

/// ✨ ENHANCED CHIME VIDEO CALL WIDGET - AWS Demo Features + Web Support
///
/// Features matching AWS Chime SDK official demo: - ✅ Multi-participant video
/// grid (1-16 participants) - ✅ Attendee roster with real-time status
/// indicators - ✅ Active speaker detection and highlighting - ✅ Meeting
/// controls (mute, video, chat, leave) - ✅ Portrait and landscape responsive
/// layouts - ✅ Professional dark theme UI - ✅ Network quality indicators - ✅
/// Web platform support (bonus!)
///
/// FlutterFlow Compatible: ✅ Yes Platforms: Android, iOS, Web SDK: Amazon
/// Chime SDK v3.19.0 (loaded from CDN)
class ChimeMeetingEnhanced extends StatefulWidget {
  const ChimeMeetingEnhanced({
    super.key,
    this.width,
    this.height,
    required this.meetingData,
    required this.attendeeData,
    this.userName = 'User',
    this.userProfileImage,
    this.userRole,
    this.providerName,
    this.providerRole,
    this.appointmentId,
    this.appointmentDate,
    this.onCallEnded,
    this.showAttendeeRoster = true,
    this.showChat = true,
    this.isProvider = false,
    this.initialMicEnabled = true,
    this.initialCameraEnabled = true,
  });

  final double? width;
  final double? height;
  final String meetingData;
  final String attendeeData;
  final String userName;
  final String? userProfileImage;
  final String? userRole;
  final String? providerName;
  final String? providerRole;
  final String? appointmentId;
  final DateTime? appointmentDate;
  final Future<dynamic> Function()? onCallEnded;
  final bool showAttendeeRoster;
  final bool showChat;
  final bool
      isProvider; // true = provider (can end call), false = patient (can only leave)
  final bool initialMicEnabled; // Initial mic state from pre-joining dialog
  final bool
      initialCameraEnabled; // Initial camera state from pre-joining dialog

  @override
  _ChimeMeetingEnhancedState createState() => _ChimeMeetingEnhancedState();
}

class _ChimeMeetingEnhancedState extends State<ChimeMeetingEnhanced> {
  InAppWebViewController? _webViewController;
  final GlobalKey webViewKey = GlobalKey();
  bool _isLoading = true;
  bool _sdkReady = false;
  Timer? _sdkLoadTimeout;

  // Enhanced state management (matching AWS demo)
  final Map<String, Map<String, dynamic>> _attendees = {};
  final Map<int, String> _videoTiles = {};
  String? _activeSpeakerId;
  bool _isMuted = false;
  bool _isVideoOff = false;
  final bool _showRoster = false;
  bool _showChat = false;
  int _participantCount = 0;
  String? _meetingId;
  RealtimeChannel? _messageChannel;
  bool _messagesLoaded = false; // Track if messages have been loaded
  DateTime? _subscriptionStartTime; // Track when subscription starts
  final Set<String> _processedMessageIds = {}; // Track processed message IDs
  static const int _maxProcessedMessageIds =
      500; // Limit to prevent memory leak
  int _unreadMessageCount = 0; // Track unread messages when chat is closed

  // === TRANSCRIPTION STATE VARIABLES ===
  bool _isTranscriptionEnabled = false;
  bool _isTranscriptionStarting = false;
  final String _transcriptionLanguage = 'en-US';
  String? _sessionId; // Video call session ID for transcription
  RealtimeChannel? _captionChannel; // Realtime channel for live captions
  final List<Map<String, dynamic>> _liveCaptions = []; // Recent live captions
  String? _currentCaption; // Currently displayed caption text
  String? _currentSpeaker; // Currently speaking person's name
  Timer? _captionFadeTimer; // Timer to fade out old captions
  bool _showCaptionOverlay = true; // Whether to show caption overlay

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 Initializing Enhanced Chime Meeting (AWS Demo Features)');

    // Initialize mic/camera state from widget parameters (set by pre-joining dialog)
    _isMuted = !widget.initialMicEnabled;
    _isVideoOff = !widget.initialCameraEnabled;
    debugPrint(
        '📹 Initial mic enabled: ${widget.initialMicEnabled} (muted: $_isMuted)');
    debugPrint(
        '📹 Initial camera enabled: ${widget.initialCameraEnabled} (video off: $_isVideoOff)');

    _extractMeetingId();
    _checkPermissionsAndInitialize();
  }

  /// Check camera/microphone permissions before initializing WebView
  Future<void> _checkPermissionsAndInitialize() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      debugPrint('📹 Checking camera/microphone permissions...');

      // Check current permission status
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;

      debugPrint('📹 Camera permission: $cameraStatus');
      debugPrint('🎤 Microphone permission: $micStatus');

      // Request permissions if not granted
      if (!cameraStatus.isGranted || !micStatus.isGranted) {
        final results = await [
          Permission.camera,
          Permission.microphone,
        ].request();

        final cameraResult = results[Permission.camera];
        final micResult = results[Permission.microphone];

        debugPrint('📹 Camera request result: $cameraResult');
        debugPrint('🎤 Microphone request result: $micResult');

        // Show warning if permissions denied
        if (cameraResult?.isDenied == true || micResult?.isDenied == true) {
          _showPermissionWarning(
            cameraResult?.isDenied == true,
            micResult?.isDenied == true,
          );
        }

        // If permanently denied, show settings prompt
        if (cameraResult?.isPermanentlyDenied == true ||
            micResult?.isPermanentlyDenied == true) {
          _showOpenSettingsDialog();
        }
      }
    }

    // Continue with initialization
    _initializeWebView();
    _startSdkLoadTimeout();

    // Initialize message subscription for realtime chat
    if (widget.appointmentId != null) {
      _subscribeToMessages();
    }
  }

  void _showPermissionWarning(bool cameraDenied, bool micDenied) {
    if (!mounted) return;

    String message;
    if (cameraDenied && micDenied) {
      message =
          'Camera and microphone access denied. You can still join but others won\'t see or hear you.';
    } else if (cameraDenied) {
      message = 'Camera access denied. Others won\'t be able to see you.';
    } else {
      message = 'Microphone access denied. Others won\'t be able to hear you.';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.black87),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(message,
                        style: const TextStyle(color: Colors.black87))),
              ],
            ),
            backgroundColor: const Color(0xFFFFB74D),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    });
  }

  void _showOpenSettingsDialog() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
              'Camera and microphone permissions are required for video calls. '
              'Please enable them in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    });
  }

  void _extractMeetingId() {
    try {
      debugPrint('🔍 Extracting meeting ID from meetingData...');
      debugPrint('   meetingData length: ${widget.meetingData.length}');
      final meetingMap = jsonDecode(widget.meetingData);
      debugPrint('   meetingMap keys: ${meetingMap.keys.toList()}');
      _meetingId =
          meetingMap['MeetingId'] ?? meetingMap['Meeting']?['MeetingId'];
      debugPrint('📋 Meeting ID extracted: $_meetingId');
      if (_meetingId == null) {
        debugPrint('⚠️ MeetingId not found in meetingData');
        debugPrint('   Available keys: ${meetingMap.keys.toList()}');
        if (meetingMap.containsKey('Meeting')) {
          debugPrint(
              '   Meeting object keys: ${meetingMap['Meeting']?.keys?.toList()}');
        }
      }
    } catch (e) {
      debugPrint('❌ Could not extract meeting ID: $e');
      debugPrint(
          '   meetingData: ${widget.meetingData.substring(0, widget.meetingData.length.clamp(0, 200))}...');
    }
  }

  @override
  void dispose() {
    _sdkLoadTimeout?.cancel();

    // Stop transcription if still active
    if (_isTranscriptionEnabled) {
      debugPrint('🛑 Stopping transcription on dispose...');
      _stopTranscription();
    }

    // Cleanup transcription resources
    _captionFadeTimer?.cancel();
    if (_captionChannel != null) {
      SupaFlow.client.removeChannel(_captionChannel!);
    }

    // Unsubscribe from message channel
    if (_messageChannel != null) {
      SupaFlow.client.removeChannel(_messageChannel!);
    }

    // Clear processed message IDs to free memory
    _processedMessageIds.clear();

    super.dispose();
  }

  void _startSdkLoadTimeout() {
    // Increased timeout for emulators (120s) - physical devices typically load in 5-10s
    _sdkLoadTimeout = Timer(const Duration(seconds: 120), () {
      if (!_sdkReady && mounted) {
        debugPrint('❌ Chime SDK load timeout after 120 seconds');
        _showErrorSnackBar(
            'Failed to load video call SDK. Please check your internet connection.');
        if (widget.onCallEnded != null) {
          widget.onCallEnded!();
        }
      }
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Shows an in-app notification banner when a new message arrives
  void _showMessageNotificationBanner(
      String senderName, String messageContent) {
    if (!mounted) return;

    // Increment unread count
    setState(() {
      _unreadMessageCount++;
    });

    // Truncate message content for display
    final displayMessage = messageContent.length > 50
        ? '${messageContent.substring(0, 50)}...'
        : messageContent;

    // Show a professional notification banner at the top
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GestureDetector(
          onTap: () {
            // Open chat when tapping the notification
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _webViewController?.evaluateJavascript(source: 'toggleChat(true);');
            setState(() {
              _showChat = true;
              _unreadMessageCount = 0;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                // Chat icon with green indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366), // WhatsApp green
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        senderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayMessage,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Tap to open chat hint
                Text(
                  'Tap to open',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: const Color(0xFF1C2833), // Dark theme
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF25D366), width: 1),
        ),
        elevation: 8,
        dismissDirection: DismissDirection.horizontal,
      ),
    );

    // Also trigger device haptic feedback
    _triggerHapticFeedback();
  }

  /// Triggers haptic feedback for message notification
  void _triggerHapticFeedback() {
    try {
      // Use Flutter's feedback mechanism
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('⚠️ Haptic feedback not available: $e');
    }
  }

  void _initializeWebView() {
    // With flutter_inappwebview, the WebView is initialized in the build method
    // The controller is obtained via onWebViewCreated callback
    debugPrint('🔧 InAppWebView initialization will occur in build method');
    // Just trigger a rebuild to show the WebView
    if (mounted) {
      setState(() {});
    }
  }

  /// Get InAppWebView settings with full WebRTC support for video calls
  InAppWebViewSettings _getWebViewSettings() {
    return InAppWebViewSettings(
      // Core JavaScript settings
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,

      // WebRTC and Media settings - CRITICAL for video calls
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,

      // Android-specific settings
      useHybridComposition: true, // Better WebRTC support on Android
      useShouldOverrideUrlLoading: true,
      allowFileAccess: true,
      allowContentAccess: true,
      geolocationEnabled: true,

      // iOS-specific settings
      allowsAirPlayForMediaPlayback: true,
      allowsPictureInPictureMediaPlayback: true,

      // General settings
      transparentBackground: false,
      supportZoom: false,
      verticalScrollBarEnabled: false,
      horizontalScrollBarEnabled: false,
      disableContextMenu: false,

      // Security settings
      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,

      // Enable debugging on Android
      isInspectable: true, // Allows debugging in Chrome DevTools
    );
  }

  /// Handle WebView creation - called when InAppWebView is ready
  void _onWebViewCreated(InAppWebViewController controller) {
    debugPrint('✅ InAppWebView created');
    _webViewController = controller;

    // Add JavaScript handlers for Flutter communication
    controller.addJavaScriptHandler(
      handlerName: 'FlutterChannel',
      callback: (args) {
        if (args.isNotEmpty) {
          _handleMessageFromWebView(args[0].toString());
        }
        return null;
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'ConsoleLog',
      callback: (args) {
        if (args.isNotEmpty) {
          debugPrint('🌐 JS: ${args[0]}');
        }
        return null;
      },
    );
  }

  /// Handle permission requests from WebView (camera, microphone)
  Future<PermissionResponse> _onPermissionRequest(
    InAppWebViewController controller,
    PermissionRequest permissionRequest,
  ) async {
    debugPrint('📹 Permission request: ${permissionRequest.resources}');
    // Grant all media permissions - we've already checked device permissions
    return PermissionResponse(
      resources: permissionRequest.resources,
      action: PermissionResponseAction.GRANT,
    );
  }

  /// Handle progress updates
  void _onProgressChanged(InAppWebViewController controller, int progress) {
    if (progress == 100 && _isLoading) {
      setState(() => _isLoading = false);
    }
  }

  /// Handle page load start
  void _onLoadStart(InAppWebViewController controller, WebUri? url) {
    setState(() => _isLoading = true);
  }

  /// Handle page load finish
  void _onLoadStop(InAppWebViewController controller, WebUri? url) {
    setState(() => _isLoading = false);
  }

  /// Handle console messages from JavaScript
  void _onConsoleMessage(
    InAppWebViewController controller,
    ConsoleMessage consoleMessage,
  ) {
    debugPrint(
        '🌐 Console [${consoleMessage.messageLevel}]: ${consoleMessage.message}');
  }

  /// Handle web resource errors
  void _onReceivedError(
    InAppWebViewController controller,
    WebResourceRequest request,
    WebResourceError error,
  ) {
    debugPrint('🌐 WebView Error: ${error.description} (${error.type})');
  }

  void _handleMessageFromWebView(String message) {
    debugPrint('📱 Message from WebView: $message');

    try {
      if (message == 'SDK_READY') {
        _handleSdkReady();
      } else if (message.startsWith('MEETING_ENDED_BY_PROVIDER:')) {
        // Provider ended the call - call edge function to end for everyone
        final meetingId =
            message.replaceFirst('MEETING_ENDED_BY_PROVIDER:', '');
        _endMeetingOnServer(meetingId);
      } else if (message == 'MEETING_ENDED_BY_HOST') {
        // Meeting was ended by the host (provider) - close UI for patient
        debugPrint('📞 Meeting ended by host - closing call for patient');
        _handleMeetingEnd('MEETING_ENDED_BY_HOST');
      } else if (message.startsWith('MEETING_LEFT') ||
          message.startsWith('MEETING_ERROR')) {
        _handleMeetingEnd(message);
      } else if (message.startsWith('MEETING_JOINED')) {
        _handleMeetingJoined();
      } else if (message == 'CHAT_OPENED') {
        // Chat panel was opened - reset unread count
        setState(() {
          _showChat = true;
          _unreadMessageCount = 0;
        });
        debugPrint('📨 Chat opened - reset unread count');
      } else if (message == 'CHAT_CLOSED') {
        // Chat panel was closed
        setState(() {
          _showChat = false;
        });
        debugPrint('📨 Chat closed');
      } else {
        // Try parsing as JSON for structured events
        final data = jsonDecode(message);
        _handleStructuredEvent(data);
      }
    } catch (e) {
      // Not JSON, handle as simple string message
      if (message.startsWith('ATTENDEE_')) {
        _handleAttendeeEvent(message);
      } else if (message.startsWith('VIDEO_TILE_')) {
        _handleVideoTileEvent(message);
      } else if (message.startsWith('ACTIVE_SPEAKER:')) {
        _handleActiveSpeaker(message);
      }
    }
  }

  // Provider ends the meeting on the server
  Future<void> _endMeetingOnServer(String meetingId) async {
    debugPrint('📞 Ending meeting on server: $meetingId');

    try {
      // Get Firebase token for auth (true = force refresh)
      final firebaseToken =
          await FirebaseAuth.instance.currentUser?.getIdToken(true);

      if (firebaseToken == null) {
        debugPrint('❌ No Firebase token available');
        _handleMeetingEnd('MEETING_LEFT');
        return;
      }

      // Call edge function to end the meeting
      final response = await SupaFlow.client.functions.invoke(
        'chime-meeting-token',
        body: {
          'action': 'end',
          'meetingId': meetingId,
        },
        headers: {
          'x-firebase-token': firebaseToken,
        },
      );

      if (response.status == 200) {
        debugPrint('✅ Meeting ended successfully on server');
      } else {
        debugPrint('⚠️ Server end response: ${response.status}');
      }
    } catch (e) {
      debugPrint('❌ Error ending meeting on server: $e');
    }

    // Always trigger the callback to close the UI
    _handleMeetingEnd('MEETING_ENDED_BY_PROVIDER');
  }

  void _handleSdkReady() {
    debugPrint('✅ Chime SDK loaded and ready');
    _sdkLoadTimeout?.cancel();
    setState(() => _sdkReady = true);
    _joinMeeting();
  }

  void _handleMeetingEnd(String message) {
    debugPrint('📞 Meeting ended: $message');
    if (widget.onCallEnded != null) {
      widget.onCallEnded!();
    }
  }

  void _handleMeetingJoined() {
    debugPrint('✅ Successfully joined meeting');

    // Register self-attendee if not already in the attendees map
    final selfAttendeeId = _getSelfAttendeeId();
    if (selfAttendeeId != null && !_attendees.containsKey(selfAttendeeId)) {
      _attendees[selfAttendeeId] = {
        'name': widget.userName ?? 'You',
        'isMuted': _isMuted,
        'videoEnabled': !_isVideoOff,
        'joinedAt': DateTime.now().toIso8601String(),
        'isSelf': true,
      };
    }

    setState(() =>
        _participantCount = _attendees.isNotEmpty ? _attendees.length : 1);

    // Auto-start transcription for providers after a short delay
    // to ensure the meeting is fully established
    if (widget.isProvider) {
      debugPrint('🎙️ Provider joined - preparing transcription auto-start...');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isTranscriptionEnabled && !_isTranscriptionStarting) {
          debugPrint('🎙️ Auto-starting transcription for provider...');
          _startTranscription();
        }
      });
    } else {
      // Patients also subscribe to captions if available
      debugPrint(
          '👤 Patient joined - will subscribe to captions when available');
      _fetchSessionId().then((_) {
        if (_sessionId != null) {
          _subscribeToCaptions();
        }
      });
    }
  }

  void _handleStructuredEvent(Map<String, dynamic> data) {
    final type = data['type'];
    debugPrint('📨 Structured event: $type');

    switch (type) {
      case 'ATTENDEE_JOINED':
        _onAttendeeJoined(data);
        break;
      case 'ATTENDEE_LEFT':
        _onAttendeeLeft(data);
        break;
      case 'ATTENDEE_MUTED':
        _onAttendeeMuted(data);
        break;
      case 'ATTENDEE_UNMUTED':
        _onAttendeeUnmuted(data);
        break;
      case 'VIDEO_ENABLED':
        _onVideoEnabled(data);
        break;
      case 'VIDEO_DISABLED':
        _onVideoDisabled(data);
        break;
      case 'VIDEO_TILE_ADDED':
        _onVideoTileAdded(data);
        break;
      case 'VIDEO_TILE_REMOVED':
        _onVideoTileRemoved(data);
        break;
      case 'ACTIVE_SPEAKER_CHANGED':
        _onActiveSpeakerChanged(data);
        break;
      case 'SEND_MESSAGE':
        _handleSendMessage(data['data']);
        break;
      case 'LOAD_MESSAGES':
        _loadMessages();
        break;
      case 'CHAT_VISIBILITY':
        _handleChatVisibility(data['visible'] ?? false);
        break;
      case 'DEVICE_ERROR':
        _handleDeviceError(
            data['message'] ?? 'Camera and microphone unavailable');
        break;
      case 'DEVICE_WARNING':
        _handleDeviceWarning(data['message'] ?? 'Some devices unavailable');
        break;
      case 'JS_ERROR':
        _handleJsError(data);
        break;
      case 'PROMISE_REJECTION':
        _handlePromiseRejection(data);
        break;
    }
  }

  /// Handle JavaScript errors caught by global error handler
  void _handleJsError(Map<String, dynamic> data) {
    final errorType = data['errorType'] ?? 'Unknown';
    final message = data['message'] ?? 'No message';
    final line = data['line'] ?? 0;
    final column = data['column'] ?? 0;
    final stack = data['stack'] ?? '';

    debugPrint('🚨 [JS_ERROR] [$errorType] $message');
    debugPrint('   Location: line $line, column $column');
    if (stack.isNotEmpty) {
      debugPrint('   Stack: ${stack.toString().split('\n').take(3).join(' | ')}');
    }

    // For TypeErrors, log additional diagnostic info
    if (errorType == 'TypeError') {
      debugPrint('   ⚠️ TypeError detected - this may indicate:');
      debugPrint('      • Accessing undefined/null object property');
      debugPrint('      • Calling method on undefined/null object');
      debugPrint('      • API method not supported in WebView');
    }
  }

  /// Handle unhandled promise rejections
  void _handlePromiseRejection(Map<String, dynamic> data) {
    final errorType = data['errorType'] ?? 'Unknown';
    final message = data['message'] ?? 'No message';
    final stack = data['stack'] ?? '';

    debugPrint('🚨 [PROMISE_REJECTION] [$errorType] $message');
    if (stack.isNotEmpty) {
      debugPrint('   Stack: ${stack.toString().split('\n').take(3).join(' | ')}');
    }

    // For TypeErrors in async code, log additional diagnostic info
    if (errorType == 'TypeError') {
      debugPrint('   ⚠️ Async TypeError detected - this may indicate:');
      debugPrint('      • Failed await on undefined promise');
      debugPrint('      • API returned unexpected type');
      debugPrint('      • Device API compatibility issue');
    }
  }

  void _handleDeviceError(String message) {
    debugPrint('❌ Device error: $message');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.videocam_off, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Camera/Microphone Unavailable',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () {
              // This could open device settings on supported platforms
              debugPrint('📱 User tapped Settings');
            },
          ),
        ),
      );
    }
  }

  void _handleDeviceWarning(String message) {
    debugPrint('⚠️ Device warning: $message');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.black87),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFFB74D),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _handleChatVisibility(bool visible) {
    debugPrint('💬 Chat visibility changed: $visible');
    setState(() {
      _showChat = visible;
      // Reset unread count when chat is opened
      if (visible) {
        _unreadMessageCount = 0;
      }
    });
  }

  void _handleAttendeeEvent(String message) {
    // Legacy string-based event handling
    if (message.startsWith('ATTENDEE_JOINED:')) {
      final parts = message.split(':');
      if (parts.length >= 3) {
        _onAttendeeJoined({
          'attendeeId': parts[1],
          'name': parts.length > 2 ? parts[2] : 'Unknown',
        });
      }
    }
  }

  void _handleVideoTileEvent(String message) {
    // Legacy video tile event handling
    final parts = message.split(':');
    if (message.startsWith('VIDEO_TILE_ADDED:') && parts.length >= 3) {
      _onVideoTileAdded({
        'tileId': int.parse(parts[1]),
        'attendeeId': parts[2],
      });
    } else if (message.startsWith('VIDEO_TILE_REMOVED:') && parts.length >= 2) {
      _onVideoTileRemoved({'tileId': int.parse(parts[1])});
    }
  }

  void _handleActiveSpeaker(String message) {
    final parts = message.split(':');
    if (parts.length >= 2) {
      _onActiveSpeakerChanged({'attendeeId': parts[1]});
    }
  }

  // Attendee state management methods
  void _onAttendeeJoined(Map<String, dynamic> data) {
    final attendeeId = data['attendeeId'] as String;
    final name = data['name'] as String? ?? 'Unknown';

    setState(() {
      _attendees[attendeeId] = {
        'name': name,
        'isMuted': false,
        'videoEnabled': true,
        'joinedAt': DateTime.now().toIso8601String(),
        'isSelf': attendeeId == _getSelfAttendeeId(),
      };
      _participantCount = _attendees.length;
    });

    debugPrint('👤 Attendee joined: $name ($attendeeId)');
  }

  void _onAttendeeLeft(Map<String, dynamic> data) {
    final attendeeId = data['attendeeId'] as String;

    setState(() {
      _attendees.remove(attendeeId);
      _participantCount = _attendees.length;
      if (_activeSpeakerId == attendeeId) {
        _activeSpeakerId = null;
      }
    });

    debugPrint('👋 Attendee left: $attendeeId');
  }

  void _onAttendeeMuted(Map<String, dynamic> data) {
    final attendeeId = data['attendeeId'] as String;
    setState(() {
      _attendees[attendeeId]?['isMuted'] = true;
    });
    debugPrint('🔇 Attendee muted: $attendeeId');
  }

  void _onAttendeeUnmuted(Map<String, dynamic> data) {
    final attendeeId = data['attendeeId'] as String;
    setState(() {
      _attendees[attendeeId]?['isMuted'] = false;
    });
    debugPrint('🔊 Attendee unmuted: $attendeeId');
  }

  void _onVideoEnabled(Map<String, dynamic> data) {
    final attendeeId = data['attendeeId'] as String;
    setState(() {
      _attendees[attendeeId]?['videoEnabled'] = true;
    });
    debugPrint('📹 Video enabled: $attendeeId');
  }

  void _onVideoDisabled(Map<String, dynamic> data) {
    final attendeeId = data['attendeeId'] as String;
    setState(() {
      _attendees[attendeeId]?['videoEnabled'] = false;
    });
    debugPrint('📷 Video disabled: $attendeeId');
  }

  void _onVideoTileAdded(Map<String, dynamic> data) {
    final tileId = data['tileId'] as int;
    final attendeeId = data['attendeeId'] as String;

    setState(() {
      _videoTiles[tileId] = attendeeId;
    });

    debugPrint('🎥 Video tile added: $tileId -> $attendeeId');
  }

  void _onVideoTileRemoved(Map<String, dynamic> data) {
    final tileId = data['tileId'] as int;

    setState(() {
      _videoTiles.remove(tileId);
    });

    debugPrint('📴 Video tile removed: $tileId');
  }

  void _onActiveSpeakerChanged(Map<String, dynamic> data) {
    final attendeeId = data['attendeeId'] as String?;

    setState(() {
      _activeSpeakerId = attendeeId;
    });

    if (attendeeId != null) {
      final name = _attendees[attendeeId]?['name'] ?? 'Unknown';
      debugPrint('🗣️ Active speaker: $name');
    }
  }

  String? _getSelfAttendeeId() {
    try {
      final attendeeMap = jsonDecode(widget.attendeeData);
      return attendeeMap['AttendeeId'] ??
          attendeeMap['Attendee']?['AttendeeId'];
    } catch (e) {
      return null;
    }
  }

  /// Fetch Supabase UUID from Firestore using Firebase Auth UID
  Future<String?> _getSupabaseUserId() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        debugPrint('⚠️ No Firebase user authenticated');
        return null;
      }

      final firebaseUid = firebaseUser.uid;
      debugPrint('🔑 Firebase UID: $firebaseUid');

      // Fetch Supabase UUID from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUid)
          .get();

      if (!doc.exists) {
        debugPrint('⚠️ User document not found in Firestore');
        return null;
      }

      final supabaseUuid = doc.data()?['supabase_uuid'] as String?;
      if (supabaseUuid == null) {
        debugPrint('⚠️ supabase_uuid field not found in Firestore');
        return null;
      }

      debugPrint('✅ Supabase UUID: $supabaseUuid');
      return supabaseUuid;
    } catch (e) {
      debugPrint('❌ Error fetching Supabase UUID: $e');
      return null;
    }
  }

  Future<void> _handleSendMessage(Map<String, dynamic> data) async {
    try {
      debugPrint('💬 Handling chat message: ${data['messageType']}');

      // Get Supabase UUID from Firestore (using Firebase Auth UID)
      final userId = await _getSupabaseUserId();
      if (userId == null) {
        debugPrint('⚠️ No Supabase user ID available');
        return;
      }

      String? fileUrl;

      // Handle file upload if present
      if (data['fileData'] != null && data['fileName'] != null) {
        try {
          final fileData = data['fileData'] as String;
          final fileName = data['fileName'] as String;
          final fileType =
              data['fileType'] as String? ?? 'application/octet-stream';

          // Extract base64 data (remove data:mime/type;base64, prefix)
          final base64Data =
              fileData.contains(',') ? fileData.split(',').last : fileData;
          final bytes = base64Decode(base64Data);

          // Sanitize filename for storage
          final sanitizedName = fileName.replaceAll(RegExp(r'[^\w\-.]'), '_');
          final timestamp = DateTime.now().millisecondsSinceEpoch;

          // Upload to Supabase Storage
          final path =
              'chat-files/${widget.appointmentId ?? _meetingId}/${timestamp}_$sanitizedName';

          await SupaFlow.client.storage.from('chime_storage').uploadBinary(
                path,
                bytes,
                fileOptions: FileOptions(
                  contentType: fileType,
                  upsert: true,
                ),
              );

          // Get public URL
          fileUrl =
              SupaFlow.client.storage.from('chime_storage').getPublicUrl(path);

          debugPrint('📎 File uploaded successfully: $fileUrl');
          debugPrint('📎 File size: ${bytes.length} bytes, type: $fileType');
        } catch (uploadError) {
          debugPrint('❌ File upload failed: $uploadError');
          // Continue without file URL - message will still be saved
        }
      }

      // Save message to Supabase (appointment-based chat)
      final senderName = data['sender'] as String? ?? widget.userName;
      final senderRole = data['role'] as String? ?? widget.userRole ?? '';
      final senderAvatar =
          data['profileImage'] as String? ?? widget.userProfileImage ?? '';

      final messageData = {
        'appointment_id':
            widget.appointmentId, // Link to appointment instead of channel
        'channel_id': _meetingId, // Keep for backward compatibility
        'user_id': userId,
        'sender_id': userId,
        'sender_name':
            senderRole.isNotEmpty ? '$senderRole $senderName' : senderName,
        'sender_avatar': senderAvatar,
        'message': data['message'] ?? '',
        'message_content': data['message'] ?? '',
        'message_type': data['messageType'] ?? 'text',
        'metadata': jsonEncode({
          'sender': senderName,
          'role': senderRole,
          'profileImage': senderAvatar,
          'fileName': data['fileName'],
          'fileUrl': fileUrl,
          'fileSize': data['fileSize'],
          'timestamp': data['timestamp'],
        }),
      };

      await SupaFlow.client.from('chime_messages').insert(messageData);

      debugPrint(
          '✅ Message saved to Supabase (appointment: ${widget.appointmentId})');
    } catch (e) {
      debugPrint('❌ Error handling message: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      // Only load messages once to prevent duplicates
      if (_messagesLoaded) {
        debugPrint('⏭️ Messages already loaded, skipping');
        return;
      }

      // Query by appointment_id for appointment-based chat history
      if (widget.appointmentId == null) {
        debugPrint('⚠️ No appointment ID provided, skipping message load');
        return;
      }

      final response = await SupaFlow.client
          .from('chime_messages')
          .select()
          .eq('appointment_id', widget.appointmentId!)
          .order('created_at', ascending: true)
          .limit(50);

      final messages = response as List<dynamic>;

      // Get Supabase UUID from Firestore (using Firebase Auth UID)
      final userId = await _getSupabaseUserId();

      // Send messages to WebView with message IDs for deduplication
      for (final msg in messages) {
        final metadata = msg['metadata'] != null
            ? jsonDecode(msg['metadata'] as String)
            : {};

        final isOwn = msg['user_id'] == userId || msg['sender_id'] == userId;

        // Escape single quotes in message content to prevent JavaScript errors
        final messageContent = (msg['message_content'] ?? msg['message'] ?? '')
            .toString()
            .replaceAll("'", "\\'")
            .replaceAll('\n', '\\n');

        await _webViewController?.evaluateJavascript(source: '''
          receiveMessage({
            id: '${msg['id']}',
            sender: '${metadata['sender'] ?? 'Unknown'}',
            role: '${metadata['role'] ?? ''}',
            profileImage: '${msg['sender_avatar'] ?? metadata['profileImage'] ?? ''}',
            message: '$messageContent',
            messageType: '${msg['message_type'] ?? 'text'}',
            fileUrl: '${metadata['fileUrl'] ?? ''}',
            fileName: '${metadata['fileName'] ?? ''}',
            timestamp: '${msg['created_at'] ?? metadata['timestamp']}',
            isOwn: $isOwn
          });
        ''');
      }

      _messagesLoaded = true;
      debugPrint('✅ Loaded ${messages.length} messages (will not reload)');
    } catch (e) {
      debugPrint('❌ Error loading messages: $e');
    }
  }

  void _subscribeToMessages() async {
    // Record subscription start time to filter only NEW messages
    _subscriptionStartTime = DateTime.now();
    debugPrint('📡 Starting realtime subscription at $_subscriptionStartTime');

    // Subscribe to appointment-based messages only
    if (widget.appointmentId == null) {
      debugPrint('⚠️ No appointment ID provided, skipping subscription');
      return;
    }

    // Get current user ID for filtering own messages
    final userId = await _getSupabaseUserId();
    debugPrint('👤 Current user ID: $userId');

    // Create unique channel name for this appointment
    final channelName = 'chat_${widget.appointmentId}';
    debugPrint('📡 Creating channel: $channelName');

    // Use Supabase Realtime Channels API for reliable message delivery
    _messageChannel = SupaFlow.client.channel(channelName);

    _messageChannel!
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'chime_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'appointment_id',
        value: widget.appointmentId!,
      ),
      callback: (payload) async {
        debugPrint('📨 Realtime INSERT received: ${payload.newRecord}');

        final msg = payload.newRecord;
        final msgId = msg['id']?.toString() ?? '';

        // Skip if already processed
        if (_processedMessageIds.contains(msgId)) {
          debugPrint('⏭️ Skipping already processed message: $msgId');
          return;
        }

        // Add to processed set with size limit to prevent memory leak
        _processedMessageIds.add(msgId);
        if (_processedMessageIds.length > _maxProcessedMessageIds) {
          // Remove oldest entries (first 100) when limit exceeded
          final toRemove = _processedMessageIds.take(100).toList();
          _processedMessageIds.removeAll(toRemove);
        }

        // Check if it's own message
        final senderId = msg['sender_id']?.toString();
        final msgUserId = msg['user_id']?.toString();
        final isOwn = senderId == userId || msgUserId == userId;

        if (isOwn) {
          debugPrint('⏭️ Skipping own message from realtime: $msgId');
          return;
        }

        // Parse metadata
        Map<String, dynamic> metadata = {};
        try {
          if (msg['metadata'] != null) {
            if (msg['metadata'] is String) {
              metadata = jsonDecode(msg['metadata'] as String);
            } else if (msg['metadata'] is Map) {
              metadata = Map<String, dynamic>.from(msg['metadata'] as Map);
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing metadata: $e');
        }

        // Get sender name for notification
        final senderName = metadata['sender']?.toString() ?? 'Unknown';
        final senderRole = metadata['role']?.toString() ?? '';
        final displayName =
            senderRole.isNotEmpty ? '$senderRole $senderName' : senderName;

        // Get raw message content for notification
        final rawMessageContent =
            (msg['message_content'] ?? msg['message'] ?? '').toString();

        // Escape single quotes in message content for JavaScript
        final messageContent =
            rawMessageContent.replaceAll("'", "\\'").replaceAll('\n', '\\n');

        // Show notification banner if chat is not visible
        if (!_showChat) {
          _showMessageNotificationBanner(displayName, rawMessageContent);
        }

        // Send to WebView
        final js = '''
              receiveMessage({
                id: '$msgId',
                sender: '${metadata['sender'] ?? 'Unknown'}',
                role: '${metadata['role'] ?? ''}',
                profileImage: '${msg['sender_avatar'] ?? metadata['profileImage'] ?? ''}',
                message: '$messageContent',
                messageType: '${msg['message_type'] ?? 'text'}',
                fileUrl: '${metadata['fileUrl'] ?? ''}',
                fileName: '${metadata['fileName'] ?? ''}',
                timestamp: '${msg['created_at'] ?? metadata['timestamp'] ?? ''}',
                isOwn: false
              });
            ''';

        _webViewController?.evaluateJavascript(source: js);
        debugPrint('✅ Message displayed from other user: $msgId');
      },
    )
        .subscribe((status, error) {
      debugPrint('📡 Channel status: $status, error: $error');
      if (status == RealtimeSubscribeStatus.subscribed) {
        debugPrint('✅ Successfully subscribed to realtime messages!');
      } else if (status == RealtimeSubscribeStatus.channelError) {
        debugPrint('❌ Channel error: $error');
      }
    });

    debugPrint(
        '✅ Subscribed to realtime messages for appointment: ${widget.appointmentId}');
  }

  // === TRANSCRIPTION METHODS ===

  /// Fetches the video call session ID for this appointment
  Future<String?> _fetchSessionId() async {
    if (widget.appointmentId == null) {
      debugPrint('⚠️ No appointment ID for session lookup');
      return null;
    }

    debugPrint(
        '🔍 Looking up session for appointment: ${widget.appointmentId}');

    try {
      final result = await SupaFlow.client
          .from('video_call_sessions')
          .select('id, meeting_id, status')
          .eq('appointment_id', widget.appointmentId!)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      debugPrint('🔍 Query result: $result');

      if (result != null) {
        _sessionId = result['id'] as String;
        final dbMeetingId = result['meeting_id'];
        final status = result['status'];
        debugPrint('📋 Video session found:');
        debugPrint('   Session ID: $_sessionId');
        debugPrint('   Meeting ID (from DB): $dbMeetingId');
        debugPrint('   Status: $status');

        // If _meetingId is null but we have it from DB, use that
        if (_meetingId == null && dbMeetingId != null) {
          _meetingId = dbMeetingId as String;
          debugPrint('   ✓ Set _meetingId from database: $_meetingId');
        }

        return _sessionId;
      } else {
        debugPrint(
            '⚠️ No session found for appointment: ${widget.appointmentId}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching session ID: $e');
    }
    return null;
  }

  /// Starts medical transcription for the video call (provider only)
  Future<void> _startTranscription() async {
    if (_isTranscriptionEnabled || _isTranscriptionStarting) {
      debugPrint('⚠️ Transcription already enabled or starting');
      return;
    }

    if (!widget.isProvider) {
      debugPrint('⚠️ Only providers can start transcription');
      return;
    }

    setState(() => _isTranscriptionStarting = true);

    try {
      // Debug: Log current state
      debugPrint('🔍 Transcription pre-check:');
      debugPrint('   appointmentId: ${widget.appointmentId}');
      debugPrint('   _meetingId: $_meetingId');
      debugPrint('   _sessionId: $_sessionId');

      // Re-extract meeting ID if null (in case JSON parsing failed earlier)
      if (_meetingId == null) {
        debugPrint('🔄 Re-extracting meeting ID...');
        _extractMeetingId();
        debugPrint('   _meetingId after re-extract: $_meetingId');
      }

      // Fetch session ID with retry (database might not be ready immediately)
      if (_sessionId == null) {
        debugPrint('🔄 Fetching session ID...');
        for (int attempt = 1; attempt <= 3; attempt++) {
          await _fetchSessionId();
          if (_sessionId != null) {
            debugPrint('   ✓ Session ID found on attempt $attempt');
            break;
          }
          if (attempt < 3) {
            debugPrint(
                '   ⏳ Session not found, retrying in 1 second (attempt $attempt/3)...');
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }

      // Debug: Log final state
      debugPrint('🔍 Transcription final check:');
      debugPrint('   _meetingId: $_meetingId');
      debugPrint('   _sessionId: $_sessionId');

      if (_sessionId == null || _meetingId == null) {
        debugPrint(
            '❌ Missing session ID ($_sessionId) or meeting ID ($_meetingId) for transcription');
        setState(() => _isTranscriptionStarting = false);
        return;
      }

      debugPrint('🎙️ Starting medical transcription...');
      debugPrint('   Meeting ID: $_meetingId');
      debugPrint('   Session ID: $_sessionId');
      debugPrint('   Language: $_transcriptionLanguage');

      // Call the controlMedicalTranscription action
      final result = await controlMedicalTranscription(
        _meetingId!,
        _sessionId!,
        'start',
        _transcriptionLanguage,
        'PRIMARYCARE',
        true,
      );

      if (result['success'] == true) {
        setState(() {
          _isTranscriptionEnabled = true;
          _isTranscriptionStarting = false;
        });

        // Subscribe to live captions
        _subscribeToCaptions();

        // Show success notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transcription Started',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Language: ${result['config']?['language'] ?? _transcriptionLanguage}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF25D366),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        debugPrint('✅ Transcription started successfully');
      } else {
        setState(() => _isTranscriptionStarting = false);
        debugPrint('❌ Failed to start transcription: ${result['error']}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to start transcription: ${result['error'] ?? 'Unknown error'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: _startTranscription,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Transcription start error: $e');
      setState(() => _isTranscriptionStarting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transcription Error',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        e.toString().length > 50
                            ? '${e.toString().substring(0, 50)}...'
                            : e.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _startTranscription,
            ),
          ),
        );
      }
    }
  }

  /// Stops medical transcription
  Future<void> _stopTranscription() async {
    if (!_isTranscriptionEnabled) {
      debugPrint('⚠️ Transcription not enabled');
      return;
    }

    try {
      if (_sessionId == null || _meetingId == null) {
        debugPrint(
            '❌ Missing session ID or meeting ID for stopping transcription');
        return;
      }

      debugPrint('🛑 Stopping medical transcription...');

      final result = await controlMedicalTranscription(
        _meetingId!,
        _sessionId!,
        'stop',
        null,
        null,
        null,
      );

      if (mounted) {
        setState(() {
          _isTranscriptionEnabled = false;
          _currentCaption = null;
          _currentSpeaker = null;
        });
      } else {
        _isTranscriptionEnabled = false;
        _currentCaption = null;
        _currentSpeaker = null;
      }

      // Unsubscribe from captions
      if (_captionChannel != null) {
        await SupaFlow.client.removeChannel(_captionChannel!);
        _captionChannel = null;
      }

      _captionFadeTimer?.cancel();

      if (result['success'] == true) {
        debugPrint(
            '✅ Transcription stopped. Duration: ${result['stats']?['durationMinutes']} min');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Transcription stopped. Duration: ${result['stats']?['durationMinutes'] ?? 0} minutes',
              ),
              backgroundColor: const Color(0xFF0073bb),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        debugPrint('⚠️ Transcription stop error: ${result['error']}');
      }
    } catch (e) {
      debugPrint('❌ Transcription stop error: $e');
    }
  }

  /// Subscribes to realtime live caption segments
  void _subscribeToCaptions() {
    if (_sessionId == null) {
      debugPrint('⚠️ No session ID for caption subscription');
      return;
    }

    debugPrint('📡 Subscribing to live captions for session: $_sessionId');

    final channelName = 'captions_$_sessionId';
    _captionChannel = SupaFlow.client.channel(channelName);

    _captionChannel!
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'live_caption_segments',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'session_id',
        value: _sessionId!,
      ),
      callback: (payload) {
        _handleCaptionReceived(payload.newRecord);
      },
    )
        .subscribe((status, error) {
      debugPrint('📡 Caption channel status: $status, error: $error');
      if (status == RealtimeSubscribeStatus.subscribed) {
        debugPrint('✅ Subscribed to live captions!');
      }
    });
  }

  /// Handles incoming live caption segments
  void _handleCaptionReceived(Map<String, dynamic> caption) {
    if (!mounted) return;

    final transcriptText = caption['transcript_text'] as String? ?? '';
    final speakerName = caption['speaker_name'] as String? ?? 'Unknown';
    final isPartial = caption['is_partial'] as bool? ?? false;

    debugPrint(
        '📝 Caption received: "$transcriptText" from $speakerName (partial: $isPartial)');

    // Only show non-empty captions
    if (transcriptText.isEmpty) return;

    setState(() {
      _currentCaption = transcriptText;
      _currentSpeaker = speakerName;

      // Add to live captions list (keep last 10)
      _liveCaptions.add({
        'text': transcriptText,
        'speaker': speakerName,
        'isPartial': isPartial,
        'timestamp': DateTime.now(),
      });
      if (_liveCaptions.length > 10) {
        _liveCaptions.removeAt(0);
      }
    });

    // Reset fade timer - captions disappear after 5 seconds of inactivity
    _captionFadeTimer?.cancel();
    _captionFadeTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentCaption = null;
          _currentSpeaker = null;
        });
      }
    });
  }

  /// Toggles caption overlay visibility
  void _toggleCaptionOverlay() {
    setState(() {
      _showCaptionOverlay = !_showCaptionOverlay;
    });
    debugPrint(
        '📝 Caption overlay: ${_showCaptionOverlay ? "shown" : "hidden"}');
  }

  Future<void> _joinMeeting() async {
    try {
      debugPrint('🎬 Joining meeting...');

      // Parse meeting and attendee data
      final meetingMap = jsonDecode(widget.meetingData);
      final attendeeMap = jsonDecode(widget.attendeeData);

      debugPrint('Meeting ID: ${meetingMap['MeetingId']}');
      debugPrint('Attendee ID: ${attendeeMap['AttendeeId']}');

      // Wrap in expected format
      final wrappedMeeting = {'Meeting': meetingMap};
      final wrappedAttendee = {'Attendee': attendeeMap};

      final meetingJson = jsonEncode(wrappedMeeting);
      final attendeeJson = jsonEncode(wrappedAttendee);
      final userName = jsonEncode(widget.userName);
      final userRole = jsonEncode(widget.userRole ?? '');
      final userProfileImage = jsonEncode(widget.userProfileImage ?? '');
      final isProvider = widget.isProvider ? 'true' : 'false';
      final meetingIdForApi = jsonEncode(meetingMap['MeetingId'] ?? '');

      // Build consultation title with date and provider role
      // Format: "Consultation MM/YYYY Doctor [Name]"
      String titleText;
      if (widget.providerName != null && widget.providerName!.isNotEmpty) {
        // Format appointment date as MM/YYYY
        String dateStr = '';
        if (widget.appointmentDate != null) {
          final month =
              widget.appointmentDate!.month.toString().padLeft(2, '0');
          final year = widget.appointmentDate!.year.toString();
          dateStr = '$month/$year ';
        }

        if (widget.providerRole != null && widget.providerRole!.isNotEmpty) {
          titleText =
              'Consultation $dateStr${widget.providerRole} ${widget.providerName}';
        } else {
          titleText = 'Consultation ${dateStr}with ${widget.providerName}';
        }
      } else {
        titleText = 'Video Call';
      }
      final callTitleJson = jsonEncode(titleText);

      // Pass initial mic/camera state from pre-joining dialog
      final initialMicOff = !widget.initialMicEnabled;
      final initialVideoOff = !widget.initialCameraEnabled;

      final script = '''
        console.log('=== Joining Enhanced Meeting ===');
        console.log('Meeting:', $meetingJson);
        console.log('Attendee:', $attendeeJson);
        console.log('Name:', $userName);
        console.log('Role:', $userRole);
        console.log('Profile Image:', $userProfileImage);
        console.log('Call Title:', $callTitleJson);
        console.log('Is Provider:', $isProvider);
        console.log('Meeting ID:', $meetingIdForApi);
        console.log('Initial Mic Off:', $initialMicOff);
        console.log('Initial Video Off:', $initialVideoOff);

        currentAttendeeName = $userName;
        currentUserRole = $userRole;
        currentUserProfileImage = $userProfileImage;
        callTitle = $callTitleJson;
        isProviderUser = $isProvider;
        currentMeetingId = $meetingIdForApi;

        // Store initial device state from pre-joining dialog
        const shouldStartMuted = $initialMicOff;
        const shouldStartVideoOff = $initialVideoOff;

        // Update leave button title based on user role (icon stays the same)
        const leaveBtn = document.getElementById('leave-btn');
        if (leaveBtn) {
            leaveBtn.title = isProviderUser ? 'End Call for Everyone' : 'Leave Call';
        }

        joinMeeting($meetingJson, $attendeeJson)
          .then(() => {
            console.log('✅ Meeting joined successfully');

            // Apply initial mic/camera state from pre-joining dialog
            if (shouldStartMuted && audioVideo) {
              console.log('🔇 Applying initial mute state from pre-joining dialog');
              audioVideo.realtimeMuteLocalAudio();
              isMuted = true;
              const muteBtn = document.getElementById('mute-btn');
              if (muteBtn) {
                muteBtn.classList.add('active');
                muteBtn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="1" y1="1" x2="23" y2="23"></line><path d="M9 9v3a3 3 0 0 0 5.12 2.12M15 9.34V4a3 3 0 0 0-5.94-.6"></path><path d="M17 16.95A7 7 0 0 1 5 12v-2m14 0v2a7 7 0 0 1-.11 1.23"></path><line x1="12" y1="19" x2="12" y2="23"></line><line x1="8" y1="23" x2="16" y2="23"></line></svg>';
              }
            }

            if (shouldStartVideoOff && audioVideo) {
              console.log('📹 Applying initial video off state from pre-joining dialog');
              audioVideo.stopLocalVideoTile();
              isVideoOff = true;
              const videoBtn = document.getElementById('video-btn');
              if (videoBtn) {
                videoBtn.classList.add('active');
                videoBtn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="1" y1="1" x2="23" y2="23"></line><path d="M21 21l-8.5-8.5L23 7v10z"></path><rect x="1" y="5" width="15" height="14" rx="2" ry="2"></rect></svg>';
              }
              // Show profile picture in local tile since camera is off
              const localTiles = document.querySelectorAll('.video-tile');
              localTiles.forEach(tile => {
                if (tile.querySelector('.local-tile')) {
                  tile.classList.add('camera-off');
                }
              });
            }

            if (window.FlutterChannel) {
              window.FlutterChannel.postMessage('MEETING_JOINED');
            }
          })
          .catch(err => {
            console.error('❌ Failed to join:', err);
            if (window.FlutterChannel) {
              window.FlutterChannel.postMessage('MEETING_ERROR:' + err.message);
            }
          });
      ''';

      await _webViewController?.evaluateJavascript(source: script);
      debugPrint('✅ Join meeting script executed');
    } catch (e) {
      debugPrint('❌ Error joining meeting: $e');
      _showErrorSnackBar('Failed to join meeting: $e');
    }
  }

  String _getEnhancedChimeHTML() {
    return r'''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>Enhanced Chime Meeting</title>

    <script>
        // ============================================
        // FLUTTER_INAPPWEBVIEW COMPATIBILITY SHIM
        // Creates FlutterChannel object that maps to flutter_inappwebview.callHandler
        // This allows existing FlutterChannel.postMessage() calls to work
        // ============================================
        (function() {
            // Create FlutterChannel shim for flutter_inappwebview
            window.FlutterChannel = {
                postMessage: function(msg) {
                    // Use flutter_inappwebview's callHandler
                    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                        window.flutter_inappwebview.callHandler('FlutterChannel', msg);
                    } else {
                        // Fallback: queue message and retry when handler is available
                        console.log('⏳ flutter_inappwebview not ready, queueing message');
                        setTimeout(() => {
                            if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                                window.flutter_inappwebview.callHandler('FlutterChannel', msg);
                            }
                        }, 100);
                    }
                }
            };
            console.log('✅ FlutterChannel shim installed for flutter_inappwebview');
        })();

        // ============================================
        // DEVICE ENUMERATION CACHE PATCH
        // Prevents repeated permission check loops on Android WebView
        // The Chromium "CheckMediaAccessPermission: Not supported" error
        // is caused by repeated calls to enumerateDevices()
        // ============================================
        (function() {
            let cachedDevices = null;
            let cacheTime = 0;
            const CACHE_DURATION = 30000; // Cache for 30 seconds

            const originalEnumerateDevices = navigator.mediaDevices?.enumerateDevices?.bind(navigator.mediaDevices);

            if (originalEnumerateDevices) {
                navigator.mediaDevices.enumerateDevices = async function() {
                    const now = Date.now();
                    // Return cached result if fresh
                    if (cachedDevices && (now - cacheTime) < CACHE_DURATION) {
                        console.log('📹 Using cached device list');
                        return cachedDevices;
                    }
                    // Call original and cache result
                    try {
                        cachedDevices = await originalEnumerateDevices();
                        cacheTime = now;
                        console.log('📹 Device list refreshed and cached');
                        return cachedDevices;
                    } catch (e) {
                        console.error('📹 Device enumeration error:', e.name);
                        // Return empty array on error to prevent loops
                        return cachedDevices || [];
                    }
                };
                console.log('✅ Device enumeration cache patch applied');
            }
        })();

        // SDK Load State Tracking
        let sdkLoadAttempts = 0;
        const maxAttempts = 3;
        let sdkLoaded = false;

        // SDK Load Success Handler
        function handleSDKLoadSuccess() {
            console.log('📦 SDK script loaded from CDN');
            updateLoadingStatus('SDK downloaded, initializing...');
            if (typeof window.ChimeSDK !== 'undefined') {
                sdkLoaded = true;
                console.log('✅ Chime SDK ready - notifying Flutter');
                updateLoadingStatus('SDK ready, joining meeting...');
                window.FlutterChannel?.postMessage('SDK_READY');
            } else {
                console.warn('⚠️ SDK script loaded but ChimeSDK not defined, waiting...');
                updateLoadingStatus('Waiting for SDK to initialize...');
                // Wait a bit for SDK to initialize
                setTimeout(() => {
                    if (typeof window.ChimeSDK !== 'undefined') {
                        sdkLoaded = true;
                        console.log('✅ Chime SDK ready (delayed) - notifying Flutter');
                        updateLoadingStatus('SDK ready, joining meeting...');
                        window.FlutterChannel?.postMessage('SDK_READY');
                    } else {
                        console.error('❌ ChimeSDK still not defined after delay');
                        updateLoadingStatus('SDK failed to initialize');
                        handleSDKLoadError();
                    }
                }, 500);
            }
        }

        // Update loading status helper (defined early for use by SDK handlers)
        function updateLoadingStatus(text) {
            const status = document.getElementById('loading-status');
            if (status) status.textContent = text;
            console.log('📊 Status:', text);
        }

        // SDK Load Error Handler
        function handleSDKLoadError() {
            console.error('❌ SDK load failed (attempt ' + (sdkLoadAttempts + 1) + '/' + maxAttempts + ')');
            updateLoadingStatus('Retrying SDK download... (attempt ' + (sdkLoadAttempts + 1) + '/' + maxAttempts + ')');
            if (sdkLoadAttempts < maxAttempts - 1) {
                sdkLoadAttempts++;
                setTimeout(() => {
                    console.log('🔄 Retrying SDK download...');
                    const script = document.createElement('script');
                    script.src = 'https://du6iimxem4mh7.cloudfront.net/assets/amazon-chime-sdk-medzen.min.js';
                    script.onload = handleSDKLoadSuccess;
                    script.onerror = handleSDKLoadError;
                    document.head.appendChild(script);
                }, 1000 * Math.pow(2, sdkLoadAttempts));
            } else {
                console.error('❌ All SDK load attempts failed');
                document.body.innerHTML = '<div style="display:flex;align-items:center;justify-content:center;height:100vh;background:#f5f5f5;color:#333;text-align:center;padding:20px;"><div><h2>⚠️ Connection Error</h2><p>Could not load video call SDK.</p><p style="margin-top:10px;font-size:14px;color:#666;">Please check your internet connection and try again.</p></div></div>';
            }
        }
    </script>

    <!-- Load Chime SDK from CloudFront CDN (custom-built working bundle v3.29.0) -->
    <script src="https://du6iimxem4mh7.cloudfront.net/assets/amazon-chime-sdk-medzen.min.js"
            onload="handleSDKLoadSuccess()"
            onerror="handleSDKLoadError()"></script>

    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        :root {
            --bg-primary: #ffffff;
            --bg-secondary: #f5f5f5;
            --bg-tertiary: #e0e0e0;
            --accent: #25D366;
            --accent-hover: #1da851;
            --text-primary: #000000;
            --text-secondary: #666666;
            --active-speaker: #25D366;
            --muted-red: #f23c50;
            --border-color: #d0d0d0;
            --whatsapp-green: #25D366;
            --facetime-green: #32de84;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            overflow: hidden;
            -webkit-touch-callout: none;
            -webkit-user-select: none;
            user-select: none;
        }

        #container {
            width: 100vw;
            height: 100vh;
            display: flex;
            flex-direction: column;
        }

        /* Video Grid Layout */
        #video-grid {
            flex: 1;
            display: grid;
            gap: 8px;
            padding: 8px;
            background: var(--bg-primary);
            overflow: hidden;
        }

        /* Responsive grid based on participant count */
        #video-grid.count-1 { grid-template-columns: 1fr; }
        #video-grid.count-2 { grid-template-columns: repeat(2, 1fr); }
        #video-grid.count-3,
        #video-grid.count-4 { grid-template-columns: repeat(2, 1fr); }
        #video-grid.count-5,
        #video-grid.count-6 { grid-template-columns: repeat(3, 1fr); }
        #video-grid.count-7,
        #video-grid.count-8,
        #video-grid.count-9 { grid-template-columns: repeat(3, 1fr); }
        #video-grid.count-10,
        #video-grid.count-11,
        #video-grid.count-12,
        #video-grid.count-13,
        #video-grid.count-14,
        #video-grid.count-15,
        #video-grid.count-16 { grid-template-columns: repeat(4, 1fr); }

        .video-tile {
            position: relative;
            background: var(--bg-secondary);
            border-radius: 8px;
            overflow: hidden;
            border: 3px solid transparent;
            transition: border-color 0.3s ease;
        }

        .video-tile.active-speaker {
            border-color: var(--active-speaker);
            box-shadow: 0 0 15px var(--active-speaker);
        }

        .video-tile video {
            width: 100%;
            height: 100%;
            object-fit: cover;
            background: var(--bg-secondary);
        }

        .video-tile-info {
            position: absolute;
            bottom: 8px;
            left: 8px;
            right: 8px;
            background: rgba(0, 0, 0, 0.7);
            padding: 6px 10px;
            border-radius: 4px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .attendee-name {
            color: var(--text-primary);
            font-size: 14px;
            font-weight: 500;
            flex: 1;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .attendee-role {
            font-size: 11px;
            color: rgba(255, 255, 255, 0.5);
            font-weight: 400;
            margin-top: 2px;
        }

        .video-tile-profile {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 120px;
            height: 120px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: none;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 48px;
            font-weight: bold;
            z-index: 1;
            overflow: hidden;
        }

        .video-tile-profile img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            border-radius: 50%;
            position: absolute;
            top: 0;
            left: 0;
        }

        .video-tile.camera-off .video-tile-profile {
            display: flex;
        }

        .video-tile.camera-off video {
            opacity: 0;
        }

        .attendee-status {
            display: flex;
            gap: 6px;
            font-size: 16px;
        }

        .status-icon {
            width: 20px;
            height: 20px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        /* Controls Bar */
        #controls {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 20px;
            padding: 20px 24px;
            background: rgba(28, 28, 30, 0.95);
            backdrop-filter: blur(20px) saturate(180%);
            -webkit-backdrop-filter: blur(20px) saturate(180%);
            border-top: 1px solid rgba(255, 255, 255, 0.1);
            box-shadow: 0 -4px 24px rgba(0, 0, 0, 0.15);
        }

        /* Apple-style Control Buttons */
        .control-btn {
            width: 56px;
            height: 56px;
            border-radius: 50%;
            border: none;
            background: rgba(255, 255, 255, 0.18);
            color: #ffffff;
            font-size: 24px;
            cursor: pointer;
            transition: all 0.2s ease-out;
            display: flex;
            align-items: center;
            justify-content: center;
            backdrop-filter: blur(20px) saturate(180%);
            -webkit-backdrop-filter: blur(20px) saturate(180%);
            box-shadow: 0 2px 12px rgba(0, 0, 0, 0.15),
                        inset 0 0 0 1px rgba(255, 255, 255, 0.1);
            position: relative;
            overflow: hidden;
        }

        .control-btn::before {
            content: '';
            position: absolute;
            inset: 0;
            border-radius: 50%;
            background: linear-gradient(180deg, rgba(255, 255, 255, 0.12) 0%, transparent 50%);
        }

        .control-btn:hover {
            background: rgba(255, 255, 255, 0.28);
            transform: scale(1.08);
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2),
                        inset 0 0 0 1px rgba(255, 255, 255, 0.15);
        }

        .control-btn:active {
            transform: scale(0.95);
            background: rgba(255, 255, 255, 0.12);
        }

        .control-btn.active {
            background: rgba(255, 59, 48, 0.9);
            box-shadow: 0 2px 12px rgba(255, 59, 48, 0.4),
                        inset 0 0 0 1px rgba(255, 255, 255, 0.1);
        }

        .control-btn.active:hover {
            background: rgba(255, 59, 48, 1);
            transform: scale(1.08);
        }

        /* End Call Button - Apple Red */
        .control-btn.leave {
            background: #FF3B30;
            box-shadow: 0 4px 16px rgba(255, 59, 48, 0.4),
                        inset 0 0 0 1px rgba(255, 255, 255, 0.1);
        }

        .control-btn.leave:hover {
            background: #FF453A;
            transform: scale(1.08);
            box-shadow: 0 6px 24px rgba(255, 59, 48, 0.5),
                        inset 0 0 0 1px rgba(255, 255, 255, 0.15);
        }

        .control-btn.leave:active {
            transform: scale(0.95);
            background: #D70015;
        }

        /* SVG Icons inside buttons */
        .control-btn svg {
            width: 24px;
            height: 24px;
            fill: currentColor;
        }

        /* Notification Badge */
        .notification-badge {
            position: absolute;
            top: -4px;
            right: -4px;
            background: #FF3B30;
            color: white;
            font-size: 11px;
            font-weight: 600;
            min-width: 18px;
            height: 18px;
            border-radius: 9px;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 0 5px;
            box-shadow: 0 2px 6px rgba(255, 59, 48, 0.5);
            animation: badge-pop 0.3s ease-out;
        }

        .notification-badge.hidden {
            display: none;
        }

        @keyframes badge-pop {
            0% { transform: scale(0); }
            50% { transform: scale(1.2); }
            100% { transform: scale(1); }
        }

        /* Loading State */
        #loading {
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            background: var(--bg-primary);
            flex-direction: column;
            gap: 20px;
        }

        .spinner {
            width: 50px;
            height: 50px;
            border: 4px solid var(--bg-tertiary);
            border-top-color: var(--accent);
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            to { transform: rotate(360deg); }
        }

        /* Responsive */
        @media (max-width: 768px) {
            #video-grid.count-3,
            #video-grid.count-4,
            #video-grid.count-5,
            #video-grid.count-6 { grid-template-columns: repeat(2, 1fr); }

            .control-btn {
                width: 48px;
                height: 48px;
                font-size: 20px;
            }

            .chat-panel {
                width: 100%;
                left: 0;
                right: 0;
            }
        }

        /* Chat Panel Styles */
        .chat-panel {
            position: fixed;
            left: 0;
            right: 0;
            top: 52px;  /* Start below Flutter header (52px gives space for header + shadow) */
            bottom: 0;
            width: 100%;
            background: #ffffff;
            border-left: 1px solid #d0d0d0;
            display: flex;
            flex-direction: column;
            transform: translate3d(100%, 0, 0);  /* Use 3D transform for GPU acceleration */
            transition: transform 0.25s ease-out;
            z-index: 999;  /* Below Flutter header but above video content */
            will-change: transform;  /* Hint to browser for optimization */
            backface-visibility: hidden;  /* Reduce GPU compositing */
            -webkit-backface-visibility: hidden;
        }

        .chat-panel.visible {
            transform: translate3d(0, 0, 0);
        }

        .chat-panel.hidden {
            transform: translate3d(100%, 0, 0);
        }

        .chat-header {
            padding: 16px;
            background: linear-gradient(135deg, #f0f0f0 0%, #e8e8e8 100%);
            border-bottom: 1px solid #d0d0d0;
            display: flex;
            gap: 12px;
            align-items: center;
            position: relative;
            box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
            z-index: 5;
        }

        .chat-header::after {
            content: '';
            position: absolute;
            bottom: 0;
            left: 0;
            right: 0;
            height: 2px;
            background: linear-gradient(90deg,
                transparent 0%,
                rgba(37, 211, 102, 0.5) 50%,
                transparent 100%
            );
            /* Removed infinite animation to reduce GPU load on emulators */
            opacity: 0.7;
        }

        .chat-header h3 {
            margin: 0;
            color: #000000;
            font-size: 18px;
            font-weight: 600;
            flex: 1;
            text-shadow: none;
        }

        .back-btn {
            background: transparent;
            border: none;
            color: #25D366;
            font-size: 28px;
            cursor: pointer;
            padding: 4px 8px;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            display: flex;
            align-items: center;
            justify-content: center;
            line-height: 1;
            font-weight: 300;
            position: relative;
            margin-right: 4px;
            z-index: 10;
            -webkit-tap-highlight-color: rgba(37, 211, 102, 0.3);
            touch-action: manipulation;
            user-select: none;
            -webkit-user-select: none;
        }

        .back-btn:hover {
            color: #1da851;
            transform: translateX(-4px) scale(1.15);
            filter: drop-shadow(0 0 8px rgba(37, 211, 102, 0.6));
        }

        .back-btn:active {
            transform: translateX(-2px) scale(1.05);
            background: rgba(37, 211, 102, 0.1);
        }

        .chat-messages {
            flex: 1;
            overflow-y: auto;
            padding: 16px;
            display: flex;
            flex-direction: column;
            gap: 12px;
            background: #ffffff;
        }

        .chat-message {
            display: flex;
            gap: 8px;
            max-width: 80%;
            align-items: flex-start;
        }

        .chat-message.own {
            align-self: flex-end;
            flex-direction: row-reverse;
        }

        .chat-message.other {
            align-self: flex-start;
            flex-direction: row;
        }

        .message-avatar {
            width: 36px;
            height: 36px;
            border-radius: 50%;
            background: linear-gradient(135deg, #25D366 0%, #1da851 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            font-size: 14px;
            flex-shrink: 0;
            overflow: hidden;
            position: relative;
        }

        .message-avatar img {
            width: 100%;
            height: 100%;
            object-fit: cover;
            border-radius: 50%;
        }

        .message-content-wrapper {
            display: flex;
            flex-direction: column;
            gap: 4px;
            flex: 1;
            min-width: 0;
        }

        .message-sender {
            font-size: 12px;
            color: #666666;
            font-weight: 500;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            max-width: 100%;
        }

        .message-content {
            background: #f0f0f0;
            padding: 10px 14px;
            border-radius: 12px;
            color: #000000;
            word-wrap: break-word;
            overflow-wrap: break-word;
            word-break: break-word;
            hyphens: auto;
            max-width: 100%;
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
            position: relative;
        }

        .message-content::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 1px;
            background: linear-gradient(90deg, transparent, rgba(37, 211, 102, 0.3), transparent);
        }

        .chat-message.own .message-content {
            background: linear-gradient(135deg, #dcf8c6 0%, #d0f0b8 100%);
            color: #000000;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }

        .chat-message.other .message-content {
            background: linear-gradient(135deg, #f0f0f0 0%, #e8e8e8 100%);
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        }

        .message-file {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 12px 14px;
            background: rgba(37, 211, 102, 0.15);
            border-radius: 10px;
            cursor: pointer;
            margin-top: 4px;
            border: 1px solid rgba(37, 211, 102, 0.2);
            font-size: 14px;
            transition: all 0.2s ease;
        }

        .message-file:hover {
            background: rgba(37, 211, 102, 0.25);
            transform: scale(1.02);
        }

        .message-file:active {
            transform: scale(0.98);
        }

        .message-image-container {
            display: flex;
            flex-direction: column;
            gap: 4px;
            margin-top: 4px;
        }

        .message-image {
            max-width: 100%;
            max-height: 300px;
            border-radius: 12px;
            cursor: pointer;
            object-fit: cover;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
            transition: transform 0.2s ease;
        }

        .message-image:hover {
            transform: scale(1.02);
        }

        .message-file-name {
            font-size: 11px;
            color: #666;
            text-align: center;
            word-break: break-all;
        }

        .message-time {
            font-size: 11px;
            color: #666666;
            margin-top: 2px;
            text-align: right;
        }

        .chat-message.own .message-time {
            color: #666666;
        }

        .chat-input-container {
            padding: 12px 16px;
            background: #f5f5f5;
            border-top: 1px solid #d0d0d0;
            display: flex;
            gap: 10px;
            align-items: center;
        }

        .input-wrapper {
            flex: 1;
            display: flex;
            align-items: center;
            background: #ffffff;
            border: 1px solid #d0d0d0;
            border-radius: 24px;
            padding: 4px 8px;
            transition: all 0.2s;
            min-width: 0;
        }

        .input-wrapper:focus-within {
            border-color: #25D366;
            box-shadow: 0 0 0 2px rgba(37, 211, 102, 0.1);
        }

        .input-icon-btn {
            background: transparent;
            border: none;
            font-size: 20px;
            cursor: pointer;
            padding: 6px;
            transition: all 0.2s;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            width: 32px;
            height: 32px;
            flex-shrink: 0;
            opacity: 0.7;
        }

        .input-icon-btn:hover {
            opacity: 1;
            background: rgba(37, 211, 102, 0.1);
            transform: scale(1.1);
        }

        .input-icon-btn:active {
            transform: scale(0.95);
        }

        .chat-input {
            flex: 1;
            background: transparent;
            border: none;
            padding: 8px 4px;
            color: #000000;
            font-size: 15px;
            min-width: 0;
        }

        .chat-input:focus {
            outline: none;
        }

        .chat-input::placeholder {
            color: #999999;
        }

        .send-btn {
            background: linear-gradient(135deg, #25D366 0%, #1da851 100%);
            border: none;
            border-radius: 50%;
            width: 48px;
            height: 48px;
            min-width: 48px;
            color: white;
            font-size: 22px;
            cursor: pointer;
            transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
            display: flex;
            align-items: center;
            justify-content: center;
            position: relative;
            overflow: hidden;
            box-shadow: 0 4px 15px rgba(37, 211, 102, 0.5);
            flex-shrink: 0;
        }

        .send-btn::before {
            content: '';
            position: absolute;
            inset: 0;
            background: radial-gradient(circle at center, rgba(255, 255, 255, 0.3), transparent);
            opacity: 0;
            transition: opacity 0.25s;
        }

        .send-btn::after {
            content: '➤';
            position: absolute;
            font-size: 22px;
            font-weight: bold;
            transition: transform 0.25s;
        }

        .send-btn:hover {
            background: linear-gradient(135deg, #1da851 0%, #158a43 100%);
            transform: scale(1.1);
            box-shadow: 0 6px 28px rgba(37, 211, 102, 0.7);
        }

        .send-btn:hover::before {
            opacity: 1;
        }

        .send-btn:hover::after {
            transform: translateX(2px);
        }

        .send-btn:active {
            transform: scale(0.95);
            box-shadow: 0 2px 10px rgba(37, 211, 102, 0.4);
        }

        .send-btn:disabled {
            opacity: 0.5;
            cursor: not-allowed;
            transform: none;
        }

        .emoji-picker {
            position: absolute;
            bottom: 80px;
            left: 16px;
            right: 16px;
            background: #ffffff;
            border: 1px solid #d0d0d0;
            border-radius: 12px;
            padding: 12px;
            max-height: 200px;
            overflow-y: auto;
            z-index: 1001;
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
        }

        .emoji-picker.hidden {
            display: none;
        }

        .emoji-grid {
            display: grid;
            grid-template-columns: repeat(8, 1fr);
            gap: 6px;
        }

        .emoji-item {
            font-size: 22px;
            cursor: pointer;
            padding: 4px;
            border-radius: 6px;
            transition: all 0.2s;
            text-align: center;
        }

        .emoji-item:hover {
            background: rgba(37, 211, 102, 0.2);
            transform: scale(1.15);
        }
    </style>
</head>
<body>
    <div id="loading">
        <div class="spinner"></div>
        <p id="loading-text" style="color: var(--text-secondary);">Loading video call SDK...</p>
        <p id="loading-status" style="color: var(--text-secondary); font-size: 12px; margin-top: 10px;"></p>
    </div>

    <div id="container" style="display: none;">
        <!-- Hidden audio sink for Chime WebRTC (required for remote audio playback) -->
        <audio id="meeting-audio" autoplay playsinline style="display:none"></audio>
        <div id="video-grid" class="count-1"></div>
        <div id="controls">
            <button id="mute-btn" class="control-btn" title="Mute/Unmute">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"></path>
                    <path d="M19 10v2a7 7 0 0 1-14 0v-2"></path>
                    <line x1="12" y1="19" x2="12" y2="23"></line>
                    <line x1="8" y1="23" x2="16" y2="23"></line>
                </svg>
            </button>
            <button id="video-btn" class="control-btn" title="Video On/Off">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polygon points="23 7 16 12 23 17 23 7"></polygon>
                    <rect x="1" y="5" width="15" height="14" rx="2" ry="2"></rect>
                </svg>
            </button>
            <button id="switch-camera-btn" class="control-btn" title="Switch Camera">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M11 19H4a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h5"></path>
                    <path d="M13 5h7a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2h-5"></path>
                    <polyline points="10 9 13 12 10 15"></polyline>
                    <polyline points="14 9 11 12 14 15"></polyline>
                </svg>
            </button>
            <button id="chat-btn" class="control-btn" title="Chat">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
                </svg>
                <span id="chat-badge" class="notification-badge hidden">0</span>
            </button>
            <button id="leave-btn" class="control-btn leave" title="End Call">
                <svg viewBox="0 0 24 24" fill="currentColor">
                    <path d="M12 9c-1.6 0-3.15.25-4.6.72v3.1c0 .39-.23.74-.56.9-.98.49-1.87 1.12-2.66 1.85-.18.18-.43.28-.7.28-.28 0-.53-.11-.71-.29L.29 13.08c-.18-.17-.29-.42-.29-.7 0-.28.11-.53.29-.71C3.34 8.78 7.46 7 12 7s8.66 1.78 11.71 4.67c.18.18.29.43.29.71 0 .28-.11.53-.29.71l-2.48 2.48c-.18.18-.43.29-.71.29-.27 0-.52-.11-.7-.28-.79-.74-1.69-1.36-2.67-1.85-.33-.16-.56-.5-.56-.9v-3.1C15.15 9.25 13.6 9 12 9z"/>
                </svg>
            </button>
        </div>

        <!-- Chat Panel -->
        <div id="chat-panel" class="chat-panel hidden">
            <div class="chat-header">
                <button id="back-btn" class="back-btn" title="Close chat">←</button>
                <h3 id="chat-title">Chat</h3>
            </div>
            <div id="chat-messages" class="chat-messages"></div>
            <div class="chat-input-container">
                <div class="input-wrapper">
                    <button id="file-btn" class="input-icon-btn" title="Attach File">📎</button>
                    <input type="text" id="chat-input" class="chat-input" placeholder="Type a message...">
                    <button id="emoji-btn" class="input-icon-btn" title="Insert Emoji">😊</button>
                </div>
                <input type="file" id="file-input" style="display:none" accept="image/*,video/*,audio/*,.pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.txt,.csv,.zip,.rar,.7z,.json,.xml,.html,.css,.js,.py,.java,.dart,.md,.rtf">
                <input type="file" id="camera-input" style="display:none" accept="image/*" capture="environment">
                <button id="send-btn" class="send-btn"></button>
            </div>
            <div id="emoji-picker" class="emoji-picker hidden">
                <div class="emoji-grid"></div>
            </div>
        </div>
    </div>

    <script>
        // Enhanced error logging for TypeErrors and debugging
        (function() {
            const originalLog = console.log;
            const originalError = console.error;
            const originalWarn = console.warn;

            // Helper to extract detailed error info
            function formatError(err) {
                if (!err) return 'Unknown error';
                let msg = '';
                if (err instanceof TypeError) {
                    msg += '[TypeError] ';
                } else if (err instanceof Error) {
                    msg += '[' + err.name + '] ';
                }
                msg += err.message || String(err);
                if (err.stack) {
                    // Get first 3 lines of stack trace
                    const stackLines = err.stack.split('\\n').slice(0, 4).join(' | ');
                    msg += ' Stack: ' + stackLines;
                }
                return msg;
            }

            // Helper to format console arguments with enhanced error handling
            function formatArgs(args) {
                return args.map(a => {
                    if (a instanceof TypeError) {
                        return '[TypeError] ' + a.message + (a.stack ? ' Stack: ' + a.stack.split('\\n').slice(0, 3).join(' | ') : '');
                    } else if (a instanceof Error) {
                        return formatError(a);
                    } else if (typeof a === 'object') {
                        try { return JSON.stringify(a); } catch(e) { return String(a); }
                    }
                    return String(a);
                }).join(' ');
            }

            console.log = function(...args) {
                originalLog.apply(console, args);
                try {
                    window.ConsoleLog?.postMessage('LOG: ' + formatArgs(args));
                } catch(e) {}
            };
            console.error = function(...args) {
                originalError.apply(console, args);
                try {
                    window.ConsoleLog?.postMessage('ERROR: ' + formatArgs(args));
                } catch(e) {}
            };
            console.warn = function(...args) {
                originalWarn.apply(console, args);
                try {
                    window.ConsoleLog?.postMessage('WARN: ' + formatArgs(args));
                } catch(e) {}
            };

            // Global error handler to catch uncaught TypeErrors and other exceptions
            window.onerror = function(message, source, lineno, colno, error) {
                const errorType = error instanceof TypeError ? 'TypeError' : (error?.name || 'Error');
                const errorDetail = '[UNCAUGHT ' + errorType + '] ' + message + ' at line ' + lineno + ':' + colno;
                window.ConsoleLog?.postMessage('CRITICAL: ' + errorDetail);
                if (error?.stack) {
                    window.ConsoleLog?.postMessage('STACK: ' + error.stack.split('\\n').slice(0, 5).join(' | '));
                }
                // Send to Flutter for debugging
                window.FlutterChannel?.postMessage(JSON.stringify({
                    type: 'JS_ERROR',
                    errorType: errorType,
                    message: message,
                    source: source,
                    line: lineno,
                    column: colno,
                    stack: error?.stack || ''
                }));
                return false; // Don't prevent default handling
            };

            // Catch unhandled promise rejections (common with async TypeErrors)
            window.onunhandledrejection = function(event) {
                const error = event.reason;
                const errorType = error instanceof TypeError ? 'TypeError' : (error?.name || 'PromiseRejection');
                window.ConsoleLog?.postMessage('UNHANDLED_REJECTION: [' + errorType + '] ' + (error?.message || String(error)));
                if (error?.stack) {
                    window.ConsoleLog?.postMessage('REJECTION_STACK: ' + error.stack.split('\\n').slice(0, 5).join(' | '));
                }
                // Send to Flutter for debugging
                window.FlutterChannel?.postMessage(JSON.stringify({
                    type: 'PROMISE_REJECTION',
                    errorType: errorType,
                    message: error?.message || String(error),
                    stack: error?.stack || ''
                }));
            };
        })();

        // Immediate test - this should appear in Flutter logs
        console.log('🚀 Video call HTML loaded - JS is running (enhanced error logging enabled)');

        // Global variables
        let meetingSession;
        let audioVideo;
        let currentAttendeeName = 'User';
        let currentUserRole = '';
        let currentUserProfileImage = '';
        let callTitle = 'Video Call';
        let isProviderUser = false; // Provider can end call, patient can only leave
        let currentMeetingId = null; // For API calls to end meeting
        let attendees = new Map();
        let videoTiles = new Map();
        let isMuted = false;
        let isVideoOff = false;
        let callState = 'inactive'; // Track call state: 'inactive', 'active', 'ended'
        let displayedMessageIds = new Set(); // Track displayed messages to prevent duplicates
        let chatVisible = false; // Track chat visibility for badge
        let unreadCount = 0; // Track unread messages
        let hasMessages = false; // Track if conversation has started (provider sent first message)
        let messageCount = 0; // Track total messages in chat

        // Permission caching to prevent repeated permission checks
        // This helps reduce the "CheckMediaAccessPermission: Not supported" loop
        let permissionsGranted = false;
        let permissionCheckInProgress = false;
        let cachedAudioDevices = null;
        let cachedVideoDevices = null;
        let noCameraMode = false; // Flag to disable video operations when no camera found
        let lastPermissionCheckTime = 0; // Throttle permission checks
        const PERMISSION_CHECK_THROTTLE_MS = 2000; // Only check permissions every 2 seconds
        let preAcquiredStream = null; // Store pre-acquired media stream to prevent device release

        // Update notification badge
        function updateChatBadge(count) {
            const badge = document.getElementById('chat-badge');
            if (!badge) return;

            unreadCount = count;
            if (count > 0) {
                badge.textContent = count > 99 ? '99+' : count;
                badge.classList.remove('hidden');
                // Play subtle notification sound (optional)
                // playNotificationSound();
            } else {
                badge.classList.add('hidden');
            }
        }

        // Increment badge when new message from other person
        function incrementUnreadCount() {
            if (!chatVisible) {
                updateChatBadge(unreadCount + 1);
            }
        }

        // Clear badge when chat is opened
        function clearUnreadCount() {
            updateChatBadge(0);
        }

        // Fallback check on window load (if SDK not already loaded)
        window.addEventListener('load', () => {
            console.log('🌐 Window loaded, sdkLoaded:', sdkLoaded);
            if (!sdkLoaded) {
                if (typeof window.ChimeSDK !== 'undefined') {
                    sdkLoaded = true;
                    console.log('✅ Chime SDK loaded (fallback on window.load)');
                    window.FlutterChannel?.postMessage('SDK_READY');
                } else {
                    console.error('❌ Chime SDK not found on window.load');
                    // Try loading again
                    handleSDKLoadError();
                }
            } else {
                console.log('✅ SDK already loaded, skipping window.load handler');
            }
        });

        // Join meeting function
        async function joinMeeting(meetingData, attendeeData) {
            try {
                console.log('🎬 Joining meeting...');

                // IMPORTANT: Request media permissions FIRST, before creating SDK objects
                // This ensures the device is fully released before Chime SDK tries to access it
                // Fixes "microphone is used by another application" error on Android
                console.log('📹 Step 1: Pre-requesting media permissions before SDK initialization...');
                await requestMediaPermissions();

                // Now create SDK objects after permissions are granted and streams released
                console.log('📦 Step 2: Creating Chime SDK objects...');
                const logger = new ChimeSDK.ConsoleLogger('SDK', ChimeSDK.LogLevel.WARN);
                const deviceController = new ChimeSDK.DefaultDeviceController(logger);
                const configuration = new ChimeSDK.MeetingSessionConfiguration(
                    meetingData.Meeting,
                    attendeeData.Attendee
                );

                meetingSession = new ChimeSDK.DefaultMeetingSession(
                    configuration,
                    logger,
                    deviceController
                );

                audioVideo = meetingSession.audioVideo;

                // Bind remote audio to a hidden sink so speakers work on WebView/mobile
                const audioElement = document.getElementById('meeting-audio');
                if (audioElement) {
                  audioElement.muted = false;
                  audioElement.autoplay = true;
                  audioElement.playsInline = true;
                  audioElement.volume = 1.0; // Ensure full volume
                  audioVideo.bindAudioElement(audioElement);
                  console.log('🔊 Audio element bound for speaker output (volume: 1.0)');
                  // Music profile reduces aggressive noise suppression that can mute speech on mobile
                  // Note: AudioProfile API varies by SDK version - make it optional
                  try {
                    if (ChimeSDK.AudioProfile) {
                      if (typeof ChimeSDK.AudioProfile.fullbandMusicStereo === 'function') {
                        // SDK 3.x API
                        audioVideo.setAudioProfile(ChimeSDK.AudioProfile.fullbandMusicStereo());
                        console.log('🎵 Audio profile set: fullbandMusicStereo');
                      } else if (typeof ChimeSDK.AudioProfile.music === 'function') {
                        // Older SDK API
                        audioVideo.setAudioProfile(ChimeSDK.AudioProfile.music());
                        console.log('🎵 Audio profile set: music');
                      } else {
                        console.log('🎵 Using default audio profile (no music profile available)');
                      }
                    }
                  } catch (profileError) {
                    console.warn('⚠️ Could not set audio profile:', profileError.message);
                  }
                } else {
                  console.warn('⚠️ meeting-audio element not found; remote audio may stay muted');
                }

                // Set up observers
                setupObservers();

                // Setup devices for Chime SDK (no need to re-request permissions)
                console.log('🎤 Step 3: Setting up audio/video devices for Chime SDK...');
                await setupDevices();

                // Start meeting
                audioVideo.start();

                // Update call state to active
                callState = 'active';
                console.log('📞 Call state: active');
                updateSendButtonState();

                // Show UI
                document.getElementById('loading').style.display = 'none';
                document.getElementById('container').style.display = 'flex';

                console.log('✅ Meeting started successfully');
            } catch (error) {
                console.error('❌ Failed to join meeting:', error);
                // Enhanced TypeError detection for meeting join
                if (error instanceof TypeError || error.name === 'TypeError') {
                    console.error('🚨 [TypeError] during meeting join');
                    console.error('   Message:', error.message);
                    console.error('   This may indicate: ChimeSDK not loaded, meeting data malformed, or API compatibility issue');
                    console.error('   Stack:', error.stack ? error.stack.split('\\n').slice(0, 5).join(' | ') : 'No stack');
                    window.FlutterChannel?.postMessage(JSON.stringify({
                        type: 'JS_ERROR',
                        errorType: 'TypeError',
                        message: 'Meeting join error: ' + error.message,
                        context: 'joinMeeting',
                        stack: error.stack || ''
                    }));
                }
                throw error;
            }
        }

        // Pre-request media permissions using navigator.mediaDevices.getUserMedia
        // This triggers the browser/WebView permission prompt before Chime SDK tries to access devices
        // Uses caching to prevent repeated permission checks which cause the
        // "CheckMediaAccessPermission: Not supported" loop on Android WebView
        async function requestMediaPermissions() {
            // Skip if permissions already granted (prevents looping)
            if (permissionsGranted) {
                console.log('📹 Permissions already granted (cached), skipping request');
                return true;
            }

            // Prevent concurrent permission checks
            if (permissionCheckInProgress) {
                console.log('📹 Permission check already in progress, waiting...');
                // Wait for existing check to complete
                while (permissionCheckInProgress) {
                    await new Promise(resolve => setTimeout(resolve, 100));
                }
                return permissionsGranted;
            }

            permissionCheckInProgress = true;
            console.log('📹 Pre-requesting camera and microphone permissions...');

            try {
                // Request both audio and video permissions in a single call
                // to minimize permission check events
                const stream = await navigator.mediaDevices.getUserMedia({
                    audio: true,
                    video: { facingMode: 'user' } // Request front camera by default
                });

                console.log('✅ Media permissions granted');
                console.log('   Audio tracks:', stream.getAudioTracks().length);
                console.log('   Video tracks:', stream.getVideoTracks().length);

                // Log available cameras for debugging
                stream.getVideoTracks().forEach((track, i) => {
                    console.log('   Camera ' + i + ':', track.label);
                });

                // IMPORTANT: On real Android devices, we MUST release the stream immediately
                // and wait for hardware to fully release before Chime SDK tries to acquire
                // Keeping the stream causes "device in use" errors on real hardware
                console.log('📹 Releasing stream immediately to free device for Chime SDK');
                stream.getTracks().forEach(track => {
                    console.log('   Stopping track:', track.kind, track.label);
                    track.stop();
                });

                // Real Android hardware needs significant time to release device locks
                // Emulators work with 100ms, but real devices need 2000ms+
                console.log('📹 Waiting 2000ms for hardware to release device locks...');
                await new Promise(resolve => setTimeout(resolve, 2000));
                console.log('📹 Device locks should be released, ready for Chime SDK');

                // Cache permission state to prevent future checks
                permissionsGranted = true;
                permissionCheckInProgress = false;
                return true;
            } catch (error) {
                console.error('❌ Media permission request failed:', error.name, error.message);
                permissionCheckInProgress = false;

                // Enhanced TypeError detection with diagnostic info
                if (error instanceof TypeError || error.name === 'TypeError') {
                    console.error('🚨 [TypeError] in media permission request');
                    console.error('   Message:', error.message);
                    console.error('   This may indicate: navigator.mediaDevices API not available or undefined');
                    console.error('   Stack:', error.stack ? error.stack.split('\\n').slice(0, 3).join(' | ') : 'No stack');
                    window.FlutterChannel?.postMessage(JSON.stringify({
                        type: 'JS_ERROR',
                        errorType: 'TypeError',
                        message: 'Camera API error: ' + error.message,
                        context: 'requestMediaPermissions',
                        stack: error.stack || ''
                    }));
                }

                // Provide helpful error messages
                if (error.name === 'NotAllowedError') {
                    console.error('⚠️ User denied camera/microphone permission');
                    window.FlutterChannel?.postMessage(JSON.stringify({
                        type: 'DEVICE_ERROR',
                        message: 'Camera and microphone permission denied. Please allow access in your device settings.'
                    }));
                } else if (error.name === 'NotFoundError') {
                    console.error('⚠️ No camera or microphone found');
                    // Set no camera mode to prevent repeated permission checks
                    noCameraMode = true;
                    console.log('📹 No camera mode enabled from permission check');

                    // Try audio-only as fallback
                    try {
                        const audioOnlyStream = await navigator.mediaDevices.getUserMedia({ audio: true });
                        console.log('✅ Audio-only permissions granted');
                        // Release immediately to free device for Chime SDK
                        audioOnlyStream.getTracks().forEach(track => {
                            console.log('   Stopping audio track:', track.label);
                            track.stop();
                        });
                        console.log('📹 Waiting 2000ms for audio device to release...');
                        await new Promise(resolve => setTimeout(resolve, 2000));
                        console.log('📹 Audio device should be released');
                        permissionsGranted = true; // Audio works at least
                        window.FlutterChannel?.postMessage(JSON.stringify({
                            type: 'DEVICE_WARNING',
                            message: 'Camera not found. Audio-only mode enabled.',
                            audioEnabled: true,
                            videoEnabled: false
                        }));
                        return true;
                    } catch (audioError) {
                        console.error('❌ Audio-only also failed:', audioError.name);
                        window.FlutterChannel?.postMessage(JSON.stringify({
                            type: 'DEVICE_ERROR',
                            message: 'No camera or microphone found on this device.'
                        }));
                    }
                } else if (error.name === 'NotReadableError') {
                    console.error('⚠️ Camera/microphone is in use by another app');
                    window.FlutterChannel?.postMessage(JSON.stringify({
                        type: 'DEVICE_ERROR',
                        message: 'Camera or microphone is being used by another app. Please close other apps and try again.'
                    }));
                } else if (error.name === 'OverconstrainedError') {
                    console.warn('⚠️ Camera constraints not satisfiable, trying without constraints');
                    // Try again without video constraints
                    try {
                        const fallbackStream = await navigator.mediaDevices.getUserMedia({
                            audio: true,
                            video: true
                        });
                        console.log('✅ Fallback media permissions granted');
                        // Release immediately to free device for Chime SDK
                        fallbackStream.getTracks().forEach(track => {
                            console.log('   Stopping fallback track:', track.label);
                            track.stop();
                        });
                        console.log('📹 Waiting 2000ms for device to release...');
                        await new Promise(resolve => setTimeout(resolve, 2000));
                        console.log('📹 Fallback device released');
                        permissionsGranted = true;
                        return true;
                    } catch (fallbackError) {
                        console.error('❌ Fallback also failed:', fallbackError.name);
                    }
                }

                // Continue anyway - Chime SDK will handle missing devices
                return false;
            }
        }

        // Setup audio/video devices with retry logic
        // Uses cached devices when available to minimize permission checks
        async function setupDevices() {
            let audioSuccess = false;
            let videoSuccess = false;

            // NOTE: We no longer store pre-acquired streams - permissions are verified and streams
            // are released immediately with a 2000ms delay in requestMediaPermissions()
            // This ensures device locks are fully released on real Android hardware before
            // Chime SDK tries to acquire them
            console.log('📹 Starting Chime SDK device setup (devices should be free)');

            // Try to setup audio first (use cached devices if available)
            try {
                const audioInputDevices = cachedAudioDevices || await audioVideo.listAudioInputDevices();
                cachedAudioDevices = audioInputDevices; // Cache for future use
                console.log('🎤 Audio devices found:', audioInputDevices.length);

                if (audioInputDevices.length > 0) {
                    // Try each audio device until one works
                    for (let i = 0; i < audioInputDevices.length; i++) {
                        try {
                            await audioVideo.startAudioInput(audioInputDevices[i].deviceId);
                            console.log('✅ Audio device selected:', audioInputDevices[i].label);
                            audioSuccess = true;
                            break;
                        } catch (audioErr) {
                            console.warn('⚠️ Audio device ' + i + ' failed:', audioErr.name);
                            // Enhanced TypeError detection for audio device selection
                            if (audioErr instanceof TypeError || audioErr.name === 'TypeError') {
                                console.error('🚨 [TypeError] during audio device selection');
                                console.error('   Device ID:', audioInputDevices[i].deviceId);
                                console.error('   Device Label:', audioInputDevices[i].label);
                                console.error('   Message:', audioErr.message);
                                console.error('   Stack:', audioErr.stack ? audioErr.stack.split('\\n').slice(0, 3).join(' | ') : 'No stack');
                                window.FlutterChannel?.postMessage(JSON.stringify({
                                    type: 'JS_ERROR',
                                    errorType: 'TypeError',
                                    message: 'Audio device error: ' + audioErr.message,
                                    context: 'startAudioInput',
                                    deviceIndex: i,
                                    deviceLabel: audioInputDevices[i].label || 'Unknown',
                                    stack: audioErr.stack || ''
                                }));
                            }
                            if (i === audioInputDevices.length - 1) {
                                console.error('❌ All audio devices failed');
                            }
                        }
                    }
                } else {
                    console.warn('⚠️ No audio input devices found');
                }
            } catch (error) {
                console.error('❌ Audio setup error:', error.name, error.message);
                // Enhanced TypeError detection for audio setup
                if (error instanceof TypeError || error.name === 'TypeError') {
                    console.error('🚨 [TypeError] during audio device setup');
                    console.error('   Message:', error.message);
                    console.error('   This may indicate: audioVideo API not ready or audio device enumeration failed');
                    console.error('   Stack:', error.stack ? error.stack.split('\\n').slice(0, 3).join(' | ') : 'No stack');
                    window.FlutterChannel?.postMessage(JSON.stringify({
                        type: 'JS_ERROR',
                        errorType: 'TypeError',
                        message: 'Audio setup error: ' + error.message,
                        context: 'setupDevices.audio',
                        stack: error.stack || ''
                    }));
                }
            }

            // Setup audio OUTPUT device (speaker) for hearing remote participants
            // Note: Android WebView doesn't support setSinkId() API used by chooseAudioOutputDevice
            // Audio output typically works by default on mobile, so we skip explicit selection
            let speakerSuccess = false;
            try {
                // Check if chooseAudioOutputDevice is supported (requires setSinkId API)
                const supportsAudioOutputSelection = typeof audioVideo.chooseAudioOutputDevice === 'function' &&
                    typeof HTMLMediaElement !== 'undefined' &&
                    typeof HTMLMediaElement.prototype.setSinkId === 'function';

                if (!supportsAudioOutputSelection) {
                    console.log('🔊 Audio output device selection not supported in this WebView - using default (this is normal on Android)');
                    speakerSuccess = true; // Audio output works via default system routing
                } else {
                    const audioOutputDevices = await audioVideo.listAudioOutputDevices();
                    console.log('🔊 Audio output devices (speakers) found:', audioOutputDevices.length);

                    if (audioOutputDevices.length > 0) {
                        // Try each speaker device until one works
                        for (let i = 0; i < audioOutputDevices.length; i++) {
                            try {
                                await audioVideo.chooseAudioOutputDevice(audioOutputDevices[i].deviceId);
                                console.log('✅ Speaker device selected:', audioOutputDevices[i].label || 'Default Speaker');
                                speakerSuccess = true;
                                break;
                            } catch (speakerErr) {
                                // TypeError means API not supported, break immediately
                                if (speakerErr instanceof TypeError || speakerErr.name === 'TypeError') {
                                    console.log('🔊 setSinkId not supported - using default audio output (this is normal on Android)');
                                    speakerSuccess = true;
                                    break;
                                }
                                console.warn('⚠️ Speaker device ' + i + ' failed:', speakerErr.name);
                                if (i === audioOutputDevices.length - 1) {
                                    console.warn('⚠️ All speaker devices failed - using default');
                                    speakerSuccess = true; // Still proceed with default
                                }
                            }
                        }
                    } else {
                        console.log('🔊 No audio output devices enumerated - using default (normal on Android WebView)');
                        // On mobile WebView, audio output is often handled automatically
                        speakerSuccess = true; // Assume default works
                    }
                }
            } catch (error) {
                console.log('🔊 Audio output setup skipped (unsupported in WebView):', error.name);
                // Audio output device selection may not be supported in all WebViews
                // The bindAudioElement call should still work for playback
                speakerSuccess = true; // Proceed anyway
            }

            if (speakerSuccess) {
                console.log('🔊 Speaker output configured successfully');
            }

            // Try to setup video (use cached devices if available)
            // Skip video setup entirely if we're already in no camera mode
            if (noCameraMode) {
                console.log('📹 Skipping video setup - no camera mode already active');
                // Still report the warning
                window.FlutterChannel?.postMessage(JSON.stringify({
                    type: 'DEVICE_WARNING',
                    message: 'Camera unavailable. You can speak but others cannot see you.',
                    audioEnabled: audioSuccess,
                    videoEnabled: false
                }));
                return;
            }

            try {
                // Throttle video device enumeration to prevent permission check loop
                const now = Date.now();
                if (now - lastPermissionCheckTime < PERMISSION_CHECK_THROTTLE_MS && cachedVideoDevices !== null) {
                    console.log('📹 Using cached video devices (throttled)');
                }
                lastPermissionCheckTime = now;

                const videoInputDevices = cachedVideoDevices || await audioVideo.listVideoInputDevices();
                cachedVideoDevices = videoInputDevices; // Cache for future use
                console.log('📹 Video devices found:', videoInputDevices.length);

                if (videoInputDevices.length > 0) {
                    // Try each video device until one works
                    for (let i = 0; i < videoInputDevices.length; i++) {
                        try {
                            await audioVideo.startVideoInput(videoInputDevices[i].deviceId);
                            audioVideo.startLocalVideoTile();
                            console.log('✅ Video device selected:', videoInputDevices[i].label);
                            videoSuccess = true;
                            break;
                        } catch (videoErr) {
                            console.warn('⚠️ Video device ' + i + ' failed:', videoErr.name);
                            // Enhanced TypeError detection for video device selection
                            if (videoErr instanceof TypeError || videoErr.name === 'TypeError') {
                                console.error('🚨 [TypeError] during video device selection');
                                console.error('   Device ID:', videoInputDevices[i].deviceId);
                                console.error('   Device Label:', videoInputDevices[i].label);
                                console.error('   Message:', videoErr.message);
                                console.error('   Stack:', videoErr.stack ? videoErr.stack.split('\\n').slice(0, 3).join(' | ') : 'No stack');
                                window.FlutterChannel?.postMessage(JSON.stringify({
                                    type: 'JS_ERROR',
                                    errorType: 'TypeError',
                                    message: 'Video device error: ' + videoErr.message,
                                    context: 'startVideoInput',
                                    deviceIndex: i,
                                    deviceLabel: videoInputDevices[i].label || 'Unknown',
                                    stack: videoErr.stack || ''
                                }));
                            }
                            // NotReadableError = device busy, NotAllowedError = permission denied
                            if (videoErr.name === 'NotReadableError') {
                                console.warn('📹 Camera may be in use by another app');
                            }
                            if (i === videoInputDevices.length - 1) {
                                console.error('❌ All video devices failed');
                            }
                        }
                    }
                } else {
                    console.warn('⚠️ No video input devices found');
                    // Set noCameraMode immediately when no video devices found
                    noCameraMode = true;
                    console.log('📹 No camera mode enabled - no video devices detected');
                }
            } catch (error) {
                console.error('❌ Video setup error:', error.name, error.message);
                // Enhanced TypeError detection for video setup
                if (error instanceof TypeError || error.name === 'TypeError') {
                    console.error('🚨 [TypeError] during video device setup');
                    console.error('   Message:', error.message);
                    console.error('   This may indicate: audioVideo API not ready or device enumeration failed');
                    console.error('   Stack:', error.stack ? error.stack.split('\\n').slice(0, 3).join(' | ') : 'No stack');
                    window.FlutterChannel?.postMessage(JSON.stringify({
                        type: 'JS_ERROR',
                        errorType: 'TypeError',
                        message: 'Video setup error: ' + error.message,
                        context: 'setupDevices.video',
                        stack: error.stack || ''
                    }));
                }
                // Also set noCameraMode on error to prevent repeated permission checks
                noCameraMode = true;
            }

            // Report status to Flutter
            if (!audioSuccess && !videoSuccess) {
                console.warn('⚠️ Joining call with no media devices - audio/video unavailable');
                window.FlutterChannel?.postMessage(JSON.stringify({
                    type: 'DEVICE_ERROR',
                    message: 'Camera and microphone unavailable. Please close other apps using the camera and try again.',
                    audioEnabled: false,
                    videoEnabled: false
                }));
            } else if (!audioSuccess) {
                console.warn('⚠️ Audio device unavailable - video only mode');
                window.FlutterChannel?.postMessage(JSON.stringify({
                    type: 'DEVICE_WARNING',
                    message: 'Microphone unavailable. You can see video but cannot speak.',
                    audioEnabled: false,
                    videoEnabled: true
                }));
            } else if (!videoSuccess) {
                console.warn('⚠️ Video device unavailable - audio only mode');
                // Set noCameraMode to prevent any further video device polling
                noCameraMode = true;
                window.FlutterChannel?.postMessage(JSON.stringify({
                    type: 'DEVICE_WARNING',
                    message: 'Camera unavailable. You can speak but others cannot see you.',
                    audioEnabled: true,
                    videoEnabled: false
                }));
                // Update video button state to show camera is off and disable it
                isVideoOff = true;
                const videoBtn = document.getElementById('video-btn');
                if (videoBtn) {
                    videoBtn.classList.add('active');
                    videoBtn.disabled = true;
                    videoBtn.style.opacity = '0.5';
                    videoBtn.style.cursor = 'not-allowed';
                }
                // Also disable camera switch button
                const switchCameraBtn = document.getElementById('switch-camera-btn');
                if (switchCameraBtn) {
                    switchCameraBtn.disabled = true;
                    switchCameraBtn.style.opacity = '0.5';
                    switchCameraBtn.style.cursor = 'not-allowed';
                    switchCameraBtn.style.display = 'none'; // Hide completely since no camera
                }
                console.log('📹 No camera mode enabled - video controls disabled');
            } else {
                console.log('✅ All devices configured successfully');
            }

        }

        // Setup event observers
        function setupObservers() {
            // Attendee presence observer
            audioVideo.realtimeSubscribeToAttendeeIdPresence((attendeeId, present) => {
                if (present) {
                    console.log('👤 Attendee joined:', attendeeId);
                    attendees.set(attendeeId, { id: attendeeId, name: currentAttendeeName });
                    window.FlutterChannel?.postMessage(JSON.stringify({
                        type: 'ATTENDEE_JOINED',
                        attendeeId: attendeeId,
                        name: currentAttendeeName
                    }));
                } else {
                    console.log('👋 Attendee left:', attendeeId);
                    attendees.delete(attendeeId);
                    window.FlutterChannel?.postMessage(JSON.stringify({
                        type: 'ATTENDEE_LEFT',
                        attendeeId: attendeeId
                    }));
                }
                updateParticipantCount();
            });

            // Video tile observer
            const observer = {
                // Called when the meeting session stops (meeting ended by anyone)
                audioVideoDidStop: (sessionStatus) => {
                    console.log('🛑 Meeting session stopped:', sessionStatus);
                    const statusCode = sessionStatus?.statusCode?.();
                    console.log('Status code:', statusCode);

                    // Meeting was ended (by provider or system)
                    callState = 'ended';
                    updateSendButtonState();

                    // Show message to user
                    const isEnded = statusCode === 1 || statusCode === 2; // MeetingEnded or AudioVideoWasStopped
                    const message = isEnded
                        ? 'The call has ended.'
                        : 'You have been disconnected from the call.';

                    console.log('📞 ' + message);

                    // Notify Flutter that meeting ended
                    window.FlutterChannel?.postMessage('MEETING_ENDED_BY_HOST');
                },

                // Called when connection drops
                audioVideoDidStartConnecting: (reconnecting) => {
                    if (reconnecting) {
                        console.log('🔄 Reconnecting to meeting...');
                    }
                },

                videoTileDidUpdate: (tileState) => {
                    console.log('🎥 Video tile updated:', tileState.tileId, 'isLocal:', tileState.localTile, 'attendee:', tileState.boundAttendeeId);

                    if (!tileState.boundAttendeeId) return;

                    // Check if tile already exists - if so, just update binding
                    if (videoTiles.has(tileState.tileId)) {
                        console.log('🔄 Tile already exists, updating binding');
                        const existingTile = videoTiles.get(tileState.tileId);
                        const existingVideo = existingTile.querySelector('video');
                        if (existingVideo) {
                            audioVideo.bindVideoElement(tileState.tileId, existingVideo);
                        }
                        return;
                    }

                    // Create new video element for new tile
                    const videoElement = document.createElement('video');
                    videoElement.autoplay = true;
                    videoElement.playsinline = true;
                    videoElement.muted = tileState.localTile; // Mute local video to prevent feedback

                    // Bind video element to tile
                    audioVideo.bindVideoElement(tileState.tileId, videoElement);

                    // Create tile UI
                    const tile = createVideoTile(tileState, videoElement);
                    videoTiles.set(tileState.tileId, tile);

                    updateVideoGrid();

                    console.log('✅ Video tile created:', tileState.localTile ? 'LOCAL' : 'REMOTE', '- Total tiles:', videoTiles.size);

                    window.FlutterChannel?.postMessage(JSON.stringify({
                        type: 'VIDEO_TILE_ADDED',
                        tileId: tileState.tileId,
                        attendeeId: tileState.boundAttendeeId,
                        isLocal: tileState.localTile
                    }));
                },

                videoTileWasRemoved: (tileId) => {
                    console.log('📴 Video tile removed:', tileId);
                    const tile = videoTiles.get(tileId);
                    if (tile) {
                        tile.remove();
                        videoTiles.delete(tileId);
                        updateVideoGrid();
                    }

                    window.FlutterChannel?.postMessage(JSON.stringify({
                        type: 'VIDEO_TILE_REMOVED',
                        tileId: tileId
                    }));
                }
            };

            audioVideo.addObserver(observer);

            // Active speaker observer
            audioVideo.subscribeToActiveSpeakerDetector(
                new ChimeSDK.DefaultActiveSpeakerPolicy(),
                (attendeeIds) => {
                    if (attendeeIds.length > 0) {
                        const speakerId = attendeeIds[0];
                        highlightActiveSpeaker(speakerId);
                        window.FlutterChannel?.postMessage(JSON.stringify({
                            type: 'ACTIVE_SPEAKER_CHANGED',
                            attendeeId: speakerId
                        }));
                    }
                }
            );

            // Mute status observer
            audioVideo.realtimeSubscribeToVolumeIndicator((attendeeId, volume, muted) => {
                const isSelf = attendeeId === meetingSession.configuration.credentials.attendeeId;
                if (muted) {
                    window.FlutterChannel?.postMessage(JSON.stringify({
                        type: 'ATTENDEE_MUTED',
                        attendeeId: attendeeId,
                        isSelf: isSelf
                    }));
                } else {
                    window.FlutterChannel?.postMessage(JSON.stringify({
                        type: 'ATTENDEE_UNMUTED',
                        attendeeId: attendeeId,
                        isSelf: isSelf
                    }));
                }
                updateTileMuteStatus(attendeeId, muted);
            });
        }

        // Create video tile element
        function createVideoTile(tileState, videoElement) {
            const tile = document.createElement('div');
            tile.className = 'video-tile';
            tile.dataset.tileId = tileState.tileId;
            tile.dataset.attendeeId = tileState.boundAttendeeId;

            // Determine display name and profile image
            // For local tile: use current user's info
            // For remote tile: use call title info or "Other Participant"
            const isLocal = tileState.localTile;
            let displayName = isLocal ? 'You' : 'Other Participant';
            let profileImageUrl = isLocal ? currentUserProfileImage : null;
            let roleText = '';

            // For remote tiles, try to get provider info if patient is viewing
            if (!isLocal) {
                // If this is the patient viewing the provider
                if (callTitle && callTitle.includes('Doctor')) {
                    // Remove "Consultation " prefix and any date patterns
                    displayName = callTitle.replace('Consultation ', '').replace(/\d{2}\/\d{4}\s*/g, '').trim();
                } else if (callTitle && callTitle.includes('with ')) {
                    displayName = callTitle.split('with ')[1] || 'Provider';
                }
            }

            // Create profile picture element (shown when camera is off)
            const profilePic = document.createElement('div');
            profilePic.className = 'video-tile-profile';

            if (profileImageUrl && profileImageUrl.trim()) {
                const img = document.createElement('img');
                img.src = profileImageUrl;
                img.alt = displayName;
                img.onerror = function() {
                    this.style.display = 'none';
                    profilePic.textContent = getInitials(displayName);
                };
                profilePic.appendChild(img);
            } else {
                profilePic.textContent = getInitials(displayName);
            }

            const info = document.createElement('div');
            info.className = 'video-tile-info';

            const name = document.createElement('span');
            name.className = 'attendee-name';
            name.textContent = displayName;

            // Add role for remote participant if provider info is available
            if (!isLocal && currentUserRole && currentUserRole.trim()) {
                const role = document.createElement('div');
                role.className = 'attendee-role';
                role.textContent = currentUserRole;
                info.appendChild(name);
                info.appendChild(role);
            } else {
                info.appendChild(name);
            }

            const status = document.createElement('div');
            status.className = 'attendee-status';
            status.innerHTML = '<span class="status-icon">🔊</span><span class="status-icon">📹</span>';

            info.appendChild(status);
            tile.appendChild(profilePic);
            tile.appendChild(videoElement);
            tile.appendChild(info);

            document.getElementById('video-grid').appendChild(tile);

            console.log('🎬 Created video tile for:', displayName, isLocal ? '(You)' : '(Remote)');

            return tile;
        }

        // Update video grid layout
        function updateVideoGrid() {
            const grid = document.getElementById('video-grid');
            const count = videoTiles.size;
            grid.className = `count-${count}`;
        }

        // Update participant count
        function updateParticipantCount() {
            console.log('👥 Total participants:', attendees.size);
        }

        // Highlight active speaker
        function highlightActiveSpeaker(attendeeId) {
            document.querySelectorAll('.video-tile').forEach(tile => {
                tile.classList.remove('active-speaker');
            });

            const activeTile = document.querySelector(`[data-attendee-id="${attendeeId}"]`);
            if (activeTile) {
                activeTile.classList.add('active-speaker');
            }
        }

        // Update tile mute status
        function updateTileMuteStatus(attendeeId, muted) {
            const tile = document.querySelector(`[data-attendee-id="${attendeeId}"]`);
            if (tile) {
                const muteIcon = tile.querySelector('.status-icon:first-child');
                if (muteIcon) {
                    muteIcon.textContent = muted ? '🔇' : '🔊';
                }
            }
        }

        // Control button handlers
        document.getElementById('mute-btn').addEventListener('click', () => {
            if (!audioVideo) return;

            isMuted = !isMuted;
            const btn = document.getElementById('mute-btn');

            if (isMuted) {
                audioVideo.realtimeMuteLocalAudio();
                btn.classList.add('active');
                btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="1" y1="1" x2="23" y2="23"></line><path d="M9 9v3a3 3 0 0 0 5.12 2.12M15 9.34V4a3 3 0 0 0-5.94-.6"></path><path d="M17 16.95A7 7 0 0 1 5 12v-2m14 0v2a7 7 0 0 1-.11 1.23"></path><line x1="12" y1="19" x2="12" y2="23"></line><line x1="8" y1="23" x2="16" y2="23"></line></svg>';
            } else {
                audioVideo.realtimeUnmuteLocalAudio();
                btn.classList.remove('active');
                btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"></path><path d="M19 10v2a7 7 0 0 1-14 0v-2"></path><line x1="12" y1="19" x2="12" y2="23"></line><line x1="8" y1="23" x2="16" y2="23"></line></svg>';
            }
        });

        document.getElementById('video-btn').addEventListener('click', () => {
            if (!audioVideo) return;

            // Skip if in no camera mode - prevents permission check loop
            if (noCameraMode) {
                console.log('📹 Video toggle skipped - no camera mode active');
                return;
            }

            isVideoOff = !isVideoOff;
            const btn = document.getElementById('video-btn');

            if (isVideoOff) {
                audioVideo.stopLocalVideoTile();
                btn.classList.add('active');
                btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 16v1a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2h2m5.66 0H14a2 2 0 0 1 2 2v3.34l1 1L23 7v10"></path><line x1="1" y1="1" x2="23" y2="23"></line></svg>';

                // Add camera-off class to local video tile to show profile picture
                const localTiles = document.querySelectorAll('.video-tile');
                localTiles.forEach(tile => {
                    const videoEl = tile.querySelector('video');
                    if (videoEl && videoEl.srcObject) {
                        tile.classList.add('camera-off');
                    }
                });
            } else {
                audioVideo.startLocalVideoTile();
                btn.classList.remove('active');
                btn.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="23 7 16 12 23 17 23 7"></polygon><rect x="1" y="5" width="15" height="14" rx="2" ry="2"></rect></svg>';

                // Remove camera-off class to hide profile picture
                const localTiles = document.querySelectorAll('.video-tile');
                localTiles.forEach(tile => {
                    tile.classList.remove('camera-off');
                });
            }
        });

        // Camera switch button - toggles between front and back camera
        // Uses cached video devices to minimize permission checks
        let currentCameraIndex = 0;
        let availableCameras = [];
        document.getElementById('switch-camera-btn').addEventListener('click', async () => {
            if (!audioVideo || isVideoOff) {
                console.log('📷 Cannot switch camera - video is off');
                return;
            }

            // Skip if in no camera mode - prevents permission check loop
            if (noCameraMode) {
                console.log('📷 Camera switch skipped - no camera mode active');
                return;
            }

            try {
                // Get available video devices (use cached if available)
                const videoDevices = cachedVideoDevices || await audioVideo.listVideoInputDevices();
                if (!cachedVideoDevices) {
                    cachedVideoDevices = videoDevices; // Cache for future use
                }
                console.log('📷 Available cameras:', videoDevices.length);

                if (videoDevices.length < 2) {
                    console.log('📷 Only one camera available, cannot switch');
                    return;
                }

                // Store available cameras
                availableCameras = videoDevices;

                // Switch to next camera
                currentCameraIndex = (currentCameraIndex + 1) % availableCameras.length;
                const nextCamera = availableCameras[currentCameraIndex];

                console.log('📷 Switching to camera:', nextCamera.label || 'Camera ' + currentCameraIndex);

                // Switch the video input device (Chime SDK v3 API)
                await audioVideo.startVideoInput(nextCamera.deviceId);

                // Briefly show camera switch feedback
                const btn = document.getElementById('switch-camera-btn');
                btn.style.backgroundColor = 'rgba(37, 211, 102, 0.3)';
                setTimeout(() => {
                    btn.style.backgroundColor = '';
                }, 300);

                console.log('✅ Camera switched successfully');
            } catch (error) {
                console.error('❌ Failed to switch camera:', error);
            }
        });

        document.getElementById('chat-btn').addEventListener('click', () => {
            console.log('💬 Chat button in controls clicked');
            toggleChat();
        });

        document.getElementById('leave-btn').addEventListener('click', () => {
            handleLeaveOrEnd();
        });

        // Function to handle leave (patient) or end (provider) the meeting
        async function handleLeaveOrEnd() {
            if (isProviderUser) {
                // Provider ends the call for everyone
                console.log('📞 Provider ending call...');
                await endMeetingForAll();
            } else {
                // Patient just leaves (can rejoin later)
                console.log('👋 Patient leaving call...');
                leaveMeeting();
            }
        }

        // Provider ends the meeting for everyone
        async function endMeetingForAll() {
            try {
                // Stop local audio/video first
                if (audioVideo) {
                    audioVideo.stop();
                }

                // Ensure pre-acquired stream is released
                if (preAcquiredStream) {
                    console.log('📹 Releasing pre-acquired stream on call end');
                    preAcquiredStream.getTracks().forEach(track => track.stop());
                    preAcquiredStream = null;
                }

                // Update call state
                callState = 'ended';
                console.log('📞 Call state: ended by provider');
                updateSendButtonState();

                // Notify Flutter that the provider ended the call
                window.FlutterChannel?.postMessage('MEETING_ENDED_BY_PROVIDER:' + currentMeetingId);
            } catch (error) {
                console.error('Error ending meeting:', error);
                // Still leave even if API call fails
                window.FlutterChannel?.postMessage('MEETING_LEFT');
            }
        }

        // Patient leaves the meeting (can rejoin)
        function leaveMeeting() {
            if (audioVideo) {
                audioVideo.stop();
            }

            // Ensure pre-acquired stream is released
            if (preAcquiredStream) {
                console.log('📹 Releasing pre-acquired stream on leave');
                preAcquiredStream.getTracks().forEach(track => track.stop());
                preAcquiredStream = null;
            }

            // For patients, call state is 'left' not 'ended' (they can rejoin)
            callState = 'left';
            console.log('👋 Call state: left (can rejoin)');
            updateSendButtonState();

            window.FlutterChannel?.postMessage('MEETING_LEFT');
        }

        // Update send button state based on call state and user role
        function updateSendButtonState() {
            const sendBtn = document.getElementById('send-btn');
            const chatInput = document.getElementById('chat-input');
            const isProvider = isProviderUser || (currentUserRole && currentUserRole.trim() !== '');

            if (!sendBtn || !chatInput) return;

            // Providers can always send messages during appointment time
            if (isProvider) {
                sendBtn.disabled = false;
                sendBtn.style.opacity = '1';
                sendBtn.style.cursor = 'pointer';
                chatInput.disabled = false;
                chatInput.placeholder = 'Type a message...';
                console.log('✅ Send enabled (provider - can always send)');
                return;
            }

            // Patients can send messages if:
            // 1. Call is active, OR
            // 2. Conversation has started (provider sent first message)
            const canSend = callState === 'active' || hasMessages;

            if (canSend) {
                sendBtn.disabled = false;
                sendBtn.style.opacity = '1';
                sendBtn.style.cursor = 'pointer';
                chatInput.disabled = false;
                chatInput.placeholder = 'Type a message...';
                console.log('✅ Send enabled (patient - ' + (callState === 'active' ? 'call active' : 'conversation started') + ')');
            } else {
                sendBtn.disabled = true;
                sendBtn.style.opacity = '0.5';
                sendBtn.style.cursor = 'not-allowed';
                chatInput.disabled = true;
                if (callState === 'inactive') {
                    chatInput.placeholder = 'Wait for doctor to start conversation...';
                } else if (callState === 'ended') {
                    chatInput.placeholder = 'Call has ended';
                } else {
                    chatInput.placeholder = 'Wait for doctor to start conversation...';
                }
                console.log(`🚫 Send disabled (patient - call ${callState}, hasMessages: ${hasMessages})`);
            }
        }

        // Chat functionality (chatVisible already declared above)
        let emojiPickerVisible = false;
        const commonEmojis = [
            '😀', '😃', '😄', '😁', '😊', '😍', '🥰', '😘',
            '👍', '👎', '👏', '🙌', '💪', '✨', '🎉', '🎊',
            '❤️', '💕', '💖', '💗', '👋', '✋', '🤝', '🙏',
            '😂', '🤣', '😅', '😆', '😉', '😌', '😎', '🤩',
        ];

        function initializeEmojiPicker() {
            const emojiGrid = document.querySelector('.emoji-grid');
            commonEmojis.forEach(emoji => {
                const item = document.createElement('div');
                item.className = 'emoji-item';
                item.textContent = emoji;
                item.onclick = () => insertEmoji(emoji);
                emojiGrid.appendChild(item);
            });
        }

        function toggleChat() {
            chatVisible = !chatVisible;
            const panel = document.getElementById('chat-panel');
            const chatTitleElement = document.getElementById('chat-title');

            if (chatVisible) {
                panel.classList.remove('hidden');
                panel.classList.add('visible');
                clearUnreadCount();
                if (chatTitleElement) {
                    chatTitleElement.textContent = callTitle;
                }
                updateSendButtonState();
                window.FlutterChannel?.postMessage(JSON.stringify({type: 'CHAT_VISIBILITY', visible: true}));
                window.FlutterChannel?.postMessage(JSON.stringify({type: 'LOAD_MESSAGES'}));
            } else {
                panel.classList.remove('visible');
                panel.classList.add('hidden');
                window.FlutterChannel?.postMessage(JSON.stringify({type: 'CHAT_VISIBILITY', visible: false}));
            }
        }

        function toggleEmojiPicker() {
            emojiPickerVisible = !emojiPickerVisible;
            const picker = document.getElementById('emoji-picker');
            picker.classList.toggle('hidden', !emojiPickerVisible);
        }

        function insertEmoji(emoji) {
            const input = document.getElementById('chat-input');
            input.value += emoji;
            input.focus();
            toggleEmojiPicker();
        }

        function sendChatMessage() {
            const input = document.getElementById('chat-input');
            const message = input.value.trim();
            if (!message) return;

            const messageData = {
                type: 'SEND_MESSAGE',
                data: {
                    message: message,
                    messageType: 'text',
                    timestamp: new Date().toISOString(),
                    sender: currentAttendeeName,
                    role: currentUserRole,
                    profileImage: currentUserProfileImage
                }
            };

            window.FlutterChannel?.postMessage(JSON.stringify(messageData));
            displayMessage({
                sender: currentAttendeeName,
                role: currentUserRole,
                profileImage: currentUserProfileImage,
                message: message,
                timestamp: new Date().toISOString(),
                isOwn: true
            });

            input.value = '';
        }

        function getInitials(name) {
            if (!name) return '?';
            const parts = name.trim().split(' ');
            if (parts.length >= 2) {
                return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
            }
            return name.substring(0, 2).toUpperCase();
        }

        function displayMessage(msg) {
            // Prevent duplicate messages using message ID
            if (msg.id && displayedMessageIds.has(msg.id)) {
                console.log('⏭️ Skipping duplicate message:', msg.id);
                return;
            }

            // Track this message ID
            if (msg.id) {
                displayedMessageIds.add(msg.id);
                console.log('✅ Displaying message:', msg.id, '- Total displayed:', displayedMessageIds.size);
            }

            // Track message count and conversation state
            messageCount++;
            if (!hasMessages) {
                hasMessages = true;
                console.log('💬 Conversation started - hasMessages set to true');
                // Update send button state for patients now that conversation has started
                updateSendButtonState();
            }

            // Increment unread count for messages from other person (not own)
            if (!msg.isOwn && msg.id) {
                incrementUnreadCount();
                console.log('🔔 New message from other user, unread count:', unreadCount);
            }

            const messagesContainer = document.getElementById('chat-messages');
            const messageDiv = document.createElement('div');
            messageDiv.className = `chat-message ${msg.isOwn ? 'own' : 'other'}`;

            // Create avatar
            const avatarEl = document.createElement('div');
            avatarEl.className = 'message-avatar';

            if (msg.profileImage && msg.profileImage.trim()) {
                const img = document.createElement('img');
                img.src = msg.profileImage;
                img.alt = msg.sender || 'User';
                img.onerror = function() {
                    // Fallback to initials if image fails to load
                    this.style.display = 'none';
                    avatarEl.textContent = getInitials(msg.sender || 'User');
                };
                avatarEl.appendChild(img);
            } else {
                avatarEl.textContent = getInitials(msg.sender || 'User');
            }

            // Create content wrapper
            const contentWrapper = document.createElement('div');
            contentWrapper.className = 'message-content-wrapper';

            // Sender name with role
            const senderDiv = document.createElement('div');
            senderDiv.className = 'message-sender';
            let senderText = msg.sender || 'Unknown';
            if (msg.role && msg.role.trim()) {
                senderText = `${msg.role} ${senderText}`;
            }
            senderDiv.textContent = senderText;

            // Message content
            const contentDiv = document.createElement('div');
            contentDiv.className = 'message-content';

            if (msg.messageType === 'image' && msg.fileUrl) {
                const imgContainer = document.createElement('div');
                imgContainer.className = 'message-image-container';

                const img = document.createElement('img');
                img.src = msg.fileUrl;
                img.className = 'message-image';
                img.alt = msg.fileName || 'Image';
                img.onclick = () => {
                    // Open in new window or download
                    if (msg.fileUrl.startsWith('data:')) {
                        const link = document.createElement('a');
                        link.href = msg.fileUrl;
                        link.download = msg.fileName || 'image.jpg';
                        link.click();
                    } else {
                        window.open(msg.fileUrl, '_blank');
                    }
                };
                img.onerror = () => {
                    imgContainer.innerHTML = '🖼️ ' + (msg.fileName || 'Image failed to load');
                    imgContainer.className = 'message-file';
                };
                imgContainer.appendChild(img);

                if (msg.fileName) {
                    const caption = document.createElement('div');
                    caption.className = 'message-file-name';
                    caption.textContent = msg.fileName;
                    imgContainer.appendChild(caption);
                }
                contentDiv.appendChild(imgContainer);
            } else if (msg.messageType === 'video' && msg.fileUrl) {
                const videoContainer = document.createElement('div');
                videoContainer.className = 'message-file';
                videoContainer.innerHTML = '🎬 ' + (msg.fileName || 'Video');
                videoContainer.style.cursor = 'pointer';
                videoContainer.onclick = () => {
                    if (msg.fileUrl.startsWith('data:')) {
                        const link = document.createElement('a');
                        link.href = msg.fileUrl;
                        link.download = msg.fileName || 'video.mp4';
                        link.click();
                    } else {
                        window.open(msg.fileUrl, '_blank');
                    }
                };
                contentDiv.appendChild(videoContainer);
            } else if (msg.messageType === 'audio' && msg.fileUrl) {
                const audioContainer = document.createElement('div');
                audioContainer.className = 'message-file';
                audioContainer.innerHTML = '🎵 ' + (msg.fileName || 'Audio');
                audioContainer.style.cursor = 'pointer';
                audioContainer.onclick = () => {
                    if (msg.fileUrl.startsWith('data:')) {
                        const link = document.createElement('a');
                        link.href = msg.fileUrl;
                        link.download = msg.fileName || 'audio.mp3';
                        link.click();
                    } else {
                        window.open(msg.fileUrl, '_blank');
                    }
                };
                contentDiv.appendChild(audioContainer);
            } else if ((msg.messageType === 'file' || msg.fileName) && msg.fileUrl) {
                const fileDiv = document.createElement('div');
                fileDiv.className = 'message-file';
                const icon = typeof getFileIcon === 'function' ? getFileIcon(msg.fileName || '', msg.fileType) : '📎';
                fileDiv.innerHTML = icon + ' ' + (msg.fileName || 'File');
                fileDiv.style.cursor = 'pointer';
                fileDiv.onclick = () => {
                    if (msg.fileUrl.startsWith('data:')) {
                        const link = document.createElement('a');
                        link.href = msg.fileUrl;
                        link.download = msg.fileName || 'file';
                        link.click();
                    } else {
                        window.open(msg.fileUrl, '_blank');
                    }
                };
                contentDiv.appendChild(fileDiv);
            } else {
                contentDiv.textContent = msg.message || '';
            }

            // Timestamp
            const timeDiv = document.createElement('div');
            timeDiv.className = 'message-time';
            timeDiv.textContent = new Date(msg.timestamp).toLocaleTimeString();

            // Assemble message
            contentWrapper.appendChild(senderDiv);
            contentWrapper.appendChild(contentDiv);
            contentWrapper.appendChild(timeDiv);

            messageDiv.appendChild(avatarEl);
            messageDiv.appendChild(contentWrapper);

            messagesContainer.appendChild(messageDiv);
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        }

        function handleFileSelect(event) {
            const file = event.target.files[0];
            if (!file) return;

            // File size limit: 25MB
            const maxSize = 25 * 1024 * 1024;
            if (file.size > maxSize) {
                alert('File size exceeds 25MB limit. Please select a smaller file.');
                return;
            }

            // Show loading indicator
            const sendBtn = document.getElementById('send-btn');
            const originalContent = sendBtn.innerHTML;
            sendBtn.innerHTML = '⏳';
            sendBtn.disabled = true;

            const reader = new FileReader();
            reader.onload = function(e) {
                const isImage = file.type.startsWith('image/');
                const isVideo = file.type.startsWith('video/');
                const isAudio = file.type.startsWith('audio/');

                let messageType = 'file';
                if (isImage) messageType = 'image';
                else if (isVideo) messageType = 'video';
                else if (isAudio) messageType = 'audio';

                const messageData = {
                    type: 'SEND_MESSAGE',
                    data: {
                        fileName: file.name,
                        fileType: file.type,
                        fileSize: file.size,
                        fileData: e.target.result,
                        messageType: messageType,
                        message: getFileDescription(file),
                        timestamp: new Date().toISOString(),
                        sender: currentAttendeeName,
                        role: currentUserRole,
                        profileImage: currentUserProfileImage
                    }
                };

                // Show local preview immediately
                displayMessage({
                    sender: currentAttendeeName,
                    role: currentUserRole,
                    profileImage: currentUserProfileImage,
                    message: getFileDescription(file),
                    messageType: messageType,
                    fileName: file.name,
                    fileUrl: e.target.result, // Use base64 for preview
                    fileSize: file.size,
                    timestamp: new Date().toISOString(),
                    isOwn: true
                });

                // Send to Flutter for upload
                window.FlutterChannel?.postMessage(JSON.stringify(messageData));

                // Reset send button
                sendBtn.innerHTML = originalContent;
                sendBtn.disabled = false;
            };

            reader.onerror = function() {
                alert('Error reading file. Please try again.');
                sendBtn.innerHTML = originalContent;
                sendBtn.disabled = false;
            };

            reader.readAsDataURL(file);

            // Clear the input so same file can be selected again
            event.target.value = '';
        }

        function getFileDescription(file) {
            const sizeKB = Math.round(file.size / 1024);
            const sizeMB = (file.size / (1024 * 1024)).toFixed(1);
            const sizeStr = file.size > 1024 * 1024 ? sizeMB + ' MB' : sizeKB + ' KB';
            return file.name + ' (' + sizeStr + ')';
        }

        function getFileIcon(fileName, fileType) {
            if (fileType && fileType.startsWith('image/')) return '🖼️';
            if (fileType && fileType.startsWith('video/')) return '🎬';
            if (fileType && fileType.startsWith('audio/')) return '🎵';

            const ext = fileName.split('.').pop().toLowerCase();
            const icons = {
                'pdf': '📄',
                'doc': '📝', 'docx': '📝',
                'xls': '📊', 'xlsx': '📊',
                'ppt': '📽️', 'pptx': '📽️',
                'txt': '📃', 'rtf': '📃',
                'zip': '📦', 'rar': '📦', '7z': '📦',
                'csv': '📊',
                'json': '📋', 'xml': '📋',
                'html': '🌐', 'css': '🎨', 'js': '⚙️',
                'py': '🐍', 'java': '☕', 'dart': '🎯',
                'md': '📖'
            };
            return icons[ext] || '📎';
        }

        function receiveMessage(messageData) {
            displayMessage(messageData);
        }

        // Initialize chat event listeners
        function initializeChatEventListeners() {
            console.log('🎯 Initializing chat event listeners...');

            // Back button
            const backBtn = document.getElementById('back-btn');
            if (backBtn) {
                backBtn.addEventListener('click', (e) => {
                    console.log('⬅️ Back button clicked!');
                    e.preventDefault();
                    e.stopPropagation();
                    toggleChat();
                });
                console.log('✅ Back button listener attached');
            } else {
                console.error('❌ Back button not found!');
            }

            // Emoji button
            const emojiBtn = document.getElementById('emoji-btn');
            if (emojiBtn) {
                emojiBtn.addEventListener('click', (e) => {
                    console.log('😊 Emoji button clicked');
                    e.preventDefault();
                    toggleEmojiPicker();
                });
                console.log('✅ Emoji button listener attached');
            }

            // Send button
            const sendBtn = document.getElementById('send-btn');
            if (sendBtn) {
                sendBtn.addEventListener('click', (e) => {
                    console.log('📤 Send button clicked');
                    e.preventDefault();

                    // Check if send is allowed before sending
                    if (!sendBtn.disabled) {
                        sendChatMessage();
                    } else {
                        console.log('🚫 Send button is disabled');
                    }
                });
                console.log('✅ Send button listener attached');
            }

            // Chat input (Enter key)
            const chatInput = document.getElementById('chat-input');
            if (chatInput) {
                chatInput.addEventListener('keypress', (e) => {
                    if (e.key === 'Enter') {
                        console.log('⏎ Enter key pressed in chat input');
                        e.preventDefault();

                        // Check if input is disabled before sending
                        if (!chatInput.disabled) {
                            sendChatMessage();
                        } else {
                            console.log('🚫 Chat input is disabled');
                        }
                    }
                });
                console.log('✅ Chat input listener attached');
            }

            // Camera button - Take photo
            const cameraBtn = document.getElementById('camera-btn');
            if (cameraBtn) {
                cameraBtn.addEventListener('click', (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    const cameraInput = document.getElementById('camera-input');
                    if (cameraInput) {
                        cameraInput.click();
                    }
                });
            }

            // Camera input
            const cameraInput = document.getElementById('camera-input');
            if (cameraInput) {
                cameraInput.addEventListener('change', (e) => {
                    handleFileSelect(e);
                });
            }

            // File button (in chat input) - Available for all users
            const fileBtn = document.getElementById('file-btn');
            if (fileBtn) {
                fileBtn.addEventListener('click', (e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    const fileInput = document.getElementById('file-input');
                    if (fileInput) {
                        fileInput.click();
                    }
                });
            }

            // File input
            const fileInput = document.getElementById('file-input');
            if (fileInput) {
                fileInput.addEventListener('change', (e) => {
                    handleFileSelect(e);
                });
            }

            console.log('✅ All chat event listeners initialized');

            // Initialize send button state based on current call state and user role
            updateSendButtonState();
        }

        // Initialize chat
        window.addEventListener('load', () => {
            initializeEmojiPicker();
            initializeChatEventListeners();
            // Set initial send button state based on user role
            updateSendButtonState();
        });

        console.log('=== Enhanced Chime UI Initialized ===');
    </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xFFFFFFFF), // White background
      child: Stack(
        children: [
          // InAppWebView with full WebRTC support for video calls
          InAppWebView(
            key: webViewKey,
            initialData: InAppWebViewInitialData(
              data: _getEnhancedChimeHTML(),
              baseUrl: WebUri('https://medzenhealth.app'),
              mimeType: 'text/html',
              encoding: 'utf-8',
            ),
            initialSettings: _getWebViewSettings(),
            onWebViewCreated: _onWebViewCreated,
            onLoadStart: _onLoadStart,
            onLoadStop: _onLoadStop,
            onProgressChanged: _onProgressChanged,
            onConsoleMessage: _onConsoleMessage,
            onReceivedError: _onReceivedError,
            onPermissionRequest: _onPermissionRequest,
          ),

          // Loading indicator - show while WebView is initializing or loading
          if (_isLoading)
            Container(
              color: const Color(0xFFFFFFFF),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF25D366)),
                    SizedBox(height: 16),
                    Text(
                      'Connecting to meeting...',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),

          // Meeting header overlay (only show when chat is NOT visible)
          if (_sdkReady && _meetingId != null && !_showChat)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildMeetingHeader(),
            ),

          // Live caption overlay at the bottom
          if (_showCaptionOverlay && _currentCaption != null && !_showChat)
            Positioned(
              bottom: 100, // Above the control bar
              left: 16,
              right: 16,
              child: _buildCaptionOverlay(),
            ),

          // Transcription indicator (top-right corner)
          if (_sdkReady && !_showChat)
            Positioned(
              top: 50,
              right: 16,
              child: _buildTranscriptionIndicator(),
            ),
        ],
      ),
    );
  }

  /// Builds the live caption overlay widget
  Widget _buildCaptionOverlay() {
    return AnimatedOpacity(
      opacity: _currentCaption != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF25D366).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speaker name
            if (_currentSpeaker != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentSpeaker!,
                      style: const TextStyle(
                        color: Color(0xFF25D366),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            // Caption text
            Text(
              _currentCaption ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the transcription status indicator
  Widget _buildTranscriptionIndicator() {
    if (_isTranscriptionStarting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Starting...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_isTranscriptionEnabled) {
      return GestureDetector(
        onTap: _toggleCaptionOverlay,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF25D366).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing recording indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _showCaptionOverlay
                    ? Icons.closed_caption
                    : Icons.closed_caption_off,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      );
    }

    // Provider can manually start transcription if not auto-started
    if (widget.isProvider && !_isTranscriptionEnabled) {
      return GestureDetector(
        onTap: _startTranscription,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_off, color: Colors.white, size: 14),
              SizedBox(width: 6),
              Text(
                'Start Transcription',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMeetingHeader() {
    // Build consultation title with date and provider role
    // Format: "Consultation MM/YYYY Doctor [Name]"
    String callTitle;
    if (widget.providerName != null && widget.providerName!.isNotEmpty) {
      // Format appointment date as MM/YYYY
      String dateStr = '';
      if (widget.appointmentDate != null) {
        final month = widget.appointmentDate!.month.toString().padLeft(2, '0');
        final year = widget.appointmentDate!.year.toString();
        dateStr = '$month/$year ';
      }

      if (widget.providerRole != null && widget.providerRole!.isNotEmpty) {
        // Show: "Consultation 12/2025 Doctor Brave Ndam"
        callTitle =
            'Consultation $dateStr${widget.providerRole} ${widget.providerName}';
      } else {
        // Show: "Consultation 12/2025 with Brave Ndam"
        callTitle = 'Consultation ${dateStr}with ${widget.providerName}';
      }
    } else {
      // Fallback to meeting ID
      callTitle = 'Video Call: ${_meetingId?.substring(0, 12) ?? ""}...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Meeting title with provider role
          Expanded(
            child: Text(
              callTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Participant count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0073bb),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_participantCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
