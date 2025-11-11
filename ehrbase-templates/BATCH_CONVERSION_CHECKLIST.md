# Batch Conversion Checklist - 26 MedZen Templates

**Tool:** Template Designer - https://tools.openehr.org/designer/
**Time Estimate:** 6.5-10.8 hours (26 templates × 15-25 min avg)
**Method:** Manual conversion via web browser

## Quick Instructions

For each template:
1. Open https://tools.openehr.org/designer/
2. Copy ADL file content (see list below)
3. Import → Paste → Validate
4. Export → Operational Template (OPT)
5. Save to `ehrbase-templates/opt-templates/[template-name].opt`
6. Check checkbox below

## Templates to Convert

### ✅ Completed | ⏳ Pending | ⏭️ Skipped

| # | Template Name | Status | Notes |
|---|---------------|--------|-------|
| 1 | medzen-admission-discharge-summary.v1 | ⏳ | Hospital admission/discharge |
| 2 | medzen-antenatal-care-encounter.v1 | ⏳ | Prenatal care |
| 3 | medzen-cardiology-encounter.v1 | ⏳ | Cardiology |
| 4 | medzen-clinical-consultation.v1 | ⏳ | General consultation |
| 5 | medzen-dermatology-consultation.v1 | ⏳ | Dermatology |
| 6 | medzen-emergency-medicine-encounter.v1 | ⏳ | Emergency room |
| 7 | medzen-endocrinology-management.v1 | ⏳ | Endocrine disorders |
| 8 | medzen-gastroenterology-procedures.v1 | ⏳ | GI procedures |
| 9 | medzen-infectious-disease-encounter.v1 | ⏳ | Infectious disease |
| 10 | medzen-laboratory-result-report.v1 | ⏳ | Lab results |
| 11 | medzen-laboratory-test-request.v1 | ⏳ | Lab test orders |
| 12 | medzen-medication-dispensing-record.v1 | ⏳ | Pharmacy dispensing |
| 13 | medzen-medication-list.v1 | ⏳ | Active medications |
| 14 | medzen-nephrology-encounter.v1 | ⏳ | Kidney disease |
| 15 | medzen-neurology-examination.v1 | ⏳ | Neurological exams |
| 16 | medzen-oncology-treatment-plan.v1 | ⏳ | Cancer treatment |
| 17 | medzen-palliative-care-plan.v1 | ⏳ | Palliative care |
| 18 | medzen-pathology-report.v1 | ⏳ | Pathology reports |
| 19 | medzen-patient-demographics.v1 | ⏳ | Patient demographics |
| 20 | medzen-pharmacy-stock-management.v1 | ⏳ | Pharmacy inventory |
| 21 | medzen-physiotherapy-session.v1 | ⏳ | Physical therapy |
| 22 | medzen-psychiatric-assessment.v1 | ⏳ | Psychiatric evaluations |
| 23 | medzen-pulmonology-encounter.v1 | ⏳ | Respiratory medicine |
| 24 | medzen-radiology-report.v1 | ⏳ | Imaging reports |
| 25 | medzen-surgical-procedure-report.v1 | ⏳ | Surgical procedures |
| 26 | medzen-vital-signs-encounter.v1 | ⏳ | Vital signs |

## File Paths

### Source Files (ADL)
```
ehrbase-templates/proper-templates/medzen-admission-discharge-summary.v1.adl
ehrbase-templates/proper-templates/medzen-antenatal-care-encounter.v1.adl
ehrbase-templates/proper-templates/medzen-cardiology-encounter.v1.adl
ehrbase-templates/proper-templates/medzen-clinical-consultation.v1.adl
ehrbase-templates/proper-templates/medzen-dermatology-consultation.v1.adl
ehrbase-templates/proper-templates/medzen-emergency-medicine-encounter.v1.adl
ehrbase-templates/proper-templates/medzen-endocrinology-management.v1.adl
ehrbase-templates/proper-templates/medzen-gastroenterology-procedures.v1.adl
ehrbase-templates/proper-templates/medzen-infectious-disease-encounter.v1.adl
ehrbase-templates/proper-templates/medzen-laboratory-result-report.v1.adl
ehrbase-templates/proper-templates/medzen-laboratory-test-request.v1.adl
ehrbase-templates/proper-templates/medzen-medication-dispensing-record.v1.adl
ehrbase-templates/proper-templates/medzen-medication-list.v1.adl
ehrbase-templates/proper-templates/medzen-nephrology-encounter.v1.adl
ehrbase-templates/proper-templates/medzen-neurology-examination.v1.adl
ehrbase-templates/proper-templates/medzen-oncology-treatment-plan.v1.adl
ehrbase-templates/proper-templates/medzen-palliative-care-plan.v1.adl
ehrbase-templates/proper-templates/medzen-pathology-report.v1.adl
ehrbase-templates/proper-templates/medzen-patient-demographics.v1.adl
ehrbase-templates/proper-templates/medzen-pharmacy-stock-management.v1.adl
ehrbase-templates/proper-templates/medzen-physiotherapy-session.v1.adl
ehrbase-templates/proper-templates/medzen-psychiatric-assessment.v1.adl
ehrbase-templates/proper-templates/medzen-pulmonology-encounter.v1.adl
ehrbase-templates/proper-templates/medzen-radiology-report.v1.adl
ehrbase-templates/proper-templates/medzen-surgical-procedure-report.v1.adl
ehrbase-templates/proper-templates/medzen-vital-signs-encounter.v1.adl
```

### Target Files (OPT)
```
ehrbase-templates/opt-templates/medzen-admission-discharge-summary.v1.opt
ehrbase-templates/opt-templates/medzen-antenatal-care-encounter.v1.opt
ehrbase-templates/opt-templates/medzen-cardiology-encounter.v1.opt
ehrbase-templates/opt-templates/medzen-clinical-consultation.v1.opt
ehrbase-templates/opt-templates/medzen-dermatology-consultation.v1.opt
ehrbase-templates/opt-templates/medzen-emergency-medicine-encounter.v1.opt
ehrbase-templates/opt-templates/medzen-endocrinology-management.v1.opt
ehrbase-templates/opt-templates/medzen-gastroenterology-procedures.v1.opt
ehrbase-templates/opt-templates/medzen-infectious-disease-encounter.v1.opt
ehrbase-templates/opt-templates/medzen-laboratory-result-report.v1.opt
ehrbase-templates/opt-templates/medzen-laboratory-test-request.v1.opt
ehrbase-templates/opt-templates/medzen-medication-dispensing-record.v1.opt
ehrbase-templates/opt-templates/medzen-medication-list.v1.opt
ehrbase-templates/opt-templates/medzen-nephrology-encounter.v1.opt
ehrbase-templates/opt-templates/medzen-neurology-examination.v1.opt
ehrbase-templates/opt-templates/medzen-oncology-treatment-plan.v1.opt
ehrbase-templates/opt-templates/medzen-palliative-care-plan.v1.opt
ehrbase-templates/opt-templates/medzen-pathology-report.v1.opt
ehrbase-templates/opt-templates/medzen-patient-demographics.v1.opt
ehrbase-templates/opt-templates/medzen-pharmacy-stock-management.v1.opt
ehrbase-templates/opt-templates/medzen-physiotherapy-session.v1.opt
ehrbase-templates/opt-templates/medzen-psychiatric-assessment.v1.opt
ehrbase-templates/opt-templates/medzen-pulmonology-encounter.v1.opt
ehrbase-templates/opt-templates/medzen-radiology-report.v1.opt
ehrbase-templates/opt-templates/medzen-surgical-procedure-report.v1.opt
ehrbase-templates/opt-templates/medzen-vital-signs-encounter.v1.opt
```

## Progress Commands

```bash
# Check how many completed
ls -1 ehrbase-templates/opt-templates/*.opt 2>/dev/null | wc -l

# List remaining
./ehrbase-templates/track_conversion_progress.sh

# Verify a converted file
head -5 ehrbase-templates/opt-templates/medzen-vital-signs-encounter.v1.opt
```

## After Conversion

```bash
# Upload all
./ehrbase-templates/upload_all_templates.sh

# Verify upload
./ehrbase-templates/verify_templates.sh
```

## Notes Section

_Use this space to track issues, time taken, or special cases:_

---

---

---

---
