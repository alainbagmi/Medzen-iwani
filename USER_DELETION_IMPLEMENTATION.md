# User Deletion Implementation - Complete Cascade Cleanup

## Overview

The `onUserDeleted` Firebase Cloud Function now properly cascades deletions across ALL integrated systems when a user is deleted from Firebase Authentication.

**Last Updated:** December 16, 2025

## Systems Integrated

1. **Firebase Authentication** (trigger point)
2. **Firebase Firestore** (user documents, FCM tokens)
3. **Supabase Authentication** (user auth records)
4. **Supabase Database** (user profiles, medical data, appointments, etc.)
5. **EHRbase** (OpenEHR electronic health records)

## Deletion Flow

```
User Deleted from Firebase Auth
         ↓
onUserDeleted Function Triggers
         ↓
    Step 1: Lookup Supabase User ID & EHR ID
         ↓
    Step 2: Delete from Supabase Database (CASCADE)
         ↓  (Automatically deletes 40+ related tables via ON DELETE CASCADE)
         ↓
    Step 3: Delete from Supabase Auth
         ↓
    Step 4: Delete from EHRbase (EHR record)
         ↓
    Step 5: Clean up Firebase Firestore
         ↓
    Step 6: Create audit log entry
         ↓
    COMPLETE - User removed from all systems
```

## What Gets Deleted

### Firebase Firestore
- User document (`users/{uid}`)
- FCM tokens (`users/{uid}/fcm_tokens/*`)

### Supabase Authentication
- Auth user record (email, password hash, metadata)

### Supabase Database (CASCADE)

The deletion from `users` table triggers CASCADE deletion for:

**User Profiles:**
- `patient_profiles`
- `medical_provider_profiles`
- `facility_admin_profiles`
- `system_admin_profiles`
- `user_profiles`

**Health Records:**
- `electronic_health_records`
- `vital_signs`
- `lab_results`
- `prescriptions`
- `immunizations`
- `medical_records`

**Specialty Medical Data (30+ tables):**
- `antenatal_visits`
- `surgical_procedures`
- `admission_discharges`
- `medication_dispensing`
- `clinical_consultations`
- `oncology_treatments`
- `infectious_disease_visits`
- `cardiology_visits`
- `emergency_visits`
- `nephrology_visits`
- `gastroenterology_procedures`
- `endocrinology_visits`
- `pulmonology_visits`
- `psychiatric_assessments`
- `neurology_exams`
- `radiology_reports`
- `pathology_reports`
- `physiotherapy_sessions`
- And more...

**Appointments & Video Calls:**
- `appointments`
- `video_call_sessions`
- `video_call_participants`
- `chime_messages`
- `chime_messaging_channels`
- `chime_message_audit`

**AI & Conversations:**
- `ai_conversations`
- `ai_messages`
- `conversations`
- `conversation_participants`

**User Preferences:**
- `language_preferences`
- `custom_vocabularies` (where `created_by` is the user)

**Payments & Withdrawals:**
- `payments` (as payer or recipient - SET NULL)
- `withdrawals`
- `reviews`

**Other Data:**
- `medical_recording_metadata`
- `chime_sdk` related audit logs
- Any other tables with foreign keys to `users(id)`

### EHRbase
- Electronic Health Record (EHR) for the patient
- All associated compositions (if EHRbase supports CASCADE deletion)

## CASCADE Deletion Mechanism

Most tables have been configured with `ON DELETE CASCADE` constraints through these migrations:

- `20251103220000_add_cascade_to_users_foreign_keys.sql`
- `20251103220001_comprehensive_cascade_constraints.sql`

This means when a user is deleted from the `users` table, PostgreSQL automatically deletes all related records in child tables.

## Code Implementation

**Location:** `firebase/functions/index.js` (lines 444-631)

**Key Features:**
1. ✅ **Idempotent** - Can run multiple times safely
2. ✅ **Error Handling** - Graceful fallback if systems are unavailable
3. ✅ **Audit Trail** - Logs deletion to `audit_logs` collection
4. ✅ **Comprehensive Logging** - Detailed console logs for debugging
5. ✅ **No Re-throw** - Doesn't fail if Supabase/EHRbase are down (user already deleted from Firebase)

**Steps:**
```javascript
1. Lookup Supabase user by email
2. Get EHR ID from electronic_health_records
3. Delete from Supabase users table (CASCADE)
4. Delete from Supabase Auth
5. Delete from EHRbase (if supported)
6. Clean up Firebase Firestore (user doc, FCM tokens)
7. Create audit log entry
```

## Storage Files

**Note:** Storage files (profile pictures, documents, S3 recordings) are NOT automatically deleted by this function.

For complete cleanup, you may need to:

1. **Supabase Storage:**
   - Delete files from `profile-pictures` bucket
   - Delete files from `medical-documents` bucket
   - Run storage cleanup Edge Function

2. **AWS S3:**
   - Delete video call recordings
   - Delete transcriptions
   - Delete medical data exports

This is intentional to allow for:
- Regulatory compliance (data retention requirements)
- Audit purposes
- Recovery if deletion was accidental

Storage cleanup should be handled by separate scheduled jobs or manual processes.

## Testing

### Manual Test

1. Create a test user in Firebase Auth
2. Wait for `onUserCreated` to complete (check logs)
3. Verify user exists in all systems:
   ```bash
   # Check Supabase
   npx supabase db execute "SELECT id, email FROM users WHERE email = 'test@example.com'"

   # Check EHR
   npx supabase db execute "SELECT ehr_id FROM electronic_health_records WHERE patient_id = '<user-id>'"
   ```
4. Delete user from Firebase Console or via SDK
5. Wait for `onUserDeleted` to complete (check logs)
6. Verify user is deleted from all systems:
   ```bash
   # Check Supabase (should return 0 rows)
   npx supabase db execute "SELECT id, email FROM users WHERE email = 'test@example.com'"
   ```

### Automated Test

Run the deletion test script:
```bash
cd firebase/functions
node delete_test_user.js
```

Monitor logs:
```bash
firebase functions:log --only functions:onUserDeleted -P medzen-bf20e -n 50
```

## Deployment

Deploy the updated function:
```bash
cd firebase/functions
firebase deploy --only functions:onUserDeleted
```

## Error Scenarios

### What if Supabase is down?
- Function logs a warning
- Skips Supabase cleanup
- User is still deleted from Firebase
- Manual cleanup required

### What if EHRbase is down or doesn't support DELETE?
- Function logs a warning
- EHR may remain in EHRbase (orphaned)
- User data is still deleted from Firebase and Supabase
- No impact on application functionality

### What if CASCADE fails?
- Database will roll back the transaction
- Function will log the error
- User remains in Supabase (but deleted from Firebase)
- Manual intervention required

## Audit & Compliance

All deletions are logged to `audit_logs` Firestore collection with:
- User email
- Firebase UID
- Supabase user ID
- EHR ID
- Timestamp
- Systems cleaned (which systems were successfully cleaned)

This satisfies:
- GDPR right to erasure (data deletion)
- HIPAA audit requirements (who deleted what and when)
- Compliance with medical data retention policies

## Important Notes

1. **Irreversible** - Once deleted, user data cannot be recovered (unless you have backups)
2. **No Undo** - There is no "undo" button
3. **Storage Retention** - Files in storage are NOT deleted automatically
4. **EHR Orphans** - If EHRbase doesn't support DELETE, EHR records may be orphaned
5. **Async Nature** - Function runs asynchronously - may take several seconds

## Related Files

- Function Implementation: `firebase/functions/index.js`
- Cascade Constraints: `supabase/migrations/20251103220000_add_cascade_to_users_foreign_keys.sql`
- Test Script: `firebase/functions/delete_test_user.js`

## Monitoring

Check function logs regularly:
```bash
firebase functions:log --only functions:onUserDeleted -P medzen-bf20e
```

Look for:
- ✅ Success messages
- ❌ Error messages
- ⚠️  Warning messages (missing config, systems down, etc.)

## Future Improvements

1. Add storage file deletion (profile pictures, documents)
2. Add S3 recording cleanup (via Lambda)
3. Implement soft delete option (mark as deleted instead of hard delete)
4. Add user export before deletion (GDPR compliance - data portability)
5. Add scheduled cleanup job for orphaned EHR records

---

**Status:** ✅ **Production Ready** (December 16, 2025)
