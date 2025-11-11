# EHRbase Test Compositions Report

**Date**: October 30, 2025
**EHRbase Instance**: ehr.medzenhealth.app
**EHRbase Version**: 2.24.0
**Test EHR ID**: 123c67f7-3022-4693-9013-96fe73218573

## Executive Summary

This report documents the successful creation of test compositions for the deployed OpenEHR templates in the MedZen EHRbase instance. A total of 22 clinical templates have been deployed, and test compositions have been created to validate template functionality.

## Test Composition Results

### 1. Vital Signs Test Composition ✅ SUCCESS

**Composition UID**: `6c457be9-f44b-4820-8238-066e5b5cd0b2::ehrbase-fargate::1`
**Template**: vital_signs_basic.v1
**Status**: Successfully created
**Created**: 2025-10-30T14:30:00Z

#### Clinical Data Captured
- **Blood Pressure**: 120/80 mmHg
- **Heart Rate**: 72 bpm
- **Territory**: ZA (South Africa)
- **Composer**: Dr. Test Provider
- **Setting**: Other care

#### File Location
- Canonical format: `/tmp/vital_signs_canonical.json`
- Response: `/tmp/composition_created.json`

#### Key Learnings
1. **Canonical Format Required**: The POST `/composition` endpoint requires canonical OpenEHR format, not FLAT or STRUCTURED formats
2. **Mandatory Attributes**:
   - `archetype_node_id` at COMPOSITION root level
   - `name` object with proper DV_TEXT structure
   - `archetype_details` with ARCHETYPED structure containing archetype_id
3. **Archetype Root Invariant**: All OBSERVATION objects must include `archetype_details` with proper archetype_id to satisfy the `Is_archetypeRoot` invariant

### 2. Laboratory Results Test Composition ⚠️ IN PROGRESS

**Template**: laboratory_results_report.en.v1
**Status**: Template structure requires further investigation
**Issue**: Archetype mismatch - the OBSERVATION archetype used doesn't match template expectations

#### Errors Encountered
```
{
  "error": "Unprocessable Entity",
  "message": "/name: The value \"Laboratory Results Report\" must be \"Laboratory Result Report\", : RmObject with type:Observation, nodeId:openEHR-EHR-OBSERVATION.laboratory_test_result.v1,name:Laboratory Test Result; not in template"
}
```

#### Next Steps
1. Retrieve template definition using GET `/definition/template/adl1.4/laboratory_results_report.en.v1`
2. Identify correct OBSERVATION archetypes expected by template
3. Create composition with correct archetype nodes

## Deployed Templates Summary

Total of 22 templates successfully deployed to EHRbase:

### Core Clinical Templates
1. **vital_signs_basic.v1** ✅ - Validated with test composition
2. **laboratory_results_report.en.v1** - Requires archetype validation
3. **IDCR - Medication Statement List.v1** - Pending test composition

### Medication Management
4. IDCR - Adverse Reaction List.v1
5. IDCR - Immunisation summary.v1
6. IDCR - Procedures List.v1

### Patient Assessment
7. RESPECT - Preferred priorities of care.v1
8. Patient Encounter.en.v1
9. Clinical Synopsis.v1

### Medical History
10. IDCR - Problem List.v1
11. IDCR - Relevant contacts.v1
12. IDCR - Family History.v1
13. Problem Diagnosis.v1

### Care Planning
14. Care Plan.v1
15. Health Protection Risk Screening.v1
16. Community Pharmacy Consultation.v1
17. Warfarin Monitoring.en.v1

### Specialized Assessments
18. SERVICE - Social Isolation Risk.v0
19. Social_care_plan.v0
20. Mental Health Triage.en.v1
21. Mental_health_assessment.v0
22. Substance Use Assessment (CAGE).v1

## OpenEHR Composition Format Requirements

### Canonical Format Structure

All compositions must follow the canonical OpenEHR Reference Model format:

```json
{
  "_type": "COMPOSITION",
  "archetype_node_id": "openEHR-EHR-COMPOSITION.encounter.v1",
  "name": {
    "_type": "DV_TEXT",
    "value": "Composition Name"
  },
  "archetype_details": {
    "_type": "ARCHETYPED",
    "archetype_id": {
      "_type": "ARCHETYPE_ID",
      "value": "openEHR-EHR-COMPOSITION.encounter.v1"
    },
    "template_id": {
      "_type": "TEMPLATE_ID",
      "value": "template_name.v1"
    },
    "rm_version": "1.0.4"
  },
  "language": { ... },
  "territory": { ... },
  "category": { ... },
  "composer": { ... },
  "context": { ... },
  "content": [ ... ]
}
```

### OBSERVATION Requirements

Each OBSERVATION in the content array must include:

```json
{
  "_type": "OBSERVATION",
  "name": { ... },
  "archetype_node_id": "openEHR-EHR-OBSERVATION.archetype.v1",
  "archetype_details": {
    "_type": "ARCHETYPED",
    "archetype_id": {
      "_type": "ARCHETYPE_ID",
      "value": "openEHR-EHR-OBSERVATION.archetype.v1"
    },
    "rm_version": "1.0.4"
  },
  "language": { ... },
  "encoding": { ... },
  "subject": { "_type": "PARTY_SELF" },
  "data": { ... }
}
```

## API Endpoints Used

### Template Management
- `GET /rest/openehr/v1/definition/template/adl1.4` - List all templates
- `POST /rest/openehr/v1/definition/template/adl1.4` - Upload template
- `GET /rest/openehr/v1/definition/template/adl1.4/{template_id}/example?format=FLAT|STRUCTURED` - Get example

### EHR Management
- `POST /rest/openehr/v1/ehr` - Create EHR
- `GET /rest/openehr/v1/ehr/{ehr_id}` - Get EHR details

### Composition Management
- `POST /rest/openehr/v1/ehr/{ehr_id}/composition` - Create composition (requires canonical format)
- `GET /rest/openehr/v1/ehr/{ehr_id}/composition/{composition_uid}` - Get composition

### Authentication
All endpoints require HTTP Basic Authentication:
- Username: ehrbase_user
- Password: Retrieved from AWS Secrets Manager (ehrbase/ehrbase-password)

## Testing Workflow

### 1. Template Upload
```bash
# Get credentials
EHRBASE_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id ehrbase/ehrbase-password \
  --region af-south-1 \
  --query SecretString \
  --output text)

# Upload template
curl -X POST \
  "http://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4" \
  -H "Content-Type: application/xml" \
  -u "ehrbase_user:${EHRBASE_PASSWORD}" \
  --data-binary @template.xml
```

### 2. Create Test EHR
```bash
curl -X POST \
  "http://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/ehr" \
  -H "Content-Type: application/json" \
  -u "ehrbase_user:${EHRBASE_PASSWORD}" \
  -d '{"ehr_status": {"subject": {"external_ref": {"id": {"value": "test-patient"}, "namespace": "medzen"}}}}'
```

### 3. Create Composition
```bash
curl -X POST \
  "http://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/ehr/{ehr_id}/composition" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Prefer: return=representation" \
  -u "ehrbase_user:${EHRBASE_PASSWORD}" \
  -d @composition_canonical.json
```

## Common Errors and Solutions

### 1. HTTP 400: Missing Name Attribute
**Error**: "Composition missing mandatory attribute: name"
**Solution**: Ensure composition has `name` object at root level:
```json
"name": {
  "_type": "DV_TEXT",
  "value": "Composition Name"
}
```

### 2. HTTP 400: Missing archetype_node_id
**Error**: "Composition missing mandatory attribute: archetype_node_id"
**Solution**: Add `archetype_node_id` at COMPOSITION root level:
```json
{
  "_type": "COMPOSITION",
  "archetype_node_id": "openEHR-EHR-COMPOSITION.encounter.v1",
  ...
}
```

### 3. HTTP 422: Invariant Is_archetypeRoot Failed
**Error**: "Invariant Is_archetypeRoot failed on type OBSERVATION"
**Solution**: Add `archetype_details` to each OBSERVATION:
```json
"archetype_details": {
  "_type": "ARCHETYPED",
  "archetype_id": {
    "_type": "ARCHETYPE_ID",
    "value": "openEHR-EHR-OBSERVATION.archetype.v1"
  },
  "rm_version": "1.0.4"
}
```

### 4. HTTP 422: RmObject Not in Template
**Error**: "RmObject with type:Observation, nodeId:...; not in template"
**Solution**:
1. Retrieve template definition to identify correct archetypes
2. Ensure OBSERVATION archetypes match those defined in template
3. Verify composition name matches template expectations (singular vs plural)

## AWS Infrastructure

### ECS Fargate Service
- **Cluster**: medzen-ehrbase-cluster
- **Service**: ehrbase-api-service
- **Region**: af-south-1 (Cape Town)
- **Load Balancer**: ehr.medzenhealth.app

### RDS PostgreSQL
- **Instance**: medzen-ehrbase-db
- **Engine**: PostgreSQL 13
- **Multi-AZ**: Enabled

### Secrets Manager
- **Secret**: ehrbase/ehrbase-password
- **Credentials**: ehrbase_user / [managed password]

## Integration with MedZen Application

### PowerSync Offline-First Architecture
The EHRbase integration supports offline-first functionality through PowerSync:

1. **Local Write → PowerSync SQLite**: Immediate, never fails
2. **PowerSync → Supabase**: Bidirectional sync when online
3. **Supabase → ehrbase_sync_queue**: Database triggers auto-queue changes
4. **Edge Function → EHRbase**: Async processing with retry logic

### Supabase Tables
- `electronic_health_records`: Links users to EHRbase EHR IDs
- `ehr_compositions`: OpenEHR compositions metadata
- `ehrbase_sync_queue`: Sync queue with retry logic
- `vital_signs`, `lab_results`, `prescriptions`: Medical data tables

### Firebase Cloud Functions
- `onUserCreated`: Creates EHRbase EHR + Supabase user atomically
- `onUserDeleted`: Cleanup across all systems

## Recommendations

### Immediate Actions
1. **Complete Laboratory Results Template**: Investigate correct archetypes and create valid test composition
2. **Create Medication Statement Test**: Validate IDCR - Medication Statement List.v1 template
3. **Document Template-Specific Archetypes**: For each template, document expected OBSERVATION/CLUSTER archetypes

### Template Validation Process
For each template:
1. Retrieve template definition using GET `/definition/template/adl1.4/{template_id}`
2. Identify all OBSERVATION and CLUSTER archetypes
3. Create minimal valid composition with required data points
4. Test POST to validate structure
5. Document working composition as reference

### Production Readiness
1. **Template Documentation**: Create usage guides for top 5 most-used templates
2. **SDK Integration**: Generate client SDKs for composition creation (Python, TypeScript)
3. **Validation Library**: Create composition validation utilities
4. **Error Handling**: Implement comprehensive error handling in sync-to-ehrbase edge function
5. **Monitoring**: Set up CloudWatch alarms for EHRbase API errors

## Conclusion

The EHRbase deployment is operational with 22 clinical templates successfully installed. The vital signs template has been validated with a successful test composition creation. The canonical OpenEHR format requirements are now well-understood, enabling efficient composition creation for remaining templates.

**Next Phase**: Complete test compositions for laboratory results and medications, then proceed with integration testing across the full MedZen application stack (Flutter → Firebase → Supabase → PowerSync → EHRbase).

---

**Report Generated**: 2025-10-30
**Author**: Claude Code
**Documentation**: See EHRBASE_DEPLOYMENT_COMPLETE.md for deployment details
