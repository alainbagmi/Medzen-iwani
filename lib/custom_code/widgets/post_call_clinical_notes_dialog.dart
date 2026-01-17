// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'index.dart'; // Imports other custom widgets

import 'dart:convert';
import 'dart:async';
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

  @override
  void initState() {
    super.initState();
    _checkTranscriptAndGenerateNote();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkTranscriptAndGenerateNote() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔍 Fetching session: ${widget.sessionId}');

      // Retry logic - session might not be saved yet
      dynamic session;
      int retries = 0;
      final maxRetries = 3;

      // Validate sessionId before attempting query (prevent UUID validation errors)
      final isValidSessionId = widget.sessionId != null &&
          widget.sessionId!.isNotEmpty &&
          widget.sessionId!.length == 36 && // UUID v4 format
          widget.sessionId!.contains('-');

      // First, try to fetch by sessionId ONLY if it's a valid UUID format
      if (isValidSessionId) {
        while (retries < maxRetries) {
          try {
            session = await SupaFlow.client
                .from('video_call_sessions')
                .select('id, transcript, speaker_segments, status')
                .eq('id', widget.sessionId!)
                .maybeSingle();

            if (session != null) {
              debugPrint('✅ Session found by ID on attempt ${retries + 1}');
              break;
            }

            retries++;
            if (retries < maxRetries) {
              debugPrint('⏳ Session not found by ID, retrying... (attempt $retries/$maxRetries)');
              await Future.delayed(Duration(milliseconds: 500 * retries)); // Exponential backoff
            }
          } catch (e) {
            debugPrint('⚠️ Error querying by sessionId: $e');
            retries++;
            if (retries < maxRetries) {
              await Future.delayed(Duration(milliseconds: 500 * retries));
            }
          }
        }
      } else {
        debugPrint('⏳ Session ID invalid or empty: "${widget.sessionId}". Skipping ID lookup and using appointmentId instead.');
      }

      // If not found by sessionId, try by appointmentId (ROOT CAUSE FIX)
      if (session == null) {
        debugPrint('⚠️ Session not found by ID after $maxRetries retries. Trying appointmentId lookup...');

        // Fallback: Query by appointment_id instead (this is the actual root cause fix)
        final sessionsByAppointment = await SupaFlow.client
            .from('video_call_sessions')
            .select('id, transcript, speaker_segments, status')
            .eq('appointment_id', widget.appointmentId)
            .eq('status', 'active')
            .maybeSingle();

        if (sessionsByAppointment != null) {
          debugPrint('✅ Session found by appointmentId: ${sessionsByAppointment['id']}');
          session = sessionsByAppointment;
        } else {
          debugPrint('⚠️ No active session found for appointment: ${widget.appointmentId}');

          // Last resort: Check if there are any sessions (for diagnostic logging)
          try {
            final allSessions = await SupaFlow.client
                .from('video_call_sessions')
                .select('id, appointment_id, status')
                .eq('appointment_id', widget.appointmentId)
                .limit(5);
            debugPrint('📋 Sessions for appointment ${widget.appointmentId}: $allSessions');
          } catch (e) {
            debugPrint('Debug query error: $e');
          }
        }
      }

      if (session == null) {
        debugPrint('❌ Could not find session by either ID or appointmentId. User can fill form manually.');
        setState(() {
          _isGenerating = false;
          _errorMessage = null; // Don't show error, just continue with empty form
          // Create empty SOAP data structure - allow user to fill it manually
          _soapData = _createEmptySoapStructure();
        });
        return;
      }

      debugPrint('✅ Session status: ${session['status']}');

      final transcript = session['transcript'] as String?;

      // Store transcript for AI enhancement later
      if (transcript != null && transcript.isNotEmpty) {
        _callTranscript = transcript;
      }

      if (transcript == null || transcript.isEmpty) {
        setState(() {
          _isGenerating = false;
          // Create empty SOAP data structure when no transcript
          _soapData = _createEmptySoapStructure();
        });
        return;
      }

      // Generate clinical note from transcript using AI
      await _generateClinicalNote(transcript);
    } catch (e) {
      debugPrint('Error checking transcript: $e');
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Error loading transcript: $e';
        // Create empty SOAP data structure on error
        _soapData = _createEmptySoapStructure();
      });
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
    try {
      final supabaseUrl = FFDevEnvironmentValues().SupaBaseURL;
      final supabaseKey = FFDevEnvironmentValues().Supabasekey;

      final response = await http.post(
        Uri.parse('$supabaseUrl/functions/v1/generate-soap-from-transcript'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sessionId': widget.sessionId,
          'appointmentId': widget.appointmentId,
          'providerId': widget.providerId,
          'patientId': widget.patientId,
          'transcript': transcript,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
      } else {
        debugPrint('Generate SOAP note failed: ${response.body}');
        setState(() {
          _isGenerating = false;
          _errorMessage = 'Failed to generate SOAP note: ${response.statusCode}';
          // Create empty SOAP structure so UI still displays
          _soapData = _createEmptySoapStructure();
        });
      }
    } catch (e) {
      debugPrint('Error generating SOAP note: $e');
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Error generating SOAP note: $e';
        // Create empty SOAP structure so UI still displays
        _soapData = _createEmptySoapStructure();
      });
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

      widget.onSaved?.call();

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

      final token = await currentUser.getIdToken(true);
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

      final token = await currentUser.getIdToken(true);
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

    setState(() => _isAiEnhancing = true);

    try {
      final supabaseUrl = FFDevEnvironmentValues().SupaBaseURL;
      final supabaseKey = FFDevEnvironmentValues().Supabasekey;

      final response = await http.post(
        Uri.parse('$supabaseUrl/functions/v1/generate-soap-from-transcript'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          // Extract structured SOAP data from response
          if (data['soapNote'] != null) {
            _soapData = data['soapNote'] as Map<String, dynamic>;
          } else if (data['normalizedSoapNote'] != null) {
            _soapData = data['normalizedSoapNote'] as Map<String, dynamic>;
          }
          _isAiEnhancing = false;
        });

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
    } catch (e) {
      debugPrint('Error enhancing SOAP note with AI: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enhancing SOAP note: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isAiEnhancing = false);
    }
  }

  void _discardNote() {
    widget.onDiscarded?.call();
    Navigator.of(context).pop({'saved': false});
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final dialogWidth = widget.width ?? (isMobile ? double.maxFinite : 800.0);
    final dialogHeight = widget.height ?? MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
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
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _discardNote,
                ),
              ],
            ),
            const Divider(height: 24),

            // Content
            if (_isGenerating) ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generating clinical note from transcript...'),
                    ],
                  ),
                ),
              ),
            ] else if (_isAiEnhancing) ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('✨ Enhancing SOAP note with AI insights...'),
                      SizedBox(height: 8),
                      Text(
                        'Analyzing transcript and optimizing clinical documentation',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
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
              if (_soapData != null)
                Expanded(
                  child: SoapSectionsViewer(
                    soapData: _soapData!,
                    isEditable: true,
                    onDataChanged: (updatedData) {
                      setState(() {
                        _soapData = updatedData;
                      });
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

            const SizedBox(height: 16),

            // Actions
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  TextButton(
                    onPressed: (_isLoading || _isAiEnhancing || _isGenerating) ? null : _discardNote,
                    child: const Text('Discard'),
                  ),
                  const SizedBox(width: 12),
                  // AI Enhance button - only show if transcript exists
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
