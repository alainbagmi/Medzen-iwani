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

/// Starts a video call with simplified parameters
///
/// This function only requires providerId and queries Supabase for complete appointment data.
/// Determines current user role and finds the matching appointment automatically.
///
/// Parameters:
/// - context: Build context for navigation
/// - providerId: The provider's user ID (required)
/// - providerName: Provider's display name
/// - providerImage: Provider's profile image URL
Future startVideoCallSimple(
  BuildContext context,
  String providerId,
  String? providerName,
  String? providerImage,
) async {
  // Get current user info from FFAppState
  final currentUserId = FFAppState().AuthuserID;
  final currentUserRole = FFAppState().UserRole;

  if (currentUserId.isEmpty || providerId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Missing user information. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  try {
    // Determine if current user is provider or patient
    bool isProvider = (currentUserRole == 'medical_provider' ||
                       currentUserRole == 'provider') &&
                      currentUserId == providerId;

    String patientId;
    String? patientName;
    String? patientImage;

    if (isProvider) {
      // Provider clicked button - need to get patient info from appointment
      // Query appointments where current user is the provider
      final appointmentResponse = await SupaFlow.client
          .from('appointments')
          .select('id, patient_id, appointment_date, appointment_time, status')
          .eq('provider_id', currentUserId)
          .eq('status', 'scheduled')
          .order('appointment_date', ascending: true)
          .order('appointment_time', ascending: true)
          .limit(1)
          .maybeSingle();

      if (appointmentResponse == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No scheduled appointment found.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      patientId = appointmentResponse['patient_id'] as String;

      // Get patient details
      final patientResponse = await SupaFlow.client
          .from('users')
          .select('display_name, profile_picture_url')
          .eq('id', patientId)
          .single();

      patientName = patientResponse['display_name'] as String?;
      patientImage = patientResponse['profile_picture_url'] as String?;
    } else {
      // Patient clicked button - current user is the patient
      patientId = currentUserId;

      // Get patient details (current user)
      final userResponse = await SupaFlow.client
          .from('users')
          .select('display_name, profile_picture_url')
          .eq('id', currentUserId)
          .single();

      patientName = userResponse['display_name'] as String?;
      patientImage = userResponse['profile_picture_url'] as String?;
    }

    // Query for appointment
    final appointmentQuery = isProvider
        ? SupaFlow.client
            .from('appointments')
            .select('id')
            .eq('provider_id', providerId)
            .eq('patient_id', patientId)
            .eq('status', 'scheduled')
            .order('appointment_date', ascending: true)
            .order('appointment_time', ascending: true)
            .limit(1)
            .maybeSingle()
        : SupaFlow.client
            .from('appointments')
            .select('id')
            .eq('patient_id', patientId)
            .eq('provider_id', providerId)
            .eq('status', 'scheduled')
            .order('appointment_date', ascending: true)
            .order('appointment_time', ascending: true)
            .limit(1)
            .maybeSingle();

    final appointmentResponse = await appointmentQuery;

    if (appointmentResponse == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No scheduled appointment found for video call.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final appointmentId = appointmentResponse['id'] as String;

    // Query for existing video call session
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
      final channelName =
          'appointment_${appointmentId}_${DateTime.now().millisecondsSinceEpoch}';

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

    // Get display names
    final userName = isProvider
        ? (providerName?.isNotEmpty ?? false ? providerName! : 'Provider')
        : (patientName?.isNotEmpty ?? false ? patientName! : 'Patient');

    final userImage = isProvider ? providerImage : patientImage;

    // Call joinRoom
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
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error starting video call. Please try again.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
    debugPrint('Error in startVideoCallSimple: $e');
  }
}
