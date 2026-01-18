/// Stub implementations for mobile-only packages when running on web platform
/// This file is only imported on web to satisfy the Dart compiler
library mobile_stubs;

// Stub for flutter_sound types
class FlutterSoundRecorder {
  Future<void> openRecorder() async {}
  Future<void> startRecorder({required String toFile, dynamic codec}) async {}
  Future<void> stopRecorder() async {}
  Future<void> closeRecorder() async {}
}

class Codec {
  static const dynamic aacADTS = null;
}

// Stub for path_provider
Future<dynamic> getTemporaryDirectory() async => null;

// Stub for permission_handler
class Permission {
  static const dynamic microphone = _PermissionProxy();
}

class _PermissionProxy {
  const _PermissionProxy();
  Future<dynamic> request() async => _PermissionStatus();
}

class _PermissionStatus {
  bool get isGranted => false;
}

// Stub for dart:io File
class File {
  File(String path) : _path = path;
  final String _path;
  bool existsSync() => false;
  Future<int> length() async => 0;
  Future<List<int>> readAsBytes() async => [];
  Future<void> delete() async {}
}
