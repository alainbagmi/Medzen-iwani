# PowerSync Deployment Checklist

**Last Updated:** 2025-01-22
**Project:** MedZen Iwani Healthcare Application

## Pre-Deployment Checklist

### ✅ Step 1: Backup Current Files

```bash
# Backup current schema
cp lib/powersync/schema.dart lib/powersync/schema.dart.backup.$(date +%Y%m%d)

# Backup sync rules (if modified)
cp POWERSYNC_SYNC_RULES.yaml POWERSYNC_SYNC_RULES.yaml.backup.$(date +%Y%m%d)
```

### ✅ Step 2: Update Schema.dart

```bash
# Review the new schema
cat POWERSYNC_UPDATED_SCHEMA.dart

# If looks good, replace
cp POWERSYNC_UPDATED_SCHEMA.dart lib/powersync/schema.dart

# Update Flutter dependencies (if needed)
flutter pub get
```

**What changed:**
- Added 18 missing tables
- Total tables: 26 (up from 8)
- All tables now match POWERSYNC_SYNC_RULES.yaml

### ✅ Step 3: Run Verification Script

```bash
# Make executable (if not already)
chmod +x verify_powersync_setup.sh

# Run verification
./verify_powersync_setup.sh
```

**Expected output:**
```
✓ All sync rule tables exist in schema.dart
✓ All critical checks passed!
```

**If verification fails:**
- Check error messages
- Most common: Missing Supabase secrets
- Fix issues before proceeding

### ✅ Step 4: Configure PowerSync Secrets

```bash
# Set PowerSync instance URL
npx supabase secrets set POWERSYNC_URL=https://YOUR_INSTANCE.journeyapps.com

# Set PowerSync Key ID (from PowerSync Dashboard → Settings → API Keys)
npx supabase secrets set POWERSYNC_KEY_ID=abc123yourKeyId

# Set PowerSync Private Key (entire PEM including headers)
npx supabase secrets set POWERSYNC_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
...your full private key here...
-----END PRIVATE KEY-----'
```

**Get these values from:**
1. Go to https://powersync.journeyapps.com/
2. Select your instance
3. Navigate to: Settings → API Keys
4. Click: Generate RSA Key Pair (if not already done)
5. Copy: Key ID and Private Key

**Verify secrets are set:**
```bash
npx supabase secrets list

# Should show:
# POWERSYNC_URL
# POWERSYNC_KEY_ID
# POWERSYNC_PRIVATE_KEY
```

### ✅ Step 5: Deploy PowerSync Token Function

```bash
# Deploy the edge function
npx supabase functions deploy powersync-token

# Expected output:
# Deploying Function powersync-token (project ref: xyz)
# Successfully deployed function powersync-token
```

**Test the function:**
```bash
# Get a user token first (from your app or Supabase Dashboard)
# Then test:
npx supabase functions invoke powersync-token \
  --headers "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Expected response:
# {
#   "token": "eyJhbGciOiJSUzI1NiIsImtpZCI6...",
#   "powersync_url": "https://YOUR_INSTANCE.journeyapps.com",
#   "expires_at": "2025-01-23T04:00:00.000Z",
#   "user_id": "user-uuid-here"
# }
```

**If function fails:**
- Check secrets are set correctly
- Verify POWERSYNC_PRIVATE_KEY has correct format (with headers)
- Check function logs: `npx supabase functions logs powersync-token`

### ✅ Step 6: Deploy Sync Rules to PowerSync Dashboard

**Manual Steps:**

1. **Open PowerSync Dashboard**
   - Go to: https://powersync.journeyapps.com/
   - Sign in

2. **Select Your Instance**
   - Click on your instance name

3. **Navigate to Sync Rules**
   - In sidebar: Click "Sync Rules"

4. **Copy Sync Rules**
   ```bash
   # Display sync rules to copy
   cat POWERSYNC_SYNC_RULES.yaml
   ```

5. **Paste and Deploy**
   - Select all existing text in editor (if any)
   - Paste copied POWERSYNC_SYNC_RULES.yaml content
   - Click: "Save"
   - Click: "Deploy"

6. **Verify Deployment**
   - Check for "Deployed successfully" message
   - Look for green checkmark icon
   - Note the deployment version number

**Common deployment errors:**

| Error | Solution |
|-------|----------|
| "Syntax error in YAML" | Run sync rules through YAML validator |
| "Table not found" | Ensure schema.dart includes all tables |
| "Invalid query syntax" | Check for unsupported SQL (e.g., JOINs) |

### ✅ Step 7: Test in Your Flutter App

**Option A: Using Connection Test Page**

1. Run your app: `flutter run`
2. Navigate to: `/connectionTest` page
3. Click: "Test Signup Flow" (creates test user in all 4 systems)
4. Click: "Test Login (Online)"
5. Click: "Test Data Operations (Online)"
6. Verify all tests pass (green checkmarks)

**Option B: Manual Testing**

```dart
// Add to your landing page initState or button:
import 'package:medzen_iwani/powersync/database.dart';

// Test PowerSync status
void checkPowerSyncStatus() {
  final status = getPowerSyncStatus();
  print('PowerSync Connected: ${status.connected}');
  print('Last Synced: ${status.lastSyncedAt}');
  print('Downloading: ${status.downloading}');
  print('Uploading: ${status.uploading}');
}

// Test a simple query
Future<void> testQuery() async {
  final results = await executeQuery(
    'SELECT COUNT(*) as count FROM users',
  );
  print('User count: ${results.first['count']}');
}
```

### ✅ Step 8: Monitor Initial Sync

**Watch sync progress:**
```dart
// In your app, add this listener
db.statusStream.listen((status) {
  print('PowerSync Status Update:');
  print('  Connected: ${status.connected}');
  print('  Downloading: ${status.downloading}');
  print('  Uploading: ${status.uploading}');
  print('  Last Synced: ${status.lastSyncedAt}');
});
```

**Check PowerSync Dashboard:**
1. Go to PowerSync Dashboard
2. Select your instance
3. Click: "Monitoring" or "Logs"
4. Verify data is syncing

**Check Supabase Logs:**
```bash
# Watch Edge Function logs
npx supabase functions logs powersync-token --follow

# Should see successful token generations
```

## Post-Deployment Verification

### ✅ Verify All Systems Working

Run through this checklist in your app:

- [ ] User can log in successfully
- [ ] PowerSync status shows "connected"
- [ ] Can create a new vital sign record (offline mode)
- [ ] Can view existing patient data
- [ ] Enable airplane mode
- [ ] Can still create/edit data offline
- [ ] Disable airplane mode
- [ ] Data automatically syncs to Supabase
- [ ] Check EHRbase sync queue has entries
- [ ] Verify medical records appear in EHRbase

### ✅ Common Issues and Solutions

**Issue: "PowerSync not configured"**
```bash
# Solution: Check secrets
npx supabase secrets list

# Redeploy function
npx supabase functions deploy powersync-token
```

**Issue: "Table not found in schema"**
```bash
# Solution: Verify schema.dart has all tables
grep "Table('" lib/powersync/schema.dart | wc -l
# Should output: 26
```

**Issue: "No data syncing"**
```dart
// Solution: Check sync rules match user's role
// Debug: Print user's firebase_uid
print('User ID: ${SupaFlow.client.auth.currentUser?.id}');

// Check this ID exists in users table
// Check sync rules correctly identify user's role
```

**Issue: "Cannot write to view"**
```
// Solution: Views are read-only
// Don't try to write to:
// - openehr_integration_health
// - system_admin_appointment_stats
// - system_admin_clinical_stats
// - system_admin_facility_stats

// These are computed views, sync downloads only
```

## Rollback Plan

If PowerSync deployment causes issues:

```bash
# 1. Restore old schema
cp lib/powersync/schema.dart.backup.YYYYMMDD lib/powersync/schema.dart

# 2. Restart app
flutter run

# 3. Disconnect PowerSync (in app)
await disconnectPowerSync();

# 4. Clear local data (if needed - WARNING: DATA LOSS)
await clearPowerSyncData();

# 5. Fix issues, then re-deploy
```

## Success Criteria

✅ All checks passed:
- [ ] Verification script shows 0 errors
- [ ] PowerSync token function deploys successfully
- [ ] Sync rules deploy to PowerSync Dashboard
- [ ] Connection Test Page shows all green
- [ ] Can create/read/update/delete data online
- [ ] Can create/read/update/delete data offline
- [ ] Data syncs automatically when back online
- [ ] No errors in app logs
- [ ] No errors in PowerSync Dashboard logs
- [ ] No errors in Supabase Function logs

## Support Resources

**Documentation:**
- `POWERSYNC_CRITICAL_ISSUES.md` - Why this fix was needed
- `POWERSYNC_UPDATED_SCHEMA.dart` - Complete schema
- `POWERSYNC_SYNC_RULES.yaml` - Sync rules
- `CLAUDE.md` - Complete system architecture

**Logs:**
```bash
# PowerSync token function logs
npx supabase functions logs powersync-token --follow

# Check PowerSync Dashboard
# https://powersync.journeyapps.com/ → Your Instance → Logs

# Flutter app logs
# flutter run --verbose
```

**Testing:**
- Connection Test Page: `/connectionTest` in your app
- Manual testing: See Step 7 above

---

**Next Steps After Successful Deployment:**

1. Monitor sync performance for 24-48 hours
2. Check PowerSync Dashboard for any errors
3. Review Supabase Edge Function logs
4. Test all 4 user roles (Patient, Provider, Facility Admin, System Admin)
5. Verify EHRbase sync queue is processing correctly
6. Document any issues for team

**Deployment Complete! 🎉**
