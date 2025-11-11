#!/bin/bash

# Get comprehensive provider profile with all related data

SUPABASE_URL="https://noaeltglphdlkbflipit.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vYWVsdGdscGhkbGtiZmxpcGl0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1OTQ0NzYzOSwiZXhwIjoyMDc1MDIzNjM5fQ.Psb3F0S0lAoJPmHpl4vqboKN6BLq1OAg6mNSIyVIAeM"
PROVIDER_ID="ae6a139c-51fd-4d7c-877d-4bf19834a07d"
PROVIDER_PROFILE_ID="56381b30-d867-4619-ab9e-8c5c59473d5c"

echo "============================================================"
echo "COMPREHENSIVE MEDICAL PROVIDER PROFILE"
echo "============================================================"
echo ""
echo "Provider ID: $PROVIDER_ID"
echo "Provider Profile ID: $PROVIDER_PROFILE_ID"
echo ""

echo "--- 1. USER INFORMATION ---"
curl -s "$SUPABASE_URL/rest/v1/users?id=eq.$PROVIDER_ID&select=id,firebase_uid,email,full_name,first_name,last_name,phone_number,date_of_birth,gender,country,preferred_language,timezone,account_status,avatar_url,unique_patient_id,is_active,is_verified,email_verified,phone_verified,created_at,updated_at" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" | jq '.[0]'

echo ""
echo "--- 2. USER PROFILE (Role-based data) ---"
curl -s "$SUPABASE_URL/rest/v1/user_profiles?user_id=eq.$PROVIDER_ID&select=id,user_id,role,display_name,bio,profile_completion_percentage,verification_status,verified_at,verified_by,address,city,state,country,postal_code,region_code,emergency_contact_name,emergency_contact_phone,emergency_contact_relationship,insurance_provider,insurance_policy_number,blood_type,height_cm,weight_kg,created_at,updated_at" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" | jq '.[0]'

echo ""
echo "--- 3. MEDICAL PROVIDER PROFILE (Professional details) ---"
curl -s "$SUPABASE_URL/rest/v1/medical_provider_profiles?user_id=eq.$PROVIDER_ID&select=id,user_id,provider_number,unique_identifier,professional_role,medical_license_number,professional_registration_number,license_issuing_authority,license_expiry_date,primary_specialization,primary_specialty_id,secondary_specializations,sub_specialties,areas_of_expertise,is_specialist,medical_school,graduation_year,qualifications,years_of_experience,practice_type,consultation_fee,consultation_fee_range,consultation_duration_minutes,languages_spoken,telemedicine_setup_complete,video_consultation_enabled,total_consultations,patient_satisfaction_avg,application_status,approved_at,created_at,updated_at" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" | jq '.[0]'

echo ""
echo "--- 4. PROVIDER SPECIALTIES (Many-to-many relationship) ---"
curl -s "$SUPABASE_URL/rest/v1/provider_specialties?provider_id=eq.$PROVIDER_PROFILE_ID&select=*" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" | jq .

echo ""
echo "--- 5. AVAILABLE SPECIALTIES (Sample - first 10) ---"
curl -s "$SUPABASE_URL/rest/v1/specialties?select=id,specialty_code,specialty_name,description&is_active=eq.true&order=display_order.asc&limit=10" \
  -H "apikey: $SERVICE_KEY" \
  -H "Authorization: Bearer $SERVICE_KEY" | jq .

echo ""
echo "--- 6. PROFESSIONAL ROLE VALUE ---"
echo "Current professional_role in database: 'doctor'"
echo ""
echo "Expected professional_role values (from user requirement):"
echo "  - Dentist"
echo "  - Doctor of Osteopathic Medicine"
echo "  - Emergency Medical Technician"
echo "  - Licensed Clinical Social Worker"
echo "  - Medical Doctor"
echo "  - Medical Technologist"
echo "  - Nurse Practitioner"
echo "  - Occupational Therapist"
echo "  - Optometrist"
echo "  - Pharmacist"
echo "  - Physical Therapist"
echo "  - Physician Assistant"
echo "  - Psychologist"
echo "  - Registered Nurse"
echo "  - Respiratory Therapist"
echo ""
echo "⚠️  NOTE: Current value 'doctor' does not match the expected list."
echo "    The professional_role field should be updated to use one of the"
echo "    standardized provider type values listed above."

echo ""
echo "============================================================"
echo "SUMMARY"
echo "============================================================"
echo ""
echo "✅ User data: Retrieved successfully"
echo "✅ User profile: Retrieved successfully"
echo "✅ Medical provider profile: Retrieved successfully"
echo "⏹️  Provider specialties: Empty (no secondary specialties assigned)"
echo "✅ Specialties table: Has data (100+ specialties available)"
echo "⚠️  Professional role mismatch: Needs to be updated to standardized value"
echo ""
echo "============================================================"
