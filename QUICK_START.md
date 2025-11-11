# EHR System Quick Start Guide

Get your complete EHR synchronization system up and running in under 30 minutes.

## Prerequisites Checklist

- [ ] Firebase project created
- [ ] Supabase project created
- [ ] EHRbase instance running (or use a hosted instance)
- [ ] Flutter SDK installed (>=3.0.0)
- [ ] Node.js 20 installed
- [ ] Firebase CLI installed (`npm install -g firebase-tools`)
- [ ] Supabase CLI installed (`npm install -g supabase`)

## Step-by-Step Setup

### 1. Database Migration (5 minutes)

```bash
# Navigate to project directory
cd /path/to/medzen-iwani-t1nrnu

# Connect to Supabase
npx supabase link --project-ref YOUR_PROJECT_REF

# Run migration
npx supabase db push
```

**Verify:**
```sql
-- Run in Supabase SQL Editor
SELECT COUNT(*) FROM ehrbase_sync_queue; -- Should return 0
SELECT COUNT(*) FROM v_sync_health_by_type; -- Should work without error
```

### 2. Firebase Functions Setup (10 minutes)

```bash
# Navigate to functions directory
cd firebase/functions

# Install dependencies
npm install

# Configure for local development
# Copy template and edit with your values
cp .runtimeconfig.template.json .runtimeconfig.json
# Edit .runtimeconfig.json with your credentials

# Test locally (optional)
npm run serve

# Deploy to production
cd ..
firebase deploy --only functions
```

**Verify:**
- Check Firebase Console → Functions
- You should see `onUserCreated` and `onUserDeleted`

### 3. Supabase Edge Functions Setup (10 minutes)

```bash
# Navigate to project root
cd /path/to/medzen-iwani-t1nrnu

# Copy environment template
cp supabase/.env.template supabase/.env
# Edit supabase/.env with your EHRbase credentials

# Deploy to production
npx supabase functions deploy sync-to-ehrbase

# Set production secrets
npx supabase secrets set EHRBASE_URL=https://your-ehrbase-instance.com
npx supabase secrets set EHRBASE_USERNAME=ehrbase-user
npx supabase secrets set EHRBASE_PASSWORD=your-password
```

**Verify:**
```bash
npx supabase functions list
# Should show sync-to-ehrbase as deployed
```

### 4. Flutter App Configuration (5 minutes)

```bash
# Install new dependencies
flutter pub get

# Run the app
flutter run
```

**In FlutterFlow (if using):**
1. Open project in FlutterFlow
2. Go to your main landing page
3. Add Action on Page Load → Custom Code → `initializeEHRSync`
4. Save and regenerate code

**Verify:**
- App should compile without errors
- Check console for "EHR Sync Service initialized" message

## Quick Test

### Test User Creation Flow

1. **Create a test user** via your app's signup flow
2. **Check Firebase Functions logs:**
   ```bash
   firebase functions:log --limit 10
   ```
3. **Check Supabase users table:**
   ```sql
   SELECT id, firebase_uid, email FROM users ORDER BY created_at DESC LIMIT 1;
   ```
4. **Check electronic_health_records:**
   ```sql
   SELECT * FROM electronic_health_records ORDER BY created_at DESC LIMIT 1;
   ```

**Expected Result:**
- User created in Firebase Auth ✅
- User record in Supabase `users` table ✅
- EHR record in `electronic_health_records` table ✅
- EHR created in EHRbase (check EHRbase UI/API) ✅

### Test Demographic Sync

1. **Update user demographics:**
   ```sql
   UPDATE users
   SET first_name = 'Test',
       last_name = 'User',
       date_of_birth = '1990-01-01'
   WHERE id = 'YOUR_USER_ID';
   ```

2. **Check sync queue:**
   ```sql
   SELECT * FROM ehrbase_sync_queue
   WHERE table_name = 'users_demographics'
   ORDER BY created_at DESC LIMIT 1;
   ```

3. **Trigger sync:**
   ```bash
   curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/sync-to-ehrbase \
     -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
   ```

4. **Verify completion:**
   ```sql
   SELECT sync_status, processed_at FROM ehrbase_sync_queue
   WHERE table_name = 'users_demographics'
   ORDER BY created_at DESC LIMIT 1;
   ```

**Expected Result:**
- Queue entry created with `sync_status = 'pending'` ✅
- After sync, `sync_status = 'completed'` ✅
- EHRbase EHR_STATUS updated with demographics ✅

## Troubleshooting

### Issue: Firebase Function Fails to Create EHR

**Error:** "Failed to create EHR: ECONNREFUSED"

**Solution:**
- Check EHRbase URL in Firebase config
- Ensure EHRbase is accessible from Firebase Cloud Functions
- Verify EHRbase credentials

### Issue: Sync Queue Items Not Processing

**Error:** Items stuck in 'pending' status

**Solution:**
```bash
# Check Edge Function logs
npx supabase functions logs sync-to-ehrbase

# Manually trigger sync
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/sync-to-ehrbase \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

### Issue: Flutter App Shows Connectivity Errors

**Error:** "package:connectivity_plus not found"

**Solution:**
```bash
# Clean and reinstall dependencies
flutter clean
flutter pub get
```

## Next Steps

1. **Set up monitoring:** Configure alerts for failed sync items
2. **Test offline mode:** Verify offline-first capabilities work
3. **Load testing:** Test with multiple concurrent users
4. **Review logs:** Set up log aggregation and monitoring
5. **Backup strategy:** Implement automated backups for critical data

## Production Checklist

Before going live:

- [ ] All environment variables set correctly
- [ ] Firebase Functions deployed and tested
- [ ] Supabase Edge Functions deployed and tested
- [ ] Database migrations applied
- [ ] Triggers and functions verified in database
- [ ] Test user flow completed successfully
- [ ] Test demographic sync completed successfully
- [ ] Test medical records sync completed successfully
- [ ] Offline mode tested on real devices
- [ ] Error handling and retry logic verified
- [ ] Monitoring and alerting configured
- [ ] Backup and disaster recovery plan in place
- [ ] Security review completed
- [ ] Performance testing completed
- [ ] Load testing completed

## Support Resources

- **Full Deployment Guide:** See [EHR_SYSTEM_DEPLOYMENT.md](./EHR_SYSTEM_DEPLOYMENT.md)
- **Firebase Logs:** `firebase functions:log`
- **Supabase Logs:** `npx supabase functions logs`
- **Database Queries:** Use Supabase SQL Editor
- **EHRbase Docs:** https://ehrbase.org/

## Common Commands Reference

```bash
# Firebase
firebase login
firebase deploy --only functions
firebase functions:log
firebase functions:config:get

# Supabase
npx supabase login
npx supabase link --project-ref YOUR_REF
npx supabase db push
npx supabase functions deploy
npx supabase functions logs sync-to-ehrbase
npx supabase secrets list

# Flutter
flutter pub get
flutter run
flutter clean
flutter analyze
```

---

**Estimated Setup Time:** 30 minutes

**Estimated Test Time:** 15 minutes

**Total Time to Complete Working System:** ~45 minutes
