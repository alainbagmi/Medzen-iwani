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

import 'join_room.dart';

/// Starts a video call from an appointment
///
/// This function handles the flow of initiating a video call from an appointment:
/// 1. Validates the appointment data
/// 2. Determines if user is provider or patient
/// 3. Calls joinRoom() which creates/retrieves session via Firebase function
///
/// Parameters:
/// - context: Build context for navigation
/// - appointmentId: The appointment ID
/// - providerId: The provider's user ID
/// - patientId: The patient's user ID
/// - providerName: Provider's display name
/// - patientName: Patient's display name
/// - providerImage: Provider's profile image URL
/// - patientImage: Patient's profile image URL
/// - currentUserId: The current user's ID
/// - currentUserRole: The current user's role (patient or medical_provider)
Future startVideoCallFromAppointment(
  BuildContext context,
  String appointmentId,
  String providerId,
  String patientId,
  String providerName,
  String patientName,
  String? providerImage,
  String? patientImage,
  String currentUserId,
  String currentUserRole,
) async {
  // Validate inputs
  if (appointmentId.isEmpty || providerId.isEmpty || patientId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invalid appointment data. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Determine if current user is provider or patient
  bool isProvider = (currentUserRole == 'medical_provider' || currentUserRole == 'provider') &&
                    currentUserId == providerId;

  // Get user name and image based on role
  String userName;
  String? userImage;

  if (isProvider) {
    userName = providerName.isNotEmpty ? providerName : 'Provider';
    userImage = providerImage;
  } else {
    userName = patientName.isNotEmpty ? patientName : 'Patient';
    userImage = patientImage;
  }

  // Query for existing video call session for this appointment
  try {
    final sessionsResponse = await SupaFlow.client
        .from('video_call_sessions')
        .select('id, channel_name, status')
        .eq('appointment_id', appointmentId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    String sessionId;

    // If no session exists, create one
    if (sessionsResponse == null) {
      // Generate unique channel name
      final channelName = 'appointment_${appointmentId}_${DateTime.now().millisecondsSinceEpoch}';

      // Create new video call session
      final createResponse = await SupaFlow.client
          .from('video_call_sessions')
          .insert({
            'appointment_id': appointmentId,
            'channel_name': channelName,
            'provider_id': providerId,
            'patient_id': patientId,
            'initiator_id': currentUserId,
            'call_type': 'video',
            'status': 'scheduled',
            'participants': [providerId, patientId],
          })
          .select('id')
          .single();

      sessionId = createResponse['id'] as String;
    } else {
      sessionId = sessionsResponse['id'] as String;
    }

    // Verify context is still mounted before navigation
    if (!context.mounted) return;

    // Call joinRoom - it will handle token generation via Firebase function
    await joinRoom(
      context,
      sessionId,
      providerId,
      patientId,
      appointmentId,
      isProvider,
      userName,
      userImage ?? '',
    );
  } catch (e) {
    // Verify context is still mounted before showing snackbar
    if (!context.mounted) return;

    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error starting video call. Please try again.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
    debugPrint('Error in startVideoCallFromAppointment: $e');
  }
}
