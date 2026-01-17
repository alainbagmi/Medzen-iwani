# SOAP AI Security Testing Guide - Phase 5

## Objective
Verify that the patient data isolation security in the SOAP AI auto-population system prevents cross-patient data access and maintains HIPAA compliance.

## Build Status
✅ **Flutter Build**: SUCCESSFUL (25.6s)
- Web build compiled without critical errors
- Type error fix (Firebase token null coalescing) verified
- All 4 phases (edge function, widget, pre-call, post-call) integrated

## Security Model Overview

The security model uses **multi-layer validation**:

1. **Appointment-Patient Match Validation** (edge function, lines 95-123)
   - Before ANY database query, verify `appointment.patient_id === patientId`
   - If mismatch: return 403 Forbidden, log security violation

2. **Patient-Scoped Database Queries**
   - ALL queries include `.eq("patient_id", patientId)` filter
   - Previous SOAPs: `.eq("patient_id", patientId)`
   - Patient profile: `.eq("user_id", patientId)`
   - Prevents SQL injection and cross-patient leakage

3. **Claude Opus Prompt Isolation** (line 212-219)
   - Prompt explicitly states: `PATIENT ID: ${patientId}`
   - Includes: `CRITICAL: You are only processing data for Patient ID: ${patientId}`
   - AI model instructed to never reference other patients

4. **Firebase Token Verification** (join_room.dart, line 837)
   - Firebase token required in all requests
   - Token verified server-side before processing
   - Prevents unauthenticated access

## Test Scenarios

### Test Scenario 1: Authorized Access (Correct Patient)

**Objective**: Verify that a provider CAN generate SOAP for their own patient

**Prerequisites**:
- Provider account (Medical Provider role)
- Patient account (Patient role)
- Scheduled appointment between provider and patient
- Provider has Firebase authentication token

**Steps**:

1. **Start the app**
   ```bash
   flutter run -d chrome
   ```

2. **Login as provider** (use provider email/password)
   - Verify provider dashboard loads
   - Locate an appointment with assigned patient

3. **Navigate to appointment**
   - Click appointment
   - Click "Join Video Call"

4. **Pre-Call SOAP Dialog (Provider Only)**
   - Dialog should appear with:
     - ✅ Read-only fields: Chief Complaint, HPI, History, Allergies
     - ✅ Lock icons (🔒) on read-only fields
     - ✅ Grey background on read-only fields
     - ✅ Patient biometrics displayed (8 vital signs)
     - ✅ "Proceed with Call" and "Cancel Call" buttons
   - Verify AI context is relevant to this specific patient:
     - Chief complaint should match appointment chief_complaint
     - History should be from THIS patient's previous visits
     - Allergies should be from THIS patient's profile

5. **Review Read-Only Fields**
   - Fields should NOT be editable (click attempt does nothing)
   - Mic buttons should NOT be present for pre-call fields
   - Only "Proceed with Call" button enables continuation

6. **Proceed with Video Call**
   - Click "Proceed with Call"
   - Dialog should close
   - Video call widget (ChimeMeetingEnhanced) should load
   - Verify call connects successfully

7. **Complete Short Video Call**
   - Wait 10-15 seconds (simulates conversation)
   - End the call

8. **Post-Call SOAP Dialog (Provider Review)**
   - Dialog should reappear with:
     - ✅ Pre-call data still visible (chief complaint, history, allergies)
     - ✅ AI-generated assessment/plan/medications in editable fields
     - ✅ Transcription auto-populated in HPI field
     - ✅ All 8 vital signs displayed
   - Verify post-call fields ARE editable:
     - Click assessment field → should open text editor
     - Type additional notes → should save
     - Mic button should be available

9. **Complete SOAP Assessment**
   - Provider edits assessment/plan/medications as needed
   - Optionally adds file attachments
   - Clicks "Sign & Submit"

10. **Verify Database Save**
    - Dialog should close
    - Check Supabase dashboard → `soap_notes` table
    - Verify new row has:
      - ✅ `is_signed = true`
      - ✅ `patient_id = correct patient UUID`
      - ✅ `appointment_id = correct appointment UUID`
      - ✅ `assessment`, `plan`, `medications` fields populated
      - ✅ `encounter_date` = today

**Expected Result**: ✅ **PASS** - Provider successfully generates SOAP for their patient

---

### Test Scenario 2: Unauthorized Access (Cross-Patient Attempt)

**Objective**: Verify that the edge function REJECTS cross-patient data access with 403 Forbidden

**Prerequisites**:
- Access to Supabase project
- API testing tool (curl, Postman, or Insomnia)
- Two test patients: Patient A and Patient B
- Appointment between Patient A and a Provider
- Valid Firebase auth token

**Steps**:

1. **Get Test Data**
   ```sql
   -- Run in Supabase SQL editor to get IDs
   SELECT id, patient_id, appointment_date FROM appointments WHERE patient_id = 'patient_a_uuid' LIMIT 1;
   ```
   - Record: `appointmentId` (belongs to Patient A)
   - Record: `patient_a_uuid`

2. **Get Patient B UUID**
   ```sql
   SELECT id FROM users WHERE id != 'patient_a_uuid' LIMIT 1;
   ```
   - Record: `patient_b_uuid` (different patient)

3. **Call Edge Function with Mismatched IDs**
   ```bash
   curl -X POST \
     https://noaeltglphdlkbflipit.supabase.co/functions/v1/generate-soap-from-context \
     -H "apikey: YOUR_SUPABASE_ANON_KEY" \
     -H "Authorization: Bearer YOUR_SUPABASE_ANON_KEY" \
     -H "x-firebase-token: YOUR_FIREBASE_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "patientId": "patient_b_uuid",
       "appointmentId": "appointment_id_for_patient_a",
       "mode": "pre-call"
     }'
   ```

4. **Expected Response: 403 Forbidden**
   ```json
   {
     "error": "Unauthorized access to patient data"
   }
   ```

5. **Verify Security Logging**
   - Check Supabase logs:
     ```bash
     npx supabase functions logs generate-soap-from-context --tail
     ```
   - Should show:
     ```
     🚨 SECURITY VIOLATION: Unauthorized access attempt!
     Requested patient: patient_b_uuid
     Appointment owner: patient_a_uuid
     Appointment: appointment_id_for_patient_a
     ```

6. **Verify Audit Log Entry**
   ```sql
   SELECT * FROM audit_log
   WHERE event_type = 'unauthorized_soap_access'
   ORDER BY created_at DESC LIMIT 1;
   ```
   - Should have entry with:
     - ✅ `event_type = 'unauthorized_soap_access'`
     - ✅ `user_id = patient_b_uuid`
     - ✅ `appointment_id = correct appointment`
     - ✅ Error details logged

**Expected Result**: ✅ **PASS** - Edge function rejects unauthorized access with 403 Forbidden

---

### Test Scenario 3: Patient User Flow (Patients Skip SOAP)

**Objective**: Verify that patients do NOT see SOAP dialogs and go directly to video call

**Prerequisites**:
- Patient account
- Scheduled appointment with provider
- Provider is on the other end (or test with mock)

**Steps**:

1. **Login as patient**
   - Use patient email/password

2. **Navigate to appointment**
   - Click appointment
   - Click "Join Video Call"

3. **Verify NO Pre-Call SOAP Dialog**
   - ✅ SOAP dialog should NOT appear
   - ✅ Video call widget should load immediately
   - ✅ Patient joins call directly

4. **Complete call**
   - Call proceeds normally
   - Call ends

5. **Verify NO Post-Call SOAP Dialog**
   - ✅ SOAP dialog should NOT reappear
   - ✅ Call finalization completes normally

**Expected Result**: ✅ **PASS** - Patients skip SOAP workflows, providers generate

---

### Test Scenario 4: Responsive Design Verification

**Objective**: Verify SOAP dialog displays correctly on different screen sizes

**Steps**:

1. **Desktop (> 1200px)**
   - Chrome DevTools: Ctrl+Shift+I
   - Set to "Desktop" or 1400x900
   - Pre-call dialog should:
     - ✅ Width: 900px
     - ✅ Font sizes: 13-20px
     - ✅ Biometrics in flexible grid (Wrap widget)
     - ✅ All fields visible without scrolling (if content fits)

2. **Tablet (600-1200px)**
   - Chrome DevTools: Set to 800x600
   - Pre-call dialog should:
     - ✅ Width: 700px
     - ✅ Font sizes: 12-18px
     - ✅ Fields still editable/readable
     - ✅ Single-scroll interface (no horizontal scroll)

3. **Mobile (< 600px)**
   - Chrome DevTools: Set to 375x667 (iPhone)
   - Pre-call dialog should:
     - ✅ Width: 95% of screen
     - ✅ Font sizes: 11-16px
     - ✅ Fields readable on small screen
     - ✅ Single-scroll (no horizontal overflow)
     - ✅ Buttons accessible at bottom

**Expected Result**: ✅ **PASS** - Dialog responsive across all breakpoints

---

## Test Execution Plan

### Week 1: Manual Security Testing
- Day 1: Test Scenario 1 (Authorized Access)
- Day 2: Test Scenario 2 (Cross-Patient Rejection)
- Day 3: Test Scenario 3 (Patient Flow)
- Day 4: Test Scenario 4 (Responsive Design)

### Week 2: Automated Testing
- Create Dart test suite for security validation
- Create Supabase RLS policy tests
- Create edge function unit tests

### Week 3: Load Testing
- Test with 10+ concurrent pre-call dialogs
- Test with rapid video call start/end cycles
- Monitor database query performance

## Success Criteria

All of the following must PASS for Phase 5 completion:

- [ ] Test Scenario 1 PASS: Authorized provider can generate SOAP for their patient
- [ ] Test Scenario 2 PASS: Unauthorized cross-patient access returns 403 Forbidden
- [ ] Test Scenario 3 PASS: Patients skip SOAP, go directly to video call
- [ ] Test Scenario 4 PASS: Dialog responsive on mobile/tablet/desktop
- [ ] Edge function logs all security events to audit_log
- [ ] Build compiles without critical errors
- [ ] No database integrity violations
- [ ] HIPAA compliance verified (patient data isolation)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Pre-call dialog doesn't appear | Check `isProvider=true` in join_room.dart, verify provider role in database |
| Edge function returns 500 | Check logs: `npx supabase functions logs generate-soap-from-context --tail` |
| AI-generated content is generic | Check `transcript` parameter passed to edge function, verify Bedrock credentials |
| Cross-patient test returns 200 instead of 403 | Verify edge function has `appointment.patient_id !== patientId` check (line 96) |
| Audit log not showing entries | Ensure `audit_log` table exists, check RLS policies allow inserts |
| Dialog shows "Security validation failed" | Verify Firebase token is valid and not expired, check x-firebase-token header format |

## Related Documentation

- Implementation: `SOAP_AI_AUTO_POPULATION_IMPLEMENTATION.md`
- Widget verification: `SOAP_IMPLEMENTATION_VERIFICATION_COMPLETE.md`
- Integration guide: `PRECALL_SOAP_INTEGRATION_GUIDE.md`
- Edge function: `supabase/functions/generate-soap-from-context/index.ts`
- Main widget: `lib/custom_code/widgets/post_call_clinical_notes_dialog.dart`
- Integration code: `lib/custom_code/actions/join_room.dart` (lines 640-956)

## Sign-Off

**Phase 5 Status**: IN PROGRESS

**Build Status**: ✅ SUCCESSFUL

**Next Steps**:
1. Execute Test Scenarios 1-4
2. Document any issues found
3. Verify all success criteria pass
4. Mark Phase 5 complete
5. Deploy to production

**Estimated Completion**: 2-3 days of testing

