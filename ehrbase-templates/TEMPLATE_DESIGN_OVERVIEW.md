# OpenEHR Template Design for MedZen Multi-Role System

## Overview

This document outlines the OpenEHR template design for all 4 user roles in the MedZen healthcare system.

## Design Philosophy

- **Each user type gets an EHR** - OpenEHR can store more than just patient clinical data
- **Role-specific templates** - Different compositions based on user role
- **Extensible architecture** - Easy to add new data types for each role
- **HIPAA compliant** - Proper access controls and audit trails

---

## 1. Patient Templates

**Primary Use:** Clinical health records and medical history

### Templates to Use:
1. **Patient Demographics** - Basic profile information
   - Template ID: `medzen.patient.demographics.v1`
   - Name, DOB, gender, contact, emergency contacts, insurance

2. **Vital Signs Encounter** (existing)
   - Template ID: `IDCR - Vital Signs Encounter.v1`
   - Blood pressure, heart rate, temperature, O2 saturation

3. **Problem/Diagnosis List** (existing)
   - Template ID: `IDCR - Problem List.v1`
   - Chronic conditions, diagnoses, onset dates, severity

4. **Medication Statement List** (existing)
   - Template ID: `IDCR - Medication Statement List.v1`
   - Current medications, dosage, frequency, prescriber

5. **Laboratory Results** (existing)
   - Template ID: `laboratory_results_report.en.v1`
   - Lab test results, reference ranges, interpretation

6. **Procedures List** (existing)
   - Template ID: `IDCR - Procedures List.v1`
   - Medical procedures, surgeries, interventions

7. **Clinical Note** (existing)
   - Template ID: `RIPPLE - Clinical Note.v0`
   - Doctor's notes, consultation summaries, telemedicine encounters

---

## 2. Medical Provider Templates

**Primary Use:** Professional credentials, specialties, availability, and practice information

### New Templates Needed:

#### 2.1 Provider Profile
- **Template ID:** `medzen.provider.profile.v1`
- **Purpose:** Core professional information
- **Structure:**
```
COMPOSITION: Provider Professional Profile
  context:
    start_time: datetime (profile creation)
    setting: 'Provider Registration'

  content:
    - ADMIN_ENTRY.provider_demographics.v1
        data:
          - Provider ID (UUID)
          - Full name
          - Date of birth
          - Gender
          - Nationality
          - Contact information (phone, email)
          - Profile photo URL

    - ADMIN_ENTRY.professional_credentials.v1
        data:
          - Medical license number
          - License issuing authority
          - License issue date
          - License expiry date
          - License verification status
          - Professional registration bodies
          - Board certifications

    - ADMIN_ENTRY.education_training.v1
        data:
          - Medical school
          - Graduation year
          - Residency program
          - Fellowship programs
          - Continuing education credits

    - ADMIN_ENTRY.specialties.v1
        data:
          - Primary specialty
          - Sub-specialties (array)
          - Years of experience
          - Areas of expertise
          - Languages spoken

    - ADMIN_ENTRY.practice_information.v1
        data:
          - Practice type (solo, group, hospital-based)
          - Associated facilities (array of facility IDs)
          - Consultation types (in-person, telemedicine)
          - Patient age groups treated

    - ADMIN_ENTRY.verification_status.v1
        data:
          - Background check status
          - Credential verification date
          - Verification authority
          - Account approval status
          - Approval date
          - Approved by (admin ID)
```

#### 2.2 Provider Availability Schedule
- **Template ID:** `medzen.provider.schedule.v1`
- **Purpose:** Working hours and appointment availability
- **Structure:**
```
COMPOSITION: Provider Availability Schedule
  context:
    start_time: datetime
    setting: 'Schedule Management'

  content:
    - ADMIN_ENTRY.schedule_configuration.v1
        data:
          - Provider ID
          - Effective date range (start/end)
          - Time zone
          - Default consultation duration (minutes)
          - Buffer time between appointments

    - ADMIN_ENTRY.weekly_schedule.v1
        data:
          - Day of week
          - Working hours (start/end times)
          - Lunch break (start/end)
          - Available slots
          - Facility location (if applicable)

    - ADMIN_ENTRY.exceptions.v1
        data:
          - Date
          - Exception type (holiday, leave, conference)
          - Notes
```

#### 2.3 Provider Performance Metrics
- **Template ID:** `medzen.provider.metrics.v1`
- **Purpose:** Track consultation quality and patient satisfaction
- **Structure:**
```
COMPOSITION: Provider Performance Metrics
  context:
    start_time: datetime
    setting: 'Quality Assurance'

  content:
    - OBSERVATION.consultation_statistics.v1
        data:
          - Total consultations completed
          - Average consultation duration
          - Response time (average)
          - Follow-up rate

    - OBSERVATION.patient_satisfaction.v1
        data:
          - Average rating (1-5 stars)
          - Total reviews
          - Positive feedback count
          - Complaints count
          - Resolution rate

    - OBSERVATION.clinical_outcomes.v1
        data:
          - Diagnosis accuracy (if trackable)
          - Treatment adherence rate
          - Patient readmission rate
```

---

## 3. Facility Admin Templates

**Primary Use:** Healthcare facility management and infrastructure

### New Templates Needed:

#### 3.1 Facility Profile
- **Template ID:** `medzen.facility.profile.v1`
- **Purpose:** Core facility information
- **Structure:**
```
COMPOSITION: Healthcare Facility Profile
  context:
    start_time: datetime
    setting: 'Facility Registration'

  content:
    - ADMIN_ENTRY.facility_identification.v1
        data:
          - Facility ID (UUID)
          - Facility name
          - Facility type (Hospital, Clinic, Pharmacy, Laboratory, Diagnostic Center)
          - Parent organization (if applicable)
          - CNPS affiliation: boolean
          - Government accreditation

    - ADMIN_ENTRY.facility_location.v1
        data:
          - Street address
          - City
          - Region/State
          - Country
          - Postal code
          - GPS coordinates
          - Landmark

    - ADMIN_ENTRY.facility_contact.v1
        data:
          - Primary phone
          - Emergency phone
          - Fax
          - Email
          - Website
          - Social media links

    - ADMIN_ENTRY.operating_hours.v1
        data:
          - Weekly schedule (hours per day)
          - 24/7 operation: boolean
          - Emergency services available: boolean
          - Holiday hours
```

#### 3.2 Facility Services & Infrastructure
- **Template ID:** `medzen.facility.services.v1`
- **Purpose:** Available services and infrastructure capacity
- **Structure:**
```
COMPOSITION: Facility Services and Infrastructure
  context:
    start_time: datetime
    setting: 'Service Management'

  content:
    - ADMIN_ENTRY.medical_services.v1
        data:
          - Services offered (array):
              ['Emergency', 'Pediatrics', 'Surgery', 'ICU',
               'Maternity', 'Pharmacy', 'Laboratory', 'Radiology',
               'Physical Therapy', 'Mental Health', 'Dental']
          - Specialties available (linked to specialty codes)

    - ADMIN_ENTRY.infrastructure_capacity.v1
        data:
          - Total beds: integer
          - ICU beds: integer
          - Incubators: integer
          - Operating rooms: integer
          - Ventilators: integer
          - Dialysis machines: integer
          - Blood bank available: boolean
          - Imaging equipment (X-ray, CT, MRI, Ultrasound)
          - Ambulance services: boolean

    - ADMIN_ENTRY.emergency_preparedness.v1
        data:
          - Emergency beds available
          - Trauma center level
          - Disaster response capabilities
          - Surge capacity

    - ADMIN_ENTRY.laboratory_services.v1
        data:
          - Lab tests available (array)
          - Sample collection methods
          - Turnaround time
          - Accreditation status
```

#### 3.3 Facility Staff Registry
- **Template ID:** `medzen.facility.staff.v1`
- **Purpose:** Track all staff associated with facility
- **Structure:**
```
COMPOSITION: Facility Staff Registry
  context:
    start_time: datetime
    setting: 'Staff Management'

  content:
    - ADMIN_ENTRY.medical_staff.v1
        data:
          - Provider ID (linked)
          - Name
          - Role (Doctor, Surgeon, Specialist)
          - Department
          - Employment type (full-time, part-time, visiting)
          - Start date
          - Status (active, on-leave, terminated)

    - ADMIN_ENTRY.nursing_staff.v1
        data:
          - Staff ID
          - Name
          - Nursing level (RN, LPN, CNA)
          - Department
          - Shift assignments

    - ADMIN_ENTRY.support_staff.v1
        data:
          - Staff ID
          - Name
          - Role (Lab tech, Radiologist, Pharmacist, Admin)
          - Department
          - Certifications

    - ADMIN_ENTRY.administrative_staff.v1
        data:
          - Staff ID
          - Name
          - Role (Manager, Receptionist, Billing)
          - Department
```

#### 3.4 Facility Billing & Financial
- **Template ID:** `medzen.facility.billing.v1`
- **Purpose:** Financial tracking and insurance
- **Structure:**
```
COMPOSITION: Facility Billing Configuration
  context:
    start_time: datetime
    setting: 'Financial Management'

  content:
    - ADMIN_ENTRY.billing_information.v1
        data:
          - Tax ID
          - Bank account details
          - Billing address
          - Accepted payment methods

    - ADMIN_ENTRY.insurance_partnerships.v1
        data:
          - Insurance provider name
          - Contract number
          - Effective dates
          - Covered services
          - Reimbursement rates

    - ADMIN_ENTRY.pricing_structure.v1
        data:
          - Service code
          - Service description
          - Base price
          - Insurance negotiated rate
          - Discounts available
```

---

## 4. System Admin Templates

**Primary Use:** System configuration, user management, and audit trails

### New Templates Needed:

#### 4.1 System Admin Profile
- **Template ID:** `medzen.admin.profile.v1`
- **Purpose:** Admin user information and permissions
- **Structure:**
```
COMPOSITION: System Administrator Profile
  context:
    start_time: datetime
    setting: 'System Administration'

  content:
    - ADMIN_ENTRY.admin_identification.v1
        data:
          - Admin ID (UUID)
          - Full name
          - Email
          - Phone
          - Department (IT, Operations, Security)

    - ADMIN_ENTRY.admin_permissions.v1
        data:
          - Access level (super-admin, admin, moderator)
          - Permitted actions (array):
              ['user_management', 'facility_approval',
               'provider_verification', 'system_config',
               'security_settings', 'audit_logs',
               'data_export', 'backup_restore']
          - Restricted modules

    - ADMIN_ENTRY.security_credentials.v1
        data:
          - Last password change
          - Two-factor authentication enabled
          - Security clearance level
          - IP whitelist
```

#### 4.2 System Audit Log
- **Template ID:** `medzen.admin.audit.v1`
- **Purpose:** Track all system actions for compliance
- **Structure:**
```
COMPOSITION: System Audit Log Entry
  context:
    start_time: datetime (action timestamp)
    setting: 'Security Audit'

  content:
    - ADMIN_ENTRY.action_details.v1
        data:
          - Action ID
          - Action type (create, read, update, delete, login, logout)
          - Resource affected (user, facility, provider, patient)
          - Resource ID
          - Actor (user who performed action)
          - Actor ID
          - Actor role

    - ADMIN_ENTRY.action_context.v1
        data:
          - IP address
          - Device type
          - Browser/App version
          - Geolocation (if available)
          - Session ID

    - ADMIN_ENTRY.action_result.v1
        data:
          - Success/Failure
          - Error message (if failed)
          - Changes made (before/after)
          - Affected records count

    - ADMIN_ENTRY.compliance_metadata.v1
        data:
          - HIPAA compliance flag
          - Data access justification
          - Approval required
          - Approval status
```

#### 4.3 System Configuration
- **Template ID:** `medzen.admin.system_config.v1`
- **Purpose:** Track system-wide settings
- **Structure:**
```
COMPOSITION: System Configuration Record
  context:
    start_time: datetime
    setting: 'System Configuration'

  content:
    - ADMIN_ENTRY.application_settings.v1
        data:
          - App version
          - API version
          - Database version
          - Maintenance mode: boolean
          - Scheduled maintenance (start/end)

    - ADMIN_ENTRY.security_settings.v1
        data:
          - Password policy
          - Session timeout (minutes)
          - Max login attempts
          - Data encryption enabled
          - Backup frequency

    - ADMIN_ENTRY.feature_flags.v1
        data:
          - Feature name
          - Enabled: boolean
          - Rollout percentage
          - Target user groups

    - ADMIN_ENTRY.integration_settings.v1
        data:
          - PowerSync configuration
          - EHRbase connection
          - Supabase settings
          - Firebase settings
          - Payment gateway config
```

---

## Template Hierarchy

```
medzen (namespace)
  ├── patient
  │   ├── demographics.v1
  │   ├── vital_signs (use existing IDCR templates)
  │   ├── problems (use existing)
  │   ├── medications (use existing)
  │   └── lab_results (use existing)
  │
  ├── provider
  │   ├── profile.v1
  │   ├── schedule.v1
  │   └── metrics.v1
  │
  ├── facility
  │   ├── profile.v1
  │   ├── services.v1
  │   ├── staff.v1
  │   └── billing.v1
  │
  └── admin
      ├── profile.v1
      ├── audit.v1
      └── system_config.v1
```

---

## Implementation Roadmap

### Phase 1: Core Templates (Week 1)
1. Create patient demographics template
2. Create provider profile template
3. Create facility profile template
4. Create admin profile template

### Phase 2: Extended Templates (Week 2)
5. Provider schedule & metrics
6. Facility services & staff
7. Admin audit & system config

### Phase 3: Integration (Week 3)
8. Update onUserCreated function
9. Update sync-to-ehrbase edge function
10. Add role-based template selection logic

### Phase 4: Testing (Week 4)
11. Test EHR creation for each role
12. Validate template structure
13. Test sync operations
14. Performance testing

---

## Database Changes Required

### 1. Update `electronic_health_records` table
```sql
ALTER TABLE electronic_health_records
ADD COLUMN user_role VARCHAR(50) NOT NULL DEFAULT 'patient',
ADD COLUMN primary_template_id VARCHAR(255);

CREATE INDEX idx_ehr_user_role ON electronic_health_records(user_role);
```

### 2. Update `ehrbase_sync_queue` table
```sql
ALTER TABLE ehrbase_sync_queue
ADD COLUMN user_role VARCHAR(50),
ADD COLUMN composition_category VARCHAR(100);

CREATE INDEX idx_sync_queue_role ON ehrbase_sync_queue(user_role);
```

---

## Next Steps

1. ✅ Review this design document
2. ⏳ Create OpenEHR template XML/JSON files
3. ⏳ Upload templates to EHRbase
4. ⏳ Update application code
5. ⏳ Test end-to-end flow

---

**Document Version:** 1.0
**Last Updated:** 2025-11-02
**Author:** MedZen Development Team
