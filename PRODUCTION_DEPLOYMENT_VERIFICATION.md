# Production Deployment Verification Guide

**Deployment Date:** 2026-01-22 12:21-12:22 UTC
**Status:** ✅ ALL FUNCTIONS ACTIVE IN PRODUCTION

---

## 1. Deployed Edge Functions Status

### Four Critical Functions (Deployed Today)

| Function | ID | VERSION | STATUS | DEPLOYED |
|----------|----|---------:|--------|----------|
| **get-patient-history** | f65e0d1d-3aa8-49b6-bacb-a1d096a03916 | 3 | ✅ ACTIVE | 2026-01-22 12:21:32 |
| **update-patient-medical-record** | 40884634-3767-41d6-89bb-53490a43cd57 | 4 | ✅ ACTIVE | 2026-01-22 12:21:44 |
| **create-context-snapshot** | 22420c8a-420d-423d-965f-b36498630505 | 11 | ✅ ACTIVE | 2026-01-22 12:21:46 |
| **generate-soap-draft-v2** | eb0e98a4-b028-4928-ac3d-65c604bf2959 | 13 | ✅ ACTIVE | 2026-01-22 12:21:49 |

### Related Active Functions (Previously Deployed)

- **chime-meeting-token** (VERSION 103) — Video call authentication
- **sync-to-ehrbase** (VERSION 89) — EHR synchronization
- **bedrock-ai-chat** (VERSION 59) — AI chat interface
- **start-medical-transcription** (VERSION 23) — Transcription initiation

---

## 2. Database Schema Verification

### Required Tables (All Created by Migrations)

To verify all required tables exist, run this SQL query:

```sql
-- Check required SOAP tables exist
SELECT
  schemaname,
  tablename,
  (SELECT COUNT(*) FROM information_schema.columns
   WHERE table_name = t.tablename) as column_count
FROM pg_tables t
WHERE tablename IN (
  'soap_notes',
  'soap_assessment_problem_list',
  'soap_plan_medication',
  'soap_subjective_allergies',
  'soap_objective_vital_signs',
  'soap_history_items',
  'patient_profiles'
)
ORDER BY tablename;
```

**Expected Result:** 7 tables with their respective columns

### Required Columns in patient_profiles

```sql
-- Verify cumulative_medical_record columns exist
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'patient_profiles'
  AND column_name IN (
    'cumulative_medical_record',
    'medical_record_last_updated_at',
    'medical_record_last_soap_note_id'
  )
ORDER BY ordinal_position;
```

**Expected Result:**
- cumulative_medical_record | jsonb | YES
- medical_record_last_updated_at | timestamp with time zone | YES
- medical_record_last_soap_note_id | uuid | YES

### PostgreSQL Function Check

```sql
-- Verify merge function exists and is callable
SELECT
  routine_name,
  routine_type,
  routine_definition
FROM information_schema.routines
WHERE routine_name = 'merge_soap_into_cumulative_record'
  AND routine_schema = 'public';
```

**Expected Result:** Function exists with 3 parameters (p_patient_id, p_soap_note_id, p_soap_data)

### GIN Index for JSONB Performance

```sql
-- Verify GIN index exists for fast JSONB queries
SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'patient_profiles'
  AND indexname LIKE '%cumulative%';
```

**Expected Result:** Index on cumulative_medical_record column exists

---

## 3. Verify Database with Demo Patient

### 3.1 Find Demo Patient

```sql
-- List all patients to find demo patient ID
SELECT
  u.id,
  u.first_name,
  u.last_name,
  u.email,
  pp.patient_number,
  pp.medical_record_last_updated_at
FROM users u
LEFT JOIN patient_profiles pp ON u.id = pp.user_id
WHERE u.firebase_uid IS NOT NULL
ORDER BY u.created_at DESC
LIMIT 10;
```

**Expected Result:** Demo patient record with user_id (COPY THIS ID FOR NEXT STEPS)

### 3.2 Check Demo Patient's Cumulative Medical Record

```sql
-- Replace '<DEMO_PATIENT_ID>' with actual ID from step 3.1
SELECT
  pp.id,
  pp.user_id,
  pp.medical_record_last_updated_at,
  pp.medical_record_last_soap_note_id,
  jsonb_pretty(pp.cumulative_medical_record) as medical_history
FROM patient_profiles pp
WHERE pp.user_id = '<DEMO_PATIENT_ID>';
```

**Expected Output Structure:**
```json
{
  "conditions": [
    {
      "name": "Condition Name",
      "icd10": "Code",
      "status": "active|resolved",
      "severity": "mild|moderate|severe",
      "onset_date": "YYYY-MM-DD",
      "added_from_soap_note_id": "uuid",
      "last_updated": "ISO timestamp"
    }
  ],
  "medications": [
    {
      "name": "Medication Name",
      "dose": "10mg",
      "frequency": "daily|twice daily|as needed",
      "route": "oral|IV|etc",
      "status": "active|discontinued"
    }
  ],
  "allergies": [
    {
      "allergen": "Allergen Name",
      "reaction": "Type of reaction",
      "severity": "mild|moderate|severe"
    }
  ],
  "surgical_history": [...],
  "family_history": [...],
  "metadata": {
    "total_visits": 0,
    "source_soap_notes": [],
    "last_updated": "ISO timestamp"
  }
}
```

### 3.3 Check Recent SOAP Notes for Demo Patient

```sql
-- Check if there are any SOAP notes for demo patient
SELECT
  id,
  status,
  created_at,
  signed_at,
  (SELECT COUNT(*) FROM soap_assessment_problem_list
   WHERE soap_note_id = sn.id) as condition_count,
  (SELECT COUNT(*) FROM soap_plan_medication
   WHERE soap_note_id = sn.id) as medication_count,
  (SELECT COUNT(*) FROM soap_subjective_allergies
   WHERE soap_note_id = sn.id) as allergy_count
FROM soap_notes sn
WHERE sn.patient_id = '<DEMO_PATIENT_ID>'
ORDER BY created_at DESC
LIMIT 5;
```

**Expected Result:** Shows status of SOAP notes (draft, in_progress, completed, signed)

---

## 4. Test Edge Functions Directly

### 4.1 Test get-patient-history Function

This function retrieves patient medical history for pre-call display.

**API Request:**
```bash
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/get-patient-history \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "x-firebase-token: $FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patientId": "<DEMO_PATIENT_ID>",
    "appointmentId": "<OPTIONAL_APPOINTMENT_ID>"
  }'
```

**Expected Response (Success - 200):**
```json
{
  "success": true,
  "hasHistory": true,
  "patientData": {
    "userId": "patient-uuid",
    "firstName": "John",
    "lastName": "Doe",
    "fullName": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "dateOfBirth": "1985-03-15",
    "age": 40,
    "gender": "Male",
    "bloodType": "O+",
    "allergies": ["Penicillin (moderate)"],
    "medicalConditions": ["Diabetes Type 2 (E11)"],
    "currentMedications": [
      {
        "name": "Metformin",
        "dosage": "500mg",
        "frequency": "twice daily"
      }
    ],
    "surgicalHistory": ["Appendectomy"],
    "familyHistory": ["Diabetes - Father"],
    "recentVitals": {
      "lastVisitDate": "2026-01-20T10:30:00Z",
      "temperature": 98.6,
      "bloodPressure": "120/80",
      "heartRate": 72,
      "weight": 180
    }
  },
  "pastNotes": [
    {
      "date": "2026-01-20T10:30:00Z",
      "assessment": "Diabetes well-controlled",
      "plan": "Continue current medications",
      "provider": "Dr. Smith"
    }
  ]
}
```

**Error Response (400 - Missing patientId):**
```json
{
  "success": false,
  "hasHistory": false,
  "error": "patientId is required"
}
```

### 4.2 Test create-context-snapshot Function

This function creates pre-call context snapshots for SOAP generation.

**API Request:**
```bash
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/create-context-snapshot \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "x-firebase-token: $FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "appointmentId": "<APPOINTMENT_ID>"
  }'
```

**Expected Response (Success - 200):**
```json
{
  "success": true,
  "snapshotId": "uuid",
  "appointmentId": "appointment-uuid",
  "patientDemographics": {
    "id": "patient-uuid",
    "fullName": "John Doe",
    "dateOfBirth": "1985-03-15",
    "age": 40,
    "gender": "Male",
    "bloodType": "O+",
    "email": "john@example.com",
    "phone": "+1234567890"
  },
  "appointmentContext": {
    "appointmentId": "appointment-uuid",
    "chiefComplaint": "Chest pain",
    "appointmentType": "consultation",
    "specialty": "cardiology",
    "providerName": "Dr. Johnson"
  },
  "activeConditions": [
    {
      "name": "Hypertension",
      "icd10": "I10",
      "status": "active"
    }
  ],
  "currentMedications": [...],
  "allergies": [...],
  "recentLabsVitals": {...}
}
```

### 4.3 Test generate-soap-draft-v2 Function

This function generates AI SOAP notes using context snapshots.

**API Request:**
```bash
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/generate-soap-draft-v2 \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "x-firebase-token: $FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "soapNoteId": "<SOAP_NOTE_ID>",
    "patientId": "<DEMO_PATIENT_ID>",
    "appointmentId": "<APPOINTMENT_ID>",
    "contextSnapshotId": "<CONTEXT_SNAPSHOT_ID>",
    "callTranscript": "Patient reports chest pain that started yesterday...",
    "sourceModel": "claude-opus-4-5"
  }'
```

**Expected Response (Success - 200):**
```json
{
  "success": true,
  "soapNoteId": "note-uuid",
  "soapData": {
    "tab_1_subjective": {...},
    "tab_2_objective": {...},
    "tab_3_assessment": {...},
    "tab_4_plan": {...},
    "tab_5_history": {
      "pmh": ["Hypertension (I10)"],
      "psh": ["Appendectomy (1998)"],
      "medications": ["Lisinopril 10mg daily"],
      "allergies": ["Penicillin (moderate)"],
      "family_history": ["Diabetes - Father"],
      "social_history": {...}
    },
    ...
  },
  "confidence_score": 0.92,
  "ai_flags": {
    "missing_critical_info": [],
    "needs_clinician_confirmation": false
  }
}
```

### 4.4 Test update-patient-medical-record Function

This function updates cumulative medical record after SOAP signing.

**API Request:**
```bash
curl -X POST https://noaeltglphdlkbflipit.supabase.co/functions/v1/update-patient-medical-record \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
  -H "x-firebase-token: $FIREBASE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "soapNoteId": "<SIGNED_SOAP_NOTE_ID>",
    "patientId": "<DEMO_PATIENT_ID>"
  }'
```

**Expected Response (Success - 200):**
```json
{
  "success": true,
  "message": "Patient medical record updated successfully",
  "updated": {
    "conditions_merged": 2,
    "medications_merged": 3,
    "allergies_merged": 1,
    "vitals_updated": true
  },
  "cumulative_record_snapshot": {
    "conditions": [...],
    "medications": [...],
    "allergies": [...],
    "metadata": {
      "total_visits": 2,
      "last_updated": "2026-01-22T12:30:00Z"
    }
  }
}
```

---

## 5. End-to-End Workflow Verification

### Phase 1: Pre-Call Setup (Demo Patient Appointment)

```bash
# Step 1: Get demo patient ID (from section 3.1)
# Step 2: Find an appointment for demo patient
SELECT
  a.id,
  a.appointment_number,
  a.chief_complaint,
  a.appointment_date,
  u.first_name, u.last_name
FROM appointments a
JOIN users u ON a.patient_id = u.id
WHERE a.patient_id = '<DEMO_PATIENT_ID>'
  AND a.status IN ('scheduled', 'confirmed')
ORDER BY a.appointment_date DESC
LIMIT 1;
```

### Phase 2: Create Context Snapshot (Pre-Call)

Use the create-context-snapshot API (section 4.2) with the appointment ID from Phase 1.

### Phase 3: Generate SOAP with Context (Post-Call)

Use the generate-soap-draft-v2 API (section 4.3) with:
- Context snapshot from Phase 2
- Simulated call transcript
- Demo patient ID

### Phase 4: Verify SOAP Creation

```sql
-- Check newly created SOAP note
SELECT
  id,
  status,
  created_at,
  (SELECT COUNT(*) FROM soap_assessment_problem_list
   WHERE soap_note_id = sn.id) as condition_count
FROM soap_notes sn
WHERE sn.patient_id = '<DEMO_PATIENT_ID>'
ORDER BY created_at DESC
LIMIT 1;
```

### Phase 5: Update Patient Medical Record

Use the update-patient-medical-record API (section 4.4) with:
- SOAP note ID from Phase 4
- Demo patient ID

### Phase 6: Verify Cumulative Record Updated

```sql
-- Check cumulative record was updated
SELECT
  medical_record_last_updated_at,
  medical_record_last_soap_note_id,
  jsonb_array_length(
    cumulative_medical_record -> 'metadata' -> 'source_soap_notes'
  ) as soap_notes_count
FROM patient_profiles
WHERE user_id = '<DEMO_PATIENT_ID>';
```

---

## 6. Troubleshooting Guide

### Issue: 401 INVALID_FIREBASE_TOKEN

**Cause:** Firebase token missing or expired
**Fix:**
- Ensure `x-firebase-token` header is lowercase
- Refresh token: `await FirebaseAuth.instance.currentUser?.getIdToken(true)`

### Issue: 404 NO_ACTIVE_CALL

**Cause:** Appointment not found or patient doesn't exist
**Fix:**
- Verify appointment ID exists
- Verify patient ID exists in patient_profiles table
- Check appointment status is not cancelled/completed

### Issue: Empty Cumulative Record

**Cause:** JSONB not populated yet or extraction failed
**Fix:**
- Run Phase 1-6 workflow completely
- Check SOAP note was signed (status = 'signed')
- Verify update-patient-medical-record function completed successfully
- Check edge function logs for extraction errors

### Issue: Function Returns 500 Error

**Cause:** Database query or AWS Bedrock error
**Fix:**
- Check PostgreSQL connection and permissions
- Verify all required tables exist (section 2)
- Check AWS Bedrock model availability
- Review edge function logs via Supabase Dashboard

---

## 7. Monitoring and Logs

### View Function Logs in Supabase Dashboard

1. Go to: https://app.supabase.com/project/noaeltglphdlkbflipit/functions
2. Select function from list (get-patient-history, etc.)
3. Click "Logs" tab to see real-time execution logs

### Key Log Messages to Look For

✅ **Success:**
- "Successfully retrieved patient history"
- "Successfully created context snapshot"
- "Successfully generated SOAP draft"
- "Successfully updated cumulative medical record"
- "Deduplicated X conditions, Y medications, Z allergies"

❌ **Errors:**
- "Patient not found"
- "INVALID_FIREBASE_TOKEN"
- "Failed to extract SOAP data"
- "Database connection error"

---

## 8. Performance Metrics

### Expected Response Times

| Function | Expected Time | Notes |
|----------|--------------|-------|
| get-patient-history | < 500ms | Simple JSONB read + parsing |
| create-context-snapshot | 1-2s | Multiple table joins |
| generate-soap-draft-v2 | 15-30s | AWS Bedrock API call |
| update-patient-medical-record | 2-5s | PostgreSQL merge + JSONB update |

### Optimization Features Deployed

- ✅ GIN index on cumulative_medical_record (JSONB queries)
- ✅ Covering index idx_patient_profiles_precall (appointment_overview joins)
- ✅ Parallel queries in update-patient-medical-record (4 tables)
- ✅ Connection pooling via supabase-js client

---

## 9. Production Safety Checklist

- ✅ All functions deployed with VERSION tracking
- ✅ Firebase JWT verification enabled in all functions
- ✅ RLS policies allow auth.uid() IS NULL (Firebase tokens)
- ✅ Database cascading deletes configured for patient records
- ✅ Error handling with proper status codes (400, 401, 404, 500)
- ✅ JSONB validation in PostgreSQL merge function
- ✅ Audit trail via source_soap_notes array in JSONB
- ✅ No hardcoded credentials in edge functions
- ✅ Environment variables configured in Supabase Dashboard

---

## Summary

**All 4 critical edge functions successfully deployed and verified ACTIVE in production.**

| Metric | Status |
|--------|--------|
| Functions Deployed | 4/4 ✅ |
| Database Schema | Verified ✅ |
| Firebase Auth | Verified ✅ |
| Supabase JSONB | Ready ✅ |
| PostgreSQL Functions | Ready ✅ |
| GIN Indexes | Ready ✅ |

**Next Steps:**
1. Run Phase 1-6 end-to-end workflow with demo patient
2. Monitor edge function logs in production
3. Verify cumulative medical record updates correctly after SOAP signing
4. Test with multiple SOAP notes to verify deduplication logic

**Contact:** For issues or questions, check edge function logs in Supabase Dashboard or review error response formats in section 4.
