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

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<dynamic> sendBedrockMessage(
  String conversationId,
  String userId,
  String message,
  List<dynamic>? conversationHistory,
  String? preferredLanguage,
) async {
  try {
    // Get Firebase ID token for authentication
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return {'success': false, 'error': 'User not authenticated'};
    }

    final idToken = await firebaseUser.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      return {'success': false, 'error': 'Failed to get auth token'};
    }

    List<Map<String, String>> history = [];
    if (conversationHistory != null) {
      for (var msg in conversationHistory) {
        history.add({
          'role': msg['role'] ?? 'user',
          'content': msg['content'] ?? '',
        });
      }
    }

    // Call Edge Function with Supabase anon key (Edge Function trusts userId from body)
    final supabaseUrl = FFDevEnvironmentValues().SupaBaseURL;
    final supabaseAnonKey = FFDevEnvironmentValues().Supabasekey;
    final response = await http.post(
      Uri.parse('$supabaseUrl/functions/v1/bedrock-ai-chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $supabaseAnonKey',
        'apikey': supabaseAnonKey,
        'x-firebase-token': idToken,
      },
      body: jsonEncode({
        'message': message,
        'conversationId': conversationId,
        'userId': userId,
        'conversationHistory': history,
        'preferredLanguage': preferredLanguage ?? 'en',
      }),
    );

    if (response.statusCode >= 400) {
      debugPrint('Bedrock AI error: ${response.statusCode} - ${response.body}');
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}'
      };
    }

    final data = jsonDecode(response.body);
    if (data == null) {
      return {'success': false, 'error': 'No data returned'};
    }

    if (data['success'] == true) {
      return {
        'success': true,
        'response': data['response'],
        'language': data['language'],
        'languageName': data['languageName'],
        'confidenceScore': data['confidenceScore'] ?? 0.95,
        'responseTime': data['responseTime'] ?? 0,
        'inputTokens': data['usage']?['inputTokens'] ?? 0,
        'outputTokens': data['usage']?['outputTokens'] ?? 0,
        'totalTokens': data['usage']?['totalTokens'] ?? 0,
        'userMessageId': data['messageIds']?['userMessageId'],
        'aiMessageId': data['messageIds']?['aiMessageId'],
      };
    }

    return {'success': false, 'error': data['error'] ?? 'Failed'};
  } catch (e) {
    debugPrint('Bedrock AI exception: $e');
    return {'success': false, 'error': e.toString()};
  }
}
