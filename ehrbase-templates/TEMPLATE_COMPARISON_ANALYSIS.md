# Template Comparison: MedZen Custom vs Official CKM Templates

**Date:** 2025-11-02
**Decision Required:** Which templates should we convert and upload to EHRbase?

## Quick Summary

| Aspect | MedZen Custom (26 ADL) | Official CKM (26 OET) |
|--------|----------------------|---------------------|
| **Format** | ADL 1.5.1 → needs OPT conversion | OET → needs OPT conversion |
| **Conversion Time** | 6.5-10.8 hours | 6.5-10.8 hours |
| **Maintenance** | Custom by MedZen team | Community-maintained |
| **Database Integration** | ✅ Matches Supabase structure | ⚠️ May need DB updates |
| **African Context** | ✅ Territory: CM, Languages: en/fr | ⚠️ Generic international |
| **Template IDs** | `medzen.*` (matches migrations) | Various standards |

## Detailed Comparison

### MedZen Custom Templates (proper-templates/)

**Pros:**
- ✅ **Designed for MedZen** - Custom-built for exact requirements
- ✅ **Database Integration** - Template IDs match Supabase migrations (`medzen.admission_discharge_summary.v1`, etc.)
- ✅ **African Healthcare Context** - Territory: CM (Cameroon), Languages: en, fr
- ✅ **Specialty Coverage** - All 19 MedZen specialties covered (cardiology, oncology, psychiatry, etc.)
- ✅ **Table Mappings** - Direct mappings to Supabase tables in migrations

**Cons:**
- ⏱️ **Same Conversion Time** - Still 6.5-10.8 hours manual work
- 🛠️ **Maintenance Burden** - Team must maintain template updates
- ⚠️ **Community Support** - Less external validation/testing

**Templates List:**
```
1. medzen-admission-discharge-summary.v1
2. medzen-antenatal-care-encounter.v1
3. medzen-cardiology-encounter.v1
4. medzen-clinical-consultation.v1
5. medzen-dermatology-consultation.v1
6. medzen-emergency-medicine-encounter.v1
7. medzen-endocrinology-management.v1
8. medzen-gastroenterology-procedures.v1
9. medzen-infectious-disease-encounter.v1
10. medzen-laboratory-result-report.v1
11. medzen-laboratory-test-request.v1
12. medzen-medication-dispensing-record.v1
13. medzen-medication-list.v1
14. medzen-nephrology-encounter.v1
15. medzen-neurology-examination.v1
16. medzen-oncology-treatment-plan.v1
17. medzen-palliative-care-plan.v1
18. medzen-pathology-report.v1
19. medzen-patient-demographics.v1
20. medzen-pharmacy-stock-management.v1
21. medzen-physiotherapy-session.v1
22. medzen-psychiatric-assessment.v1
23. medzen-pulmonology-encounter.v1
24. medzen-radiology-report.v1
25. medzen-surgical-procedure-report.v1
26. medzen-vital-signs-encounter.v1
```

### Official CKM Templates (official-templates/)

**Pros:**
- ✅ **Production-Ready** - Used in real healthcare systems worldwide
- ✅ **Community Maintained** - OpenEHR foundation support
- ✅ **Well-Tested** - Validated by multiple implementations
- ✅ **Standard Compliance** - Follows international standards (epSOS, FHIR, etc.)

**Cons:**
- ⏱️ **Same Conversion Time** - Still 6.5-10.8 hours manual work
- ⚠️ **Database Mismatch** - Template IDs don't match Supabase migrations
- ⚠️ **Generic Context** - Not tailored for Cameroon/African healthcare
- ⚠️ **Integration Work** - Would need to update:
  - Database migrations (template ID mappings)
  - Sync queue functions (template ID references)
  - Database triggers (template ID expectations)

**Templates List:**
```
1. AU COVID-19 Likelihood Assessment
2. COVID-19 Pneumonia Diagnosis and Treatment (7th edition)
3. Demo with hide-on-form
4. EAR Primary Hip Arthroplasty Report
5. EAR Revision Hip Arthroplasty Report
6. ePrescription (epSoS_Contsys)
7. ePrescription (FHIR)
8. epSOS Active Problems Section
9. epSOS Allergy and Other Adverse Reactions Section
10. epSOS History of Past Illness Section
11. epSOS Medication Summary Section
12. epSOS Vital Signs Observations
13. eReferral
14. Examination archetypes
15. GECCO core
16. Generic lab test result example simple
17. Heart Failure Clinic First Visit Summary
18. International Patient Summary
19. Molecular Pathology Report
20. openEHR confirmed COVID-19 infection report
21. openEHR suspected COVID-19 risk assessment
22. SARS event notification
23. Slovenia RES Primary Hip Arthroplasty Report
24. Slovenia RES Revision Hip Arthroplasty Report
25. TREAT Registry report
26. Vital signs
```

## Database Integration Impact

### Current Supabase Migrations Expect MedZen Template IDs

From `supabase/migrations/`:

```sql
-- Example from admission_discharge_records table trigger
CREATE TRIGGER queue_admission_discharge_sync
AFTER INSERT OR UPDATE ON admission_discharge_records
FOR EACH ROW EXECUTE FUNCTION queue_ehrbase_sync('medzen.admission_discharge_summary.v1');

-- Example from vital_signs table trigger
CREATE TRIGGER queue_vital_signs_sync
AFTER INSERT OR UPDATE ON vital_signs
FOR EACH ROW EXECUTE FUNCTION queue_ehrbase_sync('ehrbase.vital_signs.v1');
```

**19 specialty tables** all have triggers expecting `medzen.*` template IDs.

### If Using Official Templates

Would need to:
1. **Update all database triggers** - Change template IDs from `medzen.*` to standard IDs
2. **Update sync queue function** - Handle different template ID patterns
3. **Test all specialty table integrations** - Ensure data mappings still work
4. **Update FlutterFlow app logic** - Any hardcoded template ID references

**Estimated Additional Work:** 4-8 hours of database migration work + testing

## Hybrid Approach (Recommended?)

**Use Official Templates Where Available, MedZen Custom Where Needed:**

| Domain | Official Template Available? | Recommendation |
|--------|----------------------------|----------------|
| **Vital Signs** | ✅ "Vital signs.oet" | Use official |
| **Prescriptions** | ✅ "ePrescription" templates | Use official |
| **Lab Results** | ✅ "Generic lab test result" | Use official |
| **Allergies** | ✅ "epSOS Allergy and Adverse Reactions" | Use official |
| **Patient Demographics** | ✅ "International Patient Summary" | Use official |
| **Cardiology** | ❌ No match | Use MedZen custom |
| **Oncology** | ❌ No match | Use MedZen custom |
| **Psychiatry** | ❌ No match | Use MedZen custom |
| **Antenatal Care** | ❌ No match | Use MedZen custom |
| **Emergency Medicine** | ❌ No match | Use MedZen custom |

**Result:** ~5-7 official templates + ~15-20 MedZen custom templates

## Recommendation Matrix

### Choose MedZen Custom If:
- ✅ You want **minimal database changes**
- ✅ You need **African healthcare context** (Cameroon, French language)
- ✅ You require **exact specialty coverage** (19 specialties)
- ✅ You can **maintain custom templates** long-term
- ✅ You want **fastest integration** (templates already match DB)

### Choose Official CKM If:
- ✅ You prioritize **community maintenance**
- ✅ You're willing to **update database migrations**
- ✅ You want **international standard compliance**
- ✅ You can **invest 4-8 hours in migration work**
- ✅ You prefer **proven, tested templates**

### Choose Hybrid If:
- ✅ You want **best of both worlds**
- ✅ You can **manage mixed template sources**
- ✅ You're willing to do **selective DB updates**
- ✅ You have **time for careful integration**

## My Analysis

**CRITICAL FINDING:** Your Supabase database migrations are already configured with `medzen.*` template IDs in 19+ database triggers.

**Implication:** Using official CKM templates would require significant rework:
- Update 19+ database triggers
- Update sync queue function
- Update edge function template ID mappings
- Extensive testing of all specialty integrations

**Time Cost Comparison:**

| Approach | Conversion Time | DB Migration | Testing | Total |
|----------|----------------|--------------|---------|-------|
| **MedZen Custom** | 6.5-10.8 hrs | 0 hrs | 1-2 hrs | 7.5-12.8 hrs |
| **Official CKM** | 6.5-10.8 hrs | 4-8 hrs | 2-4 hrs | 12.5-22.8 hrs |
| **Hybrid (5+20)** | 6.5-10.8 hrs | 2-4 hrs | 2-3 hrs | 10.5-17.8 hrs |

## Recommended Decision

**Use MedZen Custom Templates** because:

1. ✅ **Already Integrated** - Database triggers reference `medzen.*` template IDs
2. ✅ **Faster Deployment** - No database migration work needed
3. ✅ **African Context** - Territory and language support built-in
4. ✅ **Specialty Coverage** - All 19 specialties already modeled
5. ✅ **Lower Risk** - No need to touch working database migrations

**When to Use Official:** For new features not yet in database, prefer official templates (e.g., COVID-19 reporting, international patient summary).

## Next Steps Based on Decision

### If Choosing MedZen Custom:
```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu
./ehrbase-templates/convert_templates_helper.sh
# Continue with ADL → OPT conversion (6.5-10.8 hrs)
```

### If Choosing Official CKM:
```bash
cd /Users/alainbagmi/Desktop/medzen-iwani-t1nrnu
./ehrbase-templates/convert_official_templates.sh
# Then update database migrations (4-8 hrs)
```

### If Choosing Hybrid:
1. Identify which official templates to use
2. Update relevant database triggers for those templates
3. Convert both sets of templates
4. Test integration thoroughly

## Questions to Consider

1. **Who will maintain the templates?** If limited resources, official templates reduce burden.
2. **How important is African healthcare context?** If critical, MedZen custom is better.
3. **Is international interoperability required?** If yes, lean towards official.
4. **How much time do you have?** MedZen custom is faster to deploy.
5. **Do you have DB migration expertise?** If not, MedZen custom is safer.

---

**Your Call:** Which approach do you want to take?
