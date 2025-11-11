-- =====================================================
-- Fix User Role Naming
-- =====================================================
-- Changes 'doctor' role to 'medical_provider' to match system requirements
-- Date: 2025-11-06
-- Issue: User roles must be one of: patient, medical_provider, facility_admin, system_admin

-- Update the role name
UPDATE user_profiles
SET role = 'medical_provider'
WHERE role = 'doctor';

-- Add check constraint to enforce valid roles (prevents future issues)
ALTER TABLE user_profiles
DROP CONSTRAINT IF EXISTS user_profiles_role_check;

ALTER TABLE user_profiles
ADD CONSTRAINT user_profiles_role_check
CHECK (role IN ('patient', 'medical_provider', 'facility_admin', 'system_admin'));

-- Add comment documenting valid roles
COMMENT ON COLUMN user_profiles.role IS 'User role: patient, medical_provider, facility_admin, or system_admin';
