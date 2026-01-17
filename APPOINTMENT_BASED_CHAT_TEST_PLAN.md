# Appointment-Based Chat Test Plan

**Date:** December 18, 2025
**Feature:** Appointment-Based Chat with Provider-Only Initiation
**Status:** Ready for Testing

## Overview

This test plan validates the new appointment-based chat architecture where:
- Chat is tied to specific appointments (not direct person-to-person messaging)
- Only providers can send messages (patients are read-only)
- Chat is only available during active video calls
- Provider role is displayed instead of medical specialty
- All widget files have been migrated from `providerSpecialty` to `providerRole`

---

## Prerequisites

### Database Schema Changes
- ✅ `appointment_overview` view includes `provider_role` field
- ✅ `video_call_sessions` table has `is_call_active` and `ended_at` columns
- ✅ `chime_messages` table has `appointment_id` column
- ✅ RLS policies enforce provider-only sending

### Code Changes
- ✅ Widget files updated to use `providerRole` (11 occurrences in 3 files)
- ✅ `ChimeMeetingEnhanced` widget updated with `appointmentId` parameter
- ✅ Chat functions updated to use `appointment_id` instead of `channel_id`

### Test Accounts Needed
1. **Provider Account** - Doctor/Nurse with active appointments
2. **Patient Account** - Patient with scheduled appointments
3. **System Admin** - For verifying database state

---

## Test Cases

### 1. Database Schema Verification

**Test 1.1: Verify appointment_overview has provider_role**
```sql
-- Run in Supabase SQL Editor
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'appointment_overview'
  AND column_name = 'provider_role';

-- Expected: Returns one row showing provider_role column exists
```

**Test 1.2: Verify video_call_sessions has new columns**
```sql
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'video_call_sessions'
  AND column_name IN ('is_call_active', 'ended_at');

-- Expected: Returns 2 rows
-- is_call_active: boolean, default TRUE
-- ended_at: timestamp with time zone
```

**Test 1.3: Verify chime_messages has appointment_id**
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'chime_messages'
  AND column_name = 'appointment_id';

-- Expected: Returns one row showing UUID type with FK constraint
```

**Test 1.4: Verify RLS policies exist**
```sql
SELECT policyname, tablename, cmd
FROM pg_policies
WHERE tablename = 'chime_messages'
  AND policyname LIKE '%provider%';

-- Expected: Shows policy "Only providers can send messages during active calls"
```

---

### 2. Provider Role Display

**Test 2.1: Join Call Page Shows Provider Role**
- Navigate to: Join Call page
- Select an appointment with provider
- **Expected:** Provider info shows "Doctor [Name]" or "Nurse [Name]", not specialty
- **Verify:** Line 473 in `join_call_widget.dart` displays `providerRole`

**Test 2.2: Appointments List Shows Provider Role**
- Navigate to: Appointments page
- View upcoming appointments list
- **Expected:** For appointments without facility, shows provider role instead of specialty
- **Verify:** Line 626 in `appointments_widget.dart` uses conditional with `providerRole`

**Test 2.3: Patient Landing Page Shows Provider Role**
- Login as: Patient
- Navigate to: Landing page
- View appointments section
- **Expected:** Shows "Role: Doctor" or "Role: Nurse" instead of "Specialty: Cardiology"
- **Verify:** Line 907 in `patient_landing_page_widget.dart`

---

### 3. Video Call Chat Functionality

**Test 3.1: Provider Can Send Messages During Active Call**
1. Login as **Provider**
2. Join video call for an appointment
3. Open chat panel
4. Send a test message: "Hello from provider"
5. **Expected:**
   - Message appears in chat immediately
   - Message saved to database with correct `appointment_id`
   - Chat title shows "Consultation MM/YYYY Doctor [Name]"

**Test 3.2: Patient Cannot Send Messages**
1. Login as **Patient** (in separate browser/device)
2. Join the same video call
3. Open chat panel
4. **Expected:**
   - Chat messages from provider are visible
   - Message input field is **HIDDEN** or **DISABLED**
   - Chat is read-only for patient
   - No send button visible

**Test 3.3: Messages Persist Across Page Refresh**
1. During active call, provider sends 3 messages
2. Refresh the page
3. Rejoin the call
4. Open chat
5. **Expected:**
   - All 3 messages still visible
   - Messages loaded from database via `appointment_id`
   - Chronological order preserved

**Test 3.4: Chat Title Format**
- During call, check chat header
- **Expected Format:** "Consultation 12/2025 Doctor Brian Ketum"
- Shows: Month/Year + Provider Role + Provider Name

---

### 4. Call Status and Chat Access

**Test 4.1: Chat Only Available During Active Calls**
1. Before starting call: Verify chat not accessible
2. Start video call: Chat becomes available
3. End call: Chat becomes read-only
4. **Expected:** `is_call_active` flag controls chat availability

**Test 4.2: Multiple Appointments Don't Mix Messages**
1. Provider has 2 appointments with different patients
2. Send messages in Call 1
3. Join Call 2
4. **Expected:**
   - Call 2 chat is empty (separate `appointment_id`)
   - Call 1 messages not visible in Call 2
   - Each appointment has isolated chat history

**Test 4.3: Verify is_call_active Flag**
```sql
-- Check call status during active call
SELECT appointment_id, is_call_active, created_at, ended_at
FROM video_call_sessions
WHERE appointment_id = 'YOUR_APPOINTMENT_ID';

-- Expected during call: is_call_active = TRUE, ended_at = NULL
-- Expected after call: is_call_active = FALSE, ended_at = timestamp
```

---

### 5. Database RLS Policy Validation

**Test 5.1: Provider Can Insert Messages**
```sql
-- Run as authenticated provider user
INSERT INTO chime_messages (
  appointment_id,
  sender_id,
  message_text,
  created_at
) VALUES (
  'appointment_uuid_here',
  auth.uid(),
  'Test message',
  NOW()
);

-- Expected: Success (provider can insert)
```

**Test 5.2: Patient Cannot Insert Messages**
```sql
-- Run as authenticated patient user
INSERT INTO chime_messages (
  appointment_id,
  sender_id,
  message_text,
  created_at
) VALUES (
  'appointment_uuid_here',
  auth.uid(),
  'Test message',
  NOW()
);

-- Expected: ERROR - RLS policy blocks patient inserts
```

**Test 5.3: Both Can Read Messages**
```sql
-- Run as either provider or patient
SELECT * FROM chime_messages
WHERE appointment_id = 'appointment_uuid_here';

-- Expected: Success - both can view messages from their appointments
```

---

### 6. Helper Functions

**Test 6.1: is_provider_in_appointment() Function**
```sql
-- As provider
SELECT is_provider_in_appointment('appointment_uuid_here');
-- Expected: TRUE

-- As patient
SELECT is_provider_in_appointment('appointment_uuid_here');
-- Expected: FALSE
```

**Test 6.2: is_call_active_for_appointment() Function**
```sql
-- During active call
SELECT is_call_active_for_appointment('appointment_uuid_here');
-- Expected: TRUE

-- After call ended
SELECT is_call_active_for_appointment('appointment_uuid_here');
-- Expected: FALSE
```

**Test 6.3: end_video_call() Function**
```sql
-- As provider
SELECT end_video_call('appointment_uuid_here');
-- Expected: Success - sets is_call_active=FALSE, ended_at=NOW()

-- As patient
SELECT end_video_call('appointment_uuid_here');
-- Expected: ERROR - "Only providers can end calls"
```

---

### 7. Edge Cases

**Test 7.1: Appointment Without Facility**
- View appointment with provider but no facility
- **Expected:** Shows provider role, not facility address
- **UI Logic:** `facilityId == null ? providerRole : facilityAddress`

**Test 7.2: Provider With Multiple Roles**
- Provider has role "Doctor"
- **Expected:** Always shows "Doctor [Name]", consistent across all pages

**Test 7.3: Long Provider Names**
- Provider: "Doctor Christopher Alexander Montgomery"
- **Expected:** Chat title truncates gracefully or wraps
- **Verify:** UI doesn't break with long names

**Test 7.4: Special Characters in Messages**
- Send message with: `<script>alert('test')</script>`
- **Expected:** Message escaped properly, no XSS
- **Verify:** HTML entities encoded in database

**Test 7.5: Concurrent Messaging**
- Provider sends 3 messages rapidly
- **Expected:**
  - All messages saved with unique IDs
  - All messages appear in chronological order
  - No duplicate messages

---

## Success Criteria

### Critical (Must Pass)
- ✅ Provider role displays instead of specialty in all widget files
- ✅ Only providers can send chat messages
- ✅ Patients can view but not send messages
- ✅ Chat messages linked to appointments, not users
- ✅ RLS policies enforce provider-only sending
- ✅ Chat available only during active calls

### Important (Should Pass)
- ✅ Chat title shows correct format with provider role
- ✅ Messages persist across page refreshes
- ✅ Multiple appointments have isolated chat histories
- ✅ Call status tracking works (is_call_active flag)
- ✅ Helper functions work correctly

### Nice to Have (Can Fix Later)
- ⚠️ Chat UI gracefully handles long names
- ⚠️ Real-time updates without manual refresh
- ⚠️ Message read receipts
- ⚠️ Typing indicators

---

## Rollback Plan

If critical issues found during testing:

1. **Revert Widget Files:**
   ```bash
   git checkout HEAD~1 lib/home_pages/join_call/join_call_widget.dart
   git checkout HEAD~1 lib/all_users_page/appointments/appointments_widget.dart
   git checkout HEAD~1 lib/patients_folder/patient_landing_page/patient_landing_page_widget.dart
   ```

2. **Revert Database Migration:**
   ```sql
   -- Recreate appointment_overview without provider_role
   -- Remove appointment_id from chime_messages
   -- Drop new RLS policies
   -- Remove is_call_active columns
   ```

3. **Restore Previous Widget:**
   - Revert `ChimeMeetingEnhanced` to use `channel_id` instead of `appointment_id`

---

## Testing Checklist

- [ ] Database schema verified (4 tests)
- [ ] Provider role display verified (3 tests)
- [ ] Chat functionality tested (4 tests)
- [ ] Call status tested (3 tests)
- [ ] RLS policies validated (3 tests)
- [ ] Helper functions tested (3 tests)
- [ ] Edge cases handled (5 tests)
- [ ] All critical success criteria met
- [ ] Documentation updated

---

## Next Steps After Testing

1. **If Tests Pass:**
   - Update todo list: Mark "Test appointment-based chat" as completed
   - Create production deployment PR
   - Update CLAUDE.md with new chat architecture
   - Document any discovered limitations

2. **If Tests Fail:**
   - Document failures in test results
   - Create bug fix tickets
   - Prioritize by severity (critical vs. nice-to-have)
   - Implement fixes and re-test

---

## Notes

- Migration file: `20251218130000_implement_appointment_based_chat_restrictions.sql`
- Widget files modified: 3 files, 11 occurrences total
- API endpoint calls (`.providerSpecialtyCall`) were correctly left unchanged
- Firebase struct (`AppointmentsStruct`) not used in codebase, left unchanged
