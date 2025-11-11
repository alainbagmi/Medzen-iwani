# OpenEHR Template Deployment Guide

## Overview

This guide provides comprehensive instructions for converting ADL templates to OPT format and uploading them to EHRbase for the 19 specialty medical tables.

## Current Status

**✅ ADL Templates Created:** 26 templates (covering all 19 specialty tables + 7 additional)
**📍 OPT Templates Generated:** 1 of 26 (medzen.provider.profile.v1.opt - needs namespace fix)
**📤 Templates Uploaded to EHRbase:** 0 of 26

## Template Inventory

### 19 Specialty Tables (Priority 1 - Required for Production)

| # | ADL Template | Supabase Table | Template ID | OPT Status | Upload Status | Last Updated |
|---|--------------|----------------|-------------|------------|---------------|--------------|
| 1 | medzen-antenatal-care-encounter.v1.adl | antenatal_visits | medzen.antenatal_care_encounter.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 2 | medzen-surgical-procedure-report.v1.adl | surgical_procedures | medzen.surgical_procedure_report.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 3 | medzen-admission-discharge-summary.v1.adl | admission_discharge_records | medzen.admission_discharge_summary.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 4 | medzen-medication-dispensing-record.v1.adl | medication_dispensing | medzen.medication_dispensing_record.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 5 | medzen-pharmacy-stock-management.v1.adl | pharmacy_stock | medzen.pharmacy_stock_management.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 6 | medzen-clinical-consultation.v1.adl | clinical_consultations | medzen.clinical_consultation.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 7 | medzen-oncology-treatment-plan.v1.adl | oncology_treatments | medzen.oncology_treatment.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 8 | medzen-infectious-disease-encounter.v1.adl | infectious_disease_visits | medzen.infectious_disease_encounter.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 9 | medzen-cardiology-encounter.v1.adl | cardiology_visits | medzen.cardiology_encounter.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 10 | medzen-emergency-medicine-encounter.v1.adl | emergency_visits | medzen.emergency_encounter.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 11 | medzen-nephrology-encounter.v1.adl | nephrology_visits | medzen.nephrology_encounter.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 12 | medzen-gastroenterology-procedures.v1.adl | gastroenterology_procedures | medzen.gastroenterology_procedures.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 13 | medzen-endocrinology-management.v1.adl | endocrinology_visits | medzen.endocrinology_management.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 14 | medzen-pulmonology-encounter.v1.adl | pulmonology_visits | medzen.pulmonology_encounter.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 15 | medzen-psychiatric-assessment.v1.adl | psychiatric_assessments | medzen.psychiatric_assessment.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 16 | medzen-neurology-examination.v1.adl | neurology_exams | medzen.neurology_examination.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 17 | medzen-radiology-report.v1.adl | radiology_reports | medzen.radiology_report.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 18 | medzen-pathology-report.v1.adl | pathology_reports | medzen.pathology_report.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |
| 19 | medzen-physiotherapy-session.v1.adl | physiotherapy_sessions | medzen.physiotherapy_session.v1 | ⏳ Not Converted | ❌ Not Uploaded | 2025-11-02 |

### Additional Core Templates (Priority 2 - General Clinical Use)

| # | ADL Template | Use Case | Template ID | OPT Status | Upload Status |
|---|--------------|----------|-------------|------------|---------------|
| 20 | medzen-patient-demographics.v1.adl | Patient registration | medzen.patient_demographics.v1 | ⏳ Not Converted | ❌ Not Uploaded |
| 21 | medzen-vital-signs-encounter.v1.adl | Vital signs recording | medzen.vital_signs.v1 | ⏳ Not Converted | ❌ Not Uploaded |
| 22 | medzen-laboratory-test-request.v1.adl | Lab test requests | medzen.lab_results.v1 | ⏳ Not Converted | ❌ Not Uploaded |
| 23 | medzen-laboratory-result-report.v1.adl | Lab results | medzen.lab_results.v1 | ⏳ Not Converted | ❌ Not Uploaded |
| 24 | medzen-medication-list.v1.adl | Medication lists | medzen.prescriptions.v1 | ⏳ Not Converted | ❌ Not Uploaded |
| 25 | medzen-dermatology-consultation.v1.adl | Dermatology visits | medzen.dermatology.v1 | ⏳ Not Converted | ❌ Not Uploaded |
| 26 | medzen-palliative-care-plan.v1.adl | Palliative care | medzen.palliative_care.v1 | ⏳ Not Converted | ❌ Not Uploaded |

## ADL to OPT Conversion Process

### Option 1: OpenEHR Template Designer (Recommended - Web-Based)

**URL:** https://tools.openehr.org/designer/

**Steps:**
1. Navigate to OpenEHR Template Designer
2. Click **"New Template"** or **"Import"**
3. Copy/paste ADL template content from `ehrbase-templates/proper-templates/*.adl`
4. Designer will validate syntax and show any errors
5. Click **"Export" → "Operational Template (OPT)"**
6. Save as `{template-name}.v1.opt` in `ehrbase-templates/opt-templates/`
7. Update tracking table above with ✅ Converted status

**Batch Processing:**
- Process all 26 templates in a single session
- Expected time: 15-30 minutes per template (including validation)
- Total estimated time: 6-13 hours

### Option 2: Archetype Designer (Alternative - Web-Based)

**URL:** https://archetype.openehr.org/

**Steps:**
1. Create account or sign in
2. Import ADL template
3. Validate and fix any issues
4. Export as OPT format
5. Save to `ehrbase-templates/opt-templates/`

### Option 3: ADL Workbench (Desktop Application - Advanced)

**Installation:** See https://openehr.github.io/adl-tools/adl_workbench_guide.html

**Best for:** Developers comfortable with desktop applications, batch processing

### Option 4: Archie Java Library (Programmatic - For Automation)

**GitHub:** https://github.com/openEHR/archie

**Use Case:** Automate conversion for future template updates

**Example:**
```java
import com.nedap.archie.adlparser.ADLParser;
import com.nedap.archie.flattener.Flattener;

// Parse ADL file
Archetype archetype = new ADLParser().parse(adlContent);

// Flatten to operational template
OperationalTemplate opt = new Flattener(null).flatten(archetype);

// Export to XML
String optXml = new OptXmlSerializer().serialize(opt);
```

## Upload Process

### Prerequisites

1. **OPT Files Generated:** All 19 specialty templates converted to OPT format
2. **Namespace Validation:** Ensure `xmlns="http://schemas.openehr.org/v1"` in root element
3. **EHRbase Credentials:** Username: `ehrbase-admin`, Password: `EvenMoreSecretPassword`
4. **EHRbase URL:** `https://ehr.medzenhealth.app/ehrbase`

### Automated Upload Script

Location: `ehrbase-templates/upload_all_templates.sh`

**Usage:**
```bash
chmod +x ehrbase-templates/upload_all_templates.sh
./ehrbase-templates/upload_all_templates.sh
```

**Features:**
- Batch uploads all OPT files from `ehrbase-templates/opt-templates/`
- Validates upload success/failure for each template
- Generates upload report with status for each template
- Updates tracking log
- Handles errors gracefully with retry logic

### Manual Upload (Single Template)

```bash
curl -X POST "https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4" \
  -H "Content-Type: application/xml" \
  -u "ehrbase-admin:EvenMoreSecretPassword" \
  --data-binary "@ehrbase-templates/opt-templates/medzen-antenatal-care-encounter.v1.opt" \
  -w "\nHTTP Status: %{http_code}\n"
```

**Success Response:** HTTP 201 Created

**Common Errors:**
- **400 Bad Request:** XML namespace issue or malformed template
- **401 Unauthorized:** Invalid credentials
- **409 Conflict:** Template already exists (delete first or use PUT to update)

### Verification

**List All Templates:**
```bash
curl -X GET "https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4" \
  -H "Accept: application/json" \
  -u "ehrbase-admin:EvenMoreSecretPassword" | jq '.templates[].template_id'
```

**Get Specific Template:**
```bash
curl -X GET "https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4/medzen.antenatal_care_encounter.v1" \
  -H "Accept: application/xml" \
  -u "ehrbase-admin:EvenMoreSecretPassword"
```

## Directory Structure

```
ehrbase-templates/
├── proper-templates/           # ADL source templates (26 files)
│   ├── medzen-antenatal-care-encounter.v1.adl
│   ├── medzen-surgical-procedure-report.v1.adl
│   └── ... (24 more ADL files)
├── opt-templates/             # Generated OPT files (target directory)
│   └── (Will contain 26 .opt files after conversion)
├── upload_all_templates.sh    # Batch upload script
├── verify_templates.sh        # Verification script
└── OPENEHR_TEMPLATES_GUIDE.md # Comprehensive template documentation
```

## Edge Function Integration

### Template Mapping

The `sync-to-ehrbase` edge function already has template mappings configured:

```typescript
const TEMPLATE_MAPPINGS: Record<string, string> = {
  'antenatal_visits': 'medzen.antenatal_care_encounter.v1',
  'surgical_procedures': 'medzen.surgical_procedure_report.v1',
  'admission_discharge_records': 'medzen.admission_discharge_summary.v1',
  // ... 16 more mappings
};
```

### Required Actions After Upload

1. ✅ **Template Mapping:** Already configured in edge function
2. ✅ **Builder Functions:** Already implemented for all 19 tables
3. ⏳ **Validation:** Test composition creation for each template
4. ⏳ **Error Handling:** Monitor edge function logs for template-related errors

## Testing Procedure

### 1. Template Upload Verification

```bash
# Run verification script
./ehrbase-templates/verify_templates.sh

# Expected output:
# ✅ Found 26 templates in EHRbase
# ✅ All medzen.* templates present
# ✅ Template structure validation passed
```

### 2. Composition Creation Test

For each template, create a test composition:

```bash
# Test antenatal visit composition
curl -X POST "https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/ehr/{ehr_id}/composition" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -u "ehrbase-admin:EvenMoreSecretPassword" \
  -d @test-compositions/antenatal-visit-sample.json
```

### 3. End-to-End Sync Test

1. Create medical record in Supabase (via app or SQL)
2. Verify `ehrbase_sync_queue` entry created
3. Monitor edge function logs: `npx supabase functions logs sync-to-ehrbase`
4. Verify composition created in EHRbase
5. Check `ehrbase_sync_queue.sync_status` = 'completed'

## Deployment Checklist

### Phase 1: Template Conversion (Estimated: 6-13 hours)

- [ ] Set up access to OpenEHR Template Designer
- [ ] Create output directory: `mkdir -p ehrbase-templates/opt-templates`
- [ ] Convert 19 priority templates (antenatal → physiotherapy)
- [ ] Convert 7 additional templates (demographics → palliative care)
- [ ] Validate all OPT files have correct namespace
- [ ] Update tracking table with conversion status

### Phase 2: Template Upload (Estimated: 30 minutes)

- [ ] Test upload with single template
- [ ] Fix any namespace/format issues
- [ ] Run batch upload script: `./ehrbase-templates/upload_all_templates.sh`
- [ ] Verify all 26 templates uploaded: `./ehrbase-templates/verify_templates.sh`
- [ ] Update tracking table with upload status

### Phase 3: Integration Testing (Estimated: 2-3 hours)

- [ ] Test composition creation for each of 19 specialty templates
- [ ] Verify edge function processes sync queue correctly
- [ ] Test offline-first workflow (create → sync → verify)
- [ ] Check error handling for invalid compositions
- [ ] Monitor edge function logs for 24 hours

### Phase 4: Production Deployment (Estimated: 1 hour)

- [ ] Deploy updated edge function (if changes needed)
- [ ] Update PowerSync sync rules (already deployed)
- [ ] Test signup flow with new templates
- [ ] Create sample medical records for each specialty
- [ ] Document any template-specific validation rules
- [ ] Train team on new specialty data entry

## Troubleshooting

### Issue: Namespace Error on Upload

**Error:** `The prefix "xsi" for attribute "xsi:type" associated with an element type "attributes" is not bound`

**Solution:** Ensure root element has correct namespace:
```xml
<template xmlns="http://schemas.openehr.org/v1">
```

NOT:
```xml
<template xmlns="openEHR/v1/Template">
```

### Issue: Template Already Exists

**Error:** HTTP 409 Conflict

**Solution:**
```bash
# Delete existing template
curl -X DELETE "https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4/{template_id}" \
  -u "ehrbase-admin:EvenMoreSecretPassword"

# Re-upload
curl -X POST ... (as above)
```

### Issue: Composition Creation Fails

**Error:** Template validation error in edge function

**Diagnosis:**
1. Check template uploaded: `GET /definition/template/adl1.4/{template_id}`
2. Validate composition structure matches template
3. Check required fields per template archetype
4. Verify terminology bindings (SNOMED CT, LOINC)

**Solution:** Update composition builder function in edge function

## Timeline Estimate

| Phase | Task | Estimated Time | Dependencies |
|-------|------|----------------|--------------|
| 1 | ADL → OPT conversion (19 priority) | 6-10 hours | Template Designer access |
| 2 | ADL → OPT conversion (7 additional) | 3-4 hours | Phase 1 |
| 3 | Batch upload all templates | 30 minutes | Phase 2, EHRbase access |
| 4 | Verification & testing | 2-3 hours | Phase 3 |
| 5 | Integration testing | 2-3 hours | Phase 4, Supabase sync |
| 6 | Production deployment | 1 hour | Phase 5 |
| **Total** | **End-to-End** | **15-21 hours** | All phases |

## Success Criteria

✅ **All 19 Priority Templates:**
- Converted to valid OPT format
- Uploaded to EHRbase successfully
- Compositions can be created programmatically
- Edge function processes sync queue without errors

✅ **Integration Verified:**
- Test medical records created for each specialty
- Sync queue processes within 5 minutes
- No sync errors in edge function logs
- All compositions appear in EHRbase

✅ **Production Ready:**
- Documentation complete
- Team trained on specialty data entry
- Monitoring in place for sync errors
- Rollback plan documented

## Support Resources

- **OpenEHR Documentation:** https://specifications.openehr.org/
- **EHRbase API Docs:** https://ehrbase.readthedocs.io/
- **Template Designer:** https://tools.openehr.org/designer/
- **Archetype Repository:** https://ckm.openehr.org/
- **MedZen Project Docs:** See `CLAUDE.md`, `EHR_SYSTEM_DEPLOYMENT.md`

## Next Steps

1. **Immediate:** Begin ADL-to-OPT conversion using OpenEHR Template Designer
2. **After Conversion:** Run batch upload script
3. **After Upload:** Execute integration tests
4. **Before Production:** Complete deployment checklist

---

**Document Version:** 1.0.0
**Last Updated:** 2025-11-02
**Status:** ADL templates complete, awaiting OPT conversion
**Owner:** Development Team
