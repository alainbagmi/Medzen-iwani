import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';

class SoapNoteTabbedView extends StatefulWidget {
  final String encounterId;
  final String sessionId;
  final String? initialStatus;

  const SoapNoteTabbedView({
    Key? key,
    required this.encounterId,
    required this.sessionId,
    this.initialStatus,
  }) : super(key: key);

  @override
  State<SoapNoteTabbedView> createState() => _SoapNoteTabbedViewState();
}

class _SoapNoteTabbedViewState extends State<SoapNoteTabbedView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _localSoapData = {};
  List<Map<String, dynamic>> _pendingOps = [];
  Timer? _debounceTimer;
  int _clientRevision = 0;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;
  DateTime? _lastSavedTime;
  String? _conflictMessage;

  // Tab 1 controllers
  late TextEditingController _tab1VisitDateController;
  late TextEditingController _tab1VisitTypeController;
  late TextEditingController _tab1ChiefComplaintController;
  late TextEditingController _tab1IdentityMethodController;

  // Tab 3 controllers
  late TextEditingController _tab3CCPatientWordsController;
  late TextEditingController _tab3PrimaryReasonController;

  // Tab 4 controllers
  late TextEditingController _tab4OnsetDateController;
  late TextEditingController _tab4DurationController;
  late TextEditingController _tab4SeverityController;
  late TextEditingController _tab4ProgressionController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 12, vsync: this);
    _initializeControllers();
    _loadSoapDraft();
  }

  void _initializeControllers() {
    _tab1VisitDateController = TextEditingController();
    _tab1VisitTypeController = TextEditingController();
    _tab1ChiefComplaintController = TextEditingController();
    _tab1IdentityMethodController = TextEditingController();

    _tab3CCPatientWordsController = TextEditingController();
    _tab3PrimaryReasonController = TextEditingController();

    _tab4OnsetDateController = TextEditingController();
    _tab4DurationController = TextEditingController();
    _tab4SeverityController = TextEditingController();
    _tab4ProgressionController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounceTimer?.cancel();
    _tab1VisitDateController.dispose();
    _tab1VisitTypeController.dispose();
    _tab1ChiefComplaintController.dispose();
    _tab1IdentityMethodController.dispose();
    _tab3CCPatientWordsController.dispose();
    _tab3PrimaryReasonController.dispose();
    _tab4OnsetDateController.dispose();
    _tab4DurationController.dispose();
    _tab4SeverityController.dispose();
    _tab4ProgressionController.dispose();
    super.dispose();
  }

  Future<void> _loadSoapDraft() async {
    try {
      final session = await SupaFlow.client
          .from('video_call_sessions')
          .select('soap_draft_json, server_revision, soap_status')
          .eq('id', widget.encounterId)
          .single();

      setState(() {
        _localSoapData = session['soap_draft_json'] ?? _createEmptySchema();
        _clientRevision = session['server_revision'] ?? 0;
        _isLoading = false;
      });

      _populateControllers();
      debugPrint('✅ SOAP draft loaded (revision $_clientRevision)');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load SOAP draft: $e';
        _isLoading = false;
      });
      debugPrint('❌ Error loading SOAP draft: $e');
    }
  }

  void _populateControllers() {
    // Tab 1
    _tab1VisitDateController.text =
        _localSoapData['tab1_encounter_header']?['visit_date'] ?? '';
    _tab1VisitTypeController.text =
        _localSoapData['tab1_encounter_header']?['visit_type'] ?? '';
    _tab1ChiefComplaintController.text =
        _localSoapData['tab1_encounter_header']?['chief_complaint_as_written'] ?? '';
    _tab1IdentityMethodController.text =
        _localSoapData['tab1_encounter_header']?['identity_verified_method'] ?? '';

    // Tab 3
    _tab3CCPatientWordsController.text =
        _localSoapData['tab3_cc']?['chief_complaint_patient_words'] ?? '';
    _tab3PrimaryReasonController.text =
        _localSoapData['tab3_cc']?['primary_reason_coded'] ?? '';

    // Tab 4
    _tab4OnsetDateController.text =
        _localSoapData['tab4_subjective_hpi']?['onset_date'] ?? '';
    _tab4DurationController.text =
        _localSoapData['tab4_subjective_hpi']?['duration'] ?? '';
    _tab4SeverityController.text =
        (_localSoapData['tab4_subjective_hpi']?['severity_0_10'] ?? '').toString();
    _tab4ProgressionController.text =
        _localSoapData['tab4_subjective_hpi']?['progression'] ?? '';
  }

  void _onFieldChanged(String jsonPath, dynamic value) {
    // Update local state immediately for instant UI feedback
    setState(() {
      _setJsonPath(_localSoapData, jsonPath, value);
    });

    // Queue patch operation
    _pendingOps.add({
      'op': 'set',
      'path': jsonPath,
      'value': value,
    });

    // Debounce server save (800ms)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _sendPatchToServer();
    });
  }

  Future<void> _sendPatchToServer() async {
    if (_pendingOps.isEmpty) return;

    final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (token == null) {
      debugPrint('⚠️ Unable to get Firebase token for SOAP patch');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final supabaseUrl = FFDevEnvironmentValues().SupaBaseURL;
      final anonKey = FFDevEnvironmentValues().Supabasekey;

      final response = await http.post(
        Uri.parse('$supabaseUrl/functions/v1/soap-draft-patch'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $anonKey',
          'x-firebase-token': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'encounter_id': widget.encounterId,
          'client_revision': _clientRevision,
          'ops': _pendingOps,
          'device': {
            'platform': kIsWeb ? 'web' : Platform.operatingSystem,
            'app_version': '1.0.0',
          },
        }),
      );

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['ok'] == true) {
        setState(() {
          _clientRevision = json['server_revision'];
          _pendingOps.clear();
          _isSaving = false;
          _lastSavedTime = DateTime.now();
          _conflictMessage = null;
        });
        debugPrint(
            '✅ SOAP draft saved (${json['operations_applied']} ops, rev $_clientRevision)');
      } else if (response.statusCode == 409) {
        // Conflict - show dialog
        _showConflictDialog(json['latest_draft']);
      } else {
        setState(() {
          _isSaving = false;
        });
        debugPrint('⚠️ Unexpected response: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      debugPrint('❌ Failed to save SOAP draft patch: $e');
    }
  }

  void _showConflictDialog(Map<String, dynamic> latestDraft) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Conflict Detected'),
        content: const Text(
            'This note was updated elsewhere. Do you want to reload the latest version? Your unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Keep My Changes'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _localSoapData = latestDraft;
                _clientRevision++;
                _pendingOps.clear();
                _populateControllers();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reloaded latest version')),
              );
            },
            child: const Text('Reload Latest'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSoapNote() async {
    // Update status to submitted
    final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (token == null) return;

    try {
      // First, ensure all pending changes are saved
      if (_pendingOps.isNotEmpty) {
        await _sendPatchToServer();
      }

      // Then update status to submitted
      await SupaFlow.client.from('video_call_sessions').update({
        'soap_status': 'submitted',
        'encounter_status': 'soap_submitted',
      }).eq('id', widget.encounterId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOAP note submitted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Error submitting SOAP note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _signOffSoapNote() async {
    // Validate required signature fields
    final signerName = _localSoapData['tab12_mdm_quality_attachments_signoff']?['signer_name'];
    final signerCredentials = _localSoapData['tab12_mdm_quality_attachments_signoff']?['signer_credentials'];

    if ((signerName == null || signerName.toString().trim().isEmpty) ||
        (signerCredentials == null || signerCredentials.toString().trim().isEmpty)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in Signer Name and Signer Credentials before signing off'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    if (token == null) return;

    try {
      // First, ensure all pending changes are saved
      if (_pendingOps.isNotEmpty) {
        await _sendPatchToServer();
      }

      // Update signature date to current timestamp if not already set
      final signatureDate = _localSoapData['tab12_mdm_quality_attachments_signoff']?['signature_date'];
      if (signatureDate == null || signatureDate.toString().trim().isEmpty) {
        _localSoapData['tab12_mdm_quality_attachments_signoff']?['signature_date'] =
            DateTime.now().toIso8601String();
      }

      // Then update status to signed and encounter to soap_signed
      await SupaFlow.client.from('video_call_sessions').update({
        'soap_status': 'signed',
        'encounter_status': 'soap_signed',
      }).eq('id', widget.encounterId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOAP note signed off successfully')),
        );

        // Show confirmation dialog with option to close encounter
        showDialog(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: const Text('Sign-off Complete'),
            content: const Text('SOAP note has been signed off. Close the encounter?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Close SOAP view
                },
                child: const Text('Yes, Close'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Stay in Note'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error signing off SOAP note: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('SOAP Note')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('SOAP Note')),
        body: Center(child: Text('Error: $_errorMessage')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOAP Note (12 Tabs)'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Colors.grey[100],
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: '1. Encounter'),
                Tab(text: '2. Patient ID'),
                Tab(text: '3. CC'),
                Tab(text: '4. HPI'),
                Tab(text: '5. History'),
                Tab(text: '6. ROS'),
                Tab(text: '7. Vitals'),
                Tab(text: '8. Exam'),
                Tab(text: '9. Diagnostics'),
                Tab(text: '10. Assessment'),
                Tab(text: '11. Plan'),
                Tab(text: '12. Sign-off'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTab1Encounter(),
                _buildTab2PatientId(),
                _buildTab3ChiefComplaint(),
                _buildTab4HPI(),
                _buildTab5History(),
                _buildTab6ROS(),
                _buildTab7Vitals(),
                _buildTab8Exam(),
                _buildTab9Diagnostics(),
                _buildTab10Assessment(),
                _buildTab11Plan(),
                _buildTab12SignOff(),
              ],
            ),
          ),

          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
              color: Colors.grey[50],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_conflictMessage != null)
                      Text(
                        _conflictMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      )
                    else if (_isSaving)
                      const Text(
                        'Saving...',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      )
                    else if (_pendingOps.isEmpty && _lastSavedTime != null)
                      const Text(
                        'Auto-saved ✓',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      )
                    else if (_pendingOps.isNotEmpty)
                      Text(
                        'Unsaved changes (${_pendingOps.length} ops)',
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      )
                    else
                      const Text(
                        'Ready',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
                Row(
                  children: [
                    // Show Submit button if status is editing or draft_ready
                    if (_localSoapData['meta']?['status'] == 'editing' ||
                        _localSoapData['meta']?['status'] == 'draft_ready')
                      ElevatedButton(
                        onPressed: _submitSoapNote,
                        child: const Text('Submit Note'),
                      ),
                    const SizedBox(width: 8),
                    // Show Sign Off button if status is submitted
                    if (_localSoapData['meta']?['status'] == 'submitted')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle),
                        onPressed: _signOffSoapNote,
                        label: const Text('Sign Off'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    // Show read-only indicator if signed or failed
                    if (_localSoapData['meta']?['status'] == 'signed' ||
                        _localSoapData['meta']?['status'] == 'failed')
                      Chip(
                        label: Text(
                          _localSoapData['meta']?['status'] == 'signed'
                              ? 'Note Signed'
                              : 'Note Failed',
                        ),
                        backgroundColor:
                            _localSoapData['meta']?['status'] == 'signed'
                                ? Colors.green[100]
                                : Colors.red[100],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tab 1: Encounter Header
  Widget _buildTab1Encounter() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Encounter Header',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _tab1VisitDateController,
            decoration: const InputDecoration(
              labelText: 'Visit Date',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) =>
                _onFieldChanged(r'$.tab1_encounter_header.visit_date', value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tab1VisitTypeController,
            decoration: const InputDecoration(
              labelText: 'Visit Type',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) =>
                _onFieldChanged(r'$.tab1_encounter_header.visit_type', value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tab1ChiefComplaintController,
            decoration: const InputDecoration(
              labelText: 'Chief Complaint (As Written)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) => _onFieldChanged(
                r'$.tab1_encounter_header.chief_complaint_as_written', value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tab1IdentityMethodController,
            decoration: const InputDecoration(
              labelText: 'Identity Verified Method',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _onFieldChanged(
                r'$.tab1_encounter_header.identity_verified_method', value),
          ),
        ],
      ),
    );
  }

  // Tab 2: Patient Identification (placeholder)
  Widget _buildTab2PatientId() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patient Identification',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text(
              'Patient demographics auto-populated from context snapshot'),
          const SizedBox(height: 12),
          if (_localSoapData['tab2_patient_identification'] != null)
            Text(_localSoapData['tab2_patient_identification'].toString()),
        ],
      ),
    );
  }

  // Tab 3: Chief Complaint
  Widget _buildTab3ChiefComplaint() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chief Complaint',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _tab3CCPatientWordsController,
            decoration: const InputDecoration(
              labelText: 'Chief Complaint (Patient\'s Words)',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            onChanged: (value) => _onFieldChanged(
                r'$.tab3_cc.chief_complaint_patient_words', value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tab3PrimaryReasonController,
            decoration: const InputDecoration(
              labelText: 'Primary Reason (Coded)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) =>
                _onFieldChanged(r'$.tab3_cc.primary_reason_coded', value),
          ),
        ],
      ),
    );
  }

  // Tab 4: HPI
  Widget _buildTab4HPI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('History of Present Illness',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _tab4OnsetDateController,
            decoration: const InputDecoration(
              labelText: 'Onset Date',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) =>
                _onFieldChanged(r'$.tab4_subjective_hpi.onset_date', value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tab4DurationController,
            decoration: const InputDecoration(
              labelText: 'Duration',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) =>
                _onFieldChanged(r'$.tab4_subjective_hpi.duration', value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tab4SeverityController,
            decoration: const InputDecoration(
              labelText: 'Severity (0-10)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final intValue = int.tryParse(value) ?? 0;
              _onFieldChanged(r'$.tab4_subjective_hpi.severity_0_10', intValue);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tab4ProgressionController,
            decoration: const InputDecoration(
              labelText: 'Progression',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) =>
                _onFieldChanged(r'$.tab4_subjective_hpi.progression', value),
          ),
        ],
      ),
    );
  }

  // Tab 5: History (PMH, PSH, Meds, Allergies)
  Widget _buildTab5History() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Medical History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildListSection(
            'Past Medical History (PMH)',
            'tab5_subjective_history.pmh',
            _localSoapData['tab5_subjective_history']?['pmh'] ?? [],
          ),
          const SizedBox(height: 16),
          _buildListSection(
            'Past Surgical History (PSH)',
            'tab5_subjective_history.psh',
            _localSoapData['tab5_subjective_history']?['psh'] ?? [],
          ),
          const SizedBox(height: 16),
          _buildListSection(
            'Current Medications',
            'tab5_subjective_history.medications',
            _localSoapData['tab5_subjective_history']?['medications'] ?? [],
          ),
          const SizedBox(height: 16),
          _buildListSection(
            'Allergies',
            'tab5_subjective_history.allergies',
            _localSoapData['tab5_subjective_history']?['allergies'] ?? [],
          ),
        ],
      ),
    );
  }

  // Tab 6: Review of Systems
  Widget _buildTab6ROS() {
    final ros = _localSoapData['tab6_ros'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review of Systems',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildROSField('Constitutional', 'constitutional', ros),
          _buildROSField('Eyes', 'eyes', ros),
          _buildROSField('Ears/Nose/Throat', 'ears_nose_throat', ros),
          _buildROSField('Cardiovascular', 'cardiovascular', ros),
          _buildROSField('Respiratory', 'respiratory', ros),
          _buildROSField('Gastrointestinal', 'gastrointestinal', ros),
          _buildROSField('Genitourinary', 'genitourinary', ros),
          _buildROSField('Musculoskeletal', 'musculoskeletal', ros),
          _buildROSField('Neurological', 'neurological', ros),
          _buildROSField('Psychiatric', 'psychiatric', ros),
          _buildROSField('Endocrine', 'endocrine', ros),
          _buildROSField('Skin', 'skin', ros),
        ],
      ),
    );
  }

  // Tab 7: Vitals & General
  Widget _buildTab7Vitals() {
    final vitals = _localSoapData['tab7_objective_vitals_general']?['vitals'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vitals & General Appearance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildVitalField('BP Systolic', 'bp_systolic', vitals),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVitalField('BP Diastolic', 'bp_diastolic', vitals),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildVitalField('Heart Rate', 'hr', vitals),
          const SizedBox(height: 12),
          _buildVitalField('Respiratory Rate', 'rr', vitals),
          const SizedBox(height: 12),
          _buildVitalField('Temperature (°F)', 'temp_f', vitals),
          const SizedBox(height: 12),
          _buildVitalField('O2 Saturation', 'o2_sat', vitals),
          const SizedBox(height: 12),
          _buildVitalField('Pain Score (0-10)', 'pain_score', vitals),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'General Appearance',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) => _onFieldChanged(
                r'$.tab7_objective_vitals_general.general_appearance', value),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Mental Status',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) => _onFieldChanged(
                r'$.tab7_objective_vitals_general.mental_status', value),
          ),
        ],
      ),
    );
  }

  // Tab 8: Exam & Telemedicine
  Widget _buildTab8Exam() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Physical Exam & Telemedicine',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Physical Exam Findings',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            onChanged: (value) =>
                _onFieldChanged(r'$.tab8_objective_exam_telemed.physical_exam.findings', value),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Telemedicine Limitations',
              hintText:
                  'e.g., Unable to perform certain exam due to remote nature',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            onChanged: (value) => _onFieldChanged(
                r'$.tab8_objective_exam_telemed.telemedicine_limitations', value),
          ),
        ],
      ),
    );
  }

  // Tab 9: Diagnostics
  Widget _buildTab9Diagnostics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Diagnostics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildListSection(
            'Recent Labs',
            'tab9_objective_diagnostics.recent_labs',
            _localSoapData['tab9_objective_diagnostics']?['recent_labs'] ?? [],
          ),
          const SizedBox(height: 16),
          _buildListSection(
            'Imaging',
            'tab9_objective_diagnostics.imaging',
            _localSoapData['tab9_objective_diagnostics']?['imaging'] ?? [],
          ),
          const SizedBox(height: 16),
          _buildListSection(
            'External Records',
            'tab9_objective_diagnostics.external_records',
            _localSoapData['tab9_objective_diagnostics']?['external_records'] ?? [],
          ),
        ],
      ),
    );
  }

  // Tab 10: Assessment
  Widget _buildTab10Assessment() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Assessment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildListSection(
            'Problem List',
            'tab10_assessment.problem_list',
            _localSoapData['tab10_assessment']?['problem_list'] ?? [],
          ),
          const SizedBox(height: 16),
          _buildListSection(
            'Differential Diagnosis',
            'tab10_assessment.differential_diagnosis',
            _localSoapData['tab10_assessment']?['differential_diagnosis'] ?? [],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Risk/Severity',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) =>
                _onFieldChanged(r'$.tab10_assessment.risk_severity', value),
          ),
        ],
      ),
    );
  }

  // Tab 11: Plan
  Widget _buildTab11Plan() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildListSection(
            'Medications',
            'tab11_plan.medications',
            _localSoapData['tab11_plan']?['medications'] ?? [],
          ),
          const SizedBox(height: 16),
          _buildListSection(
            'Orders',
            'tab11_plan.orders',
            _localSoapData['tab11_plan']?['orders'] ?? [],
          ),
          const SizedBox(height: 16),
          _buildListSection(
            'Patient Education',
            'tab11_plan.patient_education',
            _localSoapData['tab11_plan']?['patient_education'] ?? [],
          ),
          const SizedBox(height: 16),
          _buildListSection(
            'Follow-up',
            'tab11_plan.follow_up',
            _localSoapData['tab11_plan']?['follow_up'] ?? [],
          ),
          const SizedBox(height: 16),
          _buildListSection(
            'Referrals',
            'tab11_plan.referrals',
            _localSoapData['tab11_plan']?['referrals'] ?? [],
          ),
        ],
      ),
    );
  }

  // Tab 12: MDM/Quality/Sign-off
  Widget _buildTab12SignOff() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Medical Decision Making & Sign-off',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Medical Decision Making',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            onChanged: (value) => _onFieldChanged(
                r'$.tab12_mdm_quality_attachments_signoff.medical_decision_making',
                value),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Billing Codes',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _onFieldChanged(
                r'$.tab12_mdm_quality_attachments_signoff.billing_codes', value),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Signature Date',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _onFieldChanged(
                r'$.tab12_mdm_quality_attachments_signoff.signature_date', value),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Signer Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _onFieldChanged(
                r'$.tab12_mdm_quality_attachments_signoff.signer_name', value),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Signer Credentials',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _onFieldChanged(
                r'$.tab12_mdm_quality_attachments_signoff.signer_credentials',
                value),
          ),
        ],
      ),
    );
  }

  // Helper Widgets

  Widget _buildROSField(String label, String key, Map ros) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        maxLines: 2,
        onChanged: (value) =>
            _onFieldChanged('${r'$.tab6_ros.'}$key', value),
      ),
    );
  }

  Widget _buildVitalField(String label, String key, Map vitals) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final numValue = num.tryParse(value);
        _onFieldChanged('${r'$.tab7_objective_vitals_general.vitals.'}$key', numValue ?? 0);
      },
    );
  }

  Widget _buildListSection(String title, String path, List items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                // Add new item - simplified for now
                debugPrint('TODO: Implement add $title');
              },
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text('No items added', style: TextStyle(color: Colors.grey))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (_, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        items[index].toString(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () {
                        debugPrint('TODO: Implement remove from $title');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Utility Functions

  Map<String, dynamic> _createEmptySchema() {
    return {
      'tab1_encounter_header': {
        'visit_date': '',
        'visit_type': '',
        'chief_complaint_as_written': '',
        'interpreter_needed': false,
        'identity_verified_method': '',
      },
      'tab2_patient_identification': {
        'full_name': '',
        'dob': '',
        'age': 0,
        'sex_at_birth': '',
        'emergency_contact_name': '',
        'emergency_contact_phone': '',
      },
      'tab3_cc': {
        'chief_complaint_patient_words': '',
        'primary_reason_coded': '',
      },
      'tab4_subjective_hpi': {
        'onset_date': '',
        'duration': '',
        'severity_0_10': 0,
        'progression': '',
        'associated_symptoms': [],
        'timeline': '',
      },
      'meta': {
        'schema_version': '1.0.0',
        'status': 'draft',
        'drafted_by': 'clinician',
        'ai_flags': {
          'needs_clinician_confirmation': [],
          'missing_critical_info': [],
        },
      },
    };
  }

  void _setJsonPath(Map<String, dynamic> obj, String path, dynamic value) {
    final keys = path.replaceFirst(RegExp(r'^\$\.'), '').split('.');
    dynamic current = obj;

    for (int i = 0; i < keys.length - 1; i++) {
      if (current[keys[i]] == null) {
        current[keys[i]] = {};
      }
      current = current[keys[i]];
    }

    current[keys.last] = value;
  }
}
