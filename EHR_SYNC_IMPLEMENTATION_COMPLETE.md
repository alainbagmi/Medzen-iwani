# EHR Sync Implementation Complete

## Summary

The complete post-call SOAP note workflow with automatic EHRbase sync has been implemented. Here's what was done:

## 1. Dialog Widget Compilation Fixed

**File:** `/lib/custom_code/widgets/post_call_clinical_notes_dialog.dart`

Fixed critical compilation errors:
- ✅ Removed unused `dart:convert` import
- ✅ Added missing `plan` field to SOAPNoteData model
- ✅ Fixed `_soapData.planController` references (should be `_soapData.plan`)
- ✅ Replaced `FFAppState().UserFullName` with dynamic `_providerName` fetched from database
- ✅ Removed unused `_errorMessage` field
- ✅ Added `_fetchProviderName()` method to load provider info on init

**Status:** File now compiles successfully with only style warnings (no functional errors)

## 2. Database Migration for Extended SOAP Notes

**File:** `/supabase/migrations/20260116000000_extend_soap_notes_for_post_call_workflow.sql`

Created comprehensive migration that:
- Adds `provider_id` and `patient_id` foreign keys
- Adds post-call signing fields: `signed_at`, `signed_by`
- Adds `transcript` field to store call transcript
- Adds `full_data` JSONB field for complete SOAP structure
- Adds EHR sync tracking fields: `ehr_sync_status`, `synced_at`, `ehr_sync_error`
- Creates trigger function `queue_signed_soap_note_for_sync()` that:
  - Automatically queues signed SOAP notes to `ehrbase_sync_queue` table
  - Validates patient has EHR ID before queueing
  - Prevents duplicate queue entries
  - Snapshots complete SOAP data for audit trail
- Creates indexes for efficient queries on new columns

**Trigger Logic:**
```
When status changes to 'signed':
  → Check if patient has EHR ID
  → Create snapshot of SOAP data
  → Insert into ehrbase_sync_queue table
  → Mark sync status as 'pending'
  → Edge functions will process asynchronously
```

## 3. Background Sync Queue Worker

**File:** `/supabase/functions/process-ehr-sync-queue/index.ts`

Created new edge function to process pending EHR sync items:

**Features:**
- Fetches up to 10 pending/failed items per run
- Implements retry logic (up to 5 retries per item)
- Calls existing `sync-to-ehrbase` edge function for each item
- Updates sync queue status based on results
- Updates source table (e.g., `soap_notes`) with sync status
- Comprehensive logging for debugging

**How it works:**
```
1. Fetch items where sync_status IN ('pending', 'failed') AND retry_count < 5
2. For each item:
   - Mark as 'processing'
   - Call sync-to-ehrbase function
   - If success → mark 'completed', update soap_notes.ehr_sync_status = 'completed'
   - If failure → increment retry_count, keep status 'failed'
   - If max retries exceeded → mark status 'error'
3. Return summary of processing results
```

**Deployment:** Deploy with: `npx supabase functions deploy process-ehr-sync-queue`

## 4. Complete Post-Call SOAP Workflow

### Step 1: Call Finalization
- Video call ends
- `finalize-video-call` edge function:
  - Stops transcription capture
  - Merges live captions
  - Builds speaker map
  - Waits for SOAP generation (or timeout after 40s)
  - Returns transcript + SOAP data to client

### Step 2: Provider Review Dialog
- Dialog displays with:
  - Raw transcript (reference panel, 30% width)
  - 6 editable SOAP tabs (70% width): Encounter, Subjective, Objective, Assessment, Plan, Sign-off
  - Speech-to-text on key fields
  - Provider can edit/amend AI-generated content or start fresh

### Step 3: Save to Database
- Provider clicks "Save & Sign"
- Dialog collects all form data into SOAPNoteData
- Saves to `soap_notes` table with:
  - Structured fields: chief_complaint, subjective, objective, assessment, plan
  - Full JSON snapshot: full_data
  - Status: 'signed'
  - Timestamps: created_at, signed_at
  - Transcript attachment
  - Provider info: provider_id, signed_by

### Step 4: Automatic EHR Sync
- Database trigger activates on `status = 'signed'`
- `queue_signed_soap_note_for_sync()` function:
  - Validates patient has EHR ID
  - Creates data snapshot with all SOAP info
  - Inserts into `ehrbase_sync_queue` as 'pending'
  - Updates `soap_notes.ehr_sync_status = 'pending'`

### Step 5: Background Processing
- `process-ehr-sync-queue` function runs periodically:
  - Fetches pending queue items
  - Calls `sync-to-ehrbase` for each item
  - Transforms SOAP data to OpenEHR format
  - Creates composition in EHRbase
  - Updates queue status to 'completed'
  - Updates `soap_notes.ehr_sync_status = 'completed'`
  - Marks `soap_notes.synced_at` with timestamp

## 5. Scheduler Configuration Required

**To make sync automatic, you need to set up periodic execution:**

### Option A: External Cron Job (Recommended)
```bash
# Call every 5 minutes via cron scheduler (e.g., GitHub Actions, cloud scheduler)
curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/process-ehr-sync-queue" \
  -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d '{}'
```

### Option B: Manual Testing
```bash
# Test the queue processor
npx supabase functions serve
# Then in another terminal:
curl -X POST "http://localhost:54321/functions/v1/process-ehr-sync-queue"
```

## 6. Data Flow Diagram

```
Provider completes call
    ↓
Dialog pops up with transcript + SOAP tabs
    ↓
Provider edits/reviews SOAP sections
    ↓
Provider signs and saves
    ↓
soap_notes table INSERT/UPDATE
    ↓
Database trigger fires
    ↓
queue_signed_soap_note_for_sync() function
    ↓
ehrbase_sync_queue table INSERT (status='pending')
    ↓
[Async background processing]
    ↓
process-ehr-sync-queue function runs
    ↓
Calls sync-to-ehrbase edge function
    ↓
Creates OpenEHR composition in EHRbase
    ↓
Updates ehrbase_sync_queue (status='completed')
    ↓
Updates soap_notes (ehr_sync_status='completed', synced_at=timestamp)
```

## 7. Files Modified/Created

### Modified:
- `/lib/custom_code/widgets/post_call_clinical_notes_dialog.dart` - Fixed compilation errors
- `/pubspec.yaml` - Added speech_to_text dependency (already done)

### Created:
- `/supabase/migrations/20260116000000_extend_soap_notes_for_post_call_workflow.sql` - Schema + triggers
- `/supabase/functions/process-ehr-sync-queue/index.ts` - Background worker

## 8. Deployment Steps

1. **Update database schema:**
   ```bash
   npx supabase migration up
   # Or specific migration:
   npx supabase migration up --name 20260116000000_extend_soap_notes_for_post_call_workflow
   ```

2. **Deploy new edge function:**
   ```bash
   npx supabase functions deploy process-ehr-sync-queue
   ```

3. **Set up periodic scheduler:** (External, not included in this task)
   - GitHub Actions
   - Cloud Scheduler (Google Cloud)
   - AWS Lambda with EventBridge
   - Or any HTTP cron service

4. **Verify deployment:**
   ```bash
   # Check migration applied
   npx supabase migration list

   # Test the queue processor
   curl -X POST "https://noaeltglphdlkbflipit.supabase.co/functions/v1/process-ehr-sync-queue" \
     -H "Authorization: Bearer $ANON_KEY" \
     -H "Content-Type: application/json"
   ```

## 9. Error Handling & Monitoring

### Queue Monitoring:
```sql
-- Check pending items
SELECT id, table_name, record_id, retry_count, error_message
FROM ehrbase_sync_queue
WHERE sync_status IN ('pending', 'failed');

-- Check completed syncs
SELECT id, synced_at, ehr_sync_status
FROM soap_notes
WHERE status = 'signed';
```

### Retry Strategy:
- Items with < 5 retries are retried
- Failed items update `soap_notes.ehr_sync_error` field
- After 5 retries, status moves from 'failed' to 'error'
- Manual intervention may be needed for 'error' status items

## 10. Testing Workflow

1. **Unit Test:** Run dialog compilation check
   ```bash
   dart analyze lib/custom_code/widgets/post_call_clinical_notes_dialog.dart
   ```

2. **Integration Test:**
   - Complete a video call
   - Dialog should pop up with SOAP entry form
   - Fill in SOAP sections
   - Click "Save & Sign"
   - Check `soap_notes` table for new record with `status='signed'`
   - Check `ehrbase_sync_queue` for new pending item
   - Run `process-ehr-sync-queue` function
   - Verify sync completed and `soap_notes.ehr_sync_status='completed'`

3. **Error Test:**
   - Manually insert invalid patient_id into SOAP note
   - Trigger should skip (patient has no EHR ID)
   - Check logs for "No EHR ID for patient" message

## 11. Next Steps (Not Included)

- [ ] Set up external cron scheduler to run `process-ehr-sync-queue` every 5 minutes
- [ ] Add UI feedback to provider showing sync status ("Syncing to EHR..." → "Synced ✓")
- [ ] Create admin dashboard to monitor sync queue status
- [ ] Add email notifications for sync failures
- [ ] Create provider bulk action to manually re-sync failed notes

## Summary

The complete post-call SOAP note workflow is now implemented with:
- ✅ Provider-friendly dialog with 6 SOAP sections
- ✅ Speech-to-text for voice dictation
- ✅ Automatic queuing for EHR sync
- ✅ Background worker to process sync queue
- ✅ Retry logic for robustness
- ✅ Comprehensive error handling
- ✅ Full audit trail via transcript and full_data JSON

The system is ready for deployment and testing. Only missing piece is the external cron scheduler which should be configured separately based on your infrastructure.
