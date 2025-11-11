# EHR System Deployment Checklist

Use this checklist to ensure proper deployment of the complete EHR synchronization system.

## Pre-Deployment Checklist

### Prerequisites
- [ ] Flutter SDK installed (>=3.0.0)
- [ ] Node.js 20 installed
- [ ] Firebase CLI installed (`npm install -g firebase-tools`)
- [ ] Supabase CLI installed (`npm install -g supabase`)
- [ ] Git repository up to date
- [ ] Firebase project created
- [ ] Supabase project created
- [ ] EHRbase instance available (URL, username, password ready)

### Credentials Ready
- [ ] Firebase project ID: ________________
- [ ] Supabase project ref: ________________
- [ ] Supabase URL: ________________
- [ ] Supabase service role key: (stored securely)
- [ ] EHRbase URL: ________________
- [ ] EHRbase username: ________________
- [ ] EHRbase password: (stored securely)

## Deployment Steps

### Step 1: Flutter Dependencies
```bash
flutter pub get
flutter analyze
```
- [ ] Dependencies installed successfully
- [ ] No analyzer errors
- [ ] `connectivity_plus` package added to pubspec.yaml

### Step 2: Database Setup
```bash
npx supabase link --project-ref YOUR_PROJECT_REF
npx supabase db push
```
- [ ] Linked to Supabase project
- [ ] Migration applied successfully
- [ ] Verify tables exist:
  - [ ] `ehrbase_sync_queue` has new columns
  - [ ] Triggers created on `users` table
  - [ ] Triggers created on `vital_signs`, `lab_results`, `prescriptions`
  - [ ] Functions created: `queue_user_demographics_for_sync`, etc.
  - [ ] Views created: `v_sync_health_by_type`

**Verification Query:**
```sql
-- Run in Supabase SQL Editor
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE trigger_schema = 'public';

-- Should show:
-- trigger_queue_user_demographics_sync on users
-- trigger_queue_vital_signs_sync on vital_signs
-- trigger_queue_lab_results_sync on lab_results
-- trigger_queue_prescriptions_sync on prescriptions
```

### Step 3: Firebase Functions Setup
```bash
cd firebase/functions
npm install
```
- [ ] Dependencies installed
- [ ] `@supabase/supabase-js` in package.json
- [ ] No npm errors

**Configure for Local Development:**
```bash
cp .runtimeconfig.template.json .runtimeconfig.json
# Edit .runtimeconfig.json with your credentials
```
- [ ] `.runtimeconfig.json` created and configured
- [ ] Supabase URL set
- [ ] Supabase service key set
- [ ] EHRbase URL set
- [ ] EHRbase credentials set

**Configure for Production:**
```bash
firebase functions:config:set \
  supabase.url="YOUR_URL" \
  supabase.service_key="YOUR_KEY" \
  ehrbase.url="YOUR_EHRBASE_URL" \
  ehrbase.username="USER" \
  ehrbase.password="PASS"

firebase functions:config:get
```
- [ ] Production config set
- [ ] Verified with `functions:config:get`

**Test Locally (Optional):**
```bash
npm run serve
```
- [ ] Emulator started successfully
- [ ] Functions visible in emulator UI

**Deploy:**
```bash
cd ..  # Back to firebase/
firebase deploy --only functions
```
- [ ] `onUserCreated` deployed successfully
- [ ] `onUserDeleted` deployed successfully
- [ ] Check Firebase Console Functions tab
- [ ] No deployment errors in logs

### Step 4: Supabase Edge Functions Setup

**Configure for Local Development:**
```bash
cp supabase/.env.template supabase/.env
# Edit supabase/.env with EHRbase credentials
```
- [ ] `.env` file created
- [ ] EHRBASE_URL set
- [ ] EHRBASE_USERNAME set
- [ ] EHRBASE_PASSWORD set

**Test Locally (Optional):**
```bash
npx supabase start
npx supabase functions serve sync-to-ehrbase --env-file supabase/.env
```
- [ ] Local Supabase started
- [ ] Edge Function serving locally
- [ ] Test with curl (see QUICK_START.md)

**Set Production Secrets:**
```bash
npx supabase secrets set EHRBASE_URL=https://your-ehrbase.com
npx supabase secrets set EHRBASE_USERNAME=user
npx supabase secrets set EHRBASE_PASSWORD=pass
npx supabase secrets list
```
- [ ] Secrets set in production
- [ ] Verified with `secrets list`

**Deploy:**
```bash
npx supabase functions deploy sync-to-ehrbase
npx supabase functions list
```
- [ ] Function deployed successfully
- [ ] Shows as deployed in `functions list`
- [ ] No deployment errors

### Step 5: Flutter App Configuration

**In Code:**
```dart
// Add to your main landing page
import 'package:medzen_iwani/custom_code/actions/initialize_ehr_sync.dart';

@override
void initState() {
  super.initState();
  initializeEHRSync();
}
```
- [ ] Import added
- [ ] `initializeEHRSync()` called on app start
- [ ] Code compiles without errors

**OR in FlutterFlow:**
- [ ] Opened project in FlutterFlow
- [ ] Navigated to main landing page
- [ ] Added Action on Page Load
- [ ] Selected Custom Code → `initializeEHRSync`
- [ ] Saved changes
- [ ] Regenerated code

**Build and Test:**
```bash
flutter clean
flutter pub get
flutter run
```
- [ ] App builds successfully
- [ ] No compilation errors
- [ ] Console shows "EHR Sync Service initialized"

## Testing Checklist

### Test 1: User Creation Flow
- [ ] Created test user via app signup
- [ ] Checked Firebase Functions logs: `firebase functions:log`
- [ ] Verified user in Supabase `users` table
- [ ] Verified EHR in `electronic_health_records` table
- [ ] Verified EHR in EHRbase (via API or UI)
- [ ] ✅ **Test Passed:** EHR created automatically on signup

**Expected Timeline:** 2-5 seconds from signup to EHR creation

### Test 2: Demographic Sync
```sql
UPDATE users
SET first_name = 'John',
    last_name = 'Doe',
    date_of_birth = '1990-01-01',
    gender = 'male'
WHERE id = 'YOUR_USER_ID';
```
- [ ] Updated user demographics in Supabase
- [ ] Verified queue entry created:
  ```sql
  SELECT * FROM ehrbase_sync_queue
  WHERE table_name = 'users_demographics';
  ```
- [ ] `sync_status = 'pending'`
- [ ] `sync_type = 'ehr_status_update'`
- [ ] `data_snapshot` contains demographic data
- [ ] Triggered sync (manually or wait for auto-sync)
- [ ] Verified `sync_status = 'completed'`
- [ ] Verified EHR_STATUS updated in EHRbase
- [ ] ✅ **Test Passed:** Demographics synced successfully

### Test 3: Medical Records Sync
```sql
INSERT INTO vital_signs (
  patient_id, systolic_bp, diastolic_bp,
  heart_rate, temperature, recorded_at
) VALUES (
  'YOUR_USER_ID', 120, 80, 72, 36.5, NOW()
) RETURNING id;
```
- [ ] Created vital signs record
- [ ] Verified queue entry:
  ```sql
  SELECT * FROM ehrbase_sync_queue
  WHERE table_name = 'vital_signs'
  ORDER BY created_at DESC LIMIT 1;
  ```
- [ ] `sync_status = 'pending'`
- [ ] Triggered sync
- [ ] Verified `sync_status = 'completed'`
- [ ] Verified composition in EHRbase
- [ ] ✅ **Test Passed:** Medical records synced successfully

### Test 4: Offline Mode (Flutter App)
- [ ] Enabled airplane mode on device
- [ ] Updated user profile in app
- [ ] Verified queue entry created (check database)
- [ ] Disabled airplane mode
- [ ] Waited 10-15 seconds (or triggered manual sync)
- [ ] Verified `sync_status = 'completed'`
- [ ] ✅ **Test Passed:** Offline-first sync works

### Test 5: Error Recovery
```sql
-- Simulate failed item
UPDATE ehrbase_sync_queue
SET sync_status = 'failed',
    retry_count = 2,
    error_message = 'Test error'
WHERE id = 'SOME_QUEUE_ITEM_ID';
```
- [ ] Created simulated failed item
- [ ] Used app to retry: `retryFailedEHRSync()`
- [ ] Verified retry attempt
- [ ] Verified successful completion or error logged
- [ ] ✅ **Test Passed:** Retry logic works

## Monitoring Setup

### Set Up Log Monitoring
- [ ] Firebase Functions logs accessible
  ```bash
  firebase functions:log
  ```
- [ ] Supabase Edge Functions logs accessible
  ```bash
  npx supabase functions logs sync-to-ehrbase
  ```
- [ ] Database monitoring queries saved:
  ```sql
  -- Sync health
  SELECT * FROM v_sync_health_by_type;

  -- Failed items
  SELECT * FROM ehrbase_sync_queue
  WHERE sync_status = 'failed';

  -- Pending items older than 1 hour
  SELECT * FROM ehrbase_sync_queue
  WHERE sync_status = 'pending'
  AND created_at < NOW() - INTERVAL '1 hour';
  ```

### Set Up Alerts (Recommended)
- [ ] Alert on failed items > threshold
- [ ] Alert on pending items older than X hours
- [ ] Alert on Firebase Function errors
- [ ] Alert on Edge Function errors

## Production Readiness Checklist

### Security
- [ ] Service role keys not exposed in client code
- [ ] `.runtimeconfig.json` in `.gitignore`
- [ ] `.env` files in `.gitignore`
- [ ] Row-level security enabled on Supabase tables
- [ ] Firebase Functions only accessible by authenticated services
- [ ] HTTPS/TLS for all connections

### Performance
- [ ] Tested with multiple concurrent users
- [ ] Sync queue processing time acceptable (<5 min)
- [ ] No memory leaks in Flutter app
- [ ] Background sync not draining battery excessively

### Data Integrity
- [ ] Verified data consistency between Supabase and EHRbase
- [ ] Tested rollback scenarios
- [ ] Backup strategy in place
- [ ] Data archival strategy documented

### Documentation
- [ ] Team familiar with deployment process
- [ ] Troubleshooting guide accessible
- [ ] API documentation reviewed
- [ ] Monitoring procedures documented

### Compliance
- [ ] openEHR standards compliance verified
- [ ] HIPAA/GDPR considerations reviewed (if applicable)
- [ ] Data retention policies implemented
- [ ] Audit logging enabled

## Post-Deployment

### Week 1
- [ ] Monitor sync success rate daily
- [ ] Review error logs
- [ ] Check queue backlog
- [ ] Verify EHRbase storage growth is as expected

### Week 2-4
- [ ] Run cleanup function for old entries
  ```sql
  SELECT cleanup_old_sync_queue_entries();
  ```
- [ ] Review performance metrics
- [ ] Optimize batch size if needed
- [ ] Adjust sync frequency if needed

### Monthly
- [ ] Review sync statistics
- [ ] Check for failed items requiring manual intervention
- [ ] Rotate credentials (if policy requires)
- [ ] Update documentation with lessons learned

## Rollback Plan

If issues arise:

1. **Disable Firebase Function**
   ```bash
   firebase functions:delete onUserCreated
   ```

2. **Disable Edge Function**
   ```bash
   npx supabase functions delete sync-to-ehrbase
   ```

3. **Pause Flutter Sync**
   - Comment out `initializeEHRSync()` call
   - Redeploy app

4. **Manual Sync**
   - Process queue manually
   - Fix issues
   - Re-enable automated sync

## Sign-Off

- [ ] All deployment steps completed
- [ ] All tests passed
- [ ] Monitoring in place
- [ ] Team trained
- [ ] Documentation reviewed
- [ ] Rollback plan understood

**Deployed By:** ________________

**Date:** ________________

**Deployment Environment:** ☐ Development  ☐ Staging  ☐ Production

**Notes:**
_________________________________________________
_________________________________________________
_________________________________________________

---

**Next Steps After Sign-Off:**
1. Monitor for 48 hours
2. Review with team
3. Document any issues encountered
4. Plan for optimization if needed

**Congratulations! Your EHR synchronization system is now live! 🎉**
