# Complete EHR Synchronization System

A production-ready, offline-first Electronic Health Record (EHR) synchronization system for MedZen Iwani, built on openEHR standards and EHRbase.

## Overview

This system provides seamless, automated synchronization between your Flutter app, Supabase database, and EHRbase following openEHR standards. It's designed to work offline-first, ensuring data is never lost and automatically syncs when connectivity is restored.

## Key Features

✅ **Automatic EHR Creation** - Every user gets an openEHR-compliant EHR on signup
✅ **Demographic Sync** - User profile changes automatically update EHR_STATUS in EHRbase
✅ **Medical Records Sync** - Vital signs, lab results, prescriptions sync as compositions
✅ **Offline-First** - Queue-based sync ensures no data loss when offline
✅ **Automatic Retry** - Failed syncs retry with exponential backoff
✅ **Real-time Monitoring** - Track sync health with built-in dashboards
✅ **Standards Compliant** - Full openEHR archetype support

## Architecture

### Components

1. **Firebase Cloud Functions**
   - `onUserCreated`: Creates user in Supabase + EHR in EHRbase on signup
   - `onUserDeleted`: Cleanup when user is deleted

2. **Supabase Database**
   - `users`: User demographics
   - `electronic_health_records`: Links users to their EHRs
   - `ehrbase_sync_queue`: Sync queue for offline-first operation
   - `vital_signs`, `lab_results`, `prescriptions`: Medical records
   - Database triggers: Automatically queue changes for sync

3. **Supabase Edge Functions**
   - `sync-to-ehrbase`: Processes sync queue, creates compositions and updates EHR_STATUS

4. **Flutter App**
   - `EHRSyncService`: Background sync service
   - Connectivity monitoring
   - Automatic sync on reconnection
   - Manual sync triggers

### Data Flow

```
┌─────────────────┐
│   User Signup   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│  Firebase Auth + Function   │──────┐
└─────────────────────────────┘      │
         │                            │
         ▼                            ▼
┌──────────────────┐         ┌──────────────┐
│  Supabase: User  │         │   EHRbase:   │
│  + EHR Record    │         │   Create EHR │
└──────────────────┘         └──────────────┘

┌─────────────────────┐
│  User Updates Demo  │
│  or Medical Record  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Database Trigger   │
└──────────┬──────────┘
           │
           ▼
┌──────────────────────┐
│  ehrbase_sync_queue  │◄───┐
└──────────┬───────────┘    │
           │                │ Retry on failure
           ▼                │
┌─────────────────────┐     │
│  Edge Function:     │─────┘
│  sync-to-ehrbase    │
└──────────┬──────────┘
           │
           ▼
┌──────────────────────┐
│  EHRbase: Update     │
│  EHR_STATUS or       │
│  Create Composition  │
└──────────────────────┘
```

## Quick Start

See [QUICK_START.md](./QUICK_START.md) for a 30-minute setup guide.

## Full Documentation

- **[QUICK_START.md](./QUICK_START.md)** - Get started in 30 minutes
- **[EHR_SYSTEM_DEPLOYMENT.md](./EHR_SYSTEM_DEPLOYMENT.md)** - Complete deployment guide
- **[CLAUDE.md](./CLAUDE.md)** - Project overview and development guide

## File Structure

```
medzen-iwani/
├── firebase/
│   └── functions/
│       ├── index.js                        # Cloud Functions (onUserCreated)
│       ├── package.json                    # Dependencies
│       └── .runtimeconfig.template.json    # Config template
│
├── supabase/
│   ├── migrations/
│   │   └── 20250121000001_enhanced_ehr_sync_system.sql  # Database setup
│   ├── functions/
│   │   └── sync-to-ehrbase/
│   │       ├── index.ts                    # Edge Function for syncing
│   │       └── deno.json                   # Deno config
│   ├── config.toml                         # Supabase config
│   └── .env.template                       # Environment template
│
├── lib/
│   ├── backend/supabase/database/tables/
│   │   ├── ehrbase_sync_queue.dart         # Sync queue model
│   │   ├── electronic_health_records.dart   # EHR records model
│   │   ├── users.dart                      # Users model
│   │   ├── vital_signs.dart                # Medical records models
│   │   ├── lab_results.dart
│   │   └── prescriptions.dart
│   │
│   └── custom_code/actions/
│       ├── ehr_sync_service.dart           # Core sync service
│       ├── initialize_ehr_sync.dart        # Initialize on app start
│       ├── trigger_ehr_sync.dart           # Manual sync trigger
│       ├── get_ehr_sync_stats.dart         # Get sync statistics
│       └── retry_failed_ehr_sync.dart      # Retry failed items
│
├── EHR_SYSTEM_README.md                    # This file
├── EHR_SYSTEM_DEPLOYMENT.md                # Deployment guide
└── QUICK_START.md                          # Quick start guide
```

## Database Schema

### ehrbase_sync_queue

The core of the offline-first sync system.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `table_name` | VARCHAR | Source table (users_demographics, vital_signs, etc.) |
| `record_id` | VARCHAR | ID of the record being synced |
| `template_id` | VARCHAR | openEHR template ID |
| `sync_type` | VARCHAR | composition_create, ehr_status_update |
| `sync_status` | VARCHAR | pending, completed, failed |
| `retry_count` | INTEGER | Number of retry attempts |
| `error_message` | TEXT | Error details if failed |
| `ehrbase_composition_id` | VARCHAR | EHRbase composition UID |
| `data_snapshot` | JSONB | Complete data snapshot for offline sync |
| `created_at` | TIMESTAMP | When queued |
| `processed_at` | TIMESTAMP | When completed |
| `last_retry_at` | TIMESTAMP | Last retry attempt |
| `updated_at` | TIMESTAMP | Last update |

### electronic_health_records

Links Supabase users to their EHRbase EHRs.

| Column | Type | Description |
|--------|------|-------------|
| `id` | UUID | Primary key |
| `patient_id` | UUID | Foreign key to users.id |
| `ehr_id` | VARCHAR | EHRbase EHR ID |
| `ehr_status` | VARCHAR | active, inactive |
| `system_id` | VARCHAR | System identifier (medzen_v1) |
| `subject_namespace` | VARCHAR | Subject namespace (medzen) |
| `ehrbase_created_at` | TIMESTAMP | When created in EHRbase |
| `created_at` | TIMESTAMP | Created in Supabase |
| `updated_at` | TIMESTAMP | Last updated |

## API Reference

### Flutter Custom Actions

#### initializeEHRSync()
Initialize the EHR sync service. Call once on app startup.

```dart
import 'package:medzen_iwani/custom_code/actions/initialize_ehr_sync.dart';

await initializeEHRSync();
```

**When to use:** In your main landing page's `onLoad` or app initialization.

#### triggerEHRSync()
Manually trigger a sync operation.

```dart
import 'package:medzen_iwani/custom_code/actions/trigger_ehr_sync.dart';

await triggerEHRSync();
```

**When to use:** On button press, pull-to-refresh, or when user manually requests sync.

#### getEHRSyncStats()
Get sync queue statistics.

```dart
import 'package:medzen_iwani/custom_code/actions/get_ehr_sync_stats.dart';

final stats = await getEHRSyncStats();
print('Pending: ${stats['pending']}');
print('Completed: ${stats['completed']}');
print('Failed: ${stats['failed']}');
```

**Returns:**
```json
{
  "pending": 5,
  "completed": 123,
  "failed": 2,
  "total": 130,
  "details": [...]
}
```

#### retryFailedEHRSync()
Retry all failed sync items.

```dart
import 'package:medzen_iwani/custom_code/actions/retry_failed_ehr_sync.dart';

await retryFailedEHRSync();
```

### Database Functions

#### queue_user_demographics_for_sync()
Automatically called by trigger when user demographics change.

#### cleanup_old_sync_queue_entries()
Removes old completed and failed entries.

```sql
SELECT cleanup_old_sync_queue_entries();
```

Run periodically (e.g., weekly) via cron job.

### Supabase Edge Function

#### POST /functions/v1/sync-to-ehrbase

Processes pending items in the sync queue.

**Request:**
```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/sync-to-ehrbase \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

**Response:**
```json
{
  "message": "Sync completed",
  "total": 10,
  "successful": 8,
  "failed": 2,
  "results": [...]
}
```

**Rate Limit:** Processes up to 50 items per invocation.

## Configuration

### Firebase Functions

Set via Firebase CLI:

```bash
firebase functions:config:set \
  supabase.url="https://YOUR_PROJECT.supabase.co" \
  supabase.service_key="YOUR_KEY" \
  ehrbase.url="https://ehrbase.example.com" \
  ehrbase.username="user" \
  ehrbase.password="pass"
```

Or for local development, create `.runtimeconfig.json`:

```json
{
  "supabase": {
    "url": "https://YOUR_PROJECT.supabase.co",
    "service_key": "YOUR_KEY"
  },
  "ehrbase": {
    "url": "http://localhost:8080",
    "username": "ehrbase-user",
    "password": "password"
  }
}
```

### Supabase Edge Functions

Set via Supabase CLI:

```bash
npx supabase secrets set EHRBASE_URL=https://ehrbase.example.com
npx supabase secrets set EHRBASE_USERNAME=user
npx supabase secrets set EHRBASE_PASSWORD=pass
```

Or for local development, create `supabase/.env`:

```
EHRBASE_URL=http://localhost:8080
EHRBASE_USERNAME=ehrbase-user
EHRBASE_PASSWORD=password
```

## Monitoring

### Check Sync Health

```sql
-- Overall health
SELECT * FROM v_sync_health_by_type;

-- Failed items
SELECT * FROM ehrbase_sync_queue
WHERE sync_status = 'failed'
ORDER BY created_at DESC;

-- Pending items older than 1 hour
SELECT * FROM ehrbase_sync_queue
WHERE sync_status = 'pending'
AND created_at < NOW() - INTERVAL '1 hour';
```

### View Logs

**Firebase Functions:**
```bash
firebase functions:log
firebase functions:log --only onUserCreated
```

**Supabase Edge Functions:**
```bash
npx supabase functions logs sync-to-ehrbase
npx supabase functions logs sync-to-ehrbase --follow
```

## Troubleshooting

### Common Issues

**1. Items stuck in pending**
- Check Edge Function logs
- Manually trigger sync
- Verify EHRbase connectivity

**2. Failed items with max retries**
- Check `error_message` column
- Fix underlying issue
- Reset retry count and status

**3. EHR not created on signup**
- Check Firebase Functions logs
- Verify EHRbase credentials
- Test EHRbase connectivity

See [EHR_SYSTEM_DEPLOYMENT.md](./EHR_SYSTEM_DEPLOYMENT.md) for detailed troubleshooting.

## Performance

### Current Limits
- **Edge Function:** 50 items per invocation
- **Sync Frequency:** Every 5 minutes (configurable)
- **Max Retries:** 5 attempts before marking as failed
- **Cleanup:** Old entries removed after 30-90 days

### Scaling Recommendations
- Increase Edge Function batch size for high volume
- Reduce sync frequency for better battery life
- Set up queue monitoring and alerts
- Implement data archival strategy

## Security

- ✅ Service role keys never exposed in client code
- ✅ Row-level security on all Supabase tables
- ✅ Data validation before syncing to EHRbase
- ✅ Encrypted connections (HTTPS/TLS)
- ✅ Audit logging in sync queue

## OpenEHR Templates

The system uses the following openEHR templates:

| Template ID | Purpose | Sync Type |
|-------------|---------|-----------|
| `ehrbase.demographics.v1` | User demographics | EHR_STATUS update |
| `ehrbase.vital_signs.v1` | Vital signs | Composition create |
| `ehrbase.lab_results.v1` | Laboratory results | Composition create |
| `ehrbase.prescriptions.v1` | Prescriptions | Composition create |

## Testing

Run the complete test suite:

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Manual testing
# See QUICK_START.md for manual test scenarios
```

## Contributing

When adding new medical record types:

1. Create database table
2. Add trigger function (copy pattern from vital_signs)
3. Create trigger
4. Update Edge Function with new template builder
5. Test sync flow
6. Update documentation

## License

See main project LICENSE file.

## Support

- **Issues:** GitHub Issues
- **Documentation:** This repository
- **EHRbase Docs:** https://ehrbase.org/
- **openEHR Docs:** https://www.openehr.org/

## Version

**Current Version:** 1.0.0
**Last Updated:** January 21, 2025
**Compatibility:** Flutter >=3.0.0, Node.js 20, EHRbase >=0.20.0
