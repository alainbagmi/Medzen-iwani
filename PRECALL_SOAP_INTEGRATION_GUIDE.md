# Pre-Call SOAP Dialog Integration Guide

## Overview
The pre-call SOAP workflow needs to be integrated into `join_room.dart` to show the SOAP clinical notes dialog BEFORE the video call starts.

## Current State
✅ **Implemented**: Post-call SOAP dialog (lines 720-745 in join_room.dart)
❌ **Missing**: Pre-call SOAP dialog

## Required Integration

### Location in Code
**File**: `lib/custom_code/actions/join_room.dart`
**Line**: Around line 640-645, BEFORE the Navigator.push to ChimeMeetingEnhanced

### Current Code Structure (lines 640-650)
```dart
// Navigate to Chime video call page
if (context.mounted) {
  debugPrint('🔍 CALLING Navigator.push');

  // Pause session timeout during video call
  _setVideoCallState(true);

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) {
        // ChimeMeetingEnhanced widget...
```

### Required Changes

#### Step 1: Add Pre-Call SOAP Dialog BEFORE Navigator.push

Insert this code block BEFORE `_setVideoCallState(true);` (around line 644):

```dart
// Show pre-call SOAP dialog for provider
if (isProvider && context.mounted) {
  debugPrint('🔍 Showing pre-call SOAP dialog for provider');

  bool proceedWithCall = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Center(
      child: PostCallClinicalNotesDialog(
        sessionId: sessionId,
        appointmentId: appointmentId,
        providerId: providerId,
        patientId: patientId,
        patientName: patientName ?? 'Patient',
        isPreCall: true, // IMPORTANT: Pre-call mode
        onPreCallAction: (proceed) {
          debugPrint('Pre-call action: proceed=$proceed');
          proceedWithCall = proceed;
          Navigator.of(dialogContext).pop();
        },
      ),
    ),
  );

  // If provider cancelled, abort the entire call
  if (!proceedWithCall) {
    debugPrint('❌ Provider cancelled pre-call SOAP assessment');
    debugPrint('Aborting video call');
    // Notify user
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video call cancelled - SOAP assessment required'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return; // Exit the entire joinRoom function
  }
}

// For patients: skip pre-call SOAP, go directly to call
if (!isProvider && context.mounted) {
  debugPrint('🔍 Patient joining call - skipping pre-call SOAP');
}
```

#### Step 2: Retrieve Existing SOAP Data (if available)

Add this BEFORE the pre-call dialog (around line 600, with other data retrieval):

```dart
// Fetch existing SOAP note for this appointment (if any)
String? soapNoteId;
Map<String, dynamic>? soapNoteData;
Map<String, dynamic>? patientBiometrics;

try {
  // Check if SOAP note exists for this appointment
  final soapNotes = await SupaFlow.client
      .from('soap_notes')
      .select()
      .eq('appointment_id', appointmentId!)
      .order('created_at', ascending: false)
      .limit(1);

  if (soapNotes.isNotEmpty) {
    soapNoteId = soapNotes[0]['id'];
    soapNoteData = soapNotes[0];
    debugPrint('✓ Found existing SOAP note: $soapNoteId');
  }

  // Fetch patient biometrics
  final patientProfile = await SupaFlow.client
      .from('patient_profiles')
      .select()
      .eq('user_id', patientId!)
      .single();

  if (patientProfile != null) {
    patientBiometrics = {
      'bloodPressure': patientProfile['blood_pressure'],
      'heartRate': patientProfile['heart_rate'],
      'temperature': patientProfile['temperature'],
      'respiratoryRate': patientProfile['respiratory_rate'],
      'oxygenSaturation': patientProfile['oxygen_saturation'],
      'weight': patientProfile['weight'],
      'height': patientProfile['height'],
      'bloodGroup': patientProfile['blood_group'],
    };
    debugPrint('✓ Fetched patient biometrics');
  }
} catch (e) {
  debugPrint('⚠️ Error fetching SOAP/biometrics data: $e');
  // Continue without existing data - not a blocker
}
```

#### Step 3: Pass SOAP Data to Post-Call Dialog

Update the post-call dialog instantiation (lines 726-743) to include:

```dart
child: PostCallClinicalNotesDialog(
  sessionId: sessionId!,
  appointmentId: appointmentId,
  providerId: providerId,
  patientId: patientId,
  patientName: patientName ?? 'Patient',
  soapNoteId: soapNoteId,              // From pre-call retrieval
  soapNoteData: soapNoteData,          // From pre-call retrieval
  patientBiometrics: patientBiometrics,// From pre-call retrieval
  transcript: transcript,
  isPreCall: false,                     // Post-call mode
  onSaved: () {
    debugPrint('✅ Provider saved SOAP note');
    Navigator.of(dialogContext).pop();
  },
  onDiscarded: () {
    debugPrint('❌ Provider discarded SOAP note');
    Navigator.of(dialogContext).pop();
  },
),
```

## Execution Flow (After Integration)

### For Medical Providers
1. Provider initiates video call
2. ↓ `joinRoom()` called with `isProvider=true`
3. ↓ Fetch appointment data + existing SOAP + biometrics
4. ↓ **Show pre-call SOAP dialog** (NEW)
5. → Provider enters: Chief Complaint, HPI, History, Allergies
6. → Biometrics auto-display
7. → Provider clicks "Proceed with Call"
8. ↓ Dialog closes, SOAP draft saved
9. ↓ ChimeMeetingEnhanced opens
10. ↓ Video call proceeds
11. ↓ Call ends
12. ↓ **Show post-call SOAP dialog**
13. → Fields pre-populated (chief complaint, history, biometrics)
14. → HPI populated with transcription
15. → Provider completes: Assessment, Plan, Medications, Follow-up
16. → Provider attaches files (optional)
17. → Provider clicks "Sign & Submit"
18. ↓ SOAP note saved with `is_signed=true`
19. → Dialog closes

### For Patients
1. Patient initiates video call
2. ↓ `joinRoom()` called with `isProvider=false`
3. ↓ Skip pre-call SOAP (patients don't need to fill SOAP)
4. ↓ ChimeMeetingEnhanced opens directly
5. ↓ Video call proceeds normally
6. ↓ Call ends
7. ↓ No post-call SOAP dialog for patient

## Key Implementation Points

### 1. onPreCallAction Callback
The pre-call dialog uses `onPreCallAction(bool proceed)` callback:
- `proceed=true` → Provider approved pre-call assessment → Continue to video call
- `proceed=false` → Provider cancelled → Abort entire `joinRoom()` function

### 2. SOAP Note Lifecycle
- **Pre-call**: Creates draft SOAP note with pre-call sections only
- **Post-call**: Updates same SOAP note with post-call sections
- **Signing**: Sets `is_signed=true` on final save

### 3. Context Safety
All dialogs and navigations use `context.mounted` checks to prevent crashes

### 4. Error Handling
Graceful fallbacks if SOAP/biometrics data unavailable:
- If no existing SOAP: Creates new note
- If no biometrics: Displays "N/A" instead of crashing
- If SOAP fetch fails: Continues without it (not a blocker)

### 5. Provider-Only Feature
Pre-call SOAP is only shown to providers (`isProvider=true`):
- Patients skip directly to video call
- Reduces friction for patient user experience

## Testing Checklist

### Pre-Call Workflow
- [ ] Build compiles without errors
- [ ] Provider initiates video call
- [ ] Pre-call SOAP dialog appears (provider)
- [ ] Patient skips SOAP, joins call directly
- [ ] Provider can edit all pre-call fields
- [ ] Biometrics display correctly
- [ ] Speech-to-text works for each field
- [ ] File attachments can be added (optional pre-call)
- [ ] "Proceed with Call" button closes dialog and starts call
- [ ] "Cancel Call" button aborts entire call
- [ ] SOAP draft data persists when "Proceed" clicked
- [ ] Transcription populates HPI field in post-call

### Post-Call Workflow
- [ ] SOAP dialog reappears after call ends
- [ ] Pre-call data still present (chief complaint, history, biometrics)
- [ ] Transcription visible in HPI
- [ ] Provider can complete assessment/plan/medications
- [ ] Can add file attachments
- [ ] "Sign & Submit" saves with `is_signed=true`
- [ ] "Cancel" discards post-call additions

### Responsive Design
- [ ] Dialog displays correctly on mobile (< 600px)
- [ ] Dialog displays correctly on tablet (600-1200px)
- [ ] Dialog displays correctly on desktop (> 1200px)
- [ ] Responsive on landscape orientation

## Code Dependencies

### Imports (already in post_call_clinical_notes_dialog.dart)
```dart
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;
import 'dart:io';
```

### Database Requirements
- `soap_notes` table (for insert/update)
- `patient_profiles` table (for biometrics)
- `chime_storage` bucket (for file attachments)

### Supabase Client
- Already initialized in `join_room.dart` via `SupaFlow.client`

## Migration Path

### Phase 1 (Current)
- Post-call SOAP dialog ✅ DONE
- Widget fully responsive ✅ DONE
- File attachments ✅ DONE
- Speech-to-text ✅ DONE
- Biometrics display ✅ DONE

### Phase 2 (This Integration)
- Add pre-call SOAP dialog ← **You are here**
- Provider must approve before call starts
- Patient skips SOAP (direct to call)

### Phase 3 (Future Enhancement)
- SOAP templates for common chief complaints
- Clinical decision support during assessment
- Integration with EHRbase for OpenEHR sync
- SOAP PDF export for medical records

## Estimated Implementation Time
- Code addition: 20-30 minutes
- Testing: 15-20 minutes (with emulator running)
- Bug fixes (if any): 10-15 minutes
- **Total: ~1 hour**

## Questions to Consider

1. **Should patients see a different pre-call dialog?**
   - Current design: Patients skip SOAP, join call directly
   - Alternative: Show read-only vital signs for patient awareness

2. **Should pre-call SOAP require all fields?**
   - Current design: Optional fields (provider can skip)
   - Alternative: Require chief complaint minimum

3. **Should pre-call SOAP save draft?**
   - Current design: Yes, saves on "Proceed"
   - Alternative: Save only after post-call "Sign & Submit"

4. **Should providers see existing SOAP from previous visits?**
   - Current design: Only shows current appointment SOAP
   - Alternative: Show history of SOAPs for same patient

## Support & Troubleshooting

| Issue | Solution |
|-------|----------|
| Dialog doesn't appear | Check `isProvider=true` is being passed, ensure `context.mounted` |
| "Proceed" button does nothing | Verify `onPreCallAction` callback is properly called |
| Biometrics show "N/A" | Check `patient_profiles` table has data, verify patient_id match |
| File upload fails | Check Supabase `chime_storage` bucket exists, verify permissions |
| Transcription doesn't populate HPI | Check `finalizationResult?['data']?['transcript']` is available |

## Next Steps
1. Implement pre-call dialog integration in `join_room.dart`
2. Run build and verify compilation
3. Test on Android emulator (provider pre-call workflow)
4. Test on web (responsive design during pre-call)
5. Test post-call workflow to ensure no regressions
6. Commit changes to ALINO branch
