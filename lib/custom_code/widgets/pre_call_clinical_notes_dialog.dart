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

import 'dart:convert';

class PreCallClinicalNotesDialog extends StatefulWidget {
  const PreCallClinicalNotesDialog({
    super.key,
    this.width,
    this.height,
    required this.patientId,
    required this.patientName,
    this.onReady,
  });

  final double? width;
  final double? height;
  final String patientId;
  final String patientName;
  final VoidCallback? onReady;

  @override
  State<PreCallClinicalNotesDialog> createState() =>
      _PreCallClinicalNotesDialogState();
}

class _PreCallClinicalNotesDialogState extends State<PreCallClinicalNotesDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _lastClinicalNote;
  Map<String, dynamic>? _patientBiometrics;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get latest clinical note for this patient
      final clinicalNotes = await SupaFlow.client
          .from('clinical_notes')
          .select('soap_note, created_at')
          .eq('patient_id', widget.patientId)
          .order('created_at', ascending: false)
          .limit(1);

      if (clinicalNotes.isNotEmpty) {
        _lastClinicalNote = clinicalNotes[0]['soap_note'] as String?;
      }

      // Get patient biometrics from patient_profiles
      final patientProfile = await SupaFlow.client
          .from('patient_profiles')
          .select('blood_type, allergies, chronic_conditions, current_medications')
          .eq('user_id', widget.patientId)
          .maybeSingle();

      if (patientProfile != null) {
        _patientBiometrics = patientProfile;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading patient data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load patient information: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.assignment_ind, color: Colors.blue[700], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Patient Context - ${widget.patientName}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Patient Biometrics Section
                  if (_patientBiometrics != null) ...[
                    Text(
                      'Patient Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_patientBiometrics!['blood_type'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Text('Blood Type: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(_patientBiometrics!['blood_type'] ?? 'N/A'),
                                ],
                              ),
                            ),
                          if (_patientBiometrics!['allergies'] != null &&
                              (_patientBiometrics!['allergies'] as String)
                                  .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Allergies:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(_patientBiometrics!['allergies'] ?? 'None'),
                                ],
                              ),
                            ),
                          if (_patientBiometrics!['chronic_conditions'] != null &&
                              (_patientBiometrics!['chronic_conditions'] as String)
                                  .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Chronic Conditions:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(_patientBiometrics!['chronic_conditions'] ??
                                      'None'),
                                ],
                              ),
                            ),
                          if (_patientBiometrics!['current_medications'] != null &&
                              (_patientBiometrics!['current_medications'] as String)
                                  .isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Current Medications:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(_patientBiometrics!['current_medications'] ??
                                    'None'),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Last Clinical Note Section
                  if (_lastClinicalNote != null && _lastClinicalNote!.isNotEmpty)
                    ...[
                      Text(
                        'Previous Clinical Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber[200]!),
                        ),
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          child: Text(
                            _lastClinicalNote!,
                            style: const TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ),
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'No previous clinical notes available',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Review patient context before starting the call',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onReady?.call();
          },
          child: const Text('Start Call'),
        ),
      ],
    );
  }
}
