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

Future<dynamic> getClinicalNotes(
  String? appointmentId,
  String? sessionId,
  String? providerId,
  String? patientId,
  String? status,
) async {
  try {
    debugPrint('getClinicalNotes: Fetching notes with filters');

    // Start building the query
    var query = SupaFlow.client.from('clinical_notes').select('*');

    // Apply optional filters
    if (appointmentId != null && appointmentId.isNotEmpty) {
      query = query.eq('appointment_id', appointmentId);
      debugPrint('getClinicalNotes: Filtering by appointmentId=$appointmentId');
    }

    if (sessionId != null && sessionId.isNotEmpty) {
      query = query.eq('session_id', sessionId);
      debugPrint('getClinicalNotes: Filtering by sessionId=$sessionId');
    }

    if (providerId != null && providerId.isNotEmpty) {
      query = query.eq('provider_id', providerId);
      debugPrint('getClinicalNotes: Filtering by providerId=$providerId');
    }

    if (patientId != null && patientId.isNotEmpty) {
      query = query.eq('patient_id', patientId);
      debugPrint('getClinicalNotes: Filtering by patientId=$patientId');
    }

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
      debugPrint('getClinicalNotes: Filtering by status=$status');
    }

    // Apply ordering and limit
    final response =
        await query.order('created_at', ascending: false).limit(20);

    final notes = List<Map<String, dynamic>>.from(response);

    debugPrint('getClinicalNotes: Retrieved ${notes.length} notes');

    return {
      'success': true,
      'notes': notes,
      'count': notes.length,
    };
  } catch (e, stackTrace) {
    debugPrint('getClinicalNotes error: $e');
    debugPrint('Stack trace: $stackTrace');
    return {
      'success': false,
      'error': e.toString(),
      'notes': <Map<String, dynamic>>[],
      'count': 0,
    };
  }
}
