import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Preview dialog for AI-generated facility documents
///
/// Displays:
/// - PDF preview viewer
/// - Facility data used for prefill
/// - AI confidence score and flags
/// - Action buttons: Cancel, Save Draft, Confirm & Print

class FacilityDocumentPreviewDialog extends StatefulWidget {
  final String documentId;
  final String documentTitle;
  final int documentVersion;
  final String documentBase64; // Base64-encoded PDF
  final double aiConfidence;
  final List<dynamic>? aiFlags;
  final Map<String, dynamic>? facilityData;

  // Callbacks
  final Function(String documentId) onConfirm;
  final Function(String documentId)? onSaveDraft;
  final Function()? onCancel;

  const FacilityDocumentPreviewDialog({
    Key? key,
    required this.documentId,
    required this.documentTitle,
    required this.documentVersion,
    required this.documentBase64,
    required this.aiConfidence,
    this.aiFlags,
    this.facilityData,
    required this.onConfirm,
    this.onSaveDraft,
    this.onCancel,
  }) : super(key: key);

  @override
  State<FacilityDocumentPreviewDialog> createState() =>
      _FacilityDocumentPreviewDialogState();
}

class _FacilityDocumentPreviewDialogState
    extends State<FacilityDocumentPreviewDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 8 : 16),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            // Content
            Expanded(
              child: Row(
                children: [
                  // PDF Viewer (left)
                  Expanded(
                    flex: 3,
                    child: _buildPdfViewer(),
                  ),
                  // Info Panel (right) - only on larger screens
                  if (!isMobile)
                    Expanded(
                      flex: 1,
                      child: _buildInfoPanel(),
                    ),
                ],
              ),
            ),
            // Footer with actions
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.documentTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 4),
              Text(
                'Version ${widget.documentVersion}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              widget.onCancel?.call();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    if (widget.documentBase64.isEmpty) {
      return Center(
        child: Text('No PDF content available'),
      );
    }

    return PdfPreview(
      build: (format) async {
        // Decode base64 PDF
        final bytes = _base64Decode(widget.documentBase64);
        return bytes;
      },
      canChangePageFormat: false,
      canDebug: false,
      allowSharing: false,
    );
  }

  Widget _buildInfoPanel() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Confidence Score
          _buildConfidenceCard(),
          SizedBox(height: 16),
          // AI Flags
          if (widget.aiFlags != null && widget.aiFlags!.isNotEmpty)
            _buildFlagsCard(),
          SizedBox(height: 16),
          // Facility Data
          if (widget.facilityData != null) _buildFacilityDataCard(),
        ],
      ),
    );
  }

  Widget _buildConfidenceCard() {
    final confidence = widget.aiConfidence;
    final Color confidenceColor = confidence >= 0.8
        ? Colors.green
        : confidence >= 0.6
            ? Colors.orange
            : Colors.red;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Confidence',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: confidence,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(confidenceColor),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '${(confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: confidenceColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              confidence >= 0.8
                  ? 'High confidence - minimal review needed'
                  : confidence >= 0.6
                      ? 'Moderate confidence - review recommended'
                      : 'Low confidence - thorough review required',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagsCard() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  'Issues Found',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            ...widget.aiFlags!.map((flag) {
              final flagText = flag is String ? flag : flag.toString();
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Text(
                        flagText,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityDataCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Facility Data',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ..._buildFacilityDataFields(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFacilityDataFields() {
    final data = widget.facilityData ?? {};
    final List<Widget> fields = [];

    // Display key facility fields
    final displayFields = ['name', 'facility_type', 'address', 'city', 'phone', 'email'];

    for (final field in displayFields) {
      final value = data[field];
      if (value != null && value.toString().isNotEmpty) {
        fields.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                Text(
                  value.toString(),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }
    }

    return fields.isEmpty
        ? [Text('No facility data available', style: TextStyle(fontSize: 12))]
        : fields;
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    widget.onCancel?.call();
                    Navigator.of(context).pop();
                  },
            child: Text('Cancel'),
          ),
          SizedBox(width: 8),
          if (widget.onSaveDraft != null)
            OutlinedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      try {
                        widget.onSaveDraft!(widget.documentId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Document saved as draft')),
                        );
                        Navigator.of(context).pop();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error saving draft: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    },
              child: Text('Save Draft'),
            ),
          SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() => _isLoading = true);
                    try {
                      // Decode and print PDF
                      final bytes = _base64Decode(widget.documentBase64);
                      await Printing.layoutPdf(
                        onLayout: (_) => bytes,
                      );

                      // Confirm document
                      widget.onConfirm(widget.documentId);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Document confirmed')),
                      );
                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
            icon: Icon(Icons.print),
            label: Text('Confirm & Print'),
          ),
        ],
      ),
    );
  }
}

// Helper function to decode base64
Uint8List _base64Decode(String input) {
  try {
    final replacedInput = input.replaceAll('-', '+').replaceAll('_', '/');
    final normalisedInput = replacedInput + '=' * (4 - replacedInput.length % 4);
    return Uint8List.fromList(
      base64.decode(normalisedInput) as List<int>,
    );
  } catch (e) {
    print('[FacilityDocumentPreviewDialog] Base64 decode error: $e');
    return Uint8List(0);
  }
}
