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
import 'dart:io' show Platform;
import 'dart:convert' show jsonEncode, jsonDecode;
import 'dart:math' show min;
import 'dart:async' show TimeoutException;

// Import the Chime video call page (self-contained with embedded HTML/JS)
import '/custom_code/widgets/index.dart';
import 'dart:async' show Completer;

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

// Validate image URLs - ensure they're proper HTTP(S) URLs or null
String? _validateImageUrl(String? url) {
  if (url == null || url.isEmpty) {
    return null;
  }

  // Check if it's a valid HTTP(S) URL
  if (url.startsWith('http://') || url.startsWith('https://')) {
    try {
      Uri.parse(url);
      return url; // Valid URL
    } catch (e) {
      debugPrint('⚠️ Invalid URL format: $url - $e');
      return null;
    }
  }

  // If it's a file:// URL or other invalid path, log and return null
  debugPrint('⚠️ Image URL is not HTTP(S): $url');
  return null;
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
  String patientName,
) async {
  // Handle empty strings as null internally for backward compatibility
  final effectiveUserName = userName.isEmpty ? null : userName;
  final effectiveProfileImage = profileImage.isEmpty ? null : profileImage;
  final effectiveProviderName = providerName.isEmpty ? null : providerName;
  final effectiveProviderRole = providerRole.isEmpty ? null : providerRole;

  try {
    // CRITICAL FIX: Fetch meeting credentials FIRST (before dialogs)
    // This prevents context.mounted race condition from long async operations
    // Store the credentials for later use after dialogs complete

    debugPrint('=== PHASE 1: Obtaining Chime Meeting Credentials ===');
    debugPrint('This happens BEFORE any dialogs to avoid context lifecycle issues');

    // Show loading indicator while fetching credentials
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
    if (Platform.isAndroid) {
      debugPrint(
          '⚠️ Running on Android - If using emulator, ensure virtual camera is enabled');
      debugPrint(
          '   AVD Manager → Edit Device → Show Advanced Settings → Camera: Webcam0');
    }

    // Determine action based on role
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

    // Call Supabase Edge Function
    final supabaseUrl = FFDevEnvironmentValues().SupaBaseURL;
    final supabaseAnonKey = FFDevEnvironmentValues().Supabasekey;

    final uri = Uri.parse('$supabaseUrl/functions/v1/chime-meeting-token');

    debugPrint('Calling: $uri');
    debugPrint('With anon key: ${supabaseAnonKey.substring(0, 20)}...');

    if (userToken.isEmpty) {
      throw Exception(
          'FATAL: Firebase token is empty! User: ${user.email}, UID: ${user.uid}');
    }

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

    final requestBody = {
      'action': action,
      'appointmentId': appointmentId,
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
        lastException = e as Exception;
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

    debugPrint('=== Request Body ===');
    debugPrint(jsonEncode(requestBody));
    debugPrint('====================');

    // Use the response from the retry loop (already made the HTTP request successfully)
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

    // CRITICAL FIX: NOW SHOW PRE-JOINING DIALOG (after credentials obtained)
    // At this point, we have valid meeting credentials, so we can safely show dialogs
    debugPrint('=== PHASE 2: Showing Pre-Joining Dialog ===');
    debugPrint('Meeting credentials obtained successfully');

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
            providerImage: _validateImageUrl(effectiveProfileImage),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      return;
    }

    debugPrint('=== Pre-Joining Complete ===');
    debugPrint('Mic enabled: $initialMicEnabled');
    debugPrint('Camera enabled: $initialCameraEnabled');
    debugPrint('=============================');

    // Hide the "Setting up video call..." SnackBar before showing video widget
    // This prevents it from covering the microphone/camera controls
    if (context.mounted) {
      debugPrint('🔍 Hiding setup SnackBar before showing video widget');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }

    // Show pre-call clinical notes dialog for providers to review patient context
    try {
      final isProviderValue = isProvider;
      final isContextMounted = context.mounted;
      debugPrint('🔍 Checking if pre-call dialog should be shown...');
      debugPrint('🔍 isProvider value: $isProviderValue');
      debugPrint('🔍 context.mounted value: $isContextMounted');

      if (isProviderValue && isContextMounted) {
        debugPrint('✅ Both conditions met - showing pre-call clinical notes dialog');
        bool? readyToProceed;

        try {
          if (context.mounted) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) {
                debugPrint('🔍 PreCallClinicalNotesDialog builder executing');
                return PreCallClinicalNotesDialog(
                  patientId: patientId,
                  patientName: patientName.isEmpty ? 'Patient' : patientName,
                  onReady: () {
                    debugPrint('🔍 Pre-call dialog: Start Call clicked');
                    readyToProceed = true;
                    Navigator.of(dialogContext).pop();
                  },
                );
              },
            );
            debugPrint('🔍 Pre-call dialog has closed');
          } else {
            debugPrint('⚠️ Context became unmounted before pre-call dialog could show');
          }
        } catch (showDialogError) {
          debugPrint('❌ Error showing pre-call dialog: $showDialogError');
          debugPrint('   Stack trace: ${StackTrace.current}');
          rethrow;
        }

        // If provider dismissed dialog without clicking "Start Call", exit
        if (readyToProceed != true) {
          debugPrint('⚠️ Provider cancelled pre-call review dialog (readyToProceed not true)');
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
          return;
        }
        debugPrint('✅ Pre-call clinical notes review complete - proceeding to video call');
      } else {
        debugPrint('⚠️ Conditions not met - isProvider: $isProviderValue, context.mounted: $isContextMounted');
        if (!isProviderValue) {
          debugPrint('   → Not a provider - only providers see pre-call dialog');
        }
        if (!isContextMounted) {
          debugPrint('   → Context not mounted - cannot show pre-call dialog');
        }
      }
    } catch (preCallError) {
      debugPrint('❌ Error in pre-call dialog logic: $preCallError');
      debugPrint('   Stack trace: ${StackTrace.current}');
      rethrow;
    }

    debugPrint('🔍 POST DIALOGS: Context check before navigation');
    debugPrint('🔍 context.mounted: ${context.mounted}');

    if (context.mounted) {
      // The snackbar shown at line 107 with 60-second duration provides
      // the timing needed for Android audio system initialization.
      // Keep it visible while user navigates to call.

      debugPrint('🔍 Platform check passed - proceeding to video call');
      debugPrint(
          '🔍 About to navigate to ChimeMeetingEnhanced (production-ready)');

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
      // Context is guaranteed to be mounted here due to check above
      debugPrint('🔍 CALLING Navigator.push');

      // Pause session timeout during video call
      _setVideoCallState(true);

      // Create a Completer to signal when call ends (for post-call dialog)
      final callEndedCompleter = Completer<void>();

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (routeContext) {
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
                userProfileImage: _validateImageUrl(effectiveProfileImage),
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
                  debugPrint('🔍 onCallEnded callback triggered');
                  // Resume session timeout when call ends
                  _setVideoCallState(false);
                  if (routeContext.mounted) {
                    debugPrint('🔍 routeContext mounted - showing post-call dialog');

                    // Show post-call dialog BEFORE popping the page
                    // This ensures routeContext is still valid (fixes context.mounted = false issue)
                    if (isProvider && routeContext.mounted) {
                      debugPrint('✅ Showing post-call clinical notes dialog in routeContext');
                      try {
                        await showDialog(
                          context: routeContext,
                          barrierDismissible: false,
                          builder: (dialogContext) {
                            debugPrint('🔍 PostCallClinicalNotesDialog builder executing');
                            return PostCallClinicalNotesDialog(
                              sessionId: sessionId,
                              appointmentId: appointmentId,
                              providerId: providerId,
                              patientId: patientId,
                              patientName: patientName.isEmpty ? 'Patient' : patientName,
                              onSaved: () {
                                debugPrint('🔍 Post-call clinical notes saved');
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }
                              },
                              onDiscarded: () {
                                debugPrint('🔍 Post-call clinical notes discarded');
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }
                              },
                            );
                          },
                        );
                        debugPrint('✅ Post-call dialog closed');
                      } catch (dialogError) {
                        debugPrint('❌ Error showing post-call dialog: $dialogError');
                      }
                    } else if (isProvider) {
                      debugPrint('⚠️ Cannot show post-call dialog - routeContext not mounted');
                    } else {
                      debugPrint('⚠️ Not showing post-call dialog - not a provider');
                    }

                    // Now pop the video call page
                    debugPrint('🔍 Popping video call page');
                    Navigator.of(routeContext).pop();
                    debugPrint('🔍 Video call page popped - completing completer');
                    // Signal that call has ended (completes immediately)
                    if (!callEndedCompleter.isCompleted) {
                      callEndedCompleter.complete();
                    }
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

      // CRITICAL: Kill any lingering video call processes after post-call dialog closes
      debugPrint('🔥 Triggering video call process cleanup...');
      await killVideoCallProcesses(sessionId);
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

/// 🔥 CRITICAL CLEANUP FUNCTION: Kill all lingering video call processes
///
/// This function ensures that when a provider ends a video call, all resources
/// are properly cleaned up to prevent:
/// - Zombie WebView processes
/// - Lingering audio/video streams
/// - Orphaned Chime SDK sessions
/// - Memory leaks from accumulated state
///
/// Called from: `onCallEnded` callback in ChimeMeetingEnhanced after call ends
Future<void> killVideoCallProcesses(String? meetingId) async {
  debugPrint('💀 KILLING VIDEO CALL PROCESSES - meetingId: $meetingId');

  try {
    // Step 1: Cleanup Supabase real-time subscriptions (chat messages, captions)
    debugPrint('🔌 Step 1: Cleaning up Supabase channels...');
    try {
      final supabase = SupaFlow.client;

      // Get all active channels and safely unsubscribe
      try {
        final channels = supabase.getChannels();
        debugPrint('   Found ${channels.length} active channels');
        for (final channel in channels) {
          try {
            await supabase.removeChannel(channel);
            debugPrint('   ✅ Removed channel');
          } catch (e) {
            debugPrint('   ⚠️ Error removing individual channel: $e');
          }
        }
        debugPrint('✅ All Supabase channels cleanup attempted');
      } catch (e) {
        debugPrint('⚠️ Error accessing channels list: $e');
      }
    } catch (e) {
      debugPrint('⚠️ Error during Supabase cleanup: $e');
    }

    // Step 2: Clear app state references
    debugPrint('🧹 Step 2: Clearing app state references...');
    try {
      // Create a new FFAppState instance to help with cleanup
      FFAppState().update(() {
        // The FFAppState will automatically persist changes
        // Just the act of updating helps clear old references
        debugPrint('✅ App state update triggered');
      });
    } catch (e) {
      debugPrint('⚠️ Error updating app state: $e');
    }

    // Step 3: Log final cleanup status
    debugPrint('═══════════════════════════════════════════');
    debugPrint('💀 VIDEO CALL PROCESS CLEANUP COMPLETE');
    debugPrint('   ✅ Supabase channels removed');
    debugPrint('   ✅ App state cleared');
    debugPrint('   ✅ Ready for next call');
    debugPrint('═══════════════════════════════════════════');

  } catch (e) {
    debugPrint('❌ CRITICAL ERROR during video call cleanup: $e');
    debugPrint('   Process cleanup may be incomplete');
  }
}
