// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class PostCallClinicalNotesDialog extends StatefulWidget {
  const PostCallClinicalNotesDialog({
    super.key,
    this.width,
    this.height,
    required this.sessionId,
    required this.appointmentId,
    required this.providerId,
    required this.patientId,
    required this.patientName,
    this.onSaved,
    this.onDiscarded,
  });

  final double? width;
  final double? height;
  final String sessionId;
  final String appointmentId;
  final String providerId;
  final String patientId;
  final String patientName;
  final VoidCallback? onSaved;
  final VoidCallback? onDiscarded;

  @override
  State<PostCallClinicalNotesDialog> createState() =>
      _PostCallClinicalNotesDialogState();
}

class _PostCallClinicalNotesDialogState
    extends State<PostCallClinicalNotesDialog> {
  bool _isLoading = false;
  bool _isGenerating = false;
  Map<String, dynamic>? _soapData;
  String? _errorMessage;
  String? _soapNoteId;
  String? _callTranscript;
  bool _isAiEnhancing = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize to ready state
    _soapData = _createEmptySoapStructure();
    _isGenerating = false;
    debugPrint('📱 PostCallClinicalNotesDialog initialized');

    // Trigger automatic transcript fetching and SOAP generation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTranscriptAndGenerateNote();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkTranscriptAndGenerateNote() async {
    debugPrint('⏳ _checkTranscriptAndGenerateNote() called - setting _isGenerating = true');
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });
    debugPrint('✅ setState completed for _isGenerating = true');

    try {
      debugPrint('🔍 Fetching session: ${widget.sessionId}');

      // OPTIMIZATION 1 + 4: Parallelize and reduce retry backoff times
      // Fetch by sessionId (if valid) AND appointmentId simultaneously for faster fallback

      // Validate sessionId before attempting query (prevent UUID validation errors)
      final isValidSessionId = widget.sessionId != null &&
          widget.sessionId!.isNotEmpty &&
          widget.sessionId!.length == 36 && // UUID v4 format
          widget.sessionId!.contains('-');

      dynamic session;

      // OPTIMIZATION: Try both in parallel - sessionId (fast) + appointmentId (fallback)
      if (isValidSessionId) {
        debugPrint('⚡ Parallelizing sessionId and appointmentId lookups...');
        final sessionByIdFuture = _fetchSessionByIdWithRetry();
        final sessionByAppointmentFuture = _fetchSessionByAppointmentId();

        final results = await Future.wait([
          sessionByIdFuture,
          sessionByAppointmentFuture,
        ]);

        session = results[0] ?? results[1]; // Use sessionId result if available, else appointmentId
      } else {
        debugPrint('⏳ Session ID invalid or empty: "${widget.sessionId}". Using appointmentId lookup only.');
        session = await _fetchSessionByAppointmentId();
      }

      // OPTIMIZATION 3: Show empty template immediately instead of waiting for generation
      if (session == null) {
        debugPrint('❌ Could not find session by either ID or appointmentId. Showing empty form.');
        setState(() {
          _isGenerating = false;
          _errorMessage = null;
          _soapData = _createEmptySoapStructure();
        });
        debugPrint('✅ Empty form displayed - user can fill manually');
        return;
      }

      debugPrint('✅ Session found. Status: ${session['status']}');

      final transcript = session['transcript'] as String?;
      debugPrint('📝 Transcript extracted: ${transcript?.length ?? 0} characters');

      // Store transcript for AI enhancement later
      if (transcript != null && transcript.isNotEmpty) {
        _callTranscript = transcript;
      }

      if (transcript == null || transcript.isEmpty) {
        debugPrint('⚠️ Transcript is empty, showing empty form');
        setState(() {
          _isGenerating = false;
          _soapData = _createEmptySoapStructure();
        });
        return;
      }

      // OPTIMIZATION 3: Show empty template first, then enhance async
      debugPrint('📋 Showing empty form template immediately...');
      setState(() {
        _isGenerating = false; // Stop showing spinner
        _soapData = _createEmptySoapStructure();
      });

      // Generate clinical note from transcript using AI (async, non-blocking)
      debugPrint('🚀 Calling _generateClinicalNote() async with transcript');
      unawaited(_generateClinicalNote(transcript)); // Fire-and-forget for faster UI response
      debugPrint('✅ Empty form displayed, generating SOAP in background...');
    } catch (e) {
      debugPrint('Error checking transcript: $e');
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Error loading transcript: $e';
        _soapData = _createEmptySoapStructure();
      });
    }
  }

  /// Fetch session by sessionId with aggressive timeout and minimal retry backoff (OPTIMIZATION 1)
  /// Reduced from 500ms/1000ms to 100ms/150ms exponential backoff with 3-second query timeout
  Future<dynamic> _fetchSessionByIdWithRetry() async {
    int retries = 0;
    final maxRetries = 1; // Only 1 retry - use appointmentId fallback if this fails

    while (retries < maxRetries) {
      try {
        debugPrint('🔍 Attempting to fetch session by ID (attempt ${retries + 1}/$maxRetries)...');
        final session = await SupaFlow.client
            .from('video_call_sessions')
            .select('id, transcript, speaker_segments, status')
            .eq('id', widget.sessionId!)
            .maybeSingle()
            .timeout(
              const Duration(seconds: 3), // Reduced from 5s to 3s - fail fast
              onTimeout: () => throw TimeoutException('Session query by ID timed out after 3s'),
            );

        if (session != null) {
          debugPrint('✅ Session found by ID on attempt ${retries + 1}');
          return session;
        }

        retries++;
        if (retries < maxRetries) {
          // OPTIMIZATION 1: Ultra-reduced backoff from 500/1000ms to 100/150ms
          final delayMs = 100 * retries; // 100ms instead of 200ms, 400ms
          debugPrint('⏳ Session not found by ID, retrying in ${delayMs}ms... (attempt $retries/$maxRetries)');
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      } catch (e) {
        debugPrint('⚠️ Error querying by sessionId: $e');
        retries++;
        if (retries < maxRetries) {
          final delayMs = 100 * retries;
          await Future.delayed(Duration(milliseconds: delayMs));
        }
      }
    }

    debugPrint('⚠️ Session not found by ID after retries, falling back to appointmentId lookup');
    return null;
  }

  /// Fetch session by appointmentId (single attempt, fail-fast timeout)
  Future<dynamic> _fetchSessionByAppointmentId() async {
    try {
      debugPrint('🔍 Fetching session by appointmentId: ${widget.appointmentId}');
      final session = await SupaFlow.client
          .from('video_call_sessions')
          .select('id, transcript, speaker_segments, status')
          .eq('appointment_id', widget.appointmentId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(
            const Duration(seconds: 3), // Reduced from 5s to 3s - fail fast on web
            onTimeout: () => throw TimeoutException('Session query by appointmentId timed out after 3s'),
          );

      if (session != null) {
        debugPrint('✅ Session found by appointmentId: ${session['id']}');
      } else {
        debugPrint('⚠️ No session found for appointment: ${widget.appointmentId}');
      }
      return session;
    } catch (e) {
      debugPrint('⚠️ Error querying by appointmentId: $e');
      return null;
    }
  }

  /// Create empty SOAP data structure for display with "No data" state
  Map<String, dynamic> _createEmptySoapStructure() {
    return {
      'subjective': {
        'hpi': {'narrative': ''},
        'ros': {},
        'medications': [],
        'allergies': [],
        'history': [],
      },
      'objective': {
        'vital_signs': {},
        'physical_exam': {},
      },
      'assessment': {
        'problem_list': [],
      },
      'plan': {
        'medication': [],
        'lab': [],
        'follow_up': [],
        'patient_education': [],
        'return_precautions': [],
      },
      'safety_alerts': [],
      'coding': {},
    };
  }

  Future<void> _generateClinicalNote(String transcript) async {
    Timer? safeguardTimer;
    try {
      debugPrint('🔍 _generateClinicalNote() started');
      final supabaseUrl = FFDevEnvironmentValues().SupaBaseURL;
      final supabaseKey = FFDevEnvironmentValues().Supabasekey;
      debugPrint('✅ Supabase config loaded');

      // Get Firebase token with force refresh for authentication
      final currentUser = FirebaseAuth.instance.currentUser;
      debugPrint('👤 Current user: ${currentUser?.uid}');
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _errorMessage = 'User not authenticated. Please log in again.';
            _soapData = _createEmptySoapStructure();
          });
        }
        return;
      }

      // WEB FIX: Add timeout to getIdToken to prevent indefinite UI freeze on web
      // Firebase auth can be slow on web when Firestore has connection issues
      String? token;
      debugPrint('⏳ About to call getIdToken(true) with 10-sec timeout');
      try {
        token = await currentUser.getIdToken(true).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Firebase token refresh timed out after 10 seconds'),
        );
        debugPrint('✅ Firebase token obtained (refreshed): ${token?.substring(0, 20)}...');
      } catch (e) {
        debugPrint('⚠️ Firebase token refresh failed: $e');
        debugPrint('⏳ Fallback: Calling getIdToken(false) with 5-sec timeout');
        // Fall back to non-refreshed token (may be stale but better than freezing)
        try {
          token = await currentUser.getIdToken(false).timeout(
            const Duration(seconds: 5),
          );
          debugPrint('✅ Firebase token obtained (non-refreshed): ${token?.substring(0, 20)}...');
        } catch (err) {
          debugPrint('❌ Even non-refreshed token failed: $err');
          // If even the non-refresh fails, create empty form
          if (mounted) {
            setState(() {
              _isGenerating = false;
              _errorMessage = 'Could not authenticate. Using empty template.';
              _soapData = _createEmptySoapStructure();
            });
          }
          return;
        }
      }

      if (token == null) {
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _errorMessage = 'Could not refresh authentication token.';
            _soapData = _createEmptySoapStructure();
          });
        }
        return;
      }

      // **WEB FIX**: Add aggressive safeguard timer to ensure UI is responsive within 30 seconds
      // This prevents indefinite UI freeze by forcing UI reset after maximum wait time
      // Bedrock Haiku should respond within 15-20 seconds, safeguard gives 10-15s buffer
      bool responseReceived = false;
      final soapGenerationStartTime = DateTime.now();
      debugPrint('📊 SOAP generation started at ${soapGenerationStartTime.toIso8601String()}');
      safeguardTimer = Timer(const Duration(seconds: 30), () {
        if (!responseReceived && mounted) {
          debugPrint('⚠️ Safeguard timeout triggered after 30 seconds - forcing UI responsive state');
          if (mounted) {
            setState(() {
              _isGenerating = false;
              _errorMessage = 'SOAP generation is taking longer than expected. Using empty template.';
              _soapData = _createEmptySoapStructure();
            });
          }
        }
      });

      final response = await http.post(
        Uri.parse('$supabaseUrl/functions/v1/generate-soap-from-transcript'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'x-firebase-token': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sessionId': widget.sessionId,
          'appointmentId': widget.appointmentId,
          'providerId': widget.providerId,
          'patientId': widget.patientId,
          'transcript': transcript,
        }),
      ).timeout(
        const Duration(seconds: 25), // Reduced from 50s to 25s - Haiku should be much faster
        onTimeout: () => throw TimeoutException('SOAP generation timed out after 25 seconds'),
      );

      responseReceived = true;
      safeguardTimer?.cancel();
      final elapsed = DateTime.now().difference(soapGenerationStartTime);
      debugPrint('✅ SOAP generation completed in ${elapsed.inMilliseconds}ms (${elapsed.inSeconds}s)');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            // Extract structured SOAP data from response
            if (data['soapNote'] != null) {
              _soapData = data['soapNote'] as Map<String, dynamic>;
            } else if (data['normalizedSoapNote'] != null) {
              _soapData = data['normalizedSoapNote'] as Map<String, dynamic>;
            } else {
              _soapData = _createEmptySoapStructure();
            }
            _soapNoteId = data['soapNoteId'] as String?;
            _isGenerating = false;
          });
        }
      } else {
        debugPrint('Generate SOAP note failed: ${response.body}');
        safeguardTimer?.cancel();
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _errorMessage = 'Failed to generate SOAP note: ${response.statusCode}';
            // Create empty SOAP structure so UI still displays
            _soapData = _createEmptySoapStructure();
          });
        }
      }
    } on TimeoutException catch (e) {
      debugPrint('❌ SOAP generation timed out: $e');
      safeguardTimer?.cancel();
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'SOAP generation timed out. Please try again or fill the form manually.';
          // Create empty SOAP structure so UI still displays
          _soapData = _createEmptySoapStructure();
        });
      }
    } catch (e) {
      debugPrint('Error generating SOAP note: $e');
      safeguardTimer?.cancel();
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'Error generating SOAP note: $e';
          // Create empty SOAP structure so UI still displays
          _soapData = _createEmptySoapStructure();
        });
      }
    }
  }

  Future<void> _saveNote() async {
    if (_soapData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No SOAP data to save')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // PHASE 1: DATABASE SAVE (BLOCKING - PRIMARY OPERATION)
      // This is the critical operation that must complete successfully
      // The SOAP note is persisted to Supabase as the source of truth
      if (_soapNoteId != null) {
        // Update existing SOAP note
        await SupaFlow.client
            .from('soap_notes')
            .update({
              'ai_raw_response': jsonEncode(_soapData),
              'status': 'signed',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', _soapNoteId!);
      } else {
        // Create new SOAP note if not generated yet
        final result = await SupaFlow.client
            .from('soap_notes')
            .insert({
              'video_call_session_id': widget.sessionId,
              'appointment_id': widget.appointmentId,
              'provider_id': widget.providerId,
              'patient_id': widget.patientId,
              'ai_raw_response': jsonEncode(_soapData),
              'status': 'signed',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select('id')
            .single();

        _soapNoteId = result['id'] as String?;
      }

      // PHASE 2: ASYNC BACKGROUND OPERATIONS (NON-BLOCKING - SECONDARY)
      // After database save completes successfully, fire async background operations:
      // 1. Sync SOAP note to EHRbase (non-blocking)
      // 2. Update cumulative patient medical record (non-blocking)
      // These do not block the provider workflow - if they fail, they're logged but don't prevent closing
      if (_soapNoteId != null) {
        _syncToEhrInBackground();
        _updatePatientMedicalRecordInBackground();
      }

      if (mounted) {
        Navigator.of(context)
            .pop({'saved': true, 'soapNoteId': _soapNoteId, 'soapData': _soapData});
      }
    } catch (e) {
      debugPrint('Error saving SOAP note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving SOAP note: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Sync SOAP note to EHRbase in background (non-blocking)
  /// Fires after SOAP note is saved successfully to database
  /// Does not block the provider workflow
  /// If EHR sync fails, the SOAP note is still safely stored in database
  Future<void> _syncToEhrInBackground() async {
    try {
      // Get Firebase token with force refresh to ensure validity
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ No user logged in, skipping EHR sync');
        return;
      }

      // WEB FIX: Add timeout to getIdToken to prevent indefinite UI freeze on web
      String? token;
      try {
        token = await currentUser.getIdToken(true).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Firebase token refresh timed out after 10 seconds'),
        );
      } catch (e) {
        debugPrint('⚠️ Firebase token refresh failed in EHR sync: $e');
        // Fall back to non-refreshed token
        try {
          token = await currentUser.getIdToken(false).timeout(
            const Duration(seconds: 5),
          );
        } catch (_) {
          debugPrint('⚠️ Even non-refreshed token failed, skipping EHR sync');
          return;
        }
      }

      final supabaseUrl = FFDevEnvironmentValues().SupaBaseURL;
      final supabaseKey = FFDevEnvironmentValues().Supabasekey;

      if (token == null) {
        debugPrint('⚠️ No Firebase token available, skipping EHR sync');
        return;
      }

      // Fire-and-forget HTTP call (don't await, don't block provider)
      // If sync-to-ehrbase fails, the SOAP note is already safely in database
      unawaited(
        http
            .post(
              Uri.parse('$supabaseUrl/functions/v1/sync-to-ehrbase'),
              headers: {
                'apikey': supabaseKey,
                'Authorization': 'Bearer $supabaseKey',
                'x-firebase-token': token,
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'soapNoteId': _soapNoteId,
                'patientId': widget.patientId,
                'appointmentId': widget.appointmentId,
              }),
            )
            .then((response) {
              if (response.statusCode == 200) {
                debugPrint(
                    '✅ SOAP note synced to EHRbase in background');
              } else {
                debugPrint(
                    '⚠️ Warning: Failed to sync to EHRbase: ${response.body}');
              }
            })
            .catchError((e) {
              debugPrint('⚠️ Background EHR sync failed: $e');
              // Don't throw - background task should never block provider
            }),
      );
    } catch (e) {
      debugPrint('⚠️ Non-blocking error syncing to EHRbase: $e');
      // Silently fail - don't block provider workflow
    }
  }

  /// Update patient medical record in background (non-blocking)
  /// Fires after SOAP note is saved successfully
  /// Does not block the provider workflow
  Future<void> _updatePatientMedicalRecordInBackground() async {
    try {
      // Get Firebase token with force refresh to ensure validity
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ No user logged in, skipping patient record update');
        return;
      }

      // WEB FIX: Add timeout to getIdToken to prevent indefinite UI freeze on web
      String? token;
      try {
        token = await currentUser.getIdToken(true).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Firebase token refresh timed out after 10 seconds'),
        );
      } catch (e) {
        debugPrint('⚠️ Firebase token refresh failed in patient record update: $e');
        // Fall back to non-refreshed token
        try {
          token = await currentUser.getIdToken(false).timeout(
            const Duration(seconds: 5),
          );
        } catch (_) {
          debugPrint('⚠️ Even non-refreshed token failed, skipping patient record update');
          return;
        }
      }

      final supabaseUrl = FFDevEnvironmentValues().SupaBaseURL;
      final supabaseKey = FFDevEnvironmentValues().Supabasekey;

      if (token == null) {
        debugPrint('⚠️ No Firebase token available, skipping patient record update');
        return;
      }

      // Fire-and-forget HTTP call (don't await, don't block provider)
      unawaited(
        http
            .post(
              Uri.parse(
                  '$supabaseUrl/functions/v1/update-patient-medical-record'),
              headers: {
                'apikey': supabaseKey,
                'Authorization': 'Bearer $supabaseKey',
                'x-firebase-token': token,
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'soapNoteId': _soapNoteId,
                'patientId': widget.patientId,
              }),
            )
            .then((response) {
              if (response.statusCode == 200) {
                debugPrint(
                    '✅ Patient medical record updated in background');
              } else {
                debugPrint(
                    '⚠️ Warning: Failed to update patient record: ${response.body}');
              }
            })
            .catchError((e) {
              debugPrint('⚠️ Background update failed: $e');
              // Don't throw - background task should never block provider
            }),
      );
    } catch (e) {
      debugPrint('⚠️ Non-blocking error updating patient record: $e');
      // Silently fail - don't block provider workflow
    }
  }

  Future<void> _enhanceWithAI() async {
    if (_callTranscript == null || _callTranscript!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transcript available for AI enhancement')),
      );
      return;
    }

    if (mounted) {
      setState(() => _isAiEnhancing = true);
    }

    Timer? safeguardTimer;
    try {
      final supabaseUrl = FFDevEnvironmentValues().SupaBaseURL;
      final supabaseKey = FFDevEnvironmentValues().Supabasekey;

      // Get Firebase token with force refresh for authentication
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not authenticated. Please log in again.')),
          );
          setState(() => _isAiEnhancing = false);
        }
        return;
      }

      // WEB FIX: Add timeout to getIdToken to prevent indefinite UI freeze on web
      String? token;
      try {
        token = await currentUser.getIdToken(true).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Firebase token refresh timed out after 10 seconds'),
        );
      } catch (e) {
        debugPrint('⚠️ Firebase token refresh failed in AI enhancement: $e');
        // Fall back to non-refreshed token
        try {
          token = await currentUser.getIdToken(false).timeout(
            const Duration(seconds: 5),
          );
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not refresh authentication token.')),
            );
            setState(() => _isAiEnhancing = false);
          }
          return;
        }
      }

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not refresh authentication token.')),
          );
          setState(() => _isAiEnhancing = false);
        }
        return;
      }

      // **WEB FIX**: Add aggressive safeguard timer for AI enhancement
      bool responseReceived = false;
      safeguardTimer = Timer(const Duration(seconds: 30), () {
        if (!responseReceived && mounted) {
          debugPrint('⚠️ AI enhancement safeguard timeout triggered after 30 seconds - forcing responsive state');
          if (mounted) {
            setState(() {
              _isAiEnhancing = false;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI enhancement took too long. Please try again.')),
              );
            });
          }
        }
      });

      final response = await http.post(
        Uri.parse('$supabaseUrl/functions/v1/generate-soap-from-transcript'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'x-firebase-token': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sessionId': widget.sessionId,
          'appointmentId': widget.appointmentId,
          'providerId': widget.providerId,
          'patientId': widget.patientId,
          'transcript': _callTranscript,
          'existingSoapNote': _soapData, // Pass existing data for enhancement context
        }),
      ).timeout(
        const Duration(seconds: 25), // Reduced from 40s to 25s - Haiku should respond quickly
        onTimeout: () => throw TimeoutException('AI enhancement timed out after 25 seconds'),
      );

      responseReceived = true;
      safeguardTimer?.cancel();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            // Extract structured SOAP data from response
            if (data['soapNote'] != null) {
              _soapData = data['soapNote'] as Map<String, dynamic>;
            } else if (data['normalizedSoapNote'] != null) {
              _soapData = data['normalizedSoapNote'] as Map<String, dynamic>;
            }
            _isAiEnhancing = false;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ SOAP note enhanced with AI insights'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        debugPrint('AI enhancement failed: ${response.body}');
        safeguardTimer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to enhance SOAP note: ${response.statusCode}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isAiEnhancing = false);
      }
    } on TimeoutException catch (e) {
      debugPrint('❌ AI enhancement timed out: $e');
      safeguardTimer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI enhancement timed out. Please try again later.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      if (mounted) {
        setState(() => _isAiEnhancing = false);
      }
    } catch (e) {
      debugPrint('Error enhancing SOAP note with AI: $e');
      safeguardTimer?.cancel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enhancing SOAP note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (mounted) {
        setState(() => _isAiEnhancing = false);
      }
    }
  }

  void _discardNote() {
    widget.onDiscarded?.call();
    Navigator.of(context).pop({'saved': false});
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 [build] method called. _isGenerating=$_isGenerating, _soapData=${_soapData != null}, _isAiEnhancing=$_isAiEnhancing');
    final isMobile = MediaQuery.of(context).size.width < 600;
    final dialogWidth = widget.width ?? (isMobile ? double.maxFinite : 800.0);
    final dialogHeight = widget.height ?? MediaQuery.of(context).size.height * 0.80;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.medical_services,
                          color: Colors.blue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Post-Call Clinical Notes',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_callTranscript != null && _callTranscript!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      border: Border.all(color: Colors.green[300]!),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Transcript Ready',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              'Patient: ${widget.patientName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                ],
              ),
            ),
            // Content area - Expanded to fill available space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _isGenerating
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            const Text('Generating clinical note from transcript...'),
                          ],
                        ),
                      )
                    : _isAiEnhancing
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                const Text('✨ Enhancing SOAP note with AI insights...'),
                                const SizedBox(height: 8),
                                const Text(
                                  'Analyzing transcript and optimizing clinical documentation',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning_amber, color: Colors.orange[700]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(color: Colors.orange[900]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (_soapData != null)
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      debugPrint('📋 [SoapSectionsViewer Builder] Building widget with ${_soapData!.keys.length} sections');
                                      return SoapSectionsViewer(
                                        soapData: _soapData!,
                                        isEditable: true,
                                        onDataChanged: (updatedData) {
                                          _soapData = updatedData;
                                        },
                                      );
                                    },
                                  ),
                                )
                              else
                                const Expanded(
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                            ],
                          ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: (_isLoading || _isAiEnhancing || _isGenerating) ? null : _discardNote,
                    child: const Text('Discard'),
                  ),
                  const SizedBox(width: 12),
                  if (_callTranscript != null && _callTranscript!.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed:
                          _isLoading || _isAiEnhancing || _isGenerating ? null : _enhanceWithAI,
                      icon: _isAiEnhancing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('AI Enhance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading || _isGenerating || _isAiEnhancing ? null : _saveNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign & Save Note'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
