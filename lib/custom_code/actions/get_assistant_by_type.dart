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

/// Gets the AI assistant UUID by assistant type.
///
/// Valid types: 'health' (patient), 'clinical' (provider), 'operations'
/// (facility admin), 'platform' (system admin).
///
/// Returns null if assistant not found or inactive.
Future<String?> getAssistantByType(String assistantType) async {
  try {
    // Use maybeSingle() instead of single() to avoid throwing on 0 rows
    // Also filter by is_active to only return active assistants
    final result = await SupaFlow.client
        .from('ai_assistants')
        .select('id')
        .eq('assistant_type', assistantType)
        .eq('is_active', true)
        .maybeSingle();

    if (result != null && result['id'] != null) {
      debugPrint('Found assistant for type $assistantType: ${result['id']}');
      return result['id'] as String;
    }

    debugPrint('No active assistant found for type: $assistantType');
    return null;
  } catch (e) {
    debugPrint('Error getting assistant by type: $e');
    return null;
  }
}
