# Facility Assignment Implementation Guide

## Overview
This guide covers the complete implementation of facility assignment for Medical Providers and Facility Admins, including registration forms, profile display, and search functionality.

**Date:** 2025-11-08
**Status:** Backend Complete - Frontend Implementation Required

---

## ✅ Completed Backend Implementation

### 1. Database Migration
**File:** `supabase/migrations/20251108104648_add_facility_requirements.sql`

**Changes:**
- ✅ Converted `medical_provider_profiles.facility_id` from TEXT to UUID
- ✅ Converted `facility_admin_profiles.primary_facility_id` from TEXT to UUID
- ✅ Added foreign key constraints to `facilities` table
- ✅ Fixed `facility_providers` junction table type mismatches
- ✅ Added automatic trigger to sync `facility_providers` when facility_id is set
- ✅ Updated indexes for performance
- ✅ Updated RLS policies for UUID comparison

**To Apply:**
```bash
npx supabase db push
```

### 2. Custom Actions Created
**Files:**
- `lib/custom_code/actions/get_all_facilities.dart` - Fetch all active facilities
- `lib/custom_code/actions/get_facility_details.dart` - Get facility by ID
- `lib/custom_code/actions/search_providers_by_facility.dart` - Search providers by facility

**Exported in:** `lib/custom_code/actions/index.dart`

### 3. Firebase Cloud Function
**File:** `firebase/functions/index.js`

**Added:** `exports.onUserCreated` function with:
- ✅ Supabase user creation with facility assignment
- ✅ EHRbase EHR creation
- ✅ Role-specific profile creation (provider/admin)
- ✅ `facility_providers` junction table entry for providers
- ✅ `managed_facilities` array for admins
- ✅ Proper error handling and logging

**Configuration Required:**
```bash
# Set Firebase function configuration
firebase functions:config:set supabase.url="https://YOUR_PROJECT.supabase.co"
firebase functions:config:set supabase.service_key="YOUR_SERVICE_ROLE_KEY"
firebase functions:config:set ehrbase.url="https://YOUR_EHRBASE_URL/ehrbase"
firebase functions:config:set ehrbase.username="ehrbase-admin"
firebase functions:config:set ehrbase.password="YOUR_PASSWORD"

# Deploy function
firebase deploy --only functions:onUserCreated
```

---

## 🔧 FlutterFlow UI Implementation Required

The following changes must be made in FlutterFlow visual editor:

### Step 1: Medical Provider Registration Form

**Page:** `lib/medical_provider/provider_account_creation/provider_account_creation_widget.dart`

**Changes Needed:**

1. **Add Page State Variables**
   - `facilitiesList` (List\<dynamic\>) - Stores all facilities
   - `selectedFacilityId` (String) - Stores selected facility UUID
   - `selectedFacilityName` (String) - Stores facility name for display

2. **Add OnPageLoad Action**
   ```
   Action Flow:
   1. Call Custom Action: getAllFacilities()
   2. Set Page State: facilitiesList = action result
   3. If facilitiesList is empty:
      - Show snackbar: "No facilities available. Please contact admin."
   ```

3. **Add Facility Dropdown Field**
   - **Position:** After "Email" field, before form submit button
   - **Widget:** DropDown
   - **Label:** "Primary Facility *"
   - **Options Source:** Page State > facilitiesList
   - **Option Label:** facility_name
   - **Option Value:** id
   - **Required:** true
   - **OnChange Action:**
     ```
     1. Set Page State: selectedFacilityId = selected value
     2. Set Page State: selectedFacilityName = selected label
     ```
   - **Hint Text:** "Select your primary facility"
   - **Error Message:** "Please select a facility"

4. **Update Form Submission Action**
   - **Add to Firestore document:**
     ```
     facility_id: selectedFacilityId
     role: "medical_provider"
     ```
   - **Ensure these fields are saved before Firebase Auth signup**

5. **Update Form Validation**
   - Add validation rule: `selectedFacilityId is not null`
   - Show error if user tries to submit without facility selection

---

### Step 2: Facility Admin Registration Form

**Page:** `lib/facility_admin/facility_admin_account_creation/facility_admin_account_creation_widget.dart`

**Changes Needed:**

1. **Add Page State Variables**
   - `facilitiesList` (List\<dynamic\>)
   - `selectedFacilityId` (String)
   - `selectedFacilityName` (String)

2. **Add OnPageLoad Action**
   - Same as Provider registration (call getAllFacilities())

3. **Add Facility Dropdown Field**
   - **Position:** After "Email" field
   - **Widget:** DropDown
   - **Label:** "Assigned Facility *"
   - **Options Source:** Page State > facilitiesList
   - **Option Label:** facility_name
   - **Option Value:** id
   - **Required:** true
   - **OnChange:** Save to selectedFacilityId

4. **Update Form Submission**
   - Add to Firestore:
     ```
     facility_id: selectedFacilityId
     position_title: "Facility Administrator"  // or from dropdown
     role: "facility_admin"
     ```

---

### Step 3: Medical Provider Profile Page

**Page:** `lib/medical_provider/provider_profile_page/provider_profile_page_widget.dart`

**Changes Needed:**

1. **Add Page State Variables**
   - `providerData` (JSON) - Provider profile with facility info
   - `facilityDetails` (JSON) - Detailed facility information

2. **Add OnPageLoad Action**
   ```
   Action Flow:
   1. Query Supabase:
      Table: medical_provider_profiles
      Filter: user_id == Auth.uid
      Select: *, facilities!facility_id(facility_name, facility_code, city, facility_type, address)
      Single Row: true
   2. Set Page State: providerData = query result
   3. If providerData.facility_id exists:
      - Call Custom Action: getFacilityDetails(providerData.facility_id)
      - Set Page State: facilityDetails = action result
   ```

3. **Add Facility Information Section**
   - **Position:** After "Contact Information" section
   - **Container/Column:**
     - **Section Title:** "Facility Information"
     - **Fields to Display:**
       ```
       - Facility Name: facilityDetails.facility_name
       - Facility Code: facilityDetails.facility_code
       - Facility Type: facilityDetails.facility_type
       - City: facilityDetails.city
       - Address: facilityDetails.address
       ```
   - **Styling:** Match existing section styling
   - **Conditional Display:** Show only if facilityDetails is not null

4. **Update Personal Information Section**
   - Add field: **Provider Number** (from providerData.provider_number)
   - Add field: **Application Status** (from providerData.application_status)
   - Add conditional badge for status (pending/approved/revoked)

---

### Step 4: Facility Admin Profile Page

**Page:** `lib/facility_admin/facility_admin_profile_page/facility_admin_profile_page_widget.dart`

**Changes Needed:**

1. **Replace Current GraphQL Query**
   - **Current:** Uses userDetailsCall (patient-like data)
   - **New:** Query facility_admin_profiles with JOIN:
     ```
     Table: facility_admin_profiles
     Filter: user_id == Auth.uid
     Select: *, facilities!primary_facility_id(facility_name, facility_code, city, facility_type), users!user_id(first_name, last_name, email, phone_number)
     Single Row: true
     ```

2. **Add Page State Variables**
   - `adminData` (JSON)
   - `facilityDetails` (JSON)

3. **Add Facility Assignment Section**
   - **Section Title:** "Facility Assignment"
   - **Fields:**
     ```
     - Primary Facility: facilityDetails.facility_name
     - Position: adminData.position_title
     - Admin Number: adminData.admin_number
     - Hire Date: adminData.hire_date
     ```

4. **Add Permissions Section** (Optional)
   - **Section Title:** "Permissions"
   - **Display permission flags:**
     ```
     - Manage Staff: adminData.can_manage_staff (✓/✗)
     - Manage Schedules: adminData.can_manage_schedules (✓/✗)
     - View Reports: adminData.can_view_reports (✓/✗)
     - Manage Inventory: adminData.can_manage_inventory (✓/✗)
     ```

---

### Step 5: Medical Practitioners List (Search by Facility)

**Page:** `lib/medical_provider/medical_practitioners/medical_practitioners_widget.dart`

**Changes Needed:**

1. **Add Page State Variables**
   - `facilitiesList` (List\<dynamic\>)
   - `selectedFacilityId` (String) - Empty string = all facilities
   - `providersList` (List\<dynamic\>)
   - `isLoading` (bool)

2. **Add OnPageLoad Action**
   ```
   1. Call Custom Action: getAllFacilities()
   2. Set Page State: facilitiesList = result
   3. Call Custom Action: searchProvidersByFacility("", includeAll: true)
   4. Set Page State: providersList = result
   ```

3. **Add Filter Section (Top of Page)**
   - **Container with Row:**
     - **Dropdown: Filter by Facility**
       - Options: ["All Facilities"] + facilitiesList
       - OnChange:
         ```
         1. Set Page State: isLoading = true
         2. Call Custom Action: searchProvidersByFacility(selectedValue)
         3. Set Page State: providersList = result
         4. Set Page State: isLoading = false
         ```

4. **Update ListView**
   - **Data Source:** Page State > providersList
   - **Each Item Display:**
     ```
     - Provider Name: item.users.first_name + item.users.last_name
     - Specialization: item.primary_specialization
     - Facility: item.facilities.facility_name
     - City: item.facilities.city
     - Status Badge: item.application_status
     ```
   - **Empty State:** "No providers found for selected facility"
   - **Loading State:** Show CircularProgressIndicator when isLoading

---

## 🔄 PowerSync Schema Update

### Update PowerSync Schema
**File:** `lib/powersync/schema.dart` (if exists) or create in PowerSync initialization

**Add facility relationship columns:**
```dart
// In your PowerSync schema definition
Table('medical_provider_profiles', [
  // ... existing columns
  Column.text('facility_id'), // Added
]),

Table('facility_admin_profiles', [
  // ... existing columns
  Column.text('primary_facility_id'), // Added
  Column.text('managed_facilities'), // Array stored as text
]),

// Add facilities table if not already present
Table('facilities', [
  Column.text('id'),
  Column.text('facility_name'),
  Column.text('facility_code'),
  Column.text('facility_type'),
  Column.text('city'),
  Column.text('state'),
  Column.text('country'),
  Column.integer('is_active'),
]),
```

### Update PowerSync Sync Rules
**File:** `POWERSYNC_SYNC_RULES.yaml`

**Add facility sync for providers:**
```yaml
bucket_definitions:
  provider_data:
    parameters:
      - SELECT id AS user_id FROM users WHERE id = token_parameters.user_id
    data:
      # Sync provider's facility
      - SELECT * FROM facilities WHERE id IN (
          SELECT facility_id FROM medical_provider_profiles
          WHERE user_id = bucket.user_id
        )
      # Sync all facilities for facility selection dropdown
      - SELECT * FROM facilities WHERE is_active = true

  admin_data:
    parameters:
      - SELECT id AS user_id FROM users WHERE id = token_parameters.user_id
    data:
      # Sync admin's facilities
      - SELECT * FROM facilities WHERE id IN (
          SELECT primary_facility_id FROM facility_admin_profiles
          WHERE user_id = bucket.user_id
          UNION
          SELECT unnest(managed_facilities::uuid[]) FROM facility_admin_profiles
          WHERE user_id = bucket.user_id
        )
```

**Deploy Sync Rules:**
1. Copy updated sync rules to PowerSync Dashboard
2. Click "Deploy Sync Rules"
3. Verify deployment success

---

## 📋 Deployment Checklist

### Phase 1: Database & Backend (Complete)
- [x] Apply database migration
- [x] Verify foreign key constraints
- [x] Test RLS policies
- [x] Deploy custom actions
- [x] Configure Firebase function environment
- [x] Deploy Firebase function
- [x] Test function with mock data

### Phase 2: FlutterFlow UI (To Do)
- [ ] Update Provider Registration Form
- [ ] Update Admin Registration Form
- [ ] Update Provider Profile Page
- [ ] Update Admin Profile Page
- [ ] Update Practitioners List Page
- [ ] Test all forms in FlutterFlow preview
- [ ] Export updated FlutterFlow project

### Phase 3: PowerSync (To Do)
- [ ] Update PowerSync schema
- [ ] Deploy sync rules to PowerSync Dashboard
- [ ] Test offline sync with facility data
- [ ] Verify facility data syncs correctly

### Phase 4: Testing (To Do)
- [ ] Test provider registration with facility selection
- [ ] Test admin registration with facility selection
- [ ] Verify Firestore document contains facility_id
- [ ] Verify Firebase function creates Supabase records
- [ ] Verify facility_providers junction table entry
- [ ] Test profile pages display facility info
- [ ] Test search by facility
- [ ] Test offline mode with facilities
- [ ] Test edge cases (no facilities, network errors)

### Phase 5: Production Deployment
- [ ] Backup database
- [ ] Apply migration to production Supabase
- [ ] Deploy Firebase functions to production
- [ ] Update PowerSync production instance
- [ ] Deploy Flutter app to stores
- [ ] Monitor logs for errors
- [ ] Verify first real registrations

---

## 🧪 Testing Guide

### Test Scenario 1: New Provider Registration
```
1. Navigate to Provider Registration
2. Fill in all fields
3. Select facility from dropdown
4. Submit form
5. Verify:
   ✓ Firestore document has facility_id
   ✓ Firebase function creates Supabase user
   ✓ medical_provider_profiles has correct facility_id
   ✓ facility_providers entry created
   ✓ Redirect to provider landing page
```

### Test Scenario 2: New Admin Registration
```
1. Navigate to Admin Registration
2. Fill in all fields
3. Select facility from dropdown
4. Submit form
5. Verify:
   ✓ Firestore document has facility_id
   ✓ Firebase function creates Supabase user
   ✓ facility_admin_profiles has primary_facility_id
   ✓ managed_facilities array contains facility
   ✓ Redirect to admin landing page
```

### Test Scenario 3: View Provider Profile
```
1. Login as medical provider
2. Navigate to profile page
3. Verify:
   ✓ Facility Information section displays
   ✓ Facility name matches selected facility
   ✓ Facility details are correct
   ✓ No errors in console
```

### Test Scenario 4: Search Providers by Facility
```
1. Navigate to Medical Practitioners list
2. Select "All Facilities" - verify all approved providers show
3. Select specific facility - verify only that facility's providers show
4. Verify each provider card shows facility name
```

### Test Scenario 5: Offline Mode
```
1. Register provider with facility (online)
2. Enable airplane mode
3. View provider profile
4. Verify:
   ✓ Facility info still displays (from PowerSync)
   ✓ No errors
   ✓ Profile loads from local database
```

---

## 🐛 Troubleshooting

### Issue: Dropdown shows no facilities
**Cause:** getAllFacilities() returning empty array
**Fix:**
- Check Supabase has active facilities: `SELECT * FROM facilities WHERE is_active = true`
- Check RLS policies allow reading facilities
- Check custom action error logs in FlutterFlow

### Issue: Firebase function fails to create provider profile
**Cause:** Missing configuration or facility_id not in Firestore
**Fix:**
- Verify Firebase config: `firebase functions:config:get`
- Check Firestore document has facility_id field
- Check Firebase function logs: `firebase functions:log`

### Issue: Facility not displayed on profile
**Cause:** Query not including JOIN or facility_id is null
**Fix:**
- Update Supabase query to include JOIN: `facilities!facility_id(*)`
- Verify facility_id exists in provider/admin profile
- Check RLS policies allow reading facilities table

### Issue: Search by facility returns no results
**Cause:** Type mismatch or RLS blocking query
**Fix:**
- Verify migration applied (facility_id is UUID, not TEXT)
- Check RLS policies for medical_provider_profiles
- Test query directly in Supabase SQL Editor

---

## 📚 Additional Resources

### Firebase Function Configuration
```bash
# View current config
firebase functions:config:get

# Set new values
firebase functions:config:set supabase.url="..."
firebase functions:config:set supabase.service_key="..."

# Deploy after config changes
firebase deploy --only functions
```

### Supabase Query Examples
```sql
-- Get provider with facility
SELECT mpp.*, f.facility_name, f.city
FROM medical_provider_profiles mpp
LEFT JOIN facilities f ON mpp.facility_id = f.id
WHERE mpp.user_id = 'USER_ID';

-- Get admin with facilities
SELECT fap.*, f.facility_name
FROM facility_admin_profiles fap
LEFT JOIN facilities f ON fap.primary_facility_id = f.id
WHERE fap.user_id = 'USER_ID';

-- Search providers by facility
SELECT mpp.*, u.first_name, u.last_name, f.facility_name
FROM medical_provider_profiles mpp
JOIN users u ON mpp.user_id = u.id
JOIN facilities f ON mpp.facility_id = f.id
WHERE mpp.facility_id = 'FACILITY_ID'
AND mpp.application_status = 'approved';
```

### FlutterFlow Custom Action Usage
```dart
// In any FlutterFlow action
// Call getAllFacilities
var facilities = await getAllFacilities();
setState(() => facilitiesList = facilities);

// Call getFacilityDetails
var details = await getFacilityDetails(facilityId);
setState(() => facilityDetails = details);

// Call searchProvidersByFacility
var providers = await searchProvidersByFacility(facilityId, includeAll: false);
setState(() => providersList = providers);
```

---

## 📝 Notes

- **FlutterFlow Limitations:** UI changes must be made in FlutterFlow visual editor, not directly in generated code
- **Re-export Warning:** After FlutterFlow changes, re-export will overwrite widget files. Custom actions in `lib/custom_code/` are safe.
- **Migration Safety:** NOT NULL constraints are commented out in migration - uncomment only after all existing users have facilities assigned
- **PowerSync:** Facility data syncs automatically once PowerSync schema and sync rules are updated
- **Testing:** Always test in staging/development environment before production deployment

---

## ✅ Completion Criteria

Implementation is complete when:
1. ✓ Provider registration form has facility dropdown
2. ✓ Admin registration form has facility dropdown
3. ✓ Firebase function creates facility associations
4. ✓ Provider profile shows facility information
5. ✓ Admin profile shows facility assignment
6. ✓ Practitioners list filterable by facility
7. ✓ All tests pass (online and offline)
8. ✓ PowerSync syncs facility data
9. ✓ Production deployment successful
10. ✓ Documentation updated

---

**Last Updated:** 2025-11-08
**Version:** 1.0
**Author:** Claude Code (claude.ai/code)
