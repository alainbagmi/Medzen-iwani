-- Empty all EHRbase-related tables
-- WARNING: This will delete all EHR sync queue data and electronic health records
-- This is a DESTRUCTIVE operation and should only be run in development/testing

BEGIN;

-- 1. Delete all entries from ehrbase_sync_queue
DELETE FROM ehrbase_sync_queue;

-- 2. Delete all entries from electronic_health_records
DELETE FROM electronic_health_records;

-- Optional: Delete all medical data that syncs to EHRbase
-- Uncomment the sections below if you also want to delete all medical records

/*
-- Medical Records
DELETE FROM vital_signs;
DELETE FROM lab_results;
DELETE FROM prescriptions;
DELETE FROM immunizations;

-- Clinical Visits
DELETE FROM antenatal_visits;
DELETE FROM surgical_procedures;
DELETE FROM admission_discharges;
DELETE FROM clinical_consultations;

-- Pharmacy
DELETE FROM pharmacy_stock;
DELETE FROM medication_dispensing;

-- Specialty Visits
DELETE FROM oncology_treatments;
DELETE FROM cardiology_visits;
DELETE FROM emergency_visits;
DELETE FROM nephrology_visits;
DELETE FROM gastroenterology_procedures;
DELETE FROM endocrinology_visits;
DELETE FROM pulmonology_visits;
DELETE FROM psychiatric_assessments;
DELETE FROM neurology_exams;

-- Diagnostics
DELETE FROM radiology_reports;
DELETE FROM pathology_reports;
DELETE FROM physiotherapy_sessions;
DELETE FROM infectious_disease_visits;
*/

COMMIT;

-- Verify deletion
DO $$
DECLARE
  queue_count INT;
  ehr_count INT;
BEGIN
  SELECT COUNT(*) INTO queue_count FROM ehrbase_sync_queue;
  SELECT COUNT(*) INTO ehr_count FROM electronic_health_records;

  RAISE NOTICE '✅ ehrbase_sync_queue: % records remaining', queue_count;
  RAISE NOTICE '✅ electronic_health_records: % records remaining', ehr_count;
END $$;
