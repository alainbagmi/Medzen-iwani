# Facility Document Generation System

## Overview

The Facility Document Generation System enables facility admins to generate AI-prefilled administrative documents (like RMA II compliance reports) from facility data stored in the database.

**Workflow:**
1. Admin clicks "Generate Document" → selects template (from `MiniSanteTemplate` bucket)
2. System fetches PDF template + facility data from database
3. AI (AWS Bedrock) analyzes PDF and determines field mappings
4. PDF returned to user for preview
5. User confirms/edits data
6. User saves to database and/or prints

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ Facility Admin UI (FlutterFlow Page)                           │
│ • Generate Document Button                                      │
│ • Template Selection Dialog                                     │
│ • Document History List                                         │
└──────────────────────┬──────────────────────────────────────────┘
                       │ generateFacilityDocument()
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│ Edge Function: generate-facility-document                       │
│ • Verify Firebase auth                                          │
│ • Check facility admin access                                   │
│ • Fetch facility data (from facilities table)                   │
│ • Download PDF template (from MiniSanteTemplate bucket)         │
│ • Call Bedrock AI for field mapping analysis                    │
│ • Create draft record in facility_generated_documents table     │
│ • Return base64 PDF + metadata                                  │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│ FacilityDocumentPreviewDialog (Flutter Widget)                  │
│ • Display PDF preview (PdfPreview widget)                       │
│ • Show facility data used for prefill                           │
│ • Display AI confidence score + flags                           │
│ • Action buttons: Cancel | Save Draft | Confirm & Print        │
└──────────────────────┬──────────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
   Cancel         Save Draft    Confirm & Print
        │              │              │
        ▼              ▼              ▼
    Close      Draft Status     Confirmed Status
             (Can re-edit)      (Ready for signature)
```

---

## Files Created

### 1. Database Migration
**File:** `supabase/migrations/20260122120000_create_facility_document_generation.sql`

**Tables:**
- `facility_generated_documents` - Tracks all generated documents with versioning

**Key Columns:**
- `id` - Unique document ID
- `facility_id` - Reference to facility
- `document_type` - Type of document (rma_ii_report, staff_roster, etc.)
- `template_path` - Path in MiniSanteTemplate bucket
- `status` - draft/preview/confirmed/saved
- `version` - Document version number
- `ai_prefill_data` - JSON with facility data used for prefilling
- `ai_confidence_score` - 0.0-1.0 confidence score
- `ai_flags` - Array of missing/flagged fields
- `confirmed_by` - User who confirmed
- `confirmed_at` - Timestamp of confirmation

### 2. Edge Function
**File:** `supabase/functions/generate-facility-document/index.ts`

**Responsibilities:**
1. Verify Firebase JWT token
2. Check facility admin permissions
3. Fetch facility data from `facilities` table
4. Download PDF template from `MiniSanteTemplate` bucket
5. Call AWS Bedrock to analyze PDF structure
6. Create draft record in `facility_generated_documents` table
7. Return base64-encoded PDF + metadata

**Environment Variables Needed:**
- `BEDROCK_LAMBDA_URL` - AWS Lambda endpoint for Bedrock calls

### 3. Flutter Custom Actions

#### a. `generateFacilityDocument()`
**File:** `lib/custom_code/actions/generate_facility_document.dart`

Initiates document generation with retry logic.

**Parameters:**
- `facilityId` (String, required) - Facility ID
- `templatePath` (String, required) - Path to PDF in MiniSanteTemplate bucket
- `documentType` (String, optional) - Type of document

**Returns:**
```dart
{
  'success': bool,
  'error': String?, // if failed
  'document': {
    'id': String,
    'documentBase64': String, // base64 PDF
    'title': String,
    'version': int,
    'status': String,
    'aiConfidence': double,
    'aiFlags': List,
    'createdAt': String,
  }
}
```

#### b. `confirmFacilityDocument()`
**File:** `lib/custom_code/actions/confirm_facility_document.dart`

Updates document status to 'confirmed' after user review.

**Parameters:**
- `documentId` (String, required)
- `confirmationNotes` (String, optional)

**Returns:**
```dart
{
  'success': bool,
  'error': String?,
  'message': String,
}
```

#### c. `saveFacilityDocumentDraft()`
Saves document as draft for later editing.

**Parameters:**
- `documentId` (String, required)
- `notes` (String, optional)

#### d. `getFacilityDocument()`
Retrieves a single document record.

#### e. `listFacilityDocuments()`
Lists documents for a facility with optional filtering.

**Parameters:**
- `facilityId` (String, required)
- `documentType` (String, optional)
- `status` (String, optional)
- `limit` (int, default: 20)

### 4. Flutter Widgets

#### `FacilityDocumentPreviewDialog`
**File:** `lib/custom_code/widgets/facility_document_preview_dialog.dart`

**Features:**
- PDF preview viewer (left panel)
- Facility data display (right panel)
- AI confidence score with progress bar
- AI flags/warnings display
- Action buttons: Cancel, Save Draft, Confirm & Print

**Usage:**
```dart
showDialog(
  context: context,
  builder: (context) => FacilityDocumentPreviewDialog(
    documentId: documentData['id'],
    documentTitle: documentData['title'],
    documentVersion: documentData['version'],
    documentBase64: documentData['documentBase64'],
    aiConfidence: documentData['aiConfidence'],
    aiFlags: documentData['aiFlags'],
    facilityData: facilityData,
    onConfirm: (documentId) {
      // Handle confirmation
      confirmFacilityDocument(documentId);
    },
    onSaveDraft: (documentId) {
      // Handle save draft
      saveFacilityDocumentDraft(documentId);
    },
    onCancel: () {
      // Handle cancellation
    },
  ),
);
```

---

## How to Use in FlutterFlow Pages

### Step 1: Add "Generate Document" Button

In your facility admin page, add a button:

```dart
FloatingActionButton(
  onPressed: () async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Loading templates...')),
    );

    // List available templates from MiniSanteTemplate bucket
    // For now, we'll hardcode the RMA II template
    final templatePath = 'RMA II 31 01 2024 ANGLAIS.pdf';

    // Call document generation action
    final result = await generateFacilityDocument(
      widget.facilityId,
      templatePath,
      documentType: 'rma_ii_report',
    );

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
          facilityData: null, // Optional: pass facility data for display
          onConfirm: (documentId) async {
            final confirmResult = await confirmFacilityDocument(documentId);
            if (confirmResult['success'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Document confirmed and printed'),
                  backgroundColor: Colors.green,
                ),
              );
              // Refresh document list
              _refreshDocumentList();
            }
          },
          onSaveDraft: (documentId) async {
            final saveResult = await saveFacilityDocumentDraft(documentId);
            if (saveResult['success'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Document saved as draft')),
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
  },
  child: Icon(Icons.add_document),
  tooltip: 'Generate Document',
);
```

### Step 2: Display Document List

Query the `facility_generated_documents` table:

```dart
// In your widget
final documentsSnapshot = await SupaFlow.client
    .from('facility_generated_documents')
    .select()
    .eq('facility_id', widget.facilityId)
    .order('created_at', ascending: false);

// Build list view
ListView.builder(
  itemCount: documentsSnapshot.length,
  itemBuilder: (context, index) {
    final doc = documentsSnapshot[index];
    return ListTile(
      title: Text(doc['title']),
      subtitle: Text('Version ${doc['version']} • ${doc['status']}'),
      trailing: Icon(
        doc['status'] == 'confirmed' ? Icons.check_circle : Icons.schedule,
        color: doc['status'] == 'confirmed' ? Colors.green : Colors.orange,
      ),
      onTap: () {
        // Re-open document or view details
      },
    );
  },
);
```

### Step 3: Add Custom Action to FlutterFlow Page

1. Go to FlutterFlow page editor
2. Add Custom Action → Select `generateFacilityDocument`
3. Pass facility_id and template_path as parameters
4. Handle response in action output

---

## Database Schema

### `facility_generated_documents` Table

```sql
id UUID PRIMARY KEY
facility_id UUID (FK -> facilities)
document_type VARCHAR(100) -- 'rma_ii_report', etc.
template_path TEXT -- Path in MiniSanteTemplate bucket
title VARCHAR(255) -- Display title
file_path TEXT -- (Future) path if saved to user storage
file_size BIGINT
version INTEGER -- Version number for this document type
status VARCHAR(50) -- 'draft', 'preview', 'confirmed', 'saved'
ai_prefill_data JSONB -- Facility data used for AI analysis
ai_confidence_score DECIMAL(3,2) -- 0.0-1.0
ai_flags JSONB -- Array of missing/flagged fields
generated_by UUID (FK -> users)
generated_at TIMESTAMPTZ
confirmed_by UUID (FK -> users)
confirmed_at TIMESTAMPTZ
confirmation_notes TEXT
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

**Indexes:**
- `idx_facility_generated_documents_facility` - For fast facility lookups
- `idx_facility_generated_documents_status` - For filtering by status
- `idx_unique_facility_document_draft` - Ensure one draft per facility per day

**RLS Policies:**
- Facility admins can view their facility's documents
- Facility admins can update their facility's documents
- Service role can manage all documents

---

## AI Confidence Scoring

The AI analyzes the PDF template and determines confidence in field mappings:

**Score Range:** 0.0 - 1.0

**Interpretation:**
- **≥ 0.8 (80%)**: High confidence - minimal review needed
- **0.6-0.79**: Moderate confidence - review recommended
- **< 0.6**: Low confidence - thorough review required

**Calculation:**
- Base: 0.85 (AI default)
- Penalty: -0.05 per high-complexity field
- Penalty: -0.1 per missing field
- Floor: 0.5 (minimum confidence score)

**User Impact:**
- High confidence: Display green indicator, "Ready to confirm"
- Moderate confidence: Display yellow warning, "Review recommended"
- Low confidence: Display red warning, "Requires manual verification"

---

## AI Flags

The AI flags potential issues with field mappings:

**Common Flags:**
```
[
  "Address field not found in PDF",
  "Registration number field unclear",
  "Contact information incomplete in database"
]
```

**User Action:**
- Review flagged fields before confirming
- Manually correct data if needed
- Confirm document once satisfied

---

## PDF Templates

### Currently Available

**Location:** `MiniSanteTemplate` bucket (public Supabase storage)

**Available Templates:**
1. `RMA II 31 01 2024 ANGLAIS.pdf` - RMA II compliance report (English)
2. `RMA II 31 01 2024 FRANCAIS.pdf` - RMA II compliance report (French)
3. Additional templates can be added to bucket

### Adding New Templates

1. Upload PDF to `MiniSanteTemplate` bucket in Supabase
2. Note the exact file path
3. Use that path in `generateFacilityDocument()` call

---

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `INVALID_FIREBASE_TOKEN` | Token expired or invalid | Force refresh token with `getIdToken(true)` |
| `INSUFFICIENT_PERMISSIONS` | User not facility admin | Verify user role in `facility_admin_profiles` |
| `FACILITY_NOT_FOUND` | Facility ID incorrect | Check facility exists in `facilities` table |
| `TEMPLATE_NOT_FOUND` | Template path incorrect | Verify file exists in `MiniSanteTemplate` bucket |
| `BEDROCK_UNAVAILABLE` | AI service error | Check `BEDROCK_LAMBDA_URL` is configured |
| `DB_INSERT_FAILED` | Database error | Check RLS policies and facility_generated_documents table |

---

## Future Enhancements

1. **Actual PDF Field Filling** - Fill form fields programmatically using pdf-lib
2. **Custom Template Upload** - Allow facility admins to upload custom templates
3. **Multi-Language Support** - Auto-detect facility language for template selection
4. **Batch Generation** - Generate reports for multiple facilities simultaneously
5. **Approval Workflow** - Add second-level review/approval step
6. **E-Signatures** - Integrate DocuSign/HelloSign for signing
7. **Export Formats** - Support DOCX, XLSX, CSV in addition to PDF
8. **Scheduled Reports** - Auto-generate monthly/quarterly reports
9. **Template Library** - Built-in templates for common documents

---

## Testing

### Unit Test Template

```dart
// Test document generation
test('Generate facility document', () async {
  final facilityId = 'test-facility-id';
  final templatePath = 'RMA II 31 01 2024 ANGLAIS.pdf';

  final result = await generateFacilityDocument(
    facilityId,
    templatePath,
    documentType: 'rma_ii_report',
  );

  expect(result['success'], equals(true));
  expect(result['document'], isNotNull);
  expect(result['document']['documentBase64'], isNotEmpty);
  expect(result['document']['aiConfidence'], isGreaterThan(0.5));
});

// Test document confirmation
test('Confirm facility document', () async {
  final documentId = 'test-document-id';

  final result = await confirmFacilityDocument(documentId);

  expect(result['success'], equals(true));
  expect(result['message'], contains('confirmed'));
});
```

### Manual Testing Checklist

- [ ] Facility admin can initiate document generation
- [ ] Correct facility data displayed in preview
- [ ] PDF renders in preview dialog
- [ ] AI confidence score displays correctly
- [ ] AI flags display with warnings
- [ ] User can save as draft
- [ ] User can confirm and print
- [ ] Document saved with correct status in database
- [ ] Version number increments on subsequent generations
- [ ] RLS policies prevent unauthorized access

---

## Support & Troubleshooting

### Enable Debug Logging

Add `flutter run -v` to see verbose logs:

```
[generateFacilityDocument] Starting for facility: facility-123
[generateFacilityDocument] Starting for facility: facility-123
[generate-facility-document] Fetched facility: MedZen Clinic
[generate-facility-document] Downloading template: RMA II...
[generate-facility-document] Calling Bedrock to analyze PDF structure
[generate-facility-document] Document created: doc-456
```

### Check Supabase Logs

```bash
# Watch edge function logs
npx supabase functions logs generate-facility-document --tail
```

### Verify Permissions

Check RLS policies in Supabase dashboard:
- `facility_admin_profiles` - Verify user has facility access
- `facility_generated_documents` - Verify policies allow SELECT/UPDATE

---

## Dependencies

### Flutter Packages

```yaml
# pubspec.yaml
firebase_auth: ^latest
http: ^latest
printing: ^latest
pdf: ^latest
```

### Supabase

- Edge Functions v1
- Storage (MiniSanteTemplate bucket)
- PostgreSQL database

### AWS

- Bedrock (Claude 3.5 Sonnet model)
- Lambda function for Bedrock integration

---

## Security Notes

1. **Authentication** - Always verify Firebase JWT token in edge function
2. **RLS Policies** - Ensure facility admins can only access their facilities' documents
3. **PDF Storage** - Consider adding encryption for stored PDFs
4. **Rate Limiting** - Consider rate limiting document generation requests
5. **Audit Trail** - `generated_by`, `confirmed_by`, timestamps tracked for compliance

---

## API Reference

### Edge Function: `generate-facility-document`

**Endpoint:** `POST /functions/v1/generate-facility-document`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer {supabaseAnonKey}
apikey: {supabaseAnonKey}
x-firebase-token: {firebaseIdToken}  (lowercase!)
```

**Request Body:**
```json
{
  "facilityId": "facility-uuid",
  "templatePath": "RMA II 31 01 2024 ANGLAIS.pdf",
  "documentType": "rma_ii_report"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "document": {
    "id": "document-uuid",
    "documentBase64": "JVBERi0xLjQK...",
    "title": "RMA II Report - MedZen Clinic",
    "version": 1,
    "status": "preview",
    "aiConfidence": 0.87,
    "aiFlags": [],
    "createdAt": "2026-01-22T10:30:00Z"
  }
}
```

**Error Responses:**
- `401` - INVALID_FIREBASE_TOKEN
- `403` - INSUFFICIENT_PERMISSIONS
- `404` - FACILITY_NOT_FOUND or TEMPLATE_NOT_FOUND
- `500` - Internal error

---

## Changelog

### v1.0.0 (2026-01-22)
- Initial release
- Document generation with AI prefill
- PDF preview dialog
- Draft saving
- Document confirmation and printing
- Facility admin access control
- AI confidence scoring and flags
