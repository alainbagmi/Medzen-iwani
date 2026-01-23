# Patient Medical History System - E2E Test Execution Instructions

**Status:** ✅ Ready to Execute
**Date:** January 22, 2026
**All 4 Critical Functions:** ACTIVE and Deployed
**Deployment Status:** PRODUCTION READY

---

## Quick Verification Checklist

- [x] Migration 20260117150900 deployed
- [x] create-context-snapshot (v11) ACTIVE - 2026-01-22 12:21:46
- [x] get-patient-history (v3) ACTIVE - 2026-01-22 12:21:32
- [x] update-patient-medical-record (v4) ACTIVE - 2026-01-22 12:21:44
- [x] generate-soap-draft-v2 (v13) ACTIVE - 2026-01-22 12:21:49

---

## E2E Test Overview

**What This Tests:**
- Patient medical history accumulation across multiple visits
- Deduplication of duplicate allergies, medications, and conditions
- Status updates (active → controlled, active → discontinued)
- New data merging from subsequent visits
- System end-to-end workflow

**Expected Duration:** 60 minutes
**Test Data:** Will be completely cleaned up after test
**Production Impact:** ZERO (test data only)

---

## Prerequisites

You'll need:
1. Access to Supabase SQL Editor (or `psql` CLI)
2. Valid Firebase authentication token
3. Supabase ANON_KEY
4. `curl` command available (for edge function testing)

---

## Phase 1: Database Schema Verification (5 min)

### Step 1: Open Supabase SQL Editor

Go to: `https://supabase.com/dashboard/project/noaeltglphdlkbflipit/sql`

### Step 2: Verify Columns Exist

Copy and paste this query into the SQL Editor and run:

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

**Expected Result:**
```
column_name                          | data_type  | column_default
cumulative_medical_record            | jsonb      |
medical_record_last_soap_note_id     | uuid       |
medical_record_last_updated_at       | timestamptz|
```

✅ **Expected:** 3 rows returned

### Step 3: Verify Merge Function Exists

```sql
SELECT proname, pronargs
FROM pg_proc
WHERE proname = 'merge_soap_into_cumulative_record'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
```

✅ **Expected:** 1 row returned, pronargs = 3

### Step 4: Verify SOAP Tables

```sql
SELECT count(*) as table_count
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE 'soap_%';
```

✅ **Expected:** 13+ rows

---

## Phase 2: Test Data Setup (10 min)

### Step 5: Create Test Patient

```sql
INSERT INTO users (
  firebase_uid, email, first_name, last_name, phone, role
) VALUES (
  'test-history-' || gen_random_uuid()::text,
  'test-history-' || floor(random()*10000)::text || '@medzen.local',
  'Historia', 'TestPatient', '+1-555-TEST', 'patient'
) RETURNING id, email;
```

**IMPORTANT:** Copy the returned `id` value and **save it as `TEST_PATIENT_ID`**

Example: `28a2d4a8-b5c2-4f3e-9d12-abc123456789`

### Step 6: Create Test Provider

```sql
INSERT INTO users (
  firebase_uid, email, first_name, last_name, phone, role
) VALUES (
  'test-provider-' || gen_random_uuid()::text,
  'test-provider-' || floor(random()*10000)::text || '@medzen.local',
  'Dr. Test', 'Provider', '+1-555-PROV', 'medical_provider'
) RETURNING id, email;
```

**IMPORTANT:** Copy the returned `id` value and **save it as `TEST_PROVIDER_ID`**

Example: `95f8e7c9-2d1a-4b6e-8c3f-def456789012`

### Step 7: Create Provider Profile

```sql
INSERT INTO medical_provider_profiles (
  user_id, specialty, license_number
) VALUES (
  'TEST_PROVIDER_ID_HERE',  -- Replace with your TEST_PROVIDER_ID
  'General Practice',
  'LIC-TEST-123'
);
```

### Step 8: Create Patient Profile with Empty Medical History

```sql
INSERT INTO patient_profiles (
  user_id, patient_number, blood_type, date_of_birth, gender,
  cumulative_medical_record
) VALUES (
  'TEST_PATIENT_ID_HERE',  -- Replace with your TEST_PATIENT_ID
  'TEST-' || to_char(now(), 'YYYYMMDDHH24MISS'),
  'A+',
  '1990-05-20'::date,
  'Female',
  '{
    "conditions": [],
    "medications": [],
    "allergies": [],
    "surgical_history": [],
    "family_history": [],
    "vital_trends": {},
    "social_history": {},
    "review_of_systems_trends": {},
    "physical_exam_findings": {},
    "metadata": {
      "total_visits": 0,
      "source_soap_notes": [],
      "last_updated": null
    }
  }'::jsonb
);
```

✅ **Expected:** 1 row affected

### Step 9: Create First Appointment

```sql
INSERT INTO appointments (
  patient_id, provider_id, appointment_type, chief_complaint,
  scheduled_start, scheduled_end, status, start_date, appointment_number
) VALUES (
  'TEST_PATIENT_ID_HERE',  -- Replace with your TEST_PATIENT_ID
  'TEST_PROVIDER_ID_HERE',  -- Replace with your TEST_PROVIDER_ID
  'initial_consultation',
  'Annual checkup - first visit',
  now() + interval '1 hour',
  now() + interval '2 hours',
  'confirmed',
  current_date,
  'TEST-001'
) RETURNING id;
```

**IMPORTANT:** Copy the returned `id` value and **save it as `TEST_APPOINTMENT_1_ID`**

---

## Phase 3: First Visit - Create SOAP Note (10 min)

### Step 10: Create First SOAP Note

```sql
INSERT INTO soap_notes (
  patient_id, provider_id, appointment_id, session_id, status, chief_complaint
) VALUES (
  'TEST_PATIENT_ID_HERE',  -- Replace with your TEST_PATIENT_ID
  'TEST_PROVIDER_ID_HERE',  -- Replace with your TEST_PROVIDER_ID
  'TEST_APPOINTMENT_1_ID_HERE',  -- Replace with your TEST_APPOINTMENT_1_ID
  'test-session-' || gen_random_uuid()::text,
  'finalized',
  'Annual checkup - first visit'
) RETURNING id;
```

**IMPORTANT:** Copy the returned `id` value and **save it as `TEST_SOAP_1_ID`**

### Step 11: Add Allergies to First SOAP Note

```sql
INSERT INTO soap_subjective_allergies (
  soap_note_id, allergen, reaction, severity
) VALUES
  ('TEST_SOAP_1_ID_HERE', 'Penicillin', 'Rash', 'moderate'),
  ('TEST_SOAP_1_ID_HERE', 'Shellfish', 'Anaphylaxis', 'severe');
```

✅ **Expected:** 2 rows affected

### Step 12: Add Diagnoses to First SOAP Note

```sql
INSERT INTO soap_assessment_problem_list (
  soap_note_id, diagnosis_name, icd10_code, status, severity
) VALUES
  ('TEST_SOAP_1_ID_HERE', 'Essential Hypertension', 'I10', 'active', 'mild'),
  ('TEST_SOAP_1_ID_HERE', 'Type 2 Diabetes Mellitus', 'E11', 'active', 'moderate');
```

✅ **Expected:** 2 rows affected

### Step 13: Add Medications to First SOAP Note

```sql
INSERT INTO soap_plan_medication (
  soap_note_id, medication_name, dose, route, frequency, status
) VALUES
  ('TEST_SOAP_1_ID_HERE', 'Lisinopril', '10mg', 'oral', 'once daily', 'active'),
  ('TEST_SOAP_1_ID_HERE', 'Metformin', '500mg', 'oral', 'twice daily', 'active');
```

✅ **Expected:** 2 rows affected

---

## Phase 4: Update Cumulative Record (5 min)

### Step 14: Get Your Credentials

You'll need:
- **SUPABASE_ANON_KEY**: From Supabase dashboard (Settings → API)
- **FIREBASE_TOKEN**: Get from your Flutter app or Firebase console
- **SUPABASE_URL**: `https://noaeltglphdlkbflipit.supabase.co`

### Step 15: Call Edge Function to Update Medical Record

Open your terminal and run:

```bash
curl -X POST \
  'https://noaeltglphdlkbflipit.supabase.co/functions/v1/update-patient-medical-record' \
  -H 'Content-Type: application/json' \
  -H 'apikey: YOUR_SUPABASE_ANON_KEY' \
  -H 'x-firebase-token: YOUR_FIREBASE_TOKEN' \
  -d '{
    "patient_id": "TEST_PATIENT_ID_HERE",
    "soap_note_id": "TEST_SOAP_1_ID_HERE"
  }'
```

Replace:
- `YOUR_SUPABASE_ANON_KEY` with your anon key
- `YOUR_FIREBASE_TOKEN` with a valid token
- `TEST_PATIENT_ID_HERE` with your TEST_PATIENT_ID
- `TEST_SOAP_1_ID_HERE` with your TEST_SOAP_1_ID

**Expected Response:**
```json
{
  "success": true,
  "updated": true,
  "message": "Medical record updated successfully"
}
```

### Step 16: Verify Cumulative Record Updated

Run this in SQL Editor:

```sql
SELECT
  jsonb_pretty(cumulative_medical_record) as record,
  medical_record_last_updated_at,
  medical_record_last_soap_note_id
FROM patient_profiles
WHERE user_id = 'TEST_PATIENT_ID_HERE';
```

✅ **Expected:**
- `cumulative_medical_record` contains 2 conditions, 2 medications, 2 allergies
- `medical_record_last_updated_at` is very recent (just now)
- `medical_record_last_soap_note_id` = TEST_SOAP_1_ID

### Step 17: Verify Exact Counts

```sql
SELECT
  jsonb_array_length(cumulative_medical_record->'conditions') as condition_count,
  jsonb_array_length(cumulative_medical_record->'medications') as medication_count,
  jsonb_array_length(cumulative_medical_record->'allergies') as allergy_count
FROM patient_profiles
WHERE user_id = 'TEST_PATIENT_ID_HERE';
```

✅ **Expected:** 2, 2, 2

---

## Phase 5: Second Visit - Deduplication Test (15 min)

### Step 18: Create Second Appointment

```sql
INSERT INTO appointments (
  patient_id, provider_id, appointment_type, chief_complaint,
  scheduled_start, scheduled_end, status, start_date, appointment_number
) VALUES (
  'TEST_PATIENT_ID_HERE',
  'TEST_PROVIDER_ID_HERE',
  'follow_up',
  'Follow-up: BP check, new symptoms',
  now() + interval '8 days',
  now() + interval '8 days' + interval '1 hour',
  'confirmed',
  current_date + interval '8 days',
  'TEST-002'
) RETURNING id;
```

**IMPORTANT:** Copy the returned `id` and **save it as `TEST_APPOINTMENT_2_ID`**

### Step 19: Create Second SOAP Note

```sql
INSERT INTO soap_notes (
  patient_id, provider_id, appointment_id, session_id, status, chief_complaint
) VALUES (
  'TEST_PATIENT_ID_HERE',
  'TEST_PROVIDER_ID_HERE',
  'TEST_APPOINTMENT_2_ID_HERE',
  'test-session-' || gen_random_uuid()::text,
  'finalized',
  'Follow-up visit'
) RETURNING id;
```

**IMPORTANT:** Copy the returned `id` and **save it as `TEST_SOAP_2_ID`**

### Step 20: Add Data to Second SOAP (Overlapping + New)

**Allergies (1 duplicate + 1 new):**
```sql
INSERT INTO soap_subjective_allergies (
  soap_note_id, allergen, reaction, severity
) VALUES
  ('TEST_SOAP_2_ID_HERE', 'Penicillin', 'Rash', 'moderate'),  -- DUPLICATE
  ('TEST_SOAP_2_ID_HERE', 'Latex', 'Hives', 'mild');  -- NEW
```

**Diagnoses (1 status change + 1 duplicate + 1 new):**
```sql
INSERT INTO soap_assessment_problem_list (
  soap_note_id, diagnosis_name, icd10_code, status, severity
) VALUES
  ('TEST_SOAP_2_ID_HERE', 'Essential Hypertension', 'I10', 'controlled', 'mild'),  -- Status: active → controlled
  ('TEST_SOAP_2_ID_HERE', 'Type 2 Diabetes Mellitus', 'E11', 'active', 'moderate'),  -- DUPLICATE
  ('TEST_SOAP_2_ID_HERE', 'Gastroesophageal Reflux Disease', 'K21', 'active', 'mild');  -- NEW
```

**Medications (1 duplicate + 1 status change + 1 new):**
```sql
INSERT INTO soap_plan_medication (
  soap_note_id, medication_name, dose, route, frequency, status
) VALUES
  ('TEST_SOAP_2_ID_HERE', 'Metformin', '500mg', 'oral', 'twice daily', 'active'),  -- DUPLICATE
  ('TEST_SOAP_2_ID_HERE', 'Lisinopril', '10mg', 'oral', 'once daily', 'discontinued'),  -- Status: active → discontinued
  ('TEST_SOAP_2_ID_HERE', 'Omeprazole', '20mg', 'oral', 'once daily', 'active');  -- NEW
```

---

## Phase 6: Verify Deduplication (10 min)

### Step 21: Call Edge Function Again

```bash
curl -X POST \
  'https://noaeltglphdlkbflipit.supabase.co/functions/v1/update-patient-medical-record' \
  -H 'Content-Type: application/json' \
  -H 'apikey: YOUR_SUPABASE_ANON_KEY' \
  -H 'x-firebase-token: YOUR_FIREBASE_TOKEN' \
  -d '{
    "patient_id": "TEST_PATIENT_ID_HERE",
    "soap_note_id": "TEST_SOAP_2_ID_HERE"
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "updated": true,
  "message": "Medical record updated successfully"
}
```

### Step 22: Verify Final Counts

```sql
SELECT
  jsonb_array_length(cumulative_medical_record->'conditions') as condition_count,
  jsonb_array_length(cumulative_medical_record->'medications') as medication_count,
  jsonb_array_length(cumulative_medical_record->'allergies') as allergy_count
FROM patient_profiles
WHERE user_id = 'TEST_PATIENT_ID_HERE';
```

✅ **Expected:** 3, 3, 3 (NOT 4, 4, 4)

### Step 23: Verify Penicillin Not Duplicated

```sql
SELECT count(*) as penicillin_count
FROM (
  SELECT jsonb_array_elements(cumulative_medical_record->'allergies') as allergy
  FROM patient_profiles
  WHERE user_id = 'TEST_PATIENT_ID_HERE'
) sub
WHERE sub.allergy->>'allergen' = 'Penicillin';
```

✅ **Expected:** 1 (NOT 2)

### Step 24: Verify Status Updates

**Check Hypertension Status:**
```sql
SELECT c->>'status' as hypertension_status
FROM patient_profiles,
  jsonb_array_elements(cumulative_medical_record->'conditions') as c
WHERE user_id = 'TEST_PATIENT_ID_HERE'
  AND c->>'name' = 'Essential Hypertension';
```

✅ **Expected:** "controlled"

**Check Lisinopril Status:**
```sql
SELECT m->>'status' as lisinopril_status
FROM patient_profiles,
  jsonb_array_elements(cumulative_medical_record->'medications') as m
WHERE user_id = 'TEST_PATIENT_ID_HERE'
  AND m->>'name' = 'Lisinopril';
```

✅ **Expected:** "discontinued"

### Step 25: View Complete Merged Record

```sql
SELECT jsonb_pretty(cumulative_medical_record) as complete_record
FROM patient_profiles
WHERE user_id = 'TEST_PATIENT_ID_HERE';
```

You should see:
- 3 conditions (Hypertension, Diabetes, GERD)
- 3 medications (Lisinopril-discontinued, Metformin-active, Omeprazole-active)
- 3 allergies (Penicillin, Shellfish, Latex)
- No duplicates
- Status updates reflected

---

## Success Checklist

- [ ] Phase 1: Database schema verified (3 columns, 1 function, 13+ tables)
- [ ] Phase 2: Test data created (patient, provider, 1 appointment)
- [ ] Phase 3: First SOAP note created (2 allergies, 2 diagnoses, 2 meds)
- [ ] Phase 4: First cumulative update successful (counts: 2, 2, 2)
- [ ] Phase 5: Second SOAP note created (with overlapping + new data)
- [ ] Phase 6a: Second update successful (counts: 3, 3, 3)
- [ ] Phase 6b: No duplicate Penicillin (count: 1)
- [ ] Phase 6c: Hypertension status = "controlled"
- [ ] Phase 6d: Lisinopril status = "discontinued"
- [ ] All verification queries pass

---

## Cleanup (2 min)

When you're done testing, clean up test data:

```sql
-- Delete in correct order (foreign keys)
DELETE FROM soap_plan_medication WHERE soap_note_id IN (
  SELECT id FROM soap_notes WHERE patient_id = 'TEST_PATIENT_ID_HERE'
);

DELETE FROM soap_assessment_problem_list WHERE soap_note_id IN (
  SELECT id FROM soap_notes WHERE patient_id = 'TEST_PATIENT_ID_HERE'
);

DELETE FROM soap_subjective_allergies WHERE soap_note_id IN (
  SELECT id FROM soap_notes WHERE patient_id = 'TEST_PATIENT_ID_HERE'
);

DELETE FROM soap_notes WHERE patient_id = 'TEST_PATIENT_ID_HERE';
DELETE FROM appointments WHERE patient_id = 'TEST_PATIENT_ID_HERE';
DELETE FROM patient_profiles WHERE user_id IN ('TEST_PATIENT_ID_HERE');
DELETE FROM medical_provider_profiles WHERE user_id = 'TEST_PROVIDER_ID_HERE';
DELETE FROM users WHERE id IN ('TEST_PATIENT_ID_HERE', 'TEST_PROVIDER_ID_HERE');
```

---

## Troubleshooting

### Error: `401 INVALID_FIREBASE_TOKEN`
- Make sure `x-firebase-token` header is lowercase
- Get a fresh token from Firebase console
- Ensure you're using `--token` flag if using Firebase CLI

### Error: `403 Forbidden` on SQL queries
- Verify you're authenticated in Supabase dashboard
- Check RLS policies are allowing your user role

### Edge function returns 500
- Check function logs: `npx supabase functions logs update-patient-medical-record --tail`
- Verify environment variables are set
- Ensure Firebase token is valid

### Counts are wrong (4, 4, 4 instead of 3, 3, 3)
- The merge function deduplication may not have run
- Check the function logs for errors
- Verify the merge function is being called

---

## Contact & Support

- **Deployment Issues:** IT/DevOps Team
- **Clinical Questions:** Medical Director
- **For E2E Test Help:** See function logs via `npx supabase functions logs [function-name] --tail`

---

## Document Info

**Status:** Ready to Execute
**Date:** January 22, 2026
**System:** Patient Medical History System
**Deployment:** PRODUCTION (v1.0)
**Test Duration:** ~60 minutes
**Test Data:** Will be deleted after test

✅ **All prerequisites met. System ready for E2E testing.**
