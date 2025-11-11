# OpenEHR Templates Directory

This directory contains OpenEHR templates and automation scripts for the MedZen healthcare application.

## 📁 Directory Structure

```
ehrbase-templates/
├── proper-templates/              # Source ADL templates (26 files)
│   ├── medzen-antenatal-care-encounter.v1.adl
│   ├── medzen-surgical-procedure-report.v1.adl
│   └── ... (24 more .adl files)
├── opt-templates/                 # Converted OPT files (XML format)
│   └── (Empty - awaiting conversion from ADL)
├── convert_templates_helper.sh    # 🚀 Interactive conversion workflow helper
├── upload_all_templates.sh        # ✅ Batch upload script
├── verify_templates.sh            # ✅ Verification script
├── track_conversion_progress.sh   # ✅ Conversion progress tracker
├── CONVERSION_WORKFLOW.md         # 📖 Optimized conversion workflow guide
├── TEMPLATE_CONVERSION_STATUS.md  # ⭐ Current status tracking
├── README.md                      # This file
└── TEMPLATE_DESIGN_OVERVIEW.md    # Template architecture documentation
```

## 🚀 Quick Start

### Step 0: Check Conversion Status

```bash
# See what needs to be converted
./track_conversion_progress.sh
```

### Step 1: Convert ADL to OPT Format

**Option A: Interactive Helper Script (Recommended - Fastest)**
```bash
# Streamlined workflow with automation
./convert_templates_helper.sh
```
Features:
- 🚀 Auto-opens Template Designer in browser
- 📋 Auto-copies ADL content to clipboard
- 💾 Saves progress (resumable across sessions)
- ✅ Validates OPT files automatically
- 📊 Real-time progress tracking
- Estimated time: 15-25 minutes per template (6.5-10.8 hours total)

See `CONVERSION_WORKFLOW.md` for detailed workflow guide and optimization tips.

**Option B: Manual Template Designer Workflow**
1. Navigate to https://tools.openehr.org/designer/
2. Import each ADL file from `proper-templates/`
3. Export as "Operational Template (OPT)"
4. Save to `opt-templates/` directory
5. Run `./track_conversion_progress.sh` to verify
6. Estimated time: 20-30 minutes per template (8.7-13 hours total)

**Option C: Archie Java Library** (for programmatic automation)
- See `OPENEHR_TEMPLATE_DEPLOYMENT_GUIDE.md` for programmatic conversion

### Step 2: Upload Templates to EHRbase

```bash
# Upload all converted OPT templates
./upload_all_templates.sh

# Expected output:
# - Color-coded status for each template
# - Success/failure report
# - Detailed log file in ehrbase-templates/
```

### Step 3: Verify Upload

```bash
# Verify all templates are in EHRbase
./verify_templates.sh

# Expected output:
# ✅ Found 26 templates in EHRbase
# ✅ All medzen.* templates present
# ✅ Template structure validation passed
```

## 📋 Template Inventory

### 19 Specialty Medical Tables (Priority 1)
| Template ID | Supabase Table | Status |
|-------------|----------------|--------|
| medzen.antenatal_care_encounter.v1 | antenatal_visits | ⏳ ADL exists |
| medzen.surgical_procedure_report.v1 | surgical_procedures | ⏳ ADL exists |
| medzen.admission_discharge_summary.v1 | admission_discharge_records | ⏳ ADL exists |
| medzen.medication_dispensing_record.v1 | medication_dispensing | ⏳ ADL exists |
| medzen.pharmacy_stock_management.v1 | pharmacy_stock | ⏳ ADL exists |
| medzen.clinical_consultation.v1 | clinical_consultations | ⏳ ADL exists |
| medzen.oncology_treatment.v1 | oncology_treatments | ⏳ ADL exists |
| medzen.infectious_disease_encounter.v1 | infectious_disease_visits | ⏳ ADL exists |
| medzen.cardiology_encounter.v1 | cardiology_visits | ⏳ ADL exists |
| medzen.emergency_encounter.v1 | emergency_visits | ⏳ ADL exists |
| medzen.nephrology_encounter.v1 | nephrology_visits | ⏳ ADL exists |
| medzen.gastroenterology_procedures.v1 | gastroenterology_procedures | ⏳ ADL exists |
| medzen.endocrinology_management.v1 | endocrinology_visits | ⏳ ADL exists |
| medzen.pulmonology_encounter.v1 | pulmonology_visits | ⏳ ADL exists |
| medzen.psychiatric_assessment.v1 | psychiatric_assessments | ⏳ ADL exists |
| medzen.neurology_examination.v1 | neurology_exams | ⏳ ADL exists |
| medzen.radiology_report.v1 | radiology_reports | ⏳ ADL exists |
| medzen.pathology_report.v1 | pathology_reports | ⏳ ADL exists |
| medzen.physiotherapy_session.v1 | physiotherapy_sessions | ⏳ ADL exists |

### 7 Additional Core Templates (Priority 2)
| Template ID | Use Case | Status |
|-------------|----------|--------|
| medzen.patient_demographics.v1 | Patient registration | ⏳ ADL exists |
| medzen.vital_signs.v1 | Vital signs recording | ⏳ ADL exists |
| medzen.lab_results.v1 | Lab test requests/results | ⏳ ADL exists |
| medzen.prescriptions.v1 | Medication lists | ⏳ ADL exists |
| medzen.dermatology.v1 | Dermatology visits | ⏳ ADL exists |
| medzen.palliative_care.v1 | Palliative care | ⏳ ADL exists |

**Total:** 26 templates (25 unique, 1 shared between lab request/result)

## 🔧 Script Details

### track_conversion_progress.sh
**Features:**
- Tracks ADL-to-OPT conversion progress in real-time
- Lists all pending templates awaiting conversion
- Validates converted OPT files (XML namespace check)
- Visual progress bar showing completion percentage
- Identifies invalid OPT files with namespace issues
- Estimates time remaining for conversion
- Color-coded status indicators

**Usage:**
```bash
./track_conversion_progress.sh
```

**When to Use:**
- Before starting conversion (see what needs to be done)
- During conversion (track progress, identify issues)
- After each conversion batch (verify success)
- Before upload (confirm all templates converted correctly)

### upload_all_templates.sh
**Features:**
- Batch uploads all OPT files from `opt-templates/`
- Retry logic with exponential backoff (max 3 attempts)
- Color-coded progress output
- Detailed logging to timestamped log file
- Handles errors: 400 (bad XML), 401 (auth), 409 (conflict)
- Success rate calculation
- Post-upload summary report

**Usage:**
```bash
./upload_all_templates.sh
```

**Requirements:**
- OPT files must exist in `opt-templates/` directory
- EHRbase must be accessible at https://ehr.medzenhealth.app
- Valid credentials: ehrbase-admin:EvenMoreSecretPassword

### verify_templates.sh
**Features:**
- Tests EHRbase connectivity
- Retrieves complete template list
- Verifies all 26 expected medzen.* templates
- Validates XML namespace and structure
- Color-coded pass/fail output
- Template coverage percentage
- Missing template report

**Usage:**
```bash
./verify_templates.sh
```

## 📖 Documentation

**Quick Reference:**
- `TEMPLATE_CONVERSION_STATUS.md` - ⭐ **START HERE** - Current status tracking
  - EHRbase connection details
  - Complete template inventory with conversion status
  - Four conversion options with pros/cons
  - Upload process and integration status
  - Critical path and timeline estimates
  - Quick status check commands
  - Comprehensive troubleshooting

**Comprehensive Guides:**
- `OPENEHR_TEMPLATE_DEPLOYMENT_GUIDE.md` - Complete deployment process (15+ pages)
  - ADL-to-OPT conversion instructions
  - Upload automation
  - Testing procedures
  - Troubleshooting guide
  - Deployment checklist

- `TEMPLATE_DESIGN_OVERVIEW.md` - Template architecture
  - Multi-role system design
  - Archetype selection rationale
  - Specialty-specific templates

**Root Directory Docs:**
- `OPENEHR_TEMPLATES_GUIDE.md` - Template usage guide
- `TEMPLATES_QUICK_REFERENCE.md` - Quick lookup reference

## ⚙️ Integration

### Edge Function
The `sync-to-ehrbase` edge function is already configured with template mappings:

```typescript
const TEMPLATE_MAPPINGS: Record<string, string> = {
  'antenatal_visits': 'medzen.antenatal_care_encounter.v1',
  'surgical_procedures': 'medzen.surgical_procedure_report.v1',
  // ... all 19 specialty tables mapped
};
```

### Sync Queue
Database triggers automatically queue medical records for EHRbase sync:

```sql
CREATE TRIGGER trigger_queue_antenatal_visits_sync
  AFTER INSERT OR UPDATE ON antenatal_visits
  FOR EACH ROW
  EXECUTE FUNCTION queue_antenatal_visits_for_sync();
```

## 🔍 Troubleshooting

### Issue: No OPT files found
**Error:** `No .opt files found in ehrbase-templates/opt-templates/`
**Solution:** Convert ADL templates to OPT format first (see Step 1 above)

### Issue: HTTP 400 Bad Request
**Error:** `The prefix "xsi" for attribute "xsi:type" is not bound`
**Solution:** Fix XML namespace in OPT file:
```xml
<!-- ✅ Correct -->
<template xmlns="http://schemas.openehr.org/v1">

<!-- ❌ Incorrect -->
<template xmlns="openEHR/v1/Template">
```

### Issue: HTTP 409 Conflict
**Error:** Template already exists
**Solution:**
```bash
# Delete existing template
curl -X DELETE "https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4/medzen.template_id.v1" \
  -u "ehrbase-admin:EvenMoreSecretPassword"

# Re-upload
./upload_all_templates.sh
```

### Issue: Connection timeout
**Error:** `Cannot connect to EHRbase`
**Solution:**
1. Verify EHRbase is running: `curl https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4`
2. Check network connectivity
3. Verify credentials are correct

## 📊 Current Status

**✅ Completed:**
- 26 ADL templates created in `proper-templates/`
- Database migrations applied (19 specialty tables)
- PowerSync schema updated
- Edge function configured with template mappings
- Upload automation script created
- Verification script created
- Comprehensive documentation

**⏳ Pending:**
- ADL-to-OPT conversion (requires manual work or Archie library)
- Upload to EHRbase (automated once OPT files exist)
- Integration testing

**📅 Timeline Estimate:**
- ADL-to-OPT conversion: 6-13 hours (manual via web tool)
- Template upload: 30 minutes (automated)
- Verification & testing: 2-3 hours
- **Total:** 9-17 hours

## 🎯 Next Steps

1. **Immediate:** Convert ADL templates to OPT format using OpenEHR Template Designer
2. **After Conversion:** Run `./upload_all_templates.sh`
3. **After Upload:** Run `./verify_templates.sh`
4. **Final:** Test composition creation and sync queue processing

## 📞 Support

For issues or questions:
1. Check `OPENEHR_TEMPLATE_DEPLOYMENT_GUIDE.md` (comprehensive troubleshooting)
2. Review script output and log files
3. Verify EHRbase connectivity and credentials
4. Check OpenEHR specifications: https://specifications.openehr.org/

---

**Last Updated:** 2025-11-02
**Status:** Ready for ADL-to-OPT conversion
**Owner:** Development Team
