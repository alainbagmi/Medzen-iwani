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
import 'package:crypto/crypto.dart';

Future<dynamic> signClinicalNote(
  String? noteId,
  String? providerId,
  String? subjective,
  String? objective,
  String? assessment,
  String? plan,
) async {
  try {
    // Validate required parameters
    if (noteId == null || noteId.isEmpty) {
      return {'success': false, 'error': 'noteId is required'};
    }
    if (providerId == null || providerId.isEmpty) {
      return {'success': false, 'error': 'providerId is required'};
    }

    print('signClinicalNote: Signing note $noteId by provider $providerId');

    // Generate signature timestamp (ISO 8601 UTC)
    final timestamp = DateTime.now().toUtc().toIso8601String();

    // Generate cryptographic signature hash for audit trail
    final signatureData = '$noteId:$providerId:$timestamp';
    final signatureHash = sha256.convert(utf8.encode(signatureData)).toString();

    print('signClinicalNote: Generated signature hash');

    // Build update payload
    final Map<String, dynamic> updatePayload = {
      'status': 'signed',
      'signed_at': timestamp,
      'signed_by': providerId,
      'signature_hash': signatureHash,
      'updated_at': timestamp,
    };

    // Include any edited SOAP sections if provided
    if (subjective != null && subjective.isNotEmpty) {
      updatePayload['subjective'] = subjective;
    }
    if (objective != null && objective.isNotEmpty) {
      updatePayload['objective'] = objective;
    }
    if (assessment != null && assessment.isNotEmpty) {
      updatePayload['assessment'] = assessment;
    }
    if (plan != null && plan.isNotEmpty) {
      updatePayload['plan'] = plan;
    }

    // Update clinical note with signature
    final response = await SupaFlow.client
        .from('clinical_notes')
        .update(updatePayload)
        .eq('id', noteId)
        .eq('provider_id', providerId)
        .select()
        .maybeSingle();

    if (response == null) {
      return {
        'success': false,
        'error': 'Note not found or you do not have permission to sign it',
      };
    }

    print('signClinicalNote: Note signed successfully');

    // Queue for EHRbase/OpenEHR sync
    try {
      await SupaFlow.client.from('ehrbase_sync_queue').insert({
        'table_name': 'clinical_notes',
        'record_id': noteId,
        'record_type': 'clinical_note',
        'template_id': 'medzen.clinical.notes.v1',
        'sync_type': 'composition_create',
        'sync_status': 'pending',
        'data_snapshot': jsonEncode(response),
        'created_at': timestamp,
      });
      print('signClinicalNote: Queued for EHR sync');
    } catch (syncError) {
      print('signClinicalNote: Warning - Failed to queue EHR sync: $syncError');
    }

    return {
      'success': true,
      'note': response,
      'signatureHash': signatureHash,
      'signedAt': timestamp,
    };
  } catch (e, stackTrace) {
    print('signClinicalNote error: $e');
    print('Stack trace: $stackTrace');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}
