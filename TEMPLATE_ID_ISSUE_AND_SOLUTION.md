# Template ID Issue and Solution

**Date**: 2025-12-16
**Status**: ✅ Solution Implemented (Temporary Workaround)

---

## Executive Summary

**Issue**: Custom MedZen OpenEHR template IDs (like `medzen.patient.demographics.v1`) don't exist in EHRbase, causing sync queue failures when creating medical record compositions.

**Root Cause**: Templates exist in ADL format but haven't been converted to OPT format and uploaded to EHRbase.

**Current Solution**: Template ID mapping in `supabase/functions/sync-to-ehrbase/index.ts` that maps custom IDs → generic templates.

**Long-term Solution**: Convert all 26 ADL templates to OPT format and upload to EHRbase.

---

## The Problem

### Where It Happens

The issue occurs **AFTER** user creation, when medical records (compositions) are synced to EHRbase:

```
User Created → EHR Created ✅ (Works fine)
    ↓
Medical Record Created (e.g., vital_signs)
    ↓
Sync Queue Triggered
    ↓
sync-to-ehrbase Function → Creates OpenEHR Composition
    ↓
❌ ERROR: "Could not retrieve template for template Id: medzen.patient.demographics.v1"
```

### What's NOT Affected

✅ **User creation works perfectly**:
- Firebase Auth user created ✅
- Supabase Auth user created ✅
- Supabase users table record created ✅
- EHRbase EHR created ✅ (EHR creation doesn't require template)
- electronic_health_records entry created ✅

The `onUserCreated` Firebase Cloud Function creates the EHR without specifying a template ID. **This always succeeds.**

### What IS Affected

❌ **Medical record synchronization** (after user creation):
- Creating compositions in EHRbase for:
  - User profile updates (demographics, provider profiles, etc.)
  - Vital signs, lab results, prescriptions
  - Clinical consultations, surgical procedures
  - All 19+ specialty medical tables

---

## Current Workaround (Implemented)

### Template ID Mapping

Location: `supabase/functions/sync-to-ehrbase/index.ts:12-50`

```typescript
const TEMPLATE_ID_MAP: Record<string, string> = {
  // User Profile Templates → Generic Clinical Notes
  'medzen.patient.demographics.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.provider.profile.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.facility.profile.v1': 'RIPPLE - Clinical Notes.v1',
  'medzen.admin.profile.v1': 'RIPPLE - Clinical Notes.v1',

  // Medical Data Templates → Generic Templates
  'medzen.vital_signs_encounter.v1': 'IDCR - Vital Signs Encounter.v1',
  'medzen.laboratory_result_report.v1': 'IDCR - Laboratory Test Report.v0',
  'medzen.medication_list.v1': 'IDCR - Medication Statement List.v0',

  // ... 20+ more mappings
}

function getMappedTemplateId(templateId: string): string {
  const mappedId = TEMPLATE_ID_MAP[templateId] || templateId
  if (mappedId !== templateId) {
    console.log(`Template ID mapped: ${templateId} → ${mappedId}`)
  }
  return mappedId
}
```

### How It Works

1. App/database specifies custom template ID: `medzen.vital_signs_encounter.v1`
2. Sync function maps it to generic template: `IDCR - Vital Signs Encounter.v1`
3. Generic template exists in EHRbase ✅
4. Composition created successfully ✅

### Limitations

⚠️ **Data Structure Mismatch**:
- Generic templates have different field structures than MedZen templates
- Some MedZen-specific fields may not map correctly
- Data may be stored in generic "notes" fields rather than structured fields

⚠️ **Reduced Data Quality**:
- Loss of MedZen-specific data validation
- Less structured data for queries and analytics
- May need data transformation when reading back

---

## Long-term Solution

### Upload Custom Templates to EHRbase

**Goal**: Replace template ID mapping with actual MedZen templates in EHRbase.

**Location**: `ehrbase-templates/` directory

**Current Status**:
- ✅ 26 ADL templates created (`ehrbase-templates/proper-templates/*.adl`)
- ⏳ 0 OPT templates converted
- ⏳ 0 templates uploaded to EHRbase

### Conversion Process

#### Option 1: Manual Conversion (6-13 hours)

1. **Open OpenEHR Template Designer**: https://tools.openehr.org/designer/
2. **For each ADL template**:
   - Import ADL file
   - Export as OPT (Operational Template)
   - Save to `ehrbase-templates/opt-templates/`
3. **Repeat for all 26 templates**

#### Option 2: Automated Conversion (Recommended, 1-2 hours)

Use OpenEHR SDK or template conversion tools:

```bash
# Install archetype-designer CLI (if available)
npm install -g openehr-archetype-designer

# Convert all ADL templates to OPT
cd ehrbase-templates/proper-templates
for file in *.adl; do
  archetype-designer convert "$file" -o "../opt-templates/${file%.adl}.opt"
done
```

**Note**: Automated conversion tools availability varies. May need to build custom converter using OpenEHR Java SDK.

### Upload Templates to EHRbase

Once converted to OPT format:

```bash
cd ehrbase-templates
chmod +x upload_all_templates.sh
./upload_all_templates.sh
```

The script will:
1. Upload each OPT template to EHRbase via REST API
2. Verify upload success
3. Generate summary report

### Verify Upload

```bash
chmod +x ehrbase-templates/verify_templates.sh
./ehrbase-templates/verify_templates.sh
```

Expected output:
```
✅ medzen.patient.demographics.v1 (uploaded)
✅ medzen.provider.profile.v1 (uploaded)
✅ medzen.vital_signs_encounter.v1 (uploaded)
... (all 26 templates)
```

### Remove Template ID Mapping

After all templates are uploaded, remove the mapping from sync function:

**File**: `supabase/functions/sync-to-ehrbase/index.ts`

**Change**:
```typescript
// OLD (temporary workaround)
const mappedTemplateId = getMappedTemplateId(templateId)

// NEW (after templates uploaded)
// Use template IDs directly - no mapping needed
const mappedTemplateId = templateId
```

**Deploy**:
```bash
npx supabase functions deploy sync-to-ehrbase
```

---

## Testing After Template Upload

### Test 1: Create User and Medical Record

```bash
node test_user_creation_complete.js --email newtest@example.com --password Test123!
```

Expected:
- ✅ User created in all systems
- ✅ EHR created
- No errors in Firebase Functions logs

### Test 2: Create Medical Record

Use app to create:
- Vital signs record
- Lab result
- Prescription

Expected:
- ✅ Records appear in Supabase tables
- ✅ ehrbase_sync_queue entries show `sync_status='completed'`
- ✅ compositions created in EHRbase with custom template IDs
- ✅ No "Could not retrieve template" errors

### Test 3: Verify Sync Queue

```sql
-- Check recent sync queue entries
SELECT
  id,
  table_name,
  template_id,
  sync_status,
  error_message
FROM ehrbase_sync_queue
WHERE created_at > NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 20;
```

Expected:
- `sync_status = 'completed'` for all entries
- `error_message IS NULL`
- `template_id` shows MedZen custom IDs (not generic)

---

## Migration Timeline

### Phase 1: Current State (Completed)
- ✅ Template ID mapping implemented
- ✅ Sync queue operational with generic templates
- ✅ User creation working end-to-end
- ✅ Medical records sync (with generic templates)

### Phase 2: Template Conversion (1-2 hours)
- ⏳ Convert 26 ADL templates → OPT format
- ⏳ Test OPT templates locally
- ⏳ Validate template structure

### Phase 3: Template Upload (30 minutes)
- ⏳ Upload all OPT templates to EHRbase
- ⏳ Verify templates accessible via REST API
- ⏳ Test composition creation with custom templates

### Phase 4: Production Cutover (15 minutes)
- ⏳ Remove template ID mapping code
- ⏳ Deploy updated sync function
- ⏳ Monitor sync queue for 24 hours

### Phase 5: Validation (1 hour)
- ⏳ End-to-end testing of all medical record types
- ⏳ Verify data structure matches expectations
- ⏳ Confirm no sync failures

**Total Estimated Time**: 4-5 hours (including testing)

---

## Cost-Benefit Analysis

### Keeping Current Workaround

**Pros**:
- ✅ Works immediately
- ✅ No conversion effort required
- ✅ Uses proven generic templates

**Cons**:
- ❌ Data structure mismatch
- ❌ Reduced data quality
- ❌ Less structured queries
- ❌ Difficult to add MedZen-specific fields
- ❌ Not compliant with MedZen data model

### Uploading Custom Templates

**Pros**:
- ✅ Perfect data structure match
- ✅ High data quality
- ✅ Structured queries
- ✅ Easy to extend with new fields
- ✅ Compliant with MedZen data model
- ✅ Better analytics and reporting

**Cons**:
- ❌ Requires 4-5 hours effort
- ❌ One-time conversion work
- ❌ Need to maintain templates going forward

**Recommendation**: Upload custom templates (benefits far outweigh costs).

---

## Related Documentation

- **Template Status**: `ehrbase-templates/TEMPLATE_CONVERSION_STATUS.md`
- **Sync Queue Status**: `SYNC_QUEUE_STATUS.md`
- **Template Mapping**: `ehrbase-templates/TEMPLATE_MAPPING_IMPLEMENTATION.md`
- **Upload Guide**: `ehrbase-templates/README.md`
- **System Overview**: `CLAUDE.md`

---

## Quick Reference

### Check Template in EHRbase

```bash
curl -s -X GET \
  "https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4/medzen.patient.demographics.v1" \
  -u "ehrbase-admin:YourPassword" | jq '.'
```

Expected:
- **404**: Template not found (need to upload)
- **200**: Template exists ✅

### List All Templates in EHRbase

```bash
curl -s -X GET \
  "https://ehr.medzenhealth.app/ehrbase/rest/openehr/v1/definition/template/adl1.4" \
  -H "Accept: application/json" \
  -u "ehrbase-admin:YourPassword" | jq '.templates[].template_id'
```

### Check Sync Queue Status

```sql
SELECT
  sync_status,
  COUNT(*) as count
FROM ehrbase_sync_queue
GROUP BY sync_status;
```

Expected:
- `pending: 0`
- `processing: 0`
- `failed: 0` (if > 0, check error_message)
- `completed: N` (all successful syncs)

---

**Document Version**: 1.0
**Last Updated**: 2025-12-16
**Status**: Workaround active, long-term solution pending
