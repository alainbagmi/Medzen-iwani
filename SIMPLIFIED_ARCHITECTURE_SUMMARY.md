# MedZen Architecture - What's Implemented & What's Needed

**Date:** 2025-11-10
**Status:** ✅ Cloud Function Simplified & Deployed

---

## ✅ What's Already Implemented

### 1. Cloud Function: `onUserCreated` (SIMPLIFIED)

**Location:** `firebase/functions/index.js` (lines 257-370)

**What it does:**
1. Creates Supabase Auth user with email only
2. Stores `firebase_uid` in user_metadata
3. Updates Firestore doc with `supabase_user_id`

**What it does NOT do anymore:**
- ❌ Does not create users table record
- ❌ Does not create EHRbase EHR
- ❌ Does not create electronic_health_records entry

**Status:** ✅ Deployed and active

---

### 2. Database Triggers: Profile Updates (ALREADY EXISTS)

**Location:** `supabase/migrations/20251110030000_update_ehr_on_profile_changes.sql`

**What they do:**
- When a profile table is created (patient_profiles, medical_provider_profiles, etc.)
- Automatically UPDATE `electronic_health_records.user_role`

**Important:** These triggers UPDATE existing electronic_health_records, they don't CREATE them.

**Status:** ✅ Already deployed

---

### 3. Database Triggers: EHR Sync Queue (ALREADY EXISTS)

**What they do:**
- When medical data is inserted (vital_signs, lab_results, etc.)
- Automatically queue in `ehrbase_sync_queue` for EHRbase sync

**Status:** ✅ Already deployed (25 triggers active)

---

## ❌ What's MISSING (FlutterFlow's Responsibility)

Based on your comments, FlutterFlow needs to handle:

### Missing #1: Update Users Table

**When:** After user signup, when collecting profile details

**What to do:**
```dart
await SupaFlow.client.from('users').update({
  'first_name': firstName,
  'last_name': lastName,
  'full_name': fullName,
  'phone_number': phoneNumber,
  // ... other fields
}).eq('id', supabaseUserId);
```

### Missing #2: Create electronic_health_records Entry

**When:** After updating users table

**What to do:**
```dart
// Create EHRbase EHR first (via Edge Function or direct API call)
final ehrId = await createEHRbaseEHR(supabaseUserId);

// Then create electronic_health_records entry
await SupaFlow.client.from('electronic_health_records').insert({
  'patient_id': supabaseUserId,
  'ehr_id': ehrId,
  'ehr_status': 'active',
  'user_role': 'patient',  // Default, will be updated by trigger
});
```

### Missing #3: Create Role-Specific Profile

**When:** After creating electronic_health_records

**What to do:**
```dart
if (userRole == 'patient') {
  await SupaFlow.client.from('patient_profiles').insert({
    'user_id': supabaseUserId,
    'date_of_birth': dateOfBirth,
    'gender': gender,
    // ... other patient fields
  });
  // Database trigger will update electronic_health_records.user_role = 'patient'
}
```

---

## 📋 Complete User Flow (Current Architecture)

```
Step 1: User Signs Up (Firebase Auth)
   ↓
Step 2: onUserCreated Cloud Function
   - Creates Supabase Auth user (email only)
   - Updates Firestore with supabase_user_id
   ↓
Step 3: FlutterFlow Role Selection Page
   - User selects role (patient, provider, admin)
   ↓
Step 4: FlutterFlow Profile Collection
   - Collect: name, phone, role-specific details
   ↓
Step 5: FlutterFlow Custom Action (NEEDS TO BE CREATED)
   - Updates users table with profile details
   - Creates EHRbase EHR (via Edge Function)
   - Creates electronic_health_records entry
   - Creates role-specific profile table
   ↓
Step 6: Database Trigger (AUTOMATIC)
   - Updates electronic_health_records.user_role based on profile table
   ↓
Step 7: User Fully Registered ✅
   - Firebase Auth ✅
   - Supabase Auth ✅
   - Supabase users table ✅
   - EHRbase EHR ✅
   - electronic_health_records ✅
   - Role-specific profile ✅
```

---

## 🔧 What You Need to Create in FlutterFlow

### Option 1: Single Comprehensive Action

**Action Name:** `completeUserProfileAndEHR`

**Inputs:**
- `userId` (String) - Firebase UID from auth
- `supabaseUserId` (String) - From Firestore doc
- `fullName` (String)
- `phoneNumber` (String)
- `userRole` (String) - 'patient', 'medical_provider', 'facility_admin', 'system_admin'
- `roleSpecificData` (Map) - Role-specific fields

**Steps:**
1. Update users table
2. Call Edge Function to create EHRbase EHR
3. Create electronic_health_records entry
4. Create role-specific profile table
5. Return success/error

### Option 2: Multiple Smaller Actions

**Action 1:** `updateUserProfile`
- Updates users table only

**Action 2:** `createEHRRecord`
- Calls Edge Function to create EHRbase EHR
- Creates electronic_health_records entry

**Action 3:** `createRoleProfile`
- Creates role-specific profile table (patient, provider, admin)

---

## 🚨 Current State

**Deployed:**
- ✅ Simplified `onUserCreated` Cloud Function (creates Supabase Auth user only)
- ✅ Database triggers (profile updates, EHR sync queue)

**Not Implemented:**
- ❌ FlutterFlow action to update users table
- ❌ FlutterFlow action to create electronic_health_records entry
- ❌ FlutterFlow action to create EHRbase EHR (via Edge Function call)
- ❌ FlutterFlow action to create role-specific profile

**Result:**
- Users can sign up and get Supabase Auth account ✅
- BUT users table is empty ❌
- AND electronic_health_records table is empty ❌
- AND no EHRbase EHR is created ❌

---

## 📝 Next Steps

### 1. Clarify FlutterFlow Actions (URGENT)

**Questions for you:**
1. Do you already have FlutterFlow actions that:
   - Update users table after signup?
   - Create electronic_health_records entries?
   - Create role-specific profiles?

2. If yes, where are they? (I couldn't find them in `lib/custom_code/actions/`)

3. If no, do you want me to:
   - Create Dart code for these actions?
   - Or just provide pseudocode/instructions?

### 2. Test Current Setup

**Test #1: Signup Flow**
```bash
# After a new user signs up:
# Check what was created:

# Firebase Auth
firebase auth:list | grep <email>

# Supabase Auth
curl "$SUPABASE_URL/auth/v1/admin/users" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY"

# Firestore
# Should have doc with supabase_user_id field

# Supabase users table
curl "$SUPABASE_URL/rest/v1/users?email=eq.<email>" \
  -H "apikey: $SERVICE_KEY"
# Currently returns empty because onUserCreated doesn't create this anymore

# electronic_health_records
curl "$SUPABASE_URL/rest/v1/electronic_health_records" \
  -H "apikey: $SERVICE_KEY"
# Currently empty because onUserCreated doesn't create this anymore
```

### 3. Implement FlutterFlow Actions

Once you confirm what needs to be created, I can:
1. Write the Dart code for FlutterFlow custom actions
2. Create SQL for any missing database functions
3. Update Edge Functions if needed
4. Test the complete flow

---

## 📄 Related Documentation

- **Simplified Function:** `ONUSERCREATED_SIMPLIFIED_ARCHITECTURE.md`
- **Previous Architecture:** `ONUSERCREATED_FIX_REPORT.md` (outdated)
- **Production Status:** `PRODUCTION_READINESS_REPORT.md`
- **Database Triggers:** `supabase/migrations/20251110030000_update_ehr_on_profile_changes.sql`

---

## ❓ Questions for You

1. **Where does FlutterFlow currently update the users table?**
   - I searched `lib/custom_code/actions/` but found no user profile actions
   - Are they in a different location?

2. **Where does FlutterFlow currently create electronic_health_records?**
   - Is this handled by a database function?
   - Or is this missing entirely?

3. **Do you want me to create the missing FlutterFlow actions?**
   - If yes, I can write the Dart code
   - If no, just tell me what exists and I'll document it

---

**Report Generated:** 2025-11-10
**Status:** ⚠️ WAITING FOR CLARIFICATION ON FLUTTERFLOW ACTIONS
