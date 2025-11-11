-- ============================================================
-- COMPREHENSIVE MEDICAL PROVIDER PROFILE QUERY
-- Matches the GraphQL query structure for provider profiles
-- ============================================================

-- Query 1: Get all users who are providers
\echo '=== 1. USERS (Provider Users) ==='
SELECT
  id,
  firebase_uid,
  full_name,
  email,
  phone_number,
  date_of_birth,
  gender,
  country,
  preferred_language,
  timezone,
  account_status,
  last_seen_at,
  created_at,
  updated_at,
  avatar_url,
  unique_patient_id,
  is_active,
  is_verified,
  email_verified,
  phone_verified
FROM users
WHERE id IN (
  SELECT DISTINCT user_id
  FROM user_profiles
  WHERE role IN ('provider', 'doctor', 'nurse', 'specialist')
)
ORDER BY created_at DESC
LIMIT 10;

\echo ''
\echo '=== 2. USER PROFILES (Provider Roles) ==='
SELECT
  id,
  user_id,
  role,
  bio,
  address,
  city,
  state,
  country,
  postal_code,
  emergency_contact_name as emergency_contact_1_name,
  emergency_contact_phone as emergency_contact_1_phone,
  emergency_contact_relationship as emergency_contact_1_relationship,
  emergency_contact_2_name,
  emergency_contact_2_phone,
  emergency_contact_2_relationship,
  insurance_provider,
  insurance_policy_number,
  profile_completion_percentage,
  verification_status,
  verified_at,
  verified_by,
  verification_documents,
  created_at,
  updated_at
FROM user_profiles
WHERE role IN ('provider', 'doctor', 'nurse', 'specialist')
ORDER BY created_at DESC
LIMIT 10;

\echo ''
\echo '=== 3. MEDICAL PROVIDER PROFILES ==='
SELECT
  id,
  user_id,
  provider_number,
  unique_identifier,
  medical_license_number,
  professional_registration_number,
  license_issuing_authority,
  license_expiry_date,
  professional_role,
  primary_specialization,
  secondary_specializations,
  sub_specialties,
  areas_of_expertise,
  is_specialist,
  medical_school,
  graduation_year,
  qualifications,
  residency_programs,
  fellowship_programs,
  board_certifications,
  continuing_education_credits,
  years_of_experience,
  previous_positions,
  hospital_affiliations,
  professional_memberships,
  practice_type,
  consultation_fee,
  consultation_fee_range,
  consultation_duration_minutes,
  max_patients_per_day,
  accepts_new_patients,
  accepts_emergency_calls,
  languages_spoken,
  telemedicine_setup_complete,
  video_consultation_enabled,
  audio_consultation_enabled,
  chat_consultation_enabled,
  ussd_consultation_enabled,
  total_consultations,
  patient_satisfaction_avg,
  response_time_avg_minutes,
  consultation_completion_rate,
  content_creator_status,
  total_posts_created,
  total_followers,
  content_engagement_score,
  background_check_completed,
  background_check_date,
  malpractice_insurance_valid,
  malpractice_insurance_expiry,
  availability_status,
  application_status,
  rejection_reason,
  facility_id,
  approved_at,
  approved_by_id,
  primary_specialty_id,
  avatar_url,
  created_at,
  updated_at
FROM medical_provider_profiles
ORDER BY created_at DESC
LIMIT 10;

\echo ''
\echo '=== 4. PROVIDER FACILITIES (with Healthcare Facilities) ==='
SELECT
  pf.id,
  pf.provider_id,
  pf.facility_id,
  pf.is_primary,
  pf.role_at_facility,
  pf.start_date,
  pf.end_date,
  pf.is_active,
  hf.name as facility_name,
  hf.facility_code,
  hf.facility_type,
  hf.address as facility_address,
  hf.city as facility_city,
  hf.region_code as facility_region_code,
  hf.phone_number as facility_phone,
  hf.email as facility_email,
  pf.created_at,
  pf.updated_at
FROM provider_facilities pf
LEFT JOIN healthcare_facilities hf ON pf.facility_id = hf.id
WHERE pf.provider_id IN (
  SELECT DISTINCT user_id
  FROM user_profiles
  WHERE role IN ('provider', 'doctor', 'nurse', 'specialist')
)
ORDER BY pf.created_at DESC
LIMIT 20;

\echo ''
\echo '=== 5. SUMMARY: Total Provider Count ==='
SELECT
  COUNT(DISTINCT up.user_id) as total_providers,
  COUNT(DISTINCT CASE WHEN up.role = 'provider' THEN up.user_id END) as providers,
  COUNT(DISTINCT CASE WHEN up.role = 'doctor' THEN up.user_id END) as doctors,
  COUNT(DISTINCT CASE WHEN up.role = 'nurse' THEN up.user_id END) as nurses,
  COUNT(DISTINCT CASE WHEN up.role = 'specialist' THEN up.user_id END) as specialists,
  COUNT(DISTINCT mpp.user_id) as with_provider_profile,
  COUNT(DISTINCT pf.provider_id) as with_facilities
FROM user_profiles up
LEFT JOIN medical_provider_profiles mpp ON up.user_id = mpp.user_id
LEFT JOIN provider_facilities pf ON up.user_id = pf.provider_id
WHERE up.role IN ('provider', 'doctor', 'nurse', 'specialist');
