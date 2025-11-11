# FlutterFlow user_profiles Creation Guide

**Status:** ✅ VERIFIED WORKING
**Last Tested:** November 3, 2025

## Overview

FlutterFlow **CAN** successfully create, read, and update user_profiles in the Supabase database. All tests pass with full CRUD capabilities.

## Test Results Summary

✅ **ALL 6 TESTS PASSED:**
1. ✅ CREATE - FlutterFlow can create new profiles
2. ✅ READ - FlutterFlow can read existing profiles
3. ✅ UPDATE - FlutterFlow can update profiles
4. ✅ Minimal fields - Only user_id and role required
5. ✅ FK constraint - Prevents orphaned profiles
6. ✅ Merge duplicates - Upsert functionality works

## Required Fields

When creating a user_profile from FlutterFlow, you **MUST** provide:

1. **user_id** (UUID)
   - Must be a valid UUID from the `users` table
   - Foreign key constraint enforced
   - Get this from: `SupaFlow.client.auth.currentUser?.id`

2. **role** (String)
   - Must be one of: `patient`, `provider`, `facility_admin`, `system_admin`
   - Default should be: `patient`

## FlutterFlow Implementation

### Method 1: Using Supabase Insert Action (Recommended)

In FlutterFlow:

1. **Action:** Supabase Insert Row
2. **Table:** user_profiles
3. **Fields:**
   ```
   user_id: Get from authenticated user ID
   role: "patient" (or selected role)
   bio: (optional) Text field value
   city: (optional) Text field value
   ... any other optional fields
   ```

### Method 2: Using Dart Code (Custom Action)

Create a custom action in FlutterFlow:

```dart
import 'package:medzen_iwani/backend/supabase/supabase.dart';

Future<bool> createUserProfile({
  required String userId,
  required String role,
  String? bio,
  String? city,
  String? state,
  String? country,
}) async {
  try {
    final response = await SupaFlow.client
        .from('user_profiles')
        .insert({
          'user_id': userId,
          'role': role,
          'bio': bio,
          'city': city,
          'state': state,
          'country': country,
        })
        .select()
        .single();

    return response != null;
  } catch (e) {
    print('Error creating user profile: $e');
    return false;
  }
}
```

### Method 3: Upsert (Create or Update)

For updating existing profiles or creating new ones:

```dart
import 'package:medzen_iwani/backend/supabase/supabase.dart';

Future<bool> upsertUserProfile({
  required String userId,
  required String role,
  Map<String, dynamic>? additionalFields,
}) async {
  try {
    final data = {
      'user_id': userId,
      'role': role,
      ...?additionalFields,
    };

    final response = await SupaFlow.client
        .from('user_profiles')
        .upsert(data)
        .select()
        .single();

    return response != null;
  } catch (e) {
    print('Error upserting user profile: $e');
    return false;
  }
}
```

## Usage Examples

### Example 1: Create Profile After Role Selection

In your role selection page (e.g., `lib/home_pages/role_page/`):

```dart
// After user selects their role
Future<void> onRoleSelected(String selectedRole) async {
  final userId = SupaFlow.client.auth.currentUser?.id;

  if (userId == null) {
    print('User not authenticated');
    return;
  }

  final success = await createUserProfile(
    userId: userId,
    role: selectedRole,
  );

  if (success) {
    // Update app state
    FFAppState().update(() {
      FFAppState().UserRole = selectedRole;
      FFAppState().SelectedRole = selectedRole;
    });

    // Navigate to role-specific page
    context.goNamed(selectedRole == 'patient' ? 'PatientsBottomNav' : 'ProviderBottomNav');
  }
}
```

### Example 2: Update Profile from Profile Page

In your profile edit page:

```dart
// When user updates their profile
Future<void> saveProfile() async {
  final userId = SupaFlow.client.auth.currentUser?.id;

  if (userId == null) return;

  await SupaFlow.client
      .from('user_profiles')
      .update({
        'bio': bioTextController.text,
        'city': cityTextController.text,
        'state': stateTextController.text,
        'country': countryTextController.text,
        'emergency_contact_name': emergencyContactNameController.text,
        'emergency_contact_phone': emergencyContactPhoneController.text,
      })
      .eq('user_id', userId);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Profile updated successfully')),
  );
}
```

### Example 3: Read Profile Data

In any page that needs profile data:

```dart
// Get current user's profile
Future<Map<String, dynamic>?> getUserProfile() async {
  final userId = SupaFlow.client.auth.currentUser?.id;

  if (userId == null) return null;

  try {
    final response = await SupaFlow.client
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .single();

    return response;
  } catch (e) {
    print('Error fetching user profile: $e');
    return null;
  }
}
```

## All Optional Fields

All fields below are **OPTIONAL** and can be updated later:

### Personal Information
- `bio` (String) - User biography
- `display_name` (String) - Display name

### Address Information
- `address` (String) - Full address (deprecated, use structured fields below)
- `street_address` (String) - Street address
- `building_name` (String) - Building name
- `apartment_unit` (String) - Apartment/unit number
- `city` (String) - City
- `state` (String) - State/province
- `country` (String) - Country
- `postal_code` (String) - Postal/ZIP code
- `region_code` (String) - Region code
- `division_code` (String) - Division code
- `subdivision_code` (String) - Subdivision code
- `community_code` (String) - Community code
- `neighborhood` (String) - Neighborhood
- `location` (String) - General location
- `coordinates` (String) - GPS coordinates
- `landmark_description` (String) - Nearby landmarks

### Emergency Contacts
- `emergency_contact_name` (String)
- `emergency_contact_phone` (String)
- `emergency_contact_relationship` (String)
- `emergency_contact_2_name` (String)
- `emergency_contact_2_phone` (String)
- `emergency_contact_2_relationship` (String)

### Insurance Information
- `insurance_provider` (String)
- `insurance_number` (String)
- `insurance_policy_number` (String)
- `insurance_expiry` (DateTime)

### Medical Information
- `blood_type` (String)
- `allergies` (List<String>)
- `chronic_conditions` (List<String>)
- `current_medications` (List<String>)
- `height_cm` (double)
- `weight_kg` (double)

### Identification
- `id_card_number` (String)
- `id_card_issue_date` (DateTime)
- `id_card_expiration_date` (DateTime)
- `national_id` (String)
- `national_id_encrypted` (String) - Encrypted version
- `passport_number` (String)

### Demographics
- `religion` (String)
- `ethnicity` (String)

### Verification
- `verification_status` (String) - Default: "pending"
- `verified_at` (DateTime)
- `verified_by` (String)
- `verification_documents` (JSONB)

### Settings
- `notification_preferences` (JSONB) - Default: {}
- `privacy_settings` (JSONB) - Default: {}
- `metadata` (JSONB) - Custom metadata

### System Fields (Auto-generated)
- `id` (UUID) - Auto-generated primary key
- `created_at` (DateTime) - Auto-set on creation
- `updated_at` (DateTime) - Auto-updated on modification
- `profile_completion_percentage` (int) - Auto-calculated

## Important Notes

### 1. User Must Exist First

The `user_id` foreign key constraint requires that a user exists in the `users` table before you can create a profile. This is automatically handled by the Firebase `onUserCreated` function.

**Correct Flow:**
1. User signs up via Firebase Auth
2. `onUserCreated` Cloud Function runs (creates users table entry)
3. FlutterFlow creates user_profile (after role selection)

### 2. No Duplicate Profiles

The database has a unique constraint on `user_id` - each user can only have ONE profile. Use upsert if you want to update an existing profile or create a new one.

### 3. Profile Created by Firebase Function

The `onUserCreated` Firebase function **already creates** a default user_profile with role="patient". FlutterFlow should:
- **Check if profile exists** before creating
- **Update the existing profile** when user selects their role
- **Use upsert** to avoid duplicate errors

### 4. Trigger on user_profiles

When a user_profile is created or updated, the database trigger `trigger_user_profiles_role_sync` automatically:
- Queues the profile for EHRbase sync
- Updates the electronic_health_records table with the role
- Creates a sync queue entry for OpenEHR composition

## Recommended FlutterFlow Workflow

### Signup Flow

1. **Firebase Auth Signup**
   - User creates account via Firebase Auth
   - `onUserCreated` function runs automatically
   - Creates: Supabase Auth user, users table entry, user_profiles (role="patient"), EHRbase EHR

2. **Role Selection Page**
   - If user's current role is "patient" (default), show role selection
   - When user selects role, UPDATE existing profile:
     ```dart
     await SupaFlow.client
         .from('user_profiles')
         .update({'role': selectedRole})
         .eq('user_id', currentUserId);
     ```

3. **Profile Completion**
   - User fills out additional fields progressively
   - Each field update increments `profile_completion_percentage`

### Login Flow

1. **Check if profile exists:**
   ```dart
   final profile = await getUserProfile();
   if (profile == null) {
     // Should never happen after signup, but handle gracefully
     await createUserProfile(userId: currentUserId, role: 'patient');
   }
   ```

2. **Navigate based on role:**
   ```dart
   final role = profile['role'];
   FFAppState().UserRole = role;

   switch (role) {
     case 'patient':
       context.goNamed('PatientsBottomNav');
       break;
     case 'provider':
       context.goNamed('MedicalProviderBottomNav');
       break;
     case 'facility_admin':
       context.goNamed('FacilityAdminBottomNav');
       break;
     case 'system_admin':
       context.goNamed('SystemAdminBottomNav');
       break;
   }
   ```

## Testing

Run the comprehensive test:
```bash
./test_flutterflow_user_profiles.sh
```

This verifies:
- CREATE operations work
- READ operations work
- UPDATE operations work
- Foreign key constraints work
- Minimal field requirements
- Upsert functionality

## Troubleshooting

### Error: Foreign Key Constraint Violation

```
"insert or update on table \"user_profiles\" violates foreign key constraint \"user_profiles_user_id_fkey\""
```

**Solution:** Ensure the user exists in the `users` table first. This should be automatically handled by the `onUserCreated` function.

### Error: Duplicate Key Violation

```
"duplicate key value violates unique constraint \"user_profiles_user_id_key\""
```

**Solution:** Use upsert instead of insert, or check if profile exists first.

### Profile Not Found After Creation

**Solution:** Wait for the `onUserCreated` function to complete (usually < 2 seconds). Check Firebase Functions logs if issues persist.

## Summary

✅ FlutterFlow can create user_profiles
✅ Only 2 fields required: `user_id` and `role`
✅ All other fields are optional
✅ Full CRUD operations supported
✅ Foreign key constraint ensures data integrity
✅ Upsert functionality available
✅ Database trigger automatically syncs to EHRbase

**Recommendation:** Use UPDATE instead of INSERT for role selection, since `onUserCreated` already creates the profile with role="patient".

---

**Created:** November 3, 2025
**Test Status:** All tests passing ✅
