# Specialty Medical Tables Testing Guide

Comprehensive testing documentation for the 19 specialty medical tables integration.

## 📋 Table of Contents

- [Overview](#overview)
- [Automated Test Suite](#automated-test-suite)
- [Manual Testing Procedures](#manual-testing-procedures)
- [Test Categories](#test-categories)
- [Validation Checklist](#validation-checklist)
- [Troubleshooting Test Failures](#troubleshooting-test-failures)

---

## Overview

The specialty medical tables system includes **19 new tables** covering comprehensive medical specialties:

**Maternal & Surgical Care:**
- antenatal_visits
- surgical_procedures
- admission_discharge_records

**Pharmacy:**
- medication_dispensing
- pharmacy_stock

**Clinical Services:**
- clinical_consultations

**Specialty Care (13 tables):**
- oncology_treatments
- infectious_disease_visits
- cardiology_visits
- emergency_visits
- nephrology_visits
- gastroenterology_procedures
- endocrinology_visits
- pulmonology_visits
- psychiatric_assessments
- neurology_exams

**Diagnostics:**
- radiology_reports
- pathology_reports

**Rehabilitation:**
- physiotherapy_sessions

---

## Automated Test Suite

### test_specialty_tables.sh

**Purpose:** Automated validation of all 19 specialty tables across database, PowerSync, Dart models, and integration components.

**Usage:**
```bash
./test_specialty_tables.sh
```

**Test Coverage:**

1. **Migration Files (Suite 1)**
   - Verifies 4 migration files exist
   - Confirms all 19 tables defined in migrations
   - Validates migration file naming convention

2. **PowerSync Schema (Suite 2)**
   - Checks PowerSync schema file exists
   - Verifies all 19 tables in schema definition
   - Validates table name consistency

3. **Dart Models (Suite 3)**
   - Confirms all 19 model files exist
   - Validates SupabaseTable/SupabaseDataRow structure
   - Checks for EHRbase sync fields in each model

4. **Database Exports (Suite 4)**
   - Verifies database.dart exists
   - Confirms all 19 tables exported
   - Validates export syntax

5. **PowerSync Sync Rules (Suite 5)**
   - Checks POWERSYNC_SYNC_RULES.yaml exists
   - Verifies bucket_definitions section
   - Counts specialty table references

6. **Edge Function (Suite 6)**
   - Confirms sync-to-ehrbase function exists
   - Checks for TEMPLATE_MAPPINGS
   - Counts specialty table mappings

7. **File Structure (Suite 7)**
   - Validates EHRbase sync fields:
     - composition_id
     - ehrbase_synced
     - ehrbase_synced_at
     - ehrbase_sync_error
     - ehrbase_retry_count
   - Checks timestamp fields (created_at/updated_at)

8. **Integration (Suite 8)**
   - Tests Supabase CLI connection
   - Runs flutter pub get
   - Executes flutter analyze on models

**Expected Output:**

```
╔═══════════════════════════════════════════════════════════╗
║   🧪 Specialty Medical Tables Test Suite                 ║
║   Testing 19 Specialty Tables Integration                ║
╚═══════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Test Suite 1: Database Migration Files
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ PASS: Migration file exists: 20250202120009_...
✅ PASS: Migration file exists: 20250202120010_...
...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📈 Final Test Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total Tests Run: 87
Passed: 87
Failed: 0
Warnings: 0

✅ ALL TESTS PASSED! (100.0% success rate)

🎉 The 19 specialty medical tables are properly integrated!

Next steps:
  1. Deploy to production: ./deploy_specialty_tables.sh
  2. Test user signup/login flows
  3. Create sample medical records for each specialty
  4. Verify EHRbase sync queue processing
```

**Exit Codes:**
- `0` - All tests passed
- `1` - One or more tests failed

**Integration with CI/CD:**
```yaml
# Example GitHub Actions workflow
- name: Test Specialty Tables
  run: ./test_specialty_tables.sh
```

---

## Manual Testing Procedures

### 1. Database Schema Validation

**Test Migration Application:**
```bash
# Reset local database
npx supabase db reset

# Verify all tables created
npx supabase db diff --schema public
```

**Expected:** All 19 tables exist with correct columns and constraints.

**Verify Tables via psql:**
```sql
-- Count specialty tables
SELECT COUNT(*)
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
  'antenatal_visits',
  'surgical_procedures',
  'admission_discharge_records',
  'medication_dispensing',
  'pharmacy_stock',
  'clinical_consultations',
  'oncology_treatments',
  'infectious_disease_visits',
  'cardiology_visits',
  'emergency_visits',
  'nephrology_visits',
  'gastroenterology_procedures',
  'endocrinology_visits',
  'pulmonology_visits',
  'psychiatric_assessments',
  'neurology_exams',
  'radiology_reports',
  'pathology_reports',
  'physiotherapy_sessions'
);
-- Should return: 19

-- Check RLS policies
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('antenatal_visits', 'surgical_procedures', 'cardiology_visits')
ORDER BY tablename, policyname;

-- Verify triggers
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND event_object_table LIKE '%_visits' OR event_object_table LIKE '%_reports'
ORDER BY event_object_table;
```

### 2. PowerSync Configuration Validation

**Check Schema File:**
```bash
# Count table definitions
grep -c "name: '" lib/powersync/schema.dart

# List all specialty tables in schema
grep "name: '" lib/powersync/schema.dart | grep -E "(antenatal|surgical|cardiology|neurology|radiology|pathology|physiotherapy)"
```

**Expected:** All 19 tables appear in PowerSync schema with correct column definitions.

**Test Sync Rules:**
```bash
# Verify sync rules file
cat POWERSYNC_SYNC_RULES.yaml | grep -A 20 "bucket_definitions:"

# Check for specialty tables
for table in antenatal_visits cardiology_visits radiology_reports; do
  echo "Checking $table..."
  grep -c "$table" POWERSYNC_SYNC_RULES.yaml
done
```

### 3. Dart Model Validation

**Check Model Generation:**
```bash
# Count model files
ls -1 lib/backend/supabase/database/tables/*.dart | wc -l

# Verify specific models exist
for table in antenatal_visits surgical_procedures cardiology_visits neurology_exams radiology_reports pathology_reports physiotherapy_sessions; do
  if [ -f "lib/backend/supabase/database/tables/${table}.dart" ]; then
    echo "✅ $table.dart exists"
  else
    echo "❌ $table.dart missing"
  fi
done
```

**Validate Model Structure:**
```bash
# Check a sample model
cat lib/backend/supabase/database/tables/cardiology_visits.dart | grep -E "(class|extends|getField|setField)"
```

**Flutter Analyzer Check:**
```bash
# Analyze specific models
flutter analyze lib/backend/supabase/database/tables/antenatal_visits.dart
flutter analyze lib/backend/supabase/database/tables/cardiology_visits.dart
flutter analyze lib/backend/supabase/database/tables/radiology_reports.dart
```

### 4. Integration Testing

**Test PowerSync Initialization:**
```dart
// Add to a test page or debug action
import 'package:medzen_iwani/powersync/database.dart';

Future<void> testPowerSyncIntegration() async {
  // Check if PowerSync is initialized
  final status = getPowerSyncStatus();
  print('PowerSync connected: ${status.connected}');
  print('PowerSync downloading: ${status.downloading}');

  // Verify tables exist in local DB
  final tables = [
    'antenatal_visits',
    'cardiology_visits',
    'radiology_reports',
    'pathology_reports'
  ];

  for (final table in tables) {
    try {
      final count = await db.execute(
        'SELECT COUNT(*) as count FROM $table'
      );
      print('$table: ${count.first['count']} records');
    } catch (e) {
      print('❌ Error accessing $table: $e');
    }
  }
}
```

**Test Edge Function:**
```bash
# Test edge function locally
npx supabase functions serve sync-to-ehrbase

# In another terminal, test invoke
curl -i --location --request POST 'http://localhost:54321/functions/v1/sync-to-ehrbase' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"test": true}'
```

### 5. CRUD Operations Test

**Test Data Creation:**
```dart
// Create sample record for each specialty
import 'package:medzen_iwani/powersync/database.dart';

Future<void> testCRUDOperations() async {
  final patientId = 'test-patient-uuid';
  final providerId = 'test-provider-uuid';
  final facilityId = 'test-facility-uuid';

  // Test 1: Antenatal visit
  await db.execute('''
    INSERT INTO antenatal_visits (
      patient_id, provider_id, facility_id, visit_date, gestational_age_weeks
    ) VALUES (?, ?, ?, ?, ?)
  ''', [patientId, providerId, facilityId, DateTime.now().toIso8601String(), 12]);

  // Test 2: Cardiology visit
  await db.execute('''
    INSERT INTO cardiology_visits (
      patient_id, cardiologist_id, facility_id, visit_date, heart_rate_bpm, blood_pressure_systolic
    ) VALUES (?, ?, ?, ?, ?, ?)
  ''', [patientId, providerId, facilityId, DateTime.now().toIso8601String(), 72, 120]);

  // Test 3: Radiology report
  await db.execute('''
    INSERT INTO radiology_reports (
      patient_id, radiologist_id, facility_id, exam_date, modality, body_part
    ) VALUES (?, ?, ?, ?, ?, ?)
  ''', [patientId, providerId, facilityId, DateTime.now().toIso8601String(), 'X-Ray', 'Chest']);

  print('✅ Sample records created successfully');

  // Verify records exist
  final antenatalCount = await db.execute('SELECT COUNT(*) as count FROM antenatal_visits WHERE patient_id = ?', [patientId]);
  final cardiologyCount = await db.execute('SELECT COUNT(*) as count FROM cardiology_visits WHERE patient_id = ?', [patientId]);
  final radiologyCount = await db.execute('SELECT COUNT(*) as count FROM radiology_reports WHERE patient_id = ?', [patientId]);

  print('Antenatal visits: ${antenatalCount.first['count']}');
  print('Cardiology visits: ${cardiologyCount.first['count']}');
  print('Radiology reports: ${radiologyCount.first['count']}');
}
```

---

## Test Categories

### Category 1: Static File Tests
**What:** Verify files exist and contain required content
**Tools:** Shell scripts, grep, file system checks
**When:** After code changes, before deployment

### Category 2: Schema Validation
**What:** Validate database schema matches specifications
**Tools:** Supabase CLI, SQL queries
**When:** After migrations, during testing

### Category 3: Model Integration
**What:** Test Dart models compile and work correctly
**Tools:** Flutter analyzer, Dart VM
**When:** After model changes, before deployment

### Category 4: Sync Testing
**What:** Verify PowerSync and EHRbase synchronization
**Tools:** PowerSync Dashboard, edge function logs
**When:** After deployment, during live testing

### Category 5: End-to-End Testing
**What:** Full user workflow testing
**Tools:** Flutter app, manual testing
**When:** Before production release

---

## Validation Checklist

Use this checklist before deploying to production:

### Pre-Deployment Checklist

- [ ] All 4 migration files exist and are numbered correctly
- [ ] PowerSync schema includes all 19 tables
- [ ] All 19 Dart model files exist
- [ ] All models exported in database.dart
- [ ] Sync rules include specialty tables
- [ ] Edge function has template mappings
- [ ] `./test_specialty_tables.sh` passes with 0 failures
- [ ] `./verify_consistency.sh` passes all checks
- [ ] `flutter pub get` runs without errors
- [ ] `flutter analyze` finds no critical issues

### Post-Deployment Checklist

- [ ] All 19 tables exist in production database
- [ ] RLS policies applied to all tables
- [ ] Triggers created for updated_at timestamps
- [ ] PowerSync Dashboard shows all tables syncing
- [ ] Edge function deployed successfully
- [ ] Test user can create records in each specialty
- [ ] EHRbase sync queue processes records
- [ ] PowerSync sync status shows "connected"
- [ ] No errors in edge function logs
- [ ] Sample medical records sync to EHRbase

### Specialty-Specific Testing

Test at least one record for each specialty:

- [ ] Antenatal visit created and synced
- [ ] Surgical procedure created and synced
- [ ] Admission/discharge record created and synced
- [ ] Medication dispensing record created and synced
- [ ] Pharmacy stock record created and synced
- [ ] Clinical consultation created and synced
- [ ] Oncology treatment created and synced
- [ ] Infectious disease visit created and synced
- [ ] Cardiology visit created and synced
- [ ] Emergency visit created and synced
- [ ] Nephrology visit created and synced
- [ ] Gastroenterology procedure created and synced
- [ ] Endocrinology visit created and synced
- [ ] Pulmonology visit created and synced
- [ ] Psychiatric assessment created and synced
- [ ] Neurology exam created and synced
- [ ] Radiology report created and synced
- [ ] Pathology report created and synced
- [ ] Physiotherapy session created and synced

---

## Troubleshooting Test Failures

### Test Failure: Migration file missing

**Symptom:**
```
❌ FAIL: Migration file missing: 20250202120009_create_antenatal_surgical_admission_medication_pharmacy_consultation_tables.sql
```

**Solution:**
1. Check `supabase/migrations/` directory
2. Verify migration file exists with exact name
3. If missing, restore from backup or regenerate
4. Check file permissions: `chmod 644 supabase/migrations/*.sql`

### Test Failure: Table missing from PowerSync schema

**Symptom:**
```
❌ FAIL: Table missing from PowerSync schema: cardiology_visits
```

**Solution:**
1. Open `lib/powersync/schema.dart`
2. Add table definition to `tables` array:
```dart
Table(
  name: 'cardiology_visits',
  columns: [
    Column.text('id'),
    // ... add all columns
  ]
)
```
3. Re-run tests

### Test Failure: Model file missing or invalid

**Symptom:**
```
❌ FAIL: Model file missing: radiology_reports.dart
```

**Solution:**
```bash
# Regenerate model
./generate_model.sh radiology_reports RadiologyReports

# Edit generated file to add fields
# Then add export to database.dart
```

### Test Failure: Export missing from database.dart

**Symptom:**
```
❌ FAIL: Export missing: pathology_reports.dart
```

**Solution:**
1. Open `lib/backend/supabase/database/database.dart`
2. Add export line:
```dart
export 'tables/pathology_reports.dart';
```
3. Save and re-run tests

### Test Failure: Flutter pub get failed

**Symptom:**
```
❌ FAIL: flutter pub get failed - check dependencies
```

**Solution:**
```bash
# Clean Flutter cache
flutter clean

# Remove generated files
rm -rf .dart_tool/
rm pubspec.lock

# Re-fetch dependencies
flutter pub get

# Verify pubspec.yaml has required packages
```

### Test Failure: Edge function deployment

**Symptom:**
```
❌ FAIL: Edge function deployment failed
```

**Solution:**
```bash
# Check Supabase connection
npx supabase status

# Check edge function syntax
cd supabase/functions/sync-to-ehrbase
npx tsc --noEmit

# Redeploy
npx supabase functions deploy sync-to-ehrbase

# Check logs
npx supabase functions logs sync-to-ehrbase
```

### Warning: EHRbase sync fields may be missing

**Symptom:**
```
⚠️  WARN: EHRbase sync fields may be missing: neurology_exams.dart
```

**Solution:**
1. Open the model file
2. Verify these fields exist:
```dart
String? get compositionId => getField<String>('composition_id');
set compositionId(String? value) => setField<String>('composition_id', value);

bool? get ehrbaseSynced => getField<bool>('ehrbase_synced');
set ehrbaseSynced(bool? value) => setField<bool>('ehrbase_synced', value);

DateTime? get ehrbaseSyncedAt => getField<DateTime>('ehrbase_synced_at');
set ehrbaseSyncedAt(DateTime? value) => setField<DateTime>('ehrbase_synced_at', value);

String? get ehrbaseSyncError => getField<String>('ehrbase_sync_error');
set ehrbaseSyncError(String? value) => setField<String>('ehrbase_sync_error', value);

int? get ehrbaseRetryCount => getField<int>('ehrbase_retry_count');
set ehrbaseRetryCount(int? value) => setField<int>('ehrbase_retry_count', value);
```
3. Save and re-run tests

---

## Additional Testing Resources

**Related Documentation:**
- `TESTING_GUIDE.md` - General testing guide
- `SYSTEM_INTEGRATION_STATUS.md` - Integration status
- `HELPER_SCRIPTS_GUIDE.md` - Helper scripts documentation
- `CLAUDE.md` - Project architecture

**Test Scripts:**
- `test_specialty_tables.sh` - This test suite
- `verify_consistency.sh` - Consistency verification
- `test_system_connections.sh` - System integration tests
- `test_auth_flow.sh` - Authentication flow tests

**PowerSync Testing:**
- PowerSync Dashboard: https://powersync.journeyapps.com
- Monitor sync status in real-time
- View bucket statistics
- Check sync errors

**Supabase Testing:**
- Supabase Studio: Check tables, data, logs
- Edge function logs: `npx supabase functions logs sync-to-ehrbase`
- Database logs: Supabase Studio → Logs

---

**Last Updated:** 2025-02-02
**Version:** 1.0.0
**Test Coverage:** 8 suites, ~87 tests
**Maintainer:** Claude Code Assistant
