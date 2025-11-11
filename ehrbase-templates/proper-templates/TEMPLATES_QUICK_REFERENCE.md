# MedZen OpenEHR Templates Quick Reference

## Template Catalog Summary

| # | Template ID | Domain | Base COMPOSITION | Category | Key Use Cases |
|---|------------|--------|------------------|----------|---------------|
| 1 | `medzen-patient-demographics.v1` | Demographics | `report.v1` | event | Patient registration, demographic updates, contact management |
| 2 | `medzen-vital-signs-encounter.v1` | Clinical | `encounter.v1` | event | Vital signs monitoring, triage, pre/post-op vitals |
| 3 | `medzen-clinical-consultation.v1` | Clinical | `encounter.v1` | event | Outpatient consultation, follow-up, specialist review, telemedicine |
| 4 | `medzen-medication-list.v1` | Pharmacy | `medication_list.v1` | persistent | Current medications, medication reconciliation, prescription refill |
| 5 | `medzen-laboratory-test-request.v1` | Laboratory | `request.v1` | event | Lab test ordering, specimen collection tracking |
| 6 | `medzen-laboratory-result-report.v1` | Laboratory | `report-result.v1` | event | Lab results reporting, clinical chemistry, hematology, microbiology |
| 7 | `medzen-antenatal-care-encounter.v1` | Maternity | `encounter.v1` | event | Prenatal care, fetal monitoring, pregnancy complications |
| 8 | `medzen-admission-discharge-summary.v1` | Hospital | `report.v1` | event | Hospital admission, discharge summary, transfer notes |
| 9 | `medzen-oncology-treatment-plan.v1` | Oncology | `care_plan.v1` | persistent | Cancer treatment planning, chemotherapy, MDT discussions |
| 10 | `medzen-surgical-procedure-report.v1` | Surgery | `report.v1` | event | Operative reports, surgical procedures, anesthesia documentation |
| 11 | `medzen-medication-dispensing-record.v1` | Pharmacy | `encounter.v1` | event | Pharmacy dispensing, prescription verification, patient counseling |
| 12 | `medzen-pharmacy-stock-management.v1` | Pharmacy | `report.v1` | event | Inventory tracking, expiry monitoring, stock movements, reorder alerts |
| 13 | `medzen-infectious-disease-encounter.v1` | Infectious Disease | `encounter.v1` | event | HIV/AIDS, TB, malaria, tropical diseases, outbreak tracking |
| 14 | `medzen-cardiology-encounter.v1` | Cardiology | `encounter.v1` | event | Heart disease, ECG interpretation, cardiac risk assessment |
| 15 | `medzen-nephrology-encounter.v1` | Nephrology | `encounter.v1` | event | CKD management, dialysis sessions, renal function tracking |
| 16 | `medzen-emergency-medicine-encounter.v1` | Emergency Medicine | `encounter.v1` | event | Triage, trauma, critical care, emergency procedures |
| 17 | `medzen-radiology-report.v1` | Radiology | `report.v1` | event | CT, MRI, ultrasound, X-ray interpretation, PACS integration |
| 18 | `medzen-gastroenterology-procedures.v1` | Gastroenterology | `encounter.v1` | event | Endoscopy, liver disease, IBD, functional GI disorders |
| 19 | `medzen-endocrinology-management.v1` | Endocrinology | `encounter.v1` | event | Diabetes, thyroid disorders, hormonal imbalances |
| 20 | `medzen-pulmonology-encounter.v1` | Pulmonology | `encounter.v1` | event | Asthma, COPD, respiratory infections, sleep disorders |
| 21 | `medzen-psychiatric-assessment.v1` | Psychiatry | `encounter.v1` | event | Mental health, mood disorders, suicide risk, psychotropics |
| 22 | `medzen-neurology-examination.v1` | Neurology | `encounter.v1` | event | Stroke, epilepsy, movement disorders, neurological assessment |
| 23 | `medzen-dermatology-consultation.v1` | Dermatology | `encounter.v1` | event | Skin lesions, dermatoscopy, tele-dermatology, skin cancer |
| 24 | `medzen-pathology-report.v1` | Pathology | `report.v1` | event | Biopsy results, histopathology, cancer staging, molecular pathology |
| 25 | `medzen-palliative-care-plan.v1` | Palliative Care | `care_plan.v1` | persistent | End-of-life care, symptom management, advance directives |
| 26 | `medzen-physiotherapy-session.v1` | Physiotherapy | `encounter.v1` | event | Rehabilitation progress, functional assessment, mobility training |

---

## Domain Coverage Matrix

| Domain | Templates | Coverage Status |
|--------|-----------|-----------------|
| **Demographics** | 1 | ✅ Complete |
| **Clinical Encounters** | 2 (vital signs, consultation) | ✅ Complete |
| **Medications** | 3 (medication list, dispensing, stock) | ✅ Complete |
| **Laboratory** | 2 (test request, results) | ✅ Complete |
| **Maternity** | 1 (antenatal care) | ✅ Complete |
| **Hospital Care** | 1 (admission/discharge) | ✅ Complete |
| **Oncology** | 1 (treatment plan) | ✅ Complete |
| **Surgery** | 1 (operative report) | ✅ Complete |
| **Infectious Disease** | 1 (infectious disease encounter) | ✅ Complete |
| **Cardiology** | 1 (cardiology encounter) | ✅ Complete |
| **Nephrology** | 1 (nephrology encounter) | ✅ Complete |
| **Emergency Medicine** | 1 (emergency encounter) | ✅ Complete |
| **Radiology** | 1 (radiology report) | ✅ Complete |
| **Gastroenterology** | 1 (GI procedures) | ✅ Complete |
| **Endocrinology** | 1 (endocrinology management) | ✅ Complete |
| **Pulmonology** | 1 (pulmonology encounter) | ✅ Complete |
| **Psychiatry** | 1 (psychiatric assessment) | ✅ Complete |
| **Neurology** | 1 (neurology examination) | ✅ Complete |
| **Dermatology** | 1 (dermatology consultation) | ✅ Complete |
| **Pathology** | 1 (pathology report) | ✅ Complete |
| **Palliative Care** | 1 (palliative care plan) | ✅ Complete |
| **Physiotherapy** | 1 (physiotherapy session) | ✅ Complete |

**Total:** 22 domains, 26 templates

---

## Key Archetypes Reference

### Most Commonly Used Archetypes

| Archetype ID | Purpose | Used In Templates |
|--------------|---------|-------------------|
| `openEHR-EHR-EVALUATION.problem_diagnosis.v1` | Diagnoses | Clinical consultation, admission/discharge, oncology, surgery |
| `openEHR-EHR-OBSERVATION.blood_pressure.v2` | Blood pressure | Vital signs, antenatal care |
| `openEHR-EHR-INSTRUCTION.medication_order.v3` | Prescriptions | Clinical consultation, oncology, admission/discharge |
| `openEHR-EHR-ACTION.medication.v1` | Medication actions | Dispensing record, stock management, surgery (anesthesia) |
| `openEHR-EHR-EVALUATION.medication_summary.v0` | Medication status | Medication list, dispensing, stock management, admission/discharge |
| `openEHR-EHR-OBSERVATION.laboratory_test_result.v1` | Lab results | Laboratory result report, antenatal care |
| `openEHR-EHR-INSTRUCTION.service_request.v1` | Service orders | Clinical consultation, lab test request, oncology, admission/discharge |
| `openEHR-EHR-EVALUATION.clinical_synopsis.v1` | Clinical notes | Laboratory results, admission/discharge, dispensing, stock management, surgery |
| `openEHR-EHR-ACTION.procedure.v1` | Procedures | Surgery, oncology |
| `openEHR-EHR-CLUSTER.specimen.v1` | Specimen details | Laboratory request/results, surgery |

---

## COMPOSITION Categories

| Category | Description | Templates Using It |
|----------|-------------|-------------------|
| **event** | Point-in-time clinical events | Demographics, vital signs, consultation, lab request/results, antenatal, admission/discharge, surgery, dispensing, stock management, infectious disease, cardiology, nephrology, emergency, radiology, gastroenterology, endocrinology, pulmonology, psychiatry, neurology, dermatology, pathology, physiotherapy (23 templates) |
| **persistent** | Ongoing/updated records | Medication list, oncology treatment plan, palliative care plan (3 templates) |

**Important:** Persistent compositions are updated/versioned throughout time. Event compositions are created for each occurrence.

---

## Template Complexity Levels

| Complexity | Templates | Characteristics |
|------------|-----------|-----------------|
| **Simple** | Demographics, vital signs, lab request | Basic structure, few archetypes (<5), 5-10 sections |
| **Moderate** | Medication list, dispensing, stock management, antenatal | Moderate structure, 5-10 archetypes, 10-15 sections |
| **Complex** | Clinical consultation, lab results, admission/discharge, surgery, infectious disease, cardiology, nephrology, emergency, radiology, gastroenterology, endocrinology, pulmonology, psychiatry, neurology, dermatology, pathology, physiotherapy | Complex structure, 10+ archetypes, 20-26 sections, comprehensive clinical documentation |
| **Very Complex** | Oncology treatment plan, palliative care plan | Extensive structure, domain-specific archetypes, longitudinal tracking, 25-28 sections, holistic care coordination |

---

## Database Table Mapping

| Template | Primary Supabase Table | Additional Tables | PowerSync Support |
|----------|------------------------|-------------------|-------------------|
| `medzen-patient-demographics.v1` | `user_profiles`, `users` | None | ✅ Yes |
| `medzen-vital-signs-encounter.v1` | `vital_signs` | None | ✅ Yes |
| `medzen-clinical-consultation.v1` | `medical_records` | `diagnoses`, `prescriptions` | ✅ Yes |
| `medzen-medication-list.v1` | `prescriptions` | None | ✅ Yes |
| `medzen-laboratory-test-request.v1` | `lab_results` (status: requested) | None | ✅ Yes |
| `medzen-laboratory-result-report.v1` | `lab_results` (status: completed) | None | ✅ Yes |
| `medzen-antenatal-care-encounter.v1` | `antenatal_visits` (NEW) | `medical_records` | ✅ Yes |
| `medzen-admission-discharge-summary.v1` | `admissions` (NEW) | `medical_records` | ✅ Yes |
| `medzen-oncology-treatment-plan.v1` | `oncology_treatment_plans` (NEW) | `medical_records` | ✅ Yes |
| `medzen-surgical-procedure-report.v1` | `surgical_procedures` (NEW) | `medical_records` | ✅ Yes |
| `medzen-medication-dispensing-record.v1` | `pharmacy_dispensing` (NEW) | `prescriptions` | ✅ Yes |
| `medzen-pharmacy-stock-management.v1` | `pharmacy_inventory` (NEW) | None | ✅ Yes |
| `medzen-infectious-disease-encounter.v1` | `infectious_disease_encounters` (NEW) | `medical_records`, `lab_results` | ✅ Yes |
| `medzen-cardiology-encounter.v1` | `cardiology_encounters` (NEW) | `medical_records`, `ecg_results` | ✅ Yes |
| `medzen-nephrology-encounter.v1` | `nephrology_encounters` (NEW) | `medical_records`, `dialysis_sessions` | ✅ Yes |
| `medzen-emergency-medicine-encounter.v1` | `emergency_encounters` (NEW) | `medical_records`, `triage_assessments` | ✅ Yes |
| `medzen-radiology-report.v1` | `radiology_reports` (NEW) | `medical_records`, `imaging_studies` | ✅ Yes |
| `medzen-gastroenterology-procedures.v1` | `gastroenterology_procedures` (NEW) | `medical_records`, `endoscopy_findings` | ✅ Yes |
| `medzen-endocrinology-management.v1` | `endocrinology_encounters` (NEW) | `medical_records`, `lab_results` | ✅ Yes |
| `medzen-pulmonology-encounter.v1` | `pulmonology_encounters` (NEW) | `medical_records`, `pulmonary_function_tests` | ✅ Yes |
| `medzen-psychiatric-assessment.v1` | `psychiatric_assessments` (NEW) | `medical_records`, `mental_health_screenings` | ✅ Yes |
| `medzen-neurology-examination.v1` | `neurology_examinations` (NEW) | `medical_records`, `neurological_tests` | ✅ Yes |
| `medzen-dermatology-consultation.v1` | `dermatology_consultations` (NEW) | `medical_records`, `skin_lesion_documentation` | ✅ Yes |
| `medzen-pathology-report.v1` | `pathology_reports` (NEW) | `medical_records`, `specimen_tracking` | ✅ Yes |
| `medzen-palliative-care-plan.v1` | `palliative_care_plans` (NEW) | `medical_records`, `advance_directives` | ✅ Yes |
| `medzen-physiotherapy-session.v1` | `physiotherapy_sessions` (NEW) | `medical_records`, `functional_assessments` | ✅ Yes |

**NEW** = Table needs to be created as part of implementation (20 new tables for specialty templates)

---

## User Role Access Matrix

| Template | Patient | Provider | Facility Admin | System Admin |
|----------|---------|----------|----------------|--------------|
| Demographics | ✅ Own | ✅ Assigned patients | ✅ All | ✅ All |
| Vital Signs | ✅ Own | ✅ Assigned patients | ✅ All | ✅ All |
| Clinical Consultation | ✅ Own | ✅ Assigned patients | ✅ All | ✅ All |
| Medication List | ✅ Own | ✅ Assigned patients | ❌ No | ✅ All |
| Lab Request | ✅ Own | ✅ Can order | ❌ No | ✅ All |
| Lab Results | ✅ Own | ✅ Assigned patients | ❌ No | ✅ All |
| Antenatal Care | ✅ Own | ✅ Assigned patients | ✅ All | ✅ All |
| Admission/Discharge | ✅ Own | ✅ Assigned patients | ✅ All | ✅ All |
| Oncology Plan | ✅ Own | ✅ Assigned patients | ❌ No | ✅ All |
| Surgical Report | ✅ Own | ✅ Assigned patients | ✅ All | ✅ All |
| Medication Dispensing | ❌ No | ✅ Pharmacist role | ✅ Pharmacy admin | ✅ All |
| Pharmacy Stock | ❌ No | ✅ Pharmacist role | ✅ Pharmacy admin | ✅ All |
| Infectious Disease | ✅ Own | ✅ Assigned patients | ❌ No | ✅ All |
| Cardiology | ✅ Own | ✅ Assigned patients | ✅ All | ✅ All |
| Nephrology | ✅ Own | ✅ Assigned patients | ❌ No | ✅ All |
| Emergency Medicine | ✅ Own | ✅ Assigned patients | ✅ All | ✅ All |
| Radiology Report | ✅ Own | ✅ Assigned patients | ❌ No | ✅ All |
| Gastroenterology | ✅ Own | ✅ Assigned patients | ❌ No | ✅ All |
| Endocrinology | ✅ Own | ✅ Assigned patients | ❌ No | ✅ All |
| Pulmonology | ✅ Own | ✅ Assigned patients | ✅ All | ✅ All |
| Psychiatric Assessment | ✅ Own | ✅ Assigned patients | ❌ No | ✅ All |
| Neurology | ✅ Own | ✅ Assigned patients | ✅ All | ✅ All |
| Dermatology | ✅ Own | ✅ Assigned patients | ✅ All | ✅ All |
| Pathology Report | ✅ Own | ✅ Assigned patients | ❌ No | ✅ All |
| Palliative Care Plan | ✅ Own | ✅ Assigned patients | ❌ No | ✅ All |
| Physiotherapy Session | ✅ Own | ✅ Assigned patients | ✅ All | ✅ All |

---

## Sync Priority Levels

For PowerSync sync rule configuration:

| Priority | Templates | Justification |
|----------|-----------|---------------|
| **High** | Vital signs, medication list, lab results (critical alerts), emergency medicine, cardiology, infectious disease (outbreak tracking) | Real-time clinical decision support, critical care, public health |
| **Medium** | Clinical consultation, antenatal care, admission/discharge, nephrology, radiology, gastroenterology, endocrinology, pulmonology, neurology, dermatology, pathology, physiotherapy, psychiatric assessment | Important clinical documentation but not immediately critical |
| **Low** | Demographics, lab requests, surgical reports | Can tolerate slight delay |
| **Batch** | Stock management, oncology treatment plan, palliative care plan (updates infrequent) | Periodic sync sufficient, persistent compositions |

---

## Validation Requirements

### Required Fields by Template

| Template | Critical Required Fields |
|----------|--------------------------|
| Demographics | Patient name, date of birth, gender |
| Vital Signs | At least one vital sign measurement, measurement date/time |
| Clinical Consultation | Chief complaint OR presenting symptoms, encounter date |
| Medication List | At least one medication OR explicit statement of none |
| Lab Request | At least one test ordered, priority level |
| Lab Results | Test performed, result values, report status |
| Antenatal Care | Gestational age, visit type, visit date |
| Admission/Discharge | Admission date, admission type, at least one diagnosis |
| Oncology Plan | Cancer type, diagnosis date, treatment intent |
| Surgical Report | Procedure performed, urgency, pre-op diagnosis |
| Medication Dispensing | Medication dispensed, quantity, prescriber verification |
| Pharmacy Stock | Medication identifier, quantity, stock movement type |
| Infectious Disease | Primary diagnosis (HIV/TB/malaria/tropical), encounter date, presenting symptoms |
| Cardiology | Chief complaint, cardiovascular history, at least one assessment (ECG/echo/stress test) |
| Nephrology | Primary diagnosis (CKD stage/dialysis), encounter date, renal function assessment |
| Emergency Medicine | Chief complaint, triage category, arrival mode, encounter date |
| Radiology | Study type (CT/MRI/X-ray/ultrasound), clinical indication, at least one finding |
| Gastroenterology | Primary diagnosis OR procedure performed, encounter date |
| Endocrinology | Primary diagnosis (diabetes/thyroid/hormonal), encounter date, relevant labs |
| Pulmonology | Primary diagnosis (asthma/COPD/respiratory), encounter date, respiratory assessment |
| Psychiatric Assessment | Chief complaint OR presenting symptoms, mental status exam, risk assessment |
| Neurology | Chief complaint, neurological examination, at least one diagnosis |
| Dermatology | Primary dermatological condition, skin examination findings, encounter date |
| Pathology | Specimen type, gross examination, microscopic examination, final diagnosis |
| Palliative Care | Primary life-limiting diagnosis, phase of care, care goals, symptom assessment |
| Physiotherapy | Primary condition/diagnosis, session type, objective assessment, treatment plan |

---

## Integration Checklist

### For Each Template Implementation

- [ ] Template uploaded to EHRbase (as OPT)
- [ ] Database table exists with appropriate schema
- [ ] DB trigger created for `ehrbase_sync_queue`
- [ ] PowerSync sync rules configured
- [ ] Edge function updated with template mapping
- [ ] Validation logic implemented
- [ ] FlutterFlow pages/custom actions created
- [ ] Offline mode tested
- [ ] All 4 user roles tested
- [ ] Performance benchmarked
- [ ] Documentation updated

---

## Performance Benchmarks (Target)

| Operation | Target Time | Critical Threshold |
|-----------|-------------|-------------------|
| Local write (PowerSync) | <100ms | 200ms |
| Supabase sync | <2s | 5s |
| EHRbase composition creation | <5s | 10s |
| Sync queue processing | <30s | 60s |
| PowerSync initial download | <10s per 100 records | 20s |

---

## Terminology Binding Status

| Template | SNOMED CT | LOINC | ICD-10 | Other |
|----------|-----------|-------|--------|-------|
| Demographics | ⚠️ Planned | ❌ N/A | ❌ N/A | ✅ ISO 3166 (country) |
| Vital Signs | ⚠️ Planned | ✅ Ready | ❌ N/A | ✅ UCUM (units) |
| Clinical Consultation | ⚠️ Planned | ❌ N/A | ⚠️ Planned | ❌ None |
| Medication List | ⚠️ Planned | ❌ N/A | ❌ N/A | ⚠️ ATC codes |
| Lab Request/Results | ❌ N/A | ✅ Ready | ❌ N/A | ✅ UCUM (units) |
| Antenatal Care | ⚠️ Planned | ✅ Ready | ❌ N/A | ✅ UCUM (units) |
| Admission/Discharge | ⚠️ Planned | ❌ N/A | ⚠️ Planned | ❌ None |
| Oncology Plan | ✅ Ready | ❌ N/A | ✅ Ready | ✅ TNM codes |
| Surgical Report | ⚠️ Planned | ❌ N/A | ⚠️ Planned | ❌ None |
| Medication Dispensing | ⚠️ Planned | ❌ N/A | ❌ N/A | ⚠️ ATC codes |
| Pharmacy Stock | ⚠️ Planned | ❌ N/A | ❌ N/A | ⚠️ ATC codes |
| Infectious Disease | ⚠️ Planned | ⚠️ Planned | ⚠️ Planned | ⚠️ WHO ICD-10 infectious |
| Cardiology | ⚠️ Planned | ⚠️ Planned | ⚠️ Planned | ⚠️ ACC/AHA classifications |
| Nephrology | ⚠️ Planned | ⚠️ Planned | ⚠️ Planned | ⚠️ KDIGO CKD stages |
| Emergency Medicine | ⚠️ Planned | ❌ N/A | ⚠️ Planned | ⚠️ ESI triage levels |
| Radiology | ⚠️ Planned | ⚠️ Planned | ❌ N/A | ⚠️ RadLex, DICOM |
| Gastroenterology | ⚠️ Planned | ❌ N/A | ⚠️ Planned | ⚠️ Montreal IBD classification |
| Endocrinology | ⚠️ Planned | ⚠️ Planned | ⚠️ Planned | ⚠️ ADA diabetes criteria |
| Pulmonology | ⚠️ Planned | ⚠️ Planned | ⚠️ Planned | ⚠️ GOLD COPD staging |
| Psychiatric Assessment | ⚠️ Planned | ❌ N/A | ⚠️ Planned | ⚠️ DSM-5 codes |
| Neurology | ⚠️ Planned | ❌ N/A | ⚠️ Planned | ⚠️ NINDS stroke scale |
| Dermatology | ⚠️ Planned | ❌ N/A | ⚠️ Planned | ⚠️ Fitzpatrick scale |
| Pathology | ⚠️ Planned | ⚠️ Planned | ⚠️ Planned | ⚠️ ICD-O, TNM, CAP |
| Palliative Care | ⚠️ Planned | ❌ N/A | ⚠️ Planned | ⚠️ KPS, ECOG, PPS scales |
| Physiotherapy | ⚠️ Planned | ❌ N/A | ⚠️ Planned | ⚠️ ICF codes, MMT scale |

**Legend:**
- ✅ Ready = Binding defined and ready for use
- ⚠️ Planned = To be added in OPT generation phase
- ❌ N/A = Not applicable for this template

---

## Template File Locations

All ADL template files are located in:
```
/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-templates/proper-templates/
```

**Original Templates (12):**
1. `medzen-patient-demographics.v1.adl`
2. `medzen-vital-signs-encounter.v1.adl`
3. `medzen-clinical-consultation.v1.adl`
4. `medzen-medication-list.v1.adl`
5. `medzen-laboratory-test-request.v1.adl`
6. `medzen-laboratory-result-report.v1.adl`
7. `medzen-antenatal-care-encounter.v1.adl`
8. `medzen-admission-discharge-summary.v1.adl`
9. `medzen-oncology-treatment-plan.v1.adl`
10. `medzen-surgical-procedure-report.v1.adl`
11. `medzen-medication-dispensing-record.v1.adl`
12. `medzen-pharmacy-stock-management.v1.adl`

**Specialty Templates - Phase 1 (14):**
13. `medzen-infectious-disease-encounter.v1.adl`
14. `medzen-cardiology-encounter.v1.adl`
15. `medzen-nephrology-encounter.v1.adl`
16. `medzen-emergency-medicine-encounter.v1.adl`
17. `medzen-radiology-report.v1.adl`
18. `medzen-gastroenterology-procedures.v1.adl`
19. `medzen-endocrinology-management.v1.adl`
20. `medzen-pulmonology-encounter.v1.adl`
21. `medzen-psychiatric-assessment.v1.adl`
22. `medzen-neurology-examination.v1.adl`
23. `medzen-dermatology-consultation.v1.adl`
24. `medzen-pathology-report.v1.adl`
25. `medzen-palliative-care-plan.v1.adl`
26. `medzen-physiotherapy-session.v1.adl`

**Additional Documentation:**
- `OPENEHR_TEMPLATES_GUIDE.md` - Comprehensive implementation guide
- `TEMPLATES_QUICK_REFERENCE.md` - This quick reference card

---

## Migration Priority

### Phase 1 (Weeks 1-2): ADL Template Creation ✅ COMPLETE
**Status:** All 26 templates created (12 original + 14 specialty)
- All ADL 1.5.1 templates with RM Release 1.0.4
- Multi-language support (en/fr)
- OpenEHR CKM archetypes
- Comprehensive clinical coverage

### Phase 2 (Weeks 3-4): Database Schema & Core Clinical Implementation
1. **Core Clinical** (already implemented):
   - Demographics, vital signs, clinical consultation, medication list
2. **Laboratory & Diagnostics** (already implemented):
   - Lab test request, lab result report
3. **HIGH Priority Specialty Templates** (NEW):
   - Emergency medicine (critical care)
   - Cardiology (cardiac events)
   - Infectious disease (outbreak tracking)
   - Radiology report (diagnostic imaging)

### Phase 3 (Weeks 5-7): Hospital Care & Medium Priority Specialties
4. **Hospital Operations** (partial implementation):
   - Admission/discharge summary (existing)
   - Surgical procedure report (existing)
5. **MEDIUM Priority Specialty Templates** (NEW):
   - Nephrology (CKD, dialysis)
   - Gastroenterology (endoscopy)
   - Endocrinology (diabetes)
   - Pulmonology (respiratory)
   - Neurology (stroke, epilepsy)
   - Dermatology (skin conditions)
   - Pathology report (histopathology)

### Phase 4 (Weeks 8-10): Advanced Care & Persistent Plans
6. **Pharmacy Operations** (existing):
   - Medication dispensing
   - Pharmacy stock management
7. **Specialty Care** (existing + NEW):
   - Antenatal care (existing)
   - Oncology treatment plan (existing)
   - Psychiatric assessment (NEW)
   - Palliative care plan (NEW)
   - Physiotherapy session (NEW)

**Implementation Notes:**
- Each phase includes: database tables, PowerSync sync rules, EHRbase integration, FlutterFlow UI
- HIGH priority templates (emergency, cardiology, infectious disease) should be prioritized in Phase 2
- Persistent compositions (medication list, oncology, palliative care) require special versioning handling
- All templates support offline-first architecture via PowerSync

---

## Support Resources

**OpenEHR Community:**
- Forum: https://discourse.openehr.org/
- Specifications: https://specifications.openehr.org/
- CKM: https://ckm.openehr.org/

**MedZen Project Documentation:**
- Main README: `/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/README.md`
- CLAUDE.md: Project instructions for AI assistants
- EHR_SYSTEM_README.md: EHR system architecture
- POWERSYNC_QUICK_START.md: Offline-first implementation

**Contact:**
- Email: info@medzenhealth.app
- Project Directory: `/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/`

---

**Last Updated:** 2025-11-02
**Template Count:** 26 (12 original + 14 specialty)
**Phase 1 Status:** ✅ COMPLETE - All ADL templates created
**Next Phase:** Database schema design and implementation (Phase 2)
**ADL Version:** 1.5.1
**RM Release:** 1.0.4
**Domains Covered:** 22 medical specialties
**Base Compositions:** encounter.v1, report.v1, care_plan.v1, medication_list.v1, request.v1, report-result.v1
