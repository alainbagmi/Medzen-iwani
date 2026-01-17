# Appointment-Based Chat - Quick Test Guide

**Date:** December 18, 2025
**Status:** Ready for Manual Testing
**Prerequisites:** ✅ Schema verified, ✅ Code updated, ✅ Migration applied

---

## Pre-Flight Check ✅

Before testing, confirm:
- [x] Migration `20251218130000` applied to database
- [x] Flutter app builds without errors (`flutter analyze` passed)
- [x] Provider and patient test accounts available
- [x] At least one appointment scheduled between test accounts

---

## Critical Tests (Do These First)

### Test 1: Provider Role Display ⭐ CRITICAL
**Location:** Any appointment list page
**Steps:**
1. Login as Patient
2. Navigate to appointments list
3. Look at appointment details

**Expected:** Shows "Doctor [Name]" or "Nurse [Name]", NOT specialty (e.g., NOT "Cardiologist")
**Files Updated:** `join_call_widget.dart:473`, `appointments_widget.dart:626,1123,1640,1767,1832`, `patient_landing_page_widget.dart:907`

**✅ Pass if:** Provider role displays correctly
**❌ Fail if:** Shows specialty instead of role

---

### Test 2: Provider Can Send Messages ⭐ CRITICAL
**Location:** Video call chat panel
**Steps:**
1. Login as **Provider**
2. Join video call for an appointment
3. Open chat panel (if not auto-open)
4. Type message: "Test from provider"
5. Send message

**Expected:**
- Message appears in chat immediately
- Chat title shows: "Consultation MM/YYYY Doctor [Name]"
- Message saved to database with `appointment_id`

**✅ Pass if:** Message sends successfully and appears in chat
**❌ Fail if:** Message fails to send or doesn't appear

---

### Test 3: Patient CANNOT Send Messages ⭐ CRITICAL
**Location:** Video call chat panel
**Steps:**
1. Login as **Patient** (use different browser/device)
2. Join the SAME video call
3. Look at chat panel

**Expected:**
- Provider's messages are visible (read-only)
- Message input field is **HIDDEN** or **DISABLED**
- No "Send" button visible for patient

**✅ Pass if:** Patient cannot send messages (input hidden/disabled)
**❌ Fail if:** Patient can send messages (RLS policy failed)

---

### Test 4: Chat Linked to Appointment ⭐ CRITICAL
**Location:** Database or video call
**Steps:**
1. Provider sends message in Appointment A
2. Provider joins video call for Appointment B (different patient)
3. Check chat in Appointment B

**Expected:**
- Appointment B chat is EMPTY (no messages from Appointment A)
- Each appointment has isolated chat history

**✅ Pass if:** Messages don't leak between appointments
**❌ Fail if:** Messages from Appointment A appear in Appointment B

---

## Quick Verification Queries

Run these in Supabase SQL Editor to verify database state:

```sql
-- Check appointment_overview has provider_role
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'appointment_overview'
  AND column_name = 'provider_role';
-- Expected: Returns 1 row

-- Check video_call_sessions has new columns
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'video_call_sessions'
  AND column_name IN ('is_call_active', 'ended_at');
-- Expected: Returns 2 rows

-- Check chime_messages has appointment_id
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'chime_messages'
  AND column_name = 'appointment_id';
-- Expected: Returns 1 row

-- Check RLS policies exist
SELECT policyname, tablename, cmd
FROM pg_policies
WHERE tablename = 'chime_messages'
  AND policyname LIKE '%provider%';
-- Expected: Returns policy "Only providers can send messages during active calls"
```

---

## Success Criteria

### Must Pass (Critical) ✅
- [ ] Provider role displays instead of specialty (Test 1)
- [ ] Provider can send chat messages (Test 2)
- [ ] Patient CANNOT send messages (Test 3)
- [ ] Chat messages linked to appointments (Test 4)

### Should Pass (Important) 🔶
- [ ] Chat title format: "Consultation MM/YYYY Doctor [Name]"
- [ ] Messages persist after page refresh
- [ ] Call status tracking works (`is_call_active` flag)

### Nice to Have (Can Fix Later) ⚪
- [ ] Real-time message updates without manual refresh
- [ ] Chat UI handles long provider names gracefully
- [ ] Message read receipts
- [ ] Typing indicators

---

## If Tests Fail

### Rollback Procedure
If critical issues discovered:

1. **Revert Widget Files:**
```bash
git checkout HEAD~1 lib/home_pages/join_call/join_call_widget.dart
git checkout HEAD~1 lib/all_users_page/appointments/appointments_widget.dart
git checkout HEAD~1 lib/patients_folder/patient_landing_page/patient_landing_page_widget.dart
```

2. **Revert Database Migration:**
Create new migration to undo changes:
```bash
npx supabase migration new revert_appointment_chat
```

3. **Rebuild App:**
```bash
flutter clean
flutter pub get
flutter run
```

---

## Reporting Issues

When reporting test failures, include:
1. **Test Number** (e.g., Test 2: Provider Can Send Messages)
2. **Expected Behavior** (from test description)
3. **Actual Behavior** (what happened instead)
4. **Screenshots** (if UI issue)
5. **Error Messages** (console logs, database errors)
6. **User Role** (Provider or Patient)
7. **Appointment ID** (for database investigation)

**Example:**
```
Test 3 FAILED - Patient CAN send messages

Expected: Message input hidden/disabled for patient
Actual: Patient can type and send messages
Role: Patient (user ID: abc-123)
Appointment ID: xyz-789
Error: None (message sent successfully but shouldn't have)
```

---

## Full Test Suite

For comprehensive testing, see:
- **Detailed Test Plan:** `APPOINTMENT_BASED_CHAT_TEST_PLAN.md` (25 test cases)
- **Implementation Summary:** `APPOINTMENT_CHAT_IMPLEMENTATION_SUMMARY.md`
- **Schema Verification:** `SCHEMA_VERIFICATION_SUMMARY.md`

---

## Quick Reference: What Changed

**Database:**
- ✅ `appointment_overview` view - Added `provider_role` field
- ✅ `video_call_sessions` table - Added `is_call_active`, `ended_at` columns
- ✅ `chime_messages` table - Added `appointment_id` column with FK
- ✅ RLS policies - Provider-only message sending
- ✅ Helper functions - 3 new functions for auth/status checking

**Widget Files:**
- ✅ `join_call_widget.dart` - 3 occurrences updated (line 473, 654, 1034)
- ✅ `appointments_widget.dart` - 7 occurrences updated (lines 626-1832)
- ✅ `patient_landing_page_widget.dart` - 1 occurrence updated (line 907)

**Total Changes:** 11 field references from `providerSpecialty` → `providerRole`

---

## After Testing

When all critical tests pass:
1. Update todo list: Mark "Test appointment-based chat" as completed
2. Document any discovered issues or limitations
3. Update `CLAUDE.md` with new chat architecture details
4. Create production deployment PR (if needed)

---

**Ready to Test!** Start with the 4 critical tests above. If they pass, proceed to the full test suite in `APPOINTMENT_BASED_CHAT_TEST_PLAN.md`.
