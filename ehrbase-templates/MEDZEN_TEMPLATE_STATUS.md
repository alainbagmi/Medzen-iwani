# MedZen OpenEHR Template Status Report

**Date:** 2025-11-02
**Project:** MedZen Healthcare Application
**EHRbase URL:** https://ehr.medzenhealth.app/ehrbase

## Executive Summary

### Current Situation

✅ **MedZen ADL Templates:** 26 custom templates exist in `proper-templates/` directory
❌ **Conversion Status:** 0 of 26 templates converted to OPT format (0% complete)
❌ **Upload Status:** Cannot upload until conversion is complete
⚠️ **CKM Templates:** 26 generic templates downloaded but NOT needed for MedZen

### Critical Finding

The 26 official OpenEHR CKM templates downloaded to `official-templates/` are **generic, production-ready templates** but are **NOT the templates MedZen needs**. MedZen requires its own custom templates for specialty medical encounters.

## Template Inventory

### Required: 26 MedZen Custom ADL Templates

Located in: `/ehrbase-templates/proper-templates/`
Format: ADL 1.5.1
Status: Source files ready, conversion pending

| # | Template ID | Purpose | Supabase Table |
|---|-------------|---------|----------------|
| 1 | medzen-admission-discharge-summary.v1 | Hospital admission/discharge | admission_discharge_records |
| 2 | medzen-antenatal-care-encounter.v1 | Prenatal care visits | antenatal_visits |
| 3 | medzen-cardiology-encounter.v1 | Cardiology consultations | cardiology_visits |
| 4 | medzen-clinical-consultation.v1 | General clinical visits | clinical_consultations |
| 5 | medzen-dermatology-consultation.v1 | Dermatology consultations | (specialty table) |
| 6 | medzen-emergency-medicine-encounter.v1 | Emergency room visits | emergency_visits |
| 7 | medzen-endocrinology-management.v1 | Endocrine disorders | endocrinology_visits |
| 8 | medzen-gastroenterology-procedures.v1 | GI procedures | gastroenterology_procedures |
| 9 | medzen-infectious-disease-encounter.v1 | Infectious disease visits | infectious_disease_visits |
| 10 | medzen-laboratory-result-report.v1 | Lab test results | lab_results |
| 11 | medzen-laboratory-test-request.v1 | Lab test orders | (test requests) |
| 12 | medzen-medication-dispensing-record.v1 | Pharmacy dispensing | medication_dispensing |
| 13 | medzen-medication-list.v1 | Active medications | prescriptions |
| 14 | medzen-nephrology-encounter.v1 | Kidney disease management | nephrology_visits |
| 15 | medzen-neurology-examination.v1 | Neurological exams | neurology_exams |
| 16 | medzen-oncology-treatment-plan.v1 | Cancer treatment plans | oncology_treatments |
| 17 | medzen-palliative-care-plan.v1 | End-of-life care planning | (palliative care) |
| 18 | medzen-pathology-report.v1 | Pathology lab reports | pathology_reports |
| 19 | medzen-patient-demographics.v1 | Patient demographics | electronic_health_records |
| 20 | medzen-pharmacy-stock-management.v1 | Pharmacy inventory | pharmacy_stock |
| 21 | medzen-physiotherapy-session.v1 | Physical therapy sessions | physiotherapy_sessions |
| 22 | medzen-psychiatric-assessment.v1 | Psychiatric evaluations | psychiatric_assessments |
| 23 | medzen-pulmonology-encounter.v1 | Respiratory medicine | pulmonology_visits |
| 24 | medzen-radiology-report.v1 | Imaging reports | radiology_reports |
| 25 | medzen-surgical-procedure-report.v1 | Surgical procedures | surgical_procedures |
| 26 | medzen-vital-signs-encounter.v1 | Vital signs measurements | vital_signs |

### Downloaded: 26 CKM Generic Templates (Not Required)

Located in: `/ehrbase-templates/official-templates/`
Format: OET (openEHR Template)
Status: Downloaded but not needed for MedZen

**Decision:** These generic CKM templates can be archived or used as reference material but are not required for MedZen deployment.

## Conversion Challenge

### Format Requirements

**Source Format:** ADL 1.5.1 (Archetype Definition Language)
```adl
template (adl_version=1.5.1; rm_release=1.0.4)
    openEHR-EHR-COMPOSITION.medzen_vital_signs_encounter.v1.0.0
```

**Target Format:** OPT 1.4 (Operational Template - XML)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<template xmlns="http://schemas.openehr.org/v1">
    <template_id>
        <value>medzen.vital_signs_encounter.v1</value>
    </template_id>
```

### Conversion Tools Available

| Tool | Status | Capability | Automated? |
|------|--------|-----------|-----------|
| **OpenEHR Template Designer** | ✅ Available | OET → OPT, ADL → OPT | ❌ Manual GUI |
| **ADL Workbench (adlc)** | ❌ Not installed | ADL → OPT | ✅ CLI available |
| **Archie Library** | ❌ ADL 2 only | ADL 2 → OPT 2 | ✅ Programmatic |
| **LinkEHR Editor** | ❌ Not installed | ADL → OPT | ⚠️ Semi-automated |

### Conversion Scripts Available

| Script | Purpose | Status |
|--------|---------|--------|
| `convert_templates_helper.sh` | Interactive ADL → OPT workflow | ✅ Ready |
| `convert_official_templates.sh` | Interactive OET → OPT workflow | ✅ Ready (wrong format) |
| `track_conversion_progress.sh` | Progress tracking | ✅ Ready |

## Conversion Workflow

### Option A: Template Designer (Recommended - Most Reliable)

**Time Estimate:** 15-25 minutes per template = 6.5-10.8 hours total

**Process:**
```bash
# Step 1: Start conversion helper
./ehrbase-templates/convert_templates_helper.sh

# The script will:
# - Open Template Designer in browser
# - Copy ADL content to clipboard
# - Guide through import/export process
# - Validate each converted OPT file
# - Track progress (resumable)

# Step 2: For each template (automated by script):
# - Navigate to https://tools.openehr.org/designer/
# - Click "Import" and paste ADL content
# - Wait for validation
# - Click "Export" → "Operational Template (OPT)"
# - Save to ehrbase-templates/opt-templates/
# - Press ENTER to continue to next template
```

**Advantages:**
- ✅ Most reliable (official tool)
- ✅ Validates template structure
- ✅ Progress tracking and resume capability
- ✅ Automated clipboard and browser operations

**Disadvantages:**
- ⏱️ Time-consuming (6.5-10.8 hours)
- 👤 Requires human interaction for each template

### Option B: ADL Workbench CLI (Fastest - If Installed)

**Time Estimate:** 10-30 minutes for batch conversion

**Installation:**
```bash
# macOS (if available via brew)
brew install openehr/tap/adl-workbench

# Or download from: https://github.com/openEHR/adl-tools/releases
```

**Batch Conversion:**
```bash
# Navigate to ADL Workbench directory
cd /path/to/adl-tools

# Convert all templates
for adl in /path/to/ehrbase-templates/proper-templates/*.adl; do
    filename=$(basename "$adl" .adl)
    ./adlc "$adl" -f xml -a serialise --flat \
        > "/path/to/ehrbase-templates/opt-templates/${filename}.opt"
done
```

**Advantages:**
- ✅ Fully automated
- ✅ Fast batch processing
- ✅ Command-line scriptable

**Disadvantages:**
- ❌ Requires installation
- ⚠️ May have compatibility issues with ADL 1.5.1
- ⚠️ Less documentation available

### Option C: Archie Library (Not Applicable)

**Status:** ❌ Not compatible

**Reason:** Archie focuses on ADL 2 / OPT 2 format. MedZen templates use ADL 1.4/1.5.1 format.

## Upload Preparation

### Upload Script Status

✅ **Script:** `upload_all_templates.sh`
✅ **Endpoint:** Configured for `https://ehr.medzenhealth.app/ehrbase`
✅ **Authentication:** Credentials configured
⏳ **Status:** Ready to run once conversion complete

### Upload Process

```bash
# After conversion completes:

# Step 1: Verify all OPT files
ls -1 ehrbase-templates/opt-templates/*.opt | wc -l
# Expected: 26

# Step 2: Upload to EHRbase
./ehrbase-templates/upload_all_templates.sh

# Expected output:
# ✅ 26/26 templates uploaded successfully
# Detailed log: ehrbase-templates/upload_log_YYYYMMDD_HHMMSS.txt

# Step 3: Verify upload
./ehrbase-templates/verify_templates.sh

# Expected output:
# ✅ Found 26 templates in EHRbase
# ✅ All medzen.* templates present
```

## Database Integration Status

### Sync Queue Configuration

✅ **DB Triggers:** Configured for all specialty tables
✅ **Edge Function:** `sync-to-ehrbase` deployed
✅ **Template Mapping:** All 26 templates mapped to tables

### Template Usage in Migrations

**Core Templates (Referenced in migrations):**
- `ehrbase.demographics.v1` → Used in user EHR creation
- `ehrbase.vital_signs.v1` → Used in vital_signs table sync
- `ehrbase.lab_results.v1` → Used in lab_results table sync
- `ehrbase.prescriptions.v1` → Used in prescriptions table sync

**Specialty Templates (Referenced in migrations):**
All 19 specialty templates are referenced in their respective table triggers (see `supabase/migrations/202502*.sql` files).

### Missing Templates Analysis

**Currently in EHRbase:** 2 templates
1. `vital_signs_basic.opt` (from openehr-mcp-server)
2. `medzen.provider.profile.v1.opt` (custom)

**Missing from EHRbase:** 26 templates
- All MedZen ADL templates need conversion and upload
- Core ehrbase.* templates may need creation or mapping

## Next Steps (Priority Order)

### Immediate Actions

1. **Decide Conversion Method**
   - Option A: Manual via Template Designer (6.5-10.8 hours)
   - Option B: Install ADL Workbench CLI (10-30 minutes + setup)
   - Recommendation: Start with Option A (most reliable)

2. **Begin Conversion**
   ```bash
   # Track current status
   ./ehrbase-templates/track_conversion_progress.sh

   # Start conversion
   ./ehrbase-templates/convert_templates_helper.sh
   ```

3. **Monitor Progress**
   - Progress file: `ehrbase-templates/.conversion_progress`
   - Status document: `ehrbase-templates/TEMPLATE_CONVERSION_STATUS.md`
   - Resumable at any time (press Q to pause)

### Post-Conversion Actions

4. **Batch Upload**
   ```bash
   ./ehrbase-templates/upload_all_templates.sh
   ```

5. **Verification**
   ```bash
   # Verify templates in EHRbase
   ./ehrbase-templates/verify_templates.sh

   # Test composition creation
   npx supabase functions logs sync-to-ehrbase --tail
   ```

6. **Integration Testing**
   - Create test data in Supabase
   - Monitor `ehrbase_sync_queue` table
   - Verify compositions created in EHRbase
   - Check edge function logs for errors

## Time Estimates

| Task | Time (Option A) | Time (Option B) |
|------|----------------|----------------|
| **ADL → OPT Conversion** | 6.5-10.8 hours | 10-30 minutes |
| **Upload to EHRbase** | 15-30 minutes | 15-30 minutes |
| **Verification** | 30-60 minutes | 30-60 minutes |
| **Integration Testing** | 1-2 hours | 1-2 hours |
| **TOTAL** | 8.5-14.5 hours | 2-4 hours |

## Archive Decisions

### CKM Templates (26 .oet files)

**Location:** `ehrbase-templates/official-templates/`
**Recommendation:** Archive for reference

```bash
# Create archive directory
mkdir -p ehrbase-templates/archive/ckm-templates-reference

# Move CKM templates to archive
mv ehrbase-templates/official-templates/*.oet \
   ehrbase-templates/archive/ckm-templates-reference/

# Update documentation
echo "Archived 26 generic CKM templates (not required for MedZen)" \
    > ehrbase-templates/archive/ckm-templates-reference/README.txt
```

**Rationale:**
- Generic templates don't match MedZen's specialty structure
- May be useful as reference for future template design
- Keeps `official-templates/` directory clean

## References

- **Template Designer:** https://tools.openehr.org/designer/
- **ADL Workbench:** https://github.com/openEHR/adl-tools
- **EHRbase Documentation:** https://ehrbase.readthedocs.io/
- **OpenEHR Specifications:** https://specifications.openehr.org/

## Support

**Issues:**
- Conversion failures: Check CONVERSION_WORKFLOW.md
- Upload failures: Check upload script logs
- Sync failures: `npx supabase functions logs sync-to-ehrbase`

**Contact:**
- MedZen Dev Team: info@medzenhealth.app
- EHRbase: https://ehr.medzenhealth.app/ehrbase

---

**Status:** Conversion pending - ready to begin
**Last Updated:** 2025-11-02
**Next Action:** Execute `./ehrbase-templates/convert_templates_helper.sh`
