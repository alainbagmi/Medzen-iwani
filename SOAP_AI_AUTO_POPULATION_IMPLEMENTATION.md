# SOAP Dialog with Claude Opus AI Auto-Population

## Complete Workflow Overview

### Pre-Call SOAP (AI Read-Only Review)
1. Provider initiates video call
2. **System fetches:** Previous SOAPs + Patient medical history + Current appointment notes
3. **Claude Opus generates:**
   - Chief Complaint
   - History of Present Illness (HPI)
   - Past Medical History
   - Allergies
4. **Provider reviews** AI-generated content (READ-ONLY, no edits)
5. Provider clicks "Proceed with Call" after reviewing context
6. Video call starts

### Post-Call SOAP (AI-Generated, Provider Editable)
1. Call ends
2. **System passes:** Transcription + Pre-call data + Patient history to Claude Opus
3. **Claude Opus generates:**
   - Assessment & Diagnosis
   - Plan
   - Medications
4. **Provider reviews and can edit** any fields that are incorrect
5. Provider can add file attachments
6. Provider clicks "Sign & Submit"
7. SOAP note saved with `is_signed=true`

## Implementation Architecture

### Option A: Edge Function for SOAP Generation (Recommended)
Create new Supabase edge function: `generate-soap-from-context`

**Input:**
```json
{
  "patientId": "uuid",
  "appointmentId": "uuid",
  "transcript": "string (optional, for post-call)",
  "mode": "pre-call | post-call"
}
```

**Process:**
1. **Validate appointment-patient match** (security: prevent data leakage)
2. Fetch previous SOAPs **for this patient only** (last 3-5)
3. Fetch patient profile + medical history **for this patient only**
4. Fetch current appointment details **for this patient only**
5. For post-call: Include transcription
6. Build Claude Opus prompt with **isolated patient context**
7. Call Bedrock Claude Opus model
8. Parse response into SOAP fields

## Security: Patient Data Isolation

**Critical Requirement**: Claude Opus must ONLY access data for the specific patient on the appointment. No access to other patient records.

### Data Access Restrictions

1. **Appointment-Patient Validation**
   ```typescript
   // ALWAYS validate that appointmentId matches patientId
   const { data: appointment } = await supabase
     .from("appointments")
     .select("patient_id")
     .eq("id", appointmentId)
     .single();

   if (appointment?.patient_id !== patientId) {
     throw new Error("Appointment-patient mismatch - security violation");
   }
   ```

2. **Patient-Scoped Queries**
   - All queries MUST include `WHERE patient_id = $patientId`
   - Never query without patient filter
   - Use `.eq("patient_id", patientId)` or `.eq("user_id", patientId)` on ALL patient data queries

3. **Queries That Must Be Scoped**
   ```typescript
   // Patient profile - MUST filter by user_id
   .from("patient_profiles")
   .select("*")
   .eq("user_id", patientId)  // REQUIRED

   // Previous SOAPs - MUST filter by patient_id
   .from("soap_notes")
   .select("*")
   .eq("patient_id", patientId)  // REQUIRED
   .order("created_at", { ascending: false })
   .limit(5);

   // Clinical notes - MUST filter by patient_id
   .from("clinical_notes")
   .select("*")
   .eq("patient_id", patientId)  // REQUIRED

   // Appointments - MUST filter by patient_id
   .from("appointments")
   .select("*")
   .eq("patient_id", patientId)  // REQUIRED
   .eq("id", appointmentId);      // Double validation
   ```

4. **Row Level Security (RLS) Verification**
   - Verify RLS policies prevent cross-patient data access
   - Test with different patient IDs to ensure isolation
   - Edge function uses service role key, so must implement manual validation

5. **Prompt Context Isolation**
   ```typescript
   // Claude Opus prompt ONLY includes data for THIS patient
   let prompt = `You are a clinical assistant for ONE specific patient consultation.

   CRITICAL: All information below is for patient ID: ${patientId}
   DO NOT reference or use data from any other patient.

   Patient Information (Patient ID: ${patientId}):
   - Name: ${patientProfile?.first_name} ${patientProfile?.last_name}
   - DOB: ${patientProfile?.date_of_birth}
   - Medical History: ${patientProfile?.medical_history || "Not provided"}

   Previous Appointments (Patient ID: ${patientId} ONLY):
   ${previousSOAPs?.map(s => `- ${s.encounter_date}: ${s.chief_complaint}`).join('\n')}

   Current Appointment (Patient ID: ${patientId}):
   - Scheduled: ${appointment?.appointment_date}
   - Type: ${appointment?.appointment_type}`;
   ```

### Security Testing Checklist

- [ ] Verify edge function validates appointmentId matches patientId
- [ ] Test with mismatched appointmentId/patientId (should reject)
- [ ] Verify all queries include patient_id filter
- [ ] Test that previous SOAPs only return for specific patient
- [ ] Verify RLS policies prevent cross-patient access
- [ ] Test with multiple patients to ensure no data leakage
- [ ] Audit Claude Opus prompt to ensure only patient-specific data included
- [ ] Log all data access attempts for audit trail

**Output:**
```json
{
  "chiefComplaint": "string",
  "hpiNarrative": "string",
  "pastMedicalHistory": "string",
  "allergies": "string",
  "assessment": "string (post-call only)",
  "plan": "string (post-call only)",
  "medications": "string (post-call only)"
}
```

### Option B: Use Existing `bedrock-ai-chat` Function
Modify existing function to support SOAP generation mode (simpler, no new function needed)

**Recommendation**: Option A (cleaner separation of concerns)

## Database Schema Changes

### Pre-Call SOAP Fields (READ-ONLY)
```dart
final bool isPreCallReadOnly = isPreCall; // True = read-only, False = editable

if (isPreCallReadOnly) {
  // Pre-call fields displayed but NOT editable
  chiefComplaintCtrl.text = soapData['chief_complaint'] ?? '';
  chiefComplaintCtrl.readOnly = true; // Not editable

  hpiCtrl.text = soapData['hpi_narrative'] ?? '';
  hpiCtrl.readOnly = true;

  historyCtrl.text = soapData['past_medical_history'] ?? '';
  historyCtrl.readOnly = true;

  allergiesCtrl.text = soapData['allergies'] ?? '';
  allergiesCtrl.readOnly = true;
}
```

### Post-Call SOAP Fields (EDITABLE)
```dart
if (!isPreCallReadOnly) {
  // Post-call assessment/plan/meds are editable
  assessmentCtrl.text = soapData['assessment'] ?? '';
  assessmentCtrl.readOnly = false; // Editable

  planCtrl.text = soapData['plan'] ?? '';
  planCtrl.readOnly = false;

  medicationsCtrl.text = soapData['medications'] ?? '';
  medicationsCtrl.readOnly = false;

  followUpCtrl.text = soapData['follow_up_instructions'] ?? '';
  followUpCtrl.readOnly = false;
}
```

## Implementation Steps

### Step 1: Create Edge Function for SOAP Generation
**File**: `supabase/functions/generate-soap-pre-call/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  try {
    const { patientId, appointmentId, transcript, mode } = await req.json();

    const supabase = createClient(supabaseUrl, supabaseServiceRole);

    // SECURITY: Validate appointment belongs to patient
    const { data: appointment, error: appointmentError } = await supabase
      .from("appointments")
      .select("patient_id, appointment_date, appointment_type, chief_complaint")
      .eq("id", appointmentId)
      .single();

    if (appointmentError || !appointment) {
      throw new Error("Appointment not found");
    }

    if (appointment.patient_id !== patientId) {
      console.error(`Security violation: Appointment ${appointmentId} does not belong to patient ${patientId}`);
      throw new Error("Unauthorized access to patient data");
    }

    // Fetch patient data - scoped to THIS patient only
    const { data: patientProfile } = await supabase
      .from("patient_profiles")
      .select("*")
      .eq("user_id", patientId)  // SECURITY: Patient-scoped query
      .single();

    // Fetch previous SOAPs - scoped to THIS patient only (last 5)
    const { data: previousSOAPs } = await supabase
      .from("soap_notes")
      .select("*")
      .eq("patient_id", patientId)  // SECURITY: Patient-scoped query
      .order("created_at", { ascending: false })
      .limit(5);

    // Build prompt for Claude Opus - SECURITY: Only include THIS patient's data
    let prompt = `You are a clinical assistant helping a medical provider prepare for a patient consultation.

CRITICAL SECURITY REQUIREMENT:
- All information below is ONLY for Patient ID: ${patientId}
- DO NOT reference, access, or use data from ANY other patient
- This is a HIPAA-compliant system with strict patient data isolation

Patient Information (ID: ${patientId}):
- Name: ${patientProfile?.first_name} ${patientProfile?.last_name}
- DOB: ${patientProfile?.date_of_birth}
- Medical History: ${patientProfile?.medical_history || "Not provided"}
- Allergies: ${patientProfile?.allergies || "Not specified"}

Previous Appointment Summary (Patient ID: ${patientId} ONLY):
${previousSOAPs?.map(s => `- ${s.encounter_date}: ${s.chief_complaint}`).join('\n') || "No previous records"}

Current Appointment (Patient ID: ${patientId}):
- Appointment ID: ${appointmentId}
- Scheduled: ${appointment?.appointment_date}
- Type: ${appointment?.appointment_type}
- Chief Complaint: ${appointment?.chief_complaint || "To be determined"}

Please generate a clinical context summary with:
1. Chief Complaint (based on appointment notes)
2. History of Present Illness (synthesized from patient history)
3. Past Medical History (from records)
4. Allergies (all known allergies)

Format as JSON with keys: chiefComplaint, hpiNarrative, pastMedicalHistory, allergies`;

    if (mode === "post-call" && transcript) {
      prompt += `

Call Transcript:
${transcript}

Additionally, please provide:
5. Assessment & Diagnosis (based on call discussion)
6. Plan (recommended treatment)
7. Medications (if any prescribed)

Format as JSON with all previous keys plus: assessment, plan, medications`;
    }

    // Call Claude Opus via Bedrock
    const bedrockResponse = await callBedrockClaudeOpus(prompt);

    // Parse response
    const soapData = JSON.parse(bedrockResponse);

    return new Response(JSON.stringify({ success: true, data: soapData }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});

async function callBedrockClaudeOpus(prompt: string): Promise<string> {
  // Implementation of Bedrock Claude Opus call
  // Similar to existing bedrock-ai-chat function
  // ...
}
```

### Step 2: Modify SOAP Dialog Widget

**Changes to `post_call_clinical_notes_dialog.dart`:**

```dart
// Add read-only mode parameter
class PostCallClinicalNotesDialog extends StatefulWidget {
  // ... existing parameters ...
  final bool preCallReadOnly;  // NEW: Read-only mode for pre-call

  const PostCallClinicalNotesDialog({
    // ... existing parameters ...
    this.preCallReadOnly = false,
  });
}

// In build method:
@override
Widget build(BuildContext context) {
  // ... existing code ...

  // Apply read-only mode to pre-call fields
  if (widget.preCallReadOnly && widget.isPreCall) {
    _chiefComplaintCtrl.readOnly = true;
    _hpiCtrl.readOnly = true;
    _historyCtrl.readOnly = true;
    _allergiesCtrl.readOnly = true;
  } else {
    _chiefComplaintCtrl.readOnly = false;
    _hpiCtrl.readOnly = false;
    _historyCtrl.readOnly = false;
    _allergiesCtrl.readOnly = false;
  }
}

// Visual indication that fields are read-only
Widget _buildEditableField({
  required String label,
  required TextEditingController controller,
  required String fieldKey,
  required double labelSize,
  required double sectionSize,
  required double fieldHeight,
  int maxLines = 1,
  bool isReadOnly = false,  // NEW parameter
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: isReadOnly ? Colors.grey[600] : Colors.black,
            ),
          ),
          if (!isReadOnly)  // Only show mic for editable fields
            GestureDetector(
              onTap: _isListening && _currentFieldKey == fieldKey
                  ? _stopListening
                  : () => _startListening(fieldKey),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_isListening && _currentFieldKey == fieldKey)
                      ? Colors.red[100]
                      : Colors.blue[100],
                ),
                child: Icon(
                  (_isListening && _currentFieldKey == fieldKey)
                      ? Icons.mic
                      : Icons.mic_none,
                  color: (_isListening && _currentFieldKey == fieldKey)
                      ? Colors.red[700]
                      : Colors.blue[700],
                  size: 16,
                ),
              ),
            ),
          if (isReadOnly)  // Show lock icon for read-only fields
            Icon(Icons.lock, size: 16, color: Colors.grey[600]),
        ],
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        readOnly: isReadOnly,
        maxLines: maxLines,
        minLines: maxLines,
        decoration: InputDecoration(
          hintText: isReadOnly ? 'Auto-populated by AI' : 'Enter $label',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: isReadOnly ? Colors.grey[100] : Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    ],
  );
}
```

### Step 3: Integration in `join_room.dart`

**Pre-Call Integration:**

```dart
// Around line 640, BEFORE Navigator.push

if (isProvider && context.mounted) {
  debugPrint('🔍 Generating pre-call SOAP context using Claude Opus');

  try {
    // Call edge function to generate SOAP
    final response = await http.post(
      Uri.parse('$supabaseUrl/functions/v1/generate-soap-pre-call'),
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
        'x-firebase-token': firebaseJwt,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'patientId': patientId,
        'appointmentId': appointmentId,
        'mode': 'pre-call',
      }),
    );

    if (response.statusCode == 200) {
      final soapData = jsonDecode(response.body)['data'];
      debugPrint('✓ AI-generated pre-call SOAP context');

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
            soapNoteData: soapData,  // AI-generated data
            patientBiometrics: patientBiometrics,
            isPreCall: true,
            preCallReadOnly: true,  // READ-ONLY for review
            onPreCallAction: (proceed) {
              proceedWithCall = proceed;
              Navigator.of(dialogContext).pop();
            },
          ),
        ),
      );

      if (!proceedWithCall) {
        debugPrint('❌ Provider cancelled pre-call review');
        return;
      }
    } else {
      throw Exception('Failed to generate SOAP: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('⚠️ Error generating pre-call SOAP: $e');
    // Fall back to empty SOAP if AI fails
  }
}
```

**Post-Call Integration:**

```dart
// Around line 720, keep existing code but enhance with AI generation

if (context.mounted) {
  try {
    // Generate post-call SOAP using transcription
    final postCallResponse = await http.post(
      Uri.parse('$supabaseUrl/functions/v1/generate-soap-pre-call'),
      headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
        'x-firebase-token': firebaseJwt,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'patientId': patientId,
        'appointmentId': appointmentId,
        'transcript': transcript,
        'mode': 'post-call',  // Includes assessment/plan/meds
      }),
    );

    if (postCallResponse.statusCode == 200) {
      final aiSoapData = jsonDecode(postCallResponse.body)['data'];
      debugPrint('✓ AI-generated post-call SOAP assessment');

      // Merge with existing data
      soapNoteData?.addAll(aiSoapData);
    }
  } catch (e) {
    debugPrint('⚠️ Error generating post-call SOAP: $e');
    // Continue with manual entry if AI fails
  }

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Center(
      child: PostCallClinicalNotesDialog(
        sessionId: sessionId!,
        appointmentId: appointmentId,
        providerId: providerId,
        patientId: patientId,
        patientName: patientName ?? 'Patient',
        soapNoteId: soapNoteId,
        soapNoteData: soapNoteData,  // Pre-call + AI-generated post-call
        patientBiometrics: patientBiometrics,
        transcript: transcript,
        isPreCall: false,
        preCallReadOnly: false,  // EDITABLE for correction
        onSaved: () {
          debugPrint('✅ Provider saved SOAP note');
          Navigator.of(dialogContext).pop();
        },
        onDiscarded: () {
          debugPrint('❌ Provider discarded SOAP note');
          Navigator.of(dialogContext).pop();
        },
      ),
    ),
  );
}
```

## User Experience Flow

### Pre-Call (Provider View)
```
[Join Call Button Clicked]
         ↓
[Loading: AI generating clinical context...]
         ↓
[SOAP Dialog Opens - READ-ONLY Mode]
┌─────────────────────────────────┐
│ Clinical Context - Review Only  │
│                                 │
│ Chief Complaint:                │
│ ████████████████████ (Read-only)│
│ 🔒                              │
│                                 │
│ History of Present Illness:     │
│ ████████████████████ (Read-only)│
│ 🔒                              │
│                                 │
│ Past Medical History:           │
│ ████████████████████ (Read-only)│
│ 🔒                              │
│                                 │
│ Allergies:                      │
│ ████████████████████ (Read-only)│
│ 🔒                              │
│                                 │
│ Vitals:                         │
│ BP: 120/80  HR: 72  Temp: 98.6 │
│                                 │
│ [Cancel Call] [Proceed Call]    │
└─────────────────────────────────┘
         ↓
[Provider clicks "Proceed with Call"]
         ↓
[Video Call Starts]
```

### Post-Call (Provider View)
```
[Call Ends]
         ↓
[Loading: AI generating assessment...]
         ↓
[SOAP Dialog Opens - EDITABLE Mode]
┌──────────────────────────────────┐
│ Clinical Assessment              │
│                                  │
│ Chief Complaint: (Read-only)     │
│ ██████████████████              │
│ 🔒                               │
│                                  │
│ Assessment & Diagnosis:          │
│ ██████████████████ (Editable) ✏️ │
│ [Provider can edit/correct]      │
│                                  │
│ Plan:                            │
│ ██████████████████ (Editable) ✏️ │
│                                  │
│ Medications:                     │
│ ██████████████████ (Editable) ✏️ │
│                                  │
│ Follow-up:                       │
│ ██████████████████ (Editable) ✏️ │
│                                  │
│ 📎 Add Attachments              │
│                                  │
│ [Cancel] [Sign & Submit]         │
└──────────────────────────────────┘
         ↓
[Provider reviews and edits as needed]
         ↓
[Provider clicks "Sign & Submit"]
         ↓
[SOAP Saved with is_signed=true]
```

## Implementation Summary

| Step | Task | Time | Status |
|------|------|------|--------|
| 1 | Create edge function for SOAP generation | 30 min | ⏳ PENDING |
| 2 | Update SOAP widget for read-only mode | 20 min | ⏳ PENDING |
| 3 | Add pre-call AI generation in join_room.dart | 20 min | ⏳ PENDING |
| 4 | Add post-call AI generation in join_room.dart | 15 min | ⏳ PENDING |
| 5 | Test pre-call workflow | 15 min | ⏳ PENDING |
| 6 | Test post-call workflow | 15 min | ⏳ PENDING |
| **Total** | | **~115 min** | |

## Benefits of This Approach

✅ Provider gets instant clinical context before consulting
✅ AI synthesizes patient history into actionable summary
✅ Reduces cognitive load (AI does research, provider does treatment)
✅ Post-call assessment auto-drafted, provider corrects/refines
✅ Workflow optimized for clinical efficiency
✅ Provider maintains full control (can override AI suggestions)
✅ Audit trail (can see AI suggestions vs provider edits)

## Key Implementation Notes

1. **Claude Opus Model**: Provides best medical reasoning for clinical context
2. **Read-Only Pre-Call**: Prevents accidental edits to AI-generated context
3. **Editable Post-Call**: Allows provider to correct/adjust AI assessment
4. **Graceful Fallback**: If AI fails, dialog still appears with manual entry mode
5. **Error Handling**: Network timeouts don't block video call initialization
6. **Audit Trail**: Original AI suggestions preserved in database

## Next Steps

1. Create `generate-soap-pre-call` edge function
2. Update SOAP dialog widget with read-only mode
3. Integrate pre-call AI generation in join_room.dart
4. Integrate post-call AI generation in join_room.dart
5. Build and test end-to-end workflow
