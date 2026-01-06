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
import 'package:http/http.dart' as http;

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
  String? _clinicalNote;
  String? _errorMessage;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkTranscriptAndGenerateNote();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkTranscriptAndGenerateNote() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      // Check if transcript exists in video_call_sessions
      final session = await SupaFlow.client
          .from('video_call_sessions')
          .select('transcript, speaker_segments')
          .eq('id', widget.sessionId)
          .maybeSingle();

      if (session == null) {
        setState(() {
          _isGenerating = false;
          _errorMessage = 'Session not found';
        });
        return;
      }

      final transcript = session['transcript'] as String?;
      if (transcript == null || transcript.isEmpty) {
        setState(() {
          _isGenerating = false;
          _clinicalNote = null;
          _notesController.text = '';
        });
        return;
      }

      // Generate clinical note from transcript
      await _generateClinicalNote(transcript);
    } catch (e) {
      debugPrint('Error checking transcript: $e');
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Error loading transcript: $e';
      });
    }
  }

  Future<void> _generateClinicalNote(String transcript) async {
    try {
      final supabaseUrl = FFDevEnvironmentValues().SupaBaseURL;
      final supabaseKey = FFDevEnvironmentValues().Supabasekey;

      final response = await http.post(
        Uri.parse('$supabaseUrl/functions/v1/generate-clinical-note'),
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
          _clinicalNote = data['clinicalNote'] ?? data['note'] ?? '';
          _notesController.text = _clinicalNote ?? '';
          _isGenerating = false;
        });
      } else {
        debugPrint('Generate clinical note failed: ${response.body}');
        setState(() {
          _isGenerating = false;
          _errorMessage = 'Failed to generate note: ${response.statusCode}';
          // Allow manual entry even if generation fails
          _notesController.text = '';
        });
      }
    } catch (e) {
      debugPrint('Error generating clinical note: $e');
      setState(() {
        _isGenerating = false;
        _errorMessage = 'Error generating note: $e';
        _notesController.text = '';
      });
    }
  }

  Future<void> _saveNote() async {
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter clinical notes')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save clinical note to database
      await SupaFlow.client.from('clinical_notes').insert({
        'video_call_session_id': widget.sessionId,
        'appointment_id': widget.appointmentId,
        'provider_id': widget.providerId,
        'patient_id': widget.patientId,
        'note_content': _notesController.text.trim(),
        'note_type': 'soap',
        'status': 'draft',
        'created_at': DateTime.now().toIso8601String(),
      });

      widget.onSaved?.call();

      if (mounted) {
        Navigator.of(context)
            .pop({'saved': true, 'note': _notesController.text});
      }
    } catch (e) {
      debugPrint('Error saving clinical note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _discardNote() {
    widget.onDiscarded?.call();
    Navigator.of(context).pop({'saved': false});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: widget.width ?? 500,
        constraints: BoxConstraints(
          maxHeight: widget.height ?? MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                      const Text(
                        'Post-Call Clinical Notes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
              const Text(
                'Clinical Notes (SOAP Format):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _notesController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: _clinicalNote == null
                        ? 'No transcript available. Enter clinical notes manually...\n\nS: Subjective\nO: Objective\nA: Assessment\nP: Plan'
                        : 'Edit the generated clinical note...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : _discardNote,
                  child: const Text('Discard'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading || _isGenerating ? null : _saveNote,
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
                      : const Text('Save to EHR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
