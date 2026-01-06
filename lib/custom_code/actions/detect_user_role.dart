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

/// Detects user role for AI assistant selection using optimized single
/// database query.
///
/// Returns one of: 'health' (patient), 'clinical' (provider), 'operations'
/// (facility admin), or 'platform' (system admin).
///
/// Performance: Single RPC call vs previous 4 sequential queries (4x faster).
Future<String> detectUserRole(String userId) async {
  try {
    // Use optimized database function for single-query role detection
    final result = await SupaFlow.client.rpc(
      'detect_user_role',
      params: {'p_user_id': userId},
    );

    // Result is the role string directly from the function
    if (result != null && result is String && result.isNotEmpty) {
      debugPrint('Detected role via RPC: $result for user: $userId');
      return result;
    }

    // Fallback to default if unexpected result
    debugPrint('RPC returned unexpected result: $result, defaulting to health');
    return 'health';
  } catch (e) {
    // Log error and fallback to legacy detection if RPC fails
    debugPrint('RPC detect_user_role failed: $e');
    return _detectUserRoleLegacy(userId);
  }
}

/// Legacy fallback: Sequential queries if RPC function not available.
/// This is kept for backwards compatibility during migration.
Future<String> _detectUserRoleLegacy(String userId) async {
  try {
    final providerResult = await SupaFlow.client
        .from('medical_provider_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (providerResult != null) return 'clinical';

    final facilityAdminResult = await SupaFlow.client
        .from('facility_admin_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (facilityAdminResult != null) return 'operations';

    try {
      final systemAdminResult = await SupaFlow.client
          .from('system_admin_profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (systemAdminResult != null) return 'platform';
    } catch (e) {
      debugPrint('System admin check skipped: $e');
    }

    return 'health';
  } catch (e) {
    debugPrint('Legacy role detection failed: $e');
    return 'health';
  }
}
