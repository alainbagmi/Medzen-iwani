# FlutterFlow Integration Guide - Facility Document Generation

## Step 1: Add "Generate Document" Button to Facility Page

In your FlutterFlow facility admin page, add a **Floating Action Button** (FAB):

**Properties:**
- Icon: `Icons.add_document` (or printer icon)
- Label: "Generate Document" or "Generate RMA II"
- Tooltip: "Generate facility compliance document"

---

## Step 2: Connect Button to Custom Action

When the button is pressed, execute the `generateFacilityDocument` custom action:

```dart
// Add this to button's onPressed callback
final result = await generateFacilityDocument(
  widget.facilityId,  // Current facility ID
  'RMA II 31 01 2024 ANGLAIS.pdf',  // Template path
  documentType: 'rma_ii_report',  // Document type
);

// Handle response
if (result['success'] == true) {
  // Show preview dialog
  showDialog(
    context: context,
    builder: (context) => FacilityDocumentPreviewDialog(
      documentId: result['documentId'],
      documentTitle: result['title'],
      documentVersion: result['version'],
      documentBase64: result['documentBase64'],
      aiConfidence: result['confidence'],
      aiFlags: result['flags'],
      onConfirm: (documentId) async {
        // User confirmed - save to database
        final confirmResult = await confirmFacilityDocument(documentId);
        if (confirmResult['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document confirmed and sent to print'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh document list
          _refreshDocumentList();
        }
      },
      onSaveDraft: (documentId) async {
        // User saved as draft - update status
        final saveResult = await saveFacilityDocumentDraft(documentId);
        if (saveResult['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Document saved as draft')),
          );
        }
      },
      onCancel: () {
        Navigator.of(context).pop();
      },
    ),
  );
} else {
  // Show error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: ${result['error']}'),
      backgroundColor: Colors.red,
    ),
  );
}
```

---

## Step 3: Display Document History List

Add a **ListView** to show previously generated documents:

```dart
// Query documents
FutureBuilder<Map<String, dynamic>>(
  future: listFacilityDocuments(widget.facilityId),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    final documents = snapshot.data?['documents'] ?? [];

    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No documents generated yet',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        final status = doc['status'] ?? 'unknown';
        final statusColor = status == 'confirmed' ? Colors.green : Colors.orange;
        final statusIcon = status == 'confirmed' ? Icons.check_circle : Icons.schedule;

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(statusIcon, color: statusColor),
            title: Text(doc['title'] ?? 'Untitled'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Version ${doc['version']} • ${status}'),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.assessment, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'Confidence: ${((doc['ai_confidence_score'] ?? 0.5) * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text('View Details'),
                  value: 'view',
                ),
                if (status == 'draft')
                  PopupMenuItem(
                    child: Text('Re-generate'),
                    value: 'regenerate',
                  ),
              ],
              onSelected: (value) async {
                if (value == 'view') {
                  // Fetch and show document
                  final docResult = await getFacilityDocument(doc['id']);
                  if (docResult['success'] == true) {
                    // Show details
                  }
                }
              },
            ),
          ),
        );
      },
    );
  },
)
```

---

## Step 4: Handle Multiple Templates (Optional)

If you want to support multiple document types, create a **Template Selection Dialog**:

```dart
// Show template selection
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Select Document Type'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTemplateOption(
            context,
            title: 'RMA II Report',
            description: 'Rwanda Ministry of Health compliance report',
            templatePath: 'RMA II 31 01 2024 ANGLAIS.pdf',
            onSelect: (path) => _generateDocument(path, 'rma_ii_report'),
          ),
          SizedBox(height: 8),
          _buildTemplateOption(
            context,
            title: 'Staff Roster',
            description: 'Facility staff member listing',
            templatePath: 'Staff_Roster_Template.pdf',
            onSelect: (path) => _generateDocument(path, 'staff_roster'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'),
      ),
    ],
  ),
);
```

---

## Step 5: Error Handling

Add comprehensive error handling:

```dart
Future<void> _handleGenerationError(String errorMessage) async {
  final snackBar = SnackBar(
    content: Text('Error: $errorMessage'),
    backgroundColor: Colors.red,
    duration: Duration(seconds: 5),
    action: SnackBarAction(
      label: 'Retry',
      onPressed: () {
        // Re-trigger generation
      },
    ),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
```

---

## Step 6: Loading States

Show a loading indicator during document generation:

```dart
bool _isGenerating = false;

// During generation
if (_isGenerating) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      CircularProgressIndicator(),
      SizedBox(height: 16),
      Text(
        'Generating document...',
        style: TextStyle(fontSize: 16),
      ),
    ],
  );
}

// Set state during generation
setState(() => _isGenerating = true);
final result = await generateFacilityDocument(...);
setState(() => _isGenerating = false);
```

---

## Complete Code Example

Here's a complete page implementation:

```dart
import 'package:flutter/material.dart';
import '/custom_code/actions/index.dart';
import '/custom_code/widgets/index.dart';

class FacilityDocumentPage extends StatefulWidget {
  final String facilityId;

  const FacilityDocumentPage({
    Key? key,
    required this.facilityId,
  }) : super(key: key);

  @override
  State<FacilityDocumentPage> createState() => _FacilityDocumentPageState();
}

class _FacilityDocumentPageState extends State<FacilityDocumentPage> {
  bool _isGenerating = false;
  List<dynamic> _documents = [];

  @override
  void initState() {
    super.initState();
    _refreshDocuments();
  }

  Future<void> _refreshDocuments() async {
    final result = await listFacilityDocuments(widget.facilityId);
    if (result['success'] == true) {
      setState(() {
        _documents = result['documents'] ?? [];
      });
    }
  }

  Future<void> _generateDocument() async {
    setState(() => _isGenerating = true);

    try {
      final result = await generateFacilityDocument(
        widget.facilityId,
        'RMA II 31 01 2024 ANGLAIS.pdf',
        documentType: 'rma_ii_report',
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Show preview dialog
        showDialog(
          context: context,
          builder: (context) => FacilityDocumentPreviewDialog(
            documentId: result['documentId'],
            documentTitle: result['title'],
            documentVersion: result['version'],
            documentBase64: result['documentBase64'],
            aiConfidence: result['confidence'],
            aiFlags: result['flags'],
            onConfirm: (documentId) async {
              final confirmResult = await confirmFacilityDocument(documentId);
              if (confirmResult['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Document confirmed'),
                    backgroundColor: Colors.green,
                  ),
                );
                _refreshDocuments();
              }
            },
            onSaveDraft: (documentId) async {
              final saveResult = await saveFacilityDocumentDraft(documentId);
              if (saveResult['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Draft saved')),
                );
              }
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documents'),
      ),
      body: _isGenerating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating document...'),
                ],
              ),
            )
          : _documents.isEmpty
              ? Center(
                  child: Text('No documents generated yet'),
                )
              : ListView.builder(
                  itemCount: _documents.length,
                  itemBuilder: (context, index) {
                    final doc = _documents[index];
                    return ListTile(
                      title: Text(doc['title'] ?? 'Untitled'),
                      subtitle: Text(
                        'Version ${doc['version']} • ${doc['status']}',
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isGenerating ? null : _generateDocument,
        child: Icon(Icons.add_document),
        tooltip: 'Generate Document',
      ),
    );
  }
}
```

---

## Testing Checklist

- [ ] Button appears on facility page
- [ ] Clicking button triggers document generation
- [ ] Loading state displays while generating
- [ ] Preview dialog shows PDF preview
- [ ] AI confidence score displays
- [ ] AI flags display with warnings
- [ ] "Confirm & Print" button works
- [ ] "Save Draft" button works
- [ ] Document appears in list after confirmation
- [ ] Version increments on subsequent generations
- [ ] RLS prevents non-admin access

---

## Troubleshooting

### Document Generation Fails

1. Check Firebase token: `getIdToken(true)` must be called
2. Verify facility admin permissions in `facility_admin_profiles` table
3. Check edge function logs: `npx supabase functions logs generate-facility-document --tail`
4. Verify `BEDROCK_LAMBDA_URL` is configured in Supabase

### Preview Dialog Not Showing

1. Verify `FacilityDocumentPreviewDialog` is imported correctly
2. Check PDF base64 data is valid
3. Ensure `printing` package is added to `pubspec.yaml`

### Document Not Saving

1. Verify RLS policies allow current user
2. Check `facility_generated_documents` table exists
3. Verify `confirmed_by` is being set to current user ID

---

## Next Steps

After migration is applied:

1. ✅ Database table created
2. ✅ Edge functions deployed
3. ✅ Flutter actions available
4. **→ Add UI to FlutterFlow** (this guide)
5. **→ Test in development**
6. **→ Deploy to production**
