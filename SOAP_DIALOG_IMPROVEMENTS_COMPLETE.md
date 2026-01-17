# SOAP Dialog - Complete Refactoring & Improvements

## Overview
Completely refactored the Post-Call Clinical Notes Dialog (`post_call_clinical_notes_dialog.dart`) to be fully responsive, support file attachments, integrate patient biometrics, and implement proper pre-call and post-call workflows.

## Key Improvements

### 1. Responsive Design (Mobile/Tablet/Desktop)
- **Breakpoints:**
  - Mobile: < 600px
  - Tablet: 600-1200px
  - Desktop: > 1200px

- **Dynamic Sizing:**
  - Dialog width: 95% on mobile, 700px on tablet, 900px on desktop
  - Font sizes scale: 11-20px based on screen size
  - Padding scales: 12-20px based on screen size
  - Field heights scale: 40-48px based on screen size

- **Responsive Components:**
  - Biometrics section uses Wrap widget for flexible card layout
  - All text fields use proper padding and sizing
  - Action buttons wrap naturally on small screens
  - Single-scroll interface prevents overflow issues

### 2. Patient Biometrics Integration
- **Displays All Vitals:**
  - Blood Pressure (BP)
  - Heart Rate (HR)
  - Temperature (Temp)
  - Respiratory Rate (RR)
  - Oxygen Saturation (O₂Sat)
  - Weight
  - Height
  - Blood Group (BG)

- **Data Sources:**
  - Fetched from `patientBiometrics` map parameter
  - Falls back to `soapNoteData` if available
  - Displays "N/A" for missing values
  - Auto-populated in pre-call assessment

### 3. File Attachment Support
- **File Picker Integration:**
  - Supports: PDF, JPG, JPEG, PNG, DOC, DOCX
  - Uses `file_picker` package v10.1.9+

- **Upload Functionality:**
  - Uploads to `chime_storage` bucket (Supabase)
  - Path: `soap_attachments/{filename}`
  - Automatic filename generation with appointment ID and timestamp
  - Shows upload progress with spinner

- **Attachment Management:**
  - List of uploaded files with removal option
  - File paths stored in `attachments` array in SOAP note
  - Success/error notifications

- **Database Integration:**
  - Attachments stored as JSON array in `soap_notes.attachments`
  - Can be expanded to create separate attachment records if needed

### 4. Editable SOAP Fields
**Provider can edit all sections:**

**Pre-Call Assessment:**
- Chief Complaint
- History of Present Illness (HPI) - 4 lines
- Past Medical History - 3 lines
- Allergies - 2 lines

**Post-Call Sections (additional):**
- Assessment & Diagnosis - 4 lines
- Plan - 4 lines
- Medications - 3 lines
- Follow-up Instructions - 3 lines

**Voice Input:**
- Speech-to-text for each field (via mic button)
- Active listening indicator (red when recording)
- Automatic field update as provider speaks
- Supports 30 seconds of listening per field

### 5. Workflow Implementation

**Pre-Call Workflow:**
1. SOAP dialog appears before call starts
2. Provider fills in chief complaint and history
3. Biometrics auto-populated
4. Provider clicks "Proceed with Call" → Dialog closes, call starts
5. Provider clicks "Cancel Call" → Ends both SOAP and call

**Post-Call Workflow:**
1. When call ends, SOAP dialog reappears
2. Fields populated with transcription and existing data
3. Provider completes assessment, plan, medications
4. Provider can add attachments (documents, images)
5. Provider clicks "Sign & Submit" → SOAP saved with `is_signed=true`
6. Provider clicks "Cancel" → Discards notes

### 6. Database Integration

**SOAP Notes Table Schema:**
```
- id (UUID, primary key)
- appointment_id (FK)
- patient_id (FK)
- provider_id (FK)
- video_session_id (FK)
- encounter_date (timestamp)
- chief_complaint (text)
- hpi_narrative (text)
- past_medical_history (text)
- allergies (text)
- blood_pressure (text)
- heart_rate (text)
- temperature (text)
- respiratory_rate (text)
- oxygen_saturation (text)
- weight (text)
- height (text)
- blood_group (text)
- assessment (text)
- plan (text)
- medications (text)
- follow_up_instructions (text)
- attachments (jsonb array of file paths)
- is_signed (boolean)
- created_at (timestamp)
- updated_at (timestamp)
```

**Operations:**
- Insert new SOAP note if `soapNoteId` is null
- Update existing SOAP note if `soapNoteId` provided
- Sign sets `is_signed = true` on update

### 7. Speech-to-Text Integration
- Uses `speech_to_text` package v7.3.0
- 30-second listening window per field
- 3-second pause detection
- Appends recognized text to current field
- Real-time field updates

### 8. Widget Parameters

**Constructor:**
```dart
PostCallClinicalNotesDialog({
  String? sessionId,           // Video session ID
  String? appointmentId,       // Appointment reference
  String? patientId,           // Patient reference
  String? providerId,          // Provider reference
  String? patientName,         // Display name
  String? soapNoteId,          // For update operations
  Map<String, dynamic>? soapNoteData,  // Pre-fill data
  String? transcript,          // Auto-populate HPI
  bool isPreCall = false,      // Pre/post-call mode
  Function()? onSaved,         // Callback when saved
  Function()? onDiscarded,     // Callback when discarded
  Function(bool proceed)? onPreCallAction,  // Pre-call proceed/cancel
  Map<String, dynamic>? patientBiometrics,  // Vitals data
})
```

### 9. Error Handling
- Try-catch blocks for all async operations
- BuildContext safety with `mounted` checks
- User-friendly error notifications
- File upload error handling
- Database operation error handling

### 10. Code Quality
- Fixed all lint warnings (async gaps, const constructors, etc.)
- Proper resource cleanup (dispose of TextEditingControllers)
- Efficient state management
- No unused imports
- Consistent naming conventions

## Testing Checklist

- [ ] Build compiles without errors
- [ ] Dialog displays on mobile (< 600px width)
- [ ] Dialog displays on tablet (600-1200px)
- [ ] Dialog displays on desktop (> 1200px)
- [ ] Biometrics display correctly
- [ ] File picker launches and selects files
- [ ] Files upload to Supabase storage
- [ ] Speech-to-text activates with mic button
- [ ] Text fields update from voice input
- [ ] All SOAP fields are editable
- [ ] Pre-call workflow works (Proceed/Cancel)
- [ ] Post-call workflow works (Sign & Submit/Cancel)
- [ ] Attachments list displays properly
- [ ] Attachments can be removed
- [ ] SOAP data saves to database
- [ ] Dialog closes after save
- [ ] Callbacks execute properly
- [ ] No crashes on screen rotation
- [ ] Responsive on all tested devices

## Files Modified
- `lib/custom_code/widgets/post_call_clinical_notes_dialog.dart` - Complete rewrite

## Dependencies Added/Updated
- `file_picker: ^10.1.9` (already in pubspec.yaml)
- `speech_to_text: ^7.3.0` (already updated)
- `supabase_flutter: ^2.9.0` (already in pubspec.yaml)

## Integration Points

**From `join_room.dart`:**
- Called after video call ends
- Passes session ID, appointment data, transcript
- Receives onSaved/onDiscarded callbacks
- Dialog manages its own lifecycle

**Database Tables:**
- `soap_notes` - Clinical note records
- `chime_storage` bucket - File attachments

**API Endpoints:**
- Supabase Storage: File upload/download
- Supabase Database: CRUD operations on soap_notes

## Next Steps
1. Run build and verify compilation
2. Test on Android emulator
3. Test on iOS simulator
4. Test web platform
5. Verify file attachments save properly
6. Confirm biometrics populate correctly
7. Test speech-to-text on all platforms
8. Verify database persistence

## Known Limitations
- Speech-to-text may require permissions on Android/iOS
- File uploads depend on internet connectivity
- Large files may take time to upload (show progress spinner)
- Audio recording requires device permissions

## Future Enhancements
- Add signature capture for provider sign-off
- Implement SOAP template presets
- Add calculation of BMI from height/weight
- Support for physical exam images
- Clinical note PDF export
- Integration with EHRbase for OpenEHR sync
