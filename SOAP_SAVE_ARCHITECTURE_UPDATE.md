# SOAP Note Save Architecture Update

**Date:** January 17, 2026
**Version:** 2.0
**Status:** IMPLEMENTED

---

## Objective

Implement a database-first persistence model for SOAP note saving that prioritizes immediate data persistence to the Supabase database before any external system synchronization.

---

## Architecture Changes

### Previous Architecture (v1.0)
```
Provider clicks "Save to EHR" button
                    ↓
        Save SOAP note to database (awaited)
                    ↓
    Fire async: Update cumulative patient record
                    ↓
            Close dialog
```

**Problem:** The button said "Save to EHR" but EHR sync was not implemented, leading to confusion about what "save" meant.

---

### New Architecture (v2.0) - Database First

```
Provider clicks "Sign & Save Note" button
                    ↓
    ┌─────────────────────────────────────────┐
    │  PHASE 1: DATABASE SAVE (BLOCKING)      │
    │  Primary operation - must complete      │
    │  before closing dialog                  │
    │                                          │
    │  ✓ Create/Update SOAP note in          │
    │    supabase.soap_notes table            │
    │  ✓ Mark status as 'signed'              │
    │  ✓ Store AI-generated data as JSON     │
    └─────────────────────────────────────────┘
                    ↓
        If database save SUCCEEDS:
                    ↓
    ┌─────────────────────────────────────────┐
    │  PHASE 2: ASYNC BACKGROUND OPS          │
    │  Secondary operations - NON-BLOCKING    │
    │  If they fail, logged but don't prevent │
    │  provider from closing dialog           │
    │                                          │
    │  ✓ Sync SOAP note to EHRbase            │
    │    (fire-and-forget via HTTP POST)     │
    │                                          │
    │  ✓ Update cumulative patient record    │
    │    (fire-and-forget via HTTP POST)     │
    └─────────────────────────────────────────┘
                    ↓
        Call widget.onSaved callback
                    ↓
            Close dialog & return
        (Background ops continue async)
```

---

## Why This Architecture?

### 1. **Data Persistence Priority**
- SOAP note saved to Supabase = permanent record
- Even if EHR sync fails, data is safely in database
- Database is source of truth
- EHR sync is secondary optimization

### 2. **Provider Workflow Protection**
- Provider not blocked by EHR synchronization latency
- If EHRbase is slow/unavailable, doesn't delay provider closing note
- Clinical efficiency maintained

### 3. **Fault Tolerance**
- EHR sync failures don't cause note save failures
- Failed EHR syncs can be retried via background job
- Cumulative record updates can be re-triggered if needed
- No data loss

### 4. **Clear Semantics**
- Button text "Sign & Save Note" indicates primary action (save to database)
- EHR sync happens implicitly in background
- Cumulative record update happens implicitly in background

---

## Implementation Details

### File: `lib/custom_code/widgets/post_call_clinical_notes_dialog.dart`

#### Method 1: `_saveNote()` (Updated)

**Changes:**
- **Phase 1 (Blocking):** Database save with clear comments indicating this is the critical operation
- **Phase 2 (Async):** Fire background operations after database save succeeds
- Only proceeds to close dialog after database save completes
- EHR sync and cumulative record updates are non-blocking

```dart
Future<void> _saveNote() async {
  // PHASE 1: DATABASE SAVE (BLOCKING - PRIMARY)
  // Awaits creation/update of SOAP note in supabase.soap_notes
  if (_soapNoteId != null) {
    await SupaFlow.client.from('soap_notes').update({...});
  } else {
    final result = await SupaFlow.client.from('soap_notes').insert({...});
    _soapNoteId = result['id'];
  }

  // PHASE 2: ASYNC BACKGROUND (NON-BLOCKING - SECONDARY)
  if (_soapNoteId != null) {
    _syncToEhrInBackground();                    // New method
    _updatePatientMedicalRecordInBackground();   // Existing method
  }

  // Close dialog only after Phase 1 succeeds
  Navigator.of(context).pop({...});
}
```

#### Method 2: `_syncToEhrInBackground()` (New)

**Purpose:** Synchronize SOAP note to EHRbase asynchronously

**Key Features:**
- Calls `sync-to-ehrbase` edge function via HTTP POST
- Passes `soapNoteId`, `patientId`, and `appointmentId`
- Uses Firebase JWT authentication (x-firebase-token header)
- Fire-and-forget pattern via `unawaited()`
- Logs success/failure for monitoring but doesn't throw exceptions
- If EHRbase is unavailable, error is logged but provider workflow continues

```dart
Future<void> _syncToEhrInBackground() async {
  try {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
    // HTTP POST to sync-to-ehrbase edge function
    unawaited(
      http.post(
        Uri.parse('$supabaseUrl/functions/v1/sync-to-ehrbase'),
        headers: {
          'x-firebase-token': token,
          // ...
        },
        body: jsonEncode({
          'soapNoteId': _soapNoteId,
          'patientId': widget.patientId,
          'appointmentId': widget.appointmentId,
        }),
      ).then((response) {
        if (response.statusCode == 200) {
          debugPrint('✅ SOAP note synced to EHRbase');
        } else {
          debugPrint('⚠️ Failed to sync: ${response.body}');
        }
      }).catchError((e) {
        debugPrint('⚠️ EHR sync failed: $e');
      }),
    );
  } catch (e) {
    debugPrint('⚠️ Non-blocking error: $e');
  }
}
```

#### Method 3: `_updatePatientMedicalRecordInBackground()` (Unchanged)

**Purpose:** Update cumulative patient medical record asynchronously

**Note:** Already existed in previous implementation. Continues to work as fire-and-forget after database save completes.

---

## UI Changes

### Button Text Update
- **Previous:** "Save to EHR"
- **New:** "Sign & Save Note"

**Rationale:** The new text is more accurate - the primary operation is saving the note to the database. EHR sync and cumulative record updates happen automatically in the background as secondary operations.

---

## Data Flow

### Request Flow
```
post_call_clinical_notes_dialog.dart
  └─ _saveNote()
      ├─ PHASE 1: Supabase Database
      │   └─ SupaFlow.client.from('soap_notes').insert/update()
      │       └─ Persists to Postgres (BLOCKING, AWAITED)
      │
      └─ PHASE 2: Background Operations (if Phase 1 succeeds)
          ├─ _syncToEhrInBackground()
          │   └─ HTTP POST → sync-to-ehrbase edge function
          │       └─ Supabase Edge Functions (Deno)
          │           └─ sync-to-ehrbase processes SOAP data
          │               └─ Submits to EHRbase OpenEHR system
          │                   └─ EU-1 EHRbase instance
          │
          └─ _updatePatientMedicalRecordInBackground()
              └─ HTTP POST → update-patient-medical-record edge function
                  └─ Supabase Edge Functions (Deno)
                      └─ Merges SOAP into cumulative record
                          └─ Updates patient_profiles JSONB
```

### Response Flow

1. **Phase 1 Success:**
   - SOAP note saved to `soap_notes` table
   - Dialog closes immediately
   - Provider workflow unblocked

2. **Phase 2 Success:**
   - EHRbase receives SOAP data (logged: "✅ SOAP note synced to EHRbase")
   - Cumulative record updated (logged: "✅ Patient medical record updated")
   - Background tasks complete without blocking provider

3. **Phase 1 Failure:**
   - Error shown to provider via SnackBar
   - Dialog remains open
   - Provider can retry or discard

4. **Phase 2 Failure:**
   - Error logged (logged: "⚠️ Failed to sync: ...")
   - Dialog already closed (user never sees error)
   - Data remains in database
   - Can be retried via background job queue

---

## Error Handling

### Phase 1 (Database Save) - Blocking Errors
| Error | Handling | Result |
|-------|----------|--------|
| Null SOAP data | Show SnackBar "No SOAP data to save" | Dialog stays open, user can retry |
| Database insert fails | Catch exception, show error SnackBar | Dialog stays open, user can edit/retry |
| Database update fails | Catch exception, show error SnackBar | Dialog stays open, user can edit/retry |

### Phase 2 (Background Sync) - Non-Blocking Errors
| Operation | Error | Handling | Result |
|-----------|-------|----------|--------|
| EHR sync | HTTP 500 | Log warning, continue | Dialog closes, data in database, can retry later |
| EHR sync | Network timeout | Log error, continue | Dialog closes, data in database, can retry later |
| EHR sync | Invalid token | Log warning, continue | Dialog closes, data in database, human review |
| Cumulative update | HTTP 500 | Log warning, continue | Dialog closes, data in database, can retry later |

**Philosophy:** Phase 2 failures never block the provider. All errors are logged for monitoring/alerting.

---

## Testing Checklist

### Unit Tests
- [ ] Verify `_saveNote()` awaits database operation before proceeding
- [ ] Verify Phase 2 async calls fire AFTER Phase 1 success
- [ ] Verify dialog closes only on Phase 1 success
- [ ] Verify errors in Phase 1 prevent dialog close
- [ ] Verify Phase 2 errors don't throw exceptions

### Integration Tests
- [ ] Complete call → Fill SOAP form → Click "Sign & Save Note"
- [ ] Verify SOAP note created in `soap_notes` table within 1 second
- [ ] Verify EHR sync logs appear within 5 seconds
- [ ] Verify cumulative record update logs appear within 5 seconds
- [ ] Verify dialog closes immediately after Phase 1 succeeds
- [ ] Simulate EHRbase offline → Verify note still saved, error logged
- [ ] Check database logs for proper transaction order

### End-to-End Tests
1. Provider starts video call with patient
2. Call completes, post-call dialog shows
3. SOAP data auto-populated from transcript
4. Provider clicks "Sign & Save Note"
5. Dialog closes within 2 seconds
6. Check database: SOAP note exists
7. Check Supabase logs: EHR sync triggered
8. Check Supabase logs: Cumulative record updated
9. Start new call with same patient
10. Pre-call history includes data from previous SOAP note

---

## Monitoring

### Key Logs to Watch

**Success Signals:**
```
✅ SOAP note synced to EHRbase in background
✅ Patient medical record updated in background
```

**Warning Signals:**
```
⚠️ Failed to sync to EHRbase: <error>
⚠️ Background EHR sync failed: <error>
⚠️ Warning: Failed to update patient record: <error>
```

**Failure Signals:**
```
Error saving SOAP note: <error>  // Phase 1 failure - shown to provider
⚠️ Non-blocking error syncing to EHRbase: <error>  // Phase 2 failure - logged only
```

### Metrics to Track

| Metric | Target | Tool |
|--------|--------|------|
| Database save latency | < 500ms | Supabase query logs |
| EHR sync latency | < 3s | Edge function logs |
| Cumulative record update latency | < 2s | Edge function logs |
| EHR sync failure rate | < 1% | Cloud monitoring |
| Dialog close latency | < 2s | Client logs |

---

## Deployment Notes

### Prerequisites
- `sync-to-ehrbase` edge function must be deployed (already exists)
- `update-patient-medical-record` edge function must be deployed (already exists)
- EHRbase endpoint must be configured (environment variables)
- Firebase authentication must be configured

### Deployment Steps
1. Update `post_call_clinical_notes_dialog.dart` with new methods (✅ DONE)
2. Test locally on emulator
3. Run comprehensive E2E test
4. Deploy to production (standard Flutter build process)
5. Monitor Supabase logs for first 24 hours
6. Monitor EHR sync success/failure rates

### Rollback Plan
If issues found:
1. Revert to previous git commit (git revert)
2. Dialog will continue with fire-and-forget cumulative record update
3. EHR sync won't be called (no harm, data still in database)
4. Investigate root cause before re-deploying

---

## Summary

The new **Database-First Persistence Architecture** ensures:

✅ **Data Safety:** SOAP notes are immediately persisted to Supabase
✅ **Provider Efficiency:** No blocking on EHR synchronization
✅ **Fault Tolerance:** EHR sync failures don't prevent note saving
✅ **Clear Semantics:** "Sign & Save Note" button accurately describes primary action
✅ **Scalability:** Background jobs can retry async operations without impacting provider workflow

**Status:** ✅ IMPLEMENTED AND READY FOR TESTING
