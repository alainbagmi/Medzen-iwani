# Helper Scripts Guide

This guide provides comprehensive documentation for the utility scripts created to streamline development and deployment of the MedZen specialty medical tables system.

## 📚 Table of Contents

- [Overview](#overview)
- [Script Reference](#script-reference)
  - [generate_migration.sh](#generate_migrationsh)
  - [generate_model.sh](#generate_modelsh)
  - [verify_consistency.sh](#verify_consistencysh)
  - [deploy_specialty_tables.sh](#deploy_specialty_tablessh)
- [Common Workflows](#common-workflows)
- [Troubleshooting](#troubleshooting)

## Overview

Four helper scripts are available to automate common development tasks:

1. **generate_migration.sh** - Generate new database migration files
2. **generate_model.sh** - Generate Dart model files from database schemas
3. **verify_consistency.sh** - Verify system consistency across all layers
4. **deploy_specialty_tables.sh** - Deploy all changes to production

All scripts:
- Include color-coded output for easy reading
- Provide detailed error messages
- Follow project conventions
- Are located in the project root directory
- Are executable (already set with `chmod +x`)

---

## Script Reference

### generate_migration.sh

**Purpose:** Generate a new Supabase migration file with proper timestamp and template structure.

**Usage:**
```bash
./generate_migration.sh <migration_name> [table_name]
```

**Arguments:**
- `migration_name` (required) - Descriptive name for the migration (e.g., `create_user_settings`)
- `table_name` (optional) - If provided, generates a full table creation template

**Examples:**

1. **Create a table migration:**
```bash
./generate_migration.sh create_user_settings user_settings
```
Generates: `supabase/migrations/20250202151030_create_user_settings.sql`

Template includes:
- Table creation with UUID primary key
- Standard created_at/updated_at timestamps
- Indexes on timestamp columns
- Row Level Security enabled
- Basic RLS policies (view/insert/update)
- updated_at trigger
- Table comment placeholder

2. **Create a generic migration:**
```bash
./generate_migration.sh add_user_preferences_column
```
Generates: `supabase/migrations/20250202151030_add_user_preferences_column.sql`

Template includes:
- Basic structure with comments
- Example ALTER TABLE and CREATE INDEX commands

**Output:**
- Creates migration file in `supabase/migrations/`
- Prints file location and next steps
- Provides reminders about PowerSync schema updates

**Next Steps After Generation:**
1. Edit the migration file to add your schema changes
2. Test locally: `npx supabase db reset`
3. Apply to production: `npx supabase db push`
4. Update PowerSync schema (`lib/powersync/schema.dart`)
5. Create Dart model file
6. Add export to `database.dart`
7. Update sync rules if needed

---

### generate_model.sh

**Purpose:** Generate a Dart model file for a Supabase table with proper SupabaseTable/SupabaseDataRow structure.

**Usage:**
```bash
./generate_model.sh <table_name> <class_name>
```

**Arguments:**
- `table_name` (required) - Database table name in snake_case (e.g., `user_settings`)
- `class_name` (required) - Dart class name in PascalCase (e.g., `UserSettings`)

**Example:**
```bash
./generate_model.sh user_settings UserSettings
```

Generates: `lib/backend/supabase/database/tables/user_settings.dart`

**Generated Template Includes:**

1. **Table Class:**
```dart
class UserSettingsTable extends SupabaseTable<UserSettingsRow> {
  @override
  String get tableName => 'user_settings';

  @override
  UserSettingsRow createRow(Map<String, dynamic> data) =>
      UserSettingsRow(data);
}
```

2. **Row Class with Field Examples:**
```dart
class UserSettingsRow extends SupabaseDataRow {
  // Primary key
  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  // Standard timestamps
  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  // Comments showing patterns for all field types
}
```

**Field Type Mapping Guide (included in template):**
```
PostgreSQL → Dart
VARCHAR/TEXT → String
INTEGER → int
REAL/DOUBLE PRECISION → double
BOOLEAN → bool
TIMESTAMPTZ/DATE → DateTime
TEXT[] → List<String>
JSONB → dynamic
UUID → String
```

**Next Steps After Generation:**
1. Edit the model file to add your field definitions
2. Add export to `lib/backend/supabase/database/database.dart`:
   ```dart
   export 'tables/user_settings.dart';
   ```
3. Run `flutter pub get`
4. Test the model in your app

---

### verify_consistency.sh

**Purpose:** Comprehensive verification of system consistency across migrations, PowerSync schema, Dart models, and exports.

**Usage:**
```bash
./verify_consistency.sh
```

**No arguments required** - Script automatically checks all components.

**Verification Checks:**

1. **Migration Files** ✓
   - Verifies migration directory exists
   - Counts migration files
   - Validates timestamp naming convention (YYYYMMDDHHMMSS_*.sql)

2. **PowerSync Schema** ✓
   - Checks schema file exists (`lib/powersync/schema.dart`)
   - Verifies Schema class definition
   - Counts table definitions

3. **Dart Models** ✓
   - Counts model files in `lib/backend/supabase/database/tables/`
   - Verifies each model extends SupabaseTable and SupabaseDataRow
   - Reports incomplete models

4. **Database Exports** ✓
   - Checks `database.dart` exists
   - Counts table exports
   - Identifies missing exports for model files

5. **PowerSync Sync Rules** ✓
   - Verifies `POWERSYNC_SYNC_RULES.yaml` exists
   - Checks for bucket_definitions section
   - Counts bucket definitions

6. **Edge Function** ✓
   - Checks `sync-to-ehrbase` function exists
   - Verifies template mappings are present

7. **Dependencies** ✓
   - Checks `pubspec.yaml` for required packages:
     - supabase_flutter
     - powersync
     - sqflite
     - path_provider

**Output:**
- Color-coded results (✅ green = pass, ❌ red = fail, ⚠️ yellow = warning)
- Detailed summary with total/passed/failed counts
- Exit code 0 if all checks pass, 1 if any fail

**Example Output:**
```
🔍 Starting consistency verification...

1️⃣  Checking migration files...
✅ PASS: Found 31 migration files
✅ PASS: All migrations follow timestamp naming convention

2️⃣  Checking PowerSync schema...
✅ PASS: PowerSync schema file exists
✅ PASS: Schema class definition found
✅ PASS: Found 42 table definitions in PowerSync schema

...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Verification Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total checks: 23
Passed: 23
Failed: 0

✅ All verification checks passed!

System is ready for deployment.
```

**When to Run:**
- Before deploying to production
- After adding new tables or models
- When troubleshooting sync issues
- As part of CI/CD pipeline

---

### deploy_specialty_tables.sh

**Purpose:** Automated deployment of all specialty medical table changes to production.

**Usage:**
```bash
./deploy_specialty_tables.sh [--dry-run]
```

**Arguments:**
- `--dry-run` (optional) - Preview deployment without making changes

**Deployment Steps:**

**Step 1: Running consistency verification**
- Executes `verify_consistency.sh`
- Aborts deployment if verification fails

**Step 2: Creating backup of current state**
- Creates timestamped backup directory: `backups/YYYYMMDD_HHMMSS/`
- Backs up:
  - All migration files
  - PowerSync schema
  - database.dart
- Prints backup location for rollback if needed

**Step 3: Deploying database migrations to Supabase**
- Runs `npx supabase db push`
- Applies all pending migrations to production database

**Step 4: Deploying PowerSync sync rules**
- Prompts for manual PowerSync Dashboard deployment
- Provides step-by-step instructions
- Waits for confirmation before proceeding

**Step 5: Deploying sync-to-ehrbase edge function**
- Runs `npx supabase functions deploy sync-to-ehrbase`
- Deploys latest edge function code

**Step 6: Building Flutter application**
- Runs `flutter pub get` to install dependencies
- Runs `flutter analyze` for static analysis
- Warns if analysis finds issues

**Step 7: Running integration tests**
- Executes `test_system_connections.sh` if available
- Reports test results

**Prerequisites:**
- Supabase CLI installed and authenticated
- Flutter SDK installed
- All verification checks passing

**Examples:**

1. **Dry Run (Preview):**
```bash
./deploy_specialty_tables.sh --dry-run
```
Shows what would happen without making changes.

2. **Production Deployment:**
```bash
./deploy_specialty_tables.sh
```
Performs full deployment to production.

**Deployment Summary Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Deployment Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Deployment completed successfully!

Deployed components:
  ✓ Database migrations (19 specialty tables)
  ✓ PowerSync sync rules (4 user roles)
  ✓ Edge function (sync-to-ehrbase)
  ✓ Dart models (19 files)
  ✓ Flutter application updates

📋 Post-deployment checklist:
  1. Verify PowerSync Dashboard shows all tables syncing
  2. Test user signup/login flows
  3. Test medical record creation for each specialty
  4. Verify EHRbase sync queue processing
  5. Check edge function logs
  6. Monitor PowerSync sync status in app

⚠️  Important:
  - Backup created at: backups/20250202_151030/
  - Review PowerSync Dashboard for sync errors
  - Test thoroughly in staging before production rollout
```

**Rollback Procedure (if needed):**
1. Locate backup directory from deployment output
2. Restore files from backup:
   ```bash
   cp -r backups/20250202_151030/migrations/* supabase/migrations/
   npx supabase db push
   ```
3. Redeploy previous edge function version
4. Restore previous PowerSync sync rules via Dashboard

---

## Common Workflows

### Workflow 1: Adding a New Table

**Complete step-by-step process:**

```bash
# 1. Generate migration file
./generate_migration.sh create_patient_notes patient_notes

# 2. Edit the migration file
# Open: supabase/migrations/TIMESTAMP_create_patient_notes.sql
# Add your table columns, constraints, indexes

# 3. Generate Dart model
./generate_model.sh patient_notes PatientNotes

# 4. Edit the model file
# Open: lib/backend/supabase/database/tables/patient_notes.dart
# Add your field getters/setters

# 5. Add export to database.dart
# Add line: export 'tables/patient_notes.dart';

# 6. Update PowerSync schema
# Edit: lib/powersync/schema.dart
# Add table definition to tables array

# 7. Update sync rules (if needed)
# Edit: POWERSYNC_SYNC_RULES.yaml
# Add bucket definitions for the new table

# 8. Update edge function (if needed)
# Edit: supabase/functions/sync-to-ehrbase/index.ts
# Add template mapping and builder function

# 9. Verify consistency
./verify_consistency.sh

# 10. Test locally
npx supabase db reset
flutter pub get
flutter run

# 11. Deploy to production
./deploy_specialty_tables.sh --dry-run  # Preview first
./deploy_specialty_tables.sh             # Actual deployment
```

### Workflow 2: Modifying Existing Table

```bash
# 1. Generate migration for changes
./generate_migration.sh add_patient_notes_priority

# 2. Edit migration to add ALTER TABLE commands
# Example: ALTER TABLE patient_notes ADD COLUMN priority TEXT;

# 3. Update Dart model
# Add new field getter/setter to patient_notes.dart

# 4. Update PowerSync schema if field types changed
# Edit lib/powersync/schema.dart

# 5. Verify consistency
./verify_consistency.sh

# 6. Deploy
./deploy_specialty_tables.sh
```

### Workflow 3: Pre-Production Checklist

```bash
# Run all verification steps
./verify_consistency.sh

# Test system connections
./test_system_connections.sh

# Dry run deployment
./deploy_specialty_tables.sh --dry-run

# Review output for any warnings

# If all clear, deploy
./deploy_specialty_tables.sh
```

---

## Troubleshooting

### Script Permission Issues

**Problem:** Script won't execute
```bash
bash: ./generate_migration.sh: Permission denied
```

**Solution:**
```bash
chmod +x generate_migration.sh
# Or make all scripts executable:
chmod +x *.sh
```

### Migration Naming Issues

**Problem:** Verification fails with "invalid naming format"

**Solution:** Migration files must follow pattern: `YYYYMMDDHHMMSS_description.sql`
- Timestamps must be 14 digits
- Use underscore separator
- Extension must be `.sql`

Example: `20250202151030_create_user_settings.sql` ✅
Not: `2025_02_02_create_user_settings.sql` ❌

### Missing Exports

**Problem:** Verification reports "X models are not exported"

**Solution:**
```bash
# Find missing exports
grep -L "export 'tables/" lib/backend/supabase/database/database.dart

# Add missing exports manually to database.dart
# Or regenerate with corrected export statement
```

### Deployment Fails at Supabase Push

**Problem:** `npx supabase db push` fails

**Common Causes:**
1. **Not logged in:** Run `npx supabase login`
2. **Not linked:** Run `npx supabase link --project-ref YOUR_REF`
3. **Migration syntax error:** Check migration SQL for errors
4. **Conflicting migrations:** Resolve conflicts, may need to squash migrations

**Solution:**
```bash
# Check connection
npx supabase projects list

# Test migration locally first
npx supabase db reset

# Check migration syntax
cat supabase/migrations/TIMESTAMP_*.sql
```

### PowerSync Sync Rules Not Working

**Problem:** Tables not syncing after deployment

**Checklist:**
1. Verify rules deployed in PowerSync Dashboard
2. Check sync rules YAML syntax
3. Verify table names match database exactly
4. Check user role in app matches bucket definition
5. Review PowerSync logs in Dashboard

**Debug:**
```bash
# Check PowerSync status in app
# Monitor db.statusStream in code

# View edge function logs
npx supabase functions logs powersync-token

# Verify token generation
curl -X POST YOUR_SUPABASE_URL/functions/v1/powersync-token \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

### Model Generation Issues

**Problem:** Generated model doesn't compile

**Common Issues:**
1. **Reserved Dart keywords:** Rename field if it conflicts (e.g., `default`, `class`)
2. **Type mismatch:** Ensure PostgreSQL→Dart type mapping is correct
3. **Missing imports:** Check `import '../database.dart';` at top

**Solution:**
```bash
# Run Flutter analyzer to see exact errors
flutter analyze lib/backend/supabase/database/tables/YOUR_TABLE.dart

# Fix reported issues
# Run pub get
flutter pub get
```

### Backup and Restore

**Create Manual Backup:**
```bash
BACKUP_DIR="backups/manual_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r supabase/migrations "$BACKUP_DIR/"
cp lib/powersync/schema.dart "$BACKUP_DIR/"
cp lib/backend/supabase/database/database.dart "$BACKUP_DIR/"
echo "Backup created: $BACKUP_DIR"
```

**Restore from Backup:**
```bash
# Find your backup
ls -la backups/

# Restore migrations
cp -r backups/20250202_151030/migrations/* supabase/migrations/

# Restore schema
cp backups/20250202_151030/schema.dart lib/powersync/

# Restore database.dart
cp backups/20250202_151030/database.dart lib/backend/supabase/database/

# Redeploy
npx supabase db push
```

---

## Additional Resources

**Related Documentation:**
- `EHR_SYSTEM_DEPLOYMENT.md` - Complete deployment guide
- `POWERSYNC_QUICK_START.md` - PowerSync setup
- `TESTING_GUIDE.md` - Testing procedures
- `CLAUDE.md` - Project overview and architecture

**Useful Commands:**
```bash
# Check Supabase status
npx supabase status

# View edge function logs
npx supabase functions logs sync-to-ehrbase

# Check PowerSync schema
cat lib/powersync/schema.dart | grep "Table("

# List all models
ls -1 lib/backend/supabase/database/tables/*.dart

# Count migrations
ls -1 supabase/migrations/*.sql | wc -l

# Verify all exports
grep "^export 'tables/" lib/backend/supabase/database/database.dart | wc -l
```

---

## Support

If you encounter issues not covered in this guide:
1. Check the project's `CLAUDE.md` for architecture details
2. Review relevant documentation in the project root
3. Check console output for detailed error messages
4. Verify all prerequisites are installed and configured
5. Try running verification script for diagnostic information

**Script Locations:**
- All scripts: Project root directory (`/Users/alainbagmi/Desktop/medzen-iwani-t1nrnu/`)
- Make executable: `chmod +x *.sh`
- Run from project root

---

**Last Updated:** 2025-02-02
**Version:** 1.0.0
**Maintainer:** Claude Code Assistant
