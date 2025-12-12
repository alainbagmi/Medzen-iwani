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

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async' show TimeoutException;

// Import the Chime video call page (self-contained with embedded HTML/JS)
import '/custom_code/widgets/index.dart';

// Method for creating/joining Chime SDK video meetings
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
  try {
    // Show loading indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setting up video call...')),
      );
    }

    // Check current permission status first
    debugPrint('=== Permission Status Check START ===');

    final cameraStatus = await Permission.camera.status;
    debugPrint('✓ Camera status retrieved');

    final microphoneStatus = await Permission.microphone.status;
    debugPrint('✓ Microphone status retrieved');

    // Check each property individually with try-catch
    try {
      final camGranted = cameraStatus.isGranted;
      debugPrint('Camera isGranted: $camGranted');
    } catch (e) {
      debugPrint('ERROR checking camera isGranted: $e');
    }

    try {
      final micGranted = microphoneStatus.isGranted;
      debugPrint('Microphone isGranted: $micGranted');
    } catch (e) {
      debugPrint('ERROR checking microphone isGranted: $e');
    }

    try {
      final camDenied = cameraStatus.isPermanentlyDenied;
      debugPrint('Camera isPermanentlyDenied: $camDenied');
    } catch (e) {
      debugPrint('ERROR checking camera isPermanentlyDenied: $e');
    }

    try {
      final micDenied = microphoneStatus.isPermanentlyDenied;
      debugPrint('Microphone isPermanentlyDenied: $micDenied');
    } catch (e) {
      debugPrint('ERROR checking microphone isPermanentlyDenied: $e');
    }

    debugPrint('=== Permission Status Check END ===');

    // If permissions are permanently denied, direct user to settings
    if (cameraStatus.isPermanentlyDenied ||
        microphoneStatus.isPermanentlyDenied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
              'Camera and microphone access is required for video calls. '
              'Please enable these permissions in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (result == true) {
          await openAppSettings();
        }
      }
      return;
    }

    // Request permissions if not already granted
    PermissionStatus finalCameraStatus = cameraStatus;
    PermissionStatus finalMicrophoneStatus = microphoneStatus;

    if (!cameraStatus.isGranted) {
      debugPrint('Requesting camera permission...');
      finalCameraStatus = await Permission.camera.request();
      debugPrint(
          'Camera permission after request: ${finalCameraStatus.isGranted}');
    }
    if (!microphoneStatus.isGranted) {
      debugPrint('Requesting microphone permission...');
      finalMicrophoneStatus = await Permission.microphone.request();
      debugPrint(
          'Microphone permission after request: ${finalMicrophoneStatus.isGranted}');
    }

    if (!finalCameraStatus.isGranted || !finalMicrophoneStatus.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Check if we're in a state where permissions weren't granted but also not denied
        // This typically indicates iOS Simulator limitation
        final isSimulatorIssue = !finalCameraStatus.isGranted &&
            !finalCameraStatus.isDenied &&
            !finalMicrophoneStatus.isGranted &&
            !finalMicrophoneStatus.isDenied;

        final errorMessage = isSimulatorIssue
            ? '⚠️ Video calls require camera and microphone access.\n\n'
                'iOS Simulator has known issues with permission dialogs. '
                'Please test on a physical iPhone device for full video call functionality.'
            : '❌ Camera and microphone permissions are required for video calls. '
                'Please grant access in Settings to continue.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: isSimulatorIssue ? Colors.orange : Colors.red,
            duration: const Duration(seconds: 6),
            action: isSimulatorIssue
                ? null
                : SnackBarAction(
                    label: 'Settings',
                    textColor: Colors.white,
                    onPressed: () => openAppSettings(),
                  ),
          ),
        );
      }
      return;
    }

    // Check if meeting already exists for this session
    final existingSessionQuery = await SupaFlow.client
        .from('video_call_sessions')
        .select('meeting_id, status')
        .eq('appointment_id', appointmentId)
        .maybeSingle();

    String? meetingId = existingSessionQuery?['meeting_id'];
    final sessionStatus = existingSessionQuery?['status'];

    // Determine action: create new meeting or join existing
    final action =
        (meetingId == null || sessionStatus == 'ended') ? 'create' : 'join';

    debugPrint('=== Chime Meeting Action: $action ===');
    debugPrint('Appointment ID: $appointmentId');
    debugPrint('Existing Meeting ID: $meetingId');
    debugPrint('Role: ${isProvider ? 'Provider' : 'Patient'}');

    // Get current user's Firebase JWT token
    // The app uses Firebase Auth, not Supabase Auth
    // IMPORTANT: Force-refresh the token to ensure it's valid and up-to-date
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final userId = user.uid;

    // Force get fresh token (not cached)
    debugPrint('=== Getting Fresh JWT Token ===');
    final userToken = await user.getIdToken(true); // true = force refresh

    if (userToken == null || userToken.isEmpty) {
      throw Exception('Failed to get authentication token');
    }

    debugPrint('=== Token Debug ===');
    debugPrint('User ID: $userId');
    debugPrint('Token length: ${userToken.length}');
    debugPrint(
        'Token first 50 chars: ${userToken.substring(0, min(50, userToken.length))}...');
    debugPrint('==================');

    // Get Supabase URL from environment
    final supabaseUrl = FFDevEnvironmentValues().SupaBaseURL;
    final functionUrl = '$supabaseUrl/functions/v1/chime-meeting-token';

    // Make direct HTTP POST request with user's JWT token
    // IMPORTANT: Use X-Firebase-Token header because Supabase Edge Functions
    // automatically validate Authorization header expecting Supabase JWT
    final response = await http
        .post(
      Uri.parse(functionUrl),
      headers: {
        'X-Firebase-Token': userToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'action': action,
        'appointmentId': appointmentId,
        if (meetingId != null) 'meetingId': meetingId,
      }),
    )
        .timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException(
            'Edge function call timed out after 30 seconds. Check backend connectivity.');
      },
    );

    debugPrint('=== Edge Function Response ===');
    debugPrint('Status code: ${response.statusCode}');
    debugPrint('Response headers: ${response.headers}');
    debugPrint('Response body length: ${response.body.length}');

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to $action meeting');
    }

    // Validate response is not empty
    if (response.body.isEmpty) {
      throw Exception('Empty response from edge function');
    }

    // Enhanced JSON parsing with error handling
    late Map<String, dynamic> responseData;
    try {
      responseData = jsonDecode(response.body);
      debugPrint('✓ JSON parsed successfully');
      debugPrint('✓ Response keys: ${responseData.keys.toList()}');

      // Validate required fields
      if (!responseData.containsKey('meeting') ||
          !responseData.containsKey('attendee')) {
        throw Exception('Missing meeting or attendee in response');
      }
    } catch (e) {
      debugPrint('❌ JSON parse error: $e');
      debugPrint('Raw response: ${response.body}');
      throw Exception('Invalid JSON response: $e');
    }
    debugPrint('==============================');
    final meetingData = responseData['meeting'];
    final attendeeData = responseData['attendee'];
    meetingId = meetingData['MeetingId'];

    debugPrint('=== Chime Meeting Created/Joined ===');
    debugPrint('Meeting ID: $meetingId');
    debugPrint('Attendee ID: ${attendeeData['AttendeeId']}');
    debugPrint('===================================');

    debugPrint('🔍 POST EDGE-FUNCTION: Starting navigation flow');
    debugPrint('🔍 context.mounted at line 248: ${context.mounted}');
    if (!context.mounted) {
      debugPrint('❌ FAILURE: context.mounted is FALSE at line 248');
      return;
    }

    if (context.mounted) {
      // Dismiss loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Connecting to video call...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('🔍 POST DELAY: Checking platform');
      debugPrint('🔍 kIsWeb value: $kIsWeb');
      if (kIsWeb) {
        debugPrint('⚠️ WEB PLATFORM DETECTED: Will show error and return');
      }

      // Platform check: Video calling not supported on web
      if (kIsWeb) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '❌ Video calling is currently only available on mobile devices'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      debugPrint('🔍 PASSED WEB CHECK: Platform is mobile');
      debugPrint('🔍 About to navigate to ChimeMeetingWebview');
      debugPrint('🔍 context.mounted at line 280: ${context.mounted}');

      // Validate data before navigation
      debugPrint('🔍 Preparing to navigate to ChimeMeetingWebview');
      debugPrint('🔍 meetingData keys: ${meetingData.keys.toList()}');
      debugPrint('🔍 attendeeData keys: ${attendeeData.keys.toList()}');

      // Validate critical fields
      if (!meetingData.containsKey('MeetingId')) {
        throw Exception('Missing MeetingId in meeting data');
      }
      if (!attendeeData.containsKey('AttendeeId')) {
        throw Exception('Missing AttendeeId in attendee data');
      }

      debugPrint('✓ Data validation passed');
      debugPrint('✓ MeetingId: ${meetingData['MeetingId']}');
      debugPrint('✓ AttendeeId: ${attendeeData['AttendeeId']}');
      debugPrint('🔍 meetingData length: ${jsonEncode(meetingData).length}');
      debugPrint('🔍 attendeeData length: ${jsonEncode(attendeeData).length}');

      // Navigate to Chime video call page
      if (context.mounted) {
        debugPrint('🔍 CALLING Navigator.push');
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              debugPrint('🔍 MATERIALPAGEROUTE BUILDER: Executing');
              debugPrint('🔍 About to construct ChimeMeetingWebview widget');
              return ChimeMeetingWebview(
                width: 400,
                height: 600,
                meetingData: jsonEncode(meetingData),
                attendeeData: jsonEncode(attendeeData),
                userName: userName ?? 'User',
                onCallEnded: () async {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              );
            },
          ),
        );
        debugPrint('🔍 RETURNED FROM NAVIGATOR.PUSH');
        debugPrint('🔍 Video call page was closed');
      }
    }
  } catch (e) {
    debugPrint('Error setting up video call: $e');

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show user-friendly error message
      String errorMessage = 'Failed to start video call';
      if (e.toString().contains('401') ||
          e.toString().contains('unauthenticated')) {
        errorMessage = 'Please log in to start a video call';
      } else if (e.toString().contains('404') ||
          e.toString().contains('not found')) {
        errorMessage = 'Video call session not found';
      } else if (e.toString().contains('403') ||
          e.toString().contains('not authorized')) {
        errorMessage = 'You are not authorized for this call';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
