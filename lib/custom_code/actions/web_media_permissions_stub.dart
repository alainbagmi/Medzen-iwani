// Stub file for non-web platforms (mobile/desktop)
// This file is imported when dart:html is not available
// The actual implementation is in request_web_media_permissions.dart

/// Stub export for linter compatibility (not used at runtime)
/// The actual implementation uses conditional imports
void webMediaPermissionsStub() {
  // This is a no-op stub for linter compatibility
  // Real implementation is in request_web_media_permissions.dart
}

// Stub classes for html types
class _MediaDevices {
  Future<dynamic> getUserMedia(dynamic constraints) async => null;
}

class _Navigator {
  _MediaDevices? get mediaDevices => _MediaDevices();
}

class _Window {
  _Navigator get navigator => _Navigator();
}

final window = _Window();

/// Stub implementation for non-web platforms
/// Returns true immediately since permission_handler handles mobile permissions
Future<bool> requestWebMediaPermissionsImpl({
  required bool audio,
  required bool video,
}) async {
  // On non-web platforms, we use permission_handler instead
  // This stub always returns true - actual permission handling
  // is done via permission_handler in the pre-join dialog
  return true;
}

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
