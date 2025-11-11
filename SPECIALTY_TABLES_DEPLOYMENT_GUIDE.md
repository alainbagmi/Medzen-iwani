# Specialty Medical Tables Deployment Guide

Complete step-by-step deployment guide for the 19 specialty medical tables system.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Pre-Deployment Checklist](#pre-deployment-checklist)
- [Automated Deployment](#automated-deployment)
- [Manual Deployment Steps](#manual-deployment-steps)
- [PowerSync Dashboard Configuration](#powersync-dashboard-configuration)
- [Post-Deployment Verification](#post-deployment-verification)
- [Rollback Procedures](#rollback-procedures)
- [Troubleshooting](#troubleshooting)

---

## Overview

This deployment adds **19 specialty medical tables** to the MedZen system:

### Tables Being Deployed

**Maternal & Surgical (3 tables):**
- antenatal_visits
- surgical_procedures
- admission_discharge_records

**Pharmacy (2 tables):**
- medication_dispensing
- pharmacy_stock

**Clinical (1 table):**
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
- radiology_reports
- pathology_reports
- physiotherapy_sessions

### Components Being Deployed

1. **Database Migrations** (4 files)
   - Table schemas with constraints
   - Indexes for performance
   - RLS policies for security
   - Triggers for automation

2. **PowerSync Schema**
   - Table definitions for local sync
   - Column mappings
   - Index configurations

3. **PowerSync Sync Rules**
   - Bucket definitions for 4 user roles
   - Data filtering logic
   - Role-based access control

4. **Edge Function**
   - OpenEHR template mappings
   - EHRbase sync logic
   - Retry mechanisms

5. **Dart Models** (19 files)
   - Type-safe data access
   - Field getters/setters
   - Database integration

---

## Prerequisites

### Required Tools

Install and configure these tools before deployment:

**1. Supabase CLI**
```bash
# Install
npm install -g supabase

# Login
npx supabase login

# Link to project
npx supabase link --project-ref YOUR_PROJECT_REF
```

**2. Flutter SDK**
```bash
# Verify installation
flutter --version

# Should be >=3.0.0
```

**3. Node.js**
```bash
# Required for Firebase Functions (if applicable)
node --version

# Should be v20 or higher
```

**4. Git**
```bash
# Verify installation
git --version
```

### Required Credentials

Ensure you have access to:

- [ ] Supabase project admin access
- [ ] PowerSync Dashboard access (https://powersync.journeyapps.com)
- [ ] EHRbase admin credentials (if applicable)
- [ ] Firebase project access (for auth)

### Environment Setup

**1. Set Environment Variables**
```bash
# Add to your shell profile (~/.bashrc, ~/.zshrc, etc.)
export SUPABASE_PROJECT_REF="your-project-ref"
export POWERSYNC_INSTANCE_URL="your-instance-url"
```

**2. Verify Connections**
```bash
# Test Supabase connection
npx supabase projects list

# Test PowerSync connection
curl -I $POWERSYNC_INSTANCE_URL

# Test Flutter
flutter doctor
```

---

## Pre-Deployment Checklist

**Complete this checklist before proceeding with deployment:**

### Code Validation

- [ ] All 19 Dart model files exist in `lib/backend/supabase/database/tables/`
- [ ] All models exported in `lib/backend/supabase/database/database.dart`
- [ ] PowerSync schema updated in `lib/powersync/schema.dart`
- [ ] Sync rules ready in `POWERSYNC_SYNC_RULES.yaml`
- [ ] Edge function updated in `supabase/functions/sync-to-ehrbase/`
- [ ] All 4 migration files exist in `supabase/migrations/`

**Verification Command:**
```bash
./verify_consistency.sh
```
Should show: ✅ All verification checks passed!

### Testing

- [ ] `./test_specialty_tables.sh` passes with 0 failures
- [ ] `flutter pub get` runs without errors
- [ ] `flutter analyze` shows no critical issues
- [ ] Local database migration succeeds: `npx supabase db reset`

### Backups

- [ ] Database backup created (automatic via deployment script)
- [ ] PowerSync sync rules backed up
- [ ] Current edge function version noted
- [ ] Git commit created with all changes

**Create Git Commit:**
```bash
git add .
git commit -m "feat: Add 19 specialty medical tables with PowerSync and EHRbase integration"
git push origin main
```

### Communication

- [ ] Stakeholders notified of deployment window
- [ ] Maintenance window scheduled (if required)
- [ ] Rollback plan reviewed and approved
- [ ] Post-deployment testing team ready

---

## Automated Deployment

### Option 1: Full Automated Deployment (Recommended)

**Use the automated deployment script for streamlined deployment:**

**1. Dry Run First (Required)**
```bash
./deploy_specialty_tables.sh --dry-run
```

Review the output carefully:
- Confirms what will be deployed
- Shows deployment steps
- No actual changes made

**2. Execute Deployment**
```bash
./deploy_specialty_tables.sh
```

The script will:
1. ✅ Run consistency verification
2. 📦 Create timestamped backup
3. 🗄️ Deploy database migrations
4. ⏸️ Prompt for PowerSync sync rules (manual step)
5. 🔧 Deploy edge function
6. 📱 Build Flutter application
7. 🧪 Run integration tests

**3. Follow PowerSync Prompt**

When you see:
```
PowerSync sync rules must be deployed manually via PowerSync Dashboard
Steps:
  1. Go to https://powersync.journeyapps.com
  2. Select your instance
  3. Navigate to Sync Rules
  4. Copy contents from POWERSYNC_SYNC_RULES.yaml
  5. Paste and deploy

Press Enter when PowerSync sync rules are deployed...
```

**Follow the steps in [PowerSync Dashboard Configuration](#powersync-dashboard-configuration) section below**, then press Enter to continue.

### Option 2: Step-by-Step Manual Control

**If you prefer manual control over each step, see [Manual Deployment Steps](#manual-deployment-steps).**

---

## Manual Deployment Steps

**For manual control over the deployment process:**

### Step 1: Create Backup

```bash
# Create backup directory
BACKUP_DIR="backups/manual_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup migrations
cp -r supabase/migrations "$BACKUP_DIR/"

# Backup PowerSync schema
cp lib/powersync/schema.dart "$BACKUP_DIR/"

# Backup database.dart
cp lib/backend/supabase/database/database.dart "$BACKUP_DIR/"

# Note backup location
echo "Backup created at: $BACKUP_DIR"
```

### Step 2: Deploy Database Migrations

```bash
# Ensure you're linked to the correct project
npx supabase projects list

# Deploy migrations
npx supabase db push

# Verify deployment
npx supabase db diff --schema public
```

**Expected Output:**
```
Applying migration 20250202120009_create_antenatal_surgical_admission_medication_pharmacy_consultation_tables.sql...
Applying migration 20250202120010_create_nephrology_gastro_endocrine_tables.sql...
Applying migration 20250202120011_create_pulmonology_psychiatry_neurology_tables.sql...
Applying migration 20250202120012_create_radiology_pathology_physiotherapy_tables.sql...
Finished npx supabase db push.
```

**Verify Tables Created:**
```bash
# Via Supabase Studio: Check Tables tab
# Or via psql:
npx supabase db remote connect

# In psql:
\dt public.*_visits;
\dt public.*_reports;
\dt public.*_procedures;
```

### Step 3: Deploy PowerSync Sync Rules

**This step MUST be done manually via PowerSync Dashboard.**

See [PowerSync Dashboard Configuration](#powersync-dashboard-configuration) section for detailed instructions.

### Step 4: Deploy Edge Function

```bash
# Deploy sync-to-ehrbase function
npx supabase functions deploy sync-to-ehrbase

# Verify deployment
npx supabase functions list
```

**Expected Output:**
```
┌────────────────────┬─────────────┬──────────────────────────────┐
│ NAME               │ VERSION     │ CREATED AT                    │
├────────────────────┼─────────────┼──────────────────────────────┤
│ sync-to-ehrbase    │ v2          │ 2025-02-02 15:30:00          │
│ powersync-token    │ v1          │ 2025-01-15 10:00:00          │
└────────────────────┴─────────────┴──────────────────────────────┘
```

**Test Edge Function:**
```bash
# Check logs for errors
npx supabase functions logs sync-to-ehrbase --tail

# Look for any deployment errors
```

### Step 5: Update Flutter Application

```bash
# Install dependencies
flutter pub get

# Run analyzer
flutter analyze

# Build for platforms (optional at this stage)
# flutter build apk        # Android
# flutter build ios        # iOS
# flutter build web        # Web
```

**Resolve Any Issues:**
- If `flutter pub get` fails: Check `pubspec.yaml` for dependency conflicts
- If `flutter analyze` fails: Review and fix reported issues before proceeding

### Step 6: Run Integration Tests

```bash
# Run specialty tables test suite
./test_specialty_tables.sh

# Run system connection tests
./test_system_connections.sh
```

**Expected:** All tests pass with 0 failures.

If tests fail, **DO NOT PROCEED** - troubleshoot and fix issues first.

---

## PowerSync Dashboard Configuration

**This is a MANUAL step that cannot be automated.**

### Accessing PowerSync Dashboard

1. **Navigate to Dashboard:**
   ```
   https://powersync.journeyapps.com
   ```

2. **Login** with your PowerSync credentials

3. **Select Your Instance:**
   - Click on your MedZen instance
   - Note the instance URL (should match `POWERSYNC_INSTANCE_URL`)

### Deploying Sync Rules

**Step 1: Open Sync Rules Editor**

1. In PowerSync Dashboard, click **"Sync Rules"** in the left sidebar
2. You'll see the current sync rules (if any)

**Step 2: Backup Current Rules (Important!)**

1. Click **"Download"** or copy current rules to a text file
2. Save as `POWERSYNC_SYNC_RULES_backup_$(date +%Y%m%d).yaml`
3. Store safely for rollback if needed

**Step 3: Open Local Sync Rules File**

```bash
# Open in your editor
cat POWERSYNC_SYNC_RULES.yaml
```

Or open in a text editor for easier copying.

**Step 4: Copy New Sync Rules**

1. Select ALL contents of `POWERSYNC_SYNC_RULES.yaml`
2. Copy to clipboard (Cmd+C or Ctrl+C)

**Step 5: Paste into PowerSync Dashboard**

1. In PowerSync Dashboard, **clear** the existing sync rules editor
2. **Paste** the new sync rules (Cmd+V or Ctrl+V)

**Step 6: Validate Sync Rules**

PowerSync will automatically validate the YAML syntax:

- ✅ **Green checkmark** = Valid syntax
- ❌ **Red error** = Syntax error - fix before deploying

Common validation errors:
- Indentation issues (use 2 spaces, not tabs)
- Missing colons
- Unmatched quotes
- Invalid SQL syntax in `SELECT` queries

**Step 7: Deploy Sync Rules**

1. Click **"Deploy"** button (usually top-right)
2. Confirm deployment in the modal dialog
3. Wait for deployment to complete (usually 5-10 seconds)

**Step 8: Verify Deployment**

Check the dashboard shows:
- **Status:** Active
- **Version:** Incremented (e.g., v2 if was v1)
- **Last Deployed:** Current timestamp

**Step 9: Monitor Initial Sync**

1. Navigate to **"Monitor"** or **"Dashboard"** tab
2. Watch for sync activity:
   - Bucket definitions should show all 19 specialty tables
   - Active connections should start syncing data
   - Check for any errors in the logs

**Expected Bucket Definitions:**

The dashboard should show buckets for each user role:
- `patient_data`
- `provider_data`
- `facility_admin_data`
- `system_admin_data`

Each bucket should include relevant specialty tables based on role.

### Troubleshooting PowerSync Deployment

**Error: "Invalid YAML syntax"**
- Check indentation (must be 2 spaces)
- Validate YAML online: https://www.yamllint.com/
- Compare with backup to see what changed

**Error: "Invalid SQL query"**
- Test SQL query in Supabase Studio → SQL Editor
- Check table names are correct (exact matches)
- Verify column references exist in database

**Error: "Bucket definition not found"**
- Ensure `bucket_definitions:` section exists
- Check each bucket has required fields: `bucket`, `select`, `where`
- Verify role parameters are correct

**Sync Not Starting:**
- Wait 1-2 minutes for rules to propagate
- Check PowerSync instance status
- Review error logs in Monitor tab
- Verify Supabase connection is healthy

---

## Post-Deployment Verification

**Complete these verification steps after deployment:**

### 1. Database Verification

```sql
-- Connect to database
-- Via Supabase Studio → SQL Editor or npx supabase db remote connect

-- Verify all 19 tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
  'antenatal_visits', 'surgical_procedures', 'admission_discharge_records',
  'medication_dispensing', 'pharmacy_stock', 'clinical_consultations',
  'oncology_treatments', 'infectious_disease_visits', 'cardiology_visits',
  'emergency_visits', 'nephrology_visits', 'gastroenterology_procedures',
  'endocrinology_visits', 'pulmonology_visits', 'psychiatric_assessments',
  'neurology_exams', 'radiology_reports', 'pathology_reports',
  'physiotherapy_sessions'
)
ORDER BY table_name;
-- Should return 19 rows

-- Verify RLS policies exist
SELECT tablename, COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
AND tablename LIKE '%_visits' OR tablename LIKE '%_reports' OR tablename LIKE '%_procedures'
GROUP BY tablename
ORDER BY tablename;
-- Each table should have 3-5 policies

-- Verify triggers exist
SELECT event_object_table, trigger_name
FROM information_schema.triggers
WHERE trigger_schema = 'public'
AND (event_object_table LIKE '%_visits'
  OR event_object_table LIKE '%_reports'
  OR event_object_table LIKE '%_procedures'
  OR event_object_table = 'medication_dispensing'
  OR event_object_table = 'pharmacy_stock')
ORDER BY event_object_table;
-- Should see ehrbase triggers and updated_at triggers
```

### 2. PowerSync Verification

**Via PowerSync Dashboard:**

1. **Check Sync Status:**
   - Navigate to Monitor/Dashboard
   - Verify "Status: Active"
   - Check "Last Sync" timestamp is recent

2. **Verify Buckets:**
   - All 4 role buckets should be visible
   - Each bucket should list relevant specialty tables
   - Check bucket sizes (may be 0 if no data yet)

3. **Check Connections:**
   - Active connections > 0 (if users are online)
   - No connection errors in logs

4. **Review Logs:**
   - No sync errors
   - Successful bucket updates
   - No SQL query errors

**Via Flutter App:**

```dart
// Add debug action or test page
import 'package:medzen_iwani/powersync/database.dart';

Future<void> verifyPowerSyncDeployment() async {
  // Check connection status
  final status = getPowerSyncStatus();
  print('Connected: ${status.connected}');
  print('Downloading: ${status.downloading}');
  print('Uploading: ${status.uploading}');

  // Verify specialty tables exist locally
  final tables = [
    'antenatal_visits',
    'surgical_procedures',
    'cardiology_visits',
    'neurology_exams',
    'radiology_reports',
    'pathology_reports',
    'physiotherapy_sessions'
  ];

  for (final table in tables) {
    try {
      final result = await db.execute(
        'SELECT COUNT(*) as count FROM $table'
      );
      print('✅ $table: ${result.first['count']} records');
    } catch (e) {
      print('❌ Error with $table: $e');
    }
  }
}
```

### 3. Edge Function Verification

```bash
# Check function is deployed
npx supabase functions list

# View recent logs
npx supabase functions logs sync-to-ehrbase --tail

# Test function invocation (if test endpoint exists)
curl -i --location --request POST \
  'YOUR_SUPABASE_URL/functions/v1/sync-to-ehrbase' \
  --header 'Authorization: Bearer YOUR_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{"test": true}'
```

**Expected:** No errors in logs, function responds successfully.

### 4. Dart Models Verification

```bash
# Verify Flutter compiles
flutter analyze lib/backend/supabase/database/

# Check specific models
flutter analyze lib/backend/supabase/database/tables/cardiology_visits.dart
flutter analyze lib/backend/supabase/database/tables/radiology_reports.dart

# Try building app
flutter build apk --debug  # Or build for your target platform
```

### 5. End-to-End Test

**Create Sample Medical Records:**

1. **Login as Provider** in the app
2. **Create Test Records** for each specialty:

   **Antenatal Visit:**
   - Navigate to Antenatal Care
   - Create new visit for test patient
   - Add gestational age, blood pressure, fetal heart rate
   - Save and sync

   **Cardiology Visit:**
   - Navigate to Cardiology
   - Create new visit
   - Add heart rate, blood pressure, ECG findings
   - Save and sync

   **Radiology Report:**
   - Navigate to Radiology
   - Create new report
   - Add modality (X-ray), body part (Chest), findings
   - Save and sync

3. **Verify Records in Database:**

```sql
-- Check records exist
SELECT table_name,
       (SELECT COUNT(*) FROM information_schema.tables t WHERE t.table_name = tables.table_name) as count
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('antenatal_visits', 'cardiology_visits', 'radiology_reports')
ORDER BY table_name;
```

4. **Check EHRbase Sync Queue:**

```sql
-- View sync queue
SELECT
  table_name,
  sync_status,
  COUNT(*) as count
FROM ehrbase_sync_queue
WHERE table_name IN ('antenatal_visits', 'cardiology_visits', 'radiology_reports')
GROUP BY table_name, sync_status
ORDER BY table_name, sync_status;
```

**Expected:** Records appear in queue with `sync_status = 'pending'` or `'processing'`.

5. **Monitor EHRbase Sync:**

```bash
# Watch edge function logs
npx supabase functions logs sync-to-ehrbase --tail
```

Look for successful sync messages:
```
✅ Synced record_id to EHRbase composition_id
```

### Verification Checklist

Complete this final checklist:

- [ ] All 19 tables exist in Supabase database
- [ ] RLS policies applied to all tables
- [ ] Triggers exist for updated_at and ehrbase_sync_queue
- [ ] PowerSync Dashboard shows all buckets active
- [ ] PowerSync mobile clients can sync data
- [ ] Edge function deployed and responding
- [ ] Edge function logs show no errors
- [ ] Flutter app compiles without errors
- [ ] Can create medical records in each specialty
- [ ] Records appear in ehrbase_sync_queue
- [ ] EHRbase sync processes successfully
- [ ] No errors in application logs
- [ ] Mobile app syncs offline changes when reconnected

---

## Rollback Procedures

**If deployment fails or critical issues arise:**

### Step 1: Stop Ongoing Operations

```bash
# No active deployments to stop for Supabase
# PowerSync changes are immediate - proceed to rollback

# If users are experiencing issues, consider:
# - Maintenance mode message
# - Disabling affected features
```

### Step 2: Rollback Database

```bash
# Find your backup
ls -la backups/

# Identify backup directory (deployment script creates these automatically)
# Format: backups/YYYYMMDD_HHMMSS/

# Restore migrations
BACKUP_DIR="backups/20250202_153000"  # Use actual backup directory

# Remove new migrations
rm supabase/migrations/20250202120009_*.sql
rm supabase/migrations/20250202120010_*.sql
rm supabase/migrations/20250202120011_*.sql
rm supabase/migrations/20250202120012_*.sql

# Restore previous migrations (if any were modified)
cp -r $BACKUP_DIR/migrations/* supabase/migrations/

# Revert database
npx supabase db push --reset

# ⚠️ WARNING: --reset will DROP all data!
# If data preservation is required, manually DROP only new tables:
```

**Manual Table Cleanup (Data Preservation):**

```sql
-- Connect to database
npx supabase db remote connect

-- Drop specialty tables
DROP TABLE IF EXISTS public.antenatal_visits CASCADE;
DROP TABLE IF EXISTS public.surgical_procedures CASCADE;
DROP TABLE IF EXISTS public.admission_discharge_records CASCADE;
DROP TABLE IF EXISTS public.medication_dispensing CASCADE;
DROP TABLE IF EXISTS public.pharmacy_stock CASCADE;
DROP TABLE IF EXISTS public.clinical_consultations CASCADE;
DROP TABLE IF EXISTS public.oncology_treatments CASCADE;
DROP TABLE IF EXISTS public.infectious_disease_visits CASCADE;
DROP TABLE IF EXISTS public.cardiology_visits CASCADE;
DROP TABLE IF EXISTS public.emergency_visits CASCADE;
DROP TABLE IF EXISTS public.nephrology_visits CASCADE;
DROP TABLE IF EXISTS public.gastroenterology_procedures CASCADE;
DROP TABLE IF EXISTS public.endocrinology_visits CASCADE;
DROP TABLE IF EXISTS public.pulmonology_visits CASCADE;
DROP TABLE IF EXISTS public.psychiatric_assessments CASCADE;
DROP TABLE IF EXISTS public.neurology_exams CASCADE;
DROP TABLE IF EXISTS public.radiology_reports CASCADE;
DROP TABLE IF EXISTS public.pathology_reports CASCADE;
DROP TABLE IF EXISTS public.physiotherapy_sessions CASCADE;
```

### Step 3: Rollback PowerSync Sync Rules

1. **Go to PowerSync Dashboard**
2. **Navigate to Sync Rules**
3. **Open your backup file:** `POWERSYNC_SYNC_RULES_backup_YYYYMMDD.yaml`
4. **Copy contents**
5. **Paste into PowerSync Dashboard editor**
6. **Deploy** previous version

### Step 4: Rollback Edge Function

```bash
# List function versions
npx supabase functions list

# Redeploy previous version (if available)
# Option 1: Restore from Git
git checkout HEAD~1 -- supabase/functions/sync-to-ehrbase/
npx supabase functions deploy sync-to-ehrbase

# Option 2: Manual restore from backup
cp -r $BACKUP_DIR/sync-to-ehrbase/* supabase/functions/sync-to-ehrbase/
npx supabase functions deploy sync-to-ehrbase
```

### Step 5: Rollback Flutter Code

```bash
# Restore PowerSync schema
cp $BACKUP_DIR/schema.dart lib/powersync/

# Restore database.dart
cp $BACKUP_DIR/database.dart lib/backend/supabase/database/

# Remove new model files
rm lib/backend/supabase/database/tables/antenatal_visits.dart
rm lib/backend/supabase/database/tables/surgical_procedures.dart
# ... remove all 19 model files

# Rebuild Flutter app
flutter clean
flutter pub get
flutter build apk  # Or your target platform
```

### Step 6: Verify Rollback

```bash
# Run verification
./verify_consistency.sh

# Test system
./test_system_connections.sh

# Check PowerSync Dashboard
# Ensure sync rules are reverted and working

# Test app functionality
flutter run
```

### Step 7: Communicate Status

- Notify stakeholders of rollback
- Document issues encountered
- Plan remediation for failed deployment
- Schedule new deployment window after fixes

---

## Troubleshooting

### Issue: Migration Fails to Apply

**Symptoms:**
```
Error: relation "antenatal_visits" already exists
```

**Cause:** Table already exists from previous deployment attempt.

**Solution:**
```sql
-- Drop the problematic table and retry
DROP TABLE IF EXISTS public.antenatal_visits CASCADE;

-- Then retry migration
npx supabase db push
```

### Issue: PowerSync Not Syncing

**Symptoms:**
- Dashboard shows "Not connected"
- Mobile app shows sync errors
- Bucket sizes remain 0

**Diagnostics:**
```bash
# Check PowerSync token function
npx supabase functions logs powersync-token

# Test token generation
curl -X POST YOUR_SUPABASE_URL/functions/v1/powersync-token \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json"
```

**Solutions:**

1. **Verify PowerSync credentials are set:**
```bash
npx supabase secrets list | grep POWERSYNC
```

2. **Redeploy token function:**
```bash
npx supabase functions deploy powersync-token
```

3. **Check sync rules syntax:**
- Validate YAML in PowerSync Dashboard
- Look for SQL errors in Monitor logs

4. **Verify Supabase connection:**
```bash
npx supabase status
```

### Issue: Edge Function Errors

**Symptoms:**
```
Error: EHRBASE_URL is not defined
```

**Cause:** Missing environment secrets.

**Solution:**
```bash
# Set required secrets
npx supabase secrets set EHRBASE_URL="https://ehr.medzenhealth.app/ehrbase"
npx supabase secrets set EHRBASE_USERNAME="ehrbase-admin"
npx supabase secrets set EHRBASE_PASSWORD="YOUR_PASSWORD"

# Redeploy function
npx supabase functions deploy sync-to-ehrbase

# Verify secrets
npx supabase secrets list
```

### Issue: Flutter Build Failures

**Symptoms:**
```
Error: The getter 'cardiologyVisits' isn't defined for the class 'SupabaseDataRow'
```

**Cause:** Missing export or model file.

**Solution:**
```bash
# Verify model exists
ls lib/backend/supabase/database/tables/cardiology_visits.dart

# Check export in database.dart
grep "cardiology_visits" lib/backend/supabase/database/database.dart

# If missing, add export
echo "export 'tables/cardiology_visits.dart';" >> lib/backend/supabase/database/database.dart

# Rebuild
flutter clean && flutter pub get
```

### Issue: RLS Policy Blocking Access

**Symptoms:**
- Can't query specialty tables
- "permission denied" errors
- Empty result sets despite data existing

**Diagnostics:**
```sql
-- Check RLS status
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'cardiology_visits';

-- View policies
SELECT * FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'cardiology_visits';
```

**Solutions:**

1. **Temporarily disable RLS for testing:**
```sql
ALTER TABLE public.cardiology_visits DISABLE ROW LEVEL SECURITY;
-- Test queries
-- Re-enable:
ALTER TABLE public.cardiology_visits ENABLE ROW LEVEL SECURITY;
```

2. **Check policy logic:**
- Verify `auth.uid()` returns expected user ID
- Check role assignment in `user_profiles`
- Ensure policy WHERE clauses match data

3. **Add missing policies:**
- Each table should have SELECT, INSERT, UPDATE policies
- Policies should check appropriate role permissions

### Issue: Test Suite Failures

**Symptoms:**
```
❌ FAIL: 5 models missing from PowerSync schema
```

**Solution:**
```bash
# Open PowerSync schema
nano lib/powersync/schema.dart

# Add missing table definitions
# Follow the pattern from existing tables

# Re-run verification
./verify_consistency.sh
```

### Getting Help

**If issues persist:**

1. **Check Logs:**
   - Edge function: `npx supabase functions logs sync-to-ehrbase`
   - PowerSync: Dashboard → Monitor → Logs
   - Flutter: Check device/emulator logs

2. **Review Documentation:**
   - `CLAUDE.md` - Project architecture
   - `POWERSYNC_QUICK_START.md` - PowerSync setup
   - `EHR_SYSTEM_DEPLOYMENT.md` - EHRbase integration

3. **Run Diagnostics:**
   ```bash
   ./test_system_connections.sh
   ./verify_consistency.sh
   ./test_specialty_tables.sh
   ```

4. **Check System Status:**
   - Supabase Status: https://status.supabase.com/
   - PowerSync Status: Check Dashboard
   - EHRbase: Verify endpoint accessibility

---

## Conclusion

**Successful Deployment Indicators:**

✅ All 19 tables exist in database
✅ RLS policies and triggers active
✅ PowerSync Dashboard shows all buckets syncing
✅ Edge function deployed without errors
✅ Flutter app builds successfully
✅ Test suite passes with 0 failures
✅ Medical records can be created in each specialty
✅ EHRbase sync queue processes records

**Post-Deployment Tasks:**

1. Monitor system for 24-48 hours
2. Review edge function logs for any sync errors
3. Check PowerSync sync success rate
4. Gather user feedback on new specialties
5. Document any issues encountered
6. Schedule follow-up review meeting

**Documentation References:**

- **Testing:** `SPECIALTY_TABLES_TESTING_GUIDE.md`
- **Helper Scripts:** `HELPER_SCRIPTS_GUIDE.md`
- **Architecture:** `CLAUDE.md`, `EHR_SYSTEM_README.md`
- **PowerSync:** `POWERSYNC_QUICK_START.md`, `POWERSYNC_MULTI_ROLE_GUIDE.md`

---

**Deployment Version:** 1.0.0
**Last Updated:** 2025-02-02
**Maintainer:** Claude Code Assistant
**Support:** Refer to project documentation or contact system administrator
