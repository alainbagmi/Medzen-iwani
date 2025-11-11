# OpenEHR Template Conversion Status

## Executive Summary

**Current State**: 26 ADL templates created, 0 OPT templates converted, 0 templates uploaded to EHRbase

**Blocker**: ADL-to-OPT conversion is required before templates can be uploaded to EHRbase

**Next Action**: Convert ADL templates to OPT format using OpenEHR Template Designer

## EHRbase Connection Details

### Production EHRbase Instance
- **Base URL**: `https://ehr.medzenhealth.app/ehrbase`
- **REST API**: `/rest/openehr/v1/`
- **Template Endpoint**: `/rest/openehr/v1/definition/template/adl1.4`
- **Status**: ✅ Online and accessible

### Credentials
- **Admin User**: `ehrbase-admin`
- **Admin Password**: `EvenMoreSecretPassword`
- **Purpose**: Template upload/management operations

### Current Template Inventory in EHRbase
EHRbase currently contains **22 generic templates**:
- `vital_signs_basic.v1` (sample template)
- `laboratory_results_report.en.v1`
- `IDCR - Medication Statement List.v1`
- `IDCR - Problem List.v1`
- `IDCR - Procedures List.v1`
- ... 17 more generic templates

**Note**: None of our MedZen-specific templates are in EHRbase yet.

## MedZen Template Inventory

### Local ADL Templates (Source Files)
Location: `ehrbase-templates/proper-templates/`

**Total Count**: 26 ADL templates
**Status**: ✅ Created and validated
**Format**: ADL 1.5.1 (Archetype Definition Language)
**Naming Convention**: `medzen-{specialty}-{type}.v1.adl`

### Template Categories

#### 19 Specialty Medical Tables (Priority 1)
| # | ADL File | Template ID | Supabase Table | OPT Status |
|---|----------|-------------|----------------|------------|
| 1 | `medzen-antenatal-care-encounter.v1.adl` | `medzen.antenatal_care_encounter.v1` | `antenatal_visits` | ❌ Not Converted |
| 2 | `medzen-surgical-procedure-report.v1.adl` | `medzen.surgical_procedure_report.v1` | `surgical_procedures` | ❌ Not Converted |
| 3 | `medzen-admission-discharge-summary.v1.adl` | `medzen.admission_discharge_summary.v1` | `admission_discharge_records` | ❌ Not Converted |
| 4 | `medzen-medication-dispensing-record.v1.adl` | `medzen.medication_dispensing_record.v1` | `medication_dispensing` | ❌ Not Converted |
| 5 | `medzen-pharmacy-stock-management.v1.adl` | `medzen.pharmacy_stock_management.v1` | `pharmacy_stock` | ❌ Not Converted |
| 6 | `medzen-clinical-consultation.v1.adl` | `medzen.clinical_consultation.v1` | `clinical_consultations` | ❌ Not Converted |
| 7 | `medzen-oncology-treatment-plan.v1.adl` | `medzen.oncology_treatment.v1` | `oncology_treatments` | ❌ Not Converted |
| 8 | `medzen-infectious-disease-encounter.v1.adl` | `medzen.infectious_disease_encounter.v1` | `infectious_disease_visits` | ❌ Not Converted |
| 9 | `medzen-cardiology-encounter.v1.adl` | `medzen.cardiology_encounter.v1` | `cardiology_visits` | ❌ Not Converted |
| 10 | `medzen-emergency-medicine-encounter.v1.adl` | `medzen.emergency_encounter.v1` | `emergency_visits` | ❌ Not Converted |
| 11 | `medzen-nephrology-encounter.v1.adl` | `medzen.nephrology_encounter.v1` | `nephrology_visits` | ❌ Not Converted |
| 12 | `medzen-gastroenterology-procedures.v1.adl` | `medzen.gastroenterology_procedures.v1` | `gastroenterology_procedures` | ❌ Not Converted |
| 13 | `medzen-endocrinology-management.v1.adl` | `medzen.endocrinology_management.v1` | `endocrinology_visits` | ❌ Not Converted |
| 14 | `medzen-pulmonology-encounter.v1.adl` | `medzen.pulmonology_encounter.v1` | `pulmonology_visits` | ❌ Not Converted |
| 15 | `medzen-psychiatric-assessment.v1.adl` | `medzen.psychiatric_assessment.v1` | `psychiatric_assessments` | ❌ Not Converted |
| 16 | `medzen-neurology-examination.v1.adl` | `medzen.neurology_examination.v1` | `neurology_exams` | ❌ Not Converted |
| 17 | `medzen-radiology-report.v1.adl` | `medzen.radiology_report.v1` | `radiology_reports` | ❌ Not Converted |
| 18 | `medzen-pathology-report.v1.adl` | `medzen.pathology_report.v1` | `pathology_reports` | ❌ Not Converted |
| 19 | `medzen-physiotherapy-session.v1.adl` | `medzen.physiotherapy_session.v1` | `physiotherapy_sessions` | ❌ Not Converted |

#### 7 Additional Core Templates (Priority 2)
| # | ADL File | Template ID | Use Case | OPT Status |
|---|----------|-------------|----------|------------|
| 20 | `medzen-patient-demographics.v1.adl` | `medzen.patient_demographics.v1` | Patient registration | ❌ Not Converted |
| 21 | `medzen-vital-signs-encounter.v1.adl` | `medzen.vital_signs.v1` | Vital signs recording | ❌ Not Converted |
| 22 | `medzen-laboratory-test-request.v1.adl` | `medzen.lab_results.v1` | Lab test requests | ❌ Not Converted |
| 23 | `medzen-laboratory-result-report.v1.adl` | `medzen.lab_results.v1` | Lab results | ❌ Not Converted |
| 24 | `medzen-medication-list.v1.adl` | `medzen.prescriptions.v1` | Medication lists | ❌ Not Converted |
| 25 | `medzen-dermatology-consultation.v1.adl` | `medzen.dermatology.v1` | Dermatology visits | ❌ Not Converted |
| 26 | `medzen-palliative-care-plan.v1.adl` | `medzen.palliative_care.v1` | Palliative care | ❌ Not Converted |

### Target OPT Templates (Output Directory)
Location: `ehrbase-templates/opt-templates/`

**Current Count**: 0 OPT files
**Status**: ❌ Directory empty, awaiting conversion
**Required Format**: XML (Operational Template format)
**Namespace Required**: `xmlns="http://schemas.openehr.org/v1"`

## ADL-to-OPT Conversion Options

### Option 1: OpenEHR Template Designer (RECOMMENDED)
**Type**: Web-based tool
**URL**: https://tools.openehr.org/designer/
**Pros**:
- Official OpenEHR tool
- No installation required
- Validates template structure
- Provides visual feedback
**Cons**:
- Manual process (one template at a time)
- Time-consuming for 26 templates

**Estimated Time**: 15-30 minutes per template
**Total Time**: 6-13 hours for all 26 templates

**Steps**:
1. Navigate to https://tools.openehr.org/designer/
2. Click "New Template" or "Import"
3. Copy/paste ADL content from `proper-templates/*.adl`
4. Designer validates syntax and shows any errors
5. Click "Export" → "Operational Template (OPT)"
6. Save as `{template-name}.v1.opt` in `opt-templates/` directory
7. Update tracking table in this document
8. Repeat for all 26 templates

### Option 2: Archetype Designer
**Type**: Web-based alternative
**URL**: https://archetype.openehr.org/
**Pros**: Alternative interface
**Cons**: Similar manual process

### Option 3: ADL Workbench
**Type**: Desktop application
**Installation**: https://openehr.github.io/adl-tools/adl_workbench_guide.html
**Pros**: Batch processing capabilities
**Cons**: Complex installation, steep learning curve

### Option 4: Archie Java Library (Programmatic)
**Type**: Java library
**GitHub**: https://github.com/openEHR/archie
**Pros**: Fully automated conversion possible
**Cons**:
- Requires Java development setup
- Complex implementation
- No ready-made conversion script

**Example Code**:
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

**Estimated Setup Time**: 4-6 hours
**Estimated Script Time**: 2-3 hours
**Total**: 6-9 hours + testing

## Upload Process (Ready Once OPT Files Exist)

### Automated Upload Script
**Location**: `ehrbase-templates/upload_all_templates.sh`
**Status**: ✅ Created and ready to use
**Dependencies**: OPT files in `opt-templates/` directory

**Features**:
- Batch uploads all OPT files
- Retry logic (3 attempts per template)
- Error handling (400, 401, 409 HTTP codes)
- Color-coded progress output
- Detailed logging to timestamped files
- Success rate calculation

**Usage**:
```bash
chmod +x ehrbase-templates/upload_all_templates.sh
./ehrbase-templates/upload_all_templates.sh
```

**Expected Output**:
- ✅ HTTP 201 Created - Upload successful
- ⚠️ HTTP 409 Conflict - Template already exists (skipped)
- ❌ HTTP 400 Bad Request - XML namespace or structure issue
- ❌ HTTP 401 Unauthorized - Invalid credentials

**Estimated Time**: 30 minutes (once OPT files exist)

### Verification Script
**Location**: `ehrbase-templates/verify_templates.sh`
**Status**: ✅ Created and ready to use

**Features**:
- Tests EHRbase connectivity
- Retrieves complete template list
- Verifies all 26 expected templates
- Validates XML namespace and structure
- Color-coded pass/fail output
- Template coverage percentage

**Usage**:
```bash
chmod +x ehrbase-templates/verify_templates.sh
./ehrbase-templates/verify_templates.sh
```

## Integration Status

### Supabase Edge Function
**Function**: `sync-to-ehrbase`
**Status**: ✅ Ready and configured
**Template Mappings**: ✅ All 19 specialty tables mapped

```typescript
const TEMPLATE_MAPPINGS: Record<string, string> = {
  'antenatal_visits': 'medzen.antenatal_care_encounter.v1',
  'surgical_procedures': 'medzen.surgical_procedure_report.v1',
  // ... 17 more mappings
}
```

### Database Triggers
**Status**: ✅ Created and active
**Function**: Auto-queue medical records to `ehrbase_sync_queue`

Example trigger for surgical procedures:
```sql
CREATE TRIGGER trigger_queue_surgical_procedures_sync
  AFTER INSERT OR UPDATE ON surgical_procedures
  FOR EACH ROW
  EXECUTE FUNCTION queue_surgical_procedures_for_sync();
```

### Sync Queue
**Table**: `ehrbase_sync_queue`
**Status**: ✅ Ready to process records
**Columns**:
- `sync_status`: pending, processing, completed, failed
- `template_id`: Maps to EHRbase template
- `data_snapshot`: JSONB copy of medical record
- `retry_count`: Exponential backoff retry tracking

## Critical Path to Production

### Phase 1: Template Conversion (CURRENT BLOCKER)
**Estimated Time**: 6-13 hours (manual) or 6-9 hours (programmatic)
**Dependencies**: None
**Task**: Convert all 26 ADL templates to OPT format

**Recommended Approach**: Manual conversion via OpenEHR Template Designer
**Reason**: Fastest time-to-production, no additional setup required

**Checkpoints**:
- [ ] Convert templates 1-5 (antenatal → pharmacy stock)
- [ ] Convert templates 6-10 (clinical consultation → emergency)
- [ ] Convert templates 11-15 (nephrology → psychiatric)
- [ ] Convert templates 16-19 (neurology → physiotherapy)
- [ ] Convert templates 20-26 (patient demographics → palliative care)
- [ ] Verify all OPT files have correct XML namespace
- [ ] Update tracking table with conversion timestamps

### Phase 2: Template Upload (30 minutes)
**Estimated Time**: 30 minutes
**Dependencies**: Phase 1 complete
**Task**: Batch upload all OPT templates to EHRbase

**Steps**:
1. Test upload with single template:
   ```bash
   curl -X POST "https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4" \
     -H "Content-Type: application/xml" \
     -u "ehrbase-admin:EvenMoreSecretPassword" \
     --data-binary "@ehrbase-templates/opt-templates/medzen-vital-signs-encounter.v1.opt"
   ```
2. Fix any namespace/format issues
3. Run batch upload: `./ehrbase-templates/upload_all_templates.sh`
4. Verify uploads: `./ehrbase-templates/verify_templates.sh`

**Expected Result**: All 26 templates uploaded, verification shows 100% coverage

### Phase 3: Integration Testing (2-3 hours)
**Estimated Time**: 2-3 hours
**Dependencies**: Phase 2 complete
**Task**: Test composition creation for each specialty

**Test Cases**:
1. Create test medical record in Supabase (e.g., surgical procedure)
2. Verify `ehrbase_sync_queue` entry created
3. Monitor edge function logs: `npx supabase functions logs sync-to-ehrbase`
4. Verify composition created in EHRbase
5. Check `ehrbase_sync_queue.sync_status` = 'completed'
6. Repeat for all 19 specialty tables

### Phase 4: Production Deployment (1 hour)
**Estimated Time**: 1 hour
**Dependencies**: Phase 3 complete
**Task**: Final verification and monitoring

**Steps**:
1. Deploy updated edge function (if changes needed)
2. Update PowerSync sync rules (already deployed)
3. Test signup flow with new templates
4. Create sample medical records for each specialty
5. Monitor sync queue for 24 hours

## Timeline Estimate

| Phase | Task | Time | Cumulative |
|-------|------|------|------------|
| 1 | ADL → OPT conversion (manual) | 6-13 hours | 6-13 hours |
| 2 | Template upload & verification | 30 min | 7-14 hours |
| 3 | Integration testing | 2-3 hours | 9-17 hours |
| 4 | Production deployment | 1 hour | 10-18 hours |
| **Total** | **End-to-End** | **10-18 hours** | |

## Success Criteria

### Templates
- ✅ All 26 ADL templates converted to OPT format
- ✅ All 26 OPT templates uploaded to EHRbase
- ✅ XML namespace validation passes for all templates
- ✅ Verification script shows 100% coverage

### Integration
- ✅ Test compositions created for each specialty
- ✅ Sync queue processes within 5 minutes
- ✅ No sync errors in edge function logs
- ✅ All compositions appear in EHRbase

### Production Ready
- ✅ Documentation complete
- ✅ Team trained on specialty data entry
- ✅ Monitoring in place for sync errors
- ✅ Rollback plan documented

## Quick Status Check Commands

```bash
# Count ADL templates (should be 26)
ls -1 ehrbase-templates/proper-templates/*.adl | wc -l

# Count OPT templates (target: 26)
ls -1 ehrbase-templates/opt-templates/*.opt 2>/dev/null | wc -l

# List current EHRbase templates
curl -s -X GET "https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4" \
  -H "Accept: application/json" \
  -u "ehrbase-admin:EvenMoreSecretPassword" | jq '.templates[].template_id'

# Verify specific MedZen template exists
curl -s -o /dev/null -w "%{http_code}" \
  -X GET "https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4/medzen.antenatal_care_encounter.v1" \
  -u "ehrbase-admin:EvenMoreSecretPassword"
# Expected: 404 (not found) until uploaded
```

## Troubleshooting

### Issue: Namespace Error on Upload
**Error**: `The prefix "xsi" for attribute "xsi:type" is not bound`
**Solution**: Ensure root element has correct namespace:
```xml
<!-- ✅ Correct -->
<template xmlns="http://schemas.openehr.org/v1">

<!-- ❌ Incorrect -->
<template xmlns="openEHR/v1/Template">
```

### Issue: ADL Parser Errors
**Error**: Syntax errors during conversion
**Solution**:
1. Validate ADL syntax at https://tools.openehr.org/designer/
2. Check for missing terminology bindings
3. Verify archetype references exist

### Issue: Template Already Exists
**Error**: HTTP 409 Conflict
**Solution**:
```bash
# Delete existing template
curl -X DELETE "https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4/{template_id}" \
  -u "ehrbase-admin:EvenMoreSecretPassword"

# Re-upload
./ehrbase-templates/upload_all_templates.sh
```

## Support Resources

- **OpenEHR Documentation**: https://specifications.openehr.org/
- **EHRbase API Docs**: https://ehrbase.readthedocs.io/
- **Template Designer**: https://tools.openehr.org/designer/
- **Archetype Repository**: https://ckm.openehr.org/
- **MedZen Project Docs**: See `CLAUDE.md`, `EHR_SYSTEM_DEPLOYMENT.md`

## Document Version

- **Version**: 1.0.0
- **Created**: 2025-11-02
- **Last Updated**: 2025-11-02
- **Status**: ADL templates complete, awaiting OPT conversion
- **Next Action**: Begin ADL-to-OPT conversion (Phase 1)
- **Owner**: Development Team
