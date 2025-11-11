// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// To call the cloud function make sure to import this dependency
import 'package:cloud_functions/cloud_functions.dart';
import 'package:permission_handler/permission_handler.dart';

import '/custom_code/widgets/pre_joining_dialog.dart';

// Method for generating secure video call tokens and proceeding to join
// Uses secure Firebase function with authentication and Supabase integration
Future joinRoom(
  BuildContext context,
  String sessionId,
  String providerId,
  String patientId,
  String appointmentId,
  bool isProvider,
  String? userName,
  String? profileImage,
) async {
  // Prepare input for secure token generation
  // No credentials passed from client - all handled server-side
  final input = <String, dynamic>{
    'sessionId': sessionId,
    'providerId': providerId,
    'patientId': patientId,
    'appointmentId': appointmentId,
  };

  try {
    // Call secure Firebase function with authentication
    final response = await FirebaseFunctions.instance
        .httpsCallable('generateVideoCallTokens')
        .call(input);

    // Parse response with multiple tokens and metadata
    final data = response.data as Map<String, dynamic>;
    final channelName = data['channelName'] as String;
    final providerToken = data['providerToken'] as String;
    final patientToken = data['patientToken'] as String;
    final conversationId = data['conversationId'] as String;
    final expiresAt = data['expiresAt'] as String;

    // Hardcoded App ID (safe to be in client code)
    const agoraAppId = '9a6e33f84cd542d9aba14374ae3326b7';

    // Use appropriate token based on user role
    final token = isProvider ? providerToken : patientToken;
    final roleLabel = isProvider ? 'Provider' : 'Patient';

    debugPrint('✅ Video call tokens generated successfully!');
    debugPrint('Channel: $channelName');
    debugPrint('Role: $roleLabel');
    debugPrint('Conversation ID: $conversationId');
    debugPrint('Token expires at: $expiresAt');

    await Future.delayed(
      const Duration(seconds: 1),
    );

    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => PreJoiningDialog(
          channelName: channelName,
          token: token,
          appId: agoraAppId,
          userName: userName ?? roleLabel,
          profileImage: profileImage ??
              'https://res.cloudinary.com/dcato1y8g/image/upload/v1747920945/1747920944488000_ld6xer.jpg',
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ Error generating video call tokens: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join video call: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
