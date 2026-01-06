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

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '/environment_values.dart';

/// Controls medical transcription for video calls using AWS Transcribe Medical.
///
/// [meetingId] - AWS Chime meeting ID (UUID format)
/// [sessionId] - Video call session ID from database
/// [action] - Either 'start' or 'stop'
/// [language] - Language code (default: 'en-US')
/// [specialty] - Medical specialty (default: 'PRIMARYCARE')
/// [enableSpeakerIdentification] - Enable speaker diarization (default: true)
///
/// Returns a map with:
/// - success: bool
/// - message: String
/// - config/stats: Additional details depending on action
Future<dynamic> controlMedicalTranscription(
  String meetingId,
  String sessionId,
  String action,
  String? language,
  String? specialty,
  bool? enableSpeakerIdentification,
) async {
  try {
    // Get Firebase token for authentication
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'success': false,
        'error': 'User not authenticated',
      };
    }

    final firebaseToken = await user.getIdToken(true);
    if (firebaseToken == null) {
      return {
        'success': false,
        'error': 'Failed to get authentication token',
      };
    }

    // Get Supabase configuration
    final supabaseUrl = FFDevEnvironmentValues().SupaBaseURL;
    final supabaseKey = FFDevEnvironmentValues().Supabasekey;

    // Prepare request body
    final requestBody = {
      'meetingId': meetingId,
      'sessionId': sessionId,
      'action': action,
      'language': language ?? 'en-US',
      'specialty': specialty ?? 'PRIMARYCARE',
      'enableSpeakerIdentification': enableSpeakerIdentification ?? true,
    };

    // Call the edge function
    final response = await http.post(
      Uri.parse('$supabaseUrl/functions/v1/start-medical-transcription'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'x-firebase-token': firebaseToken, // lowercase as per CLAUDE.md
      },
      body: jsonEncode(requestBody),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message':
            responseBody['message'] ?? 'Transcription $action successful',
        'config': responseBody['config'],
        'stats': responseBody['stats'],
      };
    } else if (response.statusCode == 429) {
      // Budget exceeded
      return {
        'success': false,
        'error': responseBody['error'] ?? 'Daily transcription budget exceeded',
        'details': responseBody['details'],
      };
    } else {
      return {
        'success': false,
        'error': responseBody['error'] ?? 'Failed to $action transcription',
        'statusCode': response.statusCode,
      };
    }
  } catch (e) {
    return {
      'success': false,
      'error': 'Exception: ${e.toString()}',
    };
  }
}
