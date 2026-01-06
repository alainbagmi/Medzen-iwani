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
import 'package:uuid/uuid.dart';

/// Role-specific introduction messages for AI assistants
String _getIntroductionMessage(String assistantType) {
  switch (assistantType) {
    case 'health':
      return '''I am MedX, an AI health assistant and not a substitute for a medical professional. Always verify information or advice with a licensed healthcare provider before taking action.

I can help you with understanding health conditions, wellness guidance, medication information, and preparing questions for your doctor.

How can I assist you with your health today?''';

    case 'clinical':
      return '''I am MedX Clinical Specialist, your AI partner trained in African and Central African medicine, tropical diseases, and resource-adaptive healthcare.

Ready to assist with diagnosis, treatment protocols, drug interactions, and patient management. How can I help?''';

    case 'operations':
      return '''I am MedX Operations, an AI assistant designed to help facility administrators optimize healthcare operations.

I can assist with staff management, resource allocation, compliance monitoring, quality improvement, financial operations, and operational analytics.

What operational challenge can I help you with today?''';

    case 'platform':
      return '''I am MedX Platform Assistant, your AI system administration advisor for the MedZen platform.

I can help with system analytics, user management, security compliance, database operations, integration support, and platform configuration.

What system administration task can I assist you with?''';

    default:
      return '''I am MedX Assistant, ready to help you.

How can I assist you today?''';
  }
}

Future<String?> createAIConversation(String userId) async {
  try {
    // Step 1: Detect user role to determine which assistant to use
    final assistantType = await detectUserRole(userId);
    debugPrint('Detected user role/assistant type: $assistantType');

    // Step 2: Get the assistant ID for this role
    String? finalAssistantId = await getAssistantByType(assistantType);

    // Fallback to health assistant if not found
    if (finalAssistantId == null) {
      debugPrint(
          'No assistant found for type: $assistantType, using health fallback');
      finalAssistantId = await getAssistantByType('health');
    }

    if (finalAssistantId == null) {
      debugPrint('Failed to get any assistant ID');
      return null;
    }

    // Step 3: Get assistant details for model version
    String? modelVersion;
    String? assistantName;
    try {
      final assistantData = await SupaFlow.client
          .from('ai_assistants')
          .select('model_version, assistant_name')
          .eq('id', finalAssistantId)
          .single();

      modelVersion = assistantData['model_version'] as String?;
      assistantName = assistantData['assistant_name'] as String?;
      debugPrint('Using assistant: $assistantName with model: $modelVersion');
    } catch (e) {
      debugPrint('Could not fetch assistant details: $e');
    }

    // Step 4: Generate a new UUID for the conversation
    final conversationId = const Uuid().v4();

    // Step 5: Create the conversation record
    // sender_id = user (human), receiver_id = AI assistant
    final Map<String, dynamic> conversationData = {
      'id': conversationId,
      'user_id': userId,
      'assistant_id': finalAssistantId,
      'sender_id': userId,
      'receiver_id': finalAssistantId,
      'conversation_title': 'New Conversation',
      'model_version': modelVersion ?? 'eu.amazon.nova-pro-v1:0',
      'is_active': true,
      'status': 'active',
      'total_messages': 1,
      'total_tokens': 0,
      'default_language': 'en',
    };

    // Set patient_id for patient role users
    if (assistantType == 'health') {
      conversationData['patient_id'] = userId;
      debugPrint('Setting patient_id for patient role user');
    }

    await SupaFlow.client.from('ai_conversations').insert(conversationData);

    // Step 6: Insert the role-specific introduction message
    final introMessageId = const Uuid().v4();
    final introMessage = _getIntroductionMessage(assistantType);

    try {
      await SupaFlow.client.from('ai_messages').insert({
        'id': introMessageId,
        'conversation_id': conversationId,
        'role': 'assistant',
        'content': introMessage,
        'sender_id': 'assistant',
        'receiver_id': userId,
        'sender_name': assistantName ?? 'MedX AI',
        'receiver_name': 'User',
        'language_code': 'en',
        'model_used': modelVersion ?? 'system',
        'input_tokens': 0,
        'output_tokens': 0,
        'total_tokens': 0,
        'response_time_ms': 0,
        'metadata': {
          'type': 'introduction',
          'assistant_type': assistantType,
        },
      });
      debugPrint('Inserted introduction message for $assistantType role');
    } catch (e) {
      debugPrint('Warning: Could not insert intro message: $e');
      // Don't fail the conversation creation if intro fails
    }

    debugPrint('Created AI conversation: $conversationId');
    return conversationId;
  } catch (e, stackTrace) {
    debugPrint('Error creating AI conversation: $e');
    debugPrint('Stack trace: $stackTrace');
    return null;
  }
}
