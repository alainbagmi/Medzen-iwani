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

// Imports other custom actions
// Imports custom functions

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:convert' show jsonEncode, jsonDecode;
import 'dart:math' show min;
import 'dart:async' show TimeoutException;

// Import the Chime video call page (self-contained with embedded HTML/JS)
import '/custom_code/widgets/index.dart';

// Inline video call state tracking (to avoid FlutterFlow sync issues)
bool _isInVideoCall = false;

// Inline session timeout control - self-contained for FlutterFlow compatibility
// Note: ActivityDetector widget handles the actual timeout logic
void _pauseSessionTimeoutLocal() {
  debugPrint('SessionTimeout: Paused for video call');
}

void _resumeSessionTimeoutLocal() {
  debugPrint('SessionTimeout: Resumed after video call');
}

void _setVideoCallState(bool isActive) {
  _isInVideoCall = isActive;

  // Pause/resume session timeout during video calls
  if (isActive) {
    _pauseSessionTimeoutLocal();
  } else {
    _resumeSessionTimeoutLocal();
  }

  debugPrint(
      'VideoCallState: ${isActive ? "In call - timeout paused" : "Call ended - timeout resumed"}');
}

// Method for creating/joining Chime SDK video meetings
// FlutterFlow-compatible: All parameters are positional required (no nullable optional params)
Future joinRoom(
  BuildContext context,
  String sessionId,
  String providerId,
  String patientId,
  String appointmentId,
  bool isProvider,
  String userName,
  String profileImage,
  String providerName,
  String providerRole,
) async {
  // Handle empty strings as null internally for backward compatibility
  final effectiveUserName = userName.isEmpty ? null : userName;
  final effectiveProfileImage = profileImage.isEmpty ? null : profileImage;
  final effectiveProviderName = providerName.isEmpty ? null : providerName;
  final effectiveProviderRole = providerRole.isEmpty ? null : providerRole;

  // Show pre-joining dialog first (like Agora pattern)
  // This lets user explicitly enable mic/camera and handles permissions on-demand
  debugPrint('=== Showing Pre-Joining Dialog ===');

  bool? dialogResult;
  bool initialMicEnabled = false;
  bool initialCameraEnabled = false;

  if (context.mounted) {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Center(
        child: ChimePreJoiningDialog(
          providerName: effectiveProviderName ?? 'Provider',
          providerRole: effectiveProviderRole ?? 'Healthcare Provider',
          providerImage: effectiveProfileImage,
          onJoin: (bool isMicEnabled, bool isCameraEnabled) async {
            debugPrint('=== Pre-Joining Dialog: User clicked Join ===');
            debugPrint('Mic enabled: $isMicEnabled');
            debugPrint('Camera enabled: $isCameraEnabled');
            initialMicEnabled = isMicEnabled;
            initialCameraEnabled = isCameraEnabled;
            dialogResult = true;
            Navigator.of(dialogContext).pop();
          },
          onCancel: () {
            debugPrint('=== Pre-Joining Dialog: User cancelled ===');
            dialogResult = false;
            Navigator.of(dialogContext).pop();
          },
        ),
      ),
    );
  }

  // If user cancelled, exit
  if (dialogResult != true) {
    debugPrint('User cancelled pre-joining dialog');
    return;
  }

  debugPrint('=== Pre-Joining Complete ===');
  debugPrint('Mic enabled: $initialMicEnabled');
  debugPrint('Camera enabled: $initialCameraEnabled');
  debugPrint('=============================');

  try {
    // Show loading indicator with proper positioning
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Setting up video call...'),
          duration: const Duration(seconds: 60),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16.0),
        ),
      );
    }

    // Additional check for Android emulators
    // Even with permissions granted, emulators may not have virtual cameras configured
    // Guard against web platform where Platform.isAndroid is not available
    if (!kIsWeb && Platform.isAndroid) {
      // Show warning about emulator limitations
      // This helps users understand why video calls might fail even with permissions
      debugPrint(
          '⚠️ Running on Android - If using emulator, ensure virtual camera is enabled');
      debugPrint(
          '   AVD Manager → Edit Device → Show Advanced Settings → Camera: Webcam0');
    }

    // Determine action based on role:
    // - Providers can CREATE new meetings or JOIN existing ones
    // - Patients can only JOIN existing active meetings (using appointmentId)

    String action;
    String? meetingId;

    if (isProvider) {
      // Provider: Check if there's an existing active session
      final existingSessionQuery = await SupaFlow.client
          .from('video_call_sessions')
          .select('meeting_id, status')
          .eq('appointment_id', appointmentId)
          .eq('status', 'active')
          .maybeSingle();

      meetingId = existingSessionQuery?['meeting_id'];
      action = meetingId != null ? 'join' : 'create';

      debugPrint('=== Provider Call Control ===');
      debugPrint('Existing Meeting ID: $meetingId');
      debugPrint('Action: $action');
      debugPrint('============================');
    } else {
      // Patient: Always try to JOIN using appointmentId
      // The edge function will handle checking if the call is active
      action = 'join';

      debugPrint('=== Patient Call Control ===');
      debugPrint('Action: join (appointment-based)');
      debugPrint('Appointment ID: $appointmentId');
      debugPrint('============================');
    }

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
    debugPrint('User email: ${user.email}');
    debugPrint('Token length: ${userToken.length}');
    debugPrint(
        'Token first 50 chars: ${userToken.substring(0, min(50, userToken.length))}...');
    debugPrint('==================');

    debugPrint('=== Calling Chime Meeting Token Edge Function ===');
    debugPrint('Action: $action');
    debugPrint('Appointment ID: $appointmentId');
    debugPrint('User ID: $userId');
    debugPrint('Meeting ID: $meetingId');
    debugPrint('================================================');

    // Call Supabase Edge Function using direct HTTP request
    // We use direct HTTP instead of SupaFlow.client.functions.invoke() because:
    // 1. App uses Firebase Auth (no active Supabase session)
    // 2. Edge function verifies Firebase tokens internally
    // 3. We need to bypass Supabase JWT verification at platform level
    final supabaseUrl = FFDevEnvironmentValues().SupaBaseURL;
    final supabaseAnonKey = FFDevEnvironmentValues().Supabasekey;

    final uri = Uri.parse('$supabaseUrl/functions/v1/chime-meeting-token');

    debugPrint('Calling: $uri');
    debugPrint('With anon key: ${supabaseAnonKey.substring(0, 20)}...');

    // CRITICAL: Verify token is not empty before making request
    if (userToken.isEmpty) {
      throw Exception(
          'FATAL: Firebase token is empty! User: ${user.email}, UID: ${user.uid}');
    }

    // Prepare headers with explicit token verification
    // IMPORTANT: Use lowercase header name 'x-firebase-token' to match CORS config
    // Supabase Edge Runtime normalizes all headers to lowercase
    final requestHeaders = {
      'Content-Type': 'application/json',
      'apikey': supabaseAnonKey,
      'Authorization': 'Bearer $supabaseAnonKey',
      'x-firebase-token': userToken,
    };

    debugPrint('=== Request Headers Debug ===');
    debugPrint('Content-Type: ${requestHeaders['Content-Type']}');
    debugPrint('apikey: ${requestHeaders['apikey']?.substring(0, 20)}...');
    debugPrint('Authorization: Bearer ${supabaseAnonKey.substring(0, 20)}...');
    debugPrint(
        'x-firebase-token: ${requestHeaders['x-firebase-token']?.substring(0, 50)}...');
    debugPrint(
        'x-firebase-token length: ${requestHeaders['x-firebase-token']?.length}');
    debugPrint('==============================');

    // Build request body:
    // - For 'create': always use appointmentId
    // - For 'join': use appointmentId (edge function supports both meetingId and appointmentId)
    final requestBody = {
      'action': action,
      'appointmentId': appointmentId,
      // Only include meetingId if we have it (provider rejoining)
      if (meetingId != null) 'meetingId': meetingId,
    };

    // Retry logic for Supabase connection issues
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);
    dynamic response;
    Exception? lastException;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint(
            '=== Chime Edge Function Request (Attempt $attempt/$maxRetries) ===');
        response = await http
            .post(
              uri,
              headers: requestHeaders,
              body: jsonEncode(requestBody),
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw TimeoutException(
                  'Supabase edge function request timed out'),
            );
        debugPrint('✅ Response status: ${response.statusCode}');
        break; // Success, exit retry loop
      } catch (e) {
        // Safely wrap any error type as an Exception
        lastException = e is Exception ? e : Exception(e.toString());
        debugPrint('❌ Attempt $attempt failed: $e');

        if (attempt < maxRetries) {
          debugPrint('⏳ Waiting ${retryDelay.inSeconds}s before retry...');
          await Future.delayed(retryDelay);
        }
      }
    }

    // If all retries failed, throw the last exception
    if (response == null) {
      throw Exception(
          'Failed to connect to Chime service after $maxRetries attempts: $lastException');
    }

    // Use the response from the retry loop (not a duplicate HTTP call)
    final httpResponse = response;

    debugPrint('=== Edge Function Response ===');
    debugPrint('Status code: ${httpResponse.statusCode}');
    debugPrint('Response body: ${httpResponse.body}');
    debugPrint('==============================');

    // Parse response
    final responseData =
        httpResponse.statusCode < 400 ? jsonDecode(httpResponse.body) : null;

    final finalResponse = (
      status: httpResponse.statusCode,
      data: responseData ??
          (httpResponse.body.isNotEmpty ? jsonDecode(httpResponse.body) : null),
    );

    if (finalResponse.status >= 400) {
      debugPrint('❌ Edge function error - Status: ${finalResponse.status}');
      debugPrint('Error response: ${finalResponse.data}');

      final errorCode = finalResponse.data?['code'];
      final errorMsg = finalResponse.data?['error'] ??
          finalResponse.data?['message'] ??
          'Failed to $action meeting';

      // Handle "PATIENT_CANNOT_CREATE" error - patient tried to start a call
      if (errorCode == 'PATIENT_CANNOT_CREATE') {
        debugPrint('✅ Showing PATIENT_CANNOT_CREATE dialog');
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Please Wait',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.video_call_outlined,
                              size: 48, color: Colors.blue[700]),
                          const SizedBox(height: 16),
                          const Text(
                            'Only providers can start video calls.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Please wait for your healthcare provider to initiate the video consultation. You will receive a notification when the call is ready.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
        return; // Return without throwing to avoid error snackbar
      }

      // Handle "NO_ACTIVE_CALL" error with centered dialog for patients
      debugPrint(
          '🔍 Checking NO_ACTIVE_CALL: errorCode=$errorCode, isProvider=$isProvider');
      if (errorCode == 'NO_ACTIVE_CALL' && !isProvider) {
        debugPrint('✅ Showing NO_ACTIVE_CALL dialog for patient');
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.access_time,
                        color: Colors.orange[700], size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Waiting for Provider',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.video_call_outlined,
                              size: 48, color: Colors.orange[700]),
                          const SizedBox(height: 16),
                          const Text(
                            'The provider has not started the video call yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'You will receive a notification when the call is ready. Please wait for your provider to initiate the call.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
        return; // Return without throwing to avoid error snackbar
      }

      // Handle "MEETING_EXPIRED" error - call ended or session timed out
      if (errorCode == 'MEETING_EXPIRED') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.call_end, color: Colors.red[700], size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Call Ended',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.video_call_outlined,
                              size: 48, color: Colors.red[700]),
                          const SizedBox(height: 16),
                          const Text(
                            'This video call has ended or expired.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isProvider
                                ? 'Please start a new call to connect with your patient.'
                                : 'Please ask your provider to start a new call.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
        return; // Return without throwing to avoid error snackbar
      }

      throw Exception(errorMsg);
    }

    // Get response data
    final meetingResponse = finalResponse.data;
    if (meetingResponse == null) {
      throw Exception('Empty response from edge function');
    }

    // Validate required fields
    if (!meetingResponse.containsKey('meeting') ||
        !meetingResponse.containsKey('attendee')) {
      throw Exception('Missing meeting or attendee in response');
    }

    debugPrint('✓ Response validated successfully');
    debugPrint('✓ Response keys: ${meetingResponse.keys.toList()}');
    debugPrint('==============================');
    final meetingData = meetingResponse['meeting'];
    final attendeeData = meetingResponse['attendee'];
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

      debugPrint('🔍 Platform check passed - proceeding to video call');
      debugPrint(
          '🔍 About to navigate to ChimeMeetingEnhanced (production-ready)');
      debugPrint('🔍 context.mounted at line 280: ${context.mounted}');

      // Validate data before navigation
      debugPrint('🔍 Preparing to navigate to ChimeMeetingEnhanced');
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

        // Pause session timeout during video call
        _setVideoCallState(true);

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              debugPrint('🔍 MATERIALPAGEROUTE BUILDER: Executing');
              debugPrint(
                  '🔍 About to construct ChimeMeetingEnhanced widget (production-ready)');
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Video Call'),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                body: ChimeMeetingEnhanced(
                  // Full screen - let widget determine size
                  meetingData: jsonEncode(meetingData),
                  attendeeData: jsonEncode(attendeeData),
                  userName: effectiveUserName ?? 'User',
                  userProfileImage: effectiveProfileImage,
                  userRole: isProvider ? 'Doctor' : null,
                  providerName: effectiveProviderName,
                  providerRole:
                      effectiveProviderRole ?? (isProvider ? 'Doctor' : null),
                  appointmentId: appointmentId, // Enable real-time chat sync
                  isProvider:
                      isProvider, // Provider can end call, patient can only leave
                  // Pass initial mic/camera state from pre-joining dialog
                  initialMicEnabled: initialMicEnabled,
                  initialCameraEnabled: initialCameraEnabled,
                  onCallEnded: () async {
                    // Resume session timeout when call ends
                    _setVideoCallState(false);

                    // For providers, show the post-call clinical notes dialog
                    if (isProvider && context.mounted) {
                      // Pop the video call screen first
                      Navigator.of(context).pop();

                      // Fetch patient name for the dialog
                      String patientName = 'Patient';
                      try {
                        final patient = await SupaFlow.client
                            .from('users')
                            .select('first_name, last_name')
                            .eq('id', patientId)
                            .maybeSingle();
                        if (patient != null) {
                          patientName =
                              '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'
                                  .trim();
                          if (patientName.isEmpty) patientName = 'Patient';
                        }
                      } catch (e) {
                        debugPrint('Error fetching patient name: $e');
                      }

                      // Small delay to ensure navigation completes
                      await Future.delayed(const Duration(milliseconds: 300));

                      // Show post-call clinical notes dialog
                      if (context.mounted) {
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (dialogContext) => PostCallClinicalNotesDialog(
                            sessionId: sessionId,
                            appointmentId: appointmentId,
                            providerId: providerId,
                            patientId: patientId,
                            patientName: patientName,
                            onSaved: () {
                              debugPrint(
                                  '✅ Clinical note saved for session: $sessionId');
                            },
                            onDiscarded: () {
                              debugPrint(
                                  '⚠️ Clinical note discarded for session: $sessionId');
                            },
                          ),
                        );
                      }
                    } else if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              );
            },
          ),
        );
        debugPrint('🔍 RETURNED FROM NAVIGATOR.PUSH');
        debugPrint('🔍 Video call page was closed');

        // Ensure session timeout is resumed when returning from video call
        _setVideoCallState(false);
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
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16.0),
        ),
      );
    }
  }
}
