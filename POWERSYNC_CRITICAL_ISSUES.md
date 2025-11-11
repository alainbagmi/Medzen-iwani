# PowerSync Critical Issues Report

**Generated:** 2025-01-22
**Status:** ❌ **CRITICAL - PowerSync will fail if deployed now**

## Executive Summary

Your PowerSync deployment is failing because **18 out of 26 tables** referenced in your sync rules are **MISSING from schema.dart**. This means PowerSync cannot sync these tables locally, causing sync failures.

## The Problem

**Tables in Sync Rules:** 26
**Tables in schema.dart:** 8
**Missing:** 18 tables (69% missing!)

### Missing Tables

```
1.  allergies
2.  appointments
3.  email_logs
4.  facility_admin_profiles
5.  facility_departments
6.  facility_providers
7.  facility_reports
8.  feedback
9.  medical_provider_profiles
10. openehr_integration_health (VIEW - special handling needed)
11. patient_profiles
12. provider_availability
13. provider_schedule_exceptions
14. system_admin_appointment_stats (VIEW)
15. system_admin_clinical_stats (VIEW)
16. system_admin_facility_stats (VIEW)
17. system_admin_profiles
18. user_activity_logs
```

**⚠️ Note:** 4 of these are database VIEWS, not tables. Views may require special handling in PowerSync.

## Solution

I've generated a complete updated `schema.dart` file with all 18 missing tables. Before deployment:

1. **Backup your current schema.dart**
2. **Replace with the updated version** (see POWERSYNC_UPDATED_SCHEMA.dart)
3. **Run verification script** to confirm all tables are included
4. **Deploy PowerSync token function** (if not already done)
5. **Deploy sync rules to PowerSync Dashboard**

## Quick Fix Commands

```bash
# 1. Backup current schema
cp lib/powersync/schema.dart lib/powersync/schema.dart.backup

# 2. Copy updated schema (after review)
cp POWERSYNC_UPDATED_SCHEMA.dart lib/powersync/schema.dart

# 3. Verify the fix
./verify_powersync_setup.sh

# 4. Deploy PowerSync token function
npx supabase functions deploy powersync-token

# 5. Test token function
npx supabase functions invoke powersync-token \
  --headers "Authorization: Bearer YOUR_USER_TOKEN"

# 6. Deploy sync rules to PowerSync Dashboard
# Go to https://powersync.journeyapps.com/
# Sync Rules → Paste POWERSYNC_SYNC_RULES.yaml → Save → Deploy
```

## Verification Steps

After updating schema.dart:

```bash
# Should show 0 missing tables
./verify_powersync_setup.sh
```

Expected output:
```
✓ All sync rule tables exist in schema.dart
✓ All critical checks passed!
```

## Next Steps

1. ✅ Review the updated schema.dart (POWERSYNC_UPDATED_SCHEMA.dart)
2. ✅ Replace your current schema.dart
3. ✅ Run flutter pub get (if needed)
4. ✅ Run verification script
5. ✅ Deploy PowerSync token function
6. ✅ Deploy sync rules to PowerSync Dashboard
7. ✅ Test with Connection Test Page in your app

## Warning About Database Views

The following tables are actually **database VIEWS**, not real tables:
- `openehr_integration_health`
- `system_admin_appointment_stats`
- `system_admin_clinical_stats`
- `system_admin_facility_stats`

Views don't have primary keys or write operations. If PowerSync has issues with these:
- Consider removing them from sync rules (read-only data)
- Or create materialized views in Supabase with proper IDs

## Common Deployment Errors

### Error: "Table not found in schema"
**Solution:** You're seeing this error now. Use the updated schema.dart.

### Error: "Cannot write to view"
**Solution:** Views are read-only. Remove write operations or convert to tables.

### Error: "PowerSync token invalid"
**Solution:** Check that POWERSYNC_PRIVATE_KEY secret is correctly set.

### Error: "No data syncing"
**Solution:** Check sync rules match your user's role and permissions.

## Support

If issues persist after applying these fixes:

1. Check PowerSync Dashboard logs
2. Check Supabase Edge Function logs: `npx supabase functions logs powersync-token`
3. Check app PowerSync status in debug mode
4. Run Connection Test Page in your app

---

**Critical:** DO NOT deploy sync rules to PowerSync Dashboard until you've updated schema.dart and verified all checks pass.
