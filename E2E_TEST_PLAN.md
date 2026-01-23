# End-to-End Test Plan: Patient Medical History Registration & Management

## Overview

This document provides a comprehensive test scenario to verify the complete patient medical history system workflow, including:
- Pre-call context snapshot retrieval
- Patient history display in pre-call dialog
- AI-powered SOAP generation with pre-populated medical history
- Provider review and medical record update
- Cumulative medical record merging with deduplication
- History enrichment for subsequent visits

---

## Test Prerequisites

### Required Setup
1. **Test Patient:** Create or use existing patient with UUID: `<test-patient-id>`
2. **Test Provider:** Use provider account with necessary permissions
3. **Test Appointment:** Schedule appointment between provider and patient
4. **Database Access:** Access to Supabase console for verification queries
5. **Edge Function Logs:** Access to `npx supabase functions logs [name] --tail`

### Initial State Verification

Verify the following tables exist and have correct schema:
```sql
-- Check patient_profiles has cumulative_medical_record column
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'patient_profiles'
AND column_name IN ('cumulative_medical_record', 'medical_record_last_updated_at', 'medical_record_last_soap_note_id');

-- Expected output:
-- cumulative_medical_record | jsonb
-- medical_record_last_updated_at | timestamp with time zone
-- medical_record_last_soap_note_id | uuid

-- Check normalized SOAP tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name LIKE 'soap_%'
ORDER BY table_name;
```

---

## Test Scenario: Complete Workflow

### Phase 1: Initial Patient Setup

**Objective:** Create test patient with baseline medical history

```sql
-- 1a. Create/find test user
INSERT INTO users (firebase_uid, email, first_name, last_name, phone, role)
VALUES
  ('firebase-uid-' || gen_random_uuid()::text,
   'test-patient@medzen.local',
   'Test',
   'Patient',
   '+1-555-0101',
   'patient')
RETURNING id;

-- Store the returned user ID as <test-patient-id>

-- 1b. Create patient profile with initial cumulative medical record
INSERT INTO patient_profiles (
  user_id,
  patient_number,
  blood_type,
  date_of_birth,
  gender,
  cumulative_medical_record
) VALUES (
  '<test-patient-id>',
  'PAT-' || to_char(now(), 'YYYYMMDD') || '-' || lpad((random()*9999)::int::text, 4, '0'),
  'O+',
  '1985-06-15'::date,
  'Male',
  '{
    "conditions": [
      {
        "name": "Type 2 Diabetes Mellitus",
        "icd10": "E11",
        "status": "active",
        "severity": "moderate",
        "onset_date": "2020-03-01",
        "added_from_soap_note_id": "initial-setup",
        "last_updated": "'|| now()::text ||'"
      }
    ],
    "medications": [
      {
        "name": "Metformin",
        "dose": "500mg",
        "frequency": "twice daily",
        "route": "oral",
        "status": "active",
        "added_from_soap_note_id": "initial-setup",
        "last_updated": "'|| now()::text ||'"
      }
    ],
    "allergies": [
      {
        "allergen": "Penicillin",
        "reaction": "rash",
        "severity": "moderate",
        "status": "active",
        "added_from_soap_note_id": "initial-setup",
        "last_updated": "'|| now()::text ||'"
      }
    ],
    "surgical_history": [
      "Appendectomy (2005)"
    ],
    "family_history": [
      "Father: Hypertension",
      "Mother: Diabetes Type 2"
    ],
    "social_history": {
      "tobacco": "Former smoker (quit 2015)",
      "alcohol": "Occasional",
      "drugs": "Denies",
      "occupation": "Software Engineer"
    },
    "vital_trends": {},
    "metadata": {
      "total_visits": 1,
      "source_soap_notes": ["initial-setup"],
      "last_updated": "'|| now()::text ||'"
    }
  }'::jsonb
) RETURNING id;

-- Store the returned profile ID as <test-profile-id>

-- 1c. Verify initial state
SELECT
  user_id,
  cumulative_medical_record->'conditions'->0->>'name' as primary_condition,
  cumulative_medical_record->'medications'->0->>'name' as primary_medication,
  cumulative_medical_record->'allergies'->0->>'allergen' as primary_allergy,
  cumulative_medical_record->'metadata'->>'total_visits' as visit_count
FROM patient_profiles
WHERE user_id = '<test-patient-id>';

-- Expected output:
-- user_id | primary_condition | primary_medication | primary_allergy | visit_count
-- <test-patient-id> | Type 2 Diabetes Mellitus | Metformin | Penicillin | 1
```

**Expected Result:** ✅ Patient profile created with baseline medical history (1 condition, 1 medication, 1 allergy)

---

### Phase 2: Create Context Snapshot

**Objective:** Verify context snapshot creation before call

```sql
-- 2a. Create test appointment
INSERT INTO appointments (
  patient_id,
  provider_id,
  appointment_date,
  chief_complaint,
  appointment_type,
  status,
  scheduled_duration_minutes
) VALUES (
  '<test-patient-id>',
  '<test-provider-id>',
  now() + interval '1 hour',
  'Follow-up for diabetes management and new chest symptoms',
  'video',
  'scheduled',
  30
) RETURNING id;

-- Store returned ID as <test-appointment-id>

-- 2b. Call create-context-snapshot edge function via HTTP
POST https://<supabase-url>/functions/v1/create-context-snapshot
Headers:
  x-firebase-token: <provider-firebase-token>
  Content-Type: application/json

Body:
{
  "appointmentId": "<test-appointment-id>",
  "patientId": "<test-patient-id>"
}

-- 2c. Verify context snapshot created and stored
SELECT
  id,
  patient_id,
  jsonb_typeof(snapshot_data) as data_type,
  snapshot_data->'active_conditions' as conditions,
  snapshot_data->'current_medications' as medications,
  snapshot_data->'allergies' as allergies,
  snapshot_data->'metadata'->>'last_updated' as updated_at
FROM context_snapshots
WHERE patient_id = '<test-patient-id>'
ORDER BY created_at DESC
LIMIT 1;

-- Expected output:
-- id | patient_id | data_type | conditions | medications | allergies | updated_at
-- <snapshot-id> | <test-patient-id> | object | [{"name":"Type 2 Diabetes Mellitus",...}] | [{"name":"Metformin",...}] | [{"allergen":"Penicillin",...}] | 2026-01-22T...

-- 2d. Verify snapshot contains cumulative_medical_record reference
SELECT
  snapshot_data->'active_conditions'->0->>'name' as first_condition,
  snapshot_data->'current_medications'->0->>'name' as first_medication,
  snapshot_data->'allergies'->0->>'allergen' as first_allergy
FROM context_snapshots
WHERE patient_id = '<test-patient-id>'
ORDER BY created_at DESC
LIMIT 1;
```

**Expected Result:** ✅ Context snapshot created with:
- `active_conditions`: ["Type 2 Diabetes Mellitus"]
- `current_medications`: ["Metformin 500mg twice daily"]
- `allergies`: ["Penicillin (moderate)"]

---

### Phase 3: Provider Views Pre-Call History

**Objective:** Verify pre-call clinical notes dialog displays patient history

**Manual UI Test:**
1. Provider logs into MedZen
2. Navigate to Appointments → Find test appointment
3. Click "View Patient History" or similar button
4. **Verify PreCallClinicalNotesDialog displays:**
   - ✓ Patient Name: "Test Patient"
   - ✓ Active Conditions: "Type 2 Diabetes Mellitus (E11)"
   - ✓ Current Medications: "Metformin 500mg, twice daily"
   - ✓ Allergies: "Penicillin (moderate)" [highlighted in yellow/orange]
   - ✓ Surgical History: "Appendectomy (2005)"
   - ✓ Family History: "Father: Hypertension, Mother: Diabetes Type 2"
   - ✓ Visit Count Badge: "1"
   - ✓ Last Updated: "1 visit ago" or timestamp

**Expected Result:** ✅ All fields populated from cumulative_medical_record JSONB

---

### Phase 4: Video Call Occurs

**Objective:** Simulate video call with new clinical findings

**Simulated Call Transcript:**
```
[0:00] Provider: Hi, how are you doing today?
[0:05] Patient: I'm doing okay, but I've been having some chest pain for about a week now.
[0:15] Provider: Tell me more about this chest pain. When did it start?
[0:20] Patient: It started about 7 days ago, maybe Tuesday evening.
[0:25] Patient: It's a dull pain in the center of my chest, maybe a 6 out of 10.
[0:35] Provider: Have you had any shortness of breath with this?
[0:40] Patient: A little bit, especially when I walk up stairs.
[0:50] Provider: Any fevers or other symptoms?
[0:55] Patient: No fever, but I've been more tired than usual this week.
[1:05] Provider: Are you still on your Metformin?
[1:10] Patient: Yes, every day.
[1:15] Provider: Good. I think we should get an EKG done to rule out cardiac issues.
[1:25] Patient: Okay, I trust your judgment.
```

**Expected Result:** ✅ Transcript captured with 9-10 speaker turns

---

### Phase 5: SOAP Draft Generation

**Objective:** Verify AI generates SOAP with pre-populated Tab 5

```sql
-- 5a. Create video call session
INSERT INTO video_call_sessions (
  appointment_id,
  patient_id,
  provider_id,
  context_snapshot_id,
  session_status,
  encounter_status,
  started_at
) VALUES (
  '<test-appointment-id>',
  '<test-patient-id>',
  '<test-provider-id>',
  '<snapshot-id>',
  'active',
  'in_call',
  now()
) RETURNING id;

-- Store returned ID as <test-session-id>

-- 5b. Simulate transcript chunks (from Chime transcription)
INSERT INTO call_transcript_chunks (
  encounter_id,
  sequence,
  speaker,
  text,
  start_ms,
  end_ms
) VALUES
  ('<test-session-id>', 1, 'Provider', 'Hi, how are you doing today?', 0, 5000),
  ('<test-session-id>', 2, 'Patient', 'I''m doing okay, but I''ve been having some chest pain for about a week now.', 5000, 15000),
  ('<test-session-id>', 3, 'Provider', 'Tell me more about this chest pain. When did it start?', 15000, 20000),
  ('<test-session-id>', 4, 'Patient', 'It started about 7 days ago, maybe Tuesday evening.', 20000, 25000),
  ('<test-session-id>', 5, 'Patient', 'It''s a dull pain in the center of my chest, maybe a 6 out of 10.', 25000, 35000),
  ('<test-session-id>', 6, 'Provider', 'Have you had any shortness of breath with this?', 35000, 40000),
  ('<test-session-id>', 7, 'Patient', 'A little bit, especially when I walk up stairs.', 40000, 50000),
  ('<test-session-id>', 8, 'Provider', 'Any fevers or other symptoms?', 50000, 55000),
  ('<test-session-id>', 9, 'Patient', 'No fever, but I''ve been more tired than usual this week.', 55000, 65000),
  ('<test-session-id>', 10, 'Provider', 'Are you still on your Metformin?', 65000, 70000),
  ('<test-session-id>', 11, 'Patient', 'Yes, every day.', 70000, 75000),
  ('<test-session-id>', 12, 'Provider', 'Good. I think we should get an EKG done to rule out cardiac issues.', 75000, 85000),
  ('<test-session-id>', 13, 'Patient', 'Okay, I trust your judgment.', 85000, 90000);

-- 5c. End call session and trigger SOAP generation
UPDATE video_call_sessions
SET
  session_status = 'ended',
  encounter_status = 'soap_drafting',
  ended_at = now()
WHERE id = '<test-session-id>';

-- 5d. Call generate-soap-draft-v2 edge function
POST https://<supabase-url>/functions/v1/generate-soap-draft-v2
Headers:
  x-firebase-token: <provider-firebase-token>
  Content-Type: application/json

Body:
{
  "encounter_id": "<test-session-id>"
}

-- 5e. Monitor edge function logs
npx supabase functions logs generate-soap-draft-v2 --tail

-- 5f. Verify SOAP draft was saved
SELECT
  id,
  soap_status,
  encounter_status,
  soap_draft_json->'tab2_patient_identification'->>'full_name' as patient_name,
  soap_draft_json->'tab5_subjective_history'->'pmh' as pmh_list,
  soap_draft_json->'tab5_subjective_history'->'medications' as med_list,
  soap_draft_json->'tab5_subjective_history'->'allergies' as allergy_list,
  soap_draft_json->'meta'->'provenance'->>'confidence' as ai_confidence,
  soap_draft_json->'meta'->'ai_flags' as ai_flags
FROM video_call_sessions
WHERE id = '<test-session-id>';

-- Expected output:
-- soap_status: "draft_ready"
-- encounter_status: "soap_ready"
-- patient_name: "Test Patient"
-- pmh_list: [
--   {"name": "Type 2 Diabetes Mellitus", ...},  (pre-populated from snapshot)
--   {"name": "Chest pain - new", ...}            (extracted from transcript)
-- ]
-- med_list: [
--   {"name": "Metformin", "dose": "500mg", ...}  (from snapshot)
-- ]
-- allergy_list: [
--   {"allergen": "Penicillin", "severity": "moderate", ...}  (from snapshot)
-- ]
-- ai_confidence: "0.85" (or similar)
-- ai_flags: {"missing_critical_info": [], "needs_clinician_confirmation": [...]}
```

**Verification Checklist:**
- ✓ Tab 2 (Patient ID): All fields populated from snapshot
- ✓ Tab 5 (History):
  - ✓ PMH includes: "Type 2 Diabetes Mellitus" (pre-populated) + "Chest pain" (new from transcript)
  - ✓ Medications: "Metformin 500mg twice daily" (pre-populated from snapshot)
  - ✓ Allergies: "Penicillin (moderate)" (pre-populated from snapshot, marked as severity escalation ready)
- ✓ Tab 4 (HPI): Captures chest pain details from transcript (7 days ago, 6/10 severity, SOB with exertion)
- ✓ Tab 3 (Chief Complaint): "Chest pain with associated dyspnea"
- ✓ Tab 6 (ROS): Lists fatigue, chest pain, dyspnea on exertion (positive findings only)
- ✓ Meta confidence: > 0.75
- ✓ `meta.provenance.context_snapshot_id`: Matches snapshot ID
- ✓ `meta.provenance.model`: "claude-3-haiku-20240307" or equivalent

**Expected Result:** ✅ SOAP draft generated with Tab 5 pre-populated from cumulative_medical_record

---

### Phase 6: Provider Review & Edit Medical History

**Objective:** Verify provider can edit Tab 5 and add new medical findings

**Manual UI Test in PostCallClinicalNotesDialog:**
1. Provider reviews generated SOAP draft
2. Navigate to Tab 5 (Subjective History)
3. **Verify pre-populated fields:**
   - ✓ PMH shows "Type 2 Diabetes Mellitus" with ICD-10 code "E11"
   - ✓ Medications shows "Metformin 500mg, twice daily"
   - ✓ Allergies shows "Penicillin (moderate)"
4. **Provider adds new findings to Tab 5:**
   - Add new condition: "Hypertension" (ICD-10: I10, status: "new", severity: "mild")
   - Add new medication: "Lisinopril 10mg daily"
   - Update Penicillin allergy severity from "moderate" → "severe" (escalation)
5. **Provider adds to other tabs:**
   - Tab 7 (Vitals): BP 145/92, HR 78, RR 16, O2 Sat 98%
   - Tab 10 (Assessment): Add "Essential Hypertension (I10)" to problem list
   - Tab 11 (Plan): Add "Order EKG", "Start Lisinopril 10mg daily"
6. Click "Sign & Save Note"
   - Verify dialog closes immediately (Phase 1 blocking save completes)
   - Provider can continue with other tasks

**Expected Result:** ✅ SOAP note saved to database with provider edits

---

### Phase 7: Background Medical Record Update

**Objective:** Verify cumulative medical record is merged with new SOAP data

```sql
-- 7a. Monitor background update logs (run in separate terminal)
npx supabase functions logs update-patient-medical-record --tail

-- Expected log output:
-- [update-patient-medical-record] Extracting SOAP data for note <soap-id>
-- [update-patient-medical-record] Merging SOAP data into patient record
-- [update-patient-medical-record] ✅ Successfully updated patient medical record
-- [update-patient-medical-record] 📊 Record now has 2 visits

-- 7b. Wait 5-10 seconds for background update to complete
-- (The system uses fire-and-forget async, so provider doesn't wait)

-- 7c. Verify cumulative medical record was updated
SELECT
  cumulative_medical_record->'conditions' as all_conditions,
  cumulative_medical_record->'medications' as all_medications,
  cumulative_medical_record->'allergies' as all_allergies,
  cumulative_medical_record->'metadata'->>'total_visits' as total_visits,
  cumulative_medical_record->'metadata'->>'source_soap_notes' as source_notes,
  cumulative_medical_record->'metadata'->>'last_updated' as last_updated,
  medical_record_last_updated_at,
  medical_record_last_soap_note_id
FROM patient_profiles
WHERE user_id = '<test-patient-id>';

-- Expected output:
-- all_conditions: [
--   {
--     "name": "Type 2 Diabetes Mellitus",
--     "icd10": "E11",
--     "status": "active",
--     "added_from_soap_note_id": "initial-setup"
--   },
--   {
--     "name": "Hypertension",
--     "icd10": "I10",
--     "status": "active",
--     "severity": "mild",
--     "added_from_soap_note_id": "<current-soap-id>"
--   }
-- ]

-- all_medications: [
--   {
--     "name": "Metformin",
--     "dose": "500mg",
--     "frequency": "twice daily",
--     "status": "active"
--   },
--   {
--     "name": "Lisinopril",
--     "dose": "10mg",
--     "frequency": "daily",
--     "status": "active",
--     "added_from_soap_note_id": "<current-soap-id>"
--   }
-- ]

-- all_allergies: [
--   {
--     "allergen": "Penicillin",
--     "severity": "severe",  ← ESCALATED from "moderate"
--     "added_from_soap_note_id": "initial-setup",
--     "last_updated": "2026-01-22T14:30:00Z"  ← Updated timestamp
--   }
-- ]

-- total_visits: "2"

-- source_notes: ["initial-setup", "<current-soap-id>"]

-- medical_record_last_updated_at: 2026-01-22T14:30:00Z

-- medical_record_last_soap_note_id: <current-soap-id>

-- 7d. Verify deduplication worked correctly
-- Should have 2 conditions (not 3 - deduped), 2 medications (not 3), 1 allergy (severity escalated)
SELECT
  jsonb_array_length(cumulative_medical_record->'conditions') as condition_count,
  jsonb_array_length(cumulative_medical_record->'medications') as medication_count,
  jsonb_array_length(cumulative_medical_record->'allergies') as allergy_count
FROM patient_profiles
WHERE user_id = '<test-patient-id>';

-- Expected output:
-- condition_count: 2
-- medication_count: 2
-- allergy_count: 1
```

**Verification Checklist:**
- ✓ Conditions: 2 total (Diabetes + Hypertension new)
- ✓ Medications: 2 total (Metformin existing + Lisinopril new)
- ✓ Allergies: 1 total (Penicillin, but severity escalated to "severe")
- ✓ Deduplication worked: No duplicate entries
- ✓ Visit count: Incremented from 1 → 2
- ✓ Source notes: Contains both initial and current SOAP IDs
- ✓ Timestamps: All updated_at fields show current time
- ✓ medical_record_last_soap_note_id: Points to current SOAP note

**Expected Result:** ✅ Cumulative medical record merged with intelligent deduplication:
- New conditions added
- New medications added
- Allergy severity escalated (safety feature)
- No duplicate entries
- Visit counter incremented
- Audit trail maintained

---

### Phase 8: Next Visit - Enriched History Display

**Objective:** Verify enriched history available for next appointment

**Manual UI Test:**
1. Provider joins a NEW appointment with same patient
2. **Verify PreCallClinicalNotesDialog now shows:**
   - ✓ Active Conditions: "Type 2 Diabetes Mellitus", "Hypertension" (2 conditions)
   - ✓ Current Medications: "Metformin 500mg", "Lisinopril 10mg" (2 medications)
   - ✓ Allergies: "Penicillin (severe)" [highlighted in RED, escalated severity]
   - ✓ Surgical History: "Appendectomy (2005)"
   - ✓ Family History: "Father: Hypertension, Mother: Diabetes"
   - ✓ Visit Count Badge: "2" (auto-incremented)
   - ✓ Last Updated: Shows recent timestamp

**Code Verification:**
```dart
// In lib/custom_code/widgets/pre_call_clinical_notes_dialog.dart
final patientProfile = await SupaFlow.client
  .from('patient_profiles')
  .select('cumulative_medical_record, medical_record_last_updated_at, blood_type')
  .eq('user_id', widget.patientId)
  .maybeSingle();

final cumulativeRecord = patientProfile?.cumulativeMedicalRecord;
final conditions = cumulativeRecord?['conditions'] as List?? [];
final medications = cumulativeRecord?['medications'] as List?? [];
final allergies = cumulativeRecord?['allergies'] as List?? [];

// Expected:
// conditions.length == 2 (Diabetes + Hypertension)
// medications.length == 2 (Metformin + Lisinopril)
// allergies[0]['severity'] == 'severe' (escalated)
```

**Expected Result:** ✅ Provider sees enriched history from cumulative_medical_record:
- 2 active conditions (vs. 1 on first visit)
- 2 active medications (vs. 1 on first visit)
- Penicillin allergy now marked as "severe" (escalated)
- Visit count shows "2"

---

## Summary Checklist

| Phase | Test | Result |
|-------|------|--------|
| 1 | Initial patient setup with medical history | ✓ Complete |
| 2 | Context snapshot creation | ✓ Contains cumulative_medical_record data |
| 3 | Pre-call history display | ✓ Shows baseline history |
| 4 | Video call with new clinical findings | ✓ Transcript captured |
| 5 | SOAP generation with Tab 5 pre-population | ✓ Tab 5 includes baseline + new findings |
| 6 | Provider review & edit | ✓ Can add/update medical history |
| 7 | Background cumulative record merge | ✓ Deduplication works, severity escalated |
| 8 | Next visit with enriched history | ✓ Shows updated conditions/meds/allergies |

---

## Critical Success Criteria

✅ **Deduplication:**
- No duplicate conditions (same name + ICD-10)
- No duplicate medications (same name)
- No duplicate allergies (same allergen)
- Severity escalation for allergies (moderate → severe)

✅ **Data Integrity:**
- All cumulative_medical_record timestamps updated
- Audit trail maintained (source_soap_notes array)
- Visit counter incremented correctly
- Status transitions correct (active/resolved/discontinued)

✅ **Performance:**
- Pre-call snapshot retrieval < 2 seconds
- SOAP generation < 60 seconds (with retries)
- Background update doesn't block provider (fire-and-forget)

✅ **User Experience:**
- Provider sees complete history before call
- AI pre-populates Tab 5 with baseline data
- Provider can easily edit/add to history
- Next visit shows enriched history automatically

---

## Troubleshooting

### Issue: Context snapshot missing allergies
**Cause:** `get-patient-history` not returning data from cumulative_medical_record
**Solution:** Verify `update-patient-medical-record` was called and merge_soap_into_cumulative_record succeeded

### Issue: Duplicate conditions appearing
**Cause:** Deduplication logic not working correctly
**Solution:** Check PostgreSQL function merge_soap_into_cumulative_record for case-sensitivity issues

### Issue: SOAP Tab 5 not pre-populated
**Cause:** Context snapshot not being used in generate-soap-draft-v2
**Solution:** Verify buildSoapPrompt includes CONTEXT_SNAPSHOT in prompt

### Issue: Background update not happening
**Cause:** Fire-and-forget async call failing silently
**Solution:** Check `npx supabase functions logs update-patient-medical-record` for errors

---

## Commands for Quick Testing

```bash
# Watch generate-soap-draft-v2 logs
npx supabase functions logs generate-soap-draft-v2 --tail

# Watch update-patient-medical-record logs
npx supabase functions logs update-patient-medical-record --tail

# Reset test patient (if needed)
npx supabase db push  # Apply migrations
DELETE FROM patient_profiles WHERE user_id = '<test-patient-id>';
DELETE FROM users WHERE id = '<test-patient-id>';

# Query cumulative record
psql $DATABASE_URL -c "SELECT cumulative_medical_record FROM patient_profiles WHERE user_id = '<test-patient-id>';"
```

---

**Last Updated:** 2026-01-22
**Status:** Ready for end-to-end testing
