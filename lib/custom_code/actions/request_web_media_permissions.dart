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

import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for web-specific implementation
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' if (dart.library.io) 'web_media_permissions_stub.dart' as html;

/// Result class for web media permission requests
class WebMediaPermissionResult {
  final bool granted;
  final String? errorMessage;
  final bool audioGranted;
  final bool videoGranted;

  const WebMediaPermissionResult({
    required this.granted,
    this.errorMessage,
    this.audioGranted = false,
    this.videoGranted = false,
  });

  factory WebMediaPermissionResult.success({
    bool audioGranted = true,
    bool videoGranted = true,
  }) {
    return WebMediaPermissionResult(
      granted: true,
      audioGranted: audioGranted,
      videoGranted: videoGranted,
    );
  }

  factory WebMediaPermissionResult.denied(String message) {
    return WebMediaPermissionResult(
      granted: false,
      errorMessage: message,
    );
  }
}

/// Request camera and microphone permissions on web platform.
///
/// This function triggers the browser's native permission prompt by calling
/// getUserMedia(). This is required for web video calls because:
/// 1. permission_handler doesn't reliably work on web
/// 2. Browser permissions can only be triggered from a user gesture
/// 3. The browser owns the permission prompt, not the app
///
/// IMPORTANT: This must be called from a user gesture (button click) to work.
/// The browser will block permission requests not triggered by user interaction.
///
/// Parameters:
/// - [audio]: Whether to request microphone permission
/// - [video]: Whether to request camera permission
///
/// Returns:
/// - [WebMediaPermissionResult] with granted status and any error message
///
/// Usage:
/// ```dart
/// // In your pre-join dialog's Join button handler:
/// if (kIsWeb) {
///   final result = await requestWebMediaPermissions(
///     audio: _micEnabled,
///     video: _cameraEnabled,
///   );
///   if (!result.granted) {
///     // Show error: result.errorMessage
///     return;
///   }
/// }
/// // Proceed with joining the call
/// ```
Future<WebMediaPermissionResult> requestWebMediaPermissions({
  required bool audio,
  required bool video,
}) async {
  // On non-web platforms, permissions are handled by permission_handler
  // Return success immediately - actual permission handling is done elsewhere
  if (!kIsWeb) {
    debugPrint('📱 Non-web platform: Using permission_handler for media permissions');
    return WebMediaPermissionResult.success(
      audioGranted: audio,
      videoGranted: video,
    );
  }

  debugPrint('🌐 Web platform: Requesting media permissions via getUserMedia()');
  debugPrint('   Audio requested: $audio');
  debugPrint('   Video requested: $video');

  // If neither is requested, consider it a success
  if (!audio && !video) {
    debugPrint('⚠️ No media permissions requested');
    return WebMediaPermissionResult.success(
      audioGranted: false,
      videoGranted: false,
    );
  }

  try {
    // Access the browser's mediaDevices API
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      debugPrint('❌ mediaDevices API not available');
      return WebMediaPermissionResult.denied(
        'Media devices not available. Please use a modern browser.',
      );
    }

    // Build constraints based on what permissions are needed
    final constraints = <String, dynamic>{};
    if (audio) constraints['audio'] = true;
    if (video) constraints['video'] = true;

    debugPrint('📹 Calling getUserMedia with constraints: $constraints');

    // This call triggers the browser's permission prompt
    // IMPORTANT: This must be called from a user gesture (button click)
    final stream = await mediaDevices.getUserMedia(constraints);

    debugPrint('✅ getUserMedia succeeded!');
    debugPrint('   Stream tracks: ${stream.getTracks().length}');

    // Check which permissions were actually granted
    bool audioGranted = false;
    bool videoGranted = false;

    for (final track in stream.getTracks()) {
      debugPrint('   Track: ${track.kind} - ${track.label}');
      if (track.kind == 'audio') audioGranted = true;
      if (track.kind == 'video') videoGranted = true;

      // Stop the track immediately - we only needed the permission prompt
      // The actual media streams will be created by the Chime SDK
      track.stop();
    }

    debugPrint('✅ Permissions granted - Audio: $audioGranted, Video: $videoGranted');

    return WebMediaPermissionResult.success(
      audioGranted: audioGranted,
      videoGranted: videoGranted,
    );
  } catch (e) {
    debugPrint('❌ getUserMedia failed: $e');

    // Parse the error to provide a user-friendly message
    String errorMessage;
    final errorString = e.toString().toLowerCase();

    if (errorString.contains('notallowederror') ||
        errorString.contains('permissiondeniederror') ||
        errorString.contains('permission denied')) {
      errorMessage =
          'Permission denied. Please allow camera and microphone access in your browser settings.';
    } else if (errorString.contains('notfounderror') ||
        errorString.contains('device not found')) {
      errorMessage =
          'No camera or microphone found. Please connect a device and try again.';
    } else if (errorString.contains('notreadableerror') ||
        errorString.contains('device in use')) {
      errorMessage =
          'Camera or microphone is in use by another application. Please close other apps and try again.';
    } else if (errorString.contains('overconstrained')) {
      errorMessage =
          'Could not access camera/microphone with the requested settings.';
    } else if (errorString.contains('securityerror') ||
        errorString.contains('not secure')) {
      errorMessage =
          'Media access requires a secure connection (HTTPS). Please use HTTPS.';
    } else {
      errorMessage = 'Failed to access camera/microphone: ${e.toString()}';
    }

    return WebMediaPermissionResult.denied(errorMessage);
  }
}

/// Check if the current context supports media permissions
/// This is useful for showing appropriate UI elements
Future<bool> isWebMediaSupported() async {
  if (!kIsWeb) return true; // Native platforms use permission_handler

  try {
    final mediaDevices = html.window.navigator.mediaDevices;
    return mediaDevices != null;
  } catch (e) {
    debugPrint('❌ Error checking media support: $e');
    return false;
  }
}
