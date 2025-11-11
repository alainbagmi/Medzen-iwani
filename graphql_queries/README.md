# Medical Provider GraphQL Queries - Documentation

**Created:** 2025-11-06
**Status:** ✅ Fully Functional

## Overview

Complete set of GraphQL queries for fetching medical provider data from Supabase database. Includes both `.graphql` query files and an executable bash script for easy testing.

## Files

| File | Purpose | Status |
|------|---------|--------|
| `medical_providers_query.graphql` | GraphQL query definitions | ✅ Complete |
| `execute_provider_query.sh` | Executable query runner | ✅ Tested & Working |
| `example_responses.json` | Example responses & common patterns | ✅ Reference |
| `README.md` | This documentation | ✅ Current |

## Available Queries

### 1. Get Provider by ID (`by-id`)
Fetches specific provider with user info and basic details.

**Usage:**
```bash
./execute_provider_query.sh by-id ae6a139c-51fd-4d7c-877d-4bf19834a07d
```

**Returns:** Provider profile with user data, specialization, practice type, consultation fees, ratings

### 2. Get Comprehensive Profile (`full-profile`)
Fetches complete provider data across all tables: users, user_profiles, medical_provider_profiles.

**Usage:**
```bash
./execute_provider_query.sh full-profile ae6a139c-51fd-4d7c-877d-4bf19834a07d
```

**Returns:**
- User account data (email, phone, avatar, demographics)
- User profile (bio, allergies, emergency contacts, insurance)
- Medical provider profile (licenses, certifications, practice details, telemedicine settings)

### 3. Get All Active Providers (`all`)
Lists all approved providers with pagination support.

**Usage:**
```bash
./execute_provider_query.sh all 10
```

**Default limit:** 10 providers
**Returns:** Simplified provider list with names, emails, roles, specializations

### 4. Get Providers by Type (`by-type`)
Filter providers by professional role (e.g., "Medical Doctor").

**Usage:**
```bash
./execute_provider_query.sh by-type "Medical Doctor" 20
```

**Returns:** Providers matching the specified type, ordered by experience

### 5. Get Providers by Specialization (`by-specialization`)
Filter by primary specialization (e.g., "general_medicine").

**Usage:**
```bash
./execute_provider_query.sh by-specialization general_medicine 15
```

**Returns:** Providers with matching specialization, ordered by patient satisfaction

### 6. Get Provider Statistics (`statistics`)
Aggregate statistics about providers in the system.

**Usage:**
```bash
./execute_provider_query.sh statistics
```

**Returns:**
- Total provider count
- Approved provider count  
- Breakdown by provider type

### 7. List All Provider Types (`types`)
Lists all 15 standardized provider types with metadata.

**Usage:**
```bash
./execute_provider_query.sh types
```

**Returns:** Complete list of provider types with codes, descriptions, and requirements

## The 15 Standardized Provider Types

| Code | Provider Type | Description |
|------|--------------|-------------|
| DDS | Dentist | Doctor of Dental Surgery |
| DO | Doctor of Osteopathic Medicine | Physician with DO degree |
| EMT | Emergency Medical Technician | Emergency medical services provider |
| LCSW | Licensed Clinical Social Worker | Mental health professional |
| MD | Medical Doctor | Physician with MD degree |
| MT | Medical Technologist | Laboratory technologist |
| NP | Nurse Practitioner | Advanced practice registered nurse |
| OT | Occupational Therapist | Licensed occupational therapist |
| OD | Optometrist | Doctor of Optometry |
| PharmD | Pharmacist | Doctor of Pharmacy |
| PT | Physical Therapist | Licensed physical therapist |
| PA | Physician Assistant | Licensed physician assistant |
| PsyD | Psychologist | Doctor of Psychology |
| RN | Registered Nurse | Licensed registered nurse |
| RT | Respiratory Therapist | Licensed respiratory therapist |

## Testing

All queries tested and verified:

✅ by-id - Get specific provider
✅ full-profile - Comprehensive data from all tables  
✅ all - List active providers
✅ by-type - Filter by professional role
✅ by-specialization - Filter by specialization
✅ statistics - Provider counts
✅ types - List all provider types

## Next Steps

1. ✅ GraphQL queries created and tested
2. ✅ Bash script working for all query types
3. ✅ Documentation complete
4. ⏳ TODO: Apply database migration for check constraints (see MIGRATION_STATUS_REPORT.md)
5. ⏳ TODO: Update FlutterFlow provider creation form to use dropdown

---

**Last Updated:** 2025-11-06  
**Status:** Production Ready
