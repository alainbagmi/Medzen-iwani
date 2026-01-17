# Post-Call SOAP Note Workflow - Deployment Guide

## Checklist: Files Ready for Deployment

### 1. Dialog Widget ✅
- **File:** `lib/custom_code/widgets/post_call_clinical_notes_dialog.dart`
- **Status:** Compiled successfully (style warnings only, no functional errors)
- **Changes:**
  - Fixed all compilation errors
  - Added `plan` field to SOAPNoteData model
  - Replaced FFAppState().UserFullName with dynamic _providerName
  - Added _fetchProviderName() method
- **Size:** ~1000 lines of code

### 2. Database Migration ✅
- **File:** `supabase/migrations/20260116000000_extend_soap_notes_for_post_call_workflow.sql`
- **Status:** Ready to deploy
- **Changes:**
  - Adds provider_id, patient_id foreign keys
  - Adds signed_at, signed_by, transcript, full_data fields
  - Adds EHR sync tracking: ehr_sync_status, synced_at, ehr_sync_error
  - Creates trigger: queue_signed_soap_note_for_sync()
  - Creates 4 new indexes for performance
- **Size:** 6.0K

### 3. Background Sync Worker ✅
- **File:** `supabase/functions/process-ehr-sync-queue/index.ts`
- **Status:** Ready to deploy
- **Features:**
  - Processes up to 10 pending items per run
  - Implements retry logic (up to 5 retries)
  - Calls sync-to-ehrbase edge function
  - Updates queue and source table status
  - Comprehensive logging
- **Size:** 7.2K

### 4. Documentation ✅
- **File:** `EHR_SYNC_IMPLEMENTATION_COMPLETE.md`
- Complete overview of workflow and architecture

---

## Deployment Steps (In Order)

### Step 1: Verify Flutter Setup
```bash
# Check Flutter version and dependencies
flutter --version
flutter pub get

# Run compilation check
dart analyze lib/custom_code/widgets/post_call_clinical_notes_dialog.dart
```

### Step 2: Deploy Database Migration
```bash
# Link to Supabase (if not already linked)
npx supabase link --project-ref noaeltglphdlkbflipit

# Apply migration
npx supabase migration up

# Verify migration applied
npx supabase migration list | grep "20260116000000"
```

### Step 3: Deploy Edge Function
```bash
# Deploy the new sync queue worker
npx supabase functions deploy process-ehr-sync-queue

# Verify deployment (optional)
npx supabase functions list
```

### Step 4: Test End-to-End Locally (Optional)
```bash
# Start local Supabase
npx supabase start

# In another terminal, run local functions
npx supabase functions serve

# Test the dialog widget by building
flutter run -d chrome  # For web testing
```

### Step 5: Configure Periodic Scheduler

**Choose one of the following:**

#### Option A: GitHub Actions (Recommended for simplicity)
```yaml
# File: .github/workflows/sync-ehr-queue.yml
name: Process EHR Sync Queue
on:
  schedule:
    - cron: '*/5 * * * *'  # Every 5 minutes

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - name: Process EHR Sync Queue
        run: |
          curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/process-ehr-sync-queue" \
            -H "Authorization: Bearer ${{ secrets.SUPABASE_ANON_KEY }}" \
            -H "Content-Type: application/json" \
            -d '{}'
```

#### Option B: Google Cloud Scheduler
```bash
gcloud scheduler jobs create http process-ehr-sync \
  --schedule="*/5 * * * *" \
  --http-method=POST \
  --uri="https://noaeltglphdlkbflipit.supabase.co/functions/v1/process-ehr-sync-queue" \
  --headers="Authorization: Bearer YOUR_SUPABASE_KEY" \
  --location=us-central1
```

#### Option C: AWS Lambda + EventBridge
- Create Lambda function to call the edge function
- Set EventBridge rule to trigger every 5 minutes
- Update Lambda to use Supabase API key from Secrets Manager

#### Option D: Manual Testing Only (For Development)
```bash
# Run manually whenever needed
npx supabase functions invoke process-ehr-sync-queue
```

---

## Verification Checklist

After deployment, verify each component:

### Database
```sql
-- Check migration was applied
SELECT table_name FROM information_schema.tables
WHERE table_name = 'soap_notes';

-- Check new columns exist
SELECT column_name FROM information_schema.columns
WHERE table_name = 'soap_notes'
AND column_name IN ('provider_id', 'signed_at', 'transcript', 'ehr_sync_status');

-- Check trigger exists
SELECT trigger_name FROM information_schema.triggers
WHERE event_object_table = 'soap_notes';
```

### Edge Function
```bash
# Check function deployed
npx supabase functions list | grep process-ehr-sync-queue

# Test function (make sure you're authenticated)
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/process-ehr-sync-queue" \
  -H "Authorization: Bearer $(curl -s https://noaeltglphdlkbflipit.supabase.co/auth/v1/user \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" | jq -r '.access_token' || echo 'use-anon-key')" \
  -H "Content-Type: application/json" \
  -d '{}'
```

### Dialog Widget
```bash
# Verify no compilation errors
dart analyze lib/custom_code/widgets/post_call_clinical_notes_dialog.dart

# Build for target platform
flutter build web  # For web
flutter build apk  # For Android
flutter build ios  # For iOS
```

---

## Testing the Complete Workflow

### Test Scenario 1: Create Signed SOAP Note
```sql
-- Simulate creating a signed SOAP note
INSERT INTO soap_notes (
  session_id,
  appointment_id,
  provider_id,
  patient_id,
  chief_complaint,
  status,
  signed_at,
  signed_by,
  transcript,
  full_data,
  created_at
) VALUES (
  (SELECT id FROM video_call_sessions LIMIT 1),
  (SELECT id FROM appointments LIMIT 1),
  (SELECT id FROM users WHERE role = 'provider' LIMIT 1),
  (SELECT id FROM users WHERE role = 'patient' LIMIT 1),
  'Test chief complaint',
  'signed',
  NOW(),
  (SELECT id FROM users WHERE role = 'provider' LIMIT 1),
  'Test transcript content',
  '{"full": "soap note data"}',
  NOW()
);

-- Check if queue item was created by the trigger
SELECT * FROM ehrbase_sync_queue
WHERE table_name = 'soap_notes'
AND sync_status = 'pending'
ORDER BY created_at DESC LIMIT 1;
```

### Test Scenario 2: Process Queue
```bash
# Call the sync queue processor
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/process-ehr-sync-queue" \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json"

# Check results
# curl should return JSON with:
# {
#   "success": true,
#   "itemsProcessed": 1,
#   "successCount": 1,
#   "failureCount": 0,
#   "results": [...]
# }
```

### Test Scenario 3: Verify UI Integration
```bash
# Start the app
flutter run -d chrome

# Navigate to video call page
# Complete a video call
# Dialog should appear with:
#   - 6 tabs: Encounter, Subjective, Objective, Assessment, Plan, Sign-off
#   - Transcript panel on right (30% width)
#   - Voice input buttons on each section
# Fill in SOAP note
# Click "Save & Sign"
# Should see success message
# Check database for saved soap_note with status='signed'
```

---

## Common Issues & Troubleshooting

### Issue 1: Migration Won't Apply
**Symptom:** `npx supabase migration up` fails
**Solution:**
```bash
# Reset and retry
npx supabase db reset
npx supabase migration up
```

### Issue 2: Edge Function Not Found
**Symptom:** 404 when calling process-ehr-sync-queue
**Solution:**
```bash
# Redeploy function
npx supabase functions deploy process-ehr-sync-queue --no-verify-jwt

# Check logs
npx supabase functions logs process-ehr-sync-queue --tail
```

### Issue 3: Trigger Not Firing
**Symptom:** Items not added to sync queue when SOAP note signed
**Solution:**
```sql
-- Check trigger exists and is enabled
SELECT event_object_table, trigger_name, event_manipulation
FROM information_schema.triggers
WHERE trigger_name LIKE '%soap_note%';

-- Manually invoke trigger function for testing
SELECT queue_signed_soap_note_for_sync();
```

### Issue 4: Sync Queue Not Processing
**Symptom:** Items stay in 'pending' status
**Solution:**
- Verify cron job is running
- Check edge function logs: `npx supabase functions logs process-ehr-sync-queue --tail`
- Verify patient has EHR ID: `SELECT ehr_id FROM users WHERE id = '<patient_id>';`
- Manually test function: `npx supabase functions invoke process-ehr-sync-queue`

### Issue 5: Dialog Compilation Error
**Symptom:** Dart analyzer errors
**Solution:**
```bash
dart analyze lib/custom_code/widgets/post_call_clinical_notes_dialog.dart
# Should show "No issues found" or only style warnings

# If errors, rebuild:
flutter clean
flutter pub get
flutter analyze
```

---

## Rollback Plan

If something goes wrong:

### Rollback Migration
```bash
# Revert the migration
npx supabase migration list
# Find the migration before 20260116000000
npx supabase migration reset
# Then run migrations up to the previous version
npx supabase migration up --name <previous-migration>
```

### Rollback Edge Function
```bash
# Remove the function (keep sync-to-ehrbase)
npx supabase functions delete process-ehr-sync-queue

# Or disable it by removing the schedule
# (depends on how you set up the scheduler)
```

### Rollback Dialog Widget
```bash
git checkout HEAD~ lib/custom_code/widgets/post_call_clinical_notes_dialog.dart
```

---

## Monitoring & Maintenance

### Daily Checks
```sql
-- Check for failed syncs
SELECT COUNT(*) as failed_syncs
FROM ehrbase_sync_queue
WHERE sync_status = 'failed';

-- Check queue size
SELECT COUNT(*) as pending_syncs
FROM ehrbase_sync_queue
WHERE sync_status = 'pending';

-- Monitor retry counts
SELECT retry_count, COUNT(*)
FROM ehrbase_sync_queue
WHERE sync_status IN ('failed', 'error')
GROUP BY retry_count;
```

### Weekly Review
- Review error messages in `ehr_sync_error` field
- Check logs: `npx supabase functions logs process-ehr-sync-queue`
- Monitor EHRbase connection status
- Verify no items stuck in 'processing' status

### Alert Setup (Optional)
Set up alerts for:
- Sync queue with > 50 pending items
- Items with retry_count >= 4
- SOAP notes with ehr_sync_status = 'error'

---

## Performance Tuning

If sync queue grows large:

### Increase Processing Capacity
```typescript
// In process-ehr-sync-queue/index.ts, change:
.limit(10)  // Process max X items per run

// To process more items:
.limit(50)  // Process max 50 items per run
```

### Reduce Sync Frequency
If sync queue stays empty, reduce scheduler frequency:
- From every 5 minutes → every 15 minutes
- Saves cloud compute resources

### Database Optimization
```sql
-- Analyze query performance
EXPLAIN ANALYZE
SELECT * FROM ehrbase_sync_queue
WHERE sync_status IN ('pending', 'failed')
LIMIT 10;

-- Add partial index if needed
CREATE INDEX idx_sync_queue_pending
ON ehrbase_sync_queue(created_at)
WHERE sync_status IN ('pending', 'failed');
```

---

## Success Criteria

Workflow is working when:
1. ✅ Dialog pops up after video call with SOAP entry form
2. ✅ Provider can edit and save SOAP note
3. ✅ SOAP note saved to database with status='signed'
4. ✅ Trigger creates entry in ehrbase_sync_queue
5. ✅ Sync worker processes queue item within 5 minutes
6. ✅ SOAP note synced to EHRbase (ehr_sync_status='completed')
7. ✅ Provider can verify sync status in UI

---

## Questions?

Refer to:
- `/EHR_SYNC_IMPLEMENTATION_COMPLETE.md` - Technical overview
- `/CLAUDE.md` - Project standards and patterns
- EHRbase docs: https://documentation.ehrbase.org/
- Supabase docs: https://supabase.com/docs
