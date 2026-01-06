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

import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Import web media permissions helper for proper browser permission handling
import '/custom_code/actions/request_web_media_permissions.dart';

/// Pre-joining dialog for video calls Allows user to configure mic/camera
/// before joining Matches the Agora pattern for permission handling
class ChimePreJoiningDialog extends StatefulWidget {
  const ChimePreJoiningDialog({
    super.key,
    required this.providerName,
    required this.providerRole,
    this.providerImage,
    required this.onJoin,
    required this.onCancel,
  });

  final String providerName;
  final String providerRole;
  final String? providerImage;
  final Function(bool isMicEnabled, bool isCameraEnabled) onJoin;
  final VoidCallback onCancel;

  @override
  State<ChimePreJoiningDialog> createState() => _ChimePreJoiningDialogState();
}

class _ChimePreJoiningDialogState extends State<ChimePreJoiningDialog> {
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  bool _isCheckingPermissions = false;
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    if (kIsWeb) return; // Web handles permissions differently

    setState(() => _isCheckingPermissions = true);

    try {
      final micStatus = await Permission.microphone.status;
      final cameraStatus = await Permission.camera.status;

      setState(() {
        _micEnabled = micStatus.isGranted;
        _cameraEnabled = cameraStatus.isGranted;
        _isCheckingPermissions = false;
      });
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      setState(() => _isCheckingPermissions = false);
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
      _permissionError = null;
    });

    // Handle web platform separately using getUserMedia
    if (kIsWeb) {
      debugPrint('🌐 Web platform: Requesting permissions via getUserMedia');
      try {
        // Request web media permissions using our helper
        // This triggers the browser's permission prompt
        final result = await requestWebMediaPermissions(
          audio: _micEnabled,
          video: _cameraEnabled,
        );

        if (!mounted) return;

        if (result.granted) {
          debugPrint('✅ Web permissions granted');
          setState(() => _isCheckingPermissions = false);

          // Update mic/camera state based on what was actually granted
          if (_micEnabled && !result.audioGranted) {
            setState(() {
              _micEnabled = false;
              _permissionError = 'Microphone permission not available';
            });
          }
          if (_cameraEnabled && !result.videoGranted) {
            setState(() {
              _cameraEnabled = false;
              _permissionError = _permissionError != null
                  ? '$_permissionError. Camera permission not available'
                  : 'Camera permission not available';
            });
          }

          // Proceed if at least one permission was granted
          if (result.audioGranted || result.videoGranted) {
            widget.onJoin(_micEnabled, _cameraEnabled);
          } else {
            // Show error if nothing was granted
            _showWebPermissionErrorDialog(result.errorMessage);
          }
        } else {
          debugPrint('❌ Web permissions denied: ${result.errorMessage}');
          setState(() {
            _isCheckingPermissions = false;
            _permissionError = result.errorMessage;
          });
          _showWebPermissionErrorDialog(result.errorMessage);
        }
      } catch (e) {
        debugPrint('❌ Error requesting web permissions: $e');
        setState(() {
          _isCheckingPermissions = false;
          _permissionError = 'Failed to access camera/microphone';
        });
        _showWebPermissionErrorDialog(
          'Failed to access camera/microphone. Please check your browser settings.',
        );
      }
      return;
    }

    // Handle native platforms (iOS/Android) using permission_handler
    try {
      // Request microphone permission if mic is enabled
      if (_micEnabled) {
        final micStatus = await Permission.microphone.request();
        if (!micStatus.isGranted) {
          setState(() {
            _permissionError = 'Microphone permission denied';
            _micEnabled = false;
          });
        }
      }

      // Request camera permission if camera is enabled
      if (_cameraEnabled) {
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          setState(() {
            _permissionError = _permissionError != null
                ? '$_permissionError. Camera permission denied'
                : 'Camera permission denied';
            _cameraEnabled = false;
          });
        }
      }

      setState(() => _isCheckingPermissions = false);

      // Proceed if at least mic is available (video is optional)
      if (_micEnabled || _cameraEnabled) {
        widget.onJoin(_micEnabled, _cameraEnabled);
      } else if (_permissionError != null) {
        // Show settings dialog if both denied
        _showPermissionSettingsDialog();
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      setState(() {
        _isCheckingPermissions = false;
        _permissionError = 'Failed to request permissions';
      });
    }
  }

  /// Show web-specific permission error dialog with helpful instructions
  void _showWebPermissionErrorDialog(String? errorMessage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.videocam_off, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Permission Required',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMessage ?? 'Camera and microphone access is required for video calls.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to enable permissions:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Click the lock/info icon in your browser\'s address bar\n'
                    '2. Find Camera and Microphone settings\n'
                    '3. Set both to "Allow"\n'
                    '4. Refresh the page and try again',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPermissionSettingsDialog() {
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
            child: const Text('Cancel'),
          ),
          TextButton(
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Provider info header
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: widget.providerImage != null &&
                          widget.providerImage!.startsWith('http')
                      ? NetworkImage(widget.providerImage!)
                      : null,
                  child: widget.providerImage == null ||
                          !widget.providerImage!.startsWith('http')
                      ? Icon(Icons.person,
                          size: 28, color: Colors.blue.shade700)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.providerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.providerRole,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ready to join text
            Text(
              'Ready to join the video call?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),

            // Mic toggle
            _buildToggleRow(
              icon: _micEnabled ? Icons.mic : Icons.mic_off,
              label: 'Microphone',
              value: _micEnabled,
              onChanged: (value) => setState(() => _micEnabled = value),
              activeColor: Colors.blue,
            ),
            const SizedBox(height: 12),

            // Camera toggle
            _buildToggleRow(
              icon: _cameraEnabled ? Icons.videocam : Icons.videocam_off,
              label: 'Camera',
              value: _cameraEnabled,
              onChanged: (value) => setState(() => _cameraEnabled = value),
              activeColor: Colors.blue,
            ),

            // Permission error message
            if (_permissionError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _permissionError!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isCheckingPermissions ? null : _requestPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isCheckingPermissions
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Join Call'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? activeColor : Colors.grey.shade500,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }
}
