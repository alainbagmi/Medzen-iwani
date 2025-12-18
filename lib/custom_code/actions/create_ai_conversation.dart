// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter/foundation.dart';

/// Creates a new AI conversation with the appropriate assistant based on user role.
///
/// Returns a Map with:
/// - 'success': true/false
/// - 'conversationId': UUID of created conversation (if successful)
/// - 'assistantType': Type of assistant assigned
/// - 'error': Error message (if failed)
Future<Map<String, dynamic>> createAIConversation(
  String userId, {
  String? conversationTitle,
  String? defaultLanguage,
}) async {
  // Validate userId
  if (userId.isEmpty) {
    return {'success': false, 'error': 'User ID is required'};
  }

  try {
    debugPrint('[createAIConversation] Starting for user: $userId');

    // Step 1: Detect user role by checking profile tables
    String assistantType = 'health'; // default for patients

    try {
      final providerResult = await SupaFlow.client
          .from('medical_provider_profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (providerResult != null) {
        assistantType = 'clinical';
      } else {
        final facilityResult = await SupaFlow.client
            .from('facility_admin_profiles')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();
        if (facilityResult != null) {
          assistantType = 'operations';
        }
      }
    } catch (e) {
      debugPrint('[createAIConversation] Role detection error: $e');
    }

    debugPrint('[createAIConversation] Detected role: $assistantType');

    // Step 2: Get assistant ID for this type
    String? assistantId;
    try {
      final assistantResult = await SupaFlow.client
          .from('ai_assistants')
          .select('id')
          .eq('assistant_type', assistantType)
          .maybeSingle();
      if (assistantResult != null) {
        assistantId = assistantResult['id'] as String?;
      }
    } catch (e) {
      debugPrint('[createAIConversation] Assistant lookup error: $e');
    }

    if (assistantId == null || assistantId.isEmpty) {
      return {
        'success': false,
        'error': 'No AI assistant configured for role: $assistantType',
      };
    }

    debugPrint('[createAIConversation] Using assistant: $assistantId');

    // Step 3: Create conversation
    final title = (conversationTitle != null && conversationTitle.isNotEmpty)
        ? conversationTitle
        : 'New Conversation';
    final language = (defaultLanguage != null && defaultLanguage.isNotEmpty)
        ? defaultLanguage
        : 'en';

    final result = await SupaFlow.client.from('ai_conversations').insert({
      'patient_id': userId,
      'user_id': userId,
      'assistant_id': assistantId,
      'conversation_title': title,
      'status': 'active',
      'default_language': language,
      'total_messages': 0,
      'total_tokens': 0,
      'is_active': true,
    }).select('id, created_at').single();

    final conversationId = result['id'] as String?;

    if (conversationId != null && conversationId.isNotEmpty) {
      debugPrint('[createAIConversation] Success: $conversationId');
      return {
        'success': true,
        'conversationId': conversationId,
        'assistantType': assistantType,
        'assistantId': assistantId,
      };
    }

    return {'success': false, 'error': 'Failed to create conversation'};
  } catch (e) {
    debugPrint('[createAIConversation] Error: $e');
    return {'success': false, 'error': e.toString()};
  }
}
