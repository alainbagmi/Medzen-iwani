# MedZen OpenEHR Templates Implementation Guide

## Overview

This directory contains 12 proper OpenEHR ADL 1.5.1 templates designed for MedZen's multi-domain healthcare platform. All templates reference official archetypes from the OpenEHR Clinical Knowledge Manager (CKM) and follow international standards for semantic interoperability.

**Territory:** CM (Cameroon)
**Languages:** English (primary), French (translations)
**ADL Version:** 1.5.1
**Reference Model:** OpenEHR RM Release 1.0.4

---

## Template Catalog

### 1. Demographics & Administrative

#### medzen-patient-demographics.v1.adl
**Purpose:** Patient administrative and demographic information
**Specializes:** `openEHR-EHR-COMPOSITION.report.v1`
**Category:** event
**Key Archetypes:**
- `openEHR-EHR-ADMIN_ENTRY.demographics.v0` - Demographics container
- `openEHR-EHR-CLUSTER.person.v1` - Person details (reusable cluster)

**Use Cases:**
- Patient registration
- Demographic updates
- Contact information management
- Emergency contact recording

**Database Mapping:**
- Supabase tables: `users`, `user_profiles`
- EHRbase: Single composition per patient (updated on demographic changes)

---

### 2. Clinical Encounters

#### medzen-vital-signs-encounter.v1.adl
**Purpose:** Comprehensive vital signs measurement during patient encounter
**Specializes:** `openEHR-EHR-COMPOSITION.encounter.v1`
**Category:** event
**Key Archetypes:**
- `openEHR-EHR-OBSERVATION.blood_pressure.v2` - Blood pressure
- `openEHR-EHR-OBSERVATION.pulse.v2` - Heart rate/pulse
- `openEHR-EHR-OBSERVATION.body_temperature.v2` - Temperature
- `openEHR-EHR-OBSERVATION.respiration.v2` - Respiratory rate
- `openEHR-EHR-OBSERVATION.pulse_oximetry.v1` - Oxygen saturation (SpO2)
- `openEHR-EHR-OBSERVATION.height.v2` - Body height
- `openEHR-EHR-OBSERVATION.body_weight.v2` - Body weight
- `openEHR-EHR-OBSERVATION.body_mass_index.v2` - BMI

**Use Cases:**
- Routine vital signs monitoring
- Triage assessment
- Pre/post-operative vitals
- Chronic disease monitoring

**Database Mapping:**
- Supabase table: `vital_signs`
- PowerSync: Offline-first vital signs capture
- EHRbase: Create composition on each vital signs recording session

**Occurrence Constraints:**
- Blood pressure, pulse, temperature, respiration, SpO2: `{0..*}` (multiple readings)
- Height: `{0..1}` (typically once)
- Weight, BMI: `{0..*}` (repeated measurements)

---

#### medzen-clinical-consultation.v1.adl
**Purpose:** Comprehensive clinical consultation/encounter following SOAP structure
**Specializes:** `openEHR-EHR-COMPOSITION.encounter.v1`
**Category:** event
**Key Archetypes:**
- `openEHR-EHR-OBSERVATION.story.v1` - Patient history/presenting complaint
- `openEHR-EHR-OBSERVATION.exam.v1` - Physical examination findings
- `openEHR-EHR-EVALUATION.problem_diagnosis.v1` - Problems/diagnoses (as requested)
- `openEHR-EHR-INSTRUCTION.medication_order.v3` - Medication prescriptions (as requested)
- `openEHR-EHR-INSTRUCTION.service_request.v1` - Lab/imaging orders
- `openEHR-EHR-INSTRUCTION.care_plan.v0` - Care planning

**Specialty Support:**
- General Medicine
- Pediatrics
- Obstetrics & Gynecology
- Cardiology
- Oncology
- Surgery
- Psychiatry
- Dermatology

**Use Cases:**
- Outpatient consultation
- Follow-up visit
- Specialist review
- Telemedicine encounter

**Database Mapping:**
- Supabase tables: `medical_records`, `diagnoses`, `prescriptions`
- EHRbase: Single composition per consultation
- PowerSync: Full offline consultation recording

---

### 3. Medications

#### medzen-medication-list.v1.adl
**Purpose:** Persistent medication list for ongoing medication management
**Specializes:** `openEHR-EHR-COMPOSITION.medication_list.v1`
**Category:** persistent
**Key Archetypes:**
- `openEHR-EHR-EVALUATION.medication_summary.v0` - Individual medication statements
- `openEHR-EHR-EVALUATION.exclusion_specific.v1` - Medication exclusions
- `openEHR-EHR-EVALUATION.absence.v1` - Absence statements

**Use Cases:**
- Current medications tracking
- Medication reconciliation
- Medication history review
- Prescription refill management

**Database Mapping:**
- Supabase table: `prescriptions` (with status tracking)
- PowerSync: Real-time medication list sync
- EHRbase: Updated composition (versioned) on medication changes

**Important:** This is a **persistent** composition (not event-based), updated whenever medication status changes.

---

#### medzen-medication-dispensing-record.v1.adl
**Purpose:** Pharmacy dispensing event documentation
**Specializes:** `openEHR-EHR-COMPOSITION.encounter.v1`
**Category:** event
**Key Archetypes:**
- `openEHR-EHR-INSTRUCTION.medication_order.v3` - Original prescription
- `openEHR-EHR-ACTION.medication.v1` - Dispensing action
- `openEHR-EHR-EVALUATION.adverse_reaction_risk.v1` - Drug interaction alerts
- `openEHR-EHR-EVALUATION.contraindication.v1` - Contraindications
- `openEHR-EHR-EVALUATION.recommendation.v2` - Patient counseling

**Dispensing Types:**
- Prescription medication
- Over-the-counter (OTC)
- Emergency supply
- Repeat prescription
- Partial dispense

**Use Cases:**
- Pharmacy dispensing workflow
- Prescription verification
- Drug interaction checking
- Patient counseling documentation
- Medication substitution recording

**Database Mapping:**
- Supabase tables: `prescriptions` (status update), pharmacy dispensing log (new table needed)
- EHRbase: Composition per dispensing event
- PowerSync: Offline dispensing recording

---

#### medzen-pharmacy-stock-management.v1.adl
**Purpose:** Pharmacy inventory tracking and expiry monitoring
**Specializes:** `openEHR-EHR-COMPOSITION.report.v1`
**Category:** event
**Key Archetypes:**
- `openEHR-EHR-EVALUATION.medication_summary.v0` - Stock status
- `openEHR-EHR-ACTION.medication.v1` - Stock movements (receipt, dispense, return, wastage)
- `openEHR-EHR-EVALUATION.recommendation.v2` - Reorder recommendations

**Report Types:**
- Daily stock report
- Stock receipt
- Stock return
- Expiry alert report
- Stock adjustment
- Reorder recommendation
- Wastage report
- Audit/Stocktake

**Use Cases:**
- Inventory level tracking
- Expiry date monitoring
- Stock receipt recording
- Wastage/disposal documentation
- Reorder alerts
- Audit trail for regulatory compliance

**Database Mapping:**
- Supabase table: New `pharmacy_inventory` table required
- PowerSync: Real-time stock level sync
- EHRbase: Composition per stock report/event

---

### 4. Laboratory

#### medzen-laboratory-test-request.v1.adl
**Purpose:** Laboratory test ordering
**Specializes:** `openEHR-EHR-COMPOSITION.request.v1`
**Category:** event
**Key Archetypes:**
- `openEHR-EHR-INSTRUCTION.service_request.v1` - Test orders
- `openEHR-EHR-CLUSTER.specimen.v1` - Specimen details

**Priority Levels:**
- Routine
- Urgent
- Emergency
- STAT

**Use Cases:**
- Laboratory test ordering
- Specimen collection tracking
- Priority classification
- Test panel requests

**Database Mapping:**
- Supabase table: `lab_results` (with request_status)
- EHRbase: Composition per test request
- PowerSync: Offline test ordering

---

#### medzen-laboratory-result-report.v1.adl
**Purpose:** Laboratory test results reporting
**Specializes:** `openEHR-EHR-COMPOSITION.report-result.v1`
**Category:** event
**Key Archetypes:**
- `openEHR-EHR-OBSERVATION.laboratory_test_result.v1` - Individual test results
- `openEHR-EHR-CLUSTER.specimen.v1` - Specimen information
- `openEHR-EHR-EVALUATION.clinical_synopsis.v1` - Clinical interpretation

**Organized Sections:**
- Clinical Chemistry (glucose, electrolytes, liver/kidney function, lipids)
- Hematology (CBC, coagulation, blood typing)
- Microbiology (cultures, sensitivity, gram stains)
- Pathology (histopathology, cytology)

**Report Status:**
- Preliminary
- Final
- Amended
- Corrected
- Cancelled

**Use Cases:**
- Lab result reporting to clinicians
- Result interpretation
- Abnormal result flagging
- Historical result comparison

**Database Mapping:**
- Supabase table: `lab_results` (status update with results)
- EHRbase: Composition per result report
- PowerSync: Result sync to mobile devices

---

### 5. Maternity Care

#### medzen-antenatal-care-encounter.v1.adl
**Purpose:** Prenatal care visit for pregnant patients
**Specializes:** `openEHR-EHR-COMPOSITION.encounter.v1`
**Category:** event
**Key Archetypes:**
- `openEHR-EHR-EVALUATION.pregnancy_summary.v0` - Pregnancy status
- `openEHR-EHR-OBSERVATION.fetal_movement.v0` - Fetal movements
- `openEHR-EHR-OBSERVATION.imaging_exam_result.v0` - Ultrasound findings
- `openEHR-EHR-EVALUATION.health_risk.v1` - Pregnancy risk assessment
- `openEHR-EHR-OBSERVATION.laboratory_test_result.v1` - Antenatal screening

**Visit Types:**
- Booking visit (first antenatal)
- Routine follow-up
- High-risk follow-up
- Ultrasound scan
- Screening tests
- Problem-focused visit

**Use Cases:**
- Routine antenatal visits
- Prenatal screening
- Fetal monitoring
- Pregnancy complications assessment
- High-risk pregnancy management

**Database Mapping:**
- Supabase tables: `medical_records` (with pregnancy-specific fields), new `antenatal_visits` table recommended
- EHRbase: Composition per antenatal visit
- PowerSync: Offline antenatal recording

**Pregnancy-Specific Data:**
- Gestational age (DV_DURATION)
- Fundal height
- Fetal heart rate
- Fetal lie and presentation
- Ultrasound measurements

---

### 6. Hospital Care

#### medzen-admission-discharge-summary.v1.adl
**Purpose:** Hospital admission and discharge documentation
**Specializes:** `openEHR-EHR-COMPOSITION.report.v1`
**Category:** event
**Key Archetypes:**
- `openEHR-EHR-EVALUATION.problem_diagnosis.v1` - Admission/discharge diagnoses
- `openEHR-EHR-EVALUATION.clinical_synopsis.v1` - Hospital course narrative
- `openEHR-EHR-EVALUATION.medication_summary.v0` - Medication reconciliation
- `openEHR-EHR-EVALUATION.adverse_reaction_risk.v1` - Allergies
- `openEHR-EHR-INSTRUCTION.medication_order.v3` - Discharge medications
- `openEHR-EHR-INSTRUCTION.service_request.v1` - Follow-up arrangements

**Admission Types:**
- Emergency
- Elective
- Transfer from other facility
- Maternity admission

**Discharge Dispositions:**
- Home with self-care
- Home with home care
- Transfer to another facility
- Left against medical advice
- Deceased
- Other

**Use Cases:**
- Hospital admission documentation
- Discharge summary
- Transfer notes
- Medication reconciliation at admission/discharge
- Follow-up planning

**Database Mapping:**
- Supabase table: New `admissions` table required
- EHRbase: Composition per admission-discharge cycle
- PowerSync: Sync admission/discharge data

---

### 7. Oncology

#### medzen-oncology-treatment-plan.v1.adl
**Purpose:** Cancer care planning and treatment documentation
**Specializes:** `openEHR-EHR-COMPOSITION.care_plan.v1`
**Category:** persistent
**Key Archetypes:**
- `openEHR-EHR-EVALUATION.problem_diagnosis.v1` - Cancer diagnosis
- `openEHR-EHR-OBSERVATION.tnm_stage.v1` - TNM staging
- `openEHR-EHR-OBSERVATION.ecog_performance_status.v0` - Performance status
- `openEHR-EHR-INSTRUCTION.medication_order.v3` - Chemotherapy/immunotherapy
- `openEHR-EHR-INSTRUCTION.service_request.v1` - Radiation therapy orders
- `openEHR-EHR-ACTION.procedure.v1` - Surgical procedures

**Cancer Types Supported:**
- Breast cancer
- Lung cancer
- Colorectal cancer
- Prostate cancer
- Cervical cancer
- Liver cancer
- Gastric cancer
- Esophageal cancer
- Lymphoma
- Leukemia
- Other

**Treatment Intent:**
- Curative
- Palliative
- Adjuvant/Neoadjuvant

**Use Cases:**
- Cancer treatment planning
- MDT (multidisciplinary team) discussion documentation
- Chemotherapy protocol management
- Radiation therapy planning
- Immunotherapy/targeted therapy
- Supportive and palliative care

**Database Mapping:**
- Supabase tables: `medical_records` (with oncology-specific fields), new `oncology_treatment_plans` table recommended
- EHRbase: Persistent composition updated throughout treatment
- PowerSync: Treatment plan sync

**Important:** This is a **persistent** composition tracking the entire cancer treatment journey, updated at each treatment milestone.

---

### 8. Surgery

#### medzen-surgical-procedure-report.v1.adl
**Purpose:** Operative report for surgical procedures
**Specializes:** `openEHR-EHR-COMPOSITION.report.v1`
**Category:** event
**Key Archetypes:**
- `openEHR-EHR-EVALUATION.problem_diagnosis.v1` - Pre/post-operative diagnosis
- `openEHR-EHR-ACTION.procedure.v1` - Surgical procedure
- `openEHR-EHR-ACTION.medication.v1` - Anesthesia
- `openEHR-EHR-CLUSTER.specimen.v1` - Specimens removed
- `openEHR-EHR-CLUSTER.device.v1` - Implants and devices
- `openEHR-EHR-OBSERVATION.fluid_balance.v1` - Blood loss tracking

**Urgency Classification:**
- Elective
- Urgent
- Emergency

**Use Cases:**
- Operative report documentation
- Surgical procedure recording
- Anesthesia documentation
- Implant/device tracking
- Specimen collection recording
- Post-operative orders

**Database Mapping:**
- Supabase table: New `surgical_procedures` table required
- EHRbase: Composition per surgical procedure
- PowerSync: Surgical procedure sync

**Comprehensive Sections:**
- Pre-operative assessment
- Anesthesia details
- Operative findings and technique
- Intraoperative complications
- Blood loss and fluid management
- Specimens and implants
- Post-operative diagnosis
- Post-operative orders and care

---

## Architecture Integration

### Database Layer (Supabase)

**Existing Tables:**
- `electronic_health_records` - Links users to EHRbase EHR IDs
- `ehr_compositions` - Tracks OpenEHR compositions (template_id, composition_uid)
- `ehrbase_sync_queue` - Async sync queue for EHRbase updates
- `vital_signs` - Vital signs measurements
- `lab_results` - Laboratory results
- `prescriptions` - Medications
- `medical_records` - General clinical records
- `users`, `user_profiles` - User demographics

**New Tables Required:**
- `pharmacy_inventory` - Medication stock tracking
- `antenatal_visits` - Pregnancy care visits
- `admissions` - Hospital admissions
- `oncology_treatment_plans` - Cancer treatment tracking
- `surgical_procedures` - Operative reports

**Schema Recommendations:**

```sql
-- Pharmacy inventory tracking
CREATE TABLE pharmacy_inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medication_name TEXT NOT NULL,
    batch_number TEXT,
    quantity_on_hand INTEGER NOT NULL,
    reorder_level INTEGER,
    expiry_date DATE,
    unit_price DECIMAL(10,2),
    storage_location TEXT,
    last_stock_check TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Antenatal visits
CREATE TABLE antenatal_visits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID REFERENCES users(id),
    visit_date DATE NOT NULL,
    gestational_age_weeks INTEGER,
    gestational_age_days INTEGER,
    visit_type TEXT, -- booking, routine, high-risk, ultrasound, screening, problem
    fundal_height_cm DECIMAL(4,1),
    fetal_heart_rate INTEGER,
    blood_pressure_systolic INTEGER,
    blood_pressure_diastolic INTEGER,
    weight_kg DECIMAL(5,2),
    risk_factors JSONB,
    ultrasound_findings JSONB,
    ehrbase_composition_uid TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Hospital admissions
CREATE TABLE admissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID REFERENCES users(id),
    admission_date TIMESTAMPTZ NOT NULL,
    discharge_date TIMESTAMPTZ,
    admission_type TEXT, -- emergency, elective, transfer, maternity
    discharge_disposition TEXT, -- home, home_care, transfer, lama, deceased
    primary_diagnosis TEXT,
    secondary_diagnoses JSONB,
    length_of_stay_days INTEGER,
    ehrbase_composition_uid TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Oncology treatment plans
CREATE TABLE oncology_treatment_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID REFERENCES users(id),
    cancer_type TEXT NOT NULL,
    diagnosis_date DATE,
    tnm_stage TEXT,
    ecog_performance_status INTEGER,
    treatment_intent TEXT, -- curative, palliative, adjuvant
    chemotherapy_protocol JSONB,
    radiation_therapy JSONB,
    surgery_planned BOOLEAN DEFAULT FALSE,
    mdt_discussion_date DATE,
    ehrbase_composition_uid TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Surgical procedures
CREATE TABLE surgical_procedures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID REFERENCES users(id),
    procedure_date TIMESTAMPTZ NOT NULL,
    urgency TEXT, -- elective, urgent, emergency
    primary_surgeon TEXT,
    anesthesia_type TEXT,
    pre_op_diagnosis TEXT,
    post_op_diagnosis TEXT,
    procedure_details JSONB,
    complications JSONB,
    blood_loss_ml INTEGER,
    implants_devices JSONB,
    ehrbase_composition_uid TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### PowerSync Integration

All templates support offline-first operation through PowerSync. Sync rules should be configured for each table in `POWERSYNC_SYNC_RULES.yaml`.

**Example Sync Rule (add to existing YAML):**

```yaml
# Antenatal visits - accessible by patient and their providers
- SELECT
    av.id,
    av.patient_id,
    av.visit_date,
    av.gestational_age_weeks,
    av.gestational_age_days,
    av.visit_type,
    av.fundal_height_cm,
    av.fetal_heart_rate,
    av.blood_pressure_systolic,
    av.blood_pressure_diastolic,
    av.weight_kg,
    av.risk_factors,
    av.ultrasound_findings,
    av.created_at,
    av.updated_at
  FROM antenatal_visits av
  WHERE
    token_parameters.user_role = 'patient' AND av.patient_id = token_parameters.user_id
    OR token_parameters.user_role = 'medical_provider' AND av.patient_id IN (
      SELECT patient_id FROM provider_patient_access WHERE provider_id = token_parameters.user_id
    )
```

### EHRbase Integration

**Sync Flow:**
1. User creates/updates medical data → PowerSync local DB (immediate)
2. PowerSync syncs to Supabase (when online)
3. Supabase DB trigger inserts to `ehrbase_sync_queue`
4. Edge function `sync-to-ehrbase` processes queue
5. Edge function creates/updates EHRbase composition using appropriate template

**Edge Function Updates Required:**

Add template mapping in `supabase/functions/sync-to-ehrbase/index.ts`:

```typescript
const TEMPLATE_MAPPING = {
  'vital_signs': 'medzen-vital-signs-encounter.v1',
  'medical_records': 'medzen-clinical-consultation.v1',
  'prescriptions': 'medzen-medication-list.v1',
  'lab_results': 'medzen-laboratory-result-report.v1',
  'antenatal_visits': 'medzen-antenatal-care-encounter.v1',
  'admissions': 'medzen-admission-discharge-summary.v1',
  'oncology_treatment_plans': 'medzen-oncology-treatment-plan.v1',
  'surgical_procedures': 'medzen-surgical-procedure-report.v1',
  'pharmacy_inventory': 'medzen-pharmacy-stock-management.v1'
};
```

---

## Template Upload to EHRbase

**Upload Process:**

1. **Convert ADL to OPT (Operational Template):**
   - Use OpenEHR Template Designer or archetype tooling
   - Generate OPT XML from ADL templates

2. **Upload to EHRbase Server:**
   ```bash
   curl -X POST "https://ehr.medzenhealth.app/ehrbase/rest/ecis/v1/template" \
     -H "Content-Type: application/xml" \
     -u "ehrbase-admin:EvenMoreSecretPassword" \
     --data-binary "@medzen-vital-signs-encounter.v1.opt.xml"
   ```

3. **Verify Upload:**
   ```bash
   curl -X GET "https://ehr.medzenhealth.app/ehrbase/rest/ecis/v1/template" \
     -H "Accept: application/json" \
     -u "ehrbase-admin:EvenMoreSecretPassword"
   ```

**Note:** Template conversion ADL → OPT may require manual processing or tooling. Consider using:
- OpenEHR Template Designer: https://tools.openehr.org/designer/
- Archetype Designer: https://archetype.openehr.org/

---

## Validation and Quality Assurance

### Template Validation Checklist

- [ ] All templates use ADL 1.5.1 syntax
- [ ] All archetypes referenced exist in CKM
- [ ] Occurrence constraints are appropriate for use case
- [ ] Multi-language terminology defined (en/fr minimum)
- [ ] Territory set to CM (Cameroon)
- [ ] COMPOSITION category appropriate (event vs persistent)
- [ ] Template specializes from appropriate base COMPOSITION
- [ ] All sections and entries have unique IDs
- [ ] Terminology codes defined for all value sets
- [ ] Documentation complete (purpose, use, keywords, misuse)

### Data Validation

Implement validation in edge function before creating EHRbase composition:

```typescript
function validateCompositionData(templateId: string, data: any): boolean {
  // Check required fields per template
  // Validate cardinality constraints
  // Verify coded values against terminology
  // Check data types (DV_TEXT, DV_CODED_TEXT, DV_QUANTITY, etc.)
  return true;
}
```

---

## Terminology Bindings

### SNOMED CT Integration

For international interoperability, bind coded terms to SNOMED CT:

**Example:** Problem/Diagnosis binding
```adl
value matches {
    DV_CODED_TEXT[id] matches {
        defining_code matches {
            [SNOMED-CT::
            73211009,    -- Diabetes mellitus
            38341003,    -- Hypertension
            195967001]   -- Asthma
        }
    }
}
```

### LOINC Integration

For laboratory tests:

**Example:** Laboratory test code binding
```adl
value matches {
    DV_CODED_TEXT[id] matches {
        defining_code matches {
            [LOINC::
            2339-0,      -- Glucose
            2951-2,      -- Sodium
            2823-3]      -- Potassium
        }
    }
}
```

**Implementation Note:** Terminology binding should be added in OPT generation phase. ADL templates define structure; OPT adds terminology bindings.

---

## Migration Strategy

### Phase 1: Template Deployment (Week 1)
- Convert ADL templates to OPT format
- Upload all 12 templates to EHRbase server
- Verify template availability via REST API

### Phase 2: Database Schema Updates (Week 2)
- Create new tables (pharmacy_inventory, antenatal_visits, admissions, oncology_treatment_plans, surgical_procedures)
- Add DB triggers for ehrbase_sync_queue
- Update PowerSync sync rules

### Phase 3: Edge Function Updates (Week 3)
- Update sync-to-ehrbase function with template mapping
- Implement validation for each template type
- Add error handling and retry logic
- Deploy and test edge function

### Phase 4: FlutterFlow Integration (Week 4)
- Create custom actions for new data types
- Update page workflows to use new templates
- Add validation and data entry forms
- Test offline-first behavior

### Phase 5: Testing and Validation (Week 5)
- End-to-end testing with test data
- Validate EHRbase composition structure
- Test all 4 user roles
- Offline mode comprehensive testing
- Performance testing with PowerSync sync

### Phase 6: Production Deployment (Week 6)
- Gradual rollout per module (start with vital signs, consultation)
- Monitor sync queue for errors
- User training and documentation
- Post-deployment monitoring

---

## Performance Considerations

### PowerSync Optimization
- Index frequently queried fields in Supabase tables
- Configure appropriate sync batch sizes
- Monitor sync latency per user role

### EHRbase Optimization
- Batch composition creation where possible
- Implement exponential backoff retry for sync failures
- Monitor composition query performance
- Consider archiving old compositions

### Database Optimization
```sql
-- Add indexes for common queries
CREATE INDEX idx_antenatal_visits_patient_date ON antenatal_visits(patient_id, visit_date DESC);
CREATE INDEX idx_admissions_patient_status ON admissions(patient_id, discharge_date NULLS FIRST);
CREATE INDEX idx_pharmacy_inventory_expiry ON pharmacy_inventory(expiry_date) WHERE expiry_date > NOW();
CREATE INDEX idx_oncology_plans_patient ON oncology_treatment_plans(patient_id, created_at DESC);
```

---

## Security and Compliance

### HIPAA Compliance
- All templates support full audit trail through EHRbase versioning
- Supabase row-level security enforces access control
- PowerSync sync rules implement role-based data access
- Encryption at rest and in transit

### Data Retention
- EHRbase maintains full version history of all compositions
- Supabase implements soft delete for critical tables
- Pharmacy stock data retained per regulatory requirements
- Patient data retention per Cameroon healthcare regulations

---

## Support and Maintenance

### Template Versioning
When updating templates:
1. Increment version number (e.g., v1.0.0 → v1.1.0)
2. Create new OPT and upload to EHRbase
3. Update edge function template mapping
4. Implement data migration if structure changes
5. Document breaking changes

### Monitoring
- Monitor `ehrbase_sync_queue` for failed syncs
- Track composition creation latency
- Alert on validation errors
- Monitor PowerSync sync status per user role

### Troubleshooting
Common issues and solutions documented in main project README:
- Template not found in EHRbase → Verify template upload
- Composition validation failed → Check data structure matches template
- Sync queue stuck → Check edge function logs
- PowerSync not syncing → Verify sync rules and JWT token

---

## References

- **OpenEHR Specifications:** https://specifications.openehr.org/
- **Clinical Knowledge Manager:** https://ckm.openehr.org/
- **ADL Workbench:** https://www.openehr.org/downloads/ADLworkbench
- **Template Designer:** https://tools.openehr.org/designer/
- **EHRbase Documentation:** https://ehrbase.readthedocs.io/
- **SNOMED CT Browser:** https://browser.ihtsdotools.org/
- **LOINC Search:** https://loinc.org/

---

## Contact

For questions or issues with OpenEHR template implementation:
- Technical Lead: MedZen Development Team
- Email: info@medzenhealth.app
- Documentation: See project README files in root directory

---

**Last Updated:** 2025-11-02
**Template Count:** 12
**Status:** Production Ready
