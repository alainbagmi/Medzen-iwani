# Patient Medical History System - E2E Test Execution Guide

## Quick Start (5 min)

**Status: All 4 critical edge functions ACTIVE and deployed**

### Deployed Functions:
- ✅ `create-context-snapshot` (v11) - Pre-call patient context gathering
- ✅ `get-patient-history` (v3) - Historical data retrieval
- ✅ `update-patient-medical-record` (v4) - Post-call medical record merge
- ✅ `generate-soap-draft-v2` (v13) - AI SOAP generation

### Core Migration:
- ✅ `20260117150900_add_cumulative_patient_medical_record.sql` deployed

---

## Phase 1: Database Schema Verification (5 min)

### Verify Columns in patient_profiles

Run this in Supabase SQL Editor:

```sql
SELECT
  column_name,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_name = 'patient_profiles'
  AND column_name IN (
    'cumulative_medical_record',
    'medical_record_last_updated_at',
    'medical_record_last_soap_note_id'
  )
ORDER BY ordinal_position;
```

**Expected:** 3 columns (JSONB, TIMESTAMPTZ, UUID)

### Verify Merge Function

```sql
SELECT proname
FROM pg_proc
WHERE proname = 'merge_soap_into_cumulative_record'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
```

**Expected:** Function exists

### Verify SOAP Tables

```sql
SELECT count(*)
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE 'soap_%';
```

**Expected:** 13+ tables

---

## Phase 2: Test Data Generation (10 min)

### Create Test Patient

```sql
INSERT INTO users (
  firebase_uid, email, first_name, last_name, phone, role
) VALUES (
  'test-' || gen_random_uuid()::text,
  'test-' || floor(random()*100000)::text || '@test.local',
  'Historia', 'Test', '+1-555-0001', 'patient'
) RETURNING id;
-- SAVE as TEST_PATIENT_ID
```

### Create Test Provider

```sql
INSERT INTO users (
  firebase_uid, email, first_name, last_name, phone, role
) VALUES (
  'prov-' || gen_random_uuid()::text,
  'prov-' || floor(random()*100000)::text || '@test.local',
  'Dr. Test', 'Provider', '+1-555-0002', 'medical_provider'
) RETURNING id;
-- SAVE as TEST_PROVIDER_ID

INSERT INTO medical_provider_profiles (user_id, specialty, license_number)
VALUES ('TEST_PROVIDER_ID', 'General Practice', 'LIC-TEST-001');
```

### Create Patient Profile with Empty History

```sql
INSERT INTO patient_profiles (
  user_id, patient_number, blood_type, date_of_birth, gender,
  cumulative_medical_record
) VALUES (
  'TEST_PATIENT_ID',
  'TEST-001',
  'A+',
  '1990-01-01'::date,
  'Female',
  '{"conditions":[],"medications":[],"allergies":[],"surgical_history":[],"family_history":[],"vital_trends":{},"social_history":{},"review_of_systems_trends":{},"physical_exam_findings":{},"metadata":{"total_visits":0,"source_soap_notes":[],"last_updated":null}}'::jsonb
);
```

### Create First Appointment

```sql
INSERT INTO appointments (
  patient_id, provider_id, appointment_type, chief_complaint,
  scheduled_start, scheduled_end, status, start_date, appointment_number
) VALUES (
  'TEST_PATIENT_ID', 'TEST_PROVIDER_ID', 'initial_consultation',
  'Annual checkup - first visit',
  now() + interval '1 hour', now() + interval '2 hours',
  'confirmed', current_date, 'TEST-001'
) RETURNING id;
-- SAVE as TEST_APPOINTMENT_1_ID
```

---

## Phase 3: First Visit - Create SOAP Note (10 min)

### Create SOAP Note

```sql
INSERT INTO soap_notes (
  patient_id, provider_id, appointment_id, session_id, status, chief_complaint
) VALUES (
  'TEST_PATIENT_ID', 'TEST_PROVIDER_ID', 'TEST_APPOINTMENT_1_ID',
  'test-' || gen_random_uuid()::text, 'finalized', 'Annual checkup'
) RETURNING id;
-- SAVE as TEST_SOAP_1_ID
```

### Add Allergies

```sql
INSERT INTO soap_subjective_allergies (soap_note_id, allergen, reaction, severity)
VALUES
  ('TEST_SOAP_1_ID', 'Penicillin', 'Rash', 'moderate'),
  ('TEST_SOAP_1_ID', 'Shellfish', 'Anaphylaxis', 'severe');
```

### Add Diagnoses

```sql
INSERT INTO soap_assessment_problem_list (
  soap_note_id, diagnosis_name, icd10_code, status, severity
) VALUES
  ('TEST_SOAP_1_ID', 'Essential Hypertension', 'I10', 'active', 'mild'),
  ('TEST_SOAP_1_ID', 'Type 2 Diabetes Mellitus', 'E11', 'active', 'moderate');
```

### Add Medications

```sql
INSERT INTO soap_plan_medication (
  soap_note_id, medication_name, dose, route, frequency, status
) VALUES
  ('TEST_SOAP_1_ID', 'Lisinopril', '10mg', 'oral', 'once daily', 'active'),
  ('TEST_SOAP_1_ID', 'Metformin', '500mg', 'oral', 'twice daily', 'active');
```

---

## Phase 4: Update Cumulative Record (5 min)

### Call Edge Function

```bash
curl -X POST \
  'https://noaeltglphdlkbflipit.supabase.co/functions/v1/update-patient-medical-record' \
  -H 'Content-Type: application/json' \
  -H 'apikey: YOUR_ANON_KEY' \
  -H 'x-firebase-token: YOUR_FIREBASE_TOKEN' \
  -d '{"patient_id": "TEST_PATIENT_ID", "soap_note_id": "TEST_SOAP_1_ID"}'
```

**Expected Response:** `{ "success": true, "updated": true }`

### Verify Update

```sql
SELECT
  jsonb_array_length(cumulative_medical_record->'conditions') as cond_count,
  jsonb_array_length(cumulative_medical_record->'medications') as med_count,
  jsonb_array_length(cumulative_medical_record->'allergies') as allergy_count
FROM patient_profiles
WHERE user_id = 'TEST_PATIENT_ID';
```

**Expected:** 2, 2, 2

---

## Phase 5: Second Visit - Deduplication Test (15 min)

### Create Second Appointment

```sql
INSERT INTO appointments (
  patient_id, provider_id, appointment_type, chief_complaint,
  scheduled_start, scheduled_end, status, start_date, appointment_number
) VALUES (
  'TEST_PATIENT_ID', 'TEST_PROVIDER_ID', 'follow_up',
  'Follow-up: BP check, new symptoms',
  now() + interval '8 days', now() + interval '8 days' + interval '1 hour',
  'confirmed', current_date + interval '8 days', 'TEST-002'
) RETURNING id;
-- SAVE as TEST_APPOINTMENT_2_ID
```

### Create Second SOAP Note

```sql
INSERT INTO soap_notes (
  patient_id, provider_id, appointment_id, session_id, status, chief_complaint
) VALUES (
  'TEST_PATIENT_ID', 'TEST_PROVIDER_ID', 'TEST_APPOINTMENT_2_ID',
  'test-' || gen_random_uuid()::text, 'finalized', 'Follow-up visit'
) RETURNING id;
-- SAVE as TEST_SOAP_2_ID
```

### Add Data (Overlapping + New)

```sql
-- Allergies: 1 duplicate (Penicillin), 1 new (Latex)
INSERT INTO soap_subjective_allergies (soap_note_id, allergen, reaction, severity)
VALUES
  ('TEST_SOAP_2_ID', 'Penicillin', 'Rash', 'moderate'),
  ('TEST_SOAP_2_ID', 'Latex', 'Hives', 'mild');

-- Diagnoses: 1 status change, 1 duplicate, 1 new
INSERT INTO soap_assessment_problem_list (
  soap_note_id, diagnosis_name, icd10_code, status, severity
) VALUES
  ('TEST_SOAP_2_ID', 'Essential Hypertension', 'I10', 'controlled', 'mild'),
  ('TEST_SOAP_2_ID', 'Type 2 Diabetes Mellitus', 'E11', 'active', 'moderate'),
  ('TEST_SOAP_2_ID', 'Gastroesophageal Reflux Disease', 'K21', 'active', 'mild');

-- Medications: 1 duplicate, 1 status change, 1 new
INSERT INTO soap_plan_medication (
  soap_note_id, medication_name, dose, route, frequency, status
) VALUES
  ('TEST_SOAP_2_ID', 'Metformin', '500mg', 'oral', 'twice daily', 'active'),
  ('TEST_SOAP_2_ID', 'Lisinopril', '10mg', 'oral', 'once daily', 'discontinued'),
  ('TEST_SOAP_2_ID', 'Omeprazole', '20mg', 'oral', 'once daily', 'active');
```

---

## Phase 6: Verify Deduplication (10 min)

### Update Medical Record

```bash
curl -X POST \
  'https://noaeltglphdlkbflipit.supabase.co/functions/v1/update-patient-medical-record' \
  -H 'Content-Type: application/json' \
  -H 'apikey: YOUR_ANON_KEY' \
  -H 'x-firebase-token: YOUR_FIREBASE_TOKEN' \
  -d '{"patient_id": "TEST_PATIENT_ID", "soap_note_id": "TEST_SOAP_2_ID"}'
```

### Check No Duplicate Penicillin

```sql
SELECT count(*)
FROM (
  SELECT jsonb_array_elements(cumulative_medical_record->'allergies') as allergy
  FROM patient_profiles WHERE user_id = 'TEST_PATIENT_ID'
) sub
WHERE sub.allergy->>'allergen' = 'Penicillin';
```

**Expected:** 1 (NOT 2)

### Check Status Updates

```sql
-- Hypertension should be "controlled"
SELECT c->>'status'
FROM patient_profiles,
  jsonb_array_elements(cumulative_medical_record->'conditions') as c
WHERE user_id = 'TEST_PATIENT_ID'
  AND c->>'name' = 'Essential Hypertension';

-- Lisinopril should be "discontinued"
SELECT m->>'status'
FROM patient_profiles,
  jsonb_array_elements(cumulative_medical_record->'medications') as m
WHERE user_id = 'TEST_PATIENT_ID'
  AND m->>'name' = 'Lisinopril';
```

**Expected:** "controlled", "discontinued"

### Verify Final Counts

```sql
SELECT
  jsonb_array_length(cumulative_medical_record->'conditions') as cond_count,
  jsonb_array_length(cumulative_medical_record->'medications') as med_count,
  jsonb_array_length(cumulative_medical_record->'allergies') as allergy_count
FROM patient_profiles
WHERE user_id = 'TEST_PATIENT_ID';
```

**Expected:** 3, 3, 3

---

## Success Checklist

- [ ] Database schema verified (3 columns)
- [ ] Merge function exists
- [ ] 13+ SOAP tables exist
- [ ] First SOAP note created (2 conditions, 2 medications, 2 allergies)
- [ ] Cumulative record updated after first visit
- [ ] Counts verified (2, 2, 2)
- [ ] Second SOAP note created with overlapping + new data
- [ ] Deduplication verified (Penicillin appears once)
- [ ] Status updates verified
- [ ] Final counts verified (3, 3, 3)
- [ ] No data loss from first visit

---

## Cleanup (2 min)

```sql
DELETE FROM soap_notes WHERE patient_id IN ('TEST_PATIENT_ID');
DELETE FROM appointments WHERE patient_id IN ('TEST_PATIENT_ID');
DELETE FROM patient_profiles WHERE user_id IN ('TEST_PATIENT_ID', 'TEST_PROVIDER_ID');
DELETE FROM medical_provider_profiles WHERE user_id = 'TEST_PROVIDER_ID';
DELETE FROM users WHERE id IN ('TEST_PATIENT_ID', 'TEST_PROVIDER_ID');
```

