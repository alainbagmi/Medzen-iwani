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
  Map<String, dynamic>? _lastSoapNote;
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
      // Get latest SOAP note for this patient (for Previous Clinical Context section)
      final soapNotes = await SupaFlow.client
          .from('soap_notes')
          .select('id')
          .eq('patient_id', widget.patientId)
          .order('created_at', ascending: false)
          .limit(1);

      if (soapNotes.isNotEmpty) {
        final soapNoteId = soapNotes[0]['id'] as String;

        // Fetch full structured SOAP note via RPC function
        final fullSoapNote = await SupaFlow.client
            .rpc('get_soap_note_full', params: {'p_soap_note_id': soapNoteId});

        if (fullSoapNote != null) {
          _lastSoapNote = fullSoapNote as Map<String, dynamic>;
        }
      }

      // Get patient cumulative medical record from patient_profiles
      final patientProfile = await SupaFlow.client
          .from('patient_profiles')
          .select(
              'blood_type, allergies, chronic_conditions, current_medications, cumulative_medical_record, medical_record_last_updated_at')
          .eq('user_id', widget.patientId)
          .maybeSingle();

      if (patientProfile != null) {
        final cumulativeRecord =
            patientProfile['cumulative_medical_record'] as Map<String, dynamic>?;

        if (cumulativeRecord != null) {
          // Transform cumulative record to display format
          _patientBiometrics = {
            'blood_type': patientProfile['blood_type'] ?? 'Unknown',
            'last_updated': patientProfile['medical_record_last_updated_at'],

            // Active conditions with ICD-10 codes
            'conditions': (cumulativeRecord['conditions'] as List?)
                    ?.where((c) => (c['status'] ?? 'active') == 'active')
                    .map((c) =>
                        '${c['name'] ?? 'Unknown'} (${c['icd10'] ?? 'N/A'})')
                    .join(', ') ??
                'None',

            // Current active medications with dose/frequency
            'medications': (cumulativeRecord['medications'] as List?)
                    ?.where((m) => (m['status'] ?? 'active') == 'active')
                    .map((m) =>
                        '${m['name'] ?? 'Unknown'} ${m['dose'] ?? ''}${m['frequency'] != null ? ' ${m['frequency']}' : ''}'
                            .trim())
                    .join(', ') ??
                'None',

            // Active allergies with severity
            'allergies': (cumulativeRecord['allergies'] as List?)
                    ?.where((a) => (a['status'] ?? 'active') == 'active')
                    .map((a) =>
                        '${a['allergen'] ?? 'Unknown'} (${a['severity'] ?? 'moderate'})')
                    .join(', ') ??
                'None',

            // Surgical history
            'surgical_history': (cumulativeRecord['surgical_history'] as List?)
                    ?.map((s) => '${s['procedure'] ?? 'Unknown'} (${s['date'] ?? 'N/A'})')
                    .join(', ') ??
                'None',

            // Family history
            'family_history': (cumulativeRecord['family_history'] as List?)
                    ?.map((f) =>
                        '${f['condition'] ?? 'Unknown'} (${f['relationship'] ?? 'N/A'})')
                    .join(', ') ??
                'None',

            // Latest vitals
            'vital_trends': cumulativeRecord['vital_trends'] ?? {},

            // Social history
            'social_history': cumulativeRecord['social_history'] ?? {},

            // Metadata
            'total_visits': cumulativeRecord['metadata']?['total_visits'] ?? 0,
          };
        } else {
          // Fallback to basic fields if no cumulative record
          _patientBiometrics = {
            'blood_type': patientProfile['blood_type'] ?? 'Unknown',
            'allergies': patientProfile['allergies'] ?? 'None',
            'chronic_conditions': patientProfile['chronic_conditions'] ?? 'None',
            'current_medications': patientProfile['current_medications'] ?? 'None',
            'total_visits': 0,
          };
        }
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
          : SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.7,
              child: SingleChildScrollView(
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
                    // Patient Cumulative Medical Record Section
                    if (_patientBiometrics != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cumulative Patient Record',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          if (_patientBiometrics!['total_visits'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_patientBiometrics!['total_visits']} visits',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.green[900]),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Blood Type
                            if (_patientBiometrics!['blood_type'] != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.bloodtype,
                                        size: 16, color: Colors.blue[700]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Blood Type',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13)),
                                          Text(
                                            _patientBiometrics!['blood_type'] ??
                                                'N/A',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[800]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Active Conditions
                            if (_patientBiometrics!['conditions'] != null &&
                                (_patientBiometrics!['conditions'] as String)
                                    .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.medical_services,
                                        size: 16, color: Colors.blue[700]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Active Conditions',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13)),
                                          Text(
                                            _patientBiometrics!['conditions'] ??
                                                'None',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[800]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Current Medications
                            if (_patientBiometrics!['medications'] != null &&
                                (_patientBiometrics!['medications'] as String)
                                    .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.medication,
                                        size: 16, color: Colors.blue[700]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Current Medications',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13)),
                                          Text(
                                            _patientBiometrics!['medications'] ??
                                                'None',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[800]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Allergies (highlighted if present)
                            if (_patientBiometrics!['allergies'] != null &&
                                (_patientBiometrics!['allergies'] as String)
                                    .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(6),
                                    border:
                                        Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.warning_amber,
                                          size: 16, color: Colors.red[700]),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Allergies',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    fontSize: 13,
                                                    color: Colors.red[900])),
                                            Text(
                                              _patientBiometrics!['allergies'] ??
                                                  'None',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red[900]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Surgical History (expandable)
                            if (_patientBiometrics!['surgical_history'] !=
                                    null &&
                                (_patientBiometrics!['surgical_history']
                                        as String)
                                    .isNotEmpty &&
                                _patientBiometrics!['surgical_history'] !=
                                    'None')
                              ExpansionTile(
                                title: const Text('Surgical History',
                                    style: TextStyle(fontSize: 13)),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      _patientBiometrics![
                                          'surgical_history'] as String,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                            // Family History (expandable)
                            if (_patientBiometrics!['family_history'] !=
                                    null &&
                                (_patientBiometrics!['family_history']
                                        as String)
                                    .isNotEmpty &&
                                _patientBiometrics!['family_history'] !=
                                    'None')
                              ExpansionTile(
                                title: const Text('Family History',
                                    style: TextStyle(fontSize: 13)),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      _patientBiometrics!['family_history']
                                          as String,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                            // Last Updated Timestamp
                            if (_patientBiometrics!['last_updated'] !=
                                null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Last updated: ${_patientBiometrics!['last_updated'] ?? 'N/A'}',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[600]),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Last SOAP Note Section
                    Text(
                      'Previous Clinical Context',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 300,
                      child: _lastSoapNote != null
                          ? SoapSectionsViewer(
                              soapData: _lastSoapNote!,
                              isEditable: false,
                            )
                          : SoapSectionsViewer(
                              soapData: _createEmptySoapStructure(),
                              isEditable: false,
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
            ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onReady?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Proceed with Call'),
        ),
      ],
    );
  }
}
