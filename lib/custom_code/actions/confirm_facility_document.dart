import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/backend/backend.dart';

/// Confirms a facility document after user review
///
/// Updates document status from 'preview' to 'confirmed' in database
/// Optionally saves PDF locally
///
/// Returns: {
///   'success': bool,
///   'error': String? (if failed),
///   'message': String,
/// }

Future<Map<String, dynamic>> confirmFacilityDocument(
  String documentId, {
  String? confirmationNotes,
}) async {
  try {
    // 1. Validate inputs
    if (documentId.isEmpty) {
      return {
        'success': false,
        'error': 'Missing document ID',
      };
    }

    // 2. Get Firebase token
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'success': false,
        'error': 'User not authenticated',
      };
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      return {
        'success': false,
        'error': 'Failed to get authentication token',
      };
    }

    if (kDebugMode) {
      print('[confirmFacilityDocument] Confirming document: $documentId');
    }

    // 3. Get Supabase client
    final supabaseClient = Supabase.instance.client;

    // 4. Update document status to 'confirmed'
    final response = await supabaseClient
        .from('facility_generated_documents')
        .update({
          'status': 'confirmed',
          'confirmed_by': user.uid,
          'confirmed_at': DateTime.now().toIso8601String(),
          if (confirmationNotes != null) 'confirmation_notes': confirmationNotes,
        })
        .eq('id', documentId)
        .then((_) => {'success': true, 'message': 'Document confirmed successfully'})
        .catchError((error) => {
              'success': false,
              'error': error.toString(),
            });

    if (kDebugMode) {
      print('[confirmFacilityDocument] Update result: $response');
    }

    return response;

  } catch (e) {
    if (kDebugMode) {
      print('[confirmFacilityDocument] Exception: $e');
    }
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

/// Saves a generated facility document (updates status from preview to saved)
///
/// Returns: {
///   'success': bool,
///   'error': String? (if failed),
///   'message': String,
/// }

Future<Map<String, dynamic>> saveFacilityDocumentDraft(
  String documentId, {
  String? notes,
}) async {
  try {
    // 1. Validate inputs
    if (documentId.isEmpty) {
      return {
        'success': false,
        'error': 'Missing document ID',
      };
    }

    // 2. Get Firebase token
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'success': false,
        'error': 'User not authenticated',
      };
    }

    if (kDebugMode) {
      print('[saveFacilityDocumentDraft] Saving draft: $documentId');
    }

    // 3. Update document status to 'draft' (if it's in preview)
    final supabaseClient = Supabase.instance.client;
    final response = await supabaseClient
        .from('facility_generated_documents')
        .update({
          'status': 'draft',
          if (notes != null) 'confirmation_notes': notes,
        })
        .eq('id', documentId)
        .then((_) => {'success': true, 'message': 'Document saved as draft'})
        .catchError((error) => {
              'success': false,
              'error': error.toString(),
            });

    if (kDebugMode) {
      print('[saveFacilityDocumentDraft] Save result: $response');
    }

    return response;

  } catch (e) {
    if (kDebugMode) {
      print('[saveFacilityDocumentDraft] Exception: $e');
    }
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

/// Retrieves a generated facility document
///
/// Returns: {
///   'success': bool,
///   'error': String? (if failed),
///   'document': {
///     'id': String,
///     'title': String,
///     'status': String,
///     'version': int,
///     'aiConfidence': double,
///     'createdAt': String,
///     'confirmedAt': String?,
///     ...
///   }
/// }

Future<Map<String, dynamic>> getFacilityDocument(String documentId) async {
  try {
    if (documentId.isEmpty) {
      return {
        'success': false,
        'error': 'Missing document ID',
      };
    }

    if (kDebugMode) {
      print('[getFacilityDocument] Fetching document: $documentId');
    }

    final supabaseClient = Supabase.instance.client;
    final response = await supabaseClient
        .from('facility_generated_documents')
        .select()
        .eq('id', documentId)
        .single();

    if (kDebugMode) {
      print('[getFacilityDocument] Fetched successfully');
    }

    return {
      'success': true,
      'document': response,
    };

  } catch (e) {
    if (kDebugMode) {
      print('[getFacilityDocument] Exception: $e');
    }
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

/// Lists facility documents for a specific facility
///
/// Returns: {
///   'success': bool,
///   'error': String? (if failed),
///   'documents': List<Map<String, dynamic>>,
///   'count': int,
/// }

Future<Map<String, dynamic>> listFacilityDocuments(
  String facilityId, {
  String? documentType,
  String? status,
  int limit = 20,
}) async {
  try {
    if (facilityId.isEmpty) {
      return {
        'success': false,
        'error': 'Missing facility ID',
      };
    }

    if (kDebugMode) {
      print('[listFacilityDocuments] Fetching for facility: $facilityId');
    }

    final supabaseClient = Supabase.instance.client;
    var baseQuery = supabaseClient
        .from('facility_generated_documents')
        .select()
        .eq('facility_id', facilityId);

    // Add optional filters
    if (documentType != null) {
      baseQuery = baseQuery.eq('document_type', documentType);
    }
    if (status != null) {
      baseQuery = baseQuery.eq('status', status);
    }

    final response = await baseQuery
        .order('created_at', ascending: false)
        .limit(limit);

    if (kDebugMode) {
      print('[listFacilityDocuments] Found ${response.length} documents');
    }

    return {
      'success': true,
      'documents': response,
      'count': response.length,
    };

  } catch (e) {
    if (kDebugMode) {
      print('[listFacilityDocuments] Exception: $e');
    }
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

/// Decodes base64 PDF data to bytes for saving/printing
Uint8List decodeDocumentBase64(String base64Data) {
  try {
    final replacedInput = base64Data.replaceAll('-', '+').replaceAll('_', '/');
    final normalisedInput = replacedInput + '=' * (4 - replacedInput.length % 4);
    return Uint8List.fromList(base64.decode(normalisedInput) as List<int>);
  } catch (e) {
    if (kDebugMode) {
      print('[decodeDocumentBase64] Error: $e');
    }
    return Uint8List(0);
  }
}
