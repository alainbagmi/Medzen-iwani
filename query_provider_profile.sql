-- Comprehensive Medical Provider Profile Query
-- This query retrieves all details for medical providers similar to the GraphQL query

-- First, let's get a list of all providers with basic info
WITH provider_users AS (
  SELECT DISTINCT
    up.user_id,
    up.role
  FROM user_profiles up
  WHERE up.role IN ('provider', 'doctor', 'nurse', 'specialist')
  LIMIT 10
)

-- Main query with all provider details
SELECT
  '=== USERS TABLE ===' as section,
  u.id,
  u.full_name,
  u.date_of_birth,
  u.gender,
  u.email,
  u.phone_number,
  u.country,
  u.preferred_language,
  u.timezone,
  u.account_status,
  u.last_seen_at,
  u.created_at,
  u.updated_at,
  u.avatar_url,
  u.unique_patient_id
FROM users u
INNER JOIN provider_users pu ON u.id = pu.user_id

UNION ALL

SELECT
  '=== USER PROFILES TABLE ===' as section,
  up.id::text,
  up.user_id::text,
  up.role,
  up.profile_completion_percentage::text,
  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM user_profiles up
INNER JOIN provider_users pu ON up.user_id = pu.user_id

UNION ALL

SELECT
  '=== MEDICAL PROVIDER PROFILES TABLE ===' as section,
  mpp.user_id::text,
  mpp.medical_license_number,
  mpp.license_issuing_authority,
  mpp.license_expiry_date::text,
  mpp.professional_registration_number,
  mpp.primary_specialization,
  mpp.professional_role,
  mpp.years_of_experience::text,
  NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM medical_provider_profiles mpp
INNER JOIN provider_users pu ON mpp.user_id = pu.user_id

UNION ALL

SELECT
  '=== PROVIDER FACILITIES ===' as section,
  pf.provider_id::text,
  pf.facility_id::text,
  pf.is_primary::text,
  hf.name,
  hf.facility_code,
  hf.facility_type,
  hf.address,
  hf.city,
  NULL, NULL, NULL, NULL, NULL, NULL, NULL
FROM provider_facilities pf
INNER JOIN provider_users pu ON pf.provider_id = pu.user_id
LEFT JOIN healthcare_facilities hf ON pf.facility_id = hf.id;
