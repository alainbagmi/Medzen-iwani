# MedZen Specialty Templates - Conversion TODO List

**Date:** 2025-11-03
**Status:** ⏳ PENDING CONVERSION (26 ADL templates → OPT format)
**Priority:** User requested "Oncology first"
**Estimated Timeline:** 6-13 hours over 2-4 days (15-30 min per template)

---

## Quick Reference

**Total Templates:** 26 MedZen custom ADL templates
**Location:** `ehrbase-templates/proper-templates/*.adl`
**Target Format:** OPT (Operational Template XML)
**Conversion Tool:** OpenEHR Template Designer (https://tools.openehr.org/designer/)
**Upload Script:** `ehrbase-templates/upload_all_templates.sh` (READY ✅)

---

## Conversion Priority List

### Priority 1: User-Requested Specialty (1 template)

1. **medzen-oncology-treatment-plan.v1.adl** ⭐ **USER PRIORITY**
   - Template ID: `medzen.oncology_treatment_plan.v1`
   - Status: ⏳ Pending conversion
   - Specializes: `openEHR-EHR-COMPOSITION.care_plan.v1`
   - Sections: Cancer diagnosis, histopathology, staging (TNM), chemotherapy, radiation, immunotherapy, surgical oncology, follow-up
   - Cancer Types: 11 supported (breast, lung, colorectal, prostate, cervical, liver, gastric, esophageal, lymphoma, leukemia, other)
   - File: `/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/ehrbase-templates/proper-templates/medzen-oncology-treatment-plan.v1.adl`
   - Lines: 448
   - **Action:** Convert first, upload immediately, test with real oncology data

---

### Priority 2: High-Volume Specialty Encounters (18 templates)

**Cardiovascular (1):**
2. **medzen-cardiology-encounter.v1.adl**
   - Template ID: `medzen.cardiology_encounter.v1`
   - Sections: Cardiac examination, ECG, echocardiography, cardiac procedures
   - Use: Cardiology visits, heart disease management

**Women's Health (1):**
3. **medzen-antenatal-care-encounter.v1.adl**
   - Template ID: `medzen.antenatal_care_encounter.v1`
   - Sections: Pregnancy history, fetal assessments, maternal health, antenatal screening
   - Use: Pregnancy monitoring, prenatal care

**Neurology (1):**
4. **medzen-neurology-examination.v1.adl**
   - Template ID: `medzen.neurology_examination.v1`
   - Sections: Neurological exam, mental status, cranial nerves, motor/sensory function
   - Use: Neurological disorders, stroke, seizures

**Mental Health (1):**
5. **medzen-psychiatric-assessment.v1.adl**
   - Template ID: `medzen.psychiatric_assessment.v1`
   - Sections: Mental status exam, psychiatric history, DSM diagnosis, treatment plan
   - Use: Mental health evaluations, psychiatric care

**Respiratory (1):**
6. **medzen-pulmonology-encounter.v1.adl**
   - Template ID: `medzen.pulmonology_encounter.v1`
   - Sections: Respiratory examination, lung function tests, oxygen therapy
   - Use: Respiratory diseases, COPD, asthma

**Renal (1):**
7. **medzen-nephrology-encounter.v1.adl**
   - Template ID: `medzen.nephrology_encounter.v1`
   - Sections: Renal function assessment, dialysis, kidney disease management
   - Use: Kidney disease, dialysis patients

**Digestive (1):**
8. **medzen-gastroenterology-procedures.v1.adl**
   - Template ID: `medzen.gastroenterology_procedures.v1`
   - Sections: Endoscopy, colonoscopy, biopsy results, GI procedures
   - Use: GI disorders, endoscopic procedures

**Endocrine (1):**
9. **medzen-endocrinology-management.v1.adl**
   - Template ID: `medzen.endocrinology_management.v1`
   - Sections: Hormone levels, diabetes management, thyroid assessment
   - Use: Diabetes, thyroid disorders, hormonal conditions

**Infectious Disease (1):**
10. **medzen-infectious-disease-encounter.v1.adl**
    - Template ID: `medzen.infectious_disease_encounter.v1`
    - Sections: Infection assessment, antimicrobial therapy, isolation precautions
    - Use: Infectious diseases, antimicrobial stewardship

**Emergency (1):**
11. **medzen-emergency-medicine-encounter.v1.adl**
    - Template ID: `medzen.emergency_medicine_encounter.v1`
    - Sections: Triage, emergency procedures, critical care, trauma assessment
    - Use: Emergency department, urgent care

**Dermatology (1):**
12. **medzen-dermatology-consultation.v1.adl**
    - Template ID: `medzen.dermatology_consultation.v1`
    - Sections: Skin examination, dermatological procedures, biopsy
    - Use: Skin conditions, dermatology consultations

**Palliative Care (1):**
13. **medzen-palliative-care-plan.v1.adl**
    - Template ID: `medzen.palliative_care_plan.v1`
    - Sections: Symptom management, end-of-life care, quality of life assessment
    - Use: Palliative care, hospice

**Rehabilitation (1):**
14. **medzen-physiotherapy-session.v1.adl**
    - Template ID: `medzen.physiotherapy_session.v1`
    - Sections: Physical assessment, treatment plan, exercise therapy
    - Use: Physiotherapy, rehabilitation

**Surgical (1):**
15. **medzen-surgical-procedure-report.v1.adl**
    - Template ID: `medzen.surgical_procedure_report.v1`
    - Sections: Operative details, surgical findings, anesthesia, post-op care
    - Use: Surgical procedures, operative notes

**General (4):**
16. **medzen-clinical-consultation.v1.adl**
    - Template ID: `medzen.clinical_consultation.v1`
    - Sections: General consultation, clinical assessment, treatment plan
    - Use: General consultations, follow-ups

17. **medzen-admission-discharge-summary.v1.adl**
    - Template ID: `medzen.admission_discharge_summary.v1`
    - Sections: Admission details, hospital course, discharge plan, medications
    - Use: Hospital admissions/discharges

18. **medzen-pathology-report.v1.adl**
    - Template ID: `medzen.pathology_report.v1`
    - Sections: Histology, cytology, specimen analysis, pathological findings
    - Use: Pathology results, biopsy reports

19. **medzen-radiology-report.v1.adl**
    - Template ID: `medzen.radiology_report.v1`
    - Sections: Imaging studies, findings, impressions, recommendations
    - Use: X-rays, CT, MRI, ultrasound reports

---

### Priority 3: Core Medical Record Templates (7 templates)

**Patient Information (1):**
20. **medzen-patient-demographics.v1.adl**
    - Template ID: `medzen.patient_demographics.v1`
    - Sections: Comprehensive demographics, contact info, next of kin, insurance
    - Use: Patient registration, demographics management

**Vital Signs (1):**
21. **medzen-vital-signs-encounter.v1.adl**
    - Template ID: `medzen.vital_signs_encounter.v1`
    - Sections: Blood pressure, heart rate, temperature, SpO2, respiratory rate
    - Use: Vital signs monitoring (MedZen-specific structure)

**Laboratory (3):**
22. **medzen-laboratory-result-report.v1.adl**
    - Template ID: `medzen.laboratory_result_report.v1`
    - Sections: Lab test results, reference ranges, clinical interpretation
    - Use: Lab results (MedZen-specific structure)

23. **medzen-laboratory-test-request.v1.adl**
    - Template ID: `medzen.laboratory_test_request.v1`
    - Sections: Test orders, clinical indication, urgency, specimen details
    - Use: Lab test ordering

**Medications (2):**
24. **medzen-medication-list.v1.adl**
    - Template ID: `medzen.medication_list.v1`
    - Sections: Current medications, dosage, frequency, prescriber
    - Use: Medication reconciliation (MedZen-specific structure)

25. **medzen-medication-dispensing-record.v1.adl**
    - Template ID: `medzen.medication_dispensing_record.v1`
    - Sections: Medication dispensed, quantity, dispenser, instructions
    - Use: Pharmacy dispensing records

**Pharmacy (1):**
26. **medzen-pharmacy-stock-management.v1.adl**
    - Template ID: `medzen.pharmacy_stock_management.v1`
    - Sections: Stock levels, expiry dates, batch numbers, supply chain
    - Use: Pharmacy inventory management

---

## Conversion Workflow

### Step-by-Step Process (Per Template)

**Time: 15-30 minutes per template**

1. **Open Source File**
   - Location: `ehrbase-templates/proper-templates/<template-name>.adl`
   - Review structure and archetypes

2. **Open Template Designer**
   - URL: https://tools.openehr.org/designer/
   - Sign in (free account required)

3. **Create New Template**
   - Click "New Template"
   - Select base archetype (e.g., COMPOSITION.care_plan.v1)
   - Set template ID (e.g., `medzen.oncology_treatment_plan.v1`)

4. **Rebuild Structure**
   - Add sections from ADL file
   - Configure archetypes and constraints
   - Set terminology bindings
   - Add data elements

5. **Validate Template**
   - Use built-in validation
   - Fix any errors or warnings
   - Test structure completeness

6. **Export as OPT**
   - Click "Export" → "OPT (XML)"
   - Save to: `ehrbase-templates/opt-templates/<template-name>.opt`

7. **Upload to EHRbase**
   ```bash
   ./ehrbase-templates/upload_all_templates.sh
   # Or upload individually via EHRbase Admin UI
   ```

8. **Verify Upload**
   ```bash
   ./ehrbase-templates/verify_templates.sh
   # Or use MCP OpenEHR tool: mcp__openEHR__openehr_template_list
   ```

---

## Progress Tracking

### Track Conversion Progress
```bash
# Real-time progress tracker
./ehrbase-templates/track_conversion_progress.sh

# Shows:
# - Total templates: 26
# - Converted: X
# - Pending: Y
# - Success rate: Z%
```

### Update This File
As each template is converted, update the checklist:
- [ ] → ✅ (when converted to OPT)
- [ ] → 📤 (when uploaded to EHRbase)
- [ ] → ✅ (when verified in EHRbase)

---

## Conversion Checklist

### Priority 1 (User Request)
- [ ] 1. medzen-oncology-treatment-plan.v1 → OPT
  - [ ] Converted
  - [ ] Uploaded
  - [ ] Verified

### Priority 2 (Specialty Encounters)
- [ ] 2. medzen-cardiology-encounter.v1
- [ ] 3. medzen-antenatal-care-encounter.v1
- [ ] 4. medzen-neurology-examination.v1
- [ ] 5. medzen-psychiatric-assessment.v1
- [ ] 6. medzen-pulmonology-encounter.v1
- [ ] 7. medzen-nephrology-encounter.v1
- [ ] 8. medzen-gastroenterology-procedures.v1
- [ ] 9. medzen-endocrinology-management.v1
- [ ] 10. medzen-infectious-disease-encounter.v1
- [ ] 11. medzen-emergency-medicine-encounter.v1
- [ ] 12. medzen-dermatology-consultation.v1
- [ ] 13. medzen-palliative-care-plan.v1
- [ ] 14. medzen-physiotherapy-session.v1
- [ ] 15. medzen-surgical-procedure-report.v1
- [ ] 16. medzen-clinical-consultation.v1
- [ ] 17. medzen-admission-discharge-summary.v1
- [ ] 18. medzen-pathology-report.v1
- [ ] 19. medzen-radiology-report.v1

### Priority 3 (Core Templates)
- [ ] 20. medzen-patient-demographics.v1
- [ ] 21. medzen-vital-signs-encounter.v1
- [ ] 22. medzen-laboratory-result-report.v1
- [ ] 23. medzen-laboratory-test-request.v1
- [ ] 24. medzen-medication-list.v1
- [ ] 25. medzen-medication-dispensing-record.v1
- [ ] 26. medzen-pharmacy-stock-management.v1

---

## Estimated Timeline

### Aggressive Schedule (6-8 hours over 2 days)
- **Day 1 (3-4 hours):** Convert 8-10 templates
  - Priority 1: Oncology (30 min)
  - Priority 2 High-traffic: Cardiology, antenatal, neurology, psychiatry, pulmonology, nephrology, gastro, endo (3-3.5 hours)

- **Day 2 (3-4 hours):** Convert remaining 16-18 templates
  - Priority 2 Remaining: Emergency, dermatology, palliative, physio, surgical, consultations, summaries, reports (3-3.5 hours)
  - Priority 3 Core: Demographics, vitals, labs, meds, pharmacy (1.5-2 hours)

### Moderate Schedule (10-13 hours over 3-4 days)
- **Day 1 (2-3 hours):** Priority 1 + High-traffic specialties (6 templates)
- **Day 2 (3-4 hours):** Remaining specialties (7 templates)
- **Day 3 (3-4 hours):** More specialties + Core templates (7 templates)
- **Day 4 (2-3 hours):** Final core templates + verification (6 templates)

### Incremental Approach (1-2 templates per day)
- **Week 1:** Priority 1 (oncology) + cardiology + antenatal + neurology + psychiatry (5 templates)
- **Week 2:** Pulmonology + nephrology + gastro + endo + infectious disease (5 templates)
- **Week 3:** Emergency + dermatology + palliative + physio + surgical (5 templates)
- **Week 4:** Consultations + summaries + reports + demographics (4 templates)
- **Week 5:** Vitals + labs + medications + pharmacy (7 templates)

---

## Post-Conversion Actions

### After All 26 Templates Converted & Uploaded

**1. Update Edge Function**
```bash
cd supabase/functions/sync-to-ehrbase

# Edit index.ts:
# - Remove TEMPLATE_ID_MAP dictionary
# - Remove getMappedTemplateId() function
# - Use template_id directly from sync queue

# Deploy:
npx supabase functions deploy sync-to-ehrbase
```

**2. Test Each Specialty Area**
```sql
-- For each specialty table:
-- 1. Insert test data
-- 2. Monitor ehrbase_sync_queue
-- 3. Verify composition created in EHRbase
-- 4. Check edge function logs
```

**3. Update Documentation**
- Mark TEMPLATE_MAPPING_IMPLEMENTATION.md as deprecated
- Update TEMPLATE_CONVERSION_STATUS.md to 100% complete
- Document new direct template usage

**4. Clean Up**
- Archive template ID mapping code
- Update CLAUDE.md with new template status
- Create completion report

---

## Resources

**Conversion Tools:**
- OpenEHR Template Designer: https://tools.openehr.org/designer/
- Clinical Knowledge Manager: https://ckm.openehr.org/
- Archetype Designer: https://tools.openehr.org/designer/

**Documentation:**
- OpenEHR Specs: https://specifications.openehr.org/
- Template Designer Guide: https://discourse.openehr.org/
- ADL Workbench: https://www.openehr.org/downloads/ADLworkbench

**Scripts (Ready to Use):**
- `ehrbase-templates/upload_all_templates.sh` ✅
- `ehrbase-templates/verify_templates.sh` ✅
- `ehrbase-templates/track_conversion_progress.sh` ✅
- `ehrbase-templates/convert_templates_helper.sh` ✅

---

## Notes

1. **Template Designer Account:** Free account required at https://tools.openehr.org/designer/
2. **ADL 1.5.1 Limitation:** Cannot directly import ADL text - must rebuild manually
3. **Conversion Quality:** Take time to validate each template thoroughly
4. **Upload Order:** Can upload templates incrementally as they're converted
5. **Testing:** Test each specialty area after its template is uploaded
6. **Backup:** Keep original ADL files (already in `proper-templates/`)
7. **Version Control:** Commit OPT files to git as they're created

---

## Support

**Questions or Issues:**
- OpenEHR Discourse: https://discourse.openehr.org/
- Template Designer Help: https://tools.openehr.org/designer/help
- ADL Specifications: https://specifications.openehr.org/releases/AM/latest/ADL2.html

**Project Documentation:**
- `TEMPLATE_CONVERSION_STRATEGY.md` - Comprehensive conversion guide
- `OPENEHR_TEMPLATE_DEPLOYMENT_GUIDE.md` - Deployment procedures
- `TEMPLATE_DESIGN_OVERVIEW.md` - Template architecture
- `CLAUDE.md` - Project overview and instructions

---

**Created:** 2025-11-03
**Status:** ⏳ PENDING CONVERSION
**Priority:** Oncology first (user request), then high-volume specialties
**Estimated Completion:** 6-13 hours (aggressive to moderate schedule)
