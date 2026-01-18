// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart';
import '/custom_code/actions/index.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class SoapSectionsViewer extends StatefulWidget {
  const SoapSectionsViewer({
    super.key,
    required this.soapData,
    this.isEditable = false,
    this.onDataChanged,
  });

  final Map<String, dynamic> soapData;
  final bool isEditable;
  final Function(Map<String, dynamic>)? onDataChanged;

  @override
  State<SoapSectionsViewer> createState() => _SoapSectionsViewerState();
}

class _SoapSectionsViewerState extends State<SoapSectionsViewer>
    with TickerProviderStateMixin {
  late Map<String, dynamic> _editableData;
  late TabController _tabController;
  final Map<String, TextEditingController> _textControllers = {};
  String? _recordingSection; // Track which section is recording
  bool _isRecording = false; // Track recording state
  final Map<String, String> _cachedStringValues = {}; // Cache string conversions

  @override
  void initState() {
    super.initState();
    _editableData = Map<String, dynamic>.from(widget.soapData);
    _tabController = TabController(length: 5, vsync: this);
    _precomputeStringValues(); // Pre-cache all string conversions
  }

  @override
  void didUpdateWidget(SoapSectionsViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize _editableData if the parent's soapData changed
    // This keeps child state in sync with parent state
    if (oldWidget.soapData != widget.soapData) {
      _editableData = Map<String, dynamic>.from(widget.soapData);
      _cachedStringValues.clear(); // Invalidate cache when prop changes
      _precomputeStringValues();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Pre-compute all string conversions to avoid expensive operations during build
  void _precomputeStringValues() {
    try {
      // Associated Symptoms
      _cachedStringValues['associated_symptoms'] =
          (_editableData['subjective']?['hpi']?['associated_symptoms'] as List<dynamic>?)?.join(', ') ?? '';

      // Review of Systems
      _cachedStringValues['review_of_systems'] =
          (_editableData['subjective']?['review_of_systems'] as List<dynamic>?)?.join(', ') ?? 'No positive findings';

      // Past Medical History
      _cachedStringValues['pmh'] =
          (_editableData['subjective']?['history_items']?['pmh'] as List<dynamic>?)?.join(', ') ?? 'None documented';

      // Surgical History
      _cachedStringValues['psh'] =
          (_editableData['subjective']?['history_items']?['psh'] as List<dynamic>?)?.join(', ') ?? 'None documented';

      // Medications
      _cachedStringValues['medications'] =
          (_editableData['subjective']?['medications'] as List<dynamic>?)
              ?.map((m) {
                if (m is Map<String, dynamic>) {
                  return '${m['name']} ${m['dose'] ?? ''}'.trim();
                }
                return m.toString();
              }).join(', ') ?? 'No medications';

      // Allergies
      _cachedStringValues['allergies'] =
          (_editableData['subjective']?['allergies'] as List<dynamic>?)
              ?.map((a) {
                if (a is Map<String, dynamic>) {
                  return '${a['allergen']} - ${a['type']}'.trim();
                }
                return a.toString();
              }).join(', ') ?? 'No allergies';

      // CPT Codes
      _cachedStringValues['cpt_codes'] =
          (_editableData['coding_billing']?['cpt_codes'] as List<dynamic>?)?.join(', ') ?? '';
    } catch (e) {
      // Silently handle precompute errors
    }
  }

  /// Get cached string value or compute it
  String _getCachedStringValue(String key, String Function() compute) {
    if (!_cachedStringValues.containsKey(key)) {
      _cachedStringValues[key] = compute();
    }
    return _cachedStringValues[key]!;
  }

  void _updateData(String path, dynamic value) {
    // Update local state without rebuilding - let parent handle state via onDataChanged
    _editableData[path] = value;
    // Don't invalidate cache here - it causes unnecessary rebuilds on every keystroke
    // Let parent rebuild handle cache invalidation if needed

    // Notify parent of the change - parent will update its state and rebuild
    widget.onDataChanged?.call(_editableData);
  }

  TextEditingController _getOrCreateController(String fieldPath, String initialValue) {
    if (!_textControllers.containsKey(fieldPath)) {
      _textControllers[fieldPath] = TextEditingController(text: initialValue);
    }
    // Never update controller text during rebuilds - this causes listener cascade
    // The controller maintains its own state from user input
    return _textControllers[fieldPath]!;
  }

  Widget _buildEditableTextField(
    String label,
    String fieldPath,
    String initialValue,
    {int maxLines = 3}
  ) {
    final controller = _getOrCreateController(fieldPath, initialValue);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          enabled: widget.isEditable,
          controller: controller,
          onChanged: (value) {
            _updateData(fieldPath, value);
          },
          onTap: () {
            // Focus handler
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.all(8),
            hintText: 'Edit this field...',
            hintStyle: const TextStyle(color: Colors.grey),
            helperText: widget.isEditable ? 'Editable' : 'Read-only',
            helperStyle: TextStyle(fontSize: 11, color: Colors.grey[500]),
            filled: true,
            fillColor: widget.isEditable ? Colors.white : Colors.grey[100],
          ),
          maxLines: maxLines,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(
    String label,
    String initialValue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            initialValue.isEmpty ? 'No data' : initialValue,
            style: TextStyle(
              color: initialValue.isEmpty
                  ? Colors.grey[600]
                  : Colors.grey[900],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingButton(String sectionKey, String fieldPath) {
    // Audio recording is not supported on web platform
    if (kIsWeb) {
      return SizedBox.shrink();
    }

    final isRecordingThis = _recordingSection == sectionKey;
    return IconButton(
      icon: Icon(
        isRecordingThis ? Icons.stop_circle : Icons.mic,
        color: isRecordingThis ? Colors.red : Colors.blue,
      ),
      onPressed: (_isRecording && !isRecordingThis) ? null : () => _handleRecording(sectionKey, fieldPath),
      tooltip: isRecordingThis ? 'Stop recording' : 'Record speech',
    );
  }

  Future<void> _handleRecording(String sectionKey, String fieldPath) async {
    if (_recordingSection == sectionKey && _isRecording) {
      // Stop recording - the action will handle the stop
      setState(() {
        _isRecording = false;
        _recordingSection = null;
      });
      return;
    }

    // Start recording
    setState(() {
      _isRecording = true;
      _recordingSection = sectionKey;
    });

    try {
      final transcribedText = await recordAndTranscribeAudio(
        context,
        maxDuration: const Duration(seconds: 30),
        onRecordingStart: () {},
        onRecordingStop: () {},
        onTranscribing: (status) {},
      );

      if (transcribedText.isNotEmpty) {
        // Update the appropriate field with transcribed text
        final controller = _getOrCreateController(fieldPath, transcribedText);
        controller.text = transcribedText;
        _updateData(fieldPath, transcribedText);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Speech recorded and transcribed'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('❌ Failed to transcribe audio'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingSection = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        // Tab bar
        TabBar(
          controller: _tabController,
          isScrollable: isMobile,
          labelColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
          unselectedLabelColor: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black).withAlpha(180),
          onTap: (index) {
            // Tab changed
          },
          tabs: const [
            Tab(text: 'Subjective', icon: Icon(Icons.description)),
            Tab(text: 'Objective', icon: Icon(Icons.favorite)),
            Tab(text: 'Assessment', icon: Icon(Icons.search)),
            Tab(text: 'Plan', icon: Icon(Icons.assignment)),
            Tab(text: 'Other', icon: Icon(Icons.more)),
          ],
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            // FIX: Removed NeverScrollableScrollPhysics on web - it was blocking pointer events
            // from reaching TextFields. Use default physics which allows proper event propagation.
            physics: null,
            children: [
              // SUBJECTIVE TAB
              _buildSubjectiveTab(),
              // OBJECTIVE TAB
              _buildObjectiveTab(),
              // ASSESSMENT TAB
              _buildAssessmentTab(),
              // PLAN TAB
              _buildPlanTab(),
              // OTHER TAB
              _buildOtherTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectiveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'History of Present Illness',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.isEditable)
                _buildRecordingButton('subjective_hpi', 'subjective.hpi.narrative'),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'Chief Complaint',
              'subjective.hpi.narrative',
              _editableData['subjective']?['hpi']?['narrative'] ?? '',
              maxLines: 4,
            )
          else
            _buildReadOnlyField(
              'Chief Complaint',
              _editableData['subjective']?['hpi']?['narrative'] ?? '',
            ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'Onset & Duration',
              'subjective.hpi.onset',
              _editableData['subjective']?['hpi']?['onset'] ?? '',
            )
          else
            _buildReadOnlyField(
              'Onset & Duration',
              _editableData['subjective']?['hpi']?['onset'] ?? '',
            ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'Location & Quality',
              'subjective.hpi.location',
              _editableData['subjective']?['hpi']?['location'] ?? '',
            )
          else
            _buildReadOnlyField(
              'Location & Quality',
              _editableData['subjective']?['hpi']?['location'] ?? '',
            ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'Severity (1-10)',
              'subjective.hpi.severity',
              _editableData['subjective']?['hpi']?['severity'] ?? '',
            )
          else
            _buildReadOnlyField(
              'Severity (1-10)',
              _editableData['subjective']?['hpi']?['severity'] ?? '',
            ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'Modifying Factors',
              'subjective.hpi.modifying_factors',
              _editableData['subjective']?['hpi']?['modifying_factors'] ?? '',
            )
          else
            _buildReadOnlyField(
              'Modifying Factors',
              _editableData['subjective']?['hpi']?['modifying_factors'] ?? '',
            ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'Associated Symptoms',
              'subjective.hpi.associated_symptoms',
              _getCachedStringValue('associated_symptoms', () =>
                  (_editableData['subjective']?['hpi']?['associated_symptoms']
                          as List<dynamic>?)
                      ?.join(', ') ??
                      ''),
            )
          else
            _buildReadOnlyField(
              'Associated Symptoms',
              _getCachedStringValue('associated_symptoms', () =>
                  (_editableData['subjective']?['hpi']?['associated_symptoms']
                          as List<dynamic>?)
                      ?.join(', ') ??
                      ''),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Review of Systems',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.isEditable)
                _buildRecordingButton('subjective_ros', 'subjective.review_of_systems'),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'Positive Symptoms',
              'subjective.review_of_systems',
              _getCachedStringValue('review_of_systems', () =>
                  (_editableData['subjective']?['review_of_systems']
                          as List<dynamic>?)
                      ?.join(', ') ??
                      'No positive findings'),
              maxLines: 3,
            )
          else
            _buildReadOnlyField(
              'Positive Symptoms',
              _getCachedStringValue('review_of_systems', () =>
                  (_editableData['subjective']?['review_of_systems']
                          as List<dynamic>?)
                      ?.join(', ') ??
                      'No positive findings'),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Medical History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.isEditable)
                _buildRecordingButton('subjective_history', 'subjective.history_items.pmh'),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'Past Medical History',
              'subjective.history_items.pmh',
              _getCachedStringValue('pmh', () =>
                  (_editableData['subjective']?['history_items']?['pmh']
                          as List<dynamic>?)
                      ?.join(', ') ??
                      'None documented'),
            )
          else
            _buildReadOnlyField(
              'Past Medical History',
              _getCachedStringValue('pmh', () =>
                  (_editableData['subjective']?['history_items']?['pmh']
                          as List<dynamic>?)
                      ?.join(', ') ??
                      'None documented'),
            ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'Surgical History',
              'subjective.history_items.psh',
              _getCachedStringValue('psh', () =>
                  (_editableData['subjective']?['history_items']?['psh']
                          as List<dynamic>?)
                      ?.join(', ') ??
                      'None documented'),
            )
          else
            _buildReadOnlyField(
              'Surgical History',
              _getCachedStringValue('psh', () =>
                  (_editableData['subjective']?['history_items']?['psh']
                          as List<dynamic>?)
                      ?.join(', ') ??
                      'None documented'),
            ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'Medications',
              'subjective.medications_text',
              _getCachedStringValue('medications', () =>
                  (_editableData['subjective']?['medications'] as List<dynamic>?)
                      ?.map((m) {
                    if (m is Map<String, dynamic>) {
                      return '${m['name']} ${m['dose'] ?? ''}'.trim();
                    }
                    return m.toString();
                  }).join(', ') ??
                      'No medications'),
            )
          else
            _buildReadOnlyField(
              'Medications',
              _getCachedStringValue('medications', () =>
                  (_editableData['subjective']?['medications'] as List<dynamic>?)
                      ?.map((m) {
                    if (m is Map<String, dynamic>) {
                      return '${m['name']} ${m['dose'] ?? ''}'.trim();
                    }
                    return m.toString();
                  }).join(', ') ??
                      'No medications'),
            ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'Allergies',
              'subjective.allergies_text',
              _getCachedStringValue('allergies', () =>
                  (_editableData['subjective']?['allergies'] as List<dynamic>?)
                      ?.map((a) {
                    if (a is Map<String, dynamic>) {
                      return '${a['allergen']} - ${a['type']}'.trim();
                    }
                    return a.toString();
                  }).join(', ') ??
                      'No allergies'),
            )
          else
            _buildReadOnlyField(
              'Allergies',
              _getCachedStringValue('allergies', () =>
                  (_editableData['subjective']?['allergies'] as List<dynamic>?)
                      ?.map((a) {
                    if (a is Map<String, dynamic>) {
                      return '${a['allergen']} - ${a['type']}'.trim();
                    }
                    return a.toString();
                  }).join(', ') ??
                      'No allergies'),
            ),
        ],
      ),
    );
  }

  Widget _buildObjectiveTab() {
    final vitals = _editableData['objective']?['vital_signs'] ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vital Signs',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: [
              _buildVitalField('Temperature', 'objective.vital_signs.temperature', '${vitals['temperature'] ?? '--'}°C'),
              _buildVitalField('Blood Pressure', 'objective.vital_signs.bp', '${vitals['bp_systolic'] ?? '--'}/${vitals['bp_diastolic'] ?? '--'}'),
              _buildVitalField('Heart Rate', 'objective.vital_signs.heart_rate', '${vitals['heart_rate'] ?? '--'} bpm'),
              _buildVitalField('Respiratory Rate', 'objective.vital_signs.respiratory_rate', '${vitals['respiratory_rate'] ?? '--'} bpm'),
              _buildVitalField('SpO₂', 'objective.vital_signs.oxygen_saturation', '${vitals['oxygen_saturation'] ?? '--'}%'),
              _buildVitalField('Weight', 'objective.vital_signs.weight', '${vitals['weight'] ?? '--'} kg'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Physical Examination',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.isEditable)
                _buildRecordingButton('objective_exam', 'objective.physical_exam.general_appearance'),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'General Appearance',
              'objective.physical_exam.general_appearance',
              _editableData['objective']?['physical_exam']?['general_appearance'] ?? '',
            )
          else
            _buildReadOnlyField(
              'General Appearance',
              _editableData['objective']?['physical_exam']?['general_appearance'] ?? '',
            ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'Cardiovascular Findings',
              'objective.physical_exam.cardiovascular',
              _editableData['objective']?['physical_exam']?['cardiovascular'] ?? '',
            )
          else
            _buildReadOnlyField(
              'Cardiovascular Findings',
              _editableData['objective']?['physical_exam']?['cardiovascular'] ?? '',
            ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'Respiratory Findings',
              'objective.physical_exam.respiratory',
              _editableData['objective']?['physical_exam']?['respiratory'] ?? '',
            )
          else
            _buildReadOnlyField(
              'Respiratory Findings',
              _editableData['objective']?['physical_exam']?['respiratory'] ?? '',
            ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'Abdominal Findings',
              'objective.physical_exam.abdominal',
              _editableData['objective']?['physical_exam']?['abdominal'] ?? '',
            )
          else
            _buildReadOnlyField(
              'Abdominal Findings',
              _editableData['objective']?['physical_exam']?['abdominal'] ?? '',
            ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'Neurological Findings',
              'objective.physical_exam.neurological',
              _editableData['objective']?['physical_exam']?['neurological'] ?? '',
            )
          else
            _buildReadOnlyField(
              'Neurological Findings',
              _editableData['objective']?['physical_exam']?['neurological'] ?? '',
            ),
        ],
      ),
    );
  }

  Widget _buildVitalField(String label, String fieldPath, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAssessmentTab() {
    final problemList = _editableData['assessment']?['problem_list'] as List<dynamic>? ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assessment & Diagnosis',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.isEditable)
                _buildRecordingButton('assessment_diagnosis', 'assessment.new_diagnosis'),
            ],
          ),
          const SizedBox(height: 12),
          if (problemList.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'No diagnoses documented',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: problemList.map((problem) {
                final p = problem as Map<String, dynamic>;
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['diagnosis'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (p['icd10_code'] != null)
                        Text(
                          'Code: ${p['icd10_code']}',
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      if (p['confidence'] != null)
                        Text(
                          'Confidence: ${p['confidence']}%',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          if (widget.isEditable) ...[
            const SizedBox(height: 16),
            _buildEditableTextField(
              'Add Diagnosis',
              'assessment.new_diagnosis',
              '',
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isEditable)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Treatment Plan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildRecordingButton('plan_notes', 'plan.notes'),
              ],
            ),
          if (widget.isEditable) const SizedBox(height: 12),
          _buildPlanSection('Medications', 'medication'),
          const SizedBox(height: 16),
          _buildPlanSection('Lab Orders', 'lab'),
          const SizedBox(height: 16),
          _buildPlanSection('Follow-up', 'follow_up'),
          const SizedBox(height: 16),
          _buildPlanSection('Patient Education', 'education'),
          const SizedBox(height: 16),
          if (widget.isEditable)
            _buildEditableTextField(
              'Additional Plan Notes',
              'plan.notes',
              _editableData['plan']?['notes'] ?? '',
              maxLines: 4,
            ),
        ],
      ),
    );
  }

  Widget _buildOtherTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safety Alerts',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if ((_editableData['safety_alerts'] as List<dynamic>?)?.isNotEmpty ?? false)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (_editableData['safety_alerts'] as List<dynamic>)
                  .map((alert) {
                final a = alert as Map<String, dynamic>;
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['alert_type'] ?? 'Alert',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red[700]),
                      ),
                      if (a['description'] != null)
                        Text(
                          a['description'],
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'No safety alerts',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coding & Billing',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.isEditable)
                _buildRecordingButton('coding_billing', 'coding_billing.cpt_codes'),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'CPT Codes',
              'coding_billing.cpt_codes',
              _getCachedStringValue('cpt_codes', () =>
                  (_editableData['coding_billing']?['cpt_codes'] as List<dynamic>?)?.join(', ') ?? ''),
            )
          else
            _buildReadOnlyField(
              'CPT Codes',
              _getCachedStringValue('cpt_codes', () =>
                  (_editableData['coding_billing']?['cpt_codes'] as List<dynamic>?)?.join(', ') ?? ''),
            ),
          const SizedBox(height: 12),
          if (widget.isEditable)
            _buildEditableTextField(
              'MDM Level',
              'coding_billing.mdm_level',
              _editableData['coding_billing']?['mdm_level'] ?? '',
            )
          else
            _buildReadOnlyField(
              'MDM Level',
              _editableData['coding_billing']?['mdm_level'] ?? '',
            ),
        ],
      ),
    );
  }

  Widget _buildPlanSection(String title, String planType) {
    final items = (_editableData['plan']?[planType] as List<dynamic>?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'No $title documented',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.toString(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
