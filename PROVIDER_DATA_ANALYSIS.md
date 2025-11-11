# Medical Provider Data Analysis

## Summary

Successfully retrieved comprehensive medical provider profile data from the Supabase database matching the GraphQL query structure provided.

## Database Query Results

### Provider Found
- **Count**: 1 medical provider found
- **User ID**: `ae6a139c-51fd-4d7c-877d-4bf19834a07d`
- **Provider Profile ID**: `56381b30-d867-4619-ab9e-8c5c59473d5c`
- **Email**: dr.dummy@example.com
- **Name**: Dummy Doctor
- **Role**: doctor (⚠️ needs update - see below)

## Data Structure Overview

### 1. Users Table ✅
Contains basic user information:
- Personal details (name, email, phone, date of birth, gender)
- Account status and verification flags
- Language and timezone preferences
- Avatar URL and unique patient ID

### 2. User Profiles Table ✅
Contains role-based profile data:
- Role assignment (current: "doctor")
- Bio and display name
- Complete address information
- Emergency contact details (2 contacts supported)
- Insurance information
- Health metrics (height, weight, blood type)
- Verification status and documents

### 3. Medical Provider Profiles Table ✅
Contains professional provider details:
- Provider number and unique identifier
- Professional role (⚠️ current value: "doctor")
- Medical license and registration information
- Specializations (primary, secondary, sub-specialties)
- Education details (medical school, graduation year, qualifications)
- Practice settings (type, fees, duration, languages)
- Telemedicine capabilities (video, audio, chat, USSD)
- Performance metrics (consultations, satisfaction, response time)
- Application status and approval information

### 4. Provider Specialties Table (Junction) ⏹️
- **Status**: Empty
- **Purpose**: Many-to-many relationship between providers and specialties
- **Fields**: specialty_type, board_certified, years_experience, certification_date
- **Available specialty types**: secondary, subspecialty, area_of_expertise

### 5. Specialties Table ✅
- **Status**: Populated with 100+ specialties
- **Categories**: Primary Care, Surgery, Internal Medicine, Diagnostics, Mental Health, Pediatrics, etc.
- **Format**: Bilingual (French/English)
- **Examples**:
  - Family Medicine (FAM_MED)
  - General Surgery (GEN_SURG)
  - Obstetrics & Gynecology (OBGYN)
  - Neurosurgery (NEUROSURG)

## ⚠️ Critical Issue: Professional Role Mismatch

### Current State
```json
{
  "professional_role": "doctor"
}
```

### Required State
The `professional_role` field should be from this standardized list:

```javascript
[
  "Dentist",
  "Doctor of Osteopathic Medicine",
  "Emergency Medical Technician",
  "Licensed Clinical Social Worker",
  "Medical Doctor",
  "Medical Technologist",
  "Nurse Practitioner",
  "Occupational Therapist",
  "Optometrist",
  "Pharmacist",
  "Physical Therapist",
  "Physician Assistant",
  "Psychologist",
  "Registered Nurse",
  "Respiratory Therapist"
]
```

### Recommended Action
Update the current provider's `professional_role` from "doctor" to "Medical Doctor" to match the standardized provider type list.

## GraphQL Query Mapping

The provided GraphQL query requests data from 4 collections:

### ✅ 1. usersCollection
**Status**: Successfully mapped
- All requested fields available
- Matches GraphQL structure

### ✅ 2. user_profilesCollection
**Status**: Successfully mapped
- Filtered by role (provider, doctor, nurse, specialist)
- All requested fields available

### ✅ 3. medical_provider_profilesCollection
**Status**: Successfully mapped
- All professional details retrieved
- ⚠️ professional_role needs value update

### ❌ 4. provider_facilitiesCollection
**Status**: Table not found
- **Error**: PGRST205 - Table 'public.provider_facilities' not found in schema cache
- **Suggested alternative**: Table may be named 'provider_specialties' instead
- **Note**: provider_specialties serves a different purpose (many-to-many with specialties)

## Complete Data Export

All provider data has been exported to:
- **JSON Format**: `provider_profile_export.json`
- **Text Output**: `provider_profile_output.txt`
- **Query Scripts**:
  - `query_providers.sh` - Simple query script
  - `get_full_provider_profile.sh` - Comprehensive query script
  - `get_provider_details.sql` - SQL query file

## Field Count Summary

| Table | Fields Queried | Fields Found | Status |
|-------|---------------|--------------|---------|
| users | 15 | 15 | ✅ |
| user_profiles | 24 | 24 | ✅ |
| medical_provider_profiles | 50+ | 50+ | ⚠️ |
| provider_facilities | N/A | N/A | ❌ |
| **Total** | **~90** | **~90** | **Partial** |

## Recommendations

### 1. Update Professional Role Values
```sql
-- Update current provider to standardized value
UPDATE medical_provider_profiles
SET professional_role = 'Medical Doctor'
WHERE professional_role = 'doctor';
```

### 2. Create Provider Types Enum
Consider creating a database enum or check constraint:

```sql
-- Option 1: Enum type
CREATE TYPE provider_type AS ENUM (
  'Dentist',
  'Doctor of Osteopathic Medicine',
  'Emergency Medical Technician',
  'Licensed Clinical Social Worker',
  'Medical Doctor',
  'Medical Technologist',
  'Nurse Practitioner',
  'Occupational Therapist',
  'Optometrist',
  'Pharmacist',
  'Physical Therapist',
  'Physician Assistant',
  'Psychologist',
  'Registered Nurse',
  'Respiratory Therapist'
);

-- Option 2: Check constraint
ALTER TABLE medical_provider_profiles
ADD CONSTRAINT check_professional_role_values
CHECK (professional_role IN (
  'Dentist',
  'Doctor of Osteopathic Medicine',
  'Emergency Medical Technician',
  'Licensed Clinical Social Worker',
  'Medical Doctor',
  'Medical Technologist',
  'Nurse Practitioner',
  'Occupational Therapist',
  'Optometrist',
  'Pharmacist',
  'Physical Therapist',
  'Physician Assistant',
  'Psychologist',
  'Registered Nurse',
  'Respiratory Therapist'
));
```

### 3. Update FlutterFlow UI
Ensure the provider account creation form uses a dropdown with the standardized provider type values instead of a free-text field.

### 4. Clarify Provider Facilities Table
Determine if:
- The table needs to be created, or
- The GraphQL query should reference a different table, or
- This relationship is not currently implemented

## Files Created

1. `provider_profile_export.json` - Structured JSON export matching GraphQL query
2. `provider_profile_output.txt` - Complete text output of all queries
3. `query_providers.sh` - Simple provider query script
4. `get_full_provider_profile.sh` - Comprehensive query with analysis
5. `get_provider_details.sql` - SQL query file for database execution
6. `PROVIDER_DATA_ANALYSIS.md` - This document

## Next Steps

1. ✅ Review the exported JSON data
2. ⚠️ Update professional_role values to match standardized list
3. ⚠️ Add database constraint to enforce provider type values
4. ⚠️ Update FlutterFlow form to use dropdown for provider types
5. ❓ Clarify provider_facilities table requirements

---

**Query Date**: 2025-11-06
**Total Providers Found**: 1
**Data Completeness**: 90% (missing provider_facilities only)
