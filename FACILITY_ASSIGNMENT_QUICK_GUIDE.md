# Facility Assignment - Quick Implementation Guide

## Goal
Enable Medical Providers and Facility Admins to select their facility during registration, save it to the database, and display it when searching for providers.

---

## ✅ What's Already Done

1. **Database Migration** - Facility columns with FK constraints
   - `medical_provider_profiles.facility_id` (UUID)
   - `facility_admin_profiles.primary_facility_id` (UUID)
   - Foreign keys to `facilities` table

2. **Custom Actions Created**
   - `getAllFacilities()` - Fetch facilities for dropdown
   - `getFacilityDetails(facilityId)` - Get facility info for display
   - `searchProvidersByFacility(facilityId)` - Filter providers by facility

3. **Apply Migration**
   ```bash
   npx supabase db push
   ```

---

## 🎯 What You Need to Do (FlutterFlow UI Only)

### 1. Medical Provider Registration - Add Facility Dropdown

**Page:** Provider Account Creation

**Steps in FlutterFlow:**

1. **Add Page State Variable**
   - Variable: `facilitiesList` (List<dynamic>)
   - Variable: `selectedFacilityId` (String)

2. **OnPageLoad Action**
   - Add Custom Action: `getAllFacilities()`
   - Update State: Set `facilitiesList` = action output

3. **Add Dropdown Widget** (after Email field)
   - Widget Type: Dropdown
   - Label: "Select Facility *"
   - Options: `facilitiesList` (from page state)
   - Option Label Field: `facility_name`
   - Option Value Field: `id`
   - Initial Value: null
   - Required: Yes
   - OnChange: Save to `selectedFacilityId`

4. **Update Supabase Insert Action** (when form submits)
   - Add to medical_provider_profiles insert:
     ```
     facility_id: selectedFacilityId
     ```
   - This saves the facility directly to the database

---

### 2. Facility Admin Registration - Add Facility Dropdown

**Page:** Facility Admin Account Creation

**Steps in FlutterFlow** (same as above):

1. Add Page State: `facilitiesList`, `selectedFacilityId`
2. OnPageLoad: Call `getAllFacilities()`
3. Add Dropdown for facility selection
4. Update Supabase Insert:
   - Add to facility_admin_profiles insert:
     ```
     primary_facility_id: selectedFacilityId
     managed_facilities: [selectedFacilityId]
     ```

---

### 3. Medical Providers List - Show Facility Name

**Page:** Medical Practitioners / Medical Providers List

**Current State:** Lists providers without facility info

**Changes Needed:**

**Option A: Simple - Display Facility Name Only**

1. **Update Supabase Query:**
   - Current: Probably `SELECT * FROM medical_provider_profiles`
   - New: Add JOIN to include facility:
     ```
     SELECT
       medical_provider_profiles.*,
       users!user_id(first_name, last_name, email),
       facilities!facility_id(facility_name, city, facility_type)
     FROM medical_provider_profiles
     WHERE application_status = 'approved'
     ```

2. **Update ListView Item Display:**
   - Add Text widget to show: `item.facilities.facility_name`
   - Add Text widget to show: `item.facilities.city`
   - Add Chip/Badge for: `item.facilities.facility_type`

**Option B: Advanced - Filter by Facility**

1. **Add Page State:**
   - `facilitiesList` (List<dynamic>)
   - `selectedFacilityFilter` (String) - empty = all facilities
   - `providersList` (List<dynamic>)

2. **Add Filter Dropdown** (top of page):
   - Options: "All Facilities" + `facilitiesList`
   - OnChange: Call `searchProvidersByFacility(selectedFacilityFilter)`
   - Update `providersList` with results

3. **ListView Data Source:**
   - Change from direct Supabase query to Page State: `providersList`

---

### 4. Provider Profile Page - Display Facility

**Page:** Provider Profile Page

**Current:** Shows basic provider info

**Add Facility Section:**

1. **Update Data Query:**
   - Add JOIN to facility:
     ```
     SELECT
       medical_provider_profiles.*,
       facilities!facility_id(facility_name, facility_code, city, address, phone_number)
     FROM medical_provider_profiles
     WHERE user_id = [Auth UID]
     ```

2. **Add UI Section** (after Contact Information):
   - **Section Header:** "Facility Information"
   - **Display Fields:**
     - Facility Name: `profileData.facilities.facility_name`
     - Facility Code: `profileData.facilities.facility_code`
     - City: `profileData.facilities.city`
     - Address: `profileData.facilities.address`

---

### 5. Admin Profile Page - Display Facility

**Page:** Facility Admin Profile Page

**Changes:**

1. **Update Query** (change from users to facility_admin_profiles):
   ```
   SELECT
     facility_admin_profiles.*,
     users!user_id(first_name, last_name, email),
     facilities!primary_facility_id(facility_name, facility_code, city)
   FROM facility_admin_profiles
   WHERE user_id = [Auth UID]
   ```

2. **Add Facility Section:**
   - Primary Facility: `adminData.facilities.facility_name`
   - Position: `adminData.position_title`
   - Admin Number: `adminData.admin_number`

---

## 📊 Database Structure Reference

### Facilities Table
```sql
facilities
├── id (UUID)
├── facility_name (TEXT) - Display this
├── facility_code (TEXT) - Unique code
├── facility_type (TEXT) - Hospital, Clinic, etc.
├── city (TEXT)
├── address (TEXT)
└── is_active (BOOLEAN) - Only show active
```

### Medical Provider Profiles
```sql
medical_provider_profiles
├── id (UUID)
├── user_id (UUID)
├── facility_id (UUID) ← Save here from dropdown
├── provider_number (TEXT)
├── professional_role (TEXT)
└── application_status (TEXT)
```

### Facility Admin Profiles
```sql
facility_admin_profiles
├── id (UUID)
├── user_id (UUID)
├── primary_facility_id (UUID) ← Save here from dropdown
├── managed_facilities (UUID[])
├── admin_number (TEXT)
└── position_title (TEXT)
```

---

## 🧪 Testing Flow

### Test 1: Register New Provider
```
1. Open provider registration
2. Fill all fields
3. Select facility from dropdown ← Should list all active facilities
4. Submit
5. Check database: medical_provider_profiles.facility_id should have UUID
```

### Test 2: View Provider Profile
```
1. Login as provider
2. Go to profile
3. Should see "Facility Information" section with facility name/address
```

### Test 3: Search Providers
```
1. Open medical practitioners list
2. Should see facility name on each provider card
3. (Optional) Filter by facility - only shows providers from that facility
```

### Test 4: Register New Admin
```
1. Open admin registration
2. Select facility
3. Submit
4. Check database: facility_admin_profiles.primary_facility_id should have UUID
```

---

## 🐛 Common Issues & Fixes

### Issue: Dropdown shows no facilities
**Check:**
- Supabase has active facilities: `SELECT * FROM facilities WHERE is_active = true`
- RLS policies allow reading facilities table
- Custom action `getAllFacilities()` has no errors

**Fix:**
- Insert test facilities into Supabase
- Update RLS: Allow SELECT on facilities for authenticated users

### Issue: Facility not saving
**Check:**
- Supabase insert action includes `facility_id` field
- selectedFacilityId has value (check in FlutterFlow debugger)
- Migration applied (facility_id is UUID type)

**Fix:**
- Verify form submission passes selectedFacilityId to Supabase insert
- Check Supabase logs for insert errors

### Issue: Facility not showing on profile
**Check:**
- Query includes JOIN: `facilities!facility_id(...)`
- facility_id exists in database (not null)
- RLS allows reading both tables

**Fix:**
- Update query to include JOIN
- Verify facility_id was saved during registration

---

## 📋 Quick Checklist

**Registration Forms:**
- [ ] Provider registration has facility dropdown
- [ ] Admin registration has facility dropdown
- [ ] Dropdowns populated from `getAllFacilities()`
- [ ] Selected facility saved to Supabase on submit

**Profile Pages:**
- [ ] Provider profile queries facility with JOIN
- [ ] Provider profile displays facility section
- [ ] Admin profile queries facility with JOIN
- [ ] Admin profile displays facility section

**Search/List:**
- [ ] Providers list shows facility name
- [ ] (Optional) Filter by facility implemented
- [ ] Search uses `searchProvidersByFacility()` action

**Database:**
- [ ] Migration applied (`npx supabase db push`)
- [ ] Test facilities exist in database
- [ ] RLS policies allow reading facilities

**Testing:**
- [ ] New provider registration saves facility
- [ ] New admin registration saves facility
- [ ] Profiles display correct facility info
- [ ] Search/filter works correctly

---

## 🚀 Quick Start Commands

```bash
# 1. Apply database migration
npx supabase db push

# 2. Insert test facilities (if none exist)
# Via Supabase Dashboard > Table Editor > facilities > Insert row
# Or via SQL:
# INSERT INTO facilities (facility_name, facility_code, facility_type, city, is_active)
# VALUES ('General Hospital', 'GH001', 'Hospital', 'Nairobi', true);

# 3. Test custom actions in FlutterFlow
# In FlutterFlow > Custom Code > Actions > Test
# Run getAllFacilities() - should return list of facilities

# 4. Update UI in FlutterFlow (see steps above)

# 5. Test registration flow
```

---

**Summary:** The database is ready. You just need to add facility dropdowns to the registration forms in FlutterFlow and update the profile/list pages to display facility information using the custom actions provided.
