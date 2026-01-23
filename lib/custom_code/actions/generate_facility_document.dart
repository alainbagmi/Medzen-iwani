import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/backend/backend.dart';
import '/environment_values.dart';

/// Generates a facility document (e.g., RMA II Report) with AI prefill
///
/// Flow:
/// 1. Fetch facility data + PDF template from MiniSanteTemplate bucket
/// 2. Call AI (Bedrock) to analyze PDF and determine field mappings
/// 3. Return base64 PDF + metadata for user preview
/// 4. User confirms/edits data
/// 5. Save to database
///
/// Returns: {
///   'success': bool,
///   'error': String? (if failed),
///   'document': {
///     'id': String,
///     'documentBase64': String,
///     'title': String,
///     'version': int,
///     'status': String,
///     'aiConfidence': double,
///     'aiFlags': List,
///     'createdAt': String,
///   }
/// }

Future<Map<String, dynamic>> generateFacilityDocument(
  String facilityId,
  String templatePath, {
  String? documentType,
}) async {
  try {
    // 1. Validate inputs
    if (facilityId.isEmpty || templatePath.isEmpty) {
      return {
        'success': false,
        'error': 'Missing facility ID or template path',
      };
    }

    // 2. Get Firebase token (CRITICAL: always force refresh)
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
      print('[generateFacilityDocument] Starting for facility: $facilityId');
    }

    // 3. Get Supabase credentials from backend configuration
    final supabaseUrl = FFDevEnvironmentValues().SupaBaseURL;
    final supabaseAnonKey = FFDevEnvironmentValues().Supabasekey;

    // 4. Prepare request body
    final requestBody = {
      'facilityId': facilityId,
      'templatePath': templatePath,
      if (documentType != null) 'documentType': documentType,
    };

    // 5. Call edge function with retry logic (exponential backoff)
    int retries = 0;
    const maxRetries = 3;
    const baseDelay = Duration(milliseconds: 500);

    http.Response? response;
    Exception? lastError;

    while (retries < maxRetries) {
      try {
        if (kDebugMode && retries > 0) {
          print('[generateFacilityDocument] Retry $retries/$maxRetries');
        }

        response = await http.post(
          Uri.parse('$supabaseUrl/functions/v1/generate-facility-document'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $supabaseAnonKey',
            'apikey': supabaseAnonKey,
            'x-firebase-token': idToken, // CRITICAL: lowercase header
          },
          body: jsonEncode(requestBody),
        ).timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw TimeoutException('Document generation timeout'),
        );

        // Check if response is successful
        if (response.statusCode == 200) {
          break; // Success, exit retry loop
        }

        // For non-200 responses, try to parse error
        if (response.statusCode >= 500) {
          // Server error, retry
          retries++;
          if (retries < maxRetries) {
            await Future.delayed(baseDelay * (1 << retries)); // Exponential backoff
            continue;
          }
        }

        // For client errors (4xx), don't retry
        break;

      } catch (e) {
        lastError = e as Exception;
        retries++;
        if (retries < maxRetries) {
          await Future.delayed(baseDelay * (1 << retries));
          continue;
        }
        break;
      }
    }

    // 6. Check if response was obtained
    if (response == null) {
      if (kDebugMode) {
        print('[generateFacilityDocument] Error: Failed to get response after $maxRetries retries');
        if (lastError != null) {
          print('[generateFacilityDocument] Last error: $lastError');
        }
      }
      return {
        'success': false,
        'error': lastError?.toString() ?? 'Document generation failed after multiple retries',
      };
    }

    // 7. Parse response
    if (response.statusCode != 200) {
      if (kDebugMode) {
        print('[generateFacilityDocument] Error response: ${response.statusCode}');
        print('[generateFacilityDocument] Body: ${response.body}');
      }

      try {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['error'] ?? 'Unknown error';
        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      } catch (e) {
        return {
          'success': false,
          'error': 'Request failed with status ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    }

    // Parse successful response
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['success'] != true) {
      return {
        'success': false,
        'error': data['error'] ?? 'Document generation failed',
      };
    }

    // 8. Extract document data
    final documentData = data['document'] as Map<String, dynamic>;

    if (kDebugMode) {
      print('[generateFacilityDocument] Success!');
      print('[generateFacilityDocument] Document ID: ${documentData['id']}');
      print('[generateFacilityDocument] AI Confidence: ${documentData['aiConfidence']}');
    }

    // 9. Return success with document data
    return {
      'success': true,
      'document': {
        'id': documentData['id'],
        'documentBase64': documentData['documentBase64'],
        'title': documentData['title'],
        'version': documentData['version'],
        'status': documentData['status'],
        'aiConfidence': documentData['aiConfidence'],
        'aiFlags': documentData['aiFlags'],
        'createdAt': documentData['createdAt'],
      },
      'documentId': documentData['id'],
      'documentBase64': documentData['documentBase64'],
      'title': documentData['title'],
      'version': documentData['version'],
      'confidence': documentData['aiConfidence'],
      'flags': documentData['aiFlags'],
    };

  } catch (e) {
    if (kDebugMode) {
      print('[generateFacilityDocument] Exception: $e');
    }
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

/// Exception for timeout errors
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
