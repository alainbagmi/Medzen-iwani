# Production Deployment Guide

## Overview

This guide walks you through deploying the **medzen-iwani** healthcare application with all 4 systems (Firebase, Supabase, PowerSync, EHRbase) properly configured for production use.

---

## Pre-Deployment Checklist

### ✅ Environment Setup

- [ ] Production Firebase project created
- [ ] Production Supabase project created
- [ ] PowerSync production instance created
- [ ] EHRbase production server accessible
- [ ] All API keys and secrets secured
- [ ] HTTPS enabled for all endpoints
- [ ] Domain names configured

### ✅ Security

- [ ] Rotate all development API keys
- [ ] Enable Firebase App Check
- [ ] Configure Supabase Row-Level Security (RLS)
- [ ] Review PowerSync sync rules for data isolation
- [ ] Enable CORS only for production domains
- [ ] SSL/TLS certificates installed
- [ ] HIPAA compliance review completed

### ✅ Code Quality

- [ ] All tests passing (`flutter test`)
- [ ] Code linter clean (`flutter analyze`)
- [ ] No debug print statements in production code
- [ ] Error tracking configured (e.g., Sentry, Firebase Crashlytics)
- [ ] Performance monitoring enabled

---

## Step 1: Firebase Configuration

### 1.1 Production Firebase Project

```bash
# Create production Firebase project at console.firebase.google.com

# Initialize Firebase in your production project
firebase use production

# Verify correct project
firebase projects:list
```

### 1.2 Deploy Firebase Cloud Functions

```bash
cd firebase/functions

# Install dependencies
npm install

# Set production configuration
firebase functions:config:set \
  supabase.url="https://YOUR_PROD_PROJECT.supabase.co" \
  supabase.service_key="YOUR_PROD_SERVICE_ROLE_KEY" \
  ehrbase.url="https://ehrbase.production.com" \
  ehrbase.username="prod-user" \
  ehrbase.password="SECURE_PASSWORD"

# Deploy functions
firebase deploy --only functions

# Verify deployment
firebase functions:log --only onUserCreated
```

### 1.3 Configure Firebase Security Rules

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage
```

**IMPORTANT:** Review `firebase/firestore.rules` and `firebase/storage.rules` to ensure they're production-ready.

---

## Step 2: Supabase Configuration

### 2.1 Database Migrations

```bash
# Connect to production Supabase
npx supabase link --project-ref YOUR_PROD_PROJECT_REF

# Run migrations
npx supabase db push

# Verify migrations
npx supabase db remote
```

### 2.2 Row-Level Security (RLS)

**Critical:** Ensure RLS is enabled on all tables.

```sql
-- Example RLS policy for users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own data"
  ON users
  FOR ALL
  USING (firebase_uid = auth.uid());

-- Repeat for all sensitive tables:
-- - electronic_health_records
-- - vital_signs
-- - lab_results
-- - prescriptions
-- - immunizations
-- - medical_records
```

### 2.3 Deploy Supabase Edge Functions

```bash
# Set production secrets
npx supabase secrets set \
  POWERSYNC_URL=https://YOUR_PROD_INSTANCE.journeyapps.com \
  POWERSYNC_KEY_ID=your-prod-key-id \
  POWERSYNC_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----
...YOUR PRODUCTION PRIVATE KEY...
-----END PRIVATE KEY-----" \
  EHRBASE_URL=https://ehrbase.production.com \
  EHRBASE_USERNAME=prod-user \
  EHRBASE_PASSWORD=SECURE_PASSWORD

# Deploy Edge Functions
npx supabase functions deploy sync-to-ehrbase
npx supabase functions deploy powersync-token

# Test Edge Functions
npx supabase functions invoke powersync-token \
  --headers "Authorization: Bearer YOUR_USER_TOKEN"
```

---

## Step 3: PowerSync Configuration

### 3.1 Create Production Instance

1. Log in to [PowerSync Dashboard](https://powersync.journeyapps.com/)
2. Create new production instance
3. Note the instance URL: `https://YOUR_PROD_INSTANCE.journeyapps.com`

### 3.2 Generate Production API Keys

1. Navigate to **Settings → API Keys**
2. Click **Generate RSA Key Pair**
3. Save:
   - **Key ID**
   - **Private Key** (PEM format)

### 3.3 Configure Sync Rules

In PowerSync Dashboard → **Sync Rules**:

```yaml
bucket_definitions:
  global:
    # Ensure users only sync their own data
    parameters: SELECT id as user_id FROM users WHERE firebase_uid = token_parameters.user_id()

    data:
      - SELECT * FROM users WHERE id = bucket.user_id
      - SELECT * FROM electronic_health_records WHERE patient_id = bucket.user_id
      - SELECT * FROM vital_signs WHERE patient_id = bucket.user_id
      - SELECT * FROM lab_results WHERE patient_id = bucket.user_id
      - SELECT * FROM prescriptions WHERE patient_id = bucket.user_id
      - SELECT * FROM immunizations WHERE patient_id = bucket.user_id
      - SELECT * FROM medical_records WHERE patient_id = bucket.user_id
      - SELECT * FROM ehrbase_sync_queue WHERE record_id IN (
          SELECT id::text FROM users WHERE id = bucket.user_id
        )
```

### 3.4 Connect to Supabase

1. PowerSync Dashboard → **Settings → Connections**
2. Add Supabase connection:
   - **Type**: PostgreSQL
   - **Host**: `db.YOUR_PROD_PROJECT_REF.supabase.co`
   - **Database**: `postgres`
   - **Username**: `postgres`
   - **Password**: Your Supabase DB password
   - **Port**: `5432`
   - **SSL Mode**: `require`

---

## Step 4: EHRbase Configuration

### 4.1 Verify EHRbase Accessibility

```bash
# Test EHRbase API
curl -X GET https://ehrbase.production.com/ehrbase/rest/openehr/v1/ehr \
  -u "prod-user:SECURE_PASSWORD" \
  -H "Content-Type: application/json"
```

### 4.2 Upload OpenEHR Templates

Ensure all required OpenEHR templates are uploaded to EHRbase:

- Vital Signs template
- Lab Results template
- Prescriptions template
- Immunizations template
- Medical Records template

```bash
# Example: Upload template
curl -X POST https://ehrbase.production.com/ehrbase/rest/openehr/v1/definition/template/adl1.4 \
  -u "prod-user:SECURE_PASSWORD" \
  -H "Content-Type: application/xml" \
  -d @templates/vital_signs_template.xml
```

---

## Step 5: Flutter App Configuration

### 5.1 Update Environment Variables

**In `lib/backend/supabase/supabase.dart`:**

```dart
// ⚠️ IMPORTANT: Use environment variables or build flavors for production

const _kSupabaseUrl = 'https://YOUR_PROD_PROJECT.supabase.co';
const _kSupabaseAnonKey = 'YOUR_PROD_ANON_KEY';
```

**Better approach:** Use build flavors:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final _kSupabaseUrl = dotenv.env['SUPABASE_URL']!;
final _kSupabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;
```

### 5.2 Build Production App

#### Android

```bash
# Build production APK
flutter build apk --release

# Or build App Bundle for Google Play
flutter build appbundle --release
```

#### iOS

```bash
# Build production IPA
flutter build ios --release

# Archive in Xcode for App Store submission
open ios/Runner.xcworkspace
```

#### Web

```bash
# Build production web app
flutter build web --release

# Deploy to hosting (Firebase Hosting example)
firebase deploy --only hosting
```

---

## Step 6: Monitoring & Observability

### 6.1 Firebase Performance Monitoring

Firebase Performance is already integrated. Verify:

```dart
// In lib/main.dart
import 'package:firebase_performance/firebase_performance.dart';

// Performance monitoring auto-starts
```

### 6.2 Error Tracking

Consider adding Sentry or Firebase Crashlytics for production error tracking:

```bash
flutter pub add sentry_flutter

# Or use Firebase Crashlytics
flutter pub add firebase_crashlytics
```

### 6.3 PowerSync Monitoring

Monitor in PowerSync Dashboard:
- **Metrics** → Active connections, sync throughput, error rates
- **Logs** → Real-time sync logs
- Set up alerts for high error rates

### 6.4 System Status Monitoring

Add the System Status Debug Widget to an admin page:

```dart
// In an admin or settings page
import 'package:medzen_iwani/components/system_status_debug/system_status_debug_widget.dart';

// Show as dialog
showDialog(
  context: context,
  builder: (context) => Dialog(
    child: SystemStatusDebugWidget(),
  ),
);
```

---

## Step 7: Testing Production Deployment

### 7.1 Test Signup Flow

1. **Create new account** via production app
2. **Verify** Firebase Auth user created
3. **Verify** Supabase `users` table has record
4. **Verify** EHRbase EHR created (check logs)
5. **Verify** `electronic_health_records` table has record
6. **Verify** PowerSync initialized for user

### 7.2 Test Online Operations

1. **Create vital signs** record
2. **Verify** saved to PowerSync local DB
3. **Verify** synced to Supabase
4. **Verify** queued in `ehrbase_sync_queue`
5. **Verify** synced to EHRbase (via Edge Function)

### 7.3 Test Offline Operations

1. **Enable airplane mode**
2. **Create vital signs** record
3. **Verify** saved to PowerSync local DB
4. **Disable airplane mode**
5. **Wait for sync**
6. **Verify** record in Supabase
7. **Verify** record in EHRbase

### 7.4 Monitor Logs

```bash
# Firebase Function logs
firebase functions:log --only onUserCreated

# Supabase Edge Function logs
npx supabase functions logs sync-to-ehrbase --follow
npx supabase functions logs powersync-token --follow

# PowerSync Dashboard
# Navigate to Logs section
```

---

## Step 8: Security Hardening

### 8.1 API Key Rotation Schedule

- **Firebase API keys**: Rotate every 90 days
- **Supabase keys**: Rotate service role key every 90 days (anon key can remain)
- **PowerSync keys**: Rotate RSA keys annually
- **EHRbase credentials**: Rotate every 90 days

### 8.2 Enable Firebase App Check

```dart
// Add to pubspec.yaml
firebase_app_check: ^latest_version

// In lib/main.dart
import 'package:firebase_app_check/firebase_app_check.dart';

await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.deviceCheck,
);
```

### 8.3 HIPAA Compliance

- [ ] Signed Business Associate Agreement (BAA) with:
  - [ ] Firebase (Google Cloud)
  - [ ] Supabase
  - [ ] PowerSync (JourneyApps)
  - [ ] EHRbase hosting provider
- [ ] Audit logging enabled for all data access
- [ ] Encryption at rest verified for all systems
- [ ] Encryption in transit (TLS 1.2+) verified
- [ ] Access controls reviewed (RLS, Firebase Rules)

---

## Step 9: Performance Optimization

### 9.1 PowerSync

```dart
// In lib/powersync/database.dart

db = PowerSyncDatabase(
  schema: schema,
  path: path,
  // Optimize for production
  options: const PowerSyncDatabaseOptions(
    enableMultiTables: true,
    // Reduce sync frequency if needed
    // (default is good for most cases)
  ),
);
```

### 9.2 Supabase Connection Pooling

Configure Supabase project settings:
- **Max connections**: Increase based on expected load
- **Connection timeout**: Set appropriate timeout

### 9.3 Firebase Firestore Indexes

Ensure all required indexes are created:

```bash
# Deploy indexes
firebase deploy --only firestore:indexes
```

---

## Step 10: Backup & Disaster Recovery

### 10.1 Supabase Backups

- Enable Point-in-Time Recovery (PITR) in Supabase dashboard
- Set up daily backups to external storage

### 10.2 EHRbase Backups

- Configure regular database backups
- Store backups in encrypted storage
- Test restore procedures monthly

### 10.3 Firebase Backups

- Enable Firestore automated backups
- Export data regularly to Cloud Storage

---

## Production Readiness Checklist

### 🚀 Ready to Deploy

- [ ] All 4 systems configured and tested
- [ ] Security hardening complete
- [ ] Monitoring and alerting configured
- [ ] Backup procedures in place
- [ ] Load testing completed
- [ ] HIPAA compliance verified
- [ ] API keys rotated and secured
- [ ] Documentation updated
- [ ] Disaster recovery plan documented
- [ ] Support team trained

---

## Troubleshooting Production Issues

### Issue: PowerSync not syncing in production

**Check:**
1. PowerSync credentials in Supabase secrets
2. PowerSync sync rules saved
3. Supabase connection in PowerSync dashboard
4. Network connectivity from app to PowerSync instance

**Debug:**
```dart
// Add to app for debugging
import 'package:medzen_iwani/services/initialization_manager.dart';

final status = initManager.getStatusSummary();
print('PowerSync status: ${status['powersync']}');
```

### Issue: Firebase Cloud Function failing

**Check:**
1. Function logs: `firebase functions:log --only onUserCreated`
2. Environment config: `firebase functions:config:get`
3. Supabase credentials in config
4. EHRbase credentials in config

### Issue: EHRbase sync failing

**Check:**
1. Edge Function logs: `npx supabase functions logs sync-to-ehrbase`
2. EHRbase credentials in Supabase secrets
3. EHRbase server accessibility
4. OpenEHR templates uploaded

---

## Support & Resources

- **Firebase Console**: https://console.firebase.google.com
- **Supabase Dashboard**: https://app.supabase.com
- **PowerSync Dashboard**: https://powersync.journeyapps.com
- **Firebase Docs**: https://firebase.google.com/docs
- **Supabase Docs**: https://supabase.com/docs
- **PowerSync Docs**: https://docs.powersync.com
- **OpenEHR Docs**: https://specifications.openehr.org

---

**Last Updated**: January 2025
**Version**: 1.0.0
