// Automatic FlutterFlow imports
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:cloud_functions/cloud_functions.dart';
import 'package:permission_handler/permission_handler.dart';
import '/custom_code/widgets/pre_joining_dialog.dart';

/// New joinRoom implementation for Agora video calls with session-based token generation
///
/// This function generates Agora RTC tokens via Firebase Cloud Function and launches video call UI.
/// Uses the new generateVideoCallTokens function with session management.
///
/// Parameters:
/// - context: Build context for navigation
/// - sessionId: UUID of the video_call_sessions record
/// - providerId: UUID of the medical provider
/// - patientId: UUID of the patient
/// - appointmentId: UUID of the appointment
/// - isProvider: Whether current user is the provider (true) or patient (false)
/// - userName: Display name of current user
/// - userImage: Profile image URL of current user
Future joinRoom(
  BuildContext context,
  String sessionId,
  String providerId,
  String patientId,
  String appointmentId,
  bool isProvider,
  String? userName,
  String? userImage,
) async {
  try {
    // Request camera and microphone permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    // Check if all permissions are granted
    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.microphone] != PermissionStatus.granted) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera and microphone permissions are required for video calls.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // Show loading indicator
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Call Firebase function to generate Agora tokens
    final input = <String, dynamic>{
      'sessionId': sessionId,
      'providerId': providerId,
      'patientId': patientId,
      'appointmentId': appointmentId,
    };

    final response = await FirebaseFunctions.instance
        .httpsCallable('generateVideoCallTokens')
        .call(input);

    // Dismiss loading indicator
    if (!context.mounted) return;
    Navigator.of(context).pop();

    final data = response.data as Map<String, dynamic>;

    if (data['success'] == true) {
      final channelName = data['channelName'] as String;
      final token = isProvider
          ? data['providerToken'] as String
          : data['patientToken'] as String;
      final conversationId = data['conversationId'] as String?;

      debugPrint('✅ Video call tokens generated successfully');
      debugPrint('Channel: $channelName');
      debugPrint('Conversation ID: $conversationId');

      // Small delay before showing dialog
      await Future.delayed(const Duration(milliseconds: 500));

      if (!context.mounted) return;

      // Show pre-joining dialog with video call controls
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PreJoiningDialog(
          channelName: channelName,
          token: token,
          appId: '', // Will be fetched from config in PreJoiningDialog
          userName: userName ?? (isProvider ? 'Provider' : 'Patient'),
          profileImage: userImage ?? '',
        ),
      );
    } else {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate video call tokens: ${data['message']}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  } catch (e) {
    // Dismiss loading indicator if shown
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error starting video call: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );

    debugPrint('❌ Error in joinRoom: $e');
  }
}
